local digest = require("core.digest")
local qa_schema = require("core.qa_schema")
local qa_process = require("runtime.qa_process")
local qa_private_result = require("runtime.qa_private_result")

local schema = {
    protocol_version = "qa.evidence_schema.v0",
}

local request_keys = {
    protocol_version = true,
    request_id = true,
    packet_id = true,
    lineage_id = true,
    generation = true,
    process_contract_id = true,
    context = true,
    stage_id = true,
    repository_id = true,
    candidate_seal_id = true,
    candidate_seal_event_ref = true,
    artifact_alignment_id = true,
    qa_contract_id = true,
    check_id = true,
    profile_id = true,
    environment_id = true,
    entrypoint = true,
    expected_exit_codes = true,
    resource_limits = true,
    source_refs = true,
    event_truth_status = true,
    content_truth_status = true,
}

local entrypoint_keys = {
    relative_path = true,
    work_unit_id = true,
    work_unit_version = true,
    bytes = true,
    sha256 = true,
    completion_ref = true,
    verification_ref = true,
}

local check_keys = {
    protocol_version = true,
    qa_check_id = true,
    packet_id = true,
    lineage_id = true,
    generation = true,
    process_contract_id = true,
    context = true,
    stage_id = true,
    repository_id = true,
    candidate_seal_id = true,
    candidate_seal_event_ref = true,
    artifact_alignment_id = true,
    qa_contract_id = true,
    check_id = true,
    profile_id = true,
    environment_id = true,
    request_id = true,
    request_ref = true,
    execution_receipt_id = true,
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
    runtime_cost = true,
    source_refs = true,
    event_truth_status = true,
    content_truth_status = true,
}

local failure_keys = {
    protocol_version = true,
    failure_id = true,
    packet_id = true,
    lineage_id = true,
    generation = true,
    process_contract_id = true,
    context = true,
    stage_id = true,
    repository_id = true,
    candidate_seal_id = true,
    candidate_seal_event_ref = true,
    artifact_alignment_id = true,
    qa_contract_id = true,
    check_id = true,
    profile_id = true,
    environment_id = true,
    request_id = true,
    request_ref = true,
    execution_receipt_id = true,
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
    transaction_disposition = true,
    source_refs = true,
    event_truth_status = true,
    content_truth_status = true,
}

