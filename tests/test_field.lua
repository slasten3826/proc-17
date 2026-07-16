package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local field = require("runtime.field")
local flow = require("organs.flow")

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

local p = packet.new("shape a field", {id = "field-test"})
local flowed, flow_payload = flow.run(p)
assert_true(flowed, flow_payload)
assert_eq(flow_payload.unit_id, "unit:1", "FLOW gets deterministic first unit")
assert_eq(p.revisions.potential, 1, "FLOW increments potential revision")

local ingress = assert(field.get_unit(p, "unit:1"))
assert_eq(ingress.kind, "user_prompt", "FLOW unit kind")
assert_eq(ingress.carrier, "shape a field", "FLOW preserves prompt carrier")
assert_eq(ingress.content_truth_status, "semantic_proposal", "prompt content remains semantic")
assert_eq(#ingress.source_refs, 0, "direct user ingress may have no prior source")
assert_eq(ingress.density, nil, "unmeasured density stays absent")

local _, observe_event = packet.append_chaos(p, {
    operator = "☴",
    kind = "substrate_response",
    text = "alpha\nbeta",
    truth_status = "semantic_proposal",
})
local observed = assert(field.add_unit(p, "☴", {
    kind = "substrate_response",
    carrier = {text = "alpha\nbeta"},
    source_refs = {ingress.id},
    event_truth_status = "runtime_confirmed",
    content_truth_status = "semantic_proposal",
    created_event_id = observe_event.id,
}))
assert_eq(observed.id, "unit:2", "OBSERVE gets deterministic second unit")
assert_eq(observed.content_truth_status, "semantic_proposal", "indexing cannot promote proposal truth")

local revision_before_failure = p.revisions.potential
local denied, denied_err = field.add_unit(p, "☶", {
    kind = "illegal",
    carrier = "x",
    source_refs = {observed.id},
    created_event_id = observe_event.id,
})
assert_true(not denied, "LOGIC cannot create field potential")
assert_eq(denied_err, "field actor cannot add units", "field writer denial reason")
assert_eq(p.revisions.potential, revision_before_failure, "failed mutation leaves revision unchanged")

local view = assert(field.view(p, {created_by = {"▽", "☴"}, limit = 8}))
assert_eq(#view.units, 2, "bounded view selects field units")
assert_eq(view.source_revision, p.revisions.potential, "view captures source revision")
view.units[1].carrier = "tampered"
assert_eq(field.get_unit(p, "unit:1").carrier, "shape a field", "views cannot mutate stored units")

local _, encode_event = packet.crystallize(p, {
    source_chaos_refs = {observe_event.id},
    calm_delta = {kind = "field-test-form"},
    loss = {kind = "field_compression", amount = 0},
    truth_status = "runtime_confirmed",
})
local encoded = assert(field.add_unit(p, "☵", {
    kind = "semantic_line",
    carrier = {id = "line:1", content = "alpha"},
    source_refs = {observed.id},
    event_truth_status = "runtime_confirmed",
    content_truth_status = "semantic_proposal",
    created_event_id = encode_event.id,
}))
local identity_map = assert(field.record_identity_map(p, "☵", {
    encode_event_id = encode_event.id,
    old_ids = {observed.id},
    new_ids = {encoded.id},
    mapping = {[observed.id] = {encoded.id}},
    shadow_only = true,
}))
assert_eq(identity_map.kind, "field_identity_map", "ENCODE records identity map")
assert_eq(identity_map.old_ids[1], observed.id, "identity map source")
assert_eq(identity_map.new_ids[1], encoded.id, "identity map target")
assert_eq(p.revisions.momentum, 0, "ENCODE identity map cannot write momentum")
assert_eq(p.trace[#p.trace].type, "identity_map", "identity map is trace-visible")

local choice_event = assert(packet.append_event(p, {
    type = "choice",
    operator = "☳",
    truth_status = "runtime_confirmed",
    payload = {kind = "field-test-choice"},
}))
local carrier_before = field.get_unit(p, encoded.id).carrier.content
local revision_before_choice = p.revisions.potential
local selected = assert(field.set_activation(p, "☳", encoded.id, "selected", {
    event_id = choice_event.id,
    reason = "test selection",
}))
assert_eq(selected.id, encoded.id, "CHOOSE preserves unit id")
assert_eq(selected.carrier.content, carrier_before, "CHOOSE preserves carrier")
assert_eq(selected.activation, "selected", "CHOOSE changes activation")
assert_eq(p.revisions.potential, revision_before_choice + 1, "activation increments potential revision")

local revision_before_noop = p.revisions.potential
assert(field.set_activation(p, "☳", encoded.id, "selected", {event_id = choice_event.id}))
assert_eq(p.revisions.potential, revision_before_noop, "no-op activation leaves revision unchanged")

local dead = packet.new("dead field", {id = "dead-field"})
assert(flow.run(dead))
assert(packet.die(dead, "cancelled", {cause = "test"}))
local dead_revision = dead.revisions.potential
local posthumous, posthumous_err = field.add_unit(dead, "▽", {
    kind = "illegal_after_death",
    carrier = "x",
    source_refs = {},
    created_event_id = dead.trace[1].id,
})
assert_true(not posthumous, "dead packet rejects field mutation")
assert_true(posthumous_err:find("dead packet", 1, true) ~= nil, "dead field rejection reason")
assert_eq(dead.revisions.potential, dead_revision, "corpse field revision is frozen")

local child = packet.new("inherited carrier", {
    id = "field-child",
    lineage_id = "field-lineage",
    generation = 2,
    parent_corpse_id = "field-corpse",
    birth_kind = "network_reentry",
    carrier_id = "carrier-1",
})
assert(flow.run(child))
assert_eq(field.get_unit(child, "unit:1").source_refs[1], "carrier-1", "network FLOW names its carrier source")

print("test_field ok")
