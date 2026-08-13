local digest = require("core.digest")
local json = require("core.json")

local schema = {
    projection_protocol = "network.reentry_projection.v1",
    current_work_protocol = "network.current_work.v0",
    rejected_form_protocol = "network.inherited_rejected_form.v0",
    bounds = {
        max_refs = 256,
        max_ref_bytes = 4096,
        max_string_bytes = 65536,
        max_record_depth = 16,
        max_record_nodes = 4096,
        max_current_work_bytes = 65536,
        hard_max_current_work_bytes = 1048576,
        max_failure_summary_bytes = 65536,
    },
}

local projection_keys = {
    protocol_version = true,
    projection_id = true,
    carrier_id = true,
    carrier_hash = true,
    lineage_id = true,
    source_packet_id = true,
    source_corpse_id = true,
    source_generation = true,
    target_generation = true,
    process_contract_id = true,
    context = true,
    stage_id = true,
    completion_assessment_id = true,
    completion_event_ref = true,
    terminal_recovery_basis = true,
    source_manifest_ref = true,
    current_work = true,
    rejected_form = true,
    historical_qa_id = true,
    source_refs = true,
    event_truth_status = true,
    content_truth_status = true,
}

local current_work_keys = {
    protocol_version = true,
    original_task = true,
    remaining_work = true,
    prior_generation = true,
    continuation_basis = true,
    process_contract_id = true,
    context = true,
    stage_id = true,
    source_refs = true,
    content_truth_status = true,
}

local rejected_form_keys = {
    protocol_version = true,
    projection_id = true,
    source_packet_id = true,
    source_corpse_id = true,
    source_corpse_hash = true,
    source_generation = true,
    target_generation = true,
    historical_qa_id = true,
    candidate_seal_id = true,
    candidate_seal_event_ref = true,
    artifact_alignment_id = true,
    qa_contract_id = true,
    verdict_id = true,
    verdict_ref = true,
    rejected_check_ids = true,
    rejected_check_refs = true,
    failure_summary = true,
    terminal_manifest_ref = true,
    source_refs = true,
    event_truth_status = true,
    applicability_truth_status = true,
}

local failure_summary_keys = {
    check_reason = true,
    termination = true,
    cause = true,
    finality = true,
}

local content_truth_statuses = {
    runtime_confirmed = true,
    semantic_proposal = true,
    unsupported = true,
    rejected = true,
    unknown = true,
    mixed = true,
}

