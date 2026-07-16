local topology = require("core.topology")

local packet = {}

packet.protocol_version = "packet.next.v1"

packet.birth_kinds = {
    user = true,
    network_reentry = true,
    recovery = true,
}

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
    operator_tick = true,
    route = true,
    chaos_append = true,
    crystallization = true,
    identity_map = true,
    relation_snapshot = true,
    relation_mutation = true,
    observation = true,
    choice = true,
    validation = true,
    cycle = true,
    tension_measure = true,
    manifest = true,
    death = true,
    terminal = true,
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

local function init_identity(packet_id, options)
    local generation = options.generation or 1
    if type(generation) ~= "number" or generation < 1 or generation ~= math.floor(generation) then
        error("generation must be integer >= 1")
    end

    local birth_kind = options.birth_kind or "user"
    if not packet.birth_kinds[birth_kind] then
        error("invalid birth kind")
    end

    if generation == 1 and birth_kind == "user" and options.parent_corpse_id ~= nil then
        error("user birth generation 1 cannot have parent corpse")
    end
    if generation > 1 then
        if type(options.lineage_id) ~= "string" or options.lineage_id == "" then
            error("generation > 1 requires lineage id")
        end
        if type(options.parent_corpse_id) ~= "string" or options.parent_corpse_id == "" then
            error("generation > 1 requires parent corpse id")
        end
    end
    if birth_kind ~= "user" and (type(options.carrier_id) ~= "string" or options.carrier_id == "") then
        error(birth_kind .. " birth requires carrier id")
    end

    return {
        lineage_id = options.lineage_id or packet_id,
        generation = generation,
        parent_corpse_id = options.parent_corpse_id,
        birth_kind = birth_kind,
        carrier_id = options.carrier_id,
        substrate_session_id = options.substrate_session_id,
    }
end

local function init_revisions()
    return {
        potential = 0,
        relations_raw = 0,
        relations_active = 0,
        momentum = 0,
        calm = 0,
        constraints = 0,
        evidence = 0,
        history = 0,
        scalars = 0,
        budget = 0,
        loss = 0,
    }
end

local function init_field()
    return {
        protocol_version = "field.v0",
        next_unit_id = 1,
        next_relation_id = 1,
        unit_order = {},
        units = {},
        relations = {
            raw = {
                epoch = 0,
                source_revision = 0,
                items = {},
            },
            active = {},
            momentum = {},
        },
        identity_maps = {},
    }
end

