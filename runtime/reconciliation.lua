local body = require("runtime.body")
local camera = require("runtime.camera")

local reconciliation = {}

local significant_components = {
    relations_active = true,
    momentum = true,
    calm = true,
    constraints = true,
    evidence = true,
    history = true,
    scalars = true,
}

local significant_event_reasons = {
    crystallization = "calm_structure_changed",
    identity_map = "encoded_identity_changed",
    relation_mutation = "active_relation_changed",
    choice = "alternatives_suppressed",
    validation = "validation_effect_recorded",
    cycle = "cycle_impulse_recorded",
}

local function completion_state(instance)
    local progress = body.progress(instance)
    local validations = instance.boundary and instance.boundary.validations or {}
    local latest_validation = validations[#validations]
    if latest_validation and latest_validation.status == "rejected" then
        return "blocked"
    end
    if progress.needed_count > 0 and progress.remaining_count == 0 then
        return "complete"
    end
    if progress.done_count > 0 then
        return "usable_partial"
    end
    return "incomplete"
end

local function trace_index(instance)
    local result = {}
    for _, event in ipairs(instance.trace or {}) do
        result[event.id] = event
    end
    return result
end

local function append_unique(list, seen, value)
    if type(value) == "string" and value ~= "" and not seen[value] then
        seen[value] = true
        list[#list + 1] = value
    end
end

function reconciliation.inspect(instance)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    local state, state_err = camera.reconciliation_state(instance)
    if not state then
        return nil, state_err
    end
    local frames, frames_err = camera.pending(instance)
    if not frames then
        return nil, frames_err
    end
    local events = trace_index(instance)
    local frame_refs = {}
    local source_refs = {}
    local source_seen = {}
    local resolved_refs = {}
    local resolved_seen = {}
    local significant_frames = {}

    for _, frame in ipairs(frames) do
        frame_refs[#frame_refs + 1] = frame.trace_event_id
        local reasons = {}
        local reason_seen = {}

        for _, change in ipairs(frame.changed_components or {}) do
            if significant_components[change.component] then
                local ref = "revision:" .. tostring(change.component) .. ":" .. tostring(change.after)
                append_unique(reasons, reason_seen, ref)
                append_unique(resolved_refs, resolved_seen, ref)
            end
        end
        for _, ref in ipairs(frame.effect_refs or {}) do
            local event = events[ref]
            local reason = event and significant_event_reasons[event.type]
            if reason then
                append_unique(reasons, reason_seen, ref)
                append_unique(resolved_refs, resolved_seen, ref)
            end
        end

        if #reasons > 0 then
            append_unique(source_refs, source_seen, frame.trace_event_id)
            for _, ref in ipairs(reasons) do
                append_unique(source_refs, source_seen, ref)
            end
            significant_frames[#significant_frames + 1] = {
                frame_ref = frame.trace_event_id,
                seq = frame.seq,
                operator = frame.operator,
                reason_refs = reasons,
            }
        end
    end

    return {
        kind = "runtime_reconciliation_inspection",
        from_seq = state.reconciled_through + 1,
        through_seq = state.head_seq,
        frame_refs = frame_refs,
        pending_frame_count = #frames,
        significant_frames = significant_frames,
        significant_frame_count = #significant_frames,
        routine_frame_count = #frames - #significant_frames,
        source_refs = source_refs,
        resolved_refs = resolved_refs,
        unresolved_refs = {},
        completion_state = completion_state(instance),
        has_debt = #significant_frames > 0,
        event_truth_status = "runtime_confirmed",
    }
end

return reconciliation
