local authority_epoch = require("runtime.authority_epoch")
local digest = require("core.digest")
local edge_catalog = require("runtime.edge_catalog")
local json = require("core.json")
local topology = require("core.topology")

local credit = {
    protocol_version = "edge-credit.v0",
    route_protocol_version = "route-evidence.v0",
    error_protocol_version = "authority-instrument-error.v0",
}

-- Live credit states are runner-owned until closure. The weak registry grants
-- an append-only fast path without weakening the strict public transactions.
local runtime_states = setmetatable({}, {__mode = "k"})

local eligibility_reasons = {
    non_tree_authority = true,
    harness_override = true,
    authority_tainted = true,
    binary_policy_control = true,
    candidate_unqualified = true,
    fixture_witness = true,
    consumer_ablation_active = true,
    control_fallback = true,
    tie_only_selection = true,
    missing_action_contract = true,
    unresolved_source_ref = true,
    epoch_mismatch = true,
    route_identity_mismatch = true,
    instrumentation_error = true,
}

local classification_errors = {
    eligibility_chain_missing = true,
    eligibility_chain_mismatch = true,
    authority_basis_missing = true,
    authority_epoch_invalid = true,
}

local route_authorities = {
    legacy_control = true,
    tree = true,
    harness_override = true,
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

local function replace_contents(target, source)
    for key in pairs(target) do
        target[key] = nil
    end
    for key, value in pairs(source) do
        target[key] = copy_value(value)
    end
end

local function same_value(left, right)
    local left_ok, left_encoded = pcall(json.encode, left)
    local right_ok, right_encoded = pcall(json.encode, right)
    return left_ok and right_ok and left_encoded == right_encoded
end

local function exact_keys(value, allowed, optional)
    if type(value) ~= "table" then
        return false
    end
    optional = optional or {}
    for key in pairs(value) do
        if not allowed[key] then
            return false
        end
    end
    for key in pairs(allowed) do
        if value[key] == nil and not optional[key] then
            return false
        end
    end
    return true
end

local function non_empty(value)
    return type(value) == "string" and value ~= ""
end

local function positive_integer(value)
    return type(value) == "number"
        and value > 0
        and value < math.huge
        and value % 1 == 0
end

local function tagged_hash(value)
    return type(value) == "string"
        and #value == 71
        and value:sub(1, 7) == "sha256:"
        and value:sub(8):match("^[0-9a-f]+$") ~= nil
end

local function instrument_error(code, extra)
    local result = {
        class = "instrument_contract",
        code = code,
        stage = "edge_credit",
    }
    for key, value in pairs(extra or {}) do
        result[key] = copy_value(value)
    end
    return result
end

local function invalid(path)
    return instrument_error("edge_credit_invalid", {path = path})
end

local function tagged_digest(seed)
    local value, err = digest.record(seed)
    if not value then
        return nil, instrument_error("edge_credit_digest_failure", {
            detail = err,
        })
    end
    return "sha256:" .. value
end

local function optional_identity(value)
    if value == nil then
        return "none"
    end
    return value
end

local function strict_sorted_unique(values, vocabulary)
    if type(values) ~= "table" then
        return nil
    end
    local seen = {}
    local result = {}
    for index, value in ipairs(values) do
        if type(value) ~= "string" or value == "" or seen[value]
            or (vocabulary and not vocabulary[value]) then
            return nil
        end
        seen[value] = true
        result[index] = value
    end
    for key in pairs(values) do
        if type(key) ~= "number" or key < 1 or key > #values or key % 1 ~= 0 then
            return nil
        end
    end
    local sorted = copy_value(result)
    table.sort(sorted)
    if not same_value(result, sorted) then
        return nil
    end
    return result
end

local function normalized_set(values, vocabulary)
    local seen = {}
    local result = {}
    for _, value in ipairs(values or {}) do
        if type(value) ~= "string" or value == ""
            or (vocabulary and not vocabulary[value]) then
            return nil
        end
        if not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function append_unique(values, value)
    if not value then
        return
    end
    for _, existing in ipairs(values) do
        if existing == value then
            return
        end
    end
    values[#values + 1] = value
    table.sort(values)
end

local function has_value(values, expected)
    for _, value in ipairs(values or {}) do
        if value == expected then
            return true
        end
    end
    return false
end

local function route_definition(from, to)
    from = topology.resolve(from)
    to = topology.resolve(to)
    if not from or not to then
        return nil
    end
    local definition = edge_catalog.get(from, to)
    if not definition then
        return nil
    end
    local direction = from .. "->" .. to
    if not has_value(definition.directions, direction) then
        return nil
    end
    return definition, from, to
end

local function normalize_body_eligibility(value)
    if type(value) ~= "table" or type(value.promotion_eligible) ~= "boolean" then
        return nil, "missing"
    end
    local reasons = strict_sorted_unique(
        value.promotion_ineligibility_reasons,
        eligibility_reasons
    )
    local basis = value.promotion_eligibility_basis
    if not reasons or not exact_keys(basis, {
        witness_ids = true,
        unqualified_snapshot = true,
        fixture_witness_ids = true,
    }) or type(basis.unqualified_snapshot) ~= "boolean" then
        return nil, "malformed"
    end
    local witness_ids = strict_sorted_unique(basis.witness_ids)
    local fixture_witness_ids = strict_sorted_unique(basis.fixture_witness_ids)
    if not witness_ids or not fixture_witness_ids then
        return nil, "malformed"
    end
    for _, fixture_id in ipairs(fixture_witness_ids) do
        if not has_value(witness_ids, fixture_id) then
            return nil, "malformed"
        end
    end
    if value.promotion_eligible then
        if #reasons ~= 0 or basis.unqualified_snapshot
            or #fixture_witness_ids ~= 0 then
            return nil, "malformed"
        end
    elseif #reasons == 0 then
        return nil, "malformed"
    end
    if basis.unqualified_snapshot
        and not has_value(reasons, "candidate_unqualified") then
        return nil, "malformed"
    end
    if #fixture_witness_ids > 0 and not has_value(reasons, "fixture_witness") then
        return nil, "malformed"
    end
    return {
        promotion_eligible = value.promotion_eligible,
        promotion_ineligibility_reasons = reasons,
        promotion_eligibility_basis = {
            witness_ids = witness_ids,
            unqualified_snapshot = basis.unqualified_snapshot,
            fixture_witness_ids = fixture_witness_ids,
        },
    }
end

local function eligibility_basis_refs(body, pressure_snapshot_ref)
    local refs = {}
    for _, value in ipairs(body.promotion_eligibility_basis.witness_ids) do
        refs[#refs + 1] = value
    end
    for _, value in ipairs(body.promotion_eligibility_basis.fixture_witness_ids) do
        refs[#refs + 1] = value
    end
    if body.promotion_eligibility_basis.unqualified_snapshot
        and non_empty(pressure_snapshot_ref) then
        refs[#refs + 1] = pressure_snapshot_ref
    end
    return normalized_set(refs)
end

local function body_eligibility_chain(decision, derivation_event, from, to)
    local decision_value, decision_status = normalize_body_eligibility(decision)
    local selected_value, selected_status = normalize_body_eligibility(
        decision and decision.selected_candidate
    )
    if decision_status == "missing" or selected_status == "missing" then
        return nil, "eligibility_chain_missing"
    end
    if not decision_value or not selected_value then
        return nil, "eligibility_chain_mismatch"
    end

    if type(derivation_event) ~= "table"
        or derivation_event.type ~= "route_derivation"
        or derivation_event.truth_status ~= "runtime_confirmed"
        or not non_empty(derivation_event.id)
        or derivation_event.id ~= decision.derivation_ref
    then
        return nil, "authority_basis_missing"
    end
    local payload = derivation_event.payload
    if type(payload) ~= "table"
        or topology.resolve(payload.current_operator) ~= from
        or topology.resolve(payload.selected_to) ~= to
        or payload.outcome ~= "selected"
        or payload.pressure_snapshot_ref ~= decision.pressure_snapshot_ref
        or payload.selected_action_plan_id ~= decision.selected_action_plan_id
    then
        return nil, "eligibility_chain_mismatch"
    end
    local derivation_value, derivation_status = normalize_body_eligibility(payload)
    local recorded_value, recorded_status = normalize_body_eligibility(
        payload.selected_candidate
    )
    if derivation_status == "missing" or recorded_status == "missing" then
        return nil, "eligibility_chain_missing"
    end
    if not derivation_value or not recorded_value
        or not same_value(decision_value, selected_value)
        or not same_value(decision_value, derivation_value)
        or not same_value(decision_value, recorded_value)
    then
        return nil, "eligibility_chain_mismatch"
    end
    return decision_value
end

local function request_seed(record)
    return {
        kind = record.kind,
        protocol_version = record.protocol_version,
        sequence = record.sequence,
        life_id = record.life_id,
        packet_id = record.packet_id,
        route_ordinal = record.route_ordinal,
        from = record.from,
        to = record.to,
        route_authority = record.route_authority,
        reason = record.reason,
        event_truth_status = record.event_truth_status,
    }
end

local function eligibility_seed(record)
    return {
        kind = record.kind,
        protocol_version = record.protocol_version,
        route_evidence_id = record.route_evidence_id,
        physics_epoch_id = optional_identity(record.physics_epoch_id),
        evidence_epoch_id = optional_identity(record.evidence_epoch_id),
        status = record.status,
        reasons = copy_value(record.reasons),
        basis_refs = copy_value(record.basis_refs),
        policy_rule_ref = record.policy_rule_ref,
        policy_rule_status = record.policy_rule_status,
        evaluation_truth_status = record.evaluation_truth_status,
    }
end

local function route_evidence_seed(record)
    return {
        protocol_version = credit.route_protocol_version,
        evidence_epoch_id = optional_identity(record.evidence_epoch_id),
        life_id = record.life_id,
        packet_id = record.packet_id,
        lineage_id = record.lineage_id,
        generation = record.generation,
        route_ordinal = record.route_ordinal,
        from = record.from,
        to = record.to,
        route_authority = record.route_authority,
        authority_basis_ref = record.authority_basis_ref,
        derivation_ref = optional_identity(record.derivation_ref),
        pressure_snapshot_ref = optional_identity(record.pressure_snapshot_ref),
        selected_action_plan_id = optional_identity(record.selected_action_plan_id),
    }
end

local function selection_seed(record)
    return {
        kind = record.kind,
        protocol_version = record.protocol_version,
        route_evidence_id = record.route_evidence_id,
        sequence = record.sequence,
        route_ordinal = record.route_ordinal,
        evidence_epoch_id = optional_identity(record.evidence_epoch_id),
        physics_epoch_id = optional_identity(record.physics_epoch_id),
        life_id = record.life_id,
        packet_id = record.packet_id,
        lineage_id = record.lineage_id,
        generation = record.generation,
        from = record.from,
        to = record.to,
        edge_id = record.edge_id,
        route_authority = record.route_authority,
        authority_basis_ref = record.authority_basis_ref,
        derivation_ref = optional_identity(record.derivation_ref),
        pressure_snapshot_ref = optional_identity(record.pressure_snapshot_ref),
        selected_action_plan_id = optional_identity(record.selected_action_plan_id),
        classification_status = record.classification_status,
        classification_error_codes = copy_value(record.classification_error_codes),
        eligibility_ref = record.eligibility
            and record.eligibility.eligibility_ref or "none",
        event_truth_status = record.event_truth_status,
    }
end

local function commit_seed(record)
    return {
        kind = record.kind,
        protocol_version = record.protocol_version,
        route_evidence_id = record.route_evidence_id,
        selection_ref = record.selection_ref,
        route_trace_ref = record.route_trace_ref,
        from = record.from,
        to = record.to,
        route_authority = record.route_authority,
        event_truth_status = record.event_truth_status,
    }
end

local function taint_seed(record)
    return {
        kind = record.kind,
        protocol_version = record.protocol_version,
        route_evidence_id = record.route_evidence_id,
        commit_ref = record.commit_ref,
        sequence = record.sequence,
        configured_owner = record.configured_owner,
        observed_owner = record.observed_owner,
        cause = record.cause,
        event_truth_status = record.event_truth_status,
    }
end

local function arrival_seed(record)
    return {
        kind = record.kind,
        protocol_version = record.protocol_version,
        route_evidence_id = record.route_evidence_id,
        commit_ref = record.commit_ref,
        destination_tick_ref = record.destination_tick_ref,
        effect_refs = copy_value(record.effect_refs),
        payload_kind = record.payload_kind,
        event_truth_status = record.event_truth_status,
    }
end

local function decision_seed(record)
    return {
        kind = record.kind,
        protocol_version = record.protocol_version,
        route_evidence_id = record.route_evidence_id,
        selection_eligibility_ref = record.selection_eligibility_ref,
        commit_ref = record.commit_ref,
        arrival_ref = record.arrival_ref,
        status = record.status,
        reasons = copy_value(record.reasons),
        basis_refs = copy_value(record.basis_refs),
        event_truth_status = record.event_truth_status,
    }
end

local function failure_seed(record)
    return {
        kind = record.kind,
        protocol_version = record.protocol_version,
        route_evidence_id = record.route_evidence_id,
        commit_ref = record.commit_ref,
        destination_tick_ref = record.destination_tick_ref,
        failure_ref = record.failure_ref,
        failure_kind = record.failure_kind,
        event_truth_status = record.event_truth_status,
    }
end

local function pending_seed(record)
    return {
        kind = record.kind,
        protocol_version = record.protocol_version,
        route_evidence_id = record.route_evidence_id,
        commit_ref = record.commit_ref,
        stop_reason = record.stop_reason,
        event_truth_status = record.event_truth_status,
    }
end

local function error_seed(record)
    return {
        kind = record.kind,
        protocol_version = record.protocol_version,
        class = record.class,
        code = record.code,
        stage = record.stage,
        route_evidence_id = optional_identity(record.route_evidence_id),
        source_refs = copy_value(record.source_refs),
        event_truth_status = record.event_truth_status,
    }
end

local function append_record(state, record)
    state.events[#state.events + 1] = copy_value(record)
    state.next_sequence = #state.events + 1
end

local function request_record(state, decision, ordinal, from, to)
    local record = {
        kind = "route_evidence_request",
        protocol_version = credit.route_protocol_version,
        sequence = state.next_sequence,
        life_id = state.identity.life_id,
        packet_id = state.identity.packet_id,
        route_ordinal = ordinal,
        from = from,
        to = to,
        route_authority = decision.authority,
        reason = non_empty(decision.reason) and decision.reason
            or "unspecified_route_request",
        event_truth_status = "runtime_confirmed",
    }
    local id, err = tagged_digest(request_seed(record))
    if not id then
        return nil, err
    end
    record.record_id = id
    return record
end

local function qualified_tree_policy(epoch_record)
    if not epoch_record or epoch_record.physics.movement_owner ~= "tree" then
        return false
    end
    local policy = epoch_record.physics.live_policy
    return type(policy) == "table"
        and policy.kind == "tree_policy_descriptor"
        and type(policy.pressure) == "table"
        and policy.pressure.pressure_policy == "qualified_need_v0"
        and policy.pressure.witness_protocol == "pressure.witness.v1"
        and policy.pressure.action_protocol == "pressure.action_plan.v0"
end

local function any_consumer_ablation(epoch_record)
    local policy = epoch_record and epoch_record.physics.live_policy
    local vector = policy and policy.pressure and policy.pressure.ablation_vector
    if type(vector) ~= "table" then
        return false
    end
    for _, value in pairs(vector) do
        if value == true then
            return true
        end
    end
    return false
end

local function first_taint(state)
    for _, event in ipairs(state.events or {}) do
        if event.kind == "authority_taint" then
            return event
        end
    end
    return nil
end

local function evaluated_reasons(state, authority, body, selected_action_plan_id)
    local reasons = copy_value(body.promotion_ineligibility_reasons)
    local epoch_record = state.authority_epoch
    local configured_owner = epoch_record
        and epoch_record.configured.configured_movement_owner or nil

    if authority ~= "tree" then
        append_unique(reasons, "non_tree_authority")
        if authority == "harness_override" then
            append_unique(reasons, "harness_override")
        end
    elseif configured_owner ~= "tree" then
        append_unique(reasons, "epoch_mismatch")
    end

    if first_taint(state) then
        append_unique(reasons, "authority_tainted")
    end

    if authority == "tree" then
        if not qualified_tree_policy(epoch_record) then
            append_unique(reasons, "binary_policy_control")
        else
            if any_consumer_ablation(epoch_record) then
                append_unique(reasons, "consumer_ablation_active")
            end
            if not non_empty(selected_action_plan_id) then
                append_unique(reasons, "missing_action_contract")
            end
        end
    end
    return reasons
end

local function make_eligibility(state, route_evidence_id, authority, body,
    selected_action_plan_id, authority_basis_ref, pressure_snapshot_ref)
    local reasons = evaluated_reasons(
        state,
        authority,
        body,
        selected_action_plan_id
    )
    local basis_refs
    if authority == "tree" then
        basis_refs = eligibility_basis_refs(body, pressure_snapshot_ref)
    else
        basis_refs = {authority_basis_ref}
    end
    local epoch_record = state.authority_epoch
    local record = {
        kind = "edge_credit_selection_eligibility",
        protocol_version = credit.protocol_version,
        route_evidence_id = route_evidence_id,
        physics_epoch_id = epoch_record and epoch_record.physics_epoch_id or nil,
        evidence_epoch_id = epoch_record and epoch_record.evidence_epoch_id or nil,
        status = #reasons == 0 and "eligible" or "ineligible",
        reasons = reasons,
        basis_refs = normalized_set(basis_refs),
        policy_rule_ref = "edge-credit.policy.v0",
        policy_rule_status = "document_decision",
        evaluation_truth_status = "runtime_confirmed",
    }
    local id, err = tagged_digest(eligibility_seed(record))
    if not id then
        return nil, err
    end
    record.eligibility_ref = id
    return record
end

local function make_instrument_error(code, route_evidence_id, refs)
    local record = {
        kind = "authority_instrument_error",
        protocol_version = credit.error_protocol_version,
        class = "identity",
        code = code,
        stage = "edge_credit.prepare",
        route_evidence_id = route_evidence_id,
        source_refs = normalized_set(refs or {}),
        message = "edge-credit selection is unclassified: " .. code,
        event_truth_status = "runtime_confirmed",
    }
    local id, err = tagged_digest(error_seed(record))
    if not id then
        return nil, err
    end
    record.error_id = id
    return record
end

local function validate_identity(identity)
    return exact_keys(identity, {
        life_id = true,
        packet_id = true,
        lineage_id = true,
        generation = true,
    }) and non_empty(identity.life_id)
        and non_empty(identity.packet_id)
        and non_empty(identity.lineage_id)
        and positive_integer(identity.generation)
end

local function verify_id(actual, seed)
    if not tagged_hash(actual) then
        return false
    end
    local expected = tagged_digest(seed)
    return expected ~= nil and actual == expected
end

local function event_identity(record)
    if record.kind == "edge_credit_selection_eligibility" then
        return record.eligibility_ref
    elseif record.kind == "edge_credit_decision" then
        return record.credit_decision_ref
    elseif record.kind == "authority_instrument_error" then
        return record.error_id
    end
    return record.record_id
end

local function verify_request(record, state, index)
    if not exact_keys(record, {
        kind = true, protocol_version = true, record_id = true,
        sequence = true, life_id = true, packet_id = true,
        route_ordinal = true, from = true, to = true,
        route_authority = true, reason = true, event_truth_status = true,
    }) or record.kind ~= "route_evidence_request"
        or record.protocol_version ~= credit.route_protocol_version
        or record.sequence ~= index
        or record.life_id ~= state.identity.life_id
        or record.packet_id ~= state.identity.packet_id
        or not positive_integer(record.route_ordinal)
        or (record.route_authority ~= "legacy_control"
            and record.route_authority ~= "harness_override")
        or not non_empty(record.reason)
        or record.event_truth_status ~= "runtime_confirmed"
        or not route_definition(record.from, record.to)
        or not verify_id(record.record_id, request_seed(record)) then
        return nil, invalid("events.request")
    end
    return true
end

local function verify_eligibility(record)
    if not exact_keys(record, {
        kind = true, protocol_version = true, eligibility_ref = true,
        route_evidence_id = true, physics_epoch_id = true,
        evidence_epoch_id = true, status = true, reasons = true,
        basis_refs = true, policy_rule_ref = true, policy_rule_status = true,
        evaluation_truth_status = true,
    }, {
        physics_epoch_id = true,
        evidence_epoch_id = true,
    }) or record.kind ~= "edge_credit_selection_eligibility"
        or record.protocol_version ~= credit.protocol_version
        or not tagged_hash(record.route_evidence_id)
        or (record.status ~= "eligible" and record.status ~= "ineligible")
        or not strict_sorted_unique(record.reasons, eligibility_reasons)
        or not strict_sorted_unique(record.basis_refs)
        or record.policy_rule_ref ~= "edge-credit.policy.v0"
        or record.policy_rule_status ~= "document_decision"
        or record.evaluation_truth_status ~= "runtime_confirmed"
        or (record.status == "eligible" and #record.reasons ~= 0)
        or (record.status == "ineligible" and #record.reasons == 0)
        or not verify_id(record.eligibility_ref, eligibility_seed(record)) then
        return nil, invalid("events.eligibility")
    end
    if record.physics_epoch_id ~= nil and not tagged_hash(record.physics_epoch_id) then
        return nil, invalid("events.eligibility.physics_epoch_id")
    end
    if record.evidence_epoch_id ~= nil and not tagged_hash(record.evidence_epoch_id) then
        return nil, invalid("events.eligibility.evidence_epoch_id")
    end
    return true
end

local function verify_selection(record, state, index)
    local allowed = {
        kind = true, protocol_version = true, record_id = true,
        route_evidence_id = true, sequence = true, route_ordinal = true,
        evidence_epoch_id = true, physics_epoch_id = true,
        life_id = true, packet_id = true, lineage_id = true, generation = true,
        from = true, to = true, edge_id = true, route_authority = true,
        authority_basis_ref = true, derivation_ref = true,
        pressure_snapshot_ref = true, selected_action_plan_id = true,
        classification_status = true, classification_error_codes = true,
        eligibility = true, event_truth_status = true,
    }
    local optional = {
        evidence_epoch_id = true, physics_epoch_id = true,
        derivation_ref = true, pressure_snapshot_ref = true,
        selected_action_plan_id = true, eligibility = true,
    }
    local definition, from, to = route_definition(record.from, record.to)
    local errors = strict_sorted_unique(
        record.classification_error_codes,
        classification_errors
    )
    if not exact_keys(record, allowed, optional)
        or record.kind ~= "route_evidence_selection"
        or record.protocol_version ~= credit.route_protocol_version
        or record.sequence ~= index
        or not positive_integer(record.route_ordinal)
        or record.life_id ~= state.identity.life_id
        or record.packet_id ~= state.identity.packet_id
        or record.lineage_id ~= state.identity.lineage_id
        or record.generation ~= state.identity.generation
        or not definition or record.from ~= from or record.to ~= to
        or record.edge_id ~= definition.id
        or not route_authorities[record.route_authority]
        or not non_empty(record.authority_basis_ref)
        or not errors
        or record.event_truth_status ~= "runtime_confirmed"
        or not tagged_hash(record.route_evidence_id)
    then
        return nil, invalid("events.selection")
    end
    if record.classification_status == "classified" then
        if #errors ~= 0 or not record.eligibility then
            return nil, invalid("events.selection.classification")
        end
        local eligibility_ok = verify_eligibility(record.eligibility)
        if not eligibility_ok then
            return nil, invalid("events.selection.eligibility")
        end
    elseif record.classification_status == "unclassified" then
        if #errors == 0 or record.eligibility ~= nil then
            return nil, invalid("events.selection.classification")
        end
    else
        return nil, invalid("events.selection.classification_status")
    end
    if state.authority_epoch then
        if record.physics_epoch_id ~= state.authority_epoch.physics_epoch_id
            or record.evidence_epoch_id ~= state.authority_epoch.evidence_epoch_id then
            return nil, invalid("events.selection.epoch")
        end
    elseif record.physics_epoch_id ~= nil or record.evidence_epoch_id ~= nil then
        return nil, invalid("events.selection.epoch")
    end
    if record.route_authority == "tree" then
        if not non_empty(record.derivation_ref)
            or record.authority_basis_ref ~= record.derivation_ref
            or not non_empty(record.pressure_snapshot_ref) then
            return nil, invalid("events.selection.authority_basis")
        end
    elseif record.derivation_ref ~= nil or record.pressure_snapshot_ref ~= nil
        or record.selected_action_plan_id ~= nil then
        return nil, invalid("events.selection.non_tree_refs")
    end
    local expected_route_id = tagged_digest(route_evidence_seed(record))
    if record.route_evidence_id ~= expected_route_id
        or not verify_id(record.record_id, selection_seed(record)) then
        return nil, invalid("events.selection.identity")
    end
    return true
end

local function verify_commit(record)
    if not exact_keys(record, {
        kind = true, protocol_version = true, record_id = true,
        route_evidence_id = true, selection_ref = true,
        route_trace_ref = true, from = true, to = true,
        route_authority = true, event_truth_status = true,
    }) or record.kind ~= "route_evidence_commit"
        or record.protocol_version ~= credit.route_protocol_version
        or not tagged_hash(record.route_evidence_id)
        or not tagged_hash(record.selection_ref)
        or not non_empty(record.route_trace_ref)
        or not route_authorities[record.route_authority]
        or record.event_truth_status ~= "runtime_confirmed"
        or not route_definition(record.from, record.to)
        or not verify_id(record.record_id, commit_seed(record)) then
        return nil, invalid("events.commit")
    end
    return true
end

local function verify_taint(record, index)
    if not exact_keys(record, {
        kind = true, protocol_version = true, record_id = true,
        route_evidence_id = true, commit_ref = true, sequence = true,
        configured_owner = true, observed_owner = true, cause = true,
        event_truth_status = true,
    }) or record.kind ~= "authority_taint"
        or record.protocol_version ~= credit.protocol_version
        or record.sequence ~= index
        or not tagged_hash(record.route_evidence_id)
        or not tagged_hash(record.commit_ref)
        or not route_authorities[record.configured_owner]
        or not route_authorities[record.observed_owner]
        or record.configured_owner == record.observed_owner
        or record.cause ~= "authority_owner_mismatch"
        or record.event_truth_status ~= "runtime_confirmed"
        or not verify_id(record.record_id, taint_seed(record)) then
        return nil, invalid("events.authority_taint")
    end
    return true
end

local function verify_arrival(record)
    if not exact_keys(record, {
        kind = true, protocol_version = true, record_id = true,
        route_evidence_id = true, commit_ref = true,
        destination_tick_ref = true, effect_refs = true,
        payload_kind = true, event_truth_status = true,
    }) or record.kind ~= "route_evidence_arrival"
        or record.protocol_version ~= credit.route_protocol_version
        or not tagged_hash(record.route_evidence_id)
        or not tagged_hash(record.commit_ref)
        or not non_empty(record.destination_tick_ref)
        or not strict_sorted_unique(record.effect_refs)
        or not non_empty(record.payload_kind)
        or record.event_truth_status ~= "runtime_confirmed"
        or not verify_id(record.record_id, arrival_seed(record)) then
        return nil, invalid("events.arrival")
    end
    return true
end

local function verify_decision(record)
    if not exact_keys(record, {
        kind = true, protocol_version = true, credit_decision_ref = true,
        route_evidence_id = true, selection_eligibility_ref = true,
        commit_ref = true, arrival_ref = true, status = true,
        reasons = true, basis_refs = true, event_truth_status = true,
    }) or record.kind ~= "edge_credit_decision"
        or record.protocol_version ~= credit.protocol_version
        or not tagged_hash(record.route_evidence_id)
        or not tagged_hash(record.selection_eligibility_ref)
        or not tagged_hash(record.commit_ref)
        or not tagged_hash(record.arrival_ref)
        or (record.status ~= "credited" and record.status ~= "rejected")
        or not strict_sorted_unique(record.reasons, eligibility_reasons)
        or not strict_sorted_unique(record.basis_refs)
        or (record.status == "credited" and #record.reasons ~= 0)
        or (record.status == "rejected" and #record.reasons == 0)
        or record.event_truth_status ~= "runtime_confirmed"
        or not verify_id(record.credit_decision_ref, decision_seed(record)) then
        return nil, invalid("events.credit_decision")
    end
    return true
end

local function verify_failure(record)
    if not exact_keys(record, {
        kind = true, protocol_version = true, record_id = true,
        route_evidence_id = true, commit_ref = true,
        destination_tick_ref = true, failure_ref = true,
        failure_kind = true, event_truth_status = true,
    }) or record.kind ~= "route_evidence_failure"
        or record.protocol_version ~= credit.route_protocol_version
        or not tagged_hash(record.route_evidence_id)
        or not tagged_hash(record.commit_ref)
        or not non_empty(record.destination_tick_ref)
        or not non_empty(record.failure_ref)
        or not non_empty(record.failure_kind)
        or record.event_truth_status ~= "runtime_confirmed"
        or not verify_id(record.record_id, failure_seed(record)) then
        return nil, invalid("events.failure")
    end
    return true
end

local function verify_pending(record)
    if not exact_keys(record, {
        kind = true, protocol_version = true, record_id = true,
        route_evidence_id = true, commit_ref = true,
        stop_reason = true, event_truth_status = true,
    }) or record.kind ~= "route_evidence_pending"
        or record.protocol_version ~= credit.route_protocol_version
        or not tagged_hash(record.route_evidence_id)
        or not tagged_hash(record.commit_ref)
        or record.stop_reason ~= "tick_limit"
        or record.event_truth_status ~= "runtime_confirmed"
        or not verify_id(record.record_id, pending_seed(record)) then
        return nil, invalid("events.pending")
    end
    return true
end

local function verify_instrument_error(record)
    if not exact_keys(record, {
        kind = true, protocol_version = true, error_id = true,
        class = true, code = true, stage = true,
        route_evidence_id = true, source_refs = true,
        message = true, event_truth_status = true,
    }, {
        route_evidence_id = true,
    }) or record.kind ~= "authority_instrument_error"
        or record.protocol_version ~= credit.error_protocol_version
        or record.class ~= "identity"
        or not classification_errors[record.code]
        or record.stage ~= "edge_credit.prepare"
        or not strict_sorted_unique(record.source_refs)
        or not non_empty(record.message)
        or record.event_truth_status ~= "runtime_confirmed"
        or (record.route_evidence_id ~= nil
            and not tagged_hash(record.route_evidence_id))
        or not verify_id(record.error_id, error_seed(record)) then
        return nil, invalid("events.instrument_error")
    end
    return true
end

-- Durable evidence consumers receive detached records, not the mutable credit
-- state. This verifier keeps record identity owned by the module that minted
-- it, so a later ledger never has to duplicate the hashing contract.
function credit.verify_record(record)
    if type(record) ~= "table" or not non_empty(record.kind) then
        return nil, invalid("record")
    end
    if record.kind == "route_evidence_request" then
        return verify_request(record, {
            identity = {
                life_id = record.life_id,
                packet_id = record.packet_id,
            },
        }, record.sequence)
    elseif record.kind == "route_evidence_selection" then
        local state = {
            identity = {
                life_id = record.life_id,
                packet_id = record.packet_id,
                lineage_id = record.lineage_id,
                generation = record.generation,
            },
            authority_epoch = nil,
        }
        if record.physics_epoch_id ~= nil or record.evidence_epoch_id ~= nil then
            state.authority_epoch = {
                physics_epoch_id = record.physics_epoch_id,
                evidence_epoch_id = record.evidence_epoch_id,
            }
        end
        return verify_selection(record, state, record.sequence)
    elseif record.kind == "edge_credit_selection_eligibility" then
        return verify_eligibility(record)
    elseif record.kind == "route_evidence_commit" then
        return verify_commit(record)
    elseif record.kind == "authority_taint" then
        return verify_taint(record, record.sequence)
    elseif record.kind == "route_evidence_arrival" then
        return verify_arrival(record)
    elseif record.kind == "edge_credit_decision" then
        return verify_decision(record)
    elseif record.kind == "route_evidence_failure" then
        return verify_failure(record)
    elseif record.kind == "route_evidence_pending" then
        return verify_pending(record)
    elseif record.kind == "authority_instrument_error" then
        return verify_instrument_error(record)
    end
    return nil, invalid("record.kind")
end

function credit.is_eligibility_reason(reason)
    return eligibility_reasons[reason] == true
end

function credit.eligibility_reason_ids()
    local result = {}
    for reason in pairs(eligibility_reasons) do
        result[#result + 1] = reason
    end
    table.sort(result)
    return result
end

function credit.verify(state)
    if not exact_keys(state, {
        kind = true,
        protocol_version = true,
        authority_epoch = true,
        identity = true,
        events = true,
        next_sequence = true,
    }, {
        authority_epoch = true,
    }) or state.kind ~= "edge_credit_state"
        or state.protocol_version ~= credit.protocol_version
        or not validate_identity(state.identity)
        or type(state.events) ~= "table"
        or state.next_sequence ~= #state.events + 1 then
        return nil, invalid("state")
    end
    for key in pairs(state.events) do
        if type(key) ~= "number" or key < 1 or key > #state.events or key % 1 ~= 0 then
            return nil, invalid("state.events")
        end
    end
    if state.authority_epoch then
        local epoch_ok, epoch_err = authority_epoch.verify(state.authority_epoch)
        if not epoch_ok then
            return nil, epoch_err
        end
    end

    local records = {}
    local record_indices = {}
    local requests = {}
    local selections = {}
    local selections_by_ref = {}
    local eligibility = {}
    local commits = {}
    local commits_by_ref = {}
    local arrivals = {}
    local terminals = {}
    local decisions = {}
    local errors = {}
    local taints = {}
    local ordinals = {}

    for index, event in ipairs(state.events) do
        local ok, err
        if event.kind == "route_evidence_request" then
            ok, err = verify_request(event, state, index)
        elseif event.kind == "route_evidence_selection" then
            ok, err = verify_selection(event, state, index)
        elseif event.kind == "edge_credit_selection_eligibility" then
            ok, err = verify_eligibility(event)
        elseif event.kind == "route_evidence_commit" then
            ok, err = verify_commit(event)
        elseif event.kind == "authority_taint" then
            ok, err = verify_taint(event, index)
        elseif event.kind == "route_evidence_arrival" then
            ok, err = verify_arrival(event)
        elseif event.kind == "edge_credit_decision" then
            ok, err = verify_decision(event)
        elseif event.kind == "route_evidence_failure" then
            ok, err = verify_failure(event)
        elseif event.kind == "route_evidence_pending" then
            ok, err = verify_pending(event)
        elseif event.kind == "authority_instrument_error" then
            ok, err = verify_instrument_error(event)
        else
            return nil, invalid("events.kind")
        end
        if not ok then
            return nil, err
        end
        local id = event_identity(event)
        if not id or records[id] then
            return nil, invalid("events.identity")
        end
        records[id] = event
        record_indices[id] = index

        if event.kind == "route_evidence_request" then
            requests[event.record_id] = event
        elseif event.kind == "route_evidence_selection" then
            if selections[event.route_evidence_id]
                or ordinals[event.route_ordinal] then
                return nil, invalid("events.selection.replay")
            end
            selections[event.route_evidence_id] = event
            selections_by_ref[event.record_id] = event
            ordinals[event.route_ordinal] = event.route_evidence_id
        elseif event.kind == "edge_credit_selection_eligibility" then
            eligibility[event.eligibility_ref] = event
        elseif event.kind == "route_evidence_commit" then
            if commits[event.route_evidence_id] then
                return nil, invalid("events.commit.replay")
            end
            commits[event.route_evidence_id] = event
            commits_by_ref[event.record_id] = event
        elseif event.kind == "route_evidence_arrival" then
            if terminals[event.route_evidence_id] then
                return nil, invalid("events.terminal.replay")
            end
            arrivals[event.record_id] = event
            terminals[event.route_evidence_id] = event
        elseif event.kind == "route_evidence_failure"
            or event.kind == "route_evidence_pending" then
            if terminals[event.route_evidence_id] then
                return nil, invalid("events.terminal.replay")
            end
            terminals[event.route_evidence_id] = event
        elseif event.kind == "edge_credit_decision" then
            if decisions[event.route_evidence_id] then
                return nil, invalid("events.credit_decision.replay")
            end
            decisions[event.route_evidence_id] = event
        elseif event.kind == "authority_instrument_error" then
            errors[event.error_id] = event
        elseif event.kind == "authority_taint" then
            taints[#taints + 1] = event
        end
    end

    for route_id, selection in pairs(selections) do
        if selection.route_authority == "tree" then
            if selection.authority_basis_ref ~= selection.derivation_ref then
                return nil, invalid("selection.tree_basis")
            end
        else
            local request = requests[selection.authority_basis_ref]
            if not request
                or record_indices[request.record_id] >= record_indices[selection.record_id]
                or request.route_ordinal ~= selection.route_ordinal
                or request.from ~= selection.from or request.to ~= selection.to
                or request.route_authority ~= selection.route_authority then
                return nil, invalid("selection.request_basis")
            end
        end
        if selection.classification_status == "classified" then
            local embedded = selection.eligibility
            local standalone = eligibility[embedded.eligibility_ref]
            if not standalone or not same_value(embedded, standalone)
                or standalone.route_evidence_id ~= route_id
                or record_indices[standalone.eligibility_ref]
                    <= record_indices[selection.record_id] then
                return nil, invalid("selection.eligibility_ref")
            end
            if state.authority_epoch then
                if embedded.physics_epoch_id ~= state.authority_epoch.physics_epoch_id
                    or embedded.evidence_epoch_id
                        ~= state.authority_epoch.evidence_epoch_id then
                    return nil, invalid("selection.eligibility_epoch")
                end
            end
        else
            for _, code in ipairs(selection.classification_error_codes) do
                local found = false
                for _, err in pairs(errors) do
                    if err.route_evidence_id == route_id and err.code == code then
                        found = true
                        break
                    end
                end
                if not found then
                    return nil, invalid("selection.instrument_error")
                end
            end
        end
    end

    for route_id, commit in pairs(commits) do
        local selection = selections[route_id]
        if not selection
            or commit.selection_ref ~= selection.record_id
            or record_indices[commit.record_id] <= record_indices[selection.record_id]
            or commit.from ~= selection.from or commit.to ~= selection.to
            or commit.route_authority ~= selection.route_authority then
            return nil, invalid("commit.selection_ref")
        end
    end

    for route_id, terminal in pairs(terminals) do
        local commit = commits[route_id]
        if not commit or terminal.commit_ref ~= commit.record_id
            or record_indices[event_identity(terminal)]
                <= record_indices[commit.record_id] then
            return nil, invalid("terminal.commit_ref")
        end
        if terminal.kind == "route_evidence_arrival" then
            local decision = decisions[route_id]
            local selection = selections[route_id]
            if selection.classification_status == "classified" then
                if not decision or decision.arrival_ref ~= terminal.record_id then
                    return nil, invalid("arrival.credit_decision")
                end
            elseif decision then
                return nil, invalid("arrival.unclassified_decision")
            end
        elseif decisions[route_id] then
            return nil, invalid("terminal.non_arrival_decision")
        end
    end

    for route_id, decision in pairs(decisions) do
        local selection = selections[route_id]
        local commit = commits[route_id]
        local arrival = arrivals[decision.arrival_ref]
        local selected_eligibility = selection and selection.eligibility
        if not selection or not commit or not arrival or not selected_eligibility
            or decision.selection_eligibility_ref
                ~= selected_eligibility.eligibility_ref
            or decision.commit_ref ~= commit.record_id
            or decision.route_evidence_id ~= route_id
            or not same_value(decision.reasons, selected_eligibility.reasons)
            or decision.status ~= (selected_eligibility.status == "eligible"
                and "credited" or "rejected") then
            return nil, invalid("credit_decision.causal_chain")
        end
        local expected_basis = normalized_set({
            selected_eligibility.eligibility_ref,
            commit.record_id,
            arrival.record_id,
        })
        if not same_value(decision.basis_refs, expected_basis) then
            return nil, invalid("credit_decision.basis_refs")
        end
    end

    local expected_mismatch
    if state.authority_epoch then
        local configured = state.authority_epoch.configured.configured_movement_owner
        for index, event in ipairs(state.events) do
            if event.kind == "route_evidence_commit" then
                local selection = selections[event.route_evidence_id]
                if selection.route_authority ~= configured then
                    expected_mismatch = {
                        commit = event,
                        selection = selection,
                        index = index,
                    }
                    break
                end
            end
        end
    end
    if expected_mismatch then
        if #taints ~= 1 then
            return nil, invalid("authority_taint.count")
        end
        local taint = taints[1]
        if taint.route_evidence_id ~= expected_mismatch.selection.route_evidence_id
            or taint.commit_ref ~= expected_mismatch.commit.record_id
            or taint.configured_owner
                ~= state.authority_epoch.configured.configured_movement_owner
            or taint.observed_owner ~= expected_mismatch.selection.route_authority
            or record_indices[taint.record_id] <= expected_mismatch.index then
            return nil, invalid("authority_taint.identity")
        end
    elseif #taints ~= 0 then
        return nil, invalid("authority_taint.unexpected")
    end

    if #taints == 1 then
        local taint_index = record_indices[taints[1].record_id]
        for _, selection in pairs(selections) do
            if record_indices[selection.record_id] > taint_index
                and selection.classification_status == "classified"
                and not has_value(selection.eligibility.reasons, "authority_tainted") then
                return nil, invalid("authority_taint.monotonicity")
            end
        end
    end
    return true
end

function credit.new(epoch_record, identity)
    if epoch_record ~= nil then
        local epoch_ok, epoch_err = authority_epoch.verify(epoch_record)
        if not epoch_ok then
            return nil, epoch_err
        end
    end
    if not validate_identity(identity) then
        return nil, instrument_error("invalid_edge_credit_identity")
    end
    local state = {
        kind = "edge_credit_state",
        protocol_version = credit.protocol_version,
        authority_epoch = epoch_record and copy_value(epoch_record) or nil,
        identity = copy_value(identity),
        events = {},
        next_sequence = 1,
    }
    local ok, err = credit.verify(state)
    if not ok then
        return nil, err
    end
    return state
end

local function working_state(state)
    local ok, err = credit.verify(state)
    if not ok then
        return nil, err
    end
    return copy_value(state)
end

local function commit_working_state(target, working)
    local ok, err = credit.verify(working)
    if not ok then
        return nil, err
    end
    replace_contents(target, working)
    return true
end

local function prepare_on(state, decision, context)
    if type(decision) ~= "table" or type(context) ~= "table"
        or not positive_integer(context.route_ordinal)
        or not route_authorities[decision.authority]
        or decision.truth_status ~= "runtime_confirmed" then
        return nil, instrument_error("invalid_route_selection_input")
    end
    local definition, from, to = route_definition(decision.from, decision.to)
    if not definition then
        return nil, instrument_error("route_outside_authority_surface")
    end
    if decision.from ~= from or decision.to ~= to then
        return nil, instrument_error("route_identity_mismatch")
    end
    for _, event in ipairs(state.events) do
        if event.kind == "route_evidence_selection"
            and event.route_ordinal == context.route_ordinal then
            return nil, instrument_error("route_ordinal_replayed")
        end
    end

    local request
    local authority_basis_ref
    if decision.authority == "tree" then
        authority_basis_ref = non_empty(decision.derivation_ref)
            and decision.derivation_ref or "none"
    else
        request = request_record(
            state,
            decision,
            context.route_ordinal,
            from,
            to
        )
        if not request then
            return nil, instrument_error("route_request_identity_failure")
        end
        append_record(state, request)
        authority_basis_ref = request.record_id
    end

    local epoch_record = state.authority_epoch
    local route_record_seed = {
        evidence_epoch_id = epoch_record and epoch_record.evidence_epoch_id or nil,
        life_id = state.identity.life_id,
        packet_id = state.identity.packet_id,
        lineage_id = state.identity.lineage_id,
        generation = state.identity.generation,
        route_ordinal = context.route_ordinal,
        from = from,
        to = to,
        route_authority = decision.authority,
        authority_basis_ref = authority_basis_ref,
        derivation_ref = decision.authority == "tree"
            and decision.derivation_ref or nil,
        pressure_snapshot_ref = decision.authority == "tree"
            and decision.pressure_snapshot_ref or nil,
        selected_action_plan_id = decision.authority == "tree"
            and decision.selected_action_plan_id or nil,
    }
    local route_evidence_id, route_id_err = tagged_digest(
        route_evidence_seed(route_record_seed)
    )
    if not route_evidence_id then
        return nil, route_id_err
    end

    local error_codes = {}
    if not epoch_record then
        error_codes[#error_codes + 1] = "authority_epoch_invalid"
    end
    local body_eligibility
    if decision.authority == "tree" then
        if not non_empty(decision.derivation_ref)
            or not non_empty(decision.pressure_snapshot_ref)
            or type(context.derivation_event) ~= "table"
            or context.derivation_event.id ~= decision.derivation_ref then
            error_codes[#error_codes + 1] = "authority_basis_missing"
        else
            local body, chain_error = body_eligibility_chain(
                decision,
                context.derivation_event,
                from,
                to
            )
            if body then
                body_eligibility = body
            else
                error_codes[#error_codes + 1] = chain_error
            end
        end
    else
        body_eligibility = {
            promotion_eligible = false,
            promotion_ineligibility_reasons = {"non_tree_authority"},
            promotion_eligibility_basis = {
                witness_ids = {},
                unqualified_snapshot = false,
                fixture_witness_ids = {},
            },
        }
    end
    error_codes = normalized_set(error_codes, classification_errors)

    local eligibility
    if #error_codes == 0 then
        eligibility = make_eligibility(
            state,
            route_evidence_id,
            decision.authority,
            body_eligibility,
            decision.selected_action_plan_id,
            authority_basis_ref,
            decision.pressure_snapshot_ref
        )
        if not eligibility then
            return nil, instrument_error("eligibility_identity_failure")
        end
    end

    local selection = {
        kind = "route_evidence_selection",
        protocol_version = credit.route_protocol_version,
        route_evidence_id = route_evidence_id,
        sequence = state.next_sequence,
        route_ordinal = context.route_ordinal,
        evidence_epoch_id = epoch_record and epoch_record.evidence_epoch_id or nil,
        physics_epoch_id = epoch_record and epoch_record.physics_epoch_id or nil,
        life_id = state.identity.life_id,
        packet_id = state.identity.packet_id,
        lineage_id = state.identity.lineage_id,
        generation = state.identity.generation,
        from = from,
        to = to,
        edge_id = definition.id,
        route_authority = decision.authority,
        authority_basis_ref = authority_basis_ref,
        derivation_ref = decision.authority == "tree"
            and decision.derivation_ref or nil,
        pressure_snapshot_ref = decision.authority == "tree"
            and decision.pressure_snapshot_ref or nil,
        selected_action_plan_id = decision.authority == "tree"
            and decision.selected_action_plan_id or nil,
        classification_status = eligibility and "classified" or "unclassified",
        classification_error_codes = error_codes,
        eligibility = eligibility and copy_value(eligibility) or nil,
        event_truth_status = "runtime_confirmed",
    }
    local selection_id, selection_id_err = tagged_digest(selection_seed(selection))
    if not selection_id then
        return nil, selection_id_err
    end
    selection.record_id = selection_id
    append_record(state, selection)
    if eligibility then
        append_record(state, eligibility)
    else
        local refs = {}
        if non_empty(decision.derivation_ref) then
            refs[#refs + 1] = decision.derivation_ref
        end
        if non_empty(decision.pressure_snapshot_ref) then
            refs[#refs + 1] = decision.pressure_snapshot_ref
        end
        for _, code in ipairs(error_codes) do
            local record, record_err = make_instrument_error(
                code,
                route_evidence_id,
                refs
            )
            if not record then
                return nil, record_err
            end
            append_record(state, record)
        end
    end
    return selection
end

function credit.prepare(state, decision, context)
    local working, working_err = working_state(state)
    if not working then
        return nil, working_err
    end
    local selection, selection_err = prepare_on(working, decision, context)
    if not selection then
        return nil, selection_err
    end
    local committed, commit_err = commit_working_state(state, working)
    if not committed then
        return nil, commit_err
    end
    return copy_value(selection)
end

local function stored_selection(state, supplied)
    if type(supplied) ~= "table" or not tagged_hash(supplied.record_id) then
        return nil, instrument_error("invalid_selection_reference")
    end
    for _, event in ipairs(state.events) do
        if event.kind == "route_evidence_selection"
            and event.record_id == supplied.record_id then
            if not same_value(event, supplied) then
                return nil, instrument_error("route_identity_mismatch")
            end
            return event
        end
    end
    return nil, instrument_error("selection_ref_unresolved")
end

local function stored_commit(state, supplied)
    if type(supplied) ~= "table" or not tagged_hash(supplied.record_id) then
        return nil, instrument_error("invalid_commit_reference")
    end
    for _, event in ipairs(state.events) do
        if event.kind == "route_evidence_commit"
            and event.record_id == supplied.record_id then
            if not same_value(event, supplied) then
                return nil, instrument_error("route_identity_mismatch")
            end
            return event
        end
    end
    return nil, instrument_error("commit_ref_unresolved")
end

local function terminal_for(state, route_evidence_id)
    for _, event in ipairs(state.events) do
        if (event.kind == "route_evidence_arrival"
            or event.kind == "route_evidence_failure"
            or event.kind == "route_evidence_pending")
            and event.route_evidence_id == route_evidence_id then
            return event
        end
    end
    return nil
end

local function route_event_matches(state, selection, route_event)
    if type(route_event) ~= "table" or not non_empty(route_event.id)
        or route_event.type ~= "route"
        or route_event.truth_status ~= "runtime_confirmed"
        or topology.resolve(route_event.operator) ~= selection.to
        or type(route_event.payload) ~= "table" then
        return false
    end
    local payload = route_event.payload
    if topology.resolve(payload.from) ~= selection.from
        or topology.resolve(payload.to) ~= selection.to
        or payload.authority ~= selection.route_authority
        or payload.derivation_ref ~= selection.derivation_ref
        or payload.pressure_snapshot_ref ~= selection.pressure_snapshot_ref
        or payload.selected_action_plan_id ~= selection.selected_action_plan_id then
        return false
    end
    if selection.route_authority == "tree"
        and selection.classification_status == "classified" then
        local body = normalize_body_eligibility(payload)
        if not body then
            return false
        end
        local expected = make_eligibility(
            state,
            selection.route_evidence_id,
            selection.route_authority,
            body,
            selection.selected_action_plan_id,
            selection.authority_basis_ref,
            selection.pressure_snapshot_ref
        )
        if not expected or not same_value(expected, selection.eligibility) then
            return false
        end
    end
    return true
end

local function record_commit_on(state, supplied_selection, route_event)
    local selection, selection_err = stored_selection(state, supplied_selection)
    if not selection then
        return nil, nil, selection_err
    end
    for _, event in ipairs(state.events) do
        if event.kind == "route_evidence_commit"
            and event.route_evidence_id == selection.route_evidence_id then
            return nil, nil, instrument_error("route_commit_replayed")
        end
    end
    if not route_event_matches(state, selection, route_event) then
        return nil, nil, instrument_error("route_identity_mismatch", {
            route_evidence_id = selection.route_evidence_id,
        })
    end
    local record = {
        kind = "route_evidence_commit",
        protocol_version = credit.route_protocol_version,
        route_evidence_id = selection.route_evidence_id,
        selection_ref = selection.record_id,
        route_trace_ref = route_event.id,
        from = selection.from,
        to = selection.to,
        route_authority = selection.route_authority,
        event_truth_status = "runtime_confirmed",
    }
    local id, id_err = tagged_digest(commit_seed(record))
    if not id then
        return nil, nil, id_err
    end
    record.record_id = id
    append_record(state, record)

    local taint
    local epoch_record = state.authority_epoch
    if epoch_record and not first_taint(state)
        and selection.route_authority
            ~= epoch_record.configured.configured_movement_owner then
        taint = {
            kind = "authority_taint",
            protocol_version = credit.protocol_version,
            route_evidence_id = selection.route_evidence_id,
            commit_ref = record.record_id,
            sequence = state.next_sequence,
            configured_owner = epoch_record.configured.configured_movement_owner,
            observed_owner = selection.route_authority,
            cause = "authority_owner_mismatch",
            event_truth_status = "runtime_confirmed",
        }
        local taint_id, taint_err = tagged_digest(taint_seed(taint))
        if not taint_id then
            return nil, nil, taint_err
        end
        taint.record_id = taint_id
        append_record(state, taint)
    end
    return record, taint
end

function credit.record_commit(state, selection, route_event)
    local working, working_err = working_state(state)
    if not working then
        return nil, nil, working_err
    end
    local record, taint, record_err = record_commit_on(
        working,
        selection,
        route_event
    )
    if not record then
        return nil, nil, record_err
    end
    local committed, commit_err = commit_working_state(state, working)
    if not committed then
        return nil, nil, commit_err
    end
    return copy_value(record), copy_value(taint), nil
end

local function selection_for_commit(state, commit)
    for _, event in ipairs(state.events) do
        if event.kind == "route_evidence_selection"
            and event.record_id == commit.selection_ref then
            return event
        end
    end
    return nil
end

local function record_arrival_on(state, supplied_commit, input)
    local commit, commit_err = stored_commit(state, supplied_commit)
    if not commit then
        return nil, nil, commit_err
    end
    if terminal_for(state, commit.route_evidence_id) then
        return nil, nil, instrument_error("route_phase_replayed", {
            route_evidence_id = commit.route_evidence_id,
        })
    end
    if type(input) ~= "table" or not non_empty(input.destination_tick_ref)
        or not non_empty(input.payload_kind) then
        return nil, nil, instrument_error("invalid_arrival_input")
    end
    local effect_refs = strict_sorted_unique(input.effect_refs)
    if not effect_refs then
        return nil, nil, instrument_error("invalid_arrival_effect_refs")
    end
    local arrival = {
        kind = "route_evidence_arrival",
        protocol_version = credit.route_protocol_version,
        route_evidence_id = commit.route_evidence_id,
        commit_ref = commit.record_id,
        destination_tick_ref = input.destination_tick_ref,
        effect_refs = effect_refs,
        payload_kind = input.payload_kind,
        event_truth_status = "runtime_confirmed",
    }
    local arrival_id, arrival_err = tagged_digest(arrival_seed(arrival))
    if not arrival_id then
        return nil, nil, arrival_err
    end
    arrival.record_id = arrival_id
    append_record(state, arrival)

    local selection = selection_for_commit(state, commit)
    if not selection then
        return nil, nil, instrument_error("selection_ref_unresolved")
    end
    if selection.classification_status == "unclassified" then
        return arrival, nil
    end
    local selected_eligibility = selection.eligibility
    local decision = {
        kind = "edge_credit_decision",
        protocol_version = credit.protocol_version,
        route_evidence_id = commit.route_evidence_id,
        selection_eligibility_ref = selected_eligibility.eligibility_ref,
        commit_ref = commit.record_id,
        arrival_ref = arrival.record_id,
        status = selected_eligibility.status == "eligible"
            and "credited" or "rejected",
        reasons = copy_value(selected_eligibility.reasons),
        basis_refs = normalized_set({
            selected_eligibility.eligibility_ref,
            commit.record_id,
            arrival.record_id,
        }),
        event_truth_status = "runtime_confirmed",
    }
    local decision_id, decision_err = tagged_digest(decision_seed(decision))
    if not decision_id then
        return nil, nil, decision_err
    end
    decision.credit_decision_ref = decision_id
    append_record(state, decision)
    return arrival, decision
end

function credit.record_arrival(state, commit, input)
    local working, working_err = working_state(state)
    if not working then
        return nil, nil, working_err
    end
    local arrival, decision, arrival_err = record_arrival_on(
        working,
        commit,
        input
    )
    if not arrival then
        return nil, nil, arrival_err
    end
    local committed, commit_err = commit_working_state(state, working)
    if not committed then
        return nil, nil, commit_err
    end
    return copy_value(arrival), copy_value(decision), nil
end

local function record_failure_on(state, supplied_commit, input)
    local commit, commit_err = stored_commit(state, supplied_commit)
    if not commit then
        return nil, commit_err
    end
    if terminal_for(state, commit.route_evidence_id) then
        return nil, instrument_error("route_phase_replayed", {
            route_evidence_id = commit.route_evidence_id,
        })
    end
    if type(input) ~= "table" or not non_empty(input.destination_tick_ref)
        or not non_empty(input.failure_ref) or not non_empty(input.failure_kind) then
        return nil, instrument_error("invalid_failure_input")
    end
    local record = {
        kind = "route_evidence_failure",
        protocol_version = credit.route_protocol_version,
        route_evidence_id = commit.route_evidence_id,
        commit_ref = commit.record_id,
        destination_tick_ref = input.destination_tick_ref,
        failure_ref = input.failure_ref,
        failure_kind = input.failure_kind,
        event_truth_status = "runtime_confirmed",
    }
    local id, id_err = tagged_digest(failure_seed(record))
    if not id then
        return nil, id_err
    end
    record.record_id = id
    append_record(state, record)
    return record
end

function credit.record_failure(state, commit, input)
    local working, working_err = working_state(state)
    if not working then
        return nil, working_err
    end
    local record, record_err = record_failure_on(working, commit, input)
    if not record then
        return nil, record_err
    end
    local committed, commit_err = commit_working_state(state, working)
    if not committed then
        return nil, commit_err
    end
    return copy_value(record)
end

local function record_pending_on(state, supplied_commit, input)
    local commit, commit_err = stored_commit(state, supplied_commit)
    if not commit then
        return nil, commit_err
    end
    if terminal_for(state, commit.route_evidence_id) then
        return nil, instrument_error("route_phase_replayed", {
            route_evidence_id = commit.route_evidence_id,
        })
    end
    if type(input) ~= "table" or input.stop_reason ~= "tick_limit" then
        return nil, instrument_error("invalid_pending_input")
    end
    local record = {
        kind = "route_evidence_pending",
        protocol_version = credit.route_protocol_version,
        route_evidence_id = commit.route_evidence_id,
        commit_ref = commit.record_id,
        stop_reason = "tick_limit",
        event_truth_status = "runtime_confirmed",
    }
    local id, id_err = tagged_digest(pending_seed(record))
    if not id then
        return nil, id_err
    end
    record.record_id = id
    append_record(state, record)
    return record
end

function credit.record_pending(state, commit, input)
    local working, working_err = working_state(state)
    if not working then
        return nil, working_err
    end
    local record, record_err = record_pending_on(working, commit, input)
    if not record then
        return nil, record_err
    end
    local committed, commit_err = commit_working_state(state, working)
    if not committed then
        return nil, commit_err
    end
    return copy_value(record)
end

local function require_runtime_state(state)
    if runtime_states[state] ~= true then
        return nil, instrument_error("runtime_credit_state_unavailable")
    end
    return true
end

local function rollback_runtime_events(state, event_count)
    for index = #state.events, event_count + 1, -1 do
        state.events[index] = nil
    end
    state.next_sequence = #state.events + 1
end

function credit.new_runtime(epoch_record, identity)
    local state, state_err = credit.new(epoch_record, identity)
    if not state then
        return nil, state_err
    end
    runtime_states[state] = true
    return state
end

function credit.runtime_prepare(state, decision, context)
    local available, available_err = require_runtime_state(state)
    if not available then
        return nil, available_err
    end
    local event_count = #state.events
    local selection, selection_err = prepare_on(state, decision, context)
    if not selection then
        rollback_runtime_events(state, event_count)
        return nil, selection_err
    end
    return copy_value(selection)
end

function credit.runtime_record_commit(state, selection, route_event)
    local available, available_err = require_runtime_state(state)
    if not available then
        return nil, nil, available_err
    end
    local event_count = #state.events
    local record, taint, record_err = record_commit_on(
        state,
        selection,
        route_event
    )
    if not record then
        rollback_runtime_events(state, event_count)
        return nil, nil, record_err
    end
    return copy_value(record), copy_value(taint), nil
end

function credit.runtime_record_arrival(state, commit, input)
    local available, available_err = require_runtime_state(state)
    if not available then
        return nil, nil, available_err
    end
    local event_count = #state.events
    local arrival, decision, arrival_err = record_arrival_on(
        state,
        commit,
        input
    )
    if not arrival then
        rollback_runtime_events(state, event_count)
        return nil, nil, arrival_err
    end
    return copy_value(arrival), copy_value(decision), nil
end

function credit.runtime_record_failure(state, commit, input)
    local available, available_err = require_runtime_state(state)
    if not available then
        return nil, available_err
    end
    local event_count = #state.events
    local record, record_err = record_failure_on(state, commit, input)
    if not record then
        rollback_runtime_events(state, event_count)
        return nil, record_err
    end
    return copy_value(record)
end

function credit.runtime_record_pending(state, commit, input)
    local available, available_err = require_runtime_state(state)
    if not available then
        return nil, available_err
    end
    local event_count = #state.events
    local record, record_err = record_pending_on(state, commit, input)
    if not record then
        rollback_runtime_events(state, event_count)
        return nil, record_err
    end
    return copy_value(record)
end

function credit.finish_runtime(state)
    local available, available_err = require_runtime_state(state)
    if not available then
        return nil, available_err
    end
    local verified, verify_err = credit.verify(state)
    if not verified then
        return nil, verify_err
    end
    runtime_states[state] = nil
    return state
end

function credit.authority_taint(state)
    local ok, err = credit.verify(state)
    if not ok then
        return nil, err
    end
    return copy_value(first_taint(state))
end

function credit.snapshot(state)
    local ok, err = credit.verify(state)
    if not ok then
        return nil, err
    end
    return copy_value(state)
end

return credit
