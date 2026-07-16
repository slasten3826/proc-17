local packet_core = require("core.packet")
local flow = require("organs.flow")
local observe = require("organs.observe")
local encode = require("organs.encode")
local choose = require("organs.choose")
local body = require("runtime.body")
local manifest = require("logic.manifest")

local runner = {}

local function last_trace_id(instance, event_type)
    for index = #instance.trace, 1, -1 do
        local event = instance.trace[index]
        if event.type == event_type then
            return event.id
        end
    end
    return nil
end

local function stage_error(stage, err)
    return stage .. ":" .. tostring(err)
end

local function move(instance, to, reason)
    return packet_core.commit_transition(instance, {
        kind = "route_decision",
        from = instance.operator,
        to = to,
        reason = reason,
        truth_status = "runtime_confirmed",
    })
end

local function enter_stage(instance, operator, reason)
    if instance.operator ~= operator then
        local moved, move_err = move(instance, operator, reason)
        if not moved then
            return nil, move_err
        end
    end
    return packet_core.begin_tick(instance, operator, {})
end

local function manifest_input(instance, options, observe_payload, choose_payload, cycle_payload)
    local response = observe_payload and observe_payload.response or {}
    local choice_loss = choose_payload and choose_payload.loss or {}
    local cycle_reason = cycle_payload and cycle_payload.reason or nil

    return {
        work_mode = options.work_mode or "build",
        substrate_result = {
            text = response.text or "",
            truth_status = response.truth_status or "semantic_proposal",
        },
        sources = {
            substrate_result_event = observe_payload and observe_payload.trace_event_id or nil,
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

function runner.single_pass(prompt, substrate, options)
    options = options or {}

    local instance = packet_core.new(prompt, options.packet_options or {})

    local result = {
        kind = "runner_single_pass_result",
        packet_id = instance.id,
        stages = {},
        final_status = instance.status,
    }

    local flowed, flow_payload = flow.run(instance)
    if not flowed then
        return nil, stage_error("flow", flow_payload)
    end
    result.stages.flow = flow_payload

    local observe_tick, observe_tick_err = enter_stage(instance, "☴", "single_pass_observe")
    if not observe_tick then
        return nil, stage_error("observe_route", observe_tick_err)
    end

    local observed, observe_payload = observe.run(instance, substrate, {
        work_mode = options.work_mode or "build",
        mode = options.observe_mode or options.mode or "mixed",
        prompt_payload = options.prompt_payload,
        system_prompt = options.system_prompt,
        substrate_options = options.substrate_options,
    })
    if not observed then
        return nil, stage_error("observe", observe_payload)
    end
    result.stages.observe = observe_payload

    local encode_tick, encode_tick_err = enter_stage(instance, "☵", "single_pass_encode")
    if not encode_tick then
        return nil, stage_error("encode_route", encode_tick_err)
    end

    local encoded, encode_payload = encode.run(instance, options.encode or {})
    if not encoded then
        return nil, stage_error("encode", encode_payload)
    end
    result.stages.encode = encode_payload

    local choose_tick, choose_tick_err = enter_stage(instance, "☳", "single_pass_choose")
    if not choose_tick then
        return nil, stage_error("choose_route", choose_tick_err)
    end

    local chosen, choose_payload = choose.run(instance, options.choose or {})
    if not chosen then
        return nil, stage_error("choose", choose_payload)
    end
    result.stages.choose = choose_payload

    local runtime_bridge, runtime_bridge_err = move(instance, "☱", "single_pass_lower_bridge")
    if not runtime_bridge then
        return nil, stage_error("cycle_route", runtime_bridge_err)
    end
    local cycle_tick, cycle_tick_err = enter_stage(instance, "☲", "single_pass_cycle")
    if not cycle_tick then
        return nil, stage_error("cycle_route", cycle_tick_err)
    end

    local cycle_payload, cycle_err = body.decide_cycle(instance, {
        cycle_key = options.cycle_key or instance.id,
        turn_count = options.turn_count or 0,
        max_turns = options.max_turns or 4,
        required_budget = options.required_budget or {steps = 1},
        logic_status = options.logic_status,
        state_fingerprint = options.state_fingerprint,
    })
    if not cycle_payload then
        return nil, stage_error("cycle", cycle_err)
    end
    result.stages.cycle = cycle_payload

    local manifest_payload, manifest_err = manifest.assemble(
        manifest_input(instance, options, observe_payload, choose_payload, cycle_payload)
    )
    if not manifest_payload then
        return nil, stage_error("manifest", manifest_err)
    end
    result.stages.manifest = manifest_payload

    if cycle_payload.decision == "stop_complete" then
        local manifest_tick, manifest_tick_err = enter_stage(instance, "△", "single_pass_manifest")
        if not manifest_tick then
            return nil, stage_error("manifest_route", manifest_tick_err)
        end
        local manifested, manifested_err = packet_core.manifest_packet(instance, manifest_payload, {
            cause = "complete",
            manifest_type = manifest_payload.output and manifest_payload.output.type,
        })
        if not manifested then
            return nil, stage_error("manifest", manifested_err)
        end
    end

    result.final_status = instance.status
    return instance, result
end

return runner
