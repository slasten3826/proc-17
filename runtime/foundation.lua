local freshness = require("runtime.freshness")

local foundation = {}

local function ensure_runtime(instance)
    instance.runtime = instance.runtime or {}
    instance.runtime.foundation = instance.runtime.foundation or {
        patterns = {},
        stability = 0,
        state = "fluid",
        reinforcements = 0,
    }
    instance.runtime.evidence = instance.runtime.evidence or {}
    return instance.runtime.foundation
end

local function pattern_key(result)
    return tostring(result.intention_hash or "") .. ":" .. tostring(result.name or result.spell_kind or "spell")
end

local function update_state(store)
    if store.reinforcements <= 0 then
        store.state = "fluid"
    elseif store.stability >= 0.85 then
        store.state = "stable_runtime"
    elseif store.stability < 0 then
        store.state = "collapsing"
    else
        store.state = "crystallizing"
    end
    return store.state
end

function foundation.reinforce(instance, spell_result)
    if type(instance) ~= "table" then
        return nil, "packet required"
    end
    if type(spell_result) ~= "table" or spell_result.kind ~= "spell_result" then
        return nil, "spell_result required"
    end

    local store = ensure_runtime(instance)
    local key = pattern_key(spell_result)
    local pattern = store.patterns[key]
    if not pattern then
        pattern = {
            spell_hash = key,
            name = spell_result.name,
            repetition_count = 0,
            success_count = 0,
            failure_count = 0,
            strength = 0,
            stability = 0,
            last_result = nil,
        }
        store.patterns[key] = pattern
    end

    pattern.repetition_count = pattern.repetition_count + 1
    if spell_result.success == true then
        pattern.success_count = pattern.success_count + 1
        pattern.strength = math.min(1.0, pattern.strength + 0.25)
        pattern.stability = math.min(1.0, pattern.stability + 0.20)
    else
        pattern.failure_count = pattern.failure_count + 1
        pattern.strength = math.max(0.0, pattern.strength - 0.10)
        pattern.stability = math.max(-1.0, pattern.stability - 0.30)
    end
    pattern.last_result = spell_result

    store.reinforcements = store.reinforcements + 1
    local total = 0
    local count = 0
    for _, current in pairs(store.patterns) do
        total = total + current.stability
        count = count + 1
    end
    store.stability = count > 0 and (total / count) or 0
    update_state(store)

    instance.runtime.evidence[#instance.runtime.evidence + 1] = spell_result
    return pattern
end

function foundation.snapshot(instance, opts)
    opts = opts or {}
    local store = ensure_runtime(instance)
    local clock = instance.physis and instance.physis.clock
    local current_tick = opts.tick or (clock and clock.ticks)
    local patterns = {}
    local stale_count = 0
    for key, pattern in pairs(store.patterns) do
        local entry = {
            spell_hash = pattern.spell_hash,
            name = pattern.name,
            repetition_count = pattern.repetition_count,
            success_count = pattern.success_count,
            failure_count = pattern.failure_count,
            strength = pattern.strength,
            stability = pattern.stability,
        }
        if pattern.last_result ~= nil then
            local read = freshness.read(pattern.last_result, {
                tick = current_tick,
                warm_window = opts.warm_window,
            })
            entry.freshness = read.zone
            entry.effective_truth_status = read.effective_truth_status
            entry.freshness_reason = read.reason
            if read.effective_truth_status ~= "runtime_confirmed" then
                stale_count = stale_count + 1
            end
        end
        patterns[key] = entry
    end
    -- the aggregate stamp certifies the counters and the snapshot act;
    -- each pattern carries its own effective status
    return {
        kind = "foundation_snapshot",
        state = store.state,
        stability = store.stability,
        reinforcements = store.reinforcements,
        evidence_count = #(instance.runtime and instance.runtime.evidence or {}),
        patterns = patterns,
        stale_count = stale_count,
        contains_stale = stale_count > 0,
        truth_status = "runtime_confirmed",
    }
end

function foundation.state(instance)
    local store = ensure_runtime(instance)
    return update_state(store)
end

return foundation
