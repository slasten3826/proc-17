package.path = "./?.lua;./?/init.lua;" .. package.path

local flow_domain = require("runtime.flow_domain")
local tension_runner = require("runtime.tension_runner")
local fake = require("substrates.fake")
local json = require("core.json")

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

local function same_array(left, right)
    local normalized_left = {}
    local normalized_right = {}
    for _, value in ipairs(left or {}) do
        normalized_left[#normalized_left + 1] = value
    end
    for _, value in ipairs(right or {}) do
        normalized_right[#normalized_right + 1] = value
    end
    table.sort(normalized_left)
    table.sort(normalized_right)
    if #normalized_left ~= #normalized_right then
        return false
    end
    for index, value in ipairs(normalized_left) do
        if normalized_right[index] ~= value then
            return false
        end
    end
    return true
end

local function domain(id)
    return assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = id,
        source_ref = "fixture:" .. id,
    }))
end

local function life_options(id, max_ticks)
    return {
        packet_life = {
            protocol_version = "vertical_packet_life.v0",
            flow_domain = domain(id),
            projection_adapter = "vertical_pair.v0",
        },
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        work_mode = "plan",
        max_ticks = max_ticks,
        legacy_shadow = false,
    }
end

local function route_text(result)
    local values = {}
    for _, route in ipairs(result.routes or {}) do
        values[#values + 1] = route.from .. route.to
    end
    return table.concat(values, "|")
end

-- No organ scope is supplied by the harness. The committed route plans drive
-- CONNECT, relation ENCODE and field-native OBSERVE end to end.
local instance, result = assert(tension_runner.run(
    "qualified action carry",
    nil,
    life_options("qualified-carry", 3)
))
assert_eq(#result.ticks, 3, "three body-owned actions execute")
assert_eq(result.ticks[1].operator, "☰", "recognition action reaches CONNECT")
assert_eq(result.ticks[2].operator, "☵", "formation action reaches ENCODE")
assert_eq(result.ticks[3].operator, "☴", "material action reaches OBSERVE")
assert_eq(result.ticks[3].payload.sensor, "field_native",
    "body selects the zero-substrate material sensor")

local qualified_routes = {}
for _, event in ipairs(instance.trace or {}) do
    local payload = event.payload or {}
    if event.type == "route" and payload.selected_action_plan_id ~= nil then
        qualified_routes[#qualified_routes + 1] = payload
    end
end
assert_eq(#qualified_routes, 3, "each selected action is sealed in route evidence")
for index, route in ipairs(qualified_routes) do
    local selected = assert(route.selected_candidate, "route keeps selected candidate")
    local plan = assert(selected.action_plan, "route keeps selected action plan")
    assert_eq(route.selected_action_plan_id, plan.plan_id,
        "route action identity matches sealed plan")
    assert_eq(plan.target_operator, result.ticks[index].operator,
        "route action target matches receiving tick")
    assert_true(same_array(plan.scope_refs, result.ticks[index].payload.effect_scope_refs),
        "effect discharges the exact committed scope")
end

-- With substrate capability present, the higher blocking semantic witness is
-- selected and its exact prompt-unit action is also carried without caller scope.
local semantic, semantic_result = assert(tension_runner.run(
    "qualified semantic carry",
    fake,
    life_options("qualified-semantic", 1)
))
assert_eq(semantic_result.ticks[1].operator, "☴", "blocking semantic sight wins")
assert_eq(semantic_result.ticks[1].payload.sensor, "semantic",
    "semantic action invokes the substrate")
local semantic_route
for _, event in ipairs(semantic.trace or {}) do
    if event.type == "route" and (event.payload or {}).to == "☴" then
        semantic_route = event.payload
        break
    end
end
assert_true(semantic_route ~= nil and semantic_route.selected_action_plan_id ~= nil,
    "semantic route seals its action")
assert_true(same_array(
    semantic_route.selected_candidate.action_plan.scope_refs,
    semantic_result.ticks[1].payload.effect_scope_refs
), "semantic effect matches route scope")

-- An external attempt to replace an action-owned CONNECT scope is a harness
-- error, not an alternate physical route or Packet death.
local overridden_options = life_options("qualified-override", 1)
overridden_options.connect = {unit_ids = {"forged"}}
local overridden, overridden_err = tension_runner.run(
    "qualified override rejected",
    nil,
    overridden_options
)
assert_true(not overridden, "caller action override is rejected")
assert_true(tostring(overridden_err):find(
    "caller options override action-owned scope",
    1,
    true
) ~= nil, "override failure remains loud")

-- Qualified policy is still an observer by default. Swapping only the shadow
-- pressure policy cannot change the live legacy route or Packet economics.
local function shadow_run(policy)
    return tension_runner.run("qualified shadow isolation", fake, {
        work_mode = "plan",
        router_mode = "shadow",
        pressure_policy = policy,
        max_ticks = 6,
        packet_options = {
            budget = {steps = 32, substrate_calls = 8, encode_items = 8, loss = 10},
        },
        choose = {
            limits = {max_selected = 1, max_killed_sample = 8},
        },
    })
end

local binary, binary_result = assert(shadow_run("camera_reconciliation"))
local observed, observed_result = assert(shadow_run("qualified_need_v0"))
assert_eq(route_text(observed_result), route_text(binary_result),
    "qualified shadow cannot change live routes")
assert_eq(observed.runtime.budget.spent.steps, binary.runtime.budget.spent.steps,
    "qualified shadow cannot charge steps")
assert_eq(observed.runtime.budget.spent.substrate_calls,
    binary.runtime.budget.spent.substrate_calls,
    "qualified shadow cannot call substrate")
assert_eq(observed.tension.loss, binary.tension.loss,
    "qualified shadow cannot create identity loss")
assert_eq(json.encode(observed.revisions), json.encode(binary.revisions),
    "qualified shadow cannot move body revisions")
assert_eq(observed_result.edge_stats_errors, nil,
    "qualified candidates remain readable by instrumentation")
for _, shadow in ipairs(observed_result.shadow_routes) do
    assert_eq(shadow.policy, "pressure.class_order.v0",
        "qualified shadow names its actual composition policy")
    assert_true(shadow.prediction_outcome ~= nil,
        "every qualified prediction has a typed outcome")
end
assert_true((observed_result.edge_stats.observers.tree.outcome_counts.selected or 0) > 0,
    "edge statistics name selected qualified outcomes")
assert_true((observed_result.edge_stats.observers.tree.outcome_counts.no_qualified_need or 0) > 0,
    "edge statistics name qualified absence")

print("test_qualified_pressure_shadow ok")
