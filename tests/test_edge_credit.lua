package.path = "./?.lua;./?/init.lua;" .. package.path

local authority_epoch = require("runtime.authority_epoch")
local credit = require("runtime.edge_credit")
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

local function contains(values, expected)
    for _, value in ipairs(values or {}) do
        if value == expected then
            return true
        end
    end
    return false
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
    local record, err = authority_epoch.resolve(options)
    assert_true(record ~= nil, err and err.code or err)
    return record
end

local qualified_epoch = resolve({
    router_mode = "tree",
    legacy_shadow = false,
    pressure_policy = "qualified_need_v0",
})

local binary_epoch = resolve({
    router_mode = "tree",
    legacy_shadow = false,
})

local function state(label, epoch_record)
    local result, err = credit.new(epoch_record, {
        life_id = "life:" .. label,
        packet_id = "packet:" .. label,
        lineage_id = "lineage:" .. label,
        generation = 1,
    })
    assert_true(result ~= nil, err and err.code or err)
    return result
end

local function triple(eligible, reasons, options)
    options = options or {}
    return {
        promotion_eligible = eligible,
        promotion_ineligibility_reasons = copy_value(reasons or {}),
        promotion_eligibility_basis = {
            witness_ids = copy_value(options.witness_ids or {"witness:body"}),
            unqualified_snapshot = options.unqualified_snapshot == true,
            fixture_witness_ids = copy_value(options.fixture_witness_ids or {}),
        },
    }
end

local function install_triple(target, value)
    target.promotion_eligible = value.promotion_eligible
    target.promotion_ineligibility_reasons = copy_value(
        value.promotion_ineligibility_reasons
    )
    target.promotion_eligibility_basis = copy_value(
        value.promotion_eligibility_basis
    )
    return target
end

local function tree_route(label, eligibility, options)
    options = options or {}
    local from = options.from or "▽"
    local to = options.to or "☴"
    local pressure_ref = "pressure:" .. label
    local derivation_ref = "derivation:" .. label
    local action_plan_id = options.no_action and nil or "action:" .. label
    local selected = install_triple({
        to = to,
        readiness = {ready = true},
        action_plan = action_plan_id and {plan_id = action_plan_id} or nil,
    }, eligibility)
    local decision = install_triple({
        kind = "tree_route_decision",
        from = from,
        to = to,
        reason = options.reason or "qualified_test_route",
        authority = "tree",
        derivation_ref = derivation_ref,
        pressure_snapshot_ref = pressure_ref,
        selected_action_plan_id = action_plan_id,
        selected_candidate = copy_value(selected),
        truth_status = "runtime_confirmed",
    }, eligibility)
    local derivation_payload = install_triple({
        kind = "route_derivation",
        current_operator = from,
        selected_to = to,
        outcome = "selected",
        pressure_snapshot_ref = pressure_ref,
        selected_action_plan_id = action_plan_id,
        selected_candidate = copy_value(selected),
    }, eligibility)
    local derivation_event = {
        id = derivation_ref,
        type = "route_derivation",
        operator = from,
        truth_status = "runtime_confirmed",
        payload = derivation_payload,
    }
    local route_payload = install_triple({
        kind = "tree_route_decision",
        from = from,
        to = to,
        authority = "tree",
        derivation_ref = derivation_ref,
        pressure_snapshot_ref = pressure_ref,
        selected_action_plan_id = action_plan_id,
    }, eligibility)
    local route_event = {
        id = "route:" .. label,
        type = "route",
        operator = to,
        truth_status = "runtime_confirmed",
        payload = route_payload,
    }
    return {
        decision = decision,
        derivation_event = derivation_event,
        route_event = route_event,
    }
end

local function non_tree_route(label, authority)
    local decision = {
        kind = "route_decision",
        from = "▽",
        to = "☴",
        reason = authority .. "_test_route",
        authority = authority,
        truth_status = "runtime_confirmed",
    }
    return {
        decision = decision,
        route_event = {
            id = "route:" .. label,
            type = "route",
            operator = "☴",
            truth_status = "runtime_confirmed",
            payload = {
                kind = "route_decision",
                from = "▽",
                to = "☴",
                authority = authority,
            },
        },
    }
end

local function prepare(state_value, route, ordinal)
    local selection, err = credit.prepare(state_value, route.decision, {
        route_ordinal = ordinal,
        derivation_event = route.derivation_event,
    })
    assert_true(selection ~= nil, err and err.code or err)
    return selection
end

