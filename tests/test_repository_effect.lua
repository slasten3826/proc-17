package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local fixture = require("tests.support.repository_hands")
local contract = require("substrates.contract")
local capabilities, capabilities_err = H.optional_require("runtime.repository_capability")
local intent_module, intent_err = H.optional_require("runtime.repository_intent")
local action_module, action_err = H.optional_require("runtime.repository_action")
local effect_module, effect_err = H.optional_require("runtime.repository_effect")
local suite = H.new("repository-effect")

local function modules()
    return suite:require_module(capabilities, capabilities_err, "runtime.repository_capability"),
        suite:require_module(intent_module, intent_err, "runtime.repository_intent"),
        suite:require_module(action_module, action_err, "runtime.repository_action"),
        suite:require_module(effect_module, effect_err, "runtime.repository_effect")
end

local function setup(provider_options)
    local cap, intents, actions = modules()
    local instance = fixture.packet({{
        path = "src/main.lua",
        content = "return 'effect'\n",
    }})
    local intent = assert(intents.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    }))
    local registry, projection, provider, state = fixture.new_registry(cap, {
        provider_options = provider_options,
    })
    local action = assert(actions.authorize(instance, intent, registry, {
        session_id = instance.session_id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        repository_id = "repo-a",
        work_mode = "build",
    }))
    fixture.move_to(instance, "☶")
    return instance, action, registry, projection, provider, state
end

