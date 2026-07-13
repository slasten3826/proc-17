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

print("test_packet ok")
