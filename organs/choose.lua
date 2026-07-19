local logic_choose = require("logic.choose")
local body = require("runtime.body")
local packet_core = require("core.packet")
local canonical_field = require("runtime.field")
local choice_inspection = require("runtime.choice_inspection")

local choose = {}

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

local function exact_choice_item(unit, selection_truth_status)
    local carrier = type(unit.carrier) == "table" and unit.carrier or {}
    return {
        id = unit.id,
        kind = unit.kind,
        value = carrier.value ~= nil and copy_value(carrier.value)
            or copy_value(unit.carrier),
        role = carrier.role,
        source_refs = copy_value(unit.source_refs or {}),
        source_truth_status = unit.content_truth_status,
        selection_truth_status = selection_truth_status,
        pre_action_version = unit.version,
        pre_action_activation = unit.activation,
    }
end

local function compatibility_readiness(instance)
    local calm = instance and instance.calm or {}
    local current = calm.current
    local items = type(current) == "table" and type(current.field) == "table"
        and current.field.items or calm.work_units or {}
    local refs = {}
    for index, item in ipairs(items or {}) do
        refs[#refs + 1] = tostring(
            type(item) == "table" and (item.id or item.value) or index
        )
    end
    return {
        operator = "☳",
        ready = #refs > 0,
        reason = #refs == 0 and "scope_empty"
            or (#refs == 1 and "confirmation_not_choice" or "ready"),
        source_refs = refs,
        alternative_count = #refs,
        collapse_possible = #refs > 1,
        required_capabilities = {},
        missing_capabilities = {},
        event_truth_status = "runtime_confirmed",
    }
end

function choose.readiness(instance, options)
    options = options or {}
    if options.choice_input == nil then
        return compatibility_readiness(instance)
    end
    local set, set_err = choice_inspection.resolve(instance, options.choice_input)
    return {
        operator = "☳",
        ready = set ~= nil,
        reason = set and "alternative_collapse_ready" or set_err,
        source_refs = set and copy_value(set.scope_refs) or {},
        choice_set_ref = set and set.choice_set_ref or nil,
        alternative_count = set and set.eligible_count or 0,
        max_selected = set and set.max_selected or nil,
        selection_policy_id = set and set.selection_policy_id or nil,
        required_capabilities = {},
        missing_capabilities = {},
        event_truth_status = "runtime_confirmed",
    }, set
end

local function exact_collapse_run(instance, options)
    local readiness, set_or_err = choose.readiness(instance, options)
    if not readiness.ready then
        return nil, readiness.reason
    end
    local set = set_or_err
    local selected_id = set.alternative_ids[1]
    local selected_unit = canonical_field.get_unit(instance, selected_id)
    if not selected_unit then
        return nil, "selected field unit missing"
    end

    local selected_ids = {selected_id}
    local suppressed_ids = {}
    local killed_alternatives = {}
    local post_versions = {}
    for index, id in ipairs(set.alternative_ids) do
        local unit = canonical_field.get_unit(instance, id)
        if not unit or unit.version ~= set.alternative_versions[id] then
            return nil, "choice operand changed after readiness"
        end
        post_versions[id] = unit.version + 1
        if index > 1 then
            suppressed_ids[#suppressed_ids + 1] = id
            if #killed_alternatives < set.max_killed_sample then
                killed_alternatives[#killed_alternatives + 1] = exact_choice_item(
                    unit,
                    "runtime_confirmed"
                )
            end
        end
    end

    local before_count = #set.alternative_ids
    local not_chosen_count = #suppressed_ids
    local loss_amount = not_chosen_count / before_count
    local choice_loss = {
        kind = "attention_collapse",
        collapse_level = "alternative_set",
        calculation_status = "provisional_count_proxy",
        before_count = before_count,
        after_count = 1,
        not_chosen_count = not_chosen_count,
        amount = loss_amount,
        loss_percentage = loss_amount,
        truncated = not_chosen_count > #killed_alternatives,
    }
    local selected = exact_choice_item(selected_unit, "runtime_confirmed")
    local effect_scope_refs = copy_value(set.scope_refs)
    table.sort(effect_scope_refs)
    local payload = {
        kind = "choose_collapse_payload",
        mode = "alternative_collapse",
        choice_set_ref = set.choice_set_ref,
        operand_versions = copy_value(set.alternative_versions),
        selected_ids = selected_ids,
        suppressed_ids = suppressed_ids,
        post_versions = post_versions,
        before_count = before_count,
        after_count = 1,
        not_chosen_count = not_chosen_count,
        selected = {selected},
        chosen = copy_value(selected),
        killed_alternatives = killed_alternatives,
        collapse_type = "alternative_collapse",
        selection_policy_id = set.selection_policy_id,
        selection_basis_truth_status = set.selection_basis_truth_status,
        choice_basis = {
            order = "formation_order",
            selection_policy_id = set.selection_policy_id,
            truth_status = set.selection_basis_truth_status,
        },
        choice_pressure = {
            consumer_contract_id = choice_inspection.consumer_contract_id,
            choice_set_ref = set.choice_set_ref,
        },
        choice_loss = copy_value(choice_loss),
        loss = choice_loss,
        limits = {
            max_selected = set.max_selected,
            max_killed_sample = set.max_killed_sample,
        },
        effect_scope_refs = effect_scope_refs,
        truth_status = "runtime_confirmed",
        content_truth_status = set.content_truth_status,
    }

    local recorded, event_or_err = body.record_choice(instance, payload)
    if not recorded then
        return nil, event_or_err
    end
    for index, id in ipairs(set.alternative_ids) do
        local activation = index == 1 and "selected" or "suppressed"
        local changed, changed_err = canonical_field.set_activation(
            instance,
            "☳",
            id,
            activation,
            {
                event_id = event_or_err.id,
                reason = index == 1 and "chosen_alternative" or "killed_alternative",
                restamp = true,
            }
        )
        if not changed then
            return nil, changed_err
        end
        if changed.version ~= post_versions[id] then
            return nil, "choice activation version invariant failed"
        end
    end

    recorded.trace_event_id = event_or_err.id
    instance.tension.last_choice_pressure = {
        selected_count = #recorded.selected_ids,
        not_chosen_count = recorded.not_chosen_count,
        choice_set_ref = recorded.choice_set_ref,
        loss = copy_value(recorded.loss),
    }
    return instance, recorded
end

function choose.run(instance, options)
    options = options or {}
    local mutable, mutable_err = packet_core.assert_mutable(instance, "choose")
    if not mutable then
        return nil, mutable_err
    end
    if options.choice_input ~= nil then
        return exact_collapse_run(instance, options)
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
    local applied, apply_err = apply_activation_plan(instance, recorded.field_shadow, event_or_err.id)
    if not applied then
        return nil, apply_err
    end
    recorded.trace_event_id = event_or_err.id
    instance.tension.last_choice_pressure = {
        selected_count = #recorded.selected,
        not_chosen_count = recorded.not_chosen_count,
        loss = copy_value(recorded.loss),
    }

    return instance, recorded
end

return choose
