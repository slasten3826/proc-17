package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local digest = require("core.digest")
local fixtures = require("tests.support.qa_hostile_fixtures")
local support = require("tests.support.qa_provider_witness")
local witness = require("runtime.qa_provider_witness")

local expected = {
    ["candidate-clean-exit"] = {reason = "expected_exit", outcome = "accepted"},
    ["candidate-nonzero-exit"] = {reason = "unexpected_exit", outcome = "rejected"},
    ["candidate-lua-error"] = {reason = "unexpected_exit", outcome = "rejected"},
    ["candidate-cpu-loop"] = {reason = "cpu_limit", outcome = "rejected"},
    ["candidate-wall-loop"] = {reason = "cpu_limit", outcome = "rejected"},
    ["candidate-allocator-exhaustion"] = {
        reason = "memory_limit", outcome = "rejected", evidence = "memory",
    },
    ["candidate-stdout-flood"] = {
        reason = "output_limit", outcome = "rejected", evidence = "stdout",
    },
    ["candidate-stderr-flood"] = {
        reason = "output_limit", outcome = "rejected", evidence = "stderr",
    },
    ["candidate-scratch-exhaustion"] = {
        reason = "unexpected_exit", outcome = "rejected", evidence = "scratch",
    },
    ["candidate-source-mutation"] = {reason = "expected_exit", outcome = "accepted"},
    ["candidate-host-path-probe"] = {reason = "expected_exit", outcome = "accepted"},
    ["candidate-socket-attempt"] = {reason = "expected_exit", outcome = "accepted"},
    ["candidate-fork-attempt"] = {reason = "expected_exit", outcome = "accepted"},
    ["candidate-exec-attempt"] = {reason = "expected_exit", outcome = "accepted"},
    ["candidate-native-module-attempt"] = {reason = "expected_exit", outcome = "accepted"},
    ["candidate-fd-escape"] = {reason = "expected_exit", outcome = "accepted"},
    ["candidate-sigsys"] = {reason = "expected_exit", outcome = "accepted"},
}

local report_keys = {
    protocol_version = true,
    operation = true,
    transaction_id = true,
    witness_id = true,
    profile_id = true,
    environment_id = true,
    outcome = true,
    reason = true,
    termination = true,
    cause = true,
    finality = true,
    source = true,
    stdout = true,
    stderr = true,
    resources = true,
    scratch = true,
    cost = true,
    event_truth_status = true,
}

local source_keys = {
    pre_inventory_id = true,
    post_inventory_id = true,
    stable = true,
    disposition = true,
}

local finality_keys = {
    "source_staging_complete",
    "candidate_started",
    "candidate_terminal_observed",
    "process_tree_reaped",
    "stdout_eof_observed",
    "stderr_eof_observed",
    "scratch_observation_complete",
    "namespace_cleanup_complete",
}

local forbidden_authority_keys = {
    candidate_process_token = true,
    content = true,
    fd = true,
    path = true,
    pre_inventory = true,
    post_inventory = true,
    repository_handle = true,
}

local function exact_keys(value, keys, label)
    H.assert_true(type(value) == "table" and getmetatable(value) == nil,
        label .. " must be a plain table")
    for key in pairs(value) do
        H.assert_true(keys[key] == true,
            label .. " contains unknown key: " .. tostring(key))
    end
    for key in pairs(keys) do
        H.assert_true(value[key] ~= nil,
            label .. " is missing key: " .. key)
    end
end

local function no_authority_leak(value, seen)
    if type(value) ~= "table" then return end
    seen = seen or {}
    H.assert_false(seen[value] == true, "report contains a table cycle")
    seen[value] = true
    for key, child in pairs(value) do
        H.assert_false(forbidden_authority_keys[key] == true,
            "report leaked authority key: " .. tostring(key))
        no_authority_leak(child, seen)
    end
    seen[value] = nil
end

