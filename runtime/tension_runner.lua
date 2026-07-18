local packet_core = require("core.packet")
local packet_birth = require("runtime.packet_birth")
local operator_registry = require("runtime.operator_registry")
local body = require("runtime.body")
local router = require("runtime.router")
local edge_stats = require("runtime.edge_stats")
local budget = require("runtime.budget")
local loss = require("runtime.loss")
local grave = require("runtime.grave")
local camera = require("runtime.camera")
local freshness = require("runtime.freshness")

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
    if observe_payload.substrate_called == false
        or observe_payload.sensor == "relation_native" then
        return true
    end
    local response = observe_payload.response or {}
    local call = observe_payload.call or {}

    local call_charge, call_charge_err = budget.charge(instance, {
        operator = "☴",
        event_id = observe_payload.trace_event_id,
        cost = {substrate_calls = 1},
        source = "substrate_call",
        truth_status = "runtime_confirmed",
    })
    if not call_charge then
        return nil, call_charge_err
    end

    local usage_cost, usage_err = budget.from_usage(response.usage or {})
    if not usage_cost then
        return nil, usage_err
    end
    if next(usage_cost) ~= nil then
        local usage_charge, usage_charge_err = budget.charge(instance, {
            operator = "☴",
            event_id = observe_payload.trace_event_id,
            cost = usage_cost,
            source = "substrate_usage",
            truth_status = "runtime_confirmed",
        })
        if not usage_charge then
            return nil, usage_charge_err
        end
        return true
    end

    local estimated = budget.estimate_tokens((call.prompt_payload or "") .. "\n" .. (response.text or ""))
    if estimated > 0 then
        local estimate_charge, estimate_charge_err = budget.charge(instance, {
            operator = "☴",
            event_id = observe_payload.trace_event_id,
            cost = {estimated_tokens = estimated},
            source = "local_estimator",
            truth_status = "estimated",
        })
        if not estimate_charge then
            return nil, estimate_charge_err
        end
    end
    return true
end

local function apply_operator_physics(instance, operator, payload)
    if operator == "☴" then
        return charge_substrate_usage(instance, payload)
    end

    if operator == "☵" and type(payload.loss) == "table" then
        local applied, apply_err = loss.apply(instance, {
            operator = "☵",
            event_id = payload.trace_event_id,
            amount = loss.from_encode_loss(payload.loss),
            kind = payload.loss.kind,
            source = "encode_loss",
            detail = payload.loss,
            truth_status = "runtime_confirmed",
        })
        if not applied then
            return nil, apply_err
        end
        return true
    end

    if operator == "☳" and type(payload.loss) == "table" then
        local applied, apply_err = loss.apply(instance, {
            operator = "☳",
            event_id = payload.trace_event_id,
            amount = loss.from_choose_loss(payload.loss),
            kind = payload.loss.kind,
            source = "choice_loss",
            detail = payload.loss,
            truth_status = "runtime_confirmed",
        })
        if not applied then
            return nil, apply_err
        end
    end
    return true
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

