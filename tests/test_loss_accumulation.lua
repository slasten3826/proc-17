package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local loss = require("runtime.loss")

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

local p = packet.new("loss test", {
    budget = {loss = 1.0},
})
loss.init(p, {near_death_at = 0.2})
assert_eq(p.tension.loss, 0, "loss starts zero")
assert_eq(p.tension.loss_remaining, 1.0, "loss starts full")
assert_eq(p.tension.loss_exhausted, false, "not exhausted")

local record = assert(loss.apply(p, {
    operator = "☵",
    amount = 0.5,
    kind = "field_compression",
    source = "encode_loss",
    truth_status = "runtime_confirmed",
}))
assert_eq(record.loss_after, 0.5, "loss accumulated")
assert_eq(record.loss_remaining_after, 0.5, "remaining decreased")
assert_eq(p.tension.loss_near_death, false, "not near death yet")

loss.apply(p, {
    operator = "☳",
    amount = 0.3,
    kind = "attention_collapse",
    source = "choice_loss",
    truth_status = "runtime_confirmed",
})
assert_true(p.tension.loss_near_death, "near death at threshold")
assert_eq(p.tension.loss_exhausted, false, "near death not exhausted")

loss.apply(p, {
    operator = "☳",
    amount = 0.2,
    kind = "attention_collapse",
    source = "choice_loss",
    truth_status = "runtime_confirmed",
})
assert_true(loss.is_exhausted(p), "loss exhausted at zero")

assert_eq(loss.from_encode_loss({loss_percentage = 0.42}), 0.42, "encode percentage maps")
assert_eq(loss.from_encode_loss({omitted_count = 5}), 0.1, "encode omitted count fallback")
assert_eq(loss.from_encode_loss({omitted_count = 0}), 0, "no encode loss fallback")
assert_eq(loss.from_choose_loss({before_count = 4, not_chosen_count = 3}), 0.75, "choose ratio maps")
assert_eq(loss.from_choose_loss({before_count = 0, not_chosen_count = 3}), 0, "bad choose denominator")

local residue = loss.identity_residue(p, {last_operator = "☳"})
assert_eq(residue.cause, "identity_loss", "identity residue cause")
assert_eq(residue.last_operator, "☳", "identity residue operator")
assert_true(#residue.loss_events_tail > 0, "identity residue has loss tail")

print("test_loss_accumulation ok")
