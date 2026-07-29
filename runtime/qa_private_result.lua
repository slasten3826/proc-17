local qa_process = require("runtime.qa_process")
local qa_schema = require("core.qa_schema")

local result = {}

local report_keys = {
    protocol_version = true,
    operation = true,
    request_id = true,
    physical_transaction_id = true,
    physical_witness_id = true,
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

local error_keys = {
    protocol_version = true,
    request_id = true,
    physical_transaction_id = true,
    physical_witness_id = true,
    profile_id = true,
    environment_id = true,
    class = true,
    code = true,
    stage = true,
    candidate_start_state = true,
    source_acquisition = true,
    source_stable = true,
    source_disposition = true,
    cleanup_state = true,
    launcher_reaped = true,
    result_eof = true,
    measured_cost = true,
    event_truth_status = true,
}

local source_keys = {
    pre_inventory_id = true,
    post_inventory_id = true,
    stable = true,
    disposition = true,
}

local body_error_codes = {
    source_reservation_unavailable = true,
    source_preflight_unavailable = true,
    source_preflight_mismatch = true,
    source_drift = true,
    supervisor_unavailable = true,
    source_staging_failed = true,
    supervisor_crashed = true,
    result_pipe_lost = true,
    terminal_frame_missing = true,
    reap_ambiguous = true,
    output_observation_incomplete = true,
    scratch_observation_incomplete = true,
    namespace_cleanup_incomplete = true,
}

local body_error_stages = {
    preflight = true,
    source_staging = true,
    namespace = true,
    launch = true,
    supervision = true,
    postflight = true,
    cleanup = true,
}

local tri_states = {
    not_started = true,
    started = true,
    unknown = true,
}

local completion_states = {
    complete = true,
    incomplete = true,
    unknown = true,
}

local function copy_value(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copied = {}
    seen[value] = copied
    for key, child in pairs(value) do
        copied[copy_value(key, seen)] = copy_value(child, seen)
    end
    return copied
end

local function exact_record(value, keys, name, optional)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, name .. " must be a plain table"
    end
    for key in pairs(value) do
        if not keys[key] then
            return nil, name .. " contains unknown key: " .. tostring(key)
        end
    end
    for key in pairs(keys) do
        if value[key] == nil and not (optional and optional[key]) then
            return nil, name .. " is missing key: " .. key
        end
    end
    return true
end

local function native_request(authority)
    local request = authority and authority.request
    if type(request) ~= "table" then
        return nil, "QA private result authority lacks request"
    end
    return qa_process.normalize_request_v1({
        protocol_version = "qa.native_run_request.v1",
        operation = "run_lua54_test_suite",
        transaction_id = authority.physical_transaction_id,
        witness_id = authority.physical_witness_id,
        profile_id = request.profile_id,
        environment_id = request.environment_id,
        entrypoint_relative_path = request.entrypoint.relative_path,
        expected_exit_code = request.expected_exit_codes[1],
        resource_limits = copy_value(request.resource_limits),
    })
end

local function identity_matches(value, authority)
    local request = authority and authority.request
    return type(request) == "table"
        and value.request_id == request.request_id
        and value.physical_transaction_id == authority.physical_transaction_id
        and value.physical_witness_id == authority.physical_witness_id
        and value.profile_id == request.profile_id
        and value.environment_id == request.environment_id
        and value.event_truth_status == "runtime_confirmed"
end

local function normalized_process_from_report(value, authority)
    local request, request_err = native_request(authority)
    if not request then
        return nil, request_err
    end
    local termination_kinds = {
        exit = 1,
        signal = 2,
        supervisor_kill = 3,
    }
    local raw = {
        protocol_version = "qa.native_run_result.v1",
        transaction_id = value.physical_transaction_id,
        witness_id = value.physical_witness_id,
        profile_id = value.profile_id,
        environment_id = value.environment_id,
        phase_ordinal = 2,
        disposition = "contained_candidate",
        start_attested = true,
        source_staging_policy = "qa.source_staging.detached_mount.v0",
        source_staging_complete = true,
        reason = value.reason,
        termination = {
            kind = termination_kinds[value.termination.kind],
            exit_code = value.termination.exit_code or 0,
            signal = value.termination.signal or 0,
        },
        cause = copy_value(value.cause),
        finality = copy_value(value.finality),
        stdout = copy_value(value.stdout),
        stderr = copy_value(value.stderr),
        resources = copy_value(value.resources),
        scratch = copy_value(value.scratch),
        event_truth_status = "runtime_confirmed",
    }
    local ok, normalized = pcall(qa_process.normalize_result_v1, raw, request)
    if not ok then
        return nil, tostring(normalized)
    end
    return normalized
end

local function normalize_report(value, authority)
    local exact, exact_err = exact_record(
        value,
        report_keys,
        "private QA candidate report"
    )
    if not exact then
        return nil, exact_err
    end
    if value.protocol_version ~= "qa.provider_candidate_report.v1"
        or value.operation ~= "run_lua54_test_suite"
        or (value.outcome ~= "accepted" and value.outcome ~= "rejected")
        or not identity_matches(value, authority) then
        return nil, "private QA candidate report envelope is invalid"
    end
    local source_ok, source_err = exact_record(
        value.source,
        source_keys,
        "private QA report source"
    )
    if not source_ok then
        return nil, source_err
    end
    if value.source.stable ~= true
        or value.source.disposition ~= "consumed"
        or type(value.source.pre_inventory_id) ~= "string"
        or value.source.pre_inventory_id == ""
        or value.source.pre_inventory_id ~= value.source.post_inventory_id
        or (authority.inventory_id ~= nil
            and value.source.pre_inventory_id ~= authority.inventory_id) then
        return nil, "private QA candidate report source is invalid"
    end
    local process, process_err = normalized_process_from_report(value, authority)
    if not process then
        return nil, process_err
    end
    local expected_outcome = process.outcome == "expected_exit"
        and "accepted" or "rejected"
    if value.outcome ~= expected_outcome
        or process.outcome ~= value.reason
        or not qa_schema.same(process.termination, value.termination)
        or not qa_schema.same(process.cause, value.cause)
        or not qa_schema.same(process.finality, value.finality)
        or not qa_schema.same(process.stdout, value.stdout)
        or not qa_schema.same(process.stderr, value.stderr)
        or not qa_schema.same(process.resources, value.resources)
        or not qa_schema.same(process.scratch, value.scratch)
        or not qa_schema.same(process.cost, value.cost) then
        return nil, "private QA candidate report contradicts RUN evidence"
    end
    return copy_value(value)
end

local function normalized_native_error(value, authority)
    return {
        protocol_version = "qa.provider_process_error.v1",
        operation = "run_lua54_test_suite",
        transaction_id = value.physical_transaction_id,
        witness_id = value.physical_witness_id,
        profile_id = value.profile_id,
        environment_id = value.environment_id,
        class = value.class,
        code = value.code,
        stage = value.stage,
        candidate_start_state = value.candidate_start_state,
        cleanup_state = value.cleanup_state,
        launcher_reaped = value.launcher_reaped,
        result_eof = value.result_eof,
        measured_cost = copy_value(value.measured_cost),
        event_truth_status = "runtime_confirmed",
    }
end

local function normalize_error(value, authority)
    local exact, exact_err = exact_record(
        value,
        error_keys,
        "private QA provider error",
        {source_stable = true, measured_cost = true}
    )
    if not exact then
        return nil, exact_err
    end
    if value.protocol_version ~= "qa.provider_error.v1"
        or not identity_matches(value, authority)
        or not body_error_codes[value.code]
        or not body_error_stages[value.stage]
        or not tri_states[value.candidate_start_state]
        or not completion_states[value.cleanup_state]
        or not completion_states[value.launcher_reaped]
        or not completion_states[value.result_eof]
        or (value.class ~= "unavailable" and value.class ~= "world"
            and value.class ~= "ambiguous") then
        return nil, "private QA provider error envelope is invalid"
    end
    if value.source_acquisition == "not_acquired" then
        if value.code ~= "source_reservation_unavailable"
            or value.class ~= "unavailable"
            or value.stage ~= "preflight"
            or value.candidate_start_state ~= "not_started"
            or value.source_stable ~= nil
            or value.source_disposition ~= "not_acquired"
            or value.cleanup_state ~= "complete"
            or value.launcher_reaped ~= "complete"
            or value.result_eof ~= "complete"
            or value.measured_cost ~= nil then
            return nil, "private QA not-acquired error topology is invalid"
        end
        return copy_value(value)
    end
    if value.source_acquisition ~= "acquired"
        or type(value.source_stable) ~= "boolean"
        or (value.source_disposition ~= "consumed"
            and value.source_disposition ~= "quarantined") then
        return nil, "private QA acquired-source topology is invalid"
    end
    if value.code == "source_preflight_unavailable"
        or value.code == "source_preflight_mismatch" then
        if value.stage ~= "preflight"
            or value.candidate_start_state ~= "not_started"
            or value.cleanup_state ~= "complete"
            or value.launcher_reaped ~= "complete"
            or value.result_eof ~= "complete"
            or value.measured_cost ~= nil then
            return nil, "private QA source-preflight topology is invalid"
        end
    elseif value.code == "source_drift" then
        if value.stage ~= "postflight"
            or value.class ~= "ambiguous"
            or value.source_disposition ~= "quarantined"
            or value.source_stable ~= false then
            return nil, "private QA source-drift topology is invalid"
        end
    else
        local _, topology_err = qa_process.error_reuse_class_v1(
            normalized_native_error(value, authority)
        )
        if topology_err then
            return nil, topology_err
        end
    end
    return copy_value(value)
end

function result.normalize(value, authority)
    if type(value) ~= "table" then
        return nil, "private QA result must be table"
    end
    if value.protocol_version == "qa.provider_candidate_report.v1" then
        return normalize_report(value, authority or {})
    end
    if value.protocol_version == "qa.provider_error.v1" then
        return normalize_error(value, authority or {})
    end
    return nil, "private QA result protocol is invalid"
end

local function report_from_pending(authority, pending)
    local process = pending.process
    return result.normalize({
        protocol_version = "qa.provider_candidate_report.v1",
        operation = "run_lua54_test_suite",
        request_id = authority.request.request_id,
        physical_transaction_id = authority.physical_transaction_id,
        physical_witness_id = authority.physical_witness_id,
        profile_id = authority.request.profile_id,
        environment_id = authority.request.environment_id,
        outcome = process.outcome == "expected_exit" and "accepted" or "rejected",
        reason = process.outcome,
        termination = copy_value(process.termination),
        cause = copy_value(process.cause),
        finality = copy_value(process.finality),
        source = {
            pre_inventory_id = pending.pre_inventory_id,
            post_inventory_id = pending.post_inventory_id,
            stable = true,
            disposition = pending.disposition,
        },
        stdout = copy_value(process.stdout),
        stderr = copy_value(process.stderr),
        resources = copy_value(process.resources),
        scratch = copy_value(process.scratch),
        cost = copy_value(process.cost),
        event_truth_status = "runtime_confirmed",
    }, authority)
end

local function error_from_pending(authority, pending)
    local process = pending.process
    local not_acquired = pending.source_acquisition == "not_acquired"
    local process_is_error = type(process) == "table"
        and process.protocol_version == "qa.provider_process_error.v1"
    local process_is_report = type(process) == "table"
        and process.protocol_version == "qa.provider_process_observation.v1"
    return result.normalize({
        protocol_version = "qa.provider_error.v1",
        request_id = authority.request.request_id,
        physical_transaction_id = authority.physical_transaction_id,
        physical_witness_id = authority.physical_witness_id,
        profile_id = authority.request.profile_id,
        environment_id = authority.request.environment_id,
        class = pending.class,
        code = pending.code,
        stage = pending.stage,
        candidate_start_state = process_is_report and "started"
            or (process_is_error and process.candidate_start_state or "not_started"),
        source_acquisition = not_acquired and "not_acquired" or "acquired",
        source_stable = not_acquired and nil or pending.source_stable == true,
        source_disposition = not_acquired and "not_acquired"
            or pending.disposition,
        cleanup_state = process_is_report and "complete"
            or (process_is_error and process.cleanup_state or "complete"),
        launcher_reaped = process_is_report and "complete"
            or (process_is_error and process.launcher_reaped or "complete"),
        result_eof = process_is_report and "complete"
            or (process_is_error and process.result_eof or "complete"),
        measured_cost = not_acquired and nil
            or (process and copy_value(process.cost or process.measured_cost)
                or nil),
        event_truth_status = "runtime_confirmed",
    }, authority)
end

function result.from_pending(authority, pending)
    if type(pending) ~= "table" then
        return nil, "private QA pending join must be table"
    end
    if pending.kind == "report" then
        return report_from_pending(authority, pending)
    end
    if pending.kind == "error" then
        return error_from_pending(authority, pending)
    end
    return nil, "private QA pending join kind is invalid"
end

return result
