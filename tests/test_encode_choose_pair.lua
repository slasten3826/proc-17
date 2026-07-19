package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")
local packet = require("core.packet")
local flow_domain = require("runtime.flow_domain")
local packet_birth = require("runtime.packet_birth")
local pressure_action = require("runtime.pressure_action")
local qualified_pressure = require("runtime.qualified_pressure")
local registry = require("runtime.operator_registry")
local router = require("runtime.router")
local tension_runner = require("runtime.tension_runner")
local flow = require("organs.flow")
local observe = require("organs.observe")

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

local function proposal(shape, values)
    local items = {}
    for index, value in ipairs(values) do
        items[index] = {
            key = "item-" .. tostring(index),
            kind = "work_item",
            value = value,
            source_keys = {},
        }
    end
    local result = {
        protocol_version = "packet.structure.proposal.v0",
        receiver_contract_id = "calm.work_structure.v0",
        shape = shape,
        items = items,
        edges = {},
    }
    if shape == "alternative_set" then
        result.choice = {kind = "mutually_exclusive"}
    end
    return result
end

local function substrate_for(envelope)
    return {
        ask = function()
            return {text = json.encode(envelope)}
        end,
    }
end

local fixture_counter = 0
local function next_domain(label)
    fixture_counter = fixture_counter + 1
    local id = label .. "-" .. tostring(fixture_counter)
    return assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = id,
        source_ref = "fixture:" .. id,
    }))
end

local function tree_options(label, max_ticks, overrides)
    local options = {
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        ablate_relation_consumer = true,
        work_mode = "plan",
        max_ticks = max_ticks,
        legacy_shadow = false,
        packet_life = {
            protocol_version = "vertical_packet_life.v0",
            flow_domain = next_domain(label),
            projection_adapter = "vertical_single.v0",
        },
    }
    for key, value in pairs(overrides or {}) do
        options[key] = value
    end
    return options
end

local function run_tree(label, shape, values, max_ticks, overrides)
    return tension_runner.run(
        label,
        substrate_for(proposal(shape, values)),
        tree_options(label, max_ticks, overrides)
    )
end

