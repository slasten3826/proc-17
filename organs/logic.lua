local packet_core = require("core.packet")
local body = require("runtime.body")
local spells = require("logic.spells")
local foundation = require("runtime.foundation")
local freshness = require("runtime.freshness")
local repository_inspection = require("runtime.repository_inspection")
local substrate_contract = require("substrates.contract")

local logic_organ = {}

local function copy_value(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

local function stamp_logic_verdict(instance, verdict, trace_event_id)
    instance.runtime = instance.runtime or {}
    instance.runtime.logic_stamp = {
        kind = "logic_stamp",
        verdict = verdict,
        evidence_fingerprint = freshness.evidence_fingerprint(instance),
        stamped_at_tick = instance.physis and instance.physis.clock
            and instance.physis.clock.ticks or nil,
        trace_event_id = trace_event_id,
        truth_status = "runtime_confirmed",
    }
    return instance.runtime.logic_stamp
end

local function record(instance, payload)
    local recorded, event_or_err = body.record_validation(instance, payload)
    if not recorded then
        return nil, event_or_err
    end
    stamp_logic_verdict(instance, recorded.status, event_or_err.id)
    return instance, recorded
end

local function exact_qa_action(value)
    if type(value) ~= "table" or getmetatable(value) ~= nil
        or value.action ~= "execute_current_candidate" then
        return nil, "QA execution requires execute_current_candidate"
    end
    for key in pairs(value) do
        if key ~= "action" then
            return nil, "QA execution action contains unknown key: "
                .. tostring(key)
        end
    end
    return true
end

local function qa_action_conflict(options)
    return options.repository_effect ~= nil
        or options.qualified_action ~= nil
        or (type(options.logic) == "table"
            and type(options.logic.spells) == "table"
            and #options.logic.spells > 0)
end

function logic_organ.readiness(instance, options, host_services)
    options = options or {}
    if options.qa_execution ~= nil then
        if qa_action_conflict(options) then
            return {
                operator = "☶",
                ready = false,
                reason = "QA execution is exclusive with other LOGIC actions",
                source_refs = {},
                required_capabilities = {},
                missing_capabilities = {},
                event_truth_status = "runtime_confirmed",
            }
        end
        local exact, exact_err = exact_qa_action(options.qa_execution)
        if not exact then
            return {
                operator = "☶",
                ready = false,
                reason = exact_err,
                source_refs = {},
                required_capabilities = {},
                missing_capabilities = {},
                event_truth_status = "runtime_confirmed",
            }
        end
        local qa_execution = require("runtime.qa_execution")
        local current, current_err = qa_execution.inspect(
            instance,
            host_services
        )
        local refs = {}
        if current and current.request then
            refs = copy_value(current.request.source_refs or {})
            refs[#refs + 1] = current.request.request_id
        end
        return {
            operator = "☶",
            ready = current ~= nil,
            reason = current and "qa_execution_ready"
                or tostring(type(current_err) == "table"
                    and current_err.code or current_err),
            source_refs = refs,
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    if options.repository_effect ~= nil and options.qualified_action ~= nil then
        local current, current_err = repository_inspection.effect_candidate(
            instance,
            options.repository_effect,
            {
                work_mode = options.work_mode,
                repository_hands = options.repository_hands,
                host_services = host_services,
            }
        )
        return {
            operator = "☶",
            ready = current ~= nil,
            reason = current and "repository_effect_ready" or tostring(current_err),
            source_refs = current and copy_value(current.route_scope_refs) or {},
            required_capabilities = {},
            missing_capabilities = {},
            event_truth_status = "runtime_confirmed",
        }
    end
    local calm = instance and instance.calm or {}
    local source_refs = {}
    if calm.current ~= nil then
        source_refs[#source_refs + 1] = "calm:current"
    end
    for index in ipairs(instance and instance.runtime and instance.runtime.evidence or {}) do
        source_refs[#source_refs + 1] = "runtime:evidence:" .. tostring(index)
    end
    return {
        operator = "☶",
        ready = calm.current ~= nil or #(calm.work_units or {}) > 0,
        reason = (calm.current ~= nil or #(calm.work_units or {}) > 0)
            and "ready" or "no_rule_or_target",
        source_refs = source_refs,
        required_capabilities = {},
        missing_capabilities = {},
        event_truth_status = "runtime_confirmed",
    }
end

function logic_organ.run(instance, options, host_services)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "run logic")
    if not mutable then
        return nil, mutable_err
    end
    options = options or {}

    if options.qa_execution ~= nil then
        if qa_action_conflict(options) then
            return nil, "QA execution is exclusive with other LOGIC actions"
        end
        local exact, exact_err = exact_qa_action(options.qa_execution)
        if not exact then return nil, exact_err end
        local qa_execution = require("runtime.qa_execution")
        local outcome, effect_or_err, effect_cost = qa_execution.execute(
            instance,
            host_services
        )
        if not outcome then
            if substrate_contract.is_effect_failure(effect_or_err) then
                return nil, effect_or_err
            end
            return nil, effect_or_err
        end
        return instance, {
            kind = "qa_execution_payload",
            mode = "qa_execution",
            outcome_kind = "check",
            request_id = outcome.request_id,
            evidence_id = outcome.qa_check_id,
            effect_cost = copy_value(effect_cost),
            truth_status = "runtime_confirmed",
        }
    end

    if options.repository_effect ~= nil then
        if options.work_mode ~= "build" then
            return nil, "repository effect requires build mode"
        end
        local repository_input = options.repository_effect
        if type(repository_input) ~= "table" or type(repository_input.action) ~= "table" then
            return nil, "repository effect input requires exact action"
        end
        local registry = host_services and host_services.repository_capabilities
        if type(registry) ~= "table" then
            return nil, "repository capability registry is required"
        end
        if options.qualified_action ~= nil then
            local current, current_err = repository_inspection.effect_candidate(
                instance,
                repository_input,
                {
                    work_mode = options.work_mode,
                    repository_hands = options.repository_hands,
                    host_services = host_services,
                }
            )
            if not current then
                return nil, current_err
            end
        end
        local repository_effect = require("runtime.repository_effect")
        local outcome, effect_err = repository_effect.execute(
            instance,
            repository_input.action,
            registry
        )
        if not outcome then
            return nil, effect_err
        end
        return record(instance, {
            kind = "logic_validation_payload",
            mode = "repository_effect",
            status = outcome.status,
            reason = outcome.reason,
            action_id = outcome.action_id,
            attempt_ref = outcome.attempt_ref,
            receipt_ref = outcome.receipt_ref,
            verification_ref = outcome.verification_ref,
            evidence_count = 1,
            effect_cost = copy_value(outcome.cost),
            effect_scope_refs = copy_value(outcome.effect_scope_refs),
            truth_status = "runtime_confirmed",
            content_truth_status = outcome.content_truth_status,
        })
    end

    if options.work_mode ~= "build" then
        return record(instance, {
            kind = "logic_validation_payload",
            status = "accepted",
            reason = "placeholder_v0",
            spell_results = {},
            evidence_count = 0,
            truth_status = "runtime_confirmed",
        })
    end

    local spell_inputs = options.logic and options.logic.spells or {}
    if type(spell_inputs) ~= "table" or #spell_inputs == 0 then
        return record(instance, {
            kind = "logic_validation_payload",
            status = "no_spell",
            reason = "build_mode_requires_spell_evidence",
            spell_results = {},
            evidence_count = 0,
            truth_status = "runtime_confirmed",
        })
    end

    local results = {}
    local status = "accepted"
    for _, configured_spell in ipairs(spell_inputs) do
        local spell_input = copy_value(configured_spell)
        if spell_input.tick == nil then
            spell_input.tick = instance.physis and instance.physis.clock
                and instance.physis.clock.ticks or nil
        end
        local result, err = spells.run(spell_input)
        if not result then
            result = {
                kind = "spell_result",
                name = spell_input.name or spell_input.kind or "invalid_spell",
                spell_kind = spell_input.kind or "invalid",
                intention_hash = spells.hash(spell_input.intention or spell_input.name or spell_input.kind),
                command_or_code = spell_input.command or spell_input.path or "",
                executed = false,
                success = false,
                reality_changed = false,
                stdout = "",
                stderr = tostring(err),
                exit_code = nil,
                truth_status = "runtime_confirmed",
            }
        end
        results[#results + 1] = result
        local reinforced, reinforce_err = foundation.reinforce(instance, result)
        if not reinforced then
            return nil, reinforce_err
        end
        if result.success ~= true then
            status = "rejected"
        end
    end

    return record(instance, {
        kind = "logic_validation_payload",
        status = status,
        spell_results = results,
        evidence_count = #results,
        foundation = foundation.snapshot(instance),
        truth_status = "runtime_confirmed",
    })
end

return logic_organ
