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
    operator_failure = true,
    route_derivation = true,
    route = true,
    chaos_append = true,
    crystallization = true,
    identity_map = true,
    relation_snapshot = true,
    relation_mutation = true,
    relation_formation = true,
    structure_formation = true,
    observation = true,
    choice = true,
    validation = true,
    cycle = true,
    runtime_frame = true,
    runtime_reconciliation = true,
    plan_completion_assessment = true,
    tension_measure = true,
    manifest = true,
    death = true,
    terminal = true,
}

packet.death_causes = {
    complete = true,
    blocked = true,
    budget_exhausted = true,
    identity_loss = true,
    invalid_topology = true,
    unsafe_scope = true,
    stalled = true,
    effect_failure = true,
    cancelled = true,
}

local dedicated_event_types = {
    birth = true,
    operator_tick = true,
    route = true,
    chaos_append = true,
    crystallization = true,
    manifest = true,
    death = true,
    terminal = true,
}

local event_actor_rights = {
    identity_map = {['☵'] = true},
    relation_snapshot = {['☰'] = true},
    relation_mutation = {['☷'] = true, ['☶'] = true, ['☱'] = true},
    relation_formation = {['☵'] = true},
    structure_formation = {['☵'] = true},
    observation = {['☴'] = true, ['☱'] = true},
    choice = {['☳'] = true},
    validation = {['☶'] = true},
    cycle = {['☲'] = true},
    runtime_reconciliation = {['☱'] = true},
    plan_completion_assessment = {['☱'] = true},
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

local function deep_copy(value, seen)
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
        result[deep_copy(key, seen)] = deep_copy(child, seen)
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
                protocol_version = "field.raw_relations.v1",
                epoch = 0,
                source_revision = 0,
                source_potential_revision = 0,
                probe_policy = nil,
                object_coverage = nil,
                outcome = "unprobed",
                items = {},
            },
            active = {},
            momentum = {},
        },
        identity_maps = {},
    }
end

