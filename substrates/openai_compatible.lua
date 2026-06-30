local json = require("core.json")
local contract = require("substrates.contract")

local openai = {}

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function write_file(path, data)
    local file, err = io.open(path, "w")
    if not file then
        return nil, err
    end
    file:write(data)
    file:close()
    return true
end

local function remove_file(path)
    pcall(os.remove, path)
end

function openai.build_messages(call)
    local payload = call.prompt_payload or call.task
    if type(payload) == "table" then
        return payload
    end

    return {
        {
            role = "system",
            content = call.system_prompt or "You are substrate current. Return semantic proposal only; runtime truth belongs to the body.",
        },
        {
            role = "user",
            content = tostring(payload),
        },
    }
end

function openai.build_request(call, config)
    config = config or {}
    return {
        model = call.model or config.model,
        messages = openai.build_messages(call),
        temperature = call.temperature or config.temperature or 0.2,
        stream = false,
    }
end

function openai.normalize_chat_response(decoded, raw, metadata)
    metadata = metadata or {}
    local choice = decoded and decoded.choices and decoded.choices[1]
    local message = choice and choice.message or {}
    return contract.normalize_response({
        text = message.content or "",
        reasoning_text = message.reasoning_content,
        usage = decoded and decoded.usage or {},
        provider_metadata = {
            provider = metadata.provider,
            model = metadata.model,
            actual_model = decoded and decoded.model or metadata.model,
            http_status = metadata.http_status,
        },
        raw = raw,
    })
end

function openai.ask(call, config)
    config = config or {}
    local ok, err = contract.validate_call(call)
    if not ok then
        return nil, err
    end
    if not config.api_key or config.api_key == "" then
        return nil, "api key is required"
    end
    if not config.base_url or config.base_url == "" then
        return nil, "base_url is required"
    end
    if not config.model or config.model == "" then
        return nil, "model is required"
    end

    local request = openai.build_request(call, config)
    local request_path = os.tmpname()
    local write_ok, write_err = write_file(request_path, json.encode(request))
    if not write_ok then
        return nil, write_err
    end

    local command = table.concat({
        "curl",
        "-sS",
        "-w", shell_quote("\n%{http_code}"),
        "-H", shell_quote("Content-Type: application/json"),
        "-H", shell_quote("Authorization: Bearer " .. config.api_key),
        "--data-binary", "@" .. shell_quote(request_path),
        shell_quote(config.base_url .. "/chat/completions"),
    }, " ")

    local handle = io.popen(command)
    if not handle then
        remove_file(request_path)
        return nil, "failed to start curl"
    end

    local output = handle:read("*a")
    local ok_close = handle:close()
    remove_file(request_path)

    if not ok_close then
        return nil, "curl failed"
    end

    local body, code = output:match("^(.*)\n(%d%d%d)%s*$")
    if not body then
        return nil, "invalid curl response"
    end
    if tonumber(code) < 200 or tonumber(code) >= 300 then
        return nil, "http " .. code .. ": " .. body
    end

    local decode_ok, decoded = pcall(json.decode, body)
    if not decode_ok then
        return nil, "invalid json response: " .. tostring(decoded)
    end

    return openai.normalize_chat_response(decoded, body, {
        provider = config.provider,
        model = config.model,
        http_status = tonumber(code),
    })
end

return openai
