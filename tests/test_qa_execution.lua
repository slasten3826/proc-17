package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local catalog = require("tests.support.qa_control_catalog").execution
local fixture = require("tests.support.qa_hand")
local packet = require("core.packet")
local repository_capabilities = require("runtime.repository_capability")
local requests, requests_err = H.optional_require("runtime.qa_request")
local capabilities, capabilities_err = H.optional_require("runtime.qa_capability")
local execution, execution_err = H.optional_require("runtime.qa_execution")
local evidence, evidence_err = H.optional_require("runtime.qa_evidence")
local suite = H.new("qa-execution")

local function need(value, err, name, functions)
    value = suite:require_module(value, err, name)
    for _, function_name in ipairs(functions or {}) do
        H.assert_true(type(value[function_name]) == "function",
            name .. "." .. function_name .. " required")
    end
    return value
end

local function same_snapshot(left, right)
    H.assert_eq(left.trace_count, right.trace_count, "trace count")
    H.assert_eq(left.loss_remaining, right.loss_remaining, "identity loss")
    for key, value in pairs(left.revisions or {}) do
        H.assert_eq(right.revisions[key], value, "revision " .. tostring(key))
    end
    for key, value in pairs(left.budget or {}) do
        H.assert_eq(right.budget[key], value, "budget " .. tostring(key))
    end
end

local function body_modules()
    return need(execution, execution_err, "runtime.qa_execution", {
        "inspect", "execute",
    }), need(evidence, evidence_err, "runtime.qa_evidence", {
        "record_request", "commit_execution", "current",
    }), need(capabilities, capabilities_err, "runtime.qa_capability", {
        "new", "mint", "begin", "with_execution", "commit",
        "with_receipt", "quarantine", "find_receipt",
    })
end

local function run_body(options)
    local module = body_modules()
    local grown = fixture.grow_body(options)
    local outcome, effect_or_err = module.execute(
        grown.instance,
        grown.body_services
    )
    return grown, outcome, effect_or_err
end

