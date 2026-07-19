package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local fixture = require("tests.support.repository_hands")
local capabilities, capabilities_err = H.optional_require("runtime.repository_capability")
local suite = H.new("repository-route")

local function require_capabilities()
    return suite:require_module(
        capabilities,
        capabilities_err,
        "runtime.repository_capability"
    )
end

local function run_with_hand(options)
    options = options or {}
    local cap = require_capabilities()
    local registry, _, _, state
    if options.with_grant ~= false then
        registry, _, _, state = fixture.new_registry(cap, {
            provider_options = options.provider_options,
        })
    else
        local provider
        provider, state = fixture.fake_provider(options.provider_options)
        registry = assert(cap.new({
            session_id = "session-repository-hands",
            providers = {[provider.provider_id] = provider},
        }))
    end
    local runner_options = {
        repository_hands = {
            protocol_version = "repository.hands.config.v0",
            enabled = true,
            repository_id = "repo-a",
        },
        host_services = {repository_capabilities = registry},
    }
    for key, value in pairs(options.runner_options or {}) do
        runner_options[key] = value
    end
    local instance, result = fixture.packet(options.items or {{
        path = "src/main.lua",
        content = "return 'route'\n",
    }}, {
        shape = options.shape,
        max_ticks = options.max_ticks or 14,
        runner_options = runner_options,
    })
    return instance, result, state
end

local function event_count(instance, event_type)
    local count = 0
    for _, event in ipairs(instance.trace or {}) do
        if event.type == event_type then
            count = count + 1
        end
    end
    return count
end

suite:check("R0/R9 disabled hands are physically inert", function()
    local items = {{path = "src/main.lua", content = "return 'same'\n"}}
    local left, left_result = fixture.packet(items, {
        label = "hand-disabled-left",
        max_ticks = 8,
    })
    local right, right_result = fixture.packet(items, {
        label = "hand-disabled-right",
        max_ticks = 8,
        runner_options = {
            repository_hands = {
                protocol_version = "repository.hands.config.v0",
                enabled = false,
                repository_id = "repo-a",
            },
        },
    })
    H.assert_eq(table.concat(fixture.route_pairs(left), ","),
        table.concat(fixture.route_pairs(right), ","), "disabled route unchanged")
    H.assert_eq(left.runtime.budget.spent.steps, right.runtime.budget.spent.steps,
        "disabled step economy unchanged")
    H.assert_eq(left.tension.loss_remaining, right.tension.loss_remaining,
        "disabled loss unchanged")
    H.assert_eq(event_count(right, "repository_effect_attempt"), 0,
        "disabled modules add no effect events")
end)

suite:check("R1 enabled hand without grant cannot call provider", function()
    local instance, _, state = run_with_hand({with_grant = false})
    H.assert_eq(state.calls.create, 0, "missing grant makes no writer call")
    H.assert_eq(event_count(instance, "repository_effect_attempt"), 0,
        "missing grant creates no attempt")
end)

suite:check("R2 exact single action uses no fake CHOOSE", function()
    local instance, _, state = run_with_hand()
    local pairs = fixture.route_pairs(instance)
    H.assert_true(fixture.contains_subsequence(pairs, {
        "☵->☱", "☱->☶", "☶->☱",
    }), "single action contains review/effect/reconcile subpath")
    H.assert_eq(#(instance.boundary.choices or {}), 0, "single action pays no choice")
    H.assert_eq(state.calls.create, 1, "one writer call")
    H.assert_eq(event_count(instance, "work_completion"), 1, "one completion")
end)

suite:check("R3 real alternatives use exact CHOOSE before effect", function()
    local instance = run_with_hand({
        shape = "alternative_set",
        items = {
            {path = "src/a.lua", content = "return 'a'\n"},
            {path = "src/b.lua", content = "return 'b'\n"},
        },
        max_ticks = 16,
    })
    H.assert_true(fixture.contains_subsequence(fixture.route_pairs(instance), {
        "☵->☳", "☳->☶", "☶->☱",
    }), "real choice reaches effect through CHOOSE")
    H.assert_eq(#(instance.boundary.choices or {}), 1, "one real collapse")
end)

suite:check("R4 review ablation removes single-action RUNTIME proposal", function()
    local instance, _, state = run_with_hand({
        runner_options = {ablate_repository_review = true},
    })
    H.assert_false(fixture.contains_subsequence(fixture.route_pairs(instance), {
        "☵->☱", "☱->☶",
    }), "review-less life cannot reach effect")
    H.assert_eq(state.calls.create, 0, "no review means no writer")
end)

suite:check("R5 effect witness ablation removes LOGIC effect", function()
    local instance, _, state = run_with_hand({
        runner_options = {ablate_repository_effect = true},
    })
    H.assert_eq(state.calls.create, 0, "effect witness is required")
    H.assert_eq(event_count(instance, "repository_effect_attempt"), 0,
        "no effect witness means no attempt")
end)

suite:check("R6 reconciliation ablation leaves file without completion", function()
    local instance, _, state = run_with_hand({
        runner_options = {ablate_repository_reconcile = true},
    })
    H.assert_eq(state.calls.create, 1, "effect may happen")
    H.assert_eq(event_count(instance, "repository_verification"), 1,
        "evidence may exist")
    H.assert_eq(event_count(instance, "work_completion"), 0,
        "no reconciliation means no done")
end)

suite:check("R7 receipt without accepted read-back cannot complete", function()
    local instance = run_with_hand({
        provider_options = {
            read_override = function(_, _, state)
                return {
                    protocol_version = "repository.provider_result.v0",
                    operation = "read_text_file",
                    outcome = "observed",
                    target_kind = "missing",
                    root = H.copy(state.root_identity),
                    mutation_primitive_entered = false,
                    published = false,
                    cost = {tool_calls = 1, file_writes = 0, time_ms = 0},
                }
            end,
        },
    })
    H.assert_eq(event_count(instance, "repository_effect_receipt"), 1,
        "writer receipt exists")
    H.assert_eq(event_count(instance, "work_completion"), 0,
        "rejected read-back cannot complete")
end)

suite:check("R8 exact accepted chain has one verified completion", function()
    local instance, _, state = run_with_hand()
    H.assert_eq(state.files["src/main.lua"], "return 'route'\n", "one exact file")
    H.assert_eq(event_count(instance, "repository_effect_attempt"), 1, "one attempt")
    H.assert_eq(event_count(instance, "repository_effect_receipt"), 1, "one receipt")
    H.assert_eq(event_count(instance, "repository_verification"), 1, "one verification")
    H.assert_eq(event_count(instance, "work_completion"), 1, "one completion")
end)

suite:check("R10 hand opt-in does not change default router authority", function()
    local cap = require_capabilities()
    local registry = fixture.new_registry(cap)
    local instance = fixture.packet({{
        path = "src/main.lua", content = "return 'shadow'\n",
    }}, {
        max_ticks = 8,
        runner_options = {
            router_mode = "shadow",
            repository_hands = {
                protocol_version = "repository.hands.config.v0",
                enabled = true,
                repository_id = "repo-a",
            },
            host_services = {repository_capabilities = registry},
        },
    })
    for _, event in ipairs(instance.trace or {}) do
        if event.type == "route" then
            H.assert_false(event.payload.authority == "tree",
                "hand cannot silently promote Tree authority")
        end
    end
end)

suite:finish()
print("test_repository_route ok")
