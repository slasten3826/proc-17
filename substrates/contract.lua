local contract = {}

contract.effect_failure_sources = {
    substrate = true,
    tool = true,
    sandbox = true,
    storage = true,
}

contract.effect_failure_retryability = {
    unknown = true,
    retryable = true,
    terminal = true,
}

contract.effect_failure_cost_axes = {
    substrate_calls = true,
    prompt_tokens = true,
    completion_tokens = true,
    total_tokens = true,
    estimated_tokens = true,
    tool_calls = true,
    file_writes = true,
    test_runs = true,
    time_ms = true,
    money_units = true,
}

local function normalize_effect_cost(value)
    if value == nil then
        return {}
    end
    if type(value) ~= "table" then
        return nil, "effect failure cost must be table"
    end
    local result = {}
    for key, amount in pairs(value) do
        if not contract.effect_failure_cost_axes[key]
            or type(amount) ~= "number"
            or amount < 0 then
            return nil, "invalid effect failure cost"
        end
        if amount ~= 0 then
            result[key] = amount
        end
    end
    return result
end

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

function contract.effect_failure(input)
    input = input or {}
    if not contract.effect_failure_sources[input.source] then
        error("invalid effect failure source")
    end
    if type(input.code) ~= "string" or input.code == "" then
        error("effect failure code is required")
    end
    local retryability = input.retryability or "unknown"
    if not contract.effect_failure_retryability[retryability] then
        error("invalid effect failure retryability")
    end
    if input.message ~= nil and type(input.message) ~= "string" then
        error("effect failure message must be string")
    end
    if input.source_refs ~= nil and type(input.source_refs) ~= "table" then
        error("effect failure source refs must be table")
    end
    local cost, cost_err = normalize_effect_cost(input.cost)
    if not cost then
        error(cost_err)
    end
    return {
        kind = "effect_failure",
        source = input.source,
        code = input.code,
        message = input.message,
        source_refs = input.source_refs or {},
        retryability = retryability,
        cost = cost,
        detail = input.detail,
        event_truth_status = "runtime_confirmed",
    }
end

function contract.is_effect_failure(value)
    local cost = type(value) == "table" and normalize_effect_cost(value.cost) or nil
    return type(value) == "table"
        and value.kind == "effect_failure"
        and contract.effect_failure_sources[value.source] == true
        and type(value.code) == "string"
        and value.code ~= ""
        and (value.message == nil or type(value.message) == "string")
        and type(value.source_refs) == "table"
        and contract.effect_failure_retryability[value.retryability] == true
        and type(value.cost) == "table"
        and cost ~= nil
        and value.event_truth_status == "runtime_confirmed"
end

return contract
