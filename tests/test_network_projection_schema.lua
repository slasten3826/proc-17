local schema = require("core.network_projection_schema")

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

local function failure_summary()
    return {
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
end

local coordinates = {
    carrier_id = "carrier:ancestor:2",
    carrier_hash = hash("a"),
    lineage_id = "lineage-network-schema",
    source_packet_id = "packet-network-schema-1",
    source_corpse_id = "corpse-network-schema-1",
    source_corpse_hash = hash("b"),
    source_generation = 1,
    target_generation = 2,
    stage_id = "stage:lineage-network-schema:1:build",
    assessment_id = id("lineage-assessment:", "c"),
    assessment_ref = "lineage-event:completion:1",
    manifest_ref = "trace:manifest:1",
    historical_qa_id = id("qa-history:", "d"),
    candidate_seal_id = id("candidate-seal:", "e"),
    candidate_seal_ref = "trace:candidate-seal:1",
    alignment_id = "artifact-alignment:network-schema",
    qa_contract_id = id("qa-contract:", "f"),
    verdict_id = id("qa-verdict:", "1"),
    verdict_ref = "trace:qa-verdict:1",
    check_id = id("qa-check:", "2"),
    check_ref = "trace:qa-check:1",
}

local current_work = assert(schema.normalize_current_work({
    protocol_version = schema.current_work_protocol,
    original_task = "build the exact candidate again",
    remaining_work = {
        count = 1,
        kind = "fresh_candidate_generation",
        stage_id = coordinates.stage_id,
    },
    prior_generation = coordinates.source_generation,
    continuation_basis = "qa_rejected",
    process_contract_id = "software.create.v0",
    context = "software_task.v0",
    stage_id = coordinates.stage_id,
    source_refs = {
        coordinates.assessment_ref,
        coordinates.assessment_id,
        coordinates.assessment_ref,
    },
    content_truth_status = "semantic_proposal",
}))
assert(schema.verify_current_work(current_work))
assert(current_work.source_refs[1] == coordinates.assessment_id)
assert(current_work.source_refs[2] == coordinates.assessment_ref)

local form_source_refs = {
    coordinates.verdict_ref,
    coordinates.source_corpse_id,
    coordinates.check_ref,
    coordinates.source_packet_id,
    coordinates.qa_contract_id,
    coordinates.candidate_seal_id,
    coordinates.source_corpse_hash,
    coordinates.historical_qa_id,
    coordinates.alignment_id,
    coordinates.candidate_seal_ref,
    coordinates.verdict_id,
    coordinates.check_id,
    coordinates.manifest_ref,
    coordinates.check_ref,
}

local rejected_form = assert(schema.normalize_rejected_form({
    protocol_version = schema.rejected_form_protocol,
    source_packet_id = coordinates.source_packet_id,
    source_corpse_id = coordinates.source_corpse_id,
    source_corpse_hash = coordinates.source_corpse_hash,
    source_generation = coordinates.source_generation,
    target_generation = coordinates.target_generation,
    historical_qa_id = coordinates.historical_qa_id,
    candidate_seal_id = coordinates.candidate_seal_id,
    candidate_seal_event_ref = coordinates.candidate_seal_ref,
    artifact_alignment_id = coordinates.alignment_id,
    qa_contract_id = coordinates.qa_contract_id,
    verdict_id = coordinates.verdict_id,
    verdict_ref = coordinates.verdict_ref,
    rejected_check_ids = {coordinates.check_id},
    rejected_check_refs = {coordinates.check_ref},
    failure_summary = failure_summary(),
    terminal_manifest_ref = coordinates.manifest_ref,
    source_refs = form_source_refs,
    event_truth_status = "runtime_confirmed",
    applicability_truth_status = "inherited_proposal",
}))
assert(schema.verify_rejected_form(rejected_form))
assert(rejected_form.projection_id:match("^rejected%-form:"))
assert(schema.rejected_form_identity(rejected_form) == rejected_form.projection_id)
assert(#rejected_form.source_refs == #form_source_refs - 1)

local projection_refs = {
    coordinates.carrier_id,
    coordinates.carrier_hash,
    coordinates.source_packet_id,
    coordinates.source_corpse_id,
    coordinates.assessment_id,
    coordinates.assessment_ref,
    coordinates.manifest_ref,
    coordinates.historical_qa_id,
}
for _, ref in ipairs(rejected_form.source_refs) do
    projection_refs[#projection_refs + 1] = ref
end

local projection = assert(schema.normalize_projection({
    protocol_version = schema.projection_protocol,
    carrier_id = coordinates.carrier_id,
    carrier_hash = coordinates.carrier_hash,
    lineage_id = coordinates.lineage_id,
    source_packet_id = coordinates.source_packet_id,
    source_corpse_id = coordinates.source_corpse_id,
    source_generation = coordinates.source_generation,
    target_generation = coordinates.target_generation,
    process_contract_id = "software.create.v0",
    context = "software_task.v0",
    stage_id = coordinates.stage_id,
    completion_assessment_id = coordinates.assessment_id,
    completion_event_ref = coordinates.assessment_ref,
    terminal_recovery_basis = "qa_rejected",
    source_manifest_ref = coordinates.manifest_ref,
    current_work = current_work,
    rejected_form = rejected_form,
    historical_qa_id = coordinates.historical_qa_id,
    source_refs = projection_refs,
    event_truth_status = "runtime_confirmed",
    content_truth_status = "mixed",
}))
assert(schema.verify_projection(projection))
assert(schema.projection_identity(projection) == projection.projection_id)

local detached = assert(schema.normalize_projection(projection))
detached.current_work.remaining_work.count = 99
detached.rejected_form.failure_summary.cause.kind = "caller_mutation"
assert(projection.current_work.remaining_work.count == 1)
assert(projection.rejected_form.failure_summary.cause.kind == "unexpected_exit")

local changed_form = copy(rejected_form)
changed_form.projection_id = nil
changed_form.failure_summary.cause.observed_value = 71
changed_form = assert(schema.normalize_rejected_form(changed_form))
assert(changed_form.projection_id ~= rejected_form.projection_id)

local wrong_identity = copy(rejected_form)
wrong_identity.failure_summary.check_reason = "signal"
assert(schema.normalize_rejected_form(wrong_identity) == nil)

local unknown = copy(projection)
unknown.repository_id = "forbidden-repository"
assert(schema.normalize_projection(unknown) == nil)

local cyclic_work = copy(current_work)
cyclic_work.remaining_work.self = cyclic_work.remaining_work
assert(schema.normalize_current_work(cyclic_work) == nil)

local metatable_summary = copy(rejected_form)
metatable_summary.projection_id = nil
setmetatable(metatable_summary.failure_summary.cause, {})
assert(schema.normalize_rejected_form(metatable_summary) == nil)

local authority_smuggling = copy(current_work)
authority_smuggling.remaining_work.repository_id = "repo-ancestor"
assert(schema.normalize_current_work(authority_smuggling) == nil)

local foreign_generation = copy(projection)
foreign_generation.projection_id = nil
foreign_generation.target_generation = 3
assert(schema.normalize_projection(foreign_generation) == nil)

local omitted_ref = copy(projection)
omitted_ref.projection_id = nil
for index, ref in ipairs(omitted_ref.source_refs) do
    if ref == coordinates.verdict_id then
        table.remove(omitted_ref.source_refs, index)
        break
    end
end
assert(schema.normalize_projection(omitted_ref) == nil)

local noncanonical = copy(projection)
noncanonical.source_refs[1], noncanonical.source_refs[2] =
    noncanonical.source_refs[2], noncanonical.source_refs[1]
assert(schema.verify_projection(noncanonical) == nil)

local too_small = schema.normalize_current_work(current_work, {
    max_current_work_bytes = 16,
})
assert(too_small == nil)

print("test_network_projection_schema ok")
