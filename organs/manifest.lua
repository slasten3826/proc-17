local packet_core = require("core.packet")
local manifest_logic = require("logic.manifest")

local manifest_organ = {}

local function last_trace_id(instance, event_type)
    for index = #(instance.trace or {}), 1, -1 do
        local event = instance.trace[index]
        if event.type == event_type then
            return event.id
        end
    end
    return nil
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
    local observe_payload = last_payload(result, "☴") or {}
    local choose_payload = last_payload(result, "☳")
    local cycle_payload = last_payload(result, "☲")
    local response = observe_payload.response or {}
    local choice_loss = choose_payload and choose_payload.loss or {}
    local cycle_reason = cycle_payload and cycle_payload.reason or nil

    return {
        work_mode = options.work_mode or "build",
        substrate_result = {
            text = response.text or "",
            truth_status = response.truth_status or "semantic_proposal",
        },
        sources = {
            substrate_result_event = observe_payload.trace_event_id,
            encoded_field_event = last_trace_id(instance, "crystallization"),
            choice_event = last_trace_id(instance, "choice"),
            cycle_event = last_trace_id(instance, "cycle"),
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
    }
end

function manifest_organ.readiness(instance, options)
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
    local payload, err = manifest_logic.assemble(manifest_organ.input(instance, options))
    if not payload then
        return nil, err
    end
    return instance, payload
end

return manifest_organ