local forbidden_record_keys = {
    artifact = true,
    artifacts = true,
    artifact_bytes = true,
    command = true,
    executable = true,
    argv = true,
    cwd = true,
    stdout = true,
    stderr = true,
    trace = true,
    packet_trace = true,
    prior_manifest = true,
    manifest = true,
    repository_id = true,
    repository_path = true,
    root_authority_id = true,
    root_fingerprint = true,
    grant_id = true,
    handle = true,
    provider = true,
    provider_id = true,
    execution_receipt = true,
    execution_receipt_id = true,
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

local function same_value(left, right, seen)
    if type(left) ~= type(right) then
        return false
    end
    if type(left) ~= "table" then
        return left == right
    end
    seen = seen or {}
    if seen[left] ~= nil then
        return seen[left] == right
    end
    seen[left] = right
    for key, value in pairs(left) do
        if not same_value(value, right[key], seen) then
            return false
        end
    end
    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end
    return true
end

local function exact_record(value, allowed, optional, label)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, label .. " must be a plain table"
    end
    optional = optional or {}
    for key in pairs(value) do
        if not allowed[key] then
            return nil, label .. " contains unknown key: " .. tostring(key)
        end
    end
    for key in pairs(allowed) do
        if value[key] == nil and not optional[key] then
            return nil, label .. " is missing key: " .. key
        end
    end
    return true
end

local function bounded_string(value, label, maximum, allow_empty)
    maximum = maximum or schema.bounds.max_string_bytes
    if type(value) ~= "string" or (value == "" and allow_empty ~= true)
        or #value > maximum or value:find("[%z\1-\31\127]")
        or utf8.len(value) == nil then
        return nil, label .. " must be bounded control-free UTF-8"
    end
    return value
end

local function positive_integer(value, label)
    if type(value) ~= "number" or value < 1 or value ~= math.floor(value) then
        return nil, label .. " must be an integer >= 1"
    end
    return value
end

local function finite_number(value, label)
    if type(value) ~= "number" or value ~= value
        or value == math.huge or value == -math.huge then
        return nil, label .. " must be finite"
    end
    return value
end

local function prefixed_digest(value, prefix)
    return type(value) == "string" and #value == #prefix + 64
        and value:sub(1, #prefix) == prefix
        and value:sub(#prefix + 1):match("^[0-9a-f]+$") ~= nil
end

local function bare_digest(value)
    return type(value) == "string" and #value == 64
        and value:match("^[0-9a-f]+$") ~= nil
end

local function dense_array_shape(value, label)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, label .. " must be a dense array"
    end
    local count, maximum = 0, 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            return nil, label .. " must be a dense array"
        end
        count = count + 1
        maximum = math.max(maximum, key)
    end
    if count ~= maximum then
        return nil, label .. " must be a dense array"
    end
    return true
end

local function normalize_refs(value, label, allow_empty)
    local shape, shape_err = dense_array_shape(value, label)
    if not shape then
        return nil, shape_err
    end
    if #value > schema.bounds.max_refs then
        return nil, label .. " exceeds its item ceiling"
    end
    local result, seen = {}, {}
    for index, ref in ipairs(value) do
        local normalized, ref_err = bounded_string(
            ref,
            label .. "[" .. tostring(index) .. "]",
            schema.bounds.max_ref_bytes
        )
        if not normalized then
            return nil, ref_err
        end
        if not seen[normalized] then
            seen[normalized] = true
            result[#result + 1] = normalized
        end
    end
    table.sort(result)
    if #result == 0 and allow_empty ~= true then
        return nil, label .. " cannot be empty"
    end
    return result
end

local function contains_ref(refs, expected)
    for _, ref in ipairs(refs or {}) do
        if ref == expected then
            return true
        end
    end
    return false
end

local function require_refs(refs, required, label)
    for _, ref in ipairs(required) do
        if not contains_ref(refs, ref) then
            return nil, label .. " omits required ref: " .. tostring(ref)
        end
    end
    return true
end

local function normalize_bounded_record(value, label, forbidden)
    local state = {nodes = 0, active = {}}

    local function walk(node, path, depth)
        local kind = type(node)
        if kind == "string" then
            return bounded_string(node, path, schema.bounds.max_string_bytes, true)
        end
        if kind == "number" then
            return finite_number(node, path)
        end
        if kind == "boolean" then
            return node
        end
        if kind ~= "table" or getmetatable(node) ~= nil then
            return nil, path .. " contains an unsupported value"
        end
        if depth > schema.bounds.max_record_depth then
            return nil, label .. " exceeds its depth ceiling"
        end
        if state.active[node] then
            return nil, label .. " contains a cycle"
        end
        state.nodes = state.nodes + 1
        if state.nodes > schema.bounds.max_record_nodes then
            return nil, label .. " exceeds its node ceiling"
        end
        state.active[node] = true

        local has_number, has_string = false, false
        local count, maximum = 0, 0
        for key in pairs(node) do
            if type(key) == "number" then
                if key < 1 or key ~= math.floor(key) then
                    state.active[node] = nil
                    return nil, path .. " contains an invalid array key"
                end
                has_number = true
                count = count + 1
                maximum = math.max(maximum, key)
            elseif type(key) == "string" then
                local _, key_err = bounded_string(key, path .. " key", 256)
                if key_err then
                    state.active[node] = nil
                    return nil, key_err
                end
                if forbidden and forbidden[key] then
                    state.active[node] = nil
                    return nil, path .. " contains forbidden key: " .. key
                end
                has_string = true
            else
                state.active[node] = nil
                return nil, path .. " contains an unsupported key"
            end
        end
        if has_number and has_string then
            state.active[node] = nil
            return nil, path .. " cannot mix array and record keys"
        end
        if has_number and count ~= maximum then
            state.active[node] = nil
            return nil, path .. " must be a dense array"
        end

        local result = {}
        for key, child in pairs(node) do
            local normalized, child_err = walk(
                child,
                path .. "." .. tostring(key),
                depth + 1
            )
            if normalized == nil and child_err ~= nil then
                state.active[node] = nil
                return nil, child_err
            end
            result[key] = normalized
        end
        state.active[node] = nil
        return result
    end

    return walk(value, label, 1)
end

local function encoded_within(value, maximum, label)
    local ok, encoded = pcall(json.encode, value)
    if not ok then
        return nil, label .. " cannot be canonically encoded: " .. tostring(encoded)
    end
    if #encoded > maximum then
        return nil, label .. " exceeds its byte ceiling"
    end
    return true
end

local function normalize_identity(value, key, prefix)
    local projected = copy_value(value)
    projected[key] = nil
    local hash, hash_err = digest.record(projected)
    if not hash then
        return nil, hash_err
    end
    local expected = prefix .. hash
    if value[key] ~= nil and value[key] ~= expected then
        return nil, key .. " identity mismatch"
    end
    projected[key] = expected
    return projected
end

function schema.normalize_failure_summary(value)
    local exact, exact_err = exact_record(
        value,
        failure_summary_keys,
        nil,
        "rejected-form failure summary"
    )
    if not exact then
        return nil, exact_err
    end
    local check_reason, reason_err = bounded_string(
        value.check_reason,
        "rejected-form check_reason",
        4096
    )
    if not check_reason then
        return nil, reason_err
    end
    local normalized = {check_reason = check_reason}
    for _, key in ipairs({"termination", "cause", "finality"}) do
        local child, child_err = normalize_bounded_record(
            value[key],
            "rejected-form " .. key,
            forbidden_record_keys
        )
        if not child then
            return nil, child_err
        end
        normalized[key] = child
    end
    local size_ok, size_err = encoded_within(
        normalized,
        schema.bounds.max_failure_summary_bytes,
        "rejected-form failure summary"
    )
    if not size_ok then
        return nil, size_err
    end
    return normalized
end

function schema.normalize_current_work(value, options)
    options = options or {}
    local exact, exact_err = exact_record(
        value,
        current_work_keys,
        nil,
        "NETWORK current work"
    )
    if not exact then
        return nil, exact_err
    end
    if value.protocol_version ~= schema.current_work_protocol
        or value.continuation_basis ~= "qa_rejected"
        or value.process_contract_id ~= "software.create.v0"
        or value.context ~= "software_task.v0"
        or not content_truth_statuses[value.content_truth_status] then
        return nil, "NETWORK current-work envelope is invalid"
    end
    local original_task, task_err = bounded_string(
        value.original_task,
        "NETWORK original task",
        schema.bounds.max_string_bytes
    )
    if not original_task then
        return nil, task_err
    end
    local generation, generation_err = positive_integer(
        value.prior_generation,
        "NETWORK prior generation"
    )
    if not generation then
        return nil, generation_err
    end
    local stage_id, stage_err = bounded_string(
        value.stage_id,
        "NETWORK stage_id",
        schema.bounds.max_ref_bytes
    )
    if not stage_id then
        return nil, stage_err
    end
    local remaining, remaining_err = normalize_bounded_record(
        value.remaining_work,
        "NETWORK remaining_work",
        forbidden_record_keys
    )
    if not remaining then
        return nil, remaining_err
    end
    local refs, refs_err = normalize_refs(
        value.source_refs,
        "NETWORK current-work source_refs"
    )
    if not refs then
        return nil, refs_err
    end
    local normalized = {
        protocol_version = schema.current_work_protocol,
        original_task = original_task,
        remaining_work = remaining,
        prior_generation = generation,
        continuation_basis = "qa_rejected",
        process_contract_id = "software.create.v0",
        context = "software_task.v0",
        stage_id = stage_id,
        source_refs = refs,
        content_truth_status = value.content_truth_status,
    }
    local maximum = options.max_current_work_bytes
        or schema.bounds.max_current_work_bytes
    if type(maximum) ~= "number" or maximum < 1
        or maximum ~= math.floor(maximum)
        or maximum > schema.bounds.hard_max_current_work_bytes then
        return nil, "NETWORK current-work byte ceiling is invalid"
    end
    local size_ok, size_err = encoded_within(
        normalized,
        maximum,
        "NETWORK current work"
    )
    if not size_ok then
        return nil, size_err
    end
    return normalized
end

function schema.normalize_rejected_form(value)
    local exact, exact_err = exact_record(
        value,
        rejected_form_keys,
        {projection_id = true},
        "NETWORK rejected form"
    )
    if not exact then
        return nil, exact_err
    end
    if value.protocol_version ~= schema.rejected_form_protocol
        or value.event_truth_status ~= "runtime_confirmed"
        or value.applicability_truth_status ~= "inherited_proposal"
        or not bare_digest(value.source_corpse_hash)
        or not prefixed_digest(value.historical_qa_id, "qa-history:")
        or not prefixed_digest(value.candidate_seal_id, "candidate-seal:")
        or not prefixed_digest(value.qa_contract_id, "qa-contract:")
        or not prefixed_digest(value.verdict_id, "qa-verdict:") then
        return nil, "NETWORK rejected-form envelope is invalid"
    end
    for _, key in ipairs({
        "source_packet_id", "source_corpse_id", "candidate_seal_event_ref",
        "artifact_alignment_id", "verdict_ref", "terminal_manifest_ref",
    }) do
        local _, string_err = bounded_string(
            value[key],
            "NETWORK rejected form " .. key,
            schema.bounds.max_ref_bytes
        )
        if string_err then
            return nil, string_err
        end
    end
    local source_generation, source_generation_err = positive_integer(
        value.source_generation,
        "NETWORK rejected-form source generation"
    )
    if not source_generation then
        return nil, source_generation_err
    end
    if value.target_generation ~= source_generation + 1 then
        return nil, "NETWORK rejected-form generation boundary is invalid"
    end
    local check_ids, check_ids_err = normalize_refs(
        value.rejected_check_ids,
        "NETWORK rejected check ids"
    )
    if not check_ids then
        return nil, check_ids_err
    end
    for _, id in ipairs(check_ids) do
        if not prefixed_digest(id, "qa-check:") then
            return nil, "NETWORK rejected check id is invalid"
        end
    end
    local check_refs, check_refs_err = normalize_refs(
        value.rejected_check_refs,
        "NETWORK rejected check refs"
    )
    if not check_refs then
        return nil, check_refs_err
    end
    if #check_ids ~= #check_refs then
        return nil, "NETWORK rejected check ids/refs disagree"
    end
    local failure, failure_err = schema.normalize_failure_summary(
        value.failure_summary
    )
    if not failure then
        return nil, failure_err
    end
    local refs, refs_err = normalize_refs(
        value.source_refs,
        "NETWORK rejected-form source_refs"
    )
    if not refs then
        return nil, refs_err
    end
    local required = {
        value.source_packet_id,
        value.source_corpse_id,
        value.source_corpse_hash,
        value.historical_qa_id,
        value.candidate_seal_id,
        value.candidate_seal_event_ref,
        value.artifact_alignment_id,
        value.qa_contract_id,
        value.verdict_id,
        value.verdict_ref,
        value.terminal_manifest_ref,
    }
    for _, ref in ipairs(check_ids) do required[#required + 1] = ref end
    for _, ref in ipairs(check_refs) do required[#required + 1] = ref end
    local refs_ok, required_err = require_refs(
        refs,
        required,
        "NETWORK rejected form"
    )
    if not refs_ok then
        return nil, required_err
    end
    local normalized = {
        protocol_version = schema.rejected_form_protocol,
        projection_id = value.projection_id,
        source_packet_id = value.source_packet_id,
        source_corpse_id = value.source_corpse_id,
        source_corpse_hash = value.source_corpse_hash,
        source_generation = source_generation,
        target_generation = value.target_generation,
        historical_qa_id = value.historical_qa_id,
        candidate_seal_id = value.candidate_seal_id,
        candidate_seal_event_ref = value.candidate_seal_event_ref,
        artifact_alignment_id = value.artifact_alignment_id,
        qa_contract_id = value.qa_contract_id,
        verdict_id = value.verdict_id,
        verdict_ref = value.verdict_ref,
        rejected_check_ids = check_ids,
        rejected_check_refs = check_refs,
        failure_summary = failure,
        terminal_manifest_ref = value.terminal_manifest_ref,
        source_refs = refs,
        event_truth_status = "runtime_confirmed",
        applicability_truth_status = "inherited_proposal",
    }
    return normalize_identity(normalized, "projection_id", "rejected-form:")
end

function schema.normalize_projection(value, options)
    options = options or {}
    local exact, exact_err = exact_record(
        value,
        projection_keys,
        {
            projection_id = true,
            rejected_form = true,
            historical_qa_id = true,
        },
        "NETWORK re-entry projection"
    )
    if not exact then
        return nil, exact_err
    end
    if value.protocol_version ~= schema.projection_protocol
        or value.process_contract_id ~= "software.create.v0"
        or value.context ~= "software_task.v0"
        or value.terminal_recovery_basis ~= "qa_rejected"
        or value.event_truth_status ~= "runtime_confirmed"
        or not content_truth_statuses[value.content_truth_status]
        or not bare_digest(value.carrier_hash)
        or not prefixed_digest(
            value.completion_assessment_id,
            "lineage-assessment:"
        ) then
        return nil, "NETWORK re-entry projection envelope is invalid"
    end
    for _, key in ipairs({
        "carrier_id", "lineage_id", "source_packet_id", "source_corpse_id",
        "stage_id", "completion_event_ref", "source_manifest_ref",
    }) do
        local _, string_err = bounded_string(
            value[key],
            "NETWORK projection " .. key,
            schema.bounds.max_ref_bytes
        )
        if string_err then
            return nil, string_err
        end
    end
    local source_generation, generation_err = positive_integer(
        value.source_generation,
        "NETWORK projection source generation"
    )
    if not source_generation then
        return nil, generation_err
    end
    if value.target_generation ~= source_generation + 1 then
        return nil, "NETWORK projection generation boundary is invalid"
    end
    local current_work, current_work_err = schema.normalize_current_work(
        value.current_work,
        options
    )
    if not current_work then
        return nil, current_work_err
    end
    if current_work.prior_generation ~= source_generation
        or current_work.continuation_basis ~= value.terminal_recovery_basis
        or current_work.process_contract_id ~= value.process_contract_id
        or current_work.context ~= value.context
        or current_work.stage_id ~= value.stage_id then
        return nil, "NETWORK current work contradicts re-entry coordinates"
    end
    local historical_qa_id = value.historical_qa_id
    if historical_qa_id ~= nil
        and not prefixed_digest(historical_qa_id, "qa-history:") then
        return nil, "NETWORK historical QA id is invalid"
    end
    local rejected_form
    if value.rejected_form ~= nil then
        rejected_form, exact_err = schema.normalize_rejected_form(
            value.rejected_form
        )
        if not rejected_form then
            return nil, exact_err
        end
        if historical_qa_id == nil
            or rejected_form.historical_qa_id ~= historical_qa_id
            or rejected_form.source_packet_id ~= value.source_packet_id
            or rejected_form.source_corpse_id ~= value.source_corpse_id
            or rejected_form.source_generation ~= source_generation
            or rejected_form.target_generation ~= value.target_generation
            or rejected_form.terminal_manifest_ref ~= value.source_manifest_ref
            or value.content_truth_status ~= "mixed" then
            return nil, "NETWORK rejected form contradicts re-entry coordinates"
        end
    elseif historical_qa_id == nil then
        if value.content_truth_status ~= current_work.content_truth_status then
            return nil, "NETWORK projection truth status contradicts current work"
        end
    elseif value.content_truth_status ~= current_work.content_truth_status then
        return nil, "NETWORK accepted-history projection truth status is invalid"
    end
    local refs, refs_err = normalize_refs(
        value.source_refs,
        "NETWORK projection source_refs"
    )
    if not refs then
        return nil, refs_err
    end
    local required = {
        value.carrier_id,
        value.carrier_hash,
        value.source_packet_id,
        value.source_corpse_id,
        value.completion_assessment_id,
        value.completion_event_ref,
        value.source_manifest_ref,
    }
    if historical_qa_id then required[#required + 1] = historical_qa_id end
    if rejected_form then
        required[#required + 1] = rejected_form.source_corpse_hash
        for _, ref in ipairs(rejected_form.source_refs) do
            required[#required + 1] = ref
        end
    end
    local refs_ok, required_err = require_refs(
        refs,
        required,
        "NETWORK projection"
    )
    if not refs_ok then
        return nil, required_err
    end
    local normalized = {
        protocol_version = schema.projection_protocol,
        projection_id = value.projection_id,
        carrier_id = value.carrier_id,
        carrier_hash = value.carrier_hash,
        lineage_id = value.lineage_id,
        source_packet_id = value.source_packet_id,
        source_corpse_id = value.source_corpse_id,
        source_generation = source_generation,
        target_generation = value.target_generation,
        process_contract_id = "software.create.v0",
        context = "software_task.v0",
        stage_id = value.stage_id,
        completion_assessment_id = value.completion_assessment_id,
        completion_event_ref = value.completion_event_ref,
        terminal_recovery_basis = "qa_rejected",
        source_manifest_ref = value.source_manifest_ref,
        current_work = current_work,
        rejected_form = rejected_form,
        historical_qa_id = historical_qa_id,
        source_refs = refs,
        event_truth_status = "runtime_confirmed",
        content_truth_status = value.content_truth_status,
    }
    return normalize_identity(normalized, "projection_id", "network-projection:")
end

local function verify_normalized(value, normalizer, label, options)
    local normalized, normalized_err = normalizer(value, options)
    if not normalized then
        return nil, normalized_err
    end
    if not same_value(value, normalized) then
        return nil, label .. " is not normalized"
    end
    return true
end

function schema.verify_current_work(value, options)
    return verify_normalized(
        value,
        schema.normalize_current_work,
        "NETWORK current work",
        options
    )
end

function schema.verify_rejected_form(value)
    return verify_normalized(
        value,
        schema.normalize_rejected_form,
        "NETWORK rejected form"
    )
end

function schema.verify_projection(value, options)
    return verify_normalized(
        value,
        schema.normalize_projection,
        "NETWORK re-entry projection",
        options
    )
end

function schema.rejected_form_identity(value)
    local prepared = copy_value(value)
    prepared.projection_id = nil
    local normalized, normalized_err = schema.normalize_rejected_form(prepared)
    if not normalized then
        return nil, normalized_err
    end
    return normalized.projection_id
end

function schema.projection_identity(value, options)
    local prepared = copy_value(value)
    prepared.projection_id = nil
    local normalized, normalized_err = schema.normalize_projection(
        prepared,
        options
    )
    if not normalized then
        return nil, normalized_err
    end
    return normalized.projection_id
end

function schema.same(left, right)
    return same_value(left, right)
end

return schema
