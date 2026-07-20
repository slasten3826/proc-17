package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local fixture = require("tests.support.repository_hands")
local capabilities, capabilities_err = H.optional_require("runtime.repository_capability")
local intent_module, intent_err = H.optional_require("runtime.repository_intent")
local action_module, action_err = H.optional_require("runtime.repository_action")
local pressure_action = require("runtime.pressure_action")
local digest = require("core.digest")
local suite = H.new("repository-action")

local function modules()
    return suite:require_module(capabilities, capabilities_err, "runtime.repository_capability"),
        suite:require_module(intent_module, intent_err, "runtime.repository_intent"),
        suite:require_module(action_module, action_err, "runtime.repository_action")
end

local function context(instance, overrides)
    local value = {
        session_id = instance.session_id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        repository_id = "repo-a",
        work_mode = "build",
    }
    for key, child in pairs(overrides or {}) do
        value[key] = child
    end
    return value
end

local function prepared(options)
    options = options or {}
    local cap, intents, actions = modules()
    local instance = fixture.packet({{
        path = options.path or "src/main.lua",
        content = options.content or "return true\n",
    }}, {
        session_id = options.session_id,
        lineage_id = options.lineage_id,
        packet_options = options.packet_options,
    })
    local intent = assert(intents.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    }))
    local registry, projection, provider, state = fixture.new_registry(cap, {
        session_id = options.session_id,
        grant = options.grant,
    })
    local action, diagnostic = actions.authorize(
        instance,
        intent,
        registry,
        context(instance, options.context)
    )
    return instance, intent, action, diagnostic, registry, projection, provider, state
end

suite:check("G2/A0 exact grant and intent produce canonical action", function()
    local _, _, actions = modules()
    local instance, intent, action = prepared()
    action = assert(action)
    H.assert_eq(action.protocol_version, "repository.action.v0", "action protocol")
    H.assert_eq(action.intent_id, intent.intent_id, "action binds intent")
    H.assert_eq(action.packet_id, instance.id, "action binds Packet")
    H.assert_eq(action.session_id, instance.session_id, "action binds session")
    H.assert_eq(action.lineage_id, instance.lineage_id, "action binds lineage")
    H.assert_true(actions.validate(instance, action), "canonical action validates")
    H.assert_nil(action.content.content, "route action has no raw content")
    H.assert_nil(action.capability.host_path, "route action has no host path")
    H.assert_nil(action.capability.provider, "route action has no provider")
end)

suite:check("G12 plan mode forbids action", function()
    local _, intents, actions = modules()
    local instance = fixture.packet({{
        path = "src/main.lua", content = "return true\n",
    }}, {work_mode = "plan"})
    local intent = assert(intents.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    }))
    local registry = fixture.new_registry(capabilities)
    local action, diagnostic = actions.authorize(instance, intent, registry,
        context(instance, {work_mode = "plan"}))
    H.assert_nil(action, "plan cannot materialize mutation")
    H.assert_eq(type(diagnostic) == "table" and diagnostic.code or diagnostic,
        "plan_mode_forbids_repository_effect", "plan denial is typed")
end)

suite:check("P6/P8 live grant bounds exclude oversized action", function()
    local _, _, actions = modules()
    local instance, intent, action, diagnostic = prepared({
        path = "src/long-name.lua",
        content = "123456789",
        grant = {
            bounds = {
                max_relative_path_bytes = 8,
                max_content_bytes = 8,
                max_effects_per_generation = 1,
            },
        },
    })
    H.assert_nil(action, "oversized material has no authorized action")
    H.assert_eq(type(diagnostic) == "table" and diagnostic.code or diagnostic,
        "capability_bounds_exceeded", "bound denial is typed")
    H.assert_true(#intent.relative_path > 8 and intent.content_bytes > 8,
        "intent still records exact unbounded material")
    H.assert_nil(actions.materialize(instance, {
        protocol_version = "repository.action.v0",
    }, {}), "malformed action cannot dispatch")
end)

suite:check("A3 stable exact state has stable action id", function()
    local _, _, actions = modules()
    local instance, _, action, _, registry = prepared()
    action = assert(action)
    local rebuilt = assert(actions.authorize(
        instance,
        assert(intent_module.derive(instance, {
            max_items = instance.regime.encoding.bounds.max_output_units,
        })),
        registry,
        context(instance)
    ))
    H.assert_eq(action.action_id, rebuilt.action_id, "same action identity is stable")
end)

