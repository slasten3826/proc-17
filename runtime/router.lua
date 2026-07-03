local topology = require("core.topology")
local body = require("runtime.body")

local router = {}

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
    local budget = instance and instance.substrate and instance.substrate.budget or {}
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

local function pressure_snapshot(instance, tick)
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
    if build_mode and pressure.progress.remaining_count > 0 and pressure.evidence_count <= 0 then
        return "☶", "missing_build_evidence"
    end
    if pressure.progress.remaining_count > 0 then
        return "☲", "remaining_work"
    end
    return "△", "no_remaining_work"
end

function router.after_tick(instance, tick)
    tick = tick or {}
    local from = topology.resolve(tick.operator)
    if not from then
        return nil, "invalid_operator"
    end

    local pressure = pressure_snapshot(instance, tick)
    local to = hard_next[from]
    local reason = "mandatory_eye_tick"

    if from == "☴" then
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

return router
