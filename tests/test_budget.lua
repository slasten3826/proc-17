package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local budget = require("runtime.budget")

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

local p = packet.new("budget test", {
    budget = {
        steps = 3,
        substrate_calls = 2,
        total_tokens = 10,
    },
})

budget.init(p)
assert_eq(p.runtime.budget.remaining.steps, 3, "steps remaining copied")
assert_eq(p.runtime.budget.remaining.substrate_calls, 2, "substrate remaining copied")
assert_eq(p.runtime.budget.remaining.total_tokens, 10, "tokens remaining copied")
assert_eq(p.runtime.budget.exhausted, false, "budget starts alive")

local record = assert(budget.charge(p, {
    operator = "☴",
    cost = {steps = 1},
    source = "body_tick",
    truth_status = "runtime_confirmed",
}))
assert_eq(record.remaining_after.steps, 2, "step charge decreases remaining")
assert_eq(p.runtime.budget.spent.steps, 1, "spent steps accumulated")

local usage = budget.from_usage({prompt_tokens = 3, completion_tokens = 4})
assert_eq(usage.total_tokens, 7, "usage total computed")
assert_eq(usage.prompt_tokens, 3, "usage prompt copied")
assert_eq(usage.completion_tokens, 4, "usage completion copied")

budget.charge(p, {
    operator = "☴",
    cost = usage,
    source = "substrate_usage",
    truth_status = "runtime_confirmed",
})
assert_eq(p.runtime.budget.spent.total_tokens, 7, "token spend accumulated")
assert_eq(p.runtime.budget.remaining.total_tokens, 3, "token remaining decreased")

local estimated = budget.estimate_tokens("123456789", {chars_per_token = 4})
assert_eq(estimated, 3, "estimated tokens ceil")

budget.charge(p, {
    operator = "☱",
    cost = {steps = 2},
    source = "body_tick",
    truth_status = "runtime_confirmed",
})
assert_eq(p.runtime.budget.remaining.steps, 0, "steps exhausted at zero")
assert_eq(p.runtime.budget.exhausted, true, "exhausted flag set")
assert_eq(p.runtime.budget.exhausted_keys[1], "steps", "exhausted key stored")

local unbounded = packet.new("unbounded", {budget = {steps = 1}})
budget.init(unbounded)
budget.charge(unbounded, {
    operator = "☴",
    cost = {total_tokens = 1000},
    source = "substrate_usage",
    truth_status = "runtime_confirmed",
})
assert_eq(unbounded.runtime.budget.exhausted, false, "unbounded token axis does not exhaust")

print("test_budget ok")
