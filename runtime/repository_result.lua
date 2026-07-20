local digest = require("core.digest")
local json = require("core.json")
local repository_action = require("runtime.repository_action")
local work_completion = require("runtime.work_completion")

local repository_result = {
    protocol_version = "repository.result.v0",
    consumer_id = "manifest.repository_result.v0",
}

local input_keys = {
    action = true,
    action_id = true,
    work_unit_id = true,
    work_unit_version = true,
    formation_event_ref = true,
    grant_id = true,
    grant_revision = true,
    evidence_refs = true,
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
    return result
end

local function same_value(left, right)
    return json.encode(left) == json.encode(right)
end

local function trace_event(instance, event_id)
    for _, event in ipairs(instance and instance.trace or {}) do
        if event.id == event_id then
            return event
        end
    end
    return nil
end

function repository_result.scope(action, completion_ref)
    if type(completion_ref) ~= "string" or completion_ref == "" then
        return nil, "repository delivery completion ref is required"
    end
    local scope, scope_err = repository_action.route_scope(action)
    if not scope then
        return nil, scope_err
    end
    for _, ref in ipairs(scope) do
        if ref == completion_ref then
            return nil, "repository delivery completion ref aliases action scope"
        end
    end
    scope[#scope + 1] = completion_ref
    table.sort(scope)
    return scope
end

function repository_result.resolve(instance, input)
    if type(instance) ~= "table" then
        return nil, "Packet instance is required"
    end
    local input_ok, input_err = exact_keys(input, input_keys,
        "repository result input")
    if not input_ok then
        return nil, input_err
    end
    local action = input.action
    local action_ok, action_err = repository_action.validate(instance, action)
    if not action_ok then
        return nil, action_err
    end
    if input.action_id ~= action.action_id
        or input.work_unit_id ~= action.work_unit.id
        or input.work_unit_version ~= action.work_unit.version
        or input.formation_event_ref ~= action.work_unit.formation_event_ref
        or input.grant_id ~= action.capability.grant_id
        or input.grant_revision ~= action.capability.revision then
        return nil, "repository result input identity mismatch"
    end
    local refs, refs_err = strict_refs(input.evidence_refs,
        "repository result evidence_refs")
    if not refs then
        return nil, refs_err
    end
    if #refs ~= 1 then
        return nil, "repository result requires exactly one completion ref"
    end

    local complete, completion_event = work_completion.is_complete(
        instance,
        action.work_unit.id,
        action.work_unit.version
    )
    if not complete or type(completion_event) ~= "table" then
        return nil, "repository work completion is absent or stale"
    end
    if completion_event.id ~= refs[1]
        or completion_event.type ~= "work_completion"
        or completion_event.operator ~= "☱"
        or completion_event.truth_status ~= "runtime_confirmed" then
        return nil, "repository result completion ref mismatch"
    end
    local completion = completion_event.payload or {}
    if completion.action_id ~= action.action_id
        or completion.work_unit_id ~= action.work_unit.id
        or completion.work_unit_version ~= action.work_unit.version
        or completion.formation_event_ref ~= action.work_unit.formation_event_ref
        or completion.completed_status ~= "done"
        or completion.completed_by ~= "☱"
        or completion.content_truth_status ~= action.content_truth_status then
        return nil, "repository result completion identity mismatch"
    end

    local verification_event = trace_event(instance, completion.verification_ref)
    local verification = verification_event and verification_event.payload or nil
    if not verification_event or verification_event.type ~= "repository_verification"
        or verification_event.operator ~= "☶"
        or verification_event.truth_status ~= "runtime_confirmed"
        or type(verification) ~= "table"
        or verification.action_id ~= action.action_id
        or verification.verdict ~= "accepted"
        or verification.reason ~= "exact_content_observed"
        or verification.grant_id ~= action.capability.grant_id
        or verification.grant_revision ~= action.capability.revision
        or verification.provider_id ~= action.capability.provider_id
        or type(verification.target) ~= "table"
        or verification.target.relative_path ~= action.target.relative_path
        or verification.target.kind ~= "regular_file"
        or type(verification.observed) ~= "table"
        or verification.observed.bytes ~= action.content.bytes
        or verification.observed.sha256 ~= action.content.sha256
        or type(verification.expected) ~= "table"
        or verification.expected.bytes ~= action.content.bytes
        or verification.expected.sha256 ~= action.content.sha256 then
        return nil, "repository result verification mismatch"
    end

    local progress = work_completion.repository_progress(instance)
    if progress.needed_count ~= 1 or progress.done_count ~= 1
        or progress.remaining_count ~= 0 or progress.done[1] ~= action.work_unit.id then
        return nil, "repository result v0 requires one completed active artifact"
    end

    local scope, scope_err = repository_result.scope(action, completion_event.id)
    if not scope then
        return nil, scope_err
    end
    return {
        action = copy_value(action),
        completion_event = copy_value(completion_event),
        completion = copy_value(completion),
        verification_event = copy_value(verification_event),
        verification = copy_value(verification),
        progress = copy_value(progress),
        scope_refs = scope,
    }
end

function repository_result.project(instance, resolved)
    if type(resolved) ~= "table" or type(resolved.action) ~= "table"
        or type(resolved.completion_event) ~= "table"
        or type(resolved.verification) ~= "table" then
        return nil, "resolved repository result is required"
    end
    local action = resolved.action
    local completion = resolved.completion
    local verification = resolved.verification
    local projection = {
        protocol_version = repository_result.protocol_version,
        result_id = nil,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        status = "complete",
        repository_id = action.capability.repository_id,
        artifacts = {{
            work_unit_id = action.work_unit.id,
            work_unit_version = action.work_unit.version,
            action_id = action.action_id,
            operation = action.operation,
            relative_path = action.target.relative_path,
            outcome = "created",
            target_kind = verification.target.kind,
            bytes = verification.observed.bytes,
            sha256 = verification.observed.sha256,
            verification_ref = resolved.verification_event.id,
            completion_ref = resolved.completion_event.id,
        }},
        event_truth_status = "runtime_confirmed",
        content_truth_status = completion.content_truth_status,
    }
    local seed = copy_value(projection)
    seed.result_id = nil
    local identity, identity_err = digest.record(seed)
    if not identity then
        return nil, identity_err
    end
    projection.result_id = "repository-result:" .. identity
    local sources = {
        structure_formation_event = completion.formation_event_ref,
        repository_effect_attempt_event = completion.attempt_ref,
        repository_effect_receipt_event = completion.receipt_ref,
        repository_verification_event = completion.verification_ref,
        logic_validation_event = completion.validation_ref,
        work_completion_event = resolved.completion_event.id,
    }
    local residue = {
        cause = "complete",
        manifest_type = "repository",
        completed_work_count = resolved.progress.done_count,
        remaining_work_count = resolved.progress.remaining_count,
        action_id = action.action_id,
        completion_ref = resolved.completion_event.id,
    }
    return projection, residue, sources
end

function repository_result.delivery(instance, input, expected_scope)
    local resolved, resolved_err = repository_result.resolve(instance, input)
    if not resolved then
        return nil, resolved_err
    end
    if expected_scope ~= nil and not same_value(expected_scope, resolved.scope_refs) then
        return nil, "repository delivery action scope mismatch"
    end
    local projected, residue, sources = repository_result.project(instance, resolved)
    if not projected then
        return nil, residue
    end
    local completion_ref = resolved.completion_event.id
    local content_truth_status = resolved.action.content_truth_status
    return {
        kind = "manifest_payload",
        mode = "repository_delivery",
        action_id = resolved.action.action_id,
        output = {
            type = "repository",
            text = json.encode(projected),
            structured = projected,
            status = "complete",
            content_truth_status = content_truth_status,
        },
        sources = sources,
        assembly = {
            rule = "repository_delivery.v0",
            work_mode = "build",
            input_provenance = "packet_state",
            outcome = "complete",
            completion_ref = completion_ref,
        },
        residue = residue,
        summary = {
            type = "repository",
            status = "complete",
            artifact_count = 1,
            created_count = 1,
            source_event = completion_ref,
        },
        terminal_cause = "complete",
        truth_status = "runtime_confirmed",
        content_truth_status = content_truth_status,
        effect_scope_refs = copy_value(resolved.scope_refs),
    }
end

function repository_result.verify_delivery_effect(instance, plan, payload)
    local input = plan and plan.options and plan.options.manifest
        and plan.options.manifest.repository_result
    if type(input) ~= "table" or type(payload) ~= "table" then
        return nil, "repository delivery effect input is missing"
    end
    local expected, expected_err = repository_result.delivery(
        instance,
        input,
        plan.scope_refs
    )
    if not expected then
        return nil, expected_err
    end
    if not same_value(payload, expected) then
        return nil, "repository delivery projection mismatch"
    end
    return true
end

return repository_result
