local lineage_budget = require("runtime.lineage_budget")

local budget = assert(lineage_budget.new({
    steps = 10,
    generations = 2,
    carrier_bytes = 100,
    total_tokens = "unlimited",
}))

assert(lineage_budget.can_allocate(budget, {steps = 6}))
local too_large, too_large_err = lineage_budget.can_allocate(budget, {steps = 11})
assert(too_large == nil)
assert(too_large_err:match("cannot allocate steps"))

local first = assert(lineage_budget.charge(budget, "generation:1", {generations = 1}, {"birth:1"}))
assert(first.cost.generations == 1)
local duplicate = assert(lineage_budget.charge(
    budget,
    "generation:1",
    {generations = 1},
    {"birth:1"}
))
assert(duplicate.spent_after.generations == 1)
assert(#budget.events == 1)
local conflicting, conflicting_err = lineage_budget.charge(
    budget,
    "generation:1",
    {generations = 2},
    {"birth:1"}
)
assert(conflicting == nil)
assert(conflicting_err:match("different cost"))

local reconciled = assert(lineage_budget.reconcile_packet(budget, {
    corpse_id = "corpse-1",
    packet_id = "packet-1",
    final_budget = {spent = {steps = 4}},
}))
assert(reconciled.cost.steps == 4)
assert(assert(lineage_budget.snapshot(budget)).spent.steps == 4)
assert(lineage_budget.reconcile_packet(budget, {
    corpse_id = "corpse-1",
    packet_id = "packet-1",
    final_budget = {spent = {steps = 4}},
}))
assert(#budget.events == 2)

assert(lineage_budget.charge(budget, "carrier:1", {carrier_bytes = 60}))
local cannot_pay, cannot_pay_err = lineage_budget.charge(
    budget,
    "carrier:2",
    {carrier_bytes = 50}
)
assert(cannot_pay == nil)
assert(cannot_pay_err:match("cannot allocate carrier_bytes"))

local unknown, unknown_err = lineage_budget.new({loss = 1})
assert(unknown == nil)
assert(unknown_err:match("unknown lineage budget axis"))

print("test_lineage_budget ok")
