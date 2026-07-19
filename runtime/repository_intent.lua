local digest = require("core.digest")

local repository_intent = {
    protocol_version = "repository.action_intent.v0",
}

local intent_keys = {
    protocol_version = true,
    intent_id = true,
    operation = true,
    source_unit_id = true,
    source_unit_version = true,
    source_formation_event_ref = true,
    relative_path = true,
    content_ref = true,
    content_bytes = true,
    content_sha256 = true,
    scope_refs = true,
    provenance_refs = true,
    event_truth_status = true,
    content_truth_status = true,
}

local value_keys = {
    path = true,
    content = true,
}

local content_ref_keys = {
    unit_id = true,
    unit_version = true,
    selector = true,
}

local forbidden_components = {
    [".git"] = true,
    [".agents"] = true,
    [".codex"] = true,
}

local function copy_value(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

local function diagnostic(code, detail)
    return {
        kind = "repository_intent_diagnostic",
        protocol_version = "repository.intent_diagnostic.v0",
        code = code,
        detail = detail,
        event_truth_status = "runtime_confirmed",
    }
end

local function validate_keys(value, allowed, name)
    if type(value) ~= "table" then
        return nil, name .. " must be table"
    end
    for key in pairs(value) do
        if not allowed[key] then
            return nil, name .. " contains unknown key: " .. tostring(key)
        end
    end
    return true
end

local function positive_integer(value, name)
    if type(value) ~= "number" or value < 1 or value ~= math.floor(value) then
        return nil, name .. " must be a positive integer"
    end
    return value
end

local function strict_string_array(value, name)
    if type(value) ~= "table" then
        return nil, name .. " must be table"
    end
    local result = {}
    local seen = {}
    for index, item in ipairs(value) do
        if type(item) ~= "string" or item == "" or seen[item] then
            return nil, name .. " must contain unique non-empty strings"
        end
        seen[item] = true
        result[index] = item
    end
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key > #result
            or key ~= math.floor(key) then
            return nil, name .. " must be an array"
        end
    end
    return result
end

local function valid_utf8(value)
    if type(value) ~= "string" then
        return false
    end
    local ok, length = pcall(utf8.len, value)
    return ok and length ~= nil
end

function repository_intent.validate_relative_path(value)
    if type(value) ~= "string" or value == "" or not valid_utf8(value) then
        return nil, "relative path must be a non-empty UTF-8 string"
    end
    if value:find("[%z\1-\31]") or value:sub(1, 1) == "/"
        or value:sub(-1) == "/" or value:find("//", 1, true) then
        return nil, "relative path has forbidden boundary or control bytes"
    end
    local component_count = 0
    for component in value:gmatch("[^/]+") do
        component_count = component_count + 1
        if component == "." or component == ".." or forbidden_components[component] then
            return nil, "relative path has a forbidden component"
        end
        if not component:match("^[A-Za-z0-9][A-Za-z0-9._-]*$") then
            return nil, "relative path component is outside v0 grammar"
        end
    end
    if component_count == 0 then
        return nil, "relative path has no components"
    end
    return value
end

function repository_intent.validate_text_content(value)
    if type(value) ~= "string" or not valid_utf8(value) then
        return nil, "content must be a UTF-8 string"
    end
    if value:find("%z") then
        return nil, "content must not contain NUL"
    end
    return value
end

local function unique_refs(values)
    local result = {}
    local seen = {}
    for _, value in ipairs(values or {}) do
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    return result
end

local function same_array(left, right)
    if type(left) ~= "table" or type(right) ~= "table" or #left ~= #right then
        return false
    end
    for index, value in ipairs(left) do
        if right[index] ~= value then
            return false
        end
    end
    return true
end

local function coverage_ref(unit)
    return table.concat({
        "coverage",
        "field_unit",
        unit.id,
        tostring(unit.version),
    }, ":")
end

local function formation_for(instance, unit)
    local matches = {}
    for _, event in ipairs(instance.trace or {}) do
        local payload = event.payload
        if event.type == "structure_formation"
            and event.packet_id == instance.id
            and event.generation == instance.generation
            and type(payload) == "table"
            and payload.protocol_version == "field.structure_formation.v0"
            and type(payload.formed_unit_ids) == "table"
            and type(payload.formed_unit_versions) == "table" then
            local formed_version = payload.formed_unit_versions[unit.id]
            local names_unit = false
            for _, formed_id in ipairs(payload.formed_unit_ids) do
                if formed_id == unit.id then
                    names_unit = true
                    break
                end
            end
            if names_unit and type(formed_version) == "number" and formed_version >= 1
                and formed_version == math.floor(formed_version)
                and formed_version <= unit.version then
                matches[#matches + 1] = event
            end
        end
    end
    if #matches ~= 1 then
        return nil, "repository field unit must have one exact structure formation"
    end
    return matches[1]
end

local function current_unit(instance, id)
    if type(instance) ~= "table" or type(instance.field) ~= "table"
        or type(instance.field.units) ~= "table" then
        return nil, "Packet field is unavailable"
    end
    local unit = instance.field.units[id]
    if type(unit) ~= "table" or unit.id ~= id or unit.kind ~= "structured_item"
        or type(unit.version) ~= "number" or unit.version < 1
        or unit.version ~= math.floor(unit.version)
        or unit.generation ~= instance.generation then
        return nil, "repository intent field unit invariant failed"
    end
    return unit
end

local function material_for(unit)
    local carrier = unit.carrier
    if type(carrier) ~= "table" then
        return nil, diagnostic("malformed_repository_item", "carrier must be table")
    end
    if carrier.kind ~= "repository.create_text_file.v0" then
        return nil, diagnostic("unsupported_repository_item", carrier.kind)
    end
    local keys_ok, keys_err = validate_keys(carrier.value, value_keys, "repository item value")
    if not keys_ok then
        return nil, diagnostic("malformed_repository_item", keys_err)
    end
    local path, path_err = repository_intent.validate_relative_path(carrier.value.path)
    if not path then
        return nil, diagnostic("invalid_relative_path", path_err)
    end
    local content, content_err = repository_intent.validate_text_content(carrier.value.content)
    if not content then
        return nil, diagnostic("invalid_text_content", content_err)
    end
    return {
        relative_path = path,
        content = content,
    }
end

local function active_units(instance, max_items)
    if type(instance) ~= "table" or type(instance.field) ~= "table"
        or type(instance.field.units) ~= "table"
        or type(instance.field.unit_order) ~= "table" then
        return nil, "Packet field invariant failed"
    end
    local result = {}
    local repository_items = 0
    local unsupported = nil
    for _, id in ipairs(instance.field.unit_order) do
        local unit = instance.field.units[id]
        if type(unit) ~= "table" or unit.id ~= id then
            return nil, "Packet field order invariant failed"
        end
        if unit.generation == instance.generation and unit.kind == "structured_item"
            and (unit.activation == "live" or unit.activation == "selected") then
            local carrier = unit.carrier
            if type(carrier) ~= "table" or type(carrier.kind) ~= "string" then
                return nil, "structured field carrier invariant failed"
            end
            if carrier.kind:match("^repository%.") then
                repository_items = repository_items + 1
                if repository_items > max_items then
                    return nil, diagnostic("repository_inspection_truncated")
                end
                if carrier.kind == "repository.create_text_file.v0" then
                    result[#result + 1] = unit
                else
                    unsupported = unsupported or carrier.kind
                end
            end
        end
    end
    if #result == 0 and unsupported then
        return nil, diagnostic("unsupported_repository_item", unsupported)
    end
    if unsupported or #result > 1 then
        return nil, diagnostic("multi_item_scheduling_deferred")
    end
    if #result == 0 then
        return nil, diagnostic("repository_intent_absent")
    end
    return result
end

local function identity_projection(intent)
    local value = copy_value(intent)
    value.intent_id = nil
    return value
end

local function build(instance, unit)
    local formation, formation_err = formation_for(instance, unit)
    if not formation then
        return nil, formation_err
    end
    local material, material_err = material_for(unit)
    if not material then
        return nil, material_err
    end
    local scope_refs = {coverage_ref(unit)}
    local provenance_refs = unique_refs({
        formation.id,
        unit.created_event_id,
        table.unpack(unit.source_refs or {}),
    })
    local content_sha256, digest_err = digest.sha256(material.content)
    if not content_sha256 then
        return nil, digest_err
    end
    local intent = {
        protocol_version = repository_intent.protocol_version,
        intent_id = nil,
        operation = "create_text_file",
        source_unit_id = unit.id,
        source_unit_version = unit.version,
        source_formation_event_ref = formation.id,
        relative_path = material.relative_path,
        content_ref = {
            unit_id = unit.id,
            unit_version = unit.version,
            selector = "carrier.value.content",
        },
        content_bytes = #material.content,
        content_sha256 = content_sha256,
        scope_refs = scope_refs,
        provenance_refs = provenance_refs,
        event_truth_status = "runtime_confirmed",
        content_truth_status = unit.content_truth_status,
    }
    local intent_digest, intent_err = digest.record(identity_projection(intent))
    if not intent_digest then
        return nil, intent_err
    end
    intent.intent_id = "repository-intent:" .. intent_digest
    return intent
end

function repository_intent.validate(instance, intent)
    local keys_ok, keys_err = validate_keys(intent, intent_keys, "repository intent")
    if not keys_ok then
        return nil, keys_err
    end
    if intent.protocol_version ~= repository_intent.protocol_version
        or intent.operation ~= "create_text_file"
        or type(intent.intent_id) ~= "string" or intent.intent_id == ""
        or type(intent.source_unit_id) ~= "string" or intent.source_unit_id == ""
        or type(intent.source_formation_event_ref) ~= "string"
        or intent.source_formation_event_ref == ""
        or intent.event_truth_status ~= "runtime_confirmed"
        or type(intent.content_truth_status) ~= "string" then
        return nil, "invalid repository intent envelope"
    end
    local _, version_err = positive_integer(intent.source_unit_version, "source unit version")
    if version_err then
        return nil, version_err
    end
    local unit, unit_err = current_unit(instance, intent.source_unit_id)
    if not unit then
        return nil, unit_err
    end
    if unit.version ~= intent.source_unit_version then
        return nil, "repository intent source unit version mismatch"
    end
    if unit.activation ~= "live" and unit.activation ~= "selected" then
        return nil, "repository intent source unit is not active"
    end
    local expected, expected_err = build(instance, unit)
    if not expected then
        return nil, expected_err
    end
    if expected.source_formation_event_ref ~= intent.source_formation_event_ref
        or expected.relative_path ~= intent.relative_path
        or expected.content_bytes ~= intent.content_bytes
        or expected.content_sha256 ~= intent.content_sha256
        or expected.content_truth_status ~= intent.content_truth_status
        or not same_array(expected.scope_refs, intent.scope_refs)
        or not same_array(expected.provenance_refs, intent.provenance_refs) then
        return nil, "repository intent no longer matches current field material"
    end
    local ref_keys_ok, ref_keys_err = validate_keys(
        intent.content_ref,
        content_ref_keys,
        "repository intent content_ref"
    )
    if not ref_keys_ok then
        return nil, ref_keys_err
    end
    if intent.content_ref.unit_id ~= unit.id
        or intent.content_ref.unit_version ~= unit.version
        or intent.content_ref.selector ~= "carrier.value.content" then
        return nil, "repository intent content referent mismatch"
    end
    local scope_refs, scope_err = strict_string_array(
        intent.scope_refs,
        "repository intent scope_refs"
    )
    if not scope_refs then
        return nil, scope_err
    end
    local provenance_refs, provenance_err = strict_string_array(
        intent.provenance_refs,
        "repository intent provenance_refs"
    )
    if not provenance_refs then
        return nil, provenance_err
    end
    local computed_id, computed_err = digest.record(identity_projection(intent))
    if not computed_id then
        return nil, computed_err
    end
    if intent.intent_id ~= "repository-intent:" .. computed_id then
        return nil, "repository intent identity mismatch"
    end
    return true
end

function repository_intent.derive(instance, options)
    options = options or {}
    local max_items = options.max_items or 128
    local _, max_err = positive_integer(max_items, "max_items")
    if max_err then
        return nil, max_err
    end
    local units, units_err = active_units(instance, max_items)
    if not units then
        return nil, units_err
    end
    local intent, intent_err = build(instance, units[1])
    if not intent then
        return nil, intent_err
    end
    local valid, valid_err = repository_intent.validate(instance, intent)
    if not valid then
        return nil, valid_err
    end
    return copy_value(intent)
end

return repository_intent
