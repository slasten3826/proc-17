local cycle = require("logic.cycle")
local packet_core = require("core.packet")
local field = require("runtime.field")
local object_coverage = require("runtime.object_coverage")
local digest = require("core.digest")

local body = {}

local upper_sensor_classes = {
    semantic = {semantic = true, material = true},
    field_native = {material = true},
    relation_native = {relation = true, material = true},
}

local eye_specs = {
    upper = {
        operator = "☴",
        revisions = {"potential", "relations_raw", "relations_active", "calm"},
    },
    lower = {
        operator = "☱",
        revisions = {
            "relations_active",
            "momentum",
            "calm",
            "constraints",
            "evidence",
            "history",
            "budget",
            "loss",
            "scalars",
        },
    },
}

local function ensure_list(parent, key)
    if type(parent[key]) ~= "table" then
        parent[key] = {}
    end
    return parent[key]
end

local function copy_array(source)
    local result = {}
    for index, value in ipairs(source or {}) do
        result[index] = value
    end
    return result
end

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

local function exact_keys(value, allowed, name)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, name .. " must be a plain table"
    end
    for key in pairs(value) do
        if not allowed[key] then
            return nil, name .. " contains unknown key: " .. tostring(key)
        end
    end
    return true
end

local function non_empty_string(value)
    return type(value) == "string" and value ~= ""
end

local function positive_integer(value)
    return type(value) == "number" and value >= 1 and value == math.floor(value)
end

local function non_negative_integer(value)
    return type(value) == "number" and value >= 0 and value == math.floor(value)
end

local function non_negative_number(value)
    return type(value) == "number" and value >= 0
        and value == value and value < math.huge
end

local function repository_refs(value)
    if type(value) ~= "table" then
        return false
    end
    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            return false
        end
        count = count + 1
    end
    if count ~= #value then
        return false
    end
    for _, ref in ipairs(value) do
        if not non_empty_string(ref) then
            return false
        end
    end
    return true
end

local repository_attempt_keys = {
    protocol_version = true, attempt_id = true, action_id = true,
    grant_id = true, grant_revision = true, operation = true,
    target_ref = true, work_unit_id = true, work_unit_version = true,
    source_refs = true, event_truth_status = true,
}
local repository_review_keys = {
    protocol_version = true, review_id = true, action_id = true,
    packet_id = true, lineage_id = true, generation = true,
    work_unit_id = true, work_unit_version = true,
    capability_grant_id = true, capability_revision = true,
    verdict = true, reason = true, scope_refs = true, source_refs = true,
    event_truth_status = true, content_truth_status = true,
}
local repository_receipt_keys = {
    protocol_version = true, receipt_id = true, attempt_id = true,
    action_id = true, grant_id = true, grant_revision = true,
    provider_id = true, operation = true, outcome = true, target = true,
    provider_observation = true, cost = true, source_refs = true,
    event_truth_status = true, content_truth_status = true,
}
local repository_verification_keys = {
    protocol_version = true, verification_id = true, action_id = true,
    attempt_id = true, receipt_ref = true, grant_id = true,
    grant_revision = true, provider_id = true, target = true,
    observed = true, expected = true, verdict = true, reason = true,
    cost = true, source_refs = true, event_truth_status = true,
    content_truth_status = true,
}
local work_completion_keys = {
    protocol_version = true, completion_id = true, work_unit_id = true,
    work_unit_version = true, formation_event_ref = true, action_id = true,
    attempt_ref = true, receipt_ref = true, verification_ref = true,
    validation_ref = true, completed_status = true, completed_by = true,
    source_refs = true, event_truth_status = true, content_truth_status = true,
}
local candidate_closure_keys = {
    protocol_version = true, closure_id = true, request_id = true,
    root_authority_id = true, lifecycle_id = true, root_fingerprint = true,
    grant_id = true, lifecycle_revision_before = true,
    lifecycle_revision_after = true, inventory_id = true,
    inventory_digest = true, state = true, source_refs = true,
    event_truth_status = true,
}
local target_keys = {relative_path = true, kind = true}
local observation_keys = {bytes = true, sha256 = true}
local effect_cost_keys = {tool_calls = true, file_writes = true, time_ms = true}