local function init_regime()
    return {
        encoding = {
            policy_id = nil,
            bounds = {},
        },
        choice = {
            policy_id = nil,
            bounds = {},
        },
        cycle = {
            phase = 0,
            recurrence_key = nil,
        },
        logic = {
            contract_id = nil,
        },
        runtime = {
            momentum_policy_id = nil,
        },
        manifest = {
            output_policy_id = nil,
        },
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

function packet.assert_mutable(instance, operation)
    operation = operation or "mutate"
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    if instance.status == "dead" then
        return nil, "dead packet cannot " .. operation
    end
    if instance.status == "dying" or instance.status == "manifested" or instance.terminal ~= nil then
        return nil, "terminal packet cannot " .. operation
    end
    return true
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
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        tick = instance.physis and instance.physis.clock and instance.physis.clock.ticks or 0,
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
    local upper_observations = {}
    local lower_observations = {}
    local memory_options = options.memory or {}
    local memory_enabled = options.memory_enabled
    if memory_enabled == nil then
        memory_enabled = memory_options.enabled == true
    end
    return {
        physis = {
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
            observations = upper_observations,
        },
        boundary = {
            observations = {
                upper = upper_observations,
                lower = lower_observations,
            },
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
            memory = {
                enabled = memory_enabled == true,
                inherited_residue = memory_enabled == true and (options.inherited_residue or {}) or {},
            },
            karma = {
                warnings = {},
                bequests = {},
                neutral = {},
            },
        },
        manifest = nil,
    }
end

function packet.new(prompt, options)
    options = options or {}
    if type(prompt) ~= "string" or prompt == "" then
        error("prompt must be non-empty string")
    end

    local packet_id = options.id or next_id("packet")
    local identity = init_identity(packet_id, options)
    local areas = init_areas(prompt, options)
    local instance = {
        protocol_version = packet.protocol_version,
        id = packet_id,
        lineage_id = identity.lineage_id,
        generation = identity.generation,
        parent_id = options.parent_id,
        parent_corpse_id = identity.parent_corpse_id,
        birth_kind = identity.birth_kind,
        carrier_id = identity.carrier_id,
        substrate_session_id = identity.substrate_session_id,
        status = "born",
        operator = "▽",
        topology = topology.version,
        revisions = init_revisions(),
        physis = areas.physis,
        substrate = areas.physis,
        chaos = areas.chaos,
        field = init_field(),
        boundary = areas.boundary,
        calm = areas.calm,
        regime = init_regime(),
        tension = areas.tension,
        runtime = areas.runtime,
        trace = {},
        residue = {},
        death = nil,
        manifest = areas.manifest,
        terminal = nil,
        metadata = options.metadata or {},
    }

    append_trace(instance, {
        type = "birth",
        operator = "▽",
        truth_status = "runtime_confirmed",
        payload = {
            raw_prompt = prompt,
            packet_id = instance.id,
            lineage_id = instance.lineage_id,
            generation = instance.generation,
            parent_id = instance.parent_id,
            parent_corpse_id = instance.parent_corpse_id,
            birth_kind = instance.birth_kind,
            carrier_id = instance.carrier_id,
            substrate_session_id = instance.substrate_session_id,
            inherited_residue_count = #(instance.runtime.memory.inherited_residue or {}),
        },
        cost = {},
    })

    return instance
end

function packet.begin_tick(instance, operator, input_refs)
    local mutable, mutable_err = packet.assert_mutable(instance, "begin tick")
    if not mutable then
        return nil, mutable_err
    end

    local resolved = topology.resolve(operator)
    if not resolved then
        return nil, "invalid tick operator"
    end
    if resolved ~= instance.operator then
        return nil, "tick operator does not match packet position"
    end
    if input_refs ~= nil and type(input_refs) ~= "table" then
        return nil, "tick input refs must be table"
    end

    if instance.status == "born" then
        instance.status = "running"
    end
    return append_trace(instance, {
        type = "operator_tick",
        operator = resolved,
        truth_status = "runtime_confirmed",
        payload = {
            input_refs = input_refs or {},
        },
        cost = {},
    })
end

function packet.commit_transition(instance, decision)
    local mutable, mutable_err = packet.assert_mutable(instance, "commit transition")
    if not mutable then
        return nil, mutable_err
    end
    if type(decision) ~= "table" then
        return nil, "route decision required"
    end

    local from = topology.resolve(decision.from)
    local to = topology.resolve(decision.to)
    if not from or not to then
        return nil, "route decision requires valid operators"
    end
    if from ~= instance.operator then
        return nil, "route source does not match packet position"
    end
    if from == "△" then
        return nil, "manifest operator has no same-life successor"
    end
    if to == "▽" then
        return nil, "living packet cannot return to flow"
    end
    if not topology.is_adjacent(from, to) then
        return nil, "invalid operator transition"
    end

    local event = append_trace(instance, {
        type = "route",
        operator = to,
        truth_status = "runtime_confirmed",
        payload = {
            kind = decision.kind or "route_decision",
            from = from,
            to = to,
            reason = decision.reason,
            pressure = decision.pressure,
        },
        cost = decision.cost or {},
    })
    instance.operator = to
    if instance.status == "born" then
        instance.status = "running"
    end
    return event
end

function packet.append_chaos(instance, fragment)
    local alive, alive_err = packet.assert_mutable(instance, "append chaos")
    if not alive then
        return nil, alive_err
    end
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
    local alive, alive_err = packet.assert_mutable(instance, "crystallize")
    if not alive then
        return nil, alive_err
    end
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
    instance.revisions.calm = instance.revisions.calm + 1

    return instance, event
end

function packet.measure_tension(instance, record)
    local alive, alive_err = packet.assert_mutable(instance, "measure tension")
    if not alive then
        return nil, alive_err
    end
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

local function copy_array(source)
    local result = {}
    for index, value in ipairs(source or {}) do
        result[index] = value
    end
    return result
end

local function budget_snapshot(instance)
    local runtime_budget = instance.runtime and instance.runtime.budget or {}
    return {
        spent = shallow_copy(runtime_budget.spent),
        remaining = shallow_copy(runtime_budget.remaining),
        exhausted = runtime_budget.exhausted == true,
        exhausted_keys = copy_array(runtime_budget.exhausted_keys),
    }
end

local function loss_snapshot(instance)
    local tension = instance.tension or {}
    return {
        loss = tension.loss or 0,
        loss_max = tension.loss_max,
        loss_remaining = tension.loss_remaining,
        near_death = tension.loss_near_death == true,
        exhausted = tension.loss_exhausted == true,
        event_count = #(tension.loss_events or {}),
    }
end

local function normalize_terminal(instance, input)
    input = input or {}
    local kind = input.kind
    if kind ~= "manifest" and kind ~= "internal_death" then
        return nil, "invalid terminal kind"
    end
    if not packet.death_causes[input.cause] then
        return nil, "invalid death cause"
    end

    local operator = topology.resolve(input.operator or instance.operator)
    if not operator or operator ~= instance.operator then
        return nil, "terminal operator does not match packet position"
    end
    if kind == "manifest" and operator ~= "△" then
        return nil, "manifest terminal requires manifest operator"
    end

    return {
        kind = kind,
        cause = input.cause,
        operator = operator,
        manifest_ref = input.manifest_ref,
        residue_ref = input.residue_ref,
        loss_snapshot = input.loss_snapshot or loss_snapshot(instance),
        budget_snapshot = input.budget_snapshot or budget_snapshot(instance),
        trace_tail_ref = input.trace_tail_ref,
        truth_status = "runtime_confirmed",
    }
end

local function append_terminal(instance, terminal)
    local event = append_trace(instance, {
        type = "terminal",
        operator = terminal.operator,
        truth_status = "runtime_confirmed",
        payload = terminal,
        cost = {},
    })
    terminal.trace_tail_ref = terminal.trace_tail_ref or event.id
    terminal.event_id = event.id
    instance.terminal = terminal
    instance.status = "dying"
    return event
end

function packet.begin_terminal(instance, input)
    local mutable, mutable_err = packet.assert_mutable(instance, "begin terminal")
    if not mutable then
        return nil, mutable_err
    end
    local terminal, terminal_err = normalize_terminal(instance, input)
    if not terminal then
        return nil, terminal_err
    end
    return append_terminal(instance, terminal)
end

function packet.freeze(instance, cause, residue)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    if instance.status == "dead" then
        return nil, "dead packet cannot freeze"
    end
    if instance.status ~= "dying" or type(instance.terminal) ~= "table" then
        return nil, "packet terminal has not begun"
    end
    if cause ~= instance.terminal.cause then
        return nil, "freeze cause does not match terminal"
    end

    instance.death = {
        cause = cause,
        time = os.time(),
        terminal_kind = instance.terminal.kind,
        terminal_event_id = instance.terminal.event_id,
    }
    instance.residue = residue or {cause = cause}
    instance.terminal.residue_ref = instance.terminal.residue_ref
        or ("packet:" .. tostring(instance.id) .. ":residue")
    instance.status = "dead"

    return {
        kind = "packet_corpse_source",
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        terminal = instance.terminal,
        death = instance.death,
        residue = instance.residue,
        truth_status = "runtime_confirmed",
    }
end

function packet.manifest_packet(instance, payload, residue)
    local alive, alive_err = packet.assert_mutable(instance, "manifest")
    if not alive then
        return nil, alive_err
    end
    payload = payload or {}
    if instance.operator ~= "△" then
        return nil, "manifest requires manifest operator"
    end
    local cause = payload.terminal_cause or "complete"
    if not packet.death_causes[cause] then
        return nil, "invalid death cause"
    end
    local truth_status = payload.truth_status or "runtime_confirmed"
    if not packet.truth_statuses[truth_status] then
        return nil, "invalid truth status"
    end

    instance.manifest = payload
    local event = append_trace(instance, {
        type = "manifest",
        operator = "△",
        truth_status = truth_status,
        payload = payload,
        cost = {},
    })
    local terminal_event, terminal_err = packet.begin_terminal(instance, {
        kind = "manifest",
        cause = cause,
        operator = "△",
        manifest_ref = event.id,
        residue_ref = "packet:" .. tostring(instance.id) .. ":residue",
    })
    if not terminal_event then
        return nil, terminal_err
    end
    local corpse, freeze_err = packet.freeze(instance, cause, residue or payload.residue or {
        cause = cause,
        manifest_type = payload.output and payload.output.type,
    })
    if not corpse then
        return nil, freeze_err
    end
    return instance, event, terminal_event
end

function packet.die(instance, cause, residue)
    local alive, alive_err = packet.assert_mutable(instance, "die")
    if not alive then
        return nil, alive_err
    end
    if not packet.death_causes[cause] then
        return nil, "invalid death cause"
    end
    local terminal, terminal_err = normalize_terminal(instance, {
        kind = "internal_death",
        cause = cause,
        operator = instance.operator,
        residue_ref = "packet:" .. tostring(instance.id) .. ":residue",
    })
    if not terminal then
        return nil, terminal_err
    end
    local death_residue = residue or {cause = cause}
    local event = append_trace(instance, {
        type = "death",
        operator = instance.operator or "△",
        truth_status = "runtime_confirmed",
        payload = {
            cause = cause,
            residue = death_residue,
        },
        cost = {},
    })
    local terminal_event = append_terminal(instance, terminal)
    local corpse, freeze_err = packet.freeze(instance, cause, death_residue)
    if not corpse then
        return nil, freeze_err
    end
    return instance, event, terminal_event
end

function packet.append_trace(instance, event)
    local alive, alive_err = packet.assert_mutable(instance, "append trace")
    if not alive then
        return nil, alive_err
    end
    return append_trace(instance, event)
end

packet.append_event = packet.append_trace

return packet