local function commit(state_value, selection, route)
    local committed, taint, err = credit.record_commit(
        state_value,
        selection,
        route.route_event
    )
    assert_true(committed ~= nil, err and err.code or err or taint)
    return committed, taint
end

local function arrive(state_value, committed, label)
    local arrival, decision, err = credit.record_arrival(state_value, committed, {
        destination_tick_ref = "tick:" .. label,
        effect_refs = {"effect:" .. label},
        payload_kind = "test_payload",
    })
    assert_true(arrival ~= nil, err and err.code or err)
    return arrival, decision
end

local function event_by_kind(state_value, kind)
    for _, event in ipairs(state_value.events or {}) do
        if event.kind == kind then
            return event
        end
    end
    return nil
end

local function decision_by_ref(state_value, ref)
    for _, event in ipairs(state_value.events or {}) do
        if event.kind == "edge_credit_decision"
            and event.credit_decision_ref == ref then
            return event
        end
    end
    return nil
end

-- EC01: an exact qualified route reaches a real credited arrival.
local ec01 = state("ec01", qualified_epoch)
local ec01_route = tree_route("ec01", triple(true))
local ec01_selection = prepare(ec01, ec01_route, 1)
assert_eq(ec01_selection.classification_status, "classified", "EC01 classified")
assert_eq(ec01_selection.eligibility.status, "eligible", "EC01 selection eligible")
local ec01_commit, ec01_taint = commit(ec01, ec01_selection, ec01_route)
assert_eq(ec01_taint, nil, "EC01 does not taint authority")
local ec01_arrival, ec01_decision = arrive(ec01, ec01_commit, "ec01")
assert_eq(ec01_decision.status, "credited", "EC01 arrival is credited")
assert_eq(ec01_decision.arrival_ref, ec01_arrival.record_id, "EC01 binds arrival")
assert_true(credit.verify(ec01), "EC01 state verifies")

-- Returned records are detached snapshots, not aliases into the state.
ec01_selection.classification_status = "tampered"
assert_eq(event_by_kind(ec01, "route_evidence_selection").classification_status,
    "classified", "selection return cannot mutate stored evidence")

-- Stored history is ordinary Lua data, so verification must catch direct
-- post-append mutation rather than trusting an append-only array by convention.
local ec01_corrupted = assert(credit.snapshot(ec01))
event_by_kind(ec01_corrupted, "route_evidence_selection").to = "☵"
local ec01_corrupt_ok, ec01_corrupt_err = credit.verify(ec01_corrupted)
assert_eq(ec01_corrupt_ok, nil, "mutated stored evidence is rejected")
assert_true(ec01_corrupt_err ~= nil, "mutation returns a typed verifier error")
assert_true(credit.verify(ec01), "corruption probe cannot alter source state")

-- EC02: an ineligible candidate remains physical but cannot be credited.
local ec02 = state("ec02", qualified_epoch)
local ec02_route = tree_route("ec02", triple(false, {"candidate_unqualified"}, {
    unqualified_snapshot = true,
}))
local ec02_selection = prepare(ec02, ec02_route, 1)
local ec02_commit = commit(ec02, ec02_selection, ec02_route)
local _, ec02_decision = arrive(ec02, ec02_commit, "ec02")
assert_eq(ec02_decision.status, "rejected", "EC02 cannot receive credit")
assert_true(contains(ec02_decision.reasons, "candidate_unqualified"),
    "EC02 retains candidate reason")

-- EC03: a harness route is classified physical control evidence and taints
-- later authority without masquerading as Tree evidence.
local ec03 = state("ec03", qualified_epoch)
local ec03_route = non_tree_route("ec03", "harness_override")
local ec03_selection = prepare(ec03, ec03_route, 1)
assert_eq(ec03_selection.eligibility.status, "ineligible", "EC03 is ineligible")
assert_true(contains(ec03_selection.eligibility.reasons, "harness_override"),
    "EC03 names harness authority")
local ec03_commit, ec03_taint = commit(ec03, ec03_selection, ec03_route)
assert_true(ec03_taint ~= nil, "EC03 commits monotonic authority taint")
local _, ec03_decision = arrive(ec03, ec03_commit, "ec03")
assert_eq(ec03_decision.status, "rejected", "EC03 physical arrival is rejected")

-- EC04: binary Tree authority is a real execution but not qualified evidence.
local ec04 = state("ec04", binary_epoch)
local ec04_route = tree_route("ec04", triple(false, {"binary_policy_control"}), {
    no_action = true,
})
local ec04_selection = prepare(ec04, ec04_route, 1)
assert_true(contains(ec04_selection.eligibility.reasons, "binary_policy_control"),
    "EC04 names binary control")
