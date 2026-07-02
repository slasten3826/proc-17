local contract = require("tools.contract")
local sandbox = require("core.sandbox")

local fs = {}

local default_ignored = {
    ".git",
    ".agents",
    ".codex",
    "node_modules",
    "vendor",
    "tmp",
}

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function read_all(path)
    local file, err = io.open(path, "r")
    if not file then
        return nil, err
    end
    local content = file:read("*a")
    file:close()
    return content
end

local function write_all(path, content)
    local file, err = io.open(path, "w")
    if not file then
        return nil, err
    end
    file:write(content or "")
    file:close()
    return true
end

local function exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

local function make_dir(path)
    local ok, err = os.rename(path, path)
    if ok then
        return true
    end
    local command = "mkdir " .. shell_quote(path)
    local result = os.execute(command)
    if result == true or result == 0 then
        return true
    end
    return nil, err or "mkdir failed"
end

local function is_ignored_path(path, ignored)
    for _, name in ipairs(ignored or default_ignored) do
        if path == name or path:sub(1, #name + 1) == name .. "/" then
            return true
        end
    end
    return false
end

local function normalize_listed_path(path)
    if path == "." then
        return "."
    end
    return (path:gsub("^%./", ""))
end

local function list_dir(prefix, limits, ignored)
    limits = limits or {}
    ignored = ignored or default_ignored

    local max_depth = limits.max_depth or 4
    local max_entries = limits.max_entries or 128
    local max_path_bytes = limits.max_path_bytes or 240
    local command_parts = {
        "find",
        shell_quote(prefix),
        "-maxdepth",
        tostring(max_depth),
        "\\(",
    }
    for index, name in ipairs(ignored) do
        if index > 1 then
            command_parts[#command_parts + 1] = "-o"
        end
        command_parts[#command_parts + 1] = "-name"
        command_parts[#command_parts + 1] = shell_quote(name)
    end
    command_parts[#command_parts + 1] = "\\)"
    command_parts[#command_parts + 1] = "-prune"
    command_parts[#command_parts + 1] = "-o"
    command_parts[#command_parts + 1] = "-printf"
    command_parts[#command_parts + 1] = shell_quote("%y\t%s\t%p\n")
    command_parts[#command_parts + 1] = "2>/dev/null"

    local command = table.concat(command_parts, " ")

    local handle = io.popen(command)
    if not handle then
        return nil, "failed to start listing"
    end

    local entries = {}
    local truncated = false
    local truncation_reason

    for line in handle:lines() do
        local kind_code, size, path = line:match("^([df])\t(%d+)\t(.+)$")
        path = path and normalize_listed_path(path)
        if path and not is_ignored_path(path, ignored) and #path <= max_path_bytes then
            if #entries >= max_entries then
                truncated = true
                truncation_reason = truncation_reason or "max_entries"
            else
                entries[#entries + 1] = {
                    path = path,
                    kind = kind_code == "d" and "directory" or "file",
                    bytes = kind_code == "f" and tonumber(size) or nil,
                    truth_status = "runtime_confirmed",
                }
            end
        elseif path and #path > max_path_bytes then
            truncated = true
            truncation_reason = truncation_reason or "max_path_bytes"
        end
    end

    local ok_close = handle:close()
    if not ok_close and #entries == 0 then
        return nil, "listing failed"
    end
    table.sort(entries, function(left, right)
        return left.path < right.path
    end)

    return {
        entries = entries,
        ignored = ignored,
        limits = {
            max_depth = max_depth,
            max_entries = max_entries,
            max_path_bytes = max_path_bytes,
        },
        truncated = truncated,
        truncation_reason = truncation_reason,
    }
end

function fs.run(call)
    local ok, err = contract.validate_call(call)
    if not ok then
        return contract.normalize_result({
            ok = false,
            action = call and call.action,
            error = err,
            metadata = {tool = "fs"},
        })
    end

    local input = call.input or {}
    local path = input.path
    local context = input.context or "body"

    if call.action == "read_file" then
        local allowed, reason = sandbox.can_read_file({mode = input.mode, context = context}, path)
        if not allowed then
            return contract.normalize_result({
                ok = false,
                action = call.action,
                error = reason,
                metadata = {tool = "fs", path = path},
            })
        end

        local content, read_err = read_all(path)
        if not content then
            return contract.normalize_result({
                ok = false,
                action = call.action,
                error = read_err,
                metadata = {tool = "fs", path = path},
            })
        end

        return contract.normalize_result({
            ok = true,
            action = call.action,
            output = {
                path = path,
                content = content,
                bytes = #content,
            },
            metadata = {tool = "fs"},
        })
    elseif call.action == "list_dir" then
        local prefix = path or "."
        local allowed, reason = sandbox.can_read_file({mode = input.mode, context = context}, prefix)
        if not allowed then
            return contract.normalize_result({
                ok = false,
                action = call.action,
                error = reason,
                metadata = {tool = "fs", path = prefix},
            })
        end

        local output, list_err = list_dir(prefix, input.limits, input.ignored)
        if not output then
            return contract.normalize_result({
                ok = false,
                action = call.action,
                error = list_err,
                metadata = {tool = "fs", path = prefix},
            })
        end

        output.prefix = prefix
        return contract.normalize_result({
            ok = true,
            action = call.action,
            output = output,
            metadata = {tool = "fs"},
        })
    elseif call.action == "write_file" then
        local mode = input.mode or "manifest"
        local allowed, reason = sandbox.can_write_file({mode = mode, context = context}, path)
        if not allowed then
            return contract.normalize_result({
                ok = false,
                action = call.action,
                error = reason,
                metadata = {
                    tool = "fs",
                    mode = mode,
                    path = path,
                    write_performed = false,
                },
            })
        end

        local write_mode = input.write_mode or (context == "workspace" and "create_only" or "overwrite")
        if write_mode ~= "create_only" and write_mode ~= "overwrite" then
            return contract.normalize_result({
                ok = false,
                action = call.action,
                error = "invalid write mode",
                metadata = {
                    tool = "fs",
                    mode = mode,
                    context = context,
                    path = path,
                    write_mode = write_mode,
                    write_performed = false,
                },
            })
        end
        if write_mode == "create_only" and exists(path) then
            return contract.normalize_result({
                ok = false,
                action = call.action,
                error = "target already exists",
                metadata = {
                    tool = "fs",
                    mode = mode,
                    context = context,
                    path = path,
                    write_mode = write_mode,
                    write_performed = false,
                },
            })
        end

        local content = input.content or ""
        local write_ok, write_err = write_all(path, content)
        if not write_ok then
            return contract.normalize_result({
                ok = false,
                action = call.action,
                error = write_err,
                metadata = {
                    tool = "fs",
                    mode = mode,
                    context = context,
                    path = path,
                    write_mode = write_mode,
                    write_performed = false,
                },
            })
        end

        return contract.normalize_result({
            ok = true,
            action = call.action,
            output = {
                path = path,
                bytes = #content,
            },
            metadata = {
                tool = "fs",
                mode = mode,
                context = context,
                path = path,
                write_mode = write_mode,
                write_performed = true,
            },
        })
    elseif call.action == "make_dir" then
        local mode = input.mode or "manifest"
        local allowed, reason = sandbox.can_make_dir({mode = mode, context = context}, path)
        if not allowed then
            return contract.normalize_result({
                ok = false,
                action = call.action,
                error = reason,
                metadata = {
                    tool = "fs",
                    mode = mode,
                    context = context,
                    path = path,
                    dir_created = false,
                },
            })
        end

        local ok_dir, dir_err = make_dir(path)
        if not ok_dir then
            return contract.normalize_result({
                ok = false,
                action = call.action,
                error = dir_err,
                metadata = {
                    tool = "fs",
                    mode = mode,
                    context = context,
                    path = path,
                    dir_created = false,
                },
            })
        end

        return contract.normalize_result({
            ok = true,
            action = call.action,
            output = {
                path = path,
            },
            metadata = {
                tool = "fs",
                mode = mode,
                context = context,
                path = path,
                dir_created = true,
            },
        })
    end

    return contract.normalize_result({
        ok = false,
        action = call.action,
        error = "fs tool supports only read_file and write_file",
        metadata = {tool = "fs"},
    })
end

return fs
