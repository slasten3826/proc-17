local packet_core = require("core.packet")
local observe = require("organs.observe")
local encode = require("organs.encode")
local choose = require("organs.choose")
local body = require("runtime.body")
local router = require("runtime.router")
local manifest = require("logic.manifest")
local spells = require("logic.spells")
local foundation = require("runtime.foundation")
local freshness = require("runtime.freshness")
local budget = require("runtime.budget")
local loss = require("runtime.loss")
local grave = require("runtime.grave")

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
    local foundation_payload = foundation.snapshot(instance)
    local budget_payload = budget.snapshot(instance)
    local loss_payload = loss.snapshot(instance)
    local _, event = packet_core.measure_tension(instance, {
        operator = "☱",
        kind = "runtime_eye_payload",
        progress = progress,
        foundation = foundation_payload,
        budget_snapshot = budget_payload,
        loss_snapshot = loss_payload,
        truth_status = "runtime_confirmed",
    })
    return {
        kind = "runtime_eye_payload",
        progress = progress,
        foundation = foundation_payload,
        trace_event_id = event.id,
        truth_status = "runtime_confirmed",
    }
end

local function stamp_logic_verdict(instance, verdict)
    instance.runtime = instance.runtime or {}
    instance.runtime.logic_stamp = {
        kind = "logic_stamp",
        verdict = verdict,
        evidence_fingerprint = freshness.evidence_fingerprint(instance),
        stamped_at_tick = instance.physis and instance.physis.clock
            and instance.physis.clock.ticks or nil,
        truth_status = "runtime_confirmed",
    }
    return instance.runtime.logic_stamp
end

