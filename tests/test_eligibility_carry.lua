package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")
local packet = require("core.packet")
local flow = require("organs.flow")
local flow_domain = require("runtime.flow_domain")
local packet_birth = require("runtime.packet_birth")
local pressure_composition = require("runtime.pressure_composition")
local qualified_pressure = require("runtime.qualified_pressure")
local router = require("runtime.router")
local tension_runner = require("runtime.tension_runner")
local fake = require("substrates.fake")

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

local function domain(id)
    return assert(flow_domain.new({2, 3, 5, 7}, {
        stream_id = id,
        source_ref = "fixture:" .. id,
    }))
end

local function born(id)
    local instance = assert(packet_birth.create(domain(id), "eligibility carry", {
        projection_adapter = "vertical_pair.v0",
    }))
    assert(flow.run(instance))
    return instance
end

local function candidate_to(candidates, target)
    for _, candidate in ipairs(candidates or {}) do
        if candidate.to == target then
            return candidate
        end
    end
    return nil
end

local function trace_by_id(instance, id)
    for _, event in ipairs(instance.trace or {}) do
        if event.id == id then
            return event
        end
    end
    return nil
end

local function route_event_for(instance, derivation_ref)
    for _, event in ipairs(instance.trace or {}) do
        if event.type == "route"
            and (event.payload or {}).derivation_ref == derivation_ref then
            return event
        end
    end
    return nil
end

-- Qualified candidates derive eligibility from the exact witness set and the
-- snapshot's typed unqualified channel.
local candidate_packet = born("eligibility-candidate")
local qualified_snapshot = assert(qualified_pressure.derive(candidate_packet, nil, {
    current_operator = "▽",
}))
local candidates = assert(pressure_composition.candidates(
    candidate_packet,
    qualified_snapshot,
    {substrate = fake}
))
local semantic_candidate = assert(candidate_to(candidates, "☴"))
assert_eq(semantic_candidate.promotion_eligible, true,
    "body semantic witness is candidate-eligible")
assert_eq(#semantic_candidate.promotion_ineligibility_reasons, 0,
    "eligible candidate has no hidden reason")
assert_eq(semantic_candidate.promotion_eligibility_basis.unqualified_snapshot,
    false, "eligible candidate names qualified snapshot")
assert_eq(#semantic_candidate.promotion_eligibility_basis.witness_ids, 1,
    "eligible candidate names its witness")

local fixture_candidate = assert(candidate_to(candidates, "☰"))
assert_eq(fixture_candidate.promotion_eligible, false,
    "fixture candidate cannot enter promotion corpus")
assert_true(contains(fixture_candidate.promotion_ineligibility_reasons,
    "fixture_witness"), "fixture reason is explicit")
assert_eq(#fixture_candidate.promotion_eligibility_basis.fixture_witness_ids, 1,
    "fixture basis names exact witness")

local unqualified_snapshot = assert(qualified_pressure.derive(candidate_packet, nil, {
    current_operator = "▽",
    ablate_relation_consumer = true,
}))
assert_true(#unqualified_snapshot.unqualified > 0,
    "control grows a typed unqualified diagnostic")
local unqualified_candidates = assert(pressure_composition.candidates(
    candidate_packet,
    unqualified_snapshot,
    {substrate = fake}
))
local unqualified_semantic = assert(candidate_to(unqualified_candidates, "☴"))
assert_eq(unqualified_semantic.promotion_eligible, false,
    "unqualified snapshot poisons candidate promotion only")
assert_true(contains(unqualified_semantic.promotion_ineligibility_reasons,
    "candidate_unqualified"), "unqualified reason is explicit")
assert_eq(unqualified_semantic.promotion_eligibility_basis.unqualified_snapshot,
    true, "basis preserves unqualified state")

-- Canonical fallback remains an observable control outcome, never a route.
local function synthetic(target)
    return {
        to = target,
        witnesses = {{witness_id = "fallback:" .. target}},
        witness_count = 1,
        highest_class = "blocking_demand",
        action_status = "validated",
        excluded = false,
        promotion_eligible = true,
        promotion_ineligibility_reasons = {},
        promotion_eligibility_basis = {
            witness_ids = {"fallback:" .. target},
            unqualified_snapshot = false,
            fixture_witness_ids = {},
        },
    }
end

local fallback = assert(pressure_composition.select(candidate_packet, {
    synthetic("☰"),
    synthetic("☴"),
}, {allow_control_fallback = true}))
assert_eq(fallback.kind, "control_selected", "fallback remains noncommittable")
assert_eq(fallback.promotion_eligible, false, "fallback cannot promote")
assert_true(contains(fallback.promotion_ineligibility_reasons,
    "control_fallback"), "fallback carries its reason")

