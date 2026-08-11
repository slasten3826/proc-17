local digest = require("core.digest")
local life_projection = require("runtime.edge_life_projection")
local json = require("core.json")

local cases = {
    protocol_version = "tree-authority-cases.v0",
    evidence_protocol_version = "edge-case-evidence.v0",
    harness_protocol_version = "edge-harness-evidence.v0",
    view_protocol_version = "edge-case-corpus-view.v0",
}

local evaluator_version = "edge-case-evaluator.v0"
local source_table = "tree_authority_promotion_corpus_yellowprint.v0"

local control_kinds = {
    observer_mirror = true,
    legacy_dissent = true,
    grave_disabled = true,
    different_session = true,
    malformed_harness = true,
    malformed_effect = true,
    host_ceiling_above_budget = true,
    grave_disabled_orphan = true,
    larger_loss_limit = true,
    no_relation_need = true,
    no_rigidity = true,
    single_alternative_confirmation = true,
    matched_typed_failure = true,
    successful_provider_run = true,
    honest_blocked_manifest = true,
    real_alternative_loss = true,
    bounded_long_trace = true,
}

local control_reference_kind = {
    observer_mirror = "observer_pair",
    legacy_dissent = "evidence",
    grave_disabled = "life",
    different_session = "life",
    malformed_harness = "evidence",
    malformed_effect = "evidence",
    host_ceiling_above_budget = "life",
    grave_disabled_orphan = "life",
    larger_loss_limit = "life",
    no_relation_need = "life",
    no_rigidity = "life",
    single_alternative_confirmation = "life",
    matched_typed_failure = "evidence",
    successful_provider_run = "evidence",
    honest_blocked_manifest = "evidence",
    real_alternative_loss = "evidence",
    bounded_long_trace = "evidence",
}

local family_case_ids = {
    "P01", "P02", "P03", "P04", "P05", "P06a", "P06b",
    "P07", "P08", "P09", "P10", "P11",
}

local definitions = {
    {"P01", "L0", "life", {"observer_mirror"}, true},
    {"P02", "L0", "life", {"legacy_dissent"}, true},
    {"P03", "L0", "lineage", {"different_session", "grave_disabled"}, true},
    {"P04", "L0", "life", {"malformed_harness"}, true},
    {"P05", "L0", "life", {"malformed_effect"}, true},
    {"P06a", "L0", "life", {"host_ceiling_above_budget"}, true},
    {"P06b", "L0", "life", {"grave_disabled_orphan"}, true},
    {"P07", "L0", "life", {"larger_loss_limit"}, true},
    {"P08", "L0", "life", {"observer_mirror"}, true},
    {"P09", "L0", "life", {"no_relation_need"}, true},
    {"P10", "L0", "life", {"no_rigidity"}, true},
    {"P11", "L0", "life", {"single_alternative_confirmation"}, true},
    {"P12", "L0", "family_pair", {}, false, family_case_ids},
    {"P13", "L0", "harness_boundary", {"matched_typed_failure"}, false},
    {"L1_ACCEPTED_BUILD", "L1", "live_document", {"successful_provider_run"}, false},
    {"L1_REJECTED_BUILD", "L1", "live_document", {"honest_blocked_manifest"}, false},
    {"L1_MULTI_CHOOSE", "L1", "live_document", {"real_alternative_loss"}, false},
    {"L1_LONG_TREE", "L1", "live_document", {"bounded_long_trace"}, false},
}

local definition_by_id = {}

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

local function same_value(left, right)
    local left_ok, left_encoded = pcall(json.encode, left)
    local right_ok, right_encoded = pcall(json.encode, right)
    return left_ok and right_ok and left_encoded == right_encoded
end

local function case_error(code, extra)
    local value = {
        class = "instrument_contract",
        code = code,
        stage = "edge_case_manifest",
    }
    for key, child in pairs(extra or {}) do value[key] = child end
    return value
end

local function non_empty(value)
    return type(value) == "string" and value ~= ""
end

