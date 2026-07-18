local packet_core = require("core.packet")
local flow_domain = require("runtime.flow_domain")
local l1_projection = require("runtime.l1_projection")

local packet_birth = {
    protocol_version = "l1.packet_birth.v0",
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

function packet_birth.create(domain, prompt, options)
    options = options or {}
    if type(prompt) ~= "string" or prompt == "" then
        return nil, "prompt must be non-empty string"
    end
    if type(options.packet_options) ~= "table" and options.packet_options ~= nil then
        return nil, "packet_options must be table"
    end
    local packet_options = copy_value(options.packet_options or {})
    if packet_options.ingress ~= nil then
        return nil, "packet ingress is owned by packet_birth"
    end

    if options.inherited_graves ~= nil and type(options.inherited_graves) ~= "table" then
        return nil, "packet birth inherited_graves must be table"
    end
    local inherited_grave_refs = {}
    for _, record in ipairs(options.inherited_graves or {}) do
        if type(record) ~= "table" or record.kind ~= "grave"
            or type(record.source_packet_id) ~= "string" or record.source_packet_id == "" then
            return nil, "packet birth inherited graves must be prepared records with source packet ids"
        end
        inherited_grave_refs[#inherited_grave_refs + 1] = record.source_packet_id
    end

    local instance, mark_or_err, domain_event = flow_domain.advance_birth(domain, function(mark, tentative)
        local projected
        if options.projection_adapter ~= nil then
            local projection_err
            projected, projection_err = l1_projection.project(
                options.projection_adapter,
                tentative,
                mark
            )
            if not projected then
                return nil, projection_err
            end
        end
        packet_options.ingress = {
            protocol_version = "packet.ingress.v0",
            integration_protocol = "vertical_packet_life.v0",
            flow_mark = mark,
            l1_projection = projected,
            carrier_ref = packet_options.carrier_id,
            inherited_grave_refs = copy_value(inherited_grave_refs),
        }
        return packet_core.new(prompt, packet_options)
    end)
    if not instance then
        return nil, mark_or_err
    end

    local mark = mark_or_err
    return instance, {
        kind = "l1_packet_birth_receipt",
        protocol_version = packet_birth.protocol_version,
        packet_id = instance.id,
        flow_ref = {
            stream_id = mark.stream_id,
            stream_epoch = mark.stream_epoch,
            birth_seq = mark.birth_seq,
        },
        flow_mark = copy_value(mark),
        domain_event_ref = domain_event.event_ref,
        event_truth_status = "runtime_confirmed",
    }
end

return packet_birth