local source_keys = {
    pre_inventory_id = true,
    post_inventory_id = true,
    stable = true,
    disposition = true,
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

local function plain_tree(value, label, active)
    if type(value) ~= "table" then return true end
    if getmetatable(value) ~= nil then
        return nil, label .. " contains a metatable-bearing record"
    end
    active = active or {}
    if active[value] then return nil, label .. " contains a cycle" end
    active[value] = true
    for key, child in pairs(value) do
        if type(key) ~= "string" and (type(key) ~= "number"
                or key < 1 or key ~= math.floor(key)) then
            return nil, label .. " contains an invalid key"
        end
        local ok, err = plain_tree(child, label, active)
        if not ok then return nil, err end
    end
    active[value] = nil
    return true
end

local function exact_record(value, keys, label, optional)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, label .. " must be a plain table"
    end
    for key in pairs(value) do
        if not keys[key] then
            return nil, label .. " contains unknown key: " .. tostring(key)
        end
    end
    for key in pairs(keys) do
        if value[key] == nil and not (optional and optional[key]) then
            return nil, label .. " is missing key: " .. key
        end
    end
    return true
end

local function non_empty(value, label)
    if type(value) ~= "string" or value == "" or #value > 4096
        or value:find("[%z\1-\31\127]") or utf8.len(value) == nil then
        return nil, label .. " must be a bounded control-free UTF-8 string"
    end
    return value
end

local function positive_integer(value, label)
    if type(value) ~= "number" or value < 1 or value ~= math.floor(value) then
        return nil, label .. " must be a positive integer"
    end
    return value
end

local function non_negative_integer(value, label)
    if type(value) ~= "number" or value < 0 or value ~= math.floor(value) then
        return nil, label .. " must be a non-negative integer"
    end
    return value
end

local function non_negative_number(value, label)
    if type(value) ~= "number" or value < 0 or value ~= value
        or value == math.huge then
        return nil, label .. " must be a finite non-negative number"
    end
    return value
end

local function prefixed_digest(value, prefix)
    return type(value) == "string" and #value == #prefix + 64
        and value:sub(1, #prefix) == prefix
        and value:sub(#prefix + 1):match("^[0-9a-f]+$") ~= nil
end

local function sorted_unique(values)
    local result = {}
    local seen = {}
    for _, value in ipairs(values or {}) do
        if not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function normalize_refs(value, label)
    label = label or "QA evidence"
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, label .. " source_refs must be a dense array"
    end
    local count, maximum = 0, 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            return nil, label .. " source_refs must be a dense array"
        end
        count = count + 1
        maximum = math.max(maximum, key)
    end
    if count ~= maximum or count > 256 then
        return nil, label .. " source_refs exceed their shape ceiling"
    end
    local result = {}
    for index, ref in ipairs(value) do
        local normalized, err = non_empty(
            ref,
            label .. " source_refs[" .. tostring(index) .. "]"
        )
        if not normalized then
            return nil, err
        end
        result[#result + 1] = normalized
    end
    return sorted_unique(result)
end

local function validate_body_coordinates(value, label)
    if (value.process_contract_id ~= "build.only.v0"
            and value.process_contract_id ~= "software.create.v0")
        or value.context ~= "software_task.v0"
        or value.profile_id ~= qa_schema.profile_id
        or value.event_truth_status ~= "runtime_confirmed" then
        return nil, label .. " envelope is invalid"
    end
    for _, key in ipairs({
        "packet_id", "lineage_id", "stage_id", "repository_id",
        "candidate_seal_event_ref", "artifact_alignment_id", "request_ref",
    }) do
        local _, err = non_empty(value[key], label .. " " .. key)
        if err then return nil, err end
    end
    if not positive_integer(value.generation, label .. " generation")
        or not prefixed_digest(value.candidate_seal_id, "candidate-seal:")
        or not prefixed_digest(value.qa_contract_id, "qa-contract:")
        or not prefixed_digest(value.check_id, "qa-check-contract:")
        or not prefixed_digest(value.environment_id, "qa-environment:")
        or not prefixed_digest(value.request_id, "qa-check-request:")
        or not prefixed_digest(
            value.execution_receipt_id,
            "qa-execution-receipt:"
        ) then
        return nil, label .. " identity coordinate is invalid"
    end
    return true
end

local function normalize_contained_process(value)
    local transaction_id = "qa-provider-transaction:" .. string.rep("0", 64)
    local witness_id = "qa-provider-witness:" .. string.rep("1", 64)
    local request = {
        protocol_version = "qa.native_run_request.v1",
        operation = "run_lua54_test_suite",
        transaction_id = transaction_id,
        witness_id = witness_id,
        profile_id = value.profile_id,
        environment_id = value.environment_id,
        entrypoint_relative_path = "tests/run.lua",
        expected_exit_code = 0,
        resource_limits = qa_schema.hard_limits(),
    }
    local kind_codes = {exit = 1, signal = 2, supervisor_kill = 3}
    if type(value.termination) ~= "table"
        or not kind_codes[value.termination.kind] then
        return nil, "QA check termination kind is invalid"
    end
    local raw = {
        protocol_version = "qa.native_run_result.v1",
        transaction_id = transaction_id,
        witness_id = witness_id,
        profile_id = value.profile_id,
        environment_id = value.environment_id,
        phase_ordinal = 2,
        disposition = "contained_candidate",
        start_attested = true,
        source_staging_policy = "qa.source_staging.detached_mount.v0",
        source_staging_complete = true,
        reason = value.reason,
        termination = {
            kind = kind_codes[value.termination.kind],
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

local function normalize_identity(value, id_key, prefix)
    local normalized = copy_value(value)
    normalized[id_key] = nil
    local identity, identity_err = digest.record(normalized)
    if not identity then return nil, identity_err end
    normalized[id_key] = prefix .. identity
    if value[id_key] ~= nil and value[id_key] ~= normalized[id_key] then
        return nil, id_key .. " identity mismatch"
    end
    return normalized
end

function schema.normalize_request(value)
    local plain, plain_err = plain_tree(value, "QA check request")
    if not plain then return nil, plain_err end
    local record_ok, record_err = exact_record(
        value,
        request_keys,
        "QA check request",
        {request_id = true}
    )
    if not record_ok then
        return nil, record_err
    end
    if value.protocol_version ~= "qa.check_request.v0"
        or (value.process_contract_id ~= "build.only.v0"
            and value.process_contract_id ~= "software.create.v0")
        or value.context ~= "software_task.v0"
        or value.profile_id ~= qa_schema.profile_id
        or value.event_truth_status ~= "runtime_confirmed"
        or (value.content_truth_status ~= "runtime_confirmed"
            and value.content_truth_status ~= "mixed") then
        return nil, "QA check request envelope is invalid"
    end
    for _, key in ipairs({
        "packet_id", "lineage_id", "stage_id", "repository_id",
        "candidate_seal_event_ref", "artifact_alignment_id",
    }) do
        local _, err = non_empty(value[key], "QA request " .. key)
        if err then
            return nil, err
        end
    end
    if not positive_integer(value.generation, "QA request generation")
        or not prefixed_digest(value.candidate_seal_id, "candidate-seal:")
        or not prefixed_digest(value.qa_contract_id, "qa-contract:")
        or not prefixed_digest(value.check_id, "qa-check-contract:")
        or not prefixed_digest(value.environment_id, "qa-environment:") then
        return nil, "QA check request identity coordinate is invalid"
    end
    local entrypoint_ok, entrypoint_err = exact_record(
        value.entrypoint,
        entrypoint_keys,
        "QA request entrypoint"
    )
    if not entrypoint_ok then
        return nil, entrypoint_err
    end
    for _, key in ipairs({
        "relative_path", "work_unit_id", "completion_ref", "verification_ref",
    }) do
        local _, err = non_empty(
            value.entrypoint[key],
            "QA entrypoint " .. key
        )
        if err then
            return nil, err
        end
    end
    if not positive_integer(
            value.entrypoint.work_unit_version,
            "QA entrypoint work_unit_version"
        )
        or not non_negative_integer(
            value.entrypoint.bytes,
            "QA entrypoint bytes"
        )
        or not prefixed_digest(value.entrypoint.sha256, "sha256:") then
        return nil, "QA request entrypoint evidence is invalid"
    end
    local exit_shape_ok = type(value.expected_exit_codes) == "table"
        and getmetatable(value.expected_exit_codes) == nil
        and value.expected_exit_codes[1] == 0
    if exit_shape_ok then
        for key in pairs(value.expected_exit_codes) do
            if key ~= 1 then
                exit_shape_ok = false
                break
            end
        end
    end
    if not exit_shape_ok then
        return nil, "QA request expected_exit_codes must be exactly {0}"
    end
    local limits, limits_err = qa_schema.normalize_limits(value.resource_limits)
    if not limits then
        return nil, limits_err
    end
    local refs, refs_err = normalize_refs(value.source_refs)
    if not refs then
        return nil, refs_err
    end
    local normalized = copy_value(value)
    normalized.request_id = nil
    normalized.resource_limits = limits
    normalized.source_refs = refs
    local request_digest, request_err = digest.record(normalized)
    if not request_digest then
        return nil, request_err
    end
    normalized.request_id = "qa-check-request:" .. request_digest
    if value.request_id ~= nil and value.request_id ~= normalized.request_id then
        return nil, "QA check request identity mismatch"
    end
    return normalized
end

function schema.verify_request(value)
    local normalized, normalized_err = schema.normalize_request(value)
    if not normalized then
        return nil, normalized_err
    end
    if not qa_schema.same(value, normalized) then
        return nil, "QA check request is not normalized"
    end
    return true
end

function schema.normalize_check(value)
    local plain, plain_err = plain_tree(value, "QA check")
    if not plain then return nil, plain_err end
    local record_ok, record_err = exact_record(
        value,
        check_keys,
        "QA check",
        {qa_check_id = true}
    )
    if not record_ok then return nil, record_err end
    if value.protocol_version ~= "qa.check.v0"
        or (value.outcome ~= "accepted" and value.outcome ~= "rejected")
        or (value.content_truth_status ~= "runtime_confirmed"
            and value.content_truth_status ~= "mixed") then
        return nil, "QA check envelope is invalid"
    end
    local coordinates_ok, coordinates_err = validate_body_coordinates(
        value,
        "QA check"
    )
    if not coordinates_ok then return nil, coordinates_err end
    local source_ok, source_err = exact_record(
        value.source,
        source_keys,
        "QA check source"
    )
    if not source_ok then return nil, source_err end
    if value.source.stable ~= true
        or value.source.disposition ~= "consumed"
        or type(value.source.pre_inventory_id) ~= "string"
        or value.source.pre_inventory_id == ""
        or value.source.pre_inventory_id ~= value.source.post_inventory_id then
        return nil, "QA check source is not exact and stable"
    end
    local process, process_err = normalize_contained_process(value)
    if not process then return nil, process_err end
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
        or not qa_schema.same(process.cost, value.runtime_cost) then
        return nil, "QA check contradicts normalized RUN v1 evidence"
    end
    local refs, refs_err = normalize_refs(value.source_refs, "QA check")
    if not refs then return nil, refs_err end
    local prepared = copy_value(value)
    prepared.termination = copy_value(process.termination)
    prepared.cause = copy_value(process.cause)
    prepared.finality = copy_value(process.finality)
    prepared.stdout = copy_value(process.stdout)
    prepared.stderr = copy_value(process.stderr)
    prepared.resources = copy_value(process.resources)
    prepared.scratch = copy_value(process.scratch)
    prepared.runtime_cost = copy_value(process.cost)
    prepared.source_refs = refs
    return normalize_identity(prepared, "qa_check_id", "qa-check:")
end

function schema.verify_check(value)
    local normalized, normalized_err = schema.normalize_check(value)
    if not normalized then return nil, normalized_err end
    if not qa_schema.same(value, normalized) then
        return nil, "QA check is not normalized"
    end
    return true
end

local function normalize_failure_topology(value)
    local transaction_id = "qa-provider-transaction:" .. string.rep("0", 64)
    local witness_id = "qa-provider-witness:" .. string.rep("1", 64)
    return qa_private_result.normalize({
        protocol_version = "qa.provider_error.v1",
        request_id = value.request_id,
        physical_transaction_id = transaction_id,
        physical_witness_id = witness_id,
        profile_id = value.profile_id,
        environment_id = value.environment_id,
        class = value.class,
        code = value.code,
        stage = value.stage,
        candidate_start_state = value.candidate_start_state,
        source_acquisition = value.source_acquisition,
        source_stable = value.source_stable,
        source_disposition = value.source_disposition,
        cleanup_state = value.cleanup_state,
        launcher_reaped = value.launcher_reaped,
        result_eof = value.result_eof,
        measured_cost = copy_value(value.measured_cost),
        event_truth_status = "runtime_confirmed",
    }, {
        request = {
            request_id = value.request_id,
            profile_id = value.profile_id,
            environment_id = value.environment_id,
        },
        physical_transaction_id = transaction_id,
        physical_witness_id = witness_id,
    })
end

function schema.normalize_failure(value)
    local plain, plain_err = plain_tree(value, "QA execution failure")
    if not plain then return nil, plain_err end
    local record_ok, record_err = exact_record(
        value,
        failure_keys,
        "QA execution failure",
        {failure_id = true, source_stable = true, measured_cost = true}
    )
    if not record_ok then return nil, record_err end
    if value.protocol_version ~= "qa.execution_failure.v0"
        or value.content_truth_status ~= "runtime_confirmed" then
        return nil, "QA execution failure envelope is invalid"
    end
    local coordinates_ok, coordinates_err = validate_body_coordinates(
        value,
        "QA execution failure"
    )
    if not coordinates_ok then return nil, coordinates_err end
    local topology, topology_err = normalize_failure_topology(value)
    if not topology then return nil, topology_err end
    local expected_disposition = topology.source_disposition == "quarantined"
        and "quarantined" or "consumed_failed"
    if value.transaction_disposition ~= expected_disposition then
        return nil, "QA execution failure transaction disposition is invalid"
    end
    local refs, refs_err = normalize_refs(
        value.source_refs,
        "QA execution failure"
    )
    if not refs then return nil, refs_err end
    local prepared = copy_value(value)
    prepared.source_refs = refs
    prepared.measured_cost = copy_value(topology.measured_cost)
    return normalize_identity(
        prepared,
        "failure_id",
        "qa-execution-failure:"
    )
end

function schema.verify_failure(value)
    local normalized, normalized_err = schema.normalize_failure(value)
    if not normalized then return nil, normalized_err end
    if not qa_schema.same(value, normalized) then
        return nil, "QA execution failure is not normalized"
    end
    return true
end

function schema.normalize_payload(event_type, value)
    if event_type == "qa_check_request" then
        return schema.normalize_request(value)
    end
    if event_type == "qa_check" then
        return schema.normalize_check(value)
    end
    if event_type == "qa_execution_failure" then
        return schema.normalize_failure(value)
    end
    return nil, "QA evidence payload schema is not implemented: "
        .. tostring(event_type)
end

function schema.validate_cost(event_type, cost)
    if type(cost) ~= "table" or getmetatable(cost) ~= nil then
        return nil, "QA evidence cost must be a plain table"
    end
    if event_type == "qa_check_request"
        or event_type == "qa_candidate_verdict" then
        if next(cost) ~= nil then
            return nil, event_type .. " cost must be empty"
        end
        return true
    end
    local allowed = {tool_calls = true, test_runs = true, time_ms = true}
    for key in pairs(cost) do
        if not allowed[key] then
            return nil, "QA evidence cost contains unknown key: " .. tostring(key)
        end
    end
    for key in pairs(allowed) do
        if cost[key] == nil then
            return nil, "QA evidence cost is missing key: " .. key
        end
    end
    if not non_negative_integer(cost.tool_calls, "QA cost tool_calls")
        or not non_negative_integer(cost.test_runs, "QA cost test_runs")
        or not non_negative_number(cost.time_ms, "QA cost time_ms") then
        return nil, "QA evidence cost is invalid"
    end
    return true
end

function schema.same(left, right)
    return qa_schema.same(left, right)
end

schema.copy = copy_value

return schema
