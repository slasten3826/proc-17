package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local field = require("runtime.field")
local flow = require("organs.flow")
local connect = require("organs.connect")
local dissolve = require("organs.dissolve")
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

local serial = 0
local function at_dissolve()
    serial = serial + 1
    local domain = assert(flow_domain.new({6, 10, 15, 21, 28}, {
        stream_id = "raw-dissolve-" .. tostring(serial),
        source_ref = "fixture:raw-dissolve:" .. tostring(serial),
    }))
    local instance = assert(packet_birth.create(domain, "release relation", {
        projection_adapter = "vertical_pair.v0",
    }))
    assert(flow.run(instance))
    assert(packet.commit_transition(instance, {
        from = "▽", to = "☰", reason = "raw_release_connect",
        authority = "harness_override",
    }))
    assert(packet.begin_tick(instance, "☰", {}))
    assert(connect.run(instance))
    local relation = instance.field.relations.raw.items[1]
    assert(packet.commit_transition(instance, {
        from = "☰", to = "☷", reason = "raw_release",
        authority = "harness_override",
    }))
    assert(packet.begin_tick(instance, "☷", {}))
    return instance, relation
end

local instance, relation = at_dissolve()
local options = {
    scope = "raw",
    raw_epoch = 1,
    relation_id = relation.id,
    endpoint_versions = relation.endpoint_versions,
    reason = {
        kind = "explicitly_released",
        policy_id = "vertical.fixture.explicit_release.v0",
    },
}
local ready = assert(dissolve.readiness(instance, options))
assert_true(ready.ready, "registered body fixture policy authorizes raw release")
local active_before = instance.revisions.relations_active
local potential_before = instance.revisions.potential
local _, payload = assert(dissolve.run(instance, options))
assert_eq(payload.mode, "raw_release", "raw release mode is explicit")
assert_eq(payload.loss.amount, 0, "raw release creates zero formed identity loss")
assert_eq(instance.revisions.relations_active, active_before,
    "raw release never touches active relation revision")
assert_eq(instance.revisions.potential, potential_before,
    "raw release without residue does not grow field")
assert_eq(#instance.field.relations.active, 0, "raw release never activates relation")
assert_eq(instance.field.relations.raw.items[1].state, "raw",
    "raw record remains immutable causal input")
assert_eq(assert(field.raw_relation_phase(instance, 1, relation.id)).phase,
    "released", "release is derived from trace disposition")
local repeat_ready = assert(dissolve.readiness(instance, options))
assert_true(not repeat_ready.ready, "released raw identity cannot release twice")
assert_eq(repeat_ready.reason, "raw_relation_released", "repeat release denial")

local residue_packet, residue_relation = at_dissolve()
local _, residue_payload = assert(dissolve.run(residue_packet, {
    scope = "raw",
    raw_epoch = 1,
    relation_id = residue_relation.id,
    endpoint_versions = residue_relation.endpoint_versions,
    preserve_residue = true,
    reason = {
        kind = "unsupported",
        policy_id = "vertical.fixture.unsupported_release.v0",
    },
}))
assert_true(residue_payload.residue ~= nil, "optional raw residue is materialized")
assert_eq(residue_payload.residue.kind, "raw_relation_residue", "residue kind")
assert_eq(residue_payload.residue.activation, "live", "residue is a unit, not retained relation")
assert_eq(#residue_packet.field.relations.active, 0, "residue cannot create active relation")

local injected, injected_relation = at_dissolve()
assert(packet.commit_transition(injected, {
    from = "☷", to = "☰", reason = "reject_injected_candidate",
    authority = "harness_override",
}))
assert(packet.begin_tick(injected, "☰", {}))
local caller_relation, caller_err = connect.run(injected, {
    candidates = {{
        from = injected_relation.from,
        to = injected_relation.to,
        kind = "caller_claim",
    }},
})
assert_true(not caller_relation, "vertical CONNECT rejects caller candidates")
assert_eq(caller_err, "vertical CONNECT rejects caller-injected relation candidates",
    "caller injection rejection")

local runtime_packet, runtime_relation = at_dissolve()
assert(packet.commit_transition(runtime_packet, {
    from = "☷", to = "☴", reason = "runtime_activation_eye",
    authority = "harness_override",
}))
assert(packet.begin_tick(runtime_packet, "☴", {}))
assert(packet.commit_transition(runtime_packet, {
    from = "☴", to = "☱", reason = "runtime_activation",
    authority = "harness_override",
}))
assert(packet.begin_tick(runtime_packet, "☱", {}))
local activated, activation_err = field.activate_relations(
    runtime_packet, "☱", {runtime_relation.id}
)
assert_true(not activated, "RUNTIME cannot retain raw relation in vertical life")
assert_eq(activation_err,
    "RUNTIME raw relation activation is forbidden in vertical packet life",
    "runtime retention denial")

print("test_raw_dissolve ok")
