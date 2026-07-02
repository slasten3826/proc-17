local cycle = require("logic.cycle")
local packet_core = require("core.packet")

local body = {}

local function ensure_list(parent, key)
    if type(parent[key]) ~= "table" then
        parent[key] = {}
    end
    return parent[key]
end

local function copy_array(source)
    local result = {}
    for index, value in ipairs(source or {}) do
        result[index] = value
    end
    return result
end

local function unit_id(unit, index)
    if type(unit) == "table" and unit.id ~= nil then
        return tostring(unit.id)
    end
    return tostring(index)
end

local function is_done(unit)
    return type(unit) == "table" and unit.status == "done"
end

local function work_units(instance)
    if type(instance) ~= "table" or type(instance.calm) ~= "table" then
        return {}
    end
    if type(instance.calm.work_units) == "table" and #instance.calm.work_units > 0 then
        return instance.calm.work_units
    end
    local current = instance.calm.current
    if type(current) == "table" and type(current.units) == "table" then
        return current.units
    end
    return {}
end

local function budget(instance)
    if type(instance) ~= "table" or type(instance.substrate) ~= "table" then
        return {}
    end
    return instance.substrate.budget or {}
end

function body.progress(instance, options)
    options = options or {}
    local units = work_units(instance)
    local done = {}
    local remaining = {}

    for index, unit in ipairs(units) do
        local id = unit_id(unit, index)
        if is_done(unit) then
            done[#done + 1] = id
        else
            remaining[#remaining + 1] = id
        end
    end

    local logic_status = options.logic_status
    if logic_status == nil then
        logic_status = "accepted"
    end

    return {
        goal = options.goal or (instance and instance.chaos and instance.chaos.raw_prompt) or nil,
        needed_count = #units,
        done_count = #done,
        remaining_count = #remaining,
        done = done,
        remaining = remaining,
        logic_status = logic_status,
    }
end

function body.record_choice(instance, choice_payload)
    choice_payload = choice_payload or {}
    local choices = ensure_list(instance.boundary, "choices")
    choices[#choices + 1] = choice_payload
    packet_core.append_trace(instance, {
        type = "choice",
        operator = "☳",
        truth_status = choice_payload.truth_status or "runtime_confirmed",
        payload = choice_payload,
        cost = choice_payload.cost or {},
    })
    return choice_payload
end

function body.record_validation(instance, validation_payload)
    validation_payload = validation_payload or {}
    local validations = ensure_list(instance.boundary, "validations")
    validations[#validations + 1] = validation_payload
    packet_core.append_trace(instance, {
        type = "validation",
        operator = "☶",
        truth_status = validation_payload.truth_status or "runtime_confirmed",
        payload = validation_payload,
        cost = validation_payload.cost or {},
    })
    return validation_payload
end

function body.record_cycle(instance, cycle_payload)
    cycle_payload = cycle_payload or {}
    local cycles = ensure_list(instance.boundary, "cycles")
    cycles[#cycles + 1] = cycle_payload
    packet_core.append_trace(instance, {
        type = "cycle",
        operator = "☲",
        truth_status = cycle_payload.truth_status or "runtime_confirmed",
        payload = cycle_payload,
        cost = cycle_payload.cost or {},
    })
    return cycle_payload
end

function body.cycle_input(instance, options)
    options = options or {}
    return {
        cycle_key = options.cycle_key or "packet_body",
        turn_count = options.turn_count or 0,
        max_turns = options.max_turns or 1,
        budget = options.budget or budget(instance),
        required_budget = options.required_budget or {steps = 1},
        state_fingerprint = options.state_fingerprint,
        previous_fingerprints = options.previous_fingerprints,
        manifest_ready = options.manifest_ready,
        unsafe = options.unsafe,
        needs_user_input = options.needs_user_input,
        progress = body.progress(instance, {
            goal = options.goal,
            logic_status = options.logic_status,
        }),
    }
end

function body.decide_cycle(instance, options)
    local payload, err = cycle.decide(body.cycle_input(instance, options))
    if not payload then
        return nil, err
    end
    body.record_cycle(instance, payload)
    return payload
end

function body.apply_crystallized_work(instance, units, options)
    options = options or {}
    instance.calm.work_units = copy_array(units)
    instance.calm.status = options.status or instance.calm.status or "accepted"
    return body.progress(instance, {
        goal = options.goal,
        logic_status = options.logic_status,
    })
end

return body
