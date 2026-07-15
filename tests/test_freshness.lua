package.path = "./?.lua;./?/init.lua;" .. package.path

local freshness = require("runtime.freshness")
local spells = require("logic.spells")

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

local function write_file(path, content)
    local file = assert(io.open(path, "w"))
    file:write(content)
    file:close()
end

-- referent clock: earned staleness through a real cast
local scratch = "sandbox/freshness_scratch.py"
write_file(scratch, "x = 1\n")

local cast = spells.run({
    kind = "py_compile_python_file",
    name = "freshness_probe",
    path = scratch,
    tick = 3,
})
assert_true(cast, "cast succeeded")
assert_eq(cast.cast_tick, 3, "cast_tick recorded")
assert_eq(cast.referent, scratch, "referent recorded")
assert_true(cast.referent_hash ~= nil, "referent hash recorded")

local fresh = freshness.read(cast, {tick = 4})
assert_eq(fresh.zone, "hot", "matching referent is hot")
assert_eq(fresh.effective_truth_status, "runtime_confirmed", "hot keeps confirmation")
assert_eq(fresh.reason, "referent_verified", "hot reason")

write_file(scratch, "x = 2\n")
local stale = freshness.read(cast, {tick = 4})
assert_eq(stale.zone, "cold", "changed referent is cold")
assert_eq(stale.effective_truth_status, "semantic_proposal", "cold degrades to proposal")
assert_eq(stale.reason, "referent_changed", "cold reason")
assert_eq(cast.truth_status, "runtime_confirmed", "reader does not mutate the record")
assert_eq(cast.referent_hash ~= nil, true, "record hash untouched")

-- tick window fallback for unhashable referents
local command_cast = spells.run({
    kind = "check_command_exit_code",
    name = "true_probe",
    command = {"true"},
    tick = 10,
})
assert_true(command_cast, "command cast succeeded")
assert_eq(command_cast.referent_hash, nil, "command spell has no referent hash")
assert_eq(command_cast.cast_tick, 10, "command cast tick")

local warm = freshness.read(command_cast, {tick = 15})
assert_eq(warm.zone, "warm", "inside window is warm")
assert_eq(warm.effective_truth_status, "runtime_confirmed", "warm keeps confirmation")
assert_eq(warm.age, 5, "age computed")

local expired = freshness.read(command_cast, {tick = 30})
assert_eq(expired.zone, "cold", "expired window is cold")
assert_eq(expired.effective_truth_status, "semantic_proposal", "expired degrades to proposal")
assert_eq(expired.reason, "tick_window_expired", "expired reason")

local custom_window = freshness.read(command_cast, {tick = 30, warm_window = 25})
assert_eq(custom_window.zone, "warm", "custom window respected")

-- unclocked record: the reader without a clock refuses live truth
local unclocked = freshness.read({kind = "spell_result", truth_status = "runtime_confirmed"}, {tick = 5})
assert_eq(unclocked.zone, "unclocked", "no clock fields is unclocked")
assert_eq(unclocked.effective_truth_status, "semantic_proposal", "unclocked degrades to proposal")
assert_eq(unclocked.reason, "no_clock", "unclocked reason")

os.remove(scratch)

-- evidence fingerprint: deterministic, changes with evidence
local instance = {runtime = {evidence = {}}}
local empty_fp = freshness.evidence_fingerprint(instance)
assert_true(empty_fp ~= nil, "empty evidence has a fingerprint")
assert_eq(empty_fp, freshness.evidence_fingerprint(instance), "fingerprint deterministic")

instance.runtime.evidence[1] = {intention_hash = "abc", cast_tick = 3, success = true}
local one_fp = freshness.evidence_fingerprint(instance)
assert_true(one_fp ~= empty_fp, "fingerprint changes when evidence appended")
assert_eq(one_fp, freshness.evidence_fingerprint(instance), "fingerprint stable for same evidence")

print("test_freshness ok")
