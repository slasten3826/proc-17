package.path = "./?.lua;./?/init.lua;" .. package.path

local cycle = require("logic.cycle")

local function decide(input)
    local payload, err = cycle.decide(input)
    if not payload then
        error("cycle decision failed: " .. tostring(err))
    end
    return payload
end

local continued = decide({
    cycle_key = "repo_loop",
    turn_count = 0,
    max_turns = 2,
    accepted_count = 1,
    new_input_count = 1,
    budget = {steps = 2, substrate_calls = 1},
    required_budget = {steps = 1},
    state_fingerprint = "a",
    previous_fingerprints = {},
})

if continued.decision ~= "continue" then
    error("cycle should continue with accepted input and budget")
end

if continued.truth_status ~= "runtime_confirmed" then
    error("cycle decision should be runtime_confirmed")
end

local unsafe = decide({
    unsafe = true,
    needs_user_input = true,
    budget = {},
    required_budget = {steps = 1},
})

if unsafe.decision ~= "stop_unsafe" then
    error("unsafe should have first priority")
end

local user_input = decide({
    needs_user_input = true,
    manifest_ready = true,
})

if user_input.decision ~= "needs_user_input" then
    error("needs_user_input should precede manifest_ready")
end

local complete = decide({
    manifest_ready = true,
    budget = {},
    required_budget = {steps = 1},
})

if complete.decision ~= "stop_complete" then
    error("manifest_ready should stop complete before budget")
end

local budget = decide({
    turn_count = 0,
    max_turns = 3,
    accepted_count = 1,
    new_input_count = 1,
    budget = {steps = 0},
    required_budget = {steps = 1},
})

if budget.decision ~= "stop_budget" then
    error("cycle should stop when budget cannot pay")
end

local max_turns = decide({
    turn_count = 2,
    max_turns = 2,
    accepted_count = 1,
    new_input_count = 1,
    budget = {steps = 1},
    required_budget = {steps = 1},
})

if max_turns.decision ~= "stop_repetition" or max_turns.reason ~= "max_turns" then
    error("cycle should stop when max_turns reached")
end

local repeated = decide({
    turn_count = 1,
    max_turns = 3,
    accepted_count = 1,
    new_input_count = 1,
    budget = {steps = 1},
    required_budget = {steps = 1},
    state_fingerprint = "same",
    previous_fingerprints = {same = true},
})

if repeated.decision ~= "stop_repetition" or repeated.reason ~= "state_fingerprint" then
    error("cycle should stop on repeated fingerprint")
end

local progress_again = decide({
    cycle_key = "organogenesis",
    turn_count = 1,
    max_turns = 5,
    budget = {steps = 4},
    required_budget = {steps = 1},
    progress = {
        goal = "workspace organs",
        needed_count = 5,
        done_count = 1,
        remaining_count = 4,
        logic_status = "accepted",
    },
})

if progress_again.decision ~= "again" or progress_again.reason ~= "remaining_work" then
    error("cycle should say again when progress has remaining work")
end

if progress_again.semantic_loss ~= "near_zero" then
    error("cycle should expose near-zero semantic loss")
end

if progress_again.runtime_cost ~= "one_turn" then
    error("cycle should expose one-turn runtime cost")
end

if progress_again.progress.remaining_count ~= 4 then
    error("cycle should copy progress remaining count")
end

local progress_complete = decide({
    turn_count = 1,
    max_turns = 5,
    budget = {steps = 4},
    required_budget = {steps = 1},
    progress = {
        needed_count = 5,
        done_count = 5,
        remaining_count = 0,
        logic_status = "accepted",
    },
})

if progress_complete.decision ~= "stop_complete" or progress_complete.reason ~= "progress_complete" then
    error("cycle should stop complete when progress is complete")
end

local progress_invalid = decide({
    turn_count = 1,
    max_turns = 5,
    budget = {steps = 4},
    required_budget = {steps = 1},
    progress = {
        needed_count = 5,
        done_count = 8,
        remaining_count = -3,
        logic_status = "rejected",
    },
})

if progress_invalid.decision ~= "stop_invalid" or progress_invalid.reason ~= "progress:rejected" then
    error("cycle should stop invalid when logic rejects progress")
end

local no_accepted = decide({
    turn_count = 0,
    max_turns = 3,
    accepted_count = 0,
    new_input_count = 1,
    budget = {steps = 1},
    required_budget = {steps = 1},
})

if no_accepted.decision ~= "stop_no_progress" or no_accepted.reason ~= "accepted_count" then
    error("cycle should stop when accepted_count is zero")
end

local no_new_input = decide({
    turn_count = 0,
    max_turns = 3,
    accepted_count = 1,
    new_input_count = 0,
    budget = {steps = 1},
    required_budget = {steps = 1},
})

if no_new_input.decision ~= "stop_no_progress" or no_new_input.reason ~= "new_input_count" then
    error("cycle should stop when new_input_count is zero")
end

local invalid, invalid_err = cycle.decide({max_turns = 0})
if invalid or invalid_err ~= "max_turns must be positive number" then
    error("cycle should reject invalid max_turns")
end

print("test_cycle ok")
