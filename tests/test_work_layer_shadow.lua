package.path = "./?.lua;./?/init.lua;" .. package.path

local plan_life = require("tests.support.plan_life")

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

local function run(label, observer, contract)
    return plan_life.run(
        label,
        "work_sequence",
        {"inspect", "build", "verify"},
        5,
        {
            work_layer_observer = observer,
            work_layer_contract = contract,
        }
    )
end

local function walk(result)
    local values = {}
    for _, route in ipairs(result.routes or {}) do
        values[#values + 1] = tostring(route.from) .. "->" .. tostring(route.to)
    end
    return table.concat(values, "|")
end

local function event_types(instance)
    local values = {}
    for _, event in ipairs(instance.trace or {}) do
        values[#values + 1] = event.type
    end
    return table.concat(values, "|")
end

local function numeric_map_eq(left, right, name)
    local keys = {}
    for key in pairs(left or {}) do keys[key] = true end
    for key in pairs(right or {}) do keys[key] = true end
    for key in pairs(keys) do
        assert_eq(left and left[key], right and right[key], name .. "." .. tostring(key))
    end
end

local disabled, disabled_result = assert(run("work-layer-shadow-off", "off"))
local enabled, enabled_result = assert(run("work-layer-shadow-on", "shadow_v0"))

assert_eq(walk(enabled_result), walk(disabled_result), "observer cannot alter route")
assert_eq(#enabled_result.ticks, #disabled_result.ticks, "observer cannot alter ticks")
numeric_map_eq(enabled.runtime.budget.spent, disabled.runtime.budget.spent,
    "observer budget")
numeric_map_eq(enabled.runtime.budget.remaining, disabled.runtime.budget.remaining,
    "observer remaining budget")
numeric_map_eq(enabled.revisions, disabled.revisions, "observer revisions")
assert_eq(enabled.tension.loss, disabled.tension.loss, "observer cannot alter loss")
assert_eq(enabled.status, disabled.status, "observer cannot alter finality")
assert_eq(enabled.death.cause, disabled.death.cause, "observer cannot alter death")
assert_eq(event_types(enabled), event_types(disabled), "observer writes no Packet event")
assert_eq(#(disabled_result.work_layer_observations or {}), 0,
    "disabled observer stores nothing")
assert_eq(#(enabled_result.work_layer_observations or {}), #enabled_result.ticks,
    "one detached observation follows each committed tick")
assert_eq(enabled_result.work_layer_observer_errors, nil,
    "valid observer has no instrumentation errors")

local glyphs = {}
for _, observation in ipairs(enabled_result.work_layer_observations) do
    local projection = observation.projection
    assert_true(type(projection) == "table", "observation carries projection")
    glyphs[projection.glyph] = true
end
assert_true(glyphs["⋯"] and glyphs["⊞"] and glyphs["◈"] and glyphs["▲"],
    "one life exposes the complete plan layer progression")

local stored_second = enabled_result.work_layer_observations[2].projection.glyph
enabled_result.work_layer_observations[1].projection.glyph = "caller-forged"
assert_eq(enabled_result.work_layer_observations[2].projection.glyph, stored_second,
    "observations do not alias each other")

local malformed, malformed_result = assert(run(
    "work-layer-shadow-error",
    "shadow_v0",
    {glyph = "▲"}
))
assert_eq(malformed.status, "dead", "instrumentation error cannot stop Packet")
assert_eq(malformed.death.cause, "complete", "instrumentation error is not mortality")
assert_true(#(malformed_result.work_layer_observer_errors or {}) > 0,
    "observer failure is recorded as instrumentation")

print("test_work_layer_shadow ok")
