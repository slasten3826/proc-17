local candidate_seal = require("runtime.candidate_seal")
local digest = require("core.digest")
local qa_contract = require("runtime.qa_contract")
local qa_schema = require("core.qa_schema")

local qa_request = {
    protocol_version = "qa.check_request.v0",
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

local function sorted_unique(values)
    local result = {}
    local seen = {}
    for _, value in ipairs(values or {}) do
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function diagnostic(code, detail, refs)
    return {
        protocol_version = "qa.request_diagnostic.v0",
        code = code,
        detail = detail or code,
        source_refs = sorted_unique(refs),
        event_truth_status = "runtime_confirmed",
    }
end

local function exact_record(value, keys, label, optional_id)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, label .. " must be a plain table"
    end
    for key in pairs(value) do
        if not keys[key] then
            return nil, label .. " contains unknown key: " .. tostring(key)
        end
    end
    for key in pairs(keys) do
        if value[key] == nil and key ~= optional_id then
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

local function prefixed_digest(value, prefix)
    return type(value) == "string" and #value == #prefix + 64
        and value:sub(1, #prefix) == prefix
        and value:sub(#prefix + 1):match("^[0-9a-f]+$") ~= nil
end

local function normalize_refs(value)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, "QA request source_refs must be a dense array"
    end
    local count, maximum = 0, 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            return nil, "QA request source_refs must be a dense array"
        end
        count = count + 1
        maximum = math.max(maximum, key)
    end
    if count ~= maximum or count > 256 then
        return nil, "QA request source_refs exceed their shape ceiling"
    end
    local result = {}
    for index, ref in ipairs(value) do
        local normalized, err = non_empty(ref,
            "QA request source_refs[" .. tostring(index) .. "]")
        if not normalized then
            return nil, err
        end
        result[#result + 1] = normalized
    end
    return sorted_unique(result)
end

local function normalize(value)
    local record_ok, record_err = exact_record(value, request_keys,
        "QA check request", "request_id")
    if not record_ok then
        return nil, record_err
    end
    if value.protocol_version ~= qa_request.protocol_version
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
    local entrypoint_ok, entrypoint_err = exact_record(value.entrypoint,
        entrypoint_keys, "QA request entrypoint")
    if not entrypoint_ok then
        return nil, entrypoint_err
    end
    for _, key in ipairs({
        "relative_path", "work_unit_id", "completion_ref", "verification_ref",
    }) do
        local _, err = non_empty(value.entrypoint[key], "QA entrypoint " .. key)
        if err then
            return nil, err
        end
    end
    if not positive_integer(value.entrypoint.work_unit_version,
        "QA entrypoint work_unit_version")
        or not non_negative_integer(value.entrypoint.bytes, "QA entrypoint bytes")
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

local function artifact_for(seal, relative_path)
    local found
    for _, artifact in ipairs(seal and seal.artifacts or {}) do
        if artifact.relative_path == relative_path then
            if found then
                return nil, "QA entrypoint artifact is ambiguous"
            end
            found = artifact
        end
    end
    if not found then
        return nil, "QA entrypoint artifact is absent"
    end
    return found
end

function qa_request.prepare(instance, host_services)
    host_services = host_services or {}
    if type(host_services) ~= "table" then
        return nil, diagnostic("host_services_invalid",
            "QA request host services must be table")
    end
    local environment = host_services.qa_environment or host_services.environment
    local seal, seal_event, seal_err = candidate_seal.current(instance)
    if not seal then
        return nil, diagnostic("candidate_seal_not_ready", seal_err)
    end
    local alignment, alignment_err = candidate_seal.inspect_alignment(instance, seal)
    if not alignment then
        return nil, diagnostic("artifact_alignment_invalid", alignment_err,
            {seal.candidate_seal_id})
    end
    local eligibility, eligibility_err = qa_contract.inspect_candidate(
        instance,
        seal,
        alignment,
        environment
    )
    if not eligibility then
        return nil, diagnostic("eligibility_invalid", eligibility_err)
    end
    if eligibility.state ~= "ready" then
        return nil, diagnostic("candidate_not_ready", eligibility.state,
            eligibility.conflicting_refs)
    end
    local contract, contract_err = qa_contract.verify_birth(instance)
    if not contract then
        return nil, diagnostic("qa_contract_invalid", contract_err)
    end
    local check = contract.required_checks[1]
    local artifact, artifact_err = artifact_for(seal, check.entrypoint.relative_path)
    if not artifact then
        return nil, diagnostic("entrypoint_invalid", artifact_err,
            {seal.candidate_seal_id})
    end
    local request = {
        protocol_version = qa_request.protocol_version,
        request_id = nil,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        process_contract_id = instance.process_contract_id,
        context = instance.work_context,
        stage_id = instance.stage_id,
        repository_id = instance.repository_id,
        candidate_seal_id = seal.candidate_seal_id,
        candidate_seal_event_ref = seal_event.id,
        artifact_alignment_id = alignment.alignment_id,
        qa_contract_id = contract.qa_contract_id,
        check_id = check.check_id,
        profile_id = check.profile_id,
        environment_id = check.environment_id,
        entrypoint = {
            relative_path = artifact.relative_path,
            work_unit_id = artifact.work_unit_id,
            work_unit_version = artifact.work_unit_version,
            bytes = artifact.bytes,
            sha256 = "sha256:" .. artifact.sha256,
            completion_ref = artifact.completion_ref,
            verification_ref = artifact.verification_ref,
        },
        expected_exit_codes = {0},
        resource_limits = copy_value(check.resource_limits),
        source_refs = sorted_unique({
            eligibility.eligibility_id,
            seal.candidate_seal_id,
            seal_event.id,
            alignment.alignment_id,
            contract.qa_contract_id,
            check.check_id,
            artifact.completion_ref,
            artifact.verification_ref,
            environment.environment_id,
        }),
        event_truth_status = "runtime_confirmed",
        content_truth_status = contract.content_truth_status,
    }
    local normalized, normalized_err = normalize(request)
    if not normalized then
        return nil, diagnostic("request_assembly_invalid", normalized_err,
            request.source_refs)
    end
    return copy_value(normalized)
end

function qa_request.verify(instance, request)
    local normalized, normalized_err = normalize(request)
    if not normalized then
        return nil, normalized_err
    end
    if not qa_schema.same(request, normalized) then
        return nil, "QA check request is not normalized"
    end
    if type(instance) ~= "table"
        or normalized.packet_id ~= instance.id
        or normalized.lineage_id ~= instance.lineage_id
        or normalized.generation ~= instance.generation
        or normalized.process_contract_id ~= instance.process_contract_id
        or normalized.context ~= instance.work_context
        or normalized.stage_id ~= instance.stage_id
        or normalized.repository_id ~= instance.repository_id then
        return nil, "QA check request is foreign to Packet"
    end
    local contract, contract_err = qa_contract.verify_birth(instance)
    if not contract then
        return nil, contract_err
    end
    local check = contract.required_checks[1]
    if normalized.qa_contract_id ~= contract.qa_contract_id
        or normalized.check_id ~= check.check_id
        or normalized.profile_id ~= check.profile_id
        or normalized.environment_id ~= check.environment_id
        or normalized.content_truth_status ~= contract.content_truth_status
        or not qa_schema.same(normalized.resource_limits, check.resource_limits)
        or normalized.entrypoint.relative_path ~= check.entrypoint.relative_path then
        return nil, "QA check request diverged from birth contract"
    end
    local seal, seal_event, seal_err = candidate_seal.find(
        instance,
        normalized.candidate_seal_id
    )
    if not seal then
        return nil, seal_err
    end
    if seal_event.id ~= normalized.candidate_seal_event_ref then
        return nil, "QA check request seal event mismatch"
    end
    local alignment, alignment_err = candidate_seal.inspect_alignment(instance, seal)
    if not alignment then
        return nil, alignment_err
    end
    if alignment.state ~= "aligned"
        or alignment.alignment_id ~= normalized.artifact_alignment_id then
        return nil, "QA check request artifact alignment changed"
    end
    local artifact, artifact_err = artifact_for(seal, normalized.entrypoint.relative_path)
    if not artifact then
        return nil, artifact_err
    end
    local expected_entrypoint = {
        relative_path = artifact.relative_path,
        work_unit_id = artifact.work_unit_id,
        work_unit_version = artifact.work_unit_version,
        bytes = artifact.bytes,
        sha256 = "sha256:" .. artifact.sha256,
        completion_ref = artifact.completion_ref,
        verification_ref = artifact.verification_ref,
    }
    if not qa_schema.same(normalized.entrypoint, expected_entrypoint) then
        return nil, "QA check request entrypoint evidence changed"
    end
    return true
end

function qa_request.find(instance, request_id)
    if type(request_id) ~= "string" or request_id == "" then
        return nil, nil, "QA request_id is required"
    end
    local found, found_event
    for _, event in ipairs(instance and instance.trace or {}) do
        if event.type == "qa_check_request"
            and type(event.payload) == "table"
            and event.payload.request_id == request_id then
            local verified, verified_err = qa_request.verify(instance, event.payload)
            if not verified then
                return nil, nil, verified_err
            end
            if found then
                return nil, nil, "QA check request is ambiguous"
            end
            found = copy_value(event.payload)
            found_event = copy_value(event)
        end
    end
    if not found then
        return nil, nil, "QA check request event is absent"
    end
    return found, found_event
end

return qa_request
