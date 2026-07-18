package.path = "./?.lua;./?/init.lua;" .. package.path

local l1 = require("l1.field")

local TICKS = 16
local MOD = 59049
local PRNG_MOD = 2147483648
local S1 = {1, 2, 3, 4, 5, 6, 7, 8}
local S2 = {1, 2, 3, 4, 5, 6, 7, 9}

local function outputs_equal(left, right)
    if #left ~= #right then
        return false
    end
    for index = 1, #left do
        if left[index] ~= right[index] then
            return false
        end
    end
    return true
end

local function distinct_count(values)
    local seen = {}
    local count = 0
    for _, value in ipairs(values) do
        if not seen[value] then
            seen[value] = true
            count = count + 1
        end
    end
    return count
end

local function first_divergence(left, right)
    for index = 1, math.min(#left, #right) do
        if left[index] ~= right[index] then
            return index - 1
        end
    end
    if #left ~= #right then
        return math.min(#left, #right)
    end
    return nil
end

local function run_l1(source, source_ref)
    local state = assert(l1.initialize(source, {source_ref = source_ref}))
    local outputs = {assert(l1.snapshot(state)).fingerprint}
    local checkpoints = {[0] = assert(l1.snapshot(state))}
    for tick = 1, TICKS do
        assert(l1.tick(state))
        local snapshot = assert(l1.snapshot(state))
        outputs[#outputs + 1] = snapshot.fingerprint
        if tick == 1 or tick == 8 or tick == 16 then
            checkpoints[tick] = snapshot
        end
    end
    return outputs, checkpoints
end

local function static_hash(source)
    local value = 0
    for _, child in ipairs(source) do
        value = (value * 131 + child) % MOD
    end
    local outputs = {}
    for tick = 0, TICKS do
        outputs[tick + 1] = value
    end
    return outputs
end

local function prng(source)
    local state = 0
    for _, child in ipairs(source) do
        state = (state * 131 + child) % PRNG_MOD
    end
    local outputs = {state % MOD}
    for tick = 1, TICKS do
        state = (1103515245 * state + 12345) % PRNG_MOD
        outputs[tick + 1] = state % MOD
    end
    return outputs
end

local function report(name, left, right)
    local distinct = distinct_count(left)
    print(string.format(
        "%s distinct=%d repeated=%d first_source_divergence=%s",
        name,
        distinct,
        #left - distinct,
        tostring(first_divergence(left, right))
    ))
end

local l1_s1, checkpoints = run_l1(S1, "smoke:S1")
local l1_s1_repeat = run_l1(S1, "smoke:S1-repeat")
local l1_s2 = run_l1(S2, "smoke:S2")
assert(outputs_equal(l1_s1, l1_s1_repeat), "L1 clean runs diverged")

local hash_s1 = static_hash(S1)
local hash_s2 = static_hash(S2)
local prng_s1 = prng(S1)
local prng_s2 = prng(S2)

print("L1 pre-registered baseline report")
report("l1", l1_s1, l1_s2)
report("static_hash", hash_s1, hash_s2)
report("seeded_prng", prng_s1, prng_s2)

for _, tick in ipairs({0, 1, 8, 16}) do
    local snapshot = checkpoints[tick]
    print(string.format(
        "l1 checkpoint=%d fp=%d density=%d dcore=%d dtrace=%d pos=%d carry=%d",
        tick,
        snapshot.fingerprint,
        snapshot.trace_density,
        snapshot.distinct_core,
        snapshot.distinct_l1_trace,
        snapshot.position,
        snapshot.carry
    ))
end
