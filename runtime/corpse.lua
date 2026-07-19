local digest = require("core.digest")

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

local function tail(source, count)
    local result = {}
    local first = math.max(1, #(source or {}) - count + 1)
    for index = first, #(source or {}) do
        result[#result + 1] = copy_value(source[index])
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
    local evidence_refs = {
        instance.terminal.event_id,
        instance.terminal.manifest_ref,
        manifest and manifest.assembly and manifest.assembly.assessment_ref,
    }
    for _, ref in ipairs(manifest and manifest.effect_scope_refs or {}) do
        evidence_refs[#evidence_refs + 1] = ref
    end

    local record = {
        kind = "proc17_corpse",
        protocol_version = corpse.protocol_version,
        corpse_id = corpse_id,
        corpse_hash = nil,
        lineage_id = instance.lineage_id,
        packet_id = instance.id,
        generation = instance.generation,
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
        trace_tail = tail(instance.trace, trace_tail_count),
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
        or (record.terminal_kind ~= "manifest" and record.terminal_kind ~= "internal_death")
        or type(record.death_cause) ~= "string"
        or type(record.trace_tail) ~= "table"
        or type(record.completion_evidence_refs) ~= "table"
        or type(record.final_loss) ~= "table"
        or type(record.final_budget) ~= "table"
        or record.truth_status ~= "runtime_confirmed" then
        return nil, "invalid corpse record"
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
