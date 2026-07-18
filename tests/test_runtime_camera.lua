package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local body = require("runtime.body")
local budget = require("runtime.budget")
local loss = require("runtime.loss")
local freshness = require("runtime.freshness")
local camera = require("runtime.camera")
local reconciliation = require("runtime.reconciliation")
local pressure = require("runtime.pressure")
local runtime_organ = require("organs.runtime")

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

local function find_kind(snapshot, kind)
    for _, value in ipairs(snapshot.contributions or {}) do
        if value.kind == kind then
            return value
        end
    end
end

local p = packet.new("runtime camera treatment", {
    id = "runtime-camera-test",
    budget = {steps = 12, loss = 2},
})
assert(budget.init(p))
assert(loss.init(p))

local caller_payload = {kind = "immutable_probe", nested = {value = 1}}
local immutable_event = assert(packet.append_event(p, {
    type = "tension_measure",
    operator = "▽",
    truth_status = "runtime_confirmed",
    payload = caller_payload,
}))
caller_payload.nested.value = 99
caller_payload.added = true
assert_eq(immutable_event.payload.nested.value, 1, "trace recursively snapshots caller payload")
assert_eq(immutable_event.payload.added, nil, "caller cannot append fields into stored trace")

local revisions_before = assert(camera.revision_snapshot(p))
local budget_before = budget.snapshot(p)
local loss_before = loss.snapshot(p)
local progress_before = body.progress(p)
local fingerprint_before = freshness.evidence_fingerprint(p)
assert(budget.charge(p, {
    operator = "▽",
    cost = {steps = 1},
    source = "body_tick",
}))
local routine, routine_event = assert(camera.capture(p, {
    operator = "▽",
    revisions_before = revisions_before,
    source_event_refs = {},
    effect_refs = {},
    budget_event_refs = {"budget:event:1"},
    budget_before = budget_before,
    loss_before = loss_before,
    progress_before = progress_before,
    evidence_fingerprint_before = fingerprint_before,
}))
assert_eq(routine.seq, 1, "first completed tick creates first runtime frame")
assert_eq(routine.changed_components[1].component, "budget", "routine charge remains visible")
assert_eq(routine.changed_components[1].cause, "body_tick_economics", "routine cost is typed")
assert_eq(p.runtime.budget.spent.steps, 1, "camera capture adds no body step")
routine.changed_components[1].component = "forged"
assert_eq(routine_event.payload.changed_components[1].component, "budget",
    "returned frame cannot rewrite immutable trace")

local routine_inspection = assert(reconciliation.inspect(p))
assert_eq(routine_inspection.pending_frame_count, 1, "routine frame remains available to readers")
assert_eq(routine_inspection.significant_frame_count, 0, "routine budget change creates no debt")
assert_eq(routine_inspection.has_debt, false, "runtime availability alone creates no pressure")
local routine_pressure = assert(pressure.derive(p, {operator = "☲"}, {
    current_operator = "☲",
    options = {work_mode = "build"},
}))
assert_eq(find_kind(routine_pressure, "runtime_reconciliation_debt"), nil,
    "routine frame does not route to RUNTIME")
assert_eq(find_kind(routine_pressure, "runtime_mismatch"), nil,
    "missing independent comparator cannot duplicate pressure")

revisions_before = assert(camera.revision_snapshot(p))
budget_before = budget.snapshot(p)
loss_before = loss.snapshot(p)
progress_before = body.progress(p)
fingerprint_before = freshness.evidence_fingerprint(p)
assert(body.apply_crystallized_work(p, {
    {id = "camera-work", status = "pending"},
}))
local significant, significant_event = assert(camera.capture(p, {
    operator = "▽",
    revisions_before = revisions_before,
    source_event_refs = {},
    effect_refs = {},
    budget_before = budget_before,
    loss_before = loss_before,
    progress_before = progress_before,
    evidence_fingerprint_before = fingerprint_before,
}))
assert_eq(significant.seq, 2, "second completed effect creates second frame")
assert_eq(significant.changed_components[1].component, "calm", "CALM change is captured")

