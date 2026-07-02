local logic_choose = require("logic.choose")
local body = require("runtime.body")

local choose = {}

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

    body.record_choice(instance, payload)
    instance.tension.last_choice_pressure = {
        selected_count = #payload.selected,
        not_chosen_count = payload.not_chosen_count,
        loss = payload.loss,
    }

    return instance, payload
end

return choose

