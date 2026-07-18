package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local field = require("runtime.field")
local registry = require("runtime.operator_registry")
local flow = require("organs.flow")
local connect = require("organs.connect")
local flow_domain = require("runtime.flow_domain")
local packet_birth = require("runtime.packet_birth")

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

local domain = assert(flow_domain.new({1, 4, 9, 16, 25}, {
    stream_id = "native-observe",
    source_ref = "fixture:native-observe",
}))
local instance = assert(packet_birth.create(domain, "observe raw relation", {
    projection_adapter = "vertical_pair.v0",
}))
assert(flow.run(instance))
assert(packet.commit_transition(instance, {
    from = "▽", to = "☰", reason = "native_observe_connect",
    authority = "harness_override",
}))
assert(packet.begin_tick(instance, "☰", {}))
assert(connect.run(instance))
local relation = instance.field.relations.raw.items[1]
assert(packet.commit_transition(instance, {
    from = "☰", to = "☴", reason = "native_observe",
    authority = "harness_override",
}))
assert(packet.begin_tick(instance, "☴", {}))

local context = {
    options = {
        observe = {
            sensor = "relation_native",
            relation_input = {
                raw_epoch = 1,
                relation_ids = {relation.id},
                endpoint_versions = relation.endpoint_versions,
                source_event_refs = {relation.origin_event_id},
            },
        },
    },
}
local available, available_reason, missing, required = registry.available("☴", instance, context)
assert_true(available, available_reason)
assert_eq(#missing, 0, "native sensor misses no capability")
assert_eq(#required, 0, "native sensor requires no substrate capability")
local ready = assert(registry.readiness("☴", instance, context))
assert_true(ready.ready, "unobserved raw relation is ready for native sight")

local field_count = #instance.field.unit_order
local chaos_count = #instance.chaos.fragments
local active_count = #instance.field.relations.active
local calm_count = #instance.calm.structures
local payload, run_err = registry.run("☴", instance, context)
assert_true(payload ~= nil, run_err)
assert_eq(payload.sensor, "relation_native", "native sensor is explicit")
assert_eq(payload.substrate_called, false, "native sensor does not call substrate")
assert_eq(payload.field_unit_id, nil, "native sensor creates no field unit")
assert_eq(#instance.field.unit_order, field_count, "native sight does not grow field")
assert_eq(#instance.chaos.fragments, chaos_count, "native sight does not append semantic chaos")
assert_eq(#instance.field.relations.active, active_count, "native sight does not retain relation")
assert_eq(#instance.calm.structures, calm_count, "native sight does not form CALM")
assert_eq(instance.boundary.observations.upper[#instance.boundary.observations.upper].fidelity,
    "body_native", "observation envelope records body-native fidelity")
assert_true(instance.boundary.observations.upper[#instance.boundary.observations.upper]
    .read_units.capture_event_ref ~= nil, "native coverage names observation event")
assert_eq(assert(field.raw_relation_phase(instance, 1, relation.id)).phase,
    "observed", "native observation changes only derived phase")

local repeated = assert(registry.readiness("☴", instance, context))
assert_true(not repeated.ready, "same raw relation is not observed twice")
assert_eq(repeated.reason, "relation_native_current", "repeat denial is exact")

local semantic_packet = packet.new("semantic capability control")
assert(packet.commit_transition(semantic_packet, {
    from = "▽", to = "☴", reason = "semantic_control",
}))
local semantic = assert(registry.readiness("☴", semantic_packet, {}))
assert_true(not semantic.ready, "semantic OBSERVE still requires substrate")
assert_eq(semantic.reason, "missing_capability", "semantic capability control remains")

print("test_relation_native_observe ok")
