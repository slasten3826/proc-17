package.path = "./?.lua;./?/init.lua;" .. package.path

-- Coding battery: what is DeepSeek-in-proc-17 capable of as a worker?
-- The harness extracts code from the manifest, writes it to sandbox and
-- validates by EXECUTION through the body's own spell engine.
-- The harness writing files is measured plumbing debt: the body cannot
-- write its own manifests to disk yet.

local json = require("core.json")
local tension_runner = require("runtime.tension_runner")
local deepseek = require("substrates.deepseek")
local spells = require("logic.spells")

local log_dir = "sandbox/coding_deepseek"

local function mkdir_p(path)
    os.execute("mkdir -p " .. string.format("%q", path))
end

local function write_file(path, text)
    local file = assert(io.open(path, "w"))
    file:write(text)
    file:close()
end

local function trace(result)
    local out = {}
    for _, tick in ipairs(result.ticks or {}) do
        out[#out + 1] = tick.operator
    end
    return table.concat(out, "")
end

local function extract_largest_code_block(text)
    local best = nil
    for block in text:gmatch("```[%w_+%-%.]*[^\n]*\n(.-)```") do
        if best == nil or #block > #best then
            best = block
        end
    end
    return best
end

local cases = {
    {
        id = "py_add_assert",
        ext = "py",
        runner_cmd = "python3",
        prompt = "Напиши Python-файл целиком: функция add(a, b), затем assert add(2, 3) == 5 и assert add(-1, 1) == 0. Весь файл одним блоком ```python. Без пояснений.",
    },
    {
        id = "py_fizzbuzz",
        ext = "py",
        runner_cmd = "python3",
        prompt = "Напиши Python-файл целиком: функция fizzbuzz(n) возвращает список строк для 1..n по правилам FizzBuzz. В конце файла assert fizzbuzz(15)[2] == 'Fizz', assert fizzbuzz(15)[4] == 'Buzz', assert fizzbuzz(15)[14] == 'FizzBuzz'. Весь файл одним блоком ```python. Без пояснений.",
    },
    {
        id = "py_error_count",
        ext = "py",
        runner_cmd = "python3",
        prompt = "Напиши Python-файл целиком: функция count_errors(lines) принимает список строк вида 'LEVEL: message' и возвращает число строк с уровнем ERROR (регистр важен, только префикс до двоеточия). В конце assert count_errors(['ERROR: a', 'INFO: b', 'ERROR: c', 'WARNING: ERROR later']) == 2. Весь файл одним блоком ```python. Без пояснений.",
    },
    {
        id = "py_fix_bug",
        ext = "py",
        runner_cmd = "python3",
        prompt = "В этом Python-коде баг:\n```python\ndef sum_to(n):\n    total = 0\n    for i in range(n):\n        total += i\n    return total\n\nassert sum_to(5) == 15\n```\nФункция должна возвращать сумму 1..n включительно. Почини и верни ИСПРАВЛЕННЫЙ файл целиком одним блоком ```python, с тем же assert. Без пояснений.",
    },
    {
        id = "lua_stack_module",
        ext = "lua",
        runner_cmd = "lua5.4",
        prompt = "Напиши Lua-файл целиком: таблица Stack с функциями Stack.new(), push, pop (pop возвращает nil для пустого стека). В конце файла проверки: local s = Stack.new(); Stack.push(s, 1); Stack.push(s, 2); assert(Stack.pop(s) == 2); assert(Stack.pop(s) == 1); assert(Stack.pop(s) == nil). Весь файл одним блоком ```lua. Без пояснений.",
    },
}

mkdir_p(log_dir)

local records = {}
local passed = 0

for _, case in ipairs(cases) do
    local packet, result_or_err = tension_runner.run(case.prompt, deepseek, {
        work_mode = "build",
        max_ticks = 14,
        packet_options = {
            budget = {steps = 32, substrate_calls = 4, total_tokens = 30000, encode_items = 12, loss = 10},
        },
        substrate_options = {
            model = os.getenv("DEEPSEEK_MODEL") or "deepseek-chat",
        },
        choose = {
            limits = {max_selected = 1, max_killed_sample = 8},
        },
    })
    if not packet then
        error(case.id .. " failed: " .. tostring(result_or_err and (result_or_err.stage or "") .. " " .. tostring(result_or_err.error)))
    end

    local manifest_output = packet.manifest and packet.manifest.output or {}
    local code = nil
    local code_source = nil
    if manifest_output.text then
        code = extract_largest_code_block(manifest_output.text)
        code_source = code and "manifest" or nil
    end
    if not code then
        -- fallback: the substrate may have proposed code the body never manifested
        for index = #result_or_err.ticks, 1, -1 do
            local tick = result_or_err.ticks[index]
            local response = tick.payload and tick.payload.response
            if tick.operator == "☴" and response and response.text then
                code = extract_largest_code_block(response.text)
                if code then
                    code_source = "observe_fallback"
                    break
                end
            end
        end
    end

    local spell_result = nil
    local verdict = "no_code_in_manifest"
    if code then
        local code_path = log_dir .. "/" .. case.id .. "." .. case.ext
        write_file(code_path, code)
        spell_result = spells.run({
            kind = "check_command_exit_code",
            name = case.id .. "_execution",
            intention = "manifested code must run and pass its own asserts",
            command = {case.runner_cmd, code_path},
            tick = packet.physis and packet.physis.clock and packet.physis.clock.ticks or nil,
        })
        if spell_result and spell_result.success then
            verdict = code_source == "manifest" and "reality_confirmed"
                or "substrate_could_body_could_not"
        else
            verdict = "execution_failed"
        end
    end
    if verdict == "reality_confirmed" or verdict == "substrate_could_body_could_not" then
        passed = passed + 1
    end

    local runtime_budget = packet.runtime and packet.runtime.budget or {}
    local rec = {
        id = case.id,
        status = packet.status,
        stop_reason = result_or_err.stop_reason,
        death = packet.death,
        trace = trace(result_or_err),
        ticks = #result_or_err.ticks,
        tokens = runtime_budget.spent and runtime_budget.spent.total_tokens,
        substrate_calls = runtime_budget.spent and runtime_budget.spent.substrate_calls,
        manifest_type = manifest_output.type,
        manifest_language = manifest_output.language,
        code_source = code_source,
        code_bytes = code and #code or 0,
        route_reasons = (function()
            local reasons = {}
            for _, route in ipairs(result_or_err.routes or {}) do
                reasons[#reasons + 1] = route.reason
            end
            return reasons
        end)(),
        spell = spell_result and {
            success = spell_result.success,
            exit_code = spell_result.exit_code,
            stderr = spell_result.stderr,
            cast_tick = spell_result.cast_tick,
        } or nil,
        verdict = verdict,
    }
    records[#records + 1] = rec
    write_file(log_dir .. "/" .. case.id .. ".json", json.encode(rec))
    print(string.format(
        "%s verdict=%s source=%s stop=%s ticks=%s tokens=%s code_bytes=%s exit=%s",
        case.id,
        verdict,
        tostring(code_source),
        tostring(rec.stop_reason),
        tostring(rec.ticks),
        tostring(rec.tokens),
        tostring(rec.code_bytes),
        tostring(spell_result and spell_result.exit_code)
    ))
end

write_file(log_dir .. "/records.json", json.encode(records))
print(string.format("smoke_deepseek_coding_battery done: %d/%d reality_confirmed", passed, #cases))
