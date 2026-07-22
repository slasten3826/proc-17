local digest = require("core.digest")
local json = require("core.json")
local repository_intent = require("runtime.repository_intent")
local repository_formation = require("runtime.repository_formation")
local work_completion = require("runtime.work_completion")

local artifact_set = {
    protocol_version = "repository.artifact_set_contract.v0",
    inspection_protocol = "runtime.artifact_set_inspection.v0",
    bounds = {
        max_artifacts = 128,
        max_relative_path_bytes = 1024,
        max_directory_depth = 64,
    },
}

local contract_keys = {
    protocol_version = true,
    artifact_set_id = true,
    packet_id = true,
    lineage_id = true,
    generation = true,
    process_contract_id = true,
    context = true,
    stage_id = true,
    repository_id = true,
    birth_ref = true,
    formation_event_ref = true,
    choice_event_ref = true,
    artifacts = true,
    source_refs = true,
    event_truth_status = true,
    content_truth_status = true,
}

local artifact_keys = {
    work_unit_id = true,
    work_unit_version = true,
    unit_created_event_ref = true,
    relative_path = true,
    expected_kind = true,
    provenance_refs = true,
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

local function non_empty(value, name)
    if type(value) ~= "string" or value == "" then
        return nil, name .. " must be a non-empty string"
    end
    return value
end

local function positive_integer(value, name)
    if type(value) ~= "number" or value < 1 or value ~= math.floor(value) then
        return nil, name .. " must be an integer >= 1"
    end
    return value
end

local function strict_refs(value, name)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, name .. " must be an array"
    end
    local result = {}
    local seen = {}
    for index, ref in ipairs(value) do
        if type(ref) ~= "string" or ref == "" or seen[ref] then
            return nil, name .. " must contain unique non-empty strings"
        end
        seen[ref] = true
        result[index] = ref
    end
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key > #result
            or key ~= math.floor(key) then
            return nil, name .. " must be an array"
        end
    end
    table.sort(result)
    return result
end

local function sorted_unique(values)
    local result = {}
    local seen = {}
    for _, value in ipairs(values or {}) do
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function path_depth(path)
    local count = 0
    for _ in path:gmatch("[^/]+") do
        count = count + 1
    end
    return count
end

local function artifact_less(left, right)
    if left.relative_path ~= right.relative_path then
        return left.relative_path < right.relative_path
    end
    return left.work_unit_id < right.work_unit_id
end

local function diagnostic(code, refs)
    return {
        kind = "artifact_set_diagnostic",
        protocol_version = "runtime.artifact_set_diagnostic.v0",
        code = code,
        source_refs = sorted_unique(refs),
        event_truth_status = "runtime_confirmed",
    }
end

local function normalize_contract(value, require_identity)
    local keys_ok, keys_err = exact_keys(value, contract_keys, "artifact set contract")
    if not keys_ok then
        return nil, keys_err
    end
    if value.protocol_version ~= artifact_set.protocol_version then
        return nil, "unsupported artifact set protocol"
    end
    for _, name in ipairs({
        "packet_id",
        "lineage_id",
        "process_contract_id",
        "context",
        "stage_id",
        "repository_id",
        "birth_ref",
        "formation_event_ref",
    }) do
        local _, value_err = non_empty(value[name], "artifact set " .. name)
        if value_err then
            return nil, value_err
        end
    end
    if value.process_contract_id ~= "build.only.v0"
        and value.process_contract_id ~= "software.create.v0" then
        return nil, "artifact set process contract is not build-compatible"
    end
    if value.context ~= "software_task.v0" then
        return nil, "artifact set context is unsupported"
    end
    if value.choice_event_ref ~= nil then
        local _, choice_err = non_empty(value.choice_event_ref,
            "artifact set choice_event_ref")
        if choice_err then
            return nil, choice_err
        end
    end
    local _, generation_err = positive_integer(value.generation, "artifact set generation")
    if generation_err then
        return nil, generation_err
    end
    if value.event_truth_status ~= "runtime_confirmed" then
        return nil, "artifact set declaration must be runtime_confirmed"
    end
    if value.content_truth_status ~= "semantic_proposal"
        and value.content_truth_status ~= "mixed" then
        return nil, "artifact set content truth status is invalid"
    end

    local refs, refs_err = strict_refs(value.source_refs, "artifact set source_refs")
    if not refs then
        return nil, refs_err
    end
    if #refs == 0 then
        return nil, "artifact set requires at least one source ref"
    end
    if type(value.artifacts) ~= "table" or getmetatable(value.artifacts) ~= nil then
        return nil, "artifact set artifacts must be an array"
    end
    local artifacts = {}
    local seen_ids = {}
    local seen_paths = {}
    for index, input in ipairs(value.artifacts) do
        if index > artifact_set.bounds.max_artifacts then
            return nil, "artifact set exceeds max_artifacts"
        end
        local artifact_ok, artifact_err = exact_keys(
            input,
            artifact_keys,
            "artifact set artifact"
        )
        if not artifact_ok then
            return nil, artifact_err
        end
        local _, id_err = non_empty(input.work_unit_id, "artifact work_unit_id")
        if id_err then
            return nil, id_err
        end
        local _, version_err = positive_integer(
            input.work_unit_version,
            "artifact work_unit_version"
        )
        if version_err then
            return nil, version_err
        end
        local path, path_err = repository_intent.validate_relative_path(input.relative_path)
        if not path then
            return nil, path_err
        end
        if #path > artifact_set.bounds.max_relative_path_bytes then
            return nil, "artifact relative path exceeds bound"
        end
        if path_depth(path) > artifact_set.bounds.max_directory_depth then
            return nil, "artifact relative path depth exceeds bound"
        end
        if input.expected_kind ~= "regular_file" then
            return nil, "artifact expected_kind must be regular_file"
        end
        local _, created_err = non_empty(input.unit_created_event_ref,
            "artifact unit_created_event_ref")
        if created_err then
            return nil, created_err
        end
        local provenance_refs, provenance_err = strict_refs(
            input.provenance_refs,
            "artifact provenance_refs"
        )
        if not provenance_refs then
            return nil, provenance_err
        end
        if #provenance_refs == 0 then
            return nil, "artifact provenance_refs cannot be empty"
        end
        if seen_ids[input.work_unit_id] then
            return nil, "duplicate artifact work identity"
        end
        if seen_paths[path] then
            return nil, "duplicate artifact relative path"
        end
        seen_ids[input.work_unit_id] = true
        seen_paths[path] = true
        artifacts[index] = {
            work_unit_id = input.work_unit_id,
            work_unit_version = input.work_unit_version,
            unit_created_event_ref = input.unit_created_event_ref,
            relative_path = path,
            expected_kind = "regular_file",
            provenance_refs = provenance_refs,
        }
    end
    for key in pairs(value.artifacts) do
        if type(key) ~= "number" or key < 1 or key > #artifacts
            or key ~= math.floor(key) then
            return nil, "artifact set artifacts must be an array"
        end
    end
    if #artifacts == 0 then
        return nil, "artifact set requires at least one artifact"
    end
    table.sort(artifacts, artifact_less)

    local normalized = {
        protocol_version = artifact_set.protocol_version,
        artifact_set_id = nil,
        packet_id = value.packet_id,
        lineage_id = value.lineage_id,
        generation = value.generation,
        process_contract_id = value.process_contract_id,
        context = value.context,
        stage_id = value.stage_id,
        repository_id = value.repository_id,
        birth_ref = value.birth_ref,
        formation_event_ref = value.formation_event_ref,
        choice_event_ref = value.choice_event_ref,
        artifacts = artifacts,
        source_refs = refs,
        event_truth_status = "runtime_confirmed",
        content_truth_status = value.content_truth_status,
    }
    local identity, identity_err = digest.record(normalized)
    if not identity then
        return nil, identity_err
    end
    normalized.artifact_set_id = "artifact-set:" .. identity
    if require_identity and value.artifact_set_id ~= normalized.artifact_set_id then
        return nil, "artifact set identity mismatch"
    end
    return normalized
end

local function birth_contract(instance)
    if type(instance) ~= "table" or type(instance.id) ~= "string"
        or type(instance.trace) ~= "table" then
        return nil, "artifact set derivation requires Packet"
    end
    if instance.status == "dead" or instance.status == "manifested" then
        return nil, "artifact set derivation requires living Packet"
    end
    local event = instance.trace[1]
    local payload = event and event.payload or nil
    if not event or event.type ~= "birth" or event.operator ~= "▽"
        or event.truth_status ~= "runtime_confirmed"
        or type(payload) ~= "table"
        or payload.packet_id ~= instance.id
        or payload.lineage_id ~= instance.lineage_id
        or payload.generation ~= instance.generation
        or payload.work_mode ~= "build"
        or payload.process_contract_id ~= instance.process_contract_id
        or payload.context ~= instance.work_context
        or payload.stage_id ~= instance.stage_id
        or payload.repository_id ~= instance.repository_id then
        return nil, "Packet birth/work contract invariant failed"
    end
    if instance.regime and instance.regime.work
        and instance.regime.work.mode ~= "build" then
        return nil, "artifact set is available only in build mode"
    end
    if instance.process_contract_id ~= "build.only.v0"
        and instance.process_contract_id ~= "software.create.v0" then
        return nil, "Packet process contract is not build-compatible"
    end
    if instance.work_context ~= "software_task.v0" then
        return nil, "Packet work context is unsupported"
    end
    if type(instance.stage_id) ~= "string" or instance.stage_id == "" then
        return nil, "Packet stage identity is absent"
    end
    if type(instance.repository_id) ~= "string" or instance.repository_id == "" then
        return nil, diagnostic("repository_identity_absent", {event.id})
    end
    return {
        event_ref = event.id,
        process_contract_id = instance.process_contract_id,
        context = instance.work_context,
        stage_id = instance.stage_id,
        repository_id = instance.repository_id,
    }
end

function artifact_set.derive(instance)
    local birth, birth_err = birth_contract(instance)
    if not birth then
        return nil, birth_err
    end
    local formation, formation_err = repository_formation.current_set(instance, {
        max_units = artifact_set.bounds.max_artifacts,
    })
    if not formation then
        return nil, formation_err
    end

    local artifacts = {}
    local source_refs = {birth.event_ref, formation.formation_event_ref}
    if formation.choice_event_ref then
        source_refs[#source_refs + 1] = formation.choice_event_ref
    end
    for _, ref in ipairs(formation.source_refs or {}) do
        source_refs[#source_refs + 1] = ref
    end
    for _, basis in ipairs(formation.units) do
        local unit = instance.field.units[basis.unit_id]
        if type(unit) ~= "table" or unit.version ~= basis.unit_version
            or type(unit.carrier) ~= "table"
            or unit.carrier.kind ~= "repository.create_text_file.v0"
            or type(unit.carrier.value) ~= "table" then
            return nil, "repository artifact carrier invariant failed"
        end
        local path, path_err = repository_intent.validate_relative_path(
            unit.carrier.value.path
        )
        if not path then
            return nil, path_err
        end
        artifacts[#artifacts + 1] = {
            work_unit_id = unit.id,
            work_unit_version = unit.version,
            unit_created_event_ref = basis.unit_created_event_ref,
            relative_path = path,
            expected_kind = "regular_file",
            provenance_refs = copy_value(basis.provenance_refs),
        }
        source_refs[#source_refs + 1] = basis.unit_created_event_ref
        for _, ref in ipairs(basis.provenance_refs) do
            source_refs[#source_refs + 1] = ref
        end
    end

    local contract, contract_err = normalize_contract({
        protocol_version = artifact_set.protocol_version,
        artifact_set_id = nil,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        process_contract_id = birth.process_contract_id,
        context = birth.context,
        stage_id = birth.stage_id,
        repository_id = birth.repository_id,
        birth_ref = birth.event_ref,
        formation_event_ref = formation.formation_event_ref,
        choice_event_ref = formation.choice_event_ref,
        artifacts = artifacts,
        source_refs = sorted_unique(source_refs),
        event_truth_status = "runtime_confirmed",
        content_truth_status = formation.content_truth_status,
    }, false)
    if not contract then
        return nil, "derived artifact set failed normalization: " .. tostring(contract_err)
    end
    local validated, validated_err = artifact_set.validate(contract)
    if not validated then
        return nil, "derived artifact set failed validation: " .. tostring(validated_err)
    end
    return copy_value(validated)
end

function artifact_set.identify(value)
    local normalized, err = normalize_contract(value, false)
    if not normalized then
        return nil, err
    end
    return normalized.artifact_set_id
end

function artifact_set.validate(value)
    local normalized, err = normalize_contract(value, true)
    if not normalized then
        return nil, err
    end
    return copy_value(normalized)
end

function artifact_set.same(left, right)
    local normalized_left = artifact_set.validate(left)
    local normalized_right = artifact_set.validate(right)
    if not normalized_left or not normalized_right then
        return false
    end
    return json.encode(normalized_left) == json.encode(normalized_right)
end

local function current_repository_units(instance)
    if type(instance) ~= "table" or type(instance.field) ~= "table"
        or type(instance.field.units) ~= "table"
        or type(instance.field.unit_order) ~= "table" then
        return nil, "Packet field is unavailable"
    end
    local result = {}
    for _, id in ipairs(instance.field.unit_order) do
        local unit = instance.field.units[id]
        if type(unit) ~= "table" or unit.id ~= id then
            return nil, "Packet field order invariant failed"
        end
        if unit.generation == instance.generation
            and (unit.activation == "live" or unit.activation == "selected")
            and type(unit.carrier) == "table"
            and unit.carrier.kind == "repository.create_text_file.v0" then
            result[#result + 1] = unit
        end
    end
    return result
end

local function content_status(contract, units)
    local status = contract.content_truth_status
    for _, unit in ipairs(units or {}) do
        local current = unit.content_truth_status or "semantic_proposal"
        if current ~= status then
            return "mixed"
        end
    end
    return status
end

local function inspection_identity(value)
    local seed = copy_value(value)
    seed.inspection_id = nil
    local identity, err = digest.record(seed)
    if not identity then
        return nil, err
    end
    return "artifact-set-inspection:" .. identity
end

local function trace_event(instance, event_id)
    for _, event in ipairs(instance and instance.trace or {}) do
        if event.id == event_id then
            return event
        end
    end
    return nil
end

local function verify_named_contract_evidence(instance, normalized)
    local birth = trace_event(instance, normalized.birth_ref)
    local birth_payload = birth and birth.payload or nil
    if not birth or birth.type ~= "birth" or birth.operator ~= "▽"
        or birth.truth_status ~= "runtime_confirmed"
        or type(birth_payload) ~= "table"
        or birth_payload.packet_id ~= normalized.packet_id
        or birth_payload.lineage_id ~= normalized.lineage_id
        or birth_payload.generation ~= normalized.generation
        or birth_payload.process_contract_id ~= normalized.process_contract_id
        or birth_payload.context ~= normalized.context
        or birth_payload.stage_id ~= normalized.stage_id
        or birth_payload.repository_id ~= normalized.repository_id then
        return nil, "artifact set birth ref is stale or mismatched"
    end
    local formation = trace_event(instance, normalized.formation_event_ref)
    if not formation or formation.type ~= "structure_formation"
        or formation.operator ~= "☵"
        or formation.truth_status ~= "runtime_confirmed" then
        return nil, "artifact set formation ref is stale or mismatched"
    end
    if normalized.choice_event_ref ~= nil then
        local choice = trace_event(instance, normalized.choice_event_ref)
        if not choice or choice.type ~= "choice" or choice.operator ~= "☳"
            or choice.truth_status ~= "runtime_confirmed"
            or type(choice.payload) ~= "table"
            or choice.payload.choice_set_ref ~= normalized.formation_event_ref then
            return nil, "artifact set choice ref is stale or mismatched"
        end
    end
    return true
end

function artifact_set.inspect(instance, contract)
    local normalized, contract_err = artifact_set.validate(contract)
    if not normalized then
        return nil, contract_err
    end
    if type(instance) ~= "table" or type(instance.id) ~= "string" then
        return nil, "artifact set inspection requires Packet"
    end
    if normalized.packet_id ~= instance.id
        or normalized.lineage_id ~= instance.lineage_id
        or normalized.generation ~= instance.generation
        or normalized.process_contract_id ~= instance.process_contract_id
        or normalized.context ~= instance.work_context
        or normalized.stage_id ~= instance.stage_id
        or normalized.repository_id ~= instance.repository_id then
        return nil, "artifact set identity is foreign to Packet"
    end
    local evidence_ok, evidence_err = verify_named_contract_evidence(instance, normalized)
    if not evidence_ok then
        return nil, evidence_err
    end

    local current_units, units_err = current_repository_units(instance)
    if not current_units then
        return nil, units_err
    end
    local current_by_id = {}
    for _, unit in ipairs(current_units) do
        current_by_id[unit.id] = unit
    end

    local artifact_records = {}
    local declared_ids = {}
    local completion_refs = {}
    local verification_refs = {}
    local source_refs = copy_value(normalized.source_refs)
    local relevant_versions = {}
    local missing_ids = {}
    local conflicting_refs = {}
    local done_count = 0
    local used_units = {}

    for _, declared in ipairs(normalized.artifacts) do
        declared_ids[declared.work_unit_id] = true
        local unit = current_by_id[declared.work_unit_id]
        local state = "missing"
        local completion_ref
        local verification_ref
        if unit then
            used_units[#used_units + 1] = unit
            relevant_versions[#relevant_versions + 1] = {
                object_kind = "field_unit",
                object_id = unit.id,
                version = unit.version,
                source_ref = unit.created_event_id,
            }
            if unit.version ~= declared.work_unit_version then
                state = "stale"
            elseif unit.created_event_id ~= declared.unit_created_event_ref then
                state = "conflict"
                conflicting_refs[#conflicting_refs + 1] = unit.created_event_id
                    or ("field-unit:" .. unit.id)
            elseif type(unit.carrier.value) ~= "table"
                or unit.carrier.value.path ~= declared.relative_path then
                state = "conflict"
                conflicting_refs[#conflicting_refs + 1] = unit.created_event_id
                    or ("field-unit:" .. unit.id)
            else
                local basis, basis_err = repository_formation.for_unit(
                    instance,
                    unit.id,
                    unit.version
                )
                if not basis then
                    state = "conflict"
                    if type(basis_err) == "table" then
                        for _, ref in ipairs(basis_err.source_refs or {}) do
                            conflicting_refs[#conflicting_refs + 1] = ref
                        end
                    end
                elseif basis.formation_event_ref ~= normalized.formation_event_ref
                    or basis.choice_event_ref ~= normalized.choice_event_ref
                    or json.encode(basis.provenance_refs)
                        ~= json.encode(declared.provenance_refs) then
                    state = "conflict"
                    conflicting_refs[#conflicting_refs + 1] = basis.formation_event_ref
                else
                    local complete, completion_event = work_completion.is_complete(
                        instance,
                        declared.work_unit_id,
                        declared.work_unit_version
                    )
                    if complete then
                        state = "complete"
                        completion_ref = completion_event.id
                        verification_ref = completion_event.payload.verification_ref
                        completion_refs[#completion_refs + 1] = completion_ref
                        verification_refs[#verification_refs + 1] = verification_ref
                        source_refs[#source_refs + 1] = completion_ref
                        source_refs[#source_refs + 1] = verification_ref
                        done_count = done_count + 1
                    else
                        state = "incomplete"
                    end
                end
            end
        end
        if state ~= "complete" then
            missing_ids[#missing_ids + 1] = declared.work_unit_id
        end
        artifact_records[#artifact_records + 1] = {
            work_unit_id = declared.work_unit_id,
            work_unit_version = declared.work_unit_version,
            relative_path = declared.relative_path,
            expected_kind = declared.expected_kind,
            state = state,
            completion_ref = completion_ref,
            verification_ref = verification_ref,
        }
    end

    local undeclared = {}
    for _, unit in ipairs(current_units) do
        if not declared_ids[unit.id] then
            undeclared[#undeclared + 1] = {
                work_unit_id = unit.id,
                work_unit_version = unit.version,
                relative_path = type(unit.carrier.value) == "table"
                    and unit.carrier.value.path or nil,
            }
        end
    end
    table.sort(undeclared, function(left, right)
        return tostring(left.relative_path) < tostring(right.relative_path)
    end)
    table.sort(relevant_versions, function(left, right)
        return left.object_id < right.object_id
    end)
    table.sort(missing_ids)
    local remaining_count = #normalized.artifacts - done_count
    local inspection = {
        protocol_version = artifact_set.inspection_protocol,
        inspection_id = nil,
        artifact_set_id = normalized.artifact_set_id,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        stage_id = normalized.stage_id,
        repository_id = normalized.repository_id,
        state = remaining_count == 0 and "complete" or "incomplete",
        needed_count = #normalized.artifacts,
        done_count = done_count,
        remaining_count = remaining_count,
        artifacts = artifact_records,
        completion_refs = sorted_unique(completion_refs),
        verification_refs = sorted_unique(verification_refs),
        undeclared_artifacts = undeclared,
        inventory_compatible = #undeclared == 0,
        source_refs = sorted_unique(source_refs),
        relevant_object_versions = relevant_versions,
        missing_ids = missing_ids,
        conflicting_refs = sorted_unique(conflicting_refs),
        event_truth_status = "runtime_confirmed",
        content_truth_status = content_status(normalized, used_units),
    }
    local inspection_id, inspection_err = inspection_identity(inspection)
    if not inspection_id then
        return nil, inspection_err
    end
    inspection.inspection_id = inspection_id
    return copy_value(inspection)
end

return artifact_set
