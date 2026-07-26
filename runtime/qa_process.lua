local qa_schema = require("core.qa_schema")

local qa_process = {
    protocol_version = "qa.process_normalizer.v0",
}

local EMPTY_SHA256 =
    "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

local request_keys = {
    "protocol_version", "operation", "transaction_id", "witness_id",
    "profile_id", "environment_id", "entrypoint_relative_path",
    "expected_exit_code", "resource_limits",
}

local result_keys = {
    "protocol_version", "disposition_code", "reason_code",
    "error_class_code", "error_code", "error_stage_code",
    "candidate_started", "cleanup_complete", "termination_kind_code",
    "exit_code", "signal", "wall_time_ms", "user_cpu_ms",
    "system_cpu_ms", "max_rss_bytes", "stdout_bytes", "stdout_limit_reached",
    "stdout_sha256", "stderr_bytes", "stderr_limit_reached",
    "stderr_sha256", "scratch_bytes", "scratch_entries",
    "scratch_bytes_limit_reached", "scratch_entries_limit_reached",
    "source_staging_policy", "source_staging_complete", "transaction_id",
    "witness_id", "profile_id", "environment_id",
}

local native_error_keys = {
    "protocol_version", "code", "stage", "diagnostic",
    "event_truth_status",
}

local reasons = {
    [1] = "expected_exit",
    [2] = "unexpected_exit",
    [3] = "signal",
    [4] = "wall_timeout",
    [5] = "cpu_limit",
    [6] = "memory_limit",
    [7] = "output_limit",
    [8] = "scratch_limit",
    [9] = "sandbox_policy_violation",
}

local termination_kinds = {
    [1] = "exit",
    [2] = "signal",
    [3] = "supervisor_kill",
}

local process_error_classes = {
    [1] = "world",
    [2] = "unavailable",
    [3] = "ambiguous",
}

local process_error_codes = {
    [1] = "source_staging_failed",
}

local process_error_stages = {
    [1] = "preflight",
    [2] = "source_staging",
    [3] = "namespace",
    [4] = "launch",
    [5] = "supervision",
    [6] = "postflight",
    [7] = "cleanup",
}

