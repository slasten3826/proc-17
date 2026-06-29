local topology = require("core.topology")
local modes = require("core.modes")

local packet = {}

packet.protocol_version = "packet.v0"

packet.statuses = {
    born = true,
    running = true,
    blocked = true,
    dying = true,
    dead = true,
    manifested = true,
}

packet.event_types = {
    birth = true,
    operator_enter = true,
    operator_exit = true,
    observation = true,
    substrate_call = true,
    substrate_result = true,
    phantom_spawn = true,
    phantom_result = true,
    tool_call = true,
    tool_result = true,
    validation = true,
    budget_spend = true,
    hint_pressure = true,
    mode_enter = true,
    unsupported_form = true,
    gap_residue = true,
    choice = true,
    manifest = true,
    death = true,
}

packet.truth_statuses = {
    runtime_confirmed = true,
    semantic_proposal = true,
    unsupported = true,
    rejected = true,
    promoted = true,
    manual = true,
    unknown = true,
}

packet.death_causes = {
    complete = true,
    budget_exhausted = true,
    blocked_by_runtime_truth = true,
    needs_user_input = true,
    invalid_topology = true,
    loop_repetition = true,
    unsafe_scope = true,
    cancelled = true,
}

packet.gap_decisions = {
    reject = true,
    defer = true,
    promote = true,
    decay = true,
}

local id_counter = 0

local function next_id(prefix)
    id_counter = id_counter + 1
    return string.format("%s-%d", prefix, id_counter)
end

