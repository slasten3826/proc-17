package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local field = require("runtime.field")
local flow = require("organs.flow")
local connect = require("organs.connect")
local flow_domain = require("runtime.flow_domain")
local packet_birth = require("runtime.packet_birth")
local object_coverage = require("runtime.object_coverage")

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

local entries = {
    {object_kind = "field_unit", object_id = "unit:1", version = 1,
        activation_at_coverage = "live", source_ref = "unit:1"},
    {object_kind = "field_unit", object_id = "unit:2", version = 1,
        activation_at_coverage = "live", source_ref = "unit:2"},
}
local captured = assert(object_coverage.capture(entries, {
    domain = "relation",
    policy_id = "test.v0",
    global_revision = 2,
}))
local fresh = assert(object_coverage.diff(captured, entries, {
    domain = "relation",
    policy_id = "test.v0",
}))
assert_eq(fresh.changed_count, 0, "identical object versions are fresh")

local added = {entries[1], entries[2], {
    object_kind = "field_unit", object_id = "unit:3", version = 1,
    activation_at_coverage = "live", source_ref = "unit:3",
}}
local missing = assert(object_coverage.diff(captured, added, {
    domain = "relation",
    policy_id = "test.v0",
}))
assert_eq(missing.changed_count, 1, "one added object creates one delta")
assert_eq(missing.missing[1].object_id, "unit:3", "delta names exact object")
assert_eq(missing.source_refs[1], "coverage:field_unit:unit:3:1", "delta names exact version")

local changed = {entries[1], {
    object_kind = "field_unit", object_id = "unit:2", version = 2,
    activation_at_coverage = "suppressed", source_ref = "unit:2",
}}
local stale = assert(object_coverage.diff(captured, changed, {
    domain = "upper_observation",
    policy_id = "test.v0",
}))
assert_eq(stale.stale[1].covered_version, 1, "stale delta retains covered version")
assert_eq(stale.stale[1].current_version, 2, "stale delta records current version")

local global_only = assert(object_coverage.capture(entries, {
    domain = "relation",
    policy_id = "test.v0",
    global_revision = 999,
}))
local global_delta = assert(object_coverage.diff(global_only, entries, {
    domain = "relation",
    policy_id = "test.v0",
}))
assert_eq(global_delta.changed_count, 0, "global revision alone cannot re-arm coverage")

local domain = assert(flow_domain.new({3, 5, 8, 13, 21}, {
    stream_id = "coverage-probe",
    source_ref = "fixture:coverage-probe",
}))
local instance = assert(packet_birth.create(domain, "probe relations", {
    projection_adapter = "vertical_pair.v0",
}))
assert(flow.run(instance))
assert(packet.commit_transition(instance, {
    from = "▽", to = "☰", reason = "coverage_probe", authority = "harness_override",
}))
assert(packet.begin_tick(instance, "☰", {}))

local first_ready = assert(connect.readiness(instance))
assert_true(first_ready.ready, "new exact domain is ready once")
assert_eq(first_ready.reason, "relation_probe_delta", "exact readiness reason")
local _, first_probe = assert(connect.run(instance))
assert_eq(first_probe.outcome, "relations_recorded", "pair projection grows relation")
assert_eq(#instance.field.relations.raw.items, 1, "one declared projection relation recorded")
assert_eq(instance.field.relations.raw.protocol_version, "field.raw_relations.v1",
    "raw relation protocol upgraded")
assert_true(instance.field.relations.raw.object_coverage.capture_event_ref ~= nil,
    "raw probe coverage names its writer event")

local discharged = assert(connect.readiness(instance))
assert_true(not discharged.ready, "same object versions cannot repeat CONNECT")
assert_eq(discharged.reason, "relation_probe_current", "probe stamp discharges readiness")
assert_eq(discharged.coverage_delta.changed_count, 0, "discharged delta is empty")
local repeated, repeated_err = connect.run(instance)
assert_true(not repeated, "unchanged CONNECT run is rejected")
assert_eq(repeated_err, "relation_probe_current", "unchanged probe rejection reason")

local empty_domain = assert(flow_domain.new({1, 1, 2, 3, 5}, {
    stream_id = "coverage-empty",
    source_ref = "fixture:coverage-empty",
}))
local empty = assert(packet_birth.create(empty_domain, "empty relation probe", {
    projection_adapter = "vertical_single.v0",
}))
assert(flow.run(empty))
assert(packet.commit_transition(empty, {
    from = "▽", to = "☰", reason = "empty_probe", authority = "harness_override",
}))
assert(packet.begin_tick(empty, "☰", {}))
local _, empty_probe = assert(connect.run(empty))
assert_eq(empty_probe.outcome, "empty_snapshot", "single projection writes honest empty probe")
assert_eq(empty.field.relations.raw.outcome, "empty", "empty raw epoch is explicit")
assert_true(not assert(connect.readiness(empty)).ready,
    "empty probe suppresses unchanged immediate repeat")

print("test_object_coverage ok")