suite:check("A0 empty text authorizes an exact zero-byte action", function()
    local _, _, actions = modules()
    local instance, _, action, diagnostic = prepared({
        path = "src/empty.lua",
        content = "",
    })
    H.assert_nil(diagnostic, "empty text has no diagnostic")
    action = assert(action)
    H.assert_eq(action.content.bytes, 0, "zero-byte action remains exact")
    H.assert_true(actions.validate(instance, action),
        "zero-byte action validates")
end)

suite:check("A6 grant revision changes action identity", function()
    local cap, intents, actions = modules()
    local instance = fixture.packet({{path = "src/main.lua", content = "x\n"}})
    local intent = assert(intents.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    }))
    local registry, projection = fixture.new_registry(cap)
    local first = assert(actions.authorize(instance, intent, registry, context(instance)))
    assert(cap.revoke(registry, projection.grant_id))
    local replacement = assert(cap.mint(registry, fixture.grant_input()))
    local second = assert(actions.authorize(instance, intent, registry, context(instance)))
    H.assert_false(first.action_id == second.action_id, "grant revision/identity changes action")
    H.assert_false(first.capability.grant_id == replacement.grant_id
        and first.capability.revision == replacement.revision,
        "replacement grant is distinct authority")
end)

suite:check("A7 Packet generation participates in action identity", function()
    local _, _, actions = modules()
    local first_instance, _, first = prepared()
    local second_instance, _, second = prepared({
        packet_options = {
            generation = 2,
            birth_kind = "recovery",
            parent_corpse_id = "corpse-parent",
            carrier_id = "carrier-child",
        },
    })
    first = assert(first)
    second = assert(second)
    H.assert_eq(first_instance.lineage_id, second_instance.lineage_id,
        "comparison stays in one lineage")
    H.assert_false(first.action_id == second.action_id, "new Packet gets new action")
end)

suite:check("A9 caller action mutation cannot alter rematerialized authority", function()
    local _, _, actions = modules()
    local instance, _, action, _, registry = prepared()
    action = assert(action)
    local caller = H.copy(action)
    caller.target.relative_path = "src/forged.lua"
    caller.content.sha256 = "forged"
    H.assert_false(actions.validate(instance, caller), "forged action rejected")
    local request = assert(actions.materialize(instance, action, registry))
    H.assert_eq(request.relative_path, "src/main.lua", "original exact path rematerializes")
    H.assert_eq(request.content, "return true\n", "content comes from field referent")
end)

suite:check("A10 stale field version blocks dispatch", function()
    local _, _, actions = modules()
    local instance, _, action, _, registry = prepared()
    action = assert(action)
    local unit = assert(instance.field.units[action.work_unit.id])
    unit.version = unit.version + 1
    local request, err = actions.materialize(instance, action, registry)
    H.assert_nil(request, "stale action cannot dispatch")
    H.assert_contains(err, "version", "stale denial names version")
end)

suite:check("A11 caller spells cannot build repository action mode", function()
    modules()
    local plan, err = pressure_action.build("repository_effect", {
        witness_id = "witness:caller-spell",
        scope_refs = {"coverage:field_unit:unit:1:1", "repository-action:missing"},
        preconditions = {
            packet_id = "packet-missing",
            generation = 1,
            object_versions = {["unit:1"] = 1},
        },
        options = {logic = {
            spells = {{kind = "check_file_exists", path = "src/main.lua"}},
        }},
        expected_effect = {discharge_reader = "repository_reconcile_need"},
    })
    H.assert_nil(plan, "spell-only caller cannot satisfy repository mode")
    H.assert_contains(err, "repository", "missing action-owned input is explicit")
end)

suite:check("A12 action and pressure scope must be identical", function()
    local _, _, actions = modules()
    local instance, _, action = prepared()
    action = assert(action)
    local forged = H.copy(action)
    forged.scope_refs = {"coverage:field_unit:other:1"}
    H.assert_false(actions.validate(instance, forged), "cross-work scope rejected")
end)

