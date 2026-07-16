local cycle = require("logic.cycle")
local packet_core = require("core.packet")

local body = {}

local eye_specs = {
    upper = {
        operator = "☴",
        revisions = {"potential", "relations_raw", "relations_active", "calm"},
    },
    lower = {
        operator = "☱",
        revisions = {
            "relations_active",
            "momentum",
            "calm",
            "constraints",
            "evidence",
            "history",
            "budget",
            "loss",
            "scalars",
        },
    },
}

local function ensure_list(parent, key)
    if type(parent[key]) ~= "table" then
        parent[key] = {}
    end
    return parent[key]
end

local function copy_array(source)
    local result = {}
    for index, value in ipairs(source or {}) do
        result[index] = value
    end
    return result
end

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

local function equal_value(left, right, seen)
    if type(left) ~= type(right) then
        return false
    end
    if type(left) ~= "table" then
        return left == right
    end
    seen = seen or {}
    if seen[left] ~= nil then
        return seen[left] == right
    end
    seen[left] = right
    for key, value in pairs(left) do
        if not equal_value(value, right[key], seen) then
            return false
        end
    end
    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end
    return true
end

local function valid_ref_list(value, name)
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

local function observation_store(instance)
    instance.boundary = instance.boundary or {}
    local observations = instance.boundary.observations
    if type(observations) ~= "table" then
        observations = {}
    end

    if observations[1] ~= nil and observations.upper == nil then
        observations = {
            upper = observations,
            lower = {},
        }
    else
        observations.upper = observations.upper or {}
        observations.lower = observations.lower or {}
    end

    instance.boundary.observations = observations
    instance.chaos = instance.chaos or {}
    instance.chaos.observations = observations.upper
    return observations
end

local function eye_spec(eye)
    if eye == "☴" then
        eye = "upper"
    elseif eye == "☱" then
        eye = "lower"
    end
    return eye_specs[eye], eye
end

function body.revision_snapshot(instance, eye, components)
    local spec, normalized_eye = eye_spec(eye)
    if not spec then
        return nil, "invalid observation eye"
    end
    if type(instance) ~= "table" or type(instance.revisions) ~= "table" then
        return nil, "packet revision vector required"
    end

    local allowed = {}
    for _, component in ipairs(spec.revisions) do
        allowed[component] = true
    end
    local selected = components or spec.revisions
    if type(selected) ~= "table" then
        return nil, "observation revision components must be table"
    end

    local snapshot = {}
    for _, component in ipairs(selected) do
        if not allowed[component] then
            return nil, normalized_eye .. " eye cannot read revision " .. tostring(component)
        end
        local revision = instance.revisions[component]
        if type(revision) ~= "number" then
            return nil, "missing packet revision " .. tostring(component)
        end
        snapshot[component] = revision
    end
    return snapshot
end

