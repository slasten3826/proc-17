local digest = require("core.digest")
local repository_intent = require("runtime.repository_intent")

local repository_action = {
    protocol_version = "repository.action.v0",
}

local action_keys = {
    protocol_version = true,
    action_id = true,
    intent_id = true,
    packet_id = true,
    session_id = true,
    lineage_id = true,
    generation = true,
    work_unit = true,
    capability = true,
    operation = true,
    target = true,
    content = true,
    required_budget = true,
    scope_refs = true,
    provenance_refs = true,
    event_truth_status = true,
    content_truth_status = true,
}

local work_unit_keys = {
    id = true,
    version = true,
    formation_event_ref = true,
}

local capability_keys = {
    grant_id = true,
    revision = true,
    repository_id = true,
    provider_id = true,
    root_fingerprint = true,
    policy_digest = true,
}

local target_keys = {
    relative_path = true,
    precondition = true,
}

local content_keys = {
    ref = true,
    bytes = true,
    sha256 = true,
}

local content_ref_keys = {
    unit_id = true,
    unit_version = true,
    selector = true,
}

local budget_keys = {
    tool_calls = true,
    file_writes = true,
}

local context_keys = {
    session_id = true,
    lineage_id = true,
    generation = true,
    repository_id = true,
    work_mode = true,
}

