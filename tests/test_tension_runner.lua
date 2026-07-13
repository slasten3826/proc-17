package.path = "./?.lua;./?/init.lua;" .. package.path

local tension_runner = require("runtime.tension_runner")
local grave = require("runtime.grave")
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

local function operators(result)
    local out = {}
    for _, tick in ipairs(result.ticks) do
        out[#out + 1] = tick.operator
    end
    return table.concat(out, "")
end

local p, result = tension_runner.run("build notes app", fake, {
    work_mode = "plan",
    max_ticks = 8,
    packet_options = {
        budget = {steps = 32, substrate_calls = 8, encode_items = 8, loss = 10},
    },
    choose = {
        limits = {max_selected = 1, max_killed_sample = 8},
    },
})

assert_true(p, result)
assert_eq(result.kind, "tension_runner_result", "result kind")
assert_eq(result.packet_id, p.id, "packet id")
assert_eq(result.stop_reason, "tick_limit", "large budget fake run should stop by host tick limit")
assert_eq(p.status, "running", "host tick limit leaves packet running")
assert_eq(p.death, nil, "host tick limit must not kill packet")
assert_true(#result.ticks >= 7, "runner should execute several routed ticks")
assert_true(#result.routes >= 6, "runner should record routes")
assert_eq(result.routes[1].from, "☴", "first route from observe")
assert_eq(result.routes[1].to, "☵", "first route to encode")
assert_eq(result.routes[2].from, "☵", "second route from encode")
assert_eq(result.routes[2].to, "☴", "second route to observe")
assert_true(operators(result):find("☴☵☴☳☴☱☲☱", 1, true) == 1, "expected pressure route prefix")
assert_eq(#p.chaos.fragments, 3, "observe should run three times in routed prefix")
assert_true(#p.calm.work_units > 0, "encode created work units")
assert_eq(#p.boundary.choices, 1, "choose recorded once before runtime")
assert_true(#p.boundary.cycles >= 1, "cycle recorded")
assert_eq(p.runtime.budget.spent.steps, #result.ticks, "runner charges one step per tick")
assert_true(#p.runtime.budget.events >= #result.ticks, "budget events recorded")

local dying, death_result = tension_runner.run("build notes app", fake, {
    work_mode = "plan",
    max_ticks = 20,
    packet_options = {
        budget = {steps = 8, substrate_calls = 8, encode_items = 8, loss = 10},
    },
    choose = {
        limits = {max_selected = 1, max_killed_sample = 8},
    },
})

assert_true(dying, death_result)
assert_eq(death_result.stop_reason, "budget_exhausted", "small budget should die before host tick limit")
assert_eq(dying.status, "dead", "budget exhaustion kills packet")
assert_eq(dying.death.cause, "budget_exhausted", "death cause")
assert_eq(dying.residue.cause, "budget_exhausted", "death residue cause")
assert_true(#dying.residue.exhausted_keys > 0, "death residue exposes exhausted keys")
assert_eq(dying.runtime.budget.exhausted, true, "runtime budget exhausted")
assert_eq(dying.runtime.budget.spent.steps, 8, "small budget spent all steps")

local default_death, default_death_result = tension_runner.run("build notes app", fake, {
    work_mode = "plan",
    packet_options = {
        budget = {steps = 16, substrate_calls = 32, encode_items = 8, loss = 10},
    },
    choose = {
        limits = {max_selected = 1, max_killed_sample = 8},
    },
})

assert_true(default_death, default_death_result)
assert_eq(default_death_result.stop_reason, "budget_exhausted", "default max_ticks should allow internal death")
assert_eq(default_death.death.cause, "budget_exhausted", "default run budget death")
assert_eq(default_death.runtime.budget.spent.steps, 16, "default run spends configured steps")

local ancestor, ancestor_result = tension_runner.run("build notes app", fake, {
    work_mode = "plan",
    max_ticks = 20,
    packet_options = {
        budget = {steps = 8, substrate_calls = 8, encode_items = 8, loss = 10},
    },
    choose = {
        limits = {max_selected = 1, max_killed_sample = 8},
    },
})

assert_true(ancestor, ancestor_result)
assert_eq(ancestor_result.stop_reason, "budget_exhausted", "ancestor dies by real budget exhaustion")
assert_eq(ancestor.residue.last_operator, "☱", "real loop death lands on runtime eye")
local ancestor_grave = assert(grave.classify(ancestor))
assert_eq(ancestor_grave.grave_kind, "warning", "real ancestor death becomes warning grave")

local inherited, inherited_result = tension_runner.run("build notes app", fake, {
    work_mode = "plan",
    max_ticks = 9,
    packet_options = {
        budget = {steps = 32, substrate_calls = 8, encode_items = 8, loss = 10},
    },
    inherited_graves = {ancestor_grave},
    choose = {
        limits = {max_selected = 1, max_killed_sample = 8},
    },
})

assert_true(inherited, inherited_result)
assert_eq(inherited_result.grave.kind, "grave_attach_payload", "runner grave payload")
assert_eq(inherited_result.grave.warning_count, 1, "runner warning attached")
assert_eq(#inherited.runtime.karma.warnings, 1, "runner packet has warning grave")
assert_eq(#inherited.chaos.unresolved_pressure, 0, "warning does not create chaos pressure")
assert_true(operators(inherited_result):find("☴☵☴☳☴☱☲☱△", 1, true) == 1, "warning inheritance manifests on repeated cycle")
assert_eq(inherited_result.routes[#inherited_result.routes].reason, "karma_warning_manifest_pressure", "runner karma warning route")
assert_eq(inherited_result.stop_reason, "manifested", "runner manifests after inherited warning")

local missing, err = tension_runner.run("build notes app", nil, {
    max_ticks = 2,
})
assert_true(not missing, "missing substrate should fail")
assert_eq(err, "☴:missing_substrate", "missing substrate error")

print("test_tension_runner ok")