local function logic_placeholder(instance, options)
    options = options or {}
    if options.work_mode == "build" then
        local spell_inputs = options.logic and options.logic.spells or {}
        local results = {}
        if type(spell_inputs) ~= "table" or #spell_inputs == 0 then
            local payload = {
                kind = "logic_validation_payload",
                status = "no_spell",
                reason = "build_mode_requires_spell_evidence",
                spell_results = {},
                evidence_count = 0,
                truth_status = "runtime_confirmed",
            }
            stamp_logic_verdict(instance, payload.status)
            body.record_validation(instance, payload)
            return payload
        end

        local status = "accepted"
        for _, spell_input in ipairs(spell_inputs) do
            if spell_input.tick == nil then
                spell_input.tick = instance.physis and instance.physis.clock
                    and instance.physis.clock.ticks or nil
            end
            local result, err = spells.run(spell_input)
            if not result then
                result = {
                    kind = "spell_result",
                    name = spell_input.name or spell_input.kind or "invalid_spell",
                    spell_kind = spell_input.kind or "invalid",
                    intention_hash = spells.hash(spell_input.intention or spell_input.name or spell_input.kind),
                    command_or_code = spell_input.command or spell_input.path or "",
                    executed = false,
                    success = false,
                    reality_changed = false,
                    stdout = "",
                    stderr = tostring(err),
                    exit_code = nil,
                    truth_status = "runtime_confirmed",
                }
            end
            results[#results + 1] = result
            foundation.reinforce(instance, result)
            if result.success ~= true then
                status = "rejected"
            end
        end

        local payload = {
            kind = "logic_validation_payload",
            status = status,
            spell_results = results,
            evidence_count = #results,
            foundation = foundation.snapshot(instance),
            truth_status = "runtime_confirmed",
        }
        stamp_logic_verdict(instance, payload.status)
        body.record_validation(instance, payload)
        return payload
    end

    local payload = {
        kind = "logic_validation_payload",
        status = "accepted",
        reason = "placeholder_v0",
        spell_results = {},
        evidence_count = 0,
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

local function charge_substrate_usage(instance, observe_payload)
    observe_payload = observe_payload or {}
    local response = observe_payload.response or {}
    local call = observe_payload.call or {}

    budget.charge(instance, {
        operator = "☴",
        event_id = observe_payload.trace_event_id,
        cost = {substrate_calls = 1},
        source = "substrate_call",
        truth_status = "runtime_confirmed",
    })

    local usage_cost = budget.from_usage(response.usage or {})
    if next(usage_cost) ~= nil then
        budget.charge(instance, {
            operator = "☴",
            event_id = observe_payload.trace_event_id,
            cost = usage_cost,
            source = "substrate_usage",
            truth_status = "runtime_confirmed",
        })
        return
    end

    local estimated = budget.estimate_tokens((call.prompt_payload or "") .. "\n" .. (response.text or ""))
    if estimated > 0 then
        budget.charge(instance, {
            operator = "☴",
            event_id = observe_payload.trace_event_id,
            cost = {estimated_tokens = estimated},
            source = "local_estimator",
            truth_status = "estimated",
        })
    end
end

local function apply_operator_physics(instance, operator, payload)
    if operator == "☴" then
        charge_substrate_usage(instance, payload)
        return
    end

    if operator == "☵" and type(payload.loss) == "table" then
        loss.apply(instance, {
            operator = "☵",
            event_id = payload.trace_event_id,
            amount = loss.from_encode_loss(payload.loss),
            kind = payload.loss.kind,
            source = "encode_loss",
            detail = payload.loss,
            truth_status = "runtime_confirmed",
        })
        return
    end

    if operator == "☳" and type(payload.loss) == "table" then
        loss.apply(instance, {
            operator = "☳",
            event_id = payload.trace_event_id,
            amount = loss.from_choose_loss(payload.loss),
            kind = payload.loss.kind,
            source = "choice_loss",
            detail = payload.loss,
            truth_status = "runtime_confirmed",
        })
    end
end

local function die_from_mortality(instance, result, current)
    if loss.is_exhausted(instance) then
        packet_core.die(instance, "identity_loss", loss.identity_residue(instance, {
            last_operator = current,
        }))
        result.stop_reason = "identity_loss"
        result.final_status = instance.status
        return true
    end

    local exhausted = budget.is_exhausted(instance)
    if exhausted then
        packet_core.die(instance, "budget_exhausted", budget.exhaustion_residue(instance, {
            last_operator = current,
            progress = body.progress(instance),
        }))
        result.stop_reason = "budget_exhausted"
        result.final_status = instance.status
        return true
    end

    return false
end

local function default_max_ticks(instance)
    local physis = instance and (instance.physis or instance.substrate) or {}
    local configured_budget = physis.budget or {}
    local steps = configured_budget.steps
    if type(steps) == "number" and steps > 0 then
        return steps * 4
    end
    return 256
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
        return logic_placeholder(instance, options)
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
    budget.init(instance)
    loss.init(instance, options.loss or {})

    local result = {
        kind = "tension_runner_result",
        packet_id = instance.id,
        ticks = {},
        routes = {},
        stop_reason = nil,
        final_status = instance.status,
    }

    if options.inherited_graves ~= nil then
        local grave_payload, grave_err = grave.attach(instance, options.inherited_graves)
        if not grave_payload then
            return nil, stage_error("grave", grave_err)
        end
        result.grave = grave_payload
    end

    local current = options.start_operator or "☴"
    local max_ticks = options.max_ticks or default_max_ticks(instance)

    while #result.ticks < max_ticks do
        local payload, err = run_operator(instance, substrate, current, options, result)
        if not payload then
            return nil, stage_error(current, err)
        end

        append_tick(result, current, payload)
        local clock = instance.physis and instance.physis.clock
        if clock then
            clock.ticks = (clock.ticks or 0) + 1
        end
        budget.charge(instance, {
            operator = current,
            cost = {steps = 1},
            source = "body_tick",
            truth_status = "runtime_confirmed",
        })
        apply_operator_physics(instance, current, payload)

        if current == "△" then
            result.stop_reason = "manifested"
            result.final_status = instance.status
            return instance, result
        end

        if die_from_mortality(instance, result, current) then
            return instance, result
        end

        local route, route_err = router.after_tick(instance, {
            operator = current,
            payload = payload,
            work_mode = options.work_mode or "build",
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