local function copy_map(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = value
    end
    return result
end

local function default_budget()
    return {
        steps = 32,
        substrate_calls = 8,
        tool_calls = 16,
        file_writes = 4,
        test_runs = 4,
    }
end

local function normalize_cost(cost)
    return {
        steps = cost and cost.steps or 0,
        substrate_calls = cost and cost.substrate_calls or 0,
        tool_calls = cost and cost.tool_calls or 0,
        file_writes = cost and cost.file_writes or 0,
        test_runs = cost and cost.test_runs or 0,
    }
end

local function validate_status(status)
    return packet.statuses[status] == true
end

local function validate_event(event)
    if type(event) ~= "table" then
        return false, "event must be table"
    end
    if not packet.event_types[event.type] then
        return false, "invalid event type"
    end
    if not topology.is_operator(event.operator) then
        return false, "invalid event operator"
    end
    if not packet.truth_statuses[event.truth_status] then
        return false, "invalid truth status"
    end
    return true
end

function packet.new(task, options)
    options = options or {}
    if type(task) ~= "string" or task == "" then
        error("task must be non-empty string")
    end

    local instance = {
        protocol_version = packet.protocol_version,
        id = options.id or next_id("packet"),
        parent_id = options.parent_id,
        task = task,
        status = "born",
        mode = options.mode or modes.default(),
        operator = "▽",
        budget = copy_map(options.budget or default_budget()),
        pressure = options.pressure or 0,
        trace = {},
        residue = {},
        death = nil,
        context = options.context or {},
        topology = topology.version,
        metadata = options.metadata or {},
    }

    if not modes.is_valid(instance.mode) then
        error("invalid packet mode")
    end

    packet.append(instance, {
        type = "birth",
        operator = "▽",
        truth_status = "runtime_confirmed",
        payload = {task = task, parent_id = instance.parent_id, mode = instance.mode},
        cost = {},
    })

    return instance
end

function packet.enter_mode(instance, mode, reason)
    if not modes.is_valid(mode) then
        return nil, "invalid mode"
    end

    instance.mode = mode
    packet.append(instance, {
        type = "mode_enter",
        operator = instance.operator,
        truth_status = "runtime_confirmed",
        payload = {
            mode = mode,
            reason = reason,
            permissions = modes.describe(mode),
        },
        cost = {},
    })

    return instance
end

function packet.append(instance, event)
    local ok, err = validate_event(event)
    if not ok then
        error(err)
    end

    local stored = {
        id = event.id or next_id("event"),
        type = event.type,
        operator = topology.resolve(event.operator),
        payload = event.payload or {},
        truth_status = event.truth_status,
        cost = normalize_cost(event.cost),
        time = event.time or os.time(),
    }

    instance.trace[#instance.trace + 1] = stored
    return instance
end

function packet.spend(instance, cost)
    local normalized = normalize_cost(cost)
    for key, value in pairs(normalized) do
        instance.budget[key] = (instance.budget[key] or 0) - value
    end

    packet.append(instance, {
        type = "budget_spend",
        operator = instance.operator,
        truth_status = "runtime_confirmed",
        payload = {cost = normalized, budget = copy_map(instance.budget)},
        cost = {},
    })

    for key, value in pairs(instance.budget) do
        if value < 0 then
            instance.status = "dying"
            return nil, "budget exhausted: " .. key
        end
    end

    return instance
end

function packet.enter(instance, operator)
    local next_operator = topology.resolve(operator)
    if not next_operator then
        return nil, "invalid operator"
    end
    if not topology.is_adjacent(instance.operator, next_operator) then
        return nil, "invalid transition"
    end

    instance.operator = next_operator
    if instance.status == "born" then
        instance.status = "running"
    end

    packet.append(instance, {
        type = "operator_enter",
        operator = next_operator,
        truth_status = "runtime_confirmed",
        payload = {operator = next_operator},
        cost = {steps = 1},
    })

    return instance
end

function packet.record_unsupported(instance, form)
    form = form or {}
    local recurrence_key = form.recurrence_key or tostring(form.emitted_form or "unknown")
    local count = 1

    for _, event in ipairs(instance.trace) do
        if event.type == "unsupported_form"
            and event.payload
            and event.payload.recurrence_key == recurrence_key then
            count = count + 1
        end
    end

    return packet.append(instance, {
        type = "unsupported_form",
        operator = instance.operator,
        truth_status = "unsupported",
        payload = {
            emitted_form = form.emitted_form,
            source_event_id = form.source_event_id,
            unsupported_because = form.unsupported_because or "not runtime confirmed",
            recurrence_key = recurrence_key,
            recurrence_count = count,
            decision = form.decision or "defer",
        },
        cost = {},
    })
end

function packet.decide_gap(instance, recurrence_key, decision)
    if not packet.gap_decisions[decision] then
        return nil, "invalid gap decision"
    end

    local truth_status = decision == "promote" and "promoted" or "rejected"
    if decision == "defer" then
        truth_status = "unknown"
    elseif decision == "decay" then
        truth_status = "rejected"
    end

    return packet.append(instance, {
        type = "gap_residue",
        operator = instance.operator,
        truth_status = truth_status,
        payload = {recurrence_key = recurrence_key, decision = decision},
        cost = {},
    })
end

function packet.manifest(instance, payload)
    payload = payload or {}
    local truth_status = payload.truth_status or "runtime_confirmed"
    if truth_status == "unsupported" or truth_status == "semantic_proposal" then
        return nil, "cannot manifest unsupported proposal as final truth"
    end

    instance.status = "manifested"
    packet.append(instance, {
        type = "manifest",
        operator = "△",
        truth_status = truth_status,
        payload = payload,
        cost = {},
    })

    return instance
end

function packet.die(instance, cause)
    if not packet.death_causes[cause] then
        return nil, "invalid death cause"
    end

    instance.status = "dead"
    instance.death = {cause = cause, time = os.time()}
    instance.residue = packet.residue(instance)

    packet.append(instance, {
        type = "death",
        operator = "△",
        truth_status = "runtime_confirmed",
        payload = {cause = cause, residue = instance.residue},
        cost = {},
    })

    return instance
end

function packet.residue(instance)
    local missing = {}
    local failed = {}

    for _, event in ipairs(instance.trace) do
        if event.type == "unsupported_form" then
            missing[#missing + 1] = event.payload.recurrence_key
        elseif event.truth_status == "rejected" then
            failed[#failed + 1] = event.type
        end
    end

    return {
        cause = instance.death and instance.death.cause or "not_dead",
        worked = {},
        failed = failed,
        missing = missing,
        do_not_repeat = {},
        resume_hint = nil,
    }
end

function packet.validate_status(status)
    return validate_status(status)
end

function packet.validate_event(event)
    return validate_event(event)
end

function packet.validate_mode(mode)
    return modes.is_valid(mode)
end

function packet.can_write_code(instance)
    return modes.can_write_code(instance.mode)
end

return packet
