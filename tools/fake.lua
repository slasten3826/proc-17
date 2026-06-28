local contract = require("tools.contract")
local modes = require("core.modes")

local fake = {}

function fake.run(call)
    local ok, err = contract.validate_call(call)
    if not ok then
        return contract.normalize_result({
            ok = false,
            action = call and call.action,
            error = err,
        })
    end

    if call.action == "inspect_task" then
        return contract.normalize_result({
            ok = true,
            action = call.action,
            output = {
                task = call.input and call.input.task,
                observed = true,
                source = "fake_tool",
            },
            metadata = {tool = "fake"},
        })
    end

    if call.action == "write_file" then
        local input = call.input or {}
        local ok_path, reason = modes.can_write_path(input.mode or "manifest", input.path)
        if not ok_path then
            return contract.normalize_result({
                ok = false,
                action = call.action,
                error = reason,
                metadata = {
                    tool = "fake",
                    mode = input.mode,
                    path = input.path,
                    write_performed = false,
                },
            })
        end

        return contract.normalize_result({
            ok = true,
            action = call.action,
            output = {
                path = input.path,
                bytes = #(input.content or ""),
                write_performed = false,
            },
            metadata = {
                tool = "fake",
                mode = input.mode,
                permission_checked = true,
            },
        })
    end

    return contract.normalize_result({
        ok = true,
        action = call.action,
        output = {simulated = true},
        metadata = {tool = "fake"},
    })
end

return fake