local function validate_fixture(item, bytes, ids)
    H.assert_eq(item.class, "candidate", "QN17 class")
    H.assert_true(expected[item.id] ~= nil,
        "unexpected QN17 fixture id: " .. tostring(item.id))
    H.assert_false(ids[item.id] == true,
        "duplicate QN17 fixture id: " .. item.id)
    ids[item.id] = true
    H.assert_true(#bytes <= fixtures.max_bytes, "fixture byte ceiling")
    H.assert_eq(bytes:sub(1, #fixtures.marker), fixtures.marker,
        "fixture inert marker")
    H.assert_contains(bytes, "-- fixture-id: " .. item.id,
        "embedded fixture identity")
end

local function validate_report(item, matrix, bytes, plan, report)
    exact_keys(report, report_keys, item.id .. " report")
    exact_keys(report.source, source_keys, item.id .. " source")
    H.assert_eq(report.protocol_version, "qa.provider_witness_report.v1")
    H.assert_eq(report.operation, "run_lua54_test_suite")
    H.assert_eq(report.transaction_id, plan.witness.transaction_id)
    H.assert_eq(report.witness_id, plan.witness.witness_id)
    H.assert_eq(report.profile_id, plan.witness.profile_id)
    H.assert_eq(report.environment_id, plan.witness.environment_id)
    H.assert_eq(report.event_truth_status, "runtime_confirmed")
    H.assert_eq(report.reason, matrix.reason, item.id .. " reason")
    H.assert_eq(report.outcome, matrix.outcome, item.id .. " outcome")
    H.assert_eq(report.cause.kind, matrix.reason, item.id .. " first cause")
    H.assert_true(report.cause.monotonic_sequence >= 1,
        item.id .. " cause sequence")

    for _, key in ipairs(finality_keys) do
        H.assert_true(report.finality[key] == true,
            item.id .. " finality: " .. key)
    end
    H.assert_true(report.source.stable, item.id .. " source stability")
    H.assert_eq(report.source.disposition, "consumed")
    H.assert_eq(report.source.pre_inventory_id, plan.witness.inventory_id)
    H.assert_eq(report.source.post_inventory_id, plan.witness.inventory_id)
    H.assert_eq(plan.witness.entrypoint.bytes, #bytes)
    H.assert_eq(plan.witness.entrypoint.sha256,
        "sha256:" .. assert(digest.sha256(bytes)))

    H.assert_eq(report.stdout.raw_retained, false,
        "stdout raw bytes retained")
    H.assert_eq(report.stderr.raw_retained, false,
        "stderr raw bytes retained")
    H.assert_eq(report.stdout.protocol_version, "qa.stream_measurement.v1")
    H.assert_eq(report.stderr.protocol_version, "qa.stream_measurement.v1")
    H.assert_eq(report.resources.protocol_version,
        "qa.resource_measurement.v1")
    H.assert_eq(report.scratch.protocol_version,
        "qa.scratch_measurement.v1")
    H.assert_eq(report.cost.protocol_version, "qa.cost.v1")
    H.assert_eq(report.cost.tool_calls, 1)
    H.assert_eq(report.cost.qa_executions, 1)
    no_authority_leak(report)

    if matrix.evidence == "memory" then
        H.assert_true(report.resources.runtime_heap_denied,
            "allocator denial owns memory_limit")
    elseif matrix.evidence == "stdout" then
        H.assert_true(report.stdout.limit_reached,
            "stdout crossing owns output_limit")
        H.assert_eq(report.stderr.limit_reached, false,
            "stderr did not own stdout fixture cause")
    elseif matrix.evidence == "stderr" then
        H.assert_true(report.stderr.limit_reached,
            "stderr crossing owns output_limit")
        H.assert_eq(report.stdout.limit_reached, false,
            "stdout did not own stderr fixture cause")
    elseif matrix.evidence == "scratch" then
        H.assert_true(report.scratch.inventory_complete,
            "scratch failure retains complete final observation")
        H.assert_true(report.scratch.stored_regular_bytes
                <= report.scratch.limit_bytes,
            "scratch bytes remain bounded")
        H.assert_true(report.scratch.stored_entries
                <= report.scratch.limit_entries,
            "scratch entries remain bounded")
    end
end

local declared = 0
for _ in pairs(expected) do declared = declared + 1 end
H.assert_eq(declared, 17, "closed QN17 expectation count")

local ids = {}
local executed = 0
local matched = 0
local source_drifts = 0
local cleanup_ambiguities = 0

for _, item in ipairs(fixtures.items) do
    if item.class == "candidate" then
        local bytes = assert(fixtures.read(item))
        validate_fixture(item, bytes, ids)
        assert(support.with_candidate(bytes, function(grown)
            local plan = assert(witness.prepare(grown.instance, grown.services))
            executed = executed + 1
            local report, witness_err = witness.execute(
                grown.instance, grown.services, plan)
            if not report then
                if witness_err and witness_err.code == "source_drift" then
                    source_drifts = source_drifts + 1
                else
                    cleanup_ambiguities = cleanup_ambiguities + 1
                end
                error(item.id .. " produced provider error: "
                    .. tostring(witness_err and witness_err.code), 0)
            end
            validate_report(item, expected[item.id], bytes, plan, report)
            matched = matched + 1
            return true
        end))
    end
end

for id in pairs(expected) do
    H.assert_true(ids[id] == true, "missing QN17 fixture: " .. id)
end
H.assert_eq(executed, 17, "QN17 executed count")
H.assert_eq(matched, 17, "QN17 matched count")
H.assert_eq(source_drifts, 0, "QN17 source drift count")
H.assert_eq(cleanup_ambiguities, 0, "QN17 cleanup ambiguity count")

print(string.format(
    "proc17 QN17 hostile campaign ok: declared=%d executed=%d matched=%d source_drifts=%d cleanup_ambiguities=%d",
    declared, executed, matched, source_drifts, cleanup_ambiguities))
