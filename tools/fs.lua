local contract = require("tools.contract")
local sandbox = require("core.sandbox")

local fs = {}

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

    if call.action == "read_file" then
        local allowed, reason = sandbox.can_read_file({mode = input.mode}, path)
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
    elseif call.action == "write_file" then
        local mode = input.mode or "manifest"
        local allowed, reason = sandbox.can_write_file({mode = mode}, path)
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
                    path = path,
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
                path = path,
                write_performed = true,
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
