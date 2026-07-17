package.path = "./?.lua;./?/init.lua;" .. package.path

local tension_runner = require("runtime.tension_runner")
local packet = require("core.packet")
local router = require("runtime.router")
local fake = require("substrates.fake")
local flow = require("organs.flow")

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

local function route_text(result)
    local out = {}
    for _, route in ipairs(result.routes or {}) do
        out[#out + 1] = route.from .. route.to
    end
    return table.concat(out, "|")
end

local function shadow_trace_count(instance)
    local count = 0
    local pressure_count = 0
    for _, event in ipairs(instance.trace or {}) do
        local kind = event.payload and event.payload.kind
        if kind == "shadow_route_decision" then
            count = count + 1
        elseif kind == "edge_pressure_snapshot" then
            pressure_count = pressure_count + 1
        end
    end
    return count, pressure_count
end

local function run(mode)
    return tension_runner.run("build notes app", fake, {
        work_mode = "plan",
        router_mode = mode,
        max_ticks = 8,
        packet_options = {
            budget = {steps = 32, substrate_calls = 8, encode_items = 8, loss = 10},
        },
        choose = {
            limits = {max_selected = 1, max_killed_sample = 8},
        },
    })
end

local legacy, legacy_result = assert(run("legacy"))
local shadow, shadow_result = assert(run("shadow"))

assert_eq(route_text(shadow_result), route_text(legacy_result), "shadow cannot change the live route")
assert_eq(shadow.runtime.budget.spent.steps, legacy.runtime.budget.spent.steps,
    "shadow cannot charge body steps")
assert_eq(shadow.runtime.budget.spent.substrate_calls, legacy.runtime.budget.spent.substrate_calls,
    "shadow cannot call substrate")
assert_eq(shadow.tension.loss, legacy.tension.loss, "shadow cannot create identity loss")
assert_eq(#legacy_result.shadow_routes, 0, "legacy mode emits no shadow predictions")
assert_eq(#shadow_result.shadow_routes, #shadow_result.routes, "every live route gets one shadow comparison")
assert_eq(shadow_result.edge_stats.shadow_ticks, #shadow_result.routes, "statistics read every shadow decision")
assert_eq(shadow_result.edge_stats.agreement_count + shadow_result.edge_stats.divergence_count,
    #shadow_result.routes, "every prediction is classified")
assert_true(shadow_result.edge_stats.divergence_count > 0, "fixture exposes migration divergences")
assert_eq(shadow_result.edge_stats_errors, nil, "edge statistics reader stays connected")

local shadow_events, pressure_events = shadow_trace_count(shadow)
assert_eq(shadow_events, #shadow_result.routes, "shadow decisions are append-only trace records")
assert_eq(pressure_events, #shadow_result.routes, "each prediction retains its pressure snapshot")

for _, comparison in ipairs(shadow_result.shadow_routes) do
    assert_eq(comparison.live_to ~= nil, true, "comparison names the authoritative route")
    assert_eq(comparison.policy, "pressure.binary.v0", "comparison names its policy")
    assert_eq(comparison.policy_status, "vibed_control", "shadow policy remains uncalibrated")
end

local promoted = packet.new("tree authority is explicit", {id = "tree-authority-explicit"})
assert(flow.run(promoted))
local tree, tree_err = router.after_tick(promoted, {operator = "▽"}, {
    mode = "tree",
    substrate = fake,
})
assert_true(tree, tree_err)
assert_eq(tree.kind, "tree_route_decision", "explicit tree mode derives a live decision")
assert_eq(tree.authority, "tree", "tree decision names its authority")
assert_true(type(tree.derivation_ref) == "string", "tree decision carries derivation evidence")
assert_true(tree.selected_candidate.readiness.ready, "tree authority selects a ready candidate")

print("test_shadow_router ok")
