local digest = require("core.digest")
local json = require("core.json")
local completion_scope = require("runtime.completion_scope")
local plan_completion = require("runtime.plan_completion")

local work_layer = {
    protocol_version = "runtime.work_layer_projection.v0",
}

local valid_glyphs = { ["⋯"] = true, ["⊞"] = true, ["◈"] = true, ["▲"] = true }
local valid_states = {
    forming = true,
    checking = true,
    crystallized = true,
    crystallizing_verdict = true,
    boundary = true,
    unsupported = true,
}
local valid_scopes = {
    none = true,
    work_item = true,
    artifact_set = true,
    candidate_sealed = true,
}
local valid_candidates = {
    none = true,
    plan_stage_ready = true,
    software_acceptance_ready = true,
    rejected_generation_recovery_ready = true,
}
local valid_alignments = {
    not_applicable = true,
    aligned = true,
    diverged = true,
    unsupported = true,
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

local function identity(value)
    local seed = copy_value(value)
    seed.projection_id = nil
    local value_digest, value_err = digest.record(seed)
    if not value_digest then
        return nil, value_err
    end
    return "work-layer:" .. value_digest
end

local function mode_from_contract(process_contract_id)
    if process_contract_id == "plan.only.v0" then
        return "plan"
    end
    if process_contract_id == "build.only.v0" then
        return "build"
    end
    return nil
end

local function packet_mode(instance)
    local mode = instance and instance.regime and instance.regime.work
        and instance.regime.work.mode
    if mode == "plan" or mode == "build" then
        return mode
    end
    return nil
end

local function base(scope, mode, revisions)
    return {
        protocol_version = work_layer.protocol_version,
        projection_id = nil,
        packet_id = scope.packet_id,
        lineage_id = scope.lineage_id,
        generation = scope.generation,
        stage_id = scope.stage_id,
        process_contract_id = scope.process_contract_id,
        context = scope.context,
        mode = mode,
        glyph = nil,
        state = "unsupported",
        reason = "work_layer_unsupported",
        completion_scope = scope.highest_scope,
        candidate_alignment = scope.candidate.artifact_alignment,
        boundary_candidate = scope.boundary_candidate.state,
        boundary_terminalized = scope.boundary_candidate.terminalized,
        boundary_terminal_ref = scope.boundary_candidate.terminal_ref,
        source_refs = copy_value(scope.source_refs),
        relevant_object_versions = copy_value(scope.relevant_object_versions),
        relevant_revisions = copy_value(revisions or {}),
        missing_requirements = copy_value(scope.missing_requirements),
        conflicting_refs = copy_value(scope.conflicting_refs),
        event_truth_status = "runtime_confirmed",
        content_truth_status = scope.content_truth_status,
    }
end

local function finish(value)
    value.source_refs = sorted_unique(value.source_refs)
    value.missing_requirements = sorted_unique(value.missing_requirements)
    value.conflicting_refs = sorted_unique(value.conflicting_refs)
    local projection_id, projection_err = identity(value)
    if not projection_id then
        return nil, projection_err
    end
    value.projection_id = projection_id
    return copy_value(value)
end

local function exact_plan_terminal(scope, value)
    if scope.boundary_candidate.state == "plan_stage_ready"
        and scope.boundary_candidate.terminalized == true then
        value.glyph = "▲"
        value.state = "boundary"
        value.reason = "plan_stage_candidate_ready"
        value.missing_requirements[#value.missing_requirements + 1] =
            "lineage_stage_transition"
        return true
    end
    return false
end

local function derive_plan_packet(instance, scope, value)
    if exact_plan_terminal(scope, value) then
        return true
    end
    local inspection, inspection_err = plan_completion.inspect(instance)
    if not inspection then
        return nil, inspection_err
    end
    local candidate = inspection.candidate
    if inspection.state == "complete_candidate" and candidate then
        append_all(value.source_refs, candidate.provenance_refs)
        local assessment, assessment_err = plan_completion.find_assessment(instance, candidate)
        if assessment then
            value.glyph = "◈"
            value.state = "crystallized"
            value.reason = "plan_export_ready"
            value.source_refs[#value.source_refs + 1] = assessment.event.id
            value.missing_requirements[#value.missing_requirements + 1] =
                "typed_plan_delivery"
            return true
        end
        if assessment_err ~= "plan_assessment_absent" then
            value.glyph = "⊞"
            value.state = "checking"
            value.reason = "plan_structure_requires_review"
            value.missing_requirements[#value.missing_requirements + 1] =
                "current_plan_completion_review"
            return true
        end
        value.glyph = "⊞"
        value.state = "checking"
        value.reason = "plan_structure_requires_review"
        value.missing_requirements[#value.missing_requirements + 1] =
            "plan_completion_review"
        return true
    end

    value.glyph = "⋯"
    value.state = "forming"
    value.reason = "plan_structure_missing"
    value.missing_requirements[#value.missing_requirements + 1] =
        "semantic_structural_formation"
    if inspection.state ~= "absent" then
        value.missing_requirements[#value.missing_requirements + 1] =
            "exact_current_plan_structure"
    end
    return true
end

local function derive_plan_corpse(scope, value)
    if exact_plan_terminal(scope, value) then
        return true
    end
    value.state = "unsupported"
    value.reason = "plan_corpse_terminal_projection_missing"
    value.missing_requirements[#value.missing_requirements + 1] =
        "plan_terminal_projection"
    return true
end

local function derive_build(scope, value)
    local set_state = scope.artifact_set.state
    if scope.candidate.state == "sealed"
        and scope.candidate.artifact_alignment == "diverged" then
        value.glyph = "⊞"
        value.state = "checking"
        value.reason = "candidate_sealed_body_conflict"
        value.missing_requirements[#value.missing_requirements + 1] =
            "fresh_generation_plan_for:" .. scope.candidate.candidate_seal_id
        return true
    end
    if scope.candidate.state == "sealed" then
        value.glyph = "⊞"
        value.state = "checking"
        value.reason = "candidate_sealed_qa_missing"
        value.missing_requirements[#value.missing_requirements + 1] =
            "qa_verdict_for:" .. scope.candidate.candidate_seal_id
        return true
    end
    if set_state == "complete" then
        value.glyph = "⋯"
        value.state = "forming"
        value.reason = "artifact_set_complete_seal_missing"
        value.missing_requirements[#value.missing_requirements + 1] =
            "candidate_seal"
        return true
    end
    if set_state == "incomplete" then
        value.glyph = "⋯"
        value.state = "forming"
        value.reason = "candidate_materialization_incomplete"
        value.missing_requirements[#value.missing_requirements + 1] =
            "bounded_create_only_materialization"
        return true
    end
    if scope.work_items.needed_count > 0
        or scope.work_items.done_count > 0
        or scope.work_items.remaining_count > 0 then
        value.glyph = "⋯"
        value.state = "forming"
        value.reason = scope.work_items.remaining_count > 0
            and "candidate_materialization_incomplete"
            or "artifact_set_contract_missing"
        value.missing_requirements[#value.missing_requirements + 1] =
            "declared_artifact_set"
        return true
    end
    value.glyph = "⋯"
    value.state = "forming"
    value.reason = "candidate_materialization_incomplete"
    value.missing_requirements[#value.missing_requirements + 1] =
        "repository_work_structure"
    return true
end

local function packet_revisions(instance)
    local result = {}
    for _, key in ipairs({
        "potential",
        "relations_raw",
        "relations_active",
        "calm",
        "constraints",
        "evidence",
        "history",
    }) do
        result[key] = instance.revisions and instance.revisions[key] or 0
    end
    return result
end

function work_layer.inspect_packet(instance, contract_view)
    local scope, scope_err = completion_scope.inspect_packet(instance, contract_view)
    if not scope then
        return nil, scope_err
    end
    local mode = packet_mode(instance)
    if not mode then
        return nil, "Packet work mode is invalid"
    end
    local value = base(scope, mode, packet_revisions(instance))
    local ok, derive_err
    if mode == "plan" then
        ok, derive_err = derive_plan_packet(instance, scope, value)
    else
        ok, derive_err = derive_build(scope, value)
    end
    if not ok then
        return nil, derive_err
    end
    return finish(value)
end

function work_layer.inspect_corpse(record, contract_view)
    local scope, scope_err = completion_scope.inspect_corpse(record, contract_view)
    if not scope then
        return nil, scope_err
    end
    local mode = record.work_mode or mode_from_contract(scope.process_contract_id)
    if mode ~= "plan" and mode ~= "build" then
        return nil, "corpse work mode is unavailable"
    end
    local value = base(scope, mode, {})
    if mode == "plan" then
        derive_plan_corpse(scope, value)
    else
        derive_build(scope, value)
    end
    return finish(value)
end

function work_layer.verify(value)
    if type(value) ~= "table"
        or value.protocol_version ~= work_layer.protocol_version
        or type(value.projection_id) ~= "string"
        or type(value.packet_id) ~= "string"
        or type(value.generation) ~= "number" or value.generation < 1
        or (value.mode ~= "plan" and value.mode ~= "build")
        or not valid_states[value.state]
        or (value.glyph ~= nil and not valid_glyphs[value.glyph])
        or not valid_scopes[value.completion_scope]
        or not valid_alignments[value.candidate_alignment]
        or not valid_candidates[value.boundary_candidate]
        or type(value.boundary_terminalized) ~= "boolean"
        or type(value.reason) ~= "string" or value.reason == ""
        or type(value.source_refs) ~= "table"
        or type(value.relevant_object_versions) ~= "table"
        or type(value.relevant_revisions) ~= "table"
        or type(value.missing_requirements) ~= "table"
        or type(value.conflicting_refs) ~= "table"
        or value.event_truth_status ~= "runtime_confirmed" then
        return nil, "invalid work layer projection"
    end
    if value.state == "unsupported" and value.glyph ~= nil then
        return nil, "unsupported work layer cannot claim glyph"
    end
    local expected, expected_err = identity(value)
    if not expected then
        return nil, expected_err
    end
    if expected ~= value.projection_id then
        return nil, "work layer identity mismatch"
    end
    return true
end

function work_layer.same(left, right)
    local left_ok = work_layer.verify(left)
    local right_ok = work_layer.verify(right)
    if not left_ok or not right_ok then
        return false
    end
    return json.encode(left) == json.encode(right)
end

return work_layer
