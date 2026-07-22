local digest = require("core.digest")
local json = require("core.json")
local artifact_set = require("runtime.artifact_set")
local candidate_seal = require("runtime.candidate_seal")
local corpse_module = require("runtime.corpse")
local plan_completion = require("runtime.plan_completion")
local work_completion = require("runtime.work_completion")

local completion_scope = {
    protocol_version = "runtime.completion_scope_inspection.v0",
    contract_view_protocol = "runtime.work_contract_view.v0",
}

local contract_view_keys = {
    protocol_version = true,
    process_contract_id = true,
    context = true,
    stage_id = true,
    artifact_set = true,
}

local process_contracts = {
    ["plan.only.v0"] = {plan = true},
    ["build.only.v0"] = {build = true},
    ["software.create.v0"] = {plan = true, build = true},
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

local function append_all(target, values)
    for _, value in ipairs(values or {}) do
        target[#target + 1] = value
    end
end

local function event_by_id(instance, id)
    for _, event in ipairs(instance and instance.trace or {}) do
        if event.id == id then
            return event
        end
    end
    return nil
end

local function work_mode(instance)
    local value = instance and instance.regime and instance.regime.work
        and instance.regime.work.mode
    if value ~= "plan" and value ~= "build" then
        return nil, "Packet work mode is invalid"
    end
    return value
end

local function birth_contract(instance)
    local birth = instance and instance.trace and instance.trace[1]
    local payload = birth and birth.payload
    local mode, mode_err = work_mode(instance)
    if not mode then
        return nil, mode_err
    end
    if not birth or birth.type ~= "birth" or birth.truth_status ~= "runtime_confirmed"
        or type(payload) ~= "table" or payload.packet_id ~= instance.id
        or payload.lineage_id ~= instance.lineage_id
        or payload.generation ~= instance.generation
        or payload.work_mode ~= mode then
        return nil, "Packet birth contract is malformed"
    end
    if type(payload.process_contract_id) ~= "string"
        or not process_contracts[payload.process_contract_id]
        or not process_contracts[payload.process_contract_id][mode]
        or payload.context ~= "software_task.v0"
        or type(payload.stage_id) ~= "string" or payload.stage_id == "" then
        return nil, "Packet birth work contract is malformed"
    end
    if instance.process_contract_id ~= payload.process_contract_id
        or instance.work_context ~= payload.context
        or instance.stage_id ~= payload.stage_id
        or instance.repository_id ~= payload.repository_id then
        return nil, "Packet work contract diverged from birth"
    end
    return {
        process_contract_id = payload.process_contract_id,
        context = payload.context,
        stage_id = payload.stage_id,
        repository_id = payload.repository_id,
        mode = mode,
        birth_ref = birth.id,
    }
end

local function bind_view(authority, supplied)
    if supplied == nil then
        return {
            process_contract_id = authority.process_contract_id,
            context = authority.context,
            stage_id = authority.stage_id,
            artifact_set = nil,
        }
    end
    local keys_ok, keys_err = exact_keys(supplied, contract_view_keys, "work contract view")
    if not keys_ok then
        return nil, keys_err
    end
    if supplied.protocol_version ~= completion_scope.contract_view_protocol then
        return nil, "unsupported work contract view protocol"
    end
    if supplied.process_contract_id ~= authority.process_contract_id
        or supplied.context ~= authority.context
        or supplied.stage_id ~= authority.stage_id then
        return nil, "work contract view does not match immutable birth authority"
    end
    return {
        process_contract_id = supplied.process_contract_id,
        context = supplied.context,
        stage_id = supplied.stage_id,
        artifact_set = copy_value(supplied.artifact_set),
    }
end

local function empty_components()
    return {
        boundary_candidate = {
            state = "none",
            terminalized = false,
            terminal_ref = nil,
            source_refs = {},
        },
        work_items = {
            needed_count = 0,
            done_count = 0,
            remaining_count = 0,
            done_refs = {},
            missing_ids = {},
        },
        artifact_set = {
            state = "unsupported",
            contract_ref = nil,
            artifact_refs = {},
        },
        candidate = {
            state = "unsupported",
            candidate_seal_id = nil,
            candidate_seal_event_ref = nil,
            qa_verdict_ref = nil,
        },
        generation_state = {
            state = "active",
            terminal_ref = nil,
            rejected_generation_manifest_ref = nil,
        },
        stage = {
            state = "unsupported",
            completion_ref = nil,
        },
        root = {
            software_state = "unsupported",
            documentation_state = "unsupported",
            delivery_state = "unsupported",
        },
    }
end

local function inspection_identity(value)
    local seed = copy_value(value)
    seed.inspection_id = nil
    local identity, err = digest.record(seed)
    if not identity then
        return nil, err
    end
    return "completion-scope:" .. identity
end

local function finalize(value)
    value.source_refs = sorted_unique(value.source_refs)
    value.missing_requirements = sorted_unique(value.missing_requirements)
    value.conflicting_refs = sorted_unique(value.conflicting_refs)
    value.boundary_candidate.source_refs = sorted_unique(
        value.boundary_candidate.source_refs
    )
    value.work_items.done_refs = sorted_unique(value.work_items.done_refs)
    value.work_items.missing_ids = sorted_unique(value.work_items.missing_ids)
    value.artifact_set.artifact_refs = sorted_unique(value.artifact_set.artifact_refs)
    table.sort(value.relevant_object_versions, function(left, right)
        local left_key = tostring(left.object_kind) .. ":" .. tostring(left.object_id)
        local right_key = tostring(right.object_kind) .. ":" .. tostring(right.object_id)
        if left_key ~= right_key then
            return left_key < right_key
        end
        return (left.version or 0) < (right.version or 0)
    end)
    local identity, identity_err = inspection_identity(value)
    if not identity then
        return nil, identity_err
    end
    value.inspection_id = identity
    return copy_value(value)
end

local function base_inspection(subject_kind, identity, view)
    local parts = empty_components()
    return {
        protocol_version = completion_scope.protocol_version,
        inspection_id = nil,
        subject_kind = subject_kind,
        packet_id = identity.packet_id,
        lineage_id = identity.lineage_id,
        generation = identity.generation,
        stage_id = view.stage_id,
        process_contract_id = view.process_contract_id,
        context = view.context,
        highest_scope = "none",
        boundary_candidate = parts.boundary_candidate,
        work_items = parts.work_items,
        artifact_set = parts.artifact_set,
        candidate = parts.candidate,
        generation_state = parts.generation_state,
        stage = parts.stage,
        root = parts.root,
        source_refs = {},
        relevant_object_versions = {},
        missing_requirements = {},
        conflicting_refs = {},
        event_truth_status = "runtime_confirmed",
        content_truth_status = "runtime_confirmed",
    }
end

local function repository_units(instance)
    local result = {}
    for _, id in ipairs(instance.field and instance.field.unit_order or {}) do
        local unit = instance.field.units[id]
        if type(unit) == "table" and unit.generation == instance.generation
            and (unit.activation == "live" or unit.activation == "selected")
            and type(unit.carrier) == "table"
            and unit.carrier.kind == "repository.create_text_file.v0" then
            result[#result + 1] = unit
        end
    end
    return result
end

local function inspect_build_packet(instance, view, result)
    result.candidate.state = "unsealed"
    local progress = work_completion.repository_progress(instance)
    result.work_items.needed_count = progress.needed_count
    result.work_items.done_count = progress.done_count
    result.work_items.remaining_count = progress.remaining_count
    result.work_items.missing_ids = copy_value(progress.remaining)
    if progress.done_count > 0 then
        result.highest_scope = "work_item"
    end

    for _, unit in ipairs(repository_units(instance)) do
        result.relevant_object_versions[#result.relevant_object_versions + 1] = {
            object_kind = "field_unit",
            object_id = unit.id,
            version = unit.version,
            source_ref = unit.created_event_id,
        }
        local complete, completion_event = work_completion.is_complete(
            instance,
            unit.id,
            unit.version
        )
        if complete then
            result.work_items.done_refs[#result.work_items.done_refs + 1] = completion_event.id
            result.source_refs[#result.source_refs + 1] = completion_event.id
        end
    end

    local derived_set, derived_err = artifact_set.derive(instance)
    if not derived_set then
        if type(derived_err) ~= "table" then
            return nil, derived_err
        end
        result.missing_requirements[#result.missing_requirements + 1] =
            "artifact_set_contract"
        return true
    end
    if view.artifact_set ~= nil then
        local supplied, supplied_err = artifact_set.validate(view.artifact_set)
        if not supplied then
            return nil, supplied_err
        end
        if not artifact_set.same(supplied, derived_set) then
            return nil, "supplied artifact set does not match body derivation"
        end
    end
    local set_view, set_err = artifact_set.inspect(instance, derived_set)
    if not set_view then
        return nil, set_err
    end
    result.artifact_set.contract_ref = set_view.artifact_set_id
    result.artifact_set.artifact_refs = copy_value(set_view.completion_refs)
    append_all(result.source_refs, set_view.source_refs)
    append_all(result.relevant_object_versions, set_view.relevant_object_versions)
    append_all(result.conflicting_refs, set_view.conflicting_refs)
    if set_view.state == "complete" and set_view.inventory_compatible then
        result.artifact_set.state = "complete"
        result.highest_scope = "artifact_set"

        local seal, seal_event, seal_err = candidate_seal.current(instance)
        if seal then
            result.candidate.state = "sealed"
            result.candidate.candidate_seal_id = seal.candidate_seal_id
            result.candidate.candidate_seal_event_ref = seal_event.id
            result.highest_scope = "candidate_sealed"
            result.source_refs[#result.source_refs + 1] = seal_event.id
            result.source_refs[#result.source_refs + 1] = seal.candidate_seal_id
            append_all(result.source_refs, seal.source_refs)
            result.content_truth_status = seal.content_truth_status
        elseif seal_err == "candidate_seal_absent" then
            result.missing_requirements[#result.missing_requirements + 1] =
                "candidate_seal"
        else
            return nil, seal_err
        end
    else
        result.artifact_set.state = "incomplete"
        if not set_view.inventory_compatible then
            result.missing_requirements[#result.missing_requirements + 1] =
                "artifact_set_inventory_compatible"
        end
    end
    if result.content_truth_status == "runtime_confirmed" then
        result.content_truth_status = set_view.content_truth_status
    end
    return true
end

local function plan_manifest(instance)
    local manifest = instance and instance.manifest
    local terminal = instance and instance.terminal
    local output = manifest and manifest.output
    local structured = output and output.structured
    if instance.status ~= "dead" or type(terminal) ~= "table"
        or terminal.kind ~= "manifest" or terminal.cause ~= "complete"
        or type(manifest) ~= "table" or manifest.mode ~= "plan_delivery"
        or type(output) ~= "table" or output.type ~= "plan" or output.status ~= "complete"
        or type(structured) ~= "table" or structured.protocol_version ~= "plan.result.v0"
        or type(terminal.manifest_ref) ~= "string"
        or type(terminal.event_id) ~= "string" then
        return nil
    end
    local manifest_event = event_by_id(instance, terminal.manifest_ref)
    local terminal_event = event_by_id(instance, terminal.event_id)
    if not manifest_event or manifest_event.type ~= "manifest"
        or manifest_event.truth_status ~= "runtime_confirmed"
        or not terminal_event or terminal_event.type ~= "terminal"
        or terminal_event.truth_status ~= "runtime_confirmed"
        or json.encode(manifest_event.payload) ~= json.encode(manifest) then
        return nil
    end
    return {
        manifest = manifest,
        structured = structured,
        manifest_ref = manifest_event.id,
        terminal_ref = terminal_event.id,
    }
end

local function plan_candidate(instance)
    local inspection, inspection_err = plan_completion.inspect(instance)
    if not inspection then
        return nil, inspection_err
    end
    if inspection.state ~= "complete_candidate" or not inspection.candidate then
        return nil, nil, inspection
    end
    return inspection.candidate, nil, inspection
end

local function inspect_plan_packet(instance, result)
    local terminal_plan = plan_manifest(instance)
    if terminal_plan then
        local items = terminal_plan.structured.items or {}
        result.work_items.needed_count = #items
        result.work_items.done_count = #items
        result.work_items.remaining_count = 0
        result.highest_scope = #items > 0 and "work_item" or "none"
        result.boundary_candidate = {
            state = "plan_stage_ready",
            terminalized = true,
            terminal_ref = terminal_plan.terminal_ref,
            source_refs = {
                terminal_plan.manifest_ref,
                terminal_plan.terminal_ref,
                terminal_plan.manifest.assembly
                    and terminal_plan.manifest.assembly.assessment_ref,
            },
        }
        result.generation_state = {
            state = "terminal_candidate",
            terminal_ref = terminal_plan.terminal_ref,
            rejected_generation_manifest_ref = nil,
        }
        append_all(result.source_refs, result.boundary_candidate.source_refs)
        result.content_truth_status = terminal_plan.manifest.content_truth_status
            or "semantic_proposal"
        result.missing_requirements[#result.missing_requirements + 1] =
            "lineage_stage_assessment"
        return true
    end

    local candidate, candidate_err = plan_candidate(instance)
    if candidate_err then
        return nil, candidate_err
    end
    if not candidate then
        result.missing_requirements[#result.missing_requirements + 1] =
            "plan_structure"
        return true
    end
    result.work_items.needed_count = #(candidate.formed_unit_ids or {})
    result.work_items.done_count = #(candidate.formed_unit_ids or {})
    result.work_items.remaining_count = 0
    result.highest_scope = result.work_items.done_count > 0 and "work_item" or "none"
    append_all(result.source_refs, candidate.provenance_refs)
    for _, id in ipairs(candidate.formed_unit_ids or {}) do
        result.relevant_object_versions[#result.relevant_object_versions + 1] = {
            object_kind = "field_unit",
            object_id = id,
            version = candidate.formed_unit_versions[id],
            source_ref = candidate.formation_event_ref,
        }
    end
    local assessment, assessment_err = plan_completion.find_assessment(instance, candidate)
    if assessment then
        result.source_refs[#result.source_refs + 1] = assessment.event.id
    elseif assessment_err ~= "plan_assessment_absent" then
        result.missing_requirements[#result.missing_requirements + 1] =
            "current_plan_assessment"
    else
        result.missing_requirements[#result.missing_requirements + 1] =
            "plan_completion_review"
    end
    result.content_truth_status = candidate.source_truth_status
    return true
end

function completion_scope.inspect_packet(instance, contract_view)
    if type(instance) ~= "table" or type(instance.id) ~= "string" then
        return nil, "completion scope requires Packet"
    end
    local authority, authority_err = birth_contract(instance)
    if not authority then
        return nil, authority_err
    end
    local view, view_err = bind_view(authority, contract_view)
    if not view then
        return nil, view_err
    end
    local result = base_inspection("packet", {
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
    }, view)
    result.source_refs[#result.source_refs + 1] = authority.birth_ref
    local ok, inspect_err
    if authority.mode == "build" then
        ok, inspect_err = inspect_build_packet(instance, view, result)
    else
        ok, inspect_err = inspect_plan_packet(instance, result)
    end
    if not ok then
        return nil, inspect_err
    end
    return finalize(result)
end

local function corpse_authority(record)
    local mode = record.work_mode
    local process_contract_id = record.process_contract_id
        or (mode == "plan" and "plan.only.v0" or mode == "build" and "build.only.v0")
    local context = record.context or "software_task.v0"
    if (mode ~= "plan" and mode ~= "build")
        or not process_contracts[process_contract_id]
        or not process_contracts[process_contract_id][mode]
        or context ~= "software_task.v0"
        or type(record.stage_id) ~= "string" or record.stage_id == "" then
        return nil, "corpse work contract is unavailable"
    end
    return {
        process_contract_id = process_contract_id,
        context = context,
        stage_id = record.stage_id,
        repository_id = record.repository_id,
        mode = mode,
        birth_ref = record.corpse_id,
    }
end

local function corpse_plan_manifest(record)
    local manifest = record.manifest
    local output = manifest and manifest.output
    local structured = output and output.structured
    if record.terminal_kind ~= "manifest" or record.death_cause ~= "complete"
        or type(manifest) ~= "table" or manifest.mode ~= "plan_delivery"
        or type(output) ~= "table" or output.type ~= "plan" or output.status ~= "complete"
        or type(structured) ~= "table" or structured.protocol_version ~= "plan.result.v0"
        or type(record.manifest_trace_ref) ~= "string"
        or type(record.terminal_trace_ref) ~= "string" then
        return nil
    end
    return manifest, structured
end

function completion_scope.inspect_corpse(record, contract_view)
    local valid, valid_err = corpse_module.verify(record)
    if not valid then
        return nil, valid_err
    end
    local authority, authority_err = corpse_authority(record)
    if not authority then
        return nil, authority_err
    end
    local view, view_err = bind_view(authority, contract_view)
    if not view then
        return nil, view_err
    end
    local result = base_inspection("corpse", {
        packet_id = record.packet_id,
        lineage_id = record.lineage_id,
        generation = record.generation,
    }, view)
    result.generation_state = {
        state = "terminal_incomplete",
        terminal_ref = record.corpse_id,
        rejected_generation_manifest_ref = nil,
    }
    result.source_refs = copy_value(record.completion_evidence_refs or {})
    result.source_refs[#result.source_refs + 1] = record.corpse_id
    result.missing_requirements[#result.missing_requirements + 1] =
        "candidate_seal_reader"

    if authority.mode == "plan" then
        local manifest, structured = corpse_plan_manifest(record)
        if manifest then
            local items = structured.items or {}
            result.work_items.needed_count = #items
            result.work_items.done_count = #items
            result.work_items.remaining_count = 0
            result.highest_scope = #items > 0 and "work_item" or "none"
            result.boundary_candidate = {
                state = "plan_stage_ready",
                terminalized = true,
                terminal_ref = record.corpse_id,
                source_refs = {
                    record.corpse_id,
                    record.manifest_trace_ref,
                    record.terminal_trace_ref,
                    manifest.assembly and manifest.assembly.assessment_ref,
                },
            }
            result.generation_state.state = "terminal_candidate"
            result.content_truth_status = manifest.content_truth_status
                or "semantic_proposal"
            result.missing_requirements[#result.missing_requirements + 1] =
                "lineage_stage_assessment"
        else
            result.missing_requirements[#result.missing_requirements + 1] =
                "plan_terminal_projection"
        end
    else
        local output = record.manifest and record.manifest.output
        local structured = output and output.structured
        if type(structured) == "table"
            and structured.protocol_version == "repository.result.v0" then
            result.work_items.needed_count = 1
            result.work_items.done_count = 1
            result.work_items.remaining_count = 0
            result.highest_scope = "work_item"
        end
        result.missing_requirements[#result.missing_requirements + 1] =
            "artifact_set_corpse_projection"
    end
    return finalize(result)
end

function completion_scope.inspect_lineage(lineage, contract_view)
    if type(lineage) ~= "table" or lineage.kind ~= "proc17_lineage"
        or lineage.protocol_version ~= "lineage.in_memory.v0"
        or type(lineage.lineage_id) ~= "string" then
        return nil, "completion scope requires verified lineage"
    end
    local mode = lineage.work_mode
    local authority = {
        process_contract_id = mode == "plan" and "plan.only.v0" or "build.only.v0",
        context = "software_task.v0",
        stage_id = "stage:" .. lineage.lineage_id .. ":lineage:" .. tostring(mode),
        mode = mode,
        birth_ref = lineage.ledger and lineage.ledger[1] and lineage.ledger[1].id,
    }
    local view, view_err = bind_view(authority, contract_view)
    if not view then
        return nil, view_err
    end
    local result = base_inspection("lineage", {
        packet_id = lineage.current_packet_id,
        lineage_id = lineage.lineage_id,
        generation = lineage.current_generation,
    }, view)
    result.generation_state.state = "unsupported"
    result.missing_requirements = {
        "lineage_stage_scope_reader",
        "lineage_software_scope_reader",
        "lineage_root_delivery_reader",
    }
    if authority.birth_ref then
        result.source_refs[1] = authority.birth_ref
    end
    return finalize(result)
end

function completion_scope.verify(value)
    if type(value) ~= "table"
        or value.protocol_version ~= completion_scope.protocol_version
        or type(value.inspection_id) ~= "string"
        or (value.subject_kind ~= "packet" and value.subject_kind ~= "corpse"
            and value.subject_kind ~= "lineage")
        or not process_contracts[value.process_contract_id]
        or value.context ~= "software_task.v0"
        or type(value.boundary_candidate) ~= "table"
        or type(value.work_items) ~= "table"
        or type(value.artifact_set) ~= "table"
        or type(value.candidate) ~= "table"
        or type(value.generation_state) ~= "table"
        or type(value.stage) ~= "table"
        or type(value.root) ~= "table"
        or value.event_truth_status ~= "runtime_confirmed" then
        return nil, "invalid completion scope inspection"
    end
    if value.subject_kind ~= "lineage"
        and (value.highest_scope == "stage"
            or value.highest_scope == "software_accepted"
            or value.highest_scope == "root_delivery") then
        return nil, "Packet-local subject exceeded scope ceiling"
    end
    local expected, expected_err = inspection_identity(value)
    if not expected then
        return nil, expected_err
    end
    if expected ~= value.inspection_id then
        return nil, "completion scope identity mismatch"
    end
    return true
end

function completion_scope.same(left, right)
    local left_ok = completion_scope.verify(left)
    local right_ok = completion_scope.verify(right)
    if not left_ok or not right_ok then
        return false
    end
    return json.encode(left) == json.encode(right)
end

return completion_scope
