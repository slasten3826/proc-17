local fs = require("tools.fs")
local json = require("core.json")
local packet_core = require("core.packet")

local repo_context = {}

local default_limits = {
    max_files = 8,
    max_bytes_per_file = 12000,
}

local function copy_limits(options)
    options = options or {}
    return {
        max_files = options.max_files or default_limits.max_files,
        max_bytes_per_file = options.max_bytes_per_file or default_limits.max_bytes_per_file,
    }
end

local function split_paths(value)
    if type(value) == "table" then
        return value
    end

    local result = {}
    for item in tostring(value or ""):gmatch("[^,]+") do
        local trimmed = item:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            result[#result + 1] = trimmed
        end
    end
    return result
end

local function truncate_content(content, max_bytes)
    if #content <= max_bytes then
        return content, false
    end
    return content:sub(1, max_bytes), true
end

function repo_context.build(options)
    options = options or {}
    local limits = copy_limits(options)
    local paths = split_paths(options.files or options.paths)

    if #paths == 0 then
        return nil, "repo context requires explicit files"
    end
    if #paths > limits.max_files then
        return nil, "repo context file limit exceeded"
    end

    local payload = {
        kind = "repo_context_payload",
        file_tree = options.file_tree or {},
        selected_files = {},
        files = {},
        limits = limits,
    }

    for _, path in ipairs(paths) do
        local result = fs.run({
            action = "read_file",
            input = {
                path = path,
                mode = options.mode,
            },
        })

        if not result.ok then
            return nil, result.error
        end

        local content, truncated = truncate_content(result.output.content or "", limits.max_bytes_per_file)
        payload.selected_files[#payload.selected_files + 1] = path
        payload.files[#payload.files + 1] = {
            path = result.output.path,
            content = content,
            bytes = #content,
            source_bytes = result.output.bytes,
            truncated = truncated,
            truth_status = "runtime_confirmed",
        }
    end

    return payload
end

function repo_context.attach(packet_instance, options)
    local payload, err = repo_context.build(options)
    if not payload then
        return nil, err
    end

    packet_instance.context = packet_instance.context or {}
    packet_instance.context.repo_context = payload

    packet_core.append(packet_instance, {
        type = "observation",
        operator = "☴",
        truth_status = "runtime_confirmed",
        payload = {
            kind = "repo_context",
            repo_context = payload,
        },
        cost = {tool_calls = #payload.files},
    })

    return payload
end

function repo_context.format_for_substrate(payload)
    if not payload then
        return ""
    end

    return table.concat({
        "Runtime-confirmed repo context follows.",
        "Treat this as evidence. Do not infer repository structure outside it.",
        json.encode(payload),
    }, "\n")
end

return repo_context
