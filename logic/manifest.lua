local evidence_schema = require("core.qa_evidence_schema")
local qa_evidence = require("runtime.qa_evidence")
local qa_verdict = require("runtime.qa_verdict")

local manifest = {}

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function lower(value)
    return tostring(value or ""):lower()
end

local function copy_map(source)
    local result = {}
    if type(source) ~= "table" then
        return result
    end
    for key, value in pairs(source) do
        result[key] = value
    end
    return result
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

local function extend(target, values)
    for _, value in ipairs(values or {}) do target[#target + 1] = value end
end

local function detect_code_language(text)
    local language = text:match("```([%w_+%-%.]*)[^\n]*\n")
    if language ~= nil then
        language = trim(language)
        if language == "" then
            return "unknown"
        end
        return language
    end
    return nil
end

local function has_residue_marker(text)
    local value = lower(text)
    return value:find("residue", 1, true)
        or value:find("unsupported", 1, true)
        or value:find("manifest: none", 1, true)
        or value:find("no manifest", 1, true)
        or value:find("not produced", 1, true)
        or value:find("cannot manifest", 1, true)
end

local function detect_type(text, work_mode)
    if trim(text) == "" then
        return "empty", nil
    end
    local language = detect_code_language(text)
    if language then
        return "code", language
    end
    if work_mode == "plan" then
        return "plan", nil
    end
    if has_residue_marker(text) then
        return "residue", nil
    end
    return "text", nil
end

local function compact(value)
    value = trim(value):gsub("%s+", " ")
    if #value > 180 then
        return value:sub(1, 177) .. "..."
    end
    return value
end

local function context_residue(input)
    local residue = {
        assumptions = {},
        unsupported = {},
        missing = {},
    }

    local choose_context = input.choose_context
    if type(choose_context) == "table" then
        residue.choice = {
            selected_count = choose_context.selected_count,
            not_chosen_count = choose_context.not_chosen_count,
            loss_kind = choose_context.loss_kind,
            last_choice_event = choose_context.last_choice_event,
        }
    end

    local logic_context = input.logic_context
    if type(logic_context) == "table" then
        residue.validation = {
            accepted_count = logic_context.accepted_count,
            rejected_count = logic_context.rejected_count,
            rejection_reasons = logic_context.rejection_reasons or {},
            last_validation_event = logic_context.last_validation_event,
        }
    end

    local cycle_context = input.cycle_context
    if type(cycle_context) == "table" then
        residue.cycle = {
            last_cycle_decision = cycle_context.last_cycle_decision,
            last_cycle_reasons = cycle_context.last_cycle_reasons or {},
            repeated_fingerprint = cycle_context.repeated_fingerprint,
            turn_budget_pressure = cycle_context.turn_budget_pressure,
        }
    end

    local runtime_context = input.runtime_context
    if type(runtime_context) == "table" then
        residue.runtime = {
            completion_state = runtime_context.completion_state,
            reconciliation_event = runtime_context.reconciliation_event,
            event_truth_status = runtime_context.event_truth_status,
        }
    end

    return residue
end

local function boundary_outcome(input)
    local runtime_context = input.runtime_context or {}
    local logic_context = input.logic_context or {}
    local rejected_count = tonumber(logic_context.rejected_count) or 0
    if runtime_context.completion_state == "blocked" or rejected_count > 0 then
        return "blocked"
    end
    return "complete"
end

function manifest.assemble(input)
    input = input or {}
    local response = input.substrate_result
    if type(response) ~= "table" then
        return nil, "missing_substrate_result"
    end

    local text = tostring(response.text or "")
    local output_type, language = detect_type(text, input.work_mode)
    local outcome = boundary_outcome(input)
    local sources = copy_map(input.sources)
    local residue = context_residue(input)
    residue.cause = outcome
    residue.manifest_type = output_type
    residue.manifest_outcome = outcome
    local payload = {
        kind = "manifest_payload",
        output = {
            type = output_type,
            text = text,
            language = language,
            status = outcome,
        },
        sources = sources,
        assembly = {
            rule = "deterministic_v0",
            work_mode = input.work_mode,
            substrate_truth_status = "semantic_proposal",
            input_provenance = input.input_provenance or "unknown",
            outcome = outcome,
            runtime_completion_state = input.runtime_context
                and input.runtime_context.completion_state or nil,
        },
        residue = residue,
        terminal_cause = outcome,
        truth_status = "runtime_confirmed",
    }

    payload.summary = {
        type = output_type,
        language = language,
        status = outcome,
        text_preview = compact(text),
        source_event = sources.substrate_result_event,
    }

    return payload
end

function manifest.qa_terminal_projection(instance, qa_contract_id)
    local candidate_seal_id
    for _, event in ipairs(instance and instance.trace or {}) do
        if event.type == "qa_candidate_verdict"
            and type(event.payload) == "table"
            and event.payload.qa_contract_id == qa_contract_id then
            if candidate_seal_id ~= nil
                and candidate_seal_id ~= event.payload.candidate_seal_id then
                return nil, "multiple QA terminal candidate seals"
            end
            candidate_seal_id = event.payload.candidate_seal_id
        end
    end
    if candidate_seal_id == nil then
        return nil, "qa_candidate_verdict_absent"
    end
    local verdict, verdict_event, verdict_err = qa_verdict.current(
        instance,
        candidate_seal_id,
        qa_contract_id
    )
    if not verdict then return nil, verdict_err end
    local current, current_err = qa_evidence.current(
        instance,
        verdict.candidate_seal_id,
        qa_contract_id
    )
    if not current then return nil, current_err end
    if #current.conflicts > 0 then
        return nil, "current QA evidence is contradictory: "
            .. table.concat(current.conflicts, ",")
    end
    local check = current.check
    if not check or current.execution_failure
        or current.verdict_ref ~= verdict_event.id then
        return nil, "exact current QA check and verdict are required"
    end
    local refs = {}
    extend(refs, check.source_refs)
    extend(refs, verdict.source_refs)
    extend(refs, {
        verdict.candidate_seal_id,
        verdict.candidate_seal_event_ref,
        verdict.artifact_alignment_id,
        verdict.qa_contract_id,
        check.request_id,
        current.request_ref,
        check.qa_check_id,
        current.check_ref,
        verdict.verdict_id,
        current.verdict_ref,
    })
    local mixed_content = check.content_truth_status == "mixed"
        or verdict.content_truth_status == "mixed"
    local content_truth_status = mixed_content
        and "mixed" or "runtime_confirmed"
    local projected, projection_err = evidence_schema.normalize_terminal_projection({
        protocol_version = "qa.terminal_projection.v1",
        candidate_seal_id = verdict.candidate_seal_id,
        candidate_seal_event_ref = verdict.candidate_seal_event_ref,
        artifact_alignment_id = verdict.artifact_alignment_id,
        qa_contract_id = verdict.qa_contract_id,
        profile_id = verdict.profile_id,
        environment_id = verdict.environment_id,
        request_id = check.request_id,
        request_ref = current.request_ref,
        qa_check_id = check.qa_check_id,
        qa_check_ref = current.check_ref,
        check_outcome = check.outcome,
        check_reason = check.reason,
        termination = evidence_schema.copy(check.termination),
        cause = evidence_schema.copy(check.cause),
        finality = evidence_schema.copy(check.finality),
        source = evidence_schema.copy(check.source),
        stdout = evidence_schema.copy(check.stdout),
        stderr = evidence_schema.copy(check.stderr),
        resources = evidence_schema.copy(check.resources),
        scratch = evidence_schema.copy(check.scratch),
        verdict_id = verdict.verdict_id,
        verdict_ref = current.verdict_ref,
        verdict = verdict.verdict,
        runtime_cost = evidence_schema.copy(verdict.runtime_cost),
        source_refs = sorted_unique(refs),
        event_truth_status = "runtime_confirmed",
        content_truth_status = content_truth_status,
    })
    if not projected then return nil, projection_err end
    return projected
end

function manifest.assemble_qa_terminal(instance, input)
    if type(input) ~= "table" or getmetatable(input) ~= nil then
        return nil, "QA terminal action must be a plain table"
    end
    for key in pairs(input) do
        if key ~= "action" and key ~= "qa_contract_id" then
            return nil, "QA terminal action contains unknown key: "
                .. tostring(key)
        end
    end
    if input.action ~= "project_current_candidate"
        or type(input.qa_contract_id) ~= "string"
        or input.qa_contract_id == "" then
        return nil, "QA terminal action is invalid"
    end
    local projection, projection_err = manifest.qa_terminal_projection(
        instance,
        input.qa_contract_id
    )
    if not projection then return nil, projection_err end
    local accepted = projection.verdict == "accepted"
    local cause = accepted and "complete" or "blocked"
    return {
        kind = "manifest_payload",
        mode = "qa_terminal_delivery",
        output = {
            type = "qa_terminal",
            text = "",
            status = projection.verdict,
            content_truth_status = projection.content_truth_status,
        },
        sources = {
            candidate_seal_event = projection.candidate_seal_event_ref,
            qa_request_event = projection.request_ref,
            qa_check_event = projection.qa_check_ref,
            qa_verdict_event = projection.verdict_ref,
        },
        assembly = {
            rule = "qa.terminal_projection.v1",
            work_mode = "build",
            input_provenance = "packet_state",
            outcome = projection.verdict,
            verdict_ref = projection.verdict_ref,
        },
        residue = {
            cause = cause,
            manifest_type = "qa_terminal",
            qa_verdict_id = projection.verdict_id,
            remaining_work_count = accepted and 0 or 1,
        },
        summary = {
            type = "qa_terminal",
            status = projection.verdict,
            verdict_id = projection.verdict_id,
            check_id = projection.qa_check_id,
            source_event = projection.verdict_ref,
        },
        qa_terminal_projection = projection,
        terminal_cause = cause,
        truth_status = "runtime_confirmed",
        content_truth_status = projection.content_truth_status,
        effect_scope_refs = evidence_schema.copy(projection.source_refs),
    }
end

return manifest
