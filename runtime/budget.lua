local packet_core = require("core.packet")

local budget = {}

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

local AXES = {
    "steps",
    "substrate_calls",
    "prompt_tokens",
    "completion_tokens",
    "total_tokens",
    "estimated_tokens",
    "tool_calls",
    "file_writes",
    "test_runs",
    "time_ms",
    "money_units",
}

local AXIS_SET = {}
for _, axis in ipairs(AXES) do
    AXIS_SET[axis] = true
end

local DISCRETE_AXES = {
    steps = true,
    substrate_calls = true,
    prompt_tokens = true,
    completion_tokens = true,
    total_tokens = true,
    estimated_tokens = true,
    tool_calls = true,
    file_writes = true,
    test_runs = true,
}

local function finite_number(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

function budget.validate_cost(cost)
    if type(cost) ~= "table" then
        return nil, "budget charge requires cost table"
    end
    local normalized = {}
    for axis, amount in pairs(cost) do
        if not AXIS_SET[axis] then
            return nil, "unknown budget cost axis: " .. tostring(axis)
        end
        if not finite_number(amount) then
            return nil, "budget cost must be finite number: " .. tostring(axis)
        end
        if amount < 0 then
            return nil, "budget cost must be non-negative: " .. tostring(axis)
        end
        if DISCRETE_AXES[axis] and amount ~= math.floor(amount) then
            return nil, "budget cost must be integer: " .. tostring(axis)
        end
        if amount ~= 0 then
            normalized[axis] = amount
        end
    end
    return normalized
end

function budget.can_pay(instance, cost)
    local required, required_err = budget.validate_cost(cost)
    if not required then
        return nil, required_err
    end
    local snapshot = budget.snapshot(instance)
    local missing = {}
    for axis, amount in pairs(required) do
        local remaining = snapshot.remaining[axis]
        if type(remaining) == "number" and remaining < amount then
            missing[#missing + 1] = axis
        end
    end
    table.sort(missing)
    return #missing == 0, missing
end

local function copy_numeric_axes(source)
    local out = {}
    for _, axis in ipairs(AXES) do
        if type(source and source[axis]) == "number" then
            out[axis] = source[axis]
        end
    end
    return out
end

local function ensure(instance)
    instance.runtime = instance.runtime or {}
    instance.runtime.budget = instance.runtime.budget or {
        spent = {},
        remaining = {},
        events = {},
        exhausted = false,
        exhausted_keys = {},
    }
    local runtime_budget = instance.runtime.budget
    runtime_budget.spent = runtime_budget.spent or {}
    runtime_budget.remaining = runtime_budget.remaining or {}
    runtime_budget.events = runtime_budget.events or {}
    runtime_budget.exhausted_keys = runtime_budget.exhausted_keys or {}
    if runtime_budget.exhausted == nil then
        runtime_budget.exhausted = false
    end
    return runtime_budget
end

local function exhausted_keys(runtime_budget)
    local keys = {}
    for _, axis in ipairs(AXES) do
        local remaining = runtime_budget.remaining[axis]
        if type(remaining) == "number" and remaining <= 0 then
            keys[#keys + 1] = axis
        end
    end
    return keys
end

local function refresh_exhaustion(runtime_budget)
    local keys = exhausted_keys(runtime_budget)
    runtime_budget.exhausted_keys = keys
    runtime_budget.exhausted = #keys > 0
    return runtime_budget.exhausted, keys
end

function budget.init(instance)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "initialize budget")
    if not mutable then
        return nil, mutable_err
    end
    local physis = instance.physis or instance.substrate or {}
    for axis, limit in pairs(physis.budget or {}) do
        if AXIS_SET[axis] then
            if not finite_number(limit) or limit < 0 then
                return nil, "budget limit must be finite number >= 0: " .. tostring(axis)
            end
            if DISCRETE_AXES[axis] and limit ~= math.floor(limit) then
                return nil, "budget limit must be integer: " .. tostring(axis)
            end
        end
    end
    local runtime_budget = ensure(instance)
    local limits = copy_numeric_axes(physis.budget or {})
    for axis, limit in pairs(limits) do
        if runtime_budget.spent[axis] == nil then
            runtime_budget.spent[axis] = 0
        end
        runtime_budget.remaining[axis] = limit - runtime_budget.spent[axis]
    end
    refresh_exhaustion(runtime_budget)
    return instance
end

function budget.from_usage(usage)
    usage = usage or {}
    if type(usage) ~= "table" then
        return nil, "substrate usage must be table"
    end
    local cost = {}
    if usage.prompt_tokens ~= nil then
        cost.prompt_tokens = usage.prompt_tokens
    end
    if usage.completion_tokens ~= nil then
        cost.completion_tokens = usage.completion_tokens
    end
    local total_supplied = usage.total_tokens ~= nil
    if total_supplied then
        cost.total_tokens = usage.total_tokens
    end
    local validated, validate_err = budget.validate_cost(cost)
    if not validated then
        return nil, validate_err
    end
    if not total_supplied
        and (usage.prompt_tokens ~= nil or usage.completion_tokens ~= nil) then
        validated.total_tokens = (validated.prompt_tokens or 0)
            + (validated.completion_tokens or 0)
    end
    return validated
end

function budget.estimate_tokens(text, options)
    options = options or {}
    local chars_per_token = options.chars_per_token or 4
    if chars_per_token <= 0 then
        chars_per_token = 4
    end
    return math.ceil(#tostring(text or "") / chars_per_token)
end

function budget.charge(instance, input)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "charge budget")
    if not mutable then
        return nil, mutable_err
    end
    input = input or {}
    local charged, cost_err = budget.validate_cost(input.cost)
    if not charged then
        return nil, cost_err
    end

    if next(charged) == nil then
        local snapshot = budget.snapshot(instance)
        return {
            kind = "budget_cost",
            status = "no_op",
            operator = input.operator,
            event_id = input.event_id,
            cost = {},
            source = input.source or "body_tick",
            truth_status = input.truth_status or "runtime_confirmed",
            spent_after = snapshot.spent,
            remaining_after = snapshot.remaining,
            exhausted = snapshot.exhausted,
            exhausted_keys = snapshot.exhausted_keys,
        }
    end

    local runtime_budget = ensure(instance)
    for key, value in pairs(charged) do
        runtime_budget.spent[key] = (runtime_budget.spent[key] or 0) + value
        if type(runtime_budget.remaining[key]) == "number" then
            runtime_budget.remaining[key] = runtime_budget.remaining[key] - value
        end
    end

    if instance.revisions then
        instance.revisions.budget = (instance.revisions.budget or 0) + 1
    end

    refresh_exhaustion(runtime_budget)

    local record = {
        kind = "budget_cost",
        status = "charged",
        operator = input.operator,
        event_id = input.event_id,
        cost = charged,
        source = input.source or "body_tick",
        truth_status = input.truth_status or "runtime_confirmed",
        spent_after = copy_numeric_axes(runtime_budget.spent),
        remaining_after = copy_numeric_axes(runtime_budget.remaining),
        exhausted = runtime_budget.exhausted,
        exhausted_keys = {table.unpack(runtime_budget.exhausted_keys)},
    }
    runtime_budget.events[#runtime_budget.events + 1] = record
    return copy_value(record)
end

function budget.snapshot(instance)
    local runtime_budget = instance and instance.runtime and instance.runtime.budget or {}
    local remaining = runtime_budget.remaining
    if type(remaining) ~= "table" then
        local physis = instance and (instance.physis or instance.substrate) or {}
        remaining = copy_numeric_axes(physis.budget or {})
    end
    local keys = exhausted_keys({remaining = remaining})
    return {
        kind = "runtime_budget_snapshot",
        spent = copy_numeric_axes(runtime_budget.spent),
        remaining = copy_numeric_axes(remaining),
        exhausted = #keys > 0,
        exhausted_keys = keys,
        event_count = #(runtime_budget.events or {}),
        truth_status = "runtime_confirmed",
    }
end

function budget.is_exhausted(instance)
    local snapshot = budget.snapshot(instance)
    return snapshot.exhausted, snapshot.exhausted_keys
end

function budget.exhaustion_residue(instance, options)
    options = options or {}
    local snapshot = budget.snapshot(instance)
    local progress = options.progress or {}
    local trace = instance.trace or {}
    local trace_tail = {}
    local tail_count = options.trace_tail_count or 5
    local start = math.max(1, #trace - tail_count + 1)
    for index = start, #trace do
        trace_tail[#trace_tail + 1] = copy_value(trace[index])
    end
    return {
        cause = "budget_exhausted",
        exhausted_keys = {table.unpack(snapshot.exhausted_keys or {})},
        last_operator = options.last_operator or instance.operator,
        trace_tail = trace_tail,
        remaining_work_count = progress.remaining_count,
        do_not_repeat = "loop consumed budget without progress",
    }
end

return budget
