local digest = require("core.digest")
local json = require("core.json")
local edge_catalog = require("runtime.edge_catalog")
local edge_stats = require("runtime.edge_stats_v3")
local life_projection = require("runtime.edge_life_projection")
local case_manifest = require("runtime.edge_case_manifest")

local corpus = {
    protocol_version = "edge-evidence-corpus.v1",
    target_decision_protocol_version = "authority-target-decision.v0",
    closure_protocol_version = "edge-evidence-corpus.v1",
}

local default_bounds = {
    max_lives = 1024,
    max_observer_pairs = 1024,
    max_case_records = 4096,
    max_documents = 256,
    max_harness_records = 256,
}

local bound_names = {
    "max_lives",
    "max_observer_pairs",
    "max_case_records",
    "max_documents",
    "max_harness_records",
}

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

local function replace_contents(target, source)
    for key in pairs(target) do target[key] = nil end
    for key, value in pairs(source) do target[key] = value end
end

local function same_value(left, right)
    local left_ok, left_encoded = pcall(json.encode, left)
    local right_ok, right_encoded = pcall(json.encode, right)
    return left_ok and right_ok and left_encoded == right_encoded
end

local function corpus_error(code, extra)
    local value = {
        class = "instrument_contract",
        code = code,
        stage = "edge_corpus",
    }
    for key, child in pairs(extra or {}) do value[key] = copy_value(child) end
    return value
end

local function non_empty(value)
    return type(value) == "string" and value ~= ""
end

local function non_negative_integer(value)
    return type(value) == "number"
        and value >= 0
        and value % 1 == 0
        and value < math.huge
end

local function positive_integer(value)
    return non_negative_integer(value) and value > 0
end

local function tagged_hash(value)
    return type(value) == "string"
        and #value == 71
        and value:sub(1, 7) == "sha256:"
        and value:sub(8):match("^[0-9a-f]+$") ~= nil
end

local function tagged_digest(value)
    local value_digest, value_err = digest.record(value)
    if not value_digest then
        return nil, corpus_error("corpus_digest_failed", {
            detail = tostring(value_err),
        })
    end
    return "sha256:" .. value_digest
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

local function count_map(value)
    local count = 0
    for _ in pairs(value or {}) do count = count + 1 end
    return count
end

