package.path = "./?.lua;./?/init.lua;" .. package.path

local digest = require("core.digest")
local dissolve = require("organs.dissolve")
local pressure_action = require("runtime.pressure_action")
local pressure_composition = require("runtime.pressure_composition")
local qualified_pressure = require("runtime.qualified_pressure")
local fixture = require("tests.support.qa_hand")

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function witnesses(snapshot, predicate)
    local result = {}
    for _, witness in ipairs(snapshot.witnesses or {}) do
        if predicate(witness) then
            result[#result + 1] = witness
        end
    end
    return result
end

local grown = assert(fixture.grow_qa_descendant())
local instance = grown.descendant
local before_state = assert(digest.record(instance))
local before = assert(qualified_pressure.derive(instance, {
    operator = "▽",
}, {
    current_operator = "▽",
    router_mode = "tree",
    pressure_policy = "qualified_need_v0",
}))
local release_witnesses = witnesses(before, function(witness)
    return witness.kind == "inherited_rejected_form_release_need"
end)
assert_eq(#release_witnesses, 1,
    "controlled pre-release state must expose one release witness")
local release_witness = release_witnesses[1]

local decision = assert(pressure_composition.predict(instance, before, {
    options = {work_mode = "build"},
}))
assert_eq(decision.kind, "tree_route_decision")
assert_eq(decision.to, "☷")
assert_eq(decision.selected_candidate.witness_count, 1)
assert_eq(decision.selected_candidate.witnesses[1].witness_id,
    release_witness.witness_id)
assert_eq(decision.selected_candidate.action_plan.plan_id,
    release_witness.action_plan.plan_id)
assert_eq(assert(digest.record(instance)), before_state,
    "pressure selection changed Packet state")

fixture.move_to(instance, "☷")
local arrival_only = assert(qualified_pressure.derive(instance, {
    operator = "☷",
}, {
    current_operator = "☷",
    router_mode = "tree",
    pressure_policy = "qualified_need_v0",
}))
assert_eq(#witnesses(arrival_only, function(witness)
    return witness.witness_id == release_witness.witness_id
end), 0, "topology alone must hide the ☷ self-target before release")
local coordinate_control = assert(qualified_pressure.derive(instance, {
    operator = "▽",
}, {
    current_operator = "▽",
    router_mode = "tree",
    pressure_policy = "qualified_need_v0",
}))
local coordinate_control_release = witnesses(coordinate_control, function(witness)
    return witness.kind == "inherited_rejected_form_release_need"
end)
assert_eq(#coordinate_control_release, 1,
    "same-coordinate control lost the release witness before the effect")
assert_eq(coordinate_control_release[1].witness_id,
    release_witness.witness_id)

local effect_context = assert(pressure_action.registry_context(
    release_witness.action_plan,
    {instance = instance, options = {work_mode = "build"}}
))
local _, effect = assert(dissolve.run(
    instance,
    effect_context.options.dissolve
))
assert(pressure_action.verify_effect(
    release_witness.action_plan,
    effect,
    instance
))

local after_effect_state = assert(digest.record(instance))
local same_coordinate_after = assert(qualified_pressure.derive(instance, {
    operator = "▽",
}, {
    current_operator = "▽",
    router_mode = "tree",
    pressure_policy = "qualified_need_v0",
}))
local successor_after = assert(qualified_pressure.derive(instance, {
    operator = "☷",
}, {
    current_operator = "☷",
    router_mode = "tree",
    pressure_policy = "qualified_need_v0",
}))
assert_eq(assert(digest.record(instance)), after_effect_state,
    "post-release pressure derivation changed Packet state")

local selected_after = witnesses(same_coordinate_after, function(witness)
    return witness.witness_id == release_witness.witness_id
end)
local release_kind_after = witnesses(same_coordinate_after, function(witness)
    return witness.kind == "inherited_rejected_form_release_need"
end)
local successors = witnesses(successor_after, function(witness)
    return witness.kind == "upper_observation_need"
        and witness.target_operator == "☴"
end)

assert_eq(#selected_after, 0,
    "the exact pressure that selected DISSOLVE survived its effect")
assert_eq(#release_kind_after, 0,
    "released inherited form still requests DISSOLVE")
assert_eq(#successors, 1,
    "release must expose one bounded post-release OBSERVE obligation")
assert(successors[1].witness_id ~= release_witness.witness_id,
    "successor obligation reused the discharged causal identity")
assert_eq(successors[1].source_domain,
    "upper_observation:material+semantic")

-- This is the observed v0 result, not a general scalar formula. The selected
-- causal obligation is discharged even though another obligation replaces it.
local observation = {
    exact_selected_witnesses_before = #release_witnesses,
    exact_selected_witnesses_after = #selected_after,
    discharged_selected_witnesses = #release_witnesses - #selected_after,
    successor_witnesses = #successors,
    aggregate_witnesses_before = #(before.witnesses or {}),
    aggregate_witnesses_after = #(same_coordinate_after.witnesses or {}),
}
assert_eq(observation.discharged_selected_witnesses, 1)
assert_eq(observation.aggregate_witnesses_before, 1)
assert_eq(observation.aggregate_witnesses_after, 1)
assert_eq(observation.aggregate_witnesses_after
    - observation.aggregate_witnesses_before, 0,
    "controlled sample no longer demonstrates scalar-count ambiguity")

print("test_dissolve_pressure_relief ok")
