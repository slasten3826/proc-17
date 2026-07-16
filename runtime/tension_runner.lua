local packet_core = require("core.packet")
local operator_registry = require("runtime.operator_registry")
local body = require("runtime.body")
local router = require("runtime.router")
local edge_stats = require("runtime.edge_stats")
local budget = require("runtime.budget")
local loss = require("runtime.loss")
local grave = require("runtime.grave")

local tension_runner = {}

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

local function note_stats_error(result, err)
    result.edge_stats_errors = result.edge_stats_errors or {}
    result.edge_stats_errors[#result.edge_stats_errors + 1] = tostring(err)
end

local function finish_measurements(result)
    local summary, err = edge_stats.summary(result.edge_stats)
    if summary then
        result.edge_evidence = summary
    else
        note_stats_error(result, err)
    end
end

local function operator_context(substrate, options, result)
    return {
        substrate = substrate,
        options = options,
        result = result,
    }
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

function tension_runner.run(prompt, substrate, options)
    options = options or {}

    local instance = packet_core.new(prompt, options.packet_options or {})
    local budget_ready, budget_err = budget.init(instance)
    if not budget_ready then
        return nil, stage_error("budget", budget_err)
    end
    local loss_ready, loss_err = loss.init(instance, options.loss or {})
    if not loss_ready then
        return nil, stage_error("loss", loss_err)
    end

    local result = {
        kind = "tension_runner_result",
        packet_id = instance.id,
        ticks = {},
        routes = {},
        shadow_routes = {},
        edge_stats = edge_stats.new({
            work_mode = options.work_mode or "build",
            router_mode = options.router_mode or "shadow",
        }),
        router_mode = options.router_mode or "shadow",
        stop_reason = nil,
        final_status = instance.status,
    }

    local flow_payload, flow_err, flow_readiness = operator_registry.run(
        "▽",
        instance,
        operator_context(substrate, options, result)
    )
    if not flow_payload then
        return nil, stage_error("flow", flow_err)
    end
    result.flow = flow_payload
    result.flow_readiness = flow_readiness

    if options.inherited_graves ~= nil then
        local grave_payload, grave_err = grave.attach(instance, options.inherited_graves)
        if not grave_payload then
            return nil, stage_error("grave", grave_err)
        end
        result.grave = grave_payload
    end

    local start_operator = options.start_operator or "☴"
    local entry_decision = {
        kind = "route_decision",
        from = instance.operator,
        to = start_operator,
        reason = "runner_entry",
        truth_status = "runtime_confirmed",
    }
    local entry_event, entry_err = packet_core.commit_transition(instance, entry_decision)
    if not entry_event then
        return nil, stage_error("entry", entry_err)
    end
    entry_decision.trace_event_id = entry_event.id
    result.entry_route = entry_decision
    result.final_status = instance.status
    local entry_stats, entry_stats_err = edge_stats.record_transition(result.edge_stats, entry_decision)
    if not entry_stats then
        note_stats_error(result, entry_stats_err)
    end

    local current = instance.operator
    local max_ticks = options.max_ticks or default_max_ticks(instance)
    local pending_arrival = entry_decision

    while #result.ticks < max_ticks do
        local tick_event, tick_err = packet_core.begin_tick(instance, current, {})
        if not tick_event then
            return nil, stage_error("tick", tick_err)
        end
        local payload, err, readiness = operator_registry.run(
            current,
            instance,
            operator_context(substrate, options, result)
        )
        if not payload then
            return nil, stage_error(current, err)
        end

        local result_tick = append_tick(result, current, payload)
        result_tick.trace_event_id = tick_event.id
        result_tick.readiness = readiness
        result_tick.registry = operator_registry.protocol_version
        if pending_arrival then
            local arrival, arrival_err = edge_stats.record_arrival(
                result.edge_stats,
                pending_arrival,
                payload
            )
            if not arrival then
                note_stats_error(result, arrival_err)
            end
            pending_arrival = nil
        end
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
            local manifested, manifest_err = packet_core.manifest_packet(instance, payload, {
                cause = "complete",
                manifest_type = payload.output and payload.output.type,
            })
            if not manifested then
                return nil, stage_error("manifest", manifest_err)
            end
            result.stop_reason = "manifested"
            result.final_status = instance.status
            finish_measurements(result)
            return instance, result
        end

        if die_from_mortality(instance, result, current) then
            finish_measurements(result)
            return instance, result
        end

        local route, route_err = router.after_tick(instance, {
            operator = current,
            payload = payload,
            work_mode = options.work_mode or "build",
        }, {
            mode = options.router_mode or "shadow",
            substrate = substrate,
            capabilities = options.capabilities,
            options = options,
            result = result,
            tree = options.tree_router,
        })
        if not route then
            return nil, stage_error("router", route_err)
        end

        if route.shadow then
            result.shadow_routes[#result.shadow_routes + 1] = route.shadow
            local recorded_stats, stats_err = edge_stats.record(result.edge_stats, route.shadow)
            if not recorded_stats then
                note_stats_error(result, stats_err)
            end
        end

        local route_event, commit_err = packet_core.commit_transition(instance, route)
        if not route_event then
            return nil, stage_error("route", commit_err)
        end
        route.trace_event_id = route_event.id
        result.routes[#result.routes + 1] = route
        local transition_stats, transition_stats_err = edge_stats.record_transition(result.edge_stats, route)
        if not transition_stats then
            note_stats_error(result, transition_stats_err)
        end
        pending_arrival = route
        current = instance.operator
    end

    result.stop_reason = "tick_limit"
    result.final_status = instance.status
    finish_measurements(result)
    return instance, result
end

return tension_runner
