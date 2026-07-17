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

return manifest