local function event_refs(instance, first_index)
    local refs = {}
    for index = first_index, #(instance.trace or {}) do
        local event = instance.trace[index]
        if event and event.id then
            refs[#refs + 1] = event.id
        end
    end
    return refs
end

local function ledger_refs(prefix, first_index, last_index)
    local refs = {}
    for index = first_index, last_index do
        refs[#refs + 1] = prefix .. tostring(index)
    end
    return refs
end

local function record_decision_evidence(result, decision, observer)
    if decision.authority == "tree" then
        local recorded, stats_err = edge_stats.record_tree_derivation(
            result.edge_stats,
            decision
        )
        if not recorded then
            note_stats_error(result, stats_err)
        end
    end
    if observer then
        result.shadow_routes[#result.shadow_routes + 1] = observer
        local recorded, stats_err = edge_stats.record(result.edge_stats, observer)
        if not recorded then
            note_stats_error(result, stats_err)
        end
    end
end

local function commit_route(instance, result, route, include_in_routes)
    -- Observer output is reported separately; it is not committed route evidence.
    local observer = route.shadow
    route.shadow = nil
    local route_event, commit_err = packet_core.commit_transition(instance, route)
    if not route_event then
        return nil, commit_err
    end
    route.trace_event_id = route_event.id
    if include_in_routes ~= false then
        result.routes[#result.routes + 1] = route
    end
    record_decision_evidence(result, route, observer)
    local recorded, stats_err = edge_stats.record_transition(result.edge_stats, route)
    if not recorded then
        note_stats_error(result, stats_err)
    end
    return route
end

local function die_from_no_viable(instance, result, outcome)
    local observer = outcome.shadow
    outcome.shadow = nil
    record_decision_evidence(result, outcome, observer)
    if die_from_mortality(instance, result, instance.operator) then
        return instance
    end
    local cause = outcome.cause == "unsafe" and "unsafe_scope" or "stalled"
    local residue = {
        cause = cause,
        stall_kind = outcome.cause or "stalled",
        last_operator = instance.operator,
        candidate_audit_ref = outcome.derivation_ref,
        pressure_snapshot_ref = outcome.pressure_snapshot_ref,
        candidates = outcome.candidates or {},
        do_not_repeat = "no viable operator edge under current packet state",
    }
    local dead, death_err = packet_core.die(instance, cause, residue)
    if not dead then
        return nil, death_err
    end
    result.stop_reason = cause
    result.final_status = instance.status
    result.no_viable_edge = outcome
    finish_measurements(result)
    return instance
end

local function failed_effect_residue(instance, operator, failure, pending_arrival, failure_event)
    return {
        cause = "effect_failure",
        last_operator = operator,
        failure = failure,
        failure_event_ref = failure_event and failure_event.id,
        committed_route_ref = pending_arrival and pending_arrival.trace_event_id,
        progress = body.progress(instance),
        do_not_repeat = "repeat only after external effect failure pressure changes",
    }
end

function tension_runner.run(prompt, substrate, options)
    options = options or {}

    local packet_life = options.packet_life
    local vertical_life = type(packet_life) == "table"
        and packet_life.protocol_version == "vertical_packet_life.v0"
    local prepared_graves
    if vertical_life and options.inherited_graves ~= nil then
        local prepare_err
        prepared_graves, prepare_err = grave.prepare(options.inherited_graves)
        if not prepared_graves then
            return nil, stage_error("grave_preflight", prepare_err)
        end
    end

    local instance
    local birth_receipt
    if vertical_life then
        local birth_err
        instance, birth_receipt = packet_birth.create(packet_life.flow_domain, prompt, {
            packet_options = options.packet_options,
            projection_adapter = packet_life.projection_adapter,
            inherited_graves = prepared_graves,
        })
        if not instance then
            birth_err = birth_receipt
            return nil, stage_error("birth", birth_err)
        end
    else
        instance = packet_core.new(prompt, options.packet_options or {})
    end
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
        legacy_shadow = (options.router_mode or "shadow") == "tree"
            and options.legacy_shadow ~= false or false,
        stop_reason = nil,
        final_status = instance.status,
        birth = birth_receipt,
    }

    if vertical_life and prepared_graves ~= nil then
        local grave_payload, grave_err = grave.attach(instance, prepared_graves)
        if not grave_payload then
            return nil, stage_error("grave", grave_err)
        end
        result.grave = grave_payload
    end

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

    if not vertical_life and options.inherited_graves ~= nil then
        local grave_payload, grave_err = grave.attach(instance, options.inherited_graves)
        if not grave_payload then
            return nil, stage_error("grave", grave_err)
        end
        result.grave = grave_payload
    end

    local entry_decision
    if result.router_mode == "tree" and options.tree_test_override ~= true then
        local derived_entry, derived_err = router.after_tick(instance, {
            operator = "▽",
            payload = flow_payload,
            work_mode = options.work_mode or "build",
        }, {
            mode = "tree",
            substrate = substrate,
            capabilities = options.capabilities,
            options = options,
            result = result,
            tree = options.tree_router,
            legacy_shadow = options.legacy_shadow,
        })
        if not derived_entry then
            return nil, stage_error("entry", derived_err)
        end
        if derived_entry.kind == "no_viable_edge" then
            result.entry_derivation = derived_entry
            local dead, death_err = die_from_no_viable(instance, result, derived_entry)
            if not dead then
                return nil, stage_error("entry", death_err)
            end
            return instance, result
        end
        entry_decision = derived_entry
    else
        local start_operator = options.start_operator or "☴"
        entry_decision = {
            kind = "route_decision",
            from = instance.operator,
            to = start_operator,
            reason = "runner_entry",
            authority = options.tree_test_override == true
                and "harness_override" or "legacy_control",
            truth_status = "runtime_confirmed",
        }
    end

    local committed_entry, entry_err = commit_route(instance, result, entry_decision, false)
    if not committed_entry then
        return nil, stage_error("entry", entry_err)
    end
    result.entry_route = entry_decision
    result.final_status = instance.status

    local current = instance.operator
    local max_ticks = options.max_ticks or default_max_ticks(instance)
    local pending_arrival = entry_decision

    while #result.ticks < max_ticks do
        local revisions_before, revisions_err = camera.revision_snapshot(instance)
        if not revisions_before then
            return nil, stage_error("camera", revisions_err)
        end
        local budget_before = budget.snapshot(instance)
        local loss_before = loss.snapshot(instance)
        local progress_before = body.progress(instance)
        local evidence_fingerprint_before = freshness.evidence_fingerprint(instance)
        local trace_start = #instance.trace + 1
        local budget_event_start = #(instance.runtime and instance.runtime.budget
            and instance.runtime.budget.events or {}) + 1
        local loss_event_start = #(instance.tension and instance.tension.loss_events or {}) + 1

        local tick_event, tick_err = packet_core.begin_tick(instance, current, {})
        if not tick_event then
            return nil, stage_error("tick", tick_err)
        end
        local execution, err = operator_registry.execute(
            current,
            instance,
            operator_context(substrate, options, result)
        )
        if not execution then
            return nil, stage_error(current, err)
        end
        if execution.status == "not_ready" then
            return nil, stage_error(current,
                "committed_operator_not_ready:" .. tostring(execution.readiness.reason))
        end
        if execution.status == "effect_failure" then
            local failure = execution.failure
            local failure_event, failure_event_err = packet_core.append_trace(instance, {
                type = "operator_failure",
                operator = current,
                truth_status = "runtime_confirmed",
                payload = {
                    kind = "operator_failure",
                    operator = current,
                    failure = failure,
                    committed_route_ref = pending_arrival and pending_arrival.trace_event_id,
                },
                cost = {},
            })
            if not failure_event then
                return nil, stage_error("operator_failure", failure_event_err)
            end

            local result_tick = append_tick(result, current, {
                kind = "operator_failure_payload",
                failure = failure,
                trace_event_id = failure_event.id,
                truth_status = "runtime_confirmed",
            })
            result_tick.trace_event_id = tick_event.id
            result_tick.readiness = execution.readiness
            result_tick.registry = operator_registry.protocol_version
            result_tick.status = "effect_failure"
            if pending_arrival then
                local failed, failed_err = edge_stats.record_failure(
                    result.edge_stats,
                    pending_arrival,
                    failure,
                    failure_event.id
                )
                if not failed then
                    note_stats_error(result, failed_err)
                end
            end

            local clock = instance.physis and instance.physis.clock
            if clock then
                clock.ticks = (clock.ticks or 0) + 1
            end
            local tick_charge, tick_charge_err = budget.charge(instance, {
                operator = current,
                event_id = failure_event.id,
                cost = {steps = 1},
                source = "body_tick",
                truth_status = "runtime_confirmed",
            })
            if not tick_charge then
                return nil, stage_error("budget", tick_charge_err)
            end
            if next(failure.cost or {}) ~= nil then
                local failure_charge, failure_charge_err = budget.charge(instance, {
                    operator = current,
                    event_id = failure_event.id,
                    cost = failure.cost,
                    source = "failed_external_effect",
                    truth_status = "runtime_confirmed",
                })
                if not failure_charge then
                    return nil, stage_error("budget", failure_charge_err)
                end
            end

            local source_event_refs = event_refs(instance, trace_start)
            local runtime_frame, frame_err = camera.capture(instance, {
                operator = current,
                revisions_before = revisions_before,
                source_event_refs = source_event_refs,
                effect_refs = {failure_event.id},
                budget_event_refs = ledger_refs(
                    "budget:event:",
                    budget_event_start,
                    #(instance.runtime and instance.runtime.budget
                        and instance.runtime.budget.events or {})
                ),
                loss_event_refs = ledger_refs(
                    "loss:event:",
                    loss_event_start,
                    #(instance.tension and instance.tension.loss_events or {})
                ),
                budget_before = budget_before,
                loss_before = loss_before,
                progress_before = progress_before,
                evidence_fingerprint_before = evidence_fingerprint_before,
            })
            if not runtime_frame then
                return nil, stage_error("camera", frame_err)
            end
            result_tick.runtime_frame_ref = runtime_frame.trace_event_id
            result_tick.runtime_frame_seq = runtime_frame.seq

            local dead, death_err = packet_core.die(instance, "effect_failure",
                failed_effect_residue(instance, current, failure, pending_arrival, failure_event))
            if not dead then
                return nil, stage_error("effect_failure", death_err)
            end
            result.stop_reason = "effect_failure"
            result.final_status = instance.status
            result.effect_failure = failure
            finish_measurements(result)
            return instance, result
        end

        local payload = execution.payload
        local readiness = execution.readiness

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
        local tick_charge, tick_charge_err = budget.charge(instance, {
            operator = current,
            cost = {steps = 1},
            source = "body_tick",
            truth_status = "runtime_confirmed",
        })
        if not tick_charge then
            return nil, stage_error("budget", tick_charge_err)
        end
        local physics_ok, physics_err = apply_operator_physics(instance, current, payload)
        if not physics_ok then
            return nil, stage_error("physics", physics_err)
        end

        local source_event_refs = event_refs(instance, trace_start)
        local runtime_frame, frame_err = camera.capture(instance, {
            operator = current,
            revisions_before = revisions_before,
            source_event_refs = source_event_refs,
            effect_refs = source_event_refs,
            budget_event_refs = ledger_refs(
                "budget:event:",
                budget_event_start,
                #(instance.runtime and instance.runtime.budget
                    and instance.runtime.budget.events or {})
            ),
            loss_event_refs = ledger_refs(
                "loss:event:",
                loss_event_start,
                #(instance.tension and instance.tension.loss_events or {})
            ),
            budget_before = budget_before,
            loss_before = loss_before,
            progress_before = progress_before,
            evidence_fingerprint_before = evidence_fingerprint_before,
        })
        if not runtime_frame then
            return nil, stage_error("camera", frame_err)
        end
        result_tick.runtime_frame_ref = runtime_frame.trace_event_id
        result_tick.runtime_frame_seq = runtime_frame.seq

        if current == "△" then
            local manifested, manifest_err = packet_core.manifest_packet(instance, payload)
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
            legacy_shadow = options.legacy_shadow,
        })
        if not route then
            return nil, stage_error("router", route_err)
        end

        if route.kind == "no_viable_edge" then
            local dead, death_err = die_from_no_viable(instance, result, route)
            if not dead then
                return nil, stage_error("router", death_err)
            end
            return instance, result
        end

        local committed, commit_err = commit_route(instance, result, route)
        if not committed then
            return nil, stage_error("route", commit_err)
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
