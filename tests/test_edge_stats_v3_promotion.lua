package.path = "./?.lua;./?/init.lua;" .. package.path

local authority_epoch = require("runtime.authority_epoch")
local edge_catalog = require("runtime.edge_catalog")
local edge_credit = require("runtime.edge_credit")
local edge_stats = require("runtime.edge_stats")
local edge_stats_v2 = require("runtime.edge_stats_v2")
local json = require("core.json")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
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

local function resolve(options)
    options = copy_value(options or {})
    options.router_mode = options.router_mode or "tree"
    if options.legacy_shadow == nil then
        options.legacy_shadow = false
    end
    if options.pressure_policy == nil then
        options.pressure_policy = "qualified_need_v0"
    end
    local record, err = authority_epoch.resolve(options)
    assert_true(record ~= nil, err and err.code or err)
    return record
end

local qualified_epoch = resolve()

local function source(kind, id, record)
    return {
        source_kind = kind,
        original_source_id = id,
        source_record = record,
    }
end

local function bundle(life, records)
    return {
        life_id = life.life_id,
        records = records or {},
    }
end

local function triple(kind)
    if kind == "ineligible" then
        return {
            promotion_eligible = false,
            promotion_ineligibility_reasons = {"candidate_unqualified"},
            promotion_eligibility_basis = {
                witness_ids = {"witness:unqualified"},
                unqualified_snapshot = true,
                fixture_witness_ids = {},
            },
        }
    end
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

local function direction(ledger)
    local definition = assert(edge_catalog.get("▽", "☴"))
    return ledger.edges[definition.edge].directions["▽->☴"],
        ledger.edges[definition.edge]
end

local function grow_life(label, options)
    options = options or {}
    local epoch_record = options.epoch or qualified_epoch
    local life = assert(edge_stats.make_life_source({
        packet_id = "packet:" .. label,
        lineage_id = "lineage:" .. label,
        generation = 1,
        session_id = "session:" .. label,
        work_mode = options.work_mode or "build",
        case_id = "case:" .. label,
        corpus_layer = "unit",
        evidence_run_id = "run:" .. label,
        model = "fixture",
    }))
    local ledger = assert(edge_stats.new(epoch_record, life))
    local credit = assert(edge_credit.new(epoch_record, {
        life_id = life.life_id,
        packet_id = life.packet_id,
        lineage_id = life.lineage_id,
        generation = life.generation,
    }))
    local eligibility = triple(options.classification)
    local pressure_ref = "pressure:" .. label
    local derivation_ref = "derivation:" .. label
    local action_ref = "action:" .. label
    local candidate = install({
        to = "☴",
        readiness = {ready = true},
        action_plan = {plan_id = action_ref},
        contributions = {},
    }, eligibility)
    local decision = install({
        kind = "tree_route_decision",
        from = "▽",
        to = "☴",
        reason = "promotion_test_route",
        authority = "tree",
        derivation_ref = derivation_ref,
        pressure_snapshot_ref = pressure_ref,
        selected_action_plan_id = action_ref,
        selected_candidate = copy_value(candidate),
        candidates = {copy_value(candidate)},
        truth_status = "runtime_confirmed",
    }, eligibility)
    local derivation_event = {
        id = derivation_ref,
        type = "route_derivation",
        operator = "▽",
        truth_status = "runtime_confirmed",
        payload = install({
            kind = "route_derivation",
            current_operator = "▽",
            selected_to = "☴",
            outcome = "selected",
            pressure_snapshot_ref = pressure_ref,
            selected_action_plan_id = action_ref,
            selected_candidate = copy_value(candidate),
            candidates = {copy_value(candidate)},
        }, eligibility),
    }
    local route_event = {
        id = "route:" .. label,
        type = "route",
        operator = "☴",
        truth_status = "runtime_confirmed",
        payload = install({
            kind = "tree_route_decision",
            from = "▽",
            to = "☴",
            authority = "tree",
            derivation_ref = derivation_ref,
            pressure_snapshot_ref = pressure_ref,
            selected_action_plan_id = action_ref,
        }, eligibility),
    }
    local pressure_event = {
        id = pressure_ref,
        type = "pressure_snapshot",
        truth_status = "runtime_confirmed",
        payload = {current_operator = "▽"},
    }
    assert(edge_stats.record_tree_derivation(ledger, decision, bundle(life, {
        source("packet_trace", derivation_ref, derivation_event),
        source("policy_evidence", pressure_ref, pressure_event),
    })))

    if options.classification == "unclassified" then
        decision.promotion_eligible = nil
        decision.promotion_ineligibility_reasons = nil
        decision.promotion_eligibility_basis = nil
        route_event.payload.promotion_eligible = nil
        route_event.payload.promotion_ineligibility_reasons = nil
        route_event.payload.promotion_eligibility_basis = nil
    end
    local selection = assert(edge_credit.prepare(credit, decision, {
        route_ordinal = 1,
        derivation_event = derivation_event,
    }))
    assert(edge_stats.record_selection(ledger, selection, bundle(life)))
    if options.stop_after == "selection" then
        return {
            epoch = epoch_record,
            life = life,
            ledger = ledger,
            selection = selection,
        }
    end
    local commit = assert(edge_credit.record_commit(credit, selection, route_event))
    assert(edge_stats.record_transition(ledger, commit, bundle(life, {
        source("packet_trace", route_event.id, route_event),
    })))
    if options.stop_after == "commit" then
        return {
            epoch = epoch_record,
            life = life,
            ledger = ledger,
            selection = selection,
            commit = commit,
        }
    end
    local arrival, credit_decision, arrival_err = edge_credit.record_arrival(
        credit,
        commit,
        {
            destination_tick_ref = "tick:" .. label,
            effect_refs = {"effect:" .. label},
            payload_kind = "promotion_test_effect",
        }
    )
    assert_true(arrival ~= nil, arrival_err and arrival_err.code)
    local arrival_sources = {
        source("runner_tick", "tick:" .. label, {
            id = "tick:" .. label,
            kind = "runner_tick",
            event_truth_status = "runtime_confirmed",
        }),
    }
    if not options.omit_effect_source then
        arrival_sources[#arrival_sources + 1] = source(
            "runner_effect",
            "effect:" .. label,
            {
                id = "effect:" .. label,
                kind = "promotion_test_effect",
                event_truth_status = "runtime_confirmed",
            }
        )
    end
    assert(edge_stats.record_arrival(
        ledger,
        arrival,
        credit_decision,
        bundle(life, arrival_sources)
    ))
    return {
        epoch = epoch_record,
        life = life,
        ledger = ledger,
        selection = selection,
        commit = commit,
        arrival = arrival,
        decision = credit_decision,
    }
