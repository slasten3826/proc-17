local json = require("core.json")
local topology = require("core.topology")
local field = require("runtime.field")
local choice_inspection = require("runtime.choice_inspection")
local plan_completion = require("runtime.plan_completion")
local structure_inspection = require("runtime.structure_inspection")
local repository_action = require("runtime.repository_action")

local action = {
    protocol_version = "pressure.action_plan.v0",
}

local mode_targets = {
    connect_probe = "☰",
    relation_formation = "☵",
    structure_formation = "☵",
    alternative_collapse = "☳",
    plan_completion_review = "☱",
    plan_delivery = "△",
    semantic_observe = "☴",
    field_native_observe = "☴",
    relation_native_observe = "☴",
    repository_action_review = "☱",
    repository_effect = "☶",
    repository_reconcile = "☱",
}

local mode_option_roots = {
    connect_probe = "connect",
    relation_formation = "encode",
    structure_formation = "encode",
    alternative_collapse = "choose",
    plan_completion_review = "runtime",
    plan_delivery = "manifest",
    semantic_observe = "observe",
    field_native_observe = "observe",
    relation_native_observe = "observe",
    repository_action_review = "runtime",
    repository_effect = "logic",
    repository_reconcile = "runtime",
}

local mode_effect_types = {
    connect_probe = "connect_organ_payload",
    relation_formation = "encode_organ_payload",
    structure_formation = "encode_organ_payload",
    alternative_collapse = "choose_collapse_payload",
    plan_completion_review = "runtime_eye_payload",
    plan_delivery = "manifest_payload",
    semantic_observe = "observe_organ_payload",
    field_native_observe = "observe_organ_payload",
    relation_native_observe = "observe_organ_payload",
    repository_action_review = "runtime_eye_payload",
    repository_effect = "logic_validation_payload",
    repository_reconcile = "runtime_eye_payload",
}

