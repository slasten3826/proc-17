package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local fixture = require("tests.support.repository_hands")
local body = require("runtime.body")
local logic = require("organs.logic")
local capabilities, capabilities_err = H.optional_require("runtime.repository_capability")
local intent_module, intent_err = H.optional_require("runtime.repository_intent")
local action_module, action_err = H.optional_require("runtime.repository_action")
local effect_module, effect_err = H.optional_require("runtime.repository_effect")
local completion_module, completion_err = H.optional_require("runtime.work_completion")
local suite = H.new("repository-progress")

local function modules()
    return suite:require_module(capabilities, capabilities_err, "runtime.repository_capability"),
        suite:require_module(intent_module, intent_err, "runtime.repository_intent"),
        suite:require_module(action_module, action_err, "runtime.repository_action"),
        suite:require_module(effect_module, effect_err, "runtime.repository_effect"),
        suite:require_module(completion_module, completion_err, "runtime.work_completion")
end

local function grown_chain(options)
    options = options or {}
    local cap, intents, actions, effects = modules()
    local instance = fixture.packet(options.items or {{
        path = "src/main.lua",
        content = "return 'complete'\n",
    }}, {
        shape = options.shape,
        max_ticks = options.max_ticks,
    })
    local intent = assert(intents.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    }))
    local registry = fixture.new_registry(cap)
    local action = assert(actions.authorize(instance, intent, registry, {
        session_id = instance.session_id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        repository_id = "repo-a",
        work_mode = "build",
    }))
    fixture.move_to(instance, "☶")
    local _, validation = assert(logic.run(instance, {
        work_mode = "build",
        repository_effect = {action = action},
    }, {repository_capabilities = registry}))
    local outcome = {
        status = validation.status,
        reason = validation.reason,
        attempt_ref = validation.attempt_ref,
        receipt_ref = validation.receipt_ref,
        verification_ref = validation.verification_ref,
    }
    local validation_event = {id = validation.trace_event_id}
    return instance, action, registry, outcome, validation, validation_event
end

suite:check("E6 accepted verification without RUNTIME is still pending", function()
    local _, _, _, _, completions = modules()
    local instance, action = grown_chain()
    H.assert_false(completions.is_complete(instance,
        action.work_unit.id, action.work_unit.version), "no ☱ means no completion")
    local progress = body.progress(instance)
    H.assert_eq(progress.done_count, 0, "verification alone is not done")
end)

suite:check("E7 exact RUNTIME chain creates one completion", function()
    local _, _, _, _, completions = modules()
    local instance, action, _, outcome, _, validation_event = grown_chain()
    fixture.move_to(instance, "☱")
    local candidate = assert(completions.derive(instance, {
        action = action,
        attempt_ref = outcome.attempt_ref,
        receipt_ref = outcome.receipt_ref,
        verification_ref = outcome.verification_ref,
        validation_ref = validation_event.id,
    }))
    local record = assert(completions.record(instance, candidate))
    H.assert_eq(record.completed_status, "done", "completion records done predicate")
    H.assert_true(completions.is_complete(instance,
        action.work_unit.id, action.work_unit.version), "exact work becomes complete")
end)

suite:check("E8 repeated reconciliation cannot duplicate completion", function()
    local _, _, _, _, completions = modules()
    local instance, action, _, outcome, _, validation_event = grown_chain()
    fixture.move_to(instance, "☱")
    local input = {
        action = action,
        attempt_ref = outcome.attempt_ref,
        receipt_ref = outcome.receipt_ref,
        verification_ref = outcome.verification_ref,
        validation_ref = validation_event.id,
    }
    local first = assert(completions.derive(instance, input))
    assert(completions.record(instance, first))
    local second, err = completions.derive(instance, input)
    H.assert_nil(second, "completed state has no new candidate")
    H.assert_contains(err, "already", "duplicate exclusion is explicit")
end)

