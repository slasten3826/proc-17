package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local fixture = require("tests.support.repository_hands")
local contract = require("substrates.contract")
local packet_core = require("core.packet")
local body = require("runtime.body")
local logic = require("organs.logic")
local capabilities = require("runtime.repository_capability")
local intents = require("runtime.repository_intent")
local actions = require("runtime.repository_action")
local effects = require("runtime.repository_effect")
local completions = require("runtime.work_completion")
local suite = H.new("repository-hostile-audit")

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
        if contains_scalar(key, target, seen)
            or contains_scalar(child, target, seen) then
            return true
        end
    end
    return false
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

local function grow(options)
    options = options or {}
    local path = options.path or "src/hostile.lua"
    local content = options.content or "return 'bounded'\n"
    local instance = fixture.packet({{
        path = path,
        content = content,
    }}, {
        label = options.label,
    })
    local intent = assert(intents.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    }))
    local registry, projection, provider, state = fixture.new_registry(capabilities, {
        provider_options = options.provider_options,
        grant = options.grant,
    })
    local action = assert(actions.authorize(instance, intent, registry, {
        session_id = instance.session_id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        repository_id = "repo-a",
        work_mode = "build",
    }))
    fixture.move_to(instance, "☶")
    local request = assert(actions.materialize(instance, action, registry))
    return {
        instance = instance,
        action = action,
        request = request,
        registry = registry,
        projection = projection,
        provider = provider,
        state = state,
    }
end

local function authorize_with_registry(registry, path, label)
    local instance = fixture.packet({{
        path = path,
        content = "return " .. string.format("%q", path) .. "\n",
    }}, {label = label})
    local intent = assert(intents.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    }))
    local action = assert(actions.authorize(instance, intent, registry, {
        session_id = instance.session_id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        repository_id = "repo-a",
        work_mode = "build",
    }))
    fixture.move_to(instance, "☶")
    return instance, action
end

local function complete_one()
    local grown = grow({label = "hostile-completion"})
    local _, validation = assert(logic.run(grown.instance, {
        work_mode = "build",
        repository_effect = {action = grown.action},
    }, {repository_capabilities = grown.registry}))
    H.assert_eq(validation.status, "accepted", "fixture chain must be accepted")
    fixture.move_to(grown.instance, "☱")
    local candidate = assert(completions.derive(grown.instance, {
        action = grown.action,
        attempt_ref = validation.attempt_ref,
        receipt_ref = validation.receipt_ref,
        verification_ref = validation.verification_ref,
        validation_ref = validation.trace_event_id,
    }))
    assert(completions.record(grown.instance, candidate))
    grown.validation = validation
    grown.candidate = candidate
    return grown
end

suite:check("H-A01 lease cannot cross capability registries", function()
    local left = grow({label = "hostile-cross-registry-left"})
    local right_registry, _, _, right_state = fixture.new_registry(capabilities)
    local lease = assert(capabilities.begin_effect(
        left.registry, left.action, left.instance))

    local result, err = capabilities.effect_create(
        right_registry, lease, left.request)
    H.assert_nil(result, "foreign registry cannot use lease")
    H.assert_contains(err, "invalid", "cross-registry denial is loud")
    H.assert_eq(right_state.calls.create, 0, "foreign provider is untouched")

    assert(capabilities.effect_create(left.registry, lease, left.request))
    H.assert_eq(left.state.calls.create, 1,
        "foreign denial does not consume the owner's exact call")
end)

suite:check("H-A02 create and read leases are one-use", function()
    local grown = grow({label = "hostile-lease-replay"})
    local lease = assert(capabilities.begin_effect(
        grown.registry, grown.action, grown.instance))
    assert(capabilities.effect_create(grown.registry, lease, grown.request))
    local repeated_create, create_err = capabilities.effect_create(
        grown.registry, lease, grown.request)
    H.assert_nil(repeated_create, "create lease cannot replay")
    H.assert_contains(create_err, "consumed", "create replay is explicit")
    H.assert_eq(grown.state.calls.create, 1, "writer called once")

    assert(capabilities.effect_read_back(grown.registry, lease))
    local repeated_read, read_err = capabilities.effect_read_back(
        grown.registry, lease)
    H.assert_nil(repeated_read, "read lease cannot replay")
    H.assert_contains(read_err, "consumed", "read replay is explicit")
    H.assert_eq(grown.state.calls.read, 1, "reader called once")
end)