local function init_regime(work_mode)
    return {
        work = {
            protocol_version = "packet.work_regime.v0",
            mode = work_mode,
        },
        encoding = {
            policy_id = "encode.packet_structure.v0",
            receiver_contract_id = "calm.work_structure.v0",
            bounds = {
                max_source_units = 1,
                max_output_units = 128,
                max_loss_log_entries = 32,
            },
        },
        choice = {
            policy_id = "formation_order.v0",
            consumer_contract_id = "calm.singular_focus.v0",
            bounds = {
                max_selected = 1,
                max_killed_sample = 8,
            },
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

local function trace_event_with_index(instance, event_id)
    for index, event in ipairs(instance and instance.trace or {}) do
        if event.id == event_id then
            return event, index
        end
    end
    return nil
end

local function current_visit_lease(instance, actor)
    for index = #(instance and instance.trace or {}), 1, -1 do
        local event = instance.trace[index]
        if event.type == "operator_tick" then
            if event.operator == actor then
                return event, index, "operator_tick"
            end
            return nil, nil, nil
        end
        if event.type == "route" then
            return nil, nil, nil
        end
        if event.type == "birth" and actor == "▽" then
            return event, index, "birth"
        end
    end
    return nil, nil, nil
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
        payload = deep_copy(event.payload or {}),
        truth_status = event.truth_status,
        cost = normalize_cost(event.cost),
        time = event.time or os.time(),
    }

    instance.trace[#instance.trace + 1] = stored
    return deep_copy(stored)
end

local function init_ingress(options)
    local input = options.ingress
    if input == nil then
        return {
            protocol_version = "packet.ingress.v0",
            integration_protocol = nil,
            flow_mark = nil,
            l1_projection = nil,
            carrier_ref = options.carrier_id,
            inherited_grave_refs = {},
        }
    end
    if type(input) ~= "table" or input.protocol_version ~= "packet.ingress.v0" then
        error("invalid packet ingress contract")
    end
    if input.integration_protocol ~= "vertical_packet_life.v0" then
        error("invalid packet ingress integration protocol")
    end
    local mark = input.flow_mark
    if type(mark) ~= "table" or mark.protocol_version ~= "l1.flow_mark.v0"
        or mark.l1_protocol_version ~= "l1.field.v0"
        or mark.variant ~= "C"
        or type(mark.stream_id) ~= "string" or mark.stream_id == ""
        or type(mark.stream_epoch) ~= "number" or mark.stream_epoch < 1
        or mark.stream_epoch ~= math.floor(mark.stream_epoch)
        or type(mark.birth_seq) ~= "number" or mark.birth_seq < 1
        or mark.birth_seq ~= math.floor(mark.birth_seq)
        or type(mark.snapshot) ~= "table"
        or mark.event_truth_status ~= "runtime_confirmed"
        or mark.semantic_claim_status ~= "none" then
        error("invalid L1 flow mark")
    end
    local projection = input.l1_projection
    if projection ~= nil then
        if type(projection) ~= "table"
            or projection.protocol_version ~= "l1.fixture_projection.v0"
            or (projection.adapter_id ~= "vertical_single.v0"
                and projection.adapter_id ~= "vertical_pair.v0")
            or type(projection.flow_ref) ~= "table"
            or projection.flow_ref.stream_id ~= mark.stream_id
            or projection.flow_ref.stream_epoch ~= mark.stream_epoch
            or projection.flow_ref.birth_seq ~= mark.birth_seq
            or type(projection.units) ~= "table" or #projection.units > 8
            or type(projection.relation_candidates) ~= "table"
            or #projection.relation_candidates > 8
            or projection.event_truth_status ~= "runtime_confirmed"
            or projection.content_truth_status ~= "non_semantic_measurement" then
            error("invalid L1 ingress projection")
        end
        for _, unit in ipairs(projection.units) do
            if type(unit) ~= "table" or type(unit.projection_key) ~= "string"
                or unit.projection_key == "" or unit.kind ~= "l1_physical_sample"
                or type(unit.carrier) ~= "table" or type(unit.source_refs) ~= "table"
                or unit.event_truth_status ~= "runtime_confirmed"
                or unit.content_truth_status ~= "non_semantic_measurement" then
                error("invalid L1 ingress projection unit")
            end
        end
    end
    if input.inherited_grave_refs ~= nil and type(input.inherited_grave_refs) ~= "table" then
        error("invalid ingress grave refs")
    end
    for _, ref in ipairs(input.inherited_grave_refs or {}) do
        if type(ref) ~= "string" or ref == "" then
            error("invalid ingress grave ref")
        end
    end
    return {
        protocol_version = "packet.ingress.v0",
        integration_protocol = input.integration_protocol,
        flow_mark = deep_copy(mark),
        l1_projection = deep_copy(input.l1_projection),
        carrier_ref = input.carrier_ref,
        inherited_grave_refs = deep_copy(input.inherited_grave_refs or {}),
    }
end

local function init_areas(prompt, options)
    local budget = deep_copy(options.budget or default_budget())
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
            sandbox = deep_copy(options.sandbox or {}),
            host = deep_copy(options.host or {}),
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
                inherited_residue = memory_enabled == true
                    and deep_copy(options.inherited_residue or {}) or {},
            },
            karma = {
                warnings = {},
                bequests = {},
                neutral = {},
            },
            camera = {
                protocol_version = "runtime.camera.v0-shadow",
                head_seq = 0,
                reconciled_through = 0,
                latest_frame_id = nil,
                latest_reconciliation_id = nil,
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
    if options.metadata ~= nil and type(options.metadata) ~= "table" then
        error("packet metadata must be table")
    end
    local metadata_mode = options.metadata and options.metadata.work_mode
    local work_mode = options.work_mode or metadata_mode or "build"
    if work_mode ~= "plan" and work_mode ~= "build" then
        error("packet work_mode must be plan or build")
    end
    if metadata_mode ~= nil and metadata_mode ~= work_mode then
        error("packet work_mode conflicts with metadata mirror")
    end
    local metadata = deep_copy(options.metadata or {})
    metadata.work_mode = work_mode

    local packet_id = options.id or next_id("packet")
    local identity = init_identity(packet_id, options)
    local areas = init_areas(prompt, options)
    local ingress = init_ingress(options)
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
        regime = init_regime(work_mode),
        tension = areas.tension,
        runtime = areas.runtime,
        trace = {},
        residue = {},
        death = nil,
        manifest = areas.manifest,
        terminal = nil,
        metadata = metadata,
        ingress = ingress,
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
            work_mode = work_mode,
            ingress_protocol = instance.ingress.protocol_version,
            integration_protocol = instance.ingress.integration_protocol,
            flow_mark = instance.ingress.flow_mark,
        },
        cost = {},
    })

    return instance
end

