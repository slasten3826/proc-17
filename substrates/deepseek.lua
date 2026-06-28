local openai = require("substrates.openai_compatible")

local deepseek = {}

deepseek.provider = "deepseek"
deepseek.default_model = "deepseek-chat"
deepseek.default_base_url = "https://api.deepseek.com"

function deepseek.capabilities()
    return {
        provider = deepseek.provider,
        model = deepseek.default_model,
        context_window = "provider_defined",
        tool_calling = false,
        json_mode = false,
        vision = false,
        streaming = false,
        latency_class = "network",
        cost_class = "external_api",
        coding_strength = "unknown_until_measured",
        reasoning_strength = "unknown_until_measured",
        known_failure_modes = {
            "semantic proposal may be unsupported",
            "provider/network errors",
            "model-specific drift",
        },
    }
end

function deepseek.ask(call, options)
    options = options or {}
    return openai.ask(call, {
        provider = deepseek.provider,
        api_key = options.api_key or os.getenv("DEEPSEEK_API_KEY"),
        base_url = options.base_url or deepseek.default_base_url,
        model = options.model or deepseek.default_model,
        temperature = options.temperature,
    })
end

return deepseek
