local spells = require("logic.spells")

local freshness = {}

-- warm_window default is vibed, not measured; tune when the body runs real tasks
freshness.default_warm_window = 8

local function verdict(zone, effective, reason, age)
    return {
        zone = zone,
        effective_truth_status = effective,
        reason = reason,
        age = age,
    }
end

function freshness.evidence_fingerprint(instance)
    local evidence = instance and instance.runtime
        and instance.runtime.evidence or {}
    local parts = {tostring(#evidence)}
    for _, item in ipairs(evidence) do
        parts[#parts + 1] = tostring(item.intention_hash) .. ":"
            .. tostring(item.cast_tick) .. ":" .. tostring(item.success)
    end
    return spells.hash(table.concat(parts, "|"))
end

function freshness.read(record, opts)
    opts = opts or {}
    if type(record) ~= "table" then
        return verdict("unclocked", "semantic_proposal", "no_clock", nil)
    end

    if record.referent_hash ~= nil and record.referent ~= nil then
        local current = spells.referent_hash(record.referent)
        if current == record.referent_hash then
            return verdict("hot", "runtime_confirmed", "referent_verified", nil)
        end
        return verdict("cold", "semantic_proposal", "referent_changed", nil)
    end

    if type(record.cast_tick) == "number" and type(opts.tick) == "number" then
        local window = opts.warm_window or freshness.default_warm_window
        local age = opts.tick - record.cast_tick
        if age <= window then
            return verdict("warm", "runtime_confirmed", "inside_tick_window", age)
        end
        return verdict("cold", "semantic_proposal", "tick_window_expired", age)
    end

    return verdict("unclocked", "semantic_proposal", "no_clock", nil)
end

return freshness
