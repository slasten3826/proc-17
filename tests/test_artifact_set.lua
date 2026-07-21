package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local digest = require("core.digest")
local fixture = require("tests.support.repository_hands")
local logic = require("organs.logic")
local capabilities = require("runtime.repository_capability")
local repository_intent = require("runtime.repository_intent")
local repository_action = require("runtime.repository_action")
local work_completion = require("runtime.work_completion")
local artifact_set, artifact_set_err = H.optional_require("runtime.artifact_set")
local suite = H.new("artifact-set")

local function normalized_seed(value)
    local seed = H.copy(value)
    seed.artifact_set_id = nil
    table.sort(seed.artifacts, function(left, right)
        if left.relative_path ~= right.relative_path then
            return left.relative_path < right.relative_path
        end
        return left.work_unit_id < right.work_unit_id
    end)
    table.sort(seed.source_refs)
    return seed
end

local function contract_for(instance, artifacts, overrides)
    local value = {
        protocol_version = "repository.artifact_set_contract.v0",
        artifact_set_id = nil,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        stage_id = "stage:" .. instance.lineage_id .. ":"
            .. tostring(instance.generation) .. ":build",
        repository_id = "repo-a",
        artifacts = H.copy(artifacts),
        source_refs = {"fixture:artifact-set"},
        event_truth_status = "runtime_confirmed",
        content_truth_status = "semantic_proposal",
    }
    for key, child in pairs(overrides or {}) do
        value[key] = H.copy(child)
    end
    value.artifact_set_id = "artifact-set:" .. assert(digest.record(normalized_seed(value)))
    return value
end

local function artifact_for(unit)
    return {
        work_unit_id = unit.id,
        work_unit_version = unit.version,
        relative_path = unit.carrier.value.path,
        expected_kind = "regular_file",
    }
end

local function completed_one(label)
    local instance = fixture.packet({{
        path = "src/main.lua",
        content = "return 'artifact-set'\n",
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

suite:check("AS01 duplicate path and work identities reject", function()
    local module = suite:require_module(artifact_set, artifact_set_err, "runtime.artifact_set")
    local instance = fixture.packet({{path = "a.lua", content = "return 1\n"}}, {
        label = "artifact-set-duplicate",
    })
    local unit = fixture.repository_units(instance)[1]
    local duplicated = contract_for(instance, {artifact_for(unit), artifact_for(unit)})
    local normalized, err = module.validate(duplicated)
    H.assert_nil(normalized, "duplicate declaration is denied")
    H.assert_contains(err, "duplicate", "duplicate denial is explicit")
end)

suite:check("AS02 exact current completion satisfies declaration", function()
    local module = suite:require_module(artifact_set, artifact_set_err, "runtime.artifact_set")
    local instance, action = completed_one("artifact-set-complete")
    local contract = contract_for(instance, {{
        work_unit_id = action.work_unit.id,
        work_unit_version = action.work_unit.version,
        relative_path = action.target.relative_path,
        expected_kind = "regular_file",
    }})
    local inspection = assert(module.inspect(instance, contract))
    H.assert_eq(inspection.state, "complete", "exact declaration completes")
    H.assert_eq(inspection.done_count, 1, "one exact completion")
    H.assert_eq(inspection.remaining_count, 0, "nothing declared remains")
    H.assert_eq(#inspection.completion_refs, 1, "completion evidence retained")
    H.assert_true(inspection.inventory_compatible, "no undeclared material exists")
end)

suite:check("AS03 stale version cannot satisfy declaration", function()
    local module = suite:require_module(artifact_set, artifact_set_err, "runtime.artifact_set")
    local instance, action = completed_one("artifact-set-stale")
    local contract = contract_for(instance, {{
        work_unit_id = action.work_unit.id,
        work_unit_version = action.work_unit.version,
        relative_path = action.target.relative_path,
        expected_kind = "regular_file",
    }})
    instance.field.units[action.work_unit.id].version = action.work_unit.version + 1
    local inspection = assert(module.inspect(instance, contract))
    H.assert_eq(inspection.state, "incomplete", "stale completion is not current")
    H.assert_eq(inspection.remaining_count, 1, "stale artifact remains")
    H.assert_eq(inspection.artifacts[1].state, "stale", "staleness is typed")
end)

suite:check("AS04 undeclared current material never counts toward set", function()
    local module = suite:require_module(artifact_set, artifact_set_err, "runtime.artifact_set")
    local instance = fixture.packet({
        {path = "src/a.lua", content = "return 'a'\n"},
        {path = "src/b.lua", content = "return 'b'\n"},
    }, {label = "artifact-set-undeclared"})
    local units = fixture.repository_units(instance)
    local inspection = assert(module.inspect(instance,
        contract_for(instance, {artifact_for(units[1])})))
    H.assert_eq(inspection.state, "incomplete", "declared artifact is still incomplete")
    H.assert_eq(#inspection.undeclared_artifacts, 1, "extra material is visible")
    H.assert_false(inspection.inventory_compatible,
        "undeclared material blocks later inventory compatibility")
end)

suite:check("AS05 declaration identity is order stable and detached", function()
    local module = suite:require_module(artifact_set, artifact_set_err, "runtime.artifact_set")
    local instance = fixture.packet({
        {path = "src/a.lua", content = "return 'a'\n"},
        {path = "src/b.lua", content = "return 'b'\n"},
    }, {label = "artifact-set-order"})
    local units = fixture.repository_units(instance)
    local left = contract_for(instance, {artifact_for(units[1]), artifact_for(units[2])}, {
        source_refs = {"source:b", "source:a"},
    })
    local right = contract_for(instance, {artifact_for(units[2]), artifact_for(units[1])}, {
        source_refs = {"source:a", "source:b"},
    })
    local normalized = assert(module.validate(left))
    local other = assert(module.validate(right))
    H.assert_eq(normalized.artifact_set_id, other.artifact_set_id, "canonical id")
    H.assert_true(module.same(normalized, other), "set equality ignores declaration order")
    normalized.artifacts[1].relative_path = "caller-mutated"
    H.assert_true(module.same(left, right), "returned values do not alias input")
end)

suite:finish()
print("test_artifact_set ok")
