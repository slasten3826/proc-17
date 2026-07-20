local digest = require("core.digest")
local packet_core = require("core.packet")
local repository_action = require("runtime.repository_action")

local work_completion = {
    protocol_version = "runtime.work_completion.v0",
}

local completion_keys = {
    protocol_version = true, completion_id = true, work_unit_id = true,
    work_unit_version = true, formation_event_ref = true, action_id = true,
    attempt_ref = true, receipt_ref = true, verification_ref = true,
    validation_ref = true, completed_status = true, completed_by = true,
    source_refs = true, event_truth_status = true, content_truth_status = true,
}
local input_keys = {
    action = true, attempt_ref = true, receipt_ref = true,
    verification_ref = true, validation_ref = true,
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

local function strict_ref_array(value)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return false
    end
    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            return false
        end
        count = count + 1
    end
    if count ~= #value then
        return false
    end
    for _, ref in ipairs(value) do
        if type(ref) ~= "string" or ref == "" then
            return false
        end
    end
    return true
end

local function trace_event(instance, event_id)
    for index, event in ipairs(instance and instance.trace or {}) do
        if event.id == event_id then
            return event, index
        end
    end
    return nil
end

local function current_repository_unit(instance, id, version)
    local unit = instance and instance.field and instance.field.units
        and instance.field.units[id]
    if type(unit) ~= "table" or unit.id ~= id
        or type(unit.carrier) ~= "table"
        or unit.carrier.kind ~= "repository.create_text_file.v0" then
        return nil, "repository work unit is not current"
    end
    if unit.version ~= version then
        return nil, "repository work unit version changed"
    end
    if unit.activation ~= "live" and unit.activation ~= "selected" then
        return nil, "repository work unit is not active"
    end
    return unit
end

local function formation_matches(instance, formation_ref, unit_id, version)
    local event = trace_event(instance, formation_ref)
    local payload = event and event.payload
    if not event or event.type ~= "structure_formation" or type(payload) ~= "table"
        or payload.protocol_version ~= "field.structure_formation.v0"
        or type(payload.formed_unit_ids) ~= "table"
        or type(payload.formed_unit_versions) ~= "table"
        or type(payload.formed_unit_versions[unit_id]) ~= "number"
        or payload.formed_unit_versions[unit_id] > version then
        return false
    end
    for _, id in ipairs(payload.formed_unit_ids) do
        if id == unit_id then
            return true
        end
    end
    return false
end

local function later_conflict(instance, action_id, evidence)
    for index = evidence.attempt_index + 1, #(instance.trace or {}) do
        local event = instance.trace[index]
        local payload = event.payload or {}
        if index ~= evidence.receipt_index and index ~= evidence.verification_index
            and index ~= evidence.validation_index then
            if event.type == "repository_effect_attempt"
                and payload.action_id == action_id then
                return "repository completion has a later conflicting attempt"
            end
            if event.type == "repository_verification"
                and payload.action_id == action_id then
                return "repository completion has a later conflicting verification"
            end
            if event.type == "validation" and payload.action_id == action_id
                and payload.mode == "repository_effect" then
                return "repository completion has a later conflicting validation"
            end
        end
    end
    return nil
end

local function chain(instance, refs)
    local attempt, attempt_index = trace_event(instance, refs.attempt_ref)
    local receipt, receipt_index = trace_event(instance, refs.receipt_ref)
    local verification, verification_index = trace_event(instance, refs.verification_ref)
    local validation, validation_index = trace_event(instance, refs.validation_ref)
    if not attempt or not receipt or not verification or not validation then
        return nil, "repository completion evidence ref is missing"
    end
    if attempt.type ~= "repository_effect_attempt"
        or receipt.type ~= "repository_effect_receipt"
        or verification.type ~= "repository_verification"
        or validation.type ~= "validation" then
        return nil, "repository completion evidence type mismatch"
    end
    if not (attempt_index < receipt_index and receipt_index < verification_index
        and verification_index < validation_index) then
        return nil, "repository completion evidence order mismatch"
    end
    return {
        attempt = attempt,
        receipt = receipt,
        verification = verification,
        validation = validation,
        attempt_index = attempt_index,
        receipt_index = receipt_index,
        verification_index = verification_index,
        validation_index = validation_index,
    }
end

local function validate_chain(instance, action, refs)
    local evidence, evidence_err = chain(instance, refs)
    if not evidence then
        return nil, evidence_err
    end
    local attempt = evidence.attempt.payload or {}
    local receipt = evidence.receipt.payload or {}
    local verification = evidence.verification.payload or {}
    local validation = evidence.validation.payload or {}
    if attempt.action_id ~= action.action_id
        or attempt.work_unit_id ~= action.work_unit.id
        or attempt.work_unit_version ~= action.work_unit.version
        or attempt.grant_id ~= action.capability.grant_id
        or attempt.grant_revision ~= action.capability.revision then
        return nil, "repository completion attempt does not match work action"
    end
    if receipt.action_id ~= action.action_id
        or receipt.attempt_id ~= attempt.attempt_id
        or receipt.grant_id ~= action.capability.grant_id
        or receipt.grant_revision ~= action.capability.revision then
        return nil, "repository completion receipt does not match work action"
    end
    if verification.action_id ~= action.action_id
        or verification.attempt_id ~= attempt.attempt_id
        or verification.receipt_ref ~= evidence.receipt.id
        or verification.grant_id ~= action.capability.grant_id
        or verification.grant_revision ~= action.capability.revision
        or verification.verdict ~= "accepted"
        or type(verification.expected) ~= "table"
        or verification.expected.bytes ~= action.content.bytes
        or verification.expected.sha256 ~= action.content.sha256 then
        return nil, "repository completion verification is not accepted exact evidence"
    end
    if validation.mode ~= "repository_effect" or validation.status ~= "accepted"
        or validation.action_id ~= action.action_id
        or validation.attempt_ref ~= evidence.attempt.id
        or validation.receipt_ref ~= evidence.receipt.id
        or validation.verification_ref ~= evidence.verification.id
        or validation.evidence_count ~= 1
        or not same_array(validation.effect_scope_refs,
            repository_action.route_scope(action))
        or validation.truth_status ~= "runtime_confirmed"
        or evidence.validation.truth_status ~= "runtime_confirmed" then
        return nil, "repository completion LOGIC validation is not accepted exact evidence"
    end
    local conflict = later_conflict(instance, action.action_id, evidence)
    if conflict then
        return nil, conflict
    end
    return evidence
end

local function latest_action_validation(instance, action_id)
    for index = #(instance and instance.trace or {}), 1, -1 do
        local event = instance.trace[index]
        local payload = event and event.payload or nil
        if event.type == "validation" and event.operator == "☶"
            and event.truth_status == "runtime_confirmed"
            and type(payload) == "table"
            and payload.mode == "repository_effect"
            and payload.action_id == action_id then
            return event, payload
        end
    end
    return nil
end

local function completion_seed(value)
    local seed = copy_value(value)
    seed.completion_id = nil
    return seed
end

local function validate_candidate(instance, value)
    local keys_ok, keys_err = exact_keys(value, completion_keys, "work completion")
    if not keys_ok then
        return nil, keys_err
    end
    if value.protocol_version ~= work_completion.protocol_version
        or type(value.completion_id) ~= "string" or value.completion_id == ""
        or type(value.work_unit_id) ~= "string" or value.work_unit_id == ""
        or type(value.work_unit_version) ~= "number" or value.work_unit_version < 1
        or value.work_unit_version ~= math.floor(value.work_unit_version)
        or type(value.formation_event_ref) ~= "string" or value.formation_event_ref == ""
        or type(value.action_id) ~= "string" or value.action_id == ""
        or value.completed_status ~= "done" or value.completed_by ~= "☱"
        or value.event_truth_status ~= "runtime_confirmed"
        or type(value.content_truth_status) ~= "string" or value.content_truth_status == ""
        or not strict_ref_array(value.source_refs) then
        return nil, "invalid work completion envelope"
    end
    for _, ref_key in ipairs({"attempt_ref", "receipt_ref", "verification_ref",
        "validation_ref"}) do
        if type(value[ref_key]) ~= "string" or value[ref_key] == "" then
            return nil, "invalid work completion " .. ref_key
        end
    end
    local unit, unit_err = current_repository_unit(instance,
        value.work_unit_id, value.work_unit_version)
    if not unit then
        return nil, unit_err
    end
    if not formation_matches(instance, value.formation_event_ref,
        value.work_unit_id, value.work_unit_version) then
        return nil, "work completion formation ref mismatch"
    end
    local evidence, evidence_err = chain(instance, value)
    if not evidence then
        return nil, evidence_err
    end
    local attempt = evidence.attempt.payload or {}
    local receipt = evidence.receipt.payload or {}
    local verification = evidence.verification.payload or {}
    local validation = evidence.validation.payload or {}
    if attempt.action_id ~= value.action_id
        or attempt.work_unit_id ~= value.work_unit_id
        or attempt.work_unit_version ~= value.work_unit_version
        or receipt.action_id ~= value.action_id
        or receipt.attempt_id ~= attempt.attempt_id
        or receipt.grant_id ~= attempt.grant_id
        or receipt.grant_revision ~= attempt.grant_revision
        or verification.action_id ~= value.action_id
        or verification.attempt_id ~= attempt.attempt_id
        or verification.receipt_ref ~= evidence.receipt.id
        or verification.grant_id ~= attempt.grant_id
        or verification.grant_revision ~= attempt.grant_revision
        or verification.provider_id ~= receipt.provider_id
        or verification.verdict ~= "accepted"
        or validation.mode ~= "repository_effect" or validation.status ~= "accepted"
        or validation.action_id ~= value.action_id
        or validation.attempt_ref ~= evidence.attempt.id
        or validation.receipt_ref ~= evidence.receipt.id
        or validation.verification_ref ~= evidence.verification.id
        or validation.evidence_count ~= 1
        or validation.truth_status ~= "runtime_confirmed"
        or evidence.attempt.truth_status ~= "runtime_confirmed"
        or evidence.receipt.truth_status ~= "runtime_confirmed"
        or evidence.verification.truth_status ~= "runtime_confirmed"
        or evidence.validation.truth_status ~= "runtime_confirmed"
        or not same_array(value.source_refs, {
            value.formation_event_ref,
            value.action_id,
            value.attempt_ref,
            value.receipt_ref,
            value.verification_ref,
            value.validation_ref,
        }) then
        return nil, "work completion evidence chain mismatch"
    end
    local conflict = later_conflict(instance, value.action_id, evidence)
    if conflict then
        return nil, conflict
    end
    local identity, identity_err = digest.record(completion_seed(value))
    if not identity then
        return nil, identity_err
    end
    if value.completion_id ~= "work-completion:" .. identity then
        return nil, "work completion identity mismatch"
    end
    return true
end

function work_completion.is_complete(instance, unit_id, version)
    for _, event in ipairs(instance and instance.trace or {}) do
        local payload = event.payload
        if event.type == "work_completion" and event.operator == "☱"
            and event.truth_status == "runtime_confirmed"
            and type(payload) == "table"
            and payload.protocol_version == work_completion.protocol_version
            and payload.work_unit_id == unit_id
            and payload.work_unit_version == version
            and payload.completed_status == "done" then
            local valid = validate_candidate(instance, payload)
            if valid then
                return true, copy_value(event)
            end
        end
    end
    return false
end

function work_completion.inspect(instance, action)
    local action_ok, action_err = repository_action.validate(instance, action)
    if not action_ok then
        return nil, action_err
    end
    local completed, completion_event = work_completion.is_complete(
        instance,
        action.work_unit.id,
        action.work_unit.version
    )
    if completed then
        return {
            state = "completed",
            action_id = action.action_id,
            completion_ref = completion_event.id,
            evidence_refs = {completion_event.id},
            event_truth_status = "runtime_confirmed",
        }
    end

    local validation_event, validation = latest_action_validation(
        instance,
        action.action_id
    )
    if not validation_event then
        return {
            state = "effect_evidence_absent",
            action_id = action.action_id,
            evidence_refs = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    if validation.status ~= "accepted" then
        return {
            state = "verification_rejected",
            action_id = action.action_id,
            validation_ref = validation_event.id,
            evidence_refs = {validation_event.id},
            event_truth_status = "runtime_confirmed",
        }
    end

    local input = {
        action = copy_value(action),
        attempt_ref = validation.attempt_ref,
        receipt_ref = validation.receipt_ref,
        verification_ref = validation.verification_ref,
        validation_ref = validation_event.id,
    }
    local evidence, evidence_err = validate_chain(instance, action, input)
    if not evidence then
        return nil, evidence_err
    end
    local refs = {
        input.attempt_ref,
        input.receipt_ref,
        input.verification_ref,
        input.validation_ref,
    }
    table.sort(refs)
    return {
        state = "completion_ready",
        action_id = action.action_id,
        input = input,
        evidence_refs = refs,
        event_truth_status = "runtime_confirmed",
    }
end

function work_completion.derive(instance, input)
    local actor, actor_err = packet_core.assert_actor_tick(instance, "☱",
        "derive work completion")
    if not actor then
        return nil, actor_err
    end
    local input_ok, input_err = exact_keys(input, input_keys,
        "repository completion input")
    if not input_ok then
        return nil, input_err
    end
    local action = input.action
    if type(action) ~= "table" or type(action.work_unit) ~= "table" then
        return nil, "repository completion work action is required"
    end
    local unit, unit_err = current_repository_unit(instance,
        action.work_unit.id, action.work_unit.version)
    if not unit then
        return nil, unit_err
    end
    local action_ok, action_err = repository_action.validate(instance, action)
    if not action_ok then
        return nil, action_err
    end
    if work_completion.is_complete(instance, action.work_unit.id,
        action.work_unit.version) then
        return nil, "repository work is already complete"
    end
    local refs = {
        attempt_ref = input.attempt_ref,
        receipt_ref = input.receipt_ref,
        verification_ref = input.verification_ref,
        validation_ref = input.validation_ref,
    }
    local evidence, evidence_err = validate_chain(instance, action, refs)
    if not evidence then
        return nil, evidence_err
    end
    local candidate = {
        protocol_version = work_completion.protocol_version,
        completion_id = nil,
        work_unit_id = action.work_unit.id,
        work_unit_version = action.work_unit.version,
        formation_event_ref = action.work_unit.formation_event_ref,
        action_id = action.action_id,
        attempt_ref = evidence.attempt.id,
        receipt_ref = evidence.receipt.id,
        verification_ref = evidence.verification.id,
        validation_ref = evidence.validation.id,
        completed_status = "done",
        completed_by = "☱",
        source_refs = {
            action.work_unit.formation_event_ref,
            action.action_id,
            evidence.attempt.id,
            evidence.receipt.id,
            evidence.verification.id,
            evidence.validation.id,
        },
        event_truth_status = "runtime_confirmed",
        content_truth_status = action.content_truth_status,
    }
    local identity, identity_err = digest.record(completion_seed(candidate))
    if not identity then
        return nil, identity_err
    end
    candidate.completion_id = "work-completion:" .. identity
    return copy_value(candidate)
end

function work_completion.record(instance, candidate)
    if work_completion.is_complete(instance,
        candidate and candidate.work_unit_id,
        candidate and candidate.work_unit_version) then
        return nil, "repository work is already complete"
    end
    local valid, valid_err = validate_candidate(instance, candidate)
    if not valid then
        return nil, valid_err
    end
    local body = require("runtime.body")
    local record, event_or_err = body.record_work_completion(instance, candidate)
    if not record then
        return nil, event_or_err
    end
    return copy_value(record), event_or_err
end

function work_completion.repository_progress(instance)
    local needed, done, remaining = {}, {}, {}
    for _, id in ipairs(instance and instance.field and instance.field.unit_order or {}) do
        local unit = instance.field.units[id]
        if type(unit) == "table" and type(unit.carrier) == "table"
            and unit.carrier.kind == "repository.create_text_file.v0"
            and unit.generation == instance.generation
            and (unit.activation == "live" or unit.activation == "selected") then
            needed[#needed + 1] = id
            if work_completion.is_complete(instance, id, unit.version) then
                done[#done + 1] = id
            else
                remaining[#remaining + 1] = id
            end
        end
    end
    return {
        needed_count = #needed,
        done_count = #done,
        remaining_count = #remaining,
        needed = needed,
        done = done,
        remaining = remaining,
        event_truth_status = "runtime_confirmed",
    }
end

return work_completion
