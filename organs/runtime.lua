local packet_core = require("core.packet")
local json = require("core.json")
local body = require("runtime.body")
local budget = require("runtime.budget")
local foundation = require("runtime.foundation")
local loss = require("runtime.loss")
local camera = require("runtime.camera")
local reconciliation = require("runtime.reconciliation")
local plan_completion = require("runtime.plan_completion")
local repository_inspection = require("runtime.repository_inspection")
local work_completion = require("runtime.work_completion")

local runtime_organ = {}

local function same_value(left, right)
    return json.encode(left) == json.encode(right)
end

local function plan_review(instance, options)
    options = options or {}
    local input = options.plan_completion_input
    if type(input) ~= "table" then
        return nil, "plan completion input required"
    end
    local candidate, candidate_err = plan_completion.resolve_candidate(instance, input)
    if not candidate then
        return nil, candidate_err
    end
    local existing, assessment_err = plan_completion.find_assessment(instance, candidate)
    if existing then
        return nil, "plan_completion_already_assessed"
    end
    if assessment_err ~= "plan_assessment_absent" then
        return nil, assessment_err
    end
    local inspection, inspection_err = reconciliation.inspect(instance)
    if not inspection then
        return nil, inspection_err
    end
    local scope, scope_err = plan_completion.review_scope(
        instance,
        candidate,
        inspection
    )
    if not scope then
        return nil, scope_err
    end
    if input.through_seq ~= scope.through_seq
        or not same_value(input.significant_frame_refs, scope.significant_frame_refs) then
        return nil, "plan completion runtime scope is stale"
    end
    local action_scope = options.qualified_action and options.qualified_action.scope_refs
    if action_scope ~= nil and not same_value(action_scope, scope.scope_refs) then
        return nil, "plan completion action scope mismatch"
    end
    return {
        candidate = candidate,
        inspection = inspection,
        scope = scope,
    }
end

local function repository_options(main_options, host_services)
    main_options = main_options or {}
    return {
        work_mode = main_options.work_mode,
        repository_hands = main_options.repository_hands,
        host_services = host_services,
    }
end

function runtime_organ.readiness(instance, options, host_services, main_options)
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
    options = options or {}
    local repository_context = repository_options(main_options, host_services)
    if options.repository_action_review ~= nil then
        local current, current_err = repository_inspection.validate_action_input(
            instance,
            options.repository_action_review,
            repository_context
        )
        local ready = current ~= nil and current.phase == "review_needed"
            and #(options.repository_action_review.evidence_refs or {}) == 0
        return {
            operator = "☱",
            ready = ready,
            reason = ready and "repository_action_review_ready"
                or tostring(current_err or "repository_action_not_reviewable"),
            source_refs = ready and current.route_scope_refs or {},
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    if options.repository_reconcile ~= nil then
        local completion_input, current_or_err =
            repository_inspection.reconcile_candidate(
                instance,
                options.repository_reconcile,
                repository_context
            )
        local current = completion_input and current_or_err or nil
        return {
            operator = "☱",
            ready = completion_input ~= nil,
            reason = completion_input and "repository_reconcile_ready"
                or tostring(current_or_err),
            source_refs = current and current.route_scope_refs or {},
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    if options.plan_completion_input ~= nil then
        local review, review_err = plan_review(instance, options)
        if not review then
            return {
                operator = "☱",
                ready = false,
                reason = review_err,
                source_refs = {},
                required_capabilities = {},
                missing_capabilities = {},
                event_truth_status = "runtime_confirmed",
            }
        end
        return {
            operator = "☱",
            ready = true,
            reason = "plan_completion_review_ready",
            source_refs = review.scope.scope_refs,
            pending_frame_count = review.inspection.pending_frame_count,
            significant_frame_count = review.inspection.significant_frame_count,
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

function runtime_organ.run(instance, options, host_services, main_options)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "run runtime eye")
    if not mutable then
        return nil, mutable_err
    end

    options = options or {}
    local repository_context = repository_options(main_options, host_services)
    local repository_mode
    local repository_record
    local repository_event
    local repository_view
    if options.repository_action_review ~= nil then
        local review, current_or_err = repository_inspection.review_candidate(
            instance,
            options.repository_action_review,
            repository_context
        )
        if not review then
            return nil, current_or_err
        end
        repository_view = current_or_err
        repository_record, repository_event = body.record_repository_action_review(
            instance,
            review
        )
        if not repository_record then
            return nil, repository_event
        end
        repository_mode = "repository_action_review"
    elseif options.repository_reconcile ~= nil then
        local completion_input, current_or_err =
            repository_inspection.reconcile_candidate(
                instance,
                options.repository_reconcile,
                repository_context
            )
        if not completion_input then
            return nil, current_or_err
        end
        repository_view = current_or_err
        local candidate, candidate_err = work_completion.derive(
            instance,
            completion_input
        )
        if not candidate then
            return nil, candidate_err
        end
        repository_record, repository_event = work_completion.record(
            instance,
            candidate
        )
        if not repository_record then
            return nil, repository_event
        end
        repository_mode = "repository_reconcile"
    end
    local review
    local inspection
    if options.plan_completion_input ~= nil then
        local review_err
        review, review_err = plan_review(instance, options)
        if not review then
            return nil, review_err
        end
        inspection = review.inspection
    else
        local inspection_err
        inspection, inspection_err = reconciliation.inspect(instance)
        if not inspection then
            return nil, inspection_err
        end
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

    local completion_assessment
    local assessment_event
    if review then
        local assessment_err
        completion_assessment, assessment_err = plan_completion.build_assessment(
            instance,
            review.candidate,
            reconciliation_record
        )
        if not completion_assessment then
            return nil, assessment_err
        end
        assessment_event, assessment_err = packet_core.append_event(instance, {
            type = "plan_completion_assessment",
            operator = "☱",
            truth_status = "runtime_confirmed",
            payload = completion_assessment,
            cost = {},
        })
        if not assessment_event then
            return nil, assessment_err
        end
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
        completion_assessment = completion_assessment,
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
    if assessment_event then
        source_refs[#source_refs + 1] = assessment_event.id
    end
    if repository_event then
        source_refs[#source_refs + 1] = repository_event.id
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
            completion_assessment = completion_assessment,
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

    local payload = {
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
    if review then
        payload.mode = "plan_completion_review"
        payload.completion_assessment = completion_assessment
        payload.assessment_event_id = assessment_event.id
        payload.effect_scope_refs = review.scope.scope_refs
    end
    if repository_mode then
        payload.mode = repository_mode
        payload.action_id = repository_view.action.action_id
        payload.effect_scope_refs = {table.unpack(repository_view.route_scope_refs)}
        if repository_mode == "repository_action_review" then
            payload.repository_action_review = repository_record
            payload.review_event_id = repository_event.id
        else
            payload.work_completion = repository_record
            payload.completion_event_id = repository_event.id
        end
    end
    return instance, payload
end

return runtime_organ
