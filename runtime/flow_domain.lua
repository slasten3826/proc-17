local l1 = require("l1.field")

local flow_domain = {
    protocol_version = "l1.flow_domain.v0",
    mark_protocol_version = "l1.flow_mark.v0",
}

local stream_counter = 0

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

local function is_integer(value)
    return type(value) == "number" and value >= 0 and value == math.floor(value)
end

local function next_stream_id()
    stream_counter = stream_counter + 1
    return "l1-stream-" .. tostring(stream_counter)
end

local function validate(domain)
    if type(domain) ~= "table" or domain.kind ~= "l1_flow_domain"
        or domain.protocol_version ~= flow_domain.protocol_version then
        return nil, "invalid L1 flow domain"
    end
    if domain.interpreter_contract ~= "lua-5.4" or domain.variant ~= "C" then
        return nil, "invalid L1 flow domain contract"
    end
    if type(domain.stream_id) ~= "string" or domain.stream_id == ""
        or not is_integer(domain.stream_epoch) or domain.stream_epoch < 1
        or not is_integer(domain.birth_seq) then
        return nil, "invalid L1 flow identity"
    end
    if domain.status ~= "open" and domain.status ~= "frozen" then
        return nil, "invalid L1 flow domain status"
    end
    if type(domain.state) ~= "table" or domain.state.protocol_version ~= l1.protocol_version
        or domain.state.ticks ~= domain.birth_seq then
        return nil, "invalid L1 flow state"
    end
    if type(domain.source_provenance) ~= "table"
        or type(domain.source_provenance.adapter_id) ~= "string"
        or domain.source_provenance.adapter_id == ""
        or type(domain.source_provenance.source_ref) ~= "string"
        or domain.source_provenance.source_ref == ""
        or domain.source_provenance.source_count ~= domain.state.ring_size then
        return nil, "invalid L1 source provenance"
    end
    if type(domain.birth_events) ~= "table" or type(domain.busy) ~= "boolean" then
        return nil, "invalid L1 flow domain runtime"
    end
    return true
end

function flow_domain.new(source, options)
    options = options or {}
    local stream_id = options.stream_id or next_stream_id()
    local stream_epoch = options.stream_epoch or 1
    local adapter_id = options.adapter_id or "explicit_lua_array.v0"
    local source_ref = options.source_ref
    if type(stream_id) ~= "string" or stream_id == "" then
        return nil, "L1 stream_id must be a non-empty string"
    end
    if not is_integer(stream_epoch) or stream_epoch < 1 then
        return nil, "L1 stream_epoch must be integer >= 1"
    end
    if type(adapter_id) ~= "string" or adapter_id == "" then
        return nil, "L1 adapter_id must be a non-empty string"
    end

    local state, state_err = l1.initialize(source, {
        variant = "C",
        source_ref = source_ref,
        max_source_units = options.max_source_units,
    })
    if not state then
        return nil, state_err
    end

    return {
        kind = "l1_flow_domain",
        protocol_version = flow_domain.protocol_version,
        l1_protocol_version = l1.protocol_version,
        interpreter_contract = l1.interpreter_contract,
        variant = "C",
        stream_id = stream_id,
        stream_epoch = stream_epoch,
        birth_seq = 0,
        state = state,
        status = "open",
        source_provenance = {
            adapter_id = adapter_id,
            source_ref = source_ref,
            source_count = state.ring_size,
            config_ref = options.config_ref,
        },
        birth_events = {},
        busy = false,
    }
end

function flow_domain.snapshot(domain)
    local valid, valid_err = validate(domain)
    if not valid then
        return nil, valid_err
    end
    local physical, physical_err = l1.snapshot(domain.state)
    if not physical then
        return nil, physical_err
    end
    return {
        kind = "l1_flow_domain_snapshot",
        protocol_version = flow_domain.protocol_version,
        stream_id = domain.stream_id,
        stream_epoch = domain.stream_epoch,
        birth_seq = domain.birth_seq,
        status = domain.status,
        source_provenance = copy_value(domain.source_provenance),
        snapshot = physical,
        birth_event_count = #domain.birth_events,
        event_truth_status = "runtime_confirmed",
    }
end

function flow_domain.freeze(domain)
    local valid, valid_err = validate(domain)
    if not valid then
        return nil, valid_err
    end
    if domain.busy then
        return nil, "L1 flow domain birth is in progress"
    end
    if domain.status == "frozen" then
        return domain
    end
    local frozen, freeze_err = l1.freeze(domain.state)
    if not frozen then
        return nil, freeze_err
    end
    domain.status = "frozen"
    return domain
end

-- Body-internal transaction boundary. Only runtime.packet_birth supplies builder.
function flow_domain.advance_birth(domain, builder)
    local valid, valid_err = validate(domain)
    if not valid then
        return nil, valid_err
    end
    if domain.status ~= "open" then
        return nil, "L1 flow domain is frozen"
    end
    if domain.busy then
        return nil, "L1 flow domain birth is in progress"
    end
    if type(builder) ~= "function" then
        return nil, "L1 birth builder is required"
    end

    domain.busy = true
    local tentative = copy_value(domain.state)
    local ticked, tick_err = l1.tick(tentative)
    if not ticked then
        domain.busy = false
        return nil, tick_err
    end
    local physical, snapshot_err = l1.snapshot(tentative)
    if not physical then
        domain.busy = false
        return nil, snapshot_err
    end

    local birth_seq = domain.birth_seq + 1
    local event_ref = table.concat({
        domain.stream_id,
        tostring(domain.stream_epoch),
        "birth",
        tostring(birth_seq),
    }, ":")
    local mark = {
        protocol_version = flow_domain.mark_protocol_version,
        l1_protocol_version = l1.protocol_version,
        variant = "C",
        stream_id = domain.stream_id,
        stream_epoch = domain.stream_epoch,
        birth_seq = birth_seq,
        trigger = "packet_birth",
        snapshot = physical,
        source_provenance = copy_value(domain.source_provenance),
        domain_event_ref = event_ref,
        event_truth_status = "runtime_confirmed",
        content_truth_status = "non_semantic_measurement",
        semantic_claim_status = "none",
    }

    local called, instance_or_err, builder_err = pcall(
        builder,
        copy_value(mark),
        copy_value(tentative)
    )
    if not called then
        domain.busy = false
        return nil, "Packet birth builder failed: " .. tostring(instance_or_err)
    end
    if not instance_or_err then
        domain.busy = false
        return nil, builder_err or "Packet birth builder rejected request"
    end
    local instance = instance_or_err
    if type(instance) ~= "table" or type(instance.id) ~= "string" then
        domain.busy = false
        return nil, "Packet birth builder returned invalid Packet"
    end

    local domain_event = {
        kind = "l1_packet_birth_event",
        event_ref = event_ref,
        packet_id = instance.id,
        flow_ref = {
            stream_id = domain.stream_id,
            stream_epoch = domain.stream_epoch,
            birth_seq = birth_seq,
        },
        snapshot = copy_value(physical),
        event_truth_status = "runtime_confirmed",
    }

    domain.state = tentative
    domain.birth_seq = birth_seq
    domain.birth_events[#domain.birth_events + 1] = domain_event
    domain.busy = false

    return instance, copy_value(mark), copy_value(domain_event)
end

return flow_domain
