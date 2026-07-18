package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local budget = require("runtime.budget")
local loss = require("runtime.loss")
local pressure = require("runtime.pressure")
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

local function find_kind(snapshot, kind)
    for _, value in ipairs(snapshot.contributions or {}) do
        if value.kind == kind then
            return value
        end
    end
    return nil
end

local p = packet.new("derive named pressure", {
    id = "pressure-test",
    metadata = {work_mode = "plan"},
    budget = {steps = 32, substrate_calls = 8, loss = 4},
})
assert(budget.init(p))
assert(loss.init(p))
assert(flow.run(p))
assert(packet.commit_transition(p, {
    from = "▽",
    to = "☴",
    reason = "pressure_test",
}))
assert(packet.begin_tick(p, "☴", {}))
assert(observe.run(p, fake, {work_mode = "plan"}))

local trace_before = #p.trace
local revisions_before = {}
for key, value in pairs(p.revisions) do
    revisions_before[key] = value
end
local snapshot = assert(pressure.derive(p, {operator = "☴", work_mode = "plan"}, {
    options = {work_mode = "plan"},
}))

assert_eq(snapshot.kind, "edge_pressure_snapshot", "pressure snapshot kind")
assert_eq(snapshot.derivation_version, "pressure.binary.v0", "pressure policy version")
assert_eq(snapshot.calibration_status, "vibed_control", "binary control is not claimed measured")
assert_eq(snapshot.runtime_policy, "camera_reconciliation", "camera policy is the default shadow treatment")
assert_eq(snapshot.current_operator, "☴", "snapshot uses post-tick position")
assert_eq(#p.trace, trace_before, "pressure derivation is pure before router records it")
for key, value in pairs(revisions_before) do
    assert_eq(p.revisions[key], value, "pressure cannot mutate revision " .. key)
end

local relation = assert(find_kind(snapshot, "relation_debt"), "relation debt should be derived")
assert_eq(relation.target_operator, "☰", "relation debt targets CONNECT")
assert_eq(relation.amount, 1, "binary help amount")
assert_true(#relation.source_refs >= 2, "relation debt retains concrete unit refs")

local encoding = assert(find_kind(snapshot, "encoding_debt"), "encoding debt should be derived")
assert_eq(encoding.target_operator, "☵", "encoding debt targets ENCODE")
assert_eq(encoding.source_truth_status, "runtime_confirmed", "derivation source status is explicit")

assert_eq(find_kind(snapshot, "lower_observation_debt"), nil,
    "missing sampled lower eye is not camera reconciliation pressure")
assert_eq(find_kind(snapshot, "runtime_mismatch"), nil,
    "runtime mismatch requires an independent comparator")

local sampled = assert(pressure.derive(p, {operator = "☴", work_mode = "plan"}, {
    options = {work_mode = "plan", pressure_policy = "sampled"},
}))
local lower = assert(find_kind(sampled, "lower_observation_debt"),
    "sampled control preserves historical lower-eye pressure")
assert_eq(lower.target_operator, "☱", "sampled lower debt targets RUNTIME")
assert_eq(lower.freshness, "missing", "sampled control distinguishes missing sight")

local seen = {}
for _, value in ipairs(snapshot.contributions) do
    assert_true(#value.source_refs > 0, value.kind .. " must have provenance")
    assert_eq(value.amount, 1, value.kind .. " follows binary control")
    local key = value.kind .. "|" .. value.target_edge .. "|" .. value.direction
    assert_true(not seen[key], "duplicate pressure kind/edge must collapse")
    seen[key] = true
end

assert(packet.commit_transition(p, {
    from = "☴",
    to = "☵",
    reason = "pressure_test_staleness",
}))
local after_observe = assert(pressure.derive(p, {operator = "☵"}, {
    options = {work_mode = "plan"},
}))
assert_eq(find_kind(after_observe, "upper_observation_debt"), nil,
    "OBSERVE scope and sensor output do not create self-observation pressure")
local sampled_after_observe = assert(pressure.derive(p, {operator = "☵"}, {
    options = {work_mode = "plan", pressure_policy = "sampled"},
}))
local upper = assert(find_kind(sampled_after_observe, "upper_observation_debt"),
    "sampled control preserves historical upper-eye revision staleness")
assert_eq(upper.target_operator, "☴", "upper debt points back to upper eye")
assert_eq(upper.freshness, "stale", "sampled own output remains deferred staleness")

print("test_pressure ok")