local ec04_commit = commit(ec04, ec04_selection, ec04_route)
local _, ec04_decision = arrive(ec04, ec04_commit, "ec04")
assert_eq(ec04_decision.status, "rejected", "EC04 cannot close qualified edge")

-- EC05: host ceiling preserves commit and pending, never execution credit.
local ec05 = state("ec05", qualified_epoch)
local ec05_route = tree_route("ec05", triple(true))
local ec05_selection = prepare(ec05, ec05_route, 1)
local ec05_commit = commit(ec05, ec05_selection, ec05_route)
local ec05_pending, ec05_pending_err = credit.record_pending(ec05, ec05_commit, {
    stop_reason = "tick_limit",
})
assert_true(ec05_pending ~= nil, ec05_pending_err and ec05_pending_err.code)
assert_eq(event_by_kind(ec05, "edge_credit_decision"), nil,
    "EC05 pending creates no decision")

-- EC06: typed destination failure is not successful arrival evidence.
local ec06 = state("ec06", qualified_epoch)
local ec06_route = tree_route("ec06", triple(true))
local ec06_selection = prepare(ec06, ec06_route, 1)
local ec06_commit = commit(ec06, ec06_selection, ec06_route)
local ec06_failure, ec06_failure_err = credit.record_failure(ec06, ec06_commit, {
    destination_tick_ref = "tick:ec06",
    failure_ref = "failure:ec06",
    failure_kind = "typed_effect_failure",
})
assert_true(ec06_failure ~= nil, ec06_failure_err and ec06_failure_err.code)
assert_eq(event_by_kind(ec06, "edge_credit_decision"), nil,
    "EC06 failure creates no decision")

-- EC07: a missing Tree eligibility chain remains unclassified even after an
-- otherwise successful physical destination tick.
local ec07 = state("ec07", qualified_epoch)
local ec07_route = tree_route("ec07", triple(true))
ec07_route.decision.promotion_eligible = nil
ec07_route.decision.promotion_ineligibility_reasons = nil
ec07_route.decision.promotion_eligibility_basis = nil
ec07_route.route_event.payload.promotion_eligible = nil
ec07_route.route_event.payload.promotion_ineligibility_reasons = nil
ec07_route.route_event.payload.promotion_eligibility_basis = nil
local ec07_selection = prepare(ec07, ec07_route, 1)
assert_eq(ec07_selection.classification_status, "unclassified",
    "EC07 remains unclassified")
assert_true(contains(ec07_selection.classification_error_codes,
    "eligibility_chain_missing"), "EC07 names missing chain")
local ec07_commit = commit(ec07, ec07_selection, ec07_route)
local _, ec07_decision = arrive(ec07, ec07_commit, "ec07")
assert_eq(ec07_decision, nil, "EC07 cannot fabricate final eligibility")
assert_true(event_by_kind(ec07, "authority_instrument_error") ~= nil,
    "EC07 writes a typed instrument error")

