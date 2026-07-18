package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local topology = require("core.topology")
local budget = require("runtime.budget")
local loss = require("runtime.loss")
local pressure = require("runtime.pressure")
local tree_router = require("runtime.tree_router")
local flow = require("organs.flow")
local observe = require("organs.observe")
local fake = require("substrates.fake")

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

local function find_candidate(candidates, target)
    for _, candidate in ipairs(candidates or {}) do
        if candidate.to == target then
            return candidate
        end
    end
    return nil
end

local p = packet.new("route the full tree in shadow", {
    id = "tree-router-test",
    metadata = {work_mode = "plan"},
    budget = {steps = 32, substrate_calls = 8, loss = 4},
})
assert(budget.init(p))
assert(loss.init(p))
assert(flow.run(p))
assert(packet.commit_transition(p, {from = "▽", to = "☴", reason = "tree_router_test"}))
assert(packet.begin_tick(p, "☴", {}))
assert(observe.run(p, fake, {work_mode = "plan"}))

local snapshot = assert(pressure.derive(p, {operator = "☴"}, {
    options = {work_mode = "plan"},
}))
local candidates = assert(tree_router.candidates(p, snapshot, {
    substrate = fake,
    options = {work_mode = "plan"},
    result = {ticks = {}},
}))

assert_eq(#candidates, #topology.operators["☴"].adjacent, "every canonical neighbor becomes an audited candidate")
for _, candidate in ipairs(candidates) do
    assert_true(topology.is_adjacent("☴", candidate.to), "candidate must be canon-adjacent")
    assert_true(type(candidate.exclusions) == "table", "candidate retains exclusions")
    assert_true(type(candidate.contributions) == "table", "candidate retains contributions")
end

local flow_candidate = assert(find_candidate(candidates, "▽"), "reverse FLOW edge remains visible")
assert_true(flow_candidate.excluded, "same-life return to FLOW is excluded")
assert_eq(flow_candidate.exclusions[1].reason, "living_packet_cannot_return_to_flow", "lifecycle denial is explicit")

local connect_candidate = assert(find_candidate(candidates, "☰"), "CONNECT candidate exists")
assert_true(not connect_candidate.excluded, "CONNECT is ready for two observed units")
assert_true(connect_candidate.total > 0, "relation debt gives CONNECT positive pressure")

local prediction = assert(tree_router.select(p, candidates))
assert_eq(prediction.kind, "tree_route_decision", "positive candidate produces prediction")
assert_eq(prediction.to, "☰", "canonical tie break prefers CONNECT over later equal candidates")
assert_eq(prediction.policy_status, "vibed_control", "prediction quality is not promoted to fact")

local reversed_tie = assert(tree_router.select(p, {
    {to = "☵", total = 1, excluded = false, exclusions = {}},
    {to = "☰", total = 1, excluded = false, exclusions = {}},
}))
assert_eq(reversed_tie.to, "☰", "tie break is canonical even if input order is reversed")

local no_viable = assert(tree_router.select(p, candidates, {threshold = 99}))
assert_eq(no_viable.kind, "no_viable_edge", "below threshold is a typed outcome")
assert_eq(no_viable.cause, "below_threshold", "no hidden fallback is invented")

local represented_edges = {}
for _, glyph in ipairs(topology.order) do
    local all = assert(tree_router.candidates(p, {
        kind = "edge_pressure_snapshot",
        current_operator = glyph,
        contributions = {},
    }, {
        substrate = fake,
        options = {work_mode = "plan"},
        result = {ticks = {}},
    }))
    for _, candidate in ipairs(all) do
        represented_edges[candidate.edge] = true
    end
end
local represented_count = 0
for _ in pairs(represented_edges) do
    represented_count = represented_count + 1
end
assert_eq(represented_count, 22, "candidate construction represents all canonical Tree edges")

print("test_tree_router ok")
