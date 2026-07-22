package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local json = require("core.json")
local completion_scope = require("runtime.completion_scope")
local fixture = require("tests.support.repository_hands")
local logic = require("organs.logic")
local capabilities = require("runtime.repository_capability")
local candidate_seal = require("runtime.candidate_seal")
local repository_action = require("runtime.repository_action")
local repository_intent = require("runtime.repository_intent")
local work_completion = require("runtime.work_completion")
local work_layer = require("runtime.work_layer")
local suite = H.new("candidate-seal")

local function grown_candidate(label, options)
    options = options or {}
    local instance = fixture.packet(options.items or {{
        path = "src/main.lua",
        content = "return 'sealed'\n",
    }}, {label = label})
    local intent = assert(repository_intent.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    }))
    local registry, grant, provider, state = fixture.new_registry(capabilities, {
        provider_options = options.provider_options,
    })
    local action = assert(repository_action.authorize(instance, intent, registry, {
        session_id = instance.session_id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        repository_id = instance.repository_id,
        work_mode = "build",
    }))
    fixture.move_to(instance, "☶")
    local _, validation = assert(logic.run(instance, {
        work_mode = "build",
        repository_effect = {action = action},
    }, {repository_capabilities = registry}))
    fixture.move_to(instance, "☱")
    local completion = assert(work_completion.derive(instance, {
        action = action,
        attempt_ref = validation.attempt_ref,
        receipt_ref = validation.receipt_ref,
        verification_ref = validation.verification_ref,
        validation_ref = validation.trace_event_id,
    }))
    assert(work_completion.record(instance, completion))
    return {
        instance = instance,
        registry = registry,
        grant = grant,
        provider = provider,
        state = state,
        action = action,
        services = {repository_capabilities = registry},
    }
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

