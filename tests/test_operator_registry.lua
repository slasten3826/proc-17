package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local topology = require("core.topology")
local registry = require("runtime.operator_registry")

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

assert_eq(registry.protocol_version, "operator-registry.v0", "registry protocol")

local descriptors = registry.list()
assert_eq(#descriptors, 10, "every canonical operator is registered")
for index, descriptor in ipairs(descriptors) do
    local glyph = topology.order[index]
    assert_eq(descriptor.glyph, glyph, "registry preserves canonical order")
    assert_eq(descriptor.name, topology.operators[glyph].name, "registry name follows topology")
    assert_true(type(descriptor.run) == "function", glyph .. " has run contract")
    assert_true(type(descriptor.readiness) == "function", glyph .. " has readiness contract")
    assert_true(type(descriptor.reads) == "table", glyph .. " declares reads")
    assert_true(type(descriptor.writes) == "table", glyph .. " declares writes")
    assert_true(type(descriptor.required_capabilities) == "table", glyph .. " declares capabilities")
    assert_true(type(descriptor.loss_profile) == "string", glyph .. " declares loss profile")
end

assert_eq(registry.get("FLOW"), registry.get("▽"), "operator aliases resolve to one descriptor")
assert_eq(registry.get("CONNECT").glyph, "☰", "CONNECT is registered before live routing")
assert_eq(registry.get("DISSOLVE").glyph, "☷", "DISSOLVE is registered before live routing")

local p = packet.new("registry contract", {id = "registry-test"})
local flow_readiness = assert(registry.readiness("▽", p, {}))
assert_true(flow_readiness.ready, "FLOW is ready on a newborn packet")
local flow_payload, flow_err, flow_witness = registry.run("▽", p, {})
assert_true(flow_payload ~= nil, flow_err)
assert_eq(flow_payload.kind, "flow_organ_payload", "registry dispatches FLOW")
assert_true(flow_witness.ready, "run returns the readiness witness it used")

local repeated_flow = assert(registry.readiness("▽", p, {}))
assert_eq(repeated_flow.ready, false, "FLOW cannot rematerialize the same ingress")
assert_eq(repeated_flow.reason, "flow_already_materialized", "FLOW denial is explicit")

assert(packet.commit_transition(p, {
    from = "▽",
    to = "☴",
    reason = "registry_test",
}))

local observe_readiness = assert(registry.readiness("☴", p, {}))
assert_eq(observe_readiness.ready, false, "OBSERVE requires a semantic current")
assert_eq(observe_readiness.reason, "missing_capability", "capability denial reason")
assert_eq(observe_readiness.missing_capabilities[1], "substrate.ask", "missing capability is named")

local wrong, wrong_err = registry.run("☵", p, {})
assert_true(not wrong, "registry cannot run an organ away from packet position")
assert_eq(wrong_err, "operator position mismatch", "position denial reason")

print("test_operator_registry ok")