end

-- Eligible potential appears at selection/commit but closes only on the exact
-- credited arrival decision.
local eligible = grow_life("eligible")
local eligible_direction, eligible_edge = direction(eligible.ledger)
assert_eq(eligible_direction.physical.executed_count, 1,
    "eligible route remains physical")
assert_eq(eligible_direction.promotion.eligible_selected_count, 1,
    "eligible selection is remembered")
assert_eq(eligible_direction.promotion.eligible_committed_count, 1,
    "eligible commit is remembered")
assert_eq(eligible_direction.promotion.eligible_executed_count, 1,
    "credited arrival closes promotion")
assert_eq(eligible_direction.promotion_status, "eligible_executed",
    "direction reports qualified execution")
assert_eq(eligible_edge.promotion_coverage, "complete",
    "one-way E03 closes only after credited arrival")

local selected_only = grow_life("selected-only", {stop_after = "selection"})
local selected_only_direction, selected_only_edge = direction(
    selected_only.ledger
)
assert_eq(selected_only_direction.promotion.eligible_selected_count, 1,
    "eligible selection records potential credit")
assert_eq(selected_only_direction.promotion.eligible_executed_count, 0,
    "selection alone cannot close promotion")
assert_eq(selected_only_edge.promotion_coverage, "unqualified",
    "selection potential is not coverage")

local committed_only = grow_life("committed-only", {stop_after = "commit"})
local committed_only_direction, committed_only_edge = direction(
    committed_only.ledger
)
assert_eq(committed_only_direction.promotion.eligible_committed_count, 1,
    "eligible commit records potential credit")
assert_eq(committed_only_direction.promotion.eligible_executed_count, 0,
    "commit alone cannot close promotion")
assert_eq(committed_only_edge.promotion_coverage, "unqualified",
    "commit potential is not coverage")

-- A rejected decision preserves execution but never qualifies it.
local ineligible = grow_life("ineligible", {classification = "ineligible"})
local ineligible_direction = direction(ineligible.ledger)
assert_eq(ineligible_direction.physical.executed_count, 1,
    "ineligible route stays physically executed")
assert_eq(ineligible_direction.promotion.ineligible_executed_count, 1,
    "rejected execution remains visible")
assert_eq(ineligible_direction.promotion.eligible_executed_count, 0,
    "rejected execution cannot close promotion")
assert_eq(ineligible_direction.promotion.rejected_reason_counts
    .candidate_unqualified, 1, "immutable rejection reason retained")

-- Missing body eligibility and missing required source both remain physical,
-- invalidate classification and cannot borrow a successful effect.
local unclassified = grow_life("unclassified", {
    classification = "unclassified",
})
local unclassified_direction = direction(unclassified.ledger)
assert_eq(unclassified.ledger.ledger_status, "invalid",
    "unclassified selection invalidates promotion ledger")
