package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local body = require("runtime.body")
local budget = require("runtime.budget")
local field = require("runtime.field")
local flow = require("organs.flow")
local freshness = require("runtime.freshness")

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

local p = packet.new("build notes app", {
    budget = {steps = 8, substrate_calls = 2},
})

local progress = body.apply_crystallized_work(p, {
    {id = "workspace_deployer", status = "done"},
    {id = "test_runner", status = "pending"},
    {id = "result_observer", status = "pending"},
}, {
    goal = "notes app organs",
})

assert_eq(progress.needed_count, 3, "needed count")
assert_eq(progress.done_count, 1, "done count")
assert_eq(progress.remaining_count, 2, "remaining count")
assert_eq(progress.remaining[1], "test_runner", "first remaining")
local calm_revision = p.revisions.calm
body.apply_crystallized_work(p, p.calm.work_units, {status = p.calm.status})
assert_eq(p.revisions.calm, calm_revision, "identical work projection does not advance calm revision")

local choice = body.record_choice(p, {
    kind = "choice_payload",
    selected = {"test_runner"},
    killed_alternatives = {"result_observer"},
})

assert_true(choice, "choice recorded")
assert_eq(#p.boundary.choices, 1, "choice boundary")
assert_eq(p.trace[#p.trace].type, "choice", "choice trace")

local validation = body.record_validation(p, {
    kind = "validation_payload",
    status = "accepted",
})

assert_true(validation, "validation recorded")
assert_eq(#p.boundary.validations, 1, "validation boundary")
assert_eq(p.trace[#p.trace].type, "validation", "validation trace")

local cycle_payload, err = body.decide_cycle(p, {
    cycle_key = "notes_app",
    turn_count = 0,
    max_turns = 4,
    required_budget = {steps = 1},
    logic_status = "accepted",
})

assert_true(cycle_payload, err)
assert_eq(cycle_payload.decision, "again", "cycle should continue unfinished work")
assert_eq(cycle_payload.reason, "remaining_work", "cycle reason")
assert_eq(cycle_payload.progress.needed_count, 3, "cycle needed count")
assert_eq(cycle_payload.progress.done_count, 1, "cycle done count")
assert_eq(cycle_payload.progress.remaining_count, 2, "cycle remaining count")
assert_eq(#p.boundary.cycles, 1, "cycle boundary")
assert_eq(p.trace[#p.trace].type, "cycle", "cycle trace")

local eyes = packet.new("observe revision physics", {
    budget = {steps = 4},
})
local _, flow_payload = assert(flow.run(eyes))
local upper = assert(body.record_observation(eyes, "upper", {
    scope_refs = {flow_payload.unit_id},
    payload = {kind = "upper_eye_test"},
    content_truth_status = "semantic_proposal",
    fidelity = "bounded_test",
}))
assert_eq(upper.kind, "eye_observation", "shared upper envelope")
assert_eq(upper.operator, "☴", "upper eye operator")
assert_eq(upper.read_revisions.potential, 1, "upper eye captures potential revision")
assert_true(eyes.chaos.observations == eyes.boundary.observations.upper, "upper compatibility alias")
assert_eq(freshness.latest_eye(eyes, "upper").zone, "fresh", "new upper observation is fresh")

local _, proposal_event = assert(packet.append_chaos(eyes, {
    operator = "☴",
    kind = "test_proposal",
    truth_status = "semantic_proposal",
}))
assert(field.add_unit(eyes, "☴", {
    kind = "test_proposal",
    carrier = "changed potential",
    source_refs = {flow_payload.unit_id},
    content_truth_status = "semantic_proposal",
    created_event_id = proposal_event.id,
}))
local stale_upper = assert(freshness.latest_eye(eyes, "upper"))
assert_eq(stale_upper.zone, "stale", "potential mutation stales upper observation")
assert_eq(#stale_upper.changed_components, 1, "unrelated revisions stay fresh")
assert_eq(stale_upper.changed_components[1].component, "potential", "potential is the changed referent")
assert_eq(upper.read_revisions.potential, 1, "historical upper record is immutable under freshness read")

assert(budget.init(eyes))
local lower = assert(body.record_observation(eyes, "☱", {
    scope_refs = {"physis:budget"},
    revision_components = {"budget"},
    payload = {kind = "lower_eye_test"},
    content_truth_status = "runtime_confirmed",
    fidelity = "body_snapshot",
}))
assert_eq(lower.eye, "lower", "glyph resolves to lower eye")
assert_eq(lower.operator, "☱", "lower eye operator")
assert_eq(freshness.latest_eye(eyes, "lower").zone, "fresh", "new lower observation is fresh")
assert(budget.charge(eyes, {
    operator = "☱",
    cost = {steps = 1},
    source = "observation_test",
}))
local stale_lower = assert(freshness.latest_eye(eyes, "lower"))
assert_eq(stale_lower.zone, "stale", "budget mutation stales lower observation")
assert_eq(#stale_lower.changed_components, 1, "lower scope stales component-wise")
assert_eq(stale_lower.changed_components[1].component, "budget", "budget is the changed lower referent")
assert_eq(#eyes.boundary.observations.lower, 1, "lower observation stored separately")

body.apply_crystallized_work(p, {
    {id = "workspace_deployer", status = "done"},
    {id = "test_runner", status = "done"},
    {id = "result_observer", status = "done"},
})

local complete, complete_err = body.decide_cycle(p, {
    cycle_key = "notes_app",
    turn_count = 1,
    max_turns = 4,
    required_budget = {steps = 1},
})

assert_true(complete, complete_err)
assert_eq(complete.decision, "stop_complete", "cycle should stop complete")
assert_eq(complete.reason, "progress_complete", "complete reason")

local invalid = body.decide_cycle(p, {
    cycle_key = "notes_app",
    turn_count = 1,
    max_turns = 4,
    logic_status = "rejected",
})

assert_eq(invalid.decision, "stop_invalid", "cycle should stop invalid progress")

local corpse = packet.new("corpse record test")
packet.die(corpse, "identity_loss", {do_not_repeat = "original residue"})
local choices_at_death = #corpse.boundary.choices
local trace_at_death = #corpse.trace

local dead_choice, dead_choice_err = body.record_choice(corpse, {
    kind = "choice_payload",
    selected = {"posthumous"},
})
assert_true(not dead_choice, "posthumous choice rejected")
assert_eq(dead_choice_err, "dead packet cannot record choice", "posthumous choice error")
assert_eq(#corpse.boundary.choices, choices_at_death, "no half-write to choices")

local dead_validation, dead_validation_err = body.record_validation(corpse, {
    kind = "validation_payload",
    status = "accepted",
})
assert_true(not dead_validation, "posthumous validation rejected")
assert_eq(dead_validation_err, "dead packet cannot record validation", "posthumous validation error")
assert_eq(#corpse.boundary.validations, 0, "no half-write to validations")

local dead_cycle, dead_cycle_err = body.record_cycle(corpse, {
    kind = "cycle_payload",
    decision = "again",
})
assert_true(not dead_cycle, "posthumous cycle rejected")
assert_eq(dead_cycle_err, "dead packet cannot record cycle", "posthumous cycle error")
assert_eq(#corpse.boundary.cycles, 0, "no half-write to cycles")
local dead_observation, dead_observation_err = body.record_observation(corpse, "upper", {
    scope_refs = {"chaos:raw_prompt"},
    content_truth_status = "semantic_proposal",
})
assert_true(not dead_observation, "posthumous observation rejected")
assert_eq(dead_observation_err, "dead packet cannot record observation", "posthumous observation error")
assert_eq(#corpse.boundary.observations.upper, 0, "no posthumous upper observation")
assert_eq(#corpse.trace, trace_at_death, "ledger frozen through body channel")

print("test_body ok")
