local pressure_snapshot = {}

local function copy_array(source, start_index)
    local result = {}
    if type(source) ~= "table" then
        return result
    end
    for index = start_index or 1, #source do
        result[#result + 1] = source[index]
    end
    return result
end

local function copy_map(source)
    local result = {}
    if type(source) ~= "table" then
        return result
    end
    for key, value in pairs(source) do
        result[key] = value
    end
    return result
end

local function normalize_limits(limits)
    limits = limits or {}
    if type(limits) ~= "table" then
        return nil, "invalid_limits"
    end

    local trace_tail_count = limits.trace_tail_count
    if trace_tail_count == nil then
        trace_tail_count = 3
    end
    if type(trace_tail_count) ~= "number" or trace_tail_count < 0 then
        return nil, "invalid_limits"
    end

    return {
        trace_tail_count = math.floor(trace_tail_count),
        include_residue = limits.include_residue ~= false,
        include_budget = limits.include_budget ~= false,
        include_pressure_sections = limits.include_pressure_sections ~= false,
    }
end

local function negative_keys(budget)
    local result = {}
    for key, value in pairs(budget) do
        if type(value) == "number" and value < 0 then
            result[#result + 1] = key
        end
    end
    table.sort(result)
    return result
end

local function exhausted_keys(budget)
    local result = {}
    for key, value in pairs(budget) do
        if type(value) == "number" and value <= 0 then
            result[#result + 1] = key
        end
    end
    table.sort(result)
    return result
end

local function last_event(trace)
    return trace[#trace]
end

local function count_residue(residue)
    if type(residue) ~= "table" then
        return 0
    end
    local count = 0
    for _ in pairs(residue) do
        count = count + 1
    end
    return count
end

local function as_context(value)
    if type(value) == "table" then
        return value
    end
    return {}
end

function pressure_snapshot.snapshot(input)
    input = input or {}
    local instance = input.packet
    if type(instance) ~= "table" then
        return nil, "missing_packet"
    end
    if type(instance.trace) ~= "table" then
        return nil, "invalid_trace"
    end
    if type(instance.budget) ~= "table" then
        return nil, "invalid_budget"
    end

    local limits, limits_err = normalize_limits(input.limits)
    if not limits then
        return nil, limits_err
    end

    local trace_count = #instance.trace
    local tail_start = trace_count - limits.trace_tail_count + 1
    if tail_start < 1 then
        tail_start = 1
    end

    local event = last_event(instance.trace)
    local budget_copy = copy_map(instance.budget)
    local negative = negative_keys(budget_copy)
    local exhausted = exhausted_keys(budget_copy)
    local residue_count = count_residue(instance.residue)
    local logic_context = as_context(input.logic_context)
    local cycle_context = as_context(input.cycle_context)
    local manifest_context = as_context(input.manifest_context)

    return {
        kind = "runtime_pressure_snapshot_payload",
        packet_id = instance.id,
        protocol_version = instance.protocol_version,
        status = instance.status,
        mode = instance.mode,
        operator = instance.operator,
        packet_state = {
            status = instance.status,
            mode = instance.mode,
            operator = instance.operator,
            tick_count = instance.tick_count or trace_count,
        },
        budget_pressure = {
            budget = limits.include_budget and budget_copy or nil,
            budget_negative_keys = negative,
            budget_exhausted_keys = exhausted,
        },
        trace_pressure = {
            trace_count = trace_count,
            trace_tail = copy_array(instance.trace, tail_start),
            last_event = event,
            last_event_type = event and event.type or nil,
            last_truth_status = event and event.truth_status or nil,
        },
        logic_pressure = {
            last_validation_event = logic_context.last_validation_event,
            accepted_count = logic_context.accepted_count or 0,
            rejected_count = logic_context.rejected_count or 0,
            rejection_reasons = copy_array(logic_context.rejection_reasons),
        },
        cycle_pressure = {
            last_cycle_decision = cycle_context.last_cycle_decision,
            last_cycle_reasons = copy_array(cycle_context.last_cycle_reasons),
            repeated_fingerprint = cycle_context.repeated_fingerprint == true,
            turn_budget_pressure = cycle_context.turn_budget_pressure,
        },
        manifest_pressure = {
            last_manifest_event = manifest_context.last_manifest_event,
            pending_output_shape = manifest_context.pending_output_shape,
            output_pressure = manifest_context.output_pressure,
        },
        death_pressure = {
            status_dead = instance.status == "dead",
            status_dying = instance.status == "dying",
            residue_count = residue_count,
            death_residue_present = instance.death ~= nil or residue_count > 0,
        },
        conditions = {
            status_dead = instance.status == "dead",
            status_dying = instance.status == "dying",
            budget_negative = #negative > 0,
            budget_exhausted_keys = exhausted,
            has_trace = trace_count > 0,
            has_residue = residue_count > 0,
            last_truth_status = event and event.truth_status or nil,
            last_event_type = event and event.type or nil,
            last_validation_event = logic_context.last_validation_event,
            last_cycle_decision = cycle_context.last_cycle_decision,
            last_manifest_event = manifest_context.last_manifest_event,
        },
        limits = limits,
        truth_status = "runtime_confirmed",
    }
end

return pressure_snapshot
