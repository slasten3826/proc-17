local digest = require("core.digest")
local json = require("core.json")

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

function carrier.build_recovery(lineage, corpse, assessment, options)
    options = options or {}
    if type(lineage) ~= "table" or lineage.kind ~= "proc17_lineage"
        or type(corpse) ~= "table" or corpse.kind ~= "proc17_corpse"
        or type(assessment) ~= "table" or assessment.kind ~= "lineage_completion_assessment" then
        return nil, "recovery carrier requires lineage, corpse and assessment"
    end
    if assessment.recoverable ~= true or corpse.corpse_id ~= lineage.current_corpse_id
        or corpse.lineage_id ~= lineage.lineage_id then
        return nil, "terminal state is not recoverable by this lineage"
    end
    local max_bytes = options.max_bytes
        or lineage.policy and lineage.policy.carrier and lineage.policy.carrier.max_bytes
    if type(max_bytes) ~= "number" or max_bytes < 1 or max_bytes ~= math.floor(max_bytes) then
        return nil, "carrier max_bytes must be integer >= 1"
    end
    local payload = {
        original_task = lineage.task.payload,
        prior_manifest = copy_value(corpse.manifest),
        residue = copy_value(corpse.residue or {}),
        remaining_work = copy_value(assessment.remaining_work or {}),
        source_generation = corpse.generation,
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
