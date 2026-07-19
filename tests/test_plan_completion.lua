package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")
local packet = require("core.packet")
local body = require("runtime.body")
local plan_completion = require("runtime.plan_completion")
local pressure_action = require("runtime.pressure_action")
local qualified_pressure = require("runtime.qualified_pressure")
local registry = require("runtime.operator_registry")
local runtime_organ = require("organs.runtime")
local observe = require("organs.observe")
local fixture = require("tests.support.plan_life")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function copy_value(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

local function witness_of(values, kind)
    for _, value in ipairs(values.witnesses or values or {}) do
        if value.kind == kind then
            return value
        end
    end
    return nil
end

-- B0-B4: work mode is one immutable birth fact with one compatibility mirror.
local default_packet = packet.new("default work mode")
assert_eq(default_packet.regime.work.mode, "build", "default mode is build")
assert_eq(default_packet.metadata.work_mode, "build", "default mirror is build")
local plan_packet = packet.new("explicit plan", {work_mode = "plan"})
assert_eq(plan_packet.regime.work.mode, "plan", "explicit plan is canonical")
assert_eq(plan_packet.trace[1].payload.work_mode, "plan", "birth stamps plan mode")
local mirrored = packet.new("metadata plan", {metadata = {work_mode = "plan"}})
assert_eq(mirrored.regime.work.mode, "plan", "metadata seeds compatibility mode")
assert_true(not pcall(packet.new, "bad mode", {work_mode = "unknown"}),
    "unknown work mode is rejected")
assert_true(not pcall(packet.new, "mode conflict", {
    work_mode = "plan", metadata = {work_mode = "build"},
}), "conflicting work mode declarations are rejected")

-- I0/I1: build mode and prose cannot become plan completion.
local build_packet = assert(fixture.run(
    "completion-build",
    "work_sequence",
    {"inspect", "change"},
    3,
    {work_mode = "build"}
))
local build_inspection = assert(plan_completion.inspect(build_packet))
assert_eq(build_inspection.state, "absent", "build has no plan completion")
assert_eq(build_inspection.diagnostics[1].kind, "plan_mode_absent",
    "build absence is typed")
local prose_packet = assert(fixture.run(
    "completion-prose",
    "work_sequence",
    nil,
    1,
    nil,
    "ordinary prose"
))
assert_eq(assert(plan_completion.inspect(prose_packet)).state, "absent",
    "prose cannot become exact plan material")

-- I2/I3: ENCODE alone is stale; field-native sight makes the sequence complete.
local stale_packet = assert(fixture.run(
    "completion-stale",
    "work_sequence",
    {"inspect", "change"},
    2
))
assert_eq(assert(plan_completion.inspect(stale_packet)).state, "stale",
    "unobserved formed versions are stale")
local sequence_packet, sequence_result = assert(fixture.run(
    "completion-sequence",
    "work_sequence",
    {"inspect", "change", "verify"},
    3
))
assert_eq(fixture.walk(sequence_result), "☴☵☴", "sequence candidate trace")
local trace_before = #sequence_packet.trace
local revisions_before = json.encode(sequence_packet.revisions)
local sequence_first = assert(plan_completion.inspect(sequence_packet))
local sequence_second = assert(plan_completion.inspect(sequence_packet))
assert_eq(sequence_first.state, "complete_candidate", "sequence is complete")
assert_eq(sequence_first.candidate.candidate_id,
    sequence_second.candidate.candidate_id, "candidate identity is stable")
assert_eq(#sequence_packet.trace, trace_before, "inspection is trace-pure")
assert_eq(json.encode(sequence_packet.revisions), revisions_before,
    "inspection is revision-pure")
assert_eq(#sequence_first.candidate.activation_partition.deliverable_ids, 3,
    "sequence preserves all items")

-- I4/I5/I6: hierarchy, artifact set and one-member alternative are complete.
local hierarchy_envelope = fixture.proposal(
    "work_hierarchy",
    {"parent", "child"},
    {{from_key = "item-1", to_key = "item-2", relation = "contains"}}
)
local hierarchy_packet = assert(fixture.run(
    "completion-hierarchy", "work_hierarchy", nil, 3, nil, hierarchy_envelope
))
assert_eq(assert(plan_completion.inspect(hierarchy_packet)).state,
    "complete_candidate", "valid hierarchy is complete")
local artifact_packet = assert(fixture.run(
    "completion-artifacts", "artifact_set", {"a.lua", "b.lua"}, 3
))
assert_eq(assert(plan_completion.inspect(artifact_packet)).state,
    "complete_candidate", "artifact set is complete")
local confirmation_packet = assert(fixture.run(
    "completion-confirmation", "alternative_set", {"only"}, 3
))
local confirmation = assert(plan_completion.inspect(confirmation_packet))
assert_eq(confirmation.state, "complete_candidate", "one alternative confirms")
assert_eq(confirmation.candidate.activation_partition.selection_mode,
    "confirmation", "confirmation remains distinct from choice")
assert_true(confirmation.candidate.choice_event_ref == nil,
    "confirmation fabricates no CHOOSE event")

-- I7-I9: choice must happen and every post-choice version must be observed.
local unresolved_packet = assert(fixture.run(
    "completion-unresolved-choice", "alternative_set", {"left", "right"}, 3
))
assert_eq(assert(plan_completion.inspect(unresolved_packet)).state, "absent",
    "unresolved alternatives are not complete")
local uncovered_packet = assert(fixture.run(
    "completion-uncovered-choice", "alternative_set", {"left", "right"}, 4
))
assert_eq(assert(plan_completion.inspect(uncovered_packet)).state, "stale",
    "post-choice versions require fresh material sight")
local collapsed_packet = assert(fixture.run(
    "completion-collapsed-choice", "alternative_set", {"left", "right"}, 5
))
local collapsed = assert(plan_completion.inspect(collapsed_packet))
assert_eq(collapsed.state, "complete_candidate", "observed collapse is complete")
assert_eq(#collapsed.candidate.activation_partition.deliverable_ids, 1,
    "collapse delivers one survivor")
assert_eq(#collapsed.candidate.activation_partition.suppressed_ids, 1,
    "collapse preserves one killed alternative")

-- I10/I13: omission and missing members cannot masquerade as complete.
local many = {}
for index = 1, 129 do
    many[index] = "item " .. tostring(index)
end
local partial_packet = assert(fixture.run(
    "completion-partial", "artifact_set", many, 3
))
assert_eq(assert(plan_completion.inspect(partial_packet)).state, "partial",
    "omitted structure remains partial")

-- I11: two independently grown current formations are ambiguous in v0.
local ambiguous_packet = assert(fixture.run(
    "completion-ambiguous", "work_sequence", {"first"}, 3
))
assert(packet.commit_transition(ambiguous_packet, {
    from = "☱", to = "☴", reason = "second_plan_source",
    authority = "harness_override",
}))
assert(packet.begin_tick(ambiguous_packet, "☴", {}))
assert(observe.run(
    ambiguous_packet,
    fixture.substrate(fixture.proposal("artifact_set", {"second"})),
    {work_mode = "plan"}
))
local second_snapshot = assert(qualified_pressure.structure_witnesses(
    ambiguous_packet,
    {current_operator = "☴"}
))
local second_witness = assert(witness_of(second_snapshot, "encoding_need"),
    "second exact formation witness required")
local second_context = assert(pressure_action.registry_context(
    second_witness.action_plan,
    {instance = ambiguous_packet, options = {work_mode = "plan"}}
))
assert(packet.commit_transition(ambiguous_packet, {
    from = "☴", to = "☵", reason = "second_plan_formation",
    authority = "harness_override",
}))
assert(packet.begin_tick(ambiguous_packet, "☵", {}))
local second_execution = assert(registry.execute("☵", ambiguous_packet, second_context))
assert_eq(second_execution.status, "applied", "second exact formation applies")
assert(packet.commit_transition(ambiguous_packet, {
    from = "☵", to = "☴", reason = "second_plan_sight",
    authority = "harness_override",
}))
assert(packet.begin_tick(ambiguous_packet, "☴", {}))
assert(observe.run(ambiguous_packet, nil, {
    sensor = "field_native",
    unit_ids = second_execution.payload.structure_formation.formed_unit_ids,
}))
assert_eq(assert(plan_completion.inspect(ambiguous_packet)).state, "ambiguous",
    "multiple exact formations require a future merge policy")

-- I12: a real rejected validation blocks an otherwise complete plan.
local rejected_packet = assert(fixture.run(
    "completion-rejected", "work_sequence", {"inspect", "change"}, 3
))
assert(packet.commit_transition(rejected_packet, {
    from = "☱", to = "☶", reason = "plan_validation_fixture",
    authority = "harness_override",
}))
assert(packet.begin_tick(rejected_packet, "☶", {}))
assert(body.record_validation(rejected_packet, {
    kind = "logic_validation_payload",
    status = "rejected",
    reason = "fixture_rejection",
    truth_status = "runtime_confirmed",
}))
assert_eq(assert(plan_completion.inspect(rejected_packet)).state, "blocked",
    "rejected validation blocks plan completion")

local broken_id = sequence_first.candidate.formed_unit_ids[1]
sequence_packet.field.units[broken_id].activation = "dissolved"
assert_eq(assert(plan_completion.inspect(sequence_packet)).state, "blocked",
    "missing plan member blocks completion")

-- R0-R5: the committed review action alone gives ☱ one assessment right.
local review_packet, review_result = assert(fixture.run(
    "completion-review", "work_sequence", {"inspect", "change"}, 3
))
assert_eq(#fixture.events(review_packet, "plan_completion_assessment"), 0,
    "route to runtime does not create assessment")
local review_route = assert(fixture.last_route_to(review_result, "☱"),
    "review route required")
local plan = review_route.selected_candidate.action_plan
assert_eq(plan.mode, "plan_completion_review", "review action is typed")
local forged_scope = copy_value(plan)
forged_scope.scope_refs = {"coverage:field_unit:forged:1"}
assert_true(not pressure_action.validate(forged_scope),
    "forged review scope is rejected")
local forged_candidate = copy_value(plan)
forged_candidate.options.runtime.plan_completion_input.candidate_id = "forged"
assert_true(not pressure_action.validate(forged_candidate),
    "forged candidate identity is rejected")
local context = assert(pressure_action.registry_context(plan, {
    instance = review_packet,
    options = {work_mode = "plan"},
    result = review_result,
}))
assert(packet.begin_tick(review_packet, "☱", {}))
local execution = assert(registry.execute("☱", review_packet, context))
assert_eq(execution.status, "applied", "qualified runtime review applies")
assert_eq(execution.payload.mode, "plan_completion_review",
    "runtime effect names review mode")
assert_true(pressure_action.verify_effect(plan, execution.payload, review_packet),
    "runtime review effect resolves")
assert_eq(#fixture.events(review_packet, "plan_completion_assessment"), 1,
    "runtime writes one assessment")
local duplicate, duplicate_err = runtime_organ.run(
    review_packet,
    context.options.runtime
)
assert_true(not duplicate and duplicate_err == "plan_completion_already_assessed",
    "unchanged review cannot write a duplicate assessment")
assert_eq(#fixture.events(review_packet, "plan_completion_assessment"), 1,
    "duplicate attempt leaves trace unchanged")

print("test_plan_completion ok")
