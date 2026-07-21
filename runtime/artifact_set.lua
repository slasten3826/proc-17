local digest = require("core.digest")
local json = require("core.json")
local repository_intent = require("runtime.repository_intent")
local work_completion = require("runtime.work_completion")

local artifact_set = {
    protocol_version = "repository.artifact_set_contract.v0",
    inspection_protocol = "runtime.artifact_set_inspection.v0",
    bounds = {
        max_artifacts = 128,
        max_relative_path_bytes = 1024,
        max_directory_depth = 64,
    },
}

local contract_keys = {
    protocol_version = true,
    artifact_set_id = true,
    packet_id = true,
    lineage_id = true,
    generation = true,
    stage_id = true,
    repository_id = true,
    artifacts = true,
    source_refs = true,
    event_truth_status = true,
    content_truth_status = true,
}

local artifact_keys = {
    work_unit_id = true,
    work_unit_version = true,
    relative_path = true,
    expected_kind = true,
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

local function exact_keys(value, allowed, name)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, name .. " must be a plain table"
    end
    for key in pairs(value) do
        if not allowed[key] then
            return nil, name .. " contains unknown key: " .. tostring(key)
        end
    end
    return true
end

local function non_empty(value, name)
    if type(value) ~= "string" or value == "" then
        return nil, name .. " must be a non-empty string"
    end
    return value
end

local function positive_integer(value, name)
    if type(value) ~= "number" or value < 1 or value ~= math.floor(value) then
        return nil, name .. " must be an integer >= 1"
    end
    return value
end

local function strict_refs(value, name)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, name .. " must be an array"
    end
    local result = {}
    local seen = {}
    for index, ref in ipairs(value) do
        if type(ref) ~= "string" or ref == "" or seen[ref] then
            return nil, name .. " must contain unique non-empty strings"
        end
        seen[ref] = true
        result[index] = ref
    end
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key > #result
            or key ~= math.floor(key) then
            return nil, name .. " must be an array"
        end
    end
    table.sort(result)
    return result
end

local function sorted_unique(values)
    local result = {}
    local seen = {}
    for _, value in ipairs(values or {}) do
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function path_depth(path)
    local count = 0
    for _ in path:gmatch("[^/]+") do
        count = count + 1
    end
    return count
end

local function artifact_less(left, right)
    if left.relative_path ~= right.relative_path then
        return left.relative_path < right.relative_path
    end
    return left.work_unit_id < right.work_unit_id
end

local function normalize_contract(value, require_identity)
    local keys_ok, keys_err = exact_keys(value, contract_keys, "artifact set contract")
    if not keys_ok then
        return nil, keys_err
    end
    if value.protocol_version ~= artifact_set.protocol_version then
        return nil, "unsupported artifact set protocol"
    end
    for _, name in ipairs({"packet_id", "lineage_id", "stage_id", "repository_id"}) do
        local _, value_err = non_empty(value[name], "artifact set " .. name)
        if value_err then
            return nil, value_err
        end
    end
    local _, generation_err = positive_integer(value.generation, "artifact set generation")
    if generation_err then
        return nil, generation_err
    end
    if value.event_truth_status ~= "runtime_confirmed" then
        return nil, "artifact set declaration must be runtime_confirmed"
    end
    if value.content_truth_status ~= "semantic_proposal"
        and value.content_truth_status ~= "mixed" then
        return nil, "artifact set content truth status is invalid"
    end

    local refs, refs_err = strict_refs(value.source_refs, "artifact set source_refs")
    if not refs then
        return nil, refs_err
    end
    if #refs == 0 then
        return nil, "artifact set requires at least one source ref"
    end
    if type(value.artifacts) ~= "table" or getmetatable(value.artifacts) ~= nil then
        return nil, "artifact set artifacts must be an array"
    end
    local artifacts = {}
    local seen_ids = {}
    local seen_paths = {}
    for index, input in ipairs(value.artifacts) do
        if index > artifact_set.bounds.max_artifacts then
            return nil, "artifact set exceeds max_artifacts"
        end
        local artifact_ok, artifact_err = exact_keys(
            input,
            artifact_keys,
            "artifact set artifact"
        )
        if not artifact_ok then
            return nil, artifact_err
        end
        local _, id_err = non_empty(input.work_unit_id, "artifact work_unit_id")
        if id_err then
            return nil, id_err
        end
        local _, version_err = positive_integer(
            input.work_unit_version,
            "artifact work_unit_version"
        )
        if version_err then
            return nil, version_err
        end
        local path, path_err = repository_intent.validate_relative_path(input.relative_path)
        if not path then
            return nil, path_err
        end
        if #path > artifact_set.bounds.max_relative_path_bytes then
            return nil, "artifact relative path exceeds bound"
        end
        if path_depth(path) > artifact_set.bounds.max_directory_depth then
            return nil, "artifact relative path depth exceeds bound"
        end
        if input.expected_kind ~= "regular_file" then
            return nil, "artifact expected_kind must be regular_file"
        end
        if seen_ids[input.work_unit_id] then
            return nil, "duplicate artifact work identity"
        end
        if seen_paths[path] then
            return nil, "duplicate artifact relative path"
        end
        seen_ids[input.work_unit_id] = true
        seen_paths[path] = true
        artifacts[index] = {
            work_unit_id = input.work_unit_id,
            work_unit_version = input.work_unit_version,
            relative_path = path,
            expected_kind = "regular_file",
        }
    end
    for key in pairs(value.artifacts) do
        if type(key) ~= "number" or key < 1 or key > #artifacts
            or key ~= math.floor(key) then
            return nil, "artifact set artifacts must be an array"
        end
    end
    if #artifacts == 0 then
        return nil, "artifact set requires at least one artifact"
    end
    table.sort(artifacts, artifact_less)

    local normalized = {
        protocol_version = artifact_set.protocol_version,
        artifact_set_id = nil,
        packet_id = value.packet_id,
        lineage_id = value.lineage_id,
        generation = value.generation,
        stage_id = value.stage_id,
        repository_id = value.repository_id,
        artifacts = artifacts,
        source_refs = refs,
        event_truth_status = "runtime_confirmed",
        content_truth_status = value.content_truth_status,
    }
    local identity, identity_err = digest.record(normalized)
    if not identity then
        return nil, identity_err
    end
    normalized.artifact_set_id = "artifact-set:" .. identity
    if require_identity and value.artifact_set_id ~= normalized.artifact_set_id then
        return nil, "artifact set identity mismatch"
    end
    return normalized
end

function artifact_set.identify(value)
    local normalized, err = normalize_contract(value, false)
    if not normalized then
        return nil, err
    end
    return normalized.artifact_set_id
end

function artifact_set.validate(value)
    local normalized, err = normalize_contract(value, true)
    if not normalized then
        return nil, err
    end
    return copy_value(normalized)
end

function artifact_set.same(left, right)
    local normalized_left = artifact_set.validate(left)
    local normalized_right = artifact_set.validate(right)
    if not normalized_left or not normalized_right then
        return false
    end
    return json.encode(normalized_left) == json.encode(normalized_right)
end

local function current_repository_units(instance)
    if type(instance) ~= "table" or type(instance.field) ~= "table"
        or type(instance.field.units) ~= "table"
        or type(instance.field.unit_order) ~= "table" then
        return nil, "Packet field is unavailable"
    end
    local result = {}
    for _, id in ipairs(instance.field.unit_order) do
        local unit = instance.field.units[id]
        if type(unit) ~= "table" or unit.id ~= id then
            return nil, "Packet field order invariant failed"
        end
        if unit.generation == instance.generation
            and (unit.activation == "live" or unit.activation == "selected")
            and type(unit.carrier) == "table"
            and unit.carrier.kind == "repository.create_text_file.v0" then
            result[#result + 1] = unit
        end
    end
    return result
end

local function content_status(contract, units)
    local status = contract.content_truth_status
    for _, unit in ipairs(units or {}) do
        local current = unit.content_truth_status or "semantic_proposal"
        if current ~= status then
            return "mixed"
        end
    end
    return status
end

local function inspection_identity(value)
    local seed = copy_value(value)
    seed.inspection_id = nil
    local identity, err = digest.record(seed)
    if not identity then
        return nil, err
    end
    return "artifact-set-inspection:" .. identity
end

function artifact_set.inspect(instance, contract)
    local normalized, contract_err = artifact_set.validate(contract)
    if not normalized then
        return nil, contract_err
    end
    if type(instance) ~= "table" or type(instance.id) ~= "string" then
        return nil, "artifact set inspection requires Packet"
    end
    if normalized.packet_id ~= instance.id
        or normalized.lineage_id ~= instance.lineage_id
        or normalized.generation ~= instance.generation
        or normalized.stage_id ~= instance.stage_id
        or normalized.repository_id ~= instance.repository_id then
        return nil, "artifact set identity is foreign to Packet"
    end

    local current_units, units_err = current_repository_units(instance)
    if not current_units then
        return nil, units_err
    end
    local current_by_id = {}
    for _, unit in ipairs(current_units) do
        current_by_id[unit.id] = unit
    end

    local artifact_records = {}
    local declared_ids = {}
    local completion_refs = {}
    local verification_refs = {}
    local source_refs = copy_value(normalized.source_refs)
    local relevant_versions = {}
    local missing_ids = {}
    local conflicting_refs = {}
    local done_count = 0
    local used_units = {}

    for _, declared in ipairs(normalized.artifacts) do
        declared_ids[declared.work_unit_id] = true
        local unit = current_by_id[declared.work_unit_id]
        local state = "missing"
        local completion_ref
        local verification_ref
        if unit then
            used_units[#used_units + 1] = unit
            relevant_versions[#relevant_versions + 1] = {
                object_kind = "field_unit",
                object_id = unit.id,
                version = unit.version,
                source_ref = unit.created_event_id,
            }
            if unit.version ~= declared.work_unit_version then
                state = "stale"
            elseif type(unit.carrier.value) ~= "table"
                or unit.carrier.value.path ~= declared.relative_path then
                state = "conflict"
                conflicting_refs[#conflicting_refs + 1] = unit.created_event_id
                    or ("field-unit:" .. unit.id)
            else
                local complete, completion_event = work_completion.is_complete(
                    instance,
                    declared.work_unit_id,
                    declared.work_unit_version
                )
                if complete then
                    state = "complete"
                    completion_ref = completion_event.id
                    verification_ref = completion_event.payload.verification_ref
                    completion_refs[#completion_refs + 1] = completion_ref
                    verification_refs[#verification_refs + 1] = verification_ref
                    source_refs[#source_refs + 1] = completion_ref
                    source_refs[#source_refs + 1] = verification_ref
                    done_count = done_count + 1
                else
                    state = "incomplete"
                end
            end
        end
        if state ~= "complete" then
            missing_ids[#missing_ids + 1] = declared.work_unit_id
        end
        artifact_records[#artifact_records + 1] = {
            work_unit_id = declared.work_unit_id,
            work_unit_version = declared.work_unit_version,
            relative_path = declared.relative_path,
            expected_kind = declared.expected_kind,
            state = state,
            completion_ref = completion_ref,
            verification_ref = verification_ref,
        }
    end

    local undeclared = {}
    for _, unit in ipairs(current_units) do
        if not declared_ids[unit.id] then
            undeclared[#undeclared + 1] = {
                work_unit_id = unit.id,
                work_unit_version = unit.version,
                relative_path = type(unit.carrier.value) == "table"
                    and unit.carrier.value.path or nil,
            }
        end
    end
    table.sort(undeclared, function(left, right)
        return tostring(left.relative_path) < tostring(right.relative_path)
    end)
    table.sort(relevant_versions, function(left, right)
        return left.object_id < right.object_id
    end)
    table.sort(missing_ids)
    local remaining_count = #normalized.artifacts - done_count
    local inspection = {
        protocol_version = artifact_set.inspection_protocol,
        inspection_id = nil,
        artifact_set_id = normalized.artifact_set_id,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        stage_id = normalized.stage_id,
        repository_id = normalized.repository_id,
        state = remaining_count == 0 and "complete" or "incomplete",
        needed_count = #normalized.artifacts,
        done_count = done_count,
        remaining_count = remaining_count,
        artifacts = artifact_records,
        completion_refs = sorted_unique(completion_refs),
        verification_refs = sorted_unique(verification_refs),
        undeclared_artifacts = undeclared,
        inventory_compatible = #undeclared == 0,
        source_refs = sorted_unique(source_refs),
        relevant_object_versions = relevant_versions,
        missing_ids = missing_ids,
        conflicting_refs = sorted_unique(conflicting_refs),
        event_truth_status = "runtime_confirmed",
        content_truth_status = content_status(normalized, used_units),
    }
    local inspection_id, inspection_err = inspection_identity(inspection)
    if not inspection_id then
        return nil, inspection_err
    end
    inspection.inspection_id = inspection_id
    return copy_value(inspection)
end

return artifact_set
