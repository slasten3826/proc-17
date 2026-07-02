package.path = "./?.lua;./?/init.lua;" .. package.path

local runner = require("runtime.runner")
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

local p, result = runner.single_pass("build notes app", fake, {
    work_mode = "plan",
    packet_options = {
        budget = {steps = 8, encode_items = 8},
    },
    choose = {
        limits = {max_selected = 1, max_killed_sample = 8},
    },
})

assert_true(p, result)
assert_eq(result.kind, "runner_single_pass_result", "result kind")
assert_eq(result.packet_id, p.id, "packet id")
assert_eq(result.stages.observe.kind, "observe_organ_payload", "observe stage")
assert_eq(result.stages.encode.kind, "encode_organ_payload", "encode stage")
assert_eq(result.stages.choose.kind, "choose_collapse_payload", "choose stage")
assert_eq(result.stages.cycle.kind, "cycle_decision_payload", "cycle stage")
assert_eq(result.stages.manifest.kind, "manifest_payload", "manifest stage")
assert_eq(result.stages.manifest.output.type, "plan", "plan manifest type")
assert_eq(result.stages.cycle.decision, "again", "unfinished work should continue")
assert_eq(p.status, "running", "again must leave packet running")
assert_eq(p.death, nil, "again must not kill packet")
assert_eq(#p.chaos.fragments, 1, "observe appended chaos")
assert_true(#p.calm.work_units > 0, "encode created work units")
assert_eq(#p.boundary.choices, 1, "choose recorded boundary")
assert_eq(#p.boundary.cycles, 1, "cycle recorded boundary")
assert_eq(p.manifest, nil, "turn manifest should not finalize packet on again")

local missing, err = runner.single_pass("build notes app", nil)
assert_true(not missing, "missing substrate should fail")
assert_eq(err, "observe:missing_substrate", "missing substrate stage error")

print("test_runner ok")
