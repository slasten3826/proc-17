local carrier = require("runtime.carrier")
local completion = require("runtime.completion")
local corpse = require("runtime.corpse")
local digest = require("core.digest")
local grave = require("runtime.grave")
local lineage = require("runtime.lineage")
local lineage_budget = require("runtime.lineage_budget")
local network_projection = require("runtime.network_projection")
local packet = require("core.packet")
local fixture = require("tests.support.qa_hand")

local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then return true end
    end
    return false
end

local function state_for(record, label, options)
    options = options or {}
    local state = assert(lineage.create("replace rejected candidate", {
        lineage_id = record.lineage_id,
        session_id = "session-qa-recovery-" .. label,
        work_mode = "build",
        completion_contract_id = "software.create.v0",
        allow_recovery = options.allow_recovery,
        carrier = {max_bytes = 1048576},
        budget = {
            steps = 100,
            generations = 4,
            carrier_bytes = 1048576,
        },
    }))
    state.status = "evaluating_terminal"
    state.current_generation = record.generation
    state.current_packet_id = record.packet_id
    state.current_corpse_id = record.corpse_id
    if options.exhausted then
        assert(lineage_budget.charge(
            state.budget,
            "test:exhaust-wallet",
            {steps = 100},
            {record.corpse_id}
        ))
        assert(state.budget.exhausted == true)
    end
    return state
end

local function rehash(record)
    local projected = fixture.copy(record)
    projected.corpse_hash = nil
    record.corpse_hash = assert(digest.record(projected))
    return record
end

local rejected = assert(fixture.grow_terminal_qa_life({
    label = "qa-rejected-lineage-recovery",
    process_contract_id = "software.create.v0",
    adapter_options = {reason = "unexpected_exit", exit_code = 70},
    tail_events = 40,
}))
local dead = rejected.corpse_record
local state = state_for(dead, "open")
local assessment = assert(completion.evaluate(state, dead))

assert(assessment.contract_id == "software.create.v0")
assert(assessment.task_state == "unfinished")
assert(assessment.terminal_recoverable == true)
assert(assessment.terminal_recovery_basis == "qa_rejected")
assert(assessment.progress.rejected_generation == dead.generation)
assert(assessment.progress.candidate_seal_id
    == dead.qa_evidence.verdict.candidate_seal_id)
assert(assessment.progress.verdict_id == dead.qa_evidence.verdict.verdict_id)
assert(assessment.remaining_work.count == 1)
assert(assessment.remaining_work.kind == "fresh_candidate_generation")
assert(assessment.remaining_work.stage_id == dead.stage_id)
for _, ref in ipairs({
    dead.corpse_id,
    dead.corpse_hash,
    dead.terminal_trace_ref,
    dead.manifest_trace_ref,
    dead.qa_evidence.check.qa_check_id,
    dead.qa_evidence.check_ref,
    dead.qa_evidence.verdict.verdict_id,
    dead.qa_evidence.verdict_ref,
}) do
    assert(contains(assessment.evidence_refs, ref), "missing assessment ref " .. ref)
end

local ledger_event = assert(lineage.append_event(state, {
    kind = "completion_evaluated",
    generation = dead.generation,
    packet_id = dead.packet_id,
    corpse_id = dead.corpse_id,
    payload = assessment,
    source_refs = assessment.evidence_refs,
    content_truth_statuses = assessment.basis_truth_statuses,
}))
assert(ledger_event.payload.assessment_id == assessment.assessment_id)
assert(ledger_event.payload.progress.verdict_id == dead.qa_evidence.verdict.verdict_id)

local recovery = assert(carrier.build_recovery(state, dead, assessment, {
    carrier_id = "carrier:qa-rejected-lineage-recovery:2",
    max_bytes = 1048576,
}))
assert(carrier.verify(recovery, {
    lineage_id = dead.lineage_id,
    source_corpse_id = dead.corpse_id,
    target_generation = dead.generation + 1,
    max_bytes = 1048576,
}))
assert(recovery.payload.remaining_work.kind == "fresh_candidate_generation")
assert(recovery.payload.qa_history.qa_evidence.verdict.verdict == "rejected")
assert(recovery.payload.qa_history.applicability_truth_status
    == "inherited_proposal")

local exhausted = assert(completion.evaluate(
    state_for(dead, "exhausted", {exhausted = true}),
    dead
))
local policy_denied = assert(completion.evaluate(
    state_for(dead, "policy-denied", {allow_recovery = false}),
    dead
))
assert(exhausted.assessment_id == assessment.assessment_id)
assert(policy_denied.assessment_id == assessment.assessment_id)
assert(exhausted.task_state == "unfinished")
assert(policy_denied.task_state == "unfinished")

