package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local body = require("runtime.body")
local router = require("runtime.router")
local tension_runner = require("runtime.tension_runner")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": " .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

os.execute("mkdir -p sandbox")
local file = assert(io.open("sandbox/build_mode_ok.py", "w"))
file:write("print('ok')\n")
file:close()

local p = packet.new("build lower triangle", {
    metadata = {work_mode = "build"},
    budget = {steps = 8, substrate_calls = 1},
})
body.apply_crystallized_work(p, {
    {id = "artifact", status = "pending"},
})

local d, err = router.after_tick(p, {
    operator = "☱",
    work_mode = "build",
})
assert_true(d, err)
assert_eq(d.to, "☶", "build runtime asks for evidence")

local fake_substrate = {
    ask = function()
        return {text = "semantic proposal"}
    end,
}

local routed_packet, result = tension_runner.run("build lower triangle", fake_substrate, {
    work_mode = "build",
    start_operator = "☶",
    max_ticks = 2,
    logic = {
        spells = {
            {
                kind = "py_compile_python_file",
                name = "compile generated artifact",
                intention = "validate build artifact",
                path = "sandbox/build_mode_ok.py",
            },
        },
    },
})

assert_true(routed_packet, result)
assert_eq(result.ticks[1].operator, "☶", "first tick logic")
assert_eq(result.ticks[1].payload.status, "accepted", "spell accepted")
assert_eq(result.ticks[1].payload.evidence_count, 1, "spell evidence count")
assert_eq(#routed_packet.runtime.evidence, 1, "runtime evidence stored")
assert_eq(routed_packet.runtime.foundation.reinforcements, 1, "foundation reinforced")
assert_eq(result.routes[1].to, "☱", "logic routes to runtime eye")

print("test_build_mode_lower_triangle ok")
