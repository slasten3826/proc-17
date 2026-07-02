local packet_core = require("core.packet")
local observe = require("organs.observe")
local encode = require("organs.encode")
local choose = require("organs.choose")
local body = require("runtime.body")
local router = require("runtime.router")
local manifest = require("logic.manifest")

local tension_runner = {}

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

local function append_tick(result, operator, payload)
    local tick = {
        index = #result.ticks + 1,
        operator = operator,
        payload = payload,
    }
    result.ticks[#result.ticks + 1] = tick
    return tick
end

local function last_payload(result, operator)
    for index = #result.ticks, 1, -1 do
        local tick = result.ticks[index]
        if tick.operator == operator then
            return tick.payload
        end
    end
    return nil
end

local function manifest_input(instance, options, result)
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

local function runtime_eye(instance)
    local progress = body.progress(instance)
    local _, event = packet_core.measure_tension(instance, {
        operator = "☱",
        kind = "runtime_eye_payload",
        progress = progress,
        budget = instance.substrate and instance.substrate.budget or {},
        loss = {
            records_count = #(instance.boundary and instance.boundary.loss_records or {}),
            current = instance.tension and instance.tension.loss or nil,
            remaining = instance.tension and instance.tension.loss_remaining or nil,
            near_death = instance.tension and instance.tension.loss_near_death == true,
            exhausted = instance.tension and instance.tension.loss_exhausted == true,
        },
        truth_status = "runtime_confirmed",
    })
    return {
        kind = "runtime_eye_payload",
        progress = progress,
        trace_event_id = event.id,
        truth_status = "runtime_confirmed",
    }
end

local function logic_placeholder(instance)
    local payload = {
        kind = "logic_validation_payload",
        status = "accepted",
        reason = "placeholder_v0",
        truth_status = "runtime_confirmed",
    }
    body.record_validation(instance, payload)
    return payload
end

local function manifest_packet(instance, options, result)
    local payload, err = manifest.assemble(manifest_input(instance, options, result))
    if not payload then
        return nil, err
    end
    packet_core.manifest_packet(instance, payload)
    packet_core.die(instance, "complete", {
        cause = "complete",
        manifest_type = payload.output and payload.output.type,
    })
    return payload
end

local function run_operator(instance, substrate, operator, options, result)
    if operator == "☴" then
        local ok, payload_or_err = observe.run(instance, substrate, {
            work_mode = options.work_mode or "build",
            mode = options.observe_mode or options.mode or "mixed",
            prompt_payload = options.prompt_payload,
            system_prompt = options.system_prompt,
            substrate_options = options.substrate_options,
        })
        if not ok then
            return nil, payload_or_err
        end
        return payload_or_err
    end

    if operator == "☵" then
        local ok, payload_or_err = encode.run(instance, options.encode or {})
        if not ok then
            return nil, payload_or_err
        end
        return payload_or_err
    end

    if operator == "☳" then
        local ok, payload_or_err = choose.run(instance, options.choose or {})
        if not ok then
            return nil, payload_or_err
        end
        return payload_or_err
    end

    if operator == "☱" then
        return runtime_eye(instance)
    end

    if operator == "☲" then
        return body.decide_cycle(instance, {
            cycle_key = options.cycle_key or instance.id,
            turn_count = options.turn_count or #result.ticks,
            max_turns = options.max_turns or options.max_ticks or 12,
            required_budget = options.required_budget or {steps = 1},
            logic_status = options.logic_status,
            state_fingerprint = options.state_fingerprint,
        })
    end

    if operator == "☶" then
        return logic_placeholder(instance)
    end

    if operator == "△" then
        return manifest_packet(instance, options, result)
    end

    return nil, "unsupported_operator"
end

function tension_runner.run(prompt, substrate, options)
    options = options or {}

    local instance = packet_core.new(prompt, options.packet_options or {})
    instance.status = "running"

    local result = {
        kind = "tension_runner_result",
        packet_id = instance.id,
        ticks = {},
        routes = {},
        stop_reason = nil,
        final_status = instance.status,
    }

    local current = options.start_operator or "☴"
    local max_ticks = options.max_ticks or 12

    while #result.ticks < max_ticks do
        local payload, err = run_operator(instance, substrate, current, options, result)
        if not payload then
            return nil, stage_error(current, err)
        end

        append_tick(result, current, payload)

        if current == "△" then
            result.stop_reason = "manifested"
            result.final_status = instance.status
            return instance, result
        end

        local route, route_err = router.after_tick(instance, {
            operator = current,
            payload = payload,
        })
        if not route then
            return nil, stage_error("router", route_err)
        end

        result.routes[#result.routes + 1] = route
        current = route.to
    end

    result.stop_reason = "tick_limit"
    result.final_status = instance.status
    return instance, result
end

return tension_runner
