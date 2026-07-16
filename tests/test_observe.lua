package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local observe = require("organs.observe")
local freshness = require("runtime.freshness")
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

local p = packet.new("observe this task")
local before_calm_count = #p.calm.structures

local observed, payload = observe.run(p, fake, {
    work_mode = "plan",
})

assert_true(observed, "observe should return packet")
assert_eq(payload.kind, "observe_organ_payload", "payload kind")
assert_eq(payload.truth_status, "semantic_proposal", "payload truth")
assert_eq(payload.call.operator, "☴", "call operator")
assert_eq(payload.call.prompt_payload, "observe this task", "call prompt")
assert_eq(payload.response.text, "fake substrate response", "fake text")
assert_eq(#p.chaos.fragments, 1, "chaos fragment appended")
assert_eq(p.chaos.fragments[1].kind, "substrate_response", "fragment kind")
assert_eq(p.chaos.fragments[1].truth_status, "semantic_proposal", "fragment truth")
assert_eq(p.trace[#p.trace].type, "observation", "canonical trace event")
assert_eq(p.trace[#p.trace].operator, "☴", "trace operator")
assert_eq(p.trace[#p.trace].truth_status, "runtime_confirmed", "observation occurrence is confirmed")
assert_eq(#p.calm.structures, before_calm_count, "observe must not write calm")
assert_eq(#p.boundary.observations.upper, 1, "upper observation stored")
assert_true(p.chaos.observations == p.boundary.observations.upper, "legacy upper observations alias canonical store")
assert_eq(p.boundary.observations.upper[1].id, payload.observation_id, "payload points to observation")
assert_eq(p.boundary.observations.upper[1].content_truth_status, "semantic_proposal", "observed meaning remains proposal")
assert_eq(p.boundary.observations.upper[1].event_truth_status, "runtime_confirmed", "observation act is confirmed")
assert_eq(p.boundary.observations.upper[1].sensor_output_refs[1], payload.field_unit_id, "observation predicts its proposal unit")
assert_eq(payload.chaos_trace_event_id, p.boundary.observations.upper[1].source_refs[1], "raw fragment remains a named source")
assert_eq(payload.field_unit_id, "unit:1", "direct OBSERVE appends first shadow unit")
assert_eq(p.field.units[payload.field_unit_id].created_by, "☴", "OBSERVE owns shadow unit")
assert_eq(p.field.units[payload.field_unit_id].carrier.text, "fake substrate response", "shadow carrier matches response")
assert_eq(p.field.units[payload.field_unit_id].content_truth_status, "semantic_proposal", "shadow truth remains semantic")

local post_output_freshness = assert(freshness.latest_eye(p, "upper"))
assert_eq(post_output_freshness.zone, "stale", "upper eye sees that its proposal changed potential")
assert_eq(post_output_freshness.changed_components[1].component, "potential", "only potential changed after proposal")
assert_eq(p.boundary.observations.upper[1].read_revisions.potential, 0, "freshness read does not rewrite history")

local missing, missing_err = observe.run(p, nil)
assert_true(not missing, "missing substrate should fail")
assert_eq(missing_err, "missing_substrate", "missing substrate error")

print("test_observe ok")
