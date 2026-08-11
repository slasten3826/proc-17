package.path = "./?.lua;./?/init.lua;" .. package.path

local authority_epoch = require("runtime.authority_epoch")
local case_manifest = require("runtime.edge_case_manifest")
local corpse = require("runtime.corpse")
local digest = require("core.digest")
local edge_catalog = require("runtime.edge_catalog")
local edge_corpus = require("runtime.edge_corpus")
local edge_credit = require("runtime.edge_credit")
local edge_stats = require("runtime.edge_stats_v3")
local json = require("core.json")
local life_projection = require("runtime.edge_life_projection")
local fixture = require("tests.support.plan_life")

local function assert_true(value, message)
    if not value then error(message or "assertion failed", 2) end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function assert_same(left, right, message)
    assert_eq(json.encode(left), json.encode(right), message)
end

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

local function tagged(value)
    return "sha256:" .. assert(digest.record(value))
end

local function resolve_epoch(observer_enabled)
    local record, err = authority_epoch.resolve({
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        legacy_shadow = observer_enabled,
    })
    assert_true(record ~= nil, err and err.code or err)
    return record
end

local enabled_epoch = resolve_epoch(true)
local disabled_epoch = resolve_epoch(false)
local changed_physics_epoch = assert(authority_epoch.resolve({
    router_mode = "tree",
    pressure_policy = "qualified_need_v0",
    legacy_shadow = false,
    ablate_relation_consumer = true,
}))
assert_eq(enabled_epoch.physics_epoch_id, disabled_epoch.physics_epoch_id,
    "observer epochs share physics")
assert_true(enabled_epoch.evidence_epoch_id ~= disabled_epoch.evidence_epoch_id,
    "observer epochs differ as evidence")
assert_true(enabled_epoch.physics_epoch_id ~= changed_physics_epoch.physics_epoch_id,
    "physics-ablation control changes physics")

local packet_template, result_template = assert(fixture.run(
    "edge-corpus-template",
    "work_sequence",
    {"inspect"},
    5,
    {
        packet_options = {
            id = "packet:edge-corpus-pair",
            lineage_id = "lineage:edge-corpus-pair",
            budget = {
                steps = 1,
                substrate_calls = 4,
                tool_calls = 4,
                encode_items = 4,
                loss = 4,
            },
        },
    }
))
assert_eq(packet_template.status, "dead", "template life completed its mortality")

local function observer_event(packet, id)
    return {
        id = id,
        packet_id = packet.id,
        lineage_id = packet.lineage_id,
        generation = packet.generation,
        tick = packet.physis.clock.ticks,
        type = "tension_measure",
        operator = packet.operator,
        payload = {
            kind = "shadow_route_decision",
            observer = "legacy",
            live_authority = "tree",
            current_operator = packet.operator,
            predicted_to = "△",
            instrumentation_status = "observed",
            truth_status = "runtime_confirmed",
        },
        truth_status = "runtime_confirmed",
        cost = {},
        time = 1,
    }
end

local function source_for(epoch, fields)
    return assert(edge_stats.make_life_source({
        packet_id = fields.packet_id or packet_template.id,
        lineage_id = fields.lineage_id or packet_template.lineage_id,
        generation = fields.generation or packet_template.generation,
        session_id = fields.session_id or packet_template.session_id,
        work_mode = fields.work_mode or "plan",
        case_id = fields.case_id,
        corpus_layer = fields.corpus_layer,
        evidence_run_id = fields.evidence_run_id,
        model = fields.model or "fixture",
        prompt_hash = fields.prompt_hash or tagged({prompt = fields.prompt or "same"}),
    }))
end