function packet.assert_actor_tick(instance, actor, operation)
    operation = operation or "mutate"
    local mutable, mutable_err = packet.assert_mutable(instance, operation)
    if not mutable then
        return nil, mutable_err
    end
    local resolved = topology.resolve(actor)
    if not resolved then
        return nil, "invalid mutation actor"
    end
    if resolved ~= instance.operator then
        return nil, "mutation actor does not match packet position"
    end
    local lease, _, lease_kind = current_visit_lease(instance, resolved)
    if not lease then
        return nil, "organ mutation requires current operator tick"
    end
    local result = deep_copy(lease)
    result.lease_kind = lease_kind
    return result
end

function packet.event_in_current_tick(instance, actor, event_id)
    local lease, lease_err = packet.assert_actor_tick(instance, actor, "use mutation source")
    if not lease then
        return nil, lease_err
    end
    if type(event_id) ~= "string" or event_id == "" then
        return nil, "mutation source event is required"
    end
    local source, source_index = trace_event_with_index(instance, event_id)
    if not source then
        return nil, "mutation source event not found"
    end
    local _, lease_index, lease_kind = current_visit_lease(instance, topology.resolve(actor))
    if source.operator ~= topology.resolve(actor)
        or source_index < lease_index
        or (lease_kind == "birth" and source_index == lease_index and source.type ~= "birth")
    then
        return nil, "mutation source event is outside current operator tick"
    end
    return deep_copy(source)
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