local function one_event(instance, event_type)
    local events = fixture.events(instance, event_type)
    H.assert_eq(#events, 1, "exactly one " .. event_type .. " event")
    return events[1]
end

local probes = {}

probes.QE01 = function()
    local module = need(execution, execution_err, "runtime.qa_execution", {"inspect"})
    local grown = fixture.grow_sealed({label = "qa-disabled-ablation"})
    local before = fixture.snapshot(grown.instance)
    local readiness = module.inspect(grown.instance, {
        repository_capabilities = grown.repository_registry,
        qa_enabled = false,
    })
    H.assert_nil(readiness, "disabled QA has no readiness")
    same_snapshot(before, fixture.snapshot(grown.instance))
end

probes.QE02 = function()
    local module = need(requests, requests_err, "runtime.qa_request", {"verify"})
    local grown = fixture.grow_sealed({label = "qa-command-surface"})
    local hostile = {
        protocol_version = "qa.check_request.v0",
        command = {"lua", "tests/run.lua"},
        executable = "/usr/bin/lua",
        argv = {},
        environment = {PATH = "/host"},
        cwd = "/host",
    }
    H.assert_nil(module.verify(grown.instance, hostile),
        "command-shaped request rejected")
end

probes.QE03 = function()
    local module = need(capabilities, capabilities_err, "runtime.qa_capability", {"begin"})
    H.assert_nil(module.begin({grant_id = "qa-grant:public"},
        "qa-check-request:public", "trace:public"),
        "detached public projection is not a registry")
end

probes.QE04 = function()
    local module = need(execution, execution_err, "runtime.qa_execution", {"inspect"})
    local adapter, state = fixture.native_adapter()
    local instance = packet.new("unsealed QA candidate", {
        work_mode = "build",
        repository_id = "repo-unsealed-qa",
    })
    H.assert_nil(module.inspect(instance, {qa_provider = adapter}),
        "unsealed Packet is not ready")
    H.assert_eq(state.runs, 0, "unsealed inspection launches no candidate")
end

probes.QE05 = function()
    local module = need(capabilities, capabilities_err, "runtime.qa_capability", {"mint"})
    local grown = fixture.grow_sealed({label = "qa-request-event-required"})
    H.assert_nil(module.mint({}, grown.instance, {
        request_id = "qa-check-request:no-event",
    }, "trace:missing"), "grant requires private registry and body request event")
end

probes.QE06 = function()
    H.assert_true(type(repository_capabilities.reserve_qa_source) == "function",
        "private source reservation API required")
    local projection = repository_capabilities.reserve_qa_source({}, {
        request_id = "qa-check-request:public",
    })
    H.assert_nil(projection, "public binding cannot obtain a source lease")
end

probes.QE07 = function()
    H.assert_true(type(repository_capabilities.reserve_qa_source) == "function",
        "private source reservation API required")
    local grown = fixture.grow_sealed({label = "qa-root-remains-sealed"})
    local before = assert(repository_capabilities.root_authority(
        grown.repository_registry, {grant_id = grown.repository_grant.grant_id}))
    H.assert_eq(before.state, "sealed", "candidate starts sealed")
    H.assert_nil(repository_capabilities.reserve_qa_source(
        grown.repository_registry, {request_id = "foreign"}),
        "foreign source binding denied")
    local after = assert(repository_capabilities.root_authority(
        grown.repository_registry, {root_authority_id = before.root_authority_id}))
    H.assert_eq(after.state, "sealed", "denial cannot reopen source writes")
end

probes.QE08 = function()
    local module = body_modules()
    local grown = fixture.grow_body({label = "qa-replay"})
    local first = assert(module.execute(grown.instance, grown.body_services))
    local trace_after_first = #grown.instance.trace
    local second = assert(module.execute(grown.instance, grown.body_services))
    H.assert_eq(grown.qa_adapter_state.runs, 1, "replay launches once")
    H.assert_eq(#grown.instance.trace, trace_after_first, "replay appends nothing")
    H.assert_eq(first.execution_receipt_id, second.execution_receipt_id,
        "replay returns the same receipt")
    one_event(grown.instance, "qa_check_request")
    one_event(grown.instance, "qa_check")
end

probes.QE09 = function()
    local module = body_modules()
    local grown = fixture.grow_body({
        label = "qa-failed-first-sticky",
        adapter_options = {run_error = "fixture trusted failure"},
    })
    local first_ok = pcall(module.execute, grown.instance, grown.body_services)
    local second_ok = pcall(module.execute, grown.instance, grown.body_services)
    H.assert_false(first_ok, "trusted first failure stays loud")
    H.assert_false(second_ok, "failed authority is not reactivated")
    H.assert_eq(grown.qa_adapter_state.runs, 1, "failed transaction never reruns")
end

probes.QE10 = function()
    local grown = assert((run_body({label = "qa-seal-normalization"})))
    local check = one_event(grown.instance, "qa_check").payload
    H.assert_eq(check.source.pre_inventory_id, grown.seal.inventory_id,
        "pre inventory is the sealed inventory")
    H.assert_eq(check.source.post_inventory_id, grown.seal.inventory_id,
        "post inventory uses the same normalization")
    H.assert_true(check.source.stable, "source remained exact")
end

probes.QE11 = function()
    local module = body_modules()
    local grown = fixture.grow_body({label = "qa-source-drift"})
    local original = grown.repository_provider.inventory_tree
    local inventories = 0
    grown.repository_provider.inventory_tree = function(...)
        inventories = inventories + 1
        if inventories == 2 then
            grown.repository_state.files["drift.lua"] = "return false\n"
        end
        return original(...)
    end
    local outcome = module.execute(grown.instance, grown.body_services)
    H.assert_nil(outcome, "drift cannot become a candidate outcome")
    H.assert_eq(#fixture.events(grown.instance, "qa_check"), 0,
        "drift writes no check")
    H.assert_eq(#fixture.events(grown.instance, "qa_execution_failure"), 1,
        "drift writes one infrastructure failure")
end

probes.QE12 = function()
    local accepted = assert((run_body({label = "qa-accepted"})))
    local rejected = assert((run_body({
        label = "qa-rejected",
        adapter_options = {reason = "unexpected_exit", exit_code = 70},
    })))
    local failed, outcome, effect = run_body({
        label = "qa-infrastructure",
        adapter_options = {error_code = "supervisor_unavailable"},
    })
    H.assert_eq(one_event(accepted.instance, "qa_check").payload.outcome,
        "accepted")
    H.assert_eq(one_event(rejected.instance, "qa_check").payload.outcome,
        "rejected")
    H.assert_nil(outcome, "infrastructure has no candidate outcome")
    H.assert_true(type(effect) == "table", "infrastructure returns effect failure")
    one_event(failed.instance, "qa_execution_failure")
end

probes.QE13 = function()
    local module = body_modules()
    local grown = fixture.grow_body({
        label = "qa-malformed-provider",
        adapter_options = {report = {protocol_version = "trusted-but-malformed"}},
    })
    local ok = pcall(module.execute, grown.instance, grown.body_services)
    H.assert_false(ok, "malformed trusted report is loud")
    H.assert_eq(#fixture.events(grown.instance, "qa_check"), 0)
    H.assert_eq(#fixture.events(grown.instance, "qa_execution_failure"), 0)
    H.assert_eq(grown.instance.status, "running", "loud failure invents no death")
end

probes.QE14 = function()
    local module = body_modules()
    local grown = fixture.grow_body({label = "qa-receipt-body-split"})
    local append = packet.append_qa_event
    packet.append_qa_event = function(instance, event)
        if event.type == "qa_check" or event.type == "qa_execution_failure" then
            return nil, "fixture body append denied after receipt"
        end
        return append(instance, event)
    end
    local first_ok, first_err = pcall(
        module.execute, grown.instance, grown.body_services)
    packet.append_qa_event = append
    local second_ok, second_err = pcall(
        module.execute, grown.instance, grown.body_services)
    H.assert_false(first_ok, "receipt/body split is loud")
    H.assert_false(second_ok, "split replay remains loud")
    H.assert_contains(first_err, "append", "first split names body boundary")
    H.assert_contains(second_err, "receipt", "replay names private receipt")
    H.assert_eq(grown.qa_adapter_state.runs, 1, "split never reruns candidate")
end

probes.QE15 = function()
    body_modules()
    H.assert_true(type(fixture.run_qa_execution_tick) == "function",
        "QE15 requires a grown runner-owned QA tick")
    local observed = assert(fixture.run_qa_execution_tick({label = "qa-cost-once"}))
    H.assert_eq(observed.qa_runs, 1, "one native run")
    H.assert_eq(observed.test_run_delta, 1, "runner debits one test run")
    H.assert_eq(observed.tool_call_delta, 1, "runner debits one tool call")
end

probes.QE16 = function()
    local module = body_modules()
    local grown = fixture.grow_body({label = "qa-pre-dispatch-denial"})
    local before = fixture.snapshot(grown.instance)
    local environments = require("runtime.qa_environment")
    assert(environments.quarantine(
        grown.qa_environment_registry,
        grown.qa_environment.environment_id,
        "fixture unavailable before begin"
    ))
    local outcome = module.execute(grown.instance, grown.body_services)
    H.assert_nil(outcome, "pre-dispatch denial has no candidate outcome")
    H.assert_eq(grown.qa_adapter_state.runs, 0, "provider was never entered")
    H.assert_eq(before.budget.test_runs, fixture.snapshot(grown.instance).budget.test_runs,
        "no candidate process cost")
end

probes.QE17 = function()
    local module = body_modules()
    local owner = fixture.grow_body({label = "qa-coordinate-owner"})
    local foreign = fixture.grow_body({label = "qa-coordinate-foreign"})
    owner.body_services.qa_capabilities = foreign.qa_registry
    local outcome = module.execute(owner.instance, owner.body_services)
    H.assert_nil(outcome, "foreign private registry cannot advance owner")
    H.assert_eq(owner.qa_adapter_state.runs, 0, "owner provider not entered")
    H.assert_eq(foreign.qa_adapter_state.runs, 0, "foreign provider not entered")
end

probes.QE18 = function()
    local module, _, registry_module = body_modules()
    local grown = fixture.grow_body({label = "qa-detached-mutation"})
    local outcome = assert(module.execute(grown.instance, grown.body_services))
    local request = one_event(grown.instance, "qa_check_request").payload
    local receipt = assert(registry_module.find_receipt(
        grown.qa_registry, request.request_id))
    local receipt_id = receipt.execution_receipt_id
    outcome.execution_receipt_id = "mutated"
    receipt.execution_receipt_id = "mutated"
    local replay = assert(module.execute(grown.instance, grown.body_services))
    H.assert_eq(replay.execution_receipt_id, receipt_id,
        "detached mutation changes no private receipt")
    H.assert_eq(grown.qa_adapter_state.runs, 1)
end

probes.QE19 = function()
    local module = body_modules()
    local owner = fixture.grow_body({label = "qa-root-owner"})
    local foreign = fixture.grow_body({label = "qa-root-foreign"})
    owner.body_services.qa_capabilities = foreign.qa_registry
    local before = assert(repository_capabilities.root_authority(
        owner.repository_registry, {root_authority_id = owner.seal.root_authority_id}))
    H.assert_nil(module.execute(owner.instance, owner.body_services),
        "foreign lineage/root alias is denied")
    local after = assert(repository_capabilities.root_authority(
        owner.repository_registry, {root_authority_id = owner.seal.root_authority_id}))
    H.assert_eq(before.state, after.state, "owner sealed root is unchanged")
end

probes.QE20 = function()
    body_modules()
    H.assert_true(type(fixture.run_repeated_body_campaign) == "function",
        "QE20 requires the grown body residue campaign")
    local campaign = assert(fixture.run_repeated_body_campaign())
    H.assert_eq(campaign.declared, campaign.executed, "all lives executed")
    H.assert_eq(campaign.matched, campaign.executed, "all residue rows matched")
    for key, value in pairs(campaign.residue or {}) do
        H.assert_eq(value, 0, "zero host residue: " .. tostring(key))
    end
end

for _, control in ipairs(catalog) do
    local id, description = control[1], control[2]
    assert(type(probes[id]) == "function", "missing QA execution probe " .. id)
    suite:check(id .. " " .. description, probes[id])
end

suite:finish()
print("test_qa_execution ok")
