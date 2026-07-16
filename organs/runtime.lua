local packet_core = require("core.packet")
local body = require("runtime.body")
local budget = require("runtime.budget")
local foundation = require("runtime.foundation")
local loss = require("runtime.loss")
local camera = require("runtime.camera")
local reconciliation = require("runtime.reconciliation")

local runtime_organ = {}

function runtime_organ.readiness(instance)
    if type(instance) ~= "table" then
        return {
            operator = "☱",
            ready = false,
            reason = "runtime_view_empty",
            source_refs = {},
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    local inspection, inspection_err = reconciliation.inspect(instance)
    if not inspection then
        return nil, inspection_err
    end
    return {
        operator = "☱",
        ready = inspection.has_debt,
        reason = inspection.has_debt and "runtime_reconciliation_debt"
            or "nothing_to_reconcile",
        source_refs = inspection.source_refs,
        pending_frame_count = inspection.pending_frame_count,
        significant_frame_count = inspection.significant_frame_count,
        required_capabilities = {},
        missing_capabilities = {},
        event_truth_status = "runtime_confirmed",
    }
end

function runtime_organ.run(instance)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "run runtime eye")
    if not mutable then
        return nil, mutable_err
    end

    local inspection, inspection_err = reconciliation.inspect(instance)
    if not inspection then
        return nil, inspection_err
    end
    local reconciliation_record, reconciliation_err = camera.reconcile(instance, {
        through_seq = inspection.through_seq,
        resolved_refs = inspection.resolved_refs,
        unresolved_refs = inspection.unresolved_refs,
        completion_state = inspection.completion_state,
    })
    if not reconciliation_record then
        return nil, reconciliation_err
    end

    local progress = body.progress(instance)
    local foundation_payload = foundation.snapshot(instance)
    local budget_payload = budget.snapshot(instance)
    local loss_payload = loss.snapshot(instance)
    local read_revisions, revision_err = body.revision_snapshot(instance, "lower")
    if not read_revisions then
        return nil, revision_err
    end

    local measured, tension_event = packet_core.measure_tension(instance, {
        operator = "☱",
        kind = "runtime_eye_payload",
        progress = progress,
        foundation = foundation_payload,
        budget_snapshot = budget_payload,
        loss_snapshot = loss_payload,
        reconciliation = reconciliation_record,
        truth_status = "runtime_confirmed",
    })
    if not measured then
        return nil, tension_event
    end

    local scope_refs = {}
    for _, ref in ipairs(inspection.frame_refs or {}) do
        scope_refs[#scope_refs + 1] = ref
    end
    if #scope_refs == 0 then
        scope_refs[1] = "runtime:camera:head:" .. tostring(inspection.through_seq)
    end
    local source_refs = {tension_event.id}
    if reconciliation_record.trace_event_id then
        source_refs[#source_refs + 1] = reconciliation_record.trace_event_id
    end
    local observation, observation_err = body.record_observation(instance, "lower", {
        scope_refs = scope_refs,
        read_revisions = read_revisions,
        payload = {
            kind = "runtime_eye_payload",
            progress = progress,
            foundation = foundation_payload,
            budget_snapshot = budget_payload,
            loss_snapshot = loss_payload,
            reconciliation = reconciliation_record,
        },
        metrics = {
            needed_count = progress.needed_count,
            done_count = progress.done_count,
            remaining_count = progress.remaining_count,
            evidence_count = foundation_payload.evidence_count,
            pending_frame_count = inspection.pending_frame_count,
            significant_frame_count = inspection.significant_frame_count,
        },
        source_refs = source_refs,
        sensor_output_refs = source_refs,
        content_truth_status = "runtime_confirmed",
        fidelity = "body_snapshot",
    })
    if not observation then
        return nil, observation_err
    end

    return instance, {
        kind = "runtime_eye_payload",
        progress = progress,
        foundation = foundation_payload,
        budget_snapshot = budget_payload,
        loss_snapshot = loss_payload,
        reconciliation = reconciliation_record,
        runtime_camera = assert(camera.reconciliation_state(instance)),
        trace_event_id = observation.trace_event_id,
        tension_trace_event_id = tension_event.id,
        observation_id = observation.id,
        truth_status = "runtime_confirmed",
    }
end

return runtime_organ
