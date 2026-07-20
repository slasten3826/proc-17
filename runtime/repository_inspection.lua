local budget = require("runtime.budget")
local digest = require("core.digest")
local packet_core = require("core.packet")
local repository_action = require("runtime.repository_action")
local repository_intent = require("runtime.repository_intent")
local work_completion = require("runtime.work_completion")

local inspection = {
    protocol_version = "repository.phase_inspection.v0",
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

local function diagnostic_code(value)
    return type(value) == "table" and value.code or nil
end

local function normal_absence(value)
    local code = diagnostic_code(value)
    return code == "repository_intent_absent"
        or code == "multi_item_scheduling_deferred"
        or code == "repository_inspection_truncated"
        or code == "missing_capability"
        or code == "revoked_capability"
        or code == "quarantined_capability"
        or code == "ambiguous_capability"
        or code == "capability_bounds_exceeded"
        or code == "plan_mode_forbids_repository_effect"
end

local function hand_context(instance, options)
    options = options or {}
    local configured = options.repository_hands
    if configured == nil or configured == false then
        return {enabled = false}
    end
    local valid, valid_err = exact_keys(configured, {
        protocol_version = true,
        enabled = true,
        repository_id = true,
    }, "repository hands config")
    if not valid then
        return nil, valid_err
    end
    if configured.protocol_version ~= "repository.hands.config.v0"
        or type(configured.enabled) ~= "boolean"
        or type(configured.repository_id) ~= "string"
        or configured.repository_id == "" then
        return nil, "invalid repository hands config"
    end
    if configured.enabled ~= true then
        return {enabled = false}
    end
    local services = options.host_services
    local registry = type(services) == "table"
        and services.repository_capabilities or nil
    if type(registry) ~= "table" then
        return {
            enabled = true,
            available = false,
            reason = "repository_capability_registry_absent",
        }
    end
    return {
        enabled = true,
        available = true,
        repository_id = configured.repository_id,
        registry = registry,
        action_context = {
            session_id = instance.session_id,
            lineage_id = instance.lineage_id,
            generation = instance.generation,
            repository_id = configured.repository_id,
            work_mode = options.work_mode or (instance.regime and instance.regime.work
                and instance.regime.work.mode) or "build",
        },
    }
end

local function latest_review(instance, action)
    for index = #(instance.trace or {}), 1, -1 do
        local event = instance.trace[index]
        local payload = event and event.payload or nil
        if event.type == "repository_action_review"
            and event.operator == "☱"
            and event.truth_status == "runtime_confirmed"
            and type(payload) == "table"
            and payload.protocol_version == "runtime.repository_action_review.v0"
            and payload.action_id == action.action_id
            and payload.work_unit_id == action.work_unit.id
            and payload.work_unit_version == action.work_unit.version
            and payload.capability_grant_id == action.capability.grant_id
            and payload.capability_revision == action.capability.revision
            and payload.verdict == "actionable" then
            return copy_value(event)
        end
    end
    return nil
end

local function latest_attempt(instance, action)
    for index = #(instance.trace or {}), 1, -1 do
        local event = instance.trace[index]
        local payload = event and event.payload or nil
        if event.type == "repository_effect_attempt"
            and event.operator == "☶"
            and event.truth_status == "runtime_confirmed"
            and type(payload) == "table"
            and payload.action_id == action.action_id
            and payload.work_unit_id == action.work_unit.id
            and payload.work_unit_version == action.work_unit.version then
            return copy_value(event)
        end
    end
    return nil
end

local function selected_source(instance, action)
    local unit = instance.field and instance.field.units
        and instance.field.units[action.work_unit.id]
    local source = unit and unit.activation_source or nil
    if unit and unit.activation == "selected" and type(source) == "table"
        and source.actor == "☳" and type(source.event_id) == "string" then
        return source.event_id
    end
    return nil
end

local function repository_input(action, evidence_refs)
    return {
        action = copy_value(action),
        action_id = action.action_id,
        work_unit_id = action.work_unit.id,
        work_unit_version = action.work_unit.version,
        formation_event_ref = action.work_unit.formation_event_ref,
        grant_id = action.capability.grant_id,
        grant_revision = action.capability.revision,
        evidence_refs = copy_value(evidence_refs or {}),
    }
end

local function same_refs(left, right)
    if type(left) ~= "table" or type(right) ~= "table" or #left ~= #right then
        return false
    end
    local a = copy_value(left)
    local b = copy_value(right)
    table.sort(a)
    table.sort(b)
    for index, value in ipairs(a) do
        if b[index] ~= value then
            return false
        end
    end
    return true
end

function inspection.derive(instance, options)
    if type(instance) ~= "table" then
        return nil, "Packet instance is required"
    end
    local context, context_err = hand_context(instance, options)
    if not context then
        return nil, context_err
    end
    if not context.enabled then
        return {
            protocol_version = inspection.protocol_version,
            enabled = false,
            phase = "disabled",
            diagnostics = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    if not context.available then
        return {
            protocol_version = inspection.protocol_version,
            enabled = true,
            phase = "authorization_missing",
            reason = context.reason,
            diagnostics = {},
            event_truth_status = "runtime_confirmed",
        }
    end

    local intent, intent_err = repository_intent.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    })
    if not intent then
        if normal_absence(intent_err) then
            return {
                protocol_version = inspection.protocol_version,
                enabled = true,
                phase = diagnostic_code(intent_err) or "intent_absent",
                diagnostics = {},
                event_truth_status = "runtime_confirmed",
            }
        end
        if type(intent_err) == "table" then
            return {
                protocol_version = inspection.protocol_version,
                enabled = true,
                phase = "intent_rejected",
                diagnostics = {copy_value(intent_err)},
                event_truth_status = "runtime_confirmed",
            }
        end
        return nil, intent_err
    end

    local action, action_err = repository_action.authorize(
        instance,
        intent,
        context.registry,
        context.action_context
    )
    if not action then
        if normal_absence(action_err) then
            return {
                protocol_version = inspection.protocol_version,
                enabled = true,
                phase = diagnostic_code(action_err) or "authorization_missing",
                diagnostics = {},
                event_truth_status = "runtime_confirmed",
            }
        end
        if type(action_err) == "table" then
            return {
                protocol_version = inspection.protocol_version,
                enabled = true,
                phase = "authorization_rejected",
                diagnostics = {copy_value(action_err)},
                event_truth_status = "runtime_confirmed",
            }
        end
        return nil, action_err
    end

    local route_scope, scope_err = repository_action.route_scope(action)
    if not route_scope then
        return nil, scope_err
    end
    local affordable, missing_or_err = budget.can_pay(
        instance,
        action.required_budget
    )
    if affordable == nil then
        return nil, missing_or_err
    end
    local review = latest_review(instance, action)
    local attempt = latest_attempt(instance, action)
    local completion, completion_err = work_completion.inspect(instance, action)
    if not completion then
        return nil, completion_err
    end
    local selected_event_ref = selected_source(instance, action)
    local phase = "review_needed"
    local evidence_refs = {}
    if completion.state == "completed" then
        phase = "completed"
        evidence_refs = copy_value(completion.evidence_refs)
    elseif completion.state == "completion_ready" then
        phase = "reconcile_needed"
        evidence_refs = copy_value(completion.evidence_refs)
    elseif completion.state == "verification_rejected" then
        phase = "verification_rejected"
        evidence_refs = copy_value(completion.evidence_refs)
    elseif attempt then
        phase = "effect_pending"
        evidence_refs = {attempt.id}
    elseif selected_event_ref then
        phase = affordable and "effect_needed" or "effect_unaffordable"
        evidence_refs = {selected_event_ref}
    elseif review then
        phase = affordable and "effect_needed" or "effect_unaffordable"
        evidence_refs = {review.id}
    elseif not affordable then
        phase = "review_unaffordable"
    end

    return {
        protocol_version = inspection.protocol_version,
        enabled = true,
        phase = phase,
        action = copy_value(action),
        action_input = repository_input(action, evidence_refs),
        route_scope_refs = route_scope,
        provenance_refs = copy_value(action.provenance_refs),
        review = review,
        attempt = attempt,
        completion = completion,
        selected_event_ref = selected_event_ref,
        affordable = affordable,
        missing_budget_axes = copy_value(missing_or_err or {}),
        diagnostics = {},
        event_truth_status = "runtime_confirmed",
    }
