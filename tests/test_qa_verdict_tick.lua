package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local budget = require("runtime.budget")
local fixture = require("tests.support.qa_hand")
local qa_verdict = require("runtime.qa_verdict")
local runner = require("runtime.tension_runner")
local runtime_organ = require("organs.runtime")

local suite = H.new("qa-verdict-tick")

local function event_index(instance, event_type, event_id)
    for index, event in ipairs(instance.trace or {}) do
        if event.type == event_type and (event_id == nil or event.id == event_id) then
            return index, event
        end
    end
    return nil
end

local function execute_then_verdict(options)
    local execution = assert(fixture.run_qa_execution_tick(options))
    local grown = execution.grown
    fixture.move_to(grown.instance, "☱")
    local before = budget.snapshot(grown.instance)
    local instance, result = assert(runner.execute_qa_verdict_tick(
        grown.instance,
        grown.qa_contract.qa_contract_id
    ))
    return grown, instance, result, before, budget.snapshot(instance)
end

suite:check("M3 accepted verdict occupies one ordinary runtime tick", function()
    local grown, instance, result, before, after = execute_then_verdict({
        label = "qa-verdict-runner-accepted",
    })
    H.assert_eq(result.status, "applied")
    H.assert_eq(result.payload.mode, "qa_verdict")
    H.assert_eq(result.payload.verdict, "accepted")
    H.assert_eq((after.spent.steps or 0) - (before.spent.steps or 0), 1)
    H.assert_eq((after.spent.tool_calls or 0)
        - (before.spent.tool_calls or 0), 0)
    H.assert_eq((after.spent.test_runs or 0)
        - (before.spent.test_runs or 0), 0)
    H.assert_eq(#fixture.events(instance, "qa_candidate_verdict"), 1)
    H.assert_eq(grown.qa_adapter_state.runs, 1)
end)

suite:check("M3 rejected verdict has equal tick depth", function()
    local _, instance, result, before, after = execute_then_verdict({
        label = "qa-verdict-runner-rejected",
        adapter_options = {reason = "unexpected_exit", exit_code = 70},
    })
    H.assert_eq(result.payload.verdict, "rejected")
    H.assert_eq((after.spent.steps or 0) - (before.spent.steps or 0), 1)
    H.assert_eq(#fixture.events(instance, "qa_candidate_verdict"), 1)
end)

suite:check("M3 verdict precedes reconciliation and preserves camera", function()
    local _, instance, result = execute_then_verdict({
        label = "qa-verdict-camera-order",
    })
    local verdict_index = assert(event_index(
        instance,
        "qa_candidate_verdict",
        result.payload.verdict_event_id
    ))
    local reconciliation_index = assert(event_index(
        instance,
        "runtime_reconciliation",
        result.payload.reconciliation.trace_event_id
    ))
    local observation_index = assert(event_index(
        instance,
        "observation",
        result.payload.trace_event_id
    ))
    H.assert_true(verdict_index < reconciliation_index)
    H.assert_true(reconciliation_index < observation_index)
    H.assert_true(type(result.runtime_frame_ref) == "string")
    H.assert_eq(result.payload.reconciliation.status, "reconciled")
end)

suite:check("M3 verdict action is exclusive with other runtime authority", function()
    local grown = fixture.grow_body({label = "qa-verdict-exclusive"})
    local readiness = assert(runtime_organ.readiness(grown.instance, {
        qa_verdict = {
            action = "assemble_current_candidate_verdict",
            qa_contract_id = grown.qa_contract.qa_contract_id,
        },
        repository_reconcile = {},
    }))
    H.assert_false(readiness.ready)
    H.assert_contains(readiness.reason, "exclusive")
end)

suite:check("M3 not-ready verdict spends nothing and calls no provider", function()
    local grown = fixture.grow_body({label = "qa-verdict-not-ready"})
    fixture.move_to(grown.instance, "☱")
    local before = budget.snapshot(grown.instance)
    local instance, err = runner.execute_qa_verdict_tick(
        grown.instance,
        grown.qa_contract.qa_contract_id
    )
    H.assert_nil(instance)
    H.assert_contains(err, "qa_request_not_ready")
    local after = budget.snapshot(grown.instance)
    H.assert_eq(after.event_count, before.event_count)
    H.assert_eq(grown.qa_adapter_state.runs, 0)
    H.assert_eq(#fixture.events(grown.instance, "qa_candidate_verdict"), 0)
end)

suite:check("M3 one actor tick cannot settle verdict twice", function()
    local grown, instance = execute_then_verdict({
        label = "qa-verdict-runner-replay",
    })
    local before = budget.snapshot(instance)
    local second, second_err = runner.execute_qa_verdict_tick(
        instance,
        grown.qa_contract.qa_contract_id
    )
    H.assert_nil(second)
    H.assert_contains(second_err, "current_tick_already_settled")
    H.assert_eq(budget.snapshot(instance).event_count, before.event_count)
    H.assert_eq(grown.qa_adapter_state.runs, 1)
end)

suite:check("M3 verdict writer rejects an actor-invalid direct commit", function()
    local execution = assert(fixture.run_qa_execution_tick({
        label = "qa-verdict-actor-invalid",
    }))
    local grown = execution.grown
    local prepared = assert(qa_verdict.prepare(
        grown.instance,
        grown.qa_contract.qa_contract_id
    ))
    local value, _, err = qa_verdict.commit(grown.instance, prepared)
    H.assert_nil(value)
    H.assert_contains(err, "actor")
    H.assert_eq(#fixture.events(grown.instance, "qa_candidate_verdict"), 0)
end)

suite:finish()
print("test_qa_verdict_tick ok")
