local json = require("core.json")
local field = require("runtime.field")
local structure_inspection = require("runtime.structure_inspection")

local inspection = {
    protocol_version = "choice.inspection.v0",
    consumer_contract_id = "calm.singular_focus.v0",
    selection_policy_id = "formation_order.v0",
}

local eligible_activations = {
    live = true,
    selected = true,
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

local function same_value(left, right)
    return json.encode(left) == json.encode(right)
end

local function exact_ref(id, version)
    return table.concat({"coverage", "field_unit", id, tostring(version)}, ":")
end

local function positive_integer(value, fallback, name)
    value = value == nil and fallback or value
    if type(value) ~= "number" or value < 1 or value ~= math.floor(value) then
        return nil, name .. " must be a positive integer"
    end
    return value
end

local function event_by_id(instance, id)
    for _, event in ipairs(instance.trace or {}) do
        if event.id == id then
            return event
        end
    end
    return nil
end

local function regime(instance)
    local configured = instance.regime and instance.regime.choice or {}
    local bounds = configured.bounds or {}
    local max_selected, selected_err = positive_integer(
        bounds.max_selected,
        1,
        "choice max_selected"
    )
    if not max_selected then
        return nil, selected_err
    end
    local max_killed_sample, killed_err = positive_integer(
        bounds.max_killed_sample,
        8,
        "choice max_killed_sample"
    )
    if not max_killed_sample then
        return nil, killed_err
    end
    return {
        consumer_contract_id = configured.consumer_contract_id,
        selection_policy_id = configured.policy_id,
        bounds = {
            max_selected = max_selected,
            max_killed_sample = max_killed_sample,
        },
    }
end

local function field_native_coverage(instance, options)
    options = options or {}
    local max_observations, max_err = positive_integer(
        options.max_observations,
        256,
        "choice max_observations"
    )
    if not max_observations then
        return nil, max_err
    end
    local records = instance.boundary and instance.boundary.observations
        and instance.boundary.observations.upper or {}
    local first = math.max(1, #records - max_observations + 1)
    local coverage = {}
    for index = #records, first, -1 do
        local record = records[index]
        if record.sensor == "field_native" then
            local material = false
            for _, class in ipairs(record.observation_classes or {}) do
                material = material or class == "material"
            end
            if material then
                for _, entry in ipairs(record.read_units and record.read_units.entries or {}) do
                    if coverage[entry.object_id] == nil then
                        coverage[entry.object_id] = {
                            version = entry.version,
                            observation_event_ref = record.trace_event_id,
                        }
                    end
                end
            end
        end
    end
    return coverage, first > 1
end

local function diagnostic(kind, input)
    input = input or {}
    return {
        kind = kind,
        choice_set_ref = input.choice_set_ref,
        reason = input.reason or kind,
        scope_refs = copy_value(input.scope_refs or {}),
        provenance_refs = copy_value(input.provenance_refs or {}),
        event_truth_status = "runtime_confirmed",
    }
end

local function derive_set(instance, formation_candidate, configured, coverage)
    local event = event_by_id(instance, formation_candidate.formation_event_ref)
    local formation = event and event.payload or nil
    local contract = type(formation) == "table" and formation.choice_contract or nil
    if type(contract) ~= "table" then
        return nil, diagnostic("choice_contract_missing", {
            choice_set_ref = formation_candidate.formation_event_ref,
        })
    end
    if contract.consumer_contract_id ~= configured.consumer_contract_id
        or contract.selection_policy_id ~= configured.selection_policy_id
        or contract.max_selected ~= configured.bounds.max_selected
        or contract.consumer_contract_id ~= inspection.consumer_contract_id
        or contract.selection_policy_id ~= inspection.selection_policy_id then
        return nil, diagnostic("choice_consumer_not_enabled", {
            choice_set_ref = event.id,
            provenance_refs = {event.id},
        })
    end
    if type(contract.ordered_alternative_ids) ~= "table"
        or #contract.ordered_alternative_ids == 0 then
        return nil, diagnostic("malformed_choice_contract", {
            choice_set_ref = event.id,
            provenance_refs = {event.id},
        })
    end

    local ids = {}
    local versions = {}
    local scope_refs = {}
    local observation_refs = {}
    local missing_coverage = {}
    local seen = {}
    for _, id in ipairs(contract.ordered_alternative_ids) do
        if type(id) ~= "string" or id == "" or seen[id] then
            return nil, diagnostic("malformed_choice_contract", {
                choice_set_ref = event.id,
                provenance_refs = {event.id},
            })
        end
        seen[id] = true
        local unit = field.get_unit(instance, id)
        if not unit or unit.generation ~= instance.generation then
            return nil, diagnostic("choice_set_member_missing", {
                choice_set_ref = event.id,
                scope_refs = {id},
                provenance_refs = {event.id},
            })
        end
        if eligible_activations[unit.activation] then
            ids[#ids + 1] = unit.id
            versions[unit.id] = unit.version
            local ref = exact_ref(unit.id, unit.version)
            scope_refs[#scope_refs + 1] = ref
            local covered = coverage[unit.id]
            if covered and covered.version == unit.version then
                observation_refs[#observation_refs + 1] = covered.observation_event_ref
            else
                missing_coverage[#missing_coverage + 1] = ref
            end
        end
    end

    local result = {
        choice_set_ref = event.id,
        formation_source_unit_id = formation.source and formation.source.unit_id,
        alternative_ids = ids,
        alternative_versions = versions,
        scope_refs = scope_refs,
        observation_event_refs = observation_refs,
        max_selected = contract.max_selected,
        max_killed_sample = configured.bounds.max_killed_sample,
        selection_policy_id = contract.selection_policy_id,
        selection_basis_truth_status = contract.selection_basis_truth_status,
        content_truth_status = formation.content_truth_status,
        eligible_count = #ids,
    }
    if #ids == 0 then
        return nil, diagnostic("choice_set_empty", {
            choice_set_ref = event.id,
            provenance_refs = {event.id},
        })
    end
    if #missing_coverage > 0 then
        return nil, diagnostic("choice_set_observation_missing", {
            choice_set_ref = event.id,
            scope_refs = missing_coverage,
            provenance_refs = {event.id},
        })
    end
    if #ids <= contract.max_selected then
        result.collapse_status = #ids == 1 and "confirmation" or "within_cardinality"
    else
        result.collapse_status = "missing"
    end
    return result
end

function inspection.derive(instance, options)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    options = options or {}
    local configured, regime_err = regime(instance)
    if not configured then
        return nil, regime_err
    end
    local structures, structures_err = structure_inspection.derive(
        instance,
        options.structure_bounds
    )
    if not structures then
        return nil, structures_err
    end
    local coverage, coverage_truncated = field_native_coverage(
        instance,
        options.coverage_bounds
    )
    if not coverage then
        return nil, coverage_truncated
    end

    local sets = {}
    local missing = {}
    local current = {}
    local diagnostics = {}
    for _, candidate in ipairs(structures.current or {}) do
        if candidate.requested_shape == "alternative_set" then
            local set, set_err = derive_set(instance, candidate, configured, coverage)
            if not set then
                diagnostics[#diagnostics + 1] = set_err
            else
                sets[#sets + 1] = set
                if set.collapse_status == "missing" then
                    missing[#missing + 1] = set
                else
                    current[#current + 1] = set
                end
            end
        end
    end
    table.sort(sets, function(left, right)
        return left.choice_set_ref < right.choice_set_ref
    end)
    table.sort(missing, function(left, right)
        return left.choice_set_ref < right.choice_set_ref
    end)
    table.sort(current, function(left, right)
        return left.choice_set_ref < right.choice_set_ref
    end)

    local incomplete = structures.qualification_status ~= "qualified"
        or (coverage_truncated and #diagnostics > 0)
    if incomplete then
        diagnostics[#diagnostics + 1] = diagnostic("incomplete_choice_scope")
    end
    return {
        protocol_version = inspection.protocol_version,
        sets = copy_value(sets),
        missing = copy_value(missing),
        current = copy_value(current),
        diagnostics = copy_value(diagnostics),
        qualification_status = incomplete and "incomplete_scope" or "qualified",
        event_truth_status = "runtime_confirmed",
    }
end

function inspection.resolve(instance, input)
    if type(input) ~= "table" then
        return nil, "choice_input required"
    end
    local result, result_err = inspection.derive(instance)
    if not result then
        return nil, result_err
    end
    for _, set in ipairs(result.missing) do
        if set.choice_set_ref == input.choice_set_ref then
            if not same_value(set.alternative_ids, input.alternative_ids)
                or not same_value(set.alternative_versions, input.alternative_versions)
                or set.max_selected ~= input.max_selected
                or set.max_killed_sample ~= input.max_killed_sample
                or set.selection_policy_id ~= input.selection_policy_id then
                return nil, "choice_input does not match current set"
            end
            return copy_value(set)
        end
    end
    for _, set in ipairs(result.current) do
        if set.choice_set_ref == input.choice_set_ref then
            return nil, "choice set does not require collapse"
        end
    end
    for _, item in ipairs(result.diagnostics) do
        if item.choice_set_ref == input.choice_set_ref then
            return nil, item.kind .. ":" .. tostring(item.reason)
        end
    end
    return nil, "choice set is not a current missing candidate"
end

local function sorted_refs(ids, versions)
    local refs = {}
    for _, id in ipairs(ids or {}) do
        refs[#refs + 1] = exact_ref(id, versions[id])
    end
    table.sort(refs)
    return refs
end

local function exact_post_versions(ids, versions)
    local result = {}
    for _, id in ipairs(ids or {}) do
        result[id] = versions[id] + 1
    end
    return result
end

function inspection.verify_effect(instance, plan, payload)
    if type(instance) ~= "table" then
        return nil, "choice collapse effect requires packet instance"
    end
    local input = plan and plan.options and plan.options.choose
        and plan.options.choose.choice_input
    if type(input) ~= "table"
        or type(payload) ~= "table"
        or payload.kind ~= "choose_collapse_payload"
        or payload.mode ~= "alternative_collapse"
        or payload.truth_status ~= "runtime_confirmed"
        or type(payload.trace_event_id) ~= "string"
        or payload.choice_set_ref ~= input.choice_set_ref
        or payload.selection_policy_id ~= input.selection_policy_id
        or payload.selection_basis_truth_status ~= plan.content_truth_status
        or payload.content_truth_status ~= plan.content_truth_status then
        return nil, "malformed choice collapse effect"
    end

    local ids = input.alternative_ids
    local selected_ids = {ids[1]}
    local suppressed_ids = {}
    for index = 2, #ids do
        suppressed_ids[#suppressed_ids + 1] = ids[index]
    end
    local post_versions = exact_post_versions(ids, input.alternative_versions)
    local expected_refs = sorted_refs(ids, input.alternative_versions)
    local not_chosen_count = #suppressed_ids
    local loss_amount = not_chosen_count / #ids
    local expected_sample_count = math.min(
        not_chosen_count,
        input.max_killed_sample
    )

    if not same_value(payload.operand_versions, input.alternative_versions)
        or not same_value(payload.selected_ids, selected_ids)
        or not same_value(payload.suppressed_ids, suppressed_ids)
        or not same_value(payload.post_versions, post_versions)
        or not same_value(payload.effect_scope_refs, expected_refs)
        or payload.before_count ~= #ids
        or payload.after_count ~= 1
        or payload.not_chosen_count ~= not_chosen_count
        or type(payload.killed_alternatives) ~= "table"
        or #payload.killed_alternatives ~= expected_sample_count
        or type(payload.selected) ~= "table"
        or #payload.selected ~= 1
        or payload.selected[1].id ~= ids[1]
        or type(payload.chosen) ~= "table"
        or payload.chosen.id ~= ids[1] then
        return nil, "choice collapse effect partition mismatch"
    end
    for index = 1, expected_sample_count do
        local killed = payload.killed_alternatives[index]
        if type(killed) ~= "table" or killed.id ~= suppressed_ids[index] then
            return nil, "choice collapse killed sample mismatch"
        end
    end

    local effect_loss = payload.loss
    if type(effect_loss) ~= "table"
        or effect_loss.kind ~= "attention_collapse"
        or effect_loss.calculation_status ~= "provisional_count_proxy"
        or effect_loss.before_count ~= #ids
        or effect_loss.after_count ~= 1
        or effect_loss.not_chosen_count ~= not_chosen_count
        or effect_loss.amount ~= loss_amount
        or effect_loss.loss_percentage ~= loss_amount
        or effect_loss.truncated ~= (not_chosen_count > expected_sample_count)
        or loss_amount <= 0
        or not same_value(payload.choice_loss, effect_loss) then
        return nil, "choice collapse loss mismatch"
    end

    local formation_event = event_by_id(instance, input.choice_set_ref)
    local formation_payload = formation_event and formation_event.payload or nil
    local formation_contract = type(formation_payload) == "table"
        and formation_payload.choice_contract or nil
    if not formation_event or formation_event.type ~= "structure_formation"
        or formation_event.operator ~= "☵"
        or formation_event.truth_status ~= "runtime_confirmed"
        or type(formation_contract) ~= "table"
        or formation_contract.consumer_contract_id ~= inspection.consumer_contract_id
        or formation_contract.selection_policy_id ~= input.selection_policy_id
        or formation_contract.max_selected ~= input.max_selected
        or formation_contract.selection_basis_truth_status ~= plan.content_truth_status
        or not same_value(formation_contract.ordered_alternative_ids, ids) then
        return nil, "choice collapse formation contract mismatch"
    end

    local event = event_by_id(instance, payload.trace_event_id)
    if not event or event.type ~= "choice" or event.operator ~= "☳"
        or event.truth_status ~= "runtime_confirmed"
        or type(event.payload) ~= "table" then
        return nil, "choice collapse event missing"
    end
    for _, key in ipairs({
        "kind",
        "mode",
        "choice_set_ref",
        "operand_versions",
        "selected_ids",
        "suppressed_ids",
        "post_versions",
        "before_count",
        "after_count",
        "not_chosen_count",
        "killed_alternatives",
        "selection_policy_id",
        "selection_basis_truth_status",
        "loss",
        "effect_scope_refs",
    }) do
        if not same_value(event.payload[key], payload[key]) then
            return nil, "choice collapse event payload mismatch"
        end
    end

    for index, id in ipairs(ids) do
        local unit = field.get_unit(instance, id)
        local activation = index == 1 and "selected" or "suppressed"
        local source = unit and unit.activation_source or nil
        if not unit or unit.generation ~= instance.generation
            or unit.version ~= post_versions[id]
            or unit.activation ~= activation
            or type(source) ~= "table"
            or source.event_id ~= event.id
            or source.actor ~= "☳" then
            return nil, "choice collapse activation effect mismatch"
        end
    end
    return true
end

inspection.exact_ref = exact_ref

return inspection