local function copy_value(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

local function exact_keys(value, names, label)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, label .. " must be a plain table"
    end
    local allowed = {}
    for _, name in ipairs(names) do
        allowed[name] = true
    end
    for key in pairs(value) do
        if not allowed[key] then
            return nil, label .. " contains unknown key: " .. tostring(key)
        end
    end
    for _, name in ipairs(names) do
        if value[name] == nil then
            return nil, label .. " is missing key: " .. name
        end
    end
    return true
end

local function tagged_digest(value, prefix)
    return type(value) == "string"
        and #value == #prefix + 64
        and value:sub(1, #prefix) == prefix
        and value:sub(#prefix + 1):match("^[0-9a-f]+$") ~= nil
end

local function non_negative_integer(value)
    return type(value) == "number" and value >= 0
        and value == math.floor(value)
end

local function boolean(value)
    return type(value) == "boolean"
end

local function fail(message)
    error("QA process contract failure: " .. tostring(message), 0)
end

function qa_process.normalize_request(value)
    local keys_ok, keys_err = exact_keys(value, request_keys,
        "native RUN request")
    if not keys_ok then
        return nil, keys_err
    end
    local limits, limits_err = qa_schema.normalize_limits(value.resource_limits)
    if value.protocol_version ~= "qa.native_run_request.v0"
        or value.operation ~= "run_lua54_test_suite"
        or not tagged_digest(value.transaction_id, "qa-provider-transaction:")
        or not tagged_digest(value.witness_id, "qa-provider-witness:")
        or value.profile_id ~= qa_schema.profile_id
        or not tagged_digest(value.environment_id, "qa-environment:")
        or value.entrypoint_relative_path ~= "tests/run.lua"
        or value.expected_exit_code ~= 0 then
        return nil, "native RUN request identity mismatch"
    end
    if not limits then
        return nil, limits_err
    end
    if not qa_schema.same(limits, qa_schema.hard_limits()) then
        return nil, "native RUN request limits mismatch"
    end
    local normalized = copy_value(value)
    normalized.resource_limits = limits
    return normalized
end

local function stream_measurement(bytes, sha256, limit, reached, label)
    if not non_negative_integer(bytes) or not tagged_digest(sha256, "sha256:")
        or not boolean(reached) then
        fail(label .. " measurement is malformed")
    end
    if bytes == 0 and sha256 ~= EMPTY_SHA256 then
        fail(label .. " empty stream digest mismatch")
    end
    if reached and bytes <= limit then
        fail(label .. " limit flag contradicts byte count")
    end
    return {
        protocol_version = "qa.stream_measurement.v0",
        observed_bytes = bytes,
        hashed_bytes = math.min(bytes, limit),
        sha256 = sha256,
        limit_bytes = limit,
        limit_reached = reached,
    }
end

local function cost(raw)
    return {
        protocol_version = "qa.cost.v0",
        tool_calls = 1,
        qa_executions = raw.candidate_started and 1 or 0,
        wall_time_ms = raw.wall_time_ms,
        cpu_time_ms = raw.user_cpu_ms + raw.system_cpu_ms,
        scratch_written_bytes = raw.scratch_bytes,
        stdout_observed_bytes = raw.stdout_bytes,
        stderr_observed_bytes = raw.stderr_bytes,
    }
end

local function validate_measurements(raw, limits)
    for _, key in ipairs({
        "wall_time_ms", "user_cpu_ms", "system_cpu_ms", "max_rss_bytes", "stdout_bytes",
        "stderr_bytes", "scratch_bytes", "scratch_entries",
    }) do
        if not non_negative_integer(raw[key]) then
            fail("native RUN result has invalid measurement: " .. key)
        end
    end
    for _, key in ipairs({
        "candidate_started", "cleanup_complete", "stdout_limit_reached",
        "stderr_limit_reached", "scratch_bytes_limit_reached",
        "scratch_entries_limit_reached", "source_staging_complete",
    }) do
        if not boolean(raw[key]) then
            fail("native RUN result has invalid boolean: " .. key)
        end
    end
    local stdout = stream_measurement(raw.stdout_bytes, raw.stdout_sha256,
        limits.stdout_bytes, raw.stdout_limit_reached, "stdout")
    local stderr = stream_measurement(raw.stderr_bytes, raw.stderr_sha256,
        limits.stderr_bytes, raw.stderr_limit_reached, "stderr")
    local scratch_limit = raw.scratch_bytes_limit_reached
        or raw.scratch_entries_limit_reached
    if raw.scratch_bytes_limit_reached and raw.scratch_bytes <= limits.scratch_bytes then
        fail("scratch byte limit flag contradicts measurement")
    end
    if raw.scratch_entries_limit_reached
        and raw.scratch_entries <= limits.scratch_entries then
        fail("scratch entry limit flag contradicts measurement")
    end
    return stdout, stderr, {
        protocol_version = "qa.resource_measurement.v0",
        wall_time_ms = raw.wall_time_ms,
        cpu_user_ms = raw.user_cpu_ms,
        cpu_system_ms = raw.system_cpu_ms,
        max_rss_bytes = raw.max_rss_bytes,
        address_space_limit_bytes = limits.address_space_bytes,
        max_open_files = limits.max_open_files,
        max_file_bytes = limits.max_file_bytes,
        max_processes = limits.max_processes,
    }, {
        protocol_version = "qa.scratch_measurement.v0",
        observed_entries = raw.scratch_entries,
        observed_regular_bytes = raw.scratch_bytes,
        limit_entries = limits.scratch_entries,
        limit_bytes = limits.scratch_bytes,
        limit_reached = scratch_limit,
    }
end

function qa_process.normalize_result(raw, request)
    local normalized_request, request_err = qa_process.normalize_request(request)
    if not normalized_request then
        fail(request_err)
    end
    local keys_ok, keys_err = exact_keys(raw, result_keys, "native RUN result")
    if not keys_ok then
        fail(keys_err)
    end
    if raw.protocol_version ~= "qa.native_run_result.v0"
        or raw.transaction_id ~= normalized_request.transaction_id
        or raw.witness_id ~= normalized_request.witness_id
        or raw.profile_id ~= normalized_request.profile_id
        or raw.environment_id ~= normalized_request.environment_id
        or raw.source_staging_policy ~= "qa.source_staging.detached_mount.v0" then
        fail("native RUN result identity mismatch")
    end
    if not non_negative_integer(raw.reason_code)
        or not non_negative_integer(raw.termination_kind_code)
        or not non_negative_integer(raw.disposition_code)
        or not non_negative_integer(raw.error_class_code)
        or not non_negative_integer(raw.error_code)
        or not non_negative_integer(raw.error_stage_code)
        or not non_negative_integer(raw.exit_code)
        or not non_negative_integer(raw.signal) then
        fail("native RUN result contains an unknown enum or scalar")
    end
    local stdout, stderr, resources, scratch = validate_measurements(
        raw, normalized_request.resource_limits)
    if raw.disposition_code == 2 then
        local class = process_error_classes[raw.error_class_code]
        local code = process_error_codes[raw.error_code]
        local stage = process_error_stages[raw.error_stage_code]
        if class ~= "world" or code ~= "source_staging_failed"
            or stage ~= "source_staging" or raw.reason_code ~= 0
            or raw.candidate_started or raw.source_staging_complete
            or not raw.cleanup_complete or raw.termination_kind_code ~= 0
            or raw.exit_code ~= 4294967295 or raw.signal ~= 4294967295
            or raw.stdout_bytes ~= 0 or raw.stderr_bytes ~= 0
            or raw.scratch_bytes ~= 0 or raw.scratch_entries ~= 0
            or raw.stdout_limit_reached or raw.stderr_limit_reached
            or raw.scratch_bytes_limit_reached
            or raw.scratch_entries_limit_reached then
            fail("native process-error combination is impossible or unknown")
        end
        return {
            protocol_version = "qa.provider_process_error.v0",
            operation = "run_lua54_test_suite",
            transaction_id = raw.transaction_id,
            witness_id = raw.witness_id,
            profile_id = raw.profile_id,
            environment_id = raw.environment_id,
            class = class,
            code = code,
            stage = stage,
            candidate_started = false,
            source_staging_complete = false,
            cleanup_complete = true,
            cost = cost(raw),
            event_truth_status = "runtime_confirmed",
        }
    end
    if raw.disposition_code ~= 1 then
        fail("native RUN disposition is unknown")
    end
    local reason = reasons[raw.reason_code]
    local termination_kind = termination_kinds[raw.termination_kind_code]
    if not reason or not termination_kind then
        fail("contained native result has unknown reason or termination")
    end
    if raw.error_class_code ~= 0 or raw.error_code ~= 0
        or raw.error_stage_code ~= 0 then
        fail("contained native result carries process-error fields")
    end
    if not raw.candidate_started or not raw.source_staging_complete
        or not raw.cleanup_complete then
        fail("contained candidate lacks staging/start/cleanup evidence")
    end
    if reason == "expected_exit" then
        if termination_kind ~= "exit" or raw.exit_code ~= 0
            or raw.signal ~= 4294967295 then
            fail("expected exit contradicts termination")
        end
    elseif reason == "unexpected_exit" then
        if termination_kind ~= "exit" or raw.exit_code == 0
            or raw.signal ~= 4294967295 then
            fail("unexpected exit contradicts termination")
        end
    elseif termination_kind == "exit" then
        fail("non-exit outcome carries exit termination")
    end
    local output_limit = raw.stdout_limit_reached or raw.stderr_limit_reached
    local scratch_limit = raw.scratch_bytes_limit_reached
        or raw.scratch_entries_limit_reached
    if (reason == "output_limit") ~= output_limit
        or (reason == "scratch_limit") ~= scratch_limit then
        fail("limit reason contradicts measurements")
    end
    return {
        protocol_version = "qa.provider_process_observation.v0",
        operation = "run_lua54_test_suite",
        transaction_id = raw.transaction_id,
        witness_id = raw.witness_id,
        profile_id = raw.profile_id,
        environment_id = raw.environment_id,
        outcome = reason,
        candidate_started = true,
        source_staging_policy = raw.source_staging_policy,
        source_staging_complete = true,
        termination = {
            kind = termination_kind,
            exit_code = termination_kind == "exit" and raw.exit_code or nil,
            signal = termination_kind == "signal" and raw.signal or nil,
        },
        stdout = stdout,
        stderr = stderr,
        resources = resources,
        scratch = scratch,
        cleanup_complete = true,
        cost = cost(raw),
        event_truth_status = "runtime_confirmed",
    }
end

function qa_process.normalize_native_error(raw, request)
    local normalized_request, request_err = qa_process.normalize_request(request)
    if not normalized_request then
        fail(request_err)
    end
    local keys_ok, keys_err = exact_keys(raw, native_error_keys,
        "native RUN error")
    if not keys_ok then
        fail(keys_err)
    end
    if raw.protocol_version ~= "qa.native_provider_error.v0"
        or raw.event_truth_status ~= "runtime_confirmed"
        or type(raw.code) ~= "string" or type(raw.stage) ~= "string"
        or type(raw.diagnostic) ~= "string" then
        fail("native RUN error identity mismatch")
    end
    if raw.code == "native_run_request_rejected" then
        fail("native launcher rejected a prevalidated RUN request")
    end
    if raw.code == "native_run_unavailable" then
        fail("native RUN unavailable lacks candidate and cleanup attestation")
    end
    fail("native RUN error code is unknown")
end

return qa_process
