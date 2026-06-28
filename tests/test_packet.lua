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

local p = packet.new("test task", {id = "packet-test"})
assert_eq(p.protocol_version, "packet.v0", "protocol version")
assert_eq(p.status, "born", "birth status")
assert_eq(p.mode, "manifest", "default mode")
assert_eq(p.operator, "▽", "birth operator")
assert_eq(#p.trace, 1, "birth event appended")

assert_true(packet.validate_mode("chaos"), "chaos mode should validate")
assert_true(not packet.validate_mode("invalid"), "invalid mode should not validate")
assert_true(packet.can_write_code(p), "manifest packet can write code")

ok, err = packet.enter_mode(p, "chaos", "test")
assert_true(ok, err)
assert_eq(p.mode, "chaos", "mode updated")
assert_true(not packet.can_write_code(p), "chaos packet cannot write code")
assert_eq(p.trace[#p.trace].type, "mode_enter", "mode enter event")

ok, err = packet.spend(p, {steps = 1})
assert_true(ok, err)
assert_eq(p.budget.steps, 31, "budget spend")

packet.record_unsupported(p, {
    emitted_form = "packet.promote_gap",
    unsupported_because = "method does not exist",
    recurrence_key = "packet.promote_gap",
})

local event = p.trace[#p.trace]
assert_eq(event.type, "unsupported_form", "unsupported event type")
assert_eq(event.truth_status, "unsupported", "unsupported truth status")
assert_eq(event.payload.recurrence_count, 1, "unsupported recurrence count")

packet.record_unsupported(p, {
    emitted_form = "packet.promote_gap",
    recurrence_key = "packet.promote_gap",
})

event = p.trace[#p.trace]
assert_eq(event.payload.recurrence_count, 2, "repeated unsupported recurrence count")

ok, err = packet.decide_gap(p, "packet.promote_gap", "promote")
assert_true(ok, err)
assert_eq(p.trace[#p.trace].truth_status, "promoted", "gap promoted")

ok, err = packet.manifest(p, {truth_status = "semantic_proposal", result = "bad"})
assert_true(not ok, "semantic proposal must not manifest as final truth")

ok, err = packet.manifest(p, {truth_status = "runtime_confirmed", result = "ok"})
assert_true(ok, err)
assert_eq(p.status, "manifested", "manifest status")

ok, err = packet.die(p, "complete")
assert_true(ok, err)
assert_eq(p.status, "dead", "death status")
assert_eq(p.residue.cause, "complete", "death residue cause")

print("test_packet ok")
