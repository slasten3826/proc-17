local modes = require("core.modes")

local sandbox = {}

local function context_mode(context)
    return context and context.mode or "manifest"
end

function sandbox.check_path(path)
    if type(path) ~= "string" or path == "" then
        return false, "path is required"
    end
    if path:sub(1, 1) == "/" then
        return false, "absolute paths are not allowed"
    end
    for part in path:gmatch("[^/]+") do
        if part == ".." then
            return false, "parent traversal is not allowed"
        end
    end
    return true
end

function sandbox.can_read_file(context, path)
    local ok, reason = sandbox.check_path(path)
    if not ok then
        return false, reason
    end
    return true, "relative workspace reads are allowed"
end

function sandbox.can_write_file(context, path)
    local ok, reason = sandbox.check_path(path)
    if not ok then
        return false, reason
    end
    return modes.can_write_path(context_mode(context), path)
end

function sandbox.can_run_command(context, command)
    return false, "shell commands are denied by sandbox.v0"
end

return sandbox
