local packet_core = require("core.packet")
local system_prompt = require("runtime.system_prompt")
local substrate_contract = require("substrates.contract")

local observe = {}

local function prompt_payload(instance, options)
    options = options or {}
    if options.prompt_payload ~= nil then
        return options.prompt_payload
    end
    return instance.chaos and instance.chaos.raw_prompt or ""
end

local function build_call(instance, options)
    options = options or {}
    local call = {
        mode = options.mode or "mixed",
        operator = "☴",
        prompt_payload = prompt_payload(instance, options),
        expected_shape = "semantic_proposal",
        work_mode = options.work_mode or "build",
        system_prompt = options.system_prompt or system_prompt.format({
            work_mode = options.work_mode or "build",
        }),
    }
    return call
end

function observe.run(instance, substrate, options)
    options = options or {}
    if type(substrate) ~= "table" or type(substrate.ask) ~= "function" then
        return nil, "missing_substrate"
    end

    local call = build_call(instance, options)
    local ok, err = substrate_contract.validate_call(call)
    if not ok then
        return nil, err
    end

    local response, ask_err = substrate.ask(call, options.substrate_options or {})
    if not response then
        return nil, ask_err or "substrate_failed"
    end

    local normalized = substrate_contract.normalize_response(response)
    local _, event = packet_core.append_chaos(instance, {
        operator = "☴",
        kind = "substrate_response",
        text = normalized.text,
        reasoning_text = normalized.reasoning_text,
        tool_intents = normalized.tool_intents,
        usage = normalized.usage,
        latency = normalized.latency,
        provider_metadata = normalized.provider_metadata,
        raw = normalized.raw,
        call = call,
        truth_status = "semantic_proposal",
    })

    return instance, {
        kind = "observe_organ_payload",
        response = normalized,
        call = call,
        trace_event_id = event.id,
        truth_status = "semantic_proposal",
    }
end

return observe

