package.path = "./?.lua;./?/init.lua;" .. package.path

local digest = require("core.digest")
local flow_domain = require("runtime.flow_domain")
local dissolve = require("organs.dissolve")
local pressure_action = require("runtime.pressure_action")
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

local function identify(value)
    local seed = copy_value(value)
    seed.measurement_id = nil
    return "pressure-relief:" .. assert(digest.record(seed))
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function valid_view()
    local value = {
        protocol_version = "dissolve.pressure_relief.v0",
        treatment = "dissolve.inherited_rejected_form_release.v0",
        packet_id = "packet-reader",
        generation = 2,
        measurement_status = "discharged",
        reason_codes = {},
        selected = {
            pre_coordinate = "▽",
            pressure_snapshot_ref = "event-10",
            route_derivation_ref = "event-11",
            route_event_ref = "event-12",
            witness_id = "pressure-id:selected",
            same_obligation_key = "pressure-obligation:" .. string.rep("a", 64),
            action_plan_id = "pressure-action:selected",
            causal_class = "blocking_demand",
            target_operator = "☷",
        },
        effect = {
            destination_tick_ref = "event-13",
            release_event_ref = "event-14",
            post_effect_runtime_frame_ref = "event-15",
            release_id = "dissolve-release:one",
            target = {
                id = "unit:2",
                before_version = 1,
                after_version = 2,
                after_activation = "dissolved",
            },
            residue_unit_id = "unit:3",
            released_mass = {forms = 1, relations = 0},
            irreversible_identity_loss = 0,
        },
        controlled_post = {
            coordinate = "▽",
            coordinate_status = "same_coordinate_control",
            exact_selected_witness_count = 0,
            same_obligation_count = 0,
            old_action_preconditions_fresh = false,
            old_action_readiness = "already_released",
        },
        actual_post = {
            coordinate = "☷",
            pressure_snapshot_ref = "event-16",
            route_derivation_ref = "event-17",
            successor_witness_ids = {"pressure-id:successor"},
            successor_obligation_count = 1,
            expected_successor = {
                witness_id = "pressure-id:successor",
                action_plan_id = "pressure-action:successor",
                presentation_policy = "network.rejected_form_after_release.v0",
                executable = true,
            },
            other_successor_witness_ids = {},
        },
        pressure_relief = {
            measure = "typed_selected_obligation_discharge",
            selected_obligation_count = 1,
            discharged_obligation_count = 1,
            unresolved_selected_obligation_count = 0,
            classification = "discharged_with_successor_obligation",
        },
        aggregate_diagnostic = {
            pre_witness_count = 1,
            controlled_post_witness_count = 1,
            actual_post_witness_count = 1,
            controlled_count_delta = 0,
            authoritative_for_relief = false,
        },
        source_refs = {"event-10", "event-11", "event-12", "event-14"},
        calculation_status = "runtime_confirmed",
        authority = "diagnostic",
    }
    value.measurement_id = identify(value)
    return value
end

