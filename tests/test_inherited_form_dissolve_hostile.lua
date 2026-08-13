package.path = "./?.lua;./?/init.lua;" .. package.path

local digest = require("core.digest")
local dissolve_schema = require("core.dissolve_schema")
local packet_core = require("core.packet")
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

local function prepared()
    local observed = assert(fixture.grow_qa_descendant())
    local instance = observed.descendant
    local witnesses = assert(qualified_pressure.inherited_form_witnesses(
        instance,
        {current_operator = "▽"},
        {router_mode = "tree"}
    ))
    local plan = assert(witnesses[1]).action_plan
    fixture.move_to(instance, "☷")
    local context = assert(pressure_action.registry_context(plan, {
        instance = instance,
        options = {work_mode = "build"},
    }))
    return observed, instance, plan, context.options.dissolve
end

do
    local _, instance, plan, options = prepared()
    local before = assert(digest.record(instance))
    local foreign = fixture.copy(options)
    foreign.reason.carrier_id = "carrier:foreign"
    local readiness, err = dissolve.readiness(instance, foreign)
    assert(readiness == nil)
    assert(tostring(err):find("contradicts NETWORK projection", 1, true))
    assert_eq(assert(digest.record(instance)), before)

    local forged = packet_core.append_trace(instance, {
        type = "unit_dissolution",
        operator = "☷",
        truth_status = "runtime_confirmed",
        payload = {
            protocol_version = dissolve_schema.release_protocol,
        },
        cost = {},
    })
    assert(forged == nil)
    assert_eq(assert(digest.record(instance)), before)

    local bad_scope = fixture.copy(options)
    bad_scope.qualified_action.scope_refs[1] = "coverage:field_unit:unit:99:1"
    local result = dissolve.readiness(instance, bad_scope)
    assert(result == nil)
    assert_eq(assert(digest.record(instance)), before)

    local stale = fixture.copy(plan)
    stale.preconditions.planned_residue_unit_id = "unit:99"
    stale.plan_id = "forged"
    assert(not pressure_action.validate(stale))
end

do
    local _, instance, _, options = prepared()
    assert(dissolve.run(instance, options))
    local aftermath = assert(qualified_pressure.upper_witnesses(
        instance,
        {current_operator = "☷"},
        {router_mode = "tree"}
    ))
    local observe_plan = assert(aftermath[1]).action_plan
    fixture.move_to(instance, "☴")
    local context = assert(pressure_action.registry_context(observe_plan, {
        instance = instance,
        options = {work_mode = "build"},
    }))
    local before = assert(digest.record(instance))
    local no_policy = fixture.copy(context.options.observe)
    no_policy.presentation_policy = nil
    local readiness, readiness_err = observe.readiness(instance, no_policy)
    assert(readiness == nil)
    assert(tostring(readiness_err):find("requires presentation policy", 1, true))
    assert_eq(assert(digest.record(instance)), before)

    local partial = fixture.copy(context.options.observe)
    local removed = table.remove(partial.unit_ids)
    partial.unit_versions[removed] = nil
    local partial_ready, partial_err = observe.readiness(instance, partial)
    assert(partial_ready == nil)
    assert(tostring(partial_err):find("three exact units", 1, true))
    assert_eq(assert(digest.record(instance)), before)

    local overridden = fixture.copy(context.options.observe)
    overridden.prompt_payload = "forged prompt"
    local calls = 0
    local result, err = observe.run(instance, {
        ask = function()
            calls = calls + 1
            return {text = "forbidden"}
        end,
    }, overridden)
    assert(result == nil)
    assert_eq(err, "presentation policy forbids caller prompt override")
    assert_eq(calls, 0)
    assert_eq(assert(digest.record(instance)), before)
end

do
    local _, instance, _, options = prepared()
    local before = assert(digest.record(instance))
    local original = field.commit_inherited_form_release
    field.commit_inherited_form_release = function()
        return nil, "injected field commit failure"
    end
    local called, result, err = pcall(dissolve.run, instance, options)
    field.commit_inherited_form_release = original
    assert(called)
    assert(result == nil)
    assert(tostring(err):find("injected field commit failure", 1, true))
    assert_eq(assert(digest.record(instance)), before,
        "failed field commit did not roll back trace and field")
end

do
    local _, instance, _, options = prepared()
    local before = assert(digest.record(instance))
    local original = dissolve_schema.normalize_residue_carrier
    dissolve_schema.normalize_residue_carrier = function()
        return nil, "injected residue rejection"
    end
    local called, result, err = pcall(dissolve.run, instance, options)
    dissolve_schema.normalize_residue_carrier = original
    assert(called)
    assert(result == nil)
    assert_eq(err, "injected residue rejection")
    assert_eq(assert(digest.record(instance)), before,
        "rejected residue changed Packet before transaction")
end

do
    local _, instance, _, options = prepared()
    assert(packet_core.begin_terminal(instance, {
        kind = "internal_death",
        cause = "cancelled",
        operator = "☷",
    }))
    assert(packet_core.freeze(instance, "cancelled", {cause = "cancelled"}))
    local before = assert(digest.record(instance))
    local readiness = assert(dissolve.readiness(instance, options))
    assert_eq(readiness.ready, false)
    assert_eq(readiness.reason, "packet_terminal")
    local result = dissolve.run(instance, options)
    assert(result == nil)
    assert_eq(assert(digest.record(instance)), before)
end

print("test_inherited_form_dissolve_hostile ok")
