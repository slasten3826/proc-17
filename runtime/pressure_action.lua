local json = require("core.json")
local topology = require("core.topology")
local field = require("runtime.field")

local action = {
    protocol_version = "pressure.action_plan.v0",
}

local mode_targets = {
    connect_probe = "☰",
    relation_formation = "☵",
    semantic_observe = "☴",
    field_native_observe = "☴",
    relation_native_observe = "☴",
}

local mode_option_roots = {
    connect_probe = "connect",
    relation_formation = "encode",
    semantic_observe = "observe",
    field_native_observe = "observe",
    relation_native_observe = "observe",
}

local mode_effect_types = {
    connect_probe = "connect_organ_payload",
    relation_formation = "encode_organ_payload",
    semantic_observe = "observe_organ_payload",
    field_native_observe = "observe_organ_payload",
    relation_native_observe = "observe_organ_payload",
}

local mergeable_modes = {
    connect_probe = true,
    relation_formation = true,
    field_native_observe = true,
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

local function sorted_unique(values, name, allow_empty)
    if type(values) ~= "table" then
        return nil, name .. " must be table"
    end
    local seen = {}
    local result = {}
    for _, value in ipairs(values) do
        if type(value) ~= "string" or value == "" then
            return nil, name .. " must contain non-empty strings"
        end
        if seen[value] then
            return nil, name .. " must not contain duplicates"
        end
        seen[value] = true
        result[#result + 1] = value
    end
    if #result == 0 and not allow_empty then
        return nil, name .. " must be non-empty"
    end
    table.sort(result)
    return result
end

local function normalize_string_array(values, name)
    return sorted_unique(values, name, false)
end

local function validate_keys(value, allowed, name)
    if type(value) ~= "table" then
        return nil, name .. " must be table"
    end
    for key in pairs(value) do
        if not allowed[key] then
            return nil, name .. " contains unknown key: " .. tostring(key)
        end
    end
    return true
end

local function normalize_versions(value, name, allow_empty)
    if type(value) ~= "table" then
        return nil, name .. " must be table"
    end
    local result = {}
    local count = 0
    for id, version in pairs(value) do
        if type(id) ~= "string" or id == ""
            or type(version) ~= "number" or version < 1
            or version ~= math.floor(version) then
            return nil, "invalid " .. name
        end
        result[id] = version
        count = count + 1
    end
    if count == 0 and not allow_empty then
        return nil, name .. " must be non-empty"
    end
    return result
end

local function versions_match_ids(ids, versions, name)
    local count = 0
    for id in pairs(versions) do
        count = count + 1
        local found = false
        for _, expected in ipairs(ids) do
            if id == expected then
                found = true
                break
            end
        end
        if not found then
            return nil, name .. " contains an unscoped object version"
        end
    end
    if count ~= #ids then
        return nil, name .. " does not cover the exact object scope"
    end
    return true
end

local function normalize_revisions(value)
    if value == nil then
        return {}
    end
    if type(value) ~= "table" then
        return nil, "action relevant_revisions must be table"
    end
    local result = {}
    for key, revision in pairs(value) do
        if type(key) ~= "string" or key == ""
            or type(revision) ~= "number" or revision < 0
            or revision ~= math.floor(revision) then
            return nil, "invalid action relevant revision"
        end
        result[key] = revision
    end
    return result
end

local function normalize_bounds(value)
    local valid, valid_err = validate_keys(value, {
        max_units = true,
        max_relations = true,
    }, "connect bounds")
    if not valid then
        return nil, valid_err
    end
    local result = {}
    for _, key in ipairs({"max_units", "max_relations"}) do
        local number = value[key]
        if type(number) ~= "number" or number < 1 or number ~= math.floor(number) then
            return nil, "connect bounds require positive integers"
        end
        result[key] = number
    end
    return result
end

local function normalize_relation_input(value)
    local valid, valid_err = validate_keys(value, {
        raw_epoch = true,
        relation_ids = true,
        endpoint_versions = true,
        source_event_refs = true,
        requested_shape = true,
    }, "relation_input")
    if not valid then
        return nil, valid_err
    end
    if type(value.raw_epoch) ~= "number" or value.raw_epoch < 1
        or value.raw_epoch ~= math.floor(value.raw_epoch) then
        return nil, "relation_input raw_epoch must be a positive integer"
    end
    local relation_ids, ids_err = normalize_string_array(
        value.relation_ids,
        "relation_input relation_ids"
    )
    if not relation_ids then
        return nil, ids_err
    end
    local endpoint_versions, versions_err = normalize_versions(
        value.endpoint_versions,
        "relation_input endpoint_versions",
        false
    )
    if not endpoint_versions then
        return nil, versions_err
    end
    local source_event_refs = {}
    if value.source_event_refs ~= nil then
        local refs_err
        source_event_refs, refs_err = sorted_unique(
            value.source_event_refs,
            "relation_input source_event_refs",
            true
        )
        if not source_event_refs then
            return nil, refs_err
        end
    end
    if value.requested_shape ~= nil
        and (type(value.requested_shape) ~= "string" or value.requested_shape == "") then
        return nil, "relation_input requested_shape must be non-empty string"
    end
    return {
        raw_epoch = value.raw_epoch,
        relation_ids = relation_ids,
        endpoint_versions = endpoint_versions,
        source_event_refs = source_event_refs,
        requested_shape = value.requested_shape,
    }
end

local function normalize_options(mode, options)
    local root = mode_option_roots[mode]
    local root_valid, root_err = validate_keys(options, {[root] = true}, "action options")
    if not root_valid then
        return nil, root_err
    end
    local configured = options[root]
    if type(configured) ~= "table" then
        return nil, "action options require " .. root
    end

    if mode == "connect_probe" then
        local valid, valid_err = validate_keys(configured, {
            policy_id = true,
            unit_ids = true,
            unit_versions = true,
            bounds = true,
        }, "connect action")
        if not valid then
            return nil, valid_err
        end
        if type(configured.policy_id) ~= "string" or configured.policy_id == "" then
            return nil, "connect action policy_id required"
        end
        local ids, ids_err = normalize_string_array(configured.unit_ids, "connect unit_ids")
        if not ids then
            return nil, ids_err
        end
        local versions, versions_err = normalize_versions(
            configured.unit_versions,
            "connect unit_versions",
            false
        )
        if not versions then
            return nil, versions_err
        end
        local exact, exact_err = versions_match_ids(ids, versions, "connect unit_versions")
        if not exact then
            return nil, exact_err
        end
        local bounds, bounds_err = normalize_bounds(configured.bounds)
        if not bounds then
            return nil, bounds_err
        end
        return {connect = {
            policy_id = configured.policy_id,
            unit_ids = ids,
            unit_versions = versions,
            bounds = bounds,
        }}
    end

    if mode == "relation_formation" then
        local valid, valid_err = validate_keys(configured, {
            relation_input = true,
        }, "encode action")
        if not valid then
            return nil, valid_err
        end
        local input, input_err = normalize_relation_input(configured.relation_input)
        if not input then
            return nil, input_err
        end
        return {encode = {relation_input = input}}
    end

    if mode == "semantic_observe" or mode == "field_native_observe" then
        local valid, valid_err = validate_keys(configured, {
            sensor = true,
            unit_ids = true,
            unit_versions = true,
        }, "observe action")
        if not valid then
            return nil, valid_err
        end
        local expected_sensor = mode == "semantic_observe" and "semantic" or "field_native"
        if configured.sensor ~= expected_sensor then
            return nil, "observe action sensor does not match mode"
        end
        local ids, ids_err = normalize_string_array(configured.unit_ids, "observe unit_ids")
        if not ids then
            return nil, ids_err
        end
        local versions, versions_err = normalize_versions(
            configured.unit_versions,
            "observe unit_versions",
            false
        )
        if not versions then
            return nil, versions_err
        end
        local exact, exact_err = versions_match_ids(ids, versions, "observe unit_versions")
        if not exact then
            return nil, exact_err
        end
        return {observe = {
            sensor = expected_sensor,
            unit_ids = ids,
            unit_versions = versions,
        }}
    end

    local valid, valid_err = validate_keys(configured, {
        sensor = true,
        relation_input = true,
    }, "relation-native observe action")
    if not valid then
        return nil, valid_err
    end
    if configured.sensor ~= "relation_native" then
        return nil, "relation-native action requires relation_native sensor"
    end
    local relation_input, input_err = normalize_relation_input(configured.relation_input)
    if not relation_input then
        return nil, input_err
    end
    return {observe = {
        sensor = "relation_native",
        relation_input = relation_input,
    }}
end

local function normalize_preconditions(value)
    local valid, valid_err = validate_keys(value, {
        packet_id = true,
        generation = true,
        object_versions = true,
        raw_epoch = true,
        relevant_revisions = true,
    }, "action preconditions")
    if not valid then
        return nil, valid_err
    end
    if type(value.packet_id) ~= "string" or value.packet_id == "" then
        return nil, "action precondition packet_id required"
    end
    if type(value.generation) ~= "number" or value.generation < 1
        or value.generation ~= math.floor(value.generation) then
        return nil, "action precondition generation must be positive integer"
    end
    local versions, versions_err = normalize_versions(
        value.object_versions or {},
        "action object_versions",
        true
    )
    if not versions then
        return nil, versions_err
    end
    if value.raw_epoch ~= nil and (type(value.raw_epoch) ~= "number"
        or value.raw_epoch < 1 or value.raw_epoch ~= math.floor(value.raw_epoch)) then
        return nil, "action raw_epoch must be positive integer"
    end
    local revisions, revisions_err = normalize_revisions(value.relevant_revisions)
    if not revisions then
        return nil, revisions_err
    end
    return {
        packet_id = value.packet_id,
        generation = value.generation,
        object_versions = versions,
        raw_epoch = value.raw_epoch,
        relevant_revisions = revisions,
    }
end

local function plan_identity(plan)
    return "pressure-action:" .. json.encode({
        protocol_version = plan.protocol_version,
        witness_id = plan.witness_id,
        target_operator = plan.target_operator,
        mode = plan.mode,
        scope_refs = plan.scope_refs,
        provenance_refs = plan.provenance_refs,
        preconditions = plan.preconditions,
        options = plan.options,
        expected_effect = plan.expected_effect,
        event_truth_status = plan.event_truth_status,
        content_truth_status = plan.content_truth_status,
    })
end

function action.build(mode, input)
    input = input or {}
    local target = mode_targets[mode]
    if not target then
        return nil, "unknown pressure action mode"
    end
    local requested_target = topology.resolve(input.target_operator or target)
    if requested_target ~= target then
        return nil, "pressure action mode/target mismatch"
    end
    if type(input.witness_id) ~= "string" or input.witness_id == "" then
        return nil, "pressure action witness_id required"
    end
    local scope_refs, scope_err = sorted_unique(input.scope_refs, "action scope_refs", false)
    if not scope_refs then
        return nil, scope_err
    end
    local provenance_refs, provenance_err = sorted_unique(
        input.provenance_refs or {},
        "action provenance_refs",
        true
    )
    if not provenance_refs then
        return nil, provenance_err
    end
    local preconditions, preconditions_err = normalize_preconditions(input.preconditions or {})
    if not preconditions then
        return nil, preconditions_err
    end
    local options, options_err = normalize_options(mode, input.options or {})
    if not options then
        return nil, options_err
    end

    local expected_input = input.expected_effect or {}
    local expected_valid, expected_err = validate_keys(expected_input, {
        event_type = true,
        scope_refs = true,
        discharge_reader = true,
    }, "expected effect")
    if not expected_valid then
        return nil, expected_err
    end
    local expected_scope, expected_scope_err = sorted_unique(
        expected_input.scope_refs or scope_refs,
        "expected effect scope_refs",
        false
    )
    if not expected_scope then
        return nil, expected_scope_err
    end
    if not same_value(expected_scope, scope_refs) then
        return nil, "expected effect scope differs from action scope"
    end
    local event_type = expected_input.event_type or mode_effect_types[mode]
    local discharge_reader = expected_input.discharge_reader
    if type(event_type) ~= "string" or event_type == ""
        or type(discharge_reader) ~= "string" or discharge_reader == "" then
        return nil, "pressure action expected effect contract required"
    end
    local content_truth_status = input.content_truth_status or "unknown"
    if type(content_truth_status) ~= "string" or content_truth_status == "" then
        return nil, "pressure action content truth status required"
    end

    local plan = {
        protocol_version = action.protocol_version,
        witness_id = input.witness_id,
        target_operator = target,
        mode = mode,
        scope_refs = scope_refs,
        provenance_refs = provenance_refs,
        preconditions = preconditions,
        options = options,
        expected_effect = {
            event_type = event_type,
            scope_refs = expected_scope,
            discharge_reader = discharge_reader,
        },
        event_truth_status = "runtime_confirmed",
        content_truth_status = content_truth_status,
    }
    plan.plan_id = plan_identity(plan)
    return copy_value(plan)
end

function action.validate(plan)
    local keys_ok, keys_err = validate_keys(plan, {
        protocol_version = true,
        plan_id = true,
        witness_id = true,
        target_operator = true,
        mode = true,
        scope_refs = true,
        provenance_refs = true,
        preconditions = true,
        options = true,
        expected_effect = true,
        event_truth_status = true,
        content_truth_status = true,
    }, "pressure action plan")
    if not keys_ok then
        return nil, keys_err
    end
    if plan.protocol_version ~= action.protocol_version
        or type(plan.plan_id) ~= "string" or plan.plan_id == ""
        or type(plan.witness_id) ~= "string" or plan.witness_id == ""
        or plan.event_truth_status ~= "runtime_confirmed"
        or type(plan.content_truth_status) ~= "string" or plan.content_truth_status == "" then
        return nil, "invalid pressure action plan"
    end
    if mode_targets[plan.mode] ~= topology.resolve(plan.target_operator) then
        return nil, "pressure action mode/target mismatch"
    end
    local scope_refs, scope_err = sorted_unique(plan.scope_refs, "action scope_refs", false)
    if not scope_refs then
        return nil, scope_err
    end
    local provenance_refs, provenance_err = sorted_unique(
        plan.provenance_refs or {},
        "action provenance_refs",
        true
    )
    if not provenance_refs then
        return nil, provenance_err
    end
    if not same_value(scope_refs, plan.scope_refs)
        or not same_value(provenance_refs, plan.provenance_refs) then
        return nil, "pressure action refs are not canonical"
    end
    local preconditions, preconditions_err = normalize_preconditions(plan.preconditions or {})
    if not preconditions then
        return nil, preconditions_err
    end
    local options, options_err = normalize_options(plan.mode, plan.options or {})
    if not options then
        return nil, options_err
    end
    if not same_value(preconditions, plan.preconditions)
        or not same_value(options, plan.options) then
        return nil, "pressure action body is not canonical"
    end
    local expected = plan.expected_effect or {}
    local expected_valid, expected_err = validate_keys(expected, {
        event_type = true,
        scope_refs = true,
        discharge_reader = true,
    }, "expected effect")
    if not expected_valid then
        return nil, expected_err
    end
    local effect_scope, effect_scope_err = sorted_unique(
        expected.scope_refs,
        "expected effect scope_refs",
        false
    )
    if not effect_scope then
        return nil, effect_scope_err
    end
    if not same_value(effect_scope, plan.scope_refs)
        or type(expected.event_type) ~= "string" or expected.event_type == ""
        or type(expected.discharge_reader) ~= "string" or expected.discharge_reader == "" then
        return nil, "invalid pressure action effect contract"
    end
    if plan.plan_id ~= plan_identity(plan) then
        return nil, "pressure action plan_id mismatch"
    end
    return true
end

function action.same(left, right)
    local left_ok = action.validate(left)
    local right_ok = action.validate(right)
    return left_ok == true and right_ok == true and left.plan_id == right.plan_id
end

local function merge_versions(left, right)
    local result = copy_value(left or {})
    for id, version in pairs(right or {}) do
        if result[id] ~= nil and result[id] ~= version then
            return nil, "ambiguous_action: incompatible object versions"
        end
        result[id] = version
    end
    return result
end

local function merge_arrays(left, right)
    local values = {}
    for _, value in ipairs(left or {}) do
        values[#values + 1] = value
    end
    for _, value in ipairs(right or {}) do
        values[#values + 1] = value
    end
    local seen = {}
    local result = {}
    for _, value in ipairs(values) do
        if not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

function action.merge(left, right)
    local left_ok, left_err = action.validate(left)
    if not left_ok then
        return nil, left_err
    end
    local right_ok, right_err = action.validate(right)
    if not right_ok then
        return nil, right_err
    end
    if action.same(left, right) then
        return copy_value(left)
    end
    if left.target_operator ~= right.target_operator or left.mode ~= right.mode
        or not mergeable_modes[left.mode] then
        return nil, "ambiguous_action"
    end
    if left.preconditions.packet_id ~= right.preconditions.packet_id
        or left.preconditions.generation ~= right.preconditions.generation
        or left.preconditions.raw_epoch ~= right.preconditions.raw_epoch
        or not same_value(
            left.preconditions.relevant_revisions,
            right.preconditions.relevant_revisions
        ) then
        return nil, "ambiguous_action: incompatible preconditions"
    end
    if left.expected_effect.event_type ~= right.expected_effect.event_type
        or left.expected_effect.discharge_reader ~= right.expected_effect.discharge_reader then
        return nil, "ambiguous_action: incompatible effect contract"
    end
    local object_versions, versions_err = merge_versions(
        left.preconditions.object_versions,
        right.preconditions.object_versions
    )
    if not object_versions then
        return nil, versions_err
    end

    local options
    if left.mode == "connect_probe" then
        local l = left.options.connect
        local r = right.options.connect
        if l.policy_id ~= r.policy_id or not same_value(l.bounds, r.bounds) then
            return nil, "ambiguous_action: incompatible connect policy"
        end
        local unit_versions, unit_err = merge_versions(l.unit_versions, r.unit_versions)
        if not unit_versions then
            return nil, unit_err
        end
        options = {connect = {
            policy_id = l.policy_id,
            bounds = copy_value(l.bounds),
            unit_ids = merge_arrays(l.unit_ids, r.unit_ids),
            unit_versions = unit_versions,
        }}
    elseif left.mode == "relation_formation" then
        local l = left.options.encode.relation_input
        local r = right.options.encode.relation_input
        if l.raw_epoch ~= r.raw_epoch or l.requested_shape ~= r.requested_shape then
            return nil, "ambiguous_action: incompatible relation epoch"
        end
        local endpoint_versions, endpoint_err = merge_versions(
            l.endpoint_versions,
            r.endpoint_versions
        )
        if not endpoint_versions then
            return nil, endpoint_err
        end
        options = {encode = {relation_input = {
            raw_epoch = l.raw_epoch,
            relation_ids = merge_arrays(l.relation_ids, r.relation_ids),
            endpoint_versions = endpoint_versions,
            source_event_refs = merge_arrays(l.source_event_refs, r.source_event_refs),
            requested_shape = l.requested_shape,
        }}}
    else
        local l = left.options.observe
        local r = right.options.observe
        local unit_versions, unit_err = merge_versions(l.unit_versions, r.unit_versions)
        if not unit_versions then
            return nil, unit_err
        end
        options = {observe = {
            sensor = "field_native",
            unit_ids = merge_arrays(l.unit_ids, r.unit_ids),
            unit_versions = unit_versions,
        }}
    end

    local witness_ids = merge_arrays({left.witness_id}, {right.witness_id})
    local merged_witness_id = "merged-witness:" .. json.encode(witness_ids)
    return action.build(left.mode, {
        witness_id = merged_witness_id,
        target_operator = left.target_operator,
        scope_refs = merge_arrays(left.scope_refs, right.scope_refs),
        provenance_refs = merge_arrays(left.provenance_refs, right.provenance_refs),
        preconditions = {
            packet_id = left.preconditions.packet_id,
            generation = left.preconditions.generation,
            object_versions = object_versions,
            raw_epoch = left.preconditions.raw_epoch,
            relevant_revisions = copy_value(left.preconditions.relevant_revisions),
        },
        options = options,
        expected_effect = {
            event_type = left.expected_effect.event_type,
            scope_refs = merge_arrays(left.scope_refs, right.scope_refs),
            discharge_reader = left.expected_effect.discharge_reader,
        },
        content_truth_status = left.content_truth_status == right.content_truth_status
            and left.content_truth_status or "mixed",
    })
end

function action.verify_preconditions(plan, instance)
    local valid, valid_err = action.validate(plan)
    if not valid then
        return nil, valid_err
    end
    if type(instance) ~= "table" or instance.id ~= plan.preconditions.packet_id
        or instance.generation ~= plan.preconditions.generation then
        return nil, "pressure action packet precondition mismatch"
    end
    for id, version in pairs(plan.preconditions.object_versions) do
        local unit = field.get_unit(instance, id)
        if not unit or unit.version ~= version then
            return nil, "pressure action object version precondition mismatch"
        end
    end
    if plan.preconditions.raw_epoch ~= nil then
        local raw = instance.field and instance.field.relations
            and instance.field.relations.raw or {}
        if raw.epoch ~= plan.preconditions.raw_epoch then
            return nil, "pressure action raw epoch precondition mismatch"
        end
    end
    for component, revision in pairs(plan.preconditions.relevant_revisions) do
        if not instance.revisions or instance.revisions[component] ~= revision then
            return nil, "pressure action revision precondition mismatch"
        end
    end
    return true
end

function action.registry_context(plan, base_context)
    local valid, valid_err = action.validate(plan)
    if not valid then
        return nil, valid_err
    end
    base_context = base_context or {}
    if type(base_context.instance) ~= "table" then
        return nil, "pressure action registry context requires packet instance"
    end
    local preconditions_ok, preconditions_err = action.verify_preconditions(
        plan,
        base_context.instance
    )
    if not preconditions_ok then
        return nil, preconditions_err
    end
    local context = {}
    for key, value in pairs(base_context) do
        if key ~= "instance" and key ~= "options" then
            context[key] = value
        end
    end
    local options = copy_value(base_context.options or {})
    local root = mode_option_roots[plan.mode]
    if type(options[root]) == "table" and next(options[root]) ~= nil then
        return nil, "caller options override action-owned scope"
    end
    options[root] = copy_value(plan.options[root])
    options[root].qualified_action = {
        plan_id = plan.plan_id,
        scope_refs = copy_value(plan.scope_refs),
    }
    context.options = options
    context.qualified_action_plan = copy_value(plan)
    context.instance = nil
    return context
end

function action.verify_readiness(plan, readiness)
    local valid, valid_err = action.validate(plan)
    if not valid then
        return nil, valid_err
    end
    if type(readiness) ~= "table" or readiness.ready ~= true
        or topology.resolve(readiness.operator) ~= plan.target_operator then
        return nil, "pressure action readiness is not executable"
    end
    local refs, refs_err = sorted_unique(
        readiness.source_refs or {},
        "readiness scope_refs",
        false
    )
    if not refs then
        return nil, refs_err
    end
    if not same_value(refs, plan.scope_refs) then
        return nil, "pressure action readiness scope mismatch"
    end
    return true
end

function action.verify_effect(plan, payload)
    local valid, valid_err = action.validate(plan)
    if not valid then
        return nil, valid_err
    end
    if type(payload) ~= "table" or payload.kind ~= plan.expected_effect.event_type then
        return nil, "pressure action effect type mismatch"
    end
    local refs, refs_err = sorted_unique(
        payload.effect_scope_refs or {},
        "effect scope_refs",
        false
    )
    if not refs then
        return nil, refs_err
    end
    if not same_value(refs, plan.scope_refs) then
        return nil, "pressure action effect scope mismatch"
    end
    return true
end

action.mode_targets = copy_value(mode_targets)

return action
