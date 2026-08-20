local packet_core = require("core.packet")
local packet_birth = require("runtime.packet_birth")
local operator_registry = require("runtime.operator_registry")
local body = require("runtime.body")
local router = require("runtime.router")
local edge_stats = require("runtime.edge_stats")
local authority_epoch = require("runtime.authority_epoch")
local edge_catalog = require("runtime.edge_catalog")
local edge_credit = require("runtime.edge_credit")
local budget = require("runtime.budget")
local loss = require("runtime.loss")
local grave = require("runtime.grave")
local camera = require("runtime.camera")
local freshness = require("runtime.freshness")
local pressure_action = require("runtime.pressure_action")
local dissolve_pressure_relief = require("runtime.dissolve_pressure_relief")
local work_layer = require("runtime.work_layer")
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
    if packet_options.network_projection ~= nil then
        return nil, "NETWORK projection must enter through trusted packet_life"
    end
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
    local hands = prepared.repository_hands
    if type(hands) == "table" and hands.enabled == true
        and type(hands.repository_id) == "string" and hands.repository_id ~= "" then
        if packet_options.repository_id ~= nil
            and packet_options.repository_id ~= hands.repository_id then
            return nil, "repository_hands repository_id conflicts with Packet birth"
        end
        if metadata.repository_id ~= nil
            and metadata.repository_id ~= hands.repository_id then
            return nil, "repository_hands repository_id conflicts with metadata mirror"
        end
        packet_options.repository_id = hands.repository_id
        metadata.repository_id = hands.repository_id
    end
    metadata.work_mode = work_mode
    packet_options.metadata = metadata
    packet_options.work_mode = work_mode
    prepared.work_mode = work_mode
    prepared.packet_options = packet_options
    if prepared.on_packet_birth ~= nil and type(prepared.on_packet_birth) ~= "function" then
        return nil, "on_packet_birth must be function"
    end
    prepared.work_layer_observer = prepared.work_layer_observer or "off"
    if prepared.work_layer_observer ~= "off"
        and prepared.work_layer_observer ~= "shadow_v0" then
        return nil, "work_layer_observer must be off or shadow_v0"
    end
    prepared.dissolve_pressure_relief_reader =
        prepared.dissolve_pressure_relief_reader or "off"
    if prepared.dissolve_pressure_relief_reader ~= "off"
        and prepared.dissolve_pressure_relief_reader ~= "v0" then
        return nil, "dissolve_pressure_relief_reader must be off or v0"
    end
    if prepared.work_layer_contract ~= nil
        and type(prepared.work_layer_contract) ~= "table" then
        return nil, "work_layer_contract must be table"
    end
    if prepared.authority_instrument ~= nil
        and prepared.authority_instrument ~= "v3"
        and prepared.authority_instrument ~= "off" then
        return nil, "authority_instrument must be v3 or off"
    end
    if prepared.authority_instrument == "off"
        and prepared.authority_instrument_test_override ~= true then
        return nil, "authority_instrument off requires test override"
    end
    if prepared.edge_evidence ~= nil and type(prepared.edge_evidence) ~= "table" then
        return nil, "edge_evidence must be table"
    end
    local evidence = copy_value(prepared.edge_evidence or {})
    local evidence_keys = {
        case_id = true,
        corpus_layer = true,
        evidence_run_id = true,
    }
    local corpus_layers = {
        L0 = true,
        L1 = true,
        unit = true,
        archaeology = true,
    }
    for key, value in pairs(evidence) do
        if not evidence_keys[key] then
            return nil, "edge_evidence contains unknown key: " .. tostring(key)
        end
        if type(value) ~= "string" or value == "" then
            return nil, "edge_evidence values must be non-empty strings"
        end
    end
    if evidence.corpus_layer ~= nil and not corpus_layers[evidence.corpus_layer] then
        return nil, "edge_evidence corpus_layer is invalid"
    end
    if prepared.edge_evidence ~= nil then
        prepared.edge_evidence = evidence
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

local function note_instrument_error(result, instrument, err)
    if instrument.mode == "off" then
        return true
    end
    local recorded, record_err = edge_stats.runtime_note_error(
        instrument.recorder,
        err
    )
    if not recorded then
        return nil, record_err
    end
    return true
end

