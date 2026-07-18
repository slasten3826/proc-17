package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local body = require("runtime.body")
local field = require("runtime.field")
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

local serial = 0
local function connected()
    serial = serial + 1
    local domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = "phase-" .. tostring(serial),
        source_ref = "fixture:phase:" .. tostring(serial),
    }))
    local instance = assert(packet_birth.create(domain, "phase fixture", {
        projection_adapter = "vertical_pair.v0",
    }))
    assert(flow.run(instance))
    assert(packet.commit_transition(instance, {
        from = "▽", to = "☰", reason = "phase_connect", authority = "harness_override",
    }))
    assert(packet.begin_tick(instance, "☰", {}))
    assert(connect.run(instance))
    local relation = instance.field.relations.raw.items[1]
    return instance, relation
end

local available, available_relation = connected()
assert_eq(assert(field.raw_relation_phase(
    available, 1, available_relation.id
)).phase, "available", "new raw relation is available")

local observed, observed_relation = connected()
assert(packet.commit_transition(observed, {
    from = "☰", to = "☴", reason = "phase_observe", authority = "harness_override",
}))
assert(packet.begin_tick(observed, "☴", {}))
local read_revisions = assert(body.revision_snapshot(observed, "upper"))
assert(body.record_observation(observed, "upper", {
    scope_refs = {observed_relation.id},
    read_revisions = read_revisions,
    payload = {
        sensor = "relation_native",
        relation_input = {
            raw_epoch = 1,
            relation_ids = {observed_relation.id},
            endpoint_versions = observed_relation.endpoint_versions,
        },
    },
    source_refs = {observed_relation.origin_event_id},
    content_truth_status = observed_relation.content_truth_status,
    fidelity = "body_native",
}))
assert_eq(assert(field.raw_relation_phase(
    observed, 1, observed_relation.id
)).phase, "observed", "native sight is non-terminal")

local encoded, encoded_relation = connected()
assert(packet.commit_transition(encoded, {
    from = "☰", to = "☵", reason = "phase_encode", authority = "harness_override",
}))
assert(packet.begin_tick(encoded, "☵", {}))
assert(packet.append_event(encoded, {
    type = "relation_formation",
    operator = "☵",
    truth_status = "runtime_confirmed",
    payload = {
        formed_from = {
            raw_epoch = 1,
            relation_ids = {encoded_relation.id},
            endpoint_versions = encoded_relation.endpoint_versions,
        },
    },
}))
assert_eq(assert(field.raw_relation_phase(
    encoded, 1, encoded_relation.id
)).phase, "encoded", "formation terminally consumes raw identity")

local released, released_relation = connected()
assert(packet.commit_transition(released, {
    from = "☰", to = "☷", reason = "phase_release", authority = "harness_override",
}))
assert(packet.begin_tick(released, "☷", {}))
assert(packet.append_event(released, {
    type = "relation_mutation",
    operator = "☷",
    truth_status = "runtime_confirmed",
    payload = {
        scope = "raw",
        disposition = "released",
        raw_epoch = 1,
        relation_id = released_relation.id,
        endpoint_versions = released_relation.endpoint_versions,
    },
}))
assert_eq(assert(field.raw_relation_phase(
    released, 1, released_relation.id
)).phase, "released", "release terminally consumes raw identity")

local stale, stale_relation = connected()
assert(packet.commit_transition(stale, {
    from = "☰", to = "☵", reason = "phase_stale_encode", authority = "harness_override",
}))
assert(packet.begin_tick(stale, "☵", {}))
assert(packet.commit_transition(stale, {
    from = "☵", to = "☳", reason = "phase_stale_choose", authority = "harness_override",
}))
assert(packet.begin_tick(stale, "☳", {}))
local choice_event = assert(packet.append_event(stale, {
    type = "choice",
    operator = "☳",
    truth_status = "runtime_confirmed",
    payload = {kind = "phase_fixture"},
}))
assert(field.set_activation(stale, "☳", stale_relation.from, "suppressed", {
    event_id = choice_event.id,
    reason = "phase fixture",
}))
assert_eq(assert(field.raw_relation_phase(
    stale, 1, stale_relation.id
)).phase, "stale", "endpoint version change stales raw identity")

local expired, expired_relation = connected()
assert(packet.begin_terminal(expired, {
    kind = "internal_death",
    cause = "cancelled",
    operator = "☰",
}))
assert(packet.freeze(expired, "cancelled", {cause = "cancelled"}))
assert_eq(assert(field.raw_relation_phase(
    expired, 1, expired_relation.id
)).phase, "expired", "terminal Packet expires unconsumed raw identity")

local contradiction, contradiction_relation = connected()
assert(packet.commit_transition(contradiction, {
    from = "☰", to = "☵", reason = "phase_contradiction_encode",
    authority = "harness_override",
}))
assert(packet.begin_tick(contradiction, "☵", {}))
assert(packet.append_event(contradiction, {
    type = "relation_formation", operator = "☵", truth_status = "runtime_confirmed",
    payload = {formed_from = {
        raw_epoch = 1,
        relation_ids = {contradiction_relation.id},
        endpoint_versions = contradiction_relation.endpoint_versions,
    }},
}))
assert(packet.commit_transition(contradiction, {
    from = "☵", to = "☴", reason = "phase_contradiction_eye",
    authority = "harness_override",
}))
assert(packet.begin_tick(contradiction, "☴", {}))
assert(packet.commit_transition(contradiction, {
    from = "☴", to = "☷", reason = "phase_contradiction_release",
    authority = "harness_override",
}))
assert(packet.begin_tick(contradiction, "☷", {}))
assert(packet.append_event(contradiction, {
    type = "relation_mutation", operator = "☷", truth_status = "runtime_confirmed",
    payload = {
        scope = "raw", disposition = "released", raw_epoch = 1,
        relation_id = contradiction_relation.id,
        endpoint_versions = contradiction_relation.endpoint_versions,
    },
}))
local invalid, invalid_err = field.raw_relation_phase(
    contradiction, 1, contradiction_relation.id
)
assert_true(not invalid, "contradictory terminal dispositions are rejected")
assert_eq(invalid_err, "raw relation has contradictory terminal dispositions",
    "contradiction is an invariant failure")

local replaced, replaced_relation = connected()
assert(packet.commit_transition(replaced, {
    from = "☰", to = "☴", reason = "phase_replace_observe",
    authority = "harness_override",
}))
assert(packet.begin_tick(replaced, "☴", {}))
local _, replacement_event = assert(packet.append_chaos(replaced, {
    operator = "☴",
    kind = "replacement_fixture",
    text = "new addressable material",
    truth_status = "semantic_proposal",
}))
assert(field.add_unit(replaced, "☴", {
    kind = "raw_relation_residue",
    carrier = "new addressable material",
    source_refs = {replaced_relation.from},
    event_truth_status = "runtime_confirmed",
    content_truth_status = "semantic_proposal",
    created_event_id = replacement_event.id,
}))
assert(packet.commit_transition(replaced, {
    from = "☴", to = "☰", reason = "phase_replace_connect",
    authority = "harness_override",
}))
assert(packet.begin_tick(replaced, "☰", {}))
assert(connect.run(replaced))
local replaced_phase = assert(field.raw_relation_phase(
    replaced, 1, replaced_relation.id
))
assert_eq(replaced_phase.phase, "replaced", "new raw epoch replaces old identity")
assert_true(type(replaced_phase.raw_snapshot_event_ref) == "string",
    "historical raw phase preserves its snapshot event ref")

print("test_relation_phase ok")
