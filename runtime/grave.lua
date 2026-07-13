local grave = {}

local function copy_array(source)
    local out = {}
    if type(source) ~= "table" then
        return out
    end
    for index, value in ipairs(source) do
        out[index] = value
    end
    return out
end

local function normalize(input)
    if type(input) ~= "table" then
        return nil, "grave input must be table"
    end

    if input.kind == "inherited_packet_residue" then
        return {
            packet_id = input.source_packet_id,
            status = input.source_status,
            death = input.source_death,
            residue = input.residue or {},
            trace_tail = input.trace_tail or {},
        }
    end

    if input.kind == "packet_memory_capsule" then
        return {
            packet_id = input.packet_id,
            status = input.status,
            death = input.death,
            residue = input.residue or {},
            trace_tail = input.trace_tail or {},
        }
    end

    return {
        packet_id = input.id or input.packet_id or input.source_packet_id,
        status = input.status or input.source_status,
        death = input.death or input.source_death,
        residue = input.residue or {},
        trace_tail = input.trace_tail or {},
    }
end

local function number_gt_zero(value)
    return type(value) == "number" and value > 0
end

local function has_progress(residue)
    residue = residue or {}
    if residue.bequest == true then
        return true
    end
    if number_gt_zero(residue.done_count) then
        return true
    end
    if number_gt_zero(residue.completed_work_count) then
        return true
    end
    if type(residue.progress) == "table" and number_gt_zero(residue.progress.done_count) then
        return true
    end
    return false
end

local function base_record(normalized, grave_kind)
    local death = normalized.death or {}
    return {
        kind = "grave",
        grave_kind = grave_kind,
        source_packet_id = normalized.packet_id,
        source_status = normalized.status,
        death_cause = death.cause,
        death = death,
        residue = normalized.residue or {},
        trace_tail = copy_array(normalized.trace_tail),
        death_truth_status = "runtime_confirmed",
        applicability_truth_status = "grave_pressure",
    }
end

local function warning_record(normalized)
    local record = base_record(normalized, "warning")
    local residue = normalized.residue or {}
    record.warning = {
        do_not_repeat = residue.do_not_repeat,
        pattern = {
            last_operator = residue.last_operator,
            do_not_repeat = residue.do_not_repeat,
            death_cause = record.death_cause,
        },
    }
    return record
end

local function bequest_record(normalized)
    local record = base_record(normalized, "bequest")
    local residue = normalized.residue or {}
    record.bequest = {
        remaining_work_count = residue.remaining_work_count,
        progress = residue.progress,
        trace_tail = copy_array(normalized.trace_tail),
    }
    return record
end

local function neutral_record(normalized)
    return base_record(normalized, "neutral")
end

local function is_array(value)
    if type(value) ~= "table" then
        return false
    end
    return value[1] ~= nil
end

local function as_list(value)
    if next(value) == nil then
        return {}
    end
    if is_array(value) then
        return value
    end
    return {value}
end

local function ensure_karma(instance)
    instance.runtime = instance.runtime or {}
    instance.runtime.karma = instance.runtime.karma or {}
    instance.runtime.karma.warnings = instance.runtime.karma.warnings or {}
    instance.runtime.karma.bequests = instance.runtime.karma.bequests or {}
    instance.runtime.karma.neutral = instance.runtime.karma.neutral or {}
    return instance.runtime.karma
end

local function ensure_chaos(instance)
    instance.chaos = instance.chaos or {}
    instance.chaos.unresolved_pressure = instance.chaos.unresolved_pressure or {}
    return instance.chaos
end

local function bequest_pressure(record)
    local bequest = record.bequest or {}
    return {
        kind = "grave_bequest_pressure",
        source_packet_id = record.source_packet_id,
        death_cause = record.death_cause,
        remaining_work_count = bequest.remaining_work_count,
        progress = bequest.progress,
        trace_tail = copy_array(bequest.trace_tail),
        death_truth_status = record.death_truth_status,
        applicability_truth_status = record.applicability_truth_status,
    }
end

function grave.classify(input)
    local normalized, err = normalize(input)
    if not normalized then
        return nil, err
    end
    if type(normalized.death) ~= "table" or normalized.death.cause == nil then
        return nil, "grave classification requires death"
    end

    local cause = normalized.death.cause
    local residue = normalized.residue or {}

    if cause == "identity_loss" then
        return warning_record(normalized)
    end

    if cause == "budget_exhausted" then
        if has_progress(residue) then
            return bequest_record(normalized)
        end
        return warning_record(normalized)
    end

    if cause == "complete" then
        return neutral_record(normalized)
    end

    if cause == "cancelled" then
        if residue.do_not_repeat ~= nil then
            return warning_record(normalized)
        end
        return neutral_record(normalized)
    end

    if residue.do_not_repeat ~= nil then
        return warning_record(normalized)
    end

    return neutral_record(normalized)
end

function grave.attach(instance, graves)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    if type(graves) ~= "table" then
        return nil, "graves required"
    end

    local karma = ensure_karma(instance)
    local chaos = ensure_chaos(instance)
    local payload = {
        kind = "grave_attach_payload",
        attached_count = 0,
        warning_count = 0,
        bequest_count = 0,
        neutral_count = 0,
        truth_status = "runtime_confirmed",
    }

    for _, item in ipairs(as_list(graves)) do
        local record = item
        if not (type(record) == "table" and record.kind == "grave") then
            local classified, classify_err = grave.classify(item)
            if not classified then
                return nil, classify_err
            end
            record = classified
        end

        if record.grave_kind == "warning" then
            karma.warnings[#karma.warnings + 1] = record
            payload.warning_count = payload.warning_count + 1
        elseif record.grave_kind == "bequest" then
            karma.bequests[#karma.bequests + 1] = record
            chaos.unresolved_pressure[#chaos.unresolved_pressure + 1] = bequest_pressure(record)
            payload.bequest_count = payload.bequest_count + 1
        elseif record.grave_kind == "neutral" then
            karma.neutral[#karma.neutral + 1] = record
            payload.neutral_count = payload.neutral_count + 1
        else
            return nil, "unknown grave kind: " .. tostring(record.grave_kind)
        end

        payload.attached_count = payload.attached_count + 1
    end

    return payload
end

return grave
