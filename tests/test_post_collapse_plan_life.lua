package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")
local packet = require("core.packet")
local pressure_action = require("runtime.pressure_action")
local qualified_pressure = require("runtime.qualified_pressure")
local registry = require("runtime.operator_registry")
local router = require("runtime.router")
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

local function grown(label, shape, values, ticks, overrides, envelope)
    local instance, result = assert(fixture.run(
        label,
        shape,
        values,
        ticks,
        overrides,
        envelope
    ))
    return instance, result
end

-- P0-P2: every exact plan shape reaches the terminal through the canonical eyes.
local sequence, sequence_result = grown(
    "life-sequence", "work_sequence", {"inspect", "change", "verify"}, 5
)
assert_eq(fixture.walk(sequence_result), "☴☵☴☱△", "sequence life")
assert_eq(sequence.status, "dead", "sequence dies after delivery")
local alternatives, alternatives_result = grown(
    "life-alternatives", "alternative_set", {"retain", "replace"}, 7
)
assert_eq(fixture.walk(alternatives_result), "☴☵☴☳☴☱△",
    "alternative life")
assert_eq(#alternatives.manifest.output.structured.items, 1,
    "alternative output contains survivor")
assert_eq(#alternatives.residue.suppressed_items, 1,
    "alternative residue contains suppressed form")
local confirmation, confirmation_result = grown(
    "life-confirmation", "alternative_set", {"only"}, 5
)
assert_eq(fixture.walk(confirmation_result), "☴☵☴☱△", "confirmation life")
assert_eq(#(confirmation.boundary.choices or {}), 0,
    "confirmation creates no choice event")

-- P3/P4: exact delivery is unavailable to build mode and malformed prose.
local build, build_result = grown(
    "life-build", "work_sequence", {"inspect", "change"}, 5,
    {work_mode = "build"}
)
assert_true(build.manifest == nil, "build cannot use plan delivery")
assert_eq(#fixture.events(build, "plan_completion_assessment"), 0,
    "build creates no plan assessment")
assert_true(build_result.stop_reason ~= "manifested",
    "build does not manifest through plan boundary")
local build_pressure = assert(qualified_pressure.derive(build, nil, {
    current_operator = build.operator,
    ablate_relation_consumer = true,
}))
for _, diagnostic in ipairs(build_pressure.unqualified or {}) do
    assert_true(diagnostic.kind ~= "plan_mode_absent",
        "normal build applicability cannot poison promotion evidence")
end
local prose, prose_result = grown(
    "life-prose", "work_sequence", nil, 4, nil, "ordinary prose"
)
assert_true(prose.manifest == nil, "prose cannot use exact plan delivery")
assert_true(prose_result.stop_reason ~= "manifested",
    "prose cannot claim exact completion")

-- P5/P6: route commitment never performs the receiving organ's effect.
local before_review, before_review_result = grown(
    "life-before-review", "work_sequence", {"inspect", "change"}, 3
)
assert_eq(before_review.operator, "☱", "review edge is committed")
assert_true(fixture.last_route_to(before_review_result, "☱") ~= nil,
    "review edge exists")
assert_eq(#fixture.events(before_review, "plan_completion_assessment"), 0,
    "committed review edge writes no assessment")
local before_delivery, before_delivery_result = grown(
    "life-before-delivery", "work_sequence", {"inspect", "change"}, 4
)
assert_eq(before_delivery.operator, "△", "delivery edge is committed")
assert_true(fixture.last_route_to(before_delivery_result, "△") ~= nil,
    "delivery edge exists")
assert_true(before_delivery.manifest == nil and before_delivery.death == nil,
    "committed delivery edge writes no terminal state")

-- Tree ablations remove exactly their producer and preserve the earlier life.
local no_review, no_review_result = grown(
    "life-review-ablated", "work_sequence", {"inspect", "change"}, 5,
    {ablate_plan_completion_consumer = true}
)
assert_eq(fixture.walk(no_review_result), "☴☵☴",
    "review ablation stops at exact observed material")
assert_eq(#fixture.events(no_review, "plan_completion_assessment"), 0,
    "review ablation writes no assessment")
local no_delivery, no_delivery_result = grown(
    "life-delivery-ablated", "work_sequence", {"inspect", "change"}, 5,
    {ablate_plan_delivery_consumer = true}
)
assert_eq(fixture.walk(no_delivery_result), "☴☵☴☱",
    "delivery ablation stops after honest assessment")
assert_eq(#fixture.events(no_delivery, "plan_completion_assessment"), 1,
    "delivery ablation preserves review")
assert_true(no_delivery.manifest == nil, "delivery ablation writes no manifest")

