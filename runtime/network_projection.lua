local carrier_module = require("runtime.carrier")
local corpse_module = require("runtime.corpse")
local digest = require("core.digest")
local projection_schema = require("core.network_projection_schema")
local qa_evidence_schema = require("core.qa_evidence_schema")
local qa_schema = require("core.qa_schema")

local network_projection = {
    protocol_version = projection_schema.projection_protocol,
}

local assessment_keys = {
    kind = true,
    protocol_version = true,
    assessment_id = true,
    contract_id = true,
    task_state = true,
    terminal_recoverable = true,
    terminal_recovery_basis = true,
    progress = true,
    remaining_work = true,
    evidence_refs = true,
    manifest_refs = true,
    missing_requirements = true,
    event_truth_status = true,
    basis_truth_statuses = true,
}

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

local function copy_value(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

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

local function sorted_unique(values)
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

local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then return true end
    end
    return false
end

local function append_all(target, values)
    for _, value in ipairs(values or {}) do target[#target + 1] = value end
end

local function event_by_id(events, id)
    for _, event in ipairs(events or {}) do
        if event.id == id then return event end
    end
    return nil
end

local function same_set(left, right)
    return qa_schema.same(sorted_unique(left), sorted_unique(right))
end

local function bare_digest(value)
    return type(value) == "string" and #value == 64
        and value:match("^[0-9a-f]+$") ~= nil
end

local function verify_rejected_assessment(assessment, lineage, corpse)
    local exact, exact_err = exact_keys(
        assessment,
        assessment_keys,
        "QA-rejected completion assessment"
    )
    if not exact then return nil, exact_err end
    if assessment.kind ~= "lineage_completion_assessment"
        or assessment.protocol_version ~= "lineage.completion.v0"
        or assessment.contract_id ~= "software.create.v0"
        or assessment.task_state ~= "unfinished"
        or assessment.terminal_recoverable ~= true
        or assessment.terminal_recovery_basis ~= "qa_rejected"
        or assessment.event_truth_status ~= "runtime_confirmed"
        or type(assessment.progress) ~= "table"
        or assessment.progress.rejected_generation ~= corpse.generation
        or type(assessment.progress.candidate_seal_id) ~= "string"
        or type(assessment.progress.verdict_id) ~= "string"
        or type(assessment.remaining_work) ~= "table"
        or assessment.remaining_work.count ~= 1
        or assessment.remaining_work.kind ~= "fresh_candidate_generation"
        or assessment.remaining_work.stage_id ~= corpse.stage_id
        or type(assessment.evidence_refs) ~= "table"
        or type(assessment.manifest_refs) ~= "table"
        or #assessment.manifest_refs ~= 1
        or assessment.manifest_refs[1] ~= corpse.manifest_trace_ref
        or type(assessment.missing_requirements) ~= "table"
        or #assessment.missing_requirements ~= 0
        or type(assessment.basis_truth_statuses) ~= "table" then
        return nil, "QA-rejected completion assessment is invalid"
    end
    local projected = copy_value(assessment)
    projected.assessment_id = nil
    local hash, hash_err = digest.record(projected)
    if not hash then return nil, hash_err end
    if assessment.assessment_id ~= "lineage-assessment:" .. hash then
        return nil, "QA-rejected completion assessment identity mismatch"
    end
    for _, ref in ipairs({
        corpse.corpse_id,
        corpse.corpse_hash,
        corpse.terminal_trace_ref,
        corpse.manifest_trace_ref,
        assessment.progress.candidate_seal_id,
        assessment.progress.verdict_id,
    }) do
        if not contains(assessment.evidence_refs, ref) then
            return nil, "QA-rejected completion assessment omits exact evidence"
        end
    end
    return true
end

local function verify_assessment_event(event, assessment, lineage, corpse)
    if type(event) ~= "table" or type(event.id) ~= "string"
        or event.kind ~= "completion_evaluated"
        or event.lineage_id ~= lineage.lineage_id
        or event.generation ~= corpse.generation
        or event.packet_id ~= corpse.packet_id
        or event.corpse_id ~= corpse.corpse_id
        or event.event_truth_status ~= "runtime_confirmed"
        or not qa_schema.same(event.payload, assessment)
        or not same_set(event.source_refs, assessment.evidence_refs)
        or not qa_schema.same(
            event.content_truth_statuses,
            assessment.basis_truth_statuses
        ) then
        return nil, "completion event does not bind the exact assessment"
    end
    return true
end

local function normalize_history(history, context)
    local exact, exact_err = exact_keys(
        history,
        qa_history_keys,
        "carrier QA history"
    )
    if not exact then return nil, exact_err end
    if history.protocol_version ~= "carrier.qa_history.v1"
        or not bare_digest(history.source_corpse_hash)
        or type(history.source_generation) ~= "number"
        or history.source_generation < 1
        or history.source_generation ~= math.floor(history.source_generation)
        or history.event_truth_status ~= "runtime_confirmed"
        or history.applicability_truth_status ~= "inherited_proposal" then
        return nil, "carrier QA history coordinates are invalid"
    end
    local evidence, evidence_err =
        qa_evidence_schema.normalize_corpse_evidence(history.qa_evidence)
    if not evidence or not qa_schema.same(evidence, history.qa_evidence) then
        return nil, evidence_err or "carrier QA history evidence is not normalized"
    end
    local refs = sorted_unique(history.source_refs)
    if not qa_schema.same(refs, history.source_refs) then
        return nil, "carrier QA history refs are not normalized"
    end
    local required_refs = {
        history.source_corpse_id,
        history.source_corpse_hash,
        history.source_packet_id,
    }
    append_all(required_refs, evidence.source_refs)
    for _, ref in ipairs(required_refs) do
        if not contains(refs, ref) then
            return nil, "carrier QA history omits source identity"
        end
    end
    context = context or {}
    if context.source_corpse_id ~= nil
        and history.source_corpse_id ~= context.source_corpse_id then
        return nil, "carrier QA history source corpse mismatch"
    end
    if context.source_corpse_hash ~= nil
        and history.source_corpse_hash ~= context.source_corpse_hash then
        return nil, "carrier QA history source hash mismatch"
    end
    if context.source_packet_id ~= nil
        and history.source_packet_id ~= context.source_packet_id then
        return nil, "carrier QA history source Packet mismatch"
    end
    if context.source_generation ~= nil
        and history.source_generation ~= context.source_generation then
        return nil, "carrier QA history source generation mismatch"
    end
    local normalized = copy_value(history)
    normalized.qa_evidence = evidence
    normalized.source_refs = refs
    return normalized
end

local function history_identity(history)
    local hash, hash_err = digest.record(history)
    if not hash then return nil, hash_err end
    return "qa-history:" .. hash
end

function network_projection.qa_subprojection(history, context)
    if history == nil then return nil, "absent" end
    local normalized, normalized_err = normalize_history(history, context)
    if not normalized then return nil, normalized_err end
    local evidence = normalized.qa_evidence
    if evidence.execution_failure ~= nil then
        if evidence.check ~= nil or evidence.verdict ~= nil
            or evidence.terminal_projection ~= nil then
            return nil, "QA infrastructure history contains candidate truth"
        end
        return nil, "execution_failure"
    end
    if evidence.check == nil and evidence.verdict == nil
        and evidence.terminal_projection == nil then
        return nil, "absent"
    end
    if evidence.check == nil or evidence.verdict == nil then
        return nil, "QA history has no complete candidate verdict"
    end
    if evidence.terminal_projection == nil then
        return nil, "QA verdict has no terminal projection"
    end
    if evidence.check.outcome ~= evidence.verdict.verdict
        or evidence.verdict.verdict ~= evidence.terminal_projection.verdict then
        return nil, "QA history terminal join is contradictory"
    end
    if evidence.verdict.verdict == "accepted" then
        return nil, "accepted"
    end
    if evidence.verdict.verdict ~= "rejected" then
        return nil, "QA history verdict is unsupported"
    end

    context = context or {}
    local target_generation = context.target_generation
        or (normalized.source_generation + 1)
    local terminal_manifest_ref = context.terminal_manifest_ref
    if type(terminal_manifest_ref) ~= "string" or terminal_manifest_ref == ""
        or target_generation ~= normalized.source_generation + 1 then
        return nil, "rejected-form target boundary is incomplete"
    end
    local historical_qa_id, identity_err = history_identity(normalized)
    if not historical_qa_id then return nil, identity_err end
    local check = evidence.check
    local verdict = evidence.verdict
    local terminal = evidence.terminal_projection
    local refs = {
        normalized.source_packet_id,
        normalized.source_corpse_id,
        normalized.source_corpse_hash,
        historical_qa_id,
        verdict.candidate_seal_id,
        verdict.candidate_seal_event_ref,
        verdict.artifact_alignment_id,
        verdict.qa_contract_id,
        verdict.verdict_id,
        evidence.verdict_ref,
        check.qa_check_id,
        evidence.check_ref,
        terminal_manifest_ref,
    }
    append_all(refs, terminal.source_refs)
    local form, form_err = projection_schema.normalize_rejected_form({
        protocol_version = projection_schema.rejected_form_protocol,
        source_packet_id = normalized.source_packet_id,
        source_corpse_id = normalized.source_corpse_id,
        source_corpse_hash = normalized.source_corpse_hash,
        source_generation = normalized.source_generation,
        target_generation = target_generation,
        historical_qa_id = historical_qa_id,
        candidate_seal_id = verdict.candidate_seal_id,
        candidate_seal_event_ref = verdict.candidate_seal_event_ref,
        artifact_alignment_id = verdict.artifact_alignment_id,
        qa_contract_id = verdict.qa_contract_id,
        verdict_id = verdict.verdict_id,
        verdict_ref = evidence.verdict_ref,
        rejected_check_ids = verdict.check_ids,
        rejected_check_refs = verdict.check_refs,
        failure_summary = {
            check_reason = terminal.check_reason,
            termination = terminal.termination,
            cause = terminal.cause,
            finality = terminal.finality,
        },
        terminal_manifest_ref = terminal_manifest_ref,
        source_refs = sorted_unique(refs),
        event_truth_status = "runtime_confirmed",
        applicability_truth_status = "inherited_proposal",
    })
    if not form then return nil, form_err end
    return form, "rejected"
end

local function verify_input_tuple(lineage, corpse, event, carrier, options)
    if type(lineage) ~= "table" or lineage.kind ~= "proc17_lineage"
        or lineage.completion_contract_id ~= "software.create.v0"
        or lineage.work_mode ~= "build"
        or lineage.current_generation ~= corpse.generation
        or lineage.current_packet_id ~= corpse.packet_id
        or lineage.current_corpse_id ~= corpse.corpse_id then
        return nil, "NETWORK projection lineage boundary is invalid"
    end
    local corpse_ok, corpse_err = corpse_module.verify(corpse)
    if not corpse_ok then return nil, corpse_err end
    local assessment = event and event.payload
    local assessment_ok, assessment_err = verify_rejected_assessment(
        assessment,
        lineage,
        corpse
    )
    if not assessment_ok then return nil, assessment_err end
    local event_ok, event_err = verify_assessment_event(
        event,
        assessment,
        lineage,
        corpse
    )
    if not event_ok then return nil, event_err end
    local stored_event = event_by_id(lineage.ledger, event.id)
    if not stored_event or not qa_schema.same(stored_event, event) then
        return nil, "completion event is not present at the lineage ledger head"
    end
    local max_bytes = options and options.max_carrier_bytes
        or lineage.policy and lineage.policy.carrier
            and lineage.policy.carrier.max_bytes
    local carrier_ok, carrier_err = carrier_module.verify(carrier, {
        lineage_id = lineage.lineage_id,
        source_corpse_id = corpse.corpse_id,
        target_generation = corpse.generation + 1,
        max_bytes = max_bytes,
    })
    if not carrier_ok then return nil, carrier_err end
    if carrier.source_packet_id ~= corpse.packet_id
        or carrier.source_generation ~= corpse.generation
        or carrier.payload.source_generation ~= corpse.generation
        or carrier.payload.original_task ~= lineage.task.payload
        or carrier.payload.process_contract_id ~= corpse.process_contract_id
        or carrier.payload.context ~= corpse.context
        or carrier.payload.stage_id ~= corpse.stage_id
        or not qa_schema.same(carrier.payload.remaining_work, assessment.remaining_work)
        or not qa_schema.same(carrier.payload.prior_manifest, corpse.manifest)
        or not contains(carrier.source_refs, assessment.assessment_id) then
        return nil, "recovery carrier contradicts projection source tuple"
    end
    return assessment
end

function network_projection.derive(lineage, corpse, assessment_event, carrier, options)
    options = options or {}
    local assessment, input_err = verify_input_tuple(
        lineage,
        corpse,
        assessment_event,
        carrier,
        options
    )
    if not assessment then return nil, input_err end
    local carrier_ceiling = options.max_carrier_bytes
        or lineage.policy and lineage.policy.carrier
            and lineage.policy.carrier.max_bytes
    local current_work_ceiling = options.max_current_work_bytes
        or math.min(
            projection_schema.bounds.max_current_work_bytes,
            carrier_ceiling
        )
    if current_work_ceiling > carrier_ceiling then
        return nil, "NETWORK current-work ceiling exceeds carrier ceiling"
    end
    local history = carrier.payload.qa_history
    local rejected_form, form_status = network_projection.qa_subprojection(
        history,
        {
            source_corpse_id = corpse.corpse_id,
            source_corpse_hash = corpse.corpse_hash,
            source_packet_id = corpse.packet_id,
            source_generation = corpse.generation,
            target_generation = carrier.target_generation,
            terminal_manifest_ref = corpse.manifest_trace_ref,
        }
    )
    if not rejected_form then
        return nil, "QA-rejected continuation has no exact rejected form: "
            .. tostring(form_status)
    end
    local historical_qa_id = rejected_form.historical_qa_id
    local work_refs = sorted_unique({
        carrier.carrier_id,
        carrier.carrier_hash,
        corpse.corpse_id,
        corpse.corpse_hash,
        assessment.assessment_id,
        assessment_event.id,
        corpse.manifest_trace_ref,
    })
    local current_work, work_err = projection_schema.normalize_current_work({
        protocol_version = projection_schema.current_work_protocol,
        original_task = lineage.task.payload,
        remaining_work = assessment.remaining_work,
        prior_generation = corpse.generation,
        continuation_basis = assessment.terminal_recovery_basis,
        process_contract_id = corpse.process_contract_id,
        context = corpse.context,
        stage_id = corpse.stage_id,
        source_refs = work_refs,
        content_truth_status = lineage.task.content_truth_status,
    }, {
        max_current_work_bytes = current_work_ceiling,
    })
    if not current_work then return nil, work_err end
    local refs = copy_value(work_refs)
    refs[#refs + 1] = corpse.packet_id
    refs[#refs + 1] = historical_qa_id
    append_all(refs, rejected_form.source_refs)
    local projection, projection_err = projection_schema.normalize_projection({
        protocol_version = projection_schema.projection_protocol,
        carrier_id = carrier.carrier_id,
        carrier_hash = carrier.carrier_hash,
        lineage_id = lineage.lineage_id,
        source_packet_id = corpse.packet_id,
        source_corpse_id = corpse.corpse_id,
        source_generation = corpse.generation,
        target_generation = carrier.target_generation,
        process_contract_id = corpse.process_contract_id,
        context = corpse.context,
        stage_id = corpse.stage_id,
        completion_assessment_id = assessment.assessment_id,
        completion_event_ref = assessment_event.id,
        terminal_recovery_basis = assessment.terminal_recovery_basis,
        source_manifest_ref = corpse.manifest_trace_ref,
        current_work = current_work,
        rejected_form = rejected_form,
        historical_qa_id = historical_qa_id,
        source_refs = sorted_unique(refs),
        event_truth_status = "runtime_confirmed",
        content_truth_status = "mixed",
    }, {
        max_current_work_bytes = current_work_ceiling,
    })
    if not projection then return nil, projection_err end
    return projection
end

function network_projection.verify(projection, context)
    context = context or {}
    local valid, valid_err = projection_schema.verify_projection(
        projection,
        {max_current_work_bytes = context.max_current_work_bytes}
    )
    if not valid then return nil, valid_err end
    if context.lineage ~= nil and context.corpse ~= nil
        and context.assessment_event ~= nil and context.carrier ~= nil then
        local expected, expected_err = network_projection.derive(
            context.lineage,
            context.corpse,
            context.assessment_event,
            context.carrier,
            context
        )
        if not expected then return nil, expected_err end
        if not projection_schema.same(projection, expected) then
            return nil, "NETWORK projection contradicts exact source tuple"
        end
    else
        local carrier = context.carrier
        local corpse = context.corpse
        if carrier and (projection.carrier_id ~= carrier.carrier_id
                or projection.carrier_hash ~= carrier.carrier_hash
                or projection.target_generation ~= carrier.target_generation) then
            return nil, "NETWORK projection carrier mismatch"
        end
        if corpse and (projection.source_corpse_id ~= corpse.corpse_id
                or projection.source_packet_id ~= corpse.packet_id
                or projection.source_generation ~= corpse.generation
                or projection.source_manifest_ref ~= corpse.manifest_trace_ref) then
            return nil, "NETWORK projection corpse mismatch"
        end
    end
    return true
end

return network_projection
