local carrier_module = require("runtime.carrier")
local json = require("core.json")

local network_ingress = {
    protocol_version = "network.ingress.v0",
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
            metadata = {work_mode = lineage.work_mode},
        },
        source_refs = {carrier.carrier_id, carrier.source_corpse_id},
        event_truth_status = "runtime_confirmed",
        content_truth_status = carrier.applicability_truth_status,
        carrier = copy_value(carrier),
    }
end

return network_ingress
