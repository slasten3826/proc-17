local sandbox = require("core.sandbox")

local spells = {}

local function stable_hash(value)
    local text = tostring(value or "")
    local hash = 2166136261
    for index = 1, #text do
        hash = (hash ~ text:byte(index)) * 16777619 % 4294967296
    end
    return string.format("%08x", hash)
end

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

local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

local function run_command(command)
    local handle = io.popen(command .. " 2>&1")
    if not handle then
        return "", "failed_to_start", 1
    end
    local output = handle:read("*a") or ""
    local ok, reason, code = handle:close()
    if ok == true then
        return output, "", 0
    end
    return "", output, code or reason or 1
end

local function result(input, fields)
    local success = fields.success == true
    return {
        kind = "spell_result",
        name = input.name or input.kind,
        spell_kind = input.kind,
        intention_hash = stable_hash(input.intention or input.name or input.kind),
        command_or_code = fields.command_or_code,
        executed = fields.executed == true,
        success = success,
        reality_changed = success and fields.reality_changed == true,
        stdout = fields.stdout or "",
        stderr = fields.stderr or "",
        exit_code = fields.exit_code,
        cast_tick = input.tick,
        referent = fields.referent,
        referent_hash = fields.referent_hash,
        truth_status = "runtime_confirmed",
    }
end

local function hash_file_content(path)
    local content = read_all(path)
    if content == nil then
        return nil
    end
    return stable_hash(content)
end

local function checked_path(input)
    local path = input.path
    local ok, reason = sandbox.check_path(path)
    if not ok then
        return nil, reason
    end
    return path
end

local function py_compile(input)
    local path, path_err = checked_path(input)
    if not path then
        return nil, path_err
    end
    local command = "python3 -m py_compile " .. shell_quote(path)
    local stdout, stderr, exit_code = run_command(command)
    return result(input, {
        command_or_code = {"python3", "-m", "py_compile", path},
        executed = true,
        success = exit_code == 0,
        reality_changed = false,
        stdout = stdout,
        stderr = stderr,
        exit_code = exit_code,
        referent = path,
        referent_hash = hash_file_content(path),
    })
end

local function check_file_exists(input)
    local path, path_err = checked_path(input)
    if not path then
        return nil, path_err
    end
    local exists = file_exists(path)
    return result(input, {
        command_or_code = "exists:" .. path,
        executed = true,
        success = exists,
        reality_changed = false,
        stdout = exists and "exists" or "",
        stderr = exists and "" or "missing",
        exit_code = exists and 0 or 1,
        referent = path,
        referent_hash = hash_file_content(path),
    })
end

local function validate_json_file(input)
    local path, path_err = checked_path(input)
    if not path then
        return nil, path_err
    end
    local command = "python3 -m json.tool " .. shell_quote(path)
    local stdout, stderr, exit_code = run_command(command)
    return result(input, {
        command_or_code = {"python3", "-m", "json.tool", path},
        executed = true,
        success = exit_code == 0,
        reality_changed = false,
        stdout = stdout,
        stderr = stderr,
        exit_code = exit_code,
        referent = path,
        referent_hash = hash_file_content(path),
    })
end

local function check_command_exit_code(input)
    local command = input.command
    if type(command) ~= "table" or #command == 0 then
        return nil, "command table required"
    end
    local parts = {}
    for _, part in ipairs(command) do
        parts[#parts + 1] = shell_quote(part)
    end
    local stdout, stderr, exit_code = run_command(table.concat(parts, " "))
    local expected = input.expected and input.expected.exit_code or 0
    return result(input, {
        command_or_code = command,
        executed = true,
        success = exit_code == expected,
        reality_changed = false,
        stdout = stdout,
        stderr = stderr,
        exit_code = exit_code,
    })
end

local function loss_threshold(input)
    local loss = input.loss
    if type(loss) ~= "table" then
        return result(input, {
            command_or_code = "loss_threshold",
            executed = true,
            success = false,
            reality_changed = false,
            stdout = "",
            stderr = "loss table required",
            exit_code = 1,
        })
    end

    local threshold = input.threshold
    if threshold == nil then
        threshold = 0.50
    end
    if type(threshold) ~= "number" then
        return result(input, {
            command_or_code = "loss_threshold",
            executed = true,
            success = false,
            reality_changed = false,
            stdout = "",
            stderr = "numeric threshold required",
            exit_code = 1,
        })
    end

    local percentage = loss.loss_percentage
    if type(percentage) ~= "number" then
        return result(input, {
            command_or_code = "loss_threshold",
            executed = true,
            success = false,
            reality_changed = false,
            stdout = "",
            stderr = "loss.loss_percentage required",
            exit_code = 1,
        })
    end

    local acceptable = percentage <= threshold
    local omitted = loss.omitted_count or 0
    local loss_log_count = #(loss.loss_log or {})
    return result(input, {
        command_or_code = {
            "loss_threshold",
            "loss_percentage=" .. tostring(percentage),
            "threshold=" .. tostring(threshold),
        },
        executed = true,
        success = acceptable,
        reality_changed = false,
        stdout = string.format(
            "loss_percentage=%.2f threshold=%.2f omitted_count=%s loss_log_count=%s verdict=%s",
            percentage,
            threshold,
            tostring(omitted),
            tostring(loss_log_count),
            acceptable and "acceptable" or "unacceptable"
        ),
        stderr = acceptable and "" or "loss threshold exceeded",
        exit_code = acceptable and 0 or 1,
    })
end

local runners = {
    py_compile_python_file = py_compile,
    check_file_exists = check_file_exists,
    validate_json_file = validate_json_file,
    check_command_exit_code = check_command_exit_code,
    loss_threshold = loss_threshold,
}

function spells.run(input)
    input = input or {}
    if type(input.kind) ~= "string" or input.kind == "" then
        return nil, "spell kind required"
    end
    local runner = runners[input.kind]
    if not runner then
        return nil, "unsupported spell kind"
    end
    return runner(input)
end

function spells.hash(value)
    return stable_hash(value)
end

function spells.referent_hash(path)
    if type(path) ~= "string" or path == "" then
        return nil
    end
    local ok = sandbox.check_path(path)
    if not ok then
        return nil
    end
    return hash_file_content(path)
end

return spells