local function events(instance, event_type)
    local result = {}
    for _, event in ipairs(instance.trace or {}) do
        if event.type == event_type then
            result[#result + 1] = event
        end
    end
    return result
end

local function contains_key(value, target, seen)
    if type(value) ~= "table" then
        return false
    end
    seen = seen or {}
    if seen[value] then
        return false
    end
    seen[value] = true
    for key, child in pairs(value) do
        if key == target or contains_key(child, target, seen) then
            return true
        end
    end
    return false
end

local function contains_scalar(value, target, seen)
    if value == target then
        return true
    end
    if type(value) ~= "table" then
        return false
    end
    seen = seen or {}
    if seen[value] then
        return false
    end
    seen[value] = true
    for key, child in pairs(value) do
        if contains_scalar(key, target, seen) or contains_scalar(child, target, seen) then
            return true
        end
    end
    return false
end

suite:check("E0 exact effect grows attempt receipt and accepted verification", function()
    local _, _, _, effects = modules()
    local instance, action, registry, _, _, state = setup()
    local outcome = assert(effects.execute(instance, action, registry))
    H.assert_eq(outcome.status, "accepted", "exact read-back accepts")
    H.assert_eq(#events(instance, "repository_effect_attempt"), 1, "one attempt")
    H.assert_eq(#events(instance, "repository_effect_receipt"), 1, "one receipt")
    H.assert_eq(#events(instance, "repository_verification"), 1, "one verification")
    H.assert_eq(state.files["src/main.lua"], "return 'effect'\n", "exact bytes written")
    H.assert_eq(state.calls.create, 1, "one writer call")
    H.assert_eq(state.calls.read, 1, "one independent reader call")
end)

suite:check("E1 committed position without execution changes no world", function()
    local _, _, _, effects = modules()
    local instance, _, _, _, _, state = setup()
    H.assert_true(type(effects.execute) == "function", "effect boundary exists")
    H.assert_eq(state.calls.create, 0, "position is not an effect")
    H.assert_eq(#events(instance, "repository_effect_attempt"), 0, "no attempt without call")
    H.assert_nil(state.files["src/main.lua"], "no file without execution")
end)

suite:check("E2 provider denial is typed and preserves actual cost", function()
    local _, _, _, effects = modules()
    local instance, action, registry = setup({
        create_override = function()
            return nil, fixture.provider_error("permission_denied", "open_temp", {
                tool_calls = 1, file_writes = 0, time_ms = 3,
            })
        end,
    })
    local outcome, err = effects.execute(instance, action, registry)
    H.assert_nil(outcome, "provider denial has no success outcome")
    H.assert_true(contract.is_effect_failure(err), "denial maps to typed effect failure")
    H.assert_eq(err.code, "permission_denied", "provider code preserved")
    H.assert_eq(err.cost.tool_calls, 1, "actual tool cost preserved")
    H.assert_eq(err.cost.file_writes or 0, 0, "no mutation primitive means no write cost")
    H.assert_eq(#events(instance, "repository_effect_attempt"), 1, "attempt remains visible")
    H.assert_eq(#events(instance, "repository_effect_receipt"), 0, "denial creates no receipt")
end)

suite:check("E3 writer success plus missing read-back is rejected evidence", function()
    local _, _, _, effects = modules()
    local instance, action, registry = setup({
        read_override = function(_, _, state)
            state.files["src/main.lua"] = nil
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
    })
    local outcome = assert(effects.execute(instance, action, registry))
    H.assert_eq(outcome.status, "rejected", "missing target rejects verification")
    H.assert_eq(outcome.reason, "target_missing", "rejection reason is exact")
    H.assert_eq(#events(instance, "repository_effect_receipt"), 1,
        "writer receipt remains distinct")
    H.assert_eq(events(instance, "repository_verification")[1].payload.verdict,
        "rejected", "rejected observation is stored")
end)

suite:check("E4 malformed writer result is loud, never honest death", function()
    local _, _, _, effects = modules()
    local instance, action, registry = setup({
        create_override = function(_, request, state)
            state.files[request.relative_path] = request.content
            return {
                protocol_version = "repository.provider_result.v0",
                operation = "create_text_file",
                outcome = "created",
                bytes = #request.content,
                content_sha256 = "forged-provider-digest",
                root = H.copy(state.root_identity),
                mutation_primitive_entered = true,
                published = true,
                cost = {tool_calls = 1, file_writes = 1, time_ms = 0},
            }
        end,
    })
    local outcome, err = effects.execute(instance, action, registry)
    H.assert_nil(outcome, "malformed writer result has no outcome")
    H.assert_false(contract.is_effect_failure(err), "trusted corruption is not world failure")
    H.assert_contains(err, "unknown", "unknown provider key is loud")
    H.assert_eq(instance.status, "running", "direct body boundary does not invent death")
    H.assert_eq(#events(instance, "repository_effect_receipt"), 0,
        "malformed report is not stored as receipt")
end)

suite:check("E5 malformed verifier result is loud", function()
    local _, _, _, effects = modules()
    local instance, action, registry = setup({
        read_override = function(_, request, state)
            return {
                protocol_version = "repository.provider_result.v0",
                operation = "read_text_file",
                outcome = "observed",
                target_kind = "regular_file",
                bytes = #state.files[request.relative_path],
                content = state.files[request.relative_path],
                action_id = "action:wrong",
                root = H.copy(state.root_identity),
                mutation_primitive_entered = false,
                published = false,
                cost = {tool_calls = 1, file_writes = 0, time_ms = 0},
            }
        end,
    })
    local outcome, err = effects.execute(instance, action, registry)
    H.assert_nil(outcome, "malformed verifier has no outcome")
    H.assert_false(contract.is_effect_failure(err), "malformed verifier is invariant")
    H.assert_contains(err, "unknown", "verifier schema error is explicit")
    H.assert_eq(instance.status, "running", "no grave-worthy death fabricated")
end)

suite:check("G7/E14 revocation after action prevents provider call at zero cost", function()
    local cap, _, _, effects = modules()
    local instance, action, registry, projection, _, state = setup()
    assert(cap.revoke(registry, projection.grant_id))
    local outcome, err = effects.execute(instance, action, registry)
    H.assert_nil(outcome, "revoked action cannot execute")
    H.assert_true(contract.is_effect_failure(err), "post-route revocation is typed")
    H.assert_eq(err.code, "grant_revoked", "revocation code")
    H.assert_eq(err.cost.tool_calls or 0, 0, "no provider call charged")
    H.assert_eq(err.cost.file_writes or 0, 0, "no file write charged")
    H.assert_eq(state.calls.create, 0, "writer not entered")
end)

suite:check("E12 returned effect data cannot mutate stored trace", function()
    local _, _, _, effects = modules()
    local instance, action, registry = setup()
    local outcome = assert(effects.execute(instance, action, registry))
    local verification = events(instance, "repository_verification")[1]
    local original = verification.payload.observed.sha256
    outcome.verification.observed.sha256 = "caller-forged"
    H.assert_eq(events(instance, "repository_verification")[1].payload.observed.sha256,
        original, "trace owns verification independently")
end)

suite:check("E13 exact hand reports cost but creates no identity loss", function()
    local _, _, _, effects = modules()
    local instance, action, registry = setup()
    local loss_before = instance.tension.loss_remaining
    local outcome = assert(effects.execute(instance, action, registry))
    H.assert_eq(outcome.cost.tool_calls, 2, "writer plus reader cost")
    H.assert_eq(outcome.cost.file_writes, 1, "one mutation primitive")
    H.assert_eq(instance.tension.loss_remaining, loss_before, "hand does not spend identity")
end)

suite:check("P17 provider request cannot express command or root", function()
    local _, _, _, effects = modules()
    local instance, action, registry = setup({
        create_override = function(_, request, state)
            H.assert_nil(request.command, "request has no command")
            H.assert_nil(request.shell, "request has no shell")
            H.assert_nil(request.project_base, "request has no host base")
            H.assert_nil(request.root_path, "request has no host root")
            state.files[request.relative_path] = request.content
            return {
                protocol_version = "repository.provider_result.v0",
                operation = "create_text_file",
                outcome = "created",
                bytes = #request.content,
                root = H.copy(state.root_identity),
                mutation_primitive_entered = true,
                published = true,
                cost = {tool_calls = 1, file_writes = 1, time_ms = 0},
            }
        end,
    })
    assert(effects.execute(instance, action, registry))
end)

suite:check("TH-A10 one exact action cannot acquire a second effect lease", function()
    local _, _, _, effects = modules()
    local instance, action, registry, _, _, state = setup()
    assert(effects.execute(instance, action, registry))
    local second, err = effects.execute(instance, action, registry)
    H.assert_nil(second, "replayed action has no second effect")
    H.assert_true(contract.is_effect_failure(err), "replay denial is typed")
    H.assert_eq(state.calls.create, 1, "writer called exactly once")
    H.assert_eq(state.calls.read, 1, "read-back called exactly once")
end)

suite:check("TH-E02/E03 read-back is exact, bounded and action-owned", function()
    local _, _, _, effects = modules()
    local instance, action, registry = setup({
        read_override = function(_, request, state)
            H.assert_eq(request.relative_path, "src/main.lua", "same exact target")
            H.assert_eq(request.max_bytes, #state.files[request.relative_path] + 1,
                "read-back uses expected+1 bound")
            H.assert_nil(request.content, "read request carries no writer bytes")
            return {
                protocol_version = "repository.provider_result.v0",
                operation = "read_text_file",
                outcome = "observed",
                target_kind = "regular_file",
                bytes = #state.files[request.relative_path],
                content = state.files[request.relative_path],
                root = H.copy(state.root_identity),
                mutation_primitive_entered = false,
                published = false,
                cost = {tool_calls = 1, file_writes = 0, time_ms = 0},
            }
        end,
    })
    assert(effects.execute(instance, action, registry))
end)

suite:check("B5/TH-M07 ambiguous temp residue quarantines the grant", function()
    local _, _, _, effects = modules()
    local instance, action, registry, _, _, state = setup({
        create_override = function()
            local err = fixture.provider_error("temp_cleanup_failed", "cleanup_unlink", {
                tool_calls = 1,
                file_writes = 1,
                time_ms = 1,
            }, "ambiguous")
            err.published = "unknown"
            return nil, err
        end,
    })
    local outcome, err = effects.execute(instance, action, registry)
    H.assert_nil(outcome, "ambiguous cleanup has no result")
    H.assert_true(contract.is_effect_failure(err), "ambiguity is typed")
    H.assert_eq(state.calls.create, 1, "one mutation attempt")
    local retried = effects.execute(instance, action, registry)
    H.assert_nil(retried, "quarantined grant cannot retry")
    H.assert_eq(state.calls.create, 1, "quarantine prevents second writer call")
end)

suite:check("B6/TH-E07-E08 public repository events leak no raw observation", function()
    local _, _, _, effects = modules()
    local instance, action, registry = setup({
        read_override = function(_, request, state)
            local secret = "readback-only-secret-bytes"
            return {
                protocol_version = "repository.provider_result.v0",
                operation = "read_text_file",
                outcome = "observed",
                target_kind = "regular_file",
                bytes = #secret,
                content = secret,
                root = H.copy(state.root_identity),
                mutation_primitive_entered = false,
                published = false,
                cost = {tool_calls = 1, file_writes = 0, time_ms = 0},
            }
        end,
    })
    local outcome = assert(effects.execute(instance, action, registry))
    H.assert_eq(outcome.status, "rejected", "mismatched read-back is rejected")
    for _, event_type in ipairs({
        "repository_effect_attempt",
        "repository_effect_receipt",
        "repository_verification",
    }) do
        for _, event in ipairs(events(instance, event_type)) do
            H.assert_false(contains_key(event.payload, "host_path"),
                "absolute host path absent")
            H.assert_false(contains_key(event.payload, "content"),
                "raw content field absent")
            H.assert_false(contains_scalar(event.payload, "readback-only-secret-bytes"),
                "raw observed bytes absent")
        end
    end
end)

suite:finish()
print("test_repository_effect ok")
