local packet_core = require("core.packet")

local budget = {}

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
    local runtime_budget = ensure(instance)
    local physis = instance.physis or instance.substrate or {}
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
    local cost = {}
    if type(usage.prompt_tokens) == "number" then
        cost.prompt_tokens = usage.prompt_tokens
    end
    if type(usage.completion_tokens) == "number" then
        cost.completion_tokens = usage.completion_tokens
    end
    if type(usage.total_tokens) == "number" then
        cost.total_tokens = usage.total_tokens
    elseif cost.prompt_tokens or cost.completion_tokens then
        cost.total_tokens = (cost.prompt_tokens or 0) + (cost.completion_tokens or 0)
    end
    return cost
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
    if type(input.cost) ~= "table" then
        return nil, "budget charge requires cost table"
    end

    local runtime_budget = ensure(instance)
    local charged = {}
    for key, value in pairs(input.cost) do
        if AXIS_SET[key] and type(value) == "number" and value ~= 0 then
            charged[key] = value
            runtime_budget.spent[key] = (runtime_budget.spent[key] or 0) + value
            if type(runtime_budget.remaining[key]) == "number" then
                runtime_budget.remaining[key] = runtime_budget.remaining[key] - value
            end
        end
    end

    if instance.revisions then
        instance.revisions.budget = (instance.revisions.budget or 0) + 1
    end

    refresh_exhaustion(runtime_budget)

    local record = {
        kind = "budget_cost",
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
    return record
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
        trace_tail[#trace_tail + 1] = trace[index]
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
