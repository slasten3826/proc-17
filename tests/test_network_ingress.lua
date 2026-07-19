local carrier = require("runtime.carrier")
local completion = require("runtime.completion")
local corpse = require("runtime.corpse")
local lineage = require("runtime.lineage")
local network_ingress = require("runtime.network_ingress")
local fixture = require("tests.support.plan_life")

local packet = assert(fixture.run(
    "network-budget-death",
    "work_sequence",
    {"inspect", "change", "verify"},
    10,
    {packet_options = {budget = {steps = 2, substrate_calls = 8, loss = 1}}}
))
local dead = assert(corpse.capture(packet, {corpse_id = "corpse-network-source"}))
local state = assert(lineage.create("prepare a plan", {
    lineage_id = dead.lineage_id,
    session_id = "network-session",
    work_mode = "plan",
    carrier = {max_bytes = 65536},
    budget = {steps = 100, generations = 4, carrier_bytes = 65536},
}))
state.status = "evaluating_terminal"
state.current_generation = dead.generation
state.current_packet_id = dead.packet_id
state.current_corpse_id = dead.corpse_id
local assessment = assert(completion.evaluate(state, dead))
local record = assert(carrier.build_recovery(state, dead, assessment, {
    carrier_id = "carrier-network-2",
}))
assert(lineage.mark_continued(state, dead, record))

local ingress = assert(network_ingress.prepare(state, record))
assert(ingress.packet_options.lineage_id == state.lineage_id)
assert(ingress.packet_options.generation == 2)
assert(ingress.packet_options.parent_id == dead.packet_id)
assert(ingress.packet_options.parent_corpse_id == dead.corpse_id)
assert(ingress.packet_options.birth_kind == "recovery")
assert(ingress.packet_options.carrier_id == record.carrier_id)
assert(not ingress.prompt:find("NETWORK", 1, true))

local wrong = {}
for key, value in pairs(record) do
    wrong[key] = value
end
wrong.target_generation = 3
local rejected, rejected_err = network_ingress.prepare(state, wrong)
assert(rejected == nil)
assert(rejected_err:match("invalid recovery carrier") or rejected_err:match("hash mismatch"))

print("test_network_ingress ok")
