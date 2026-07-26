package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local qa_process = require("runtime.qa_process")
local qa_schema = require("core.qa_schema")

local suite = H.new("qa-process")
local empty_sha =
    "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

local request = {
    protocol_version = "qa.native_run_request.v0",
    operation = "run_lua54_test_suite",
    transaction_id = "qa-provider-transaction:" .. string.rep("a", 64),
    witness_id = "qa-provider-witness:" .. string.rep("b", 64),
    profile_id = "qa.profile.lua54_test_suite.v0",
    environment_id = "qa-environment:" .. string.rep("c", 64),
    entrypoint_relative_path = "tests/run.lua",
    expected_exit_code = 0,
    resource_limits = qa_schema.hard_limits(),
}

local function raw(reason, exit_code)
    return {
        protocol_version = "qa.native_run_result.v0",
        disposition_code = 1,
        reason_code = reason,
        error_class_code = 0,
        error_code = 0,
        error_stage_code = 0,
        candidate_started = true,
        cleanup_complete = true,
        termination_kind_code = 1,
        exit_code = exit_code,
        signal = 4294967295,
        wall_time_ms = 1,
        user_cpu_ms = 0,
        system_cpu_ms = 1,
        max_rss_bytes = 4096,
        stdout_bytes = 0,
        stdout_limit_reached = false,
        stdout_sha256 = empty_sha,
        stderr_bytes = 0,
        stderr_limit_reached = false,
        stderr_sha256 = empty_sha,
        scratch_bytes = 0,
        scratch_entries = 0,
        scratch_bytes_limit_reached = false,
        scratch_entries_limit_reached = false,
        source_staging_policy = "qa.source_staging.detached_mount.v0",
        source_staging_complete = true,
        transaction_id = request.transaction_id,
        witness_id = request.witness_id,
        profile_id = request.profile_id,
        environment_id = request.environment_id,
    }
end

suite:check("PO01 clean RUN normalizes to expected exit", function()
    local result = qa_process.normalize_result(raw(1, 0), request)
    H.assert_eq(result.protocol_version,
        "qa.provider_process_observation.v0")
    H.assert_eq(result.outcome, "expected_exit")
    H.assert_eq(result.termination.exit_code, 0)
    H.assert_eq(result.cost.qa_executions, 1)
end)

suite:check("PO02 Lua error normalizes to unexpected exit", function()
    local result = qa_process.normalize_result(raw(2, 70), request)
    H.assert_eq(result.outcome, "unexpected_exit")
    H.assert_eq(result.termination.exit_code, 70)
end)

suite:check("PO03 clean staging failure remains process error", function()
    local input = raw(1, 0)
    input.disposition_code = 2
    input.reason_code = 0
    input.error_class_code = 1
    input.error_code = 1
    input.error_stage_code = 2
    input.candidate_started = false
    input.source_staging_complete = false
    input.termination_kind_code = 0
    input.exit_code = 4294967295
    local result = qa_process.normalize_result(input, request)
    H.assert_eq(result.protocol_version, "qa.provider_process_error.v0")
    H.assert_eq(result.class, "world")
    H.assert_eq(result.code, "source_staging_failed")
    H.assert_false(result.candidate_started)
    H.assert_true(result.cleanup_complete)
end)

suite:check("PO04 impossible native result is loud", function()
    local changed = raw(1, 70)
    local ok, err = pcall(qa_process.normalize_result, changed, request)
    H.assert_false(ok)
    H.assert_contains(err, "expected exit contradicts termination")

    changed = raw(1, 0)
    changed.foreign = true
    ok, err = pcall(qa_process.normalize_result, changed, request)
    H.assert_false(ok)
    H.assert_contains(err, "unknown key")

    changed = raw(1, 0)
    changed.stdout_sha256 = "sha256:" .. string.rep("0", 64)
    ok, err = pcall(qa_process.normalize_result, changed, request)
    H.assert_false(ok)
    H.assert_contains(err, "empty stream digest mismatch")
end)

suite:check("PO05 observation carries no source claim", function()
    local result = qa_process.normalize_result(raw(1, 0), request)
    H.assert_nil(result.pre_inventory_id)
    H.assert_nil(result.post_inventory_id)
    H.assert_nil(result.source_stable)
    H.assert_nil(result.closure_request_id)
end)

suite:check("PO06 raw staging identity cannot cross adapter", function()
    local result = qa_process.normalize_result(raw(1, 0), request)
    H.assert_nil(result.root_device)
    H.assert_nil(result.root_inode)
    H.assert_nil(result.root_mount_id)
end)

suite:check("PO07 cost is exact native arithmetic", function()
    local input = raw(1, 0)
    input.wall_time_ms = 7
    input.user_cpu_ms = 2
    input.system_cpu_ms = 3
    local result = qa_process.normalize_result(input, request)
    H.assert_eq(result.cost.wall_time_ms, 7)
    H.assert_eq(result.cost.cpu_time_ms, 5)
    H.assert_eq(result.cost.stdout_observed_bytes, 0)
end)

suite:check("PO08 returned observation is detached", function()
    local input = raw(1, 0)
    local result = qa_process.normalize_result(input, request)
    result.stdout.sha256 = "changed"
    H.assert_eq(input.stdout_sha256, empty_sha)
end)

suite:finish()
print("test_qa_process ok")
