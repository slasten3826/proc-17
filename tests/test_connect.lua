package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local field = require("runtime.field")
local flow = require("organs.flow")
local connect = require("organs.connect")

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

local p = packet.new("connect two requirements", {id = "connect-test"})
local _, flow_payload = assert(flow.run(p))
local birth_event_id = p.trace[1].id
local second = assert(field.add_unit(p, "▽", {
    kind = "user_requirement",
    carrier = "run the tests",
    source_refs = {},
    event_truth_status = "runtime_confirmed",
    content_truth_status = "semantic_proposal",
    created_event_id = birth_event_id,
}))
local first = assert(field.get_unit(p, flow_payload.unit_id))

assert(packet.commit_transition(p, {from = "▽", to = "☰", reason = "connect_test"}))
assert(packet.begin_tick(p, "☰", {first.id, second.id}))

local potential_before = p.revisions.potential
local raw_before = p.revisions.relations_raw
local active_before = p.revisions.relations_active
local momentum_before = p.revisions.momentum
local connected, payload = connect.run(p, {
    candidates = {
        {
            from = first.id,
            to = second.id,
            kind = "requires",
            confidence = 0.9,
            source_refs = {first.id, second.id},
            content_truth_status = "semantic_proposal",
        },
    },
})

assert_true(connected, payload)
assert_eq(payload.kind, "connect_organ_payload", "CONNECT payload kind")
assert_eq(payload.status, "applied", "CONNECT applies candidate relation")
assert_eq(payload.loss.amount, 0, "CONNECT has zero direct identity loss")
assert_eq(payload.writes.relation_ids[1], "relation:1", "CONNECT gets deterministic relation id")
assert_eq(p.field.relations.raw.epoch, 1, "CONNECT advances raw epoch")
assert_eq(#p.field.relations.raw.items, 1, "CONNECT stores raw relation")
assert_eq(p.field.relations.raw.items[1].state, "raw", "CONNECT writes only raw relation")
assert_eq(p.field.relations.raw.items[1].content_truth_status, "semantic_proposal",
    "CONNECT cannot promote endpoint meaning")
assert_eq(p.revisions.relations_raw, raw_before + 1, "CONNECT owns raw revision")
assert_eq(p.revisions.relations_active, active_before, "CONNECT cannot activate relation")
assert_eq(p.revisions.momentum, momentum_before, "CONNECT cannot write momentum")
assert_eq(p.revisions.potential, potential_before, "CONNECT cannot remap potential")
assert_eq(p.operator, "☰", "CONNECT cannot route directly")
assert_eq(p.trace[#p.trace].type, "relation_snapshot", "CONNECT snapshot is trace-visible")
assert_eq(field.get_unit(p, first.id).carrier, first.carrier, "CONNECT preserves first carrier")
assert_eq(field.get_unit(p, second.id).carrier, second.carrier, "CONNECT preserves second carrier")

local activation_denied, activation_denied_err = field.activate_relations(p, "☰", {"relation:1"})
assert_true(not activation_denied, "CONNECT cannot preserve its own raw relation")
assert_eq(activation_denied_err, "only RUNTIME may activate raw relations", "active writer denial")
assert_eq(p.revisions.relations_active, active_before, "denied activation leaves active revision unchanged")

local denied_revision = p.revisions.relations_raw
local denied, denied_err = field.snapshot_raw_relations(p, "☵", {
    items = {},
    source_revision = p.revisions.potential,
})
assert_true(not denied, "ENCODE cannot impersonate CONNECT")
assert_eq(denied_err, "only CONNECT may snapshot raw relations", "raw writer denial")
assert_eq(p.revisions.relations_raw, denied_revision, "denied raw write leaves revision unchanged")

local no_op_packet, no_op = connect.run(p, {candidates = {}})
assert_true(no_op_packet, no_op)
assert_eq(no_op.status, "applied", "empty recognition still records a real snapshot")
assert_eq(no_op.outcome, "empty_snapshot", "empty recognition outcome is explicit")
assert_eq(no_op.reason, "no_relation_candidates", "no relation reason")
assert_eq(p.field.relations.raw.epoch, 2, "no-relation observation is a new raw epoch")
assert_eq(#p.field.relations.raw.items, 0, "new raw epoch replaces old transient snapshot")
assert_eq(p.revisions.relations_raw, denied_revision + 1, "no-relation epoch remains observable")

local lonely = packet.new("one unit only", {id = "connect-lonely"})
assert(flow.run(lonely))
assert(packet.commit_transition(lonely, {from = "▽", to = "☰", reason = "connect_lonely"}))
local lonely_witness = assert(connect.readiness(lonely))
assert_eq(lonely_witness.ready, false, "CONNECT requires two addressable units")
assert_eq(lonely_witness.reason, "no_relation_candidates", "CONNECT readiness reason")
local lonely_raw_revision = lonely.revisions.relations_raw
local missing, missing_err = connect.run(lonely)
assert_true(not missing, "unready CONNECT does not fake a successful tick")
assert_eq(missing_err, "no_relation_candidates", "unready CONNECT error")
assert_eq(lonely.revisions.relations_raw, lonely_raw_revision, "unready CONNECT does not mutate raw field")

print("test_connect ok")
