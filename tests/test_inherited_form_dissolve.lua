package.path = "./?.lua;./?/init.lua;" .. package.path

local digest = require("core.digest")
local json = require("core.json")
local packet_core = require("core.packet")
local flow = require("organs.flow")
local dissolve = require("organs.dissolve")
local observe = require("organs.observe")
local field = require("runtime.field")
local pressure_action = require("runtime.pressure_action")
local qualified_pressure = require("runtime.qualified_pressure")
local fixture = require("tests.support.qa_hand")

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function find_unit(instance, kind)
    local found
    for _, id in ipairs(instance.field.unit_order or {}) do
        local unit = instance.field.units[id]
        if unit and unit.kind == kind then
            assert(found == nil, "duplicate " .. kind)
            found = unit
        end
    end
    return found
end

local function find_witness(values, kind)
    for _, value in ipairs(values or {}) do
        if value.kind == kind then return value end
    end
    return nil
end

local function count_plain(text, needle)
    local count, cursor = 0, 1
    while true do
        local first, last = text:find(needle, cursor, true)
        if not first then return count end
        count = count + 1
        cursor = last + 1
    end
end

local observed = assert(fixture.grow_qa_descendant())
local instance = observed.descendant
local projection = instance.ingress.network_projection
local current = assert(find_unit(instance, "network_current_work"))
local inherited = assert(find_unit(instance, "inherited_rejected_form"))
local before = assert(digest.record(instance))

