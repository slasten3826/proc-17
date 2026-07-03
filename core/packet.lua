local topology = require("core.topology")

local packet = {}

packet.protocol_version = "packet.next.v0"

packet.statuses = {
    born = true,
    running = true,
    dying = true,
    dead = true,
    manifested = true,
}

packet.truth_statuses = {
    runtime_confirmed = true,
    semantic_proposal = true,
    unsupported = true,
    rejected = true,
    unknown = true,
}

packet.event_types = {
    birth = true,
    chaos_append = true,
    crystallization = true,
    choice = true,
    validation = true,
    cycle = true,
    tension_measure = true,
    manifest = true,
    death = true,
}

packet.death_causes = {
    complete = true,
    budget_exhausted = true,
    identity_loss = true,
    invalid_topology = true,
    unsafe_scope = true,
    cancelled = true,
}

local id_counter = 0

local function next_id(prefix)
    id_counter = id_counter + 1
    return string.format("%s-%d", prefix, id_counter)
end

local function shallow_copy(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = value
    end
    return result
end

local function default_budget()
    return {
        steps = 64,
        substrate_calls = 8,
        tool_calls = 16,
        file_writes = 8,
        test_runs = 8,
        loss = 1.0,
    }
end

local function normalize_cost(cost)
    return {
        steps = cost and cost.steps or 0,
        substrate_calls = cost and cost.substrate_calls or 0,
        tool_calls = cost and cost.tool_calls or 0,
        file_writes = cost and cost.file_writes or 0,
        test_runs = cost and cost.test_runs or 0,
        loss = cost and cost.loss or 0,
    }
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

local function append_trace(instance, event)
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
    return stored
end

local function init_areas(prompt, options)
    local budget = shallow_copy(options.budget or default_budget())
    return {
        substrate = {
            budget = budget,
            clock = {ticks = 0},
            sandbox = options.sandbox or {},
            host = options.host or {},
        },
        chaos = {
            raw_prompt = prompt,
            fragments = {},
            unresolved_pressure = {},
            fingerprints = {},
            drift = {},
            observations = {},
        },
        boundary = {
            observations = {},
            crystallizations = {},
            loss_records = {},
            choices = {},
            validations = {},
            cycles = {},
        },
        calm = {
            structures = {},
            constraints = {},
            executable_fragments = {},
            work_units = {},
            current = nil,
            status = nil,
        },
        tension = {
            chaos_pressure = nil,
            calm_rigidity = nil,
            boundary_load = nil,
            unresolved_delta = nil,
            action_pressure = nil,
        },
        runtime = {
            foundation = {
                patterns = {},
                stability = 0,
                state = "fluid",
                reinforcements = 0,
            },
            evidence = {},
        },
        manifest = nil,
    }
end

function packet.new(prompt, options)
    options = options or {}
    if type(prompt) ~= "string" or prompt == "" then
        error("prompt must be non-empty string")
    end

    local areas = init_areas(prompt, options)
    local instance = {
        protocol_version = packet.protocol_version,
        id = options.id or next_id("packet"),
        parent_id = options.parent_id,
        status = "born",
        operator = "▽",
        topology = topology.version,
        substrate = areas.substrate,
        chaos = areas.chaos,
        boundary = areas.boundary,
        calm = areas.calm,
        tension = areas.tension,
        runtime = areas.runtime,
        trace = {},
        residue = {},
        death = nil,
        manifest = areas.manifest,
        metadata = options.metadata or {},
    }

    append_trace(instance, {
        type = "birth",
        operator = "▽",
        truth_status = "runtime_confirmed",
        payload = {
            raw_prompt = prompt,
            packet_id = instance.id,
            parent_id = instance.parent_id,
        },
        cost = {},
    })

    return instance
end

function packet.append_chaos(instance, fragment)
    fragment = fragment or {}
    instance.chaos.fragments[#instance.chaos.fragments + 1] = fragment
    local event = append_trace(instance, {
        type = "chaos_append",
        operator = fragment.operator or "☴",
        truth_status = fragment.truth_status or "semantic_proposal",
        payload = fragment,
        cost = fragment.cost or {},
    })
    return instance, event
end

function packet.crystallize(instance, record)
    record = record or {}
    if type(record.loss) ~= "table" then
        return nil, "crystallization requires loss table"
    end
    if record.loss.kind == nil then
        return nil, "crystallization loss requires kind"
    end
    if type(record.calm_delta) ~= "table" then
        return nil, "crystallization requires calm_delta table"
    end

    local event = append_trace(instance, {
        type = "crystallization",
        operator = "☵",
        truth_status = record.truth_status or "runtime_confirmed",
        payload = {
            source_chaos_refs = record.source_chaos_refs or {},
            calm_delta = record.calm_delta,
            loss = record.loss,
            status = record.status or "accepted",
        },
        cost = {loss = record.loss.amount or 0},
    })

    local crystal = {
        source_chaos_refs = record.source_chaos_refs or {},
        calm_delta = record.calm_delta,
        loss = record.loss,
        status = record.status or "accepted",
        trace_event_id = event.id,
    }

    instance.boundary.crystallizations[#instance.boundary.crystallizations + 1] = crystal
    instance.boundary.loss_records[#instance.boundary.loss_records + 1] = {
        loss = record.loss,
        trace_event_id = event.id,
    }
    instance.calm.structures[#instance.calm.structures + 1] = record.calm_delta
    instance.calm.current = record.calm_delta
    instance.calm.status = crystal.status

    return instance, event
end

function packet.measure_tension(instance, record)
    record = record or {}
    for key, value in pairs(record) do
        instance.tension[key] = value
    end
    local event = append_trace(instance, {
        type = "tension_measure",
        operator = record.operator or "☱",
        truth_status = record.truth_status or "runtime_confirmed",
        payload = record,
        cost = record.cost or {},
    })
    return instance, event
end

function packet.manifest_packet(instance, payload)
    payload = payload or {}
    instance.manifest = payload
    instance.status = "manifested"
    local event = append_trace(instance, {
        type = "manifest",
        operator = "△",
        truth_status = payload.truth_status or "runtime_confirmed",
        payload = payload,
        cost = {},
    })
    return instance, event
end

function packet.die(instance, cause, residue)
    if not packet.death_causes[cause] then
        return nil, "invalid death cause"
    end
    instance.status = "dead"
    instance.death = {
        cause = cause,
        time = os.time(),
    }
    instance.residue = residue or {cause = cause}
    local event = append_trace(instance, {
        type = "death",
        operator = instance.operator or "△",
        truth_status = "runtime_confirmed",
        payload = {
            cause = cause,
            residue = instance.residue,
        },
        cost = {},
    })
    return instance, event
end

function packet.append_trace(instance, event)
    return append_trace(instance, event)
end

return packet
