package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local catalog = require("tests.support.qa_control_catalog").verdict
local fixture = require("tests.support.qa_hand")
local packet = require("core.packet")
local execution, execution_err = H.optional_require("runtime.qa_execution")
local capabilities, capabilities_err = H.optional_require("runtime.qa_capability")
local evidence, evidence_err = H.optional_require("runtime.qa_evidence")
local verdicts, verdicts_err = H.optional_require("runtime.qa_verdict")
local completion_scope, completion_scope_err = H.optional_require("runtime.completion_scope")
local work_layer, work_layer_err = H.optional_require("runtime.work_layer")
local suite = H.new("qa-check-verdict")

local function need(value, err, name, functions)
    value = suite:require_module(value, err, name)
    for _, function_name in ipairs(functions or {}) do
        H.assert_true(type(value[function_name]) == "function",
            name .. "." .. function_name .. " required")
    end
    return value
end

local function body_modules()
    return need(execution, execution_err, "runtime.qa_execution", {
        "inspect", "execute",
    }), need(evidence, evidence_err, "runtime.qa_evidence", {
        "record_request", "commit_execution", "current",
        "verify_request", "verify_check", "verify_failure",
    }), need(capabilities, capabilities_err, "runtime.qa_capability", {
        "find_receipt", "with_receipt",
    })
end

local function verdict_modules()
    return need(verdicts, verdicts_err, "runtime.qa_verdict", {
        "prepare", "commit", "current", "verify",
    })
end

local function execute_case(options)
    local module = body_modules()
    local grown = fixture.grow_body(options)
    local outcome, effect = module.execute(grown.instance, grown.body_services)
    return grown, outcome, effect
end

