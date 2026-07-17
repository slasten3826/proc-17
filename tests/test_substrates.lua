package.path = "./?.lua;./?/init.lua;" .. package.path

local openai = require("substrates.openai_compatible")
local deepseek = require("substrates.deepseek")
local contract = require("substrates.contract")

local sample = {
    id = "sample",
    choices = {
        {
            message = {
                role = "assistant",
                content = "sample answer",
                reasoning_content = "sample reasoning",
            },
        },
    },
    usage = {
        prompt_tokens = 1,
        completion_tokens = 2,
    },
}

local normalized = openai.normalize_chat_response(sample, "raw", {
    provider = "deepseek",
    model = "deepseek-chat",
})

if normalized.text ~= "sample answer" then
    error("normalized text mismatch")
end

if normalized.reasoning_text ~= "sample reasoning" then
    error("normalized reasoning mismatch")
end

if normalized.provider_metadata.provider ~= "deepseek" then
    error("provider metadata mismatch")
end

if normalized.provider_metadata.actual_model ~= "deepseek-chat" then
    error("actual model fallback mismatch")
end

local caps = deepseek.capabilities()
if caps.provider ~= "deepseek" then
    error("deepseek capabilities mismatch")
end

local failure = contract.effect_failure({
    source = "substrate",
    code = "connection_lost",
    message = "test failure",
    retryability = "retryable",
    cost = {substrate_calls = 1},
})
if not contract.is_effect_failure(failure) then
    error("well-formed effect failure rejected")
end
if contract.is_effect_failure({
    kind = "effect_failure",
    source = "substrate",
    code = "connection_lost",
}) then
    error("partial effect failure accepted")
end

local invalid_retry = pcall(contract.effect_failure, {
    source = "substrate",
    code = "connection_lost",
    retryability = "maybe",
})
if invalid_retry then
    error("invalid effect failure retryability accepted")
end

local missing_config_response, missing_config_failure = openai.ask({
    mode = "natural",
    operator = "☴",
    task = "config boundary test",
}, {})
if missing_config_response ~= nil
    or not contract.is_effect_failure(missing_config_failure)
    or missing_config_failure.code ~= "missing_api_key"
    or next(missing_config_failure.cost) ~= nil then
    error("OpenAI-compatible adapter did not type missing configuration")
end

print("test_substrates ok")
