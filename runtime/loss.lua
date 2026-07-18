local packet_core = require("core.packet")

local loss = {}

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
        out[#out + 1] = copy_value(source[index])
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
        out[#out + 1] = copy_value(source[index])
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
    local mutable, mutable_err = packet_core.assert_mutable(instance, "initialize loss")
    if not mutable then
        return nil, mutable_err
    end
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
    local mutable, mutable_err = packet_core.assert_mutable(instance, "apply loss")
    if not mutable then
        return nil, mutable_err
    end
    input = input or {}
    if type(input.amount) ~= "number"
        or input.amount ~= input.amount
        or input.amount == math.huge
        or input.amount == -math.huge then
        return nil, "loss amount must be finite number"
    end
    if input.amount < 0 then
        return nil, "loss amount must be non-negative"
    end
    local tension = ensure(instance)
    local amount = clamp(input.amount, 0, tension.loss_max or 1.0)
    tension.loss = (tension.loss or 0) + amount
    refresh(tension)
    if instance.revisions then
        instance.revisions.loss = (instance.revisions.loss or 0) + 1
    end

    local record = {
        kind = "loss_accumulation",
        operator = input.operator,
        event_id = input.event_id,
        amount = amount,
        loss_kind = input.kind,
        source = input.source or "manual",
        detail = copy_value(input.detail or {}),
        loss_after = tension.loss,
        loss_remaining_after = tension.loss_remaining,
        near_death = tension.loss_near_death,
        exhausted = tension.loss_exhausted,
        truth_status = input.truth_status or "runtime_confirmed",
    }
    tension.loss_events[#tension.loss_events + 1] = record
    return copy_value(record)
end

function loss.snapshot(instance)
    local tension = instance and instance.tension or {}
    local physis = instance and (instance.physis or instance.substrate) or {}
    local loss_max = tension.loss_max or (physis.budget and physis.budget.loss) or 1.0
    local current_loss = tension.loss or 0
    local loss_remaining = loss_max - current_loss
    local near_death_at = tension.loss_near_death_at or 0.2
    return {
        kind = "packet_loss_snapshot",
        loss = current_loss,
        loss_max = loss_max,
        loss_remaining = loss_remaining,
        near_death = loss_remaining <= near_death_at,
        exhausted = loss_remaining <= 0,
        event_count = #(tension.loss_events or {}),
        truth_status = "runtime_confirmed",
    }
end

function loss.is_exhausted(instance)
    return loss.snapshot(instance).exhausted == true
end

function loss.identity_residue(instance, options)
    options = options or {}
    local tension = instance and instance.tension or {}
    local snapshot = loss.snapshot(instance)
    return {
        cause = "identity_loss",
        loss = snapshot.loss,
        loss_remaining = snapshot.loss_remaining,
        loss_near_death = snapshot.near_death,
        loss_exhausted = snapshot.exhausted,
        loss_events_tail = tail(tension.loss_events, options.loss_events_tail_count or 5),
        loss_records_tail = tail(instance.boundary and instance.boundary.loss_records, options.loss_records_tail_count or 5),
        last_operator = options.last_operator or instance.operator,
        do_not_repeat = "packet coherence exhausted by loss",
    }
end

loss._copy_array = copy_array

return loss
