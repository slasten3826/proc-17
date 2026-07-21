package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local digest = require("core.digest")
local corpse = require("runtime.corpse")
local lineage = require("runtime.lineage")
local fixture = require("tests.support.repository_hands")
local plan_life = require("tests.support.plan_life")
local logic = require("organs.logic")
local capabilities = require("runtime.repository_capability")
local repository_intent = require("runtime.repository_intent")
local repository_action = require("runtime.repository_action")
local work_completion = require("runtime.work_completion")
local completion_scope, completion_scope_err = H.optional_require("runtime.completion_scope")
local suite = H.new("completion-scope")

local function completed_one(label)
    local instance = fixture.packet({{
        path = "src/main.lua",
        content = "return 'completion-scope'\n",
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
    local candidate = assert(work_completion.derive(instance, {
        action = action,
        attempt_ref = validation.attempt_ref,
        receipt_ref = validation.receipt_ref,
        verification_ref = validation.verification_ref,
        validation_ref = validation.trace_event_id,
    }))
    assert(work_completion.record(instance, candidate))
    return instance, action
end

local function artifact_contract(instance, action)
    local value = {
        protocol_version = "repository.artifact_set_contract.v0",
        artifact_set_id = nil,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        stage_id = instance.trace[1].payload.stage_id,
        repository_id = "repo-a",
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
    local seed = H.copy(value)
    seed.artifact_set_id = nil
    value.artifact_set_id = "artifact-set:" .. assert(digest.record(seed))
    return value
end

local function contract_view(instance, declared_set)
    local birth = instance.trace[1].payload
    return {
        protocol_version = "runtime.work_contract_view.v0",
        process_contract_id = birth.process_contract_id,
        context = birth.context,
        stage_id = birth.stage_id,
        artifact_set = declared_set,
    }
end

suite:check("CS00 Packet birth owns process coordinates", function()
    local instance = fixture.packet({{path = "a.lua", content = "return 1\n"}}, {
        label = "completion-scope-birth",
    })
    local birth = instance.trace[1].payload
    H.assert_eq(birth.process_contract_id, "build.only.v0", "mode selects process contract")
    H.assert_eq(birth.context, "software_task.v0", "semantic context is independent")
    H.assert_eq(birth.stage_id,
        "stage:" .. instance.lineage_id .. ":1:build", "stage is birth-stamped")
    H.assert_eq(birth.repository_id, "repo-a", "repository identity is birth-stamped")
end)

suite:check("CS01 one completion reaches work_item but no larger implicit scope", function()
    local module = suite:require_module(
        completion_scope,
        completion_scope_err,
        "runtime.completion_scope"
    )
    local instance = completed_one("completion-scope-work-item")
    local inspection = assert(module.inspect_packet(instance))
    H.assert_eq(inspection.highest_scope, "work_item", "one completion is local work")
    H.assert_eq(inspection.artifact_set.state, "unsupported",
        "undeclared set is not inferred")
    H.assert_eq(inspection.candidate.state, "unsupported", "seal reader is absent")
    H.assert_eq(inspection.stage.state, "unsupported", "Packet cannot complete stage")
    H.assert_eq(inspection.root.software_state, "unsupported",
        "Packet cannot accept software")
end)

suite:check("CS02 exact declared set reaches artifact_set and stops", function()
    local module = suite:require_module(
        completion_scope,
        completion_scope_err,
        "runtime.completion_scope"
    )
    local instance, action = completed_one("completion-scope-artifact-set")
    local inspection = assert(module.inspect_packet(instance,
        contract_view(instance, artifact_contract(instance, action))))
    H.assert_eq(inspection.highest_scope, "artifact_set", "declared set is exact")
    H.assert_eq(inspection.artifact_set.state, "complete", "set is complete")
    H.assert_eq(inspection.candidate.state, "unsupported", "no seal is invented")
    H.assert_eq(inspection.boundary_candidate.state, "none", "no QA boundary invented")
end)

suite:check("CS03 stale current version lowers scope", function()
    local module = suite:require_module(
        completion_scope,
        completion_scope_err,
        "runtime.completion_scope"
    )
    local instance, action = completed_one("completion-scope-stale")
    local view = contract_view(instance, artifact_contract(instance, action))
    instance.field.units[action.work_unit.id].version = action.work_unit.version + 1
    local inspection = assert(module.inspect_packet(instance, view))
    H.assert_eq(inspection.highest_scope, "none", "stale work is not complete")
    H.assert_eq(inspection.artifact_set.state, "incomplete", "set follows exact version")
end)

suite:check("CS04 plan corpse offers candidate but never writes stage", function()
    local module = suite:require_module(
        completion_scope,
        completion_scope_err,
        "runtime.completion_scope"
    )
    local packet = assert(plan_life.run(
        "completion-scope-plan",
        "work_sequence",
        {"inspect", "build", "verify"},
        5
    ))
    local packet_view = assert(module.inspect_packet(packet))
    H.assert_eq(packet_view.boundary_candidate.state, "plan_stage_ready",
        "dead Packet offers exact plan boundary")
    H.assert_true(packet_view.boundary_candidate.terminalized,
        "Packet terminal is already committed")
    H.assert_eq(packet_view.stage.state, "unsupported", "candidate is not stage completion")

    local dead = assert(corpse.capture(packet, {corpse_id = "corpse-completion-scope-plan"}))
    local corpse_view = assert(module.inspect_corpse(dead))
    H.assert_eq(corpse_view.boundary_candidate.state, "plan_stage_ready",
        "corpse retains the boundary")
    H.assert_eq(corpse_view.boundary_candidate.terminal_ref, dead.corpse_id,
        "corpse identity terminalizes candidate")
    H.assert_eq(corpse_view.highest_scope, "work_item",
        "corpse ceiling remains Packet-local")
end)

suite:check("CS05 caller cannot replace birth contract", function()
    local module = suite:require_module(
        completion_scope,
        completion_scope_err,
        "runtime.completion_scope"
    )
    local instance = fixture.packet({{path = "a.lua", content = "return 1\n"}}, {
        label = "completion-scope-forged-contract",
    })
    local forged = contract_view(instance)
    forged.process_contract_id = "software.create.v0"
    local inspection, err = module.inspect_packet(instance, forged)
    H.assert_nil(inspection, "caller-selected process contract is denied")
    H.assert_contains(err, "birth", "denial names immutable source")
end)

suite:check("CS06 economics cannot alter intrinsic inspection", function()
    local module = suite:require_module(
        completion_scope,
        completion_scope_err,
        "runtime.completion_scope"
    )
    local instance, action = completed_one("completion-scope-wallet")
    local view = contract_view(instance, artifact_contract(instance, action))
    local before = assert(module.inspect_packet(instance, view))
    instance.runtime.budget.exhausted = true
    instance.runtime.budget.remaining.steps = 0
    local after = assert(module.inspect_packet(instance, view))
    H.assert_true(module.same(before, after), "wallet is outside intrinsic completion")
end)

suite:check("CS07 returned inspection is detached", function()
    local module = suite:require_module(
        completion_scope,
        completion_scope_err,
        "runtime.completion_scope"
    )
    local instance = completed_one("completion-scope-detached")
    local first = assert(module.inspect_packet(instance))
    first.highest_scope = "root_delivery"
    first.work_items.done_refs[1] = "caller-forged"
    local second = assert(module.inspect_packet(instance))
    H.assert_eq(second.highest_scope, "work_item", "caller cannot raise scope")
    H.assert_true(second.work_items.done_refs[1] ~= "caller-forged",
        "nested evidence is detached")
end)

suite:check("CS08 lineage API stays unsupported without named stage readers", function()
    local module = suite:require_module(
        completion_scope,
        completion_scope_err,
        "runtime.completion_scope"
    )
    local state = assert(lineage.create("inspect lineage scope", {
        lineage_id = "lineage-completion-scope",
        session_id = "session-completion-scope",
        work_mode = "plan",
        budget = {steps = 16},
        carrier = {max_bytes = 4096},
    }))
    local inspection = assert(module.inspect_lineage(state))
    H.assert_eq(inspection.highest_scope, "none", "ledger readers are not invented")
    H.assert_eq(inspection.stage.state, "unsupported", "stage reader absence is typed")
    H.assert_eq(inspection.root.delivery_state, "unsupported", "root reader absence is typed")
end)

suite:finish()
print("test_completion_scope ok")
