local logic_encode = require("logic.encode")
local packet_core = require("core.packet")

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
    local budget = instance.substrate and instance.substrate.budget or {}
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

function encode.run(instance, options)
    options = options or {}
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
        truth_status = "runtime_confirmed",
    }
end

return encode
