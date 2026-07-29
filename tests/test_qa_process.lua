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

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end

local request_v1 = copy(request)
request_v1.protocol_version = "qa.native_run_request.v1"

local function stream_v1()
    return {
        protocol_version = "qa.stream_measurement.v1",
        observed_bytes = 0,
        hashed_bytes = 0,
        sha256 = empty_sha,
        limit_bytes = qa_schema.hard_limits().stdout_bytes,
        limit_reached = false,
        eof_observed = true,
        raw_retained = false,
    }
end

local function raw_v1(reason, exit_code)
    local limits = qa_schema.hard_limits()
    return {
        protocol_version = "qa.native_run_result.v1",
        transaction_id = request_v1.transaction_id,
        witness_id = request_v1.witness_id,
        profile_id = request_v1.profile_id,
        environment_id = request_v1.environment_id,
        phase_ordinal = 2,
        disposition = "contained_candidate",
        start_attested = true,
        source_staging_policy = "qa.source_staging.detached_mount.v0",
        source_staging_complete = true,
        reason = reason,
        termination = {
            kind = 1,
            exit_code = exit_code,
            signal = 4294967295,
        },
        cause = {
            protocol_version = "qa.first_cause.v1",
            kind = reason,
            monotonic_sequence = 1,
            observed_value = exit_code,
        },
        finality = {
            source_staging_complete = true,
            candidate_started = true,
            candidate_terminal_observed = true,
            process_tree_reaped = true,
            stdout_eof_observed = true,
            stderr_eof_observed = true,
            scratch_observation_complete = true,
            namespace_cleanup_complete = true,
        },
        stdout = stream_v1(),
        stderr = stream_v1(),
        resources = {
            protocol_version = "qa.resource_measurement.v1",
            wall_time_ms = 2,
            cpu_user_ms = 1,
            cpu_system_ms = 1,
            max_rss_bytes = 4096,
            address_space_limit_bytes = limits.address_space_bytes,
            runtime_heap_peak_bytes = 1024,
            runtime_heap_limit_bytes = qa_schema.runtime_heap_limit_bytes,
            runtime_heap_denied = false,
            max_processes = limits.max_processes,
            max_open_files = limits.max_open_files,
            max_file_bytes = limits.max_file_bytes,
        },
        scratch = {
            protocol_version = "qa.scratch_measurement.v1",
            stored_regular_bytes = 0,
            stored_entries = 0,
            limit_bytes = limits.scratch_bytes,
            limit_entries = limits.scratch_entries,
            byte_capacity_exhausted = false,
            entry_capacity_exhausted = false,
            inventory_complete = true,
        },
        event_truth_status = "runtime_confirmed",
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

suite:check("PO09 RUN v1 request is closed and never coerces v0", function()
    local normalized = assert(qa_process.normalize_request_v1(request_v1))
    H.assert_eq(normalized.protocol_version, "qa.native_run_request.v1")
    H.assert_nil(qa_process.normalize_request_v1(request))
    local widened = copy(request_v1)
    widened.command = "lua tests/run.lua"
    H.assert_nil(qa_process.normalize_request_v1(widened))
end)

suite:check("PO10 complete RUN v1 result normalizes without private start token", function()
    local result = qa_process.normalize_result_v1(
        raw_v1("expected_exit", 0), request_v1)
    H.assert_eq(result.protocol_version, "qa.provider_process_observation.v1")
    H.assert_eq(result.outcome, "expected_exit")
    H.assert_true(result.finality.namespace_cleanup_complete)
    H.assert_eq(result.cost.qa_executions, 1)
    H.assert_nil(result.candidate_process_token)
    H.assert_nil(qa_process.normalize_started_v1)
end)

suite:check("PO11 incomplete or token-bearing RUN v1 result is loud", function()
    local changed = raw_v1("expected_exit", 0)
    changed.finality.stderr_eof_observed = false
    local ok, err = pcall(qa_process.normalize_result_v1, changed, request_v1)
    H.assert_false(ok)
    H.assert_contains(err, "lacks finality")

    changed = raw_v1("expected_exit", 0)
    changed.candidate_process_token = "sha256:" .. string.rep("d", 64)
    ok, err = pcall(qa_process.normalize_result_v1, changed, request_v1)
    H.assert_false(ok)
    H.assert_contains(err, "unknown key")
end)

suite:check("PO12 RUN v1 reason requires its physical witness", function()
    local changed = raw_v1("memory_limit", 70)
    local ok, err = pcall(qa_process.normalize_result_v1, changed, request_v1)
    H.assert_false(ok)
    H.assert_contains(err, "allocator denial")

    changed.resources.runtime_heap_denied = true
    local result = qa_process.normalize_result_v1(changed, request_v1)
    H.assert_eq(result.outcome, "memory_limit")

    changed = raw_v1("scratch_limit", 70)
    ok, err = pcall(qa_process.normalize_result_v1, changed, request_v1)
    H.assert_false(ok)
    H.assert_contains(err, "reserved")
end)

suite:check("PO13 RUN v1 infrastructure error carries tri-state not verdict", function()
    local raw_error = {
        protocol_version = "qa.native_run_error.v1",
        transaction_id = request_v1.transaction_id,
        witness_id = request_v1.witness_id,
        profile_id = request_v1.profile_id,
        environment_id = request_v1.environment_id,
        phase_ordinal = 1,
        class = "unavailable",
        code = "supervisor_unavailable",
        stage = "preflight",
        candidate_start_state = "not_started",
        cleanup_state = "complete",
        launcher_reaped = "complete",
        result_eof = "complete",
        event_truth_status = "runtime_confirmed",
    }
    local result = qa_process.normalize_error_v1(raw_error, request_v1)
    H.assert_eq(result.protocol_version, "qa.provider_process_error.v1")
    H.assert_nil(result.outcome)
    H.assert_nil(result.measured_cost)

    raw_error.phase_ordinal = 2
    local ok, err = pcall(qa_process.normalize_error_v1, raw_error, request_v1)
    H.assert_false(ok)
    H.assert_contains(err, "contradicts start state")
end)

suite:check("PO14 RUN v1 error topology is closed and reusable only pre-start", function()
    local rows = {
        {"unavailable", "supervisor_unavailable", "preflight", 1,
            "not_started", "complete", "complete", "complete",
            "clean_prestart"},
        {"unavailable", "supervisor_unavailable", "launch", 1,
            "not_started", "complete", "complete", "complete",
            "clean_prestart"},
        {"world", "source_staging_failed", "source_staging", 1,
            "not_started", "complete", "complete", "complete",
            "clean_prestart"},
        {"unavailable", "supervisor_crashed", "supervision", 1,
            "not_started", "unknown", "complete", "complete",
            "non_reusable"},
        {"unavailable", "supervisor_crashed", "supervision", 2,
            "started", "unknown", "complete", "complete", "non_reusable"},
        {"ambiguous", "result_pipe_lost", "supervision", 1,
            "not_started", "unknown", "complete", "unknown",
            "non_reusable"},
        {"ambiguous", "result_pipe_lost", "supervision", 2,
            "started", "unknown", "complete", "unknown", "non_reusable"},
        {"ambiguous", "terminal_frame_missing", "postflight", 1,
            "not_started", "unknown", "complete", "complete",
            "non_reusable"},
        {"ambiguous", "terminal_frame_missing", "postflight", 2,
            "started", "unknown", "complete", "complete", "non_reusable"},
        {"ambiguous", "reap_ambiguous", "cleanup", 2,
            "started", "unknown", "unknown", "complete", "non_reusable"},
        {"ambiguous", "reap_ambiguous", "cleanup", 1,
            "unknown", "unknown", "unknown", "unknown", "non_reusable"},
        {"ambiguous", "output_observation_incomplete", "postflight", 2,
            "started", "incomplete", "complete", "complete",
            "non_reusable"},
        {"ambiguous", "scratch_observation_incomplete", "postflight", 2,
            "started", "incomplete", "complete", "complete",
            "non_reusable"},
        {"ambiguous", "namespace_cleanup_incomplete", "cleanup", 2,
            "started", "incomplete", "complete", "complete",
            "non_reusable"},
    }
    for _, row in ipairs(rows) do
        local raw_error = {
            protocol_version = "qa.native_run_error.v1",
            transaction_id = request_v1.transaction_id,
            witness_id = request_v1.witness_id,
            profile_id = request_v1.profile_id,
            environment_id = request_v1.environment_id,
            class = row[1],
            code = row[2],
            stage = row[3],
            phase_ordinal = row[4],
            candidate_start_state = row[5],
            cleanup_state = row[6],
            launcher_reaped = row[7],
            result_eof = row[8],
            event_truth_status = "runtime_confirmed",
        }
        local normalized = qa_process.normalize_error_v1(raw_error, request_v1)
        local reuse, reuse_err = qa_process.error_reuse_class_v1(normalized)
        H.assert_eq(reuse, row[9], row[2] .. " reuse class")
        H.assert_nil(reuse_err, row[2] .. " topology error")
    end
end)

suite:check("PO15 impossible RUN v1 causal tuples are loud", function()
    local probes = {
        {"ambiguous", "reap_ambiguous", "preflight", 1,
            "not_started", "complete", "complete", "complete"},
        {"ambiguous", "terminal_frame_missing", "preflight", 2,
            "started", "unknown", "complete", "complete"},
        {"ambiguous", "output_observation_incomplete", "postflight", 2,
            "started", "complete", "complete", "complete"},
        {"ambiguous", "scratch_observation_incomplete", "postflight", 1,
            "not_started", "incomplete", "complete", "complete"},
        {"ambiguous", "namespace_cleanup_incomplete", "postflight", 2,
            "started", "incomplete", "complete", "complete"},
        {"unavailable", "supervisor_unavailable", "launch", 2,
            "started", "unknown", "complete", "complete"},
    }
    for _, row in ipairs(probes) do
        local raw_error = {
            protocol_version = "qa.native_run_error.v1",
            transaction_id = request_v1.transaction_id,
            witness_id = request_v1.witness_id,
            profile_id = request_v1.profile_id,
            environment_id = request_v1.environment_id,
            class = row[1],
            code = row[2],
            stage = row[3],
            phase_ordinal = row[4],
            candidate_start_state = row[5],
            cleanup_state = row[6],
            launcher_reaped = row[7],
            result_eof = row[8],
            event_truth_status = "runtime_confirmed",
        }
        local ok, err = pcall(
            qa_process.normalize_error_v1, raw_error, request_v1)
        H.assert_false(ok, row[2] .. " laundering probe")
        H.assert_contains(err, "causal topology", row[2] .. " rejection")
    end
end)

suite:finish()
print("test_qa_process ok")