local witnesses, diagnostics = assert(qualified_pressure.inherited_form_witnesses(
    instance,
    {current_operator = "▽"},
    {router_mode = "tree"}
))
assert_eq(#witnesses, 1)
assert_eq(#diagnostics, 0)
local witness = witnesses[1]
assert_eq(witness.kind, "inherited_rejected_form_release_need")
assert_eq(witness.target_operator, "☷")
assert_eq(witness.causal_class, "blocking_demand")
assert_eq(witness.source_domain, "network_inherited_rejected_form")
assert_eq(witness.source_truth_status, "inherited_proposal")
assert_eq(witness.consumer_contract, "dissolve.inherited_rejected_form.v0")

local plan = witness.action_plan
assert(pressure_action.validate(plan))
assert_eq(plan.mode, "inherited_rejected_form_release")
assert_eq(plan.target_operator, "☷")
assert_eq(plan.options.dissolve.target.id, inherited.id)
assert_eq(plan.options.dissolve.target.version, inherited.version)
assert_eq(plan.options.dissolve.reason.network_projection_id,
    projection.projection_id)
assert_eq(plan.preconditions.object_versions[inherited.id], inherited.version)
assert_eq(plan.preconditions.planned_residue_unit_id, "unit:3")
assert_eq(plan.preconditions.relevant_revisions.potential,
    instance.revisions.potential)
assert(pressure_action.verify_preconditions(plan, instance))

local context = assert(pressure_action.registry_context(plan, {
    instance = instance,
    options = {work_mode = "build"},
}))
assert_eq(context.options.dissolve.target.id, inherited.id)
assert_eq(context.options.dissolve.qualified_action.plan_id, plan.plan_id)
local overridden, override_err = pressure_action.registry_context(plan, {
    instance = instance,
    options = {dissolve = {scope = "relation"}},
})
assert(overridden == nil)
assert_eq(override_err, "caller options override action-owned scope")

local upper, upper_diagnostics = assert(qualified_pressure.upper_witnesses(
    instance,
    {current_operator = "▽"},
    {router_mode = "tree"}
))
local current_ref = table.concat({
    "coverage", "field_unit", current.id, tostring(current.version),
}, ":")
for _, upper_witness in ipairs(upper) do
    for _, ref in ipairs(upper_witness.scope_refs or {}) do
        assert(ref ~= current_ref,
            "current work became observable before inherited-form release")
    end
end
assert_eq(#upper_diagnostics, 0,
    "expected inherited-form ordering is not unqualified pressure")

local snapshot = assert(qualified_pressure.derive(instance, {
    operator = "▽",
}, {
    current_operator = "▽",
    router_mode = "tree",
    pressure_policy = "qualified_need_v0",
}))
assert(find_witness(snapshot.witnesses,
    "inherited_rejected_form_release_need"))
assert_eq(assert(digest.record(instance)), before,
    "pressure derivation changed Packet state")

local ablated, ablation_diagnostics = assert(
    qualified_pressure.inherited_form_witnesses(
        instance,
        {current_operator = "▽"},
        {
            router_mode = "tree",
            ablate_inherited_form_consumer = true,
        }
    )
)
assert_eq(#ablated, 0)
assert_eq(ablation_diagnostics[1].consumer_contract,
    "dissolve.inherited_rejected_form.v0")
local no_authority = assert(qualified_pressure.inherited_form_witnesses(
    instance,
    {current_operator = "▽"},
    {router_mode = "shadow"}
))
assert_eq(#no_authority, 0)

local ordinary = packet_core.new("ordinary control")
assert(flow.run(ordinary))
local absent = assert(qualified_pressure.inherited_form_witnesses(
    ordinary,
    {current_operator = "▽"},
    {router_mode = "tree"}
))
assert_eq(#absent, 0)

fixture.move_to(instance, "☷")
local guarded, guarded_err = field.set_activation(
    instance,
    "☷",
    inherited.id,
    "dissolved",
    {event_id = instance.trace[#instance.trace].id}
)
assert(guarded == nil)
assert_eq(guarded_err,
    "inherited rejected form requires atomic release transaction")

local live_context = assert(pressure_action.registry_context(plan, {
    instance = instance,
    options = {work_mode = "build"},
}))
local readiness = assert(dissolve.readiness(
    instance,
    live_context.options.dissolve
))
assert(readiness.ready)
assert_eq(readiness.reason, "inherited_rejected_form_releasable")
assert(pressure_action.verify_readiness(plan, readiness))
local potential_before = instance.revisions.potential
local trace_before = #instance.trace
local _, payload = assert(dissolve.run(
    instance,
    live_context.options.dissolve
))
assert_eq(payload.mode, "inherited_rejected_form_release")
assert_eq(payload.status, "applied")
assert_eq(payload.released_mass.forms, 1)
assert_eq(payload.released_mass.relations, 0)
assert_eq(payload.loss.amount, 0)
assert_eq(payload.loss.irreversible, false)
assert_eq(instance.revisions.potential, potential_before + 1)
assert_eq(#instance.trace, trace_before + 1)
assert_eq(instance.trace[#instance.trace].type, "unit_dissolution")
assert_eq(field.get_unit(instance, inherited.id).activation, "dissolved")
assert_eq(field.get_unit(instance, inherited.id).version,
    plan.options.dissolve.target.version + 1)
local residue = assert(field.get_unit(instance, payload.residue.id))
assert_eq(residue.kind, "rejected_form_residue")
assert_eq(residue.carrier.release_id, payload.dissolution.release_id)
assert_eq(residue.created_event_id, payload.trace_event_id)
assert(pressure_action.verify_effect(plan, payload, instance))

local aftermath = assert(qualified_pressure.upper_witnesses(
    instance,
    {current_operator = "☷"},
    {router_mode = "tree"}
))
assert_eq(#aftermath, 1)
local observe_witness = aftermath[1]
assert_eq(observe_witness.kind, "upper_observation_need")
assert_eq(observe_witness.target_operator, "☴")
assert_eq(observe_witness.action_plan.mode, "semantic_observe")
assert_eq(observe_witness.action_plan.options.observe.presentation_policy,
    "network.rejected_form_after_release.v0")
assert_eq(#observe_witness.action_plan.options.observe.unit_ids, 3)
assert(pressure_action.validate(observe_witness.action_plan))

fixture.move_to(instance, "☴")
local observe_context = assert(pressure_action.registry_context(
    observe_witness.action_plan,
    {instance = instance, options = {work_mode = "build"}}
))
local captured_call
local substrate = {
    ask = function(call)
        captured_call = call
        return {
            text = "bounded post-release observation",
            usage = {prompt_tokens = 1, completion_tokens = 1, total_tokens = 2},
        }
    end,
}
local observe_readiness = assert(observe.readiness(
    instance,
    observe_context.options.observe
))
assert(observe_readiness.ready)
assert(pressure_action.verify_readiness(
    observe_witness.action_plan,
    observe_readiness
))
local _, observed_payload = assert(observe.run(
    instance,
    substrate,
    observe_context.options.observe
))
assert(pressure_action.verify_effect(
    observe_witness.action_plan,
    observed_payload,
    instance
))
assert(captured_call)
local base_prompt = instance.chaos.raw_prompt
local base_count = count_plain(captured_call.prompt_payload, base_prompt)
assert_eq(base_count, 1, "current work must appear exactly once")
assert(captured_call.prompt_payload:find(
    payload.dissolution.release_id,
    1,
    true
))
assert(not captured_call.prompt_payload:find(
    json.encode(projection.rejected_form),
    1,
    true
), "OBSERVE leaked full inherited form")
assert(not captured_call.prompt_payload:find(
    projection.rejected_form.artifact_alignment_id,
    1,
    true
), "OBSERVE leaked inherited artifact alignment")
local observation = assert(instance.boundary.observations.upper[
    #instance.boundary.observations.upper
])
assert_eq(#observation.read_units.entries, 4)
local covered = {}
for _, entry in ipairs(observation.read_units.entries) do
    covered[entry.object_id] = entry.version
end
assert_eq(covered[current.id], current.version)
assert_eq(covered[inherited.id], payload.dissolution.target.after_version)
assert_eq(covered[residue.id], residue.version)
local observed_classes = {}
for _, class in ipairs(observation.observation_classes) do
    observed_classes[class] = true
end
assert(observed_classes.semantic)
assert(observed_classes.material)

local replay_readiness = assert(dissolve.readiness(
    instance,
    live_context.options.dissolve
))
assert_eq(replay_readiness.ready, false)
assert_eq(replay_readiness.reason, "already_released")
local replay_trace = #instance.trace
local replay_revision = instance.revisions.potential
local replay, replay_err = dissolve.run(instance, live_context.options.dissolve)
assert(replay == nil)
assert_eq(replay_err, "already_released")
assert_eq(#instance.trace, replay_trace)
assert_eq(instance.revisions.potential, replay_revision)

local current_plan, stale_err = pressure_action.verify_preconditions(plan, instance)
assert(current_plan == nil)
assert(tostring(stale_err):find("object version", 1, true))

print("test_inherited_form_dissolve ok")
