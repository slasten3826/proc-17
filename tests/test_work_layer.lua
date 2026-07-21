package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local artifact_set = require("runtime.artifact_set")
local capabilities = require("runtime.repository_capability")
local corpse = require("runtime.corpse")
local fixture = require("tests.support.repository_hands")
local logic = require("organs.logic")
local plan_life = require("tests.support.plan_life")
local repository_action = require("runtime.repository_action")
local repository_intent = require("runtime.repository_intent")
local work_completion = require("runtime.work_completion")
local work_layer, work_layer_err = H.optional_require("runtime.work_layer")
local suite = H.new("work-layer")

local function plan_at(label, ticks)
    local instance = assert(plan_life.run(
        label,
        "work_sequence",
        {"inspect", "build", "verify"},
        ticks
    ))
    return instance
end

local function completed_build(label)
    local instance = fixture.packet({{
        path = "src/main.lua",
        content = "return 'work-layer'\n",
    }}, {label = label})
    local intent = assert(repository_intent.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    }))
    local registry = fixture.new_registry(capabilities)
    local action = assert(repository_action.authorize(instance, intent, registry, {
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
    fixture.move_to(instance, "☱")
    assert(work_completion.record(instance, assert(work_completion.derive(instance, {
        action = action,
        attempt_ref = validation.attempt_ref,
        receipt_ref = validation.receipt_ref,
        verification_ref = validation.verification_ref,
        validation_ref = validation.trace_event_id,
    }))))
    return instance, action
end

local function build_contract(instance, action)
    local declared = {
        protocol_version = "repository.artifact_set_contract.v0",
        artifact_set_id = nil,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        stage_id = instance.stage_id,
        repository_id = instance.repository_id,
        artifacts = {{
            work_unit_id = action.work_unit.id,
            work_unit_version = action.work_unit.version,
            relative_path = action.target.relative_path,
            expected_kind = "regular_file",
        }},
        source_refs = {action.work_unit.formation_event_ref},
        event_truth_status = "runtime_confirmed",
        content_truth_status = "semantic_proposal",
    }
    declared.artifact_set_id = assert(artifact_set.identify(declared))
    return {
        protocol_version = "runtime.work_contract_view.v0",
        process_contract_id = instance.process_contract_id,
        context = instance.work_context,
        stage_id = instance.stage_id,
        artifact_set = declared,
    }
end

suite:check("WL01 plan formation projects four exact layers", function()
    local module = suite:require_module(work_layer, work_layer_err, "runtime.work_layer")
    local forming = assert(module.inspect_packet(plan_at("work-layer-forming", 1)))
    H.assert_eq(forming.glyph, "⋯", "missing plan structure is formation")
    H.assert_eq(forming.state, "forming", "formation state")
    H.assert_eq(forming.reason, "plan_structure_missing", "formation reason")

    local checking = assert(module.inspect_packet(plan_at("work-layer-checking", 3)))
    H.assert_eq(checking.glyph, "⊞", "exact structure awaits review")
    H.assert_eq(checking.state, "checking", "review state")
    H.assert_eq(checking.reason, "plan_structure_requires_review", "review reason")

    local crystallized = assert(module.inspect_packet(plan_at("work-layer-crystallized", 4)))
    H.assert_eq(crystallized.glyph, "◈", "accepted assessment is crystallized")
    H.assert_eq(crystallized.state, "crystallized", "crystallized state")
    H.assert_eq(crystallized.reason, "plan_export_ready", "delivery is next")

    local boundary_packet = plan_at("work-layer-boundary", 5)
    local boundary = assert(module.inspect_packet(boundary_packet))
    H.assert_eq(boundary.glyph, "▲", "exact plan manifest reaches boundary")
    H.assert_eq(boundary.state, "boundary", "boundary state")
    H.assert_eq(boundary.boundary_candidate, "plan_stage_ready", "candidate is typed")
    H.assert_true(boundary.boundary_terminalized, "manifested Packet is terminalized")

    local dead = assert(corpse.capture(boundary_packet, {
        corpse_id = "corpse-work-layer-boundary",
    }))
    local inherited = assert(module.inspect_corpse(dead))
    H.assert_eq(inherited.glyph, "▲", "corpse retains final glyph")
    H.assert_eq(inherited.boundary_terminal_ref, dead.corpse_id,
        "corpse projection names frozen boundary")
end)

suite:check("WL02 current build baseline stays honestly low", function()
    local module = suite:require_module(work_layer, work_layer_err, "runtime.work_layer")
    local instance = fixture.packet({{
        path = "src/main.lua",
        content = "return 'forming'\n",
    }}, {label = "work-layer-build-forming"})
    local projection = assert(module.inspect_packet(instance))
    H.assert_eq(projection.glyph, "⋯", "unmaterialized build is forming")
    H.assert_eq(projection.completion_scope, "none", "no completion is invented")
    H.assert_eq(projection.reason, "candidate_materialization_incomplete",
        "missing materialization is explicit")
end)

suite:check("WL02b complete declared build set asks only for seal", function()
    local module = suite:require_module(work_layer, work_layer_err, "runtime.work_layer")
    local instance, action = completed_build("work-layer-build-complete")
    local projection = assert(module.inspect_packet(instance, build_contract(instance, action)))
    H.assert_eq(projection.glyph, "⋯", "complete material remains build formation")
    H.assert_eq(projection.completion_scope, "artifact_set", "set scope is exact")
    H.assert_eq(projection.reason, "artifact_set_complete_seal_missing",
        "next missing authority is only the seal")
end)

suite:check("WL03 caller cannot inject glyph or scope", function()
    local module = suite:require_module(work_layer, work_layer_err, "runtime.work_layer")
    local instance = fixture.packet({{path = "a.lua", content = "return 1\n"}}, {
        label = "work-layer-forged",
    })
    local birth = instance.trace[1].payload
    local projection, err = module.inspect_packet(instance, {
        protocol_version = "runtime.work_contract_view.v0",
        process_contract_id = birth.process_contract_id,
        context = birth.context,
        stage_id = birth.stage_id,
        glyph = "▲",
    })
    H.assert_nil(projection, "caller glyph is rejected")
    H.assert_contains(err, "unknown key", "authority injection is explicit")
end)

suite:check("WL04 projection is deterministic and detached", function()
    local module = suite:require_module(work_layer, work_layer_err, "runtime.work_layer")
    local instance = plan_at("work-layer-detached", 4)
    local first = assert(module.inspect_packet(instance))
    local second = assert(module.inspect_packet(instance))
    H.assert_true(module.same(first, second), "repeat inspection is exact")
    first.glyph = "▲"
    first.source_refs[1] = "caller-forged"
    local third = assert(module.inspect_packet(instance))
    H.assert_eq(third.glyph, "◈", "caller cannot mutate derivation")
    H.assert_true(third.source_refs[1] ~= "caller-forged", "nested refs are detached")
end)

suite:finish()
print("test_work_layer ok")