local function finish_measurements(result, instrument)
    if instrument.mode == "off" then
        return true
    end
    local credit_state, credit_err = edge_credit.finish_runtime(
        instrument.credit
    )
    if not credit_state then
        return nil, credit_err
    end
    result.edge_credit = credit_state
    local ledger, summary_or_err = edge_stats.finish_runtime(
        instrument.recorder
    )
    if not ledger then
        return nil, summary_or_err
    end
    local summary = summary_or_err
    if not summary then
        return nil, "runtime recorder returned no summary"
    end
    instrument.stats = ledger
    result.edge_stats = ledger
    result.edge_evidence = summary
    if #summary.errors > 0 or summary.error_overflow ~= nil then
        result.authority_instrument_errors = {
            errors = copy_value(summary.errors),
            error_overflow = copy_value(summary.error_overflow),
        }
    end
    return true
end

local function observe_work_layer(instance, result, options, phase)
    if options.work_layer_observer ~= "shadow_v0" then
        return true
    end
    local called, projection, inspect_err = pcall(
        work_layer.inspect_packet,
        instance,
        options.work_layer_contract
    )
    if not called or not projection then
        result.work_layer_observer_errors = result.work_layer_observer_errors or {}
        result.work_layer_observer_errors[#result.work_layer_observer_errors + 1] = {
            kind = "work_layer_instrumentation_error",
            tick_index = #result.ticks,
            operator = instance.operator,
            phase = phase,
            reason = tostring(called and inspect_err or projection),
            event_truth_status = "runtime_confirmed",
        }
        return false
    end
    result.work_layer_observations[#result.work_layer_observations + 1] = {
        kind = "work_layer_shadow_observation",
        observer = "work_layer.shadow_v0",
        authority = "instrumentation_only",
        tick_index = #result.ticks,
        operator = instance.operator,
        phase = phase,
        projection = copy_value(projection),
        event_truth_status = "runtime_confirmed",
    }
    return true
end

local runner_only_option_keys = {
    authority_instrument = true,
    authority_instrument_test_override = true,
    authority_instrument_bounds = true,
    expected_authority_epoch = true,
    edge_evidence = true,
    dissolve_pressure_relief_reader = true,
}

local function body_options(options)
    local projected = {}
    for key, value in pairs(options or {}) do
        if not runner_only_option_keys[key] then
            projected[key] = value
        end
    end
    return projected
end

