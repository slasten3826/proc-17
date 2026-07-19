local packet = require("core.packet")
local lineage = require("runtime.lineage")

local state = assert(lineage.create("prepare a plan", {
    lineage_id = "lineage-test",
    session_id = "session-test",
    work_mode = "plan",
    carrier = {max_bytes = 4096},
    budget = {steps = 20, generations = 2, carrier_bytes = 4096},
    time = 10,
}))
assert(state.status == "created")
assert(state.current_generation == 0)
assert(state.ledger[1].kind == "lineage_created")

local transaction = assert(lineage.begin_generation(state, {steps = 8}, {time = 11}))
local parallel, parallel_err = lineage.begin_generation(state, {steps = 8})
assert(parallel == nil)
assert(parallel_err:match("already pending"))
local instance = packet.new("prepare a plan", {
    id = "packet-lineage-1",
    lineage_id = state.lineage_id,
    generation = 1,
    work_mode = "plan",
    budget = {steps = 8},
})
local receipt = {
    kind = "l1_packet_birth_receipt",
    protocol_version = "l1.packet_birth.v0",
    packet_id = instance.id,
    domain_event_ref = "stream:1:birth:1",
    flow_ref = {stream_id = "stream", stream_epoch = 1, birth_seq = 1},
}
local entry = assert(lineage.commit_birth(state, transaction, instance, receipt, {time = 12}))
assert(entry.generation == 1)
assert(state.status == "running")
assert(state.current_packet_id == instance.id)
local repeated, repeated_err = lineage.commit_birth(state, transaction, instance, receipt)
assert(repeated == nil)
assert(repeated_err:match("already committed"))

local corpse = {
    corpse_id = "corpse-lineage-1",
    corpse_hash = string.rep("a", 64),
    lineage_id = state.lineage_id,
    packet_id = instance.id,
    generation = 1,
    terminal_kind = "internal_death",
    death_cause = "budget_exhausted",
    terminal_trace_ref = "event-terminal-1",
}
assert(lineage.register_corpse(state, corpse, {time = 13}))
assert(state.status == "evaluating_terminal")

local carrier = {
    carrier_id = "carrier-lineage-1",
    source_corpse_id = corpse.corpse_id,
    target_generation = 2,
}
assert(lineage.mark_continued(state, corpse, carrier, {time = 14}))
assert(state.status == "continuing")
local duplicate_child, duplicate_child_err = lineage.mark_continued(state, corpse, carrier)
assert(duplicate_child == nil)
assert(duplicate_child_err:match("not ready") or duplicate_child_err:match("already"))

local child_transaction = assert(lineage.begin_generation(state, {steps = 8}))
assert(child_transaction.parent_packet_id == instance.id)
assert(child_transaction.parent_corpse_id == corpse.corpse_id)
assert(child_transaction.ingress_carrier_id == carrier.carrier_id)
assert(lineage.validate(state))

print("test_lineage ok")
