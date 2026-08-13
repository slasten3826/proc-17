local digest = require("core.digest")
local json = require("core.json")
local corpse_module = require("runtime.corpse")
local qa_evidence_schema = require("core.qa_evidence_schema")
local qa_schema = require("core.qa_schema")

local carrier = {
    protocol_version = "carrier.v0",
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

local function identity_projection(record)
    local projected = copy_value(record)
    projected.carrier_hash = nil
    return projected
end

local qa_history_keys = {
    protocol_version = true,
    source_corpse_id = true,
    source_corpse_hash = true,
    source_packet_id = true,
    source_generation = true,
    qa_evidence = true,
    source_refs = true,
    event_truth_status = true,
    applicability_truth_status = true,
}

local function exact_keys(value, allowed, label)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, label .. " must be a plain table"
    end
    for key in pairs(value) do
        if not allowed[key] then
            return nil, label .. " contains unknown key: " .. tostring(key)
        end
    end
    for key in pairs(allowed) do
        if value[key] == nil then
            return nil, label .. " is missing key: " .. key
        end
    end
    return true
end

local function unique_refs(values)
    local result, seen = {}, {}
    for _, value in ipairs(values or {}) do
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function contains_ref(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then return true end
    end
    return false
end

local function verify_qa_rejected_assessment(corpse, assessment, qa_history)
    if assessment.contract_id ~= "software.create.v0"
        or assessment.task_state ~= "unfinished"
        or assessment.terminal_recoverable ~= true
        or assessment.terminal_recovery_basis ~= "qa_rejected"
        or assessment.event_truth_status ~= "runtime_confirmed"
        or corpse.process_contract_id ~= "software.create.v0"
        or corpse.work_mode ~= "build"
        or corpse.death_cause ~= "blocked"
        or type(assessment.progress) ~= "table"
        or assessment.progress.rejected_generation ~= corpse.generation
        or type(assessment.remaining_work) ~= "table"
        or assessment.remaining_work.count ~= 1
        or assessment.remaining_work.kind ~= "fresh_candidate_generation"
        or assessment.remaining_work.stage_id ~= corpse.stage_id
        or type(qa_history) ~= "table" then
        return nil, "QA-rejected assessment cannot produce recovery carrier"
    end
    local evidence = qa_history.qa_evidence
    local verdict = evidence and evidence.verdict
    if not verdict or verdict.verdict ~= "rejected"
        or assessment.progress.candidate_seal_id ~= verdict.candidate_seal_id
        or assessment.progress.verdict_id ~= verdict.verdict_id then
        return nil, "QA-rejected assessment contradicts frozen verdict"
    end
    for _, required in ipairs({
        corpse.corpse_id,
        corpse.corpse_hash,
        corpse.terminal_trace_ref,
        corpse.manifest_trace_ref,
        evidence.qa_contract_id,
        evidence.request_id,
        evidence.request_ref,
        evidence.check and evidence.check.qa_check_id,
        evidence.check_ref,
        verdict.verdict_id,
        evidence.verdict_ref,
    }) do
        if type(required) ~= "string"
            or not contains_ref(assessment.evidence_refs, required) then
            return nil, "QA-rejected assessment omits frozen evidence"
        end
    end
    for _, required in ipairs(evidence.source_refs or {}) do
        if not contains_ref(assessment.evidence_refs, required) then
            return nil, "QA-rejected assessment omits QA source ref"
        end
    end
    return true
end

local function build_qa_history(source)
    local evidence = source.qa_evidence
    if type(evidence) ~= "table" then return nil end
    if evidence.request_id == nil and evidence.check == nil
        and evidence.execution_failure == nil and evidence.verdict == nil
        and evidence.terminal_projection == nil then
        return nil
    end
    local valid, valid_err = qa_evidence_schema.verify_corpse_evidence(evidence)
    if not valid then return nil, valid_err end
    local refs = {
        source.corpse_id,
        source.corpse_hash,
        source.packet_id,
    }
    for _, ref in ipairs(evidence.source_refs or {}) do refs[#refs + 1] = ref end
    return {
        protocol_version = "carrier.qa_history.v1",
        source_corpse_id = source.corpse_id,
        source_corpse_hash = source.corpse_hash,
        source_packet_id = source.packet_id,
        source_generation = source.generation,
        qa_evidence = copy_value(evidence),
        source_refs = unique_refs(refs),
        event_truth_status = "runtime_confirmed",
        applicability_truth_status = "inherited_proposal",
    }
end

local function verify_qa_history(value, record)
    local exact, exact_err = exact_keys(
        value,
        qa_history_keys,
        "carrier QA history"
    )
    if not exact then return nil, exact_err end
    if value.protocol_version ~= "carrier.qa_history.v1"
        or value.source_corpse_id ~= record.source_corpse_id
        or value.source_packet_id ~= record.source_packet_id
        or value.source_generation ~= record.source_generation
        or type(value.source_corpse_hash) ~= "string"
        or #value.source_corpse_hash ~= 64
        or value.event_truth_status ~= "runtime_confirmed"
        or value.applicability_truth_status ~= "inherited_proposal" then
        return nil, "invalid carrier QA history coordinates"
    end
    local evidence_ok, evidence_err =
        qa_evidence_schema.verify_corpse_evidence(value.qa_evidence)
    if not evidence_ok then return nil, evidence_err end
    if not qa_schema.same(
            record.payload.prior_manifest
                and record.payload.prior_manifest.qa_terminal_projection,
            value.qa_evidence.terminal_projection
        ) then
        return nil, "carrier QA history contradicts prior manifest"
    end
    local expected_refs = unique_refs(value.source_refs)
    if not qa_schema.same(expected_refs, value.source_refs) then
        return nil, "carrier QA history refs are not normalized"
    end
    local required_refs = {
        value.source_corpse_id,
        value.source_corpse_hash,
        value.source_packet_id,
    }
    for _, ref in ipairs(value.qa_evidence.source_refs or {}) do
        required_refs[#required_refs + 1] = ref
    end
    for _, required in ipairs(required_refs) do
        local present = false
        for _, ref in ipairs(value.source_refs) do
            if ref == required then present = true break end
        end
        if not present then return nil, "carrier QA history omits source ref" end
    end
    return true
end

function carrier.build_recovery(lineage, corpse, assessment, options)
    options = options or {}
    if type(lineage) ~= "table" or lineage.kind ~= "proc17_lineage"
        or type(corpse) ~= "table" or corpse.kind ~= "proc17_corpse"
        or type(assessment) ~= "table" or assessment.kind ~= "lineage_completion_assessment" then
        return nil, "recovery carrier requires lineage, corpse and assessment"
    end
    if assessment.task_state ~= "unfinished"
        or assessment.terminal_recoverable ~= true
        or type(assessment.terminal_recovery_basis) ~= "string"
        or corpse.corpse_id ~= lineage.current_corpse_id
        or corpse.lineage_id ~= lineage.lineage_id then
        return nil, "terminal assessment cannot produce a recovery carrier"
    end
    local corpse_valid, corpse_err = corpse_module.verify(corpse)
    if not corpse_valid then return nil, corpse_err end
    local max_bytes = options.max_bytes
        or lineage.policy and lineage.policy.carrier and lineage.policy.carrier.max_bytes
    if type(max_bytes) ~= "number" or max_bytes < 1 or max_bytes ~= math.floor(max_bytes) then
        return nil, "carrier max_bytes must be integer >= 1"
    end
    local qa_history, qa_history_err = build_qa_history(corpse)
    if qa_history_err then return nil, qa_history_err end
    if assessment.terminal_recovery_basis == "qa_rejected" then
        local exact, exact_err = verify_qa_rejected_assessment(
            corpse,
            assessment,
            qa_history
        )
        if not exact then return nil, exact_err end
    end
    local payload = {
        original_task = lineage.task.payload,
        prior_manifest = copy_value(corpse.manifest),
        residue = copy_value(corpse.residue or {}),
        remaining_work = copy_value(assessment.remaining_work or {}),
        source_generation = corpse.generation,
        process_contract_id = corpse.process_contract_id,
        context = corpse.context,
        stage_id = corpse.stage_id,
        qa_contract_id = corpse.qa_contract_id,
        qa_contract = copy_value(corpse.qa_contract),
        qa_history = copy_value(qa_history),
    }
    local encoded_ok, encoded = pcall(json.encode, payload)
    if not encoded_ok then
        return nil, "carrier payload encoding failed: " .. tostring(encoded)
    end
    if #encoded > max_bytes then
        return nil, "carrier_too_large"
    end
    local target_generation = corpse.generation + 1
    local carrier_id = options.carrier_id
    if carrier_id == nil and type(options.id_source) == "function" then
        carrier_id = options.id_source("carrier", corpse, target_generation)
    end
    carrier_id = carrier_id
        or ("carrier:" .. corpse.corpse_id .. ":" .. tostring(target_generation))
    if type(carrier_id) ~= "string" or carrier_id == "" then
        return nil, "carrier id is required"
    end
    local record = {
        kind = "proc17_lineage_carrier",
        protocol_version = carrier.protocol_version,
        carrier_id = carrier_id,
        carrier_hash = nil,
        lineage_id = lineage.lineage_id,
        source_packet_id = corpse.packet_id,
        source_corpse_id = corpse.corpse_id,
        source_generation = corpse.generation,
        target_generation = target_generation,
        carrier_class = "recovery",
        media_type = "application/vnd.proc17.recovery+json",
        payload = payload,
        payload_bytes = #encoded,
        source_refs = {
            corpse.corpse_id,
            corpse.terminal_trace_ref,
            assessment.assessment_id,
        },
        semantic_truth_status = lineage.task.content_truth_status,
        applicability_truth_status = "reentry_proposal",
        materialization_loss = {
            kind = "bounded_carrier_projection",
            amount = 0,
            truncated = false,
        },
        substrate_session_id = lineage.substrate_session_id,
        created_at = options.time or corpse.frozen_at,
    }
    local hash, hash_err = digest.record(identity_projection(record))
    if not hash then
        return nil, hash_err
    end
    record.carrier_hash = hash
    return record
end

function carrier.verify(record, context)
    if type(record) ~= "table" or record.kind ~= "proc17_lineage_carrier"
        or record.protocol_version ~= carrier.protocol_version
        or type(record.carrier_id) ~= "string" or record.carrier_id == ""
        or type(record.carrier_hash) ~= "string" or #record.carrier_hash ~= 64
        or type(record.lineage_id) ~= "string" or record.lineage_id == ""
        or type(record.source_packet_id) ~= "string"
        or type(record.source_corpse_id) ~= "string"
        or type(record.source_generation) ~= "number"
        or record.target_generation ~= record.source_generation + 1
        or record.carrier_class ~= "recovery"
        or type(record.payload) ~= "table"
        or type(record.payload_bytes) ~= "number"
        or record.applicability_truth_status ~= "reentry_proposal" then
        return nil, "invalid recovery carrier"
    end
    local payload = record.payload
    if (payload.qa_contract_id == nil) ~= (payload.qa_contract == nil) then
        return nil, "invalid recovery carrier QA contract"
    end
    if payload.qa_contract ~= nil then
        local normalized, normalized_err = qa_schema.normalize_contract(payload.qa_contract)
        if not normalized then
            return nil, "invalid recovery carrier QA contract: "
                .. tostring(normalized_err)
        end
        if not qa_schema.same(payload.qa_contract, normalized)
            or payload.qa_contract_id ~= normalized.qa_contract_id
            or normalized.lineage_id ~= record.lineage_id
            or normalized.process_contract_id ~= payload.process_contract_id
            or normalized.context ~= payload.context
            or normalized.stage_id ~= payload.stage_id then
            return nil, "invalid recovery carrier QA contract"
        end
    end
    if payload.qa_history ~= nil then
        local history_ok, history_err = verify_qa_history(
            payload.qa_history,
            record
        )
        if not history_ok then return nil, history_err end
    elseif payload.prior_manifest
        and payload.prior_manifest.qa_terminal_projection ~= nil then
        return nil, "recovery carrier omitted QA history"
    end
    local encoded_ok, encoded = pcall(json.encode, record.payload)
    if not encoded_ok or record.payload_bytes ~= #encoded then
        return nil, "invalid recovery carrier"
    end
    local actual, actual_err = digest.record(identity_projection(record))
    if not actual then
        return nil, actual_err
    end
    if actual ~= record.carrier_hash then
        return nil, "carrier hash mismatch"
    end
    context = context or {}
    if context.lineage_id ~= nil and context.lineage_id ~= record.lineage_id then
        return nil, "carrier lineage mismatch"
    end
    if context.source_corpse_id ~= nil
        and context.source_corpse_id ~= record.source_corpse_id then
        return nil, "carrier source corpse mismatch"
    end
    if context.target_generation ~= nil
        and context.target_generation ~= record.target_generation then
        return nil, "carrier target generation mismatch"
    end
    if context.max_bytes ~= nil and record.payload_bytes > context.max_bytes then
        return nil, "carrier_too_large"
    end
    return true
end

return carrier
