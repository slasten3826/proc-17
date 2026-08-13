local dissolve = require("core.dissolve_schema")

local function hash(char)
    return string.rep(char, 64)
end

local function id(prefix, char)
    return prefix .. hash(char)
end

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy(key, seen)] = copy(child, seen)
    end
    return result
end

local reason = assert(dissolve.normalize_inherited_reason({
    kind = "rejected",
    subtype = "ancestor_candidate",
    network_projection_id = id("network-projection:", "a"),
    carrier_id = "carrier:dissolve-schema:2",
    source_corpse_id = "corpse-dissolve-schema-1",
    historical_qa_id = id("qa-history:", "b"),
    candidate_seal_id = id("candidate-seal:", "c"),
    verdict_id = id("qa-verdict:", "d"),
}))
assert(dissolve.verify_inherited_reason(reason))

local target_ref = "coverage:field_unit:unit:1:1"
local release_input = {
    protocol_version = dissolve.release_protocol,
    target = {
        kind = "unit",
        id = "unit:1",
        before_version = 1,
        after_version = 2,
        before_activation = "live",
        after_activation = "dissolved",
    },
    reason = reason,
    residue_unit_id = "unit:2",
    released_mass = {forms = 1, relations = 0},
    irreversible_identity_loss = 0,
    source_refs = {
        reason.verdict_id,
        reason.network_projection_id,
        reason.historical_qa_id,
        reason.source_corpse_id,
        reason.candidate_seal_id,
        reason.carrier_id,
        target_ref,
        reason.carrier_id,
    },
    event_truth_status = "runtime_confirmed",
    content_truth_status = "mixed",
}

local release = assert(dissolve.normalize_release(release_input))
assert(dissolve.verify_release(release))
assert(release.release_id:match("^dissolve%-release:"))
assert(dissolve.release_identity(release) == release.release_id)
assert(#release.source_refs == #release_input.source_refs - 1)

local failure_summary = {
    check_reason = "unexpected_exit",
    termination = {kind = "exit", exit_code = 70},
    cause = {
        protocol_version = "qa.first_cause.v1",
        kind = "unexpected_exit",
        monotonic_sequence = 1,
        observed_value = 70,
    },
    finality = {
        candidate_terminal_observed = true,
        process_tree_reaped = true,
        namespace_cleanup_complete = true,
    },
}

local residue = assert(dissolve.normalize_residue_carrier({
    protocol_version = dissolve.residue_protocol,
    source_packet_id = "packet-dissolve-schema-1",
    source_corpse_id = reason.source_corpse_id,
    source_generation = 1,
    historical_qa_id = reason.historical_qa_id,
    candidate_seal_id = reason.candidate_seal_id,
    qa_contract_id = id("qa-contract:", "e"),
    verdict_id = reason.verdict_id,
    rejected_check_refs = {"trace:qa-check:1"},
    failure_summary = failure_summary,
    release_id = release.release_id,
    ancestor_evidence_truth_status = "runtime_confirmed",
    prior_applicability_truth_status = "inherited_proposal",
    release_truth_status = "runtime_confirmed",
}))
assert(dissolve.verify_residue_carrier(residue))

local detached = assert(dissolve.normalize_residue_carrier(residue))
detached.failure_summary.cause.kind = "caller_mutation"
assert(residue.failure_summary.cause.kind == "unexpected_exit")

local changed = copy(release)
changed.release_id = nil
changed.target.before_activation = "selected"
local changed_release = assert(dissolve.normalize_release(changed))
assert(changed_release.release_id ~= release.release_id)

local wrong_identity = copy(release)
wrong_identity.reason.carrier_id = "carrier:tampered"
assert(dissolve.normalize_release(wrong_identity) == nil)

local unknown = copy(release_input)
unknown.command = "rm"
assert(dissolve.normalize_release(unknown) == nil)

local bad_target = copy(release_input)
bad_target.target.after_version = 3
assert(dissolve.normalize_release(bad_target) == nil)

local aliased_target = copy(release_input)
aliased_target.residue_unit_id = aliased_target.target.id
assert(dissolve.normalize_release(aliased_target) == nil)

local missing_scope = copy(release_input)
for index, ref in ipairs(missing_scope.source_refs) do
    if ref == reason.verdict_id then
        table.remove(missing_scope.source_refs, index)
        break
    end
end
assert(dissolve.normalize_release(missing_scope) == nil)

local noncanonical = copy(release)
noncanonical.source_refs[1], noncanonical.source_refs[2] =
    noncanonical.source_refs[2], noncanonical.source_refs[1]
assert(dissolve.verify_release(noncanonical) == nil)

local raw_output = copy(residue)
raw_output.failure_summary.cause.stdout = "forbidden"
assert(dissolve.normalize_residue_carrier(raw_output) == nil)

local cyclic = copy(residue)
cyclic.failure_summary.cause.self = cyclic.failure_summary.cause
assert(dissolve.normalize_residue_carrier(cyclic) == nil)

local metatable = copy(residue)
setmetatable(metatable.failure_summary.termination, {})
assert(dissolve.normalize_residue_carrier(metatable) == nil)

local wrong_truth = copy(residue)
wrong_truth.prior_applicability_truth_status = "runtime_confirmed"
assert(dissolve.normalize_residue_carrier(wrong_truth) == nil)

print("test_dissolve_schema ok")
