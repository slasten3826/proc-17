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

local function transaction_surface(id)
    need(requests, requests_err, "runtime.qa_request", {
        "prepare", "verify", "find",
    })
    need(capabilities, capabilities_err, "runtime.qa_capability", {
        "new", "mint", "begin", "commit", "quarantine", "find_receipt",
    })
    need(execution, execution_err, "runtime.qa_execution", {
        "inspect", "execute",
    })
    need(evidence, evidence_err, "runtime.qa_evidence", {
        "record_request", "commit_execution", "current",
    })
    H.assert_true(type(repository_capabilities.reserve_qa_source) == "function",
        "repository source lease API required")
    H.assert_true(type(repository_capabilities.with_qa_source) == "function",
        "repository source consumer API required")
    H.assert_true(type(repository_capabilities.finish_qa_source) == "function",
        "repository source finish API required")
    error(id .. " exact grown transaction witness is still red", 2)
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

for _, id in ipairs({
    "QE08", "QE09", "QE10", "QE11", "QE12", "QE13", "QE14",
    "QE15", "QE16", "QE17", "QE18", "QE19", "QE20",
}) do
    probes[id] = function()
        transaction_surface(id)
    end
end

for _, control in ipairs(catalog) do
    local id, description = control[1], control[2]
    assert(type(probes[id]) == "function", "missing QA execution probe " .. id)
    suite:check(id .. " " .. description, probes[id])
end

suite:finish()
print("test_qa_execution ok")
