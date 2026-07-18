local l1 = require("l1.field")

local projection = {
    protocol_version = "l1.fixture_projection.v0",
}

local adapters = {
    ["vertical_single.v0"] = 1,
    ["vertical_pair.v0"] = 2,
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

local function sample(state, mark, index, ordinal)
    return {
        projection_key = "sample:" .. tostring(ordinal),
        kind = "l1_physical_sample",
        carrier = {
            ring_index = index,
            core = state.core[index],
            l1_trace = state.l1_trace[index],
            phase = state.phase[index],
            flow_ref = {
                stream_id = mark.stream_id,
                stream_epoch = mark.stream_epoch,
                birth_seq = mark.birth_seq,
            },
        },
        source_refs = {
            mark.domain_event_ref,
            mark.source_provenance.source_ref,
        },
        event_truth_status = "runtime_confirmed",
        content_truth_status = "non_semantic_measurement",
    }
end

function projection.project(adapter_id, state, mark)
    local sample_count = adapters[adapter_id]
    if not sample_count then
        return nil, "unknown L1 projection adapter: " .. tostring(adapter_id)
    end
    if type(state) ~= "table" or state.protocol_version ~= l1.protocol_version
        or type(state.ring_size) ~= "number" or state.ring_size < sample_count then
        return nil, "invalid tentative L1 state for projection"
    end
    if type(mark) ~= "table" or mark.protocol_version ~= "l1.flow_mark.v0" then
        return nil, "invalid L1 flow mark for projection"
    end

    local start = state.position
    local units = {}
    for ordinal = 1, sample_count do
        local index = ((start + ordinal - 2) % state.ring_size) + 1
        units[#units + 1] = sample(state, mark, index, ordinal)
    end

    local relation_candidates = {}
    if sample_count == 2 then
        relation_candidates[1] = {
            from_key = units[1].projection_key,
            to_key = units[2].projection_key,
            kind = "l1_ring_adjacency",
            source_refs = {
                mark.domain_event_ref,
                units[1].projection_key,
                units[2].projection_key,
            },
            event_truth_status = "runtime_confirmed",
            content_truth_status = "non_semantic_measurement",
        }
    end

    return {
        protocol_version = projection.protocol_version,
        adapter_id = adapter_id,
        flow_ref = {
            stream_id = mark.stream_id,
            stream_epoch = mark.stream_epoch,
            birth_seq = mark.birth_seq,
        },
        units = units,
        relation_candidates = relation_candidates,
        event_truth_status = "runtime_confirmed",
        content_truth_status = "non_semantic_measurement",
    }
end

function projection.is_registered(adapter_id)
    return adapters[adapter_id] ~= nil
end

function projection.copy(value)
    return copy_value(value)
end

return projection
