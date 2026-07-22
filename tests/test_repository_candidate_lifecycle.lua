package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local fixture = require("tests.support.repository_hands")
local capabilities = require("runtime.repository_capability")
local repository_action = require("runtime.repository_action")
local repository_effect = require("runtime.repository_effect")
local repository_intent = require("runtime.repository_intent")
local suite = H.new("repository-candidate-lifecycle")

local function code(value)
    return type(value) == "table" and value.code or tostring(value)
end

local function context(instance, generation)
    return {
        session_id = instance.session_id,
        lineage_id = instance.lineage_id,
        generation = generation or instance.generation,
        repository_id = instance.repository_id,
        operation = "create_text_file",
    }
end

local function action_for(instance, registry)
    local intent = assert(repository_intent.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    }))
    return assert(repository_action.authorize(instance, intent, registry, {
        session_id = instance.session_id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        repository_id = instance.repository_id,
        work_mode = "build",
    }))
end

local function packet(label, generation, path)
    return fixture.packet({{
        path = path or "src/main.lua",
        content = "return '" .. label .. "'\n",
    }}, {
        label = label,
        session_id = "session-repository-hands",
        lineage_id = "lineage-repository-hands",
        repository_id = "repo-a",
        packet_options = {generation = generation or 1},
    })
end

suite:check("LC01 mint creates one detached unclaimed root", function()
    local registry, grant = fixture.new_registry(capabilities)
    local root = assert(capabilities.root_authority(registry, {
        grant_id = grant.grant_id,
    }))
    H.assert_eq(root.state, "unclaimed", "mint does not select a generation")
    H.assert_nil(root.lifecycle_id, "unclaimed root has no lifecycle")
    H.assert_eq(root.active_grant_count, 1, "one exact grant is attached")
    root.state = "sealed"
    local again = assert(capabilities.root_authority(registry, {
        grant_id = grant.grant_id,
    }))
    H.assert_eq(again.state, "unclaimed", "projection cannot mutate root")
end)

suite:check("LC02 first begin_effect atomically claims root", function()
    local instance = packet("lifecycle-first", 1)
    local registry, grant = fixture.new_registry(capabilities)
    local action = action_for(instance, registry)
    assert(capabilities.begin_effect(registry, action, instance))
    local lifecycle = assert(capabilities.candidate_lifecycle(registry, {
        grant_id = grant.grant_id,
    }))
    H.assert_eq(lifecycle.state, "materializing", "first authority creates life")
    H.assert_eq(lifecycle.generation, 1, "claim owns exact generation")
    H.assert_true(type(lifecycle.lifecycle_id) == "string", "lifecycle is named")
end)

suite:check("LC03 owning generation may continue with a fresh action", function()
    local first = packet("lifecycle-owner-a", 1, "src/a.lua")
    local second = packet("lifecycle-owner-b", 1, "src/b.lua")
    local registry = fixture.new_registry(capabilities)
    assert(capabilities.begin_effect(registry, action_for(first, registry), first))
    local next_action = action_for(second, registry)
    local lease = assert(capabilities.begin_effect(registry, next_action, second))
    H.assert_true(type(lease) == "table", "same owner receives another lease")
end)

suite:check("LC03a root claim does not rewrite action identity", function()
    local instance = packet("lifecycle-stable-action", 1)
    local registry = fixture.new_registry(capabilities)
    local before_claim = action_for(instance, registry)
    assert(capabilities.begin_effect(registry, before_claim, instance))
    local after_claim = action_for(instance, registry)
    H.assert_eq(after_claim.action_id, before_claim.action_id,
        "private lifecycle state is not part of immutable action identity")
    H.assert_eq(after_claim.root_authority_id, before_claim.root_authority_id,
        "action keeps the stable root authority identity")
end)

suite:check("LC04 descendant is denied after first claim", function()
    local instance = packet("lifecycle-descendant", 1)
    local registry = fixture.new_registry(capabilities)
    assert(capabilities.begin_effect(registry, action_for(instance, registry), instance))
    local match, err = capabilities.resolve(registry, context(instance, 2))
    H.assert_nil(match, "descendant cannot reopen ancestor root")
    H.assert_eq(code(err), "repository_root_claimed_by_other_generation",
        "denial names root owner")
end)

suite:check("LC05 failed first effect does not release claim", function()
    local instance = packet("lifecycle-failed", 1)
    local registry = fixture.new_registry(capabilities, {
        provider_options = {
            create_override = function()
                return nil, {
                    protocol_version = "repository.provider_error.v0",
                    class = "world",
                    code = "permission_denied",
                    stage = "open_temp",
                    errno = 13,
                    mutation_primitive_entered = false,
                    published = false,
                    cost = {tool_calls = 1, file_writes = 0, time_ms = 0},
                }
            end,
        },
    })
    local action = action_for(instance, registry)
    fixture.move_to(instance, "☶")
    local result = repository_effect.execute(instance, action, registry)
    H.assert_nil(result, "provider failure remains a failed effect")
    local match, err = capabilities.resolve(registry, context(instance, 2))
    H.assert_nil(match, "zero published files do not release root")
    H.assert_eq(code(err), "repository_root_claimed_by_other_generation",
        "failed first use remains history")
end)