assert_eq(unclassified_direction.physical.executed_count, 1,
    "unclassified arrival remains physical")
assert_eq(unclassified_direction.promotion.unclassified_executed_count, 1,
    "unclassified arrival has an explicit counter")

local missing_source = grow_life("missing-source", {
    omit_effect_source = true,
})
local missing_direction = direction(missing_source.ledger)
assert_eq(missing_source.ledger.ledger_status, "invalid",
    "SE06 missing required effect invalidates ledger")
assert_eq(missing_direction.physical.executed_count, 1,
    "SE06 physical arrival remains visible")
assert_eq(missing_direction.promotion.eligible_executed_count, 0,
    "SE06 cannot accept credited decision")
assert_eq(missing_direction.promotion.unclassified_executed_count, 1,
    "SE06 is classified as unclassified execution")

-- EM01/EM08: unlike work modes share an evidence epoch and merge exactly when
-- their life identities are disjoint.
local plan_life = grow_life("merge-plan", {work_mode = "plan"})
local build_life = grow_life("merge-build", {
    work_mode = "build",
    classification = "ineligible",
})
assert(edge_stats.merge(plan_life.ledger, build_life.ledger))
local merged_direction = direction(plan_life.ledger)
assert_eq(merged_direction.physical.executed_count, 2,
    "EM01 physical counters sum")
assert_eq(merged_direction.promotion.eligible_executed_count, 1,
    "EM01 promotion counters sum")
assert_eq(merged_direction.promotion.ineligible_executed_count, 1,
    "EM08 Plan and Build lives are both retained")
assert_true(plan_life.ledger.source_lives[plan_life.life.life_id] ~= nil,
    "merge keeps target life")
assert_true(plan_life.ledger.source_lives[build_life.life.life_id] ~= nil,
    "merge keeps source life")

local function rejected_merge(target, source_ledger, expected_code, label)
    local before = assert(edge_stats.summary(target))
    local merged, err = edge_stats.merge(target, source_ledger)
    assert_eq(merged, nil, label .. " rejects")
    if expected_code then
        assert_eq(err.code, expected_code, label .. " error code")
    end
    assert_same(assert(edge_stats.summary(target)), before,
        label .. " leaves target unchanged")
end

-- EM11: exact replay of a previously merged life is not idempotent evidence;
-- it would double-count a life and therefore rejects.
rejected_merge(
    plan_life.ledger,
    build_life.ledger,
    "life_source_overlap",
    "EM11 duplicate life"
)

-- EM02 binary/qualified, EM03 ablated/canonical and EM04 observer arrangement
-- are distinct evidence epochs even when their edge surface is identical.
local binary = grow_life("merge-binary", {
    epoch = resolve({pressure_policy = "camera_reconciliation"}),
})
rejected_merge(plan_life.ledger, binary.ledger,
    "evidence_epoch_mismatch", "EM02 binary epoch")

local ablated = grow_life("merge-ablated", {
    epoch = resolve({ablate_relation_consumer = true}),
})
rejected_merge(plan_life.ledger, ablated.ledger,
    "evidence_epoch_mismatch", "EM03 ablated epoch")

local observer_on = grow_life("merge-observer-on", {
    epoch = resolve({legacy_shadow = true}),
})
rejected_merge(plan_life.ledger, observer_on.ledger,
    "evidence_epoch_mismatch", "EM04 observer arrangement")

-- EM05: v2 history remains archaeology and cannot be restamped through merge.
rejected_merge(plan_life.ledger, edge_stats_v2.new({}),
    "edge_stats_protocol_mismatch", "EM05 v2 source")

-- EM06/EM07/EM10/SE07: malformed source evidence rejects before any target
-- counter or source index changes.
local malformed = assert(edge_stats.summary(eligible.ledger))
local malformed_ref = next(malformed.evidence_records)
malformed.evidence_records[malformed_ref].source_record.kind = "tampered"
rejected_merge(plan_life.ledger, malformed, nil,
    "EM06 changed source payload")

local unknown_reason = assert(edge_stats.summary(ineligible.ledger))
for _, evidence in pairs(unknown_reason.evidence_records) do
    if evidence.source_record.kind == "edge_credit_selection_eligibility" then
        evidence.source_record.reasons = {"unknown_reason"}
        break
    end
end
rejected_merge(plan_life.ledger, unknown_reason, nil,
    "EM07 unknown eligibility reason")

local malformed_halfway = assert(edge_stats.summary(eligible.ledger))
local second_ref
for ref in pairs(malformed_halfway.evidence_records) do
    if second_ref then
        malformed_halfway.evidence_records[ref].source_record = function() end
        break
    end
    second_ref = ref
end
rejected_merge(plan_life.ledger, malformed_halfway, nil,
    "EM10 malformed source halfway")

print("test_edge_stats_v3_promotion ok")