local function grown_release_life()
    local grown = assert(qa_fixture.grow_qa_descendant({
        label = "pressure-relief-reader-selected",
        session_id = "session-pressure-relief-reader-selected",
        packet_options = {id = "packet:pressure-relief-reader-ancestor"},
        child_packet_id = "packet:pressure-relief-reader-fixture-child",
        child_stream_id = "stream:pressure-relief-reader-fixture-child",
        fresh_repository_id = "repo-pressure-relief-reader-child",
    }))
    local packet_options = copy_value(grown.ingress.packet_options)
    packet_options.id = "packet:pressure-relief-reader-child"
    packet_options.repository_id = grown.fresh_repository_id
    packet_options.budget = {
        steps = 32,
        substrate_calls = 8,
        tool_calls = 8,
        encode_items = 16,
        loss = 10,
    }
    local domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = "stream:pressure-relief-reader-child",
        source_ref = grown.network_projection.projection_id,
    }))
    local instance, result = assert(tension_runner.run(
        grown.ingress.prompt,
        nil,
        {
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
                case_id = "PR-R8.2",
                corpus_layer = "unit",
                evidence_run_id = "run:pressure-relief-reader-selected",
            },
        }
    ))
    local route_ref
    local other_route_ref
    local release_ref
    local frame_index
    local post_snapshot_ref
    local capture_index
    for index, event in ipairs(instance.trace) do
        local payload = event.payload or {}
        if event.type == "route" and payload.from == "▽" and payload.to == "☷" then
            route_ref = event.id
        elseif event.type == "route" then
            other_route_ref = event.id
        end
        if route_ref and event.type == "unit_dissolution" then
            release_ref = event.id
        elseif release_ref and event.type == "runtime_frame"
            and event.operator == "☷" then
            frame_index = index
        elseif frame_index and event.type == "tension_measure"
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
    assert(route_ref, "grown release life has no ▽ -> ☷ route")
    assert(frame_index, "grown release life has no post-release runtime frame")
    assert(capture_index, "grown release life has no post-release derivation")

    -- R8.6 will invoke the reader at this exact live capture hook. Until that
    -- runner hook exists, trim the completed fixture back to the same body
    -- boundary instead of asking terminal state to impersonate a live Packet.
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
    return captured, result, route_ref, other_route_ref
end

local function edge_context(result, route_ref)
    local commit
    local arrival
    for _, record in ipairs(result.edge_credit.events) do
        if record.kind == "route_evidence_commit"
            and record.route_trace_ref == route_ref then
            commit = record
        end
    end
    assert(commit, "grown release life has no route commit evidence")
    for _, record in ipairs(result.edge_credit.events) do
        if record.kind == "route_evidence_arrival"
            and record.commit_ref == commit.record_id then
            arrival = record
        end
    end
    assert(arrival, "grown release life has no route arrival evidence")
    return {edge_credit = {commit = commit, arrival = arrival}}
end

local function inherited_release_witness(instance)
    for _, event in ipairs(instance.trace) do
        local payload = event.payload or {}
        if event.type == "tension_measure" and event.operator == "▽"
            and payload.kind == "qualified_pressure_snapshot" then
            for _, witness in ipairs(payload.witnesses or {}) do
                if witness.kind == "inherited_rejected_form_release_need" then
                    return copy_value(witness)
                end
            end
        end
    end
    error("release witness not found", 2)
end

local function measure_with_control_mutation(instance, request, mutate)
    local original = qualified_pressure.derive
    qualified_pressure.derive = function(control_instance, tick, options)
        local snapshot, snapshot_err = original(control_instance, tick, options)
        if not snapshot then return nil, snapshot_err end
        mutate(snapshot, control_instance)
        return snapshot
    end
    local values = table.pack(pcall(reader.measure, instance, request))
    qualified_pressure.derive = original
    if not values[1] then error(values[2], 0) end
    return table.unpack(values, 2, values.n)
end

do
    local value = valid_view()
    assert(reader.verify(value))
    local second = valid_view()
    assert_eq(second.measurement_id, value.measurement_id,
        "equal views must have stable identity")
end

do
    local value = valid_view()
    value.unknown = true
    value.measurement_id = identify(value)
    local ok, err = reader.verify(value)
    assert(ok == nil and err:find("unknown key", 1, true),
        "unknown view key was accepted")
end

do
    local value = valid_view()
    value.source_refs = {"event-12", "event-10"}
    value.measurement_id = identify(value)
    local ok, err = reader.verify(value)
    assert(ok == nil and err:find("sorted and unique", 1, true),
        "unsorted source refs were accepted")
end

do
    local value = valid_view()
    value.measurement_id = "pressure-relief:" .. string.rep("0", 64)
    local ok, err = reader.verify(value)
    assert(ok == nil and err:find("identity mismatch", 1, true),
        "forged measurement identity was accepted")
end

