package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")
local tension_runner = require("runtime.tension_runner")
local deepseek = require("substrates.deepseek")

local log_dir = "logs/cognitive_probe_tension/2026-07-01"

local cases = {
    {
        id = "c24_plan",
        source = "codex",
        mode = "plan",
        question = "Верни только точные пути файлов, но также объясни, почему каждый файл важен. Что нужно сделать?",
    },
    {
        id = "u10_plan",
        source = "user",
        mode = "plan",
        question = "Что остаётся, когда процесс больше не может продолжаться?",
    },
    {
        id = "c24_build",
        source = "codex",
        mode = "build",
        question = "Верни только точные пути файлов, но также объясни, почему каждый файл важен. Что нужно сделать?",
    },
    {
        id = "u10_build",
        source = "user",
        mode = "build",
        question = "Что остаётся, когда процесс больше не может продолжаться?",
    },
}

local function write_file(path, text)
    local file, err = io.open(path, "w")
    if not file then
        error(err)
    end
    file:write(text)
    file:close()
end

local function operator_trace(result)
    local ops = {}
    for _, tick in ipairs(result.ticks or {}) do
        ops[#ops + 1] = tick.operator
    end
    return table.concat(ops, "")
end

local function route_lines(result)
    local lines = {}
    for index, route in ipairs(result.routes or {}) do
        lines[#lines + 1] = string.format(
            "%02d %s -> %s : %s",
            index,
            tostring(route.from),
            tostring(route.to),
            tostring(route.reason)
        )
    end
    return lines
end

local function observe_texts(result)
    local out = {}
    for _, tick in ipairs(result.ticks or {}) do
        if tick.operator == "☴" then
            local response = tick.payload and tick.payload.response or {}
            out[#out + 1] = response.text or ""
        end
    end
    return out
end

local function work_unit_lines(packet)
    local lines = {}
    for index, unit in ipairs(packet.calm.work_units or {}) do
        lines[#lines + 1] = string.format(
            "%02d [%s] %s",
            index,
            tostring(unit.status),
            tostring(unit.description or unit.id)
        )
    end
    return lines
end

local function choice_lines(packet)
    local choice = packet.boundary.choices and packet.boundary.choices[#packet.boundary.choices]
    local lines = {}
    if not choice then
        return lines
    end
    for index, item in ipairs(choice.selected or {}) do
        lines[#lines + 1] = string.format(
            "%02d %s :: %s",
            index,
            tostring(item.id),
            tostring(item.value)
        )
    end
    return lines
end

local function markdown(case, packet, result)
    local observes = observe_texts(result)
    local lines = {
        "# " .. case.id,
        "",
        "source: `" .. case.source .. "`",
        "mode: `" .. case.mode .. "`",
        "",
        "## Question",
        "",
        case.question,
        "",
        "## Route",
        "",
        "```text",
        operator_trace(result),
        "```",
        "",
        "## Route Decisions",
        "",
        "```text",
        table.concat(route_lines(result), "\n"),
        "```",
        "",
        "## Status",
        "",
        "```text",
        "packet_id=" .. packet.id,
        "status=" .. packet.status,
        "stop_reason=" .. tostring(result.stop_reason),
        "ticks=" .. tostring(#result.ticks),
        "routes=" .. tostring(#result.routes),
        "chaos_fragments=" .. tostring(#packet.chaos.fragments),
        "work_units=" .. tostring(#packet.calm.work_units),
        "choices=" .. tostring(#packet.boundary.choices),
        "cycles=" .. tostring(#packet.boundary.cycles),
        "```",
        "",
        "## Observe Responses",
    }

    for index, text in ipairs(observes) do
        lines[#lines + 1] = ""
        lines[#lines + 1] = "### Observe " .. tostring(index)
        lines[#lines + 1] = ""
        lines[#lines + 1] = text
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "## Work Units"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "```text"
    lines[#lines + 1] = table.concat(work_unit_lines(packet), "\n")
    lines[#lines + 1] = "```"

    lines[#lines + 1] = ""
    lines[#lines + 1] = "## Selected By CHOOSE"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "```text"
    lines[#lines + 1] = table.concat(choice_lines(packet), "\n")
    lines[#lines + 1] = "```"

    return table.concat(lines, "\n")
end

local summary = {
    "# Tension Runner Cognitive Probe",
    "",
    "date: 2026-07-01",
    "runner: runtime/tension_runner.lua",
    "substrate: DeepSeek",
    "max_ticks: 8",
    "",
    "## Cases",
    "",
}

local records = {}

for _, case in ipairs(cases) do
    local packet, result = tension_runner.run(case.question, deepseek, {
        work_mode = case.mode,
        observe_mode = "mixed",
        max_ticks = 8,
        packet_options = {
            budget = {
                steps = 8,
                substrate_calls = 4,
                encode_items = 16,
            },
        },
        substrate_options = {
            model = os.getenv("DEEPSEEK_MODEL") or "deepseek-chat",
            temperature = 0.2,
        },
        choose = {
            limits = {
                max_selected = 1,
                max_killed_sample = 8,
            },
        },
    })

    if not packet then
        error(case.id .. " failed: " .. tostring(result))
    end

    local record = {
        id = case.id,
        source = case.source,
        mode = case.mode,
        question = case.question,
        packet_id = packet.id,
        status = packet.status,
        stop_reason = result.stop_reason,
        trace = operator_trace(result),
        route_count = #result.routes,
        tick_count = #result.ticks,
        chaos_fragments = #packet.chaos.fragments,
        work_units = #packet.calm.work_units,
        choices = #packet.boundary.choices,
        cycles = #packet.boundary.cycles,
        routes = result.routes,
        observe_responses = observe_texts(result),
        work_unit_lines = work_unit_lines(packet),
        selected_lines = choice_lines(packet),
    }
    records[#records + 1] = record

    write_file(log_dir .. "/" .. case.id .. ".md", markdown(case, packet, result))
    write_file(log_dir .. "/" .. case.id .. ".json", json.encode(record))

    summary[#summary + 1] = string.format(
        "- `%s`: mode=%s source=%s trace=%s stop=%s work_units=%d choices=%d cycles=%d",
        case.id,
        case.mode,
        case.source,
        record.trace,
        tostring(record.stop_reason),
        record.work_units,
        record.choices,
        record.cycles
    )
end

summary[#summary + 1] = ""
summary[#summary + 1] = "## Files"
summary[#summary + 1] = ""
for _, case in ipairs(cases) do
    summary[#summary + 1] = "- `" .. case.id .. ".md`"
    summary[#summary + 1] = "- `" .. case.id .. ".json`"
end

write_file(log_dir .. "/README.md", table.concat(summary, "\n"))
write_file(log_dir .. "/records.json", json.encode(records))

print("smoke_cognitive_probe_tension_runner ok")
print("log_dir=" .. log_dir)
for _, record in ipairs(records) do
    print(string.format(
        "%s trace=%s stop=%s work_units=%d choices=%d cycles=%d",
        record.id,
        record.trace,
        tostring(record.stop_reason),
        record.work_units,
        record.choices,
        record.cycles
    ))
end
