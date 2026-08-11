package.path = "./?.lua;./?/init.lua;" .. package.path

local case_manifest = require("runtime.edge_case_manifest")
local corpse = require("runtime.corpse")
local digest = require("core.digest")
local json = require("core.json")
local life_projection = require("runtime.edge_life_projection")
local fixture = require("tests.support.plan_life")

local function assert_true(value, message)
    if not value then error(message or "assertion failed", 2) end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function copy_value(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

local function tagged(value)
    return "sha256:" .. assert(digest.record(value))
end

local manifest = case_manifest.current()
assert_true(case_manifest.verify_manifest(manifest), "CA01 current manifest verifies")
assert_eq(#manifest.required_l0, 14, "CA01 fourteen L0 cases")
assert_eq(#manifest.required_l1, 4, "CA01 four L1 cases")
assert_eq(case_manifest.current().manifest_id, manifest.manifest_id,
    "CA01 manifest digest stable")
assert_eq(manifest.required_l0[6].case_id, "P06a", "CA01 P06 split a")
assert_eq(manifest.required_l0[7].case_id, "P06b", "CA01 P06 split b")

local altered_manifest = copy_value(manifest)
altered_manifest.required_l0[1].evaluator_id = "caller.green.v0"
local altered_ok = case_manifest.verify_manifest(altered_manifest)
assert_eq(altered_ok, nil, "CA02 caller cannot replace evaluator")

local packet, result = assert(fixture.run(
    "edge-case-p06a",
    "work_sequence",
    {"inspect"},
    5,
    {
        packet_options = {
            id = "packet:edge-case-p06a",
            lineage_id = "lineage:edge-case-p06a",
            budget = {
                steps = 1,
                substrate_calls = 4,
                tool_calls = 4,
                encode_items = 4,
                loss = 4,
            },
        },
    }
))
local dead = assert(corpse.capture(packet, {
    corpse_id = "corpse:edge-case-p06a",
    trace_tail_count = 4,
}))
local primary_projection = assert(life_projection.capture(packet, result, dead, {
    life_id = "projection:edge-case-p06a",
}))

local epoch_id = tagged({epoch = "qualified"})
local physics_id = tagged({physics = "qualified"})
local revision = "revision:edge-case-manifest"
local function life(
    life_id, case_id, layer, revision_override, epoch_override, physics_override
)
    return {
        life_id = life_id,
        case_id = case_id,
        corpus_layer = layer or "L0",
        evidence_epoch_id = epoch_override or epoch_id,
        physics_epoch_id = physics_override or physics_id,
        implementation_revision = revision_override or revision,
        projection = copy_value(primary_projection),
        eligible_directions = {},
    }
end

local primary_id = "life:p06a:primary"
local control_id = "life:p06a:host-ceiling-control"
local pair_id = tagged({pair = "p06a"})
local view = {
    kind = "edge_case_corpus_view",
    protocol_version = case_manifest.view_protocol_version,
    target_evidence_epoch_id = epoch_id,
    target_physics_epoch_id = physics_id,
    implementation_revision = revision,
    lives = {
        [primary_id] = life(primary_id, "P06a"),
        [control_id] = life(control_id, "P08"),
    },
    observer_pairs = {
        [pair_id] = {
            pair_id = pair_id,
            status = "green",
            enabled_life_id = primary_id,
            disabled_life_id = control_id,
            physics_epoch_id = physics_id,
        },
    },
    evidence_records = {},
    harness_evidence = {},
}

local p06a = assert(case_manifest.evaluate_l0("P06a", view, {
    life_ids = {primary_id},
    observer_pair_refs = {pair_id},
    controls = {
        host_ceiling_above_budget = {life_ids = {control_id}},
    },
}))
assert_eq(p06a.status, "green", "closed P06a evaluator derives green")
assert_true(case_manifest.verify_case_evidence(p06a, manifest),
    "derived L0 evidence verifies")

local unknown, unknown_err = case_manifest.evaluate_l0("P99", view, {})
assert_eq(unknown, nil, "CA02 unknown case rejects")
assert_eq(unknown_err.code, "case_id_unknown", "CA02 unknown case code")

local forged_truth = copy_value(p06a)
forged_truth.evaluation_truth_status = "document_decision"
local forged_ok, forged_err = case_manifest.verify_case_evidence(forged_truth, manifest)
assert_eq(forged_ok, nil, "CA03 L0 cannot borrow document truth")
assert_eq(forged_err.code, "case_evaluation_truth_invalid", "CA03 truth code")

local unresolved, unresolved_err = case_manifest.evaluate_l0("P06a", view, {
    life_ids = {"life:missing"},
    observer_pair_refs = {pair_id},
    controls = {host_ceiling_above_budget = {life_ids = {control_id}}},
})
assert_eq(unresolved, nil, "CA04 unresolved life rejects")
assert_eq(unresolved_err.code, "case_life_unresolved", "CA04 unresolved code")

local wrong_epoch_view = copy_value(view)
wrong_epoch_view.lives[control_id].evidence_epoch_id = tagged({epoch = "other"})
local wrong_epoch, wrong_epoch_err = case_manifest.evaluate_l0(
    "P06a",
    wrong_epoch_view,
    {
        life_ids = {primary_id},
        observer_pair_refs = {pair_id},
        controls = {host_ceiling_above_budget = {life_ids = {control_id}}},
    }
)
assert_eq(wrong_epoch, nil, "CA05 unlike life epoch rejects")
assert_eq(wrong_epoch_err.code, "case_life_unresolved", "CA05 epoch code")

local wrong_revision_view = copy_value(view)
wrong_revision_view.lives[control_id].implementation_revision = "other-revision"
local wrong_revision = case_manifest.evaluate_l0("P06a", wrong_revision_view, {
    life_ids = {primary_id},
    observer_pair_refs = {pair_id},
    controls = {host_ceiling_above_budget = {life_ids = {control_id}}},
})
assert_eq(wrong_revision, nil, "CA05 unlike implementation revision rejects")

local document_digest = tagged({artifact = "accepted-build"})
local prompt_hash = tagged({prompt = "live"})
local valid_document = assert(case_manifest.l1_document({
    case_id = "L1_ACCEPTED_BUILD",
    artifact_path = "sandbox/live/accepted.json",
    artifact_digest = document_digest,
    provider = "deepseek",
    model = "deepseek-chat",
    prompt_hash = prompt_hash,
    usage_ref = "usage:live:accepted",
    source_revision = revision,
    verifier_ref = "verifier:live:accepted",
    decision = "green",
    decision_reason = "verified_success",
}))
assert_true(case_manifest.verify_l1_document(valid_document),
    "CA06 complete live document verifies")
local missing_provider = copy_value(valid_document)
missing_provider.provider = ""
local missing_ok, missing_err = case_manifest.verify_l1_document(missing_provider)
assert_eq(missing_ok, nil, "CA06 missing provider rejects")
assert_eq(missing_err.code, "l1_document_invalid", "CA06 missing provider code")

local family_pairs = {}
local family_view = copy_value(view)
local family_ids = {
    "P01", "P02", "P03", "P04", "P05", "P06a", "P06b",
    "P07", "P08", "P09", "P10", "P11",
}
for index, case_id in ipairs(family_ids) do
    local enabled = "life:family:" .. case_id .. ":enabled"
    local disabled = "life:family:" .. case_id .. ":disabled"
    local family_pair = tagged({pair = case_id, index = index})
    family_view.lives[enabled] = life(enabled, case_id)
    family_view.lives[disabled] = life(
        disabled,
        case_id,
        nil,
        nil,
        tagged({epoch = "observer-control", case_id = case_id})
    )
    family_view.observer_pairs[family_pair] = {
        pair_id = family_pair,
        status = "green",
        enabled_life_id = enabled,
        disabled_life_id = disabled,
        physics_epoch_id = physics_id,
    }
    family_pairs[case_id] = family_pair
end
local incomplete_pairs = copy_value(family_pairs)
incomplete_pairs.P11 = nil
local incomplete = assert(case_manifest.evaluate_l0("P12", family_view, {
    family_pairs = incomplete_pairs,
}))
assert_eq(incomplete.status, "blocked", "CA07 omitted family pair is not green")
local complete = assert(case_manifest.evaluate_l0("P12", family_view, {
    family_pairs = family_pairs,
}))
assert_eq(complete.status, "green", "CA07 all twelve family pairs are green")

local pair_without_target = copy_value(family_view)
local first_pair = pair_without_target.observer_pairs[family_pairs.P01]
pair_without_target.lives[first_pair.enabled_life_id].evidence_epoch_id =
    tagged({epoch = "observer-enabled-control"})
local no_target, no_target_err = case_manifest.evaluate_l0("P12", pair_without_target, {
    family_pairs = family_pairs,
})
assert_eq(no_target, nil, "real observer pair must contain the target epoch")
assert_eq(no_target_err.code, "case_observer_pair_target_mismatch",
    "target-epoch pair mismatch is typed")

local harness = assert(case_manifest.harness_evidence({
    case_id = "P13",
    invalid_invocation_digest = tagged({invocation = "malformed"}),
    harness_error_code = "trusted_contract_contradiction",
    packet_death_observed = false,
    packet_terminal_observed = false,
    matching_valid_life_id = control_id,
    source_revision = revision,
    verifier_ref = "verifier:harness:P13",
}))
local p13_view = copy_value(view)
p13_view.harness_evidence[harness.boundary_evidence_id] = harness
p13_view.lives[control_id].case_id = "P05"
local p13 = assert(case_manifest.evaluate_l0("P13", p13_view, {
    controls = {
        matched_typed_failure = {evidence_refs = {harness.boundary_evidence_id}},
    },
    evidence_refs = {harness.boundary_evidence_id},
}))
assert_eq(p13.status, "green", "CA08 matched loud harness evidence is green")
assert_eq(#p13.life_ids, 0, "CA08 no synthetic P13 life")
assert_eq(#p13.observer_pair_refs, 0, "CA08 no synthetic P13 observer pair")

local unit_view = copy_value(view)
unit_view.lives[control_id].corpus_layer = "unit"
local unit_control, unit_err = case_manifest.evaluate_l0("P06a", unit_view, {
    life_ids = {primary_id},
    observer_pair_refs = {pair_id},
    controls = {host_ceiling_above_budget = {life_ids = {control_id}}},
})
assert_eq(unit_control, nil, "CA09 unit life cannot enter corpus refs")
assert_eq(unit_err.code, "case_life_unresolved", "CA09 unit exclusion code")

print("test_edge_case_manifest ok")