suite:check("A13 repository pressure modes carry action without executing it", function()
    modules()
    local instance, _, action, _, _, _, _, state = prepared()
    action = assert(action)
    local scope_refs = H.copy(action.scope_refs)
    scope_refs[#scope_refs + 1] = action.action_id
    local function repository_input(evidence_refs)
        return {
            action = H.copy(action),
            action_id = action.action_id,
            work_unit_id = action.work_unit.id,
            work_unit_version = action.work_unit.version,
            formation_event_ref = action.work_unit.formation_event_ref,
            grant_id = action.capability.grant_id,
            grant_revision = action.capability.revision,
            evidence_refs = evidence_refs or {},
        }
    end
    local function plan(mode, options, evidence_refs, discharge_reader)
        return assert(pressure_action.build(mode, {
            witness_id = "witness:" .. mode,
            scope_refs = scope_refs,
            provenance_refs = action.provenance_refs,
            preconditions = {
                packet_id = instance.id,
                generation = instance.generation,
                object_versions = {
                    [action.work_unit.id] = action.work_unit.version,
                },
            },
            options = options(repository_input(evidence_refs)),
            expected_effect = {discharge_reader = discharge_reader},
            content_truth_status = action.content_truth_status,
        }))
    end
    local review = plan(
        "repository_action_review",
        function(input) return {runtime = {repository_action_review = input}} end,
        {},
        "repository_effect_need"
    )
    local effect = plan(
        "repository_effect",
        function(input) return {logic = {repository_effect = input}} end,
        {"repository-review:event-1"},
        "repository_reconcile_need"
    )
    local reconcile = plan(
        "repository_reconcile",
        function(input) return {runtime = {repository_reconcile = input}} end,
        {"repository-verification:event-1", "validation:event-1"},
        "repository_work_completion"
    )
    H.assert_true(pressure_action.validate(review), "review schema validates")
    H.assert_true(pressure_action.validate(effect), "effect schema validates")
    H.assert_true(pressure_action.validate(reconcile), "reconcile schema validates")

    local host_services = {repository_capabilities = {opaque = true}}
    local context_value = assert(pressure_action.registry_context(effect, {
        instance = instance,
        host_services = host_services,
        options = {
            host_services = host_services,
            logic = {spells = {{kind = "ignored_compatibility_spell"}}},
        },
    }))
    H.assert_eq(context_value.options.logic.spells[1].kind,
        "ignored_compatibility_spell", "unrelated compatibility options survive")
    H.assert_eq(context_value.options.logic.repository_effect.action_id,
        action.action_id, "action-owned effect subtree installed")
    H.assert_true(context_value.host_services == host_services,
        "private host services preserve opaque identity")
    H.assert_nil(context_value.options.host_services,
        "private host services do not enter action-owned options")

    local forged = H.copy(action)
    forged.content.content = "raw route bytes are forbidden"
    local invalid, invalid_err = pressure_action.build("repository_effect", {
        witness_id = "witness:forged-repository-effect",
        scope_refs = scope_refs,
        preconditions = {
            packet_id = instance.id,
            generation = instance.generation,
            object_versions = {[action.work_unit.id] = action.work_unit.version},
        },
        options = {logic = {repository_effect = {
            action = forged,
            action_id = forged.action_id,
            work_unit_id = forged.work_unit.id,
            work_unit_version = forged.work_unit.version,
            formation_event_ref = forged.work_unit.formation_event_ref,
            grant_id = forged.capability.grant_id,
            grant_revision = forged.capability.revision,
            evidence_refs = {"repository-review:event-1"},
        }}},
        expected_effect = {discharge_reader = "repository_reconcile_need"},
    })
    H.assert_nil(invalid, "raw content cannot enter route action")
    H.assert_contains(invalid_err, "unknown key", "forbidden projection is explicit")
    H.assert_eq(state.calls.create, 0, "pressure schemas cannot call writer")
    H.assert_eq(state.calls.read, 0, "pressure schemas cannot call verifier")
end)

suite:check("A14 intent and authorization have no Packet mass", function()
    local cap, intents, actions = modules()
    local instance = fixture.packet({{
        path = "src/pure.lua",
        content = "return 'pure'\n",
    }})
    local before = assert(digest.record(instance))
    local intent = assert(intents.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    }))
    local registry = fixture.new_registry(cap)
    local action = assert(actions.authorize(instance, intent, registry,
        context(instance)))
    H.assert_true(type(action.action_id) == "string", "authorization returned action")
    H.assert_eq(assert(digest.record(instance)), before,
        "pure qualification does not mutate Packet")
end)

suite:finish()
print("test_repository_action ok")
