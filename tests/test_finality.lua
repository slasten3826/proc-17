package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")
local packet = require("core.packet")
local body = require("runtime.body")
local budget = require("runtime.budget")
local loss = require("runtime.loss")
local foundation = require("runtime.foundation")
local grave = require("runtime.grave")
local packet_memory = require("runtime.packet_memory")
local observe = require("organs.observe")
local encode = require("organs.encode")
local choose = require("organs.choose")

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

local function assert_dead_rejection(value, err, operation)
    assert_true(not value, operation .. " must reject corpse")
    assert_eq(err, "dead packet cannot " .. operation, operation .. " rejection reason")
end

local function frozen_projection(instance)
    return json.encode({
        status = instance.status,
        operator = instance.operator,
        terminal = instance.terminal,
        death = instance.death,
        residue = instance.residue,
        trace = instance.trace,
        chaos = instance.chaos,
        boundary = instance.boundary,
        calm = instance.calm,
        tension = instance.tension,
        runtime = instance.runtime,
    })
end

local corpse = packet.new("freeze every public mutation channel", {
    id = "packet-finality",
    memory_enabled = true,
    budget = {steps = 8, substrate_calls = 2, loss = 1.0},
})
assert(budget.init(corpse))
assert(loss.init(corpse))
assert(packet.die(corpse, "cancelled", {
    cause = "cancelled",
    do_not_repeat = "mutate a corpse",
}))

local before = frozen_projection(corpse)

local value, err = budget.init(corpse)
assert_dead_rejection(value, err, "initialize budget")
value, err = budget.charge(corpse, {cost = {steps = 1}})
assert_dead_rejection(value, err, "charge budget")
value, err = loss.init(corpse)
assert_dead_rejection(value, err, "initialize loss")
value, err = loss.apply(corpse, {amount = 0.1})
assert_dead_rejection(value, err, "apply loss")
value, err = foundation.reinforce(corpse, {
    kind = "spell_result",
    name = "posthumous spell",
    intention_hash = "dead",
    success = true,
})
assert_dead_rejection(value, err, "reinforce foundation")
value, err = grave.attach(corpse, {})
assert_dead_rejection(value, err, "attach grave")
value, err = packet_memory.attach(corpse, {kind = "inherited_packet_residue"}, {enabled = true})
assert_dead_rejection(value, err, "attach memory")
value, err = body.record_choice(corpse, {kind = "choice_payload"})
assert_dead_rejection(value, err, "record choice")
value, err = body.record_validation(corpse, {kind = "validation_payload"})
assert_dead_rejection(value, err, "record validation")
value, err = body.record_cycle(corpse, {kind = "cycle_payload"})
assert_dead_rejection(value, err, "record cycle")
value, err = body.decide_cycle(corpse, {})
assert_dead_rejection(value, err, "decide cycle")
value, err = body.apply_crystallized_work(corpse, {})
assert_dead_rejection(value, err, "apply crystallized work")

local substrate_calls = 0
value, err = observe.run(corpse, {
    ask = function()
        substrate_calls = substrate_calls + 1
        return {text = "should not run"}
    end,
})
assert_dead_rejection(value, err, "observe")
assert_eq(substrate_calls, 0, "corpse cannot call substrate")
value, err = encode.run(corpse, {})
assert_dead_rejection(value, err, "encode")
value, err = choose.run(corpse, {})
assert_dead_rejection(value, err, "choose")
value, err = packet.begin_tick(corpse, corpse.operator, {})
assert_dead_rejection(value, err, "begin tick")
value, err = packet.commit_transition(corpse, {from = "▽", to = "☴"})
assert_dead_rejection(value, err, "commit transition")
value, err = packet.append_event(corpse, {
    type = "cycle",
    operator = "☲",
    truth_status = "runtime_confirmed",
})
assert_dead_rejection(value, err, "append trace")

budget.snapshot(corpse)
budget.is_exhausted(corpse)
loss.snapshot(corpse)
loss.is_exhausted(corpse)
foundation.snapshot(corpse)
foundation.state(corpse)

assert_eq(frozen_projection(corpse), before, "public APIs leave corpse byte-stable")

print("test_finality ok")
