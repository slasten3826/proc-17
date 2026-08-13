local corpse = require("runtime.corpse")
local digest = require("core.digest")
local lineage = require("runtime.lineage")
local network_projection = require("runtime.network_projection")
local schema = require("core.network_projection_schema")
local fixture = require("tests.support.qa_hand")

local function copy(value)
    return fixture.copy(value)
end

local function sorted_unique(values)
    local result, seen = {}, {}
    for _, value in ipairs(values or {}) do
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then return true end
    end
    return false
end

local function history_from(record)
    local refs = {
        record.corpse_id,
        record.corpse_hash,
        record.packet_id,
    }
    for _, ref in ipairs(record.qa_evidence.source_refs or {}) do
        refs[#refs + 1] = ref
    end
    return {
        protocol_version = "carrier.qa_history.v1",
        source_corpse_id = record.corpse_id,
        source_corpse_hash = record.corpse_hash,
        source_packet_id = record.packet_id,
        source_generation = record.generation,
        qa_evidence = copy(record.qa_evidence),
        source_refs = sorted_unique(refs),
        event_truth_status = "runtime_confirmed",
        applicability_truth_status = "inherited_proposal",
    }
end

local function count_events(state, kind)
    local count = 0
    for _, event in ipairs(state.ledger or {}) do
        if event.kind == kind then count = count + 1 end
    end
    return count
end

local boundary = assert(fixture.grow_qa_recovery_boundary({
    label = "network-rejected-projection",
    session_id = "session-network-rejected-projection",
    tail_events = 40,
}))
local state = boundary.lineage
local dead = boundary.corpse
local event = boundary.assessment_event
local carrier = boundary.carrier
local projection = boundary.network_projection

assert(state.status == "evaluating_terminal")
assert(count_events(state, "continuation_decided") == 0)
assert(schema.verify_projection(projection))
assert(network_projection.verify(projection, {
    lineage = state,
    corpse = dead,
    assessment_event = event,
    carrier = carrier,
    max_carrier_bytes = 1048576,
}))
assert(projection.terminal_recovery_basis == "qa_rejected")
assert(projection.current_work.original_task == state.task.payload)
assert(projection.current_work.remaining_work.kind
    == "fresh_candidate_generation")
assert(projection.rejected_form.projection_id:match("^rejected%-form:"))
assert(projection.rejected_form.failure_summary.check_reason
    == "unexpected_exit")
assert(projection.rejected_form.stdout == nil)
assert(projection.rejected_form.stderr == nil)
assert(projection.rejected_form.repository_id == nil)
assert(projection.rejected_form.repair_instruction == nil)
assert(projection.historical_qa_id
    == projection.rejected_form.historical_qa_id)

local state_before = assert(digest.record(state))
local corpse_before = assert(digest.record(dead))
local carrier_before = assert(digest.record(carrier))
local same_projection = assert(network_projection.derive(
    state,
    dead,
    event,
    carrier
))
assert(same_projection.projection_id == projection.projection_id)
assert(assert(digest.record(state)) == state_before)
assert(assert(digest.record(dead)) == corpse_before)
assert(assert(digest.record(carrier)) == carrier_before)
same_projection.current_work.original_task = "mutated detached return"
assert(projection.current_work.original_task == state.task.payload)

local absent, absent_status = network_projection.qa_subprojection(nil, {})
assert(absent == nil and absent_status == "absent")

local accepted = assert(fixture.grow_terminal_qa_life({
    label = "network-accepted-subprojection",
    process_contract_id = "software.create.v0",
}))
local accepted_form, accepted_status = network_projection.qa_subprojection(
    history_from(accepted.corpse_record),
    {
        target_generation = accepted.corpse_record.generation + 1,
        terminal_manifest_ref = accepted.corpse_record.manifest_trace_ref,
    }
)
assert(accepted_form == nil and accepted_status == "accepted")

local infrastructure = assert(fixture.run_qa_execution_tick({
    label = "network-infrastructure-subprojection",
    process_contract_id = "software.create.v0",
    adapter_options = {error_code = "supervisor_unavailable"},
}))
local infrastructure_dead = assert(corpse.capture(infrastructure.instance, {
    corpse_id = "corpse:network-infrastructure-subprojection",
}))
local infrastructure_form, infrastructure_status =
    network_projection.qa_subprojection(
        history_from(infrastructure_dead),
        {target_generation = infrastructure_dead.generation + 1}
    )
assert(infrastructure_form == nil)
assert(infrastructure_status == "execution_failure")

local incomplete_history = copy(carrier.payload.qa_history)
incomplete_history.qa_evidence.terminal_projection = nil
local incomplete_form, incomplete_err = network_projection.qa_subprojection(
    incomplete_history,
    {
        target_generation = dead.generation + 1,
        terminal_manifest_ref = dead.manifest_trace_ref,
    }
)
assert(incomplete_form == nil)
assert(incomplete_err:match("no terminal projection"))

local tampered_carrier = copy(carrier)
tampered_carrier.carrier_hash = string.rep("0", 64)
local tampered_projection, tampered_err = network_projection.derive(
    state,
    dead,
    event,
    tampered_carrier
)
assert(tampered_projection == nil)
assert(type(tampered_err) == "string" and tampered_err ~= "")

local foreign_event = copy(event)
foreign_event.id = "lineage-event:foreign-completion"
local foreign_projection, foreign_err = network_projection.derive(
    state,
    dead,
    foreign_event,
    carrier
)
assert(foreign_projection == nil)
assert(foreign_err:match("ledger head"))

local before_missing = #state.ledger
local missing, missing_err = lineage.mark_continued(state, dead, carrier)
assert(missing == nil)
assert(missing_err:match("requires NETWORK projection"))
assert(#state.ledger == before_missing)
assert(state.status == "evaluating_terminal")

local foreign_target = copy(projection)
foreign_target.target_generation = foreign_target.target_generation + 1
local before_foreign = #state.ledger
local denied, denied_err = lineage.mark_continued(state, dead, carrier, {
    network_projection = foreign_target,
})
assert(denied == nil)
assert(type(denied_err) == "string" and denied_err ~= "")
assert(#state.ledger == before_foreign)
assert(count_events(state, "continuation_decided") == 0)

assert(lineage.mark_continued(state, dead, carrier, {
    network_projection = projection,
}))
assert(state.status == "continuing")
assert(count_events(state, "continuation_decided") == 1)
local continuation = state.ledger[#state.ledger]
assert(continuation.kind == "continuation_decided")
assert(continuation.payload.network_projection_id == projection.projection_id)
assert(continuation.payload.completion_assessment_id
    == projection.completion_assessment_id)
assert(continuation.payload.completion_event_ref
    == projection.completion_event_ref)
for _, ref in ipairs({
    dead.corpse_id,
    carrier.carrier_id,
    projection.projection_id,
    projection.completion_assessment_id,
    projection.completion_event_ref,
}) do
    assert(contains(continuation.source_refs, ref))
end

print("test_network_rejected_projection ok")