local function valid_effect_cost(value, tool_calls, file_writes)
    local ok = exact_keys(value, effect_cost_keys, "repository effect cost")
    return ok == true
        and value.tool_calls == tool_calls
        and value.file_writes == file_writes
        and non_negative_number(value.time_ms)
end

local function validate_repository_attempt(value)
    local ok, err = exact_keys(value, repository_attempt_keys,
        "repository effect attempt")
    if not ok then return nil, err end
    if value.protocol_version ~= "repository.effect_attempt.v0"
        or value.operation ~= "create_text_file"
        or value.event_truth_status ~= "runtime_confirmed"
        or not positive_integer(value.grant_revision)
        or not positive_integer(value.work_unit_version)
        or not repository_refs(value.source_refs) then
        return nil, "invalid repository effect attempt"
    end
    for _, key in ipairs({"attempt_id", "action_id", "grant_id", "target_ref",
        "work_unit_id"}) do
        if not non_empty_string(value[key]) then
            return nil, "invalid repository effect attempt " .. key
        end
    end
    return true
end

local function validate_repository_review(value)
    local ok, err = exact_keys(value, repository_review_keys,
        "repository action review")
    if not ok then return nil, err end
    if value.protocol_version ~= "runtime.repository_action_review.v0"
        or (value.verdict ~= "actionable" and value.verdict ~= "not_actionable")
        or value.event_truth_status ~= "runtime_confirmed"
        or not positive_integer(value.generation)
        or not positive_integer(value.work_unit_version)
        or not positive_integer(value.capability_revision)
        or not repository_refs(value.scope_refs) or #value.scope_refs == 0
        or not repository_refs(value.source_refs) or #value.source_refs == 0
        or not non_empty_string(value.content_truth_status) then
        return nil, "invalid repository action review"
    end
    for _, key in ipairs({"review_id", "action_id", "packet_id", "lineage_id",
        "work_unit_id", "capability_grant_id", "reason"}) do
        if not non_empty_string(value[key]) then
            return nil, "invalid repository action review " .. key
        end
    end
    local seed = copy_value(value)
    seed.review_id = nil
    local identity, identity_err = digest.record(seed)
    if not identity then
        return nil, identity_err
    end
    if value.review_id ~= "repository-action-review:" .. identity then
        return nil, "repository action review identity mismatch"
    end
    return true
end

local function validate_repository_receipt(value)
    local ok, err = exact_keys(value, repository_receipt_keys,
        "repository effect receipt")
    if not ok then return nil, err end
    local target_ok, target_err = exact_keys(value.target, target_keys,
        "repository receipt target")
    if not target_ok then return nil, target_err end
    local observed_ok, observed_err = exact_keys(value.provider_observation,
        observation_keys, "repository receipt observation")
    if not observed_ok then return nil, observed_err end
    if value.protocol_version ~= "repository.effect_receipt.v0"
        or value.operation ~= "create_text_file" or value.outcome ~= "created"
        or value.target.kind ~= "regular_file"
        or value.event_truth_status ~= "runtime_confirmed"
        or not positive_integer(value.grant_revision)
        or not non_negative_integer(value.provider_observation.bytes)
        or type(value.provider_observation.sha256) ~= "string"
        or #value.provider_observation.sha256 ~= 64
        or not valid_effect_cost(value.cost, 1, 1)
        or not repository_refs(value.source_refs)
        or not non_empty_string(value.content_truth_status) then
        return nil, "invalid repository effect receipt"
    end
    for _, key in ipairs({"receipt_id", "attempt_id", "action_id", "grant_id",
        "provider_id"}) do
        if not non_empty_string(value[key]) then
            return nil, "invalid repository effect receipt " .. key
        end
    end
    if not non_empty_string(value.target.relative_path) then
        return nil, "invalid repository receipt target path"
    end
    return true
end

