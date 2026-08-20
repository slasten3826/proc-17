package.path = "./?.lua;./?/init.lua;" .. package.path

local digest = require("core.digest")
local flow_domain = require("runtime.flow_domain")
local qualified_pressure = require("runtime.qualified_pressure")
local reader = require("runtime.dissolve_pressure_relief")
local tension_runner = require("runtime.tension_runner")
local qa_fixture = require("tests.support.qa_hand")

local function copy_value(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function assert_error(value, err, code, stage)
    assert(value == nil, "hostile reader input was accepted")
    assert(type(err) == "table", "hostile reader error is not typed")
    assert_eq(err.code, code)
    assert_eq(err.stage, stage)
end

local function with_frozen_time(callback)
    local original = os.time
    os.time = function() return 1787184000 end
    local result = table.pack(pcall(callback))
    os.time = original
    if not result[1] then error(result[2], 0) end
    return table.unpack(result, 2, result.n)
end

local function grow_capture()
    local grown = assert(qa_fixture.grow_qa_descendant({
        label = "pressure-relief-reader-hostile",
        session_id = "session-pressure-relief-reader-hostile",
        packet_options = {id = "packet:pressure-relief-hostile-ancestor"},
        child_packet_id = "packet:pressure-relief-hostile-fixture-child",
        child_stream_id = "stream:pressure-relief-hostile-fixture-child",
        fresh_repository_id = "repo-pressure-relief-hostile-child",
    }))
    local packet_options = copy_value(grown.ingress.packet_options)
    packet_options.id = "packet:pressure-relief-hostile-child"
    packet_options.repository_id = grown.fresh_repository_id
    packet_options.budget = {
        steps = 32,
        substrate_calls = 8,
        tool_calls = 8,
        encode_items = 16,
        loss = 10,
    }
    local domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = "stream:pressure-relief-hostile-child",
        source_ref = grown.network_projection.projection_id,
    }))
    local instance, result = assert(with_frozen_time(function()
        return tension_runner.run(grown.ingress.prompt, nil, {
            authority_instrument = "v3",
            router_mode = "tree",
            pressure_policy = "qualified_need_v0",
            legacy_shadow = false,
            work_mode = "build",
            max_ticks = 1,
            ablate_relation_consumer = true,
            packet_options = packet_options,
            packet_life = {
                protocol_version = "vertical_packet_life.v0",
                flow_domain = domain,
                projection_adapter = "vertical_single.v0",
                network_projection = grown.ingress.network_projection,
            },
            edge_evidence = {
                case_id = "PR-hostile",
                corpus_layer = "unit",
                evidence_run_id = "run:pressure-relief-reader-hostile",
            },
        })
    end))
    local route_ref
    local capture_index
    local post_snapshot_ref
    local release_seen = false
    local frame_seen = false
    for index, event in ipairs(instance.trace) do
        local payload = event.payload or {}
        if event.type == "route" and payload.from == "▽" and payload.to == "☷" then
            route_ref = event.id
        elseif route_ref and event.type == "unit_dissolution" then
            release_seen = true
        elseif release_seen and event.type == "runtime_frame"
            and event.operator == "☷" then
            frame_seen = true
        elseif frame_seen and event.type == "tension_measure"
            and event.operator == "☷"
            and payload.kind == "qualified_pressure_snapshot" then
            post_snapshot_ref = event.id
        elseif post_snapshot_ref and event.type == "route_derivation"
            and event.operator == "☷"
            and payload.pressure_snapshot_ref == post_snapshot_ref then
            capture_index = index
            break
        end
    end
    assert(route_ref and capture_index, "hostile fixture lacks capture boundary")
    local captured = copy_value(instance)
    while #captured.trace > capture_index do
        captured.trace[#captured.trace] = nil
    end
    captured.status = "running"
    captured.operator = "☷"
    captured.terminal = nil
    captured.death = nil
    captured.residue = nil
    captured.manifest = nil
    return captured, result, route_ref
end

local function request_for(instance, route_ref)
    return {
        protocol_version = reader.request_protocol_version,
        packet_id = instance.id,
        generation = instance.generation,
        route_event_ref = route_ref,
    }
end

local function edge_context(result, route_ref)
    local commit
    local arrival
    for _, record in ipairs(result.edge_credit.events) do
        if record.kind == "route_evidence_commit"
            and record.route_trace_ref == route_ref then
            commit = copy_value(record)
        end
    end
    assert(commit, "hostile fixture lacks edge commit")
    for _, record in ipairs(result.edge_credit.events) do
        if record.kind == "route_evidence_arrival"
            and record.commit_ref == commit.record_id then
            arrival = copy_value(record)
        end
    end
    assert(arrival, "hostile fixture lacks edge arrival")
    return {edge_credit = {commit = commit, arrival = arrival}}
end

local function release_target_id(instance)
    for _, event in ipairs(instance.trace) do
        if event.type == "unit_dissolution" then
            return event.payload.target.id
        end
    end
    error("release target not found", 2)
end

local instance, result, route_ref = grow_capture()
local request = request_for(instance, route_ref)

-- PR-T03: a release record cannot discharge a target that remains live.
do
    local hostile = copy_value(instance)
    hostile.field.units[release_target_id(hostile)].activation = "live"
    local value, err = reader.measure(hostile, request)
    assert_error(value, err, "runtime_invariant_failure", "effect")
end

-- PR-T04: target state cannot advance independently of the release/residue.
do
    local hostile = copy_value(instance)
    local target = hostile.field.units[release_target_id(hostile)]
    target.version = target.version + 1
    local value, err = reader.measure(hostile, request)
    assert_error(value, err, "runtime_invariant_failure", "effect")
end

-- PR-T11: same-coordinate derivation is a reader and must have zero mass.
do
    local hostile = copy_value(instance)
    local original = qualified_pressure.derive
    qualified_pressure.derive = function(control_instance, tick, options)
        local snapshot, snapshot_err = original(control_instance, tick, options)
        control_instance.revisions.potential =
            control_instance.revisions.potential + 1
        return snapshot, snapshot_err
    end
    local values = table.pack(pcall(reader.measure, hostile, request))
    qualified_pressure.derive = original
    assert(values[1], values[2])
    assert_error(values[2], values[3], "reader_failure", "purity")
end

-- PR-T14: v0 refuses a selected route that merges multiple release witnesses.
do
    local hostile = copy_value(instance)
    local route
    local derivation
    for _, event in ipairs(hostile.trace) do
        if event.id == route_ref then route = event end
    end
    for _, event in ipairs(hostile.trace) do
        if route and event.id == route.payload.derivation_ref then
            derivation = event
        end
    end
    assert(route and derivation, "selected route records not found")
    local selected
    for _, candidate in ipairs(derivation.payload.candidates) do
        if candidate.to == "☷" then selected = candidate end
    end
    assert(selected, "selected DISSOLVE candidate not found")
    selected.witness_count = 2
    selected.executable_witness_count = 2
    selected.witnesses[2] = copy_value(selected.witnesses[1])
    selected.executable_witnesses[2] = copy_value(
        selected.executable_witnesses[1]
    )
    derivation.payload.selected_candidate = copy_value(selected)
    route.payload.selected_candidate = copy_value(selected)
    local value, err = reader.measure(hostile, request)
    assert_error(value, err, "unsupported_v0", "selected_obligation")
end

-- PR-T17: a later body revision closes the exact capture window.
do
    local hostile = copy_value(instance)
    hostile.revisions.potential = hostile.revisions.potential + 1
    local value = assert(reader.measure(hostile, request))
    assert_eq(value.measurement_status, "not_measurable")
    assert_eq(value.reason_codes[1], "capture_window_advanced")
end

-- PR-T18: the stored post snapshot must name the runtime frame's revisions.
do
    local hostile = copy_value(instance)
    for _, event in ipairs(hostile.trace) do
        local payload = event.payload or {}
        if event.type == "tension_measure" and event.operator == "☷"
            and payload.kind == "qualified_pressure_snapshot" then
            payload.source_revisions.potential =
            payload.source_revisions.potential + 1
        end
    end
    local value, err = reader.measure(hostile, request)
    assert_error(value, err, "runtime_invariant_failure", "actual_post")
end

local function tagged(seed)
    return "sha256:" .. assert(digest.record(seed))
end

-- PR-T19: even self-consistent v3 records cannot point at foreign body refs.
do
    local context = edge_context(result, route_ref)
    local commit = context.edge_credit.commit
    commit.route_trace_ref = "event-9997"
    commit.record_id = tagged({
        kind = commit.kind,
        protocol_version = commit.protocol_version,
        route_evidence_id = commit.route_evidence_id,
        selection_ref = commit.selection_ref,
        route_trace_ref = commit.route_trace_ref,
        from = commit.from,
        to = commit.to,
        route_authority = commit.route_authority,
        event_truth_status = commit.event_truth_status,
    })
    local arrival = context.edge_credit.arrival
    arrival.commit_ref = commit.record_id
    arrival.destination_tick_ref = "event-9998"
    arrival.effect_refs = {"event-9999"}
    arrival.record_id = tagged({
        kind = arrival.kind,
        protocol_version = arrival.protocol_version,
        route_evidence_id = arrival.route_evidence_id,
        commit_ref = arrival.commit_ref,
        destination_tick_ref = arrival.destination_tick_ref,
        effect_refs = copy_value(arrival.effect_refs),
        payload_kind = arrival.payload_kind,
        event_truth_status = arrival.event_truth_status,
    })
    local value, err = reader.measure(instance, request, context)
    assert_error(value, err, "runtime_invariant_failure", "edge_credit")
end

print("test_dissolve_pressure_relief_reader_hostile ok")
