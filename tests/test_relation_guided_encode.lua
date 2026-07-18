package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local field = require("runtime.field")
local flow = require("organs.flow")
local connect = require("organs.connect")
local observe = require("organs.observe")
local encode = require("organs.encode")
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

local domain = assert(flow_domain.new({8, 13, 21, 34, 55}, {
    stream_id = "relation-encode",
    source_ref = "fixture:relation-encode",
}))
local instance = assert(packet_birth.create(domain, "form relation", {
    projection_adapter = "vertical_pair.v0",
}))
assert(flow.run(instance))
assert(packet.commit_transition(instance, {
    from = "▽", to = "☰", reason = "relation_encode_connect",
    authority = "harness_override",
}))
assert(packet.begin_tick(instance, "☰", {}))
assert(connect.run(instance))
local relation = instance.field.relations.raw.items[1]
assert(packet.commit_transition(instance, {
    from = "☰", to = "☴", reason = "relation_encode_observe",
    authority = "harness_override",
}))
assert(packet.begin_tick(instance, "☴", {}))
assert(observe.run(instance, nil, {
    sensor = "relation_native",
    relation_input = {
        raw_epoch = 1,
        relation_ids = {relation.id},
        endpoint_versions = relation.endpoint_versions,
    },
}))
assert(packet.commit_transition(instance, {
    from = "☴", to = "☵", reason = "relation_encode_form",
    authority = "harness_override",
}))
assert(packet.begin_tick(instance, "☵", {}))

local options = {
    relation_input = {
        raw_epoch = 1,
        relation_ids = {relation.id},
        endpoint_versions = relation.endpoint_versions,
        requested_shape = "bounded_relation_form",
    },
}
local ready = assert(encode.readiness(instance, options))
assert_true(ready.ready, "observed raw relation is formable")
local active_before = instance.revisions.relations_active
local _, payload = assert(encode.run(instance, options))
assert_eq(payload.mode, "relation_guided", "relation encode mode")
assert_eq(payload.formation_basis, "relation_guided", "formation basis is explicit")
assert_eq(payload.loss.kind, "relation_formation_loss", "relation formation loss kind")
assert_eq(payload.loss.loss_percentage, 0.5, "two endpoint identities compact to one form")
assert_eq(instance.calm.current.kind, "relation_formed_calm", "CALM owns retained form")
assert_eq(instance.calm.current.relation_formation.protocol_version,
    "l2.relation_formation.v0", "CALM formation protocol")
assert_eq(instance.calm.current.relation_formation.identity_map_ref,
    "identity_map:1", "CALM references planned identity map without rewrite")
assert_eq(payload.identity_map.id, "identity_map:1", "identity map id matches CALM")
assert_eq(payload.identity_map.mapping_kind, "relation_guided", "mapping basis")
assert_eq(#payload.relation_formation.formed_unit_ids, 1, "one relation creates one formed unit")
local formed_id = payload.relation_formation.formed_unit_ids[1]
assert_eq(field.get_unit(instance, formed_id).kind, "formed_relation", "formed field unit kind")
assert_eq(field.get_unit(instance, formed_id).content_truth_status,
    "non_semantic_measurement", "formation preserves source content truth")
assert_eq(instance.revisions.relations_active, active_before,
    "ENCODE does not use legacy active relation graph")
assert_eq(#instance.field.relations.active, 0, "retained form lives in CALM, not active graph")
assert_eq(assert(field.raw_relation_phase(instance, 1, relation.id)).phase,
    "encoded", "formation event terminally consumes raw identity")
assert_true(payload.formation_event_id ~= nil, "dedicated formation event is visible")

local second_ready = assert(encode.readiness(instance, options))
assert_true(not second_ready.ready, "encoded raw identity cannot form twice")
assert_eq(second_ready.reason, "raw relation is not formable from phase encoded",
    "second formation denial")

local wrong_versions = {}
for id, version in pairs(relation.endpoint_versions) do
    wrong_versions[id] = version + 1
end
local wrong = assert(encode.readiness(instance, {
    relation_input = {
        raw_epoch = 1,
        relation_ids = {relation.id},
        endpoint_versions = wrong_versions,
    },
}))
assert_true(not wrong.ready, "wrong endpoint versions cannot claim relation formation")
assert_eq(wrong.reason, "raw relation endpoint versions do not match",
    "version mismatch is explicit")

local ordinary = packet.new("ordinary encode remains a control")
assert(packet.commit_transition(ordinary, {
    from = "▽", to = "☴", reason = "ordinary_encode_control_eye",
}))
assert(packet.commit_transition(ordinary, {
    from = "☴", to = "☵", reason = "ordinary_encode_control",
}))
assert(packet.begin_tick(ordinary, "☵", {}))
local _, ordinary_payload = assert(encode.run(ordinary))
assert_eq(ordinary_payload.formation_basis, "semantic_text",
    "ordinary ENCODE cannot claim relation-guided formation")

print("test_relation_guided_encode ok")
