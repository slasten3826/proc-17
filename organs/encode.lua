local logic_encode = require("logic.encode")
local packet_core = require("core.packet")
local field = require("runtime.field")

local encode = {}

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
    local flow_unit
    for _, unit in ipairs(view.units) do
        unit_by_event[unit.created_event_id] = unit
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
            unit = event and unit_by_event[event.id] or nil
        elseif legacy_ref == "chaos:raw_prompt" then
            event = birth
            unit = flow_unit
        end

        if unit then
            append_unique(provenance_refs, provenance_seen, unit.id)
            append_unique(old_ids, old_seen, unit.id)
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

    instance.calm.work_units = work_units
    instance.calm.current = calm_delta
    instance.calm.status = "accepted"

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
    }
end

return encode
