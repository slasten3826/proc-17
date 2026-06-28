local json = require("core.json")

local trace_store = {}

local function event_envelope(instance, event)
    return {
        packet_id = instance.id,
        event_id = event.id,
        type = event.type,
        operator = event.operator,
        truth_status = event.truth_status,
        payload = event.payload,
    }
end

function trace_store.write_jsonl(path, instance)
    if type(path) ~= "string" or path == "" then
        return nil, "path is required"
    end

    local file, err = io.open(path, "w")
    if not file then
        return nil, err
    end

    for _, event in ipairs(instance.trace or {}) do
        file:write(json.encode(event_envelope(instance, event)))
        file:write("\n")
    end

    file:write(json.encode({
        packet_id = instance.id,
        type = "final",
        status = instance.status,
        residue = instance.residue,
    }))
    file:write("\n")
    file:close()

    return true
end

return trace_store