suite:check("E8b completion candidate is invalidated by a later effect attempt", function()
    local _, _, _, effects, completions = modules()
    local instance, action, registry, outcome, _, validation_event = grown_chain()
    fixture.move_to(instance, "☱")
    local candidate = assert(completions.derive(instance, {
        action = action,
        attempt_ref = outcome.attempt_ref,
        receipt_ref = outcome.receipt_ref,
        verification_ref = outcome.verification_ref,
        validation_ref = validation_event.id,
    }))
    fixture.move_to(instance, "☶")
    local repeated = effects.execute(instance, action, registry)
    H.assert_nil(repeated, "one-use action creates no second effect")
    fixture.move_to(instance, "☱")
    local record, err = completions.record(instance, candidate)
    H.assert_nil(record, "stale completion candidate cannot cross a later attempt")
    H.assert_contains(err, "conflicting", "TOCTOU denial names the conflict")
end)

suite:check("E9 evidence for work A cannot complete work B", function()
    local _, _, _, _, completions = modules()
    local instance, action, _, outcome, _, validation_event = grown_chain()
    fixture.move_to(instance, "☱")
    local forged = H.copy(action)
    forged.work_unit.id = "unit:other"
    local candidate, err = completions.derive(instance, {
        action = forged,
        attempt_ref = outcome.attempt_ref,
        receipt_ref = outcome.receipt_ref,
        verification_ref = outcome.verification_ref,
        validation_ref = validation_event.id,
    })
    H.assert_nil(candidate, "cross-work completion denied")
    H.assert_contains(err, "work", "cross-work mismatch is explicit")
end)

suite:check("E10 changed field version invalidates old evidence", function()
    local _, _, _, _, completions = modules()
    local instance, action, _, outcome, _, validation_event = grown_chain()
    instance.field.units[action.work_unit.id].version = action.work_unit.version + 1
    fixture.move_to(instance, "☱")
    local candidate, err = completions.derive(instance, {
        action = action,
        attempt_ref = outcome.attempt_ref,
        receipt_ref = outcome.receipt_ref,
        verification_ref = outcome.verification_ref,
        validation_ref = validation_event.id,
    })
    H.assert_nil(candidate, "old evidence cannot complete changed work")
    H.assert_contains(err, "version", "stale evidence names version")
end)

suite:check("E12 returned completion cannot mutate trace", function()
    local _, _, _, _, completions = modules()
    local instance, action, _, outcome, _, validation_event = grown_chain()
    fixture.move_to(instance, "☱")
    local record = assert(completions.record(instance, assert(completions.derive(instance, {
        action = action,
        attempt_ref = outcome.attempt_ref,
        receipt_ref = outcome.receipt_ref,
        verification_ref = outcome.verification_ref,
        validation_ref = validation_event.id,
    }))))
    record.completed_status = "caller-forged"
    local stored
    for _, event in ipairs(instance.trace) do
        if event.type == "work_completion" then
            stored = event.payload
        end
    end
    H.assert_eq(stored.completed_status, "done", "trace owns completion")
end)

suite:check("E15 exact completion drives body.progress", function()
    local _, _, _, _, completions = modules()
    local instance, action, _, outcome, _, validation_event = grown_chain()
    fixture.move_to(instance, "☱")
    assert(completions.record(instance, assert(completions.derive(instance, {
        action = action,
        attempt_ref = outcome.attempt_ref,
        receipt_ref = outcome.receipt_ref,
        verification_ref = outcome.verification_ref,
        validation_ref = validation_event.id,
    }))))
    local progress = body.progress(instance)
    H.assert_eq(progress.needed_count, 1, "one exact work predicate")
    H.assert_eq(progress.done_count, 1, "completion ledger drives done")
    H.assert_eq(progress.remaining_count, 0, "no repository work remains")
end)

suite:check("E16 selected alternative keeps its earlier formation witness", function()
    local _, _, _, _, completions = modules()
    local instance, action, _, outcome, _, validation_event = grown_chain({
        shape = "alternative_set",
        max_ticks = 4,
        items = {
            {path = "src/a.lua", content = "return 'a'\n"},
            {path = "src/b.lua", content = "return 'b'\n"},
        },
    })
    H.assert_eq(action.work_unit.version, 2,
        "CHOOSE restamped the selected unit after formation")
    fixture.move_to(instance, "☱")
    local record = assert(completions.record(instance, assert(completions.derive(instance, {
        action = action,
        attempt_ref = outcome.attempt_ref,
        receipt_ref = outcome.receipt_ref,
        verification_ref = outcome.verification_ref,
        validation_ref = validation_event.id,
    }))))
    H.assert_eq(record.completed_status, "done",
        "formation version at or below selected version remains exact history")
end)

suite:finish()
print("test_repository_progress ok")
