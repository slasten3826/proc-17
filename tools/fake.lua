local contract = require("tools.contract")

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

    return contract.normalize_result({
        ok = true,
        action = call.action,
        output = {simulated = true},
        metadata = {tool = "fake"},
    })
end

return fake
