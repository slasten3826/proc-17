local topology = require("core.topology")
local packet_core = require("core.packet")
local body = require("runtime.body")
local budget = require("runtime.budget")
local loss = require("runtime.loss")
local freshness = require("runtime.freshness")

local camera = {
    protocol_version = "runtime.camera.v0-shadow",
}

local completion_states = {
    incomplete = true,
    complete = true,
    usable_partial = true,
    blocked = true,
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

local function sorted_keys(value)
    local keys = {}
    for key in pairs(value or {}) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

local function valid_refs(value, name)
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

local function index(instance)
    local runtime = instance and instance.runtime or {}
    local value = runtime.camera or {}
    return {
        protocol_version = value.protocol_version or camera.protocol_version,
        head_seq = value.head_seq or 0,
        reconciled_through = value.reconciled_through or 0,
        latest_frame_id = value.latest_frame_id,
        latest_reconciliation_id = value.latest_reconciliation_id,
    }
end

local function ensure_index(instance)
    instance.runtime = instance.runtime or {}
    instance.runtime.camera = instance.runtime.camera or index(instance)
    return instance.runtime.camera
end

local function revision_snapshot(instance)
    local result = {}
    for _, component in ipairs(sorted_keys(instance and instance.revisions or {})) do
        result[component] = instance.revisions[component]
    end
    return result
end

local function changed_components(before, after, input)
    local result = {}
    local source_refs = input.source_event_refs or {}
    local budget_refs = input.budget_event_refs or {}
    local loss_refs = input.loss_event_refs or {}
    for _, component in ipairs(sorted_keys(after)) do
        local previous = before[component]
        local current = after[component]
        if previous ~= current then
            local cause = "operator_effect"
            local refs = source_refs
            if component == "budget" then
                cause = "body_tick_economics"
                refs = budget_refs
            elseif component == "loss" then
                cause = "operator_identity_loss"
                refs = loss_refs
            end
            result[#result + 1] = {
                component = component,
                before = previous,
                after = current,
                cause = cause,
                source_event_refs = copy_value(refs),
            }
        end
    end
    return result
end

local function frame_from_event(event)
    if type(event) ~= "table" or event.type ~= "runtime_frame" then
        return nil
    end
    local frame = copy_value(event.payload or {})
    frame.trace_event_id = event.id
    return frame
end

function camera.revision_snapshot(instance)
    if type(instance) ~= "table" or type(instance.revisions) ~= "table" then
        return nil, "packet revision vector required"
    end
    return revision_snapshot(instance)
end

function camera.capture(instance, input)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "capture runtime frame")
    if not mutable then
        return nil, mutable_err
    end
    input = input or {}
    local operator = topology.resolve(input.operator or instance.operator)
    if not operator then
        return nil, "runtime frame requires valid operator"
    end
    if operator ~= instance.operator then
        return nil, "runtime frame operator does not match packet position"
    end
    if type(input.revisions_before) ~= "table" then
        return nil, "runtime frame requires revisions_before"
    end
    for _, item in ipairs({
        {input.source_event_refs, "runtime frame source_event_refs"},
        {input.effect_refs, "runtime frame effect_refs"},
        {input.budget_event_refs, "runtime frame budget_event_refs"},
        {input.loss_event_refs, "runtime frame loss_event_refs"},
    }) do
        local ok, err = valid_refs(item[1], item[2])
        if not ok then
            return nil, err
        end
    end

    local store = ensure_index(instance)
    local after = revision_snapshot(instance)
    local budget_after = budget.snapshot(instance)
    local loss_after = loss.snapshot(instance)
    local progress_after = body.progress(instance)
    local frame = {
        kind = "runtime_frame",
        seq = (store.head_seq or 0) + 1,
        tick = instance.physis and instance.physis.clock
            and instance.physis.clock.ticks or 0,
        operator = operator,
        source_event_refs = copy_value(input.source_event_refs or {}),
        revisions_before = copy_value(input.revisions_before),
        revisions_after = after,
        changed_components = changed_components(input.revisions_before, after, input),
        budget = {
            before = copy_value(input.budget_before or {}),
            after = budget_after,
            exhausted_transition = type(input.budget_before) == "table"
                and input.budget_before.exhausted ~= true
                and budget_after.exhausted == true,
        },
        loss = {
            before = copy_value(input.loss_before or {}),
            after = loss_after,
            near_death_transition = type(input.loss_before) == "table"
                and input.loss_before.near_death ~= true
                and loss_after.near_death == true,
            exhausted_transition = type(input.loss_before) == "table"
                and input.loss_before.exhausted ~= true
                and loss_after.exhausted == true,
        },
        progress = {
            before = copy_value(input.progress_before or {}),
            after = progress_after,
        },
        evidence_fingerprint = {
            before = input.evidence_fingerprint_before,
            after = freshness.evidence_fingerprint(instance),
        },
        effect_refs = copy_value(input.effect_refs or {}),
        event_truth_status = "runtime_confirmed",
    }

    local event, event_err = packet_core.append_event(instance, {
        type = "runtime_frame",
        operator = operator,
        truth_status = "runtime_confirmed",
        payload = frame,
        cost = {},
    })
    if not event then
        return nil, event_err
    end
    store.head_seq = frame.seq
    store.latest_frame_id = event.id
    frame.trace_event_id = event.id
    return frame, event
