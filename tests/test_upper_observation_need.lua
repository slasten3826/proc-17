package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local body = require("runtime.body")
local field = require("runtime.field")
local choose = require("organs.choose")
local encode = require("organs.encode")
local flow = require("organs.flow")
local observe = require("organs.observe")
local fake = require("substrates.fake")
local flow_domain = require("runtime.flow_domain")
local packet_birth = require("runtime.packet_birth")
local object_coverage = require("runtime.object_coverage")
local qualified_pressure = require("runtime.qualified_pressure")
local upper_coverage = require("runtime.upper_coverage")

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

local function find_need(result, object_id, observation_class)
    for _, item in ipairs(result.items or {}) do
        if item.object_id == object_id and item.observation_class == observation_class then
            return item
        end
    end
    return nil
end

local function find_witness(snapshot, kind, mode)
    for _, witness in ipairs(snapshot.witnesses or snapshot or {}) do
        if witness.kind == kind
            and (mode == nil or witness.action_plan.mode == mode) then
            return witness
        end
    end
    return nil
end

-- PR-U0/U3: an empty field has no upper need; body clocks and ledgers are not
-- field mutations and therefore cannot invent one.
local empty = packet.new("empty upper control")
local empty_upper = assert(qualified_pressure.upper_witnesses(empty, {
    current_operator = "▽",
}))
assert_eq(find_witness(empty_upper, "upper_observation_need"), nil,
    "empty field has no upper witness")

-- PR-U2: semantic OBSERVE commits its own output as exact version-one
-- coverage. Global potential freshness may move, but qualified upper sight
-- must not ask to observe the unchanged proposal again.
local semantic = packet.new("observe once")
assert(packet.commit_transition(semantic, {
    from = "▽", to = "☴", reason = "semantic_own_output",
}))
assert(packet.begin_tick(semantic, "☴", {}))
local _, semantic_payload = assert(observe.run(semantic, fake, {work_mode = "plan"}))
local semantic_view = assert(upper_coverage.derive(semantic))
local semantic_needs = assert(upper_coverage.needs(semantic, semantic_view))
assert_eq(find_need(semantic_needs, semantic_payload.field_unit_id, "material"), nil,
    "semantic own output is atomically covered")
assert_eq(semantic.boundary.observations.upper[1].sensor, "semantic",
    "semantic sensor is explicit")
assert_true(#semantic.boundary.observations.upper[1].observation_classes >= 1,
    "semantic observation classes are explicit")
local semantic_after = assert(qualified_pressure.upper_witnesses(semantic, {
    current_operator = "☵",
}))
assert_eq(find_witness(semantic_after, "upper_observation_need"), nil,
    "semantic own output does not immediately request a second sight")

