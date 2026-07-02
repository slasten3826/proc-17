local modes = require("core.modes")

local sandbox = {}
sandbox.WORKSPACE_ROOT = "sandbox"

local function context_mode(context)
    return context and context.mode or "manifest"
end

local function context_kind(context)
    return context and context.context or "body"
end

local function is_hidden_control_part(part)
    return part == ".git" or part == ".agents" or part == ".codex"
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
        if is_hidden_control_part(part) then
            return false, "hidden control directories are not allowed"
        end
    end
    return true
end

function sandbox.workspace_root()
    return sandbox.WORKSPACE_ROOT
end

function sandbox.is_workspace_path(path)
    return type(path) == "string"
        and (path == sandbox.WORKSPACE_ROOT or path:sub(1, #sandbox.WORKSPACE_ROOT + 1) == sandbox.WORKSPACE_ROOT .. "/")
end

local function can_workspace_path(path)
    local ok, reason = sandbox.check_path(path)
    if not ok then
        return false, reason
    end
    if not sandbox.is_workspace_path(path) then
        return false, "workspace context requires sandbox path"
    end
    return true, "workspace sandbox path allowed"
end

function sandbox.can_read_file(context, path)
    if context_kind(context) == "workspace" then
        return can_workspace_path(path)
    end
    local ok, reason = sandbox.check_path(path)
    if not ok then
        return false, reason
    end
    return true, "relative workspace reads are allowed"
end

function sandbox.can_write_file(context, path)
    if context_kind(context) == "workspace" then
        return can_workspace_path(path)
    end
    local ok, reason = sandbox.check_path(path)
    if not ok then
        return false, reason
    end
    return modes.can_write_path(context_mode(context), path)
end

function sandbox.can_make_dir(context, path)
    if context_kind(context) == "workspace" then
        return can_workspace_path(path)
    end
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
