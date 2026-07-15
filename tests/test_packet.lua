package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")

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

local p = packet.new("build a small body", {id = "packet-test"})

assert_eq(p.protocol_version, "packet.next.v0", "protocol")
assert_eq(p.status, "born", "status")
assert_eq(p.operator, "▽", "operator")
assert_eq(p.chaos.raw_prompt, "build a small body", "dirty prompt in chaos")
assert_true(type(p.physis.budget) == "table", "physis budget exists")
assert_true(p.substrate == p.physis, "substrate compatibility alias points to physis")
assert_true(type(p.boundary.crystallizations) == "table", "boundary exists")
assert_true(type(p.calm.structures) == "table", "calm exists")
assert_true(type(p.tension) == "table", "tension exists")
assert_eq(#p.trace, 1, "birth trace")
assert_eq(p.trace[1].type, "birth", "birth event")

local ok, event = packet.append_chaos(p, {
    operator = "☴",
    kind = "substrate_fragment",
    text = "candidate structure",
})

assert_true(ok, "append chaos returns packet")
assert_eq(event.type, "chaos_append", "chaos append event")
assert_eq(#p.chaos.fragments, 1, "chaos fragment stored")
assert_eq(#p.trace, 2, "chaos append traced")

local bad, bad_err = packet.crystallize(p, {
    calm_delta = {kind = "work_shape"},
})

assert_true(not bad, "crystallization without loss must fail")
assert_eq(bad_err, "crystallization requires loss table", "loss required")

local crystal_packet, crystal_event = packet.crystallize(p, {
    source_chaos_refs = {event.id},
    calm_delta = {
        kind = "work_shape",
        units = {
            {id = "packet_core", status = "done"},
        },
    },
    loss = {
        kind = "compression",
        amount = 0.12,
    },
    status = "accepted",
})

assert_true(crystal_packet, "crystallization succeeds")
assert_eq(crystal_event.type, "crystallization", "crystallization event")
assert_eq(crystal_event.operator, "☵", "crystallization operator")
assert_eq(#p.boundary.crystallizations, 1, "boundary crystallization stored")
assert_eq(#p.boundary.loss_records, 1, "loss record stored")
assert_eq(#p.calm.structures, 1, "calm structure stored")
assert_eq(p.calm.current.kind, "work_shape", "current calm set")
assert_eq(p.calm.status, "accepted", "calm status")

local tension_packet, tension_event = packet.measure_tension(p, {
    chaos_pressure = 7,
    calm_rigidity = 3,
    boundary_load = 2,
    unresolved_delta = 4,
    action_pressure = "hold",
})

assert_true(tension_packet, "tension measure succeeds")
assert_eq(tension_event.type, "tension_measure", "tension event")
assert_eq(p.tension.unresolved_delta, 4, "tension stored")

local dead, death_event = packet.die(p, "identity_loss", {
    cause = "identity_loss",
    do_not_repeat = "continue after semantic drift",
})

assert_true(dead, "death succeeds")
assert_eq(death_event.type, "death", "death event")
assert_eq(p.status, "dead", "dead status")
assert_eq(p.death.cause, "identity_loss", "death cause")
assert_eq(p.residue.do_not_repeat, "continue after semantic drift", "death residue")

local second_death, second_death_err = packet.die(p, "budget_exhausted", {
    cause = "budget_exhausted",
    do_not_repeat = "overwrite first death",
})
assert_true(not second_death, "second death rejected")
assert_eq(second_death_err, "dead packet cannot die", "second death error")
assert_eq(p.death.cause, "identity_loss", "first death preserved")
assert_eq(p.residue.do_not_repeat, "continue after semantic drift", "first residue preserved")

local post_manifest, post_manifest_err = packet.manifest_packet(p, {
    output = {type = "text", content = "corpse output"},
})
assert_true(not post_manifest, "posthumous manifest rejected")
assert_eq(post_manifest_err, "dead packet cannot manifest", "posthumous manifest error")
assert_eq(p.status, "dead", "corpse stays dead")

local post_chaos, post_chaos_err = packet.append_chaos(p, {
    operator = "☴",
    kind = "posthumous",
})
assert_true(not post_chaos, "posthumous chaos rejected")
assert_eq(post_chaos_err, "dead packet cannot append chaos", "posthumous chaos error")

local post_crystal, post_crystal_err = packet.crystallize(p, {
    calm_delta = {kind = "posthumous"},
    loss = {kind = "posthumous", amount = 0.1},
})
assert_true(not post_crystal, "posthumous crystallization rejected")
assert_eq(post_crystal_err, "dead packet cannot crystallize", "posthumous crystallization error")

local post_tension, post_tension_err = packet.measure_tension(p, {
    chaos_pressure = 99,
})
assert_true(not post_tension, "posthumous tension rejected")
assert_eq(post_tension_err, "dead packet cannot measure tension", "posthumous tension error")

local trace_length_at_death = #p.trace
local post_trace, post_trace_err = packet.append_trace(p, {
    type = "cycle",
    operator = "☲",
    truth_status = "semantic_proposal",
    payload = {kind = "posthumous"},
})
assert_true(not post_trace, "posthumous trace rejected")
assert_eq(post_trace_err, "dead packet cannot append trace", "posthumous trace error")
assert_eq(#p.trace, trace_length_at_death, "ledger frozen after death")

print("test_packet ok")
