package.path = "./?.lua;./?/init.lua;" .. package.path

local l1 = require("l1.field")

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

local function copy_array(source)
    local result = {}
    for index, value in ipairs(source) do
        result[index] = value
    end
    return result
end

local function assert_array_eq(left, right, message)
    assert_eq(#left, #right, (message or "arrays differ") .. " length")
    for index = 1, #left do
        assert_eq(left[index], right[index], (message or "arrays differ") .. " at " .. index)
    end
end

local function assert_snapshot(snapshot, expected, label)
    for key, value in pairs(expected) do
        assert_eq(snapshot[key], value, label .. " " .. key)
    end
end

assert_eq(_VERSION, "Lua 5.4", "L1 parity interpreter")

local small_source = {1, 2, 3, 4, 5, 6, 7, 8}
local small = assert(l1.initialize(small_source, {
    variant = "C",
    source_ref = "fixture:l1-small-s1",
}))

assert_eq(small.protocol_version, "l1.field.v0", "L1 state protocol")
assert_eq(small.interpreter_contract, "lua-5.4", "L1 state interpreter contract")
assert_eq(small.ring_size, 8, "L1 small ring size")
assert_true(small.source.token_ids == nil, "L1 state does not retain source sequence")

local expected_fingerprints = {
    29523,
    0,
    29524,
    1,
    29525,
    4,
    29527,
    8,
    29521,
    4,
    29521,
    3,
    29521,
    4,
    29523,
    4,
    29520,
}

local snapshots = {}
snapshots[0] = assert(l1.snapshot(small))
assert_snapshot(snapshots[0], {
    tick = 0,
    position = 1,
    carry = 1,
    fingerprint = 29523,
    trace_density = 8,
    distinct_core = 8,
    distinct_l1_trace = 4,
}, "small t0")

for tick = 1, 16 do
    local prior_position = small.position
    local prior_core = copy_array(small.core)
    local prior_trace = copy_array(small.l1_trace)
    assert(l1.tick(small))
    assert_eq(small.ticks, tick, "L1 tick count")
    assert_eq(small.position, (prior_position % small.ring_size) + 1, "L1 position advance")
    for index = 1, small.ring_size do
        if index ~= prior_position then
            assert_eq(small.core[index], prior_core[index], "L1 changes only visited core position")
            assert_eq(small.l1_trace[index], prior_trace[index],
                "L1 changes only visited trace position")
        end
    end
    snapshots[tick] = assert(l1.snapshot(small))
    assert_eq(snapshots[tick].fingerprint, expected_fingerprints[tick + 1],
        "small full trajectory fingerprint t" .. tick)
end

assert_snapshot(snapshots[1], {
    position = 2,
    carry = 29523,
    fingerprint = 0,
    trace_density = 8,
    distinct_core = 8,
    distinct_l1_trace = 4,
}, "small t1")
assert_snapshot(snapshots[8], {
    position = 1,
    carry = 3,
    fingerprint = 29521,
    trace_density = 7,
    distinct_core = 7,
    distinct_l1_trace = 7,
}, "small t8")
assert_snapshot(snapshots[16], {
    position = 1,
    carry = 4,
    fingerprint = 29520,
    trace_density = 8,
    distinct_core = 5,
    distinct_l1_trace = 5,
}, "small t16")

local core_before_snapshot = copy_array(small.core)
local trace_before_snapshot = copy_array(small.l1_trace)
local first_observation = assert(l1.snapshot(small))
local second_observation = assert(l1.snapshot(small))
assert_snapshot(second_observation, first_observation, "repeated snapshot")
assert_array_eq(small.core, core_before_snapshot, "snapshot preserves core")
assert_array_eq(small.l1_trace, trace_before_snapshot, "snapshot preserves L1 trace")

local frozen = assert(l1.freeze(small))
assert_true(frozen.frozen, "L1 freeze marks state")
assert_eq(assert(l1.freeze(small)), small, "L1 freeze is idempotent")
local frozen_core = copy_array(small.core)
local frozen_tick, frozen_err = l1.tick(small)
assert_true(not frozen_tick, "frozen L1 rejects tick")
assert_eq(frozen_err, "L1 state is frozen", "frozen L1 error")
assert_array_eq(small.core, frozen_core, "frozen L1 does not mutate")
assert(l1.snapshot(small))

local missing_ref, missing_ref_err = l1.initialize({1, 2, 3})
assert_true(not missing_ref, "L1 requires source provenance")
assert_eq(missing_ref_err, "L1 source_ref must be a non-empty string", "source ref error")

local too_short, too_short_err = l1.initialize({1, 2}, {source_ref = "fixture:short"})
assert_true(not too_short, "L1 rejects short source")
assert_eq(too_short_err, "L1 source must contain at least 3 integers", "short source error")

local non_integer, non_integer_err = l1.initialize({1, 2.5, 3}, {source_ref = "fixture:float"})
assert_true(not non_integer, "L1 rejects non-integer source")
assert_eq(non_integer_err, "L1 source values must be Lua 5.4 integers", "integer source error")

local wrong_variant, wrong_variant_err = l1.initialize({1, 2, 3}, {
    source_ref = "fixture:variant",
    variant = "T3",
})
assert_true(not wrong_variant, "L1 rejects non-C variant")
assert_eq(wrong_variant_err, "L1 v0 supports only variant C", "variant error")

local over_caller_bound, over_caller_bound_err = l1.initialize({1, 2, 3, 4}, {
    source_ref = "fixture:bound",
    max_source_units = 3,
})
assert_true(not over_caller_bound, "L1 enforces caller bound")
assert_eq(over_caller_bound_err, "L1 source exceeds max_source_units", "caller bound error")

local museum = assert(dofile("tests/fixtures/l1_processlang_bootstrap_machine_ru_v2.lua"))
assert_eq(museum.token_count, 7965, "museum fixture token count")
assert_eq(#museum.token_ids, museum.token_count, "museum fixture source count")
local parity = assert(l1.initialize(museum.token_ids, {
    variant = "C",
    source_ref = "museum:processlang-bootstrap-machine-ru-v2",
}))

local parity_expected = {
    [1] = {
        position = 2,
        carry = 29525,
        fingerprint = 6887,
        trace_density = 7955,
        distinct_core = 1168,
        distinct_l1_trace = 794,
    },
    [7965] = {
        position = 1,
        carry = 29861,
        fingerprint = 0,
        trace_density = 7964,
        distinct_core = 1642,
        distinct_l1_trace = 4444,
    },
    [15930] = {
        position = 1,
        carry = 338,
        fingerprint = 29188,
        trace_density = 7964,
        distinct_core = 2715,
        distinct_l1_trace = 1140,
    },
}

for tick = 1, 15930 do
    assert(l1.tick(parity))
    local expected = parity_expected[tick]
    if expected then
        assert_snapshot(assert(l1.snapshot(parity)), expected, "museum parity t" .. tick)
    end
end

print("test_l1 ok")
