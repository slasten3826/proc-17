local carrier_module = require("runtime.carrier")
local json = require("core.json")
local network_projection = require("runtime.network_projection")

local network_ingress = {
    protocol_version = "network.ingress.v0",
    rejected_protocol_version = "network.ingress.v1",
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

local function qa_rejected_carrier(value)
    local evidence = value and value.payload and value.payload.qa_history
        and value.payload.qa_history.qa_evidence
    return evidence and evidence.verdict
        and evidence.verdict.verdict == "rejected"
        and evidence.terminal_projection
        and evidence.terminal_projection.verdict == "rejected"
end

local function continuation_event(lineage, carrier, projection)
    local matched
    for _, event in ipairs(lineage.ledger or {}) do
        local payload = event.payload or {}
        if event.kind == "continuation_decided"
            and event.lineage_id == lineage.lineage_id
            and event.generation == carrier.source_generation
            and event.packet_id == carrier.source_packet_id
            and event.corpse_id == carrier.source_corpse_id
            and event.carrier_id == carrier.carrier_id
            and event.event_truth_status == "runtime_confirmed"
            and payload.decision == "continue"
            and payload.target_generation == carrier.target_generation
            and payload.network_projection_id == projection.projection_id
            and payload.completion_assessment_id
                == projection.completion_assessment_id
            and payload.completion_event_ref == projection.completion_event_ref then
            if matched ~= nil then
                return nil, "multiple continuation decisions bind NETWORK projection"
            end
            matched = event
        end
    end
    if matched == nil then
        return nil, "continuation decision does not bind exact NETWORK projection"
    end
    return matched
end

local function prepare_rejected(lineage, carrier, options, max_bytes)
    local projection = options.network_projection
    if type(projection) ~= "table" then
        return nil, "QA-rejected NETWORK ingress requires projection"
    end
    local continued, continued_err = continuation_event(
        lineage,
        carrier,
        projection
    )
    if not continued then return nil, continued_err end
    local corpse = options.source_corpse
    local assessment_event = options.assessment_event
    if type(corpse) ~= "table" or type(assessment_event) ~= "table" then
        return nil, "QA-rejected NETWORK ingress requires exact source tuple"
    end
    local projection_ok, projection_err = network_projection.verify(
        projection,
        {
            lineage = lineage,
            corpse = corpse,
            assessment_event = assessment_event,
            carrier = carrier,
            max_carrier_bytes = max_bytes,
            max_current_work_bytes = options.max_current_work_bytes,
        }
    )
    if not projection_ok then return nil, projection_err end
    if projection.terminal_recovery_basis ~= "qa_rejected"
        or type(projection.rejected_form) ~= "table" then
        return nil, "QA-rejected NETWORK projection has no rejected form"
    end
    local prompt = json.encode(projection.current_work)
    local metadata = {
        work_mode = "build",
        process_contract_id = projection.process_contract_id,
        context = projection.context,
        stage_id = projection.stage_id,
        qa_contract_id = carrier.payload.qa_contract_id,
    }
    return {
        kind = "network_packet_ingress",
        protocol_version = network_ingress.rejected_protocol_version,
        prompt = prompt,
        network_projection = copy_value(projection),
        packet_options = {
            lineage_id = projection.lineage_id,
            generation = projection.target_generation,
            parent_id = projection.source_packet_id,
            parent_corpse_id = projection.source_corpse_id,
            birth_kind = "recovery",
            carrier_id = projection.carrier_id,
            substrate_session_id = carrier.substrate_session_id,
            work_mode = "build",
            process_contract_id = projection.process_contract_id,
            context = projection.context,
            stage_id = projection.stage_id,
            qa_contract = copy_value(carrier.payload.qa_contract),
            metadata = metadata,
        },
        source_refs = {
            projection.carrier_id,
            projection.source_corpse_id,
            projection.projection_id,
        },
        event_truth_status = "runtime_confirmed",
        content_truth_status = projection.content_truth_status,
    }
end

function network_ingress.prepare(lineage, carrier, options)
    options = options or {}
    if type(lineage) ~= "table" or lineage.kind ~= "proc17_lineage" then
        return nil, "NETWORK ingress requires lineage"
    end
    if lineage.status ~= "continuing" then
        return nil, "lineage is not continuing"
    end
    local max_bytes = options.max_bytes
        or lineage.policy and lineage.policy.carrier and lineage.policy.carrier.max_bytes
    local verified, verified_err = carrier_module.verify(carrier, {
        lineage_id = lineage.lineage_id,
        source_corpse_id = lineage.current_corpse_id,
        target_generation = lineage.current_generation + 1,
        max_bytes = max_bytes,
    })
    if not verified then
        return nil, verified_err
    end
    if lineage.current_carrier_id ~= carrier.carrier_id
        or lineage.continued_corpses[lineage.current_corpse_id] ~= carrier.carrier_id
        or carrier.source_generation ~= lineage.current_generation
        or carrier.source_packet_id ~= lineage.current_packet_id then
        return nil, "carrier is not selected by current lineage boundary"
    end
    if qa_rejected_carrier(carrier) then
        return prepare_rejected(lineage, carrier, options, max_bytes)
    end
    if options.network_projection ~= nil then
        return nil, "ordinary recovery cannot attach QA NETWORK projection"
    end
    local metadata = {
        work_mode = lineage.work_mode,
        process_contract_id = carrier.payload.process_contract_id,
        context = carrier.payload.context,
        stage_id = carrier.payload.stage_id,
        qa_contract_id = carrier.payload.qa_contract_id,
    }
    return {
        kind = "network_packet_ingress",
        protocol_version = network_ingress.protocol_version,
        prompt = json.encode(carrier.payload),
        packet_options = {
            lineage_id = lineage.lineage_id,
            generation = carrier.target_generation,
            parent_id = carrier.source_packet_id,
            parent_corpse_id = carrier.source_corpse_id,
            birth_kind = "recovery",
            carrier_id = carrier.carrier_id,
            substrate_session_id = carrier.substrate_session_id,
            work_mode = lineage.work_mode,
            process_contract_id = carrier.payload.process_contract_id,
            context = carrier.payload.context,
            stage_id = carrier.payload.stage_id,
            qa_contract = copy_value(carrier.payload.qa_contract),
            metadata = metadata,
        },
        source_refs = {carrier.carrier_id, carrier.source_corpse_id},
        event_truth_status = "runtime_confirmed",
        content_truth_status = carrier.applicability_truth_status,
        carrier = copy_value(carrier),
    }
end

return network_ingress
