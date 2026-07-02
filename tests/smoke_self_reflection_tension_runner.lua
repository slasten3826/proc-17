package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")
local tension_runner = require("runtime.tension_runner")
local deepseek = require("substrates.deepseek")

local log_dir = "logs/self_reflection_tension/2026-07-01"

local architecture = [[
You are proc-17.

This is your current body:

core:
- core/packet.lua: packet birth, chaos, calm, boundary, tension, trace, death, manifest.
- core/topology.lua: ProcessLang adjacency.
- core/json.lua: JSON encode/decode.

substrate:
- DeepSeek is not the body.
- DeepSeek enters only through ☴ observe as semantic current.
- substrate output is semantic_proposal, not runtime truth.

organs:
- ☴ organs/observe.lua: asks substrate and appends semantic chaos.
- ☵ organs/encode.lua: reads packet chaos and crystallizes calm field/work_units.
- ☳ organs/choose.lua: collapses calm alternatives and records killed alternatives.
- ☱ runtime eye inside runtime/tension_runner.lua: records runtime pressure.
- ☲ logic/cycle.lua through runtime/body.lua: decides continuation pressure.
- △ logic/manifest.lua: assembles output only when runner reaches manifest.

routing:
- runtime/router.lua chooses next operator by packet pressure.
- hard rules: ☵ -> ☴, ☳ -> ☴, ☲ -> ☱, ☶ -> ☱.
- ☴ may route to ☵ / ☳ / ☱.
- ☱ may route to ☲ / ☶ / ☴ / △.

current runner:
- runtime/tension_runner.lua starts at ☴.
- after every tick it asks router.after_tick.
- it stops at △ or max_ticks.
- if max_ticks is reached, packet remains running.

known current behavior:
- typical trace: ☴☵☴☳☴☱☲☱.
- if no executor marks work_units done, ☲ sees remaining_work.
- this is not completion.

pressure axes:
- loss = packet physics.
- budget = runtime economics.
- they are separate.
]]

local question = architecture .. [[

Question:
Ты proc-17. Это твоё тело. Что ты думаешь о нём?

Do not solve a task.
Do not invent files.
Reflect from inside this architecture.
]]

local cases = {
    {id = "self_plan", mode = "plan"},
    {id = "self_build", mode = "build"},
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
        lines[#lines + 1] = string.format("%02d %s -> %s : %s", index, route.from, route.to, route.reason)
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
        lines[#lines + 1] = string.format("%02d [%s] %s", index, tostring(unit.status), tostring(unit.description or unit.id))
    end
    return lines
end

local function selected_lines(packet)
    local choice = packet.boundary.choices and packet.boundary.choices[#packet.boundary.choices]
    local lines = {}
    if not choice then
        return lines
    end
    for index, item in ipairs(choice.selected or {}) do
        lines[#lines + 1] = string.format("%02d %s :: %s", index, tostring(item.id), tostring(item.value))
    end
    return lines
end

local function markdown(case, packet, result)
    local lines = {
        "# " .. case.id,
        "",
        "mode: `" .. case.mode .. "`",
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

    for index, text in ipairs(observe_texts(result)) do
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
    lines[#lines + 1] = table.concat(selected_lines(packet), "\n")
    lines[#lines + 1] = "```"

    return table.concat(lines, "\n")
end

local summary = {
    "# Self Reflection Tension Probe",
    "",
    "date: 2026-07-01",
    "runner: runtime/tension_runner.lua",
    "substrate: DeepSeek",
    "max_ticks: 8",
    "",
}

local records = {}

for _, case in ipairs(cases) do
    local packet, result = tension_runner.run(question, deepseek, {
        work_mode = case.mode,
        observe_mode = "mixed",
        max_ticks = 8,
        packet_options = {
            budget = {
                steps = 8,
                substrate_calls = 4,
                encode_items = 24,
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
        mode = case.mode,
        packet_id = packet.id,
        status = packet.status,
        stop_reason = result.stop_reason,
        trace = operator_trace(result),
        tick_count = #result.ticks,
        route_count = #result.routes,
        chaos_fragments = #packet.chaos.fragments,
        work_units = #packet.calm.work_units,
        choices = #packet.boundary.choices,
        cycles = #packet.boundary.cycles,
        routes = result.routes,
        observe_responses = observe_texts(result),
        work_unit_lines = work_unit_lines(packet),
        selected_lines = selected_lines(packet),
    }
    records[#records + 1] = record

    write_file(log_dir .. "/" .. case.id .. ".md", markdown(case, packet, result))
    write_file(log_dir .. "/" .. case.id .. ".json", json.encode(record))

    summary[#summary + 1] = string.format(
        "- `%s`: trace=%s stop=%s work_units=%d choices=%d cycles=%d",
        case.id,
        record.trace,
        tostring(record.stop_reason),
        record.work_units,
        record.choices,
        record.cycles
    )
end

write_file(log_dir .. "/README.md", table.concat(summary, "\n"))
write_file(log_dir .. "/records.json", json.encode(records))

print("smoke_self_reflection_tension_runner ok")
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
