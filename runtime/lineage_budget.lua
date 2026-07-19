local json = require("core.json")

local lineage_budget = {}

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
    "generations",
    "carrier_bytes",
}

local AXIS_SET = {}
for _, axis in ipairs(AXES) do
    AXIS_SET[axis] = true
end

local DISCRETE = {
    steps = true,
    substrate_calls = true,
    prompt_tokens = true,
    completion_tokens = true,
    total_tokens = true,
    estimated_tokens = true,
    tool_calls = true,
    file_writes = true,
    test_runs = true,
    generations = true,
    carrier_bytes = true,
}

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

local function finite(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function validate_axis_value(axis, value, allow_unlimited)
    if allow_unlimited and value == "unlimited" then
        return true
    end
    if not finite(value) or value < 0 then
        return nil, axis .. " must be finite number >= 0"
    end
    if DISCRETE[axis] and value ~= math.floor(value) then
        return nil, axis .. " must be integer"
    end
    return true
end

local function normalize(input, allow_unlimited)
    if type(input) ~= "table" then
        return nil, "lineage budget values must be table"
    end
    local result = {}
    for axis, value in pairs(input) do
        if not AXIS_SET[axis] then
            return nil, "unknown lineage budget axis: " .. tostring(axis)
        end
        local valid, valid_err = validate_axis_value(axis, value, allow_unlimited)
        if not valid then
            return nil, valid_err
        end
        if value ~= 0 then
            result[axis] = value
        end
    end
    return result
end

local function refresh(state)
    local exhausted_keys = {}
    local remaining = {}
    for _, axis in ipairs(AXES) do
        local limit = state.limits[axis]
        local spent = state.spent[axis] or 0
        if limit == "unlimited" or limit == nil then
            remaining[axis] = "unlimited"
        else
            remaining[axis] = limit - spent
            if remaining[axis] <= 0 then
                exhausted_keys[#exhausted_keys + 1] = axis
            end
        end
    end
    state.remaining = remaining
    state.exhausted_keys = exhausted_keys
    state.exhausted = #exhausted_keys > 0
end

local function validate_state(state)
    if type(state) ~= "table" or state.kind ~= "lineage_budget"
        or state.protocol_version ~= "lineage.budget.v0" then
        return nil, "invalid lineage budget"
    end
    return true
end

function lineage_budget.new(limits)
    limits = limits or {}
    local normalized, normalized_err = normalize(limits, true)
    if not normalized then
        return nil, normalized_err
    end
    local state = {
        kind = "lineage_budget",
        protocol_version = "lineage.budget.v0",
        limits = normalized,
        spent = {},
        remaining = {},
        events = {},
        charged_keys = {},
        exhausted = false,
        exhausted_keys = {},
    }
    refresh(state)
    return state
end

function lineage_budget.can_allocate(state, allocation)
    local valid, valid_err = validate_state(state)
    if not valid then
        return nil, valid_err
    end
    local normalized, normalized_err = normalize(allocation or {}, false)
    if not normalized then
        return nil, normalized_err
    end
    for axis, amount in pairs(normalized) do
        local remaining = state.remaining[axis]
        if type(remaining) == "number" and amount > remaining then
            return nil, "lineage budget cannot allocate " .. axis
        end
    end
    return true
end

function lineage_budget.charge(state, key, cost, source_refs, options)
    options = options or {}
    local valid, valid_err = validate_state(state)
    if not valid then
        return nil, valid_err
    end
    if type(key) ~= "string" or key == "" then
        return nil, "lineage budget charge key is required"
    end
    if state.charged_keys[key] ~= nil then
        local existing = state.events[state.charged_keys[key]]
        local normalized, normalized_err = normalize(cost or {}, false)
        if not normalized then
            return nil, normalized_err
        end
        if json.encode(existing.cost or {}) ~= json.encode(normalized) then
            return nil, "lineage budget charge key reused with different cost"
        end
        if json.encode(existing.source_refs or {}) ~= json.encode(source_refs or {}) then
            return nil, "lineage budget charge key reused with different source"
        end
        return copy_value(existing)
    end
    local normalized, normalized_err = normalize(cost or {}, false)
    if not normalized then
        return nil, normalized_err
    end
    if options.allow_overdraw ~= true then
        local allocatable, allocation_err = lineage_budget.can_allocate(state, normalized)
        if not allocatable then
            return nil, allocation_err
        end
    end

    for axis, amount in pairs(normalized) do
        state.spent[axis] = (state.spent[axis] or 0) + amount
    end
    local event = {
        kind = "lineage_budget_spent",
        protocol_version = "lineage.budget.event.v0",
        key = key,
        cost = copy_value(normalized),
        source_refs = copy_value(source_refs or {}),
        event_truth_status = "runtime_confirmed",
    }
    state.events[#state.events + 1] = event
    state.charged_keys[key] = #state.events
    refresh(state)
    event.spent_after = copy_value(state.spent)
    event.remaining_after = copy_value(state.remaining)
    event.exhausted = state.exhausted
    event.exhausted_keys = copy_value(state.exhausted_keys)
    return copy_value(event)
end

function lineage_budget.reconcile_packet(state, corpse)
    if type(corpse) ~= "table" or type(corpse.packet_id) ~= "string" then
        return nil, "corpse with packet id is required for budget reconciliation"
    end
    local final_budget = corpse.final_budget or {}
    local spent = final_budget.spent or {}
    local normalized, normalized_err = normalize(spent, false)
    if not normalized then
        return nil, "invalid corpse budget: " .. tostring(normalized_err)
    end
    return lineage_budget.charge(
        state,
        "packet:" .. corpse.packet_id,
        normalized,
        {corpse.corpse_id, corpse.packet_id},
        {allow_overdraw = true}
    )
end

function lineage_budget.snapshot(state)
    local valid, valid_err = validate_state(state)
    if not valid then
        return nil, valid_err
    end
    return copy_value({
        kind = state.kind,
        protocol_version = state.protocol_version,
        limits = state.limits,
        spent = state.spent,
        remaining = state.remaining,
        event_count = #state.events,
        exhausted = state.exhausted,
        exhausted_keys = state.exhausted_keys,
    })
end

lineage_budget.axes = copy_value(AXES)

return lineage_budget
