local completion = require("runtime.completion")
local corpse = require("runtime.corpse")
local lineage = require("runtime.lineage")
local fixture = require("tests.support.plan_life")

local function state_for(record, contract)
    local state = assert(lineage.create("prepare a plan", {
        lineage_id = record.lineage_id,
        session_id = "completion-session",
        work_mode = "plan",
        completion_contract_id = contract or "plan.v0",
        carrier = {max_bytes = 65536},
        budget = {steps = 100, generations = 4, carrier_bytes = 65536},
    }))
    state.status = "evaluating_terminal"
    state.current_generation = record.generation
    state.current_packet_id = record.packet_id
    state.current_corpse_id = record.corpse_id
    return state
end

local plan_packet = assert(fixture.run(
    "lineage-completion-plan",
    "work_sequence",
    {"inspect", "change", "verify"},
    5
))
local plan_corpse = assert(corpse.capture(plan_packet, {
    corpse_id = "corpse-lineage-completion-plan",
}))
local complete = assert(completion.evaluate(state_for(plan_corpse), plan_corpse))
assert(complete.task_state == "complete")
assert(complete.terminal_recoverable == false)
assert(complete.terminal_recovery_basis == nil)
assert(complete.recoverable == nil)
assert(complete.progress.delivered_item_count == 3)
assert(complete.basis_truth_statuses[2] == "semantic_proposal")

local budget_packet, budget_result = assert(fixture.run(
    "lineage-completion-budget",
    "work_sequence",
    {"inspect", "change", "verify"},
    10,
    {packet_options = {budget = {steps = 2, substrate_calls = 8, loss = 1}}}
))
assert(budget_result.stop_reason == "budget_exhausted")
local budget_corpse = assert(corpse.capture(budget_packet, {
    corpse_id = "corpse-lineage-completion-budget",
}))
local unfinished = assert(completion.evaluate(state_for(budget_corpse), budget_corpse))
assert(unfinished.task_state == "unfinished")
assert(unfinished.terminal_recoverable == true)
assert(unfinished.terminal_recovery_basis == "budget_exhausted")
assert(unfinished.recoverable == nil)

local unknown = assert(completion.evaluate(
    state_for(budget_corpse, "build.v9"),
    budget_corpse
))
assert(unknown.task_state == "unknown")
assert(unknown.terminal_recoverable == false)

local forged = assert(corpse.capture(plan_packet, {
    corpse_id = "corpse-lineage-completion-forged",
}))
forged.manifest.assembly.assessment_ref = "missing-assessment"
forged.corpse_hash = require("core.digest").record((function()
    local projected = {}
    for key, value in pairs(forged) do
        if key ~= "corpse_hash" then
            projected[key] = value
        end
    end
    return projected
end)())
local forged_state = state_for(forged)
local blocked = assert(completion.evaluate(forged_state, forged))
assert(blocked.task_state == "blocked")
assert(blocked.terminal_recoverable == false)

print("test_lineage_completion ok")
