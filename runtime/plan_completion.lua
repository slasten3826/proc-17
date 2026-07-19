local json = require("core.json")
local field = require("runtime.field")
local choice_inspection = require("runtime.choice_inspection")
local structure_inspection = require("runtime.structure_inspection")
local upper_coverage = require("runtime.upper_coverage")

local completion = {
    inspection_protocol = "plan.completion_inspection.v0",
    candidate_protocol = "plan.delivery_candidate.v0",
    assessment_protocol = "plan.completion_assessment.v0",
    result_protocol = "plan.result.v0",
    review_consumer_id = "runtime.plan_completion.v0",
    delivery_consumer_id = "manifest.plan_delivery.v0",
}

local accepted_shapes = {
    work_sequence = true,
    work_hierarchy = true,
    artifact_set = true,
    alternative_set = true,
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

local function sorted_unique(values)
    local seen = {}
    local result = {}
    for _, value in ipairs(values or {}) do
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function merge_refs(...)
    local result = {}
    for index = 1, select("#", ...) do
        for _, value in ipairs(select(index, ...) or {}) do
            result[#result + 1] = value
        end
    end
    return sorted_unique(result)
end

local function exact_ref(id, version)
    return table.concat({"coverage", "field_unit", id, tostring(version)}, ":")
end

local function event_by_id(instance, id)
    for _, event in ipairs(instance.trace or {}) do
        if event.id == id then
            return event
        end
    end
    return nil
end

local function identity_map_by_id(instance, id)
    for _, record in ipairs(instance.field and instance.field.identity_maps or {}) do
        if record.id == id then
            return record
        end
    end
    return nil
end

local function loss_record_by_ref(instance, ref)
    for _, record in ipairs(instance.boundary and instance.boundary.loss_records or {}) do
        if record.trace_event_id == ref then
            return record
        end
    end
    return nil
end

local function diagnostic(kind, reason, refs)
    return {
        kind = kind,
        reason = reason or kind,
        scope_refs = sorted_unique(refs or {}),
        event_truth_status = "runtime_confirmed",
    }
end

local function result(state, work_mode, candidate, diagnostics)
    return {
        protocol_version = completion.inspection_protocol,
        work_mode = work_mode,
        state = state,
        candidate = copy_value(candidate),
        diagnostics = copy_value(diagnostics or {}),
        event_truth_status = "runtime_confirmed",
    }
end

local function current_work_mode(instance)
    local work = instance.regime and instance.regime.work
    if type(work) ~= "table" or work.protocol_version ~= "packet.work_regime.v0"
        or (work.mode ~= "plan" and work.mode ~= "build") then
        return nil, "invalid Packet work regime"
    end
    if instance.metadata and instance.metadata.work_mode ~= nil
        and instance.metadata.work_mode ~= work.mode then
        return nil, "Packet work mode mirror mismatch"
    end
    return work.mode
end

local function content_status(units)
    local status
    for _, unit in ipairs(units or {}) do
        local current = unit.content_truth_status or "unknown"
        if status == nil then
            status = current
        elseif status ~= current then
            return "mixed"
        end
    end
    return status or "unknown"
end

local function latest_validation_rejected(instance)
    local validations = instance.boundary and instance.boundary.validations or {}
    local latest = validations[#validations]
    return latest and latest.status == "rejected", latest
end

local function formation_records(instance, candidate)
    local event = event_by_id(instance, candidate.formation_event_ref)
    local payload = event and event.payload or nil
    if not event or event.type ~= "structure_formation"
        or event.operator ~= "☵" or event.truth_status ~= "runtime_confirmed"
        or type(payload) ~= "table"
        or payload.protocol_version ~= structure_inspection.formation_protocol then
        return nil, "plan formation event is malformed"
    end
    local crystallization = event_by_id(instance, payload.crystallization_event_ref)
    local identity_map = identity_map_by_id(instance, payload.identity_map_ref)
    local loss_record = loss_record_by_ref(instance, payload.loss_record_ref)
    if not crystallization or crystallization.type ~= "crystallization"
        or not identity_map or identity_map.shadow_only == true
        or identity_map.trace_event_id ~= payload.identity_map_event_ref
        or not loss_record
        or loss_record.trace_event_id ~= payload.loss_record_ref
        or not same_value(loss_record.loss, crystallization.payload.loss) then
        return nil, "plan formation proof is incomplete"
    end
    return {
        event = event,
        payload = payload,
        crystallization = crystallization,
        identity_map = identity_map,
        loss_record = loss_record,
    }
end

local function complete_loss(records)
    local loss_value = records.loss_record.loss or {}
    if loss_value.kind ~= "structure_projection_loss" then
        return nil, "plan formation has unsupported loss record"
    end
    if (loss_value.omitted_count or 0) ~= 0
        or (loss_value.omitted_edge_count or 0) ~= 0
        or loss_value.truncated == true
        or loss_value.loss_log_truncated == true then
        return nil, "plan formation is partial"
    end
    return copy_value(loss_value)
end

local function resolve_units(instance, formation)
    local ids = formation.formed_unit_ids
    if type(ids) ~= "table" or #ids == 0 then
        return nil, "plan formation has no units"
    end
    local units = {}
    local versions = {}
    local refs = {}
    local seen = {}
    for _, id in ipairs(ids) do
        if type(id) ~= "string" or id == "" or seen[id] then
            return nil, "plan formation unit order is malformed"
        end
        seen[id] = true
        local unit = field.get_unit(instance, id)
        if not unit or unit.generation ~= instance.generation
            or unit.created_by ~= "☵" or unit.activation == "dissolved" then
            return nil, "plan formation unit is missing or dissolved"
        end
        units[#units + 1] = unit
        versions[id] = unit.version
        refs[#refs + 1] = exact_ref(id, unit.version)
    end
    return {
        ids = copy_value(ids),
        units = units,
        versions = versions,
        refs = sorted_unique(refs),
    }
end

local function resolve_coverage(instance, units, options)
    local view, view_err = upper_coverage.derive(instance, options or {})
    if not view then
        return nil, view_err
    end
    if view.truncated then
        return nil, "plan upper coverage is incomplete"
    end
    local covered = {}
    for _, entry in ipairs(view.entries or {}) do
        if entry.observation_class == "material" then
            covered[entry.object_id] = entry
        end
    end
    local observation_refs = {}
    for _, unit in ipairs(units) do
        local entry = covered[unit.id]
        if not entry or entry.version ~= unit.version
            or entry.sensor ~= "field_native" then
            return nil, "plan material version is not field-native observed"
        end
        observation_refs[#observation_refs + 1] = entry.observation_event_ref
    end
    return sorted_unique(observation_refs)
end

local function choice_event_for(instance, formation_ref)
    for index = #(instance.trace or {}), 1, -1 do
        local event = instance.trace[index]
        local payload = event.type == "choice" and event.payload or nil
        if type(payload) == "table" and payload.mode == "alternative_collapse"
            and payload.choice_set_ref == formation_ref then
            return event
        end
    end
    return nil
end

local function partition_non_choice(units)
    local deliverable = {}
    for _, unit in ipairs(units) do
        if unit.activation ~= "live" and unit.activation ~= "selected" then
            return nil, "non-choice plan contains suppressed material"
        end
        deliverable[#deliverable + 1] = unit.id
    end
    return {
        deliverable_ids = deliverable,
        selected_ids = {},
        suppressed_ids = {},
        selection_mode = "none",
    }
end

local function partition_choice(instance, records, unit_view, options)
    local formation = records.payload
    local contract = formation.choice_contract
    if type(contract) ~= "table"
        or not same_value(contract.ordered_alternative_ids, unit_view.ids) then
        return nil, "alternative plan choice contract is malformed"
    end
    local choice_view, choice_err = choice_inspection.derive(
        instance,
        options and options.choice_bounds
    )
    if not choice_view then
        return nil, choice_err
    end
    if choice_view.qualification_status ~= "qualified" then
        return nil, "alternative plan choice scope is incomplete"
    end
    local current_set
    local missing_set
    for _, set in ipairs(choice_view.current or {}) do
        if set.choice_set_ref == records.event.id then
            current_set = set
        end
    end
    for _, set in ipairs(choice_view.missing or {}) do
        if set.choice_set_ref == records.event.id then
            missing_set = set
        end
    end
    if missing_set then
        return nil, "alternative plan still requires choice"
    end
    if not current_set then
        return nil, "alternative plan choice state is unavailable"
    end

    if #unit_view.ids == 1 then
        local unit = unit_view.units[1]
        if current_set.collapse_status ~= "confirmation"
            or (unit.activation ~= "live" and unit.activation ~= "selected") then
            return nil, "single alternative is not a confirmation"
        end
        return {
            deliverable_ids = {unit.id},
            selected_ids = {unit.id},
            suppressed_ids = {},
            selection_mode = "confirmation",
        }
    end

    local event = choice_event_for(instance, records.event.id)
    local payload = event and event.payload or nil
    if not event or event.operator ~= "☳" or event.truth_status ~= "runtime_confirmed"
        or type(payload) ~= "table" or type(payload.selected_ids) ~= "table"
        or #payload.selected_ids ~= 1 or type(payload.suppressed_ids) ~= "table"
        or #payload.suppressed_ids ~= #unit_view.ids - 1
        or type(payload.post_versions) ~= "table" then
        return nil, "alternative plan collapse event is missing"
    end
    local expected_selected = payload.selected_ids[1]
    local seen = {[expected_selected] = true}
    for _, id in ipairs(payload.suppressed_ids) do
        if seen[id] then
            return nil, "alternative plan collapse partition overlaps"
        end
        seen[id] = true
    end
    for _, id in ipairs(unit_view.ids) do
        if not seen[id] or payload.post_versions[id] ~= unit_view.versions[id] then
            return nil, "alternative plan collapse versions are stale"
        end
        local unit
        for _, candidate in ipairs(unit_view.units) do
            if candidate.id == id then
                unit = candidate
                break
            end
        end
        local expected_activation = id == expected_selected and "selected" or "suppressed"
        if not unit or unit.activation ~= expected_activation then
            return nil, "alternative plan activation partition mismatch"
        end
    end
    return {
        deliverable_ids = {expected_selected},
        selected_ids = {expected_selected},
        suppressed_ids = copy_value(payload.suppressed_ids),
        selection_mode = "alternative_collapse",
        choice_event_ref = event.id,
        choice_loss = copy_value(payload.loss),
    }
end

local function calm_structure(instance, records)
    local current = instance.calm and instance.calm.current
    local marker = type(current) == "table" and current.structure_formation or nil
    if type(marker) ~= "table"
        or marker.source_unit_id ~= records.payload.source.unit_id
        or marker.source_version ~= records.payload.source.version
        or marker.identity_map_ref ~= records.payload.identity_map_ref
        or not same_value(marker.formed_unit_ids, records.payload.formed_unit_ids) then
        return nil, "current CALM structure does not match formation"
    end
    return current
end

local function validate_connections(shape, connections, formed_ids)
    if type(connections) ~= "table" then
        return nil, "plan connections must be table"
    end
    local members = {}
    for _, id in ipairs(formed_ids or {}) do
        members[id] = true
    end
    for _, connection in ipairs(connections) do
        if type(connection) ~= "table"
            or not members[connection.from] or not members[connection.to]
            or type(connection.relation) ~= "string" or connection.relation == "" then
            return nil, "plan hierarchy connection is malformed"
        end
    end
    return true
end

local function candidate_identity(value)
    local body = copy_value(value)
    body.candidate_id = nil
    return "plan-candidate:" .. json.encode(body)
end

function completion.inspect(instance, options)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    options = options or {}
    local work_mode, mode_err = current_work_mode(instance)
    if not work_mode then
        return nil, mode_err
    end
    if work_mode ~= "plan" then
        return result("absent", work_mode, nil, {
            diagnostic("plan_mode_absent", "Packet work mode is not plan"),
        })
    end

    local structures, structures_err = structure_inspection.derive(
        instance,
        options.structure_bounds
    )
    if not structures then
        return nil, structures_err
    end
    if structures.qualification_status ~= "qualified" or structures.truncated then
        return result("incomplete_scope", work_mode, nil, {
            diagnostic("plan_material_incomplete_scope"),
        })
    end
    if #(structures.missing or {}) > 0 then
        return result("absent", work_mode, nil, {
            diagnostic("plan_structure_formation_missing"),
        })
    end
    for _, item in ipairs(structures.diagnostics or {}) do
        if item.kind == "formation_repair_pressure"
            or item.kind == "malformed_structure_formation" then
            return result("blocked", work_mode, nil, {
                diagnostic("plan_material_blocked", item.reason, item.scope_refs),
            })
        end
    end
    if #(structures.current or {}) == 0 then
        return result("absent", work_mode, nil, {
            diagnostic("plan_material_absent"),
        })
    end
    if #(structures.current or {}) ~= 1 then
        return result("ambiguous", work_mode, nil, {
            diagnostic("ambiguous_plan_material"),
        })
    end

    local source = structures.current[1]
    local records, records_err = formation_records(instance, source)
    if not records then
        return result("blocked", work_mode, nil, {
            diagnostic("plan_material_blocked", records_err),
        })
    end
    if not accepted_shapes[records.payload.requested_shape] then
        return result("blocked", work_mode, nil, {
            diagnostic("plan_shape_unsupported"),
        })
    end
    local structure_loss, loss_err = complete_loss(records)
    if not structure_loss then
        return result("partial", work_mode, nil, {
            diagnostic("plan_material_partial", loss_err),
        })
    end
    local unit_view, units_err = resolve_units(instance, records.payload)
    if not unit_view then
        return result("blocked", work_mode, nil, {
            diagnostic("plan_material_blocked", units_err),
        })
    end
    local coverage_refs, coverage_err = resolve_coverage(
        instance,
        unit_view.units,
        options.upper_bounds
    )
    if not coverage_refs then
        local state = tostring(coverage_err):find("incomplete", 1, true)
            and "incomplete_scope" or "stale"
        return result(state, work_mode, nil, {
            diagnostic("plan_material_stale", coverage_err, unit_view.refs),
        })
    end
    local calm_value, calm_err = calm_structure(instance, records)
    if not calm_value then
        return result("blocked", work_mode, nil, {
            diagnostic("plan_material_blocked", calm_err),
        })
    end
    local connections_ok, connections_err = validate_connections(
        records.payload.requested_shape,
        calm_value.connections,
        unit_view.ids
    )
    if not connections_ok then
        return result("blocked", work_mode, nil, {
            diagnostic("plan_material_blocked", connections_err),
        })
    end

    local partition, partition_err
    if records.payload.requested_shape == "alternative_set" then
        partition, partition_err = partition_choice(
            instance,
            records,
            unit_view,
            options
        )
    else
        partition, partition_err = partition_non_choice(unit_view.units)
    end
    if not partition then
        local state = tostring(partition_err):find("requires choice", 1, true)
            and "absent" or "blocked"
        return result(state, work_mode, nil, {
            diagnostic("plan_choice_incomplete", partition_err, unit_view.refs),
        })
    end

    local rejected, validation = latest_validation_rejected(instance)
    if rejected then
        return result("blocked", work_mode, nil, {
            diagnostic("plan_validation_rejected", validation.reason, {
                validation.trace_event_id,
            }),
        })
    end

    local activations = {}
    for _, unit in ipairs(unit_view.units) do
        activations[unit.id] = unit.activation
    end
    local connections = copy_value(calm_value.connections or {})
    local material_fingerprint = "plan-material:" .. json.encode({
        shape = records.payload.requested_shape,
        ids = unit_view.ids,
        versions = unit_view.versions,
        activations = activations,
        partition = partition,
        connections = connections,
        structure_loss = structure_loss,
    })
    local provenance_refs = merge_refs({
        records.event.id,
        records.crystallization.id,
        records.identity_map.trace_event_id,
        records.payload.loss_record_ref,
        partition.choice_event_ref,
    }, coverage_refs)
    local candidate = {
        protocol_version = completion.candidate_protocol,
        packet_id = instance.id,
        generation = instance.generation,
        work_mode = "plan",
        formation_event_ref = records.event.id,
        source_unit_ref = exact_ref(
            records.payload.source.unit_id,
            records.payload.source.version
        ),
        requested_shape = records.payload.requested_shape,
        formed_unit_ids = copy_value(unit_view.ids),
        formed_unit_versions = copy_value(unit_view.versions),
        activation_partition = {
            deliverable_ids = copy_value(partition.deliverable_ids),
            selected_ids = copy_value(partition.selected_ids),
            suppressed_ids = copy_value(partition.suppressed_ids),
            selection_mode = partition.selection_mode,
        },
        coverage_event_refs = coverage_refs,
        crystallization_event_ref = records.crystallization.id,
        identity_map_ref = records.identity_map.id,
        identity_map_event_ref = records.identity_map.trace_event_id,
        loss_record_ref = records.payload.loss_record_ref,
        choice_event_ref = partition.choice_event_ref,
        choice_set_ref = records.payload.choice_contract and records.event.id or nil,
        material_fingerprint = material_fingerprint,
        scope_refs = copy_value(unit_view.refs),
        provenance_refs = provenance_refs,
        source_truth_status = content_status(unit_view.units),
        event_truth_status = "runtime_confirmed",
    }
    candidate.candidate_id = candidate_identity(candidate)
    return result("complete_candidate", work_mode, candidate, {})
end

local function validate_candidate_input(input)
    if type(input) ~= "table" or type(input.candidate_id) ~= "string"
        or type(input.formation_event_ref) ~= "string"
        or type(input.formed_unit_ids) ~= "table"
        or type(input.formed_unit_versions) ~= "table"
        or type(input.coverage_event_refs) ~= "table" then
        return nil, "plan completion input is malformed"
    end
    return true
end

function completion.resolve_candidate(instance, input)
    local valid, valid_err = validate_candidate_input(input)
    if not valid then
        return nil, valid_err
    end
    local inspection, inspection_err = completion.inspect(instance)
    if not inspection then
        return nil, inspection_err
    end
    local candidate = inspection.candidate
    if inspection.state ~= "complete_candidate" or not candidate then
        return nil, "plan completion candidate is not current: " .. inspection.state
    end
    for _, key in ipairs({
        "candidate_id",
        "formation_event_ref",
        "formed_unit_ids",
        "formed_unit_versions",
        "coverage_event_refs",
        "choice_event_ref",
    }) do
        if not same_value(input[key], candidate[key]) then
            return nil, "plan completion input does not match current candidate"
        end
    end
    return candidate
end

function completion.review_scope(instance, candidate, runtime_inspection)
    if type(candidate) ~= "table"
        or candidate.protocol_version ~= completion.candidate_protocol then
        return nil, "plan delivery candidate required"
    end
    if type(runtime_inspection) ~= "table" or runtime_inspection.has_debt ~= true
        or type(runtime_inspection.through_seq) ~= "number"
        or #(runtime_inspection.significant_frames or {}) == 0 then
        return nil, "plan runtime effect is absent"
    end
    local candidate_refs = {}
    for _, ref in ipairs(candidate.provenance_refs or {}) do
        candidate_refs[ref] = true
    end
    local linked = false
    local frame_refs = {}
    for _, frame in ipairs(runtime_inspection.significant_frames or {}) do
        frame_refs[#frame_refs + 1] = frame.frame_ref
        for _, ref in ipairs(frame.reason_refs or {}) do
            linked = linked or candidate_refs[ref] == true
        end
    end
    if not linked then
        return nil, "runtime debt does not reference plan consequences"
    end
    return {
        through_seq = runtime_inspection.through_seq,
        significant_frame_refs = sorted_unique(frame_refs),
        scope_refs = merge_refs(
            candidate.scope_refs,
            runtime_inspection.source_refs
        ),
        provenance_refs = merge_refs(
            candidate.provenance_refs,
            candidate.coverage_event_refs,
            {"consumer:" .. completion.review_consumer_id}
        ),
    }
end

local function relevant_revisions(instance)
    return {
        potential = instance.revisions.potential,
        calm = instance.revisions.calm,
        constraints = instance.revisions.constraints,
        evidence = instance.revisions.evidence,
        history = instance.revisions.history,
    }
end

completion.relevant_revisions = relevant_revisions

local function assessment_identity(value)
    local body = copy_value(value)
    body.assessment_id = nil
    return "plan-assessment:" .. json.encode(body)
end

function completion.build_assessment(instance, candidate, reconciliation_record)
    if type(candidate) ~= "table"
        or candidate.protocol_version ~= completion.candidate_protocol
        or type(reconciliation_record) ~= "table"
        or reconciliation_record.kind ~= "runtime_reconciliation"
        or type(reconciliation_record.trace_event_id) ~= "string" then
        return nil, "plan assessment inputs are malformed"
    end
    local value = {
        protocol_version = completion.assessment_protocol,
        state = "complete",
        candidate_id = candidate.candidate_id,
        work_mode = "plan",
        formation_event_ref = candidate.formation_event_ref,
        requested_shape = candidate.requested_shape,
        formed_unit_ids = copy_value(candidate.formed_unit_ids),
        formed_unit_versions = copy_value(candidate.formed_unit_versions),
        activation_partition = copy_value(candidate.activation_partition),
        coverage_event_refs = copy_value(candidate.coverage_event_refs),
        choice_event_ref = candidate.choice_event_ref,
        crystallization_event_ref = candidate.crystallization_event_ref,
        identity_map_ref = candidate.identity_map_ref,
        loss_record_ref = candidate.loss_record_ref,
        runtime_reconciliation_ref = reconciliation_record.trace_event_id,
        manifest_material_refs = merge_refs(
            candidate.scope_refs,
            candidate.provenance_refs
        ),
        basis_revisions = relevant_revisions(instance),
        basis_truth_statuses = sorted_unique({
            "runtime_confirmed",
            candidate.source_truth_status,
        }),
        event_truth_status = "runtime_confirmed",
        content_truth_status = candidate.source_truth_status,
    }
    value.assessment_id = assessment_identity(value)
    return value
end

local function valid_assessment(instance, value, candidate)
    if type(value) ~= "table"
        or value.protocol_version ~= completion.assessment_protocol
        or value.state ~= "complete"
        or value.work_mode ~= "plan"
        or value.event_truth_status ~= "runtime_confirmed"
        or type(value.assessment_id) ~= "string"
        or value.assessment_id ~= assessment_identity(value)
        or value.candidate_id ~= candidate.candidate_id
        or value.formation_event_ref ~= candidate.formation_event_ref
        or not same_value(value.formed_unit_ids, candidate.formed_unit_ids)
        or not same_value(value.formed_unit_versions, candidate.formed_unit_versions)
        or not same_value(value.activation_partition, candidate.activation_partition)
        or not same_value(value.coverage_event_refs, candidate.coverage_event_refs)
        or value.choice_event_ref ~= candidate.choice_event_ref
        or value.content_truth_status ~= candidate.source_truth_status
        or not same_value(value.basis_revisions, relevant_revisions(instance))
        or type(value.runtime_reconciliation_ref) ~= "string" then
        return nil, "plan completion assessment is malformed or stale"
    end
    local reconciliation_event = event_by_id(instance, value.runtime_reconciliation_ref)
    if not reconciliation_event or reconciliation_event.type ~= "runtime_reconciliation"
        or reconciliation_event.operator ~= "☱"
        or reconciliation_event.truth_status ~= "runtime_confirmed" then
        return nil, "plan assessment reconciliation is missing"
    end
    return true
end

function completion.find_assessment(instance, candidate)
    for index = #(instance.trace or {}), 1, -1 do
        local event = instance.trace[index]
        if event.type == "plan_completion_assessment"
            and event.payload and event.payload.candidate_id == candidate.candidate_id then
            if event.operator ~= "☱" or event.truth_status ~= "runtime_confirmed" then
                return nil, "plan completion assessment actor mismatch"
            end
            local valid, valid_err = valid_assessment(instance, event.payload, candidate)
            if not valid then
                return nil, "plan_assessment_stale:" .. tostring(valid_err)
            end
            return {
                event = copy_value(event),
                assessment = copy_value(event.payload),
            }
        end
    end
    return nil, "plan_assessment_absent"
end

function completion.resolve_assessment(instance, input)
    if type(input) ~= "table" or type(input.assessment_event_ref) ~= "string"
        or type(input.assessment_id) ~= "string" then
        return nil, "plan delivery input is malformed"
    end
    local candidate, candidate_err = completion.resolve_candidate(instance, input)
    if not candidate then
        return nil, candidate_err
    end
    local event = event_by_id(instance, input.assessment_event_ref)
    if not event or event.type ~= "plan_completion_assessment"
        or event.operator ~= "☱" or event.truth_status ~= "runtime_confirmed"
        or event.payload.assessment_id ~= input.assessment_id then
        return nil, "plan delivery assessment event is missing"
    end
    local valid, valid_err = valid_assessment(instance, event.payload, candidate)
    if not valid then
        return nil, valid_err
    end
    return {
        event = copy_value(event),
        assessment = copy_value(event.payload),
    }, candidate
end

local function project_item(unit)
    local carrier = unit.carrier or {}
    return {
        id = unit.id,
        key = carrier.key,
        kind = carrier.kind,
        value = copy_value(carrier.value),
        position = carrier.position,
        activation = unit.activation,
        content_truth_status = unit.content_truth_status,
    }
end

local function ids_set(ids)
    local result = {}
    for _, id in ipairs(ids or {}) do
        result[id] = true
    end
    return result
end

function completion.project(instance, assessment_record, candidate)
    if type(assessment_record) ~= "table" or not assessment_record.event
        or not assessment_record.assessment then
        return nil, "plan assessment record required"
    end
    local valid, valid_err = valid_assessment(
        instance,
        assessment_record.assessment,
        candidate
    )
    if not valid then
        return nil, valid_err
    end
    local deliverable = ids_set(candidate.activation_partition.deliverable_ids)
    local suppressed = ids_set(candidate.activation_partition.suppressed_ids)
    local items = {}
    local suppressed_items = {}
    for _, id in ipairs(candidate.formed_unit_ids) do
        local unit = field.get_unit(instance, id)
        if not unit or unit.version ~= candidate.formed_unit_versions[id] then
            return nil, "plan projection unit is stale"
        end
        if deliverable[id] then
            items[#items + 1] = project_item(unit)
        elseif suppressed[id] then
            suppressed_items[#suppressed_items + 1] = project_item(unit)
        else
            return nil, "plan projection partition is incomplete"
        end
    end
    local records, records_err = formation_records(instance, {
        formation_event_ref = candidate.formation_event_ref,
    })
    if not records then
        return nil, records_err
    end
    local calm_value, calm_err = calm_structure(instance, records)
    if not calm_value then
        return nil, calm_err
    end
    local selection = {
        mode = candidate.activation_partition.selection_mode,
        selected_ids = copy_value(candidate.activation_partition.selected_ids),
        suppressed_ids = copy_value(candidate.activation_partition.suppressed_ids),
        choice_event_ref = candidate.choice_event_ref,
    }
    local plan_result = {
        protocol_version = completion.result_protocol,
        assessment_ref = assessment_record.event.id,
        formation_event_ref = candidate.formation_event_ref,
        shape = candidate.requested_shape,
        items = items,
        connections = copy_value(calm_value.connections or {}),
        selection = selection,
        content_truth_status = candidate.source_truth_status,
    }
    local choice_loss
    if candidate.choice_event_ref then
        local choice_event = event_by_id(instance, candidate.choice_event_ref)
        choice_loss = choice_event and copy_value(choice_event.payload.loss) or nil
    end
    local residue = {
        structure_loss = copy_value(records.loss_record.loss),
        choice_loss = choice_loss,
        suppressed_items = suppressed_items,
        assumptions = {},
        unsupported = {},
        missing = {},
        cause = "complete",
        manifest_type = "plan",
        manifest_outcome = "complete",
    }
    local sources = {
        assessment_event = assessment_record.event.id,
        runtime_reconciliation_event = assessment_record.assessment
            .runtime_reconciliation_ref,
        structure_formation_event = candidate.formation_event_ref,
        choice_event = candidate.choice_event_ref,
        crystallization_event = candidate.crystallization_event_ref,
        identity_map_event = candidate.identity_map_event_ref,
        upper_observation_events = copy_value(candidate.coverage_event_refs),
    }
    return plan_result, residue, sources
end

function completion.verify_review_effect(instance, plan, payload)
    local input = plan and plan.options and plan.options.runtime
        and plan.options.runtime.plan_completion_input
    if type(input) ~= "table" or type(payload) ~= "table"
        or payload.kind ~= "runtime_eye_payload"
        or payload.mode ~= "plan_completion_review"
        or type(payload.assessment_event_id) ~= "string"
        or type(payload.completion_assessment) ~= "table" then
        return nil, "malformed plan completion review effect"
    end
    local candidate, candidate_err = completion.resolve_candidate(instance, input)
    if not candidate then
        return nil, candidate_err
    end
    local event = event_by_id(instance, payload.assessment_event_id)
    if not event or event.type ~= "plan_completion_assessment"
        or event.operator ~= "☱" or event.truth_status ~= "runtime_confirmed"
        or not same_value(event.payload, payload.completion_assessment) then
        return nil, "plan completion assessment event mismatch"
    end
    local valid, valid_err = valid_assessment(instance, event.payload, candidate)
    if not valid then
        return nil, valid_err
    end
    return true
end

function completion.verify_delivery_effect(instance, plan, payload)
    local input = plan and plan.options and plan.options.manifest
        and plan.options.manifest.plan_input
    if type(input) ~= "table" or type(payload) ~= "table"
        or payload.kind ~= "manifest_payload" or payload.mode ~= "plan_delivery"
        or payload.truth_status ~= "runtime_confirmed"
        or type(payload.output) ~= "table"
        or payload.output.type ~= "plan" or payload.output.status ~= "complete"
        or type(payload.assembly) ~= "table"
        or payload.assembly.rule ~= "plan_delivery.v0"
        or payload.assembly.input_provenance ~= "packet_state"
        or payload.terminal_cause ~= "complete" then
        return nil, "malformed plan delivery effect"
    end
    local assessment, candidate_or_err = completion.resolve_assessment(instance, input)
    if not assessment then
        return nil, candidate_or_err
    end
    local candidate = candidate_or_err
    local projected, residue, sources = completion.project(
        instance,
        assessment,
        candidate
    )
    if not projected then
        return nil, residue
    end
    if not same_value(payload.output.structured, projected)
        or payload.output.text ~= json.encode(projected)
        or not same_value(payload.residue, residue)
        or not same_value(payload.sources, sources)
        or payload.content_truth_status ~= candidate.source_truth_status then
        return nil, "plan delivery projection mismatch"
    end
    return true
end

return completion
