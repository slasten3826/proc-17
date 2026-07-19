package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")
local packet = require("core.packet")
local plan_completion = require("runtime.plan_completion")
local pressure_action = require("runtime.pressure_action")
local qualified_pressure = require("runtime.qualified_pressure")
local registry = require("runtime.operator_registry")
local fixture = require("tests.support.plan_life")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function find_witness(snapshot, kind)
    for _, witness in ipairs(snapshot.witnesses or snapshot or {}) do
        if witness.kind == kind then
            return witness
        end
    end
    return nil
end

-- D0/D3: executing ☱ creates an assessment; committing △ still creates no output.
local pending_packet, pending_result = assert(fixture.run(
    "delivery-pending", "work_sequence", {"inspect", "change", "verify"}, 4
))
assert_eq(fixture.walk(pending_result), "☴☵☴☱", "delivery boundary trace")
assert_eq(#fixture.events(pending_packet, "plan_completion_assessment"), 1,
    "runtime review creates one assessment")
assert_true(pending_packet.manifest == nil, "route to manifest creates no manifest")
assert_true(pending_packet.death == nil, "route to manifest creates no death")
assert_eq(pending_packet.operator, "△", "committed delivery arrives at manifest")
local delivery_route = assert(fixture.last_route_to(pending_result, "△"),
    "delivery route required")
local delivery_plan = delivery_route.selected_candidate.action_plan
assert_eq(delivery_plan.mode, "plan_delivery", "terminal action is typed")

-- D1: any relevant post-assessment mutation invalidates the old assessment.
local stale_packet = pending_packet
local stale_input = delivery_plan.options.manifest.plan_input
stale_packet.revisions.constraints = stale_packet.revisions.constraints + 1
local stale_assessment, stale_err = plan_completion.resolve_assessment(
    stale_packet,
    stale_input
)
assert_true(not stale_assessment
    and tostring(stale_err):find("stale", 1, true) ~= nil,
    "assessment cannot survive a relevant revision")
local stale_snapshot = assert(qualified_pressure.plan_witnesses(stale_packet, {
    current_operator = "☱",
}))
assert_true(find_witness(stale_snapshot, "plan_delivery_need") == nil,
    "stale assessment creates no delivery witness")

-- D2/A2: qualified MANIFEST reads Packet state, not runner result text or ticks.
local projection_packet, projection_result = assert(fixture.run(
    "delivery-projection", "work_sequence", {"inspect", "change"}, 4
))
local projection_route = assert(fixture.last_route_to(projection_result, "△"))
local projection_plan = projection_route.selected_candidate.action_plan
local _, override_err = pressure_action.registry_context(projection_plan, {
    instance = projection_packet,
    options = {manifest = {plan_input = {assessment_id = "forged"}}},
})
assert_eq(override_err, "caller options override action-owned scope",
    "caller cannot replace manifest scope")
local context_a = assert(pressure_action.registry_context(projection_plan, {
    instance = projection_packet,
    options = {work_mode = "plan"},
    result = {ticks = {{operator = "☴", payload = {response = {text = "forged A"}}}}},
}))
local context_b = assert(pressure_action.registry_context(projection_plan, {
    instance = projection_packet,
    options = {work_mode = "plan"},
    result = {ticks = {{operator = "☴", payload = {response = {text = "forged B"}}}}},
}))
assert(packet.begin_tick(projection_packet, "△", {}))
local execution_a = assert(registry.execute("△", projection_packet, context_a))
local execution_b = assert(registry.execute("△", projection_packet, context_b))
assert_eq(execution_a.status, "applied", "first projection applies")
assert_eq(execution_b.status, "applied", "second projection applies")
assert_eq(json.encode(execution_a.payload), json.encode(execution_b.payload),
    "runner result injection cannot change qualified output")
assert_true(not execution_a.payload.output.text:find("forged", 1, true),
    "runner text does not leak into plan")
assert_true(pressure_action.verify_effect(
    projection_plan,
    execution_a.payload,
    projection_packet
), "Packet-local delivery effect resolves")

-- D4: a grown life seals the projected plan and dies complete.
local delivered_packet, delivered_result = assert(fixture.run(
    "delivery-complete", "work_sequence", {"inspect", "change", "verify"}, 5
))
assert_eq(fixture.walk(delivered_result), "☴☵☴☱△", "complete delivery trace")
assert_eq(delivered_result.stop_reason, "manifested", "life manifests")
assert_eq(delivered_packet.status, "dead", "manifested Packet is a corpse")
assert_eq(delivered_packet.death.cause, "complete", "delivery death is complete")
assert_eq(delivered_packet.manifest.mode, "plan_delivery", "manifest mode is exact")
assert_eq(delivered_packet.manifest.output.type, "plan", "output type is plan")
assert_eq(delivered_packet.manifest.output.status, "complete", "output is complete")
assert_eq(delivered_packet.manifest.output.structured.protocol_version,
    "plan.result.v0", "structured plan protocol is explicit")
assert_eq(#delivered_packet.manifest.output.structured.items, 3,
    "all sequence items are delivered")
assert_eq(delivered_packet.manifest.truth_status, "runtime_confirmed",
    "body assembly is runtime truth")
assert_eq(delivered_packet.manifest.content_truth_status, "semantic_proposal",
    "plan content remains semantic proposal")
assert_eq(delivered_packet.manifest.assembly.input_provenance, "packet_state",
    "qualified delivery names Packet provenance")
assert_eq(delivered_packet.residue.cause, "complete", "corpse retains completion")

print("test_plan_delivery ok")
