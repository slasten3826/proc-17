local digest = require("core.digest")
local dissolve_schema = require("core.dissolve_schema")
local packet = require("core.packet")
local network_projection_schema = require("core.network_projection_schema")
local edge_credit = require("runtime.edge_credit")
local field = require("runtime.field")
local pressure_action = require("runtime.pressure_action")
local qualified_pressure = require("runtime.qualified_pressure")
local dissolve = require("organs.dissolve")

local reader = {
    protocol_version = "dissolve.pressure_relief.v0",
    request_protocol_version = "dissolve.pressure_relief.request.v0",
    error_protocol_version = "dissolve.pressure_relief.error.v0",
}

local bounds = {
    max_stored_trace_events = 8192,
    max_body_trace_events = 4096,
    max_source_refs = 256,
    max_successor_witnesses = 64,
    max_reason_codes = 8,
    max_string_bytes = 262144,
}

local request_keys = {
    protocol_version = true,
    packet_id = true,
    generation = true,
    route_event_ref = true,
}

local trusted_context_keys = {edge_credit = true}
local edge_context_keys = {commit = true, arrival = true}

local error_codes = {
    invalid_measurement_request = true,
    unsupported_v0 = true,
    runtime_invariant_failure = true,
    reader_failure = true,
}

local error_stages = {
    request = true,
    body_trace = true,
    selected_obligation = true,
    arrival = true,
    effect = true,
    runtime_frame = true,
    actual_post = true,
    same_coordinate_control = true,
    successor = true,
    edge_credit = true,
    view = true,
    purity = true,
}

local not_measurable_reasons = {
    destination_tick_absent = true,
    release_event_absent = true,
    post_effect_runtime_frame_absent = true,
    actual_post_pressure_snapshot_absent = true,
    actual_post_route_derivation_absent = true,
    capture_window_advanced = true,
    same_coordinate_control_unavailable = true,
}

local not_discharged_reasons = {
    exact_selected_witness_survived = true,
    same_obligation_survived = true,
    old_action_preconditions_remain_fresh = true,
    old_action_readiness_remains_releasable = true,
}

local view_keys = {
    protocol_version = true,
    measurement_id = true,
    treatment = true,
    packet_id = true,
    generation = true,
    measurement_status = true,
    reason_codes = true,
    selected = true,
    effect = true,
    controlled_post = true,
    actual_post = true,
    pressure_relief = true,
    aggregate_diagnostic = true,
    source_refs = true,
    calculation_status = true,
    authority = true,
}

local selected_keys = {
    pre_coordinate = true,
    pressure_snapshot_ref = true,
    route_derivation_ref = true,
    route_event_ref = true,
    witness_id = true,
    same_obligation_key = true,
    action_plan_id = true,
    causal_class = true,
    target_operator = true,
}

local effect_keys = {
    destination_tick_ref = true,
    release_event_ref = true,
    post_effect_runtime_frame_ref = true,
    release_id = true,
    target = true,
    residue_unit_id = true,
    released_mass = true,
    irreversible_identity_loss = true,
}

local target_keys = {
    id = true,
    before_version = true,
    after_version = true,
    after_activation = true,
}

local released_mass_keys = {forms = true, relations = true}

local controlled_keys = {
    coordinate = true,
    coordinate_status = true,
    exact_selected_witness_count = true,
    same_obligation_count = true,
    old_action_preconditions_fresh = true,
    old_action_readiness = true,
}

local actual_keys = {
    coordinate = true,
    pressure_snapshot_ref = true,
    route_derivation_ref = true,
    successor_witness_ids = true,
    successor_obligation_count = true,
    expected_successor = true,
    other_successor_witness_ids = true,
}

local expected_successor_keys = {
    witness_id = true,
    action_plan_id = true,
    presentation_policy = true,
    executable = true,
}

local relief_keys = {
    measure = true,
    selected_obligation_count = true,
    discharged_obligation_count = true,
    unresolved_selected_obligation_count = true,
    classification = true,
}