local function tagged_hash(value)
    return type(value) == "string"
        and #value == 71
        and value:sub(1, 7) == "sha256:"
        and value:sub(8):match("^[0-9a-f]+$") ~= nil
end

local function tagged_digest(value)
    local hashed, hash_err = digest.record(value)
    if not hashed then
        return nil, case_error("case_digest_failed", {detail = tostring(hash_err)})
    end
    return "sha256:" .. hashed
end

local function exact_keys(value, required, optional)
    if type(value) ~= "table" or getmetatable(value) ~= nil then return false end
    optional = optional or {}
    for key in pairs(value) do
        if not required[key] and not optional[key] then return false end
    end
    for key in pairs(required) do
        if value[key] == nil then return false end
    end
    return true
end

local function sorted_unique(values, allow_empty)
    if type(values) ~= "table" then return nil end
    local result = {}
    local seen = {}
    for _, value in ipairs(values) do
        if not non_empty(value) or seen[value] then return nil end
        seen[value] = true
        result[#result + 1] = value
    end
    if not allow_empty and #result == 0 then return nil end
    table.sort(result)
    return result
end

local function canonical_unique(values)
    local result = {}
    local seen = {}
    for _, value in ipairs(values or {}) do
        if not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function definition_record(raw)
    local case_id, layer, evidence_kind, required, pair_required, families =
        raw[1], raw[2], raw[3], raw[4], raw[5], raw[6]
    local evaluator_id = layer == "L0"
        and ("tree-authority.case." .. case_id .. ".v0")
        or ("tree-authority.live." .. case_id .. ".document.v0")
    return {
        case_id = case_id,
        layer = layer,
        evidence_kind = evidence_kind,
        evaluator_id = evaluator_id,
        evaluator_version = evaluator_version,
        required_control_kinds = copy_value(required),
        observer_pair_required = pair_required,
        observer_family_case_ids = copy_value(families or {}),
    }
end

for _, raw in ipairs(definitions) do
    definition_by_id[raw[1]] = definition_record(raw)
end

local function manifest_seed(record)
    return {
        kind = record.kind,
        protocol_version = record.protocol_version,
        source_table = record.source_table,
        required_l0 = copy_value(record.required_l0),
        required_l1 = copy_value(record.required_l1),
        decision_truth_status = record.decision_truth_status,
        event_truth_status = record.event_truth_status,
    }
end

local function current_manifest()
    local record = {
        kind = "tree_authority_case_manifest",
        protocol_version = cases.protocol_version,
        manifest_id = nil,
        source_table = source_table,
        required_l0 = {},
        required_l1 = {},
        decision_truth_status = "document_decision",
        event_truth_status = "runtime_confirmed",
    }
    for _, raw in ipairs(definitions) do
        local definition = definition_record(raw)
        local target = definition.layer == "L0"
            and record.required_l0 or record.required_l1
        target[#target + 1] = definition
    end
    record.manifest_id = assert(tagged_digest(manifest_seed(record)))
    return record
end

function cases.current()
    return copy_value(current_manifest())
end

function cases.verify_manifest(record)
    if not exact_keys(record, {
        kind = true,
        protocol_version = true,
        manifest_id = true,
        source_table = true,
        required_l0 = true,
        required_l1 = true,
        decision_truth_status = true,
        event_truth_status = true,
    }) or record.kind ~= "tree_authority_case_manifest"
        or record.protocol_version ~= cases.protocol_version
        or not tagged_hash(record.manifest_id)
        or record.source_table ~= source_table
        or record.decision_truth_status ~= "document_decision"
        or record.event_truth_status ~= "runtime_confirmed" then
        return nil, case_error("case_manifest_invalid")
    end
    local expected = current_manifest()
    if not same_value(record, expected) then
        return nil, case_error("case_manifest_not_current")
    end
    return true
end

local function case_seed(record)
    local seed = copy_value(record)
    seed.case_evidence_id = nil
    return seed
end

local function harness_seed(record)
    local seed = copy_value(record)
    seed.boundary_evidence_id = nil
    return seed
end

local function document_seed(record)
    local seed = copy_value(record)
    seed.document_id = nil
    return seed
end

function cases.verify_harness_evidence(record)
    if not exact_keys(record, {
        kind = true,
        protocol_version = true,
        boundary_evidence_id = true,
        case_id = true,
        invalid_invocation_digest = true,
        harness_error_code = true,
        packet_death_observed = true,
        packet_terminal_observed = true,
        matching_valid_life_id = true,
        source_revision = true,
        verifier_ref = true,
        event_truth_status = true,
    }) or record.kind ~= "edge_harness_boundary_evidence"
        or record.protocol_version ~= cases.harness_protocol_version
        or (record.case_id ~= "P04" and record.case_id ~= "P05"
            and record.case_id ~= "P13")
        or not tagged_hash(record.boundary_evidence_id)
        or not tagged_hash(record.invalid_invocation_digest)
        or not non_empty(record.harness_error_code)
        or record.packet_death_observed ~= false
        or record.packet_terminal_observed ~= false
        or not non_empty(record.matching_valid_life_id)
        or not non_empty(record.source_revision)
        or not non_empty(record.verifier_ref)
        or record.event_truth_status ~= "runtime_confirmed" then
        return nil, case_error("harness_evidence_invalid")
    end
    local expected, expected_err = tagged_digest(harness_seed(record))
    if not expected then return nil, expected_err end
    if record.boundary_evidence_id ~= expected then
        return nil, case_error("harness_evidence_identity_mismatch")
    end
    return true
end

function cases.harness_evidence(fields)
    if type(fields) ~= "table" then
        return nil, case_error("harness_evidence_fields_required")
    end
    local record = {
        kind = "edge_harness_boundary_evidence",
        protocol_version = cases.harness_protocol_version,
        boundary_evidence_id = nil,
        case_id = fields.case_id,
        invalid_invocation_digest = fields.invalid_invocation_digest,
        harness_error_code = fields.harness_error_code,
        packet_death_observed = fields.packet_death_observed,
        packet_terminal_observed = fields.packet_terminal_observed,
        matching_valid_life_id = fields.matching_valid_life_id,
        source_revision = fields.source_revision,
        verifier_ref = fields.verifier_ref,
        event_truth_status = "runtime_confirmed",
    }
    local identity, identity_err = tagged_digest(harness_seed(record))
    if not identity then return nil, identity_err end
    record.boundary_evidence_id = identity
    local ok, err = cases.verify_harness_evidence(record)
    if not ok then return nil, err end
    return copy_value(record)
end

local reason_by_status = {
    green = {verified_success = true},
    red = {semantic_failure = true, verifier_rejection = true},
    blocked = {provider_unavailable = true, transport_failure = true},
}

function cases.verify_l1_document(record)
    if not exact_keys(record, {
        kind = true,
        protocol_version = true,
        document_id = true,
        case_id = true,
        artifact_path = true,
        artifact_digest = true,
        provider = true,
        model = true,
        prompt_hash = true,
        usage_ref = true,
        source_revision = true,
        verifier_ref = true,
        decision = true,
        decision_reason = true,
        decision_truth_status = true,
    }) or record.kind ~= "edge_live_case_document"
        or record.protocol_version ~= cases.evidence_protocol_version
        or not definition_by_id[record.case_id]
        or definition_by_id[record.case_id].layer ~= "L1"
        or not tagged_hash(record.document_id)
        or not non_empty(record.artifact_path)
        or not tagged_hash(record.artifact_digest)
        or not non_empty(record.provider)
        or not non_empty(record.model)
        or not tagged_hash(record.prompt_hash)
        or not non_empty(record.usage_ref)
        or not non_empty(record.source_revision)
        or not non_empty(record.verifier_ref)
        or not reason_by_status[record.decision]
        or not reason_by_status[record.decision][record.decision_reason]
        or record.decision_truth_status ~= "document_decision" then
        return nil, case_error("l1_document_invalid")
    end
    local expected, expected_err = tagged_digest(document_seed(record))
    if not expected then return nil, expected_err end
    if record.document_id ~= expected then
        return nil, case_error("l1_document_identity_mismatch")
    end
    return copy_value(record)
end

function cases.l1_document(fields)
    if type(fields) ~= "table" then
        return nil, case_error("l1_document_fields_required")
    end
    local record = {
        kind = "edge_live_case_document",
        protocol_version = cases.evidence_protocol_version,
        document_id = nil,
        case_id = fields.case_id,
        artifact_path = fields.artifact_path,
        artifact_digest = fields.artifact_digest,
        provider = fields.provider,
        model = fields.model,
        prompt_hash = fields.prompt_hash,
        usage_ref = fields.usage_ref,
        source_revision = fields.source_revision,
        verifier_ref = fields.verifier_ref,
        decision = fields.decision,
        decision_reason = fields.decision_reason,
        decision_truth_status = "document_decision",
    }
    local identity, identity_err = tagged_digest(document_seed(record))
    if not identity then return nil, identity_err end
    record.document_id = identity
    return cases.verify_l1_document(record)
end

local function definition_for(manifest, case_id)
    for _, list in ipairs({manifest.required_l0, manifest.required_l1}) do
        for _, definition in ipairs(list) do
            if definition.case_id == case_id then return definition end
        end
    end
    return nil
end

function cases.verify_case_evidence(record, manifest)
    manifest = manifest or current_manifest()
    local manifest_ok, manifest_err = cases.verify_manifest(manifest)
    if not manifest_ok then return nil, manifest_err end
    if not exact_keys(record, {
        kind = true,
        protocol_version = true,
        case_evidence_id = true,
        case_manifest_id = true,
        case_id = true,
        layer = true,
        target_evidence_epoch_id = true,
        implementation_revision = true,
        status = true,
        life_ids = true,
        control_life_ids = true,
        observer_pair_refs = true,
        evidence_refs = true,
        evaluator_id = true,
        evaluator_version = true,
        verifier_ref = true,
        evaluation_truth_status = true,
        event_truth_status = true,
    }) or record.kind ~= "edge_case_evidence"
        or record.protocol_version ~= cases.evidence_protocol_version
        or not tagged_hash(record.case_evidence_id)
        or record.case_manifest_id ~= manifest.manifest_id
        or not tagged_hash(record.target_evidence_epoch_id)
        or not non_empty(record.implementation_revision)
        or (record.status ~= "green" and record.status ~= "red"
            and record.status ~= "blocked")
        or not non_empty(record.verifier_ref)
        or record.event_truth_status ~= "runtime_confirmed" then
        return nil, case_error("case_evidence_invalid")
    end
    local definition = definition_for(manifest, record.case_id)
    if not definition or definition.layer ~= record.layer
        or definition.evaluator_id ~= record.evaluator_id
        or definition.evaluator_version ~= record.evaluator_version then
        return nil, case_error("case_evaluator_mismatch")
    end
    local expected_truth = record.layer == "L0"
        and "runtime_confirmed" or "document_decision"
    if record.evaluation_truth_status ~= expected_truth then
        return nil, case_error("case_evaluation_truth_invalid")
    end
    for _, key in ipairs({
        "life_ids", "control_life_ids", "observer_pair_refs", "evidence_refs",
    }) do
        local sorted = sorted_unique(record[key], true)
        if not sorted or not same_value(sorted, record[key]) then
            return nil, case_error("case_refs_not_canonical", {path = key})
        end
    end
    if record.status == "green" and definition.observer_pair_required
        and #record.observer_pair_refs == 0 then
        return nil, case_error("case_observer_pair_required")
    end
    if record.status == "green" and record.case_id == "P12"
        and #record.observer_pair_refs < #family_case_ids then
        return nil, case_error("case_family_pairs_incomplete")
    end
    if record.case_id == "P13" and #record.observer_pair_refs > 0 then
        return nil, case_error("harness_case_cannot_invent_observer_pair")
    end
    local expected, expected_err = tagged_digest(case_seed(record))
    if not expected then return nil, expected_err end
    if record.case_evidence_id ~= expected then
        return nil, case_error("case_evidence_identity_mismatch")
    end
    return true
end

local function terminal_view(life)
    local components = life.projection.exact_components
    return components.manifest_death_residue_terminal,
        components.identity_and_work_contract.packet,
        components.operator_status_and_walk,
        components.chaos_calm_field_revisions_effects,
        components.budget_and_loss
end

local function work_mode(identity)
    return identity and identity.regime and identity.regime.work
        and identity.regime.work.mode
end

local function death_cause(terminal)
    return terminal and terminal.death and terminal.death.cause
end

local function has_direction(life, glyph)
    for _, direction in ipairs(life.eligible_directions or {}) do
        if direction:find(glyph, 1, true) then return true end
    end
    return false
end

local function semantic_l0(case_id, life)
    local terminal, identity, status, field, budget_loss = terminal_view(life)
    local cause = death_cause(terminal)
    local residue = terminal.residue or {}
    if case_id == "P01" then
        return work_mode(identity) == "build" and cause == "complete"
            and type(terminal.manifest) == "table"
            and terminal.terminal and terminal.terminal.cause == "complete"
    elseif case_id == "P02" then
        return work_mode(identity) == "build" and cause == "blocked"
            and terminal.terminal and terminal.terminal.cause == "blocked"
    elseif case_id == "P03" then
        return type(identity.generation) == "number" and identity.generation > 1
            and non_empty(identity.parent_corpse_id)
            and non_empty(identity.carrier_id)
    elseif case_id == "P04" then
        return (cause == "stalled" or cause == "unsafe_scope")
            and type(terminal.runner.no_viable_edge) == "table"
    elseif case_id == "P05" then
        return cause == "effect_failure"
            and type(terminal.runner.effect_failure) == "table"
    elseif case_id == "P06a" or case_id == "P06b" then
        local progress = residue.progress or {}
        local done = progress.done_count or 0
        return cause == "budget_exhausted"
            and (case_id == "P06a" and done == 0 or case_id == "P06b" and done > 0)
    elseif case_id == "P07" then
        return cause == "identity_loss"
            and type(budget_loss.tension) == "table"
            and type(budget_loss.tension.loss) == "number"
            and budget_loss.tension.loss > 0
    elseif case_id == "P08" then
        return life.projection.corpse_status == "absent_alive"
            and status.runner.stop_reason == "tick_limit"
            and status.packet.status ~= "dead"
    elseif case_id == "P09" then
        local revisions = field.revisions or {}
        return has_direction(life, "☰")
            and ((revisions.relations_raw or 0) > 0
                or (revisions.relations_active or 0) > 0)
    elseif case_id == "P10" then
        return has_direction(life, "☷")
            and #(budget_loss.loss_records or {}) > 0
    elseif case_id == "P11" then
        for _, choice in ipairs(field.boundary.choices or {}) do
            local before = choice.before or choice.alternative_count or 0
            local killed = choice.not_chosen_count or choice.killed_count or 0
            if before > 1 and killed > 0 then return true end
        end
        return false
    end
    return false
end

local function validate_view(view)
    if type(view) ~= "table"
        or view.kind ~= "edge_case_corpus_view"
        or view.protocol_version ~= cases.view_protocol_version
        or not tagged_hash(view.target_evidence_epoch_id)
        or not tagged_hash(view.target_physics_epoch_id)
        or not non_empty(view.implementation_revision)
        or type(view.lives) ~= "table"
        or type(view.observer_pairs) ~= "table"
        or type(view.evidence_records) ~= "table"
        or type(view.harness_evidence) ~= "table" then
        return nil, case_error("case_corpus_view_invalid")
    end
    return true
end

local function resolve_life(
    view, life_id, expected_case, target_epoch_required, cache
)
    local life = view.lives[life_id]
    if type(life) ~= "table" or life.life_id ~= life_id
        or not tagged_hash(life.evidence_epoch_id)
        or life.physics_epoch_id ~= view.target_physics_epoch_id
        or life.implementation_revision ~= view.implementation_revision
        or life.corpus_layer ~= "L0"
        or (target_epoch_required
            and life.evidence_epoch_id ~= view.target_evidence_epoch_id)
        or (expected_case ~= nil and life.case_id ~= expected_case) then
        return nil, case_error("case_life_unresolved", {ref = life_id})
    end
    cache = cache or {projections = {}}
    cache.projections = cache.projections or {}
    local projection_id = life.projection and life.projection.projection_id
    if not cache.projections[projection_id] then
        local projection_ok, projection_err = life_projection.verify(life.projection)
        if not projection_ok then
            return nil, case_error("case_life_projection_invalid", {
                ref = life_id,
                detail = projection_err and projection_err.code,
            })
        end
        cache.projections[projection_id] = true
    end
    return life
end

local function resolve_pair(view, pair_ref, cache)
    local pair = view.observer_pairs[pair_ref]
    if type(pair) ~= "table" or pair.pair_id ~= pair_ref
        or (pair.status ~= "green" and pair.status ~= "red")
        or not non_empty(pair.enabled_life_id)
        or not non_empty(pair.disabled_life_id) then
        return nil, case_error("case_observer_pair_unresolved", {ref = pair_ref})
    end
    local enabled, enabled_err = resolve_life(
        view, pair.enabled_life_id, nil, false, cache
    )
    if not enabled then return nil, enabled_err end
    local disabled, disabled_err = resolve_life(
        view, pair.disabled_life_id, nil, false, cache
    )
    if not disabled then return nil, disabled_err end
    if pair.physics_epoch_id ~= view.target_physics_epoch_id
        or (enabled.evidence_epoch_id ~= view.target_evidence_epoch_id
            and disabled.evidence_epoch_id ~= view.target_evidence_epoch_id) then
        return nil, case_error("case_observer_pair_target_mismatch", {
            ref = pair_ref,
        })
    end
    return pair
end

local function resolve_evidence(view, ref, case_id)
    local harness = view.harness_evidence[ref]
    if harness then
        local ok, err = cases.verify_harness_evidence(harness)
        if not ok or harness.case_id ~= case_id
            or harness.source_revision ~= view.implementation_revision then
            return nil, err or case_error("case_harness_evidence_mismatch", {ref = ref})
        end
        return harness, "harness"
    end
    local evidence = view.evidence_records[ref]
    if type(evidence) ~= "table"
        or (evidence.corpus_layer ~= nil and evidence.corpus_layer ~= "L0") then
        return nil, case_error("case_evidence_ref_unresolved", {ref = ref})
    end
    return evidence, "evidence"
end

local function normalize_control_slot(slot)
    if not exact_keys(slot or {}, {}, {
        life_ids = true,
        observer_pair_refs = true,
        evidence_refs = true,
    }) then
        return nil
    end
    local result = {
        life_ids = sorted_unique(slot.life_ids or {}, true),
        observer_pair_refs = sorted_unique(slot.observer_pair_refs or {}, true),
        evidence_refs = sorted_unique(slot.evidence_refs or {}, true),
    }
    if not result.life_ids or not result.observer_pair_refs or not result.evidence_refs then
        return nil
    end
    return result
end

local function append_all(target, values)
    for _, value in ipairs(values or {}) do target[#target + 1] = value end
end

local function make_case_record(definition, view, status, refs)
    local record = {
        kind = "edge_case_evidence",
        protocol_version = cases.evidence_protocol_version,
        case_evidence_id = nil,
        case_manifest_id = current_manifest().manifest_id,
        case_id = definition.case_id,
        layer = definition.layer,
        target_evidence_epoch_id = view.target_evidence_epoch_id,
        implementation_revision = view.implementation_revision,
        status = status,
        life_ids = canonical_unique(refs.life_ids),
        control_life_ids = canonical_unique(refs.control_life_ids),
        observer_pair_refs = canonical_unique(refs.observer_pair_refs),
        evidence_refs = canonical_unique(refs.evidence_refs),
        evaluator_id = definition.evaluator_id,
        evaluator_version = definition.evaluator_version,
        verifier_ref = definition.evaluator_id,
        evaluation_truth_status = definition.layer == "L0"
            and "runtime_confirmed" or "document_decision",
        event_truth_status = "runtime_confirmed",
    }
    record.case_evidence_id = assert(tagged_digest(case_seed(record)))
    return record
end

function cases.evaluate_l0(case_id, view, evidence_input)
    local definition = definition_by_id[case_id]
    if not definition or definition.layer ~= "L0" then
        return nil, case_error("case_id_unknown", {case_id = case_id})
    end
    local view_ok, view_err = validate_view(view)
    if not view_ok then return nil, view_err end
    if not exact_keys(evidence_input or {}, {}, {
        life_ids = true,
        controls = true,
        observer_pair_refs = true,
        evidence_refs = true,
        family_pairs = true,
    }) then
        return nil, case_error("case_evidence_input_invalid")
    end

    local primary_ids = sorted_unique(evidence_input.life_ids or {}, true)
    local pair_refs = sorted_unique(evidence_input.observer_pair_refs or {}, true)
    local evidence_refs = sorted_unique(evidence_input.evidence_refs or {}, true)
    if not primary_ids or not pair_refs or not evidence_refs then
        return nil, case_error("case_candidate_refs_invalid")
    end
    local refs = {
        life_ids = primary_ids,
        control_life_ids = {},
        observer_pair_refs = pair_refs,
        evidence_refs = evidence_refs,
    }
    local resolution_cache = {projections = {}}
    local status = "green"
    local primary_lives = {}
    for _, life_id in ipairs(primary_ids) do
        local life, life_err = resolve_life(
            view, life_id, case_id, true, resolution_cache
        )
        if not life then return nil, life_err end
        primary_lives[#primary_lives + 1] = life
    end

    for _, pair_ref in ipairs(pair_refs) do
        local pair, pair_err = resolve_pair(view, pair_ref, resolution_cache)
        if not pair then return nil, pair_err end
        if pair.status == "red" then status = "red" end
    end
    for _, ref in ipairs(evidence_refs) do
        local resolved, resolve_err = resolve_evidence(view, ref, case_id)
        if not resolved then return nil, resolve_err end
    end

    local controls = evidence_input.controls or {}
    if type(controls) ~= "table" then
        return nil, case_error("case_controls_invalid")
    end
    local required_controls = {}
    for _, required_kind in ipairs(definition.required_control_kinds) do
        required_controls[required_kind] = true
    end
    for key in pairs(controls) do
        if not control_kinds[key] or not required_controls[key] then
            return nil, case_error("case_control_kind_unknown", {control_kind = key})
        end
    end
    for _, required_kind in ipairs(definition.required_control_kinds) do
        local slot = normalize_control_slot(controls[required_kind])
        if not slot then
            status = status == "red" and "red" or "blocked"
        else
            if #slot.life_ids + #slot.observer_pair_refs + #slot.evidence_refs == 0 then
                status = status == "red" and "red" or "blocked"
            end
            local expected_kind = control_reference_kind[required_kind]
            local wrong_shape = expected_kind == "life"
                    and (#slot.observer_pair_refs > 0 or #slot.evidence_refs > 0)
                or expected_kind == "observer_pair"
                    and (#slot.life_ids > 0 or #slot.evidence_refs > 0)
                or expected_kind == "evidence"
                    and (#slot.life_ids > 0 or #slot.observer_pair_refs > 0)
            if wrong_shape then
                return nil, case_error("case_control_reference_kind_invalid", {
                    control_kind = required_kind,
                })
            end
            for _, life_id in ipairs(slot.life_ids) do
                local life, life_err = resolve_life(
                    view, life_id, nil, true, resolution_cache
                )
                if not life then return nil, life_err end
                refs.control_life_ids[#refs.control_life_ids + 1] = life_id
            end
            for _, pair_ref in ipairs(slot.observer_pair_refs) do
                local pair, pair_err = resolve_pair(
                    view, pair_ref, resolution_cache
                )
                if not pair then return nil, pair_err end
                refs.observer_pair_refs[#refs.observer_pair_refs + 1] = pair_ref
                if pair.status == "red" then status = "red" end
            end
            for _, ref in ipairs(slot.evidence_refs) do
                local resolved, resolve_err = resolve_evidence(view, ref, case_id)
                if not resolved then return nil, resolve_err end
                refs.evidence_refs[#refs.evidence_refs + 1] = ref
            end
        end
    end

    if definition.observer_pair_required and #refs.observer_pair_refs == 0 then
        status = status == "red" and "red" or "blocked"
    end
    if definition.observer_pair_required and #primary_ids > 0 then
        local primary_set = {}
        for _, life_id in ipairs(primary_ids) do primary_set[life_id] = true end
        local connected = false
        for _, pair_ref in ipairs(refs.observer_pair_refs) do
            local pair = assert(view.observer_pairs[pair_ref])
            if primary_set[pair.enabled_life_id]
                or primary_set[pair.disabled_life_id] then
                connected = true
                break
            end
        end
        if not connected then status = "red" end
    end

    if case_id == "P12" then
        if #primary_ids > 0 then
            return nil, case_error("case_family_pair_has_synthetic_life")
        end
        local supplied = evidence_input.family_pairs
        if type(supplied) ~= "table" then
            status = "blocked"
        else
            local family_set = {}
            for _, family_id in ipairs(family_case_ids) do family_set[family_id] = true end
            for supplied_id in pairs(supplied) do
                if not family_set[supplied_id] then
                    return nil, case_error("case_family_pair_unknown", {
                        case_id = supplied_id,
                    })
                end
            end
            for _, family_id in ipairs(family_case_ids) do
                local pair_ref = supplied[family_id]
                if not non_empty(pair_ref) then
                    status = status == "red" and "red" or "blocked"
                else
                    local pair, pair_err = resolve_pair(
                        view, pair_ref, resolution_cache
                    )
                    if not pair then return nil, pair_err end
                    local enabled, enabled_err = resolve_life(
                        view, pair.enabled_life_id, family_id, false,
                        resolution_cache
                    )
                    if not enabled then return nil, enabled_err end
                    local disabled, disabled_err = resolve_life(
                        view, pair.disabled_life_id, family_id, false,
                        resolution_cache
                    )
                    if not disabled then return nil, disabled_err end
                    refs.observer_pair_refs[#refs.observer_pair_refs + 1] = pair_ref
                    if pair.status == "red" then status = "red" end
                end
            end
        end
    elseif case_id == "P13" then
        if #primary_ids > 0 or #refs.observer_pair_refs > 0 then
            return nil, case_error("harness_case_cannot_invent_life_pair")
        end
        local found_harness = false
        for _, ref in ipairs(refs.evidence_refs) do
            local evidence, kind = resolve_evidence(view, ref, case_id)
            if not evidence then return nil, kind end
            if kind == "harness" then
                found_harness = true
                local matching, matching_err = resolve_life(
                    view, evidence.matching_valid_life_id, nil, true,
                    resolution_cache
                )
                if not matching then return nil, matching_err end
                refs.control_life_ids[#refs.control_life_ids + 1] =
                    evidence.matching_valid_life_id
            end
        end
        if not found_harness then status = "blocked" end
    else
        if #primary_lives == 0 then
            status = "blocked"
        else
            for _, life in ipairs(primary_lives) do
                if not semantic_l0(case_id, life) then status = "red" end
            end
        end
    end

    local record = make_case_record(definition, view, status, refs)
    local verified, verify_err = cases.verify_case_evidence(record, current_manifest())
    if not verified then return nil, verify_err end
    return copy_value(record)
end

return cases
