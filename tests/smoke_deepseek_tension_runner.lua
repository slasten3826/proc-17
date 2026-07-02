package.path = "./?.lua;./?/init.lua;" .. package.path

local tension_runner = require("runtime.tension_runner")
local deepseek = require("substrates.deepseek")

local prompt = table.concat({
    "Task: plan a tiny CLI notes application.",
    "Return 3 to 5 concrete work units.",
    "Do not write code.",
    "Each work unit should be one short line.",
}, "\n")

local packet, result = tension_runner.run(prompt, deepseek, {
    work_mode = "plan",
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
    io.stderr:write("smoke_deepseek_tension_runner failed: " .. tostring(result) .. "\n")
    os.exit(1)
end

local ops = {}
for _, tick in ipairs(result.ticks) do
    ops[#ops + 1] = tick.operator
end

print("smoke_deepseek_tension_runner ok")
print("packet_id=" .. packet.id)
print("status=" .. packet.status)
print("stop_reason=" .. tostring(result.stop_reason))
print("ticks=" .. tostring(#result.ticks))
print("routes=" .. tostring(#result.routes))
print("trace=" .. table.concat(ops, ""))
print("chaos_fragments=" .. tostring(#packet.chaos.fragments))
print("work_units=" .. tostring(#packet.calm.work_units))
print("choices=" .. tostring(#packet.boundary.choices))
print("cycles=" .. tostring(#packet.boundary.cycles))
print("last_route=" .. tostring(result.routes[#result.routes] and result.routes[#result.routes].reason))