suite:check("H-A03 mutated action cannot consume a dispatch slot", function()
    local grown = grow({label = "hostile-forged-action"})
    local forged = H.copy(grown.action)
    forged.target.relative_path = "src/forged.lua"
    local lease = capabilities.begin_effect(
        grown.registry, forged, grown.instance)
    H.assert_nil(lease, "action projection mutation is denied")

    local exact = assert(capabilities.begin_effect(
        grown.registry, grown.action, grown.instance))
    H.assert_true(type(exact) == "table", "denial did not spend valid authority")
end)

suite:check("H-A03 exact request rejects unknown authority fields", function()
    local grown = grow({label = "hostile-forged-request"})
    local lease = assert(capabilities.begin_effect(
        grown.registry, grown.action, grown.instance))
    local forged = H.copy(grown.request)
    forged.command = "touch outside"
    local result = capabilities.effect_create(grown.registry, lease, forged)
    H.assert_nil(result, "unknown request field is rejected")
    H.assert_eq(grown.state.calls.create, 0, "forged request reaches no provider")

    assert(capabilities.effect_create(grown.registry, lease, grown.request))
    H.assert_eq(grown.state.calls.create, 1,
        "schema denial does not consume exact create lease")
end)

suite:check("H-A04 generation effect limit blocks a second action", function()
    local provider, state = fixture.fake_provider()
    local registry = assert(capabilities.new({
        session_id = "session-repository-hands",
        providers = {[provider.provider_id] = provider},
    }))
    assert(capabilities.mint(registry, fixture.grant_input({
        bounds = {
            max_relative_path_bytes = 128,
            max_content_bytes = 4096,
            max_effects_per_generation = 1,
        },
    })))
    local first_instance, first_action = authorize_with_registry(
        registry, "src/first.lua", "hostile-limit-first")
    local second_instance, second_action = authorize_with_registry(
        registry, "src/second.lua", "hostile-limit-second")

    assert(effects.execute(first_instance, first_action, registry))
    local outcome, err = effects.execute(second_instance, second_action, registry)
    H.assert_nil(outcome, "exhausted generation has no second effect")
    H.assert_true(contract.is_effect_failure(err), "exhaustion is typed")
    H.assert_eq(err.code, "effect_limit_exhausted", "exact limit reason")
    H.assert_eq(state.calls.create, 1, "provider sees one generation effect")
end)

suite:check("H-A05 revoked grant invalidates an already issued lease", function()
    local grown = grow({label = "hostile-revoke-after-lease"})
    local lease = assert(capabilities.begin_effect(
        grown.registry, grown.action, grown.instance))
    local revoked = assert(capabilities.revoke(
        grown.registry, grown.projection.grant_id))
    local forged_current = H.copy(grown.request)
    forged_current.grant_revision = revoked.revision
    local result = capabilities.effect_create(
        grown.registry, lease, forged_current)
    H.assert_nil(result, "revoked grant cannot spend an older lease")
    H.assert_eq(grown.state.calls.create, 0, "revocation precedes provider call")
end)

suite:check("H-A05 quarantined grant invalidates an already issued lease", function()
    local grown = grow({label = "hostile-quarantine-after-lease"})
    local lease = assert(capabilities.begin_effect(
        grown.registry, grown.action, grown.instance))
    local quarantined = assert(capabilities.quarantine_effect(
        grown.registry, lease, {code = "hostile_audit_quarantine"}))
    local forged_current = H.copy(grown.request)
    forged_current.grant_revision = quarantined.revision
    local result = capabilities.effect_create(
        grown.registry, lease, forged_current)
    H.assert_nil(result, "quarantined grant cannot spend an older lease")
    H.assert_eq(grown.state.calls.create, 0, "quarantine precedes provider call")
end)

