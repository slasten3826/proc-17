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
local pressure_action = require("runtime.pressure_action")
local digest = require("core.digest")

local tension_runner = {}

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

local function prepare_options(options)
    local prepared = {}
    for key, value in pairs(options or {}) do
        prepared[key] = value
    end
    if prepared.packet_options ~= nil and type(prepared.packet_options) ~= "table" then
        return nil, "packet_options must be table"
    end
    local packet_options = copy_value(prepared.packet_options or {})
    if packet_options.metadata ~= nil and type(packet_options.metadata) ~= "table" then
        return nil, "packet metadata must be table"
    end
    local metadata = copy_value(packet_options.metadata or {})
    local runner_mode = prepared.work_mode
    local packet_mode = packet_options.work_mode
    local metadata_mode = metadata.work_mode
    local work_mode = runner_mode or packet_mode or metadata_mode or "build"
    if work_mode ~= "plan" and work_mode ~= "build" then
        return nil, "work_mode must be plan or build"
    end
    for _, declared in ipairs({runner_mode, packet_mode, metadata_mode}) do
        if declared ~= nil and declared ~= work_mode then
            return nil, "work_mode declarations disagree"
        end
    end
    metadata.work_mode = work_mode
    packet_options.metadata = metadata
    packet_options.work_mode = work_mode
    prepared.work_mode = work_mode
    prepared.packet_options = packet_options
    if prepared.on_packet_birth ~= nil and type(prepared.on_packet_birth) ~= "function" then
        return nil, "on_packet_birth must be function"
    end
    return prepared
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
        host_services = options and options.host_services,
    }
end

local function arrival_context(instance, operator, pending_arrival, substrate, options, result)
    local base = operator_context(substrate, options, result)
    local selected = pending_arrival and pending_arrival.selected_candidate
    local plan = selected and selected.action_plan
    if plan == nil then
        return base, nil
    end
    if pending_arrival.to ~= operator or plan.target_operator ~= operator then
        return nil, "qualified action target does not match committed arrival"
    end
    if pending_arrival.selected_action_plan_id ~= plan.plan_id then
        return nil, "qualified action plan id does not match committed arrival"
    end
    base.instance = instance
    local context, context_err = pressure_action.registry_context(plan, base)
    if not context then
        return nil, context_err
    end
    return context, plan
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

    if operator == "☶" and payload.mode == "repository_effect" then
        local effect_cost, cost_err = budget.validate_cost(payload.effect_cost)
        if not effect_cost then
            return nil, cost_err
        end
        local charged, charge_err = budget.charge(instance, {
            operator = "☶",
            event_id = payload.trace_event_id,
            cost = effect_cost,
            source = "repository_effect",
            truth_status = "runtime_confirmed",
        })
        if not charged then
            return nil, charge_err
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
    local committed_arrival = route_event.payload
    committed_arrival.trace_event_id = route_event.id
    committed_arrival.truth_status = route_event.truth_status
    return route, committed_arrival
end

local function is_committable_route(value)
    return type(value) == "table"
        and (value.kind == "route_decision" or value.kind == "tree_route_decision")
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
    local prepared_options, options_err = prepare_options(options or {})
    if not prepared_options then
        return nil, stage_error("birth_config", options_err)
    end
    options = prepared_options

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

    if options.on_packet_birth ~= nil then
        if not vertical_life or type(birth_receipt) ~= "table" then
            return nil, stage_error("birth_hook", "trusted birth hook requires vertical Packet life")
        end
        local before_hash, before_hash_err = digest.record(instance)
        if not before_hash then
            return nil, stage_error("birth_hook", before_hash_err)
        end
        local called, accepted, hook_err = pcall(
            options.on_packet_birth,
            instance,
            copy_value(birth_receipt)
        )
        if not called then
            return nil, stage_error("birth_hook", accepted)
        end
        if accepted ~= true then
            return nil, stage_error("birth_hook", hook_err or "birth hook rejected Packet")
        end
        local after_hash, after_hash_err = digest.record(instance)
        if not after_hash then
            return nil, stage_error("birth_hook", after_hash_err)
        end
        if after_hash ~= before_hash then
            return nil, stage_error("birth_hook", "birth hook mutated Packet")
        end
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
        if not is_committable_route(derived_entry) then
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

    local committed_entry, entry_arrival_or_err = commit_route(
        instance,
        result,
        entry_decision,
        false
    )
    if not committed_entry then
        return nil, stage_error("entry", entry_arrival_or_err)
    end
    result.entry_route = entry_decision
    result.final_status = instance.status

    local current = instance.operator
    local max_ticks = options.max_ticks or default_max_ticks(instance)
    local pending_arrival = entry_arrival_or_err

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

        local execution_context, committed_plan_or_err = arrival_context(
            instance,
            current,
            pending_arrival,
            substrate,
            options,
            result
        )
        if not execution_context then
            return nil, stage_error("qualified_action", committed_plan_or_err)
        end
        local committed_plan = committed_plan_or_err
        local tick_event, tick_err = packet_core.begin_tick(instance, current, {})
        if not tick_event then
            return nil, stage_error("tick", tick_err)
        end
        local execution, err = operator_registry.execute(
            current,
            instance,
            execution_context
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
        if committed_plan then
            local readiness_ok, readiness_err = pressure_action.verify_readiness(
                committed_plan,
                readiness
            )
            if not readiness_ok then
                return nil, stage_error("qualified_action", readiness_err)
            end
            local effect_ok, effect_err = pressure_action.verify_effect(
                committed_plan,
                payload,
                instance
            )
            if not effect_ok then
                return nil, stage_error("qualified_action", effect_err)
            end
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

        if not is_committable_route(route) then
            local dead, death_err = die_from_no_viable(instance, result, route)
            if not dead then
                return nil, stage_error("router", death_err)
            end
            return instance, result
        end

        local committed, committed_arrival_or_err = commit_route(instance, result, route)
        if not committed then
            return nil, stage_error("route", committed_arrival_or_err)
        end
        pending_arrival = committed_arrival_or_err
        current = instance.operator
    end

    result.stop_reason = "tick_limit"
    result.final_status = instance.status
    finish_measurements(result)
    return instance, result
end

return tension_runner