-- EC08: a successful and explicitly evidenced effect cannot launder a route
-- that was already ineligible at selection time.
local ec08 = state("ec08", qualified_epoch)
local ec08_route = tree_route("ec08", triple(false, {"fixture_witness"}, {
    witness_ids = {"witness:fixture"},
    fixture_witness_ids = {"witness:fixture"},
}))
local ec08_selection = prepare(ec08, ec08_route, 1)
local ec08_commit = commit(ec08, ec08_selection, ec08_route)
local ec08_arrival, ec08_decision = arrive(ec08, ec08_commit, "ec08")
assert_eq(#ec08_arrival.effect_refs, 1, "EC08 has successful effect evidence")
assert_eq(ec08_decision.status, "rejected", "EC08 cannot launder selection")
assert_true(contains(ec08_decision.reasons, "fixture_witness"),
    "EC08 keeps immutable selection reason")

-- EC09: an arrival replay is rejected transactionally.
local ec09 = state("ec09", qualified_epoch)
local ec09_route = tree_route("ec09", triple(true))
local ec09_selection = prepare(ec09, ec09_route, 1)
local ec09_commit = commit(ec09, ec09_selection, ec09_route)
arrive(ec09, ec09_commit, "ec09")
local ec09_before = assert(credit.snapshot(ec09))
local replay_arrival, replay_decision, replay_err = credit.record_arrival(
    ec09,
    ec09_commit,
    {
        destination_tick_ref = "tick:ec09",
        effect_refs = {"effect:ec09"},
        payload_kind = "test_payload",
    }
)
assert_eq(replay_arrival, nil, "EC09 replay rejected")
assert_eq(replay_decision, nil, "EC09 replay has no second decision")
assert_eq(replay_err.code, "route_phase_replayed", "EC09 typed replay error")
assert_same(assert(credit.snapshot(ec09)), ec09_before,
    "EC09 rejection leaves state unchanged")

-- EC10: route/epoch identity mismatch is an instrument error and cannot
-- partially append a commit.
local ec10 = state("ec10", qualified_epoch)
local ec10_route = tree_route("ec10", triple(true))
local ec10_selection = prepare(ec10, ec10_route, 1)
local ec10_before = assert(credit.snapshot(ec10))
ec10_route.route_event.payload.pressure_snapshot_ref = "pressure:foreign"
local bad_commit, bad_taint, bad_commit_err = credit.record_commit(
    ec10,
    ec10_selection,
    ec10_route.route_event
)
assert_eq(bad_commit, nil, "EC10 mismatched commit rejected")
assert_eq(bad_taint, nil, "EC10 cannot taint on rejected evidence")
assert_eq(bad_commit_err.code, "route_identity_mismatch",
    "EC10 names route identity mismatch")
assert_same(assert(credit.snapshot(ec10)), ec10_before,
    "EC10 failure is mutation-free")

-- EC11: once a harness commit taints the life, a later clean-looking Tree
-- route remains ineligible.
local ec11 = state("ec11", qualified_epoch)
local ec11_harness = non_tree_route("ec11-harness", "harness_override")
local ec11_harness_selection = prepare(ec11, ec11_harness, 1)
local ec11_harness_commit = commit(ec11, ec11_harness_selection, ec11_harness)
arrive(ec11, ec11_harness_commit, "ec11-harness")
local ec11_tree = tree_route("ec11-tree", triple(true))
local ec11_tree_selection = prepare(ec11, ec11_tree, 2)
assert_eq(ec11_tree_selection.eligibility.status, "ineligible",
    "EC11 later Tree route is ineligible")
assert_true(contains(ec11_tree_selection.eligibility.reasons,
    "authority_tainted"), "EC11 names prior authority taint")
local ec11_tree_commit = commit(ec11, ec11_tree_selection, ec11_tree)
local _, ec11_tree_decision = arrive(ec11, ec11_tree_commit, "ec11-tree")
assert_eq(ec11_tree_decision.status, "rejected", "EC11 cannot regain credit")
assert_true(credit.verify(ec11), "EC11 state verifies after mixed authority")

-- EC12: a later harness route cannot rewrite an earlier credited decision.
local ec12 = state("ec12", qualified_epoch)
local ec12_tree = tree_route("ec12-tree", triple(true))
local ec12_tree_selection = prepare(ec12, ec12_tree, 1)
local ec12_tree_commit = commit(ec12, ec12_tree_selection, ec12_tree)
local _, ec12_first_decision = arrive(ec12, ec12_tree_commit, "ec12-tree")
local first_ref = ec12_first_decision.credit_decision_ref
local ec12_harness = non_tree_route("ec12-harness", "harness_override")
local ec12_harness_selection = prepare(ec12, ec12_harness, 2)
local ec12_harness_commit = commit(ec12, ec12_harness_selection, ec12_harness)
arrive(ec12, ec12_harness_commit, "ec12-harness")
local ec12_snapshot = assert(credit.snapshot(ec12))
assert_eq(assert(decision_by_ref(ec12_snapshot, first_ref)).status, "credited",
    "EC12 preserves earlier credit")
assert_true(credit.authority_taint(ec12) ~= nil,
    "EC12 still exposes later taint")

-- Exact same inputs reproduce route and record identity.
local deterministic_a = state("deterministic", qualified_epoch)
local deterministic_b = state("deterministic", qualified_epoch)
local deterministic_route_a = tree_route("deterministic", triple(true))
local deterministic_route_b = tree_route("deterministic", triple(true))
local deterministic_selection_a = prepare(deterministic_a, deterministic_route_a, 1)
local deterministic_selection_b = prepare(deterministic_b, deterministic_route_b, 1)
assert_eq(deterministic_selection_a.route_evidence_id,
    deterministic_selection_b.route_evidence_id,
    "route evidence identity is deterministic")
assert_eq(deterministic_selection_a.record_id,
    deterministic_selection_b.record_id,
    "selection record identity is deterministic")

print("test_edge_credit ok")
