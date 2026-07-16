local logic_choose = require("logic.choose")
local body = require("runtime.body")
local packet_core = require("core.packet")
local canonical_field = require("runtime.field")

local choose = {}

local function activation_plan(instance, payload)
    local current = instance.calm and instance.calm.current or nil
    local shadow = type(current) == "table" and current.field_shadow or nil
    local mapping = type(shadow) == "table" and shadow.legacy_to_unit_id or nil
    local plan = {
        status = "unavailable",
        selected_unit_ids = {},
        suppressed_unit_ids = {},
        shadow_only = true,
    }
    if type(mapping) ~= "table" then
        plan.reason = "no_field_mapping"
        return plan
    end
    if payload.collapse_type == "confirmation" then
        plan.status = "confirmation"
        plan.reason = "no_alternatives_suppressed"
        return plan
    end

    local seen = {}
    for _, selected in ipairs(payload.selected or {}) do
        local unit_id = mapping[tostring(selected.id)]
        if not unit_id or not canonical_field.get_unit(instance, unit_id) then
            plan.reason = "selected_field_unit_missing"
            return plan
        end
        if not seen[unit_id] then
            seen[unit_id] = true
            plan.selected_unit_ids[#plan.selected_unit_ids + 1] = unit_id
        end
    end
    for _, legacy_id in ipairs(payload.suppressed_ids or {}) do
        local unit_id = mapping[tostring(legacy_id)]
        if not unit_id or not canonical_field.get_unit(instance, unit_id) then
            plan.reason = "suppressed_field_unit_missing"
            return plan
        end
        if not seen[unit_id] then
            seen[unit_id] = true
            plan.suppressed_unit_ids[#plan.suppressed_unit_ids + 1] = unit_id
        end
    end

    plan.status = "planned"
    plan.reason = nil
    return plan
end

local function apply_activation_plan(instance, plan, event_id)
    if plan.status ~= "planned" then
        return true
    end
    for _, unit_id in ipairs(plan.selected_unit_ids) do
        local unit, unit_err = canonical_field.set_activation(instance, "☳", unit_id, "selected", {
            event_id = event_id,
            reason = "chosen_alternative",
        })
        if not unit then
            return nil, unit_err
        end
    end
    for _, unit_id in ipairs(plan.suppressed_unit_ids) do
        local unit, unit_err = canonical_field.set_activation(instance, "☳", unit_id, "suppressed", {
            event_id = event_id,
            reason = "killed_alternative",
        })
        if not unit then
            return nil, unit_err
        end
    end
    plan.status = "applied"
    return true
end

local function field_from_calm(instance)
    local current = instance.calm and instance.calm.current or nil
    if type(current) == "table" and type(current.field) == "table" then
        return current.field
    end

    local items = {}
    local units = instance.calm and instance.calm.work_units or {}
    for _, unit in ipairs(units or {}) do
        items[#items + 1] = {
            id = unit.id,
            kind = unit.kind or "work_unit",
            value = unit.description or unit.id,
            role = "alternative",
            truth_status = unit.truth_status or unit.content_truth_status or "runtime_confirmed",
        }
    end

    if #items == 0 then
        return nil
    end

    return {
        shape = "work_unit_field",
        intent = "choose_work_unit",
        truth_status = "runtime_confirmed",
        items = items,
    }
end

function choose.run(instance, options)
    options = options or {}
    local mutable, mutable_err = packet_core.assert_mutable(instance, "choose")
    if not mutable then
        return nil, mutable_err
    end
    local field = options.field or field_from_calm(instance)
    if not field then
        return nil, "empty_calm"
    end

    local payload, err = logic_choose.choose({
        field = field,
        limits = options.limits or {max_selected = 1, max_killed_sample = 8},
        pressure = options.pressure or {
            field_shape = field.shape,
            field_intent = field.intent,
            operator_pressure = "calm_alternatives",
        },
        semantic_ranking = options.semantic_ranking,
    })
    if not payload then
        return nil, err
    end

    payload.field_shadow = activation_plan(instance, payload)

    local recorded, event_or_err = body.record_choice(instance, payload)
    if not recorded then
        return nil, event_or_err
    end
    local applied, apply_err = apply_activation_plan(instance, payload.field_shadow, event_or_err.id)
    if not applied then
        return nil, apply_err
    end
    payload.trace_event_id = event_or_err.id
    instance.tension.last_choice_pressure = {
        selected_count = #payload.selected,
        not_chosen_count = payload.not_chosen_count,
        loss = payload.loss,
    }

    return instance, payload
end

return choose