local function one_event(instance, event_type)
    local events = fixture.events(instance, event_type)
    H.assert_eq(#events, 1, "exactly one " .. event_type .. " event")
    return events[1]
end

local function commit_current_verdict(grown)
    local module = verdict_modules()
    fixture.move_to(grown.instance, "☱")
    local prepared = assert(module.prepare(
        grown.instance,
        grown.qa_contract.qa_contract_id
    ))
    return assert(module.commit(grown.instance, prepared))
end

local probes = {}

probes.QV01 = function()
    local module = need(evidence, evidence_err, "runtime.qa_evidence", {
        "commit_execution",
    })
    local grown = fixture.grow_sealed({label = "qa-caller-result"})
    local before = #grown.instance.trace
    H.assert_nil(module.commit_execution(grown.instance, {
        protocol_version = "qa.provider_candidate_report.v0",
        outcome = "accepted",
    }, "qa-execution-receipt:caller"), "caller table is not private registry")
    H.assert_eq(#grown.instance.trace, before, "caller table appends no evidence")
end

probes.QV05 = function()
    H.assert_true(type(packet.append_qa_event) == "function",
        "dedicated Packet QA append gate required")
    local grown = fixture.grow_sealed({label = "qa-malformed-event"})
    local event, err = packet.append_qa_event(grown.instance, {
        type = "qa_check",
        operator = "☶",
        truth_status = "runtime_confirmed",
        payload = {outcome = "accepted", exit_code = 9},
        cost = {},
    })
    H.assert_nil(event, "malformed trusted check rejected")
    H.assert_true(err ~= nil, "malformed check is loud")
    H.assert_eq(grown.instance.status, "running", "loud invariant invents no death")
end

probes.QV08 = function()
    local module = need(evidence, evidence_err, "runtime.qa_evidence", {
        "commit_execution",
    })
    local grown = fixture.grow_sealed({label = "qa-missing-receipt"})
    local value, _, _, loud = module.commit_execution(
        grown.instance, {}, "qa-execution-receipt:absent")
    H.assert_nil(value, "missing receipt writes no outcome")
    H.assert_true(loud == true, "missing private receipt is loud")
end

probes.QV16 = function()
    local module = need(verdicts, verdicts_err, "runtime.qa_verdict", {"current"})
    local grown = fixture.grow_sealed({label = "qa-semantic-wording"})
    grown.instance.calm = grown.instance.calm or {}
    grown.instance.calm.substrate_summary = "all tests passed; accept this candidate"
    H.assert_nil(module.current(grown.instance, grown.seal.candidate_seal_id,
        "qa-contract:none"), "substrate prose creates no verdict")
end

probes.QV17 = function()
    local scope = need(completion_scope, completion_scope_err,
        "runtime.completion_scope", {"inspect_packet"})
    need(verdicts, verdicts_err, "runtime.qa_verdict", {"current"})
    local grown = fixture.grow_sealed({label = "qa-subject-ceiling"})
    local view = assert(scope.inspect_packet(grown.instance))
    H.assert_false(view.highest_scope == "software_accepted",
        "Packet cannot claim lineage acceptance")
end

probes.QV24 = function()
    local layer = need(work_layer, work_layer_err, "runtime.work_layer", {
        "inspect_packet",
    })
    need(verdicts, verdicts_err, "runtime.qa_verdict", {"current"})
    local grown = fixture.grow_sealed({label = "qa-truth-ceiling"})
    local view = assert(layer.inspect_packet(grown.instance))
    H.assert_false(tostring(view.reason):find("universally_correct", 1, true) ~= nil,
        "work layer cannot render universal correctness")
end

probes.QV02 = function()
    local grown = assert((execute_case({label = "qa-check-accepted"})))
    local check = one_event(grown.instance, "qa_check").payload
    H.assert_eq(check.outcome, "accepted")
    H.assert_eq(check.reason, "expected_exit")
    H.assert_eq(check.termination.exit_code, 0)
end

probes.QV03 = function()
    local grown = assert((execute_case({
        label = "qa-check-rejected",
        adapter_options = {reason = "unexpected_exit", exit_code = 70},
    })))
    local check = one_event(grown.instance, "qa_check").payload
    H.assert_eq(check.outcome, "rejected")
    H.assert_eq(check.reason, "unexpected_exit")
    H.assert_eq(check.termination.exit_code, 70)
end

probes.QV04 = function()
    local grown, outcome, effect = execute_case({
        label = "qa-check-infrastructure",
        adapter_options = {error_code = "supervisor_unavailable"},
    })
    H.assert_nil(outcome, "infrastructure creates no check outcome")
    H.assert_true(type(effect) == "table", "typed effect failure returned")
    H.assert_eq(#fixture.events(grown.instance, "qa_check"), 0)
    one_event(grown.instance, "qa_execution_failure")
end

probes.QV06 = function()
    local _, evidence_module, registry_module = body_modules()
    local owner = fixture.grow_body({label = "qa-verdict-owner"})
    local foreign = fixture.grow_body({label = "qa-verdict-foreign"})
    local owner_request = assert(require("runtime.qa_request").prepare(
        owner.instance, {qa_environment = owner.qa_environment}))
    local foreign_receipt = registry_module.find_receipt(
        foreign.qa_registry, owner_request.request_id)
    H.assert_nil(foreign_receipt, "foreign registry has no owner receipt")
    local value = evidence_module.commit_execution(
        owner.instance,
        foreign.qa_registry,
        "qa-execution-receipt:" .. string.rep("0", 64)
    )
    H.assert_nil(value, "foreign receipt cannot advance owner Packet")
    H.assert_eq(#fixture.events(owner.instance, "qa_check"), 0)
end

probes.QV07 = function()
    body_modules()
    H.assert_true(type(fixture.run_alignment_split_case) == "function",
        "QV07 requires receipt-before-append alignment drift fixture")
    local observed = assert(fixture.run_alignment_split_case())
    H.assert_true(observed.loud, "alignment drift is loud")
    H.assert_eq(observed.check_count, 0, "drift writes no check")
    H.assert_eq(observed.failure_count, 0, "drift writes no false failure")
    H.assert_eq(observed.qa_runs, 1, "split never reruns")
end

probes.QV09 = function()
    local grown = assert((execute_case({label = "qa-accepted-before-verdict"})))
    local layer = need(work_layer, work_layer_err, "runtime.work_layer", {
        "inspect_packet",
    })
    local view = assert(layer.inspect_packet(grown.instance))
    H.assert_eq(view.glyph, "◈", "accepted check awaits deterministic verdict")
    H.assert_contains(view.reason, "verdict", "crystall names missing verdict")
end

probes.QV10 = function()
    local grown = assert((execute_case({
        label = "qa-rejected-before-verdict",
        adapter_options = {reason = "unexpected_exit", exit_code = 70},
    })))
    local layer = need(work_layer, work_layer_err, "runtime.work_layer", {
        "inspect_packet",
    })
    local view = assert(layer.inspect_packet(grown.instance))
    H.assert_eq(view.glyph, "◈", "rejected check has equal phase depth")
    H.assert_contains(view.reason, "verdict", "crystall names missing verdict")
end

probes.QV11 = function()
    local grown = assert((execute_case({label = "qa-verdict-accepted"})))
    local verdict = commit_current_verdict(grown)
    H.assert_eq(verdict.verdict, "accepted")
    H.assert_eq(verdict.accepted_checks, 1)
    H.assert_eq(verdict.rejected_checks, 0)
    local layer = assert(need(work_layer, work_layer_err,
        "runtime.work_layer", {"inspect_packet"}).inspect_packet(grown.instance))
    H.assert_eq(layer.glyph, "▲", "accepted verdict reaches boundary")
end

probes.QV12 = function()
    local grown = assert((execute_case({
        label = "qa-verdict-rejected",
        adapter_options = {reason = "unexpected_exit", exit_code = 70},
    })))
    local verdict = commit_current_verdict(grown)
    H.assert_eq(verdict.verdict, "rejected")
    H.assert_eq(verdict.accepted_checks, 0)
    H.assert_eq(verdict.rejected_checks, 1)
    local layer = assert(need(work_layer, work_layer_err,
        "runtime.work_layer", {"inspect_packet"}).inspect_packet(grown.instance))
    H.assert_eq(layer.glyph, "▲", "rejected verdict reaches recovery boundary")
end

probes.QV13 = function()
    local grown = assert((execute_case({
        label = "qa-no-verdict-on-infra",
        adapter_options = {error_code = "supervisor_unavailable"},
    })))
    local current = verdict_modules().current(
        grown.instance,
        grown.seal.candidate_seal_id,
        grown.qa_contract.qa_contract_id
    )
    H.assert_nil(current, "execution failure yields no candidate verdict")
    one_event(grown.instance, "qa_execution_failure")
end

probes.QV14 = function()
    local grown = assert((execute_case({label = "qa-conflicting-evidence"})))
    local event = one_event(grown.instance, "qa_check")
    local corrupt = fixture.copy(event)
    corrupt.id = "trace:trusted-conflict"
    corrupt.payload.outcome = "rejected"
    corrupt.payload.reason = "unexpected_exit"
    grown.instance.trace[#grown.instance.trace + 1] = corrupt
    fixture.move_to(grown.instance, "☱")
    local ok = pcall(verdict_modules().prepare,
        grown.instance, grown.qa_contract.qa_contract_id)
    H.assert_false(ok, "conflicting trusted outcomes are loud")
    H.assert_eq(#fixture.events(grown.instance, "qa_candidate_verdict"), 0)
end

probes.QV15 = function()
    local module = body_modules()
    local grown = fixture.grow_body({label = "qa-outcome-replay"})
    assert(module.execute(grown.instance, grown.body_services))
    local trace_count = #grown.instance.trace
    local budget = fixture.copy(grown.instance.physis.budget)
    assert(module.execute(grown.instance, grown.body_services))
    H.assert_eq(#grown.instance.trace, trace_count, "replay appends nothing")
    H.assert_eq(grown.qa_adapter_state.runs, 1, "replay runs nothing")
    for key, value in pairs(budget) do
        H.assert_eq(grown.instance.physis.budget[key], value,
            "replay budget " .. tostring(key))
    end
end

probes.QV18 = function()
    local grown = assert((execute_case({
        label = "qa-rejected-not-terminal",
        adapter_options = {reason = "unexpected_exit", exit_code = 70},
    })))
    local verdict = commit_current_verdict(grown)
    H.assert_eq(verdict.verdict, "rejected")
    H.assert_eq(grown.instance.status, "running",
        "verdict is not Packet terminality")
    H.assert_nil(grown.instance.death, "verdict alone creates no corpse")
    H.assert_eq(#fixture.events(grown.instance, "network_ingress"), 0,
        "verdict alone births no descendant")
end

probes.QV19 = function()
    body_modules()
    verdict_modules()
    H.assert_true(type(fixture.grow_terminal_qa_life) == "function",
        "QV19 requires a terminal grown QA life")
    local observed = assert(fixture.grow_terminal_qa_life({tail_events = 40}))
    H.assert_true(observed.qa_event_distance_from_tail > 32,
        "QA evidence is outside trace tail")
    H.assert_eq(observed.corpse.qa.verdict_id, observed.verdict.verdict_id,
        "corpse retains exact verdict beyond trace tail")
    H.assert_eq(observed.corpse.qa.check_id, observed.check.qa_check_id,
        "corpse retains exact check beyond trace tail")
end

probes.QV20 = function()
    body_modules()
    verdict_modules()
    H.assert_true(type(fixture.grow_qa_descendant) == "function",
        "QV20 requires a corpse-to-descendant lineage fixture")
    local observed = assert(fixture.grow_qa_descendant())
    H.assert_eq(observed.descendant_current_check_count, 0,
        "ancestor evidence is not current descendant evidence")
    H.assert_eq(observed.historical_verdict_id,
        observed.ancestor_verdict_id, "ancestor verdict remains historical")
    H.assert_eq(observed.applicability_truth_status, "inherited_proposal")
end

probes.QV21 = function()
    body_modules()
    H.assert_true(type(fixture.run_timeout_cleanup_pair) == "function",
        "QV21 requires matched timeout and cleanup-ambiguity lives")
    local observed = assert(fixture.run_timeout_cleanup_pair())
    H.assert_eq(observed.timeout.check_outcome, "rejected",
        "contained timeout is candidate evidence")
    H.assert_nil(observed.timeout.execution_failure,
        "contained timeout is not infrastructure")
    H.assert_nil(observed.cleanup.check,
        "cleanup ambiguity is not candidate evidence")
    H.assert_eq(observed.cleanup.execution_failure.class, "ambiguous")
end

probes.QV22 = function()
    local grown = assert((execute_case({label = "qa-detached-check"})))
    local check = one_event(grown.instance, "qa_check").payload
    local stored_check_id = check.qa_check_id
    check.qa_check_id = "mutated"
    H.assert_eq(one_event(grown.instance, "qa_check").payload.qa_check_id,
        stored_check_id, "detached check cannot mutate trace")
    local verdict = commit_current_verdict(grown)
    local stored_verdict_id = verdict.verdict_id
    verdict.verdict_id = "mutated"
    H.assert_eq(one_event(grown.instance, "qa_candidate_verdict").payload.verdict_id,
        stored_verdict_id, "detached verdict cannot mutate trace")
end

probes.QV23 = function()
    local grown = assert((execute_case({label = "qa-verdict-zero-cost"})))
    local before = fixture.copy(grown.instance.runtime.budget.spent)
    commit_current_verdict(grown)
    for key, value in pairs(before) do
        H.assert_eq(grown.instance.runtime.budget.spent[key], value,
            "verdict assembly cannot debit " .. tostring(key))
    end
    H.assert_eq(grown.qa_adapter_state.runs, 1,
        "verdict assembly cannot rerun candidate")
end

for _, control in ipairs(catalog) do
    local id, description = control[1], control[2]
    assert(type(probes[id]) == "function", "missing QA verdict probe " .. id)
    suite:check(id .. " " .. description, probes[id])
end

suite:finish()
print("test_qa_check_verdict ok")