function body.record_observation(instance, eye, input)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "record observation")
    if not mutable then
        return nil, mutable_err
    end
    local spec, normalized_eye = eye_spec(eye)
    if not spec then
        return nil, "invalid observation eye"
    end
    input = input or {}

    for _, item in ipairs({
        {input.scope_refs, "observation scope_refs"},
        {input.source_refs, "observation source_refs"},
        {input.sensor_output_refs, "observation sensor_output_refs"},
        {input.missing_scope, "observation missing_scope"},
    }) do
        local ok, err = valid_ref_list(item[1], item[2])
        if not ok then
            return nil, err
        end
    end

    local read_revisions = input.read_revisions
    if read_revisions == nil then
        local snapshot, snapshot_err = body.revision_snapshot(instance, normalized_eye, input.revision_components)
        if not snapshot then
            return nil, snapshot_err
        end
        read_revisions = snapshot
    elseif type(read_revisions) ~= "table" then
        return nil, "observation read_revisions must be table"
    end
    if next(read_revisions) == nil then
        return nil, "observation must read at least one revision"
    end

    local allowed = {}
    for _, component in ipairs(spec.revisions) do
        allowed[component] = true
    end
    for component, revision in pairs(read_revisions) do
        if not allowed[component] then
            return nil, normalized_eye .. " eye cannot record revision " .. tostring(component)
        end
        if type(revision) ~= "number" then
            return nil, "observation revision must be number"
        end
    end

    local content_truth_status = input.content_truth_status or "unknown"
    if type(content_truth_status) ~= "string" or content_truth_status == "" then
        return nil, "observation content truth status is required"
    end
    if input.fidelity ~= nil and (type(input.fidelity) ~= "string" or input.fidelity == "") then
        return nil, "observation fidelity must be non-empty string"
    end

    local stores = observation_store(instance)
    local records = stores[normalized_eye]
    local record = {
        kind = "eye_observation",
        id = "observation:" .. normalized_eye .. ":" .. tostring(#records + 1),
        eye = normalized_eye,
        operator = spec.operator,
        scope_refs = copy_value(input.scope_refs or {}),
        read_revisions = copy_value(read_revisions),
        payload = copy_value(input.payload or {}),
        metrics = copy_value(input.metrics or {}),
        missing_scope = copy_value(input.missing_scope or {}),
        sensor_output_refs = copy_value(input.sensor_output_refs or {}),
        source_refs = copy_value(input.source_refs or {}),
        event_truth_status = "runtime_confirmed",
        content_truth_status = content_truth_status,
        fidelity = input.fidelity or "bounded",
        tick = instance.physis and instance.physis.clock and instance.physis.clock.ticks or 0,
    }

    local event, event_err = packet_core.append_event(instance, {
        type = "observation",
        operator = spec.operator,
        truth_status = "runtime_confirmed",
        payload = record,
        cost = {},
    })
    if not event then
        return nil, event_err
    end
    record.trace_event_id = event.id
    records[#records + 1] = record
    return record, event
end

function body.latest_observation(instance, eye)
    local _, normalized_eye = eye_spec(eye)
    if not normalized_eye or not eye_specs[normalized_eye] then
        return nil, "invalid observation eye"
    end
    local stores = instance and instance.boundary and instance.boundary.observations or {}
    local records = stores[normalized_eye] or {}
    return copy_value(records[#records])
end

local function unit_id(unit, index)
    if type(unit) == "table" and unit.id ~= nil then
        return tostring(unit.id)
    end
    return tostring(index)
end

local function is_done(unit)
    return type(unit) == "table" and unit.status == "done"
end

local function work_units(instance)
    if type(instance) ~= "table" or type(instance.calm) ~= "table" then
        return {}
    end
    if type(instance.calm.work_units) == "table" and #instance.calm.work_units > 0 then
        return instance.calm.work_units
    end
    local current = instance.calm.current
    if type(current) == "table" and type(current.units) == "table" then
        return current.units
    end
    return {}
end

local function budget(instance)
    if type(instance) ~= "table" then
        return {}
    end
    local physis = instance.physis or instance.substrate or {}
    return physis.budget or {}
end

function body.progress(instance, options)
    options = options or {}
    local units = work_units(instance)
    local done = {}
    local remaining = {}

    for index, unit in ipairs(units) do
        local id = unit_id(unit, index)
        if is_done(unit) then
            done[#done + 1] = id
        else
            remaining[#remaining + 1] = id
        end
    end

    local logic_status = options.logic_status
    if logic_status == nil then
        logic_status = "accepted"
    end

    return {
        goal = options.goal or (instance and instance.chaos and instance.chaos.raw_prompt) or nil,
        needed_count = #units,
        done_count = #done,
        remaining_count = #remaining,
        done = done,
        remaining = remaining,
        logic_status = logic_status,
    }
end

function body.record_choice(instance, choice_payload)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "record choice")
    if not mutable then
        return nil, mutable_err
    end
    choice_payload = choice_payload or {}
    local event, event_err = packet_core.append_event(instance, {
        type = "choice",
        operator = "☳",
        truth_status = choice_payload.truth_status or "runtime_confirmed",
        payload = choice_payload,
        cost = choice_payload.cost or {},
    })
    if not event then
        return nil, event_err
    end
    local choices = ensure_list(instance.boundary, "choices")
    choices[#choices + 1] = choice_payload
    return choice_payload, event
end

function body.record_validation(instance, validation_payload)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "record validation")
    if not mutable then
        return nil, mutable_err
    end
    validation_payload = validation_payload or {}
    local event, event_err = packet_core.append_event(instance, {
        type = "validation",
        operator = "☶",
        truth_status = validation_payload.truth_status or "runtime_confirmed",
        payload = validation_payload,
        cost = validation_payload.cost or {},
    })
    if not event then
        return nil, event_err
    end
    local validations = ensure_list(instance.boundary, "validations")
    validations[#validations + 1] = validation_payload
    if instance.revisions then
        instance.revisions.constraints = (instance.revisions.constraints or 0) + 1
    end
    return validation_payload
end

function body.record_cycle(instance, cycle_payload)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "record cycle")
    if not mutable then
        return nil, mutable_err
    end
    cycle_payload = cycle_payload or {}
    local event, event_err = packet_core.append_event(instance, {
        type = "cycle",
        operator = "☲",
        truth_status = cycle_payload.truth_status or "runtime_confirmed",
        payload = cycle_payload,
        cost = cycle_payload.cost or {},
    })
    if not event then
        return nil, event_err
    end
    local cycles = ensure_list(instance.boundary, "cycles")
    cycles[#cycles + 1] = cycle_payload
    return cycle_payload
end

function body.cycle_input(instance, options)
    options = options or {}
    return {
        cycle_key = options.cycle_key or "packet_body",
        turn_count = options.turn_count or 0,
        max_turns = options.max_turns or 1,
        budget = options.budget or budget(instance),
        required_budget = options.required_budget or {steps = 1},
        state_fingerprint = options.state_fingerprint,
        previous_fingerprints = options.previous_fingerprints,
        manifest_ready = options.manifest_ready,
        unsafe = options.unsafe,
        needs_user_input = options.needs_user_input,
        progress = body.progress(instance, {
            goal = options.goal,
            logic_status = options.logic_status,
        }),
    }
end

function body.decide_cycle(instance, options)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "decide cycle")
    if not mutable then
        return nil, mutable_err
    end
    local payload, err = cycle.decide(body.cycle_input(instance, options))
    if not payload then
        return nil, err
    end
    local recorded, record_err = body.record_cycle(instance, payload)
    if not recorded then
        return nil, record_err
    end
    return payload
end

function body.apply_crystallized_work(instance, units, options)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "apply crystallized work")
    if not mutable then
        return nil, mutable_err
    end
    options = options or {}
    local next_units = copy_array(units)
    local next_status = options.status or instance.calm.status or "accepted"
    local changed = not equal_value(instance.calm.work_units or {}, next_units)
        or instance.calm.status ~= next_status
    if changed then
        instance.calm.work_units = next_units
        instance.calm.status = next_status
        if instance.revisions then
            instance.revisions.calm = (instance.revisions.calm or 0) + 1
        end
    end
    return body.progress(instance, {
        goal = options.goal,
        logic_status = options.logic_status,
    })
end

return body