local function projection_for(source, observed, mutation)
    local packet = copy_value(packet_template)
    local result = copy_value(result_template)
    packet.id = source.packet_id
    packet.lineage_id = source.lineage_id
    packet.generation = source.generation
    packet.session_id = source.session_id
    packet.regime.work.mode = source.work_mode
    result.packet_id = source.packet_id
    result.router_mode = "tree"
    result.shadow_routes = nil
    result.legacy_shadow = nil
    if mutation then mutation(packet, result) end
    if observed then
        local event = observer_event(packet, "observer-event-1")
        packet.trace[#packet.trace + 1] = event
        result.shadow_routes = {{
            kind = "shadow_route_decision",
            observer = "legacy",
            live_authority = "tree",
            current_operator = packet.operator,
            predicted_to = "△",
            instrumentation_status = "observed",
            truth_status = "runtime_confirmed",
            trace_event_id = event.id,
        }}
    end
    return assert(life_projection.capture(packet, result, nil, {
        life_id = source.life_id,
    }))
end

local function provenance(revision, state)
    return {
        source_revision = revision,
        worktree_state = state or "clean",
        artifact_digest = tagged({artifact = revision}),
        event_truth_status = "runtime_confirmed",
        content_truth_status = "runtime_confirmed",
        verifier_ref = "verifier:" .. revision,
    }
end

local function descriptor(kind, original_id, record)
    return {
        source_kind = kind,
        original_source_id = original_id,
        source_record = record,
    }
end

local function bundle(source, records)
    return {life_id = source.life_id, records = records or {}}
end

local function eligibility()
    return {
        promotion_eligible = true,
        promotion_ineligibility_reasons = {},
        promotion_eligibility_basis = {
            witness_ids = {"witness:qualified"},
            unqualified_snapshot = false,
            fixture_witness_ids = {},
        },
    }
end

local function install(target, value)
    target.promotion_eligible = value.promotion_eligible
    target.promotion_ineligibility_reasons = copy_value(
        value.promotion_ineligibility_reasons
    )
    target.promotion_eligibility_basis = copy_value(
        value.promotion_eligibility_basis
    )
    return target
end

local function add_route(ledger, source, credit, direction, ordinal, classified)
    local from, to = direction:match("^(.-)%-%>(.-)$")
    local label = tostring(ordinal) .. ":" .. direction
    local triple = eligibility()
    if classified == false then
        triple.promotion_eligible = false
        triple.promotion_ineligibility_reasons = {"candidate_unqualified"}
        triple.promotion_eligibility_basis = {
            witness_ids = {"witness:unqualified"},
            unqualified_snapshot = true,
            fixture_witness_ids = {},
        }
    end
    local pressure_ref = "pressure:" .. label
    local derivation_ref = "derivation:" .. label
    local action_ref = "action:" .. label
    local candidate = install({
        to = to,
        readiness = {ready = true},
        action_plan = {plan_id = action_ref},
        contributions = {},
    }, triple)
    local decision = install({
        kind = "tree_route_decision",
        from = from,
        to = to,
        reason = "corpus_test_route",
        authority = "tree",
        derivation_ref = derivation_ref,
        pressure_snapshot_ref = pressure_ref,
        selected_action_plan_id = action_ref,
        selected_candidate = copy_value(candidate),
        candidates = {copy_value(candidate)},
        truth_status = "runtime_confirmed",
    }, triple)
    local derivation_event = {
        id = derivation_ref,
        type = "route_derivation",
        operator = from,
        truth_status = "runtime_confirmed",
        payload = install({
            kind = "route_derivation",
            current_operator = from,
            selected_to = to,
            outcome = "selected",
            pressure_snapshot_ref = pressure_ref,
            selected_action_plan_id = action_ref,
            selected_candidate = copy_value(candidate),
            candidates = {copy_value(candidate)},
        }, triple),
    }
    local pressure_event = {
        id = pressure_ref,
        type = "pressure_snapshot",
        truth_status = "runtime_confirmed",
        payload = {current_operator = from},
    }
    assert(edge_stats.record_tree_derivation(ledger, decision, bundle(source, {
        descriptor("packet_trace", derivation_ref, derivation_event),
        descriptor("policy_evidence", pressure_ref, pressure_event),
    })))
    local selection = assert(edge_credit.prepare(credit, decision, {
        route_ordinal = ordinal,
        derivation_event = derivation_event,
    }))
    assert(edge_stats.record_selection(ledger, selection, bundle(source)))
    local route_event = {
        id = "route:" .. label,
        type = "route",
        operator = to,
        truth_status = "runtime_confirmed",
        payload = install({
            kind = "tree_route_decision",
            from = from,
            to = to,
            authority = "tree",
            derivation_ref = derivation_ref,
            pressure_snapshot_ref = pressure_ref,
            selected_action_plan_id = action_ref,
        }, triple),
    }
    local commit = assert(edge_credit.record_commit(credit, selection, route_event))
    assert(edge_stats.record_transition(ledger, commit, bundle(source, {
        descriptor("packet_trace", route_event.id, route_event),
    })))
    local tick_ref = "tick:" .. label
    local effect_ref = "effect:" .. label
    local arrival, credit_decision = assert(edge_credit.record_arrival(
        credit,
        commit,
        {
            destination_tick_ref = tick_ref,
            effect_refs = {effect_ref},
            payload_kind = "corpus_test_effect",
        }
    ))
    assert(edge_stats.record_arrival(
        ledger,
        arrival,
        credit_decision,
        bundle(source, {
            descriptor("runner_tick", tick_ref, {
                id = tick_ref,
                kind = "runner_tick",
                event_truth_status = "runtime_confirmed",
            }),
            descriptor("runner_effect", effect_ref, {
                id = effect_ref,
                kind = "corpus_test_effect",
                event_truth_status = "runtime_confirmed",
            }),
        })
    ))
end

local function ledger_for(epoch, source, directions, classified)
    local ledger = assert(edge_stats.new(epoch, source))
    if directions and #directions > 0 then
        local credit = assert(edge_credit.new(epoch, {
            life_id = source.life_id,
            packet_id = source.packet_id,
            lineage_id = source.lineage_id,
            generation = source.generation,
        }))
        for ordinal, direction in ipairs(directions) do
            add_route(ledger, source, credit, direction, ordinal, classified)
        end
    end
    return ledger
end

local function add_life(record, epoch, source, projected, directions, prov, classified)
    local ledger = ledger_for(epoch, source, directions or {}, classified)
    local ok, err = edge_corpus.add_life(record, {
        edge_stats_v3 = ledger,
    }, projected, prov)
    assert_true(ok ~= nil, err and err.code or err)
    return ledger
end

local revision = "revision:edge-corpus"
local record = assert(edge_corpus.new({
    corpus_id = "corpus:edge-v1",
    authority_claim = "diagnostic",
}))
assert_true(edge_corpus.verify(record), "empty corpus verifies")

local enabled_source = source_for(enabled_epoch, {
    case_id = "P06a",
    corpus_layer = "L0",
    evidence_run_id = "case:P06a:enabled",
})
local disabled_source = source_for(disabled_epoch, {
    case_id = "P06a",
    corpus_layer = "L0",
    evidence_run_id = "case:P06a:disabled",
})
local enabled_projection = projection_for(enabled_source, true)
local disabled_projection = projection_for(disabled_source, false)

add_life(record, enabled_epoch, enabled_source, enabled_projection, {},
    provenance(revision))
add_life(record, disabled_epoch, disabled_source, disabled_projection, {},
    provenance(revision))
assert_eq((function() local n=0 for _ in pairs(record.buckets) do n=n+1 end return n end)(),
    2, "CO02 unlike evidence epochs remain separate")

local pair, pair_err = edge_corpus.add_observer_pair(
    record, enabled_source.life_id, disabled_source.life_id
)
assert_true(pair ~= nil, pair_err
    and (pair_err.code .. ":" .. tostring(pair_err.field)) or pair_err)
assert_eq(pair.status, "green", "EM04 observer pair crosses evidence epochs")
assert_true(edge_corpus.verify(record), "green pair corpus verifies")

local sparse_pairs = copy_value(record)
sparse_pairs.observer_pairs[3] = copy_value(pair)
local sparse_ok, sparse_err = edge_corpus.verify(sparse_pairs)
assert_eq(sparse_ok, nil, "sparse pair array cannot hide evidence")
assert_eq(sparse_err.code, "observer_pair_array_invalid",
    "sparse pair rejection is typed")

-- CO10/CO11: rejected transactions preserve the complete corpus digest.
local before_reuse = assert(digest.record(record))
local reused = source_for(enabled_epoch, {
    case_id = "P06a",
    corpus_layer = "L0",
    evidence_run_id = enabled_source.evidence_run_id,
    packet_id = "packet:reused-run",
    lineage_id = "lineage:reused-run",
})
local reused_ok, reused_err = edge_corpus.add_life(record, {
    edge_stats_v3 = ledger_for(enabled_epoch, reused),
}, projection_for(reused, true), provenance(revision))
assert_eq(reused_ok, nil, "CO10 reused evidence run rejects")
assert_eq(reused_err.code, "corpus_evidence_run_reused", "CO10 typed error")
assert_eq(assert(digest.record(record)), before_reuse,
    "CO10 failed add leaves corpus unchanged")

local tampered_projection = copy_value(disabled_projection)
tampered_projection.life_id = enabled_source.life_id
local tampered_ok = edge_corpus.add_life(record, {
    edge_stats_v3 = ledger_for(enabled_epoch, reused),
}, tampered_projection, provenance(revision))
assert_eq(tampered_ok, nil, "CO11 tampered projection rejects")
assert_eq(assert(digest.record(record)), before_reuse,
    "CO11 projection failure is atomic")

-- CO01: a second Plan life under the exact epoch merges into one bucket.
local merged_source = source_for(enabled_epoch, {
    case_id = "P08",
    corpus_layer = "L0",
    evidence_run_id = "case:P08:merged",
    packet_id = "packet:merged",
    lineage_id = "lineage:merged",
})
add_life(record, enabled_epoch, merged_source, projection_for(merged_source, true),
    {}, provenance(revision))
assert_true(record.buckets[enabled_epoch.evidence_epoch_id]
    .source_lives[merged_source.life_id] ~= nil,
    "CO01 same epoch lives merge in one bucket")

local diagnostic = assert(edge_corpus.closure(record, {
    target_evidence_epoch_id = enabled_epoch.evidence_epoch_id,
    implementation_revision = revision,
    observer_pair_ref = pair.pair_id,
}))
assert_eq(diagnostic.closure_status, "diagnostic",
    "CO09 diagnostic claim cannot become complete")
assert_eq(diagnostic.required_direction_count, 38, "CO09 keeps full denominator")
assert_eq(diagnostic.observer_gate, "green", "observer gate resolves target pair")

-- CO04/CO05: incomplete provenance is retained but blocks a report.
local dirty_record = assert(edge_corpus.new({
    corpus_id = "corpus:dirty",
    authority_claim = "diagnostic",
}))
local dirty_source = source_for(enabled_epoch, {
    case_id = "P08",
    corpus_layer = "L0",
    evidence_run_id = "case:P08:dirty",
    packet_id = "packet:dirty",
    lineage_id = "lineage:dirty",
})
add_life(dirty_record, enabled_epoch, dirty_source,
    projection_for(dirty_source, true), {}, provenance(revision, "dirty"))
local dirty_report = assert(edge_corpus.closure(dirty_record, {
    target_evidence_epoch_id = enabled_epoch.evidence_epoch_id,
    implementation_revision = revision,
}))
assert_eq(dirty_report.provenance_gate, "red", "CO05 dirty provenance red")
assert_eq(dirty_report.closure_status, "blocked", "CO05 dirty report blocked")

-- CO13: bounds reject without eviction.
local bounded = assert(edge_corpus.new({
    corpus_id = "corpus:bounded",
    authority_claim = "diagnostic",
    bounds = {max_lives = 1},
}))
add_life(bounded, enabled_epoch, enabled_source, enabled_projection, {},
    provenance(revision))
local bounded_before = assert(digest.record(bounded))
local bounded_ok, bounded_err = edge_corpus.add_life(bounded, {
    edge_stats_v3 = ledger_for(disabled_epoch, disabled_source),
}, disabled_projection, provenance(revision))
assert_eq(bounded_ok, nil, "CO13 max_lives rejects")
assert_eq(bounded_err.code, "corpus_max_lives_exceeded", "CO13 typed bound")
assert_eq(assert(digest.record(bounded)), bounded_before, "CO13 no eviction")

-- CO15: equal bodies with different route ledgers retain a red pair.
local ledger_red = assert(edge_corpus.new({
    corpus_id = "corpus:ledger-red",
    authority_claim = "diagnostic",
}))
add_life(ledger_red, enabled_epoch, enabled_source, enabled_projection,
    {"▽->☴"}, provenance(revision))
add_life(ledger_red, disabled_epoch, disabled_source, disabled_projection,
    {}, provenance(revision))
local red_pair = assert(edge_corpus.add_observer_pair(
    ledger_red, enabled_source.life_id, disabled_source.life_id
))
assert_eq(red_pair.status, "red", "CO15 ledger delta makes pair red")
assert_true(red_pair.differing_fields[#red_pair.differing_fields] == "edge_ledger",
    "CO15 reports ledger channel")

-- CO06/CO12: valid negative pairs are retained instead of rejected.
local physics_red = assert(edge_corpus.new({
    corpus_id = "corpus:physics-red",
    authority_claim = "diagnostic",
}))
add_life(physics_red, enabled_epoch, enabled_source, enabled_projection, {},
    provenance(revision))
add_life(physics_red, changed_physics_epoch, disabled_source, disabled_projection, {},
    provenance(revision))
local physics_pair = assert(edge_corpus.add_observer_pair(
    physics_red, enabled_source.life_id, disabled_source.life_id
))
assert_eq(physics_pair.status, "red", "CO06 physics delta is retained red")
assert_true(physics_pair.differing_fields[1] == "physics_epoch_id",
    "CO06 names the changed physics coordinate")

local body_red = assert(edge_corpus.new({
    corpus_id = "corpus:body-red",
    authority_claim = "diagnostic",
}))
local body_changed_projection = projection_for(enabled_source, true, function(packet)
    packet.metadata.corpus_probe = "body-delta"
end)
add_life(body_red, enabled_epoch, enabled_source, body_changed_projection, {},
    provenance(revision))
add_life(body_red, disabled_epoch, disabled_source, disabled_projection, {},
    provenance(revision))
local body_pair = assert(edge_corpus.add_observer_pair(
    body_red, enabled_source.life_id, disabled_source.life_id
))
assert_eq(body_pair.status, "red", "CO12 body delta is retained red")
assert_true(#body_pair.differing_fields > 0, "CO12 names differing body surface")

-- CO07/CO08/CA10: 38 physical and ledger-eligible directions still cannot
-- close a full-tree claim while the required case campaign is missing.
local all_directions = {}
for _, definition in ipairs(edge_catalog.list()) do
    for _, direction in ipairs(definition.directions) do
        all_directions[#all_directions + 1] = direction
    end
end
assert_eq(#all_directions, 38, "surface exposes 38 directions")

local run_full_campaign = os.getenv("PROC17_EDGE_CORPUS_CAMPAIGN") == "1"
if run_full_campaign then
local full = assert(edge_corpus.new({
    corpus_id = "corpus:full-missing-cases",
    authority_claim = "full_tree",
}))
local full_enabled = source_for(enabled_epoch, {
    case_id = "P06a",
    corpus_layer = "L0",
    evidence_run_id = "case:P06a:full-pair:enabled",
})
local full_disabled = source_for(disabled_epoch, {
    case_id = "P06a",
    corpus_layer = "L0",
    evidence_run_id = "case:P06a:full-pair:disabled",
})
add_life(full, enabled_epoch, full_enabled, projection_for(full_enabled, true),
    {}, provenance(revision))
add_life(full, disabled_epoch, full_disabled, projection_for(full_disabled, false),
    {}, provenance(revision))
local full_pair = assert(edge_corpus.add_observer_pair(
    full, full_enabled.life_id, full_disabled.life_id
))
assert_eq(full_pair.status, "green", "all-direction observer pair is neutral")

local full_routes = source_for(enabled_epoch, {
    case_id = "P09",
    corpus_layer = "L0",
    evidence_run_id = "case:P09:all-directions",
    packet_id = "packet:all-directions",
    lineage_id = "lineage:all-directions",
})
add_life(full, enabled_epoch, full_routes, projection_for(full_routes, true),
    all_directions, provenance(revision))

local surface = assert(edge_catalog.authority_surface())
local decision = {
    kind = "authority_target_decision",
    protocol_version = edge_corpus.target_decision_protocol_version,
    decision_id = nil,
    corpus_id = full.corpus_id,
    target_physics_epoch_id = enabled_epoch.physics_epoch_id,
    target_evidence_epoch_id = enabled_epoch.evidence_epoch_id,
    authority_surface_id = surface.surface_id,
    rationale_ref = "docs/decision:full-tree-test",
    decision_truth_status = "document_decision",
}
local decision_seed = copy_value(decision)
decision_seed.decision_id = nil
decision.decision_id = tagged(decision_seed)

local missing_decision = assert(edge_corpus.closure(full, {
    target_evidence_epoch_id = enabled_epoch.evidence_epoch_id,
    implementation_revision = revision,
    observer_pair_ref = full_pair.pair_id,
}))
assert_eq(missing_decision.closure_status, "blocked",
    "CO14 missing target decision blocks full claim")

local full_report = assert(edge_corpus.closure(full, {
    target_evidence_epoch_id = enabled_epoch.evidence_epoch_id,
    target_epoch_decision = decision,
    implementation_revision = revision,
    observer_pair_ref = full_pair.pair_id,
}))
assert_eq(full_report.physical_direction_count, 38, "CO07 all physical visible")
assert_eq(full_report.eligible_direction_count, 38, "CO08 all exact credits visible")
assert_eq(full_report.l0_case_gate, "missing", "CA10 missing L0 case gate")
assert_eq(full_report.closure_status, "partial",
    "CA10 38 ledger-green directions cannot bypass cases")
end

-- A physical-only route is visible but filtered from corpus eligibility.
local physical = assert(edge_corpus.new({
    corpus_id = "corpus:physical-only",
    authority_claim = "diagnostic",
}))
local physical_source = source_for(enabled_epoch, {
    case_id = "P09",
    corpus_layer = "L0",
    evidence_run_id = "case:P09:physical-only",
    packet_id = "packet:physical-only",
    lineage_id = "lineage:physical-only",
})
add_life(physical, enabled_epoch, physical_source,
    projection_for(physical_source, true), {"▽->☴"},
    provenance(revision), false)
local physical_report = assert(edge_corpus.closure(physical, {
    target_evidence_epoch_id = enabled_epoch.evidence_epoch_id,
    implementation_revision = revision,
}))
assert_eq(physical_report.physical_direction_count, 1, "CO07 physical route visible")
assert_eq(physical_report.eligible_direction_count, 0,
    "CO07 ineligible route does not close")

-- CA11: evaluator history keeps a later contradiction; red dominates green.
local case_green = assert(edge_corpus.evaluate_l0_case(record, "P06a", {
    life_ids = {enabled_source.life_id},
    observer_pair_refs = {pair.pair_id},
    controls = {
        host_ceiling_above_budget = {life_ids = {enabled_source.life_id}},
    },
}))
assert_eq(case_green.status, "green", "P06a grown death is green")
local malformed_call, malformed_value, malformed_err = pcall(
    edge_corpus.evaluate_l0_case,
    record,
    "P06a",
    {
        life_ids = {enabled_source.life_id},
        observer_pair_refs = {pair.pair_id},
        controls = "not-a-control-map",
    }
)
assert_true(malformed_call, "malformed case input must remain a typed rejection")
assert_eq(malformed_value, nil, "malformed controls cannot write a case")
assert_eq(malformed_err.code, "case_controls_invalid",
    "malformed controls reach the closed evaluator")

local red_enabled_source = source_for(enabled_epoch, {
    case_id = "P06a",
    corpus_layer = "L0",
    evidence_run_id = "case:P06a:red:enabled",
})
local red_disabled_source = source_for(disabled_epoch, {
    case_id = "P06a",
    corpus_layer = "L0",
    evidence_run_id = "case:P06a:red:disabled",
})
local function complete_mutation(packet)
    packet.death.cause = "complete"
    packet.terminal.cause = "complete"
end
local red_enabled_projection = projection_for(
    red_enabled_source, true, complete_mutation
)
local red_disabled_projection = projection_for(
    red_disabled_source, false, complete_mutation
)
add_life(record, enabled_epoch, red_enabled_source, red_enabled_projection, {},
    provenance(revision))
add_life(record, disabled_epoch, red_disabled_source, red_disabled_projection, {},
    provenance(revision))
local red_semantic_pair = assert(edge_corpus.add_observer_pair(
    record, red_enabled_source.life_id, red_disabled_source.life_id
))
local case_red = assert(edge_corpus.evaluate_l0_case(record, "P06a", {
    life_ids = {red_enabled_source.life_id},
    observer_pair_refs = {red_semantic_pair.pair_id},
    controls = {
        host_ceiling_above_budget = {life_ids = {red_enabled_source.life_id}},
    },
}))
assert_eq(case_red.status, "red", "contradictory P06a life is retained red")
local red_history_report = assert(edge_corpus.closure(record, {
    target_evidence_epoch_id = enabled_epoch.evidence_epoch_id,
    implementation_revision = revision,
    observer_pair_ref = pair.pair_id,
}))
assert_eq(red_history_report.case_status.P06a.status, "red",
    "CA11 red dominates prior green")

-- CA12: a transient blocked live document remains, then a verified retry wins.
local l1_source = source_for(enabled_epoch, {
    case_id = "L1_ACCEPTED_BUILD",
    corpus_layer = "L1",
    evidence_run_id = "case:L1_ACCEPTED_BUILD:live",
    packet_id = "packet:l1-live",
    lineage_id = "lineage:l1-live",
})
add_life(record, enabled_epoch, l1_source, projection_for(l1_source, true), {},
    provenance(revision))
local function live_document(status, reason, suffix)
    return assert(case_manifest.l1_document({
        case_id = "L1_ACCEPTED_BUILD",
        artifact_path = "sandbox/live/accepted-" .. suffix .. ".json",
        artifact_digest = tagged({artifact = suffix}),
        provider = "fixture-live-provider",
        model = "fixture-model",
        prompt_hash = tagged({prompt = "live"}),
        usage_ref = "usage:" .. suffix,
        source_revision = revision,
        verifier_ref = "verifier:live:" .. suffix,
        decision = status,
        decision_reason = reason,
    }))
end
local blocked_document = live_document("blocked", "provider_unavailable", "blocked")
local green_document = live_document("green", "verified_success", "green")
assert(edge_corpus.add_l1_document(record, blocked_document))
assert(edge_corpus.add_l1_document(record, green_document))
local retry_report = assert(edge_corpus.closure(record, {
    target_evidence_epoch_id = enabled_epoch.evidence_epoch_id,
    implementation_revision = revision,
    observer_pair_ref = pair.pair_id,
}))
assert_eq(retry_report.case_status.L1_ACCEPTED_BUILD.status, "green",
    "CA12 green retry satisfies L1")
assert_eq(#retry_report.case_status.L1_ACCEPTED_BUILD.case_evidence_refs, 2,
    "CA12 blocked history remains visible")

assert_true(edge_corpus.verify(record), "final corpus verifies")
print("test_edge_corpus ok")