end

function camera.latest(instance)
    for index_value = #(instance and instance.trace or {}), 1, -1 do
        local frame = frame_from_event(instance.trace[index_value])
        if frame then
            return frame
        end
    end
    return nil
end

function camera.pending(instance, options)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    options = options or {}
    local state = index(instance)
    local after_seq = options.after_seq
    if after_seq == nil then
        after_seq = state.reconciled_through
    end
    local through_seq = options.through_seq or state.head_seq
    local limit = options.limit or math.huge
    if type(after_seq) ~= "number" or after_seq < 0 then
        return nil, "invalid runtime frame lower bound"
    end
    if type(through_seq) ~= "number" or through_seq < after_seq then
        return nil, "invalid runtime frame upper bound"
    end
    if type(limit) ~= "number" or limit < 1 then
        return nil, "invalid runtime frame limit"
    end

    local frames = {}
    for _, event in ipairs(instance.trace or {}) do
        local frame = frame_from_event(event)
        if frame and frame.seq > after_seq and frame.seq <= through_seq then
            frames[#frames + 1] = frame
            if #frames >= limit then
                break
            end
        end
    end
    return frames
end

function camera.reconcile(instance, input)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "reconcile runtime frames")
    if not mutable then
        return nil, mutable_err
    end
    if instance.operator ~= "☱" then
        return nil, "runtime reconciliation requires RUNTIME operator"
    end
    input = input or {}
    for _, item in ipairs({
        {input.resolved_refs, "runtime reconciliation resolved_refs"},
        {input.unresolved_refs, "runtime reconciliation unresolved_refs"},
    }) do
        local ok, err = valid_refs(item[1], item[2])
        if not ok then
            return nil, err
        end
    end
    local completion_state = input.completion_state or "incomplete"
    if not completion_states[completion_state] then
        return nil, "invalid runtime reconciliation completion state"
    end

    local store = ensure_index(instance)
    local through_seq = input.through_seq or store.head_seq or 0
    if type(through_seq) ~= "number" or through_seq < (store.reconciled_through or 0)
        or through_seq > (store.head_seq or 0)
    then
        return nil, "invalid runtime reconciliation watermark"
    end
    local frames, frames_err = camera.pending(instance, {
        after_seq = store.reconciled_through or 0,
        through_seq = through_seq,
    })
    if not frames then
        return nil, frames_err
    end
    if #frames == 0 then
        return {
            kind = "runtime_reconciliation",
            status = "nothing_to_reconcile",
            from_seq = (store.reconciled_through or 0) + 1,
            through_seq = store.reconciled_through or 0,
            frame_refs = {},
            resolved_refs = {},
            unresolved_refs = {},
            completion_state = completion_state,
            event_truth_status = "runtime_confirmed",
        }
    end

    local frame_refs = {}
    for _, frame in ipairs(frames) do
        frame_refs[#frame_refs + 1] = frame.trace_event_id
    end
    local record = {
        kind = "runtime_reconciliation",
        status = "reconciled",
        from_seq = (store.reconciled_through or 0) + 1,
        through_seq = through_seq,
        frame_refs = frame_refs,
        resolved_refs = copy_value(input.resolved_refs or {}),
        unresolved_refs = copy_value(input.unresolved_refs or {}),
        momentum_updates = copy_value(input.momentum_updates or {}),
        foundation_updates = copy_value(input.foundation_updates or {}),
        completion_state = completion_state,
        event_truth_status = "runtime_confirmed",
    }
    local event, event_err = packet_core.append_event(instance, {
        type = "runtime_reconciliation",
        operator = "☱",
        truth_status = "runtime_confirmed",
        payload = record,
        cost = {},
    })
    if not event then
        return nil, event_err
    end
    store.reconciled_through = through_seq
    store.latest_reconciliation_id = event.id
    record.trace_event_id = event.id
    return record, event
end

function camera.reconciliation_state(instance)
    if type(instance) ~= "table" then
        return nil, "packet instance required"
    end
    local state = index(instance)
    state.pending_count = math.max(0, state.head_seq - state.reconciled_through)
    state.kind = "runtime_camera_state"
    state.event_truth_status = "runtime_confirmed"
    return state
end

return camera
