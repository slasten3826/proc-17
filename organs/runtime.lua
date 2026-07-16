local packet_core = require("core.packet")
local body = require("runtime.body")
local budget = require("runtime.budget")
local foundation = require("runtime.foundation")
local loss = require("runtime.loss")

local runtime_organ = {}

function runtime_organ.readiness(instance)
    local source_refs = {}
    if instance and instance.calm and instance.calm.current ~= nil then
        source_refs[#source_refs + 1] = "calm:current"
    end
    if instance and instance.runtime and #(instance.runtime.evidence or {}) > 0 then
        source_refs[#source_refs + 1] = "runtime:evidence"
    end
    source_refs[#source_refs + 1] = "physis:budget"
    source_refs[#source_refs + 1] = "tension:loss"
    return {
        operator = "☱",
        ready = type(instance) == "table",
        reason = type(instance) == "table" and "ready" or "runtime_view_empty",
        source_refs = source_refs,
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
        truth_status = "runtime_confirmed",
    })
    if not measured then
        return nil, tension_event
    end

    local observation, observation_err = body.record_observation(instance, "lower", {
        scope_refs = {
            "calm:current",
            "runtime:evidence",
            "runtime:foundation",
            "physis:budget",
            "tension:loss",
        },
        read_revisions = read_revisions,
        payload = {
            kind = "runtime_eye_payload",
            progress = progress,
            foundation = foundation_payload,
            budget_snapshot = budget_payload,
            loss_snapshot = loss_payload,
        },
        metrics = {
            needed_count = progress.needed_count,
            done_count = progress.done_count,
            remaining_count = progress.remaining_count,
            evidence_count = foundation_payload.evidence_count,
        },
        source_refs = {tension_event.id},
        sensor_output_refs = {tension_event.id},
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
        trace_event_id = observation.trace_event_id,
        tension_trace_event_id = tension_event.id,
        observation_id = observation.id,
        truth_status = "runtime_confirmed",
    }
end

return runtime_organ
