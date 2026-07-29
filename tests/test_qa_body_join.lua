package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local evidence = require("runtime.qa_evidence")
local execution = require("runtime.qa_execution")
local packet = require("core.packet")
local fixture = require("tests.support.qa_hand")

local suite = H.new("qa-execution-body")

local function events(instance, event_type)
    return fixture.events(instance, event_type)
end

local function one_event(instance, event_type)
    local found = events(instance, event_type)
    H.assert_eq(#found, 1, "one " .. event_type)
    return found[1]
end

suite:check("M2.3 accepted RUN joins one exact body check", function()
    local grown = fixture.grow_body({label = "body-check-accepted"})
    local outcome = assert(execution.execute(
        grown.instance,
        grown.body_services
    ))
    local event = one_event(grown.instance, "qa_check")
    H.assert_eq(outcome.outcome, "accepted")
    H.assert_eq(outcome.qa_check_id, event.payload.qa_check_id)
    H.assert_true(evidence.verify_check(grown.instance, event.payload))
    H.assert_eq(event.cost.tool_calls, 1)
    H.assert_eq(event.cost.test_runs, 1)
    H.assert_eq(event.cost.steps, 0)
    H.assert_eq(#events(grown.instance, "qa_execution_failure"), 0)
end)

suite:check("M2.3 contained rejection remains candidate evidence", function()
    local grown = fixture.grow_body({
        label = "body-check-rejected",
        adapter_options = {reason = "unexpected_exit", exit_code = 70},
    })
    local outcome = assert(execution.execute(
        grown.instance,
        grown.body_services
    ))
    H.assert_eq(outcome.outcome, "rejected")
    H.assert_eq(one_event(grown.instance, "qa_check").payload.reason,
        "unexpected_exit")
    H.assert_eq(#events(grown.instance, "qa_execution_failure"), 0)
end)

suite:check("M2.3 infrastructure writes failure and effect only", function()
    local grown = fixture.grow_body({
        label = "body-check-infrastructure",
        adapter_options = {error_code = "supervisor_unavailable"},
    })
    local outcome, effect = execution.execute(
        grown.instance,
        grown.body_services
    )
    H.assert_nil(outcome)
    H.assert_eq(effect.code, "qa_supervisor_unavailable")
    local failure = one_event(grown.instance, "qa_execution_failure").payload
    H.assert_true(evidence.verify_failure(grown.instance, failure))
    H.assert_eq(#events(grown.instance, "qa_check"), 0)
end)

suite:check("M2.3 replay returns one receipt without process or append", function()
    local grown = fixture.grow_body({label = "body-check-replay"})
    local first = assert(execution.execute(grown.instance, grown.body_services))
    local trace_count = #grown.instance.trace
    local second = assert(execution.execute(grown.instance, grown.body_services))
    H.assert_eq(first.execution_receipt_id, second.execution_receipt_id)
    H.assert_eq(grown.qa_adapter_state.runs, 1)
    H.assert_eq(#grown.instance.trace, trace_count)
end)

suite:check("M2.3 source drift cannot become candidate truth", function()
    local grown = fixture.grow_body({label = "body-check-source-drift"})
    local inventory = grown.repository_provider.inventory_tree
    local calls = 0
    grown.repository_provider.inventory_tree = function(...)
        calls = calls + 1
        if calls == 2 then
            grown.repository_state.files["drift.lua"] = "return false\n"
        end
        return inventory(...)
    end
    local outcome, effect = execution.execute(
        grown.instance,
        grown.body_services
    )
    H.assert_nil(outcome)
    H.assert_eq(effect.code, "qa_source_drift")
    H.assert_eq(#events(grown.instance, "qa_check"), 0)
    one_event(grown.instance, "qa_execution_failure")
end)

suite:check("M2.3 malformed trusted provider result is loud and inert", function()
    local grown = fixture.grow_body({
        label = "body-check-malformed",
        adapter_options = {
            report = {protocol_version = "trusted-but-malformed"},
        },
    })
    local ok = pcall(execution.execute, grown.instance, grown.body_services)
    H.assert_false(ok)
    H.assert_eq(#events(grown.instance, "qa_check"), 0)
    H.assert_eq(#events(grown.instance, "qa_execution_failure"), 0)
    H.assert_eq(grown.instance.status, "running")
end)

suite:check("M2.4 receipt body split is loud and never reruns", function()
    local grown = fixture.grow_body({label = "body-check-split"})
    local append = packet.append_qa_event
    packet.append_qa_event = function(instance, event)
        if event.type == "qa_check" then
            return nil, "fixture append boundary denied"
        end
        return append(instance, event)
    end
    local first_ok = pcall(execution.execute, grown.instance, grown.body_services)
    packet.append_qa_event = append
    local second_ok = pcall(execution.execute, grown.instance, grown.body_services)
    H.assert_false(first_ok)
    H.assert_false(second_ok)
    H.assert_eq(grown.qa_adapter_state.runs, 1)
    H.assert_eq(#events(grown.instance, "qa_check"), 0)
end)

suite:check("M2.4 alignment drift after receipt writes no body outcome", function()
    local observed = assert(fixture.run_alignment_split_case())
    H.assert_true(observed.loud)
    H.assert_eq(observed.check_count, 0)
    H.assert_eq(observed.failure_count, 0)
    H.assert_eq(observed.qa_runs, 1)
end)

suite:check("M2.4 timeout and cleanup ambiguity remain distinct", function()
    local observed = assert(fixture.run_timeout_cleanup_pair())
    H.assert_eq(observed.timeout.check_outcome, "rejected")
    H.assert_nil(observed.timeout.execution_failure)
    H.assert_nil(observed.cleanup.check)
    H.assert_eq(observed.cleanup.execution_failure.class, "ambiguous")
end)

suite:finish()
print("test_qa_body_join ok")
