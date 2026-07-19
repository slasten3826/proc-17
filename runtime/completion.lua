local digest = require("core.digest")
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
