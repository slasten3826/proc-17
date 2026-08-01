local body = require("runtime.body")
local digest = require("core.digest")
local evidence_schema = require("core.qa_evidence_schema")
local packet = require("core.packet")
local qa_capability = require("runtime.qa_capability")
local qa_request = require("runtime.qa_request")
local qa_schema = require("core.qa_schema")
local substrate_contract = require("substrates.contract")

local evidence = {}

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

local function extend_refs(target, values)
    for _, value in ipairs(values or {}) do target[#target + 1] = value end
end

local function cost_projection(cost)
    cost = cost or {}
    return {
        tool_calls = cost.tool_calls or 0,
        test_runs = cost.qa_executions or 0,
        time_ms = cost.wall_time_ms or 0,
    }
end

local function trace_cost_projection(cost)
    local admitted = cost_projection(cost)
    return {
        steps = 0,
        substrate_calls = 0,
        tool_calls = admitted.tool_calls,
        file_writes = 0,
        test_runs = admitted.test_runs,
        loss = 0,
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

local function request_coordinates_match(request, value)
    for _, key in ipairs({
        "packet_id", "lineage_id", "generation", "process_contract_id",
        "context", "stage_id", "repository_id", "candidate_seal_id",
        "candidate_seal_event_ref", "artifact_alignment_id",
        "qa_contract_id", "check_id", "profile_id", "environment_id",
    }) do
        if request[key] ~= value[key] then return false end
    end
    return request.request_id == value.request_id
end

local function request_event_is_exact(instance, event)
    if type(event) ~= "table"
        or event.type ~= "qa_check_request"
        or event.operator ~= "☶"
        or event.truth_status ~= "runtime_confirmed"
        or event.packet_id ~= instance.id
        or event.lineage_id ~= instance.lineage_id
        or event.generation ~= instance.generation then
        return nil, "QA check request event envelope is invalid"
    end
    local verified, verified_err = evidence_schema.verify_request(event.payload)
    if not verified then
        return nil, verified_err
    end
    if not body_coordinates_match(instance, event.payload) then
        return nil, "QA check request is foreign to Packet"
    end
    local cost_keys = {
        steps = true,
        substrate_calls = true,
        tool_calls = true,
        file_writes = true,
        test_runs = true,
        loss = true,
    }
    if type(event.cost) ~= "table" or getmetatable(event.cost) ~= nil then
        return nil, "QA check request event cost is invalid"
    end
    for key in pairs(event.cost) do
        if not cost_keys[key] then
            return nil, "QA check request event cost contains unknown axis"
        end
    end
    for key in pairs(cost_keys) do
        if event.cost[key] ~= 0 then
            return nil, "QA check request event has non-zero cost"
        end
    end
    return true
end

function evidence.verify_request(instance, value)
    return qa_request.verify(instance, value)
end

function evidence.record_request(instance, prepared_request)
    local verified, verified_err = qa_request.verify(instance, prepared_request)
    if not verified then
        return nil, nil, verified_err
    end
    local normalized, normalized_err = evidence_schema.normalize_request(
        prepared_request
    )
    if not normalized then
        return nil, nil, normalized_err
    end
    if not evidence_schema.same(prepared_request, normalized) then
        return nil, nil, "QA check request is not normalized"
    end

    local replay_request, replay_event
    for _, event in ipairs(instance.trace or {}) do
        if event.type == "qa_check_request" then
            local exact, exact_err = request_event_is_exact(instance, event)
            if not exact then
                return nil, nil, exact_err
            end
            local payload = event.payload
            if payload.candidate_seal_id == normalized.candidate_seal_id
                and payload.check_id == normalized.check_id then
                if not evidence_schema.same(payload, normalized) then
                    return nil, nil,
                        "Packet contains contradictory QA check request"
                end
                if replay_event then
                    return nil, nil, "QA check request event is ambiguous"
                end
                replay_request = copy(payload)
                replay_event = copy(event)
            end
        end
    end
    if replay_event then
        return replay_request, replay_event
    end

    local stored, event_or_err = body.record_qa_request(instance, normalized)
    if not stored then
        return nil, nil, event_or_err
    end
    return copy(stored), copy(event_or_err)
end

local function outcome_event_is_exact(instance, event, event_type)
    local actor = "☶"
    if type(event) ~= "table"
        or event.type ~= event_type
        or event.operator ~= actor
        or event.truth_status ~= "runtime_confirmed"
        or event.packet_id ~= instance.id
        or event.lineage_id ~= instance.lineage_id
        or event.generation ~= instance.generation then
        return nil, "QA outcome event envelope is invalid"
    end
    local verified, verified_err
    if event_type == "qa_check" then
        verified, verified_err = evidence_schema.verify_check(event.payload)
    else
        verified, verified_err = evidence_schema.verify_failure(event.payload)
    end
    if not verified then return nil, verified_err end
    if not body_coordinates_match(instance, event.payload) then
        return nil, "QA outcome is foreign to Packet"
    end
    local expected = event_type == "qa_check"
        and trace_cost_projection(event.payload.runtime_cost)
        or trace_cost_projection(event.payload.measured_cost)
    if not qa_schema.same(event.cost, expected) then
        return nil, "QA outcome event cost contradicts evidence"
    end
    return true
end

local function verdict_event_is_exact(instance, event)
    if type(event) ~= "table"
        or event.type ~= "qa_candidate_verdict"
        or event.operator ~= "☱"
        or event.truth_status ~= "runtime_confirmed"
        or event.packet_id ~= instance.id
        or event.lineage_id ~= instance.lineage_id
        or event.generation ~= instance.generation then
        return nil, "QA verdict event envelope is invalid"
    end
    local verified, verified_err = evidence_schema.verify_verdict(event.payload)
    if not verified then return nil, verified_err end
    if not body_coordinates_match(instance, event.payload) then
        return nil, "QA verdict is foreign to Packet"
    end
    for _, value in pairs(event.cost or {}) do
        if value ~= 0 then return nil, "QA verdict event has non-zero cost" end
    end
    return true
end

local function verify_outcome(instance, value, event_type)
    local normalized, normalized_err
    if event_type == "qa_check" then
        normalized, normalized_err = evidence_schema.normalize_check(value)
    else
        normalized, normalized_err = evidence_schema.normalize_failure(value)
    end
    if not normalized then return nil, normalized_err end
    if not qa_schema.same(value, normalized) then
        return nil, "QA outcome is not normalized"
    end
    if not body_coordinates_match(instance, normalized) then
        return nil, "QA outcome is foreign to Packet"
    end
    local request, request_event, request_err = qa_request.find(
        instance,
        normalized.request_id
    )
    if not request then return nil, request_err end
    if request_event.id ~= normalized.request_ref
        or not request_coordinates_match(request, normalized) then
        return nil, "QA outcome contradicts its request event"
    end
    return true
end

function evidence.verify_check(instance, value)
    return verify_outcome(instance, value, "qa_check")
end

function evidence.verify_failure(instance, value)
    return verify_outcome(instance, value, "qa_execution_failure")
end

local function collect_current(
    instance,
    candidate_seal_id,
    qa_contract_id,
    require_live_verification
)
    if type(candidate_seal_id) ~= "string" or candidate_seal_id == ""
        or type(qa_contract_id) ~= "string" or qa_contract_id == "" then
        return nil, "current QA evidence coordinates are required"
    end
    local view = {
        protocol_version = "qa.current_evidence.v0",
        candidate_seal_id = candidate_seal_id,
        qa_contract_id = qa_contract_id,
        request = nil,
        request_ref = nil,
        check = nil,
        check_ref = nil,
        execution_failure = nil,
        execution_failure_ref = nil,
        verdict = nil,
        verdict_ref = nil,
        conflicts = {},
    }
    for _, event in ipairs(instance and instance.trace or {}) do
        local payload = event.payload
        local is_qa_request = event.type == "qa_check_request"
        local is_qa_outcome = event.type == "qa_check"
            or event.type == "qa_execution_failure"
        local is_qa_verdict = event.type == "qa_candidate_verdict"
        if is_qa_request then
            local exact, exact_err = request_event_is_exact(instance, event)
            if not exact then return nil, exact_err end
        elseif is_qa_outcome then
            local exact, exact_err = outcome_event_is_exact(
                instance,
                event,
                event.type
            )
            if not exact then return nil, exact_err end
            if require_live_verification then
                local verified, verified_err = verify_outcome(
                    instance,
                    payload,
                    event.type
                )
                if not verified then return nil, verified_err end
            end
        elseif is_qa_verdict then
            local exact, exact_err = verdict_event_is_exact(instance, event)
            if not exact then return nil, exact_err end
        end
        local current = type(payload) == "table"
            and payload.candidate_seal_id == candidate_seal_id
            and payload.qa_contract_id == qa_contract_id
        if current and is_qa_request then
            if view.request then
                view.conflicts[#view.conflicts + 1] = "multiple_requests"
            else
                view.request = copy(payload)
                view.request_ref = event.id
            end
        elseif current and is_qa_outcome then
            if event.type == "qa_check" then
                if view.check then
                    view.conflicts[#view.conflicts + 1] = "multiple_checks"
                else
                    view.check = copy(payload)
                    view.check_ref = event.id
                end
            else
                if view.execution_failure then
                    view.conflicts[#view.conflicts + 1] =
                        "multiple_execution_failures"
                else
                    view.execution_failure = copy(payload)
                    view.execution_failure_ref = event.id
                end
            end
        elseif current and is_qa_verdict then
            if view.verdict then
                view.conflicts[#view.conflicts + 1] = "multiple_verdicts"
            else
                view.verdict = copy(payload)
                view.verdict_ref = event.id
            end
        end
    end
    if view.check and view.execution_failure then
        view.conflicts[#view.conflicts + 1] = "check_and_execution_failure"
    end
    if view.request and view.check
        and view.request.request_id ~= view.check.request_id then
        view.conflicts[#view.conflicts + 1] = "check_request_mismatch"
    end
    if view.request and view.check
        and not request_coordinates_match(view.request, view.check) then
        view.conflicts[#view.conflicts + 1] =
            "check_request_coordinate_mismatch"
    end
    if view.request and view.execution_failure
        and view.request.request_id ~= view.execution_failure.request_id then
        view.conflicts[#view.conflicts + 1] = "failure_request_mismatch"
    end
    if view.request and view.execution_failure
        and not request_coordinates_match(
            view.request,
            view.execution_failure
        ) then
        view.conflicts[#view.conflicts + 1] =
            "failure_request_coordinate_mismatch"
    end
    if view.verdict then
        if not view.request or not view.check then
            view.conflicts[#view.conflicts + 1] = "verdict_without_complete_check"
        else
            if view.verdict.check_ids[1] ~= view.check.qa_check_id
                or view.verdict.check_refs[1] ~= view.check_ref
                or view.verdict.request_refs[1] ~= view.request_ref
                or view.verdict.verdict ~= view.check.outcome
                or not qa_schema.same(
                    view.verdict.runtime_cost,
                    view.check.runtime_cost
                ) then
                view.conflicts[#view.conflicts + 1] =
                    "verdict_check_mismatch"
            end
        end
        if view.execution_failure then
            view.conflicts[#view.conflicts + 1] =
                "verdict_and_execution_failure"
        end
    end
    view.conflicts = sorted_unique(view.conflicts)
    return copy(view)
end

function evidence.current(instance, candidate_seal_id, qa_contract_id)
    return collect_current(
        instance,
        candidate_seal_id,
        qa_contract_id,
        true
    )
end

function evidence.historical(instance, candidate_seal_id, qa_contract_id)
    return collect_current(
        instance,
        candidate_seal_id,
        qa_contract_id,
        false
    )
end

local receipt_keys = {
    protocol_version = true,
    execution_receipt_id = true,
    request_id = true,
    request_ref = true,
    grant_id = true,
    physical_transaction_id = true,
    packet_id = true,
    lineage_id = true,
    generation = true,
    process_contract_id = true,
    context = true,
    stage_id = true,
    repository_id = true,
    candidate_seal_id = true,
    artifact_alignment_id = true,
    qa_contract_id = true,
    check_id = true,
    profile_id = true,
    environment_id = true,
    result_kind = true,
    source_acquisition = true,
    source_disposition = true,
    normalized_result_id = true,
    transaction_disposition = true,
    cost = true,
    committed = true,
}

local function exact_receipt(receipt, result, receipt_id)
    if type(receipt) ~= "table" or getmetatable(receipt) ~= nil
        or type(result) ~= "table" or getmetatable(result) ~= nil then
        return nil, "QA receipt join requires plain records"
    end
    for key in pairs(receipt) do
        if not receipt_keys[key] then
            return nil, "QA execution receipt contains unknown key: "
                .. tostring(key)
        end
    end
    for key in pairs(receipt_keys) do
        if receipt[key] == nil and key ~= "cost" then
            return nil, "QA execution receipt is missing key: " .. key
        end
    end
    if receipt.protocol_version ~= "qa.execution_receipt.v1"
        or receipt.execution_receipt_id ~= receipt_id
        or receipt.committed ~= true
        or (receipt.result_kind ~= "candidate_report"
            and receipt.result_kind ~= "provider_error") then
        return nil, "QA execution receipt envelope is invalid"
    end
    local receipt_seed = copy(receipt)
    receipt_seed.execution_receipt_id = nil
    local receipt_digest, receipt_digest_err = digest.record(receipt_seed)
    if not receipt_digest then return nil, receipt_digest_err end
    if receipt.execution_receipt_id ~= "qa-execution-receipt:"
        .. receipt_digest then
        return nil, "QA execution receipt identity mismatch"
    end
    local result_digest, result_digest_err = digest.record(result)
    if not result_digest then return nil, result_digest_err end
    if receipt.normalized_result_id ~= "qa-provider-result:" .. result_digest
        or result.request_id ~= receipt.request_id
        or result.physical_transaction_id ~= receipt.physical_transaction_id
        or result.profile_id ~= receipt.profile_id
        or result.environment_id ~= receipt.environment_id then
        return nil, "QA receipt and private result identity disagree"
    end
    if receipt.result_kind == "candidate_report" then
        if result.protocol_version ~= "qa.provider_candidate_report.v1"
            or receipt.source_acquisition ~= "acquired"
            or receipt.source_disposition ~= result.source.disposition
            or receipt.source_disposition ~= "consumed"
            or receipt.transaction_disposition ~= "completed"
            or not qa_schema.same(receipt.cost, result.cost) then
            return nil, "QA candidate receipt topology is invalid"
        end
    else
        local expected_disposition = result.source_disposition == "quarantined"
            and "quarantined" or "consumed_failed"
        if result.protocol_version ~= "qa.provider_error.v1"
            or receipt.source_acquisition ~= result.source_acquisition
            or receipt.source_disposition ~= result.source_disposition
            or receipt.transaction_disposition ~= expected_disposition
            or not qa_schema.same(receipt.cost, result.measured_cost) then
            return nil, "QA failure receipt topology is invalid"
        end
    end
    return true
end

local function receipt_coordinates_match(instance, request, event, receipt)
    if not body_coordinates_match(instance, receipt)
        or receipt.request_ref ~= event.id
        or receipt.request_id ~= request.request_id then
        return false
    end
    for _, key in ipairs({
        "packet_id", "lineage_id", "generation", "process_contract_id",
        "context", "stage_id", "repository_id", "candidate_seal_id",
        "artifact_alignment_id", "qa_contract_id", "check_id", "profile_id",
        "environment_id",
    }) do
        if receipt[key] ~= request[key] then return false end
    end
    return true
end

local function outcome_refs(request, request_event, receipt)
    local refs = {}
    extend_refs(refs, request.source_refs)
    extend_refs(refs, {
        request.request_id,
        request_event.id,
        request.candidate_seal_id,
        request.candidate_seal_event_ref,
        request.artifact_alignment_id,
        request.qa_contract_id,
        request.check_id,
        receipt.execution_receipt_id,
        receipt.normalized_result_id,
    })
    return sorted_unique(refs)
end

local function check_from_private(request, request_event, receipt, result)
    return evidence_schema.normalize_check({
        protocol_version = "qa.check.v0",
        qa_check_id = nil,
        packet_id = request.packet_id,
        lineage_id = request.lineage_id,
        generation = request.generation,
        process_contract_id = request.process_contract_id,
        context = request.context,
        stage_id = request.stage_id,
        repository_id = request.repository_id,
        candidate_seal_id = request.candidate_seal_id,
        candidate_seal_event_ref = request.candidate_seal_event_ref,
        artifact_alignment_id = request.artifact_alignment_id,
        qa_contract_id = request.qa_contract_id,
        check_id = request.check_id,
        profile_id = request.profile_id,
        environment_id = request.environment_id,
        request_id = request.request_id,
        request_ref = request_event.id,
        execution_receipt_id = receipt.execution_receipt_id,
        outcome = result.outcome,
        reason = result.reason,
        termination = copy(result.termination),
        cause = copy(result.cause),
        finality = copy(result.finality),
        source = copy(result.source),
        stdout = copy(result.stdout),
        stderr = copy(result.stderr),
        resources = copy(result.resources),
        scratch = copy(result.scratch),
        runtime_cost = copy(result.cost),
        source_refs = outcome_refs(request, request_event, receipt),
        event_truth_status = "runtime_confirmed",
        content_truth_status = request.content_truth_status,
    })
end

local function failure_from_private(request, request_event, receipt, result)
    return evidence_schema.normalize_failure({
        protocol_version = "qa.execution_failure.v0",
        failure_id = nil,
        packet_id = request.packet_id,
        lineage_id = request.lineage_id,
        generation = request.generation,
        process_contract_id = request.process_contract_id,
        context = request.context,
        stage_id = request.stage_id,
        repository_id = request.repository_id,
        candidate_seal_id = request.candidate_seal_id,
        candidate_seal_event_ref = request.candidate_seal_event_ref,
        artifact_alignment_id = request.artifact_alignment_id,
        qa_contract_id = request.qa_contract_id,
        check_id = request.check_id,
        profile_id = request.profile_id,
        environment_id = request.environment_id,
        request_id = request.request_id,
        request_ref = request_event.id,
        execution_receipt_id = receipt.execution_receipt_id,
        class = result.class,
        code = result.code,
        stage = result.stage,
        candidate_start_state = result.candidate_start_state,
        source_acquisition = result.source_acquisition,
        source_stable = result.source_stable,
        source_disposition = result.source_disposition,
        cleanup_state = result.cleanup_state,
        launcher_reaped = result.launcher_reaped,
        result_eof = result.result_eof,
        measured_cost = copy(result.measured_cost),
        transaction_disposition = receipt.transaction_disposition,
        source_refs = outcome_refs(request, request_event, receipt),
        event_truth_status = "runtime_confirmed",
        content_truth_status = "runtime_confirmed",
    })
end

local function effect_failure(value, event)
    return substrate_contract.effect_failure({
        source = "sandbox",
        code = "qa_" .. value.code,
        retryability = value.class == "ambiguous" and "terminal" or "unknown",
        source_refs = sorted_unique({
            value.failure_id,
            event.id,
            value.request_ref,
        }),
        cost = cost_projection(value.measured_cost),
        detail = copy(value),
    })
end

function evidence.commit_execution(instance, registry, execution_receipt_id)
    local mutable, mutable_err = packet.assert_mutable(
        instance,
        "commit QA execution evidence"
    )
    local actor, actor_err = packet.assert_actor_tick(
        instance,
        "☶",
        "commit QA execution evidence"
    )
    if not mutable or not actor
        or not instance.regime or not instance.regime.work
        or instance.regime.work.mode ~= "build" then
        return nil, nil, nil, true, mutable_err or actor_err
            or "QA execution evidence requires a living build Packet at ☶"
    end
    local joined, joined_err = qa_capability.with_receipt(
        registry,
        execution_receipt_id,
        function(receipt, result)
            local exact, exact_err = exact_receipt(
                receipt,
                result,
                execution_receipt_id
            )
            if not exact then return nil, exact_err end
            local request, request_event, request_err = qa_request.find(
                instance,
                receipt.request_id
            )
            if not request then return nil, request_err end
            if not receipt_coordinates_match(
                instance,
                request,
                request_event,
                receipt
            ) then
                return nil, "QA receipt coordinates contradict current Packet"
            end
            local current, current_err = evidence.current(
                instance,
                request.candidate_seal_id,
                request.qa_contract_id
            )
            if not current then return nil, current_err end
            if #current.conflicts > 0 then
                return nil, "current QA evidence is contradictory: "
                    .. table.concat(current.conflicts, ",")
            end
            local existing = current.check or current.execution_failure
            local expected_event_type = receipt.result_kind == "candidate_report"
                and "qa_check" or "qa_execution_failure"
            if existing then
                local actual_event_type = current.check and "qa_check"
                    or "qa_execution_failure"
                if actual_event_type ~= expected_event_type
                    or existing.execution_receipt_id ~= execution_receipt_id
                    or existing.request_id ~= request.request_id then
                    return nil, "QA receipt contradicts current body outcome"
                end
                return {
                    kind = actual_event_type,
                    replay = true,
                    payload = copy(existing),
                    event_ref = current.check_ref
                        or current.execution_failure_ref,
                }
            end
            local payload, payload_err
            if receipt.result_kind == "candidate_report" then
                payload, payload_err = check_from_private(
                    request,
                    request_event,
                    receipt,
                    result
                )
            else
                payload, payload_err = failure_from_private(
                    request,
                    request_event,
                    receipt,
                    result
                )
            end
            if not payload then return nil, payload_err end
            return {
                kind = expected_event_type,
                replay = false,
                payload = payload,
            }
        end
    )
    if not joined then
        return nil, nil, nil, true, joined_err
    end
    if joined.replay then
        local event
        for _, candidate in ipairs(instance.trace or {}) do
            if candidate.id == joined.event_ref then event = copy(candidate) end
        end
        if not event then
            return nil, nil, nil, true,
                "QA replay body event disappeared after receipt join"
        end
        if joined.kind == "qa_check" then
            return copy(joined.payload), event
        end
        return copy(joined.payload), event,
            effect_failure(joined.payload, event)
    end
    local stored, event_or_err
    if joined.kind == "qa_check" then
        stored, event_or_err = body.record_qa_check(instance, joined.payload)
    else
        stored, event_or_err = body.record_qa_execution_failure(
            instance,
            joined.payload
        )
    end
    if not stored then
        return nil, nil, nil, true,
            "QA body outcome append failed after private receipt: "
                .. tostring(event_or_err)
    end
    if joined.kind == "qa_check" then
        return copy(stored), copy(event_or_err)
    end
    return copy(stored), copy(event_or_err),
        effect_failure(stored, event_or_err)
end

return evidence
