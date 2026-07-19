local completion = require("runtime.completion")
local corpse = require("runtime.corpse")
local lineage = require("runtime.lineage")
local lineage_budget = require("runtime.lineage_budget")
local lineage_runner = require("runtime.lineage_runner")
local fixture = require("tests.support.plan_life")

local proposal = fixture.proposal(
    "work_sequence",
    {"inspect", "change", "verify"}
)

local packet, result = assert(fixture.run(
    "completion-separation-corpse",
    "work_sequence",
    {"inspect", "change", "verify"},
    10,
    {packet_options = {budget = {steps = 2, substrate_calls = 8, loss = 1}}},
    proposal
))
assert(result.stop_reason == "budget_exhausted")

local dead = assert(corpse.capture(packet, {
    corpse_id = "corpse-completion-separation",
}))
assert(corpse.verify(dead))

local function state_for(options)
    options = options or {}
    local state = assert(lineage.create("prepare a plan", {
        lineage_id = dead.lineage_id,
        session_id = "completion-separation-session",
        work_mode = "plan",
        completion_contract_id = "plan.v0",
        allow_recovery = options.allow_recovery ~= false,
        carrier = {max_bytes = 65536},
        budget = {
            steps = options.steps or 100,
            generations = 4,
            carrier_bytes = 65536,
        },
    }))
    state.status = "evaluating_terminal"
    state.current_generation = dead.generation
    state.current_packet_id = dead.packet_id
    state.current_corpse_id = dead.corpse_id
    assert(lineage_budget.reconcile_packet(state.budget, dead))
    return state
end

local funded_state = state_for()
local exhausted_state = state_for({steps = dead.final_budget.spent.steps})
local disabled_state = state_for({allow_recovery = false})
assert(funded_state.budget.exhausted == false)
assert(exhausted_state.budget.exhausted == true)
assert(disabled_state.policy.allow_recovery == false)

local funded = assert(completion.evaluate(funded_state, dead))
local exhausted = assert(completion.evaluate(exhausted_state, dead))
local disabled = assert(completion.evaluate(disabled_state, dead))

for _, assessment in ipairs({funded, exhausted, disabled}) do
    assert(assessment.task_state == "unfinished")
    assert(assessment.terminal_recoverable == true)
    assert(assessment.terminal_recovery_basis == "budget_exhausted")
    assert(#assessment.missing_requirements == 0)
    assert(assessment.recoverable == nil)
end
assert(funded.assessment_id == exhausted.assessment_id)
assert(funded.assessment_id == disabled.assessment_id)

local id_counters = {}
local function id_source(kind)
    id_counters[kind] = (id_counters[kind] or 0) + 1
    return kind .. "-completion-separation-" .. tostring(id_counters[kind])
end

local function runner_options(label, overrides)
    local options = {
        session_id = label .. "-session",
        lineage_id = label .. "-lineage",
        work_mode = "plan",
        completion_contract_id = "plan.v0",
        flow_source = {2, 3, 5, 7, 11},
        flow_options = {
            stream_id = label .. "-stream",
            source_ref = "test:" .. label,
        },
        projection_adapter = "vertical_single.v0",
        packet_budget = {steps = 2, substrate_calls = 8, loss = 1},
        lineage_budget = {
            steps = 32,
            substrate_calls = 16,
            generations = 2,
            carrier_bytes = 65536,
        },
        carrier = {max_bytes = 65536},
        allow_recovery = true,
        history_enabled = false,
        emergency_max_generations = 2,
        packet_runner_options = {
            router_mode = "tree",
            pressure_policy = "qualified_need_v0",
            ablate_relation_consumer = true,
            legacy_shadow = false,
            max_ticks = 20,
        },
        id_source = id_source,
    }
    for key, value in pairs(overrides or {}) do
        options[key] = value
    end
    return options
end

local exhausted_lineage, exhausted_report = assert(lineage_runner.run(
    "economic completion separation",
    fixture.substrate(proposal),
    runner_options("completion-separation-economic", {
        lineage_budget = {
            steps = 2,
            substrate_calls = 16,
            generations = 2,
            carrier_bytes = 65536,
        },
    })
))
assert(exhausted_lineage.status == "exhausted")
assert(exhausted_lineage.terminal.cause == "lineage_budget_exhausted")
assert(#exhausted_report.generations == 1)
assert(#exhausted_report.carriers == 0)
assert(exhausted_report.assessments[1].task_state == "unfinished")
assert(exhausted_report.assessments[1].terminal_recoverable == true)

local disabled_lineage, disabled_report = assert(lineage_runner.run(
    "policy completion separation",
    fixture.substrate(proposal),
    runner_options("completion-separation-policy", {
        allow_recovery = false,
    })
))
assert(disabled_lineage.status == "suspended")
assert(disabled_lineage.terminal.cause == "recovery_disabled_by_policy")
assert(#disabled_report.generations == 1)
assert(#disabled_report.carriers == 0)
assert(disabled_report.assessments[1].task_state == "unfinished")
assert(disabled_report.assessments[1].terminal_recoverable == true)

print("test_lineage_completion_separation ok")
