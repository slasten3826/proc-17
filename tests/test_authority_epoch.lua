package.path = "./?.lua;./?/init.lua;" .. package.path

local epoch = require("runtime.authority_epoch")
local edge_catalog = require("runtime.edge_catalog")
local pressure = require("runtime.pressure")
local router = require("runtime.router")
local tree_router = require("runtime.tree_router")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local function assert_false(value, message)
    if value then
        error(message or "expected false", 2)
    end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function copy_value(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

local function resolve(options)
    local record, diagnostics = epoch.resolve(options)
    assert_true(record ~= nil, diagnostics and diagnostics.code or diagnostics)
    assert(epoch.verify(record))
    return record, diagnostics
end

local function same_physics(left, right)
    local same, err = epoch.same_physics(left, right)
    assert_true(same ~= nil, err and err.code or err)
    return same
end

local function same_evidence(left, right)
    local same, err = epoch.same_evidence(left, right)
    assert_true(same ~= nil, err and err.code or err)
    return same
end

local function contains(values, expected)
    for _, value in ipairs(values or {}) do
        if value == expected then
            return true
        end
    end
    return false
end

local surface = assert(edge_catalog.authority_surface())
assert_eq(surface.edge_count, 22, "authority surface has all edges")
assert_eq(surface.legal_direction_count, 38, "authority surface has all directions")
assert_true(surface.surface_id:match("^sha256:") ~= nil, "surface id is tagged")
assert(edge_catalog.verify_authority_surface(surface))

local mutated_surface = copy_value(surface)
mutated_surface.edges[1].legal_directions[1] = "☰->▽"
local surface_ok, surface_err = edge_catalog.verify_authority_surface(mutated_surface)
assert_eq(surface_ok, nil, "surface law cannot be rewritten by caller")
assert_eq(surface_err.class, "instrument_contract", "surface error class")
assert_eq(surface_err.code, "authority_surface_mismatch", "surface error code")
assert_eq(surface_err.stage, "authority_epoch", "surface error stage")
local surface_error_keys = 0
for _ in pairs(surface_err) do
    surface_error_keys = surface_error_keys + 1
end
assert_eq(surface_error_keys, 3, "AE09 surface error is exact")
assert_eq(assert(edge_catalog.authority_surface()).edges[1].legal_directions[1],
    "▽->☰", "surface API returns a snapshot")
local public_definition = assert(edge_catalog.get("E01"))
public_definition.directions[1] = "☰->▽"
assert_eq(assert(edge_catalog.get("E01")).directions[1], "▽->☰",
    "catalog lookup cannot rewrite authority surface")
local public_list = edge_catalog.list()
public_list[1].left = "☰"
assert_eq(assert(edge_catalog.get("E01")).left, "▽",
    "catalog list cannot rewrite authority surface")

local legacy_descriptor = router.legacy_descriptor()
assert_eq(legacy_descriptor.routing_policy, router.legacy_policy,
    "legacy descriptor names exported policy")
assert_eq(legacy_descriptor.routing_policy_status, router.legacy_policy_status,
    "legacy descriptor names exported status")

local binary_pressure, binary_diagnostics = assert(pressure.describe({
    pressure_policy = "sampled",
    ablate_relation_consumer = true,
}))
assert_eq(binary_pressure.ablation_vector.relation_consumer, false,
    "binary policy cannot claim qualified ablation")
assert_true(contains(binary_pressure.unused_options, "ablate_relation_consumer"),
    "binary descriptor exposes unused ablation")
assert_true(contains(binary_diagnostics.unused_options, "ablate_relation_consumer"),
    "binary diagnostics expose unused ablation")

local qualified_pressure = assert(pressure.describe({
    pressure_policy = "qualified_need_v0",
    ablate_relation_consumer = true,
}))
assert_eq(qualified_pressure.ablation_vector.relation_consumer, true,
    "qualified descriptor carries effective ablation")
assert_eq(qualified_pressure.witness_protocol, "pressure.witness.v1",
    "qualified witness protocol is explicit")
local qualified_tree = assert(tree_router.describe(qualified_pressure, {
    threshold = 3,
    allow_control_fallback = true,
}))
assert(tree_router.verify_descriptor(qualified_tree))
assert_eq(qualified_tree.pressure.unused_options, nil,
    "tree identity omits diagnostic-only options")
assert_eq(qualified_tree.policy_parameters.movement_threshold, 3,
    "tree threshold is normalized")

-- AE01: pressure/witness policy changes both physical and evidential identity.
local tree_binary = resolve({router_mode = "tree", legacy_shadow = false})
local tree_qualified = resolve({
    router_mode = "tree",
    legacy_shadow = false,
    pressure_policy = "qualified_need_v0",
})
assert_false(same_physics(tree_binary, tree_qualified),
    "AE01 binary and qualified physics differ")
assert_false(same_evidence(tree_binary, tree_qualified),
    "AE01 binary and qualified evidence differ")

-- AE02: Lua insertion order is not epoch identity.
local ordered_a = {
    router_mode = "tree",
    pressure_policy = "qualified_need_v0",
    ablate_relation_consumer = true,
    tree_router = {threshold = 2, allow_control_fallback = true},
}
local ordered_b = {}
ordered_b.tree_router = {}
ordered_b.tree_router.allow_control_fallback = true
ordered_b.tree_router.threshold = 2
ordered_b.ablate_relation_consumer = true
ordered_b.pressure_policy = "qualified_need_v0"
ordered_b.router_mode = "tree"
local order_left = resolve(ordered_a)
local order_right = resolve(ordered_b)
assert_true(same_physics(order_left, order_right),
    "AE02 map order leaves physics stable")
assert_true(same_evidence(order_left, order_right),
    "AE02 map order leaves evidence stable")

-- AE03/AE04: work and economic coordinates do not define authority.
local plan_epoch = resolve({
    router_mode = "tree",
    pressure_policy = "qualified_need_v0",
    work_mode = "plan",
    prompt = "plan one",
    model = "model-a",
    packet_options = {budget = {steps = 8}},
})
local build_epoch = resolve({
    router_mode = "tree",
    pressure_policy = "qualified_need_v0",
    work_mode = "build",
    prompt = "build another",
    model = "model-b",
    packet_options = {budget = {steps = 4096}},
})
assert_true(same_physics(plan_epoch, build_epoch),
    "AE03/AE04 task coordinates leave physics stable")
assert_true(same_evidence(plan_epoch, build_epoch),
    "AE03/AE04 task coordinates leave evidence stable")

-- AE05-T: an effective live Tree ablation changes both ids.
local tree_unablated = resolve({
    router_mode = "tree",
    pressure_policy = "qualified_need_v0",
})
local tree_ablated = resolve({
    router_mode = "tree",
    pressure_policy = "qualified_need_v0",
    ablate_relation_consumer = true,
})
assert_false(same_physics(tree_unablated, tree_ablated),
    "AE05-T live ablation changes physics")
assert_false(same_evidence(tree_unablated, tree_ablated),
    "AE05-T live ablation changes evidence")

-- AE05-S: a Tree observer ablation changes only evidence identity.
local shadow_unablated = resolve({
    router_mode = "shadow",
    pressure_policy = "qualified_need_v0",
})
local shadow_ablated = resolve({
    router_mode = "shadow",
    pressure_policy = "qualified_need_v0",
    ablate_relation_consumer = true,
})
assert_true(same_physics(shadow_unablated, shadow_ablated),
    "AE05-S observer ablation leaves live physics stable")
assert_false(same_evidence(shadow_unablated, shadow_ablated),
    "AE05-S observer ablation changes evidence")

-- AE05-L: Tree-only options are diagnostic under legacy authority.
local legacy_plain, legacy_plain_diagnostics = resolve({router_mode = "legacy"})
local legacy_ablated, legacy_ablated_diagnostics = resolve({
    router_mode = "legacy",
    pressure_policy = "qualified_need_v0",
    ablate_relation_consumer = true,
})
assert_true(same_physics(legacy_plain, legacy_ablated),
    "AE05-L unused Tree option leaves physics stable")
assert_true(same_evidence(legacy_plain, legacy_ablated),
    "AE05-L unused Tree option leaves evidence stable")
assert_eq(#legacy_plain_diagnostics.unused_options, 0,
    "legacy baseline has no unused policy option")
assert_true(contains(legacy_ablated_diagnostics.unused_options,
    "ablate_relation_consumer"), "legacy reports unused ablation")

-- AE06-A: default shadow observes the same legacy physics as legacy mode.
local shadow_default = resolve({router_mode = "shadow"})
assert_true(same_physics(legacy_plain, shadow_default),
    "AE06-A legacy and shadow share live physics")
assert_false(same_evidence(legacy_plain, shadow_default),
    "AE06-A observer changes evidence identity")
assert_eq(shadow_default.instrumentation.observer_mode, "tree_shadow",
    "A1 shadow names Tree observer")

-- AE06-B: the legacy observer has no mass under Tree authority.
local tree_observed = resolve({router_mode = "tree"})
local tree_unobserved = resolve({router_mode = "tree", legacy_shadow = false})
assert_true(same_physics(tree_observed, tree_unobserved),
    "AE06-B observer toggle leaves Tree physics stable")
assert_false(same_evidence(tree_observed, tree_unobserved),
    "AE06-B observer toggle changes evidence identity")
assert_eq(tree_observed.instrumentation.observer_mode, "legacy_shadow",
    "A1 Tree default names legacy observer")
assert_eq(tree_unobserved.instrumentation.observer_mode, "none",
    "A1 Tree observer can be disabled")

local tree_harness_override = resolve({
    router_mode = "tree",
    tree_test_override = true,
})
assert_true(same_physics(tree_observed, tree_harness_override),
    "A1 harness override is route taint, not configured physics")
assert_true(same_evidence(tree_observed, tree_harness_override),
    "A1 harness override is outside configured evidence identity")

-- AE07: normalized routing parameters participate in Tree identity.
local threshold_default = resolve({router_mode = "tree", legacy_shadow = false})
local threshold_changed = resolve({
    router_mode = "tree",
    legacy_shadow = false,
    tree_router = {threshold = 1},
})
assert_false(same_physics(threshold_default, threshold_changed),
    "AE07 threshold changes physics")
assert_false(same_evidence(threshold_default, threshold_changed),
    "AE07 threshold changes evidence")
local fallback_default = resolve({
    router_mode = "tree",
    legacy_shadow = false,
    pressure_policy = "qualified_need_v0",
})
local fallback_changed = resolve({
    router_mode = "tree",
    legacy_shadow = false,
    pressure_policy = "qualified_need_v0",
    tree_router = {allow_control_fallback = true},
})
assert_false(same_physics(fallback_default, fallback_changed),
    "AE07 fallback changes physics")

-- AE08: unknown policy-affecting options cannot be called unablated.
local unknown, unknown_err = epoch.resolve({
    router_mode = "legacy",
    ablate_future_reader = true,
})
assert_eq(unknown, nil, "AE08 unknown ablation invalidates epoch")
assert_eq(unknown_err.code, "unknown_policy_affecting_option",
    "AE08 error is typed")
assert_eq(unknown_err.option, "ablate_future_reader", "AE08 names option")

-- AE09: current surface disagreement is a dedicated instrument error.
local bad_surface_epoch = copy_value(shadow_default)
bad_surface_epoch.physics.authority_surface_id = "sha256:" .. string.rep("0", 64)
local bad_surface_ok, bad_surface_err = epoch.verify(bad_surface_epoch)
assert_eq(bad_surface_ok, nil, "AE09 epoch rejects foreign surface")
assert_eq(bad_surface_err.code, "authority_surface_mismatch",
    "AE09 epoch preserves surface error")

-- AE10: caller may assert ids, never supply the epoch as truth.
local expected_lie, expected_lie_err = epoch.resolve({
    expected_authority_epoch = {
        physics_epoch_id = "sha256:" .. string.rep("0", 64),
    },
})
assert_eq(expected_lie, nil, "AE10 expected identity lie is loud")
assert_eq(expected_lie_err.code, "authority_epoch_expectation_mismatch",
    "AE10 error is typed")
assert_eq(expected_lie_err.fatal_to_harness, true,
    "AE10 mismatch is fatal to harness")

-- AE11: evidence retention bounds change evidence, never body physics.
local bounds_default = resolve({router_mode = "shadow"})
local bounds_explicit_default = resolve({
    router_mode = "shadow",
    authority_instrument_bounds = {
        max_source_records = 4096,
        max_single_source_bytes = 2 * 1024 * 1024,
        max_source_bytes_per_life = 32 * 1024 * 1024,
        max_projection_bytes = 16 * 1024 * 1024,
        max_error_records = 256,
    },
})
assert_true(same_evidence(bounds_default, bounds_explicit_default),
    "AE11 equal effective defaults share evidence identity")
local bounds_changed = resolve({
    router_mode = "shadow",
    authority_instrument_bounds = {max_source_records = 128},
})
assert_true(same_physics(bounds_default, bounds_changed),
    "AE11 bounds leave physics stable")
assert_false(same_evidence(bounds_default, bounds_changed),
    "AE11 bounds change evidence identity")

local snap = assert(epoch.snapshot(tree_qualified))
snap.physics.live_policy.routing_policy = "tampered"
assert(epoch.verify(tree_qualified))
assert_eq(tree_qualified.physics.live_policy.routing_policy,
    "pressure.class_order.v0", "epoch snapshot cannot alias source")

print("test_authority_epoch ok")
