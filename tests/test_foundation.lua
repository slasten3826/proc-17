package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local foundation = require("runtime.foundation")

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

local function enter_logic(instance)
    assert(packet.commit_transition(instance, {from = "▽", to = "☴", reason = "foundation_fixture"}))
    assert(packet.commit_transition(instance, {from = "☴", to = "☳", reason = "foundation_fixture"}))
    assert(packet.commit_transition(instance, {from = "☳", to = "☶", reason = "foundation_fixture"}))
    assert(packet.begin_tick(instance, "☶", {}))
end

local p = packet.new("foundation test")
assert_eq(foundation.state(p), "fluid", "new foundation state")
enter_logic(p)

local result = {
    kind = "spell_result",
    name = "py_compile",
    spell_kind = "py_compile_python_file",
    intention_hash = "abc",
    success = true,
    truth_status = "runtime_confirmed",
}

local pattern = assert(foundation.reinforce(p, result))
assert_eq(pattern.repetition_count, 1, "first repetition")
assert_eq(pattern.success_count, 1, "first success")
assert_eq(pattern.failure_count, 0, "no failures")
assert_true(pattern.strength > 0, "strength increased")
assert_eq(foundation.state(p), "crystallizing", "success crystallizes")
assert_eq(p.revisions.evidence, 1, "runtime evidence advances evidence revision")

foundation.reinforce(p, result)
local snap = foundation.snapshot(p)
assert_eq(snap.kind, "foundation_snapshot", "snapshot kind")
assert_eq(snap.reinforcements, 2, "reinforcements count")
assert_eq(snap.evidence_count, 2, "evidence count")

local failed = {
    kind = "spell_result",
    name = "py_compile",
    spell_kind = "py_compile_python_file",
    intention_hash = "abc",
    success = false,
    truth_status = "runtime_confirmed",
}
pattern = assert(foundation.reinforce(p, failed))
assert_eq(pattern.failure_count, 1, "failure count")
assert_eq(#p.runtime.evidence, 3, "runtime evidence stored")

-- truth rent: staleness must be earned through a real cast
local spells = require("logic.spells")

local function write_file(path, content)
    local file = assert(io.open(path, "w"))
    file:write(content)
    file:close()
end

local scratch = "sandbox/foundation_rent_scratch.py"
write_file(scratch, "y = 1\n")

local rent_packet = packet.new("truth rent probe")
rent_packet.physis.clock.ticks = 5
enter_logic(rent_packet)

local live_cast = assert(spells.run({
    kind = "py_compile_python_file",
    name = "rent_probe",
    intention = "rent_probe",
    path = scratch,
    tick = rent_packet.physis.clock.ticks,
}))
assert(foundation.reinforce(rent_packet, live_cast))

local hot_snap = foundation.snapshot(rent_packet)
assert_eq(hot_snap.contains_stale, false, "fresh cast is not stale")
for _, entry in pairs(hot_snap.patterns) do
    assert_eq(entry.freshness, "hot", "referent verified pattern is hot")
    assert_eq(entry.effective_truth_status, "runtime_confirmed", "hot pattern keeps confirmation")
end

write_file(scratch, "y = 2\n")
local stale_snap = foundation.snapshot(rent_packet)
assert_eq(stale_snap.contains_stale, true, "mutated referent surfaces as stale")
assert_eq(stale_snap.stale_count, 1, "one stale pattern")
for _, entry in pairs(stale_snap.patterns) do
    assert_eq(entry.freshness, "cold", "changed referent pattern is cold")
    assert_eq(entry.effective_truth_status, "semantic_proposal", "cold pattern degrades to proposal")
end

-- recast pays the rent: a NEW event resets the clock
rent_packet.physis.clock.ticks = 9
local recast = assert(spells.run({
    kind = "py_compile_python_file",
    name = "rent_probe",
    intention = "rent_probe",
    path = scratch,
    tick = rent_packet.physis.clock.ticks,
}))
assert(foundation.reinforce(rent_packet, recast))

local paid_snap = foundation.snapshot(rent_packet)
assert_eq(paid_snap.contains_stale, false, "recast pattern is fresh again")
for _, entry in pairs(paid_snap.patterns) do
    assert_eq(entry.freshness, "hot", "recast pattern is hot")
end

os.remove(scratch)

print("test_foundation ok")