local forbidden_projection_keys = {
    provider = true,
    repository_handle = true,
    root_handle = true,
    host_path = true,
    project_base = true,
    command = true,
    shell = true,
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
        kind = "repository_action_diagnostic",
        protocol_version = "repository.action_diagnostic.v0",
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

local function non_negative_integer(value, name)
    if type(value) ~= "number" or value < 0 or value ~= math.floor(value) then
        return nil, name .. " must be a non-negative integer"
    end
    return value
end

local function non_empty(value, name)
    if type(value) ~= "string" or value == "" then
        return nil, name .. " must be a non-empty string"
    end
    return value
end

local function strict_array(value, name)
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

local function identity_projection(action)
    local value = copy_value(action)
    value.action_id = nil
    return value
end

local function contains_forbidden_projection_key(value, seen)
    if type(value) ~= "table" then
        return false
    end
    seen = seen or {}
    if seen[value] then
        return false
    end
    seen[value] = true
    for key, child in pairs(value) do
        if forbidden_projection_keys[key] then
            return true, key
        end
        local found, found_key = contains_forbidden_projection_key(child, seen)
        if found then
            return true, found_key
        end
    end
    return false
end

function repository_action.validate_projection(action)
    local keys_ok, keys_err = validate_keys(action, action_keys, "repository action")
    if not keys_ok then
        return nil, keys_err
    end
    if action.protocol_version ~= repository_action.protocol_version
        or type(action.action_id) ~= "string" or action.action_id == ""
        or type(action.intent_id) ~= "string" or action.intent_id == ""
        or type(action.packet_id) ~= "string" or action.packet_id == ""
        or type(action.session_id) ~= "string" or action.session_id == ""
        or type(action.lineage_id) ~= "string" or action.lineage_id == ""
        or type(action.generation) ~= "number" or action.generation < 1
        or action.generation ~= math.floor(action.generation)
        or action.operation ~= "create_text_file"
        or action.event_truth_status ~= "runtime_confirmed"
        or type(action.content_truth_status) ~= "string" then
        return nil, "invalid repository action projection"
    end
    for _, spec in ipairs({
        {action.work_unit, work_unit_keys, "repository action work_unit"},
        {action.capability, capability_keys, "repository action capability"},
        {action.target, target_keys, "repository action target"},
        {action.content, content_keys, "repository action content"},
        {action.required_budget, budget_keys, "repository action required_budget"},
    }) do
        local nested_ok, nested_err = validate_keys(spec[1], spec[2], spec[3])
        if not nested_ok then
            return nil, nested_err
        end
    end
    local ref_ok, ref_err = validate_keys(
        action.content and action.content.ref,
        content_ref_keys,
        "repository action content ref"
    )
    if not ref_ok then
        return nil, ref_err
    end
    local forbidden, forbidden_key = contains_forbidden_projection_key(action)
    if forbidden then
        return nil, "repository action projection contains forbidden key: "
            .. tostring(forbidden_key)
    end
    local computed_id, computed_err = digest.record(identity_projection(action))
    if not computed_id then
        return nil, computed_err
    end
    if action.action_id ~= "repository-action:" .. computed_id then
        return nil, "repository action identity mismatch"
    end
    return true
end

local function actual_work_mode(instance)
    return instance and instance.regime and instance.regime.work
        and instance.regime.work.mode
end

local function current_unit(instance, id)
    local unit = instance and instance.field and instance.field.units
        and instance.field.units[id]
    if type(unit) ~= "table" or unit.id ~= id then
        return nil, "repository action work unit is missing"
    end
    return unit
end

local function current_content(unit)
    local carrier = unit and unit.carrier
    local value = carrier and carrier.value
    if type(value) ~= "table" then
        return nil, "repository action content referent is missing"
    end
    return value.content
end

local function projection_has_operation(projection, operation)
    for _, candidate in ipairs(projection.operations or {}) do
        if candidate == operation then
            return true
        end
    end
    return false
end

local function validate_context(instance, context)
    local keys_ok, keys_err = validate_keys(context, context_keys, "repository action context")
    if not keys_ok then
        return nil, keys_err
    end
    for _, name in ipairs({"session_id", "lineage_id", "repository_id", "work_mode"}) do
        local _, value_err = non_empty(context[name], name)
        if value_err then
            return nil, value_err
        end
    end
    local _, generation_err = positive_integer(context.generation, "generation")
    if generation_err then
        return nil, generation_err
    end
    if context.session_id ~= instance.session_id
        or context.lineage_id ~= instance.lineage_id
        or context.generation ~= instance.generation then
        return nil, "repository action context does not match Packet identity"
    end
    local mode = actual_work_mode(instance)
    if context.work_mode ~= mode then
        return nil, "repository action work mode does not match Packet"
    end
    return true
end

function repository_action.validate(instance, action)
    local projection_ok, projection_err = repository_action.validate_projection(action)
    if not projection_ok then
        return nil, projection_err
    end
    if action.protocol_version ~= repository_action.protocol_version
        or action.operation ~= "create_text_file"
        or action.event_truth_status ~= "runtime_confirmed"
        or type(action.content_truth_status) ~= "string"
        or type(action.action_id) ~= "string" or action.action_id == ""
        or type(action.intent_id) ~= "string" or action.intent_id == "" then
        return nil, "invalid repository action envelope"
    end
    for _, name in ipairs({"packet_id", "session_id", "lineage_id"}) do
        local _, value_err = non_empty(action[name], "action " .. name)
        if value_err then
            return nil, value_err
        end
    end
    local _, generation_err = positive_integer(action.generation, "action generation")
    if generation_err then
        return nil, generation_err
    end
    if action.packet_id ~= instance.id or action.session_id ~= instance.session_id
        or action.lineage_id ~= instance.lineage_id
        or action.generation ~= instance.generation then
        return nil, "repository action Packet identity mismatch"
    end
    local work_ok, work_err = validate_keys(action.work_unit, work_unit_keys, "action work_unit")
    if not work_ok then
        return nil, work_err
    end
    local _, work_id_err = non_empty(action.work_unit.id, "work unit id")
    if work_id_err then
        return nil, work_id_err
    end
    local _, work_version_err = positive_integer(action.work_unit.version, "work unit version")
    if work_version_err then
        return nil, work_version_err
    end
    local _, formation_err = non_empty(
        action.work_unit.formation_event_ref,
        "formation event ref"
    )
    if formation_err then
        return nil, formation_err
    end
    local unit, unit_err = current_unit(instance, action.work_unit.id)
    if not unit then
        return nil, unit_err
    end
    if unit.version ~= action.work_unit.version then
        return nil, "repository action work unit version mismatch"
    end
    if unit.activation ~= "live" and unit.activation ~= "selected" then
        return nil, "repository action work unit is not active"
    end
    local capability_ok, capability_err = validate_keys(
        action.capability,
        capability_keys,
        "action capability"
    )
    if not capability_ok then
        return nil, capability_err
    end
    for _, name in ipairs({
        "grant_id",
        "repository_id",
        "provider_id",
        "root_fingerprint",
        "policy_digest",
    }) do
        local _, value_err = non_empty(action.capability[name], "capability " .. name)
        if value_err then
            return nil, value_err
        end
    end
    local _, revision_err = positive_integer(action.capability.revision, "grant revision")
    if revision_err then
        return nil, revision_err
    end
    local target_ok, target_err = validate_keys(action.target, target_keys, "action target")
    if not target_ok then
        return nil, target_err
    end
    if action.target.precondition ~= "absent" then
        return nil, "repository action target must require absence"
    end
    local _, path_err = repository_intent.validate_relative_path(action.target.relative_path)
    if path_err then
        return nil, path_err
    end
    local content_ok, content_err = validate_keys(action.content, content_keys, "action content")
    if not content_ok then
        return nil, content_err
    end
    local ref_ok, ref_err = validate_keys(action.content.ref, content_ref_keys, "action content ref")
    if not ref_ok then
        return nil, ref_err
    end
    if action.content.ref.unit_id ~= action.work_unit.id
        or action.content.ref.unit_version ~= action.work_unit.version
        or action.content.ref.selector ~= "carrier.value.content" then
        return nil, "repository action content referent mismatch"
    end
    local _, bytes_err = non_negative_integer(action.content.bytes, "action content bytes")
    if bytes_err then
        return nil, bytes_err
    end
    if type(action.content.sha256) ~= "string" or #action.content.sha256 ~= 64 then
        return nil, "repository action content digest is invalid"
    end
    local budget_ok, budget_err = validate_keys(
        action.required_budget,
        budget_keys,
        "action required_budget"
    )
    if not budget_ok then
        return nil, budget_err
    end
    if action.required_budget.tool_calls ~= 2 or action.required_budget.file_writes ~= 1 then
        return nil, "repository action required budget mismatch"
    end
    local scope_refs, scope_err = strict_array(action.scope_refs, "action scope_refs")
    if not scope_refs then
        return nil, scope_err
    end
    local provenance_refs, provenance_err = strict_array(
        action.provenance_refs,
        "action provenance_refs"
    )
    if not provenance_refs then
        return nil, provenance_err
    end
    local current_intent, current_err = repository_intent.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    })
    if not current_intent then
        local code = type(current_err) == "table" and current_err.code or current_err
        return nil, "repository action current intent unavailable: " .. tostring(code)
    end
    if current_intent.intent_id ~= action.intent_id
        or current_intent.source_unit_id ~= action.work_unit.id
        or current_intent.source_unit_version ~= action.work_unit.version
        or current_intent.source_formation_event_ref ~= action.work_unit.formation_event_ref
        or current_intent.relative_path ~= action.target.relative_path
        or current_intent.content_bytes ~= action.content.bytes
        or current_intent.content_sha256 ~= action.content.sha256
        or current_intent.content_truth_status ~= action.content_truth_status
        or not same_array(current_intent.scope_refs, scope_refs)
        or not same_array(current_intent.provenance_refs, provenance_refs) then
        return nil, "repository action does not match current intent"
    end
    local content = current_content(unit)
    local valid_content, valid_content_err = repository_intent.validate_text_content(content)
    if not valid_content then
        return nil, valid_content_err
    end
    if #content ~= action.content.bytes
        or digest.sha256(content) ~= action.content.sha256 then
        return nil, "repository action content digest mismatch"
    end
    local computed_id, computed_err = digest.record(identity_projection(action))
    if not computed_id then
        return nil, computed_err
    end
    if action.action_id ~= "repository-action:" .. computed_id then
        return nil, "repository action identity mismatch"
    end
    return true
