local topology = require("core.topology")
local packet_core = require("core.packet")
local body = require("runtime.body")
local freshness = require("runtime.freshness")
local pressure_module = require("runtime.pressure")
local tree_router = require("runtime.tree_router")

local router = {}

local legacy_policy = "legacy.control.v0"
local legacy_policy_status = "historical_control"

local hard_next = {
    ["☵"] = "☴",
    ["☳"] = "☴",
    ["☲"] = "☱",
    ["☶"] = "☱",
}

local function last(list)
    if type(list) ~= "table" then
        return nil
    end
    return list[#list]
end

local function budget_pressure(instance)
    local runtime_budget = instance and instance.runtime and instance.runtime.budget
    if type(runtime_budget) == "table" then
        return {
            kind = "runtime_budget",
            exhausted = runtime_budget.exhausted == true,
            exhausted_keys = runtime_budget.exhausted_keys or {},
            values = runtime_budget.remaining or {},
            spent = runtime_budget.spent or {},
        }
    end

    local physis = instance and (instance.physis or instance.substrate) or {}
    local budget = physis.budget or {}
    local exhausted = false
    for _, key in ipairs({"steps", "substrate_calls", "tool_calls", "file_writes", "test_runs"}) do
        if type(budget[key]) == "number" and budget[key] <= 0 then
            exhausted = true
            break
        end
    end
    return {
        kind = "runtime_budget",
        exhausted = exhausted,
        exhausted_keys = {},
        values = budget,
    }
end

local function loss_pressure(instance)
    local loss_records = instance and instance.boundary and instance.boundary.loss_records or {}
    local tension = instance and instance.tension or {}
    return {
        kind = "packet_loss",
        exhausted = tension.loss_exhausted == true,
        near_death = tension.loss_near_death == true,
        records_count = #loss_records,
        current = tension.loss,
        remaining = tension.loss_remaining,
    }
end

local function karma_pressure(instance)
    local runtime = instance and instance.runtime or {}
    local karma = runtime.karma or {}
    return {
        kind = "grave_karma",
        warning_count = #(karma.warnings or {}),
        bequest_count = #(karma.bequests or {}),
        neutral_count = #(karma.neutral or {}),
        warnings = karma.warnings or {},
    }
end

local function legacy_pressure_snapshot(instance, tick)
    tick = tick or {}
    local payload_pressure = type(tick.payload) == "table" and tick.payload.pressure or nil
    local payload = type(tick.payload) == "table" and tick.payload or {}
    local progress = body.progress(instance)
    local calm = instance and instance.calm or {}
    local runtime = instance and instance.runtime or {}
    local foundation = runtime.foundation or {}
    local evidence = runtime.evidence or {}
    local last_validation = last(instance and instance.boundary and instance.boundary.validations)
    local last_cycle = last(instance and instance.boundary and instance.boundary.cycles)
    return {
        loss = loss_pressure(instance),
        budget = budget_pressure(instance),
        karma = karma_pressure(instance),
        progress = progress,
        payload = payload_pressure or {},
        work_mode = payload.work_mode or tick.work_mode or (instance and instance.metadata and instance.metadata.work_mode),
        last_choice = last(instance and instance.boundary and instance.boundary.choices),
        last_validation = last_validation,
        last_cycle = last_cycle,
        validation_status = last_validation and last_validation.status,
        cycle_decision = last_cycle and last_cycle.decision,
        foundation_state = foundation.state,
        evidence_count = #evidence,
        logic_stamp = runtime.logic_stamp,
        evidence_fingerprint = freshness.evidence_fingerprint(instance),
        calm_status = calm.status,
        has_calm = calm.current ~= nil or progress.needed_count > 0,
    }
end

local function decision(from, to, reason, pressure)
    return {
        kind = "route_decision",
        from = from,
        to = to,
        reason = reason,
        pressure = pressure,
        authority = "legacy_control",
        truth_status = "runtime_confirmed",
    }
end

local function route_observe(pressure)
    local payload = pressure.payload or {}
    if payload.runtime_ready == true then
        return "☱", "runtime_ready"
    end
    if payload.choice_pressure == true then
        return "☳", "choice_pressure"
    end
    if payload.encoding_pressure == true then
        return "☵", "encoding_pressure"
    end
    if pressure.last_choice ~= nil then
        return "☱", "choice_observed"
    end
    if pressure.has_calm and pressure.progress.needed_count > 0 then
        return "☳", "calm_alternatives"
    end
    return "☵", "missing_calm"
end

local function repeated_cycle_warning(pressure)
    local last_cycle = pressure.last_cycle
    if type(last_cycle) ~= "table" then
        return nil
    end
    if last_cycle.decision ~= "again" and last_cycle.reason ~= "remaining_work" then
        return nil
    end

    local warnings = pressure.karma and pressure.karma.warnings or {}
    for _, warning in ipairs(warnings) do
        local warning_body = warning.warning or {}
        local pattern = warning_body.pattern or {}
        if (pattern.last_operator == "☲" or pattern.last_operator == "☱")
            and warning_body.do_not_repeat ~= nil
        then
            return warning
        end
    end
    return nil
end

local function route_runtime(pressure)
    local payload = pressure.payload or {}
    local build_mode = pressure.work_mode == "build"
    if payload.semantic_uncertainty == true then
        return "☴", "semantic_uncertainty"
    end
    if pressure.loss.exhausted or pressure.loss.near_death then
        return "△", "loss_manifest_pressure"
    end
    if pressure.budget.exhausted then
        return "△", "budget_manifest_pressure"
    end
    if payload.validation_pressure == true then
        return "☶", "validation_pressure"
    end
    if build_mode and pressure.validation_status == "rejected" then
        return "☴", "validation_rejected_semantic_repair"
    end
    if build_mode and (
        pressure.cycle_decision == "stop_repetition"
        or pressure.cycle_decision == "stop_budget"
        or pressure.cycle_decision == "stop_invalid"
        or pressure.cycle_decision == "stop_unsafe"
        or pressure.cycle_decision == "needs_user_input"
    ) then
        return "△", "cycle_stop_manifest_pressure"
    end
    if payload.manifest_ready == true then
        return "△", "manifest_ready"
    end
    if pressure.progress.remaining_count > 0 and repeated_cycle_warning(pressure) ~= nil then
        return "△", "karma_warning_manifest_pressure"
    end
    if build_mode and pressure.progress.remaining_count > 0 and pressure.evidence_count <= 0 then
        local stamp = pressure.logic_stamp
        if stamp and stamp.evidence_fingerprint == pressure.evidence_fingerprint then
            return "△", "logic_stamp_no_new_evidence"
        end
        return "☶", "missing_build_evidence"
    end
    if pressure.progress.remaining_count > 0 then
        return "☲", "remaining_work"
    end
    return "△", "no_remaining_work"
end

local function legacy_after_tick(instance, tick, options)
    tick = tick or {}
    options = options or {}
    local from = topology.resolve(tick.operator)
    if not from then
        return nil, "invalid_operator"
    end

    local pressure = legacy_pressure_snapshot(instance, tick)
    local to = hard_next[from]
    local reason = "mandatory_eye_tick"

    if from == "▽" then
        to = topology.resolve(options.start_operator or "☴")
        reason = "runner_entry"
    elseif from == "☴" then
        to, reason = route_observe(pressure)
    elseif from == "☱" then
        to, reason = route_runtime(pressure)
    elseif not to then
        return nil, "unsupported_route_source"
    end

    if not topology.is_adjacent(from, to) then
        return nil, "invalid_route"
    end

    return decision(from, to, reason, pressure)
end

local function record_pressure_snapshot(instance, snapshot)
    local event, err = packet_core.append_trace(instance, {
        type = "tension_measure",
        operator = snapshot.current_operator,
        truth_status = "runtime_confirmed",
        payload = snapshot,
        cost = {},
    })
    if not event then
        return nil, err
    end
    snapshot.trace_event_id = event.id
    return event
end

local function record_shadow(instance, shadow)
    local event, err = packet_core.append_trace(instance, {
        type = "tension_measure",
        operator = shadow.current_operator,
        truth_status = "runtime_confirmed",
        payload = shadow,
        cost = {},
    })
    if not event then
        return nil, err
    end
    shadow.trace_event_id = event.id
    return event
end

local function selected_candidate(prediction)
    for _, candidate in ipairs(prediction and prediction.candidates or {}) do
        if candidate.to == prediction.to then
            return candidate
        end
    end
    return nil
end

local function record_derivation(instance, snapshot, prediction)
    local selected = selected_candidate(prediction)
    local payload = {
        kind = "route_derivation",
        current_operator = snapshot.current_operator,
        pressure_snapshot_ref = snapshot.trace_event_id,
        candidates = prediction.candidates or {},
        outcome = prediction.kind == "tree_route_decision"
            and "selected" or prediction.kind,
        selected_to = prediction.to,
        selected_action_plan_id = selected and selected.action_plan
            and selected.action_plan.plan_id or nil,
        no_viable_cause = prediction.kind == "no_viable_edge"
            and prediction.cause or nil,
        policy = prediction.policy,
        policy_status = prediction.policy_status,
        threshold = prediction.threshold,
    }
    local event, err = packet_core.append_trace(instance, {
        type = "route_derivation",
        operator = snapshot.current_operator,
        truth_status = "runtime_confirmed",
        payload = payload,
        cost = {},
    })
    if not event then
        return nil, err
    end
    return event, payload
end

local function derive_tree_authority(instance, tick, options)
    options = options or {}
    local snapshot, snapshot_err = pressure_module.derive(instance, tick, {
        current_operator = tick.operator,
        options = options.options or {},
    })
    if not snapshot then
        return nil, snapshot_err
    end
    local pressure_event, pressure_err = record_pressure_snapshot(instance, snapshot)
    if not pressure_event then
        return nil, pressure_err
    end

    local prediction, prediction_err = tree_router.predict(instance, snapshot, {
        substrate = options.substrate,
        capabilities = options.capabilities,
        options = options.options or {},
        result = options.result,
        tree = options.tree,
    })
    if not prediction then
        return nil, prediction_err
    end
    local derivation_event, derivation_err = record_derivation(instance, snapshot, prediction)
    if not derivation_event then
        return nil, derivation_err
    end

    if prediction.kind ~= "tree_route_decision" then
        prediction.from = snapshot.current_operator
        prediction.authority = "tree"
        prediction.derivation_ref = derivation_event.id
        prediction.pressure_snapshot_ref = snapshot.trace_event_id
        prediction.truth_status = "runtime_confirmed"
        return prediction
    end

    local selected = selected_candidate(prediction)
    if not selected then
        return nil, "tree decision missing selected candidate"
    end
    return {
        kind = "tree_route_decision",
        from = snapshot.current_operator,
        to = prediction.to,
        reason = prediction.reason,
        authority = "tree",
        derivation_ref = derivation_event.id,
        pressure_snapshot_ref = snapshot.trace_event_id,
        selected_candidate = selected,
        selected_action_plan_id = selected.action_plan
            and selected.action_plan.plan_id or nil,
        candidates = prediction.candidates or {},
        policy = prediction.policy,
        policy_status = prediction.policy_status,
        threshold = prediction.threshold,
        winning_total = prediction.winning_total,
        truth_status = "runtime_confirmed",
    }
end

local function shadow_error(from, live, err)
    return {
        kind = "shadow_route_decision",
        observer = "tree",
        live_authority = "legacy_control",
        current_operator = from,
        candidates = {},
        predicted_to = nil,
        predicted_reason = "prediction_error",
        live_to = live.to,
        agreement = false,
        divergence = "prediction_error:" .. tostring(err),
        instrumentation_status = "error",
        policy = tree_router.policy,
        policy_status = tree_router.policy_status,
        truth_status = "runtime_confirmed",
    }
end

local function derive_shadow(instance, tick, live, options)
    options = options or {}
    local snapshot, snapshot_err = pressure_module.derive(instance, tick, {
        current_operator = tick.operator,
        options = options.options or {},
    })
    if not snapshot then
        return shadow_error(live.from, live, snapshot_err)
    end
    local pressure_event, pressure_err = record_pressure_snapshot(instance, snapshot)
    if not pressure_event then
        return shadow_error(live.from, live, pressure_err)
    end

    local prediction, prediction_err = tree_router.predict(instance, snapshot, {
        substrate = options.substrate,
        capabilities = options.capabilities,
        options = options.options or {},
        result = options.result,
        tree = options.tree,
    })
    if not prediction then
        local failed = shadow_error(live.from, live, prediction_err)
        failed.pressure_snapshot_ref = snapshot.trace_event_id
        return failed
    end

    local predicted_to = prediction.kind == "tree_route_decision" and prediction.to or nil
    local agreement = predicted_to ~= nil and predicted_to == live.to
    local divergence
    if predicted_to == nil then
        divergence = tostring(prediction.kind) .. ":" .. tostring(prediction.cause)
    elseif not agreement then
        divergence = "live:" .. tostring(live.to) .. "/shadow:" .. tostring(predicted_to)
    end
    return {
        kind = "shadow_route_decision",
        observer = "tree",
        live_authority = "legacy_control",
        current_operator = live.from,
        candidates = prediction.candidates or {},
        predicted_to = predicted_to,
        predicted_reason = prediction.reason or prediction.cause,
        prediction_outcome = prediction.kind == "tree_route_decision"
            and "selected" or prediction.kind,
        live_to = live.to,
        agreement = agreement,
        divergence = divergence,
        instrumentation_status = "observed",
        no_viable_edge = prediction.kind ~= "tree_route_decision" and prediction or nil,
        pressure_snapshot_ref = snapshot.trace_event_id,
        policy = prediction.policy or tree_router.policy,
        policy_status = prediction.policy_status or tree_router.policy_status,
        truth_status = "runtime_confirmed",
    }
end

local function legacy_shadow_from_tree(instance, tick, live, options)
    options = options or {}
    local prediction, prediction_err = legacy_after_tick(
        instance,
        tick,
        options.options or {}
    )

    local shadow
    if prediction then
        local agreement = live.to ~= nil and prediction.to == live.to
        local divergence
        if not agreement then
            divergence = "live:" .. tostring(live.to)
                .. "/shadow:" .. tostring(prediction.to)
        end
        shadow = {
            kind = "shadow_route_decision",
            observer = "legacy",
            live_authority = "tree",
            current_operator = live.from,
            candidates = {},
            predicted_to = prediction.to,
            predicted_reason = prediction.reason,
            live_to = live.to,
            live_reason = live.reason or live.cause,
            agreement = agreement,
            divergence = divergence,
            instrumentation_status = "observed",
            tree_derivation_ref = live.derivation_ref,
            policy = legacy_policy,
            policy_status = legacy_policy_status,
            truth_status = "runtime_confirmed",
        }
    elseif prediction_err == "unsupported_route_source" then
        shadow = {
            kind = "shadow_route_decision",
            observer = "legacy",
            live_authority = "tree",
            current_operator = live.from,
            candidates = {},
            predicted_to = nil,
            predicted_reason = prediction_err,
            live_to = live.to,
            live_reason = live.reason or live.cause,
            agreement = false,
            divergence = "legacy_unavailable:" .. prediction_err,
            instrumentation_status = "unavailable",
            tree_derivation_ref = live.derivation_ref,
            policy = legacy_policy,
            policy_status = legacy_policy_status,
            truth_status = "runtime_confirmed",
        }
    else
        return nil, "legacy_shadow:" .. tostring(prediction_err)
    end

    local recorded, record_err = record_shadow(instance, shadow)
    if not recorded then
        return nil, record_err
    end
    return shadow
end

local function shadow_without_authority(instance, tick, live, options)
    local ok, shadow_or_err = pcall(derive_shadow, instance, tick, live, options)
    local shadow
    if ok then
        shadow = shadow_or_err
    else
        shadow = shadow_error(live.from, live, shadow_or_err)
    end
    local recorded, record_err = record_shadow(instance, shadow)
    if not recorded then
        shadow.trace_error = tostring(record_err)
    end
    return shadow
end

function router.after_tick(instance, tick, options)
    tick = tick or {}
    options = options or {}
    local mode = options.mode or "shadow"
    if mode ~= "legacy" and mode ~= "shadow" and mode ~= "tree" then
        return nil, "invalid_router_mode"
    end
    if mode == "tree" then
        local live, live_err = derive_tree_authority(instance, tick, options)
        if not live then
            return nil, live_err
        end
        if options.legacy_shadow ~= false then
            local shadow, shadow_err = legacy_shadow_from_tree(instance, tick, live, options)
            if not shadow then
                return nil, shadow_err
            end
            live.shadow = shadow
        end
        return live
    end

    local live, live_err = legacy_after_tick(instance, tick)
    if not live then
        return nil, live_err
    end
    if mode == "legacy" then
        return live
    end

    local shadow = shadow_without_authority(instance, tick, live, options)
    live.shadow = shadow
    return live
end

router.legacy_after_tick = legacy_after_tick
router.derive_tree_authority = derive_tree_authority
function router.tree_after_tick(instance, tick, options)
    local tree_options = {}
    for key, value in pairs(options or {}) do
        tree_options[key] = value
    end
    tree_options.mode = "tree"
    return router.after_tick(instance, tick, tree_options)
end
router.legacy_shadow_from_tree = legacy_shadow_from_tree

return router
