local spells = require("logic.spells")

local freshness = {}

-- warm_window default is vibed, not measured; tune when the body runs real tasks
freshness.default_warm_window = 8

local function verdict(zone, effective, reason, age, detail)
    local result = {
        zone = zone,
        effective_truth_status = effective,
        reason = reason,
        age = age,
    }
    for key, value in pairs(detail or {}) do
        result[key] = value
    end
    return result
end

function freshness.evidence_fingerprint(instance, opts)
    opts = opts or {}
    local evidence = instance and instance.runtime
        and instance.runtime.evidence or {}
    local clock = instance and instance.physis and instance.physis.clock
    local current_tick = opts.tick
    if current_tick == nil then
        current_tick = clock and clock.ticks
    end
    local parts = {tostring(#evidence)}
    for _, item in ipairs(evidence) do
        local read = freshness.read(item, {
            tick = current_tick,
            warm_window = opts.warm_window,
        })
        parts[#parts + 1] = table.concat({
            tostring(item.intention_hash),
            tostring(item.cast_tick),
            tostring(item.success),
            tostring(item.referent),
            tostring(item.referent_hash),
            tostring(read.zone),
            tostring(read.reason),
            tostring(read.effective_truth_status),
            tostring(read.current_referent_hash),
            tostring(read.referent_present),
        }, ":")
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
            return verdict("hot", "runtime_confirmed", "referent_verified", nil, {
                current_referent_hash = current,
                referent_present = current ~= nil,
            })
        end
        return verdict("cold", "semantic_proposal", "referent_changed", nil, {
            current_referent_hash = current,
            referent_present = current ~= nil,
        })
    end

    if type(record.cast_tick) == "number" and type(opts.tick) == "number" then
        local window = opts.warm_window or freshness.default_warm_window
        local age = opts.tick - record.cast_tick
        if age <= window then
            return verdict("warm", "runtime_confirmed", "inside_tick_window", age, {
                referent_present = false,
            })
        end
        return verdict("cold", "semantic_proposal", "tick_window_expired", age, {
            referent_present = false,
        })
    end

    return verdict("unclocked", "semantic_proposal", "no_clock", nil, {
        referent_present = false,
    })
end

local function sorted_keys(value)
    local keys = {}
    for key in pairs(value or {}) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

function freshness.observation(instance, record)
    if type(instance) ~= "table" or type(instance.revisions) ~= "table" then
        return nil, "packet revision vector required"
    end
    if type(record) ~= "table" or record.kind ~= "eye_observation" then
        return nil, "eye observation required"
    end
    if type(record.read_revisions) ~= "table" then
        return nil, "observation read revisions required"
    end

    local changed = {}
    local current = {}
    for _, component in ipairs(sorted_keys(record.read_revisions)) do
        local observed_revision = record.read_revisions[component]
        local current_revision = instance.revisions[component]
        current[component] = current_revision
        if current_revision ~= observed_revision then
            changed[#changed + 1] = {
                component = component,
                observed = observed_revision,
                current = current_revision,
            }
        end
    end

    local fresh = #changed == 0
    return {
        kind = "observation_freshness",
        observation_id = record.id,
        eye = record.eye,
        fresh = fresh,
        zone = fresh and "fresh" or "stale",
        reason = fresh and "referent_revisions_match" or "referent_revision_changed",
        changed_components = changed,
        read_revisions = record.read_revisions,
        current_revisions = current,
        event_truth_status = "runtime_confirmed",
        content_truth_status = record.content_truth_status,
    }
end

function freshness.latest_eye(instance, eye)
    local key = eye
    if eye == "☴" then
        key = "upper"
    elseif eye == "☱" then
        key = "lower"
    end
    if key ~= "upper" and key ~= "lower" then
        return nil, "invalid observation eye"
    end

    local observations = instance and instance.boundary and instance.boundary.observations or {}
    local records = observations[key] or {}
    local record = records[#records]
    if not record then
        return {
            kind = "observation_freshness",
            eye = key,
            fresh = false,
            zone = "missing",
            reason = "no_observation",
            changed_components = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    return freshness.observation(instance, record)
end

return freshness
