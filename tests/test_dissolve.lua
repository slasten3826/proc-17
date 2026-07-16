package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local field = require("runtime.field")
local flow = require("organs.flow")
local connect = require("organs.connect")
local dissolve = require("organs.dissolve")

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

local fixture_index = 0

local function active_relation(reason_kind)
    fixture_index = fixture_index + 1
    local p = packet.new("dissolve relation " .. fixture_index, {
        id = "dissolve-test-" .. fixture_index,
    })
    local _, flow_payload = assert(flow.run(p))
    local first = assert(field.get_unit(p, flow_payload.unit_id))
    local second = assert(field.add_unit(p, "▽", {
        kind = "user_requirement",
        carrier = "second endpoint",
        source_refs = {},
        event_truth_status = "runtime_confirmed",
        content_truth_status = "semantic_proposal",
        created_event_id = p.trace[1].id,
    }))

    assert(packet.commit_transition(p, {from = "▽", to = "☰", reason = "fixture_connect"}))
    assert(packet.begin_tick(p, "☰", {first.id, second.id}))
    local _, connect_payload = assert(connect.run(p, {
        candidates = {
            {
                from = first.id,
                to = second.id,
                kind = reason_kind == "contradictory" and "contradicts" or "depends_on",
                source_refs = {first.id, second.id},
                content_truth_status = "semantic_proposal",
            },
        },
    }))
    local relation_id = connect_payload.writes.relation_ids[1]

    assert(packet.commit_transition(p, {from = "☰", to = "☴", reason = "fixture_upper_eye"}))
    assert(packet.commit_transition(p, {from = "☴", to = "☱", reason = "fixture_runtime"}))
    assert(packet.begin_tick(p, "☱", {relation_id}))
    local _, reason_event = packet.measure_tension(p, {
        operator = "☱",
        kind = "relation_condition_observation",
        relation_id = relation_id,
        reason_kind = reason_kind,
        truth_status = "runtime_confirmed",
    })
    assert(field.activate_relations(p, "☱", {relation_id}, {
        event_id = reason_event.id,
        reason = "fixture_activation",
    }))
    local revision_after_activation = p.revisions.relations_active
    local activation_no_op = assert(field.activate_relations(p, "☱", {relation_id}, {
        event_id = reason_event.id,
        reason = "fixture_repeated_activation",
    }))
    assert_eq(activation_no_op.status, "no_op", "repeated activation is a true no-op")
    assert_eq(p.revisions.relations_active, revision_after_activation,
        "true activation no-op leaves revision unchanged")

    return p, relation_id, reason_event
end

local function enter_dissolve(p)
    assert(packet.commit_transition(p, {from = "☱", to = "☴", reason = "inspect_before_dissolve"}))
    assert(packet.commit_transition(p, {from = "☴", to = "☷", reason = "dissolve_ready"}))
    assert(packet.begin_tick(p, "☷", {}))
end

local p, relation_id, reason_event = active_relation("rigid")
enter_dissolve(p)
local active_revision = p.revisions.relations_active
local potential_revision = p.revisions.potential
local momentum_revision = p.revisions.momentum
local dissolved, payload = dissolve.run(p, {
    relation_id = relation_id,
    reason = {kind = "rigid", event_id = reason_event.id},
    target_state = "dissolved",
})

assert_true(dissolved, payload)
assert_eq(payload.kind, "dissolve_organ_payload", "DISSOLVE payload kind")
assert_eq(payload.status, "applied", "DISSOLVE applies relation mutation")
assert_eq(payload.writes.relation_state, "dissolved", "DISSOLVE target state")
assert_true(payload.writes.residue_unit_id ~= nil, "recoverable dissolution returns residue")
assert_eq(payload.loss.amount, 0, "residue-preserving dissolution has no identity loss")
assert_eq(payload.loss.irreversible, false, "preserved residue is reversible enough for zero loss")
assert_eq(p.field.relations.active[relation_id].state, "dissolved", "active relation remains auditable as dissolved")
assert_eq(p.revisions.relations_active, active_revision + 1, "DISSOLVE increments active relation revision")
assert_eq(p.revisions.potential, potential_revision + 1, "released residue returns to potential")
assert_eq(p.revisions.momentum, momentum_revision, "DISSOLVE cannot write momentum")
assert_eq(p.field.units[payload.writes.residue_unit_id].created_by, "☷", "DISSOLVE owns residue unit")
assert_eq(p.field.units[payload.writes.residue_unit_id].carrier.relation_id, relation_id,
    "residue preserves dissolved relation identity")
