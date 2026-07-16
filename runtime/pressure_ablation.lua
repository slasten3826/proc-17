local topology = require("core.topology")

local pressure_ablation = {
    protocol_version = "pressure.ablation.v0",
    profiles = {"C0", "A", "B", "AB"},
}

local profile_set = {
    C0 = true,
    A = true,
    B = true,
    AB = true,
}

local canonical_index = {}
for index, glyph in ipairs(topology.order) do
    canonical_index[glyph] = index
end

local ignored_lower_components = {
    budget = true,
    loss = true,
}

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

local function normalized_profile(profile)
    if type(profile) ~= "string" then
        return nil, "ablation profile must be string"
    end
    profile = string.upper(profile)
    if not profile_set[profile] then
        return nil, "unknown ablation profile"
    end
    return profile
end

local function profile_has(profile, flag)
    return profile == flag or profile == "AB"
end

local function revision_component(ref)
    if type(ref) ~= "string" then
        return nil
    end
    return ref:match("^revision:([^:]+):")
end

local function removal_record(contribution, action, components)
    return {
        action = action,
        kind = contribution.kind,
        target_operator = contribution.target_operator,
        target_edge = contribution.target_edge,
        source_refs = copy_value(contribution.source_refs or {}),
        removed_components = copy_value(components or {}),
    }
end

local function filter_lower_components(contribution, removed)
    local changed = contribution.changed_components
    if type(changed) ~= "table" or #changed == 0 then
        return copy_value(contribution)
    end

    local kept = {}
    local removed_names = {}
    for _, item in ipairs(changed) do
        if ignored_lower_components[item.component] then
            removed_names[#removed_names + 1] = item.component
        else
            kept[#kept + 1] = copy_value(item)
        end
    end

    if #removed_names == 0 then
        return copy_value(contribution)
    end
    if #kept == 0 then
        removed[#removed + 1] = removal_record(
            contribution,
            "remove_contribution",
            removed_names
        )
        return nil
    end

    local result = copy_value(contribution)
    result.changed_components = kept
    local refs = {}
    for _, ref in ipairs(result.source_refs or {}) do
        local component = revision_component(ref)
        if not ignored_lower_components[component] then
            refs[#refs + 1] = ref
        end
    end
    result.source_refs = refs
    result.source_ref = refs[1]
    removed[#removed + 1] = removal_record(
        contribution,
        "remove_components",
        removed_names
    )
    return result
end

local function filter_contributions(contributions, profile)
    local result = {}
    local removed = {}
    for _, contribution in ipairs(contributions or {}) do
        local filtered
        if profile_has(profile, "A") and contribution.kind == "runtime_mismatch" then
            removed[#removed + 1] = removal_record(
                contribution,
                "remove_contribution",
                {}
            )
        elseif profile_has(profile, "B")
            and contribution.kind == "lower_observation_debt"
        then
            filtered = filter_lower_components(contribution, removed)
        else
            filtered = copy_value(contribution)
        end
        if filtered then
            result[#result + 1] = filtered
        end
    end
    return result, removed
end

local function totals(contributions)
    local positive = 0
    local resistance = 0
    for _, contribution in ipairs(contributions or {}) do
        local amount = tonumber(contribution.amount) or 0
        if contribution.direction == "resist" then
            resistance = resistance + amount
        elseif contribution.direction == "help" then
            positive = positive + amount
        end
    end
    return positive, resistance, positive - resistance
end

local function no_viable_cause(candidates)
    local saw_missing_capability = false
    local saw_ready = false
    local saw_unsafe = false
    for _, candidate in ipairs(candidates or {}) do
        if candidate.readiness and candidate.readiness.ready then
            saw_ready = true
        end
        for _, exclusion in ipairs(candidate.exclusions or {}) do
            if exclusion.reason == "missing_capability" then
                saw_missing_capability = true
            elseif exclusion.kind == "safety" then
                saw_unsafe = true
            end
        end
    end
    if saw_unsafe then
        return "unsafe"
    end
    if saw_missing_capability and not saw_ready then
        return "missing_capability"
    end
    if saw_ready then
        return "below_threshold"
    end
    return "stalled"
end

local function select(candidates, threshold)
    threshold = threshold or 0
    local winner
    local tied = false
    for _, candidate in ipairs(candidates or {}) do
        if not candidate.excluded and candidate.total > threshold then
            if not winner or candidate.total > winner.total then
                winner = candidate
                tied = false
            elseif candidate.total == winner.total then
                tied = true
                if (canonical_index[candidate.to] or math.huge)
                    < (canonical_index[winner.to] or math.huge)
                then
                    winner = candidate
                end
            end
        end
    end
    if not winner then
        return nil, no_viable_cause(candidates)
    end
    return winner, tied and "highest_pressure_canonical_tie_break"
        or "highest_positive_pressure"
end

function pressure_ablation.apply(snapshot, profile)
    if type(snapshot) ~= "table" or snapshot.kind ~= "edge_pressure_snapshot" then
        return nil, "pressure snapshot required"
    end
    local normalized, profile_err = normalized_profile(profile)
    if not normalized then
        return nil, profile_err
    end

    local result = copy_value(snapshot)
    local contributions, removed = filter_contributions(snapshot.contributions, normalized)
    result.contributions = contributions
    result.ablation = {
        protocol_version = pressure_ablation.protocol_version,
        profile = normalized,
        base_derivation_version = snapshot.derivation_version,
        removed = removed,
        authority = "counterfactual_shadow_only",
    }
    return result
end

function pressure_ablation.reselect(shadow, profile, options)
    if type(shadow) ~= "table" or shadow.kind ~= "shadow_route_decision" then
        return nil, "shadow route decision required"
    end
    if shadow.predicted_reason == "prediction_error" then
        return nil, "cannot ablate failed shadow prediction"
    end
    local normalized, profile_err = normalized_profile(profile)
    if not normalized then
        return nil, profile_err
    end
    options = options or {}

    local candidates = copy_value(shadow.candidates or {})
    local removed = {}
    for _, candidate in ipairs(candidates) do
        local contributions, candidate_removed = filter_contributions(
            candidate.contributions,
            normalized
        )
        candidate.contributions = contributions
        candidate.removed_contributions = candidate_removed
        for _, item in ipairs(candidate_removed) do
            removed[#removed + 1] = item
        end
        candidate.positive, candidate.resistance, candidate.total = totals(contributions)
    end

    local winner, reason = select(candidates, options.threshold or 0)
    local predicted_to = winner and winner.to or nil
    local agreement = predicted_to ~= nil and predicted_to == shadow.live_to
    return {
        kind = "counterfactual_shadow_decision",
        protocol_version = pressure_ablation.protocol_version,
        profile = normalized,
        current_operator = shadow.current_operator,
        live_to = shadow.live_to,
        predicted_to = predicted_to,
        predicted_reason = winner and reason or reason,
        agreement = agreement,
        divergence = predicted_to == nil
            and ("no_viable_edge:" .. tostring(reason))
            or (agreement and nil
                or ("live:" .. tostring(shadow.live_to)
                    .. "/counterfactual:" .. tostring(predicted_to))),
        candidates = candidates,
        removed = removed,
        authority = "counterfactual_shadow_only",
        event_truth_status = "runtime_confirmed",
    }
end

return pressure_ablation
