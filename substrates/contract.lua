local contract = {}

contract.modes = {
    glyph = true,
    natural = true,
    mixed = true,
}

function contract.validate_call(call)
    if type(call) ~= "table" then
        return false, "call must be table"
    end
    if not contract.modes[call.mode or "natural"] then
        return false, "invalid substrate mode"
    end
    if type(call.operator or "☴") ~= "string" then
        return false, "operator must be string"
    end
    if call.prompt_payload == nil and call.task == nil then
        return false, "prompt_payload or task is required"
    end
    return true
end

function contract.normalize_response(response)
    response = response or {}
    return {
        text = response.text or "",
        reasoning_text = response.reasoning_text,
        tool_intents = response.tool_intents or {},
        usage = response.usage or {},
        latency = response.latency,
        provider_metadata = response.provider_metadata or {},
        raw = response.raw,
    }
end

return contract
