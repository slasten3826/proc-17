package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local fixture = require("tests.support.repository_hands")
local logic = require("organs.logic")
local capabilities = require("runtime.repository_capability")
local repository_intent = require("runtime.repository_intent")
local repository_action = require("runtime.repository_action")
local work_completion = require("runtime.work_completion")
local artifact_set, artifact_set_err = H.optional_require("runtime.artifact_set")
local suite = H.new("artifact-set")

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
    local duplicated = assert(module.derive(instance))
    duplicated.artifacts[2] = H.copy(duplicated.artifacts[1])
    local normalized, err = module.validate(duplicated)
    H.assert_nil(normalized, "duplicate declaration is denied")
    H.assert_contains(err, "duplicate", "duplicate denial is explicit")
end)

suite:check("AS02 exact current completion satisfies declaration", function()
    local module = suite:require_module(artifact_set, artifact_set_err, "runtime.artifact_set")
    local instance, action = completed_one("artifact-set-complete")
    local contract = assert(module.derive(instance))
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
    local contract = assert(module.derive(instance))
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
    local contract = assert(module.derive(instance))
    contract.artifacts = {H.copy(contract.artifacts[1])}
    contract.artifact_set_id = assert(module.identify(contract))
    local inspection = assert(module.inspect(instance, contract))
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
    local left = assert(module.derive(instance))
    local right = H.copy(left)
    right.artifacts[1], right.artifacts[2] = right.artifacts[2], right.artifacts[1]
    local reversed = {}
    for index = #right.source_refs, 1, -1 do
        reversed[#reversed + 1] = right.source_refs[index]
    end
    right.source_refs = reversed
    for _, artifact in ipairs(right.artifacts) do
        local refs = {}
        for index = #artifact.provenance_refs, 1, -1 do
            refs[#refs + 1] = artifact.provenance_refs[index]
        end
        artifact.provenance_refs = refs
    end
    local normalized = assert(module.validate(left))
    local other = assert(module.validate(right))
    H.assert_eq(normalized.artifact_set_id, other.artifact_set_id, "canonical id")
    H.assert_true(module.same(normalized, other), "set equality ignores declaration order")
    normalized.artifacts[1].relative_path = "caller-mutated"
    H.assert_true(module.same(left, right), "returned values do not alias input")
end)

suite:check("AS06 body derivation round-trips through exact schema", function()
    local module = suite:require_module(artifact_set, artifact_set_err, "runtime.artifact_set")
    local instance = fixture.packet({
        {path = "src/a.lua", content = "return 'a'\n"},
        {path = "src/b.lua", content = "return 'b'\n"},
    }, {label = "artifact-set-derived"})
    local derived = assert(module.derive(instance))
    local validated = assert(module.validate(derived))
    H.assert_eq(derived.artifact_set_id, validated.artifact_set_id,
        "derive and validate agree")
    H.assert_eq(derived.birth_ref, instance.trace[1].id, "birth is named")
    H.assert_true(type(derived.formation_event_ref) == "string",
        "formation is named")
    H.assert_eq(#derived.artifacts, 2, "all current required artifacts derive")
end)

suite:check("AS07 legacy caller-built schema is rejected", function()
    local module = suite:require_module(artifact_set, artifact_set_err, "runtime.artifact_set")
    local instance = fixture.packet({{path = "src/main.lua", content = "return 1\n"}}, {
        label = "artifact-set-legacy",
    })
    local derived = assert(module.derive(instance))
    derived.birth_ref = nil
    derived.formation_event_ref = nil
    derived.process_contract_id = nil
    derived.context = nil
    derived.artifacts[1].unit_created_event_ref = nil
    derived.artifacts[1].provenance_refs = nil
    local value = module.validate(derived)
    H.assert_nil(value, "old declaration has no authority after schema migration")
end)

suite:check("AS08 derivation is physically massless", function()
    local module = suite:require_module(artifact_set, artifact_set_err, "runtime.artifact_set")
    local instance = fixture.packet({{path = "src/main.lua", content = "return 1\n"}}, {
        label = "artifact-set-massless",
    })
    local before_trace = #instance.trace
    local before_revisions = H.copy(instance.revisions)
    local first = assert(module.derive(instance))
    local second = assert(module.derive(instance))
    H.assert_eq(first.artifact_set_id, second.artifact_set_id,
        "repeat derivation is stable")
    H.assert_eq(#instance.trace, before_trace, "derivation appends no event")
    for key, value in pairs(before_revisions) do
        H.assert_eq(instance.revisions[key], value,
            "derivation does not move revision " .. key)
    end
end)

suite:finish()
print("test_artifact_set ok")
