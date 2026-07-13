package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local budget = require("runtime.budget")
local loss = require("runtime.loss")
local tension_runner = require("runtime.tension_runner")
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

local function trace(result)
    local out = {}
    for _, tick in ipairs(result.ticks or {}) do
        out[#out + 1] = tick.operator
    end
    return table.concat(out, "")
end

local function run_case(name, fn)
    fn()
    print("mortality " .. name .. " ok")
end

run_case("small_steps_loop", function()
    local p, result = tension_runner.run("build notes app", fake, {
        work_mode = "plan",
        max_ticks = 20,
        packet_options = {
            budget = {steps = 8, substrate_calls = 8, encode_items = 8, loss = 10},
        },
        choose = {
            limits = {max_selected = 1, max_killed_sample = 8},
        },
    })
    assert_true(p, result)
    assert_eq(result.stop_reason, "budget_exhausted", "small steps should die from budget")
    assert_eq(p.status, "dead", "packet dead")
    assert_eq(p.death.cause, "budget_exhausted", "budget death")
    assert_true(trace(result):find("☱☲☱", 1, true) ~= nil, "trace reaches runtime/cycle loop")
end)

run_case("substrate_call_limit", function()
    local p, result = tension_runner.run("build notes app", fake, {
        work_mode = "plan",
        max_ticks = 20,
        packet_options = {
            budget = {steps = 64, substrate_calls = 1, encode_items = 8, loss = 10},
        },
    })
    assert_true(p, result)
    assert_eq(result.stop_reason, "budget_exhausted", "second observe should exhaust substrate call budget")
    assert_eq(p.death.cause, "budget_exhausted", "substrate call budget death")
    assert_true(p.runtime.budget.spent.substrate_calls >= 1, "substrate calls charged")
end)

run_case("token_limit_with_usage", function()
    local usage_substrate = {
        ask = function()
            return {
                text = "fake substrate response",
                usage = {
                    prompt_tokens = 60,
                    completion_tokens = 50,
                    total_tokens = 110,
                },
            }
        end,
    }

    local p, result = tension_runner.run("token budget task", usage_substrate, {
        work_mode = "plan",
        max_ticks = 20,
        packet_options = {
            budget = {steps = 64, substrate_calls = 8, total_tokens = 50, encode_items = 8, loss = 10},
        },
    })
    assert_true(p, result)
    assert_eq(result.stop_reason, "budget_exhausted", "usage tokens should exhaust token budget")
    assert_eq(p.runtime.budget.spent.total_tokens, 110, "usage total tokens charged")
    assert_eq(p.death.cause, "budget_exhausted", "token budget death")
end)

run_case("host_guard_not_death", function()
    local p, result = tension_runner.run("build notes app", fake, {
        work_mode = "plan",
        max_ticks = 5,
        packet_options = {
            budget = {steps = 100, substrate_calls = 20, encode_items = 8, loss = 10},
        },
    })
    assert_true(p, result)
    assert_eq(result.stop_reason, "tick_limit", "host guard remains host guard")
    assert_eq(p.status, "running", "host guard leaves packet running")
    assert_eq(p.death, nil, "host guard is not packet death")
end)

run_case("choose_identity_loss", function()
    local p = packet.new("choose loss", {
        budget = {loss = 0.5},
    })
    loss.init(p)
    loss.apply(p, {
        operator = "☳",
        amount = loss.from_choose_loss({before_count = 10, not_chosen_count = 9}),
        kind = "attention_collapse",
        source = "choice_loss",
        truth_status = "runtime_confirmed",
    })
    assert_true(loss.is_exhausted(p), "large choice collapse exhausts low loss budget")
    local residue = loss.identity_residue(p, {last_operator = "☳"})
    assert_eq(residue.cause, "identity_loss", "identity residue cause")
    assert_true(#residue.loss_events_tail > 0, "identity residue has loss events")
end)

run_case("cycle_does_not_create_loss", function()
    local p, result = tension_runner.run("build notes app", fake, {
        work_mode = "plan",
        max_ticks = 14,
        packet_options = {
            budget = {steps = 64, substrate_calls = 20, encode_items = 8, loss = 10},
        },
        choose = {
            limits = {max_selected = 1, max_killed_sample = 8},
        },
    })
    assert_true(p, result)
    local cycle_count = 0
    for _, tick in ipairs(result.ticks) do
        if tick.operator == "☲" then
            cycle_count = cycle_count + 1
        end
    end
    assert_true(cycle_count > 1, "test reaches repeated cycles")
    assert_eq(#p.tension.loss_events, 2, "only encode and choose add loss")
end)

run_case("budget_residue_shape", function()
    local p, result = tension_runner.run("build notes app", fake, {
        work_mode = "plan",
        max_ticks = 20,
        packet_options = {
            budget = {steps = 8, substrate_calls = 8, encode_items = 8, loss = 10},
        },
    })
    assert_true(p, result)
    assert_eq(p.residue.cause, "budget_exhausted", "budget residue cause")
    assert_true(#p.residue.exhausted_keys > 0, "budget residue exhausted keys")
    assert_true(#p.residue.trace_tail > 0, "budget residue trace tail")
    assert_true(type(p.residue.do_not_repeat) == "string", "budget residue do_not_repeat")
end)

run_case("identity_residue_shape", function()
    local p = packet.new("identity loss", {
        budget = {loss = 0.2},
    })
    loss.init(p)
    loss.apply(p, {
        operator = "☵",
        amount = 0.25,
        kind = "field_compression",
        source = "encode_loss",
        truth_status = "runtime_confirmed",
    })
    local residue = loss.identity_residue(p, {last_operator = "☵"})
    assert_eq(residue.cause, "identity_loss", "identity residue cause")
    assert_true(residue.loss_exhausted, "identity residue exhausted")
    assert_true(#residue.loss_events_tail > 0, "identity residue events")
end)

print("smoke_mortality_battery ok")