-- A0: review pressure is massless while the legacy observer remains authority.
local function review_shadow(ablate)
    local instance, result = grown(
        "life-review-shadow", "work_sequence", {"inspect", "change"}, 3
    )
    assert(packet.commit_transition(instance, {
        from = "☱",
        to = "☴",
        reason = "review_shadow_fixture",
        authority = "harness_override",
    }))
    assert(packet.begin_tick(instance, "☴", {}))
    local revisions = json.encode(instance.revisions)
    local budget = json.encode(instance.runtime.budget)
    local loss = instance.tension.loss
    local decision = assert(router.after_tick(instance, {
        operator = "☴",
        payload = result.ticks[3].payload,
        work_mode = "plan",
    }, {
        mode = "shadow",
        options = {
            pressure_policy = "qualified_need_v0",
            ablate_relation_consumer = true,
            ablate_plan_completion_consumer = ablate,
        },
    }))
    return instance, decision, revisions, budget, loss
end

local review_active, active_review, active_revisions, active_budget, active_loss =
    review_shadow(false)
local review_ablated, ablated_review, ablated_revisions, ablated_budget, ablated_loss =
    review_shadow(true)
assert_eq(active_review.to, ablated_review.to,
    "review observer cannot change legacy live route")
assert_eq(active_review.shadow.predicted_to, "☱",
    "active observer sees plan review")
assert_true(ablated_review.shadow.predicted_to == nil,
    "review ablation removes only prediction")
assert_eq(json.encode(review_active.revisions), active_revisions,
    "active review derivation cannot move revisions")
assert_eq(json.encode(review_ablated.revisions), ablated_revisions,
    "ablated review derivation cannot move revisions")
assert_eq(json.encode(review_active.runtime.budget), active_budget,
    "review derivation cannot charge budget")
assert_eq(json.encode(review_ablated.runtime.budget), ablated_budget,
    "review ablation cannot charge budget")
assert_eq(review_active.tension.loss, active_loss,
    "review derivation cannot charge loss")
assert_eq(review_ablated.tension.loss, ablated_loss,
    "review ablation cannot charge loss")

-- A1: once ☱ writes an assessment, delivery pressure is equally massless.
local function delivery_shadow(ablate)
    local instance, result = grown(
        "life-delivery-shadow", "work_sequence", {"inspect", "change"}, 3
    )
    local route = assert(fixture.last_route_to(result, "☱"))
    local action_plan = route.selected_candidate.action_plan
    local context = assert(pressure_action.registry_context(action_plan, {
        instance = instance,
        options = {work_mode = "plan"},
        result = result,
    }))
    assert(packet.begin_tick(instance, "☱", {}))
    local execution = assert(registry.execute("☱", instance, context))
    assert_eq(execution.status, "applied", "delivery shadow fixture reviews")
    local revisions = json.encode(instance.revisions)
    local budget = json.encode(instance.runtime.budget)
    local loss = instance.tension.loss
    local decision = assert(router.after_tick(instance, {
        operator = "☱",
        payload = execution.payload,
        work_mode = "plan",
    }, {
        mode = "shadow",
        options = {
            pressure_policy = "qualified_need_v0",
            ablate_relation_consumer = true,
            ablate_plan_delivery_consumer = ablate,
        },
    }))
    return instance, decision, revisions, budget, loss
end

local delivery_active, active_delivery, delivery_revisions, delivery_budget,
    delivery_loss = delivery_shadow(false)
local delivery_ablated, ablated_delivery, ablated_delivery_revisions,
    ablated_delivery_budget, ablated_delivery_loss = delivery_shadow(true)
assert_eq(active_delivery.to, ablated_delivery.to,
    "delivery observer cannot change legacy live route")
assert_eq(active_delivery.shadow.predicted_to, "△",
    "active observer sees plan delivery")
assert_true(ablated_delivery.shadow.predicted_to == nil,
    "delivery ablation removes only prediction")
assert_eq(json.encode(delivery_active.revisions), delivery_revisions,
    "delivery derivation cannot move revisions")
assert_eq(json.encode(delivery_ablated.revisions), ablated_delivery_revisions,
    "delivery ablation cannot move revisions")
assert_eq(json.encode(delivery_active.runtime.budget), delivery_budget,
    "delivery derivation cannot charge budget")
assert_eq(json.encode(delivery_ablated.runtime.budget), ablated_delivery_budget,
    "delivery ablation cannot charge budget")
assert_eq(delivery_active.tension.loss, delivery_loss,
    "delivery derivation cannot charge loss")
assert_eq(delivery_ablated.tension.loss, ablated_delivery_loss,
    "delivery ablation cannot charge loss")

print("test_post_collapse_plan_life ok")
