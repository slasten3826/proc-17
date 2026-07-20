local packet_core = require("core.packet")
local json = require("core.json")
local manifest_logic = require("logic.manifest")
local plan_completion = require("runtime.plan_completion")
local repository_result = require("runtime.repository_result")

local manifest_organ = {}

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

local function same_value(left, right)
    return json.encode(left) == json.encode(right)
end

local function sorted_unique(values)
    local seen = {}
    local result = {}
    for _, value in ipairs(values or {}) do
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function plan_delivery(instance, options)
    local input = options and options.plan_input
    if type(input) ~= "table" then
        return nil, "plan delivery input required"
    end
    local assessment, candidate_or_err = plan_completion.resolve_assessment(
        instance,
        input
    )
    if not assessment then
        return nil, candidate_or_err
    end
    local candidate = candidate_or_err
    local scope_refs = copy_value(candidate.scope_refs)
    scope_refs[#scope_refs + 1] = assessment.event.id
    scope_refs = sorted_unique(scope_refs)
    local action_scope = options.qualified_action and options.qualified_action.scope_refs
    if action_scope ~= nil and not same_value(action_scope, scope_refs) then
        return nil, "plan delivery action scope mismatch"
    end
    local projected, residue, sources = plan_completion.project(
        instance,
        assessment,
        candidate
    )
    if not projected then
        return nil, residue
    end
    return {
        assessment = assessment,
        candidate = candidate,
        projected = projected,
        residue = residue,
        sources = sources,
        scope_refs = scope_refs,
    }
end

local function repository_delivery(instance, options)
    local input = options and options.repository_result
    if type(input) ~= "table" then
        return nil, "repository result input required"
    end
    local action_scope = options.qualified_action
        and options.qualified_action.scope_refs or nil
    return repository_result.delivery(instance, input, action_scope)
end

local function last_trace_event(instance, event_type, operator)
    for index = #(instance.trace or {}), 1, -1 do
        local event = instance.trace[index]
        if event.type == event_type and (operator == nil or event.operator == operator) then
            return event
        end
    end
    return nil
end

local function last_trace_id(instance, event_type)
    local event = last_trace_event(instance, event_type)
    return event and event.id or nil
end

local function last_payload(result, operator)
    for index = #(result and result.ticks or {}), 1, -1 do
        local tick = result.ticks[index]
        if tick.operator == operator then
            return tick.payload
        end
    end
    return nil
end

function manifest_organ.input(instance, options)
    options = options or {}
    local result = options.result or {ticks = {}}
    local observation_event = last_trace_event(instance, "observation", "☴")
    local observation_record = observation_event and observation_event.payload or {}
    local observation_payload = observation_record.payload or {}
    local observe_payload = last_payload(result, "☴") or {}
    local response = observation_payload.response or observe_payload.response or {}
    local choice_event = last_trace_event(instance, "choice", "☳")
    local choose_payload = choice_event and choice_event.payload or last_payload(result, "☳")
    local cycle_event = last_trace_event(instance, "cycle", "☲")
    local cycle_payload = cycle_event and cycle_event.payload or last_payload(result, "☲")
    local validation_event = last_trace_event(instance, "validation", "☶")
    local validation_payload = validation_event and validation_event.payload or nil
    local reconciliation_event = last_trace_event(instance, "runtime_reconciliation", "☱")
    local reconciliation_payload = reconciliation_event and reconciliation_event.payload or nil
    local choice_loss = choose_payload and choose_payload.loss or {}
    local cycle_reason = cycle_payload and cycle_payload.reason or nil
    local birth_event = last_trace_event(instance, "birth", "▽")
    local relation_snapshot_event = last_trace_event(instance, "relation_snapshot", "☰")
    local relation_formation_event = last_trace_event(instance, "relation_formation", "☵")

    return {
        work_mode = options.work_mode or "build",
        substrate_result = {
            text = response.text or "",
            truth_status = response.truth_status or "semantic_proposal",
        },
        sources = {
            birth_event = birth_event and birth_event.id,
            flow_domain_event = birth_event and birth_event.payload
                and birth_event.payload.flow_mark
                and birth_event.payload.flow_mark.domain_event_ref,
            raw_relation_event = relation_snapshot_event and relation_snapshot_event.id,
            relation_formation_event = relation_formation_event
                and relation_formation_event.id,
            substrate_result_event = observation_event and observation_event.id
                or observe_payload.trace_event_id,
            encoded_field_event = last_trace_id(instance, "crystallization"),
            choice_event = choice_event and choice_event.id,
            cycle_event = cycle_event and cycle_event.id,
            validation_event = validation_event and validation_event.id,
            runtime_reconciliation_event = reconciliation_event and reconciliation_event.id,
        },
        choose_context = choose_payload and {
            selected_count = #(choose_payload.selected or {}),
            not_chosen_count = choose_payload.not_chosen_count,
            loss_kind = choice_loss.kind,
            last_choice_event = last_trace_id(instance, "choice"),
        } or nil,
        cycle_context = cycle_payload and {
            last_cycle_decision = cycle_payload.decision,
            last_cycle_reasons = cycle_reason and {cycle_reason} or {},
            repeated_fingerprint = cycle_payload.reason == "state_fingerprint",
            turn_budget_pressure = cycle_payload.decision == "stop_budget" and "cannot_pay" or "payable",
        } or nil,
        logic_context = validation_payload and {
            accepted_count = validation_payload.status == "accepted" and 1 or 0,
            rejected_count = validation_payload.status == "rejected" and 1 or 0,
            rejection_reasons = validation_payload.status == "rejected"
                and {validation_payload.reason or "validation_rejected"} or {},
            last_validation_event = validation_event.id,
        } or nil,
        runtime_context = reconciliation_payload and {
            completion_state = reconciliation_payload.completion_state,
            reconciliation_event = reconciliation_event.id,
            event_truth_status = reconciliation_event.truth_status,
        } or nil,
        input_provenance = observation_event and "packet_trace" or "harness_compatibility",
    }
end

function manifest_organ.readiness(instance, options)
    options = options or {}
    if options.repository_result ~= nil then
        local delivery, delivery_err = repository_delivery(instance, options)
        if not delivery then
            return {
                operator = "△",
                ready = false,
                reason = delivery_err,
                source_refs = {},
                required_capabilities = {},
                missing_capabilities = {},
                event_truth_status = "runtime_confirmed",
            }
        end
        return {
            operator = "△",
            ready = true,
            reason = "repository_delivery_ready",
            source_refs = copy_value(delivery.effect_scope_refs),
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    if options.plan_input ~= nil then
        local delivery, delivery_err = plan_delivery(instance, options)
        if not delivery then
            return {
                operator = "△",
                ready = false,
                reason = delivery_err,
                source_refs = {},
                required_capabilities = {},
                missing_capabilities = {},
                event_truth_status = "runtime_confirmed",
            }
        end
        return {
            operator = "△",
            ready = true,
            reason = "plan_delivery_ready",
            source_refs = delivery.scope_refs,
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    local input = manifest_organ.input(instance, options)
    local source_refs = {}
    for _, ref in pairs(input.sources or {}) do
        if type(ref) == "string" then
            source_refs[#source_refs + 1] = ref
        end
    end
    table.sort(source_refs)
    return {
        operator = "△",
        ready = input.substrate_result.text ~= "" or #source_refs > 0,
        reason = (input.substrate_result.text ~= "" or #source_refs > 0)
            and "ready" or "nothing_manifestable",
        source_refs = source_refs,
        required_capabilities = {},
        missing_capabilities = {},
        event_truth_status = "runtime_confirmed",
    }
end

function manifest_organ.run(instance, options)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "assemble manifest")
    if not mutable then
        return nil, mutable_err
    end
    options = options or {}
    if options.repository_result ~= nil then
        local delivery, delivery_err = repository_delivery(instance, options)
        if not delivery then
            return nil, delivery_err
        end
        return instance, delivery
    end
    if options.plan_input ~= nil then
        local delivery, delivery_err = plan_delivery(instance, options)
        if not delivery then
            return nil, delivery_err
        end
        local item_count = #(delivery.projected.items or {})
        local suppressed_count = #(delivery.residue.suppressed_items or {})
        return instance, {
            kind = "manifest_payload",
            mode = "plan_delivery",
            output = {
                type = "plan",
                text = json.encode(delivery.projected),
                structured = delivery.projected,
                status = "complete",
                content_truth_status = delivery.candidate.source_truth_status,
            },
            sources = delivery.sources,
            assembly = {
                rule = "plan_delivery.v0",
                work_mode = "plan",
                input_provenance = "packet_state",
                outcome = "complete",
                assessment_ref = delivery.assessment.event.id,
            },
            residue = delivery.residue,
            summary = {
                type = "plan",
                status = "complete",
                item_count = item_count,
                suppressed_count = suppressed_count,
                source_event = delivery.assessment.event.id,
            },
            terminal_cause = "complete",
            truth_status = "runtime_confirmed",
            content_truth_status = delivery.candidate.source_truth_status,
            effect_scope_refs = delivery.scope_refs,
        }
    end
    local payload, err = manifest_logic.assemble(manifest_organ.input(instance, options))
    if not payload then
        return nil, err
    end
    return instance, payload
end

return manifest_organ