end

function repository_action.authorize(instance, intent, registry, context)
    if type(instance) ~= "table" then
        return nil, "Packet instance is required"
    end
    if instance.status == "dead" or instance.status == "dying"
        or instance.status == "manifested" then
        return nil, diagnostic("terminal_packet_cannot_authorize")
    end
    local context_ok, context_err = validate_context(instance, context or {})
    if not context_ok then
        return nil, context_err
    end
    if context.work_mode == "plan" then
        return nil, diagnostic("plan_mode_forbids_repository_effect")
    end
    if context.work_mode ~= "build" then
        return nil, "unsupported repository action work mode"
    end
    local intent_ok, intent_err = repository_intent.validate(instance, intent)
    if not intent_ok then
        return nil, intent_err
    end
    local capabilities = require("runtime.repository_capability")
    local match, match_err = capabilities.resolve(registry, {
        session_id = context.session_id,
        lineage_id = context.lineage_id,
        generation = context.generation,
        repository_id = context.repository_id,
        operation = intent.operation,
    })
    if not match then
        return nil, match_err
    end
    if match.state ~= "active" or not projection_has_operation(match, intent.operation) then
        return nil, diagnostic("missing_capability")
    end
    if #intent.relative_path > match.bounds.max_relative_path_bytes
        or intent.content_bytes > match.bounds.max_content_bytes then
        return nil, diagnostic("capability_bounds_exceeded")
    end
    local action = {
        protocol_version = repository_action.protocol_version,
        action_id = nil,
        intent_id = intent.intent_id,
        packet_id = instance.id,
        session_id = instance.session_id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        work_unit = {
            id = intent.source_unit_id,
            version = intent.source_unit_version,
            formation_event_ref = intent.source_formation_event_ref,
        },
        capability = {
            grant_id = match.grant_id,
            revision = match.revision,
            repository_id = match.repository_id,
            provider_id = match.provider_id,
            root_fingerprint = match.root_fingerprint,
            policy_digest = match.policy_digest,
        },
        operation = intent.operation,
        target = {
            relative_path = intent.relative_path,
            precondition = "absent",
        },
        content = {
            ref = copy_value(intent.content_ref),
            bytes = intent.content_bytes,
            sha256 = intent.content_sha256,
        },
        required_budget = {
            tool_calls = 2,
            file_writes = 1,
        },
        scope_refs = copy_value(intent.scope_refs),
        provenance_refs = copy_value(intent.provenance_refs),
        event_truth_status = "runtime_confirmed",
        content_truth_status = intent.content_truth_status,
    }
    local action_digest, action_err = digest.record(identity_projection(action))
    if not action_digest then
        return nil, action_err
    end
    action.action_id = "repository-action:" .. action_digest
    local action_ok, action_validation_err = repository_action.validate(instance, action)
    if not action_ok then
        return nil, action_validation_err
    end
    return copy_value(action)
