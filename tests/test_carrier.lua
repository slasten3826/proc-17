local carrier = require("runtime.carrier")
local completion = require("runtime.completion")
local corpse = require("runtime.corpse")
local lineage = require("runtime.lineage")
local fixture = require("tests.support.plan_life")

local packet = assert(fixture.run(
    "carrier-budget-death",
    "work_sequence",
    {"inspect", "change", "verify"},
    10,
    {packet_options = {budget = {steps = 2, substrate_calls = 8, loss = 1}}}
))
local dead = assert(corpse.capture(packet, {corpse_id = "corpse-carrier-source"}))
local state = assert(lineage.create("prepare a plan", {
    lineage_id = dead.lineage_id,
    session_id = "carrier-session",
    work_mode = "plan",
    carrier = {max_bytes = 65536},
    budget = {steps = 100, generations = 4, carrier_bytes = 65536},
}))
state.status = "evaluating_terminal"
state.current_generation = dead.generation
state.current_packet_id = dead.packet_id
state.current_corpse_id = dead.corpse_id
local assessment = assert(completion.evaluate(state, dead))
assert(assessment.task_state == "unfinished")
assert(assessment.terminal_recoverable == true)

local record = assert(carrier.build_recovery(state, dead, assessment, {
    carrier_id = "carrier-test-2",
    time = 50,
}))
assert(carrier.verify(record, {
    lineage_id = state.lineage_id,
    source_corpse_id = dead.corpse_id,
    target_generation = 2,
    max_bytes = 65536,
}))
assert(record.payload.original_task == "prepare a plan")
assert(record.target_generation == 2)
assert(record.payload_bytes > 0)

local rejected_assessment = {}
for key, value in pairs(assessment) do
    rejected_assessment[key] = value
end
rejected_assessment.terminal_recoverable = false
local rejected, rejected_err = carrier.build_recovery(
    state,
    dead,
    rejected_assessment,
    {max_bytes = 65536}
)
assert(rejected == nil)
assert(rejected_err == "terminal assessment cannot produce a recovery carrier")

local same = assert(carrier.build_recovery(state, dead, assessment, {
    carrier_id = "carrier-test-2",
    time = 50,
}))
assert(same.carrier_hash == record.carrier_hash)

local oversize, oversize_err = carrier.build_recovery(state, dead, assessment, {
    max_bytes = 8,
})
assert(oversize == nil)
assert(oversize_err == "carrier_too_large")

record.payload.original_task = "tampered"
local invalid, invalid_err = carrier.verify(record)
assert(invalid == nil)
assert(invalid_err:match("invalid recovery carrier") or invalid_err:match("hash mismatch"))

print("test_carrier ok")