local aggregate_keys = {
    pre_witness_count = true,
    controlled_post_witness_count = true,
    actual_post_witness_count = true,
    controlled_count_delta = true,
    authoritative_for_relief = true,
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

local function acyclic_plain(value, label, active, checked)
    if type(value) ~= "table" then
        return true
    end
    if getmetatable(value) ~= nil then
        return nil, label .. " must contain only plain tables"
    end
    active = active or {}
    checked = checked or {}
    if active[value] then
        return nil, label .. " must be acyclic"
    end
    if checked[value] then
        return true
    end
    active[value] = true
    for key, child in pairs(value) do
        local key_ok, key_err = acyclic_plain(key, label, active, checked)
        if not key_ok then
            return nil, key_err
        end
        local child_ok, child_err = acyclic_plain(child, label, active, checked)
        if not child_ok then
            return nil, child_err
        end
    end
    active[value] = nil
    checked[value] = true
    return true
end

local function exact_record(value, allowed, optional, label)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, label .. " must be a plain table"
    end
    optional = optional or {}
    for key in pairs(value) do
        if not allowed[key] then
            return nil, label .. " contains unknown key: " .. tostring(key)
        end
    end
    for key in pairs(allowed) do
        if value[key] == nil and not optional[key] then
            return nil, label .. " is missing key: " .. tostring(key)
        end
    end
    return true
end

local function bounded_string(value, label)
    if type(value) ~= "string" or value == "" or #value > bounds.max_string_bytes
        or value:find("[%z\1-\31\127]") or utf8.len(value) == nil then
        return nil, label .. " must be bounded control-free UTF-8"
    end
    return value
end

local function positive_integer(value, label)
    if type(value) ~= "number" or value < 1 or value ~= math.floor(value) then
        return nil, label .. " must be an integer >= 1"
    end
    return value
end

local function nonnegative_integer(value, label)
    if type(value) ~= "number" or value < 0 or value ~= math.floor(value) then
        return nil, label .. " must be an integer >= 0"
    end
    return value
end

local function prefixed_digest(value, prefix)
    return type(value) == "string" and #value == #prefix + 64
        and value:sub(1, #prefix) == prefix
        and value:sub(#prefix + 1):match("^[0-9a-f]+$") ~= nil
end

local function dense_array(value, label)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, label .. " must be a dense array"
    end
    local count, maximum = 0, 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            return nil, label .. " must be a dense array"
        end
        count = count + 1
        maximum = math.max(maximum, key)
    end
    if count ~= maximum then
        return nil, label .. " must be a dense array"
    end
    return true
end

local function strict_string_array(value, label, maximum)
    local shape_ok, shape_err = dense_array(value, label)
    if not shape_ok then
        return nil, shape_err
    end
    if #value > maximum then
        return nil, label .. " exceeds bound"
    end
    local result = {}
    local previous
    for index = 1, #value do
        local item, item_err = bounded_string(value[index], label .. " item")
        if not item then
            return nil, item_err
        end
        if previous ~= nil and previous >= item then
            return nil, label .. " must be sorted and unique"
        end
        result[index] = item
        previous = item
    end
    return result
end

local function same_array(left, right)
    if #left ~= #right then
        return false
    end
    for index = 1, #left do
        if left[index] ~= right[index] then
            return false
        end
    end
    return true
end

local function sorted_unique(values)
    local result, seen = {}, {}
    for _, value in ipairs(values or {}) do
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function make_error(code, stage, message, source_refs)
    assert(error_codes[code], "unknown pressure-relief error code")
    assert(error_stages[stage], "unknown pressure-relief error stage")
    return {
        kind = "dissolve_pressure_relief_error",
        protocol_version = reader.error_protocol_version,
        code = code,
        stage = stage,
        message = tostring(message or code),
        source_refs = sorted_unique(source_refs),
    }
end

local function normalize_request(instance, request)
    local plain_ok, plain_err = acyclic_plain(request, "pressure-relief request")
    if not plain_ok then
        return nil, make_error("invalid_measurement_request", "request", plain_err)
    end
    local keys_ok, keys_err = exact_record(
        request,
        request_keys,
        nil,
        "pressure-relief request"
    )
    if not keys_ok then
        return nil, make_error("invalid_measurement_request", "request", keys_err)
    end
    if request.protocol_version ~= reader.request_protocol_version then
        return nil, make_error(
            "invalid_measurement_request",
            "request",
            "unsupported pressure-relief request protocol"
        )
    end
    local packet_id, packet_err = bounded_string(request.packet_id, "request packet_id")
    if not packet_id then
        return nil, make_error("invalid_measurement_request", "request", packet_err)
    end
    local generation, generation_err = positive_integer(
        request.generation,
        "request generation"
    )
    if not generation then
        return nil, make_error("invalid_measurement_request", "request", generation_err)
    end
    local route_ref, route_err = bounded_string(
        request.route_event_ref,
        "request route_event_ref"
    )
    if not route_ref or not route_ref:match("^event%-%d+$") then
        return nil, make_error(
            "invalid_measurement_request",
            "request",
            route_err or "request route_event_ref must be event-N"
        )
    end
    if type(instance) ~= "table" or instance.id ~= packet_id
        or instance.generation ~= generation or type(instance.trace) ~= "table" then
        return nil, make_error(
            "invalid_measurement_request",
            "request",
            "request does not match Packet identity"
        )
    end
    if #instance.trace > bounds.max_stored_trace_events then
        return nil, make_error(
            "unsupported_v0",
            "body_trace",
            "stored Packet trace exceeds v0 bound",
            {route_ref}
        )
    end
    return {
        protocol_version = reader.request_protocol_version,
        packet_id = packet_id,
        generation = generation,
        route_event_ref = route_ref,
    }
end

local function normalize_trusted_context(context)
    if context == nil then
        return {}
    end
    local plain_ok, plain_err = acyclic_plain(context, "pressure-relief trusted context")
    if not plain_ok then
        return nil, make_error("runtime_invariant_failure", "edge_credit", plain_err)
    end
    local context_ok, context_err = exact_record(
        context,
        trusted_context_keys,
        {edge_credit = true},
        "pressure-relief trusted context"
    )
    if not context_ok then
        return nil, make_error(
            "runtime_invariant_failure",
            "edge_credit",
            context_err
        )
    end
    if context.edge_credit == nil then
        return {}
    end
    local pair_ok, pair_err = exact_record(
        context.edge_credit,
        edge_context_keys,
        nil,
        "pressure-relief edge-credit context"
    )
    if not pair_ok then
        return nil, make_error("runtime_invariant_failure", "edge_credit", pair_err)
    end
    local commit_ok, commit_err = edge_credit.verify_record(context.edge_credit.commit)
    if not commit_ok then
        return nil, make_error("runtime_invariant_failure", "edge_credit", commit_err)
    end
    local arrival_ok, arrival_err = edge_credit.verify_record(context.edge_credit.arrival)
    if not arrival_ok then
        return nil, make_error("runtime_invariant_failure", "edge_credit", arrival_err)
    end
    local commit = context.edge_credit.commit
    local arrival = context.edge_credit.arrival
    if commit.kind ~= "route_evidence_commit"
        or arrival.kind ~= "route_evidence_arrival"
        or arrival.route_evidence_id ~= commit.route_evidence_id
        or arrival.commit_ref ~= commit.record_id then
        return nil, make_error(
            "runtime_invariant_failure",
            "edge_credit",
            "edge-credit commit and arrival do not form one route chain"
        )
    end
    return {edge_credit = {commit = copy_value(commit), arrival = copy_value(arrival)}}
end

local function same_value(left, right)
    local left_id, left_err = digest.record(left)
    if not left_id then return nil, left_err end
    local right_id, right_err = digest.record(right)
    if not right_id then return nil, right_err end
    return left_id == right_id
end

local function contains(values, expected)
    for _, value in ipairs(values or {}) do
        if value == expected then return true end
    end
    return false
end

local function canonical_body_trace(instance, route_ref)
    local body, body_err = packet.body_trace_tail(
        instance.trace,
        #instance.trace
    )
    if not body then
        return nil, make_error("reader_failure", "body_trace", body_err, {route_ref})
    end
    if #body > bounds.max_body_trace_events then
        return nil, make_error(
            "unsupported_v0",
            "body_trace",
            "Packet body trace exceeds v0 bound",
            {route_ref}
        )
    end
    local by_id = {}
    for index, event in ipairs(body) do
        if type(event) ~= "table" or type(event.id) ~= "string" or event.id == "" then
            return nil, make_error(
                "runtime_invariant_failure",
                "body_trace",
                "Packet body trace contains an event without identity",
                {route_ref}
            )
        end
        if by_id[event.id] ~= nil then
            return nil, make_error(
                "runtime_invariant_failure",
                "body_trace",
                "Packet body trace contains duplicate event identity",
                {route_ref, event.id}
            )
        end
        by_id[event.id] = {event = event, index = index}
    end
    return {events = body, by_id = by_id}
end

local function invalid_root(message, refs)
    return nil, make_error(
        "invalid_measurement_request",
        "request",
        message,
        refs
    )
end

local function invariant(stage, message, refs)
    return nil, make_error(
        "runtime_invariant_failure",
        stage,
        message,
        refs
    )
end

local function resolve_root_route(trace, request)
    local root = trace.by_id[request.route_event_ref]
    if not root then
        return invalid_root("route_event_ref does not resolve in the body lane", {
            request.route_event_ref,
        })
    end
    local event = root.event
    local payload = event.payload
    if event.type ~= "route" or event.truth_status ~= "runtime_confirmed"
        or type(payload) ~= "table" or payload.authority ~= "tree"
        or payload.from ~= "▽" or payload.to ~= "☷" then
        return invalid_root("route_event_ref is not a committed Tree ▽ -> ☷ route", {
            request.route_event_ref,
        })
    end
    if event.operator ~= "☷" or payload.kind ~= "tree_route_decision" then
        return invariant("selected_obligation", "committed route shape is contradictory", {
            request.route_event_ref,
        })
    end
    for _, key in ipairs({
        "derivation_ref",
        "pressure_snapshot_ref",
        "selected_action_plan_id",
    }) do
        if type(payload[key]) ~= "string" or payload[key] == "" then
            return invariant(
                "selected_obligation",
                "committed route is missing " .. key,
                {request.route_event_ref}
            )
        end
    end
    return root
end

local function resolve_pre_records(trace, root)
    local route = root.event
    local route_payload = route.payload
    local derivation = trace.by_id[route_payload.derivation_ref]
    local snapshot = trace.by_id[route_payload.pressure_snapshot_ref]
    if not derivation or not snapshot then
        return invariant(
            "selected_obligation",
            "committed route pre-effect refs do not resolve in the body lane",
            {
                route.id,
                route_payload.derivation_ref,
                route_payload.pressure_snapshot_ref,
            }
        )
    end
    if not (snapshot.index < derivation.index and derivation.index < root.index) then
        return invariant(
            "selected_obligation",
            "pre-effect snapshot/derivation/route order is invalid",
            {snapshot.event.id, derivation.event.id, route.id}
        )
    end
    local derivation_payload = derivation.event.payload
    if derivation.event.type ~= "route_derivation"
        or derivation.event.operator ~= "▽"
        or derivation.event.truth_status ~= "runtime_confirmed"
        or type(derivation_payload) ~= "table"
        or derivation_payload.kind ~= "route_derivation"
        or derivation_payload.current_operator ~= "▽"
        or derivation_payload.outcome ~= "selected"
        or derivation_payload.selected_to ~= "☷"
        or derivation_payload.pressure_snapshot_ref ~= snapshot.event.id then
        return invariant(
            "selected_obligation",
            "route derivation contradicts committed route",
            {route.id, derivation.event.id, snapshot.event.id}
        )
    end
    local snapshot_payload = snapshot.event.payload
    if snapshot.event.type ~= "tension_measure"
        or snapshot.event.operator ~= "▽"
        or snapshot.event.truth_status ~= "runtime_confirmed"
        or type(snapshot_payload) ~= "table"
        or snapshot_payload.kind ~= "qualified_pressure_snapshot" then
        return invariant(
            "selected_obligation",
            "pre-effect pressure snapshot shape is invalid",
            {snapshot.event.id}
        )
    end
    return {
        route = route,
        route_index = root.index,
        derivation = derivation.event,
        derivation_index = derivation.index,
        snapshot = snapshot.event,
        snapshot_index = snapshot.index,
    }
end

local function selected_candidate(pre)
    local route_payload = pre.route.payload
    local derivation_payload = pre.derivation.payload
    local selected
    local selected_count = 0
    if type(derivation_payload.candidates) ~= "table" then
        return invariant(
            "selected_obligation",
            "route derivation candidates are absent",
            {pre.derivation.id}
        )
    end
    for _, candidate in ipairs(derivation_payload.candidates) do
        if type(candidate) == "table" and candidate.to == "☷" then
            selected = candidate
            selected_count = selected_count + 1
        end
    end
    if selected_count ~= 1 then
        return invariant(
            "selected_obligation",
            "route derivation does not contain one ☷ candidate",
            {pre.derivation.id}
        )
    end
    for _, copy in ipairs({
        derivation_payload.selected_candidate,
        route_payload.selected_candidate,
    }) do
        local same, same_err = same_value(selected, copy)
        if same == nil then
            return nil, make_error("reader_failure", "selected_obligation", same_err, {
                pre.route.id,
                pre.derivation.id,
            })
        end
        if not same then
            return invariant(
                "selected_obligation",
                "selected candidate copies disagree",
                {pre.route.id, pre.derivation.id}
            )
        end
    end
    if selected.excluded ~= false
        or type(selected.readiness) ~= "table"
        or selected.readiness.ready ~= true
        or selected.action_status ~= "validated"
        or selected.witness_count ~= 1
        or selected.executable_witness_count ~= 1
        or type(selected.witnesses) ~= "table" or #selected.witnesses ~= 1
        or type(selected.executable_witnesses) ~= "table"
        or #selected.executable_witnesses ~= 1
        or type(selected.action_plan) ~= "table" then
        return nil, make_error(
            "unsupported_v0",
            "selected_obligation",
            "selected DISSOLVE candidate is not one executable witness/action",
            {pre.route.id, pre.derivation.id}
        )
    end
    local witness = selected.witnesses[1]
    local executable_same, executable_err = same_value(
        witness,
        selected.executable_witnesses[1]
    )
    if executable_same == nil then
        return nil, make_error(
            "reader_failure",
            "selected_obligation",
            executable_err,
            {pre.derivation.id}
        )
    end
    if not executable_same then
        return invariant(
            "selected_obligation",
            "selected and executable witnesses disagree",
            {pre.derivation.id}
        )
    end
    if route_payload.selected_action_plan_id ~= selected.action_plan.plan_id
        or derivation_payload.selected_action_plan_id ~= selected.action_plan.plan_id then
        return invariant(
            "selected_obligation",
            "selected action identity disagrees across route records",
            {pre.route.id, pre.derivation.id}
        )
    end
    return selected, witness, selected.action_plan
end

local function snapshot_witness(pre, selected_witness)
    local snapshot = pre.snapshot.payload
    if snapshot.packet_id == nil or snapshot.generation == nil
        or snapshot.current_operator ~= "▽"
        or snapshot.derivation_version ~= "pressure.qualified_need.v0"
        or snapshot.runtime_policy ~= "qualified_need_v0"
        or snapshot.event_truth_status ~= "runtime_confirmed"
        or type(snapshot.witnesses) ~= "table" then
        return invariant(
            "selected_obligation",
            "pre-effect qualified pressure snapshot is malformed",
            {pre.snapshot.id}
        )
    end
    local found
    local count = 0
    for _, witness in ipairs(snapshot.witnesses) do
        if type(witness) == "table"
            and witness.witness_id == selected_witness.witness_id then
            found = witness
            count = count + 1
        end
    end
    if count ~= 1 then
        return invariant(
            "selected_obligation",
            "selected witness does not resolve uniquely in pressure snapshot",
            {pre.snapshot.id, pre.derivation.id}
        )
    end
    local same, same_err = same_value(found, selected_witness)
    if same == nil then
        return nil, make_error(
            "reader_failure",
            "selected_obligation",
            same_err,
            {pre.snapshot.id, pre.derivation.id}
        )
    end
    if not same then
        return invariant(
            "selected_obligation",
            "selected witness copies disagree",
            {pre.snapshot.id, pre.derivation.id}
        )
    end
    return found
end

local function exact_object_version(versions, target_id, target_version)
    if type(versions) ~= "table" or getmetatable(versions) ~= nil then
        return false
    end
    local count = 0
    for id, version in pairs(versions) do
        count = count + 1
        if id ~= target_id or version ~= target_version then
            return false
        end
    end
    return count == 1
end

local function validate_treatment(instance, pre, witness, plan)
    local plan_ok, plan_err = pressure_action.validate(plan)
    if not plan_ok then
        return invariant(
            "selected_obligation",
            "selected pressure action is invalid: " .. tostring(plan_err),
            {pre.snapshot.id, pre.derivation.id, pre.route.id}
        )
    end
    local witness_plan_same = pressure_action.same(plan, witness.action_plan)
    local options = plan.options and plan.options.dissolve
    local target = options and options.target
    local reason = options and options.reason
    local expected_effect = plan.expected_effect
    if witness_plan_same ~= true
        or witness.protocol_version ~= "pressure.witness.v1"
        or witness.kind ~= "inherited_rejected_form_release_need"
        or witness.current_operator ~= "▽"
        or witness.target_operator ~= "☷"
        or witness.causal_class ~= "blocking_demand"
        or witness.source_domain ~= "network_inherited_rejected_form"
        or witness.consumer_contract ~= "dissolve.inherited_rejected_form.v0"
        or witness.calculation_status ~= "runtime_confirmed"
        or witness.source_truth_status ~= "inherited_proposal"
        or type(witness.scope_refs) ~= "table"
        or type(witness.provenance_refs) ~= "table"
        or plan.witness_id ~= witness.witness_id
        or plan.mode ~= "inherited_rejected_form_release"
        or plan.target_operator ~= "☷"
        or plan.preconditions.packet_id ~= instance.id
        or plan.preconditions.generation ~= instance.generation
        or type(target) ~= "table" or target.kind ~= "unit"
        or type(target.id) ~= "string" or target.id == ""
        or type(target.version) ~= "number"
        or not exact_object_version(
            plan.preconditions.object_versions,
            target.id,
            target.version
        )
        or type(plan.preconditions.planned_residue_unit_id) ~= "string"
        or plan.preconditions.planned_residue_unit_id == ""
        or type(plan.preconditions.relevant_revisions) ~= "table"
        or type(plan.preconditions.relevant_revisions.potential) ~= "number"
        or options.scope ~= "unit" or options.preserve_residue ~= true
        or type(reason) ~= "table"
        or type(expected_effect) ~= "table"
        or expected_effect.event_type ~= "dissolve_organ_payload"
        or expected_effect.discharge_reader
            ~= "inherited_rejected_form_release_need" then
        return invariant(
            "selected_obligation",
            "selected witness/action does not match inherited-form treatment v0",
            {pre.snapshot.id, pre.derivation.id, pre.route.id}
        )
    end
    local projection = instance.ingress and instance.ingress.network_projection
    local projection_ok, projection_err = network_projection_schema.verify_projection(
        projection
    )
    if not projection_ok then
        return invariant(
            "selected_obligation",
            "NETWORK projection is invalid: " .. tostring(projection_err),
            {pre.route.id}
        )
    end
    local form = projection.rejected_form
    if type(form) ~= "table" then
        return invariant(
            "selected_obligation",
            "NETWORK projection has no rejected form",
            {pre.route.id, projection.projection_id}
        )
    end
    local expected_reason = {
        kind = "rejected",
        subtype = "ancestor_candidate",
        network_projection_id = projection.projection_id,
        carrier_id = projection.carrier_id,
        source_corpse_id = projection.source_corpse_id,
        historical_qa_id = projection.historical_qa_id,
        candidate_seal_id = form.candidate_seal_id,
        verdict_id = form.verdict_id,
    }
    if not network_projection_schema.same(reason, expected_reason)
        or witness.network_projection_id ~= projection.projection_id then
        return invariant(
            "selected_obligation",
            "selected witness/action contradicts NETWORK projection",
            {pre.snapshot.id, pre.route.id, projection.projection_id}
        )
    end
    local expected_scope = {
        "coverage:field_unit:" .. target.id .. ":" .. tostring(target.version),
        projection.projection_id,
        projection.carrier_id,
        projection.source_corpse_id,
        projection.historical_qa_id,
        form.candidate_seal_id,
        form.verdict_id,
    }
    table.sort(expected_scope)
    if not same_array(plan.scope_refs, expected_scope)
        or not same_array(witness.scope_refs, expected_scope)
        or not contains(witness.provenance_refs,
            "consumer:dissolve.inherited_rejected_form.v0") then
        return invariant(
            "selected_obligation",
            "selected witness/action scope is not exact",
            {pre.snapshot.id, pre.derivation.id}
        )
    end
    return {
        witness = copy_value(witness),
        plan = copy_value(plan),
        target = copy_value(target),
        reason = copy_value(reason),
        projection = copy_value(projection),
        planned_residue_unit_id = plan.preconditions.planned_residue_unit_id,
    }
end

local function resolve_selected_obligation(instance, request)
    local trace, trace_err = canonical_body_trace(instance, request.route_event_ref)
    if not trace then return nil, trace_err end
    local root, root_err = resolve_root_route(trace, request)
    if not root then return nil, root_err end
    local pre, pre_err = resolve_pre_records(trace, root)
    if not pre then return nil, pre_err end
    if pre.snapshot.payload.packet_id ~= instance.id
        or pre.snapshot.payload.generation ~= instance.generation then
        return invariant(
            "selected_obligation",
            "pre-effect snapshot Packet identity is foreign",
            {pre.snapshot.id, pre.route.id}
        )
    end
    local candidate, candidate_witness, plan_or_err = selected_candidate(pre)
    if not candidate then return nil, candidate_witness end
    local witness, witness_err = snapshot_witness(pre, candidate_witness)
    if not witness then return nil, witness_err end
    local treatment, treatment_err = validate_treatment(
        instance,
        pre,
        witness,
        plan_or_err
    )
    if not treatment then return nil, treatment_err end
    return {
        trace = trace,
        pre = pre,
        candidate = copy_value(candidate),
        treatment = treatment,
    }
end

local terminal_body_events = {
    death = true,
    manifest = true,
    terminal = true,
}

local function missing_aftermath(reason, selected, refs)
    return {
        not_measurable_reason = reason,
        selected = selected,
        source_refs = sorted_unique(refs),
    }
end

local function verify_edge_join(context, selected, tick, release, effect_refs)
    if context.edge_credit == nil then
        return true
    end
    local commit = context.edge_credit.commit
    local arrival = context.edge_credit.arrival
    local plan = selected.treatment.plan
    if commit.route_trace_ref ~= selected.pre.route.id
        or commit.from ~= "▽" or commit.to ~= "☷"
        or commit.route_authority ~= "tree"
        or arrival.destination_tick_ref ~= tick.id
        or arrival.payload_kind ~= plan.expected_effect.event_type
        or not same_array(arrival.effect_refs, effect_refs)
        or not contains(arrival.effect_refs, release.id) then
        return invariant(
            "edge_credit",
            "edge-credit chain contradicts body-derived arrival/effect",
            {
                selected.pre.route.id,
                tick.id,
                release.id,
                commit.record_id,
                arrival.record_id,
            }
        )
    end
    return true
end

local function verify_release_join(instance, selected, release_event)
    local treatment = selected.treatment
    local release = release_event.payload
    local release_ok, release_err = dissolve_schema.verify_release(release)
    if not release_ok then
        return invariant(
            "effect",
            "DISSOLVE release is invalid: " .. tostring(release_err),
            {selected.pre.route.id, release_event.id}
        )
    end
    if release_event.operator ~= "☷"
        or release_event.truth_status ~= "runtime_confirmed"
        or release.target.id ~= treatment.target.id
        or release.target.before_version ~= treatment.target.version
        or not dissolve_schema.same(release.reason, treatment.reason)
        or release.residue_unit_id ~= treatment.planned_residue_unit_id
        or not same_array(release.source_refs, treatment.plan.scope_refs) then
        return invariant(
            "effect",
            "DISSOLVE release contradicts selected obligation",
            {selected.pre.route.id, release_event.id}
        )
    end

    local target = field.get_unit(instance, release.target.id)
    local residue = field.get_unit(instance, release.residue_unit_id)
    local target_source = target and target.activation_source
    local residue_carrier_ok = residue
        and dissolve_schema.verify_residue_carrier(residue.carrier)
    if not target or target.kind ~= "inherited_rejected_form"
        or target.generation ~= instance.generation
        or target.version ~= release.target.after_version
        or target.activation ~= "dissolved"
        or type(target_source) ~= "table"
        or target_source.event_id ~= release_event.id
        or target_source.actor ~= "☷"
        or target_source.reason ~= "inherited_rejected_form_release"
        or not residue or residue.kind ~= "rejected_form_residue"
        or residue.generation ~= instance.generation
        or residue.activation ~= "live"
        or residue.created_event_id ~= release_event.id
        or residue_carrier_ok ~= true
        or residue.carrier.release_id ~= release.release_id then
        return invariant(
            "effect",
            "DISSOLVE release contradicts current target/residue state",
            {selected.pre.route.id, release_event.id, release.residue_unit_id}
        )
    end
    return {
        release = copy_value(release),
        target = target,
        residue = residue,
    }
end

local function old_action_finality(instance, selected, release_event)
    local plan = selected.treatment.plan
    local preconditions_ok, preconditions_err = pressure_action.verify_preconditions(
        plan,
        instance
    )
    local preconditions_fresh = preconditions_ok == true
    if not preconditions_fresh
        and preconditions_err
            ~= "pressure action object version precondition mismatch" then
        return invariant(
            "effect",
            "old action did not stale on its target version: "
                .. tostring(preconditions_err),
            {selected.pre.route.id, release_event.id}
        )
    end
    local options = copy_value(plan.options.dissolve)
    options.qualified_action = {
        plan_id = plan.plan_id,
        scope_refs = copy_value(plan.scope_refs),
        planned_residue_unit_id = plan.preconditions.planned_residue_unit_id,
        potential_revision = plan.preconditions.relevant_revisions.potential,
    }
    local readiness, readiness_err = dissolve.readiness(instance, options)
    if not readiness then
        return invariant(
            "effect",
            "post-release DISSOLVE readiness failed: " .. tostring(readiness_err),
            {selected.pre.route.id, release_event.id}
        )
    end
    local readiness_state
    if readiness.ready == false and readiness.reason == "already_released" then
        readiness_state = "already_released"
    elseif readiness.ready == true
        and readiness.reason == "inherited_rejected_form_releasable" then
        readiness_state = "releasable"
    else
        return invariant(
            "effect",
            "post-release DISSOLVE readiness is contradictory",
            {selected.pre.route.id, release_event.id}
        )
    end
    return {
        old_action_preconditions_fresh = preconditions_fresh,
        old_action_readiness = readiness_state,
    }
end

local function resolve_effect_aftermath(instance, selected, context)
    local trace = selected.trace.events
    local route = selected.pre.route
    local tick_entry = trace[selected.pre.route_index + 1]
    if tick_entry == nil then
        return missing_aftermath(
            "destination_tick_absent",
            selected,
            {route.id}
        )
    end
    if tick_entry.type ~= "operator_tick" or tick_entry.operator ~= "☷"
        or tick_entry.truth_status ~= "runtime_confirmed"
        or type(tick_entry.payload) ~= "table"
        or type(tick_entry.payload.input_refs) ~= "table" then
        return invariant(
            "arrival",
            "first body event after route is not the destination ☷ tick",
            {route.id, tick_entry.id}
        )
    end

    local release_entry
    local frame_entry
    local frame_index
    for index = selected.pre.route_index + 2, #trace do
        local event = trace[index]
        if event.type == "operator_tick" or terminal_body_events[event.type] then
            break
        end
        if event.type == "route" then
            return invariant(
                "arrival",
                "body route appeared inside the destination tick",
                {route.id, tick_entry.id, event.id}
            )
        end
        if event.type == "unit_dissolution" then
            if release_entry ~= nil then
                return invariant(
                    "effect",
                    "destination tick contains multiple unit_dissolution events",
                    {route.id, release_entry.id, event.id}
                )
            end
            release_entry = event
        elseif event.type == "runtime_frame" then
            frame_entry = event
            frame_index = index
            break
        end
    end
    if release_entry == nil then
        return missing_aftermath(
            "release_event_absent",
            selected,
            {route.id, tick_entry.id}
        )
    end
    if frame_entry == nil then
        return missing_aftermath(
            "post_effect_runtime_frame_absent",
            selected,
            {route.id, tick_entry.id, release_entry.id}
        )
    end

    local release_state, release_err = verify_release_join(
        instance,
        selected,
        release_entry
    )
    if not release_state then return nil, release_err end
    local frame = frame_entry.payload
    if frame_entry.operator ~= "☷"
        or frame_entry.truth_status ~= "runtime_confirmed"
        or type(frame) ~= "table" or frame.kind ~= "runtime_frame"
        or frame.operator ~= "☷" or frame.trace_event_id ~= nil
        or not contains(frame.source_event_refs, tick_entry.id)
        or not contains(frame.source_event_refs, release_entry.id)
        or not contains(frame.effect_refs, release_entry.id) then
        return invariant(
            "runtime_frame",
            "post-effect runtime frame contradicts destination release",
            {route.id, tick_entry.id, release_entry.id, frame_entry.id}
        )
    end
    local revisions_same, revisions_err = same_value(
        instance.revisions,
        frame.revisions_after
    )
    if revisions_same == nil then
        return nil, make_error(
            "reader_failure",
            "runtime_frame",
            revisions_err,
            {frame_entry.id}
        )
    end
    if not revisions_same then
        return missing_aftermath(
            "capture_window_advanced",
            selected,
            {route.id, release_entry.id, frame_entry.id}
        )
    end

    local effect_refs = {}
    for index = selected.pre.route_index + 2, #trace do
        local event = trace[index]
        if event.id == frame_entry.id then break end
        effect_refs[#effect_refs + 1] = event.id
    end
    table.sort(effect_refs)
    local edge_ok, edge_err = verify_edge_join(
        context,
        selected,
        tick_entry,
        release_entry,
        effect_refs
    )
    if not edge_ok then return nil, edge_err end

    local finality, finality_err = old_action_finality(
        instance,
        selected,
        release_entry
    )
    if not finality then return nil, finality_err end
    return {
        selected = selected,
        destination_tick = copy_value(tick_entry),
        release_event = copy_value(release_entry),
        runtime_frame = copy_value(frame_entry),
        runtime_frame_index = frame_index,
        release_state = release_state,
        old_action = finality,
        source_refs = sorted_unique({
            selected.pre.snapshot.id,
            selected.pre.derivation.id,
            route.id,
            tick_entry.id,
            release_entry.id,
            frame_entry.id,
        }),
    }
end

local obligation_protocol = "dissolve.pressure_obligation_identity.v0"

local function obligation_identity(instance, witness)
    local plan = witness and witness.action_plan
    local options = plan and plan.options and plan.options.dissolve
    local target = options and options.target
    local reason = options and options.reason
    local projection = instance.ingress and instance.ingress.network_projection
    local projection_ok, projection_err = network_projection_schema.verify_projection(
        projection
    )
    if not projection_ok then
        return nil, "NETWORK projection is invalid: " .. tostring(projection_err)
    end
    local form = projection.rejected_form
    local plan_ok, plan_err = pressure_action.validate(plan)
    if not plan_ok then
        return nil, "release action is invalid: " .. tostring(plan_err)
    end
    local expected_reason = {
        kind = "rejected",
        subtype = "ancestor_candidate",
        network_projection_id = projection.projection_id,
        carrier_id = projection.carrier_id,
        source_corpse_id = projection.source_corpse_id,
        historical_qa_id = projection.historical_qa_id,
        candidate_seal_id = form.candidate_seal_id,
        verdict_id = form.verdict_id,
    }
    if witness.protocol_version ~= "pressure.witness.v1"
        or witness.kind ~= "inherited_rejected_form_release_need"
        or witness.current_operator ~= "▽"
        or witness.target_operator ~= "☷"
        or witness.causal_class ~= "blocking_demand"
        or witness.source_domain ~= "network_inherited_rejected_form"
        or witness.calculation_status ~= "runtime_confirmed"
        or witness.source_truth_status ~= "inherited_proposal"
        or witness.consumer_contract
            ~= "dissolve.inherited_rejected_form.v0"
        or witness.network_projection_id ~= projection.projection_id
        or plan.mode ~= "inherited_rejected_form_release"
        or plan.target_operator ~= "☷"
        or plan.witness_id ~= witness.witness_id
        or not same_array(plan.scope_refs or {}, witness.scope_refs or {})
        or plan.preconditions.packet_id ~= instance.id
        or plan.preconditions.generation ~= instance.generation
        or type(options) ~= "table" or options.scope ~= "unit"
        or options.preserve_residue ~= true
        or type(target) ~= "table" or target.kind ~= "unit"
        or type(target.id) ~= "string" or target.id == ""
        or type(target.version) ~= "number" or target.version < 1
        or target.version ~= math.floor(target.version)
        or not exact_object_version(
            plan.preconditions.object_versions,
            target.id,
            target.version
        )
        or type(plan.expected_effect) ~= "table"
        or plan.expected_effect.event_type ~= "dissolve_organ_payload"
        or plan.expected_effect.discharge_reader
            ~= "inherited_rejected_form_release_need"
        or not dissolve_schema.same(reason, expected_reason) then
        return nil, "release witness cannot form canonical obligation identity"
    end
    local envelope = {
        protocol_version = obligation_protocol,
        packet_id = instance.id,
        generation = instance.generation,
        treatment = "dissolve.inherited_rejected_form_release.v0",
        consumer_contract = "dissolve.inherited_rejected_form.v0",
        witness_kind = "inherited_rejected_form_release_need",
        source_domain = "network_inherited_rejected_form",
        target_operator = "☷",
        action_mode = "inherited_rejected_form_release",
        target_unit_id = target.id,
        network_projection_id = projection.projection_id,
        carrier_id = projection.carrier_id,
        source_corpse_id = projection.source_corpse_id,
        historical_qa_id = projection.historical_qa_id,
        candidate_seal_id = form.candidate_seal_id,
        verdict_id = form.verdict_id,
    }
    local identity, identity_err = digest.record(envelope)
    if not identity then return nil, identity_err end
    return "pressure-obligation:" .. identity
end

local function resolve_same_coordinate_control(instance, aftermath)
    local selected = aftermath.selected
    local selected_key, selected_key_err = obligation_identity(
        instance,
        selected.treatment.witness
    )
    if not selected_key then
        return invariant(
            "same_coordinate_control",
            "selected obligation identity failed: " .. tostring(selected_key_err),
            {selected.pre.snapshot.id, selected.pre.route.id}
        )
    end

    local before, before_err = digest.record(instance)
    if not before then
        return nil, make_error(
            "reader_failure",
            "purity",
            before_err,
            aftermath.source_refs
        )
    end
    local called, control, control_err = pcall(
        qualified_pressure.derive,
        instance,
        {operator = "▽"},
        {
            current_operator = "▽",
            router_mode = "tree",
        }
    )
    local after, after_err = digest.record(instance)
    if not after then
        return nil, make_error(
            "reader_failure",
            "purity",
            after_err,
            aftermath.source_refs
        )
    end
    if before ~= after then
        return nil, make_error(
            "reader_failure",
            "purity",
            "same-coordinate pressure derivation mutated Packet state",
            aftermath.source_refs
        )
    end
    if not called then
        return nil, make_error(
            "reader_failure",
            "same_coordinate_control",
            control,
            aftermath.source_refs
        )
    end
    if not control then
        return nil, make_error(
            "reader_failure",
            "same_coordinate_control",
            control_err,
            aftermath.source_refs
        )
    end
    local revisions_same, revisions_err = same_value(
        control.source_revisions,
        instance.revisions
    )
    if revisions_same == nil then
        return nil, make_error(
            "reader_failure",
            "same_coordinate_control",
            revisions_err,
            aftermath.source_refs
        )
    end
    if control.kind ~= "qualified_pressure_snapshot"
        or control.packet_id ~= instance.id
        or control.generation ~= instance.generation
        or control.current_operator ~= "▽"
        or control.derivation_version ~= "pressure.qualified_need.v0"
        or control.runtime_policy ~= "qualified_need_v0"
        or control.event_truth_status ~= "runtime_confirmed"
        or type(control.witnesses) ~= "table"
        or not revisions_same then
        return invariant(
            "same_coordinate_control",
            "same-coordinate pressure snapshot is contradictory",
            aftermath.source_refs
        )
    end

    local exact_count = 0
    local same_obligation_count = 0
    for _, witness in ipairs(control.witnesses) do
        if witness.witness_id == selected.treatment.witness.witness_id then
            exact_count = exact_count + 1
        end
        if witness.kind == "inherited_rejected_form_release_need" then
            local key, key_err = obligation_identity(instance, witness)
            if not key then
                return invariant(
                    "same_coordinate_control",
                    "post witness obligation identity failed: "
                        .. tostring(key_err),
                    aftermath.source_refs
                )
            end
            if key == selected_key then
                same_obligation_count = same_obligation_count + 1
            end
        end
    end
    return {
        snapshot = copy_value(control),
        selected_obligation_key = selected_key,
        evidence = {
            coordinate = "▽",
            coordinate_status = "same_coordinate_control",
            exact_selected_witness_count = exact_count,
            same_obligation_count = same_obligation_count,
            old_action_preconditions_fresh =
                aftermath.old_action.old_action_preconditions_fresh,
            old_action_readiness = aftermath.old_action.old_action_readiness,
        },
    }
end

local function current_work_unit(instance, projection)
    local view, view_err = field.view(instance, {
        kinds = {network_current_work = true},
        generation = instance.generation,
        limit = 2,
    })
    if not view then return nil, view_err end
    if view.truncated or view.total_count ~= 1 or #view.units ~= 1 then
        return nil, "post-release field does not contain one current-work unit"
    end
    local unit = view.units[1]
    local migration = unit.migration or {}
    if unit.activation ~= "live" and unit.activation ~= "selected" then
        return nil, "current-work unit is not active"
    end
    if unit.generation ~= instance.generation or unit.created_by ~= "▽"
        or not network_projection_schema.same(unit.carrier, projection.current_work)
        or migration.status ~= "network_reentry_v1"
        or migration.projection_id ~= projection.projection_id
        or migration.projection_role ~= "current_work" then
        return nil, "current-work unit contradicts NETWORK projection"
    end
    return unit
end

local function exact_versions(value, expected)
    if type(value) ~= "table" or getmetatable(value) ~= nil then return false end
    local count = 0
    for id, version in pairs(value) do
        count = count + 1
        if expected[id] ~= version then return false end
    end
    local expected_count = 0
    for id, version in pairs(expected) do
        expected_count = expected_count + 1
        if value[id] ~= version then return false end
    end
    return count == expected_count
end

local function candidate_for(derivation, target)
    local found
    local count = 0
    for _, candidate in ipairs(derivation.candidates or {}) do
        if type(candidate) == "table" and candidate.to == target then
            found = candidate
            count = count + 1
        end
    end
    if count ~= 1 then return nil end
    return found
end

local function witness_in(values, witness)
    local count = 0
    for _, candidate in ipairs(values or {}) do
        if candidate.witness_id == witness.witness_id then
            local same = same_value(candidate, witness)
            if same ~= true then return nil, "witness copies disagree" end
            count = count + 1
        end
    end
    return count
end

local function verify_expected_successor(instance, aftermath, witness, derivation)
    local plan = witness.action_plan
    local observe = plan and plan.options and plan.options.observe
    local projection = aftermath.selected.treatment.projection
    local release = aftermath.release_state.release
    local target = aftermath.release_state.target
    local residue = aftermath.release_state.residue
    local current, current_err = current_work_unit(instance, projection)
    if not current then return nil, current_err end
    local expected_versions = {
        [current.id] = current.version,
        [target.id] = target.version,
        [residue.id] = residue.version,
    }
    local expected_ids = sorted_unique({current.id, target.id, residue.id})
    local expected_scope = sorted_unique({
        "coverage:field_unit:" .. current.id .. ":" .. tostring(current.version),
        "coverage:field_unit:" .. target.id .. ":" .. tostring(target.version),
        "coverage:field_unit:" .. residue.id .. ":" .. tostring(residue.version),
    })
    local plan_ok, plan_err = pressure_action.validate(plan)
    if not plan_ok then
        return nil, "successor action is invalid: " .. tostring(plan_err)
    end
    if witness.protocol_version ~= "pressure.witness.v1"
        or witness.kind ~= "upper_observation_need"
        or witness.current_operator ~= "☷"
        or witness.target_operator ~= "☴"
        or witness.causal_class ~= "blocking_demand"
        or witness.source_domain ~= "upper_observation:material+semantic"
        or plan.mode ~= "semantic_observe" or plan.target_operator ~= "☴"
        or type(observe) ~= "table" or observe.sensor ~= "semantic"
        or observe.presentation_policy
            ~= "network.rejected_form_after_release.v0"
        or not same_array(observe.unit_ids or {}, expected_ids)
        or not exact_versions(observe.unit_versions, expected_versions)
        or not exact_versions(plan.preconditions.object_versions, expected_versions)
        or not same_array(witness.scope_refs or {}, expected_scope)
        or plan.preconditions.packet_id ~= instance.id
        or plan.preconditions.generation ~= instance.generation
        or residue.carrier.release_id ~= release.release_id
        or not contains(witness.provenance_refs, residue.created_event_id)
        or not contains(witness.provenance_refs, target.created_event_id)
        or not contains(witness.provenance_refs, current.created_event_id) then
        return nil, "upper-OBSERVE successor contradicts release/field identity"
    end
    local candidate = candidate_for(derivation, "☴")
    if not candidate then
        return nil, "post derivation has no unique OBSERVE candidate"
    end
    local witness_count, witness_err = witness_in(candidate.witnesses, witness)
    if witness_count == nil then return nil, witness_err end
    if witness_count ~= 1 then
        return nil, "OBSERVE candidate omits expected successor witness"
    end
    local executable_count, executable_err = witness_in(
        candidate.executable_witnesses,
        witness
    )
    if executable_count == nil then return nil, executable_err end
    if executable_count > 1 then
        return nil, "OBSERVE candidate duplicates executable successor"
    end
    local executable = executable_count == 1
    if executable then
        local same_plan = same_value(candidate.action_plan, plan)
        if candidate.excluded ~= false or candidate.action_status ~= "validated"
            or same_plan ~= true then
            return nil, "executable successor contradicts candidate decision"
        end
    end
    return {
        witness_id = witness.witness_id,
        action_plan_id = plan.plan_id,
        presentation_policy = "network.rejected_form_after_release.v0",
        executable = executable,
    }
end

local function resolve_actual_successor(instance, aftermath)
    local trace = aftermath.selected.trace.events
    local snapshot_entry
    local snapshot_index
    for index = aftermath.runtime_frame_index + 1, #trace do
        local event = trace[index]
        if event.type == "operator_tick" or event.type == "route"
            or terminal_body_events[event.type] then
            break
        end
        if event.type == "tension_measure" then
            snapshot_entry = event
            snapshot_index = index
            break
        end
    end
    if snapshot_entry == nil then
        return missing_aftermath(
            "actual_post_pressure_snapshot_absent",
            aftermath.selected,
            aftermath.source_refs
        )
    end
    local snapshot = snapshot_entry.payload
    local frame = aftermath.runtime_frame.payload
    local frame_revisions_same = same_value(
        snapshot and snapshot.source_revisions,
        frame.revisions_after
    )
    local live_revisions_same = same_value(
        snapshot and snapshot.source_revisions,
        instance.revisions
    )
    if snapshot_entry.operator ~= "☷"
        or snapshot_entry.truth_status ~= "runtime_confirmed"
        or type(snapshot) ~= "table"
        or snapshot.kind ~= "qualified_pressure_snapshot"
        or snapshot.packet_id ~= instance.id
        or snapshot.generation ~= instance.generation
        or snapshot.current_operator ~= "☷"
        or snapshot.derivation_version ~= "pressure.qualified_need.v0"
        or snapshot.runtime_policy ~= "qualified_need_v0"
        or snapshot.event_truth_status ~= "runtime_confirmed"
        or type(snapshot.witnesses) ~= "table"
        or frame_revisions_same ~= true
        or live_revisions_same ~= true then
        return invariant(
            "actual_post",
            "actual post-effect pressure snapshot is contradictory",
            {aftermath.runtime_frame.id, snapshot_entry.id}
        )
    end

    local derivation_entry = trace[snapshot_index + 1]
    if derivation_entry == nil then
        return missing_aftermath(
            "actual_post_route_derivation_absent",
            aftermath.selected,
            sorted_unique({
                aftermath.runtime_frame.id,
                snapshot_entry.id,
            })
        )
    end
    local derivation = derivation_entry.payload
    if derivation_entry.type ~= "route_derivation"
        or derivation_entry.operator ~= "☷"
        or derivation_entry.truth_status ~= "runtime_confirmed"
        or type(derivation) ~= "table"
        or derivation.kind ~= "route_derivation"
        or derivation.current_operator ~= "☷"
        or derivation.pressure_snapshot_ref ~= snapshot_entry.id
        or type(derivation.candidates) ~= "table" then
        return invariant(
            "actual_post",
            "actual post-effect route derivation is contradictory",
            {snapshot_entry.id, derivation_entry.id}
        )
    end

    local witness_ids = {}
    local expected
    local expected_count = 0
    for _, witness in ipairs(snapshot.witnesses) do
        if type(witness) ~= "table" or type(witness.witness_id) ~= "string"
            or witness.witness_id == "" then
            return invariant(
                "successor",
                "actual post snapshot contains an invalid witness",
                {snapshot_entry.id}
            )
        end
        witness_ids[#witness_ids + 1] = witness.witness_id
        if witness.kind == "upper_observation_need"
            and witness.target_operator == "☴"
            and witness.source_domain == "upper_observation:material+semantic"
            and witness.action_plan
            and witness.action_plan.mode == "semantic_observe"
            and witness.action_plan.options
            and witness.action_plan.options.observe
            and witness.action_plan.options.observe.presentation_policy
                == "network.rejected_form_after_release.v0" then
            expected_count = expected_count + 1
            expected = witness
        end
    end
    witness_ids = sorted_unique(witness_ids)
    if #witness_ids ~= #snapshot.witnesses then
        return invariant(
            "successor",
            "actual post snapshot contains duplicate witness identity",
            {snapshot_entry.id}
        )
    end
    if expected_count > 1 then
        return invariant(
            "successor",
            "actual post snapshot contains multiple expected successors",
            {snapshot_entry.id, derivation_entry.id}
        )
    end
    local expected_projection
    if expected then
        local projected, projected_err = verify_expected_successor(
            instance,
            aftermath,
            expected,
            derivation
        )
        if not projected then
            return invariant(
                "successor",
                projected_err,
                {snapshot_entry.id, derivation_entry.id}
            )
        end
        expected_projection = projected
    end
    local others = {}
    for _, witness_id in ipairs(witness_ids) do
        if not expected_projection
            or witness_id ~= expected_projection.witness_id then
            others[#others + 1] = witness_id
        end
    end
    return {
        snapshot = copy_value(snapshot),
        derivation = copy_value(derivation),
        evidence = {
            coordinate = "☷",
            pressure_snapshot_ref = snapshot_entry.id,
            route_derivation_ref = derivation_entry.id,
            successor_witness_ids = witness_ids,
            successor_obligation_count = #witness_ids,
            expected_successor = expected_projection,
            other_successor_witness_ids = others,
        },
        source_refs = {snapshot_entry.id, derivation_entry.id},
    }
end

local function selected_projection(instance, selected, obligation_key)
    local key = obligation_key
    if key == nil then
        local key_err
        key, key_err = obligation_identity(instance, selected.treatment.witness)
        if not key then return nil, key_err end
    end
    return {
        pre_coordinate = "▽",
        pressure_snapshot_ref = selected.pre.snapshot.id,
        route_derivation_ref = selected.pre.derivation.id,
        route_event_ref = selected.pre.route.id,
        witness_id = selected.treatment.witness.witness_id,
        same_obligation_key = key,
        action_plan_id = selected.treatment.plan.plan_id,
        causal_class = "blocking_demand",
        target_operator = "☷",
    }
end

local function effect_projection(aftermath)
    local release = aftermath.release_state.release
    return {
        destination_tick_ref = aftermath.destination_tick.id,
        release_event_ref = aftermath.release_event.id,
        post_effect_runtime_frame_ref = aftermath.runtime_frame.id,
        release_id = release.release_id,
        target = {
            id = release.target.id,
            before_version = release.target.before_version,
            after_version = release.target.after_version,
            after_activation = release.target.after_activation,
        },
        residue_unit_id = release.residue_unit_id,
        released_mass = copy_value(release.released_mass),
        irreversible_identity_loss = release.irreversible_identity_loss,
    }
end

local verify_view
local expected_not_discharged

local function finalize_view(value)
    value.measurement_id = nil
    local identity, identity_err = digest.record(value)
    if not identity then return nil, identity_err end
    value.measurement_id = "pressure-relief:" .. identity
    local verified, verified_err = verify_view(value, true)
    if not verified then return nil, verified_err end
    return copy_value(value)
end

local function not_measurable_view(instance, selected, reason, refs, aftermath, control)
    local selected_value, selected_err = selected_projection(instance, selected)
    if not selected_value then return nil, selected_err end
    return finalize_view({
        protocol_version = reader.protocol_version,
        treatment = "dissolve.inherited_rejected_form_release.v0",
        packet_id = instance.id,
        generation = instance.generation,
        measurement_status = "not_measurable",
        reason_codes = {reason},
        selected = selected_value,
        effect = aftermath and effect_projection(aftermath) or nil,
        controlled_post = control and copy_value(control.evidence) or nil,
        actual_post = nil,
        pressure_relief = {
            measure = "typed_selected_obligation_discharge",
            selected_obligation_count = 1,
            classification = "not_measurable",
        },
        aggregate_diagnostic = nil,
        source_refs = sorted_unique(refs),
        calculation_status = "runtime_confirmed",
        authority = "diagnostic",
    })
end

local function measured_view(instance, aftermath, control, actual)
    local controlled = copy_value(control.evidence)
    local reasons = expected_not_discharged(controlled)
    local status = #reasons > 0 and "not_discharged" or "discharged"
    local selected_value, selected_err = selected_projection(
        instance,
        aftermath.selected,
        control.selected_obligation_key
    )
    if not selected_value then return nil, selected_err end
    local actual_value = copy_value(actual.evidence)
    local classification
    local discharged
    local unresolved
    if status == "not_discharged" then
        classification = "not_discharged"
        discharged = 0
        unresolved = 1
    else
        classification = actual_value.successor_obligation_count > 0
            and "discharged_with_successor_obligation"
            or "discharged_without_successor_obligation"
        discharged = 1
        unresolved = 0
    end
    local source_refs = copy_value(aftermath.source_refs)
    for _, ref in ipairs(actual.source_refs) do
        source_refs[#source_refs + 1] = ref
    end
    return finalize_view({
        protocol_version = reader.protocol_version,
        treatment = "dissolve.inherited_rejected_form_release.v0",
        packet_id = instance.id,
        generation = instance.generation,
        measurement_status = status,
        reason_codes = reasons,
        selected = selected_value,
        effect = effect_projection(aftermath),
        controlled_post = controlled,
        actual_post = actual_value,
        pressure_relief = {
            measure = "typed_selected_obligation_discharge",
            selected_obligation_count = 1,
            discharged_obligation_count = discharged,
            unresolved_selected_obligation_count = unresolved,
            classification = classification,
        },
        aggregate_diagnostic = {
            pre_witness_count = #(aftermath.selected.pre.snapshot.payload.witnesses or {}),
            controlled_post_witness_count = #(control.snapshot.witnesses or {}),
            actual_post_witness_count = #(actual.snapshot.witnesses or {}),
            controlled_count_delta = #(control.snapshot.witnesses or {})
                - #(aftermath.selected.pre.snapshot.payload.witnesses or {}),
            authoritative_for_relief = false,
        },
        source_refs = sorted_unique(source_refs),
        calculation_status = "runtime_confirmed",
        authority = "diagnostic",
    })
end

local function verify_selected(value)
    local ok, err = exact_record(value, selected_keys, nil, "pressure-relief selected")
    if not ok then return nil, err end
    if value.pre_coordinate ~= "▽" or value.causal_class ~= "blocking_demand"
        or value.target_operator ~= "☷" then
        return nil, "pressure-relief selected constants are invalid"
    end
    for _, key in ipairs({
        "pressure_snapshot_ref",
        "route_derivation_ref",
        "route_event_ref",
        "witness_id",
        "action_plan_id",
    }) do
        local _, value_err = bounded_string(value[key], "pressure-relief selected " .. key)
        if value_err then return nil, value_err end
    end
    if not prefixed_digest(value.same_obligation_key, "pressure-obligation:") then
        return nil, "pressure-relief selected obligation key is invalid"
    end
    return true
end

local function verify_effect(value)
    local ok, err = exact_record(value, effect_keys, nil, "pressure-relief effect")
    if not ok then return nil, err end
    for _, key in ipairs({
        "destination_tick_ref",
        "release_event_ref",
        "post_effect_runtime_frame_ref",
        "release_id",
        "residue_unit_id",
    }) do
        local _, value_err = bounded_string(value[key], "pressure-relief effect " .. key)
        if value_err then return nil, value_err end
    end
    local target_ok, target_err = exact_record(
        value.target,
        target_keys,
        nil,
        "pressure-relief effect target"
    )
    if not target_ok then return nil, target_err end
    local _, id_err = bounded_string(value.target.id, "pressure-relief target id")
    if id_err then return nil, id_err end
    local before, before_err = positive_integer(
        value.target.before_version,
        "pressure-relief target before_version"
    )
    if not before then return nil, before_err end
    local after, after_err = positive_integer(
        value.target.after_version,
        "pressure-relief target after_version"
    )
    if not after then return nil, after_err end
    if after ~= before + 1 or value.target.after_activation ~= "dissolved" then
        return nil, "pressure-relief target transition is invalid"
    end
    local mass_ok, mass_err = exact_record(
        value.released_mass,
        released_mass_keys,
        nil,
        "pressure-relief released mass"
    )
    if not mass_ok then return nil, mass_err end
    if value.released_mass.forms ~= 1 or value.released_mass.relations ~= 0
        or value.irreversible_identity_loss ~= 0 then
        return nil, "pressure-relief release accounting is invalid"
    end
    return true
end

local function verify_controlled(value)
    local ok, err = exact_record(
        value,
        controlled_keys,
        nil,
        "pressure-relief controlled post"
    )
    if not ok then return nil, err end
    if value.coordinate ~= "▽"
        or value.coordinate_status ~= "same_coordinate_control" then
        return nil, "pressure-relief controlled-post coordinate is invalid"
    end
    for _, key in ipairs({"exact_selected_witness_count", "same_obligation_count"}) do
        local _, count_err = nonnegative_integer(
            value[key],
            "pressure-relief controlled post " .. key
        )
        if count_err then return nil, count_err end
    end
    if type(value.old_action_preconditions_fresh) ~= "boolean" then
        return nil, "pressure-relief old-action freshness must be boolean"
    end
    if value.old_action_readiness ~= "already_released"
        and value.old_action_readiness ~= "releasable" then
        return nil, "pressure-relief old-action readiness is invalid"
    end
    return true
end

local function verify_actual(value)
    local ok, err = exact_record(
        value,
        actual_keys,
        {expected_successor = true},
        "pressure-relief actual post"
    )
    if not ok then return nil, err end
    if value.coordinate ~= "☷" then
        return nil, "pressure-relief actual-post coordinate is invalid"
    end
    for _, key in ipairs({"pressure_snapshot_ref", "route_derivation_ref"}) do
        local _, value_err = bounded_string(value[key], "pressure-relief actual post " .. key)
        if value_err then return nil, value_err end
    end
    local successors, successors_err = strict_string_array(
        value.successor_witness_ids,
        "pressure-relief successor witness ids",
        bounds.max_successor_witnesses
    )
    if not successors then return nil, successors_err end
    local others, others_err = strict_string_array(
        value.other_successor_witness_ids,
        "pressure-relief other successor witness ids",
        bounds.max_successor_witnesses
    )
    if not others then return nil, others_err end
    local count, count_err = nonnegative_integer(
        value.successor_obligation_count,
        "pressure-relief successor obligation count"
    )
    if not count then return nil, count_err end
    if count ~= #successors then
        return nil, "pressure-relief successor count does not match ids"
    end
    local expected_id
    if value.expected_successor ~= nil then
        local expected_ok, expected_err = exact_record(
            value.expected_successor,
            expected_successor_keys,
            nil,
            "pressure-relief expected successor"
        )
        if not expected_ok then return nil, expected_err end
        expected_id = value.expected_successor.witness_id
        for _, key in ipairs({"witness_id", "action_plan_id"}) do
            local _, value_err = bounded_string(
                value.expected_successor[key],
                "pressure-relief expected successor " .. key
            )
            if value_err then return nil, value_err end
        end
        if value.expected_successor.presentation_policy
                ~= "network.rejected_form_after_release.v0"
            or type(value.expected_successor.executable) ~= "boolean" then
            return nil, "pressure-relief expected successor is invalid"
        end
    end
    local partition = {}
    if expected_id then partition[expected_id] = true end
    for _, id in ipairs(others) do
        if partition[id] then
            return nil, "pressure-relief successor partition overlaps"
        end
        partition[id] = true
    end
    for _, id in ipairs(successors) do
        if not partition[id] then
            return nil, "pressure-relief successor partition is incomplete"
        end
        partition[id] = nil
    end
    if next(partition) ~= nil then
        return nil, "pressure-relief successor partition contains foreign ids"
    end
    return true
end

expected_not_discharged = function(controlled)
    local reasons = {}
    if controlled.exact_selected_witness_count > 0 then
        reasons[#reasons + 1] = "exact_selected_witness_survived"
    end
    if controlled.same_obligation_count > 0 then
        reasons[#reasons + 1] = "same_obligation_survived"
    end
    if controlled.old_action_preconditions_fresh then
        reasons[#reasons + 1] = "old_action_preconditions_remain_fresh"
    end
    if controlled.old_action_readiness == "releasable" then
        reasons[#reasons + 1] = "old_action_readiness_remains_releasable"
    end
    table.sort(reasons)
    return reasons
end

local function verify_relief(value, measurement_status, controlled, actual, reasons)
    local optional = {
        discharged_obligation_count = measurement_status == "not_measurable",
        unresolved_selected_obligation_count = measurement_status == "not_measurable",
    }
    local ok, err = exact_record(
        value,
        relief_keys,
        optional,
        "pressure-relief accounting"
    )
    if not ok then return nil, err end
    if value.measure ~= "typed_selected_obligation_discharge"
        or value.selected_obligation_count ~= 1 then
        return nil, "pressure-relief accounting constants are invalid"
    end
    if measurement_status == "not_measurable" then
        if value.classification ~= "not_measurable"
            or value.discharged_obligation_count ~= nil
            or value.unresolved_selected_obligation_count ~= nil then
            return nil, "unmeasured relief contains measured counts"
        end
        if #reasons == 0 then
            return nil, "unmeasured relief requires a reason"
        end
        return true
    end
    if measurement_status == "not_discharged" then
        if value.classification ~= "not_discharged"
            or value.discharged_obligation_count ~= 0
            or value.unresolved_selected_obligation_count ~= 1
            or controlled == nil then
            return nil, "not-discharged relief accounting is invalid"
        end
        local expected = expected_not_discharged(controlled)
        if #expected == 0 or not same_array(expected, reasons) then
            return nil, "not-discharged reasons do not match controlled evidence"
        end
        return true
    end
    if value.discharged_obligation_count ~= 1
        or value.unresolved_selected_obligation_count ~= 0
        or #reasons ~= 0 or controlled == nil or actual == nil
        or controlled.exact_selected_witness_count ~= 0
        or controlled.same_obligation_count ~= 0
        or controlled.old_action_preconditions_fresh ~= false
        or controlled.old_action_readiness ~= "already_released" then
        return nil, "discharged relief predicate is incomplete"
    end
    local expected_class = actual.successor_obligation_count > 0
        and "discharged_with_successor_obligation"
        or "discharged_without_successor_obligation"
    if value.classification ~= expected_class then
        return nil, "discharged relief classification contradicts successors"
    end
    return true
end

local function verify_aggregate(value)
    local ok, err = exact_record(
        value,
        aggregate_keys,
        nil,
        "pressure-relief aggregate diagnostic"
    )
    if not ok then return nil, err end
    for _, key in ipairs({
        "pre_witness_count",
        "controlled_post_witness_count",
        "actual_post_witness_count",
    }) do
        local _, count_err = nonnegative_integer(
            value[key],
            "pressure-relief aggregate " .. key
        )
        if count_err then return nil, count_err end
    end
    if type(value.controlled_count_delta) ~= "number"
        or value.controlled_count_delta ~= math.floor(value.controlled_count_delta)
        or value.controlled_count_delta
            ~= value.controlled_post_witness_count - value.pre_witness_count
        or value.authoritative_for_relief ~= false then
        return nil, "pressure-relief aggregate diagnostic is invalid"
    end
    return true
end

verify_view = function(value, verify_identity)
    local plain_ok, plain_err = acyclic_plain(value, "pressure-relief view")
    if not plain_ok then return nil, plain_err end
    local top_ok, top_err = exact_record(value, view_keys, {
        effect = true,
        controlled_post = true,
        actual_post = true,
        aggregate_diagnostic = true,
    }, "pressure-relief view")
    if not top_ok then return nil, top_err end
    if value.protocol_version ~= reader.protocol_version
        or value.treatment ~= "dissolve.inherited_rejected_form_release.v0"
        or value.calculation_status ~= "runtime_confirmed"
        or value.authority ~= "diagnostic" then
        return nil, "pressure-relief view constants are invalid"
    end
    if not prefixed_digest(value.measurement_id, "pressure-relief:") then
        return nil, "pressure-relief measurement id is invalid"
    end
    local _, packet_err = bounded_string(value.packet_id, "pressure-relief packet_id")
    if packet_err then return nil, packet_err end
    local _, generation_err = positive_integer(value.generation, "pressure-relief generation")
    if generation_err then return nil, generation_err end
    if value.measurement_status ~= "not_measurable"
        and value.measurement_status ~= "not_discharged"
        and value.measurement_status ~= "discharged" then
        return nil, "pressure-relief measurement status is invalid"
    end
    local reasons, reasons_err = strict_string_array(
        value.reason_codes,
        "pressure-relief reason codes",
        bounds.max_reason_codes
    )
    if not reasons then return nil, reasons_err end
    local allowed_reasons = value.measurement_status == "not_measurable"
        and not_measurable_reasons or not_discharged_reasons
    for _, reason in ipairs(reasons) do
        if not allowed_reasons[reason] then
            return nil, "pressure-relief reason code does not match outcome"
        end
    end
    local selected_ok, selected_err = verify_selected(value.selected)
    if not selected_ok then return nil, selected_err end
    if value.effect ~= nil then
        local effect_ok, effect_err = verify_effect(value.effect)
        if not effect_ok then return nil, effect_err end
    end
    if value.controlled_post ~= nil then
        local controlled_ok, controlled_err = verify_controlled(value.controlled_post)
        if not controlled_ok then return nil, controlled_err end
    end
    if value.actual_post ~= nil then
        local actual_ok, actual_err = verify_actual(value.actual_post)
        if not actual_ok then return nil, actual_err end
    end
    if value.measurement_status ~= "not_measurable"
        and (value.effect == nil or value.controlled_post == nil or value.actual_post == nil) then
        return nil, "measured relief requires effect and both post views"
    end
    local relief_ok, relief_err = verify_relief(
        value.pressure_relief,
        value.measurement_status,
        value.controlled_post,
        value.actual_post,
        reasons
    )
    if not relief_ok then return nil, relief_err end
    if value.aggregate_diagnostic ~= nil then
        local aggregate_ok, aggregate_err = verify_aggregate(value.aggregate_diagnostic)
        if not aggregate_ok then return nil, aggregate_err end
    end
    local source_refs, source_err = strict_string_array(
        value.source_refs,
        "pressure-relief source refs",
        bounds.max_source_refs
    )
    if not source_refs then return nil, source_err end
    if #source_refs == 0 then
        return nil, "pressure-relief source refs must not be empty"
    end
    if verify_identity ~= false then
        local seed = copy_value(value)
        seed.measurement_id = nil
        local identity, identity_err = digest.record(seed)
        if not identity then return nil, identity_err end
        if value.measurement_id ~= "pressure-relief:" .. identity then
            return nil, "pressure-relief measurement identity mismatch"
        end
    end
    return true
end

function reader.verify(value)
    return verify_view(value, true)
end

function reader.measure(instance, request, trusted_context)
    local normalized, request_err = normalize_request(instance, request)
    if not normalized then
        return nil, request_err
    end
    local context, context_err = normalize_trusted_context(trusted_context)
    if not context then
        return nil, context_err
    end
    local selected, selected_err = resolve_selected_obligation(instance, normalized)
    if not selected then
        return nil, selected_err
    end
    local aftermath, aftermath_err = resolve_effect_aftermath(
        instance,
        selected,
        context
    )
    if not aftermath then
        return nil, aftermath_err
    end
    if aftermath.not_measurable_reason ~= nil then
        local view, view_err = not_measurable_view(
            instance,
            selected,
            aftermath.not_measurable_reason,
            aftermath.source_refs
        )
        if not view then
            return nil, make_error(
                "reader_failure",
                "view",
                view_err,
                aftermath.source_refs
            )
        end
        return view
    end
    local control, control_err = resolve_same_coordinate_control(
        instance,
        aftermath
    )
    if not control then
        return nil, control_err
    end
    local actual, actual_err = resolve_actual_successor(instance, aftermath)
    if not actual then
        return nil, actual_err
    end
    if actual.not_measurable_reason ~= nil then
        local refs = copy_value(aftermath.source_refs)
        for _, ref in ipairs(actual.source_refs or {}) do
            refs[#refs + 1] = ref
        end
        local view, view_err = not_measurable_view(
            instance,
            selected,
            actual.not_measurable_reason,
            refs,
            aftermath,
            control
        )
        if not view then
            return nil, make_error("reader_failure", "view", view_err, refs)
        end
        return view
    end
    local view, view_err = measured_view(instance, aftermath, control, actual)
    if not view then
        return nil, make_error(
            "reader_failure",
            "view",
            view_err,
            aftermath.source_refs
        )
    end
    return view
end

return reader
