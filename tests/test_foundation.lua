package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local foundation = require("runtime.foundation")

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

local p = packet.new("foundation test")
assert_eq(foundation.state(p), "fluid", "new foundation state")

local result = {
    kind = "spell_result",
    name = "py_compile",
    spell_kind = "py_compile_python_file",
    intention_hash = "abc",
    success = true,
    truth_status = "runtime_confirmed",
}

local pattern = assert(foundation.reinforce(p, result))
assert_eq(pattern.repetition_count, 1, "first repetition")
assert_eq(pattern.success_count, 1, "first success")
assert_eq(pattern.failure_count, 0, "no failures")
assert_true(pattern.strength > 0, "strength increased")
assert_eq(foundation.state(p), "crystallizing", "success crystallizes")

foundation.reinforce(p, result)
local snap = foundation.snapshot(p)
assert_eq(snap.kind, "foundation_snapshot", "snapshot kind")
assert_eq(snap.reinforcements, 2, "reinforcements count")
assert_eq(snap.evidence_count, 2, "evidence count")

local failed = {
    kind = "spell_result",
    name = "py_compile",
    spell_kind = "py_compile_python_file",
    intention_hash = "abc",
    success = false,
    truth_status = "runtime_confirmed",
}
pattern = assert(foundation.reinforce(p, failed))
assert_eq(pattern.failure_count, 1, "failure count")
assert_eq(#p.runtime.evidence, 3, "runtime evidence stored")

print("test_foundation ok")
