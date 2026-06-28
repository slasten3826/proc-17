local choose = {}

local function copy_map(source)
    local result = {}
    if type(source) ~= "table" then
        return result
    end
    for key, value in pairs(source) do
        result[key] = value
    end
    return result
end

local function copy_array(source, max_items)
    local result = {}
    if type(source) ~= "table" then
        return result
    end
    local limit = max_items or #source
    for index = 1, math.min(#source, limit) do
        result[#result + 1] = source[index]
    end
    return result
end

local function normalize_limits(limits)
    limits = limits or {}
    if type(limits) ~= "table" then
        return nil, "invalid_limits"
    end

    local max_selected = limits.max_selected or 1
    local max_killed_sample = limits.max_killed_sample or 8

    if type(max_selected) ~= "number" or max_selected < 1 then
        return nil, "invalid_limits"
    end
    if type(max_killed_sample) ~= "number" or max_killed_sample < 0 then
        return nil, "invalid_limits"
    end

    return {
        max_selected = math.floor(max_selected),
        max_killed_sample = math.floor(max_killed_sample),
    }
end

local function item_id(item, index)
    if item.id ~= nil then
        return tostring(item.id)
    end
    if item.value ~= nil then
        return tostring(item.value)
    end
    return tostring(index)
end

local function normalize_items(field)
    if type(field) ~= "table" then
        return nil, "missing_field"
    end
    if type(field.items) ~= "table" then
        return nil, "invalid_field_items"
    end
    if #field.items == 0 then
        return nil, "empty_field"
    end

    local result = {}
    local by_id = {}
    for index, item in ipairs(field.items) do
        if type(item) ~= "table" then
            return nil, "invalid_field_items"
        end
        local normalized = {
            id = item_id(item, index),
            kind = item.kind,
            value = item.value,
            truth_status = item.truth_status or field.truth_status or "unknown",
            original_index = index,
        }
        result[#result + 1] = normalized
        by_id[normalized.id] = normalized
        if normalized.value ~= nil then
            by_id[tostring(normalized.value)] = normalized
        end
    end

    return result, nil, by_id
end

local function ranking_items(semantic_ranking)
    if type(semantic_ranking) ~= "table" or type(semantic_ranking.items) ~= "table" then
        return {}
    end
    return semantic_ranking.items
end

local function ranked_order(items, by_id, semantic_ranking)
    local ordered = {}
    local seen = {}
    local rank_truth = semantic_ranking and semantic_ranking.truth_status or "semantic_proposal"

    for _, rank_item in ipairs(ranking_items(semantic_ranking)) do
        local ref
        local reason
        if type(rank_item) == "table" then
            ref = rank_item.value or rank_item.path or rank_item.id
            reason = rank_item.reason
        else
            ref = rank_item
        end

        local item = ref ~= nil and by_id[tostring(ref)] or nil
        if item and not seen[item.id] then
            seen[item.id] = {
                text = reason,
                truth_status = rank_truth == "runtime_confirmed" and "runtime_confirmed" or "semantic_proposal",
            }
            ordered[#ordered + 1] = item
        end
    end

    for _, item in ipairs(items) do
        if not seen[item.id] then
            seen[item.id] = {
                truth_status = "unknown",
            }
            ordered[#ordered + 1] = item
        end
    end

    return ordered, seen
end

local function selected_item(item, reason)
    return {
        id = item.id,
        kind = item.kind,
        value = item.value,
        source_truth_status = item.truth_status,
        selection_truth_status = "runtime_confirmed",
        reason = reason or {truth_status = "unknown"},
    }
end

local function killed_item(item)
    return {
        id = item.id,
        kind = item.kind,
        value = item.value,
        source_truth_status = item.truth_status,
    }
end

function choose.choose(input)
    input = input or {}
    local limits, limits_err = normalize_limits(input.limits)
    if not limits then
        return nil, limits_err
    end

    local items, items_err, by_id = normalize_items(input.field)
    if not items then
        return nil, items_err
    end

    local ordered, reasons = ranked_order(items, by_id, input.semantic_ranking)
    local selected = {}
    local selected_ids = {}
    for _, item in ipairs(ordered) do
        if #selected >= limits.max_selected then
            break
        end
        selected[#selected + 1] = selected_item(item, reasons[item.id])
        selected_ids[item.id] = true
    end

    if #selected == 0 then
        return nil, "empty_field"
    end

    local killed_full = {}
    for _, item in ipairs(items) do
        if not selected_ids[item.id] then
            killed_full[#killed_full + 1] = killed_item(item)
        end
    end

    local killed_sample = copy_array(killed_full, limits.max_killed_sample)
    local not_chosen_count = #items - #selected

    return {
        kind = "choose_collapse_payload",
        selected = selected,
        killed_alternatives = killed_sample,
        not_chosen_count = not_chosen_count,
        choice_pressure = copy_map(input.pressure),
        choice_basis = {
            order = input.semantic_ranking and "semantic_ranking_then_field_order" or "field_order",
            semantic_ranking_truth_status = input.semantic_ranking and (input.semantic_ranking.truth_status or "semantic_proposal") or nil,
        },
        loss = {
            kind = "attention_collapse",
            not_chosen_count = not_chosen_count,
            truncated = #killed_full > #killed_sample,
        },
        limits = limits,
        truth_status = "runtime_confirmed",
    }
end

return choose
