local fs = require("tools.fs")
local json = require("core.json")
local packet_core = require("core.packet")

local repo_listing = {}

local default_limits = {
    max_depth = 4,
    max_entries = 128,
    max_path_bytes = 240,
}

local default_ignored = {
    ".git",
    ".agents",
    ".codex",
    "node_modules",
    "vendor",
    "tmp",
}

local function copy_list(source)
    local result = {}
    for index, value in ipairs(source or {}) do
        result[index] = value
    end
    return result
end

local function copy_limits(options)
    options = options or {}
    return {
        max_depth = options.max_depth or default_limits.max_depth,
        max_entries = options.max_entries or default_limits.max_entries,
        max_path_bytes = options.max_path_bytes or default_limits.max_path_bytes,
    }
end

function repo_listing.build(options)
    options = options or {}
    local prefix = options.prefix or "."
    local limits = copy_limits(options)
    local ignored = copy_list(options.ignored or default_ignored)

    local result = fs.run({
        action = "list_dir",
        input = {
            path = prefix,
            mode = options.mode,
            limits = limits,
            ignored = ignored,
        },
    })

    if not result.ok then
        return nil, result.error
    end

    return {
        kind = "repo_listing_payload",
        root = ".",
        prefix = result.output.prefix,
        entries = result.output.entries or {},
        limits = result.output.limits or limits,
        ignored = result.output.ignored or ignored,
        truncated = result.output.truncated == true,
        truncation_reason = result.output.truncation_reason,
        truth_status = "runtime_confirmed",
    }
end

function repo_listing.attach(packet_instance, options)
    local payload, err = repo_listing.build(options)
    if not payload then
        return nil, err
    end

    packet_instance.context = packet_instance.context or {}
    packet_instance.context.repo_listing = payload

    packet_core.append(packet_instance, {
        type = "observation",
        operator = "☴",
        truth_status = "runtime_confirmed",
        payload = {
            kind = "repo_listing",
            repo_listing = payload,
        },
        cost = {tool_calls = 1},
    })

    return payload
end

function repo_listing.format_for_substrate(payload)
    if not payload then
        return ""
    end

    return table.concat({
        "Runtime-confirmed repo listing follows.",
        "Treat this as bounded evidence. Do not infer paths outside it.",
        json.encode(payload),
    }, "\n")
end

return repo_listing
