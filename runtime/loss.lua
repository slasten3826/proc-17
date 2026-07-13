local loss = {}

local function clamp(value, min, max)
    value = tonumber(value) or 0
    if value < min then
        return min
    end
    if value > max then
        return max
    end
    return value
end

local function copy_array(source, limit)
    local out = {}
    if type(source) ~= "table" then
        return out
    end
    local count = math.min(#source, limit or #source)
    for index = 1, count do
        out[#out + 1] = source[index]
    end
    return out
end

local function tail(source, limit)
    local out = {}
    if type(source) ~= "table" then
        return out
    end
    limit = limit or 5
    local start = math.max(1, #source - limit + 1)
    for index = start, #source do
        out[#out + 1] = source[index]
    end
    return out
end

local function ensure(instance, options)
    options = options or {}
    instance.tension = instance.tension or {}
    local tension = instance.tension
    local physis = instance.physis or instance.substrate or {}
    local budget_loss = physis.budget and physis.budget.loss
    tension.loss_max = tension.loss_max or options.max_loss or budget_loss or 1.0
    tension.loss_near_death_at = tension.loss_near_death_at or options.near_death_at or 0.2
    tension.loss = tension.loss or 0
    tension.loss_remaining = tension.loss_remaining or tension.loss_max
    tension.loss_near_death = tension.loss_near_death == true
    tension.loss_exhausted = tension.loss_exhausted == true
    tension.loss_events = tension.loss_events or {}
    return tension
end

local function refresh(tension)
    tension.loss_remaining = (tension.loss_max or 1.0) - (tension.loss or 0)
    tension.loss_near_death = tension.loss_remaining <= (tension.loss_near_death_at or 0.2)
    tension.loss_exhausted = tension.loss_remaining <= 0
end

function loss.init(instance, options)
    local tension = ensure(instance, options)
    refresh(tension)
    return instance
end

function loss.from_encode_loss(encoded_loss)
    encoded_loss = encoded_loss or {}
    if type(encoded_loss.loss_percentage) == "number" then
        return clamp(encoded_loss.loss_percentage, 0, 1)
    end
    if type(encoded_loss.omitted_count) == "number" and encoded_loss.omitted_count > 0 then
        return 0.1
    end
    return 0
end

function loss.from_choose_loss(choice_loss)
    choice_loss = choice_loss or {}
    local before = choice_loss.before_count
    if type(before) ~= "number" or before <= 0 then
        return 0
    end
    return clamp((choice_loss.not_chosen_count or 0) / before, 0, 1)
end

function loss.apply(instance, input)
    input = input or {}
    local tension = ensure(instance)
    local amount = clamp(input.amount, 0, tension.loss_max or 1.0)
    tension.loss = (tension.loss or 0) + amount
    refresh(tension)

    local record = {
        kind = "loss_accumulation",
        operator = input.operator,
        event_id = input.event_id,
        amount = amount,
        loss_kind = input.kind,
        source = input.source or "manual",
        detail = input.detail or {},
        loss_after = tension.loss,
        loss_remaining_after = tension.loss_remaining,
        near_death = tension.loss_near_death,
        exhausted = tension.loss_exhausted,
        truth_status = input.truth_status or "runtime_confirmed",
    }
    tension.loss_events[#tension.loss_events + 1] = record
    return record
end

function loss.snapshot(instance)
    local tension = ensure(instance)
    refresh(tension)
    return {
        kind = "packet_loss_snapshot",
        loss = tension.loss,
        loss_max = tension.loss_max,
        loss_remaining = tension.loss_remaining,
        near_death = tension.loss_near_death,
        exhausted = tension.loss_exhausted,
        event_count = #(tension.loss_events or {}),
        truth_status = "runtime_confirmed",
    }
end

function loss.is_exhausted(instance)
    local tension = ensure(instance)
    refresh(tension)
    return tension.loss_exhausted == true
end

function loss.identity_residue(instance, options)
    options = options or {}
    local tension = ensure(instance)
    refresh(tension)
    return {
        cause = "identity_loss",
        loss = tension.loss,
        loss_remaining = tension.loss_remaining,
        loss_near_death = tension.loss_near_death,
        loss_exhausted = tension.loss_exhausted,
        loss_events_tail = tail(tension.loss_events, options.loss_events_tail_count or 5),
        loss_records_tail = tail(instance.boundary and instance.boundary.loss_records, options.loss_records_tail_count or 5),
        last_operator = options.last_operator or instance.operator,
        do_not_repeat = "packet coherence exhausted by loss",
    }
end

loss._copy_array = copy_array

return loss