do
    local value = valid_view()
    value.measurement_status = "not_discharged"
    value.controlled_post.same_obligation_count = 1
    value.controlled_post.old_action_readiness = "releasable"
    value.reason_codes = {
        "old_action_readiness_remains_releasable",
        "same_obligation_survived",
    }
    value.pressure_relief.discharged_obligation_count = 0
    value.pressure_relief.unresolved_selected_obligation_count = 1
    value.pressure_relief.classification = "not_discharged"
    value.measurement_id = identify(value)
    assert(reader.verify(value))
    value.reason_codes = {"same_obligation_survived"}
    value.measurement_id = identify(value)
    local ok, err = reader.verify(value)
    assert(ok == nil and err:find("do not match controlled evidence", 1, true),
        "not-discharged view hid a failed predicate")
end

do
    local value = valid_view()
    value.measurement_status = "not_measurable"
    value.reason_codes = {"capture_window_advanced"}
    value.effect = nil
    value.controlled_post = nil
    value.actual_post = nil
    value.aggregate_diagnostic = nil
    value.pressure_relief.discharged_obligation_count = nil
    value.pressure_relief.unresolved_selected_obligation_count = nil
    value.pressure_relief.classification = "not_measurable"
    value.measurement_id = identify(value)
    assert(reader.verify(value))
end

do
    local request = {
        protocol_version = reader.request_protocol_version,
        packet_id = "packet-reader",
        generation = 2,
        route_event_ref = "event-12",
    }
    local instance = {id = "packet-reader", generation = 2, trace = {}}
    local view, err = reader.measure(instance, request)
    assert(view == nil)
    assert_eq(err.code, "invalid_measurement_request")
    assert_eq(err.stage, "request")
    assert_eq(err.source_refs[1], "event-12")

    -- PR-T13: downstream callers cannot expand the bounded request schema.
    request.effect_ref = "event-14"
    local invalid, invalid_err = reader.measure(instance, request)
    assert(invalid == nil)
    assert_eq(invalid_err.code, "invalid_measurement_request")
    assert_eq(invalid_err.stage, "request")
end

