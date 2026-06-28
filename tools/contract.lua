local contract = {}

contract.actions = {
    inspect_task = true,
    read_file = true,
    list_dir = true,
    run_command = true,
}

function contract.validate_call(call)
    if type(call) ~= "table" then
        return false, "tool call must be table"
    end
    if not contract.actions[call.action] then
        return false, "invalid tool action"
    end
    return true
end

function contract.normalize_result(result)
    result = result or {}
    return {
        ok = result.ok == true,
        action = result.action,
        output = result.output,
        error = result.error,
        metadata = result.metadata or {},
    }
end

return contract
