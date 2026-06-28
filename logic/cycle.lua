local cycle = {}

local decisions = {
    continue = true,
    stop_complete = true,
    stop_no_progress = true,
    stop_repetition = true,
    stop_budget = true,
    stop_unsafe = true,
    needs_user_input = true,
}

local function number_or_zero(value)
    if type(value) == "number" then
        return value
    end
    return 0
end

local function has_fingerprint(previous, fingerprint)
    if not fingerprint or fingerprint == "" then
        return false
    end
    if type(previous) ~= "table" then
        return false
    end
    if previous[fingerprint] == true then
        return true
    end
    for _, value in ipairs(previous) do
        if value == fingerprint then
            return true
        end
    end
    return false
end

local function budget_can_pay(budget, required)
    budget = budget or {}
    required = required or {}
    for key, amount in pairs(required) do
        if number_or_zero(budget[key]) < number_or_zero(amount) then
            return false, key
        end
    end
    return true
end

local function payload(input, decision, reason)
    return {
        kind = "cycle_decision_payload",
        decision = decision,
        reason = reason,
        cycle_key = input.cycle_key,
        turn_count = number_or_zero(input.turn_count),
        max_turns = number_or_zero(input.max_turns),
        truth_status = "runtime_confirmed",
    }
end

function cycle.is_decision(value)
    return decisions[value] == true
end

function cycle.decide(input)
    input = input or {}
    local max_turns = input.max_turns or 1
    if type(max_turns) ~= "number" or max_turns < 1 then
        return nil, "max_turns must be positive number"
    end

    if input.unsafe == true then
        return payload(input, "stop_unsafe", "unsafe")
    end

    if input.needs_user_input == true then
        return payload(input, "needs_user_input", "needs_user_input")
    end

    if input.manifest_ready == true then
        return payload(input, "stop_complete", "manifest_ready")
    end

    local can_pay, missing_key = budget_can_pay(input.budget, input.required_budget)
    if not can_pay then
        return payload(input, "stop_budget", "budget:" .. tostring(missing_key))
    end

    if number_or_zero(input.turn_count) >= max_turns then
        return payload(input, "stop_repetition", "max_turns")
    end

    if has_fingerprint(input.previous_fingerprints, input.state_fingerprint) then
        return payload(input, "stop_repetition", "state_fingerprint")
    end

    if number_or_zero(input.accepted_count) <= 0 then
        return payload(input, "stop_no_progress", "accepted_count")
    end

    if number_or_zero(input.new_input_count) <= 0 then
        return payload(input, "stop_no_progress", "new_input_count")
    end

    return payload(input, "continue", "continuation_payable")
end

return cycle