local forged_assessment = fixture.copy(assessment)
for index, ref in ipairs(forged_assessment.evidence_refs) do
    if ref == dead.corpse_hash then
        table.remove(forged_assessment.evidence_refs, index)
        break
    end
end
local forged_carrier, forged_carrier_err = carrier.build_recovery(
    state,
    dead,
    forged_assessment,
    {max_bytes = 1048576}
)
assert(forged_carrier == nil)
assert(forged_carrier_err:match("omits frozen evidence"))

local accepted = assert(fixture.grow_terminal_qa_life({
    label = "qa-accepted-lineage-boundary",
    process_contract_id = "software.create.v0",
}))
local accepted_assessment = assert(completion.evaluate(
    state_for(accepted.corpse_record, "accepted"),
    accepted.corpse_record
))
assert(accepted_assessment.task_state == "unknown")
assert(accepted_assessment.terminal_recoverable == false)
assert(accepted_assessment.terminal_recovery_basis == nil)
assert(accepted_assessment.progress.accepted_generation
    == accepted.corpse_record.generation)
assert(accepted_assessment.missing_requirements[1]
    == "lineage_software_scope_reader")

local partial = assert(fixture.run_qa_execution_tick({
    label = "qa-partial-lineage-boundary",
    process_contract_id = "software.create.v0",
    adapter_options = {reason = "unexpected_exit", exit_code = 70},
}))
assert(packet.die(partial.instance, "blocked", {
    cause = "blocked",
    remaining_work_count = 1,
}))
local partial_dead = assert(corpse.capture(partial.instance, {
    corpse_id = "corpse:qa-partial-lineage-boundary",
}))
local partial_assessment = assert(completion.evaluate(
    state_for(partial_dead, "partial"),
    partial_dead
))
assert(partial_assessment.task_state == "blocked")
assert(partial_assessment.terminal_recoverable == false)
assert(partial_assessment.terminal_recovery_basis == nil)

local malformed = rehash(fixture.copy(dead))
malformed.qa_evidence.terminal_projection = nil
rehash(malformed)
local malformed_assessment, malformed_err = completion.evaluate(
    state_for(malformed, "malformed"),
    malformed
)
assert(malformed_assessment == nil)
assert(type(malformed_err) == "string" and malformed_err ~= "")

local foreign = fixture.copy(dead)
foreign.qa_evidence.verdict.stage_id = "stage:foreign-lineage:1:build"
rehash(foreign)
local foreign_assessment, foreign_err = completion.evaluate(
    state_for(foreign, "foreign"),
    foreign
)
assert(foreign_assessment == nil)
assert(type(foreign_err) == "string" and foreign_err ~= "")

local infrastructure = assert(fixture.run_qa_execution_tick({
    label = "qa-infrastructure-lineage-boundary",
    process_contract_id = "software.create.v0",
    adapter_options = {error_code = "supervisor_unavailable"},
}))
assert(infrastructure.instance.status == "dead")
assert(infrastructure.instance.death.cause == "effect_failure")
local infrastructure_dead = assert(corpse.capture(infrastructure.instance, {
    corpse_id = "corpse:qa-infrastructure-lineage-boundary",
}))
local infrastructure_assessment = assert(completion.evaluate(
    state_for(infrastructure_dead, "infrastructure"),
    infrastructure_dead
))
assert(infrastructure_assessment.task_state == "blocked")
assert(infrastructure_assessment.terminal_recoverable == false)
assert(infrastructure_assessment.terminal_recovery_basis == nil)

local grave_input = {
    id = dead.packet_id,
    status = "dead",
    terminal = {kind = "manifest"},
    death = {cause = "blocked"},
    residue = {remaining_work_count = 1},
    trace_tail = {},
}
local grave_without_qa = assert(grave.classify(grave_input))
local grave_with_qa_input = fixture.copy(grave_input)
grave_with_qa_input.qa_evidence = fixture.copy(dead.qa_evidence)
local grave_with_qa = assert(grave.classify(grave_with_qa_input))
assert(grave_with_qa.grave_kind == grave_without_qa.grave_kind)
assert(grave_with_qa.death_cause == grave_without_qa.death_cause)

local continuation_projection = assert(network_projection.derive(
    state,
    dead,
    ledger_event,
    recovery
))
assert(lineage.mark_continued(
    state,
    dead,
    recovery,
    {network_projection = continuation_projection}
))
local repeated, repeated_err = lineage.mark_continued(
    state,
    dead,
    recovery,
    {network_projection = continuation_projection}
)
assert(repeated == nil)
assert(type(repeated_err) == "string" and repeated_err ~= "")

print("test_qa_rejected_lineage_recovery ok")