suite:check("H-P01 provider exception remains a loud harness failure", function()
    local grown = grow({
        label = "hostile-provider-panic",
        provider_options = {
            create_override = function()
                error("hostile-provider-panic", 0)
            end,
        },
    })
    local outcome, err = effects.execute(grown.instance, grown.action, grown.registry)
    H.assert_nil(outcome, "provider exception has no effect result")
    H.assert_false(contract.is_effect_failure(err),
        "trusted exception is not honest world failure")
    H.assert_contains(err, "invariant failure", "exception stays loud")
    H.assert_eq(grown.instance.status, "running", "Packet is not honestly killed")
end)

suite:check("H-P02 cyclic provider residue is rejected loudly", function()
    local grown = grow({
        label = "hostile-cyclic-residue",
        provider_options = {
            create_override = function()
                local err = fixture.provider_error(
                    "temp_cleanup_failed",
                    "cleanup_unlink",
                    {tool_calls = 1, file_writes = 1, time_ms = 1},
                    "ambiguous"
                )
                local residue = {
                    protocol_version = "repository.provider_residue.v0",
                    kind = "reserved_temp",
                    relative_name = ".proc17-tmp-" .. string.rep("a", 32),
                }
                residue.loop = residue
                err.residue = residue
                return nil, err
            end,
        },
    })
    local outcome, err = effects.execute(grown.instance, grown.action, grown.registry)
    H.assert_nil(outcome, "malformed residue has no result")
    H.assert_false(contract.is_effect_failure(err),
        "cyclic trusted record is not a world event")
    H.assert_contains(err, "residue", "nested contract failure is explicit")
    H.assert_eq(grown.instance.status, "running", "malformed record creates no death")
end)

suite:check("H-P03 impossible provider economics are rejected loudly", function()
    local grown = grow({
        label = "hostile-nan-economics",
        provider_options = {
            create_override = function()
                local err = fixture.provider_error(
                    "permission_denied",
                    "open_temp",
                    {tool_calls = 1, file_writes = 0, time_ms = 0 / 0}
                )
                return nil, err
            end,
        },
    })
    local outcome, err = effects.execute(grown.instance, grown.action, grown.registry)
    H.assert_nil(outcome, "impossible cost has no result")
    H.assert_false(contract.is_effect_failure(err), "NaN cost is not certified")
    H.assert_contains(err, "economics", "cost corruption is explicit")
end)

suite:check("H-P04 foreign read root is a loud identity contradiction", function()
    local grown = grow({
        label = "hostile-root-substitution",
        provider_options = {
            read_override = function(_, request, state)
                local content = assert(state.files[request.relative_path])
                return {
                    protocol_version = "repository.provider_result.v0",
                    operation = "read_text_file",
                    outcome = "observed",
                    target_kind = "regular_file",
                    bytes = #content,
                    content = content,
                    root = {device = state.root_identity.device, inode = 999999},
                    mutation_primitive_entered = false,
                    published = false,
                    cost = {tool_calls = 1, file_writes = 0, time_ms = 0},
                }
            end,
        },
    })
    local outcome, err = effects.execute(grown.instance, grown.action, grown.registry)
    H.assert_nil(outcome, "foreign root has no verification")
    H.assert_false(contract.is_effect_failure(err),
        "trusted root contradiction is not world failure")
    H.assert_contains(err, "root identity", "identity mismatch is explicit")
    H.assert_eq(#events(grown.instance, "repository_verification"), 0,
        "foreign observation is not stored")
end)

