package.path = "./?.lua;./?/init.lua;" .. package.path

local openai = require("substrates.openai_compatible")
local deepseek = require("substrates.deepseek")

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

print("test_substrates ok")
