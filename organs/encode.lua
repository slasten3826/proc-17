local logic_encode = require("logic.encode")
local packet_core = require("core.packet")
local field = require("runtime.field")

local encode = {}

local function exact_ref(id, version)
    return table.concat({"coverage", "field_unit", id, tostring(version)}, ":")
end

local function relation_scope(instance, input)
    if type(input) ~= "table" or type(input.raw_epoch) ~= "number"
        or type(input.relation_ids) ~= "table" or #input.relation_ids == 0
        or type(input.endpoint_versions) ~= "table" then
        return nil, "relation-guided ENCODE requires exact relation_input"
    end
    if not (instance.ingress
        and instance.ingress.integration_protocol == "vertical_packet_life.v0") then
        return nil, "relation-guided ENCODE requires vertical packet life"
    end
    local relations = {}
    local endpoint_ids = {}
    local endpoint_seen = {}
    local source_refs = {}
    local scope_refs = {}
    local content_status
    for _, relation_id in ipairs(input.relation_ids) do
        local relation, relation_err = field.raw_relation_exact(
            instance,
            input.raw_epoch,
            relation_id,
            input.endpoint_versions
        )
        if not relation then
            return nil, relation_err
        end
        local phase, phase_err = field.raw_relation_phase(
            instance,
            input.raw_epoch,
            relation_id
        )
        if not phase then
            return nil, phase_err
        end
        if phase.phase ~= "available" and phase.phase ~= "observed" then
            return nil, "raw relation is not formable from phase " .. phase.phase
        end
        relations[#relations + 1] = relation
        source_refs[#source_refs + 1] = relation.id
        scope_refs[#scope_refs + 1] = relation.id
        if relation.origin_event_id then
            source_refs[#source_refs + 1] = relation.origin_event_id
        end
        for endpoint, version in pairs(relation.endpoint_versions or {}) do
            source_refs[#source_refs + 1] = exact_ref(endpoint, version)
            scope_refs[#scope_refs + 1] = exact_ref(endpoint, version)
            if not endpoint_seen[endpoint] then
                endpoint_seen[endpoint] = true
                endpoint_ids[#endpoint_ids + 1] = endpoint
            end
        end
        local current = relation.content_truth_status or "unknown"
        if content_status == nil then
            content_status = current
        elseif content_status ~= current then
            content_status = "mixed"
        end
    end
    table.sort(endpoint_ids)
    return {
        input = input,
        relations = relations,
        endpoint_ids = endpoint_ids,
        source_refs = source_refs,
        scope_refs = scope_refs,
        content_truth_status = content_status or "unknown",
    }
end

function encode.readiness(instance, options)
    options = options or {}
    if options.relation_input ~= nil then
        local scope, scope_err = relation_scope(instance, options.relation_input)
        return {
            operator = "☵",
            ready = scope ~= nil,
            reason = scope and "relation_formation_ready" or scope_err,
            source_refs = scope and scope.scope_refs or {},
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }, scope
    end
    local chaos = instance and instance.chaos or {}
    local refs = {}
    for index, fragment in ipairs(chaos.fragments or {}) do
        if fragment.text ~= nil or fragment.value ~= nil or fragment.content ~= nil then
            refs[#refs + 1] = "chaos:fragment:" .. tostring(index)
        end
    end
    if #refs == 0 and type(chaos.raw_prompt) == "string" and chaos.raw_prompt ~= "" then
        refs[1] = "chaos:raw_prompt"
    end
    return {
        operator = "☵",
        ready = #refs > 0,
        reason = #refs > 0 and "ready" or "no_compressible_structure",
        source_refs = refs,
        required_capabilities = {},
        missing_capabilities = {},
        event_truth_status = "runtime_confirmed",
    }
end

local function relation_guided_run(instance, options)
    local witness, scope_or_err = encode.readiness(instance, options)
    if not witness.ready then
        return nil, witness.reason
    end
    local scope = scope_or_err
    local planned_ids, plan_err = field.plan_unit_ids(instance, #scope.relations)
    if not planned_ids then
        return nil, plan_err
    end
    local identity_map_id, map_plan_err = field.plan_identity_map_id(instance)
    if not identity_map_id then
        return nil, map_plan_err
    end

    local items = {}
    local work_units = {}
    for index, relation in ipairs(scope.relations) do
        items[index] = {
            id = "formed_relation:" .. tostring(index),
            kind = "formed_relation",
            relation_kind = relation.kind,
            from = relation.from,
            to = relation.to,
            endpoint_versions = relation.endpoint_versions,
            source_relation_id = relation.id,
            content_truth_status = relation.content_truth_status,
        }
        work_units[index] = {
            id = planned_ids[index],
            status = "pending",
            description = relation.kind .. ":" .. relation.from .. "->" .. relation.to,
            source_relation_id = relation.id,
            content_truth_status = relation.content_truth_status,
        }
    end
    local observation_refs = {}
    for _, relation in ipairs(scope.relations) do
        local phase = assert(field.raw_relation_phase(
            instance,
            options.relation_input.raw_epoch,
            relation.id
        ))
        if phase.disposition_event_ref then
            observation_refs[#observation_refs + 1] = phase.disposition_event_ref
        end
    end
    local formation = {
        protocol_version = "l2.relation_formation.v0",
        formed_from = {
            raw_epoch = options.relation_input.raw_epoch,
            relation_ids = options.relation_input.relation_ids,
            endpoint_versions = options.relation_input.endpoint_versions,
            observation_event_refs = observation_refs,
        },
        formed_unit_ids = planned_ids,
        identity_map_ref = identity_map_id,
        content_truth_status = scope.content_truth_status,
    }
    local calm_delta = {
        kind = "relation_formed_calm",
        source_area = "field.relations.raw",
        source_refs = scope.source_refs,
        field = {
            kind = "relation_formed_field",
            items = items,
            truth_status = scope.content_truth_status,
        },
        connections = {},
        hierarchy = {},
        work_units = work_units,
        formation_basis = "relation_guided",
        requested_shape = options.relation_input.requested_shape,
        relation_formation = formation,
    }
    local old_count = #scope.endpoint_ids
    local new_count = #planned_ids
    local loss_percentage = old_count > 0
        and math.max(0, (old_count - new_count) / old_count) or 0
    local relation_loss = {
        kind = "relation_formation_loss",
        amount = loss_percentage,
        input_count = old_count,
        output_count = new_count,
        omitted_count = 0,
        truncated = false,
        loss_percentage = loss_percentage,
        encoding_type = "relation_guided",
        loss_log = {{
            kind = "identity_compaction",
            input_identity_count = old_count,
            output_identity_count = new_count,
            amount = loss_percentage,
        }},
    }

    local crystallized, crystallization_event = packet_core.crystallize(instance, {
        source_chaos_refs = scope.source_refs,
        calm_delta = calm_delta,
        loss = relation_loss,
        status = "accepted",
        truth_status = "runtime_confirmed",
    })
    if not crystallized then
        return nil, crystallization_event
    end
    local new_ids = {}
    for index, item in ipairs(items) do
        local unit, unit_err = field.add_unit(instance, "☵", {
            id = planned_ids[index],
            kind = "formed_relation",
            carrier = item,
            source_refs = scope.source_refs,
            event_truth_status = "runtime_confirmed",
            content_truth_status = scope.content_truth_status,
            created_event_id = crystallization_event.id,
            migration = {
                status = "formed_from_raw_relation",
                protocol_version = formation.protocol_version,
                raw_epoch = formation.formed_from.raw_epoch,
                relation_id = item.source_relation_id,
            },
        })
        if not unit then
            return nil, unit_err
        end
        new_ids[#new_ids + 1] = unit.id
    end
    local mapping = {}
    for _, endpoint_id in ipairs(scope.endpoint_ids) do
        mapping[endpoint_id] = new_ids
    end
    local identity_map, identity_err = field.record_identity_map(instance, "☵", {
        id = identity_map_id,
        encode_event_id = crystallization_event.id,
        old_ids = scope.endpoint_ids,
        new_ids = new_ids,
        mapping = mapping,
        mapping_kind = "relation_guided",
        source_event_refs = scope.source_refs,
        shadow_only = false,
    })
    if not identity_map then
        return nil, identity_err
    end
    local formation_event, formation_err = packet_core.append_event(instance, {
        type = "relation_formation",
        operator = "☵",
        truth_status = "runtime_confirmed",
        payload = {
            kind = "relation_formation",
            protocol_version = formation.protocol_version,
            formed_from = formation.formed_from,
            formed_unit_ids = new_ids,
            identity_map_ref = identity_map.id,
            identity_map_event_ref = identity_map.trace_event_id,
            event_truth_status = "runtime_confirmed",
            content_truth_status = scope.content_truth_status,
        },
        cost = {},
    })
    if not formation_event then
        return nil, formation_err
    end

    return instance, {
        kind = "encode_organ_payload",
        mode = "relation_guided",
        formation_basis = "relation_guided",
        calm_delta = calm_delta,
        work_units = work_units,
        loss = relation_loss,
        relation_formation = formation,
        identity_map = identity_map,
        trace_event_id = crystallization_event.id,
        effect_scope_refs = scope.scope_refs,
        formation_event_id = formation_event.id,
        field_shadow = {
            status = "formed",
            source_unit_ids = scope.endpoint_ids,
            member_unit_ids = new_ids,
            identity_map_ref = identity_map.id,
            shadow_only = false,
        },
        truth_status = "runtime_confirmed",
        content_truth_status = scope.content_truth_status,
    }
end

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function chaos_text(instance)
    local parts = {}
    local refs = {}
    local chaos = instance.chaos or {}

    if type(chaos.fragments) == "table" then
        for index, fragment in ipairs(chaos.fragments) do
            local text = fragment.text or fragment.value or fragment.content
            if trim(text) ~= "" then
                parts[#parts + 1] = text
                refs[#refs + 1] = "chaos:fragment:" .. tostring(index)
            end
        end
    end

    if #parts == 0 and trim(chaos.raw_prompt) ~= "" then
        parts[#parts + 1] = chaos.raw_prompt
        refs[#refs + 1] = "chaos:raw_prompt"
    end

    return table.concat(parts, "\n"), refs
end

local function substrate_limits(instance, options)
    options = options or {}
    if options.limits then
        return options.limits
    end
    local physis = instance.physis or instance.substrate or {}
    local budget = physis.budget or {}
    local max_items = budget.encode_items or budget.work_units or 128
    return {max_items = max_items}
end

local function work_units_from_field(field)
    local units = {}
    for _, item in ipairs(field.items or {}) do
        if item.role == nil or item.role == "alternative" or item.role == "evidence" or item.role == "residue" then
            units[#units + 1] = {
                id = item.id,
                status = "pending",
                description = item.content or item.value or item.label,
                source_item_id = item.id,
                source_truth_status = item.source_truth_status,
                content_truth_status = item.content_truth_status,
                kind = item.kind,
                label = item.label,
                source_refs = item.source_refs,
            }
        end
    end
    return units
end

local function append_unique(target, seen, value)
    if value ~= nil and not seen[value] then
        seen[value] = true
        target[#target + 1] = value
    end
end

local function field_sources(instance, legacy_refs)
    local view = field.view(instance, {
        created_by = {"▽", "☴"},
        limit = math.max(1, #(instance.field.unit_order or {})),
    }) or {units = {}}
    local unit_by_event = {}
    local unit_by_legacy_ref = {}
    local unit_by_id = {}
    local flow_unit
    for _, unit in ipairs(view.units) do
        unit_by_id[unit.id] = unit
        unit_by_event[unit.created_event_id] = unit
        local migration = unit.migration or {}
        if type(migration.legacy_ref) == "string" then
            unit_by_legacy_ref[migration.legacy_ref] = unit
        end
        if unit.created_by == "▽" and not flow_unit then
            flow_unit = unit
        end
    end

    local birth
    local chaos_events = {}
    for _, event in ipairs(instance.trace or {}) do
        if event.type == "birth" and not birth then
            birth = event
        elseif event.type == "chaos_append" then
            chaos_events[#chaos_events + 1] = event
        end
    end

    local provenance_refs = {}
    local old_ids = {}
    local source_event_refs = {}
    local provenance_seen = {}
    local old_seen = {}
    local event_seen = {}
    for _, legacy_ref in ipairs(legacy_refs) do
        local event
        local unit
        local fragment_index = legacy_ref:match("^chaos:fragment:(%d+)$")
        if fragment_index then
            event = chaos_events[tonumber(fragment_index)]
            unit = unit_by_legacy_ref[legacy_ref]
                or (event and unit_by_event[event.id] or nil)
        elseif legacy_ref == "chaos:raw_prompt" then
            event = birth
            unit = flow_unit
        end

        if unit then
            append_unique(provenance_refs, provenance_seen, unit.id)
            append_unique(old_ids, old_seen, unit.id)
            for _, ref in ipairs(unit.source_refs or {}) do
                if unit_by_id[ref] then
                    append_unique(provenance_refs, provenance_seen, ref)
                    append_unique(old_ids, old_seen, ref)
                end
            end
        elseif event then
            append_unique(provenance_refs, provenance_seen, event.id)
        else
            append_unique(provenance_refs, provenance_seen, legacy_ref)
        end
        if event then
            append_unique(source_event_refs, event_seen, event.id)
        end
    end

    return provenance_refs, old_ids, source_event_refs
end

local function legacy_unit_map(items, planned_ids)
    local mapping = {}
    for index, item in ipairs(items or {}) do
        mapping[tostring(item.id or index)] = planned_ids[index]
    end
    return mapping
end

function encode.run(instance, options)
    options = options or {}
    local mutable, mutable_err = packet_core.assert_mutable(instance, "encode")
    if not mutable then
        return nil, mutable_err
    end
    if options.relation_input ~= nil then
        return relation_guided_run(instance, options)
    end
    local text, source_refs = chaos_text(instance)
    if text == "" then
        return nil, "empty_chaos"
    end

    local encoded, err = logic_encode.encode({
        substrate_result = {
            text = text,
            truth_status = "semantic_proposal",
        },
        limits = substrate_limits(instance, options),
    })
    if not encoded then
        return nil, err
    end

    local work_units = work_units_from_field(encoded.field)
    local provenance_refs, old_unit_ids, source_event_refs = field_sources(instance, source_refs)
    local planned_unit_ids, plan_err = field.plan_unit_ids(instance, #encoded.field.items)
    if not planned_unit_ids then
        return nil, plan_err
    end
    local legacy_to_unit_id = legacy_unit_map(encoded.field.items, planned_unit_ids)
    local calm_delta = {
        kind = "encoded_field",
        source_area = "chaos",
        source_refs = source_refs,
        field = encoded.field,
        connections = encoded.connections,
        hierarchy = encoded.hierarchy,
        work_units = work_units,
        encoding_basis = encoded.encoding_basis,
        structure = encoded.field.structure,
        encoding = encoded.field.encoding,
        loss_log = encoded.loss.loss_log or encoded.field.loss_log or {},
        field_shadow = {
            protocol_version = "field-shadow.v0",
            status = "shadow_only",
            source_revision = instance.revisions.potential,
            source_unit_ids = old_unit_ids,
            source_event_refs = source_event_refs,
            member_unit_ids = planned_unit_ids,
            legacy_to_unit_id = legacy_to_unit_id,
            named_reader = "organs.choose",
            promotion_phase = "Phase D",
        },
    }

    local loss = {
        kind = encoded.loss.kind,
        amount = encoded.loss.omitted_count or 0,
        input_count = encoded.loss.input_count,
        output_count = encoded.loss.output_count,
        omitted_count = encoded.loss.omitted_count,
        truncated = encoded.loss.truncated,
        source_detail_loss = encoded.loss.source_detail_loss,
        hierarchy_loss = encoded.loss.hierarchy_loss,
        encoding_type = encoded.loss.encoding_type,
        loss_percentage = encoded.loss.loss_percentage,
        loss_level = encoded.loss.loss_level,
        loss_log = encoded.loss.loss_log or {},
    }

    local ok, event_or_err = packet_core.crystallize(instance, {
        source_chaos_refs = source_refs,
        calm_delta = calm_delta,
        loss = loss,
        status = "accepted",
        truth_status = "runtime_confirmed",
    })
    if not ok then
        return nil, event_or_err
    end

    local new_unit_ids = {}
    for index, item in ipairs(encoded.field.items) do
        local unit, unit_err = field.add_unit(instance, "☵", {
            id = planned_unit_ids[index],
            kind = item.kind or "encoded_item",
            carrier = item,
            source_refs = provenance_refs,
            event_truth_status = "runtime_confirmed",
            content_truth_status = item.content_truth_status or encoded.field.truth_status or "unknown",
            created_event_id = event_or_err.id,
            migration = {
                status = "shadow_only",
                legacy_id = tostring(item.id or index),
            },
        })
        if not unit then
            return nil, unit_err
        end
        new_unit_ids[#new_unit_ids + 1] = unit.id
    end

    local identity_mapping = {}
    for _, old_id in ipairs(old_unit_ids) do
        identity_mapping[old_id] = new_unit_ids
    end
    local identity_map, identity_err = field.record_identity_map(instance, "☵", {
        encode_event_id = event_or_err.id,
        old_ids = old_unit_ids,
        new_ids = new_unit_ids,
        mapping = identity_mapping,
        mapping_kind = "coarse_all_sources",
        source_event_refs = source_event_refs,
        shadow_only = true,
    })
    if not identity_map then
        return nil, identity_err
    end

    return instance, {
        kind = "encode_organ_payload",
        encoded = encoded,
        calm_delta = calm_delta,
        loss = loss,
        work_units = work_units,
        trace_event_id = event_or_err.id,
        field_shadow = {
            status = "recorded",
            source_unit_ids = old_unit_ids,
            member_unit_ids = new_unit_ids,
            legacy_to_unit_id = legacy_to_unit_id,
            identity_map_ref = identity_map.trace_event_id,
            shadow_only = true,
        },
        truth_status = "runtime_confirmed",
        formation_basis = "semantic_text",
    }
end

return encode
