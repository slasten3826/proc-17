local digest = require("core.digest")
local packet_core = require("core.packet")
local qa_evidence = require("runtime.qa_evidence")
local qa_evidence_schema = require("core.qa_evidence_schema")
local qa_schema = require("core.qa_schema")

local corpse = {
    protocol_version = "corpse.v0",
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

local function unique_refs(values)
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

local function append_refs(target, values)
    for _, value in ipairs(values or {}) do target[#target + 1] = value end
end

local function qa_evidence_envelope(instance, manifest)
    local qa_contract_id = instance.qa_contract_id
    local candidate_seal_id
    for _, event in ipairs(instance.trace or {}) do
        if event.type == "qa_check_request" or event.type == "qa_check"
            or event.type == "qa_execution_failure"
            or event.type == "qa_candidate_verdict" then
            local payload = event.payload
            if type(payload) ~= "table" then
                return nil, "corpse encountered malformed QA event"
            end
            if qa_contract_id ~= nil and payload.qa_contract_id ~= qa_contract_id then
                return nil, "corpse QA event contradicts birth contract"
            end
            qa_contract_id = qa_contract_id or payload.qa_contract_id
            if candidate_seal_id ~= nil
                and candidate_seal_id ~= payload.candidate_seal_id then
                return nil, "corpse contains multiple QA candidate seals"
            end
            candidate_seal_id = payload.candidate_seal_id
        end
    end

    local current
    if candidate_seal_id ~= nil then
        local current_err
        current, current_err = qa_evidence.historical(
            instance,
            candidate_seal_id,
            qa_contract_id
        )
        if not current then return nil, current_err end
        if #current.conflicts > 0 then
            return nil, "corpse QA evidence is contradictory: "
                .. table.concat(current.conflicts, ",")
        end
    end

    local refs = {}
    if qa_contract_id then refs[#refs + 1] = qa_contract_id end
    if current then
        for _, ref in ipairs({
            current.request and current.request.request_id,
            current.request_ref,
            current.check and current.check.qa_check_id,
            current.check_ref,
            current.execution_failure and current.execution_failure.failure_id,
            current.execution_failure_ref,
            current.verdict and current.verdict.verdict_id,
            current.verdict_ref,
        }) do
            if ref then refs[#refs + 1] = ref end
        end
        append_refs(refs, current.request and current.request.source_refs)
        append_refs(refs, current.check and current.check.source_refs)
        append_refs(refs, current.execution_failure
            and current.execution_failure.source_refs)
        append_refs(refs, current.verdict and current.verdict.source_refs)
    end
    local terminal_projection = manifest and manifest.qa_terminal_projection
    if terminal_projection ~= nil then
        append_refs(refs, terminal_projection.source_refs)
    end
    if manifest and manifest.mode == "qa_terminal_delivery"
        and terminal_projection == nil then
        return nil, "QA terminal manifest omits its terminal projection"
    end

    return qa_evidence_schema.normalize_corpse_evidence({
        protocol_version = "corpse.qa_evidence.v1",
        qa_contract_id = qa_contract_id,
        request_id = current and current.request and current.request.request_id,
        request_ref = current and current.request_ref,
        check = current and copy_value(current.check),
        check_ref = current and current.check_ref,
        execution_failure = current
            and copy_value(current.execution_failure),
        execution_failure_ref = current and current.execution_failure_ref,
        verdict = current and copy_value(current.verdict),
        verdict_ref = current and current.verdict_ref,
        terminal_projection = copy_value(terminal_projection),
        source_refs = unique_refs(refs),
    })
end

local function identity_projection(record)
    local projected = copy_value(record)
    projected.corpse_hash = nil
    return projected
end

function corpse.capture(instance, options)
    options = options or {}
    if type(instance) ~= "table" or type(instance.id) ~= "string" then
        return nil, "corpse capture requires Packet"
    end
    if instance.status ~= "dead" or type(instance.terminal) ~= "table"
        or type(instance.death) ~= "table" then
        return nil, "corpse capture requires terminal dead Packet"
    end
    local trace_tail_count = options.trace_tail_count or 32
    if type(trace_tail_count) ~= "number" or trace_tail_count < 1
        or trace_tail_count ~= math.floor(trace_tail_count) then
        return nil, "corpse trace_tail_count must be integer >= 1"
    end
    local corpse_id = options.corpse_id
    if corpse_id == nil and type(options.id_source) == "function" then
        corpse_id = options.id_source("corpse", instance)
    end
    corpse_id = corpse_id or ("corpse:" .. instance.id)
    if type(corpse_id) ~= "string" or corpse_id == "" then
        return nil, "corpse id is required"
    end

    local manifest = copy_value(instance.manifest)
    local qa_envelope, qa_envelope_err = qa_evidence_envelope(instance, manifest)
    if not qa_envelope then return nil, qa_envelope_err end
    local evidence_refs = {
        instance.terminal.event_id,
        instance.terminal.manifest_ref,
        manifest and manifest.assembly and manifest.assembly.assessment_ref,
    }
    for _, ref in ipairs(manifest and manifest.effect_scope_refs or {}) do
        evidence_refs[#evidence_refs + 1] = ref
    end
    append_refs(evidence_refs, qa_envelope.source_refs)

    local trace_tail, trace_tail_err = packet_core.body_trace_tail(
        instance.trace,
        trace_tail_count
    )
    if not trace_tail then return nil, trace_tail_err end

    local record = {
        kind = "proc17_corpse",
        protocol_version = corpse.protocol_version,
        corpse_id = corpse_id,
        corpse_hash = nil,
        lineage_id = instance.lineage_id,
        packet_id = instance.id,
        generation = instance.generation,
        work_mode = instance.regime and instance.regime.work
            and instance.regime.work.mode or nil,
        process_contract_id = instance.process_contract_id,
        context = instance.work_context,
        stage_id = instance.stage_id,
        repository_id = instance.repository_id,
        qa_contract_id = instance.qa_contract_id,
        qa_contract = copy_value(instance.qa_contract),
        qa_evidence = qa_envelope,
        parent_packet_id = instance.parent_id,
        parent_corpse_id = instance.parent_corpse_id,
        ingress_carrier_id = instance.carrier_id,
        terminal_kind = instance.terminal.kind,
        death_cause = instance.death.cause,
        manifest = manifest,
        manifest_trace_ref = instance.terminal.manifest_ref,
        residue = copy_value(instance.residue or {}),
        final_loss = copy_value(instance.terminal.loss_snapshot or {}),
        final_budget = copy_value(instance.terminal.budget_snapshot or {}),
        terminal_trace_ref = instance.terminal.event_id,
        trace_tail = trace_tail,
        completion_evidence_refs = unique_refs(evidence_refs),
        frozen_at = instance.death.time,
        truth_status = "runtime_confirmed",
    }
    local hash, hash_err = digest.record(identity_projection(record))
    if not hash then
        return nil, hash_err
    end
    record.corpse_hash = hash
    return record
end

function corpse.verify(record)
    if type(record) ~= "table" or record.kind ~= "proc17_corpse"
        or record.protocol_version ~= corpse.protocol_version
        or type(record.corpse_id) ~= "string" or record.corpse_id == ""
        or type(record.corpse_hash) ~= "string" or #record.corpse_hash ~= 64
        or type(record.packet_id) ~= "string" or record.packet_id == ""
        or type(record.lineage_id) ~= "string" or record.lineage_id == ""
        or type(record.generation) ~= "number" or record.generation < 1
        or record.generation ~= math.floor(record.generation)
        or (record.work_mode ~= nil and record.work_mode ~= "plan"
            and record.work_mode ~= "build")
        or (record.process_contract_id ~= nil
            and type(record.process_contract_id) ~= "string")
        or (record.context ~= nil and type(record.context) ~= "string")
        or (record.stage_id ~= nil and type(record.stage_id) ~= "string")
        or (record.repository_id ~= nil and type(record.repository_id) ~= "string")
        or (record.terminal_kind ~= "manifest" and record.terminal_kind ~= "internal_death")
        or type(record.death_cause) ~= "string"
        or type(record.trace_tail) ~= "table"
        or type(record.completion_evidence_refs) ~= "table"
        or type(record.final_loss) ~= "table"
        or type(record.final_budget) ~= "table"
        or record.truth_status ~= "runtime_confirmed" then
        return nil, "invalid corpse record"
    end
    if (record.qa_contract_id == nil) ~= (record.qa_contract == nil) then
        return nil, "invalid corpse QA contract projection"
    end
    local qa_evidence_ok, qa_evidence_err =
        qa_evidence_schema.verify_corpse_evidence(record.qa_evidence)
    if not qa_evidence_ok then
        return nil, "invalid corpse QA evidence: " .. tostring(qa_evidence_err)
    end
    if record.qa_evidence.qa_contract_id ~= record.qa_contract_id then
        return nil, "corpse QA evidence contradicts QA contract projection"
    end
    local manifest_projection = record.manifest
        and record.manifest.qa_terminal_projection or nil
    if not qa_schema.same(
            manifest_projection,
            record.qa_evidence.terminal_projection
        ) then
        return nil, "corpse QA terminal projection contradicts manifest"
    end
    if record.manifest and record.manifest.mode == "qa_terminal_delivery" then
        local projection = record.qa_evidence.terminal_projection
        if projection == nil then
            return nil, "corpse QA terminal projection is absent"
        end
        local expected_cause = projection.verdict == "accepted"
            and "complete" or "blocked"
        if record.death_cause ~= expected_cause then
            return nil, "corpse QA verdict contradicts death cause"
        end
    end
    if record.qa_contract ~= nil then
        local normalized, normalized_err = qa_schema.normalize_contract(record.qa_contract)
        if not normalized then
            return nil, "invalid corpse QA contract: " .. tostring(normalized_err)
        end
        if not qa_schema.same(record.qa_contract, normalized)
            or record.qa_contract_id ~= normalized.qa_contract_id
            or normalized.lineage_id ~= record.lineage_id
            or normalized.process_contract_id ~= record.process_contract_id
            or normalized.context ~= record.context
            or normalized.stage_id ~= record.stage_id then
            return nil, "invalid corpse QA contract projection"
        end
    end
    local actual, actual_err = digest.record(identity_projection(record))
    if not actual then
        return nil, actual_err
    end
    if actual ~= record.corpse_hash then
        return nil, "corpse hash mismatch"
    end
    return true
end

return corpse
