package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")
local tension_runner = require("runtime.tension_runner")
local deepseek = require("substrates.deepseek")

local log_dir = "sandbox/mortality_deepseek"

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

local function budget_snapshot(packet)
    return packet.runtime and packet.runtime.budget or {}
end

local function record(case, packet, result)
    local runtime_budget = budget_snapshot(packet)
    return {
        id = case.id,
        prompt = case.prompt,
        work_mode = case.work_mode,
        packet_id = packet.id,
        status = packet.status,
        stop_reason = result.stop_reason,
        death = packet.death,
        residue = packet.residue,
        trace = trace(result),
        budget = {
            spent = runtime_budget.spent,
            remaining = runtime_budget.remaining,
            exhausted = runtime_budget.exhausted,
            exhausted_keys = runtime_budget.exhausted_keys,
            event_count = #(runtime_budget.events or {}),
        },
        ticks = #result.ticks,
        routes = #result.routes,
    }
end

local cases = {
    {
        id = "deepseek_plan_low_step_budget",
        prompt = "Сделай короткий план: как проверить смертность пакета proc-17. Ответь кратко.",
        work_mode = "plan",
        max_ticks = 20,
        packet_options = {
            budget = {steps = 8, substrate_calls = 8, total_tokens = 20000, encode_items = 8, loss = 10},
        },
    },
    {
        id = "deepseek_build_token_visibility",
        prompt = "Напиши маленькую функцию на Lua add(a, b) и один минимальный тест. Только код и короткое пояснение.",
        work_mode = "build",
        max_ticks = 12,
        packet_options = {
            budget = {steps = 32, substrate_calls = 4, total_tokens = 20000, encode_items = 12, loss = 10},
        },
    },
    {
        id = "deepseek_plan_high_budget_same_task",
        prompt = "Сделай короткий план: как проверить смертность пакета proc-17. Ответь кратко.",
        work_mode = "plan",
        max_ticks = 20,
        packet_options = {
            budget = {steps = 32, substrate_calls = 8, total_tokens = 20000, encode_items = 8, loss = 10},
        },
    },
}

mkdir_p(log_dir)

local records = {}
for _, case in ipairs(cases) do
    local packet, result_or_err = tension_runner.run(case.prompt, deepseek, {
        work_mode = case.work_mode,
        max_ticks = case.max_ticks,
        packet_options = case.packet_options,
        substrate_options = {
            model = os.getenv("DEEPSEEK_MODEL") or "deepseek-chat",
        },
        choose = {
            limits = {max_selected = 1, max_killed_sample = 8},
        },
    })
    if not packet then
        error(case.id .. " failed: " .. tostring(result_or_err))
    end

    local rec = record(case, packet, result_or_err)
    records[#records + 1] = rec
    write_file(log_dir .. "/" .. case.id .. ".json", json.encode(rec))
    print(string.format(
        "%s stop=%s death=%s trace=%s steps=%s tokens=%s",
        case.id,
        tostring(rec.stop_reason),
        tostring(rec.death and rec.death.cause),
        rec.trace,
        tostring(rec.budget.spent and rec.budget.spent.steps),
        tostring(rec.budget.spent and rec.budget.spent.total_tokens)
    ))
end

write_file(log_dir .. "/records.json", json.encode(records))
print("smoke_deepseek_mortality_battery ok")
