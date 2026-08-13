local digest = require("core.digest")
local qa_evidence_schema = require("core.qa_evidence_schema")
local qa_schema = require("core.qa_schema")
local corpse_module = require("runtime.corpse")

local completion = {
    protocol_version = "lineage.completion.v0",
}

local RECOVERABLE_TERMINALS = {
    budget_exhausted = true,
    identity_loss = true,
    stalled = true,
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

local function event_by_id(events, id)
    for _, event in ipairs(events or {}) do
        if event.id == id then
            return event
        end
    end
    return nil
end

local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end
    return false
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

local function append_all(target, values)
    for _, value in ipairs(values or {}) do
        target[#target + 1] = value
    end
end

local function require_refs(haystack, required, label)
    for _, ref in ipairs(required or {}) do
        if type(ref) == "string" and ref ~= "" and not contains(haystack, ref) then
            return nil, label .. " omits required ref: " .. ref
        end
    end
    return true
end

local function exact_plan(corpse)
    local manifest = corpse.manifest
    local output = manifest and manifest.output
    local structured = output and output.structured
    local assembly = manifest and manifest.assembly
    if corpse.terminal_kind ~= "manifest" or corpse.death_cause ~= "complete"
        or type(manifest) ~= "table" or manifest.mode ~= "plan_delivery"
        or type(output) ~= "table" or output.type ~= "plan" or output.status ~= "complete"
        or type(structured) ~= "table" or structured.protocol_version ~= "plan.result.v0"
        or type(assembly) ~= "table" or assembly.rule ~= "plan_delivery.v0"
        or assembly.input_provenance ~= "packet_state"
        or type(assembly.assessment_ref) ~= "string" then
        return nil, "exact plan manifest is absent"
    end
    if not contains(corpse.completion_evidence_refs, assembly.assessment_ref)
        or corpse.manifest_trace_ref == nil
        or not contains(corpse.completion_evidence_refs, corpse.manifest_trace_ref) then
        return nil, "exact plan evidence refs are incomplete"
    end
    local assessment = event_by_id(corpse.trace_tail, assembly.assessment_ref)
    local payload = assessment and assessment.payload
    if not assessment or assessment.type ~= "plan_completion_assessment"
        or assessment.operator ~= "☱" or assessment.truth_status ~= "runtime_confirmed"
        or type(payload) ~= "table"
        or payload.protocol_version ~= "plan.completion_assessment.v0"
        or payload.state ~= "complete"
        or payload.work_mode ~= "plan"
        or payload.event_truth_status ~= "runtime_confirmed" then
        return nil, "exact plan assessment is absent"
    end
    return true, assessment
end

local function exact_software_qa_terminal(lineage, corpse)
    local manifest = corpse.manifest
    local evidence = corpse.qa_evidence
    local manifest_claim = type(manifest) == "table"
        and manifest.mode == "qa_terminal_delivery"
    local evidence_claim = type(evidence) == "table"
        and evidence.terminal_projection ~= nil

    if not manifest_claim and not evidence_claim then
        return nil, "absent"
    end
    if not manifest_claim or not evidence_claim then
        return nil, nil, "QA terminal claim is incomplete"
    end
    if lineage.completion_contract_id ~= "software.create.v0"
        or lineage.work_mode ~= "build"
        or lineage.current_generation ~= corpse.generation
        or corpse.process_contract_id ~= "software.create.v0"
        or corpse.context ~= "software_task.v0"
        or corpse.work_mode ~= "build"
        or corpse.terminal_kind ~= "manifest"
        or type(corpse.stage_id) ~= "string" or corpse.stage_id == "" then
        return nil, nil, "QA terminal claim contradicts software lineage coordinates"
    end

    local normalized, normalized_err =
        qa_evidence_schema.normalize_corpse_evidence(evidence)
    if not normalized or not qa_schema.same(normalized, evidence) then
        return nil, nil, normalized_err or "corpse QA evidence is not normalized"
    end
    local check = normalized.check
    local verdict = normalized.verdict
    local projection = normalized.terminal_projection
    if normalized.execution_failure ~= nil
        or check == nil or verdict == nil or projection == nil then
        return nil, nil, "QA terminal claim lacks exact check/verdict projection"
    end

    local expected_cause = projection.verdict == "accepted"
        and "complete" or "blocked"
    if (projection.verdict ~= "accepted" and projection.verdict ~= "rejected")
        or check.outcome ~= projection.verdict
        or verdict.verdict ~= projection.verdict
        or corpse.death_cause ~= expected_cause
        or manifest.terminal_cause ~= expected_cause
        or type(manifest.output) ~= "table"
        or manifest.output.type ~= "qa_terminal"
        or manifest.output.status ~= projection.verdict
        or type(manifest.assembly) ~= "table"
        or manifest.assembly.rule ~= "qa.terminal_projection.v1"
        or manifest.assembly.work_mode ~= "build"
        or manifest.assembly.input_provenance ~= "packet_state"
        or manifest.assembly.outcome ~= projection.verdict
        or manifest.assembly.verdict_ref ~= normalized.verdict_ref
        or not qa_schema.same(manifest.qa_terminal_projection, projection) then
        return nil, nil, "QA terminal manifest contradicts exact evidence"
    end

    for _, body_record in ipairs({check, verdict}) do
        if body_record.packet_id ~= corpse.packet_id
            or body_record.lineage_id ~= corpse.lineage_id
            or body_record.generation ~= corpse.generation
            or body_record.process_contract_id ~= corpse.process_contract_id
            or body_record.context ~= corpse.context
            or body_record.stage_id ~= corpse.stage_id
            or body_record.repository_id ~= corpse.repository_id
            or body_record.qa_contract_id ~= corpse.qa_contract_id then
            return nil, nil, "QA terminal body coordinates contradict corpse"
        end
    end
    if check.candidate_seal_id ~= verdict.candidate_seal_id
        or check.candidate_seal_id ~= projection.candidate_seal_id
        or check.candidate_seal_event_ref ~= verdict.candidate_seal_event_ref
        or check.candidate_seal_event_ref ~= projection.candidate_seal_event_ref
        or check.artifact_alignment_id ~= verdict.artifact_alignment_id
        or check.artifact_alignment_id ~= projection.artifact_alignment_id
        or check.profile_id ~= verdict.profile_id
        or check.profile_id ~= projection.profile_id
        or check.environment_id ~= verdict.environment_id
        or check.environment_id ~= projection.environment_id
        or check.request_id ~= normalized.request_id
        or check.request_ref ~= normalized.request_ref
        or check.qa_check_id ~= projection.qa_check_id
        or normalized.check_ref ~= projection.qa_check_ref
        or verdict.verdict_id ~= projection.verdict_id
        or normalized.verdict_ref ~= projection.verdict_ref then
        return nil, nil, "QA terminal identity join is inconsistent"
    end

    local retained = corpse.completion_evidence_refs or {}
    local retention_ok, retention_err = require_refs(retained, {
        corpse.terminal_trace_ref,
        corpse.manifest_trace_ref,
    }, "QA terminal corpse")
    if not retention_ok then
        return nil, nil, retention_err
    end
    retention_ok, retention_err = require_refs(
        retained,
        normalized.source_refs,
        "QA terminal corpse"
    )
    if not retention_ok then
        return nil, nil, retention_err
    end
    retention_ok, retention_err = require_refs(
        retained,
        projection.source_refs,
        "QA terminal corpse"
    )
    if not retention_ok then
        return nil, nil, retention_err
    end

    return projection.verdict, normalized
end

local function qa_assessment_refs(corpse, evidence)
    local check = evidence.check
    local verdict = evidence.verdict
    local projection = evidence.terminal_projection
    local refs = {
        corpse.corpse_id,
        corpse.corpse_hash,
        corpse.terminal_trace_ref,
        corpse.manifest_trace_ref,
        evidence.qa_contract_id,
        evidence.request_id,
        evidence.request_ref,
        check and check.candidate_seal_id,
        check and check.candidate_seal_event_ref,
        check and check.artifact_alignment_id,
        check and check.qa_check_id,
        evidence.check_ref,
        verdict and verdict.verdict_id,
        evidence.verdict_ref,
    }
    append_all(refs, evidence.source_refs)
    append_all(refs, projection and projection.source_refs)
    return sorted_unique(refs)
end

local function qa_basis_truth_statuses(evidence)
    local values = {"runtime_confirmed"}
    for _, status in ipairs({
        evidence.check and evidence.check.content_truth_status,
        evidence.verdict and evidence.verdict.content_truth_status,
        evidence.terminal_projection
            and evidence.terminal_projection.content_truth_status,
    }) do
        if status ~= nil and not contains(values, status) then
            values[#values + 1] = status
        end
    end
    return values
end

local function build_assessment(lineage, corpse, input)
    local record = {
        kind = "lineage_completion_assessment",
        protocol_version = completion.protocol_version,
        assessment_id = nil,
        contract_id = lineage.completion_contract_id,
        task_state = input.task_state,
        terminal_recoverable = input.terminal_recoverable == true,
        terminal_recovery_basis = input.terminal_recovery_basis,
        progress = copy_value(input.progress or {}),
        remaining_work = copy_value(input.remaining_work or {}),
        evidence_refs = copy_value(input.evidence_refs or {}),
        manifest_refs = copy_value(input.manifest_refs or {}),
        missing_requirements = copy_value(input.missing_requirements or {}),
        event_truth_status = "runtime_confirmed",
        basis_truth_statuses = copy_value(input.basis_truth_statuses or {
            corpse.truth_status,
        }),
    }
    local hash, hash_err = digest.record(record)
    if not hash then
        return nil, hash_err
    end
    record.assessment_id = "lineage-assessment:" .. hash
    return record
end

function completion.evaluate(lineage, corpse)
    if type(lineage) ~= "table" or lineage.kind ~= "proc17_lineage"
        or type(corpse) ~= "table" or corpse.kind ~= "proc17_corpse" then
        return nil, "lineage and corpse are required for completion"
    end
    local verified, verify_err = corpse_module.verify(corpse)
    if not verified then
        return nil, verify_err
    end
    if corpse.lineage_id ~= lineage.lineage_id
        or corpse.packet_id ~= lineage.current_packet_id
        or corpse.corpse_id ~= lineage.current_corpse_id then
        return nil, "completion corpse is not current lineage terminal"
    end

    if corpse.death_cause == "unsafe_scope" or corpse.death_cause == "cancelled" then
        return build_assessment(lineage, corpse, {
            task_state = "unsafe",
            evidence_refs = {corpse.terminal_trace_ref},
            missing_requirements = {"safe continuation"},
        })
    end

    if lineage.completion_contract_id == "plan.v0" then
        local complete, assessment_or_err = exact_plan(corpse)
        if complete then
            local plan_assessment = assessment_or_err
            return build_assessment(lineage, corpse, {
                task_state = "complete",
                progress = {
                    delivered_item_count = #(corpse.manifest.output.structured.items or {}),
                    generation = corpse.generation,
                },
                evidence_refs = {
                    corpse.terminal_trace_ref,
                    plan_assessment.id,
                    corpse.manifest.assembly.assessment_ref,
                },
                manifest_refs = {corpse.manifest_trace_ref},
                basis_truth_statuses = {
                    "runtime_confirmed",
                    corpse.manifest.content_truth_status or "unknown",
                },
            })
        end
    elseif lineage.completion_contract_id == "software.create.v0" then
        local qa_outcome, evidence_or_absent, qa_err =
            exact_software_qa_terminal(lineage, corpse)
        if qa_err then
            return nil, qa_err
        end
        if qa_outcome == "rejected" then
            local evidence = evidence_or_absent
            return build_assessment(lineage, corpse, {
                task_state = "unfinished",
                terminal_recoverable = true,
                terminal_recovery_basis = "qa_rejected",
                progress = {
                    rejected_generation = corpse.generation,
                    candidate_seal_id = evidence.verdict.candidate_seal_id,
                    verdict_id = evidence.verdict.verdict_id,
                },
                remaining_work = {
                    count = 1,
                    kind = "fresh_candidate_generation",
                    stage_id = corpse.stage_id,
                },
                evidence_refs = qa_assessment_refs(corpse, evidence),
                manifest_refs = {corpse.manifest_trace_ref},
                missing_requirements = {},
                basis_truth_statuses = qa_basis_truth_statuses(evidence),
            })
        end
        if qa_outcome == "accepted" then
            local evidence = evidence_or_absent
            return build_assessment(lineage, corpse, {
                task_state = "unknown",
                progress = {
                    accepted_generation = corpse.generation,
                    candidate_seal_id = evidence.verdict.candidate_seal_id,
                    verdict_id = evidence.verdict.verdict_id,
                },
                evidence_refs = qa_assessment_refs(corpse, evidence),
                manifest_refs = {corpse.manifest_trace_ref},
                missing_requirements = {"lineage_software_scope_reader"},
                basis_truth_statuses = qa_basis_truth_statuses(evidence),
            })
        end
    else
        return build_assessment(lineage, corpse, {
            task_state = "unknown",
            evidence_refs = {corpse.terminal_trace_ref},
            missing_requirements = {
                "known completion contract: " .. tostring(lineage.completion_contract_id),
            },
        })
    end

    local terminal_recoverable = RECOVERABLE_TERMINALS[corpse.death_cause] == true
    return build_assessment(lineage, corpse, {
        task_state = terminal_recoverable and "unfinished" or "blocked",
        terminal_recoverable = terminal_recoverable,
        terminal_recovery_basis = terminal_recoverable and corpse.death_cause or nil,
        progress = copy_value(corpse.residue and corpse.residue.progress or {}),
        remaining_work = {
            count = corpse.residue and corpse.residue.remaining_work_count,
        },
        evidence_refs = {corpse.terminal_trace_ref},
        missing_requirements = terminal_recoverable
            and {} or {"recoverable terminal state"},
    })
end

return completion