end

function inspection.validate_action_input(instance, input, options)
    if type(input) ~= "table" or type(input.action) ~= "table" then
        return nil, "repository action input is required"
    end
    local supplied_ok, supplied_err = repository_action.validate(
        instance,
        input.action
    )
    if not supplied_ok then
        return nil, supplied_err
    end
    local current, current_err = inspection.derive(instance, options)
    if not current then
        return nil, current_err
    end
    if type(current.action) ~= "table"
        or current.action.action_id ~= input.action_id
        or input.action.action_id ~= input.action_id
        or current.action.work_unit.id ~= input.work_unit_id
        or current.action.work_unit.version ~= input.work_unit_version
        or current.action.work_unit.formation_event_ref ~= input.formation_event_ref
        or current.action.capability.grant_id ~= input.grant_id
        or current.action.capability.revision ~= input.grant_revision then
        return nil, "repository action input is stale or mismatched"
    end
    return current
end

function inspection.review_candidate(instance, input, options)
    local current, current_err = inspection.validate_action_input(
        instance,
        input,
        options
    )
    if not current then
        return nil, current_err
    end
    if current.phase ~= "review_needed"
        or type(input.evidence_refs) ~= "table" or #input.evidence_refs ~= 0 then
        return nil, "repository action is not awaiting review"
    end
    local actor, actor_err = packet_core.assert_actor_tick(
        instance,
        "☱",
        "build repository action review"
    )
    if not actor then
        return nil, actor_err
    end
    local source_refs = copy_value(current.provenance_refs)
    source_refs[#source_refs + 1] = actor.id
    local review = {
        protocol_version = "runtime.repository_action_review.v0",
        review_id = nil,
        action_id = current.action.action_id,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        work_unit_id = current.action.work_unit.id,
        work_unit_version = current.action.work_unit.version,
        capability_grant_id = current.action.capability.grant_id,
        capability_revision = current.action.capability.revision,
        verdict = "actionable",
        reason = "exact_action_affordable",
        scope_refs = copy_value(current.route_scope_refs),
        source_refs = source_refs,
        event_truth_status = "runtime_confirmed",
        content_truth_status = current.action.content_truth_status,
    }
    local seed = copy_value(review)
    seed.review_id = nil
    local identity, identity_err = digest.record(seed)
    if not identity then
        return nil, identity_err
    end
    review.review_id = "repository-action-review:" .. identity
    return review, current
end

function inspection.effect_candidate(instance, input, options)
    local current, current_err = inspection.validate_action_input(
        instance,
        input,
        options
    )
    if not current then
        return nil, current_err
    end
    if current.phase ~= "effect_needed"
        or not same_refs(input.evidence_refs, current.action_input.evidence_refs) then
        return nil, "repository action is not awaiting exact effect"
    end
    return current
end

function inspection.reconcile_candidate(instance, input, options)
    local current, current_err = inspection.validate_action_input(
        instance,
        input,
        options
    )
    if not current then
        return nil, current_err
    end
    if current.phase ~= "reconcile_needed"
        or not same_refs(input.evidence_refs, current.completion.evidence_refs) then
        return nil, "repository action is not awaiting exact reconciliation"
    end
    return copy_value(current.completion.input), current
end

inspection.repository_input = repository_input

return inspection