local function sorted_unique(values, allow_empty)
    if type(values) ~= "table" then return nil end
    local result = {}
    local seen = {}
    local key_count = 0
    for key in pairs(values) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0
            or key > #values then
            return nil
        end
        key_count = key_count + 1
    end
    if key_count ~= #values then return nil end
    for _, value in ipairs(values) do
        if not non_empty(value) or seen[value] then return nil end
        seen[value] = true
        result[#result + 1] = value
    end
    if not allow_empty and #result == 0 then return nil end
    table.sort(result)
    return result
end

local function append_unique(target, value)
    for _, existing in ipairs(target) do
        if existing == value then return end
    end
    target[#target + 1] = value
    table.sort(target)
end

local function normalize_bounds(configured)
    if configured ~= nil and type(configured) ~= "table" then
        return nil, corpus_error("corpus_bounds_invalid")
    end
    configured = configured or {}
    local allowed = {}
    for _, name in ipairs(bound_names) do allowed[name] = true end
    for key in pairs(configured) do
        if not allowed[key] then
            return nil, corpus_error("corpus_bounds_invalid", {field = key})
        end
    end
    local result = {
        calibration_status = next(configured) == nil
            and "unmeasured_safety_default"
            or "explicit_unmeasured_override",
    }
    for _, name in ipairs(bound_names) do
        result[name] = configured[name] or default_bounds[name]
        if not positive_integer(result[name]) then
            return nil, corpus_error("corpus_bounds_invalid", {field = name})
        end
    end
    return result
end

local function verify_bounds(value)
    local required = {calibration_status = true}
    for _, name in ipairs(bound_names) do required[name] = true end
    if not exact_keys(value, required)
        or (value.calibration_status ~= "unmeasured_safety_default"
            and value.calibration_status ~= "explicit_unmeasured_override") then
        return false
    end
    for _, name in ipairs(bound_names) do
        if not positive_integer(value[name]) then return false end
    end
    return true
end

local function verify_provenance(value)
    if not exact_keys(value, {
        source_revision = true,
        worktree_state = true,
        artifact_digest = true,
        event_truth_status = true,
        content_truth_status = true,
        verifier_ref = true,
    }, {
        source_revision = true,
        artifact_digest = true,
        verifier_ref = true,
    }) or (value.source_revision ~= nil and not non_empty(value.source_revision))
        or (value.worktree_state ~= "clean"
            and value.worktree_state ~= "dirty"
            and value.worktree_state ~= "unknown")
        or (value.artifact_digest ~= nil and not tagged_hash(value.artifact_digest))
        or value.event_truth_status ~= "runtime_confirmed"
        or (value.content_truth_status ~= "unknown"
            and value.content_truth_status ~= "semantic_proposal"
            and value.content_truth_status ~= "runtime_confirmed")
        or (value.verifier_ref ~= nil and not non_empty(value.verifier_ref)) then
        return nil, corpus_error("implementation_provenance_invalid")
    end
    return true
end

local function provenance_green(value, revision)
    local ok = verify_provenance(value)
    return ok ~= nil
        and value.source_revision == revision
        and value.worktree_state == "clean"
        and value.content_truth_status == "runtime_confirmed"
        and non_empty(value.verifier_ref)
end

local function manifest_definition(manifest, case_id)
    for _, list in ipairs({manifest.required_l0, manifest.required_l1}) do
        for _, definition in ipairs(list) do
            if definition.case_id == case_id then return definition end
        end
    end
    return nil
end

local function find_life(record, life_id)
    for epoch_id, bucket in pairs(record.buckets or {}) do
        local source = bucket.source_lives and bucket.source_lives[life_id]
        if source then return source, bucket, epoch_id end
    end
    return nil
end

local function evidence_run_exists(record, evidence_run_id)
    for _, bucket in pairs(record.buckets or {}) do
        for _, source in pairs(bucket.source_lives or {}) do
            if source.evidence_run_id == evidence_run_id then return true end
        end
    end
    return false
end

local function projection_matches_source(projected, source)
    local ok, err = life_projection.verify(projected)
    if not ok then return nil, err end
    local identity = projected.exact_components.identity_and_work_contract
    local packet = identity and identity.packet
    local mode = packet and packet.regime and packet.regime.work
        and packet.regime.work.mode
    if projected.life_id ~= source.life_id
        or type(packet) ~= "table"
        or packet.id ~= source.packet_id
        or packet.lineage_id ~= source.lineage_id
        or packet.generation ~= source.generation
        or packet.session_id ~= source.session_id
        or mode ~= source.work_mode then
        return nil, corpus_error("life_projection_source_mismatch", {
            life_id = source.life_id,
        })
    end
    return true
end

local function extract_ledger(runner_result)
    if type(runner_result) ~= "table" then
        return nil, corpus_error("runner_result_required")
    end
    local found
    for _, key in ipairs({"edge_evidence_v3", "edge_stats_v3", "edge_evidence"}) do
        local candidate = runner_result[key]
        if type(candidate) == "table"
            and candidate.protocol_version == edge_stats.protocol_version then
            if found and not same_value(found, candidate) then
                return nil, corpus_error("runner_edge_stats_ambiguous")
            end
            found = candidate
        end
    end
    if not found then return nil, corpus_error("runner_edge_stats_missing") end
    local snapshot, snapshot_err = edge_stats.summary(found)
    if not snapshot then return nil, snapshot_err end
    return snapshot
end

local function one_life_source(ledger)
    local source
    for _, candidate in pairs(ledger.source_lives or {}) do
        if source then return nil, corpus_error("runner_life_count_invalid") end
        source = candidate
    end
    if not source then return nil, corpus_error("runner_life_count_invalid") end
    return source
end

local function verify_source_case(manifest, source)
    if source.corpus_layer == "L0" or source.corpus_layer == "L1" then
        local definition = manifest_definition(manifest, source.case_id)
        if not definition or definition.layer ~= source.corpus_layer then
            return nil, corpus_error("life_case_manifest_mismatch", {
                life_id = source.life_id,
            })
        end
    end
    return true
end

local function source_by_original(bucket, life_id, original_id)
    for _, evidence in pairs(bucket.evidence_records or {}) do
        if evidence.life_id == life_id
            and evidence.original_source_id == original_id then
            return evidence.source_record
        end
    end
    return nil
end

local function corpus_evidence_resolves(record, ref)
    for _, bucket in pairs(record.buckets or {}) do
        if bucket.evidence_records[ref] then return true end
        for _, evidence in pairs(bucket.evidence_records) do
            if evidence.original_source_id == ref then return true end
        end
    end
    return false
end

local function normalized_life_ledger(bucket, life_id)
    local routes = {}
    for _, route in pairs(bucket.routes or {}) do
        if route.life_id == life_id then
            local selection = source_by_original(
                bucket, life_id, route.selection_ref
            ) or {}
            local decision = route.credit_decision_ref
                and source_by_original(bucket, life_id, route.credit_decision_ref)
                or nil
            local arrival = route.arrival_ref
                and source_by_original(bucket, life_id, route.arrival_ref)
                or nil
            local failure = route.failure_ref
                and source_by_original(bucket, life_id, route.failure_ref)
                or nil
            local eligibility = selection.eligibility
            routes[#routes + 1] = {
                route_ordinal = route.route_ordinal,
                edge_id = route.edge_id,
                direction = route.direction,
                phase_status = route.phase_status,
                route_authority = selection.route_authority,
                classification_status = selection.classification_status,
                eligibility_status = eligibility and eligibility.status or "unclassified",
                eligibility_reasons = copy_value(eligibility and eligibility.reasons or {}),
                credit_status = decision and decision.status or "none",
                credit_reasons = copy_value(decision and decision.reasons or {}),
                arrival_kind = arrival and arrival.payload_kind or nil,
                failure_kind = failure and failure.failure_kind or nil,
                authority_tainted = route.authority_taint_ref ~= nil,
            }
        end
    end
    table.sort(routes, function(left, right)
        if left.route_ordinal ~= right.route_ordinal then
            return left.route_ordinal < right.route_ordinal
        end
        return left.direction < right.direction
    end)
    return {
        kind = "observer_neutral_edge_ledger",
        protocol_version = corpus.protocol_version,
        routes = routes,
    }
end

local function eligible_directions(bucket, life_id)
    local result = {}
    for _, route in pairs(bucket.routes or {}) do
        if route.life_id == life_id and route.credit_decision_ref then
            local decision = source_by_original(
                bucket, life_id, route.credit_decision_ref
            )
            if decision and decision.status == "credited" then
                append_unique(result, route.direction)
            end
        end
    end
    return result
end

local function observer_pair_seed(record)
    local seed = copy_value(record)
    seed.pair_id = nil
    return seed
end

local function observer_equality_seed(
    record, enabled_neutral_digest, disabled_neutral_digest
)
    return {
        comparison_mode = record.comparison_mode,
        physics_epoch_id = record.physics_epoch_id,
        enabled_projection_ref = record.enabled_projection_ref,
        disabled_projection_ref = record.disabled_projection_ref,
        enabled_observer_neutral_digest = enabled_neutral_digest,
        disabled_observer_neutral_digest = disabled_neutral_digest,
        ledger_equality_digest = record.ledger_equality_digest,
        status = record.status,
        differing_fields = copy_value(record.differing_fields),
    }
end

local function compute_observer_pair(record, enabled_life_id, disabled_life_id)
    if enabled_life_id == disabled_life_id then
        return nil, corpus_error("observer_pair_life_reused")
    end
    local enabled, enabled_bucket, enabled_epoch = find_life(record, enabled_life_id)
    local disabled, disabled_bucket, disabled_epoch = find_life(record, disabled_life_id)
    if not enabled or not disabled then
        return nil, corpus_error("observer_pair_life_missing")
    end
    local enabled_provenance = record.life_provenance[enabled_life_id]
    local disabled_provenance = record.life_provenance[disabled_life_id]
    local enabled_projection = record.life_projections[enabled_life_id]
    local disabled_projection = record.life_projections[disabled_life_id]
    if enabled.case_id ~= disabled.case_id
        or enabled.prompt_hash ~= disabled.prompt_hash
        or enabled.work_mode ~= disabled.work_mode
        or enabled.packet_id ~= disabled.packet_id
        or enabled.lineage_id ~= disabled.lineage_id
        or enabled.generation ~= disabled.generation
        or enabled.session_id ~= disabled.session_id
        or enabled.evidence_run_id == disabled.evidence_run_id
        or enabled_provenance.source_revision
            ~= disabled_provenance.source_revision then
        return nil, corpus_error("observer_pair_identity_mismatch")
    end
    local enabled_epoch_record = enabled_bucket.authority_epoch
    local disabled_epoch_record = disabled_bucket.authority_epoch
    local enabled_instrument = enabled_epoch_record.instrumentation
    local disabled_instrument = disabled_epoch_record.instrumentation
    local enabled_mode = enabled_epoch_record.configured.router_mode
    local disabled_mode = disabled_epoch_record.configured.router_mode
    local valid_mode_pair = enabled_mode == "tree" and disabled_mode == "tree"
        or enabled_mode == "shadow" and disabled_mode == "legacy"
    if enabled_instrument.observer_enabled ~= true
        or disabled_instrument.observer_enabled ~= false
        or not valid_mode_pair
        or enabled_instrument.edge_stats_protocol
            ~= disabled_instrument.edge_stats_protocol
        or not same_value(enabled_instrument.bounds, disabled_instrument.bounds) then
        return nil, corpus_error("observer_pair_roles_invalid")
    end
    local enabled_identity = enabled_projection.exact_components
        .identity_and_work_contract.packet
    local disabled_identity = disabled_projection.exact_components
        .identity_and_work_contract.packet
    for _, key in ipairs({
        "process_contract_id", "work_context", "stage_id", "repository_id",
        "qa_contract_id", "birth_kind", "parent_id", "parent_corpse_id",
        "carrier_id",
    }) do
        if enabled_identity[key] ~= disabled_identity[key] then
            return nil, corpus_error("observer_pair_work_identity_mismatch", {
                field = key,
            })
        end
    end

    local body_equal, body_differences = life_projection.same_observer_neutral(
        enabled_projection,
        disabled_projection
    )
    if body_equal == nil then
        return nil, body_differences
    end
    local enabled_ledger = normalized_life_ledger(enabled_bucket, enabled_life_id)
    local disabled_ledger = normalized_life_ledger(disabled_bucket, disabled_life_id)
    local ledger_equal = same_value(enabled_ledger, disabled_ledger)
    local physics_equal = enabled_bucket.physics_epoch_id
        == disabled_bucket.physics_epoch_id
    local ledger_digest, ledger_err = tagged_digest({
        enabled = enabled_ledger,
        disabled = disabled_ledger,
        equal = ledger_equal,
    })
    if not ledger_digest then return nil, ledger_err end
    local differences = sorted_unique(body_differences or {}, true) or {}
    if not physics_equal then append_unique(differences, "physics_epoch_id") end
    if not ledger_equal then append_unique(differences, "edge_ledger") end
    local pair = {
        kind = "observer_ablation_pair",
        protocol_version = corpus.protocol_version,
        pair_id = nil,
        enabled_life_id = enabled_life_id,
        disabled_life_id = disabled_life_id,
        enabled_projection_ref = enabled_projection.projection_id,
        disabled_projection_ref = disabled_projection.projection_id,
        comparison_mode = "observer_neutral",
        physics_epoch_id = enabled_bucket.physics_epoch_id,
        enabled_evidence_epoch_id = enabled_epoch,
        disabled_evidence_epoch_id = disabled_epoch,
        equality_digest = nil,
        ledger_equality_digest = ledger_digest,
        status = body_equal and ledger_equal and physics_equal and "green" or "red",
        differing_fields = differences,
        event_truth_status = "runtime_confirmed",
    }
    pair.equality_digest = assert(tagged_digest(observer_equality_seed(
        pair,
        enabled_projection.observer_neutral_digest,
        disabled_projection.observer_neutral_digest
    )))
    pair.pair_id = assert(tagged_digest(observer_pair_seed(pair)))
    return pair
end

local function verify_observer_pair(record, pair)
    if not exact_keys(pair, {
        kind = true,
        protocol_version = true,
        pair_id = true,
        enabled_life_id = true,
        disabled_life_id = true,
        enabled_projection_ref = true,
        disabled_projection_ref = true,
        comparison_mode = true,
        physics_epoch_id = true,
        enabled_evidence_epoch_id = true,
        disabled_evidence_epoch_id = true,
        equality_digest = true,
        ledger_equality_digest = true,
        status = true,
        differing_fields = true,
        event_truth_status = true,
    }) then
        return nil, corpus_error("observer_pair_shape_invalid")
    end
    if pair.kind ~= "observer_ablation_pair"
        or pair.protocol_version ~= corpus.protocol_version
        or pair.comparison_mode ~= "observer_neutral"
        or (pair.status ~= "green" and pair.status ~= "red")
        or pair.event_truth_status ~= "runtime_confirmed" then
        return nil, corpus_error("observer_pair_literal_invalid")
    end
    for _, field in ipairs({
        "pair_id", "enabled_projection_ref", "disabled_projection_ref",
        "physics_epoch_id", "enabled_evidence_epoch_id",
        "disabled_evidence_epoch_id", "equality_digest",
        "ledger_equality_digest",
    }) do
        if not tagged_hash(pair[field]) then
            return nil, corpus_error("observer_pair_identity_invalid", {
                field = field,
            })
        end
    end
    local canonical_differences = sorted_unique(pair.differing_fields, true)
    if not canonical_differences
        or not same_value(pair.differing_fields, canonical_differences) then
        return nil, corpus_error("observer_pair_differences_invalid")
    end
    local expected, expected_err = compute_observer_pair(
        record, pair.enabled_life_id, pair.disabled_life_id
    )
    if not expected then return nil, expected_err end
    if not same_value(expected, pair) then
        return nil, corpus_error("observer_pair_evidence_mismatch", {
            pair_id = pair.pair_id,
        })
    end
    return true
end

local function target_decision_seed(record)
    local seed = copy_value(record)
    seed.decision_id = nil
    return seed
end

local function verify_target_decision(record, decision, bucket)
    if not exact_keys(decision, {
        kind = true,
        protocol_version = true,
        decision_id = true,
        corpus_id = true,
        target_physics_epoch_id = true,
        target_evidence_epoch_id = true,
        authority_surface_id = true,
        rationale_ref = true,
        decision_truth_status = true,
    }) or decision.kind ~= "authority_target_decision"
        or decision.protocol_version ~= corpus.target_decision_protocol_version
        or not tagged_hash(decision.decision_id)
        or decision.corpus_id ~= record.corpus_id
        or decision.target_physics_epoch_id ~= bucket.physics_epoch_id
        or decision.target_evidence_epoch_id ~= bucket.evidence_epoch_id
        or not non_empty(decision.rationale_ref)
        or decision.decision_truth_status ~= "document_decision" then
        return nil, corpus_error("target_epoch_decision_invalid")
    end
    local surface = assert(edge_catalog.authority_surface())
    local expected_id = tagged_digest(target_decision_seed(decision))
    if decision.authority_surface_id ~= surface.surface_id
        or decision.decision_id ~= expected_id then
        return nil, corpus_error("target_epoch_decision_invalid")
    end
    return true
end

local function life_case_view(record, target_epoch_id, revision)
    local target_bucket = record.buckets[target_epoch_id]
    local view = {
        kind = "edge_case_corpus_view",
        protocol_version = case_manifest.view_protocol_version,
        target_evidence_epoch_id = target_epoch_id,
        target_physics_epoch_id = target_bucket.physics_epoch_id,
        implementation_revision = revision,
        lives = {},
        observer_pairs = {},
        evidence_records = {},
        harness_evidence = copy_value(record.harness_evidence),
    }
    for _, bucket in pairs(record.buckets) do
        if bucket.physics_epoch_id == target_bucket.physics_epoch_id then
            for life_id, source in pairs(bucket.source_lives) do
                local provenance = record.life_provenance[life_id]
                view.lives[life_id] = {
                    life_id = life_id,
                    case_id = source.case_id,
                    corpus_layer = source.corpus_layer,
                    evidence_epoch_id = source.evidence_epoch_id
                        or bucket.evidence_epoch_id,
                    physics_epoch_id = bucket.physics_epoch_id,
                    implementation_revision = provenance.source_revision,
                    projection = copy_value(record.life_projections[life_id]),
                    eligible_directions = eligible_directions(bucket, life_id),
                }
            end
            for evidence_ref, evidence in pairs(bucket.evidence_records) do
                local source = bucket.source_lives[evidence.life_id]
                local exposed = copy_value(evidence)
                exposed.corpus_layer = source and source.corpus_layer or nil
                view.evidence_records[evidence_ref] = exposed
                view.evidence_records[evidence.original_source_id] = exposed
            end
        end
    end
    for _, pair in ipairs(record.observer_pairs) do
        view.observer_pairs[pair.pair_id] = copy_value(pair)
    end
    return view
end

local function referenced_life_ids(record, evidence_input)
    local ids = {}
    local function add(value)
        if non_empty(value) then ids[value] = true end
    end
    local life_inputs = type(evidence_input.life_ids) == "table"
        and evidence_input.life_ids or {}
    local controls = type(evidence_input.controls) == "table"
        and evidence_input.controls or {}
    local pair_inputs = type(evidence_input.observer_pair_refs) == "table"
        and evidence_input.observer_pair_refs or {}
    local family_inputs = type(evidence_input.family_pairs) == "table"
        and evidence_input.family_pairs or {}
    local evidence_inputs = type(evidence_input.evidence_refs) == "table"
        and evidence_input.evidence_refs or {}
    for _, life_id in ipairs(life_inputs) do add(life_id) end
    for _, slot in pairs(controls) do
        slot = type(slot) == "table" and slot or {}
        for _, life_id in ipairs(type(slot.life_ids) == "table"
            and slot.life_ids or {}) do add(life_id) end
        for _, pair_id in ipairs(type(slot.observer_pair_refs) == "table"
            and slot.observer_pair_refs or {}) do
            for _, pair in ipairs(record.observer_pairs) do
                if pair.pair_id == pair_id then
                    add(pair.enabled_life_id)
                    add(pair.disabled_life_id)
                end
            end
        end
        for _, evidence_ref in ipairs(type(slot.evidence_refs) == "table"
            and slot.evidence_refs or {}) do
            local harness = record.harness_evidence[evidence_ref]
            if harness then add(harness.matching_valid_life_id) end
        end
    end
    for _, pair_id in ipairs(pair_inputs) do
        for _, pair in ipairs(record.observer_pairs) do
            if pair.pair_id == pair_id then
                add(pair.enabled_life_id)
                add(pair.disabled_life_id)
            end
        end
    end
    for _, pair_id in pairs(family_inputs) do
        for _, pair in ipairs(record.observer_pairs) do
            if pair.pair_id == pair_id then
                add(pair.enabled_life_id)
                add(pair.disabled_life_id)
            end
        end
    end
    for _, evidence_ref in ipairs(evidence_inputs) do
        local harness = record.harness_evidence[evidence_ref]
        if harness then add(harness.matching_valid_life_id) end
        for _, bucket in pairs(record.buckets) do
            local evidence = bucket.evidence_records[evidence_ref]
            if evidence then add(evidence.life_id) end
        end
    end
    local result = {}
    for life_id in pairs(ids) do result[#result + 1] = life_id end
    table.sort(result)
    return result
end

local function infer_case_target(record, case_id, evidence_input)
    local ids = referenced_life_ids(record, evidence_input)
    if #ids == 0 then return nil, corpus_error("case_target_unresolved") end
    local revision
    local physics_id
    local candidate_epochs = {}
    local primary_epochs = {}
    for _, life_id in ipairs(ids) do
        local source, bucket = find_life(record, life_id)
        if not source then return nil, corpus_error("case_life_unresolved") end
        local provenance = record.life_provenance[life_id]
        revision = revision or provenance.source_revision
        physics_id = physics_id or bucket.physics_epoch_id
        if provenance.source_revision ~= revision
            or bucket.physics_epoch_id ~= physics_id then
            return nil, corpus_error("case_target_ambiguous")
        end
        candidate_epochs[bucket.evidence_epoch_id] =
            (candidate_epochs[bucket.evidence_epoch_id] or 0) + 1
    end
    for _, life_id in ipairs(type(evidence_input.life_ids) == "table"
        and evidence_input.life_ids or {}) do
        local _, _, epoch_id = find_life(record, life_id)
        if epoch_id then primary_epochs[epoch_id] = true end
    end
    local target_epoch
    if next(primary_epochs) then
        for epoch_id in pairs(primary_epochs) do
            if target_epoch then return nil, corpus_error("case_target_ambiguous") end
            target_epoch = epoch_id
        end
    elseif case_id == "P12" then
        local intersection
        for _, pair_id in pairs(type(evidence_input.family_pairs) == "table"
            and evidence_input.family_pairs or {}) do
            local pair
            for _, candidate in ipairs(record.observer_pairs) do
                if candidate.pair_id == pair_id then pair = candidate break end
            end
            if pair then
                local epochs = {
                    [pair.enabled_evidence_epoch_id] = true,
                    [pair.disabled_evidence_epoch_id] = true,
                }
                if intersection == nil then
                    intersection = epochs
                else
                    for epoch_id in pairs(intersection) do
                        if not epochs[epoch_id] then intersection[epoch_id] = nil end
                    end
                end
            end
        end
        for epoch_id in pairs(intersection or {}) do
            if target_epoch then return nil, corpus_error("case_target_ambiguous") end
            target_epoch = epoch_id
        end
    else
        for epoch_id in pairs(candidate_epochs) do
            if target_epoch then return nil, corpus_error("case_target_ambiguous") end
            target_epoch = epoch_id
        end
    end
    if not target_epoch or not non_empty(revision) then
        return nil, corpus_error("case_target_unresolved")
    end
    return target_epoch, revision
end

local function case_evidence_seed(value)
    local seed = copy_value(value)
    seed.case_evidence_id = nil
    return seed
end

function corpus.new(config)
    if not exact_keys(config or {}, {
        corpus_id = true,
        authority_claim = true,
    }, {bounds = true}) or not non_empty(config.corpus_id)
        or (config.authority_claim ~= "full_tree"
            and config.authority_claim ~= "diagnostic") then
        return nil, corpus_error("corpus_config_invalid")
    end
    local bounds, bounds_err = normalize_bounds(config.bounds)
    if not bounds then return nil, bounds_err end
    local record = {
        kind = "edge_evidence_corpus",
        protocol_version = corpus.protocol_version,
        corpus_id = config.corpus_id,
        authority_claim = config.authority_claim,
        bounds = bounds,
        buckets = {},
        life_provenance = {},
        life_projections = {},
        case_manifest = case_manifest.current(),
        case_evidence = {},
        case_documents = {},
        harness_evidence = {},
        observer_pairs = {},
        event_truth_status = "runtime_confirmed",
    }
    local ok, err = corpus.verify(record)
    if not ok then return nil, err end
    return record
end

function corpus.add_life(
    record, runner_result, projected_life, implementation_provenance
)
    local record_ok, record_err = corpus.verify(record)
    if not record_ok then return nil, record_err end
    if count_map(record.life_provenance) >= record.bounds.max_lives then
        return nil, corpus_error("corpus_max_lives_exceeded")
    end
    local ledger, ledger_err = extract_ledger(runner_result)
    if not ledger then return nil, ledger_err end
    if ledger.ledger_status ~= "valid" or not tagged_hash(ledger.evidence_epoch_id) then
        return nil, corpus_error("corpus_life_ledger_invalid")
    end
    local source, source_err = one_life_source(ledger)
    if not source then return nil, source_err end
    if not non_empty(source.evidence_run_id)
        or evidence_run_exists(record, source.evidence_run_id)
        or find_life(record, source.life_id) then
        return nil, corpus_error("corpus_evidence_run_reused", {
            life_id = source.life_id,
        })
    end
    local source_case_ok, source_case_err = verify_source_case(
        record.case_manifest, source
    )
    if not source_case_ok then return nil, source_case_err end
    local projection_ok, projection_err = projection_matches_source(
        projected_life, source
    )
    if not projection_ok then return nil, projection_err end
    local provenance_ok, provenance_err = verify_provenance(
        implementation_provenance
    )
    if not provenance_ok then return nil, provenance_err end

    local working = copy_value(record)
    local bucket = working.buckets[ledger.evidence_epoch_id]
    if bucket then
        local merged, merge_err = edge_stats.merge(bucket, ledger)
        if not merged then return nil, merge_err end
    else
        working.buckets[ledger.evidence_epoch_id] = copy_value(ledger)
    end
    working.life_provenance[source.life_id] = copy_value(implementation_provenance)
    working.life_projections[source.life_id] = assert(
        life_projection.snapshot(projected_life)
    )
    local working_ok, working_err = corpus.verify(working)
    if not working_ok then return nil, working_err end
    replace_contents(record, working)
    return true
end

function corpus.add_observer_pair(record, enabled_life_id, disabled_life_id)
    local ok, err = corpus.verify(record)
    if not ok then return nil, err end
    if #record.observer_pairs >= record.bounds.max_observer_pairs then
        return nil, corpus_error("corpus_max_observer_pairs_exceeded")
    end
    local pair, pair_err = compute_observer_pair(
        record, enabled_life_id, disabled_life_id
    )
    if not pair then return nil, pair_err end
    for _, existing in ipairs(record.observer_pairs) do
        if existing.pair_id == pair.pair_id then return copy_value(existing) end
    end
    local working = copy_value(record)
    working.observer_pairs[#working.observer_pairs + 1] = pair
    local working_ok, working_err = corpus.verify(working)
    if not working_ok then return nil, working_err end
    replace_contents(record, working)
    return copy_value(pair)
end

function corpus.add_harness_evidence(record, evidence)
    local ok, err = corpus.verify(record)
    if not ok then return nil, err end
    local evidence_ok, evidence_err = case_manifest.verify_harness_evidence(evidence)
    if not evidence_ok then return nil, evidence_err end
    local source = find_life(record, evidence.matching_valid_life_id)
    local provenance = record.life_provenance[evidence.matching_valid_life_id]
    if not source or not provenance
        or provenance.source_revision ~= evidence.source_revision then
        return nil, corpus_error("harness_matching_life_unresolved")
    end
    local existing = record.harness_evidence[evidence.boundary_evidence_id]
    if existing then
        if same_value(existing, evidence) then return copy_value(existing) end
        return nil, corpus_error("harness_evidence_conflict")
    end
    if count_map(record.harness_evidence) >= record.bounds.max_harness_records then
        return nil, corpus_error("corpus_max_harness_records_exceeded")
    end
    local working = copy_value(record)
    working.harness_evidence[evidence.boundary_evidence_id] = copy_value(evidence)
    local working_ok, working_err = corpus.verify(working)
    if not working_ok then return nil, working_err end
    replace_contents(record, working)
    return copy_value(evidence)
end

function corpus.evaluate_l0_case(record, case_id, evidence_input)
    local ok, err = corpus.verify(record)
    if not ok then return nil, err end
    if count_map(record.case_evidence) >= record.bounds.max_case_records then
        return nil, corpus_error("corpus_max_case_records_exceeded")
    end
    if type(evidence_input) ~= "table" then
        return nil, corpus_error("case_evidence_input_invalid")
    end
    local target_epoch, revision_or_err = infer_case_target(
        record, case_id, evidence_input
    )
    if not target_epoch then return nil, revision_or_err end
    local view = life_case_view(record, target_epoch, revision_or_err)
    local case_record, case_err = case_manifest.evaluate_l0(
        case_id, view, evidence_input
    )
    if not case_record then return nil, case_err end
    local existing = record.case_evidence[case_record.case_evidence_id]
    if existing then return copy_value(existing) end
    local working = copy_value(record)
    working.case_evidence[case_record.case_evidence_id] = case_record
    local working_ok, working_err = corpus.verify(working)
    if not working_ok then return nil, working_err end
    replace_contents(record, working)
    return copy_value(case_record)
end

function corpus.add_l1_document(record, document)
    local ok, err = corpus.verify(record)
    if not ok then return nil, err end
    local document_ok, document_err = case_manifest.verify_l1_document(document)
    if not document_ok then return nil, document_err end
    if count_map(record.case_documents) >= record.bounds.max_documents then
        return nil, corpus_error("corpus_max_documents_exceeded")
    end
    if count_map(record.case_evidence) >= record.bounds.max_case_records then
        return nil, corpus_error("corpus_max_case_records_exceeded")
    end
    local life_ids = {}
    local target_epoch
    for epoch_id, bucket in pairs(record.buckets) do
        for life_id, source in pairs(bucket.source_lives) do
            local provenance = record.life_provenance[life_id]
            if source.corpus_layer == "L1"
                and source.case_id == document.case_id
                and provenance.source_revision == document.source_revision then
                target_epoch = target_epoch or epoch_id
                if target_epoch ~= epoch_id then
                    return nil, corpus_error("l1_document_epoch_ambiguous")
                end
                life_ids[#life_ids + 1] = life_id
            end
        end
    end
    table.sort(life_ids)
    if not target_epoch or #life_ids == 0 then
        return nil, corpus_error("l1_document_life_missing")
    end
    local definition = manifest_definition(record.case_manifest, document.case_id)
    local case_record = {
        kind = "edge_case_evidence",
        protocol_version = case_manifest.evidence_protocol_version,
        case_evidence_id = nil,
        case_manifest_id = record.case_manifest.manifest_id,
        case_id = document.case_id,
        layer = "L1",
        target_evidence_epoch_id = target_epoch,
        implementation_revision = document.source_revision,
        status = document.decision,
        life_ids = life_ids,
        control_life_ids = {},
        observer_pair_refs = {},
        evidence_refs = {document.document_id},
        evaluator_id = definition.evaluator_id,
        evaluator_version = definition.evaluator_version,
        verifier_ref = document.verifier_ref,
        evaluation_truth_status = "document_decision",
        event_truth_status = "runtime_confirmed",
    }
    case_record.case_evidence_id = assert(tagged_digest(
        case_evidence_seed(case_record)
    ))
    local case_ok, case_err = case_manifest.verify_case_evidence(
        case_record, record.case_manifest
    )
    if not case_ok then return nil, case_err end

    local working = copy_value(record)
    working.case_documents[document.document_id] = copy_value(document)
    working.case_evidence[case_record.case_evidence_id] = case_record
    local working_ok, working_err = corpus.verify(working)
    if not working_ok then return nil, working_err end
    replace_contents(record, working)
    return copy_value(case_record)
end

local function case_gate(record, layer, target_epoch, revision)
    local statuses = {}
    local refs = {}
    local definitions = layer == "L0"
        and record.case_manifest.required_l0 or record.case_manifest.required_l1
    for _, definition in ipairs(definitions) do
        local green = false
        local red = false
        local blocked = false
        local case_refs = {}
        for evidence_id, evidence in pairs(record.case_evidence) do
            if evidence.case_id == definition.case_id
                and evidence.target_evidence_epoch_id == target_epoch
                and evidence.implementation_revision == revision then
                case_refs[#case_refs + 1] = evidence_id
                if evidence.status == "green" then green = true
                elseif evidence.status == "red" then red = true
                elseif evidence.status == "blocked" then blocked = true end
            end
        end
        table.sort(case_refs)
        local status
        if red or (layer == "L0" and blocked) then
            status = red and "red" or "blocked"
        elseif green then
            status = "green"
        elseif blocked then
            status = "blocked"
        else
            status = "missing"
        end
        statuses[definition.case_id] = {
            status = status,
            case_evidence_refs = case_refs,
        }
        refs[#refs + 1] = status
    end
    local gate = "green"
    for _, status in ipairs(refs) do
        if status == "red" or status == "blocked" then
            gate = "red"
            break
        elseif status == "missing" and gate == "green" then
            gate = "missing"
        end
    end
    return gate, statuses
end

local function route_life_for_arrival(bucket, arrival_ref)
    for _, route in pairs(bucket.routes) do
        if route.arrival_ref == arrival_ref then return route.life_id end
    end
    return nil
end

local function target_policy_is_qualified_tree(bucket)
    local epoch = bucket.authority_epoch
    local policy = epoch and epoch.physics and epoch.physics.live_policy
    local pressure = policy and policy.pressure
    return epoch and epoch.physics.movement_owner == "tree"
        and policy.kind == "tree_policy_descriptor"
        and pressure and pressure.pressure_policy == "qualified_need_v0"
        and pressure.witness_protocol == "pressure.witness.v1"
        and pressure.action_protocol == "pressure.action_plan.v0"
end

function corpus.closure(record, options)
    local record_ok, record_err = corpus.verify(record)
    if not record_ok then return nil, record_err end
    if not exact_keys(options or {}, {
        target_evidence_epoch_id = true,
        implementation_revision = true,
    }, {
        target_epoch_decision = true,
        observer_pair_ref = true,
    }) or not tagged_hash(options.target_evidence_epoch_id)
        or not non_empty(options.implementation_revision)
        or (options.observer_pair_ref ~= nil
            and not tagged_hash(options.observer_pair_ref)) then
        return nil, corpus_error("closure_options_invalid")
    end
    local bucket = record.buckets[options.target_evidence_epoch_id]
    if not bucket then return nil, corpus_error("closure_target_epoch_missing") end
    local surface = assert(edge_catalog.authority_surface())

    local ledger_gate = edge_stats.verify(bucket) and bucket.ledger_status == "valid"
        and "green" or "red"
    local provenance_gate = "green"
    for life_id in pairs(bucket.source_lives) do
        if not provenance_green(
            record.life_provenance[life_id], options.implementation_revision
        ) then
            provenance_gate = "red"
            break
        end
    end

    local decision_ok = false
    if options.target_epoch_decision then
        decision_ok = verify_target_decision(
            record, options.target_epoch_decision, bucket
        ) ~= nil
    end
    local target_selection_truth_status = decision_ok
        and "document_decision" or "diagnostic_query"
    local target_gate_red = record.authority_claim == "full_tree"
        and (not decision_ok or not target_policy_is_qualified_tree(bucket))

    local observer_pair
    if options.observer_pair_ref then
        for _, pair in ipairs(record.observer_pairs) do
            if pair.pair_id == options.observer_pair_ref then observer_pair = pair break end
        end
    end
    local observer_gate = "missing"
    if observer_pair then
        local contains_target = observer_pair.enabled_evidence_epoch_id
                == options.target_evidence_epoch_id
            or observer_pair.disabled_evidence_epoch_id
                == options.target_evidence_epoch_id
        observer_gate = contains_target and observer_pair.status or "red"
    elseif options.observer_pair_ref then
        observer_gate = "red"
    end

    local l0_gate, l0_status = case_gate(
        record, "L0", options.target_evidence_epoch_id,
        options.implementation_revision
    )
    local l1_gate, l1_status = case_gate(
        record, "L1", options.target_evidence_epoch_id,
        options.implementation_revision
    )
    local case_status = l0_status
    for case_id, status in pairs(l1_status) do case_status[case_id] = status end

    local directions = {}
    local physical_count = 0
    local eligible_count = 0
    for _, definition in ipairs(edge_catalog.list()) do
        local edge = bucket.edges[definition.edge]
        for _, direction in ipairs(definition.directions) do
            local directional = edge.directions[direction]
            local corpus_refs = {}
            for _, arrival_ref in ipairs(
                directional.promotion.eligible_executed_refs
            ) do
                local life_id = route_life_for_arrival(bucket, arrival_ref)
                local source = life_id and bucket.source_lives[life_id]
                if source and (source.corpus_layer == "L0"
                    or source.corpus_layer == "L1")
                    and manifest_definition(record.case_manifest, source.case_id)
                    and provenance_green(
                        record.life_provenance[life_id],
                        options.implementation_revision
                    ) then
                    corpus_refs[#corpus_refs + 1] = arrival_ref
                end
            end
            table.sort(corpus_refs)
            if directional.physical.executed_count > 0 then
                physical_count = physical_count + 1
            end
            if #corpus_refs > 0 then eligible_count = eligible_count + 1 end
            directions[direction] = {
                physical_status = directional.physical_status,
                promotion_status = directional.promotion_status,
                executed_refs = copy_value(directional.physical.executed_refs),
                ledger_eligible_executed_refs = copy_value(
                    directional.promotion.eligible_executed_refs
                ),
                corpus_eligible_executed_refs = corpus_refs,
                rejected_reason_counts = copy_value(
                    directional.promotion.rejected_reason_counts
                ),
            }
        end
    end

    local closure_status
    local any_red = target_gate_red or ledger_gate == "red"
        or provenance_gate == "red"
        or observer_gate == "red" or l0_gate == "red" or l1_gate == "red"
    if record.authority_claim == "diagnostic" then
        closure_status = any_red and "blocked" or "diagnostic"
    elseif any_red then
        closure_status = "blocked"
    elseif observer_gate == "green" and l0_gate == "green"
        and l1_gate == "green"
        and eligible_count == surface.legal_direction_count then
        closure_status = "complete"
    else
        closure_status = "partial"
    end

    return {
        kind = "edge_closure_report",
        protocol_version = corpus.closure_protocol_version,
        target_physics_epoch_id = bucket.physics_epoch_id,
        target_evidence_epoch_id = bucket.evidence_epoch_id,
        target_epoch_decision_ref = decision_ok
            and options.target_epoch_decision.decision_id or nil,
        target_epoch_decision = decision_ok
            and copy_value(options.target_epoch_decision) or nil,
        target_selection_truth_status = target_selection_truth_status,
        authority_surface_id = surface.surface_id,
        authority_claim = record.authority_claim,
        implementation_revision = options.implementation_revision,
        observer_pair_ref = observer_pair and observer_pair.pair_id or nil,
        physical_direction_count = physical_count,
        eligible_direction_count = eligible_count,
        required_direction_count = surface.legal_direction_count,
        directions = directions,
        observer_gate = observer_gate,
        l0_case_gate = l0_gate,
        l1_case_gate = l1_gate,
        case_status = case_status,
        ledger_gate = ledger_gate,
        provenance_gate = provenance_gate,
        closure_status = closure_status,
        decision_truth_status = "runtime_confirmed",
    }
end

function corpus.verify(record)
    if not exact_keys(record, {
        kind = true,
        protocol_version = true,
        corpus_id = true,
        authority_claim = true,
        bounds = true,
        buckets = true,
        life_provenance = true,
        life_projections = true,
        case_manifest = true,
        case_evidence = true,
        case_documents = true,
        harness_evidence = true,
        observer_pairs = true,
        event_truth_status = true,
    }) or record.kind ~= "edge_evidence_corpus"
        or record.protocol_version ~= corpus.protocol_version
        or not non_empty(record.corpus_id)
        or (record.authority_claim ~= "full_tree"
            and record.authority_claim ~= "diagnostic")
        or not verify_bounds(record.bounds)
        or type(record.buckets) ~= "table"
        or type(record.life_provenance) ~= "table"
        or type(record.life_projections) ~= "table"
        or type(record.case_evidence) ~= "table"
        or type(record.case_documents) ~= "table"
        or type(record.harness_evidence) ~= "table"
        or type(record.observer_pairs) ~= "table"
        or record.event_truth_status ~= "runtime_confirmed" then
        return nil, corpus_error("corpus_invalid")
    end
    local manifest_ok, manifest_err = case_manifest.verify_manifest(
        record.case_manifest
    )
    if not manifest_ok then return nil, manifest_err end

    local lives = {}
    local evidence_runs = {}
    for epoch_id, bucket in pairs(record.buckets) do
        local bucket_ok, bucket_err = edge_stats.verify(bucket)
        if not bucket_ok or bucket.ledger_status ~= "valid"
            or bucket.evidence_epoch_id ~= epoch_id then
            return nil, bucket_err or corpus_error("corpus_bucket_invalid")
        end
        for life_id, source in pairs(bucket.source_lives) do
            if lives[life_id] or not non_empty(source.evidence_run_id)
                or evidence_runs[source.evidence_run_id] then
                return nil, corpus_error("corpus_life_identity_reused")
            end
            lives[life_id] = true
            evidence_runs[source.evidence_run_id] = true
            local provenance = record.life_provenance[life_id]
            local projected = record.life_projections[life_id]
            local provenance_ok = provenance and verify_provenance(provenance)
            local projected_ok = projected
                and projection_matches_source(projected, source)
            local source_case_ok = verify_source_case(record.case_manifest, source)
            if not provenance_ok or not projected_ok or not source_case_ok then
                return nil, corpus_error("corpus_life_record_invalid", {
                    life_id = life_id,
                })
            end
        end
    end
    if count_map(lives) ~= count_map(record.life_provenance)
        or count_map(lives) ~= count_map(record.life_projections)
        or count_map(lives) > record.bounds.max_lives then
        return nil, corpus_error("corpus_life_store_mismatch")
    end
    for life_id in pairs(record.life_provenance) do
        if not lives[life_id] then return nil, corpus_error("orphan_provenance") end
    end
    for life_id in pairs(record.life_projections) do
        if not lives[life_id] then return nil, corpus_error("orphan_projection") end
    end

    if #record.observer_pairs > record.bounds.max_observer_pairs then
        return nil, corpus_error("corpus_pair_bound_invalid")
    end
    local pair_ids = {}
    local pair_key_count = 0
    for key in pairs(record.observer_pairs) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0
            or key > #record.observer_pairs then
            return nil, corpus_error("observer_pair_array_invalid")
        end
        pair_key_count = pair_key_count + 1
    end
    if pair_key_count ~= #record.observer_pairs then
        return nil, corpus_error("observer_pair_array_invalid")
    end
    for index, pair in ipairs(record.observer_pairs) do
        if index < 1 or index % 1 ~= 0 or pair_ids[pair.pair_id] then
            return nil, corpus_error("observer_pair_duplicate")
        end
        local pair_ok, pair_err = verify_observer_pair(record, pair)
        if not pair_ok then return nil, pair_err end
        pair_ids[pair.pair_id] = true
    end

    if count_map(record.case_evidence) > record.bounds.max_case_records
        or count_map(record.case_documents) > record.bounds.max_documents
        or count_map(record.harness_evidence) > record.bounds.max_harness_records then
        return nil, corpus_error("corpus_record_bound_invalid")
    end
    for evidence_id, evidence in pairs(record.harness_evidence) do
        local evidence_ok = case_manifest.verify_harness_evidence(evidence)
        local source = find_life(record, evidence.matching_valid_life_id)
        local provenance = record.life_provenance[evidence.matching_valid_life_id]
        if not evidence_ok or evidence_id ~= evidence.boundary_evidence_id
            or not source or not provenance
            or provenance.source_revision ~= evidence.source_revision then
            return nil, corpus_error("harness_evidence_invalid")
        end
    end
    for document_id, document in pairs(record.case_documents) do
        local document_ok = case_manifest.verify_l1_document(document)
        if not document_ok or document_id ~= document.document_id then
            return nil, corpus_error("case_document_invalid")
        end
    end
    for evidence_id, evidence in pairs(record.case_evidence) do
        local evidence_ok = case_manifest.verify_case_evidence(
            evidence, record.case_manifest
        )
        if not evidence_ok or evidence_id ~= evidence.case_evidence_id
            or not record.buckets[evidence.target_evidence_epoch_id] then
            return nil, corpus_error("case_evidence_invalid")
        end
        for _, life_id in ipairs(evidence.life_ids) do
            local source, _, epoch_id = find_life(record, life_id)
            local provenance = record.life_provenance[life_id]
            if not source or epoch_id ~= evidence.target_evidence_epoch_id
                or provenance.source_revision ~= evidence.implementation_revision then
                return nil, corpus_error("case_life_ref_invalid")
            end
        end
        for _, life_id in ipairs(evidence.control_life_ids) do
            local source, _, epoch_id = find_life(record, life_id)
            local provenance = record.life_provenance[life_id]
            if not source or epoch_id ~= evidence.target_evidence_epoch_id
                or provenance.source_revision ~= evidence.implementation_revision then
                return nil, corpus_error("case_control_life_ref_invalid")
            end
        end
        for _, pair_id in ipairs(evidence.observer_pair_refs) do
            if not pair_ids[pair_id] then
                return nil, corpus_error("case_pair_ref_invalid")
            end
        end
        for _, ref in ipairs(evidence.evidence_refs) do
            local resolved = record.harness_evidence[ref]
                or record.case_documents[ref]
                or corpus_evidence_resolves(record, ref)
            if not resolved then return nil, corpus_error("case_ref_invalid") end
        end
    end
    return true
end

return corpus
