local body = require("runtime.body")
local candidate_seal = require("runtime.candidate_seal")
local evidence = require("runtime.qa_evidence")
local evidence_schema = require("core.qa_evidence_schema")
local packet = require("core.packet")
local qa_contract = require("runtime.qa_contract")
local qa_schema = require("core.qa_schema")

local qa_verdict = {
    protocol_version = "qa.candidate_verdict.v0",
}

local function copy(value)
    return evidence_schema.copy(value)
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

local function extend(target, values)
    for _, value in ipairs(values or {}) do target[#target + 1] = value end
end

local function diagnostic(code, detail, refs)
    return {
        protocol_version = "qa.verdict_diagnostic.v0",
        code = code,
        detail = detail or code,
        source_refs = sorted_unique(refs),
        event_truth_status = "runtime_confirmed",
    }
end

local function body_coordinates_match(instance, value)
    return type(instance) == "table"
        and value.packet_id == instance.id
        and value.lineage_id == instance.lineage_id
        and value.generation == instance.generation
        and value.process_contract_id == instance.process_contract_id
        and value.context == instance.work_context
        and value.stage_id == instance.stage_id
        and value.repository_id == instance.repository_id
end

local function trace_event(instance, event_id)
    for _, event in ipairs(instance and instance.trace or {}) do
        if event.id == event_id then return event end
    end
    return nil
end

local function current_inputs(instance, qa_contract_id)
    if type(instance) ~= "table" or instance.status == "dead"
        or instance.status == "manifested" or instance.terminal ~= nil
        or not instance.regime or not instance.regime.work
        or instance.regime.work.mode ~= "build" then
        return nil, diagnostic(
            "living_build_packet_required",
            "QA verdict requires one living build Packet"
        )
    end
    local contract, contract_err = qa_contract.verify_birth(instance)
    if not contract then
        if contract_err == "absent" or contract_err == "not_applicable" then
            return nil, diagnostic("qa_contract_not_ready", contract_err)
        end
        error("trusted QA contract invariant failed: " .. tostring(contract_err), 0)
    end
    if qa_contract_id ~= contract.qa_contract_id then
        return nil, diagnostic(
            "qa_contract_not_current",
            "requested QA contract is not current",
            {contract.qa_contract_id}
        )
    end
    local seal, seal_event, seal_err = candidate_seal.current(instance)
    if not seal then
        if seal_err == "candidate_seal_absent" then
            return nil, diagnostic("candidate_seal_not_ready", seal_err)
        end
        error("trusted candidate seal invariant failed: " .. tostring(seal_err), 0)
    end
    local alignment, alignment_err = candidate_seal.inspect_alignment(instance, seal)
    if not alignment then
        error("trusted artifact alignment invariant failed: "
            .. tostring(alignment_err), 0)
    end
    if alignment.state ~= "aligned" then
        return nil, diagnostic(
            "candidate_alignment_not_current",
            alignment.state,
            {seal.candidate_seal_id, alignment.alignment_id}
        )
    end
    local current, current_err = evidence.current(
        instance,
        seal.candidate_seal_id,
        contract.qa_contract_id
    )
    if not current then
        error("trusted QA evidence invariant failed: " .. tostring(current_err), 0)
    end
    if #current.conflicts > 0 then
        error("current QA evidence is contradictory: "
            .. table.concat(current.conflicts, ","), 0)
    end
    return {
        contract = contract,
        check_contract = contract.required_checks[1],
        seal = seal,
        seal_event = seal_event,
        alignment = alignment,
        current = current,
    }
end

local function verify_relations(inputs, value)
    local current = inputs.current
    local check = current.check
    local request = current.request
    if not check or not request
        or value.candidate_seal_id ~= inputs.seal.candidate_seal_id
        or value.candidate_seal_event_ref ~= inputs.seal_event.id
        or value.artifact_alignment_id ~= inputs.alignment.alignment_id
        or value.qa_contract_id ~= inputs.contract.qa_contract_id
        or value.profile_id ~= inputs.check_contract.profile_id
        or value.environment_id ~= inputs.check_contract.environment_id
        or value.check_ids[1] ~= check.qa_check_id
        or value.check_refs[1] ~= current.check_ref
        or value.request_refs[1] ~= current.request_ref
        or value.verdict ~= check.outcome
        or not qa_schema.same(value.runtime_cost, check.runtime_cost) then
        return nil, "QA candidate verdict contradicts current evidence"
    end
    return true
end

local function build(inputs, instance)
    local current = inputs.current
    if current.execution_failure then
        return nil, diagnostic(
            "qa_infrastructure_incomplete",
            "execution failure cannot contribute to candidate verdict",
            {current.execution_failure.failure_id, current.execution_failure_ref}
        )
    end
    if not current.request then
        return nil, diagnostic(
            "qa_request_not_ready",
            "current QA request is absent",
            {inputs.seal.candidate_seal_id}
        )
    end
    if not current.check then
        return nil, diagnostic(
            "qa_check_not_ready",
            "current required QA check is absent",
            {current.request.request_id, current.request_ref}
        )
    end
    local check = current.check
    local contract_check = inputs.check_contract
    if check.check_id ~= contract_check.check_id
        or check.profile_id ~= contract_check.profile_id
        or check.environment_id ~= contract_check.environment_id
        or check.request_id ~= current.request.request_id then
        error("current QA check contradicts its birth contract", 0)
    end
    local source_refs = {}
    extend(source_refs, inputs.contract.source_refs)
    extend(source_refs, inputs.seal.source_refs)
    extend(source_refs, current.request.source_refs)
    extend(source_refs, check.source_refs)
    extend(source_refs, {
        inputs.contract.qa_contract_id,
        inputs.seal.candidate_seal_id,
        inputs.seal_event.id,
        inputs.alignment.alignment_id,
        current.request.request_id,
        current.request_ref,
        check.qa_check_id,
        current.check_ref,
    })
    local content_truth_status = "runtime_confirmed"
    if inputs.contract.content_truth_status == "mixed"
        or current.request.content_truth_status == "mixed"
        or check.content_truth_status == "mixed" then
        content_truth_status = "mixed"
    end
    local normalized, normalized_err = evidence_schema.normalize_verdict({
        protocol_version = qa_verdict.protocol_version,
        verdict_id = nil,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        process_contract_id = instance.process_contract_id,
        context = instance.work_context,
        stage_id = instance.stage_id,
        repository_id = instance.repository_id,
        candidate_seal_id = inputs.seal.candidate_seal_id,
        candidate_seal_event_ref = inputs.seal_event.id,
        artifact_alignment_id = inputs.alignment.alignment_id,
        qa_contract_id = inputs.contract.qa_contract_id,
        profile_id = contract_check.profile_id,
        environment_id = contract_check.environment_id,
        verdict = check.outcome,
        required_checks = 1,
        accepted_checks = check.outcome == "accepted" and 1 or 0,
        rejected_checks = check.outcome == "rejected" and 1 or 0,
        check_ids = {check.qa_check_id},
        check_refs = {current.check_ref},
        request_refs = {current.request_ref},
        runtime_cost = copy(check.runtime_cost),
        source_refs = sorted_unique(source_refs),
        event_truth_status = "runtime_confirmed",
        content_truth_status = content_truth_status,
    })
    if not normalized then
        error("trusted QA verdict assembly failed: " .. tostring(normalized_err), 0)
    end
    return copy(normalized)
end

function qa_verdict.prepare(instance, qa_contract_id)
    local inputs, inputs_err = current_inputs(instance, qa_contract_id)
    if not inputs then return nil, inputs_err end
    if inputs.current.verdict then
        local valid, valid_err = verify_relations(inputs, inputs.current.verdict)
        if not valid then error(valid_err, 0) end
        return copy(inputs.current.verdict)
    end
    return build(inputs, instance)
end

function qa_verdict.verify(instance, value)
    local normalized, normalized_err = evidence_schema.normalize_verdict(value)
    if not normalized then return nil, normalized_err end
    if not evidence_schema.same(value, normalized) then
        return nil, "QA candidate verdict is not normalized"
    end
    if not body_coordinates_match(instance, normalized) then
        return nil, "QA candidate verdict is foreign to Packet"
    end
    return true
end

function qa_verdict.current(instance, candidate_seal_id, qa_contract_id)
    local current, current_err = evidence.current(
        instance,
        candidate_seal_id,
        qa_contract_id
    )
    if not current then return nil, nil, current_err end
    if #current.conflicts > 0 then
        return nil, nil, "current QA evidence is contradictory: "
            .. table.concat(current.conflicts, ",")
    end
    if not current.verdict then
        return nil, nil, current.execution_failure
            and "qa_infrastructure_incomplete" or "qa_candidate_verdict_absent"
    end
    local valid, valid_err = qa_verdict.verify(instance, current.verdict)
    if not valid then return nil, nil, valid_err end
    local inputs, inputs_err = current_inputs(instance, qa_contract_id)
    if not inputs then
        return nil, nil, type(inputs_err) == "table"
            and inputs_err.code or inputs_err
    end
    local relations, relations_err = verify_relations(inputs, current.verdict)
    if not relations then return nil, nil, relations_err end
    local event = trace_event(instance, current.verdict_ref)
    if not event then return nil, nil, "QA verdict event is absent" end
    return copy(current.verdict), copy(event)
end

function qa_verdict.commit(instance, prepared)
    local mutable, mutable_err = packet.assert_mutable(
        instance,
        "commit QA candidate verdict"
    )
    local actor, actor_err = packet.assert_actor_tick(
        instance,
        "☱",
        "commit QA candidate verdict"
    )
    if not mutable or not actor then
        return nil, nil, mutable_err or actor_err
    end
    local valid, valid_err = qa_verdict.verify(instance, prepared)
    if not valid then return nil, nil, valid_err end
    local derived, derived_err = qa_verdict.prepare(
        instance,
        prepared.qa_contract_id
    )
    if not derived then
        return nil, nil, type(derived_err) == "table"
            and derived_err.code or derived_err
    end
    if not evidence_schema.same(prepared, derived) then
        return nil, nil, "prepared QA candidate verdict is stale"
    end
    local current, current_event, current_err = qa_verdict.current(
        instance,
        prepared.candidate_seal_id,
        prepared.qa_contract_id
    )
    if current then
        if not evidence_schema.same(current, prepared) then
            return nil, nil, "Packet contains contradictory QA candidate verdict"
        end
        return copy(current), copy(current_event)
    end
    if current_err ~= "qa_candidate_verdict_absent" then
        return nil, nil, current_err
    end
    local stored, event_or_err = body.record_qa_candidate_verdict(
        instance,
        prepared
    )
    if not stored then return nil, nil, event_or_err end
    return copy(stored), copy(event_or_err)
end

return qa_verdict
