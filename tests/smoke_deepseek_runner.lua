package.path = "./?.lua;./?/init.lua;" .. package.path

local runner = require("runtime.runner")
local deepseek = require("substrates.deepseek")

local prompt = table.concat({
    "Task: plan a tiny CLI notes application.",
    "Return 3 to 5 concrete work units.",
    "Do not write code.",
    "Each work unit should be one short line.",
}, "\n")

local packet, result = runner.single_pass(prompt, deepseek, {
    work_mode = "plan",
    observe_mode = "mixed",
    packet_options = {
        budget = {
            steps = 8,
            substrate_calls = 1,
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
    max_turns = 4,
})

if not packet then
    io.stderr:write("smoke_deepseek_runner failed: " .. tostring(result) .. "\n")
    os.exit(1)
end

print("smoke_deepseek_runner ok")
print("packet_id=" .. packet.id)
print("status=" .. packet.status)
print("chaos_fragments=" .. tostring(#packet.chaos.fragments))
print("work_units=" .. tostring(#packet.calm.work_units))
print("choices=" .. tostring(#packet.boundary.choices))
print("cycles=" .. tostring(#packet.boundary.cycles))
print("cycle_decision=" .. tostring(result.stages.cycle.decision))
print("cycle_reason=" .. tostring(result.stages.cycle.reason))
print("manifest_type=" .. tostring(result.stages.manifest.output.type))
print("manifest_preview=" .. tostring(result.stages.manifest.summary.text_preview))
