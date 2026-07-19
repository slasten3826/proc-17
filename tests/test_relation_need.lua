package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local connect = require("organs.connect")
local flow = require("organs.flow")
local flow_domain = require("runtime.flow_domain")
local packet_birth = require("runtime.packet_birth")
local qualified_pressure = require("runtime.qualified_pressure")
local relation_inspection = require("runtime.relation_inspection")
local field = require("runtime.field")

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

local function domain(id)
    return assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = id,
        source_ref = "fixture:" .. id,
    }))
end

local function find_witness(snapshot, kind)
    for _, witness in ipairs(snapshot.witnesses or {}) do
        if witness.kind == kind then
            return witness
        end
    end
    return nil
end

local function born(id, adapter)
    local instance = assert(packet_birth.create(domain(id), "inspect relations", {
        projection_adapter = adapter,
    }))
    assert(flow.run(instance))
    return instance
end

-- PR-R1: an uncovered single-object domain permits one honest probe, but it
-- contains no relation candidate and therefore no relation need.
local single = born("relation-need-single", "vertical_single.v0")
local single_trace = #single.trace
local single_potential = single.revisions.potential
local single_inspection = assert(relation_inspection.derive(single))
assert_eq(single_inspection.coverage_delta.changed_count, 1,
    "single object remains an uncovered probe scope")