local function validate_repository_verification(value)
    local ok, err = exact_keys(value, repository_verification_keys,
        "repository verification")
    if not ok then return nil, err end
    local target_ok, target_err = exact_keys(value.target, target_keys,
        "repository verification target")
    if not target_ok then return nil, target_err end
    local observed_ok, observed_err = exact_keys(value.observed, observation_keys,
        "repository verification observed")
    if not observed_ok then return nil, observed_err end
    local expected_ok, expected_err = exact_keys(value.expected, observation_keys,
        "repository verification expected")
    if not expected_ok then return nil, expected_err end
    local observed_shape = (value.observed.bytes == nil and value.observed.sha256 == nil)
        or (non_negative_integer(value.observed.bytes)
            and type(value.observed.sha256) == "string"
            and #value.observed.sha256 == 64)
    if value.protocol_version ~= "repository.verification.v0"
        or (value.verdict ~= "accepted" and value.verdict ~= "rejected")
        or (value.target.kind ~= "regular_file" and value.target.kind ~= "missing"
            and value.target.kind ~= "other")
        or value.event_truth_status ~= "runtime_confirmed"
        or not positive_integer(value.grant_revision)
        or not observed_shape
        or not non_negative_integer(value.expected.bytes)
        or type(value.expected.sha256) ~= "string" or #value.expected.sha256 ~= 64
        or not valid_effect_cost(value.cost, 1, 0)
        or not repository_refs(value.source_refs)
        or not non_empty_string(value.reason)
        or not non_empty_string(value.content_truth_status) then
        return nil, "invalid repository verification"
    end
    for _, key in ipairs({"verification_id", "action_id", "attempt_id",
        "receipt_ref", "grant_id", "provider_id"}) do
        if not non_empty_string(value[key]) then
            return nil, "invalid repository verification " .. key
        end
    end
    return true
end

local function validate_work_completion(value)
    local ok, err = exact_keys(value, work_completion_keys, "work completion")
    if not ok then return nil, err end
    if value.protocol_version ~= "runtime.work_completion.v0"
        or value.completed_status ~= "done" or value.completed_by ~= "☱"
        or value.event_truth_status ~= "runtime_confirmed"
        or not positive_integer(value.work_unit_version)
        or not repository_refs(value.source_refs)
        or not non_empty_string(value.content_truth_status) then
        return nil, "invalid work completion"
    end
    for _, key in ipairs({"completion_id", "work_unit_id", "formation_event_ref",
        "action_id", "attempt_ref", "receipt_ref", "verification_ref",
        "validation_ref"}) do
        if not non_empty_string(value[key]) then
            return nil, "invalid work completion " .. key
        end
    end
    return true
end

local function validate_candidate_closure(value)
    local ok, err = exact_keys(value, candidate_closure_keys,
        "candidate closure receipt")
    if not ok then return nil, err end
    if value.protocol_version ~= "repository.candidate_closure_receipt.v0"
        or value.state ~= "sealed"
        or value.event_truth_status ~= "runtime_confirmed"
        or not positive_integer(value.lifecycle_revision_before)
        or not positive_integer(value.lifecycle_revision_after)
        or value.lifecycle_revision_after <= value.lifecycle_revision_before
        or not repository_refs(value.source_refs) then
        return nil, "invalid candidate closure receipt"
    end
    for _, key in ipairs({
        "closure_id", "request_id", "root_authority_id", "lifecycle_id",
        "root_fingerprint", "grant_id", "inventory_id", "inventory_digest",
    }) do
        if not non_empty_string(value[key]) then
            return nil, "invalid candidate closure receipt " .. key
        end
    end
    local seed = copy_value(value)
    seed.closure_id = nil
    local identity, identity_err = digest.record(seed)
    if not identity then
        return nil, identity_err
    end
    if value.closure_id ~= "candidate-closure:" .. identity then
        return nil, "candidate closure receipt identity mismatch"
    end
    return true
end

local function record_repository_event(instance, actor, event_type, payload,
    validator, revision_axis)
    local lease, lease_err = packet_core.assert_actor_tick(instance, actor,
        "record " .. event_type)
    if not lease then
        return nil, lease_err
    end
    local valid, valid_err = validator(payload or {})
    if not valid then
        return nil, valid_err
    end
    local stored = copy_value(payload or {})
    valid, valid_err = validator(stored)
    if not valid then
        return nil, valid_err
    end
    local event, event_err = packet_core.append_repository_event(instance, {
        type = event_type,
        operator = actor,
        truth_status = "runtime_confirmed",
        payload = stored,
        cost = stored.cost or {},
    })
    if not event then
        return nil, event_err
    end
    if revision_axis and instance.revisions then
        instance.revisions[revision_axis] = (instance.revisions[revision_axis] or 0) + 1
    end
    return copy_value(stored), event
end

local function equal_value(left, right, seen)
    if type(left) ~= type(right) then
        return false
    end
    if type(left) ~= "table" then
        return left == right
    end
    seen = seen or {}
    if seen[left] ~= nil then
        return seen[left] == right
    end
    seen[left] = right
    for key, value in pairs(left) do
        if not equal_value(value, right[key], seen) then
            return false
        end
    end
    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end
    return true
end

local function valid_ref_list(value, name)
    if value == nil then
        return true
    end
    if type(value) ~= "table" then
        return nil, name .. " must be table"
    end
    for _, ref in ipairs(value) do
        if type(ref) ~= "string" or ref == "" then
            return nil, name .. " must contain non-empty strings"
        end
    end
    return true
end

local function observation_store(instance)
    instance.boundary = instance.boundary or {}
    local observations = instance.boundary.observations
    if type(observations) ~= "table" then
        observations = {}
    end

    if observations[1] ~= nil and observations.upper == nil then
        observations = {
            upper = observations,
            lower = {},
        }
    else
        observations.upper = observations.upper or {}
        observations.lower = observations.lower or {}
    end

    instance.boundary.observations = observations
    instance.chaos = instance.chaos or {}
    instance.chaos.observations = observations.upper
    return observations
end

local function eye_spec(eye)
    if eye == "☴" then
        eye = "upper"
    elseif eye == "☱" then
        eye = "lower"
    end
    return eye_specs[eye], eye
end

local function upper_observation_contract(input)
    local payload = input.payload or {}
    local sensor = input.sensor or payload.sensor
    if sensor == nil then
        if payload.kind == "field_native_observation" then
            sensor = "field_native"
        elseif payload.kind == "relation_native_observation" then
            sensor = "relation_native"
        else
            sensor = "semantic"
        end
    end
    if not upper_sensor_classes[sensor] then
        return nil, "invalid upper observation sensor"
    end
    local classes = input.observation_classes
    if classes == nil then
        if sensor == "field_native" then
            classes = {"material"}
        elseif sensor == "relation_native" then
            classes = {"relation"}
        else
            classes = {"semantic"}
        end
    end
    if type(classes) ~= "table" or #classes == 0 then
        return nil, "upper observation classes must be a non-empty table"
    end
    local normalized = {}
    local seen = {}
    for _, class in ipairs(classes) do
        if type(class) ~= "string" or not upper_sensor_classes[sensor][class] then
            return nil, "upper observation sensor/class mismatch"
        end
        if seen[class] then
            return nil, "duplicate upper observation class"
        end
        seen[class] = true
        normalized[#normalized + 1] = class
    end
    table.sort(normalized)
    return {
        sensor = sensor,
        observation_classes = normalized,
    }
end

function body.revision_snapshot(instance, eye, components)
    local spec, normalized_eye = eye_spec(eye)
    if not spec then
        return nil, "invalid observation eye"
    end
    if type(instance) ~= "table" or type(instance.revisions) ~= "table" then
        return nil, "packet revision vector required"
    end

    local allowed = {}
    for _, component in ipairs(spec.revisions) do
        allowed[component] = true
    end
    local selected = components or spec.revisions
    if type(selected) ~= "table" then
        return nil, "observation revision components must be table"
    end

    local snapshot = {}
    for _, component in ipairs(selected) do
        if not allowed[component] then
            return nil, normalized_eye .. " eye cannot read revision " .. tostring(component)
        end
        local revision = instance.revisions[component]
        if type(revision) ~= "number" then
            return nil, "missing packet revision " .. tostring(component)
        end
        snapshot[component] = revision
    end
    return snapshot
end

function body.record_observation(instance, eye, input)
    local spec, normalized_eye = eye_spec(eye)
    if not spec then
        return nil, "invalid observation eye"
    end
    local lease, lease_err = packet_core.assert_actor_tick(
        instance,
        spec.operator,
        "record observation"
    )
    if not lease then
        return nil, lease_err
    end
    input = input or {}
    local upper_contract
    if normalized_eye == "upper" then
        local contract_err
        upper_contract, contract_err = upper_observation_contract(input)
        if not upper_contract then
            return nil, contract_err
        end
    end

    for _, item in ipairs({
        {input.scope_refs, "observation scope_refs"},
        {input.source_refs, "observation source_refs"},
        {input.sensor_output_refs, "observation sensor_output_refs"},
        {input.missing_scope, "observation missing_scope"},
    }) do
        local ok, err = valid_ref_list(item[1], item[2])
        if not ok then
            return nil, err
        end
    end

    local read_revisions = input.read_revisions
    if read_revisions == nil then
        local snapshot, snapshot_err = body.revision_snapshot(instance, normalized_eye, input.revision_components)
        if not snapshot then
            return nil, snapshot_err
        end
        read_revisions = snapshot
    elseif type(read_revisions) ~= "table" then
        return nil, "observation read_revisions must be table"
    end
    if next(read_revisions) == nil then
        return nil, "observation must read at least one revision"
    end

    local allowed = {}
    for _, component in ipairs(spec.revisions) do
        allowed[component] = true
    end
    for component, revision in pairs(read_revisions) do
        if not allowed[component] then
            return nil, normalized_eye .. " eye cannot record revision " .. tostring(component)
        end
        if type(revision) ~= "number" then
            return nil, "observation revision must be number"
        end
    end

    local content_truth_status = input.content_truth_status or "unknown"
    if type(content_truth_status) ~= "string" or content_truth_status == "" then
        return nil, "observation content truth status is required"
    end
    if input.fidelity ~= nil and (type(input.fidelity) ~= "string" or input.fidelity == "") then
        return nil, "observation fidelity must be non-empty string"
    end
    if input.read_units ~= nil then
        local coverage_ok, coverage_err = object_coverage.validate(input.read_units)
        if not coverage_ok or input.read_units.domain ~= "upper_observation" then
            return nil, coverage_err or "observation unit coverage must use upper domain"
        end
    end

    local stores = observation_store(instance)
    local records = stores[normalized_eye]
    local record = {
        kind = "eye_observation",
        id = "observation:" .. normalized_eye .. ":" .. tostring(#records + 1),
        eye = normalized_eye,
        operator = spec.operator,
        scope_refs = copy_value(input.scope_refs or {}),
        read_revisions = copy_value(read_revisions),
        read_units = copy_value(input.read_units),
        payload = copy_value(input.payload or {}),
        metrics = copy_value(input.metrics or {}),
        missing_scope = copy_value(input.missing_scope or {}),
        sensor_output_refs = copy_value(input.sensor_output_refs or {}),
        source_refs = copy_value(input.source_refs or {}),
        event_truth_status = "runtime_confirmed",
        content_truth_status = content_truth_status,
        fidelity = input.fidelity or "bounded",
        tick = instance.physis and instance.physis.clock and instance.physis.clock.ticks or 0,
    }
    if upper_contract then
        record.sensor = upper_contract.sensor
        record.observation_classes = copy_array(upper_contract.observation_classes)
    end

    local event, event_err = packet_core.append_event(instance, {
        type = "observation",
        operator = spec.operator,
        truth_status = "runtime_confirmed",
        payload = record,
        cost = {},
    })
    if not event then
        return nil, event_err
    end
    record.trace_event_id = event.id
    if record.read_units then
        record.read_units.capture_event_ref = event.id
    end
    records[#records + 1] = copy_value(record)
    return copy_value(record), event
end

function body.commit_upper_observation(instance, input)
    input = input or {}
    if input.sensor ~= "semantic" then
        return nil, "upper observation commit v0 requires semantic sensor"
    end
    local contract, contract_err = upper_observation_contract(input)
    if not contract then
        return nil, contract_err
    end
    if type(input.planned_unit_id) ~= "string" or input.planned_unit_id == "" then
        return nil, "upper observation planned_unit_id required"
    end
    if type(input.sensor_output) ~= "table" then
        return nil, "upper observation sensor_output required"
    end
    local planned_ids, planned_err = field.plan_unit_ids(instance, 1)
    if not planned_ids then
        return nil, planned_err
    end
    if planned_ids[1] ~= input.planned_unit_id then
        return nil, "upper observation planned unit is stale"
    end

    local unit_input = copy_value(input.sensor_output)
    unit_input.id = input.planned_unit_id
    unit_input.created_event_id = nil
    local planned_unit, unit_plan_err = field.validate_unit_plan(
        instance,
        "☴",
        unit_input,
        {pending_created_event = true}
    )
    if not planned_unit then
        return nil, unit_plan_err
    end

    local read_units_ok, read_units_err = object_coverage.validate(input.read_units)
    if not read_units_ok or input.read_units.domain ~= "upper_observation" then
        return nil, read_units_err or "semantic observation requires upper unit coverage"
    end
    local merged_entries = copy_value(input.read_units.entries)
    for _, entry in ipairs(merged_entries) do
        if entry.object_id == input.planned_unit_id then
            return nil, "semantic observation output is already present in input coverage"
        end
    end
    merged_entries[#merged_entries + 1] = {
        object_kind = "field_unit",
        object_id = planned_unit.id,
        version = 1,
        activation_at_coverage = planned_unit.activation,
        source_ref = planned_unit.id,
        content_truth_status = planned_unit.content_truth_status,
    }
    local committed_coverage, coverage_err = object_coverage.capture(merged_entries, {
        domain = "upper_observation",
        policy_id = input.read_units.policy_id,
        total_count = input.read_units.total_count + 1,
        global_revision = instance.revisions.potential + 1,
    })
    if not committed_coverage then
        return nil, coverage_err
    end

    local observation_input = copy_value(input)
    observation_input.sensor_output = nil
    observation_input.planned_unit_id = nil
    observation_input.read_units = committed_coverage
    observation_input.sensor_output_refs = copy_array(input.sensor_output_refs or {})
    local output_named = false
    for _, ref in ipairs(observation_input.sensor_output_refs) do
        if ref == planned_unit.id then
            output_named = true
        end
    end
    if not output_named then
        observation_input.sensor_output_refs[#observation_input.sensor_output_refs + 1] = planned_unit.id
    end

    local observation, observation_event = body.record_observation(
        instance,
        "upper",
        observation_input
    )
    if not observation then
        return nil, observation_event
    end

    unit_input.created_event_id = observation.trace_event_id
    local unit, unit_err = field.add_unit(instance, "☴", unit_input)
    if not unit then
        error("invariant_failure: semantic observation unit commit failed: "
            .. tostring(unit_err))
    end
    if unit.id ~= planned_unit.id or unit.version ~= 1 then
        error("invariant_failure: semantic observation unit commit diverged from plan")
    end
    return observation, unit
end

function body.latest_observation(instance, eye)
    local _, normalized_eye = eye_spec(eye)
    if not normalized_eye or not eye_specs[normalized_eye] then
        return nil, "invalid observation eye"
    end
    local stores = instance and instance.boundary and instance.boundary.observations or {}
    local records = stores[normalized_eye] or {}
    return copy_value(records[#records])
end

local function unit_id(unit, index)
    if type(unit) == "table" and unit.id ~= nil then
        return tostring(unit.id)
    end
    return tostring(index)
end

local function is_done(unit)
    return type(unit) == "table" and unit.status == "done"
end

local function repository_field_unit(instance, id)
    local field_unit = instance and instance.field and instance.field.units
        and instance.field.units[id]
    if type(field_unit) == "table" and type(field_unit.carrier) == "table"
        and field_unit.carrier.kind == "repository.create_text_file.v0" then
        return field_unit
    end
    return nil
end

local function work_units(instance)
    if type(instance) ~= "table" or type(instance.calm) ~= "table" then
        return {}
    end
    if type(instance.calm.work_units) == "table" and #instance.calm.work_units > 0 then
        return instance.calm.work_units
    end
    local current = instance.calm.current
    if type(current) == "table" and type(current.units) == "table" then
        return current.units
    end
    return {}
end

local function budget(instance)
    if type(instance) ~= "table" then
        return {}
    end
    local physis = instance.physis or instance.substrate or {}
    return physis.budget or {}
end

function body.progress(instance, options)
    options = options or {}
    local units = work_units(instance)
    local done = {}
    local remaining = {}

    for index, unit in ipairs(units) do
        local id = unit_id(unit, index)
        local repository_unit = repository_field_unit(instance, id)
        local completed = is_done(unit)
        if repository_unit then
            local work_completion = require("runtime.work_completion")
            completed = work_completion.is_complete(
                instance,
                repository_unit.id,
                repository_unit.version
            ) == true
        end
        if completed then
            done[#done + 1] = id
        else
            remaining[#remaining + 1] = id
        end
    end

    local logic_status = options.logic_status
    if logic_status == nil then
        logic_status = "accepted"
    end

    return {
        goal = options.goal or (instance and instance.chaos and instance.chaos.raw_prompt) or nil,
        needed_count = #units,
        done_count = #done,
        remaining_count = #remaining,
        done = done,
        remaining = remaining,
        logic_status = logic_status,
    }
end

function body.record_repository_effect_attempt(instance, payload)
    return record_repository_event(instance, "☶", "repository_effect_attempt",
        payload, validate_repository_attempt)
end

function body.record_repository_action_review(instance, payload)
    return record_repository_event(instance, "☱", "repository_action_review",
        payload, validate_repository_review)
end

function body.record_repository_effect_receipt(instance, payload)
    return record_repository_event(instance, "☶", "repository_effect_receipt",
        payload, validate_repository_receipt)
end

function body.record_repository_verification(instance, payload)
    return record_repository_event(instance, "☶", "repository_verification",
        payload, validate_repository_verification, "evidence")
end

function body.record_work_completion(instance, payload)
    return record_repository_event(instance, "☱", "work_completion",
        payload, validate_work_completion, "history")
end

function body.record_candidate_seal(instance, payload, registry, closure)
    local candidate_seal = require("runtime.candidate_seal")
    local capabilities = require("runtime.repository_capability")
    local payload_ok, payload_err = candidate_seal.validate_seal(instance, payload)
    if not payload_ok then
        return nil, payload_err
    end
    local closure_ok, closure_err = validate_candidate_closure(closure)
    if not closure_ok then
        return nil, closure_err
    end
    if closure.request_id ~= payload.request_id
        or closure.root_authority_id ~= payload.root_authority_id
        or closure.lifecycle_id ~= payload.lifecycle_id
        or closure.root_fingerprint ~= payload.root_fingerprint
        or closure.inventory_id ~= payload.inventory_id
        or closure.inventory_digest ~= payload.inventory_digest
        or closure.closure_id ~= payload.authority_closure_ref then
        return nil, "candidate seal contradicts closure receipt"
    end
    local observed, observed_err = capabilities.observe_candidate_closure(registry, {
        root_authority_id = payload.root_authority_id,
        lifecycle_id = payload.lifecycle_id,
        request_id = payload.request_id,
    })
    if not observed then
        return nil, observed_err
    end
    if not equal_value(observed, closure) then
        return nil, "candidate closure receipt contradicts private registry"
    end
    for _, event in ipairs(instance.trace or {}) do
        if event.type == "candidate_seal" then
            if event.operator == "☶" and event.truth_status == "runtime_confirmed"
                and equal_value(event.payload, payload) then
                return copy_value(event.payload), copy_value(event)
            end
            return nil, "Packet contains contradictory candidate seal event"
        end
    end
    return record_repository_event(instance, "☶", "candidate_seal", payload,
        function(value)
            return candidate_seal.validate_seal(instance, value)
        end, "evidence")
end

function body.record_choice(instance, choice_payload)
    local lease, lease_err = packet_core.assert_actor_tick(instance, "☳", "record choice")
    if not lease then
        return nil, lease_err
    end
    choice_payload = copy_value(choice_payload or {})
    local event, event_err = packet_core.append_event(instance, {
        type = "choice",
        operator = "☳",
        truth_status = choice_payload.truth_status or "runtime_confirmed",
        payload = choice_payload,
        cost = choice_payload.cost or {},
    })
    if not event then
        return nil, event_err
    end
    choice_payload.trace_event_id = event.id
    local choices = ensure_list(instance.boundary, "choices")
    choices[#choices + 1] = copy_value(choice_payload)
    return copy_value(choice_payload), event
end

function body.record_validation(instance, validation_payload)
    local lease, lease_err = packet_core.assert_actor_tick(instance, "☶", "record validation")
    if not lease then
        return nil, lease_err
    end
    validation_payload = copy_value(validation_payload or {})
    local event, event_err = packet_core.append_event(instance, {
        type = "validation",
        operator = "☶",
        truth_status = validation_payload.truth_status or "runtime_confirmed",
        payload = validation_payload,
        cost = validation_payload.cost or {},
    })
    if not event then
        return nil, event_err
    end
    validation_payload.trace_event_id = event.id
    local validations = ensure_list(instance.boundary, "validations")
    validations[#validations + 1] = copy_value(validation_payload)
    if instance.revisions then
        instance.revisions.constraints = (instance.revisions.constraints or 0) + 1
    end
    return copy_value(validation_payload), event
end

function body.record_cycle(instance, cycle_payload)
    local lease, lease_err = packet_core.assert_actor_tick(instance, "☲", "record cycle")
    if not lease then
        return nil, lease_err
    end
    cycle_payload = copy_value(cycle_payload or {})
    local event, event_err = packet_core.append_event(instance, {
        type = "cycle",
        operator = "☲",
        truth_status = cycle_payload.truth_status or "runtime_confirmed",
        payload = cycle_payload,
        cost = cycle_payload.cost or {},
    })
    if not event then
        return nil, event_err
    end
    cycle_payload.trace_event_id = event.id
    local cycles = ensure_list(instance.boundary, "cycles")
    cycles[#cycles + 1] = copy_value(cycle_payload)
    return copy_value(cycle_payload)
end

function body.cycle_input(instance, options)
    options = options or {}
    return {
        cycle_key = options.cycle_key or "packet_body",
        turn_count = options.turn_count or 0,
        max_turns = options.max_turns or 1,
        budget = options.budget or budget(instance),
        required_budget = options.required_budget or {steps = 1},
        state_fingerprint = options.state_fingerprint,
        previous_fingerprints = options.previous_fingerprints,
        manifest_ready = options.manifest_ready,
        unsafe = options.unsafe,
        needs_user_input = options.needs_user_input,
        progress = body.progress(instance, {
            goal = options.goal,
            logic_status = options.logic_status,
        }),
    }
end

function body.decide_cycle(instance, options)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "decide cycle")
    if not mutable then
        return nil, mutable_err
    end
    local payload, err = cycle.decide(body.cycle_input(instance, options))
    if not payload then
        return nil, err
    end
    local recorded, record_err = body.record_cycle(instance, payload)
    if not recorded then
        return nil, record_err
    end
    return payload
end

function body.apply_crystallized_work(instance, units, options)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "apply crystallized work")
    if not mutable then
        return nil, mutable_err
    end
    options = options or {}
    local next_units = copy_value(units or {})
    local next_status = options.status or instance.calm.status or "accepted"
    local changed = not equal_value(instance.calm.work_units or {}, next_units)
        or instance.calm.status ~= next_status
    if changed then
        instance.calm.work_units = next_units
        instance.calm.status = next_status
        if instance.revisions then
            instance.revisions.calm = (instance.revisions.calm or 0) + 1
        end
    end
    return body.progress(instance, {
        goal = options.goal,
        logic_status = options.logic_status,
    })
end

return body
