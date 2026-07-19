package.path = "./?.lua;./?/init.lua;" .. package.path

local flow = require("organs.flow")
local flow_domain = require("runtime.flow_domain")
local packet_birth = require("runtime.packet_birth")
local pressure_composition = require("runtime.pressure_composition")
local qualified_pressure = require("runtime.qualified_pressure")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": " .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function born(id)
    local domain = assert(flow_domain.new({2, 3, 5, 7}, {
        stream_id = id,
        source_ref = "fixture:" .. id,
    }))
    local instance = assert(packet_birth.create(domain, "compose pressure", {
        projection_adapter = "vertical_pair.v0",
    }))
    assert(flow.run(instance))
    return instance
end

-- A real qualified relation witness survives validation, readiness and
-- affordability and reaches selection with its action intact.
local ranked = born("composition-ranked")
local ranked_snapshot = assert(qualified_pressure.derive(ranked, nil, {
    current_operator = "▽",
}))
local bounded_candidates = assert(pressure_composition.candidates(
    ranked,
    ranked_snapshot,
    {}
))
local bounded_result = assert(pressure_composition.select(ranked, bounded_candidates))
assert_eq(bounded_result.to, "☰", "capability exclusion happens before class selection")
assert_true(bounded_result.selected_candidate.action_plan ~= nil,
    "selected edge carries its validated action")

local function synthetic(to, class, extra)
    local value = {
        to = to,
        witnesses = {{causal_class = class}},
        witness_count = 1,
        highest_class = class,
        action_status = "validated",
        excluded = false,
        promotion_eligible = true,
    }
    for key, child in pairs(extra or {}) do
        value[key] = child
    end
    return value
end

-- PR-C1: a blocking demand outranks a canonically earlier affordance.
local ranked_result = assert(pressure_composition.select(ranked, {
    synthetic("☰", "causal_affordance"),
    synthetic("☴", "blocking_demand"),
}))
assert_eq(ranked_result.kind, "tree_route_decision", "unique highest class selects")
assert_eq(ranked_result.to, "☴", "blocking demand beats relation affordance")
assert_eq(ranked_result.causal_class, "blocking_demand", "winning class is explicit")

-- PR-C2: an honest terminal boundary dominates nonterminal work in the pure
-- composition law. Production terminal action remains deferred by blueprint.
local terminal = assert(pressure_composition.select(ranked, {
    synthetic("△", "terminal_boundary"),
    synthetic("☴", "blocking_demand"),
}))
assert_eq(terminal.to, "△", "terminal boundary has highest class")

-- PR-C4: excluded control noise cannot suppress one executable affordance.
local noise = assert(pressure_composition.select(ranked, {
    synthetic("☰", "causal_affordance"),
    synthetic("☴", "blocking_demand", {excluded = true}),
}))
assert_eq(noise.to, "☰", "unique executable affordance survives excluded noise")

-- PR-C3: two independent demands are not silently settled by glyph order.
local ambiguous_candidates = {
    synthetic("☰", "blocking_demand"),
    synthetic("☴", "blocking_demand"),
}
local ambiguous = assert(pressure_composition.select(ranked, ambiguous_candidates))
assert_eq(ambiguous.kind, "ambiguous_pressure", "equal demands stay ambiguous")
assert_eq(ambiguous.promotion_eligible, false, "ambiguity cannot promote")

-- PR-C9: a canonical fallback is an explicit control, never evidence.
local fallback = assert(pressure_composition.select(ranked, ambiguous_candidates, {
    allow_control_fallback = true,
}))
assert_eq(fallback.kind, "control_selected", "fallback has a separate result kind")
assert_eq(fallback.to, "☰", "control fallback is deterministic")
assert_eq(fallback.selection_reason, "canonical_control_fallback",
    "fallback reason cannot masquerade as pressure")
assert_eq(fallback.promotion_eligible, false, "fallback remains promotion-ineligible")

-- PR-C6: incompatible actions on one edge produce their own typed result.
local action_ambiguity = assert(pressure_composition.select(ranked, {
    synthetic("☴", "blocking_demand", {
        action_status = "ambiguous_action",
        action_error = "ambiguous_action: incompatible modes",
    }),
}))
assert_eq(action_ambiguity.kind, "ambiguous_action", "action conflict is typed")

local none = assert(pressure_composition.select(ranked, {}))
assert_eq(none.kind, "no_qualified_need", "absence is not a routing failure")

local excluded = assert(pressure_composition.select(ranked, {
    synthetic("☰", "causal_affordance", {excluded = true}),
}))
assert_eq(excluded.kind, "no_viable_edge", "physical exclusion is distinct from absence")

print("test_pressure_composition ok")