local function trace_event_by_id(instance, event_id)
    for _, event in ipairs(instance.trace or {}) do
        if event.id == event_id then
            return event
        end
    end
    return nil
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

    local authority = decision.authority
    if authority == nil then
        authority = decision.kind == "tree_route_decision"
            and "tree" or "legacy_control"
    end
    local selected = decision.selected_candidate
    if authority == "tree" then
        if type(decision.derivation_ref) ~= "string" or decision.derivation_ref == "" then
            return nil, "tree route requires derivation ref"
        end
        if type(decision.pressure_snapshot_ref) ~= "string"
            or decision.pressure_snapshot_ref == "" then
            return nil, "tree route requires pressure snapshot ref"
        end
        if type(selected) ~= "table" or topology.resolve(selected.to) ~= to then
            return nil, "tree route requires matching selected candidate"
        end
        if type(selected.readiness) ~= "table" or selected.readiness.ready ~= true then
            return nil, "tree route cannot commit unready candidate"
        end

        local derivation = trace_event_by_id(instance, decision.derivation_ref)
        if not derivation or derivation.type ~= "route_derivation" then
            return nil, "tree route derivation ref must name route_derivation event"
        end
        local derivation_payload = derivation.payload or {}
        if topology.resolve(derivation_payload.current_operator) ~= from
            or derivation_payload.outcome ~= "selected"
            or topology.resolve(derivation_payload.selected_to) ~= to then
            return nil, "tree route does not match recorded derivation"
        end
        if derivation_payload.pressure_snapshot_ref ~= decision.pressure_snapshot_ref then
            return nil, "tree route pressure ref does not match recorded derivation"
        end

        local pressure_event = trace_event_by_id(instance, decision.pressure_snapshot_ref)
        if not pressure_event
            or pressure_event.type ~= "tension_measure"
            or pressure_event.operator ~= from
            or ((pressure_event.payload or {}).kind ~= "edge_pressure_snapshot"
                and (pressure_event.payload or {}).kind ~= "qualified_pressure_snapshot") then
            return nil, "tree route pressure ref must name matching edge pressure snapshot"
        end

        local recorded_candidate
        for _, candidate in ipairs(derivation_payload.candidates or {}) do
            if topology.resolve(candidate.to) == to
                and candidate.excluded ~= true
                and type(candidate.readiness) == "table"
                and candidate.readiness.ready == true then
                recorded_candidate = candidate
                break
            end
        end
        if not recorded_candidate then
            return nil, "tree route selected candidate is absent from derivation"
        end
        selected = recorded_candidate
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
            authority = authority,
            derivation_ref = decision.derivation_ref,
            pressure_snapshot_ref = decision.pressure_snapshot_ref,
            selected_candidate = selected,
            selected_action_plan_id = selected and selected.action_plan
                and selected.action_plan.plan_id or nil,
            policy = decision.policy,
            policy_status = decision.policy_status,
            threshold = decision.threshold,
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
    fragment = fragment or {}
    local actor = fragment.operator or instance.operator
    local lease, lease_err = packet.assert_actor_tick(instance, actor, "append chaos")
    if not lease then
        return nil, lease_err
    end
    local stored_fragment = deep_copy(fragment)
    stored_fragment.operator = topology.resolve(actor)
    instance.chaos.fragments[#instance.chaos.fragments + 1] = stored_fragment
    local event = append_trace(instance, {
        type = "chaos_append",
        operator = stored_fragment.operator,
        truth_status = stored_fragment.truth_status or "semantic_proposal",
        payload = stored_fragment,
        cost = stored_fragment.cost or {},
    })
    return instance, event
end

function packet.crystallize(instance, record)
    local lease, lease_err = packet.assert_actor_tick(instance, "☵", "crystallize")
    if not lease then
        return nil, lease_err
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

    local source_refs = deep_copy(record.source_chaos_refs or {})
    local event_calm_delta = deep_copy(record.calm_delta)
    local event_loss = deep_copy(record.loss)
    local status = record.status or "accepted"
    local event = append_trace(instance, {
        type = "crystallization",
        operator = "☵",
        truth_status = record.truth_status or "runtime_confirmed",
        payload = {
            source_chaos_refs = source_refs,
            calm_delta = event_calm_delta,
            loss = event_loss,
            status = status,
        },
        cost = {loss = record.loss.amount or 0},
    })

    local crystal = {
        source_chaos_refs = deep_copy(source_refs),
        calm_delta = deep_copy(event_calm_delta),
        loss = deep_copy(event_loss),
        status = status,
        trace_event_id = event.id,
    }

    instance.boundary.crystallizations[#instance.boundary.crystallizations + 1] = crystal
    instance.boundary.loss_records[#instance.boundary.loss_records + 1] = {
        loss = deep_copy(event_loss),
        trace_event_id = event.id,
    }
    instance.calm.structures[#instance.calm.structures + 1] = deep_copy(event_calm_delta)
    instance.calm.current = deep_copy(event_calm_delta)
    if type(event_calm_delta.work_units) == "table" then
        instance.calm.work_units = deep_copy(event_calm_delta.work_units)
    end
    instance.calm.status = crystal.status
    instance.revisions.calm = instance.revisions.calm + 1

    return instance, event
end

function packet.measure_tension(instance, record)
    record = record or {}
    local actor = record.operator or instance.operator
    local lease, lease_err = packet.assert_actor_tick(instance, actor, "measure tension")
    if not lease then
        return nil, lease_err
    end
    local stored_record = deep_copy(record)
    stored_record.operator = topology.resolve(actor)
    for key, value in pairs(record) do
        instance.tension[key] = deep_copy(value)
    end
    local event = append_trace(instance, {
        type = "tension_measure",
        operator = stored_record.operator,
        truth_status = stored_record.truth_status or "runtime_confirmed",
        payload = stored_record,
        cost = stored_record.cost or {},
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
    instance.residue = deep_copy(residue or {cause = cause})
    instance.terminal.residue_ref = instance.terminal.residue_ref
        or ("packet:" .. tostring(instance.id) .. ":residue")
    instance.status = "dead"

    return deep_copy({
        kind = "packet_corpse_source",
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        terminal = instance.terminal,
        death = instance.death,
        residue = instance.residue,
        flow_mark = instance.ingress and instance.ingress.flow_mark,
        truth_status = "runtime_confirmed",
    })
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

    local death_residue = deep_copy(residue or payload.residue or {})
    if type(death_residue) ~= "table" then
        return nil, "manifest residue must be table"
    end
    if death_residue.cause ~= nil and death_residue.cause ~= cause then
        return nil, "manifest residue cause does not match terminal"
    end
    death_residue.cause = cause
    death_residue.manifest_type = death_residue.manifest_type
        or (payload.output and payload.output.type)

    local stored_payload = deep_copy(payload)
    instance.manifest = stored_payload
    local event = append_trace(instance, {
        type = "manifest",
        operator = "△",
        truth_status = truth_status,
        payload = stored_payload,
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
    local corpse, freeze_err = packet.freeze(instance, cause, death_residue)
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
    local death_residue = deep_copy(residue or {cause = cause})
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
    if type(event) ~= "table" or not packet.event_types[event.type] then
        return nil, "valid event required"
    end
    if dedicated_event_types[event.type] then
        return nil, "event type requires dedicated writer"
    end
    local actor = topology.resolve(event.operator)
    local rights = event_actor_rights[event.type]
    if rights and not rights[actor] then
        return nil, "event actor has no right for event type"
    end
    local lease, lease_err = packet.assert_actor_tick(
        instance,
        actor,
        "append trace"
    )
    if not lease then
        return nil, lease_err
    end
    return append_trace(instance, event)
end

packet.append_event = packet.append_trace

return packet
