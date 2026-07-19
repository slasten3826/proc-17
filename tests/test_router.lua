package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local body = require("runtime.body")
local grave = require("runtime.grave")
local router = require("runtime.router")

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

local function move(instance, target, tick)
    assert(packet.commit_transition(instance, {
        from = instance.operator,
        to = target,
        reason = "router_fixture",
    }))
    if tick then
        assert(packet.begin_tick(instance, target, {}))
    end
end

local p = packet.new("route packet", {
    work_mode = "plan",
    budget = {steps = 8, substrate_calls = 1},
})

local d, err = router.after_tick(p, {operator = "☵"})
assert_true(d, err)
assert_eq(d.to, "☴", "after encode routes to observe")
assert_eq(d.reason, "mandatory_eye_tick", "encode hard rule")

d, err = router.after_tick(p, {operator = "☳"})
assert_true(d, err)
assert_eq(d.to, "☴", "after choose routes to observe")

d, err = router.after_tick(p, {operator = "☲"})
assert_true(d, err)
assert_eq(d.to, "☱", "after cycle routes to runtime")

d, err = router.after_tick(p, {operator = "☶"})
assert_true(d, err)
assert_eq(d.to, "☱", "after logic routes to runtime")

d, err = router.after_tick(p, {operator = "☴"})
assert_true(d, err)
assert_eq(d.to, "☵", "observe without calm routes to encode")
assert_eq(d.reason, "missing_calm", "observe missing calm reason")

body.apply_crystallized_work(p, {
    {id = "a", status = "pending"},
    {id = "b", status = "pending"},
})

d, err = router.after_tick(p, {operator = "☴"})
assert_true(d, err)
assert_eq(d.to, "☳", "observe with calm alternatives routes to choose")
assert_eq(d.reason, "calm_alternatives", "observe calm reason")

d, err = router.after_tick(p, {
    operator = "☴",
    payload = {pressure = {runtime_ready = true}},
})
assert_true(d, err)
assert_eq(d.to, "☱", "observe runtime-ready routes to runtime")

move(p, "☴")
move(p, "☳", true)
assert(body.record_choice(p, {
    kind = "choice_payload",
    selected = {{id = "a"}},
    killed_alternatives = {{id = "b"}},
    not_chosen_count = 1,
    truth_status = "runtime_confirmed",
}))
move(p, "☴")

d, err = router.after_tick(p, {operator = "☴"})
assert_true(d, err)
assert_eq(d.to, "☱", "observe after choice routes to runtime")
assert_eq(d.reason, "choice_observed", "choice observed reason")

d, err = router.after_tick(p, {operator = "☱"})
assert_true(d, err)
assert_eq(d.to, "☲", "runtime with remaining work routes to cycle")
assert_eq(d.reason, "remaining_work", "runtime remaining reason")

d, err = router.after_tick(p, {
    operator = "☱",
    payload = {pressure = {validation_pressure = true}},
})
assert_true(d, err)
assert_eq(d.to, "☶", "runtime validation pressure routes to logic")

d, err = router.after_tick(p, {
    operator = "☱",
    payload = {pressure = {semantic_uncertainty = true}},
})
assert_true(d, err)
assert_eq(d.to, "☴", "runtime semantic uncertainty routes to observe")

body.apply_crystallized_work(p, {
    {id = "a", status = "done"},
    {id = "b", status = "done"},
})

d, err = router.after_tick(p, {operator = "☱"})
assert_true(d, err)
assert_eq(d.to, "△", "runtime with no remaining work routes to manifest")
assert_eq(d.reason, "no_remaining_work", "runtime no remaining reason")

p.tension.loss_near_death = true
d, err = router.after_tick(p, {operator = "☱"})
assert_true(d, err)
assert_eq(d.to, "△", "loss pressure routes to manifest")
assert_eq(d.reason, "loss_manifest_pressure", "loss reason")
assert_eq(d.pressure.loss.kind, "packet_loss", "loss axis")
assert_eq(d.pressure.budget.kind, "runtime_budget", "budget axis")

local build_packet = packet.new("build route packet", {
    metadata = {work_mode = "build"},
    budget = {steps = 8, substrate_calls = 1},
})
body.apply_crystallized_work(build_packet, {
    {id = "a", status = "pending"},
})

d, err = router.after_tick(build_packet, {
    operator = "☱",
    work_mode = "build",
})
assert_true(d, err)
assert_eq(d.to, "☶", "build mode remaining work without evidence routes to logic")
assert_eq(d.reason, "missing_build_evidence", "build evidence reason")

move(build_packet, "☴")
move(build_packet, "☵")
move(build_packet, "☲", true)
assert(body.record_cycle(build_packet, {
    kind = "cycle_decision_payload",
    decision = "stop_repetition",
    reason = "max_turns",
    truth_status = "runtime_confirmed",
}))
move(build_packet, "☱")