suite:check("LC06 revoke and replacement do not erase owner", function()
    local instance = packet("lifecycle-revoke", 1)
    local registry, grant = fixture.new_registry(capabilities)
    assert(capabilities.begin_effect(registry, action_for(instance, registry), instance))
    assert(capabilities.revoke(registry, grant.grant_id))
    local replacement = assert(capabilities.mint(registry, fixture.grant_input()))
    local owner = assert(capabilities.resolve(registry, context(instance, 1)))
    H.assert_eq(owner.grant_id, replacement.grant_id,
        "replacement remains usable by exact owner")
    local descendant, err = capabilities.resolve(registry, context(instance, 2))
    H.assert_nil(descendant, "replacement does not reset generation claim")
    H.assert_eq(code(err), "repository_root_claimed_by_other_generation",
        "sticky claim survives revoke")
end)

suite:check("LC07 repository id cannot alias one trusted root", function()
    local registry = fixture.new_registry(capabilities)
    local alias, err = capabilities.mint(registry, fixture.grant_input({
        repository_id = "repo-b",
    }))
    H.assert_nil(alias, "logical id cannot manufacture a fresh root")
    H.assert_eq(code(err), "repository_root_logical_alias", "alias is typed")
end)

suite:check("LC07a lineage id cannot alias one trusted root", function()
    local registry = fixture.new_registry(capabilities)
    local alias, err = capabilities.mint(registry, fixture.grant_input({
        lineage_id = "foreign-lineage",
    }))
    H.assert_nil(alias, "foreign lineage cannot claim the same physical root")
    H.assert_eq(code(err), "repository_root_logical_alias",
        "cross-lineage alias is typed")
end)

suite:check("LC08 provider dispatch is in flight only during the call", function()
    local registry
    local grant
    local state
    local provider
    local observed_during_create
    registry, grant, provider, state = fixture.new_registry(capabilities, {
        provider_options = {
            create_override = function(_, request, provider_state)
                observed_during_create = assert(capabilities.root_authority(registry, {
                    grant_id = grant.grant_id,
                }))
                provider_state.files[request.relative_path] = request.content
                return {
                    protocol_version = "repository.provider_result.v0",
                    operation = "create_text_file",
                    outcome = "created",
                    bytes = #request.content,
                    root = fixture.copy(provider_state.root_identity),
                    mutation_primitive_entered = true,
                    published = true,
                    cost = {tool_calls = 1, file_writes = 1, time_ms = 0},
                }
            end,
        },
    })
    local instance = packet("lifecycle-in-flight", 1)
    local action = action_for(instance, registry)
    fixture.move_to(instance, "☶")
    assert(repository_effect.execute(instance, action, registry))

    H.assert_eq(observed_during_create.active_dispatch_count, 1,
        "provider entry has one exact in-flight dispatch")
    local after = assert(capabilities.root_authority(registry, {
        grant_id = grant.grant_id,
    }))
    H.assert_eq(after.active_dispatch_count, 0,
        "returned provider call leaves no in-flight authority")
    H.assert_true(type(provider) == "table", "test uses the registered provider")
    H.assert_eq(state.calls.create, 1, "one consumed create dispatch remains audit evidence")
end)

suite:check("LC09 provider panic quarantines every grant on the root", function()
    local instance = packet("lifecycle-provider-panic", 1)
    local registry, first = fixture.new_registry(capabilities, {
        provider_options = {
            create_override = function()
                error("host provider exploded")
            end,
        },
    })
    local action = action_for(instance, registry)
    local request = assert(repository_action.materialize(instance, action, registry))
    local lease = assert(capabilities.begin_effect(registry, action, instance))
    local second = assert(capabilities.mint(registry, fixture.grant_input()))

    local called, failure = pcall(
        capabilities.effect_create,
        registry,
        lease,
        request
    )
    H.assert_false(called, "trusted provider panic is loud")
    H.assert_contains(failure, "provider invariant failure", "panic is not typed world failure")
    local root = assert(capabilities.root_authority(registry, {
        grant_id = first.grant_id,
    }))
    H.assert_eq(root.state, "quarantined", "physical root is terminally quarantined")
    H.assert_eq(root.active_dispatch_count, 0, "panic leaves no ghost dispatch")
    H.assert_eq(root.active_grant_count, 0, "all root grants lose authority")
    H.assert_eq(assert(capabilities.project(registry, first.grant_id)).state,
        "quarantined", "first grant is quarantined")
    H.assert_eq(assert(capabilities.project(registry, second.grant_id)).state,
        "quarantined", "sibling grant is quarantined")
end)

suite:check("LC10 malformed trusted result quarantines the physical root", function()
    local instance = packet("lifecycle-malformed-provider", 1)
    local registry, grant = fixture.new_registry(capabilities, {
        provider_options = {
            create_override = function(_, request, provider_state)
                provider_state.files[request.relative_path] = request.content
                return {
                    protocol_version = "repository.provider_result.v0",
                    operation = "create_text_file",
                    outcome = "created",
                    bytes = #request.content,
                    forged = true,
                    root = fixture.copy(provider_state.root_identity),
                    mutation_primitive_entered = true,
                    published = true,
                    cost = {tool_calls = 1, file_writes = 1, time_ms = 0},
                }
            end,
        },
    })
    local action = action_for(instance, registry)
    fixture.move_to(instance, "☶")
    local result, err = repository_effect.execute(instance, action, registry)
    H.assert_nil(result, "malformed trusted report cannot become evidence")
    H.assert_contains(err, "unknown", "schema corruption remains loud")
    H.assert_eq(instance.status, "running", "harness failure is not Packet mortality")
    local root = assert(capabilities.root_authority(registry, {
        grant_id = grant.grant_id,
    }))
    H.assert_eq(root.state, "quarantined", "malformed trusted report closes root")
    H.assert_eq(root.active_grant_count, 0, "no grant survives trusted corruption")
end)

suite:finish()
print("test_repository_candidate_lifecycle ok")