assert_eq(#single_inspection.candidates, 0, "single object has no candidate")
assert_eq(#single_inspection.candidate_delta.missing, 0,
    "coverage gap alone cannot become relation need")
assert_eq(find_witness(
    assert(qualified_pressure.derive(single, nil, {current_operator = "▽"})),
    "relation_recognition_need"
), nil, "empty probe readiness does not become pressure")
assert_eq(#single.trace, single_trace, "inspection is trace-pure")
assert_eq(single.revisions.potential, single_potential, "inspection is revision-pure")

-- PR-R2/PR-R3: a registered pair is one exact candidate; CONNECT records the
-- same candidate and the next derivation classifies it as current.
local pair = born("relation-need-pair", "vertical_pair.v0")
local first = assert(relation_inspection.derive(pair))
assert_eq(#first.candidates, 1, "registered pair yields one candidate")
assert_eq(#first.candidate_delta.missing, 1, "unrecorded candidate is missing")
local candidate = first.candidate_delta.missing[1]
assert_eq(candidate.predicate_id, "connect.l1_registered_projection.v0",
    "candidate names its body predicate")
assert_eq(#candidate.scope_refs, 2, "candidate scope contains only endpoint versions")
assert_true(candidate.scope_refs[1]:find("coverage:field_unit:", 1, true) == 1,
    "candidate scope is exact object-version coverage")

local recognition = assert(find_witness(
    assert(qualified_pressure.derive(pair, nil, {current_operator = "▽"})),
    "relation_recognition_need"
), "registered candidate produces qualified recognition need")
assert_eq(recognition.target_operator, "☰", "recognition targets CONNECT")
assert_eq(recognition.causal_class, "causal_affordance",
    "initial relation consumer is an affordance")
assert_eq(recognition.action_plan.mode, "connect_probe",
    "recognition carries bounded CONNECT action")
assert_eq(#recognition.scope_refs, 2, "recognition keeps exact endpoint scope")
local recognition_again = assert(find_witness(
    assert(qualified_pressure.derive(pair, nil, {current_operator = "▽"})),
    "relation_recognition_need"
), "unchanged fact remains derivable")
assert_eq(recognition_again.witness_id, recognition.witness_id,
    "a visit without effect cannot discharge or rewrite the fact")

assert(packet.commit_transition(pair, {
    from = "▽", to = "☰", reason = "relation_need_probe",
    authority = "harness_override",
}))
assert(packet.begin_tick(pair, "☰", {}))
local _, payload = assert(connect.run(pair))
assert_eq(payload.inspection_id, first.inspection_id,
    "CONNECT executes the same inspection it declared ready")
local relation = pair.field.relations.raw.items[1]
assert_eq(relation.predicate_id, candidate.predicate_id,
    "raw relation preserves detector identity")

local second = assert(relation_inspection.derive(pair))
assert_eq(#second.candidate_delta.missing, 0, "recorded candidate is no longer missing")
assert_eq(#second.candidate_delta.current, 1, "recorded exact candidate is current")
assert_true(not relation_inspection.same(first, second),
    "effect changes the inspection identity")

local post_connect = assert(qualified_pressure.derive(pair))
assert_eq(find_witness(post_connect, "relation_recognition_need"), nil,
    "CONNECT discharges recognition need")
local formation = assert(find_witness(post_connect, "relation_formation_need"),
    "raw relation creates formation need")
assert_eq(formation.target_operator, "☵", "formation targets ENCODE")
assert_eq(formation.action_plan.mode, "relation_formation",
    "formation carries exact ENCODE action")
assert_eq(formation.action_plan.preconditions.raw_epoch, pair.field.relations.raw.epoch,
    "formation pins the raw epoch")

assert(packet.commit_transition(pair, {
    from = "☰", to = "☵", reason = "relation_need_form",
    authority = "harness_override",
}))
assert(packet.begin_tick(pair, "☵", {}))
assert(require("organs.encode").run(pair, formation.action_plan.options.encode))
local after_encode = assert(qualified_pressure.relation_witnesses(pair, {
    current_operator = "☰",
}))
for _, witness in ipairs(after_encode) do
    assert_true(witness.kind ~= "relation_formation_need",
        "encoded raw relation cannot request formation again")
    assert_true(witness.kind ~= "relation_recognition_need",
        "unrelated formed unit permits probing but creates no relation need")
end

-- PR-R7: changing an endpoint version makes the old raw representation stale
-- and derives one new exact recognition action over the current versions.
local rearmed = born("relation-need-rearmed", "vertical_pair.v0")
assert(packet.commit_transition(rearmed, {
    from = "▽", to = "☰", reason = "relation_rearm_probe",
    authority = "harness_override",
}))
assert(packet.begin_tick(rearmed, "☰", {}))
assert(connect.run(rearmed))
local old_relation = rearmed.field.relations.raw.items[1]
assert(packet.commit_transition(rearmed, {
    from = "☰", to = "☵", reason = "relation_rearm_cross",
    authority = "harness_override",
}))
assert(packet.commit_transition(rearmed, {
    from = "☵", to = "☳", reason = "relation_rearm_mutate",
    authority = "harness_override",
}))
assert(packet.begin_tick(rearmed, "☳", {}))
local _, mutation_event = assert(packet.append_chaos(rearmed, {
    operator = "☳",
    kind = "relation_endpoint_version_fixture",
    truth_status = "runtime_confirmed",
}))
local changed = assert(field.set_activation(
    rearmed,
    "☳",
    old_relation.from,
    "selected",
    {event_id = mutation_event.id, reason = "relation_rearm_fixture"}
))
local stale_inspection = assert(relation_inspection.derive(rearmed))
assert_eq(#stale_inspection.candidate_delta.stale, 1,
    "old relation is stale against changed endpoint")
local stale_snapshot = assert(qualified_pressure.derive(rearmed, nil, {
    current_operator = "☵",
}))
local stale_witness = assert(find_witness(
    stale_snapshot,
    "relation_recognition_need"
), "stale relation creates a new recognition need")
assert_eq(stale_witness.action_plan.preconditions.object_versions[changed.id],
    changed.version, "re-armed action pins current endpoint version")

local ablated = born("relation-need-ablated", "vertical_pair.v0")
local ablated_snapshot = assert(qualified_pressure.derive(ablated, nil, {
    current_operator = "▽",
    ablate_relation_consumer = true,
}))
assert_eq(find_witness(ablated_snapshot, "relation_recognition_need"), nil,
    "consumer ablation removes relation pressure while candidate remains")

print("test_relation_need ok")
