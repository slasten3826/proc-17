package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local runtime = require("runtime.pressure_snapshot")

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

local function snapshot(input)
    local payload, err = runtime.snapshot(input)
    if not payload then
        error("runtime snapshot failed: " .. tostring(err))
    end
    return payload
end

local p = packet.new("runtime pressure task", {
    id = "packet-runtime-test",
    budget = {
        steps = 2,
        substrate_calls = 0,
        tool_calls = -1,
    },
})

packet.enter(p, "☰")
packet.enter(p, "☴")

local trace_count_before = #p.trace
local budget_steps_before = p.budget.steps
local operator_before = p.operator

local payload = snapshot({
    packet = p,
    limits = {trace_tail_count = 2},
    logic_context = {
        last_validation_event = "validation-1",
        accepted_count = 2,
        rejected_count = 1,
        rejection_reasons = {"absent_from_listing"},
    },
    cycle_context = {
        last_cycle_decision = "continue",
        last_cycle_reasons = {"continuation_payable"},
        repeated_fingerprint = true,
        turn_budget_pressure = "payable",
    },
    manifest_context = {
        pending_output_shape = "summary",
        output_pressure = "not_ready",
    },
})

assert_eq(payload.kind, "runtime_pressure_snapshot_payload", "payload kind")
assert_eq(payload.packet_id, "packet-runtime-test", "packet id")
assert_eq(payload.protocol_version, "packet.v0", "protocol version")
assert_eq(payload.status, "running", "packet status")
assert_eq(payload.mode, "manifest", "packet mode")
assert_eq(payload.operator, "☴", "packet operator")
assert_eq(payload.truth_status, "runtime_confirmed", "truth status")

assert_eq(payload.packet_state.tick_count, trace_count_before, "tick count defaults to trace count")
assert_eq(payload.budget_pressure.budget.steps, 2, "budget copied")
assert_eq(#payload.budget_pressure.budget_negative_keys, 1, "negative budget key count")
assert_eq(payload.budget_pressure.budget_negative_keys[1], "tool_calls", "negative budget key")
assert_true(#payload.budget_pressure.budget_exhausted_keys >= 2, "exhausted budget keys include zero and negative")

assert_eq(payload.trace_pressure.trace_count, trace_count_before, "trace count")
assert_eq(#payload.trace_pressure.trace_tail, 2, "bounded trace tail")
assert_eq(payload.trace_pressure.last_event_type, "operator_enter", "last event type")
assert_eq(payload.trace_pressure.last_truth_status, "runtime_confirmed", "last truth status")

assert_eq(payload.logic_pressure.last_validation_event, "validation-1", "logic pressure event")
assert_eq(payload.logic_pressure.accepted_count, 2, "logic accepted count")
assert_eq(payload.logic_pressure.rejected_count, 1, "logic rejected count")
assert_eq(payload.logic_pressure.rejection_reasons[1], "absent_from_listing", "logic rejection reason")

assert_eq(payload.cycle_pressure.last_cycle_decision, "continue", "cycle pressure decision")
assert_eq(payload.cycle_pressure.last_cycle_reasons[1], "continuation_payable", "cycle pressure reason")
assert_eq(payload.cycle_pressure.repeated_fingerprint, true, "cycle repeated fingerprint")

assert_eq(payload.manifest_pressure.pending_output_shape, "summary", "manifest pending shape")
assert_eq(payload.manifest_pressure.output_pressure, "not_ready", "manifest output pressure")

assert_eq(payload.death_pressure.status_dead, false, "not dead")
assert_eq(payload.death_pressure.status_dying, false, "not dying")
assert_eq(payload.conditions.budget_negative, true, "budget negative condition")
assert_eq(payload.conditions.last_cycle_decision, "continue", "condition cycle decision")

assert_eq(payload.can_continue, nil, "runtime must not decide continuation")
assert_eq(payload.next_action, nil, "runtime must not choose next action")
assert_eq(payload.stop_reason, nil, "runtime must not stop")
assert_eq(payload.route_choice, nil, "runtime must not route")
assert_eq(payload.plan, nil, "runtime must not plan")

assert_eq(#p.trace, trace_count_before, "snapshot must not append trace")
assert_eq(p.budget.steps, budget_steps_before, "snapshot must not mutate budget")
assert_eq(p.operator, operator_before, "snapshot must not mutate operator")

payload.budget_pressure.budget.steps = 99
payload.logic_pressure.rejection_reasons[1] = "mutated"

local payload_again = snapshot({
    packet = p,
    limits = {trace_tail_count = 2},
    logic_context = {
        last_validation_event = "validation-1",
        accepted_count = 2,
        rejected_count = 1,
        rejection_reasons = {"absent_from_listing"},
    },
    cycle_context = {
        last_cycle_decision = "continue",
        last_cycle_reasons = {"continuation_payable"},
        repeated_fingerprint = true,
        turn_budget_pressure = "payable",
    },
    manifest_context = {
        pending_output_shape = "summary",
        output_pressure = "not_ready",
    },
})

assert_eq(payload_again.budget_pressure.budget.steps, 2, "snapshot should copy budget")
assert_eq(payload_again.logic_pressure.rejection_reasons[1], "absent_from_listing", "snapshot should copy arrays")

local missing, missing_err = runtime.snapshot({})
assert_true(not missing, "missing packet should fail")
assert_eq(missing_err, "missing_packet", "missing packet error")

local bad_trace, bad_trace_err = runtime.snapshot({packet = {budget = {}}})
assert_true(not bad_trace, "bad trace should fail")
assert_eq(bad_trace_err, "invalid_trace", "bad trace error")

local bad_budget, bad_budget_err = runtime.snapshot({packet = {trace = {}}})
assert_true(not bad_budget, "bad budget should fail")
assert_eq(bad_budget_err, "invalid_budget", "bad budget error")

local bad_limits, bad_limits_err = runtime.snapshot({packet = p, limits = {trace_tail_count = -1}})
assert_true(not bad_limits, "bad limits should fail")
assert_eq(bad_limits_err, "invalid_limits", "bad limits error")

local dead = packet.new("dead runtime pressure task", {id = "packet-runtime-dead"})
packet.die(dead, "complete")
local dead_payload = snapshot({packet = dead})
assert_eq(dead_payload.death_pressure.status_dead, true, "dead pressure")
assert_eq(dead_payload.death_pressure.death_residue_present, true, "death residue present")

print("test_runtime_pressure_snapshot ok")