local function operator_list(result)
    local operators = {}
    for _, tick in ipairs(result.ticks or {}) do
        operators[#operators + 1] = tick.operator
    end
    return operators
end

local function route_text(result)
    local routes = {}
    for _, route in ipairs(result.routes or {}) do
        routes[#routes + 1] = tostring(route.from) .. tostring(route.to)
    end
    return table.concat(routes, "|")
end

local function route_to(result, target)
    for _, route in ipairs(result.routes or {}) do
        if route.to == target then
            return route
        end
    end
    return nil
end

local function assert_prefix(result, expected, message)
    local actual = operator_list(result)
    for index, operator in ipairs(expected) do
        assert_eq(actual[index], operator,
            (message or "operator prefix") .. " tick " .. tostring(index))
    end
end

-- P0: a sequence is structured but never becomes a choice set.
local sequence_packet, sequence_result = assert(run_tree(
    "pair-sequence",
    "work_sequence",
    {"inspect", "change", "verify"},
    5
))
assert_prefix(sequence_result, {"☴", "☵", "☴"}, "sequence treatment")
for _, operator in ipairs(operator_list(sequence_result)) do
    assert_true(operator ~= "☳", "work sequence cannot invoke qualified CHOOSE")
end
assert_eq(#(sequence_packet.boundary.choices or {}), 0,
    "work sequence creates no boundary choice")

-- P1: the complete pair route is generated from dependencies, not a rail.
local pair_packet, pair_result = assert(run_tree(
    "pair-alternatives",
    "alternative_set",
    {"retain", "replace"},
    7
))
assert_prefix(pair_result, {"☴", "☵", "☴", "☳", "☴", "☱", "△"},
    "alternative treatment")
assert_eq(#(pair_packet.boundary.choices or {}), 1,
    "exact pair records one real boundary choice")
local choice_tick = pair_result.ticks[4]
assert_eq(choice_tick.payload.mode, "alternative_collapse",
    "pair executes production CHOOSE mode")
local choice_route = assert(route_to(pair_result, "☳"),
    "pair route must commit CHOOSE")
assert_eq(choice_route.authority, "tree", "pair route belongs to tree authority")
assert_eq(choice_route.selected_candidate.action_plan.mode, "alternative_collapse",
    "committed route seals the exact choice action")
assert_eq(choice_route.selected_action_plan_id,
    choice_route.selected_candidate.action_plan.plan_id,
    "committed choice action identity is stable")
assert_eq(
    json.encode(choice_route.selected_candidate.action_plan.scope_refs),
    json.encode(choice_tick.payload.effect_scope_refs),
    "choice effect consumes the committed exact scope"
)
assert_true(pair_packet.tension.loss >= 0.9,
    "pair life pays structure and choice identity loss")
assert_eq(pair_result.stop_reason, "manifested",
    "post-collapse plan reaches body-owned delivery")
assert_eq(pair_packet.manifest.mode, "plan_delivery",
    "post-collapse terminal is the exact plan delivery mode")

-- P2: removing only the choice consumer leaves formation and sight intact.
local no_choice_packet, no_choice_result = assert(run_tree(
    "pair-choice-ablated",
    "alternative_set",
    {"retain", "replace"},
    5,
    {ablate_choice_consumer = true}
))
assert_prefix(no_choice_result, {"☴", "☵", "☴"},
    "choice-consumer ablation")
for _, operator in ipairs(operator_list(no_choice_result)) do
    assert_true(operator ~= "☳", "choice ablation removes only CHOOSE execution")
end
assert_eq(#(no_choice_packet.boundary.choices or {}), 0,
    "choice ablation cannot create a choice event")

-- P3: removing the structure receiver prevents both downstream organs.
local no_structure_packet, no_structure_result = assert(run_tree(
    "pair-structure-ablated",
    "alternative_set",
    {"retain", "replace"},
    4,
    {ablate_structure_consumer = true}
))
assert_prefix(no_structure_result, {"☴"}, "structure-consumer ablation")
for _, operator in ipairs(operator_list(no_structure_result)) do
    assert_true(operator ~= "☵" and operator ~= "☳",
        "structure ablation removes ENCODE and downstream CHOOSE")
end
assert_eq(#(no_structure_packet.boundary.choices or {}), 0,
    "missing form cannot create downstream choice")

-- C13: committing a route to ☳ is not itself a choice or choice loss.
local routed_packet, routed_result = assert(run_tree(
    "pair-route-only",
    "alternative_set",
    {"retain", "replace"},
    3
))
assert_prefix(routed_result, {"☴", "☵", "☴"}, "route-only treatment")
assert_true(route_to(routed_result, "☳") ~= nil,
    "tick ceiling is reached after the body commits the CHOOSE edge")
assert_eq(#(routed_packet.boundary.choices or {}), 0,
    "route selection cannot write a boundary choice")
for _, event in ipairs(routed_packet.tension.loss_events or {}) do
    assert_true(event.operator ~= "☳", "route selection cannot create CHOOSE loss")
end

-- P4a: exact ENCODE pressure is observable but massless under shadow authority.
local function shadow_pair_life(label, ablate)
    local instance, result = assert(tension_runner.run(
        label,
        substrate_for(proposal("alternative_set", {"retain", "replace"})),
        {
            router_mode = "shadow",
            pressure_policy = "qualified_need_v0",
            ablate_relation_consumer = true,
            ablate_structure_consumer = ablate,
            ablate_choice_consumer = ablate,
            work_mode = "plan",
            max_ticks = 6,
        }
    ))
    return instance, result
end

local shadow_active, shadow_active_result = shadow_pair_life(
    "pair-shadow-active",
    false
)
local shadow_ablated, shadow_ablated_result = shadow_pair_life(
    "pair-shadow-ablated",
    true
)
assert_eq(route_text(shadow_active_result), route_text(shadow_ablated_result),
    "qualified pair cannot alter legacy live routes")
assert_eq(shadow_active.runtime.budget.spent.steps,
    shadow_ablated.runtime.budget.spent.steps,
    "qualified pair cannot alter shadow step economy")
assert_eq(shadow_active.runtime.budget.spent.substrate_calls,
    shadow_ablated.runtime.budget.spent.substrate_calls,
    "qualified pair cannot alter shadow substrate economy")
assert_eq(shadow_active.tension.loss, shadow_ablated.tension.loss,
    "qualified pair cannot alter shadow identity loss")
assert_eq(json.encode(shadow_active.revisions), json.encode(shadow_ablated.revisions),
    "qualified pair cannot move shadow body revisions")
assert_eq(shadow_active_result.stop_reason, shadow_ablated_result.stop_reason,
    "qualified pair cannot alter shadow terminal outcome")
assert_eq(shadow_active_result.shadow_routes[1].predicted_to, "☵",
    "active shadow actually observes exact ENCODE pressure")
assert_true(shadow_ablated_result.shadow_routes[1].predicted_to == nil,
    "paired ablation removes that prediction without touching live physics")

-- Build an exact choice-ready state to make the CHOOSE shadow ablation non-vacuous.
local function choice_ready_state(label)
    local instance = assert(packet_birth.create(
        next_domain(label),
        "form an exact choice set",
        {projection_adapter = "vertical_single.v0"}
    ))
    assert(flow.run(instance))
    assert(packet.commit_transition(instance, {
        from = "▽", to = "☴", reason = "pair_semantic_sight",
        authority = "harness_override",
    }))
    assert(packet.begin_tick(instance, "☴", {}))
    assert(observe.run(
        instance,
        substrate_for(proposal("alternative_set", {"retain", "replace"})),
        {work_mode = "plan"}
    ))
    local structure = assert(qualified_pressure.structure_witnesses(instance, {
        current_operator = "☴",
    }))
    local structure_witness = assert(structure[1], "structure witness required")
    local context = assert(pressure_action.registry_context(
        structure_witness.action_plan,
        {instance = instance, options = {work_mode = "plan"}}
    ))
    assert(packet.commit_transition(instance, {
        from = "☴", to = "☵", reason = "pair_structure_formation",
        authority = "harness_override",
    }))
    assert(packet.begin_tick(instance, "☵", {}))
    local formed = assert(registry.execute("☵", instance, context))
    assert_eq(formed.status, "applied", "exact structure fixture applies")
    assert(packet.commit_transition(instance, {
        from = "☵", to = "☴", reason = "pair_material_sight",
        authority = "harness_override",
    }))
    assert(packet.begin_tick(instance, "☴", {}))
    local _, observed = assert(observe.run(instance, nil, {
        sensor = "field_native",
        unit_ids = formed.payload.structure_formation.formed_unit_ids,
    }))
    return instance, observed
end

local function shadow_choice_decision(label, ablate)
    local instance, observed = choice_ready_state(label)
    local route = assert(router.after_tick(instance, {
        operator = "☴",
        payload = observed,
        work_mode = "plan",
    }, {
        mode = "shadow",
        options = {
            pressure_policy = "qualified_need_v0",
            ablate_relation_consumer = true,
            ablate_choice_consumer = ablate,
        },
    }))
    return instance, route
end

local choice_shadow_active, active_decision = shadow_choice_decision(
    "choice-shadow-active",
    false
)
local choice_shadow_ablated, ablated_decision = shadow_choice_decision(
    "choice-shadow-ablated",
    true
)
assert_eq(active_decision.to, "☳", "legacy live route remains CHOOSE")
assert_eq(ablated_decision.to, "☳", "ablation cannot alter legacy live route")
assert_eq(active_decision.shadow.predicted_to, "☳",
    "active shadow observes the exact choice need")
assert_true(ablated_decision.shadow.predicted_to == nil,
    "choice ablation removes the shadow prediction")
assert_eq(json.encode(choice_shadow_active.runtime.budget or {}),
    json.encode(choice_shadow_ablated.runtime.budget or {}),
    "choice shadow observation cannot charge budget")
assert_eq(choice_shadow_active.tension.loss, choice_shadow_ablated.tension.loss,
    "choice shadow observation cannot charge identity")
assert_eq(json.encode(choice_shadow_active.revisions),
    json.encode(choice_shadow_ablated.revisions),
    "choice shadow observation cannot move revisions")
assert_eq(#(choice_shadow_active.boundary.choices or {}), 0,
    "observing choice pressure cannot execute it")

-- P8: semantic-text CHOOSE remains a legacy compatibility behavior.
local compatibility_substrate = {
    ask = function()
        return {text = "first semantic line\nsecond semantic line"}
    end,
}
local compatibility_packet, compatibility_result = assert(tension_runner.run(
    "compatibility semantic choice",
    compatibility_substrate,
    {
        router_mode = "shadow",
        pressure_policy = "qualified_need_v0",
        work_mode = "plan",
        max_ticks = 4,
    }
))
assert_prefix(compatibility_result, {"☴", "☵", "☴", "☳"},
    "compatibility route")
local compatibility_tick = compatibility_result.ticks[4]
assert_true(compatibility_tick.payload.mode ~= "alternative_collapse",
    "legacy semantic choice cannot impersonate exact collapse")
assert_true(compatibility_tick.payload.choice_set_ref == nil,
    "legacy semantic choice has no exact formation referent")
local compatibility_route = assert(route_to(compatibility_result, "☳"))
assert_eq(compatibility_route.authority, "legacy_control",
    "compatibility CHOOSE remains under legacy authority")
assert_true(compatibility_route.selected_action_plan_id == nil,
    "compatibility route cannot count as qualified action evidence")
assert_eq(#(compatibility_packet.boundary.choices or {}), 1,
    "compatibility behavior remains callable")

-- P9: a target that executes but returns the wrong effect scope is a loud harness error.
local descriptor = assert(registry.get("☳"))
local original_run = descriptor.run
descriptor.run = function(instance, context)
    local payload, payload_err = original_run(instance, context)
    if payload and payload.mode == "alternative_collapse" then
        payload.effect_scope_refs = {"coverage:field_unit:forged:1"}
    end
    return payload, payload_err
end
local call_ok, malformed_instance, malformed_err = pcall(function()
    return run_tree(
        "pair-malformed-effect",
        "alternative_set",
        {"retain", "replace"},
        4
    )
end)
descriptor.run = original_run
assert_true(call_ok, "typed invariant rejection need not throw Lua")
assert_true(malformed_instance == nil,
    "malformed qualified effect cannot become a Packet result")
assert_true(tostring(malformed_err):find(
    "pressure action effect scope mismatch",
    1,
    true
) ~= nil, "malformed effect preserves its invariant diagnostic")

print("test_encode_choose_pair ok")