local significant_inspection = assert(reconciliation.inspect(p))
assert_eq(significant_inspection.significant_frame_count, 1, "meaningful effect creates one bounded debt")
assert_true(significant_inspection.has_debt, "meaningful effect requests RUNTIME reconciliation")
local significant_pressure = assert(pressure.derive(p, {operator = "☲"}, {
    current_operator = "☲",
    options = {work_mode = "build"},
}))
local debt = assert(find_kind(significant_pressure, "runtime_reconciliation_debt"),
    "camera debt becomes named pressure")
assert_eq(debt.amount, 1, "many pending frames collapse to one binary pressure")
assert_eq(debt.significant_frame_count, 1, "pressure exposes bounded causal count")

assert(packet.commit_transition(p, {from = "▽", to = "☴", reason = "camera_test"}))
assert(packet.commit_transition(p, {from = "☴", to = "☱", reason = "camera_test"}))
assert(packet.begin_tick(p, "☱", {}))
local ready = assert(runtime_organ.readiness(p))
assert_true(ready.ready, "RUNTIME is ready while significant frames are pending")
local record, reconciliation_event = assert(camera.reconcile(p, {
    through_seq = significant_inspection.through_seq,
    resolved_refs = significant_inspection.resolved_refs,
    unresolved_refs = {"runtime:semantic:future"},
    completion_state = significant_inspection.completion_state,
}))
assert_eq(record.from_seq, 1, "first reconciliation covers the complete camera interval")
assert_eq(record.through_seq, 2, "reconciliation advances through observed head")
assert_eq(record.unresolved_refs[1], "runtime:semantic:future", "unresolved refs survive reconciliation")
record.unresolved_refs[1] = "forged"
assert_eq(reconciliation_event.payload.unresolved_refs[1], "runtime:semantic:future",
    "reconciliation trace is immutable")
local state = assert(camera.reconciliation_state(p))
assert_eq(state.reconciled_through, 2, "watermark advances monotonically")
assert_eq(assert(reconciliation.inspect(p)).has_debt, false, "reconciled effect discharges debt")

revisions_before = assert(camera.revision_snapshot(p))
budget_before = budget.snapshot(p)
loss_before = loss.snapshot(p)
progress_before = body.progress(p)
fingerprint_before = freshness.evidence_fingerprint(p)
assert(budget.charge(p, {
    operator = "☱",
    cost = {steps = 1},
    source = "body_tick",
}))
assert(camera.capture(p, {
    operator = "☱",
    revisions_before = revisions_before,
    source_event_refs = {reconciliation_event.id},
    effect_refs = {reconciliation_event.id},
    budget_event_refs = {"budget:event:2"},
    budget_before = budget_before,
    loss_before = loss_before,
    progress_before = progress_before,
    evidence_fingerprint_before = fingerprint_before,
}))
local own_frame = assert(reconciliation.inspect(p))
assert_eq(own_frame.pending_frame_count, 1, "RUNTIME own frame remains visible telemetry")
assert_eq(own_frame.has_debt, false, "RUNTIME own routine frame does not recreate pressure")
assert_eq(assert(runtime_organ.readiness(p)).ready, false, "nothing_to_reconcile is explicit readiness")

local pending_copy = assert(camera.pending(p))
pending_copy[1].operator = "forged"
assert_eq(assert(camera.pending(p))[1].operator, "☱", "camera readers receive immutable copies")

assert(packet.die(p, "cancelled", {cause = "cancelled"}))
local dead_frame, dead_frame_err = camera.capture(p, {
    operator = "☱",
    revisions_before = p.revisions,
})
assert_true(not dead_frame, "dead packet rejects camera capture")
assert_eq(dead_frame_err, "dead packet cannot capture runtime frame", "dead camera error")
local dead_reconciliation, dead_reconciliation_err = camera.reconcile(p, {})
assert_true(not dead_reconciliation, "dead packet rejects runtime reconciliation")
assert_eq(dead_reconciliation_err, "dead packet cannot reconcile runtime frames", "dead reconciliation error")

print("test_runtime_camera ok")