do
    -- PR-T01 grows the complete rejected-ancestor -> carrier -> child release.
    local instance, result, route_ref, other_route_ref = grown_release_life()
    local request = {
        protocol_version = reader.request_protocol_version,
        packet_id = instance.id,
        generation = instance.generation,
        route_event_ref = route_ref,
    }
    local packet_before = assert(digest.record(instance))
    local value, err = reader.measure(
        instance,
        request,
        edge_context(result, route_ref)
    )
    assert_eq(assert(digest.record(instance)), packet_before,
        "R8.5 reader changed Packet state")
    assert(value, err and err.message)
    assert(reader.verify(value))
    assert_eq(value.measurement_status, "discharged")
    assert_eq(value.pressure_relief.classification,
        "discharged_with_successor_obligation")
    assert_eq(value.controlled_post.exact_selected_witness_count, 0)
    assert_eq(value.controlled_post.same_obligation_count, 0)
    assert_eq(value.controlled_post.old_action_preconditions_fresh, false)
    assert_eq(value.controlled_post.old_action_readiness, "already_released")
    assert_eq(value.actual_post.coordinate, "☷")
    -- PR-T09: the exact upper-OBSERVE successor remains visible after release.
    assert_eq(value.actual_post.successor_obligation_count, 1)
    assert(value.actual_post.expected_successor)
    assert_eq(value.actual_post.expected_successor.presentation_policy,
        "network.rejected_form_after_release.v0")
    assert_eq(value.aggregate_diagnostic.pre_witness_count, 1)
    -- PR-T07: aggregate 1 -> 1 does not hide selected-obligation discharge.
    assert_eq(value.aggregate_diagnostic.controlled_post_witness_count, 1)
    assert_eq(value.aggregate_diagnostic.controlled_count_delta, 0)
    local repeated = assert(reader.measure(
        instance,
        request,
        edge_context(result, route_ref)
    ))
    assert_eq(repeated.measurement_id, value.measurement_id,
        "equal body evidence produced a different measurement identity")

    if other_route_ref then
        request.route_event_ref = other_route_ref
        local wrong, wrong_err = reader.measure(instance, request)
        assert(wrong == nil)
        assert_eq(wrong_err.code, "invalid_measurement_request")
        assert_eq(wrong_err.stage, "request")
    end

    local hostile = copy_value(instance)
    for _, event in ipairs(hostile.trace) do
        if event.id == route_ref then
            event.payload.selected_action_plan_id = "pressure-action:foreign"
        end
    end
    request.route_event_ref = route_ref
    local bad, bad_err = reader.measure(hostile, request)
    assert(bad == nil)
    assert_eq(bad_err.code, "runtime_invariant_failure")
    assert_eq(bad_err.stage, "selected_obligation")

    -- PR-T02: a verified arrival without its body release is not measurable.
    local missing_release = copy_value(instance)
    for index = #missing_release.trace, 1, -1 do
        if missing_release.trace[index].type == "unit_dissolution" then
            table.remove(missing_release.trace, index)
        end
    end
    local absent = assert(reader.measure(
        missing_release,
        request,
        edge_context(result, route_ref)
    ))
    assert_eq(absent.measurement_status, "not_measurable")
    assert_eq(absent.reason_codes[1], "release_event_absent")
    assert(absent.effect == nil and absent.actual_post == nil,
        "missing release did not preserve its not-measurable reason")

    local missing_tick = copy_value(instance)
    while missing_tick.trace[#missing_tick.trace].id ~= route_ref do
        missing_tick.trace[#missing_tick.trace] = nil
    end
    local unticked = assert(reader.measure(missing_tick, request))
    assert_eq(unticked.measurement_status, "not_measurable")
    assert_eq(unticked.reason_codes[1], "destination_tick_absent")
    assert(unticked.effect == nil and unticked.controlled_post == nil,
        "missing destination tick lost its not-measurable reason")

    local missing_frame = copy_value(instance)
    for index = #missing_frame.trace, 1, -1 do
        if missing_frame.trace[index].type == "runtime_frame"
            and missing_frame.trace[index].operator == "☷" then
            table.remove(missing_frame.trace, index)
        end
    end
    local unframed = assert(reader.measure(missing_frame, request))
    assert_eq(unframed.measurement_status, "not_measurable")
    assert_eq(unframed.reason_codes[1], "post_effect_runtime_frame_absent")
    assert(unframed.effect == nil and unframed.actual_post == nil,
        "missing runtime frame lost its not-measurable reason")

    local bad_frame = copy_value(instance)
    for _, event in ipairs(bad_frame.trace) do
        if event.type == "runtime_frame" and event.operator == "☷" then
            event.payload.effect_refs = {}
        end
    end
    local framed, frame_err = reader.measure(bad_frame, request)
    assert(framed == nil)
    assert_eq(frame_err.code, "runtime_invariant_failure")
    assert_eq(frame_err.stage, "runtime_frame")

    local bad_state = copy_value(instance)
    local target_id
    for _, event in ipairs(bad_state.trace) do
        if event.type == "unit_dissolution" then
            target_id = event.payload.target.id
        end
    end
    assert(target_id and bad_state.field.units[target_id])
    bad_state.field.units[target_id].activation = "live"
    local state_value, state_err = reader.measure(bad_state, request)
    assert(state_value == nil)
    assert_eq(state_err.code, "runtime_invariant_failure")
    assert_eq(state_err.stage, "effect")

    -- PR-T10: absent actual post snapshot remains typed, not guessed.
    local missing_actual = copy_value(instance)
    for index = #missing_actual.trace, 1, -1 do
        local event = missing_actual.trace[index]
        if event.type == "tension_measure" and event.operator == "☷"
            or event.type == "route_derivation" and event.operator == "☷" then
            table.remove(missing_actual.trace, index)
        end
    end
    local no_actual = assert(reader.measure(missing_actual, request))
    assert_eq(no_actual.measurement_status, "not_measurable")
    assert_eq(no_actual.reason_codes[1],
        "actual_post_pressure_snapshot_absent")
    assert(no_actual.effect and no_actual.controlled_post
        and no_actual.actual_post == nil)

    local missing_derivation = copy_value(instance)
    for index = #missing_derivation.trace, 1, -1 do
        local event = missing_derivation.trace[index]
        if event.type == "route_derivation" and event.operator == "☷" then
            table.remove(missing_derivation.trace, index)
        end
    end
    local no_derivation = assert(reader.measure(missing_derivation, request))
    assert_eq(no_derivation.measurement_status, "not_measurable")
    assert_eq(no_derivation.reason_codes[1],
        "actual_post_route_derivation_absent")

    local original_derive = qualified_pressure.derive
    qualified_pressure.derive = function(control_instance, tick, options)
        local snapshot, snapshot_err = original_derive(
            control_instance,
            tick,
            options
        )
        if not snapshot then return nil, snapshot_err end
        local old_witness
        for _, event in ipairs(control_instance.trace) do
            if event.type == "tension_measure" and event.operator == "▽"
                and event.payload.kind == "qualified_pressure_snapshot" then
                for _, witness in ipairs(event.payload.witnesses or {}) do
                    if witness.kind == "inherited_rejected_form_release_need" then
                        old_witness = copy_value(witness)
                    end
                end
            end
        end
        assert(old_witness, "hostile control could not recover old witness")
        snapshot.witnesses[#snapshot.witnesses + 1] = old_witness
        table.sort(snapshot.witnesses, function(left, right)
            return left.witness_id < right.witness_id
        end)
        return snapshot
    end
    local controlled_ok, controlled_or_err = pcall(reader.measure, instance, request)
    qualified_pressure.derive = original_derive
    assert(controlled_ok, controlled_or_err)
    local survived = assert(controlled_or_err)
    assert_eq(survived.measurement_status, "not_discharged")
    assert_eq(survived.pressure_relief.discharged_obligation_count, 0)
    assert_eq(survived.pressure_relief.unresolved_selected_obligation_count, 1)
    assert_eq(survived.controlled_post.exact_selected_witness_count, 1)
    assert_eq(survived.controlled_post.same_obligation_count, 1)
    assert_eq(survived.reason_codes[1], "exact_selected_witness_survived")
    assert_eq(survived.reason_codes[2], "same_obligation_survived")

    -- PR-T05: a new witness/action identity may still name the same bounded
    -- obligation. Exact-id disappearance alone is not discharge.
    local old_witness = inherited_release_witness(instance)
    local changed_witness = copy_value(old_witness)
    changed_witness.witness_id = old_witness.witness_id .. ":post-version"
    changed_witness.action_plan = assert(pressure_action.build(
        old_witness.action_plan.mode,
        {
            witness_id = changed_witness.witness_id,
            scope_refs = old_witness.action_plan.scope_refs,
            provenance_refs = old_witness.action_plan.provenance_refs,
            preconditions = old_witness.action_plan.preconditions,
            options = old_witness.action_plan.options,
            expected_effect = old_witness.action_plan.expected_effect,
            content_truth_status = old_witness.action_plan.content_truth_status,
        }
    ))
    local changed = assert(measure_with_control_mutation(
        instance,
        request,
        function(snapshot)
            snapshot.witnesses[#snapshot.witnesses + 1] = changed_witness
            table.sort(snapshot.witnesses, function(left, right)
                return left.witness_id < right.witness_id
            end)
        end
    ))
    assert_eq(changed.measurement_status, "not_discharged")
    assert_eq(changed.controlled_post.exact_selected_witness_count, 0)
    assert_eq(changed.controlled_post.same_obligation_count, 1)
    assert_eq(changed.reason_codes[1], "same_obligation_survived")

    -- PR-T06: even with no surviving witness copy, fresh preconditions or
    -- releasable readiness independently prevent a discharge claim.
    local original_preconditions = pressure_action.verify_preconditions
    local original_readiness = dissolve.readiness
    pressure_action.verify_preconditions = function() return true end
    dissolve.readiness = function()
        return {
            ready = true,
            reason = "inherited_rejected_form_releasable",
        }
    end
    local readiness_call = table.pack(pcall(reader.measure, instance, request))
    pressure_action.verify_preconditions = original_preconditions
    dissolve.readiness = original_readiness
    assert(readiness_call[1], readiness_call[2])
    local readiness_survived = assert(readiness_call[2], readiness_call[3])
    assert_eq(readiness_survived.measurement_status, "not_discharged")
    assert_eq(readiness_survived.controlled_post.same_obligation_count, 0)
    assert_eq(readiness_survived.controlled_post.old_action_preconditions_fresh,
        true)
    assert_eq(readiness_survived.controlled_post.old_action_readiness,
        "releasable")
    assert_eq(readiness_survived.reason_codes[1],
        "old_action_preconditions_remain_fresh")
    assert_eq(readiness_survived.reason_codes[2],
        "old_action_readiness_remains_releasable")

    -- PR-T08: an aggregate count decrease is not discharge when the selected
    -- same-obligation debt survives.
    local aggregate_fall = copy_value(instance)
    local unrelated_pre_witness
    for _, event in ipairs(aggregate_fall.trace) do
        local payload = event.payload or {}
        if event.type == "tension_measure" and event.operator == "☷"
            and payload.kind == "qualified_pressure_snapshot" then
            unrelated_pre_witness = copy_value(payload.witnesses[1])
        end
    end
    assert(unrelated_pre_witness, "actual successor witness not found")
    for _, event in ipairs(aggregate_fall.trace) do
        local payload = event.payload or {}
        if event.type == "tension_measure" and event.operator == "▽"
            and payload.kind == "qualified_pressure_snapshot" then
            payload.witnesses[#payload.witnesses + 1] = unrelated_pre_witness
        end
    end
    local aggregate_survived = assert(measure_with_control_mutation(
        aggregate_fall,
        request,
        function(snapshot)
            snapshot.witnesses = {inherited_release_witness(aggregate_fall)}
        end
    ))
    assert_eq(aggregate_survived.measurement_status, "not_discharged")
    assert_eq(aggregate_survived.controlled_post.same_obligation_count, 1)
    assert_eq(aggregate_survived.aggregate_diagnostic.pre_witness_count, 2)
    assert_eq(aggregate_survived.aggregate_diagnostic.controlled_post_witness_count,
        1)
    assert_eq(aggregate_survived.aggregate_diagnostic.controlled_count_delta, -1)

    -- PR-T20: unrelated post-effect pressure is retained beside the exact
    -- upper-OBSERVE successor and cannot be charged as release debt.
    local extra_successor = copy_value(instance)
    local unrelated_id = "pressure-id:unrelated-successor"
    for _, event in ipairs(extra_successor.trace) do
        local payload = event.payload or {}
        if event.type == "tension_measure" and event.operator == "☷"
            and payload.kind == "qualified_pressure_snapshot" then
            payload.witnesses[#payload.witnesses + 1] = {
                witness_id = unrelated_id,
                kind = "unrelated_diagnostic_need",
            }
        end
    end
    local with_unrelated = assert(reader.measure(extra_successor, request))
    assert_eq(with_unrelated.measurement_status, "discharged")
    assert_eq(with_unrelated.actual_post.successor_obligation_count, 2)
    assert(with_unrelated.actual_post.expected_successor)
    assert_eq(#with_unrelated.actual_post.other_successor_witness_ids, 1)
    assert_eq(with_unrelated.actual_post.other_successor_witness_ids[1],
        unrelated_id)
end

do
    local value = valid_view()
    value.selected.loop = value.selected
    local ok, err = reader.verify(value)
    assert(ok == nil and err:find("acyclic", 1, true),
        "cyclic view was accepted")
end

print("test_dissolve_pressure_relief_reader ok")