local function vertical_options(id)
    return {
        packet_life = {
            protocol_version = "vertical_packet_life.v0",
            flow_domain = domain(id),
            projection_adapter = "vertical_pair.v0",
        },
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        work_mode = "plan",
        max_ticks = 1,
        legacy_shadow = false,
    }
end

-- A normal qualified selection carries one immutable triple through candidate,
-- derivation, decision and committed route.
local qualified_instance, qualified_result = assert(tension_runner.run(
    "qualified eligibility carry",
    fake,
    vertical_options("eligibility-qualified-route")
))
local qualified_route = assert(qualified_result.entry_route)
assert_eq(qualified_route.promotion_eligible, true,
    "qualified entry decision is eligible")
local qualified_derivation = assert(trace_by_id(
    qualified_instance,
    qualified_route.derivation_ref
))
local qualified_route_event = assert(route_event_for(
    qualified_instance,
    qualified_route.derivation_ref
))
for _, source in ipairs({
    qualified_route.selected_candidate,
    qualified_derivation.payload,
    qualified_route_event.payload,
}) do
    assert_eq(source.promotion_eligible, qualified_route.promotion_eligible,
        "eligibility boolean survives every boundary")
    assert_same(source.promotion_ineligibility_reasons,
        qualified_route.promotion_ineligibility_reasons,
        "eligibility reasons survive every boundary")
    assert_same(source.promotion_eligibility_basis,
        qualified_route.promotion_eligibility_basis,
        "eligibility basis survives every boundary")
end

qualified_route.promotion_eligibility_basis.witness_ids[1] = "mutated"
assert_true(qualified_route_event.payload.promotion_eligibility_basis
        .witness_ids[1] ~= "mutated",
    "committed route owns a detached eligibility snapshot")

-- A fixture-selected qualified route executes physically while staying
-- ineligible. Lack of substrate removes the competing semantic witness.
local fixture_instance, fixture_result = assert(tension_runner.run(
    "fixture eligibility carry",
    nil,
    vertical_options("eligibility-fixture-route")
))
local fixture_route = assert(fixture_result.entry_route)
assert_eq(fixture_route.to, "☰", "fixture route remains physically selected")
assert_eq(fixture_route.promotion_eligible, false,
    "fixture route remains promotion-ineligible")
assert_true(contains(fixture_route.promotion_ineligibility_reasons,
    "fixture_witness"), "fixture route preserves reason")
assert_true(#fixture_result.ticks == 1,
    "ineligibility does not prevent destination tick")
assert_true(fixture_instance.status ~= "born",
    "fixture route moved the Packet")

-- Binary Tree decisions are controls; a real tie names both reasons.
local binary_instance, binary_result = assert(tension_runner.run(
    "binary eligibility carry",
    fake,
    {
        router_mode = "tree",
        work_mode = "plan",
        max_ticks = 2,
        legacy_shadow = false,
    }
))
assert_eq(binary_result.entry_route.promotion_eligible, false,
    "binary entry is not qualified evidence")
assert_true(contains(binary_result.entry_route.promotion_ineligibility_reasons,
    "binary_policy_control"), "binary route names control policy")
local tied
for _, route in ipairs(binary_result.routes or {}) do
    if route.reason == "highest_pressure_canonical_tie_break" then
        tied = route
        break
    end
end
assert_true(tied ~= nil, "control grows a real binary tie")
assert_true(contains(tied.promotion_ineligibility_reasons,
    "binary_policy_control"), "tie remains binary control")
assert_true(contains(tied.promotion_ineligibility_reasons,
    "tie_only_selection"), "tie-only reason is explicit")
assert_true(binary_instance.runtime.budget.spent.steps > 0,
    "binary control still executes ordinary body ticks")

-- Missing classification is an instrumentation absence, not a movement veto.
local unclassified = packet.new("unclassified eligibility carry")
assert(flow.run(unclassified))
local decision = assert(router.derive_tree_authority(unclassified, {
    operator = "▽",
}, {
    substrate = fake,
    options = {work_mode = "plan"},
    tree = {},
}))
decision.promotion_eligible = nil
decision.promotion_ineligibility_reasons = nil
decision.promotion_eligibility_basis = nil
local unclassified_route = assert(packet.commit_transition(unclassified, decision))
assert_eq(unclassified.operator, decision.to,
    "missing eligibility cannot block lawful transition")
assert_eq(unclassified_route.payload.promotion_eligible, nil,
    "route remains honestly unclassified")

print("test_eligibility_carry ok")