local repository_option_keys = {
    repository_action_review = "repository_action_review",
    repository_effect = "repository_effect",
    repository_reconcile = "repository_reconcile",
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

local function normalize_ordered_string_array(values, name)
    if type(values) ~= "table" or #values == 0 then
        return nil, name .. " must be non-empty table"
    end
    local result = {}
    local seen = {}
    for index, value in ipairs(values) do
        if type(value) ~= "string" or value == "" or seen[value] then
            return nil, name .. " must contain unique non-empty strings"
        end
        seen[value] = true
        result[index] = value
    end
    for key in pairs(values) do
        if type(key) ~= "number" or key < 1 or key > #result
            or key ~= math.floor(key) then
            return nil, name .. " must be an array"
        end
    end
    return result
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

local function exact_unit_ref(id, version)
    return table.concat({"coverage", "field_unit", id, tostring(version)}, ":")
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

local function normalize_structure_bounds(value)
    local valid, valid_err = validate_keys(value, {
        max_output_units = true,
        max_loss_log_entries = true,
    }, "structure formation bounds")
    if not valid then
        return nil, valid_err
    end
    local result = {}
    for _, key in ipairs({"max_output_units", "max_loss_log_entries"}) do
        local number = value[key]
        if type(number) ~= "number" or number < 1 or number ~= math.floor(number) then
            return nil, "structure formation bounds require positive integers"
        end
        result[key] = number
    end
    return result
end

local function normalize_structure_input(value)
    local valid, valid_err = validate_keys(value, {
        source_unit_id = true,
        source_version = true,
        envelope_fingerprint = true,
        receiver_contract_id = true,
        requested_shape = true,
        adapter_policy_id = true,
        bounds = true,
    }, "structure_input")
    if not valid then
        return nil, valid_err
    end
    if type(value.source_unit_id) ~= "string" or value.source_unit_id == ""
        or type(value.source_version) ~= "number" or value.source_version < 1
        or value.source_version ~= math.floor(value.source_version)
        or type(value.envelope_fingerprint) ~= "string"
        or value.envelope_fingerprint == "" then
        return nil, "structure_input requires exact source identity"
    end
    if value.receiver_contract_id ~= structure_inspection.receiver_contract_id
        or value.adapter_policy_id ~= structure_inspection.adapter_policy_id
        or not structure_inspection.accepted_shapes[value.requested_shape] then
        return nil, "structure_input names unsupported body contract"
    end
    local bounds, bounds_err = normalize_structure_bounds(value.bounds)
    if not bounds then
        return nil, bounds_err
    end
    return {
        source_unit_id = value.source_unit_id,
        source_version = value.source_version,
        envelope_fingerprint = value.envelope_fingerprint,
        receiver_contract_id = value.receiver_contract_id,
        requested_shape = value.requested_shape,
        adapter_policy_id = value.adapter_policy_id,
        bounds = bounds,
    }
end

local function normalize_choice_input(value)
    local valid, valid_err = validate_keys(value, {
        choice_set_ref = true,
        alternative_ids = true,
        alternative_versions = true,
        max_selected = true,
        selection_policy_id = true,
        max_killed_sample = true,
    }, "choice_input")
    if not valid then
        return nil, valid_err
    end
    if type(value.choice_set_ref) ~= "string" or value.choice_set_ref == "" then
        return nil, "choice_input choice_set_ref required"
    end
    local ids, ids_err = normalize_ordered_string_array(
        value.alternative_ids,
        "choice_input alternative_ids"
    )
    if not ids then
        return nil, ids_err
    end
    local versions, versions_err = normalize_versions(
        value.alternative_versions,
        "choice_input alternative_versions",
        false
    )
    if not versions then
        return nil, versions_err
    end
    local exact, exact_err = versions_match_ids(
        ids,
        versions,
        "choice_input alternative_versions"
    )
    if not exact then
        return nil, exact_err
    end
    if value.max_selected ~= 1
        or value.selection_policy_id ~= choice_inspection.selection_policy_id
        or type(value.max_killed_sample) ~= "number"
        or value.max_killed_sample < 1
        or value.max_killed_sample ~= math.floor(value.max_killed_sample) then
        return nil, "choice_input names unsupported collapse policy"
    end
    return {
        choice_set_ref = value.choice_set_ref,
        alternative_ids = ids,
        alternative_versions = versions,
        max_selected = 1,
        selection_policy_id = value.selection_policy_id,
        max_killed_sample = value.max_killed_sample,
    }
end

local function normalize_plan_material_identity(value, name)
    if type(value) ~= "table" then
        return nil, name .. " must be table"
    end
    if type(value.candidate_id) ~= "string" or value.candidate_id == ""
        or type(value.formation_event_ref) ~= "string"
        or value.formation_event_ref == "" then
        return nil, name .. " requires candidate and formation identity"
    end
    local ids, ids_err = normalize_ordered_string_array(
        value.formed_unit_ids,
        name .. " formed_unit_ids"
    )
    if not ids then
        return nil, ids_err
    end
    local versions, versions_err = normalize_versions(
        value.formed_unit_versions,
        name .. " formed_unit_versions",
        false
    )
    if not versions then
        return nil, versions_err
    end
    local exact, exact_err = versions_match_ids(
        ids,
        versions,
        name .. " formed_unit_versions"
    )
    if not exact then
        return nil, exact_err
    end
    local coverage_refs, coverage_err = normalize_string_array(
        value.coverage_event_refs,
        name .. " coverage_event_refs"
    )
    if not coverage_refs then
        return nil, coverage_err
    end
    if value.choice_event_ref ~= nil
        and (type(value.choice_event_ref) ~= "string"
            or value.choice_event_ref == "") then
        return nil, name .. " choice_event_ref must be non-empty string"
    end
    return {
        candidate_id = value.candidate_id,
        formation_event_ref = value.formation_event_ref,
        formed_unit_ids = ids,
        formed_unit_versions = versions,
        coverage_event_refs = coverage_refs,
        choice_event_ref = value.choice_event_ref,
    }
end

local function normalize_plan_completion_input(value)
    local valid, valid_err = validate_keys(value, {
        candidate_id = true,
        formation_event_ref = true,
        formed_unit_ids = true,
        formed_unit_versions = true,
        coverage_event_refs = true,
        choice_event_ref = true,
        through_seq = true,
        significant_frame_refs = true,
    }, "plan_completion_input")
    if not valid then
        return nil, valid_err
    end
    local identity, identity_err = normalize_plan_material_identity(
        value,
        "plan_completion_input"
    )
    if not identity then
        return nil, identity_err
    end
    if type(value.through_seq) ~= "number" or value.through_seq < 1
        or value.through_seq ~= math.floor(value.through_seq) then
        return nil, "plan_completion_input through_seq must be positive integer"
    end
    local frame_refs, frames_err = normalize_string_array(
        value.significant_frame_refs,
        "plan_completion_input significant_frame_refs"
    )
    if not frame_refs then
        return nil, frames_err
    end
    identity.through_seq = value.through_seq
    identity.significant_frame_refs = frame_refs
    return identity
end

local function normalize_plan_input(value)
    local valid, valid_err = validate_keys(value, {
        assessment_event_ref = true,
        assessment_id = true,
        candidate_id = true,
        formation_event_ref = true,
        formed_unit_ids = true,
        formed_unit_versions = true,
        coverage_event_refs = true,
        choice_event_ref = true,
    }, "plan_input")
    if not valid then
        return nil, valid_err
    end
    if type(value.assessment_event_ref) ~= "string"
        or value.assessment_event_ref == ""
        or type(value.assessment_id) ~= "string" or value.assessment_id == "" then
        return nil, "plan_input requires assessment identity"
    end
    local identity, identity_err = normalize_plan_material_identity(
        value,
        "plan_input"
    )
    if not identity then
        return nil, identity_err
    end
    identity.assessment_event_ref = value.assessment_event_ref
    identity.assessment_id = value.assessment_id
    return identity
end

local function normalize_repository_input(value, mode)
    local valid, valid_err = validate_keys(value, {
        action = true,
        action_id = true,
        work_unit_id = true,
        work_unit_version = true,
        formation_event_ref = true,
        grant_id = true,
        grant_revision = true,
        evidence_refs = true,
    }, "repository_input")
    if not valid then
        return nil, valid_err
    end
    local action_ok, action_err = repository_action.validate_projection(value.action)
    if not action_ok then
        return nil, action_err
    end
    local action_value = value.action
    if value.action_id ~= action_value.action_id
        or value.work_unit_id ~= action_value.work_unit.id
        or value.work_unit_version ~= action_value.work_unit.version
        or value.formation_event_ref ~= action_value.work_unit.formation_event_ref
        or value.grant_id ~= action_value.capability.grant_id
        or value.grant_revision ~= action_value.capability.revision then
        return nil, "repository_input identity does not match action"
    end
    local evidence_refs, evidence_err = sorted_unique(
        value.evidence_refs or {},
        "repository_input evidence_refs",
        true
    )
    if not evidence_refs then
        return nil, evidence_err
    end
    if mode == "repository_action_review" and #evidence_refs ~= 0 then
        return nil, "repository action review begins without effect evidence"
    end
    if mode ~= "repository_action_review" and #evidence_refs == 0 then
        return nil, mode .. " requires evidence refs"
    end
    return {
        action = copy_value(action_value),
        action_id = value.action_id,
        work_unit_id = value.work_unit_id,
        work_unit_version = value.work_unit_version,
        formation_event_ref = value.formation_event_ref,
        grant_id = value.grant_id,
        grant_revision = value.grant_revision,
        evidence_refs = evidence_refs,
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

    local repository_key = repository_option_keys[mode]
    if repository_key then
        local valid, valid_err = validate_keys(
            configured,
            {[repository_key] = true},
            "repository " .. mode .. " action"
        )
        if not valid then
            return nil, valid_err
        end
        local input, input_err = normalize_repository_input(
            configured[repository_key],
            mode
        )
        if not input then
            return nil, input_err
        end
        return {[root] = {[repository_key] = input}}
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

    if mode == "structure_formation" then
        local valid, valid_err = validate_keys(configured, {
            structure_input = true,
        }, "structure formation action")
        if not valid then
            return nil, valid_err
        end
        local input, input_err = normalize_structure_input(configured.structure_input)
        if not input then
            return nil, input_err
        end
        return {encode = {structure_input = input}}
    end

    if mode == "alternative_collapse" then
        local valid, valid_err = validate_keys(configured, {
            choice_input = true,
        }, "alternative collapse action")
        if not valid then
            return nil, valid_err
        end
        local input, input_err = normalize_choice_input(configured.choice_input)
        if not input then
            return nil, input_err
        end
        return {choose = {choice_input = input}}
    end

    if mode == "plan_completion_review" then
        local valid, valid_err = validate_keys(configured, {
            plan_completion_input = true,
        }, "runtime plan completion action")
        if not valid then
            return nil, valid_err
        end
        local input, input_err = normalize_plan_completion_input(
            configured.plan_completion_input
        )
        if not input then
            return nil, input_err
        end
        return {runtime = {plan_completion_input = input}}
    end

    if mode == "plan_delivery" then
        local valid, valid_err = validate_keys(configured, {
            plan_input = true,
        }, "manifest plan delivery action")
        if not valid then
            return nil, valid_err
        end
        local input, input_err = normalize_plan_input(configured.plan_input)
        if not input then
            return nil, input_err
        end
        return {manifest = {plan_input = input}}
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

local function validate_mode_contract(mode, scope_refs, preconditions, options)
    local repository_key = repository_option_keys[mode]
    if repository_key then
        local root = mode_option_roots[mode]
        local input = options[root][repository_key]
        local expected_refs = copy_value(input.action.scope_refs)
        expected_refs[#expected_refs + 1] = input.action_id
        table.sort(expected_refs)
        if not same_value(scope_refs, expected_refs) then
            return nil, mode .. " requires exact work/action scope"
        end
        local version_count = 0
        for _ in pairs(preconditions.object_versions) do
            version_count = version_count + 1
        end
        if version_count ~= 1
            or preconditions.object_versions[input.work_unit_id]
                ~= input.work_unit_version then
            return nil, mode .. " requires one exact work version"
        end
        if preconditions.raw_epoch ~= nil
            or next(preconditions.relevant_revisions) ~= nil then
            return nil, mode .. " preconditions exceed exact action scope"
        end
        return true
    end
    if mode ~= "structure_formation" and mode ~= "alternative_collapse"
        and mode ~= "plan_completion_review" and mode ~= "plan_delivery" then
        return true
    end

    if mode == "plan_completion_review" or mode == "plan_delivery" then
        local input = mode == "plan_completion_review"
            and options.runtime.plan_completion_input or options.manifest.plan_input
        local exact, exact_err = versions_match_ids(
            input.formed_unit_ids,
            preconditions.object_versions,
            mode .. " object_versions"
        )
        if not exact then
            return nil, exact_err
        end
        if not same_value(preconditions.object_versions, input.formed_unit_versions)
            or preconditions.raw_epoch ~= nil then
            return nil, mode .. " precondition mismatch"
        end
        local scoped = {}
        for _, ref in ipairs(scope_refs) do
            scoped[ref] = true
        end
        for _, id in ipairs(input.formed_unit_ids) do
            if not scoped[exact_unit_ref(id, input.formed_unit_versions[id])] then
                return nil, mode .. " requires exact formed unit scope"
            end
        end
        if mode == "plan_completion_review" then
            for _, ref in ipairs(input.significant_frame_refs) do
                if not scoped[ref] then
                    return nil, "plan completion review requires frame scope"
                end
            end
        else
            local expected = {input.assessment_event_ref}
            for _, id in ipairs(input.formed_unit_ids) do
                expected[#expected + 1] = exact_unit_ref(
                    id,
                    input.formed_unit_versions[id]
                )
            end
            table.sort(expected)
            if not same_value(expected, scope_refs) then
                return nil, "plan delivery requires exact assessment/material scope"
            end
        end
        return true
    end


    if mode == "alternative_collapse" then
        local input = options.choose.choice_input
        local expected_refs = {}
        for _, id in ipairs(input.alternative_ids) do
            expected_refs[#expected_refs + 1] = exact_unit_ref(
                id,
                input.alternative_versions[id]
            )
        end
        table.sort(expected_refs)
        if not same_value(scope_refs, expected_refs) then
            return nil, "alternative collapse action requires exact operand scope"
        end
        local exact, exact_err = versions_match_ids(
            input.alternative_ids,
            preconditions.object_versions,
            "alternative collapse object_versions"
        )
        if not exact then
            return nil, exact_err
        end
        if not same_value(preconditions.object_versions, input.alternative_versions) then
            return nil, "alternative collapse version precondition mismatch"
        end
        if preconditions.raw_epoch ~= nil or next(preconditions.relevant_revisions) ~= nil then
            return nil, "alternative collapse preconditions exceed exact operand scope"
        end
        return true
    end

    local input = options.encode.structure_input
    local expected_ref = exact_unit_ref(input.source_unit_id, input.source_version)
    if #scope_refs ~= 1 or scope_refs[1] ~= expected_ref then
        return nil, "structure formation action requires exact source scope"
    end
    local exact, exact_err = versions_match_ids(
        {input.source_unit_id},
        preconditions.object_versions,
        "structure formation object_versions"
    )
    if not exact then
        return nil, exact_err
    end
    if preconditions.object_versions[input.source_unit_id] ~= input.source_version then
        return nil, "structure formation source version precondition mismatch"
    end
    if preconditions.raw_epoch ~= nil or next(preconditions.relevant_revisions) ~= nil then
        return nil, "structure formation preconditions exceed exact source scope"
    end
    return true
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
        if type(mode) == "string" and mode:match("^repository_") then
            return nil, "repository pressure action mode is not installed"
        end
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
    local mode_ok, mode_err = validate_mode_contract(
        mode,
        scope_refs,
        preconditions,
        options
    )
    if not mode_ok then
        return nil, mode_err
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
    local mode_ok, mode_err = validate_mode_contract(
        plan.mode,
        scope_refs,
        preconditions,
        options
    )
    if not mode_ok then
        return nil, mode_err
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
    local repository_key = repository_option_keys[plan.mode]
    if repository_key then
        if options[root] ~= nil and type(options[root]) ~= "table" then
            return nil, "caller options override action-owned scope"
        end
        options[root] = copy_value(options[root] or {})
        if options[root][repository_key] ~= nil
            or options[root].qualified_action ~= nil then
            return nil, "caller options override action-owned scope"
        end
        options[root][repository_key] = copy_value(plan.options[root][repository_key])
    else
        if type(options[root]) == "table" and next(options[root]) ~= nil then
            return nil, "caller options override action-owned scope"
        end
        options[root] = copy_value(plan.options[root])
    end
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

function action.verify_effect(plan, payload, instance)
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
    if plan.mode == "structure_formation" then
        return structure_inspection.verify_effect(instance, plan, payload)
    end
    if plan.mode == "alternative_collapse" then
        return choice_inspection.verify_effect(instance, plan, payload)
    end
    if plan.mode == "plan_completion_review" then
        return plan_completion.verify_review_effect(instance, plan, payload)
    end
    if plan.mode == "plan_delivery" then
        return plan_completion.verify_delivery_effect(instance, plan, payload)
    end
    return true
end

action.mode_targets = copy_value(mode_targets)

return action