end

function repository_action.materialize(instance, action, registry)
    local valid, valid_err = repository_action.validate(instance, action)
    if not valid then
        return nil, valid_err
    end
    local capabilities = require("runtime.repository_capability")
    local match, match_err = capabilities.resolve(registry, {
        session_id = action.session_id,
        lineage_id = action.lineage_id,
        generation = action.generation,
        repository_id = action.capability.repository_id,
        operation = action.operation,
    })
    if not match then
        return nil, match_err
    end
    if match.grant_id ~= action.capability.grant_id
        or match.revision ~= action.capability.revision
        or match.provider_id ~= action.capability.provider_id
        or match.root_fingerprint ~= action.capability.root_fingerprint
        or match.policy_digest ~= action.capability.policy_digest then
        return nil, "repository action grant revision or identity mismatch"
    end
    local unit = assert(current_unit(instance, action.work_unit.id))
    local content = current_content(unit)
    local content_ok, content_err = repository_intent.validate_text_content(content)
    if not content_ok then
        return nil, content_err
    end
    local content_sha256, digest_err = digest.sha256(content)
    if not content_sha256 then
        return nil, digest_err
    end
    if #action.target.relative_path > match.bounds.max_relative_path_bytes
        or #content > match.bounds.max_content_bytes then
        return nil, "repository action exceeds current grant bounds"
    end
    if #content ~= action.content.bytes or content_sha256 ~= action.content.sha256 then
        return nil, "repository action materialized content mismatch"
    end
    return {
        protocol_version = "repository.create_text_file.request.v0",
        action_id = action.action_id,
        grant_id = match.grant_id,
        grant_revision = match.revision,
        root_fingerprint = match.root_fingerprint,
        relative_path = action.target.relative_path,
        content = content,
        content_bytes = #content,
        content_sha256 = content_sha256,
        precondition = "absent",
    }, copy_value(match)
end

return repository_action