local pure_trace_count = #semantic.trace
local pure_potential = semantic.revisions.potential
assert(upper_coverage.needs(semantic, assert(upper_coverage.derive(semantic))))
assert_eq(#semantic.trace, pure_trace_count, "upper derivation is trace-pure")
assert_eq(semantic.revisions.potential, pure_potential, "upper derivation is revision-pure")

-- Expected plan errors are rejected before either half of the observation/unit
-- commit can mutate the Packet.
local preflight = packet.new("invalid semantic plan")
assert(packet.commit_transition(preflight, {
    from = "▽", to = "☴", reason = "semantic_preflight",
}))
assert(packet.begin_tick(preflight, "☴", {}))
local empty_coverage = assert(object_coverage.capture({}, {
    domain = "upper_observation",
    policy_id = "observe.semantic.v0",
    global_revision = preflight.revisions.potential,
}))
local preflight_trace = #preflight.trace
local rejected, rejected_err = body.commit_upper_observation(preflight, {
    sensor = "semantic",
    observation_classes = {"semantic", "material"},
    scope_refs = {"chaos:raw_prompt"},
    read_revisions = assert(body.revision_snapshot(preflight, "upper")),
    read_units = empty_coverage,
    planned_unit_id = "unit:1",
    sensor_output = {
        kind = "substrate_response",
        source_refs = {"chaos:raw_prompt"},
        content_truth_status = "semantic_proposal",
    },
    content_truth_status = "semantic_proposal",
})
assert_true(not rejected, "invalid output plan is rejected")
assert_eq(rejected_err, "field unit requires carrier or carrier_ref",
    "preflight reports the exact invalid field plan")
assert_eq(#preflight.trace, preflight_trace, "preflight failure appends no observation")
assert_eq(#preflight.field.unit_order, 0, "preflight failure appends no unit")

-- PR-U9: an L1 physical sample is not generic semantic or material debt.
local l1_domain = assert(flow_domain.new({1, 4, 9, 16, 25}, {
    stream_id = "upper-l1-control",
    source_ref = "fixture:upper-l1-control",
}))
local l1_packet = assert(packet_birth.create(l1_domain, "semantic ingress", {
    projection_adapter = "vertical_single.v0",
}))
local _, l1_flow = assert(flow.run(l1_packet))
local l1_view = assert(upper_coverage.derive(l1_packet))
local l1_needs = assert(upper_coverage.needs(l1_packet, l1_view))
assert_true(find_need(l1_needs, l1_flow.unit_ids[1], "semantic") ~= nil,
    "unseen prompt requests semantic sight")
assert_eq(find_need(l1_needs, l1_flow.unit_ids[2], "semantic"), nil,
    "L1 sample is not semantic debt")
assert_eq(find_need(l1_needs, l1_flow.unit_ids[2], "material"), nil,
    "L1 sample is not material debt")
local prompt_witness = assert(find_witness(
    assert(qualified_pressure.derive(l1_packet, nil, {current_operator = "▽"})),
    "upper_observation_need",
    "semantic_observe"
), "unseen prompt produces semantic action")
assert_eq(#prompt_witness.scope_refs, 1, "semantic action is scoped to prompt version")
assert_eq(prompt_witness.action_plan.options.observe.unit_ids[1], l1_flow.unit_ids[1],
    "semantic action owns its exact prompt unit")

-- PR-U4/U5/U6: ENCODE creates exact material need, field-native sight
-- discharges it, and CHOOSE re-arms only the changed object versions.
local shaped_domain = assert(flow_domain.new({3, 6, 9, 12, 15}, {
    stream_id = "upper-shaped-life",
    source_ref = "fixture:upper-shaped-life",
}))
local shaped = assert(packet_birth.create(shaped_domain, "shape upper coverage", {
    projection_adapter = "vertical_single.v0",
}))
assert(flow.run(shaped))
assert(packet.commit_transition(shaped, {
    from = "▽", to = "☴", reason = "upper_fixture_source",
}))
assert(packet.begin_tick(shaped, "☴", {}))
assert(packet.append_chaos(shaped, {
    operator = "☴",
    text = "alpha\nbeta",
    truth_status = "semantic_proposal",
}))
assert(packet.commit_transition(shaped, {
    from = "☴", to = "☵", reason = "upper_fixture_encode",
}))
assert(packet.begin_tick(shaped, "☵", {}))
local _, encoded = assert(encode.run(shaped))
local unit_ids = encoded.field_shadow.member_unit_ids
local encoded_view = assert(upper_coverage.derive(shaped))
local encoded_needs = assert(upper_coverage.needs(shaped, encoded_view))
for _, unit_id in ipairs(unit_ids) do
    local need = assert(find_need(encoded_needs, unit_id, "material"),
        "ENCODE unit requires material sight")
    assert_eq(need.version, 1, "ENCODE need names version one")
    assert_eq(need.sensor, "field_native", "ENCODE need selects body-native sensor")
end
local encoded_snapshot = assert(qualified_pressure.derive(shaped))
local field_witness = assert(find_witness(
    encoded_snapshot,
    "upper_observation_need",
    "field_native_observe"
), "ENCODE consequence produces body-native observation action")
assert_eq(#field_witness.action_plan.options.observe.unit_ids, #unit_ids,
    "field-native action covers every exact changed unit")

assert(packet.commit_transition(shaped, {
    from = "☵", to = "☴", reason = "upper_fixture_field_sight",
}))
assert(packet.begin_tick(shaped, "☴", {}))
assert(observe.run(shaped, nil, {sensor = "field_native", unit_ids = unit_ids}))
local covered_view = assert(upper_coverage.derive(shaped))
local covered_needs = assert(upper_coverage.needs(shaped, covered_view))
for _, unit_id in ipairs(unit_ids) do
    assert_eq(find_need(covered_needs, unit_id, "material"), nil,
        "field-native sight discharges exact material version")
end
local discharged = assert(qualified_pressure.upper_witnesses(shaped, {
    current_operator = "☵",
}))
assert_eq(find_witness(discharged, "upper_observation_need", "field_native_observe"), nil,
    "field-native effect discharges qualified upper pressure")

assert(packet.commit_transition(shaped, {
    from = "☴", to = "☳", reason = "upper_fixture_choose",
}))
assert(packet.begin_tick(shaped, "☳", {}))
assert(choose.run(shaped, {limits = {max_selected = 1, max_killed_sample = 8}}))
local chosen_view = assert(upper_coverage.derive(shaped))
local chosen_needs = assert(upper_coverage.needs(shaped, chosen_view))
for _, unit_id in ipairs(unit_ids) do
    local unit = assert(field.get_unit(shaped, unit_id))
    local need = assert(find_need(chosen_needs, unit_id, "material"),
        "CHOOSE mutation re-arms material sight")
    assert_eq(need.version, unit.version, "CHOOSE need names exact current version")
end
local rearmed = assert(qualified_pressure.derive(shaped))
local rearmed_witness = assert(find_witness(
    rearmed,
    "upper_observation_need",
    "field_native_observe"
), "CHOOSE version changes re-arm qualified sight")
assert_eq(#rearmed_witness.scope_refs, #unit_ids,
    "re-armed witness names exact changed versions")

-- PR-U8: once the CHOOSE delta is observed, a DISSOLVE mutation re-arms only
-- the exact released object version.
assert(packet.commit_transition(shaped, {
    from = "☳", to = "☴", reason = "upper_cover_choice_delta",
}))
assert(packet.begin_tick(shaped, "☴", {}))
assert(observe.run(shaped, nil, {
    sensor = "field_native",
    unit_ids = unit_ids,
}))
assert(packet.commit_transition(shaped, {
    from = "☴", to = "☷", reason = "upper_dissolve_delta",
}))
assert(packet.begin_tick(shaped, "☷", {}))
local _, dissolve_event = assert(packet.append_chaos(shaped, {
    operator = "☷",
    kind = "upper_dissolve_fixture",
    truth_status = "runtime_confirmed",
}))
local dissolved = assert(field.set_activation(
    shaped,
    "☷",
    unit_ids[1],
    "dissolved",
    {event_id = dissolve_event.id, reason = "upper_dissolve_fixture"}
))
local dissolved_snapshot = assert(qualified_pressure.derive(shaped))
local dissolved_witness = assert(find_witness(
    dissolved_snapshot,
    "upper_observation_need",
    "field_native_observe"
), "DISSOLVE creates material observation need")
assert_eq(#dissolved_witness.scope_refs, 1,
    "DISSOLVE re-arms only the changed object")
assert_eq(dissolved_witness.action_plan.preconditions.object_versions[dissolved.id],
    dissolved.version, "DISSOLVE witness pins exact released version")

-- PR-U10: unknown field mutations stay visible as diagnostics and block the
-- affected snapshot from becoming promotion evidence.
local unknown = packet.new("unknown upper mutation")
assert(flow.run(unknown))
local _, unknown_event = assert(packet.append_chaos(unknown, {
    operator = "▽",
    kind = "unknown_upper_fixture",
    truth_status = "runtime_confirmed",
}))
assert(field.add_unit(unknown, "▽", {
    kind = "unregistered_upper_kind",
    carrier = {value = "unknown"},
    source_refs = {},
    created_event_id = unknown_event.id,
    content_truth_status = "unknown",
}))
local unknown_snapshot = assert(qualified_pressure.derive(unknown, nil, {
    current_operator = "▽",
}))
local saw_unknown = false
for _, diagnostic in ipairs(unknown_snapshot.unqualified or {}) do
    if diagnostic.kind == "unclassified_upper_mutation" then
        saw_unknown = true
    end
end
assert_true(saw_unknown, "unknown mutation is a typed unqualified diagnostic")

print("test_upper_observation_need ok")