d, err = router.after_tick(build_packet, {
    operator = "☱",
    work_mode = "build",
})
assert_true(d, err)
assert_eq(d.to, "△", "build mode stop repetition routes to manifest")
assert_eq(d.reason, "cycle_stop_manifest_pressure", "cycle stop reason")

local plan_packet = packet.new("plan route packet", {
    metadata = {work_mode = "plan"},
    budget = {steps = 8, substrate_calls = 1},
})
body.apply_crystallized_work(plan_packet, {
    {id = "a", status = "pending"},
})

d, err = router.after_tick(plan_packet, {
    operator = "☱",
    work_mode = "plan",
})
assert_true(d, err)
assert_eq(d.to, "☲", "plan mode does not require build evidence")
assert_eq(d.reason, "remaining_work", "plan remains normal")

local karma_packet = packet.new("karma route packet", {
    metadata = {work_mode = "plan"},
    budget = {steps = 8, substrate_calls = 1},
})
body.apply_crystallized_work(karma_packet, {
    {id = "a", status = "pending"},
})
local attached = assert(grave.attach(karma_packet, {
    packet_id = "ancestor-loop",
    status = "dead",
    death = {cause = "budget_exhausted"},
    residue = {
        do_not_repeat = "loop consumed budget without progress",
        last_operator = "☱",
    },
}))
assert_eq(attached.warning_count, 1, "karma warning attached")

d, err = router.after_tick(karma_packet, {
    operator = "☱",
    work_mode = "plan",
})
assert_true(d, err)
assert_eq(d.to, "☲", "karma warning allows first cycle")
assert_eq(d.reason, "remaining_work", "first cycle still normal")
assert_eq(d.pressure.karma.warning_count, 1, "karma pressure visible")

move(karma_packet, "☴")
move(karma_packet, "☵")
move(karma_packet, "☲", true)
assert(body.record_cycle(karma_packet, {
    kind = "cycle_decision_payload",
    decision = "again",
    reason = "remaining_work",
    truth_status = "runtime_confirmed",
}))
move(karma_packet, "☱")

d, err = router.after_tick(karma_packet, {
    operator = "☱",
    work_mode = "plan",
})
assert_true(d, err)
assert_eq(d.to, "△", "karma warning blocks repeated dead cycle")
assert_eq(d.reason, "karma_warning_manifest_pressure", "karma warning reason")

local rejected_packet = packet.new("build rejected route", {
    metadata = {work_mode = "build"},
    budget = {steps = 8, substrate_calls = 1},
})
body.apply_crystallized_work(rejected_packet, {
    {id = "a", status = "pending"},
})
move(rejected_packet, "☴")
move(rejected_packet, "☳")
move(rejected_packet, "☶", true)
assert(body.record_validation(rejected_packet, {
    kind = "logic_validation_payload",
    status = "rejected",
    truth_status = "runtime_confirmed",
}))
move(rejected_packet, "☱")

d, err = router.after_tick(rejected_packet, {
    operator = "☱",
    work_mode = "build",
})
assert_true(d, err)
assert_eq(d.to, "☴", "build rejected validation routes to observe repair")
assert_eq(d.reason, "validation_rejected_semantic_repair", "rejected repair reason")

local invalid, invalid_err = router.after_tick(p, {operator = "NOPE"})
assert_true(not invalid, "invalid operator should fail")
assert_eq(invalid_err, "invalid_operator", "invalid operator error")

-- logic stamp: one court visit per evidence state
local freshness = require("runtime.freshness")

local stamp_packet = packet.new("logic stamp packet", {
    metadata = {work_mode = "build"},
    budget = {steps = 8, substrate_calls = 1},
})
body.apply_crystallized_work(stamp_packet, {
    {id = "unit", status = "pending"},
})

d, err = router.after_tick(stamp_packet, {operator = "☱", work_mode = "build"})
assert_true(d, err)
assert_eq(d.to, "☶", "no stamp: court open")
assert_eq(d.reason, "missing_build_evidence", "no stamp reason")

stamp_packet.runtime.logic_stamp = {
    kind = "logic_stamp",
    verdict = "no_spell",
    evidence_fingerprint = freshness.evidence_fingerprint(stamp_packet),
    truth_status = "runtime_confirmed",
}
d, err = router.after_tick(stamp_packet, {operator = "☱", work_mode = "build"})
assert_true(d, err)
assert_eq(d.to, "△", "fresh stamp: court closed, manifest pressure")
assert_eq(d.reason, "logic_stamp_no_new_evidence", "fresh stamp reason")

stamp_packet.runtime.evidence[#stamp_packet.runtime.evidence + 1] = {
    kind = "spell_result",
    intention_hash = "newproof",
    cast_tick = 5,
    success = true,
    truth_status = "runtime_confirmed",
}
d, err = router.after_tick(stamp_packet, {operator = "☱", work_mode = "build"})
assert_true(d, err)
assert_true(d.reason ~= "logic_stamp_no_new_evidence", "new evidence stales the stamp")

print("test_router ok")
