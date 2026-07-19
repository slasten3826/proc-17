package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local flow = require("organs.flow")
local pressure_action = require("runtime.pressure_action")

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

local instance = packet.new("action plan")
local _, flowed = assert(flow.run(instance))
local unit_id = flowed.unit_id
local scope_ref = "coverage:field_unit:" .. unit_id .. ":1"

local function field_plan(id, witness)
    return assert(pressure_action.build("field_native_observe", {
        witness_id = witness,
        scope_refs = {"coverage:field_unit:" .. id .. ":1"},
        provenance_refs = {"event:fixture:" .. id},
        preconditions = {
            packet_id = instance.id,
            generation = instance.generation,
            object_versions = {[id] = 1},
            relevant_revisions = {potential = instance.revisions.potential},
        },
        options = {observe = {
            sensor = "field_native",
            unit_ids = {id},
            unit_versions = {[id] = 1},
        }},
        expected_effect = {
            discharge_reader = "upper_observation_need",
        },
        content_truth_status = "semantic_proposal",
    }))
end

local plan = field_plan(unit_id, "witness:field:1")
assert_true(pressure_action.validate(plan), "canonical action validates")
local reordered = assert(pressure_action.build("field_native_observe", {
    witness_id = "witness:field:1",
    scope_refs = {scope_ref},
    provenance_refs = {"event:fixture:" .. unit_id},
    preconditions = {
        packet_id = instance.id,
        generation = instance.generation,
        object_versions = {[unit_id] = 1},
        relevant_revisions = {potential = instance.revisions.potential},
    },
    options = {observe = {
        sensor = "field_native",
        unit_ids = {unit_id},
        unit_versions = {[unit_id] = 1},
    }},
    expected_effect = {discharge_reader = "upper_observation_need"},
    content_truth_status = "semantic_proposal",
}))
assert_true(pressure_action.same(plan, reordered), "same fact yields same plan identity")

local forged = {}
for key, value in pairs(plan) do forged[key] = value end
forged.plan_id = "forged"
assert_true(not pressure_action.validate(forged), "forged identity is rejected")

local unknown, unknown_err = pressure_action.build("field_native_observe", {
    witness_id = "witness:bad",
    scope_refs = {scope_ref},
    preconditions = {
        packet_id = instance.id,
        generation = instance.generation,
        object_versions = {[unit_id] = 1},
    },
    options = {observe = {
        sensor = "field_native",
        unit_ids = {unit_id},
        unit_versions = {[unit_id] = 1},
        tool = "forbidden",
    }},
    expected_effect = {discharge_reader = "upper_observation_need"},
})
assert_true(not unknown, "unknown action options are rejected")
assert_true(tostring(unknown_err):find("unknown key", 1, true) ~= nil,
    "unknown option error is explicit")

local second = packet.new("action merge")
local _, second_flow = assert(flow.run(second))
assert(packet.commit_transition(second, {
    from = "▽", to = "☴", reason = "action_merge_unit",
}))
assert(packet.begin_tick(second, "☴", {}))
local _, event = assert(packet.append_chaos(second, {
    operator = "☴", kind = "action_merge", truth_status = "semantic_proposal",
}))
local second_unit = assert(require("runtime.field").add_unit(second, "☴", {
    kind = "fixture",
    carrier = "two",
    source_refs = {second_flow.unit_id},
    created_event_id = event.id,
    content_truth_status = "semantic_proposal",
}))

local function second_plan(id, witness)
    return assert(pressure_action.build("field_native_observe", {
        witness_id = witness,
        scope_refs = {"coverage:field_unit:" .. id .. ":1"},
        provenance_refs = {"event:" .. id},
        preconditions = {
            packet_id = second.id,
            generation = second.generation,
            object_versions = {[id] = 1},
            relevant_revisions = {potential = second.revisions.potential},
        },
        options = {observe = {
            sensor = "field_native",
            unit_ids = {id},
            unit_versions = {[id] = 1},
        }},
        expected_effect = {discharge_reader = "upper_observation_need"},
    }))
end

local merged = assert(pressure_action.merge(
    second_plan(second_flow.unit_id, "witness:merge:1"),
    second_plan(second_unit.id, "witness:merge:2")
))
assert_eq(#merged.options.observe.unit_ids, 2, "compatible scopes merge")
assert_eq(#merged.scope_refs, 2, "merged effect keeps exact union")

local semantic = assert(pressure_action.build("semantic_observe", {
    witness_id = "witness:semantic",
    scope_refs = {scope_ref},
    provenance_refs = {"event:semantic"},
    preconditions = {
        packet_id = instance.id,
        generation = instance.generation,
        object_versions = {[unit_id] = 1},
    },
    options = {observe = {
        sensor = "semantic",
        unit_ids = {unit_id},
        unit_versions = {[unit_id] = 1},
    }},
    expected_effect = {discharge_reader = "upper_observation_need"},
}))
local incompatible, incompatible_err = pressure_action.merge(plan, semantic)
assert_true(not incompatible, "cross-mode OBSERVE plans do not merge")
assert_eq(incompatible_err, "ambiguous_action", "incompatible mode is typed")

local context = assert(pressure_action.registry_context(plan, {
    instance = instance,
    options = {work_mode = "build"},
}))
assert_eq(context.options.observe.sensor, "field_native", "action owns registry sensor")
assert_eq(context.options.observe.unit_ids[1], unit_id, "action owns registry scope")
local overridden, override_err = pressure_action.registry_context(plan, {
    instance = instance,
    options = {observe = {sensor = "semantic"}},
})
assert_true(not overridden, "caller cannot override action scope")
assert_eq(override_err, "caller options override action-owned scope", "override is loud")

assert_true(pressure_action.verify_readiness(plan, {
    operator = "☴", ready = true, source_refs = {scope_ref},
}), "readiness exact scope verifies")
assert_true(pressure_action.verify_effect(plan, {
    kind = "observe_organ_payload", effect_scope_refs = {scope_ref},
}), "effect exact scope verifies")
assert_true(not pressure_action.verify_effect(plan, {
    kind = "observe_organ_payload", effect_scope_refs = {"coverage:field_unit:other:1"},
}), "wrong effect scope is rejected")

print("test_pressure_action ok")
