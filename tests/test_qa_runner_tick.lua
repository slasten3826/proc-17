package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local budget = require("runtime.budget")
local runner = require("runtime.tension_runner")
local logic = require("organs.logic")
local fixture = require("tests.support.qa_hand")
local suite = H.new("qa-runner-tick")

local function fresh_qa_tick(grown)
    fixture.move_to(grown.instance, "☱")
    fixture.move_to(grown.instance, "☶")
    return grown
end

local function source_count(instance, source)
    local count = 0
    for _, event in ipairs(instance.runtime and instance.runtime.budget
            and instance.runtime.budget.events or {}) do
        if event.source == source then count = count + 1 end
    end
    return count
end

local function measured_failure_cost()
    return {
        protocol_version = "qa.cost.v1",
        tool_calls = 1,
        qa_executions = 1,
        wall_time_ms = 2,
        cpu_time_ms = 2,
        scratch_written_bytes = 0,
        stdout_observed_bytes = 0,
        stderr_observed_bytes = 0,
    }
end

suite:check("M2.5 runner settles one QA success exactly once", function()
    local observed = assert(fixture.run_qa_execution_tick({
        label = "qa-runner-success",
    }))
    H.assert_eq(observed.result.status, "applied")
    H.assert_eq(observed.step_delta, 1)
    H.assert_eq(observed.tool_call_delta, 1)
    H.assert_eq(observed.test_run_delta, 1)
    H.assert_eq(observed.result.payload.mode, "qa_execution")
    H.assert_eq(observed.result.payload.outcome_kind, "check")
    H.assert_eq(source_count(observed.instance, "qa_execution"), 1)
    H.assert_eq(observed.loss_delta, 0, "QA creates no identity loss")
end)

suite:check("M2.5 QA action cannot hide another LOGIC action", function()
    local grown = fresh_qa_tick(fixture.grow_body({
        label = "qa-runner-action-conflict",
    }))
    local readiness = assert(logic.readiness(grown.instance, {
        work_mode = "build",
        qa_execution = {action = "execute_current_candidate"},
        repository_effect = {action = {}},
    }, grown.body_services))
    H.assert_false(readiness.ready)
    H.assert_contains(readiness.reason, "exclusive")
    H.assert_eq(grown.qa_adapter_state.runs, 0)
end)

suite:check("M2.5 settled actor tick cannot debit or execute again", function()
    local observed = assert(fixture.run_qa_execution_tick({
        label = "qa-runner-settlement-replay",
    }))
    local before = budget.snapshot(observed.instance)
    local second, second_err = runner.execute_qa_tick(
        observed.instance,
        observed.grown.body_services
    )
    H.assert_nil(second)
    H.assert_contains(second_err, "current_tick_already_settled")
    local after = budget.snapshot(observed.instance)
    H.assert_eq(after.event_count, before.event_count)
    H.assert_eq(observed.grown.qa_adapter_state.runs, 1)
end)

suite:check("M2.5 direct evidence is charged by its first runner settlement", function()
    local execution = require("runtime.qa_execution")
    local grown = fixture.grow_body({label = "qa-direct-before-runner"})
    assert(execution.execute(grown.instance, grown.body_services))
    H.assert_eq(source_count(grown.instance, "qa_execution"), 0)
    fresh_qa_tick(grown)
    local before = budget.snapshot(grown.instance)
    local instance = assert(runner.execute_qa_tick(
        grown.instance,
        grown.body_services
    ))
    local after = budget.snapshot(instance)
    H.assert_eq((after.spent.tool_calls or 0)
        - (before.spent.tool_calls or 0), 1)
    H.assert_eq((after.spent.test_runs or 0)
        - (before.spent.test_runs or 0), 1)
    H.assert_eq(source_count(instance, "qa_execution"), 1)
    H.assert_eq(grown.qa_adapter_state.runs, 1)
end)

suite:check("M2.5 later QA replay pays a step but no second external cost", function()
    local observed = assert(fixture.run_qa_execution_tick({
        label = "qa-runner-later-replay",
    }))
    fresh_qa_tick(observed.grown)
    local before = budget.snapshot(observed.instance)
    local instance = assert(runner.execute_qa_tick(
        observed.instance,
        observed.grown.body_services
    ))
    local after = budget.snapshot(instance)
    H.assert_eq((after.spent.steps or 0) - (before.spent.steps or 0), 1)
    H.assert_eq((after.spent.tool_calls or 0)
        - (before.spent.tool_calls or 0), 0)
    H.assert_eq((after.spent.test_runs or 0)
        - (before.spent.test_runs or 0), 0)
    H.assert_eq(source_count(instance, "qa_execution"), 1)
    H.assert_eq(observed.grown.qa_adapter_state.runs, 1)
end)

suite:check("M2.5 typed infrastructure failure pays once then dies", function()
    local grown = fresh_qa_tick(fixture.grow_body({
        label = "qa-runner-effect-failure",
        adapter_options = {
            error_code = "supervisor_unavailable",
            measured_cost = measured_failure_cost(),
        },
    }))
    local before = budget.snapshot(grown.instance)
    local instance, result = assert(runner.execute_qa_tick(
        grown.instance,
        grown.body_services
    ))
    local after = budget.snapshot(instance)
    H.assert_eq(result.status, "effect_failure")
    H.assert_eq(instance.status, "dead")
    H.assert_eq(instance.death.cause, "effect_failure")
    H.assert_eq((after.spent.steps or 0) - (before.spent.steps or 0), 1)
    H.assert_eq((after.spent.tool_calls or 0)
        - (before.spent.tool_calls or 0), 1)
    H.assert_eq((after.spent.test_runs or 0)
        - (before.spent.test_runs or 0), 1)
    H.assert_eq(source_count(instance, "failed_external_effect"), 1)
    H.assert_eq(#fixture.events(instance, "qa_execution_failure"), 1)
    H.assert_eq(grown.qa_adapter_state.runs, 1)
end)

suite:check("M2.5 trusted contradiction stays loud and economically inert", function()
    local grown = fresh_qa_tick(fixture.grow_body({
        label = "qa-runner-trusted-contradiction",
        adapter_options = {
            report = {protocol_version = "trusted-but-malformed"},
        },
    }))
    local before = budget.snapshot(grown.instance)
    local ok = pcall(runner.execute_qa_tick,
        grown.instance, grown.body_services)
    H.assert_false(ok, "trusted contradiction must escape the body as loud")
    local after = budget.snapshot(grown.instance)
    H.assert_eq(after.event_count, before.event_count)
    H.assert_eq(grown.instance.status, "running")
    H.assert_eq(#fixture.events(grown.instance, "qa_check"), 0)
    H.assert_eq(#fixture.events(grown.instance, "qa_execution_failure"), 0)
end)

suite:finish()
print("test_qa_runner_tick ok")