assert_eq(p.operator, "☷", "DISSOLVE cannot route directly")
assert_eq(p.trace[#p.trace].type, "relation_mutation", "dissolution event remains last trace event")

local again, again_err = dissolve.run(p, {
    relation_id = relation_id,
    reason = {kind = "rigid", event_id = reason_event.id},
})
assert_true(not again, "dissolved relation cannot be dissolved again")
assert_eq(again_err, "nothing_dissolvable", "second dissolution readiness reason")

local weakened_packet, weakened_id, weakened_reason = active_relation("stale")
enter_dissolve(weakened_packet)
local weakened, weakened_payload = dissolve.run(weakened_packet, {
    relation_id = weakened_id,
    reason = {kind = "stale", event_id = weakened_reason.id},
})
assert_true(weakened, weakened_payload)
assert_eq(weakened_payload.writes.relation_state, "weakened", "stale relation weakens by default")
assert_eq(weakened_payload.writes.residue_unit_id, nil, "weakening does not fabricate residue")
assert_eq(weakened_payload.loss.amount, 0, "weakening preserves identity")

local discard_packet, discard_id, discard_reason = active_relation("unsupported")
enter_dissolve(discard_packet)
local discard_potential = discard_packet.revisions.potential
local discarded, discard_payload = dissolve.run(discard_packet, {
    relation_id = discard_id,
    reason = {kind = "unsupported", event_id = discard_reason.id},
    preserve_residue = false,
    irreversible_fraction = 0.25,
})
assert_true(discarded, discard_payload)
assert_eq(discard_payload.loss.amount, 0.25, "irreversible discard names conditional identity loss")
assert_eq(discard_payload.loss.irreversible, true, "discard is marked irreversible")
assert_eq(discard_payload.writes.residue_unit_id, nil, "discard creates no recoverable residue")
assert_eq(discard_packet.revisions.potential, discard_potential, "discard does not invent potential")

local rejected_packet, rejected_id, rejected_reason = active_relation("rejected")
local relation_revision = rejected_packet.revisions.relations_active
local denied, denied_err = field.weaken_relation(rejected_packet, "☵", rejected_id, {
    target_state = "dissolved",
    reason_kind = "rejected",
    event_id = rejected_reason.id,
})
assert_true(not denied, "ENCODE cannot weaken active relations")
assert_eq(denied_err, "field actor cannot apply requested relation weakening", "subtractive writer denial")
assert_eq(rejected_packet.revisions.relations_active, relation_revision, "denied weakening leaves revision unchanged")

assert(packet.commit_transition(rejected_packet, {from = "☱", to = "☶", reason = "logic_relation_rule"}))
assert(packet.begin_tick(rejected_packet, "☶", {rejected_id}))
local logic_event = assert(packet.append_event(rejected_packet, {
    type = "validation",
    operator = "☶",
    truth_status = "runtime_confirmed",
    payload = {
        relation_id = rejected_id,
        reason_kind = "rejected",
    },
}))
local locked = assert(field.weaken_relation(rejected_packet, "☶", rejected_id, {
    target_state = "locked",
    reason_kind = "rejected",
    event_id = logic_event.id,
}))
assert_eq(locked.after.state, "locked", "LOGIC may lock under its declared reason")
assert_eq(rejected_packet.revisions.momentum, 0, "LOGIC relation mutation cannot write momentum")

print("test_dissolve ok")