suite:check("H-P05 safe temporary residue is bounded and detached", function()
    local returned_error
    local residue_name = ".proc17-tmp-" .. string.rep("b", 32)
    local grown = grow({
        label = "hostile-safe-residue",
        provider_options = {
            create_override = function()
                returned_error = fixture.provider_error(
                    "temp_cleanup_failed",
                    "cleanup_unlink",
                    {tool_calls = 1, file_writes = 1, time_ms = 1},
                    "ambiguous"
                )
                returned_error.residue = {
                    protocol_version = "repository.provider_residue.v0",
                    kind = "reserved_temp",
                    relative_name = residue_name,
                }
                return nil, returned_error
            end,
        },
    })
    local outcome, err = effects.execute(grown.instance, grown.action, grown.registry)
    H.assert_nil(outcome, "ambiguous residue has no success")
    H.assert_true(contract.is_effect_failure(err), "safe ambiguity is typed")
    H.assert_eq(err.detail.residue.relative_name, residue_name,
        "only exact relative residue is projected")
    H.assert_false(contains_scalar(err, "/trusted/proc17-test-projects"),
        "failure contains no host root")
    returned_error.residue.relative_name = "caller-mutated"
    H.assert_eq(err.detail.residue.relative_name, residue_name,
        "public failure does not alias provider record")
end)

suite:check("H-T03 repository event schemas reject metatables and cycles", function()
    local grown = grow({label = "hostile-event-schema"})
    assert(effects.execute(grown.instance, grown.action, grown.registry))
    local attempt_payload = H.copy(events(
        grown.instance, "repository_effect_attempt")[1].payload)
    local trace_before = #grown.instance.trace

    setmetatable(attempt_payload, {__index = {forged = true}})
    local record = body.record_repository_effect_attempt(
        grown.instance, attempt_payload)
    H.assert_nil(record, "metatable payload is rejected")
    H.assert_eq(#grown.instance.trace, trace_before, "metatable leaves no trace")

    setmetatable(attempt_payload, nil)
    attempt_payload.source_refs = {}
    attempt_payload.source_refs[1] = attempt_payload.source_refs
    record = body.record_repository_effect_attempt(grown.instance, attempt_payload)
    H.assert_nil(record, "cyclic refs are rejected")
    H.assert_eq(#grown.instance.trace, trace_before, "cycle leaves no trace")
end)

suite:check("H-C03 generic trace writer cannot forge review or completion", function()
    local grown = grow({label = "hostile-forged-completion"})
    fixture.move_to(grown.instance, "☱")
    local event = packet_core.append_event(grown.instance, {
        type = "work_completion",
        operator = "☱",
        truth_status = "runtime_confirmed",
        payload = {
            protocol_version = completions.protocol_version,
            work_unit_id = grown.action.work_unit.id,
            work_unit_version = grown.action.work_unit.version,
            completed_status = "done",
        },
        cost = {},
    })
    H.assert_nil(event, "generic writer cannot mint completion authority")
    local review = packet_core.append_event(grown.instance, {
        type = "repository_action_review",
        operator = "☱",
        truth_status = "runtime_confirmed",
        payload = {verdict = "actionable"},
        cost = {},
    })
    H.assert_nil(review, "generic writer cannot mint action review authority")
    H.assert_false(completions.is_complete(grown.instance,
        grown.action.work_unit.id, grown.action.work_unit.version),
        "forged payload does not complete work")
end)

suite:check("H-C03 later conflicting attempt invalidates old completion", function()
    local grown = complete_one()
    H.assert_true(completions.is_complete(grown.instance,
        grown.action.work_unit.id, grown.action.work_unit.version),
        "grown completion starts exact")
    fixture.move_to(grown.instance, "☶")
    local replay = effects.execute(grown.instance, grown.action, grown.registry)
    H.assert_nil(replay, "one-use action cannot execute again")
    H.assert_false(completions.is_complete(grown.instance,
        grown.action.work_unit.id, grown.action.work_unit.version),
        "reader notices later conflicting attempt")
end)

suite:check("H-C04 changed work version makes old completion inert", function()
    local grown = complete_one()
    local old_version = grown.action.work_unit.version
    grown.instance.field.units[grown.action.work_unit.id].version = old_version + 1
    H.assert_false(completions.is_complete(grown.instance,
        grown.action.work_unit.id, old_version),
        "old completion cannot survive a current version change")
    local progress = body.progress(grown.instance)
    H.assert_eq(progress.done_count, 0, "changed predicate is pending")
    H.assert_eq(progress.remaining_count, 1, "current work remains visible")
end)

suite:finish()
print("test_repository_hostile_audit ok")
