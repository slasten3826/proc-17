local corpse = require("runtime.corpse")
local fixture = require("tests.support.plan_life")

local dead = assert(fixture.run(
    "corpse-exact-plan",
    "work_sequence",
    {"inspect", "change", "verify"},
    5
))
assert(dead.status == "dead")

local record = assert(corpse.capture(dead, {
    corpse_id = "corpse-exact-plan",
    trace_tail_count = 24,
}))
assert(corpse.verify(record))
assert(record.packet_id == dead.id)
assert(record.lineage_id == dead.lineage_id)
assert(record.terminal_kind == "manifest")
assert(record.death_cause == "complete")
assert(#record.trace_tail <= 24)
assert(record.field == nil)
assert(record.calm == nil)
assert(record.runtime == nil)
assert(record.operator == nil)

local same = assert(corpse.capture(dead, {
    corpse_id = "corpse-exact-plan",
    trace_tail_count = 24,
}))
assert(same.corpse_hash == record.corpse_hash)

local original_mode = dead.manifest.mode
record.manifest.mode = "tampered"
assert(dead.manifest.mode == original_mode)
local invalid, invalid_err = corpse.verify(record)
assert(invalid == nil)
assert(invalid_err:match("hash mismatch"))

local live = assert(fixture.run(
    "corpse-live-rejected",
    "work_sequence",
    {"inspect", "change"},
    4
))
assert(live.status ~= "dead")
local rejected, rejected_err = corpse.capture(live)
assert(rejected == nil)
assert(rejected_err:match("terminal dead Packet"))

print("test_corpse ok")
