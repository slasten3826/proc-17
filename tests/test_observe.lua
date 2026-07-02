package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local observe = require("organs.observe")
local fake = require("substrates.fake")

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

local p = packet.new("observe this task")
local before_calm_count = #p.calm.structures

local observed, payload = observe.run(p, fake, {
    work_mode = "plan",
})

assert_true(observed, "observe should return packet")
assert_eq(payload.kind, "observe_organ_payload", "payload kind")
assert_eq(payload.truth_status, "semantic_proposal", "payload truth")
assert_eq(payload.call.operator, "☴", "call operator")
assert_eq(payload.call.prompt_payload, "observe this task", "call prompt")
assert_eq(payload.response.text, "fake substrate response", "fake text")
assert_eq(#p.chaos.fragments, 1, "chaos fragment appended")
assert_eq(p.chaos.fragments[1].kind, "substrate_response", "fragment kind")
assert_eq(p.chaos.fragments[1].truth_status, "semantic_proposal", "fragment truth")
assert_eq(p.trace[#p.trace].type, "chaos_append", "trace event")
assert_eq(p.trace[#p.trace].operator, "☴", "trace operator")
assert_eq(#p.calm.structures, before_calm_count, "observe must not write calm")

local missing, missing_err = observe.run(p, nil)
assert_true(not missing, "missing substrate should fail")
assert_eq(missing_err, "missing_substrate", "missing substrate error")

print("test_observe ok")