suite:check("PRE prepare is pure and body-derived", function()
    local grown = grown_candidate("candidate-seal-prepare")
    local trace_before = #grown.instance.trace
    local root_before = assert(capabilities.root_authority(grown.registry, {
        grant_id = grown.grant.grant_id,
    }))
    local request = assert(candidate_seal.prepare(
        grown.instance, grown.services))
    H.assert_eq(request.packet_id, grown.instance.id, "request binds Packet")
    H.assert_eq(request.artifact_set_id:sub(1, 13), "artifact-set:",
        "request binds derived artifact set")
    H.assert_eq(request.expected_files[1].relative_path, "src/main.lua",
        "body evidence names exact file")
    H.assert_eq(request.expected_directories[1], "src",
        "required directory is explicit")
    H.assert_eq(#grown.instance.trace, trace_before, "prepare appends no trace")
    local root_after = assert(capabilities.root_authority(grown.registry, {
        grant_id = grown.grant.grant_id,
    }))
    H.assert_eq(root_after.state, root_before.state, "prepare changes no authority")
    H.assert_eq(root_after.revision, root_before.revision, "prepare changes no revision")
end)

suite:check("ST11/ST22/ST23/ST28 exact tree closes authority once", function()
    local grown = grown_candidate("candidate-seal-exact")
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    fixture.move_to(grown.instance, "☶")
    local result = assert(candidate_seal.execute(
        grown.instance, request, grown.services))
    H.assert_eq(result.status, "sealed", "exact tree seals")
    H.assert_false(result.idempotent, "first closure is not replay")
    H.assert_eq(#events(grown.instance, "candidate_seal"), 1, "one body seal event")
    H.assert_eq(result.seal.request_id, request.request_id, "event binds request")
    H.assert_eq(result.inventory.entries[1].kind, "directory",
        "normalized inventory retains directory")
    H.assert_nil(result.inventory.entries[2].content, "normalized inventory drops bytes")
    local seal_event = events(grown.instance, "candidate_seal")[1]
    H.assert_false(json.encode(seal_event):find("return 'sealed'", 1, true) ~= nil,
        "candidate body event contains hashes, never inventory bytes")
    local root = assert(capabilities.root_authority(grown.registry, {
        root_authority_id = request.root_authority_id,
    }))
    H.assert_eq(root.state, "sealed", "private root is terminally sealed")
    H.assert_eq(root.active_grant_count, 0, "source-write grant is closed")
    local scope = assert(completion_scope.inspect_packet(grown.instance))
    H.assert_eq(scope.highest_scope, "candidate_sealed",
        "named scope reader observes the body seal")
    local layer = assert(work_layer.inspect_packet(grown.instance))
    H.assert_eq(layer.glyph, "⊞", "sealed build is checking")
    H.assert_eq(layer.reason, "candidate_sealed_qa_missing",
        "QA absence remains explicit")

    result.seal.artifacts[1].sha256 = string.rep("0", 64)
    result.closure.inventory_digest = string.rep("0", 64)
    local stored = assert(candidate_seal.current(grown.instance))
    H.assert_true(stored.artifacts[1].sha256 ~= string.rep("0", 64),
        "returned seal cannot mutate body event")
    local closure = assert(capabilities.observe_candidate_closure(grown.registry, {
        root_authority_id = request.root_authority_id,
        lifecycle_id = request.lifecycle_id,
        request_id = request.request_id,
    }))
    H.assert_true(closure.inventory_digest ~= string.rep("0", 64),
        "returned closure cannot mutate private registry")
end)

suite:check("ST24 exact repeat performs no provider work", function()
    local grown = grown_candidate("candidate-seal-repeat")
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    fixture.move_to(grown.instance, "☶")
    assert(candidate_seal.execute(grown.instance, request, grown.services))
    local calls_before = grown.state.calls.inventory
    local repeated = assert(candidate_seal.execute(
        grown.instance, request, grown.services))
    H.assert_true(repeated.idempotent, "three exact surfaces replay")
    H.assert_eq(grown.state.calls.inventory, calls_before,
        "idempotence performs no second inventory")
    H.assert_eq(#events(grown.instance, "candidate_seal"), 1,
        "idempotence appends no second event")
end)

suite:check("REG detached defaults cannot rewrite sealed evidence", function()
    local grown = grown_candidate("candidate-seal-stable-bounds")
    local request = assert(candidate_seal.prepare(grown.instance, grown.services, {
        inventory_bounds = {
            protocol_version = "repository.inventory_bounds.v0",
            max_entries = 512,
            max_depth = 64,
            max_path_bytes = 1024,
            max_component_bytes = 255,
            max_file_bytes = 1048576,
            max_total_bytes = 16777216,
        },
    }))
    fixture.move_to(grown.instance, "☶")
    local result = assert(candidate_seal.execute(
        grown.instance, request, grown.services))

    local saved = H.copy(candidate_seal.default_inventory_bounds)
    candidate_seal.default_inventory_bounds.max_entries = 1
    candidate_seal.default_inventory_bounds.max_total_bytes = 1
    local stored, _, err = candidate_seal.current(grown.instance)
    candidate_seal.default_inventory_bounds = saved

    H.assert_true(stored ~= nil, tostring(err))
    H.assert_eq(stored.candidate_seal_id, result.seal.candidate_seal_id,
        "public defaults cannot retroactively invalidate a committed seal")
end)

suite:check("ST13/ST30 stable extra file aborts without false seal", function()
    local grown = grown_candidate("candidate-seal-extra", {
        provider_options = {
            files = {['extra.txt'] = "host contamination\n"},
        },
    })
    local request = assert(candidate_seal.prepare(grown.instance, grown.services))
    fixture.move_to(grown.instance, "☶")
    local result, err, loud = candidate_seal.execute(
        grown.instance, request, grown.services)
    H.assert_nil(result, "extra path cannot seal")
    H.assert_eq(err.code, "candidate_inventory_mismatch", "mismatch is typed")
    H.assert_false(loud, "stable mismatch is not harness corruption")
    local root = assert(capabilities.root_authority(grown.registry, {
        root_authority_id = request.root_authority_id,
    }))
    H.assert_eq(root.state, "materializing", "two proofs permit exact abort")
    H.assert_eq(#events(grown.instance, "candidate_seal"), 0, "no false seal")
    local scope = assert(completion_scope.inspect_packet(grown.instance))
    H.assert_eq(scope.highest_scope, "artifact_set",
        "stable mismatch cannot raise completion scope")
    H.assert_eq(scope.candidate.state, "unsealed",
        "stable mismatch cannot manufacture a seal")
end)

suite:check("ST12 native nested tree reaches the same body seal", function()
    local native_build = require("tests.support.repository_native_build")
    local roots = require("tests.support.owned_temp_root")
    assert(native_build.ensure_loader_fixtures())
    package.loaded["runtime.repository_provider"] = nil
    local provider = require("runtime.repository_provider")

    assert(roots.with_root(function(root)
        local instance = fixture.packet({{
            path = "src/native-seal.lua",
            content = "return 'native-sealed'\n",
        }}, {label = "candidate-seal-native"})
        local registry = assert(capabilities.new({
            session_id = instance.session_id,
            providers = {[provider.provider_id] = provider},
        }))
        assert(capabilities.mint(registry, fixture.grant_input({
            project_base = root.project_base,
            repository_path = "repo",
        })))
        local intent = assert(repository_intent.derive(instance, {
            max_items = instance.regime.encoding.bounds.max_output_units,
        }))
        local action = assert(repository_action.authorize(instance, intent, registry, {
            session_id = instance.session_id,
            lineage_id = instance.lineage_id,
            generation = instance.generation,
            repository_id = instance.repository_id,
            work_mode = "build",
        }))
        fixture.move_to(instance, "☶")
        local _, validation = assert(logic.run(instance, {
            work_mode = "build",
            repository_effect = {action = action},
        }, {repository_capabilities = registry}))
        fixture.move_to(instance, "☱")
        local completion = assert(work_completion.derive(instance, {
            action = action,
            attempt_ref = validation.attempt_ref,
            receipt_ref = validation.receipt_ref,
            verification_ref = validation.verification_ref,
            validation_ref = validation.trace_event_id,
        }))
        assert(work_completion.record(instance, completion))
        local services = {repository_capabilities = registry}
        local request = assert(candidate_seal.prepare(instance, services))
        fixture.move_to(instance, "☶")
        local result, err, loud = candidate_seal.execute(instance, request, services)
        H.assert_true(result ~= nil, tostring(err) .. " loud=" .. tostring(loud))
        H.assert_eq(result.status, "sealed", "native inventory seals exact tree")
        H.assert_eq(result.inventory.observed_entry_count, 2,
            "native inventory observes directory plus file")
        H.assert_eq(result.inventory.entries[2].relative_path,
            "src/native-seal.lua", "native path remains exact")
        H.assert_nil(result.inventory.entries[2].content,
            "native bytes die at adapter boundary")
        return true
    end))
end)

suite:finish()
print("test_candidate_seal ok")