local function operator_context(substrate, options, result)
    return {
        substrate = substrate,
        options = body_options(options),
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

local function find_budget_charge(instance, source, event_id)
    for _, event in ipairs(instance.runtime and instance.runtime.budget
            and instance.runtime.budget.events or {}) do
        if event.source == source and event.event_id == event_id then
            return event
        end
    end
    return nil
end

local function same_cost(left, right)
    for key, value in pairs(left or {}) do
        if right[key] ~= value then return false end
    end
    for key, value in pairs(right or {}) do
        if left[key] ~= value then return false end
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
    if operator == "☶" and payload.mode == "qa_execution" then
        local effect_cost, cost_err = budget.validate_cost(payload.effect_cost)
        if not effect_cost then
            return nil, cost_err
        end
        local prior = find_budget_charge(
            instance,
            "qa_execution",
            payload.evidence_id
        )
        if prior then
            local prior_cost, prior_cost_err = budget.validate_cost(prior.cost)
            if not prior_cost then return nil, prior_cost_err end
            if not same_cost(prior_cost, effect_cost) then
                return nil, "QA execution budget replay cost mismatch"
            end
            return true
        end
        local charged, charge_err = budget.charge(instance, {
            operator = "☶",
            event_id = payload.evidence_id,
            cost = effect_cost,
            source = "qa_execution",
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

local function trace_event_by_id(instance, event_id)
    for _, event in ipairs(instance.trace or {}) do
        if event.id == event_id then
            return event
        end
    end
    return nil
end

local function detached_plain(value, active)
    if type(value) ~= "table" then
        return value
    end
    if getmetatable(value) ~= nil then
        return nil
    end
    active = active or {}
    if active[value] then
        return nil
    end
    active[value] = true
    local result = {}
    for key, child in pairs(value) do
        local key_copy = detached_plain(key, active)
        local child_copy = detached_plain(child, active)
        if key_copy == nil or (child ~= nil and child_copy == nil) then
            active[value] = nil
            return nil
        end
        result[key_copy] = child_copy
    end
    active[value] = nil
    return result
end

local function source_descriptor(kind, original_id, record)
    if type(original_id) ~= "string" or original_id == ""
        or type(record) ~= "table" then
        return nil
    end
    local snapshot = detached_plain(record)
    return {
        source_kind = kind,
        original_source_id = original_id,
        source_record = snapshot or record,
    }
end

local function source_bundle(instrument, records)
    return {
        life_id = instrument.life.life_id,
        records = records or {},
    }
end

local function append_source(records, kind, original_id, record)
    local descriptor = source_descriptor(kind, original_id, record)
    if descriptor then
        records[#records + 1] = descriptor
    end
end

local function authority_surface_decision(decision)
    local projected = copy_value(decision)
    projected.candidates = {}
    for _, candidate in ipairs(decision.candidates or {}) do
        local definition = edge_catalog.get(decision.from, candidate.to)
        local direction = tostring(decision.from) .. "->" .. tostring(candidate.to)
        local legal = false
        for _, candidate_direction in ipairs(definition and definition.directions or {}) do
            if candidate_direction == direction then
                legal = true
                break
            end
        end
        if legal then
            projected.candidates[#projected.candidates + 1] = copy_value(candidate)
        end
    end
    return projected
end

local function initialize_instrument(instance, result, options)
    local mode = options.authority_instrument or "v3"
    local instrument = {mode = mode}
    result.authority_instrument = mode
    if mode == "off" then
        return instrument
    end

    local epoch_record, diagnostics_or_err = authority_epoch.resolve(options)
    if not epoch_record and diagnostics_or_err
        and diagnostics_or_err.fatal_to_harness == true then
        return nil, diagnostics_or_err
    end
    local prompt_digest, prompt_digest_err = digest.sha256(
        instance.chaos and instance.chaos.raw_prompt
    )
    if not prompt_digest then
        return nil, prompt_digest_err
    end
    local evidence = options.edge_evidence or {}
    local life, life_err = edge_stats.make_life_source({
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        session_id = instance.session_id,
        work_mode = instance.regime.work.mode,
        case_id = evidence.case_id,
        corpus_layer = evidence.corpus_layer,
        evidence_run_id = evidence.evidence_run_id,
        model = type(options.model) == "string" and options.model or nil,
        prompt_hash = "sha256:" .. prompt_digest,
    })
    if not life then
        return nil, life_err
    end
    local epoch_error
    if not epoch_record then
        epoch_error = diagnostics_or_err
    end
    local recorder, stats_err = edge_stats.begin_runtime(
        epoch_record,
        life,
        epoch_error
    )
    if not recorder then
        return nil, stats_err
    end
    local credit_state, credit_err = edge_credit.new_runtime(epoch_record, {
        life_id = life.life_id,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
    })
    if not credit_state then
        return nil, credit_err
    end
    instrument.epoch = epoch_record
    instrument.life = life
    instrument.recorder = recorder
    instrument.credit = credit_state
    instrument.next_route_ordinal = 1
    result.authority_epoch = copy_value(epoch_record)
    if epoch_record then
        result.authority_epoch_diagnostics = copy_value(diagnostics_or_err)
    else
        result.authority_epoch_error = copy_value(diagnostics_or_err)
    end
    return instrument
end

local function ledger_refs(prefix, first_index, last_index)
    local refs = {}
    for index = first_index, last_index do
        refs[#refs + 1] = prefix .. tostring(index)
    end
    return refs
end

local function record_decision_evidence(instance, result, instrument, decision, observer)
    if observer then
        result.shadow_routes[#result.shadow_routes + 1] = observer
    end
    if instrument.mode == "off" then
        return true
    end

    if decision.authority == "tree" then
        local measured_decision = authority_surface_decision(decision)
        local records = {}
        append_source(records, "packet_trace", decision.derivation_ref,
            trace_event_by_id(instance, decision.derivation_ref))
        append_source(records, "policy_evidence", decision.pressure_snapshot_ref,
            trace_event_by_id(instance, decision.pressure_snapshot_ref))
        local recorded, stats_err = edge_stats.runtime_record_tree_derivation(
            instrument.recorder,
            measured_decision,
            source_bundle(instrument, records)
        )
        if not recorded then
            local noted, note_err = note_instrument_error(result, instrument, stats_err)
            if not noted then return nil, note_err end
        end
    end
    if observer then
        local records = {}
        append_source(records, "observer", observer.trace_event_id,
            trace_event_by_id(instance, observer.trace_event_id))
        append_source(records, "policy_evidence", observer.pressure_snapshot_ref,
            trace_event_by_id(instance, observer.pressure_snapshot_ref))
        local recorded, stats_err = edge_stats.runtime_record_observer(
            instrument.recorder,
            observer,
            source_bundle(instrument, records)
        )
        if not recorded then
            local noted, note_err = note_instrument_error(result, instrument, stats_err)
            if not noted then return nil, note_err end
        end
    end
    return true
end

local function commit_route(instance, result, instrument, route, include_in_routes)
    -- Observer output is reported separately; it is not committed route evidence.
    local observer = route.shadow
    route.shadow = nil
    local selection
    if instrument.mode == "v3" then
        local ordinal = instrument.next_route_ordinal
        instrument.next_route_ordinal = ordinal + 1
        local selection_err
        selection, selection_err = edge_credit.runtime_prepare(
            instrument.credit,
            route,
            {
                route_ordinal = ordinal,
                derivation_event = trace_event_by_id(
                    instance,
                    route.derivation_ref
                ),
            }
        )
        if not selection then
            local noted, note_err = note_instrument_error(
                result,
                instrument,
                selection_err
            )
            if not noted then return nil, note_err end
        end
        local observed, observe_err = record_decision_evidence(
            instance,
            result,
            instrument,
            route,
            observer
        )
        if not observed then return nil, observe_err end
        if selection then
            local recorded, stats_err = edge_stats.runtime_record_selection(
                instrument.recorder,
                selection,
                source_bundle(instrument)
            )
            if not recorded then
                local noted, note_err = note_instrument_error(
                    result,
                    instrument,
                    stats_err
                )
                if not noted then return nil, note_err end
            end
        end
    end
    local route_event, commit_err = packet_core.commit_transition(instance, route)
    if not route_event then
        return nil, commit_err
    end
    route.trace_event_id = route_event.id
    if include_in_routes ~= false then
        result.routes[#result.routes + 1] = route
    end
    local credit_commit
    if instrument.mode ~= "v3" then
        local observed, observe_err = record_decision_evidence(
            instance,
            result,
            instrument,
            route,
            observer
        )
        if not observed then return nil, observe_err end
    end
    if instrument.mode == "v3" and selection then
        local taint
        local credit_err
        credit_commit, taint, credit_err = edge_credit.runtime_record_commit(
            instrument.credit,
            selection,
            route_event
        )
        if not credit_commit then
            local noted, note_err = note_instrument_error(
                result,
                instrument,
                credit_err
            )
            if not noted then return nil, note_err end
        else
            local records = {}
            append_source(records, "packet_trace", route_event.id, route_event)
            local recorded, stats_err = edge_stats.runtime_record_transition(
                instrument.recorder,
                credit_commit,
                source_bundle(instrument, records)
            )
            if not recorded then
                local noted, note_err = note_instrument_error(
                    result,
                    instrument,
                    stats_err
                )
                if not noted then return nil, note_err end
            end
        end
    end
    local committed_arrival = route_event.payload
    committed_arrival.trace_event_id = route_event.id
    committed_arrival.truth_status = route_event.truth_status
    return route, committed_arrival, credit_commit
end

local function is_committable_route(value)
    return type(value) == "table"
        and (value.kind == "route_decision" or value.kind == "tree_route_decision")
end

local function die_from_no_viable(instance, result, instrument, outcome)
    local observer = outcome.shadow
    outcome.shadow = nil
    local observed, observe_err = record_decision_evidence(
        instance,
        result,
        instrument,
        outcome,
        observer
    )
    if not observed then return nil, observe_err end
    if die_from_mortality(instance, result, instance.operator) then
        local finished, finish_err = finish_measurements(result, instrument)
        if not finished then return nil, finish_err end
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
    local finished, finish_err = finish_measurements(result, instrument)
    if not finished then return nil, finish_err end
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

local function tick_effect_sources(instance, instrument, trace_start, tick_event)
    local records = {}
    local effect_refs = {}
    append_source(records, "runner_tick", tick_event.id, tick_event)
    for index = trace_start, #(instance.trace or {}) do
        local event = instance.trace[index]
        if event and event.id and event.id ~= tick_event.id then
            effect_refs[#effect_refs + 1] = event.id
            append_source(records, "runner_effect", event.id, event)
        end
    end
    table.sort(effect_refs)
    return effect_refs, source_bundle(instrument, records)
end

local function record_arrival_evidence(instance, result, instrument,
    pending_arrival, pending_credit, tick_event, payload, trace_start)
    if instrument.mode == "off" or not pending_arrival then
        return true, nil
    end
    if not pending_credit then
        return true, nil
    end
    local effect_refs, bundle = tick_effect_sources(
        instance,
        instrument,
        trace_start,
        tick_event
    )
    local arrival, decision, arrival_err = edge_credit.runtime_record_arrival(
        instrument.credit,
        pending_credit,
        {
            destination_tick_ref = tick_event.id,
            effect_refs = effect_refs,
            payload_kind = type(payload.kind) == "string" and payload.kind
                or "operator_payload",
        }
    )
    if not arrival then
        local noted, note_err = note_instrument_error(
            result,
            instrument,
            arrival_err
        )
        if not noted then return nil, note_err end
        return true, nil
    end
    local recorded, stats_err = edge_stats.runtime_record_arrival(
        instrument.recorder,
        arrival,
        decision,
        bundle
    )
    if not recorded then
        local noted, note_err = note_instrument_error(result, instrument, stats_err)
        if not noted then return nil, note_err end
        return true, nil
    end
    return true, copy_value(arrival)
end

local function relief_error(err)
    if type(err) == "table" then
        return table.concat({
            tostring(err.code or "reader_failure"),
            tostring(err.stage or "unknown_stage"),
            tostring(err.message or "pressure-relief reader failed"),
        }, ":")
    end
    return tostring(err or "pressure-relief reader failed")
end

local function capture_dissolve_pressure_relief(instance, result, options, input)
    if options.dissolve_pressure_relief_reader ~= "v0" then
        return true
    end
    local before, before_err = digest.record(instance)
    if not before then
        return nil, "dissolve_pressure_relief:purity:" .. tostring(before_err)
    end
    local trusted_context
    if input.credit_commit and input.arrival_evidence then
        trusted_context = {edge_credit = {
            commit = copy_value(input.credit_commit),
            arrival = copy_value(input.arrival_evidence),
        }}
    end
    local called, view, measure_err = pcall(
        dissolve_pressure_relief.measure,
        instance,
        {
            protocol_version = dissolve_pressure_relief.request_protocol_version,
            packet_id = instance.id,
            generation = instance.generation,
            route_event_ref = input.arrived_route_ref,
        },
        trusted_context
    )
    local after, after_err = digest.record(instance)
    if not after then
        return nil, "dissolve_pressure_relief:purity:" .. tostring(after_err)
    end
    if before ~= after then
        return nil, "dissolve_pressure_relief:purity:reader mutated Packet"
    end
    if not called then
        return nil, "dissolve_pressure_relief:reader_failure:"
            .. tostring(view)
    end
    if not view then
        return nil, "dissolve_pressure_relief:" .. relief_error(measure_err)
    end
    local verified, verify_err = dissolve_pressure_relief.verify(view)
    if not verified then
        return nil, "dissolve_pressure_relief:invalid_view:"
            .. tostring(verify_err)
    end
    for _, existing in ipairs(result.dissolve_pressure_relief_measurements) do
        if existing.measurement_id == view.measurement_id then
            return nil, "dissolve_pressure_relief:duplicate_measurement_id"
        end
    end
    result.dissolve_pressure_relief_measurements[
        #result.dissolve_pressure_relief_measurements + 1
    ] = copy_value(view)
    return true
end

local function record_failure_evidence(instance, result, instrument,
    pending_arrival, pending_credit, tick_event, failure_event, failure)
    if instrument.mode == "off" or not pending_arrival then
        return true
    end
    if not pending_credit then
        return true
    end
    local record, record_err = edge_credit.runtime_record_failure(
        instrument.credit,
        pending_credit,
        {
            destination_tick_ref = tick_event.id,
            failure_ref = failure_event.id,
            failure_kind = type(failure.kind) == "string" and failure.kind
                or (type(failure.code) == "string" and failure.code
                    or "effect_failure"),
        }
    )
    if not record then
        return note_instrument_error(result, instrument, record_err)
    end
    local records = {}
    append_source(records, "runner_tick", tick_event.id, tick_event)
    append_source(records, "runner_effect", failure_event.id, failure_event)
    local recorded, stats_err = edge_stats.runtime_record_failure(
        instrument.recorder,
        record,
        source_bundle(instrument, records)
    )
    if not recorded then
        return note_instrument_error(result, instrument, stats_err)
    end
    return true
end

local function record_pending_evidence(result, instrument, pending_credit)
    if instrument.mode ~= "v3" or not pending_credit then
        return true
    end
    local record, record_err = edge_credit.runtime_record_pending(
        instrument.credit,
        pending_credit,
        {stop_reason = "tick_limit"}
    )
    if not record then
        return note_instrument_error(result, instrument, record_err)
    end
    local recorded, stats_err = edge_stats.runtime_record_pending(
        instrument.recorder,
        record
    )
    if not recorded then
        return note_instrument_error(result, instrument, stats_err)
    end
    return true
end

local function current_tick_was_charged(instance, tick_event_id)
    return find_budget_charge(instance, "body_tick", tick_event_id) ~= nil
end

-- Manual/grown corpus entrance for the exact QA action. Routing remains unchanged.
function tension_runner.execute_qa_tick(instance, host_services)
    local tick_lease, lease_err = packet_core.assert_actor_tick(
        instance,
        "☶",
        "execute runner-owned QA tick"
    )
    if not tick_lease then return nil, stage_error("qa_tick", lease_err) end
    if current_tick_was_charged(instance, tick_lease.id) then
        return nil, stage_error("qa_tick", "current_tick_already_settled")
    end

    local revisions_before, revisions_err = camera.revision_snapshot(instance)
    if not revisions_before then return nil, stage_error("camera", revisions_err) end
    local budget_before = budget.snapshot(instance)
    local loss_before = loss.snapshot(instance)
    local progress_before = body.progress(instance)
    local evidence_fingerprint_before = freshness.evidence_fingerprint(instance)
    local trace_start = #instance.trace + 1
    local budget_event_start = #(instance.runtime and instance.runtime.budget
        and instance.runtime.budget.events or {}) + 1
    local loss_event_start = #(instance.tension and instance.tension.loss_events or {}) + 1
    local options = {
        work_mode = "build",
        logic = {
            qa_execution = {action = "execute_current_candidate"},
        },
        host_services = host_services,
    }
    local result = {
        kind = "tension_runner_manual_tick_result",
        operator = "☶",
        status = nil,
        final_status = instance.status,
    }
    local execution, execution_err = operator_registry.execute(
        "☶",
        instance,
        operator_context(nil, options, {ticks = {}})
    )
    if not execution then return nil, stage_error("☶", execution_err) end
    if execution.status == "not_ready" then
        return nil, stage_error("☶",
            "committed_operator_not_ready:" .. tostring(execution.readiness.reason))
    end

    local clock = instance.physis and instance.physis.clock
    if clock then clock.ticks = (clock.ticks or 0) + 1 end

    if execution.status == "effect_failure" then
        local failure = execution.failure
        local failure_event, failure_event_err = packet_core.append_trace(instance, {
            type = "operator_failure",
            operator = "☶",
            truth_status = "runtime_confirmed",
            payload = {
                kind = "operator_failure",
                operator = "☶",
                failure = failure,
                committed_route_ref = nil,
            },
            cost = {},
        })
        if not failure_event then
            return nil, stage_error("operator_failure", failure_event_err)
        end
        local tick_charge, tick_charge_err = budget.charge(instance, {
            operator = "☶",
            event_id = tick_lease.id,
            cost = {steps = 1},
            source = "body_tick",
            truth_status = "runtime_confirmed",
        })
        if not tick_charge then return nil, stage_error("budget", tick_charge_err) end
        if next(failure.cost or {}) ~= nil then
            local failure_charge, failure_charge_err = budget.charge(instance, {
                operator = "☶",
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
        table.insert(source_event_refs, 1, tick_lease.id)
        local runtime_frame, frame_err = camera.capture(instance, {
            operator = "☶",
            revisions_before = revisions_before,
            source_event_refs = source_event_refs,
            effect_refs = {failure_event.id},
            budget_event_refs = ledger_refs(
                "budget:event:", budget_event_start,
                #(instance.runtime and instance.runtime.budget
                    and instance.runtime.budget.events or {})
            ),
            loss_event_refs = ledger_refs(
                "loss:event:", loss_event_start,
                #(instance.tension and instance.tension.loss_events or {})
            ),
            budget_before = budget_before,
            loss_before = loss_before,
            progress_before = progress_before,
            evidence_fingerprint_before = evidence_fingerprint_before,
        })
        if not runtime_frame then return nil, stage_error("camera", frame_err) end
        local dead, death_err = packet_core.die(
            instance,
            "effect_failure",
            failed_effect_residue(instance, "☶", failure, nil, failure_event)
        )
        if not dead then return nil, stage_error("effect_failure", death_err) end
        result.status = "effect_failure"
        result.failure = copy_value(failure)
        result.runtime_frame_ref = runtime_frame.trace_event_id
        result.final_status = instance.status
        return instance, result
    end

    local payload = execution.payload
    local tick_charge, tick_charge_err = budget.charge(instance, {
        operator = "☶",
        event_id = tick_lease.id,
        cost = {steps = 1},
        source = "body_tick",
        truth_status = "runtime_confirmed",
    })
    if not tick_charge then return nil, stage_error("budget", tick_charge_err) end
    local physics_ok, physics_err = apply_operator_physics(instance, "☶", payload)
    if not physics_ok then return nil, stage_error("physics", physics_err) end
    local source_event_refs = event_refs(instance, trace_start)
    table.insert(source_event_refs, 1, tick_lease.id)
    local runtime_frame, frame_err = camera.capture(instance, {
        operator = "☶",
        revisions_before = revisions_before,
        source_event_refs = source_event_refs,
        effect_refs = source_event_refs,
        budget_event_refs = ledger_refs(
            "budget:event:", budget_event_start,
            #(instance.runtime and instance.runtime.budget
                and instance.runtime.budget.events or {})
        ),
        loss_event_refs = ledger_refs(
            "loss:event:", loss_event_start,
            #(instance.tension and instance.tension.loss_events or {})
        ),
        budget_before = budget_before,
        loss_before = loss_before,
        progress_before = progress_before,
        evidence_fingerprint_before = evidence_fingerprint_before,
    })
    if not runtime_frame then return nil, stage_error("camera", frame_err) end
    result.status = "applied"
    result.payload = copy_value(payload)
    result.readiness = copy_value(execution.readiness)
    result.runtime_frame_ref = runtime_frame.trace_event_id
    if die_from_mortality(instance, result, "☶") then
        result.status = "mortality"
    end
    result.final_status = instance.status
    return instance, result
end

-- Manual/grown corpus entrance for the deterministic QA verdict action.
function tension_runner.execute_qa_verdict_tick(instance, qa_contract_id)
    if type(qa_contract_id) ~= "string" or qa_contract_id == "" then
        return nil, stage_error("qa_verdict_tick", "qa_contract_id_required")
    end
    local tick_lease, lease_err = packet_core.assert_actor_tick(
        instance,
        "☱",
        "execute runner-owned QA verdict tick"
    )
    if not tick_lease then
        return nil, stage_error("qa_verdict_tick", lease_err)
    end
    if current_tick_was_charged(instance, tick_lease.id) then
        return nil, stage_error(
            "qa_verdict_tick",
            "current_tick_already_settled"
        )
    end

    local revisions_before, revisions_err = camera.revision_snapshot(instance)
    if not revisions_before then return nil, stage_error("camera", revisions_err) end
    local budget_before = budget.snapshot(instance)
    local loss_before = loss.snapshot(instance)
    local progress_before = body.progress(instance)
    local evidence_fingerprint_before = freshness.evidence_fingerprint(instance)
    local trace_start = #instance.trace + 1
    local budget_event_start = #(instance.runtime and instance.runtime.budget
        and instance.runtime.budget.events or {}) + 1
    local loss_event_start = #(instance.tension and instance.tension.loss_events or {}) + 1
    local options = {
        work_mode = "build",
        runtime = {
            qa_verdict = {
                action = "assemble_current_candidate_verdict",
                qa_contract_id = qa_contract_id,
            },
        },
    }
    local result = {
        kind = "tension_runner_manual_tick_result",
        operator = "☱",
        status = nil,
        final_status = instance.status,
    }
    local execution, execution_err = operator_registry.execute(
        "☱",
        instance,
        operator_context(nil, options, {ticks = {}})
    )
    if not execution then return nil, stage_error("☱", execution_err) end
    if execution.status == "not_ready" then
        return nil, stage_error(
            "☱",
            "committed_operator_not_ready:"
                .. tostring(execution.readiness.reason)
        )
    end
    if execution.status ~= "applied" then
        return nil, stage_error("☱", "qa_verdict_unexpected_effect_failure")
    end

    local clock = instance.physis and instance.physis.clock
    if clock then clock.ticks = (clock.ticks or 0) + 1 end
    local tick_charge, tick_charge_err = budget.charge(instance, {
        operator = "☱",
        event_id = tick_lease.id,
        cost = {steps = 1},
        source = "body_tick",
        truth_status = "runtime_confirmed",
    })
    if not tick_charge then return nil, stage_error("budget", tick_charge_err) end
    local physics_ok, physics_err = apply_operator_physics(
        instance,
        "☱",
        execution.payload
    )
    if not physics_ok then return nil, stage_error("physics", physics_err) end

    local source_event_refs = event_refs(instance, trace_start)
    table.insert(source_event_refs, 1, tick_lease.id)
    local runtime_frame, frame_err = camera.capture(instance, {
        operator = "☱",
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
    if not runtime_frame then return nil, stage_error("camera", frame_err) end
    result.status = "applied"
    result.payload = copy_value(execution.payload)
    result.readiness = copy_value(execution.readiness)
    result.runtime_frame_ref = runtime_frame.trace_event_id
    if die_from_mortality(instance, result, "☱") then
        result.status = "mortality"
    end
    result.final_status = instance.status
    return instance, result
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
            network_projection = packet_life.network_projection,
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
        router_mode = options.router_mode or "shadow",
        legacy_shadow = (options.router_mode or "shadow") == "tree"
            and options.legacy_shadow ~= false or false,
        work_layer_observer = options.work_layer_observer,
        work_layer_observations = {},
        dissolve_pressure_relief_reader =
            options.dissolve_pressure_relief_reader,
        dissolve_pressure_relief_measurements = {},
        stop_reason = nil,
        final_status = instance.status,
        birth = birth_receipt,
    }
    local instrument, instrument_err = initialize_instrument(
        instance,
        result,
        options
    )
    if not instrument then
        local detail = type(instrument_err) == "table"
            and (instrument_err.code or instrument_err.message)
            or instrument_err
        return nil, stage_error("authority_instrument", detail)
    end

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
            options = body_options(options),
            result = result,
            tree = options.tree_router,
            legacy_shadow = options.legacy_shadow,
        })
        if not derived_entry then
            return nil, stage_error("entry", derived_err)
        end
        if not is_committable_route(derived_entry) then
            result.entry_derivation = derived_entry
            local dead, death_err = die_from_no_viable(
                instance,
                result,
                instrument,
                derived_entry
            )
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

    local committed_entry, entry_arrival_or_err, entry_credit = commit_route(
        instance,
        result,
        instrument,
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
    local pending_credit = entry_credit

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
        local arrived_route_ref = pending_arrival
            and pending_arrival.trace_event_id or nil
        local arrived_action_mode = committed_plan and committed_plan.mode or nil
        local arrived_credit_commit = pending_credit and copy_value(pending_credit)
            or nil
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
            local failure_recorded, failure_record_err = record_failure_evidence(
                instance,
                result,
                instrument,
                pending_arrival,
                pending_credit,
                tick_event,
                failure_event,
                failure
            )
            if not failure_recorded then
                return nil, stage_error("authority_instrument", failure_record_err)
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
            observe_work_layer(instance, result, options, "post_effect_failure")
            local finished, finish_err = finish_measurements(result, instrument)
            if not finished then
                return nil, stage_error("authority_instrument", finish_err)
            end
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
        local arrival_evidence
        if pending_arrival then
            local arrival_recorded, arrival_evidence_or_err = record_arrival_evidence(
                instance,
                result,
                instrument,
                pending_arrival,
                pending_credit,
                tick_event,
                payload,
                trace_start
            )
            if not arrival_recorded then
                return nil, stage_error(
                    "authority_instrument",
                    arrival_evidence_or_err
                )
            end
            arrival_evidence = arrival_evidence_or_err
            pending_arrival = nil
            pending_credit = nil
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
            observe_work_layer(instance, result, options, "post_terminal_tick")
            local finished, finish_err = finish_measurements(result, instrument)
            if not finished then
                return nil, stage_error("authority_instrument", finish_err)
            end
            return instance, result
        end

        if die_from_mortality(instance, result, current) then
            observe_work_layer(instance, result, options, "post_mortality_tick")
            local finished, finish_err = finish_measurements(result, instrument)
            if not finished then
                return nil, stage_error("authority_instrument", finish_err)
            end
            return instance, result
        end

        observe_work_layer(instance, result, options, "post_body_tick")

        local route, route_err = router.after_tick(instance, {
            operator = current,
            payload = payload,
            work_mode = options.work_mode or "build",
        }, {
            mode = options.router_mode or "shadow",
            substrate = substrate,
            capabilities = options.capabilities,
            options = body_options(options),
            result = result,
            tree = options.tree_router,
            legacy_shadow = options.legacy_shadow,
        })
        if not route then
            return nil, stage_error("router", route_err)
        end

        if current == "☷"
            and arrived_action_mode == "inherited_rejected_form_release" then
            local captured, capture_err = capture_dissolve_pressure_relief(
                instance,
                result,
                options,
                {
                    arrived_route_ref = arrived_route_ref,
                    credit_commit = arrived_credit_commit,
                    arrival_evidence = arrival_evidence,
                }
            )
            if not captured then return nil, capture_err end
        end

        if not is_committable_route(route) then
            local dead, death_err = die_from_no_viable(
                instance,
                result,
                instrument,
                route
            )
            if not dead then
                return nil, stage_error("router", death_err)
            end
            return instance, result
        end

        local committed, committed_arrival_or_err, committed_credit = commit_route(
            instance,
            result,
            instrument,
            route
        )
        if not committed then
            return nil, stage_error("route", committed_arrival_or_err)
        end
        pending_arrival = committed_arrival_or_err
        pending_credit = committed_credit
        current = instance.operator
    end

    result.stop_reason = "tick_limit"
    result.final_status = instance.status
    local pending_recorded, pending_record_err = record_pending_evidence(
        result,
        instrument,
        pending_credit
    )
    if not pending_recorded then
        return nil, stage_error("authority_instrument", pending_record_err)
    end
    local finished, finish_err = finish_measurements(result, instrument)
    if not finished then
        return nil, stage_error("authority_instrument", finish_err)
    end
    return instance, result
end

return tension_runner
