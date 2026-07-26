package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local catalog = require("tests.support.qa_control_catalog").verdict
local fixture = require("tests.support.qa_hand")
local packet = require("core.packet")
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

local function outcome_surface(id)
    need(evidence, evidence_err, "runtime.qa_evidence", {
        "record_request", "commit_execution", "current",
        "verify_request", "verify_check", "verify_failure",
    })
    need(verdicts, verdicts_err, "runtime.qa_verdict", {
        "prepare", "commit", "current", "verify",
    })
    H.assert_true(type(packet.append_qa_event) == "function",
        "dedicated Packet QA append gate required")
    error(id .. " exact grown body/verdict witness is still red", 2)
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

for _, id in ipairs({
    "QV02", "QV03", "QV04", "QV06", "QV07", "QV09", "QV10",
    "QV11", "QV12", "QV13", "QV14", "QV15", "QV18", "QV19",
    "QV20", "QV21", "QV22", "QV23",
}) do
    probes[id] = function()
        outcome_surface(id)
    end
end

for _, control in ipairs(catalog) do
    local id, description = control[1], control[2]
    assert(type(probes[id]) == "function", "missing QA verdict probe " .. id)
    suite:check(id .. " " .. description, probes[id])
end

suite:finish()
print("test_qa_check_verdict ok")
