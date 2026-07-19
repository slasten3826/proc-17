local carrier = require("runtime.carrier")
local completion = require("runtime.completion")
local corpse = require("runtime.corpse")
local flow_domain = require("runtime.flow_domain")
local grave = require("runtime.grave")
local lineage = require("runtime.lineage")
local lineage_budget = require("runtime.lineage_budget")
local network_ingress = require("runtime.network_ingress")
local session_memory = require("runtime.session_memory")
local tension_runner = require("runtime.tension_runner")

local lineage_runner = {
    protocol_version = "lineage.runner.in_memory.v0",
}

local PACKET_BUDGET_AXES = {
    steps = true,
    substrate_calls = true,
    prompt_tokens = true,
    completion_tokens = true,
    total_tokens = true,
    estimated_tokens = true,
    tool_calls = true,
    file_writes = true,
    test_runs = true,
    time_ms = true,
    money_units = true,
}

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

local function merge(base, overlay)
    local result = copy_value(base or {})
    for key, value in pairs(overlay or {}) do
        result[key] = copy_value(value)
    end
    return result
end

local function economic_allocation(packet_budget)
    local result = {}
    for axis, amount in pairs(packet_budget or {}) do
        if PACKET_BUDGET_AXES[axis] then
            result[axis] = amount
        end
    end
    return result
end

local function stage_error(stage, err)
    return stage .. ":" .. tostring(err)
end

local function prepare_flow(options)
    if options.flow_domain ~= nil then
        if type(options.flow_domain) ~= "table"
            or options.flow_domain.kind ~= "l1_flow_domain" then
            return nil, "invalid shared flow_domain"
        end
        return options.flow_domain
    end
    if type(options.flow_source) ~= "table" or #options.flow_source == 0 then
        return nil, "lineage runner requires flow_domain or non-empty flow_source"
    end
    return flow_domain.new(options.flow_source, options.flow_options or {})
end

local function prepare_session(options)
    if options.session ~= nil then
        if type(options.session) ~= "table" or options.session.kind ~= "proc17_session" then
            return nil, "invalid proc-17 session"
        end
        return options.session
    end
    return session_memory.create(options.session_id, {label = options.session_label})
end

local function packet_budget_for(options, generation, state)
    local value
    if type(options.packet_budget_for_generation) == "function" then
        local called, produced = pcall(
            options.packet_budget_for_generation,
            generation,
            assert(lineage.snapshot(state))
        )
        if not called then
            return nil, "packet budget policy failed: " .. tostring(produced)
        end
        value = produced
    else
        value = options.packet_budget
    end
    if type(value) ~= "table" then
        return nil, "lineage runner requires packet_budget or packet budget policy"
    end
    return copy_value(value)
end

local function grave_input(record)
    return {
        packet_id = record.packet_id,
        status = "dead",
        terminal = {
            kind = record.terminal_kind,
            cause = record.death_cause,
        },
        death = {cause = record.death_cause},
        residue = copy_value(record.residue),
        trace_tail = copy_value(record.trace_tail),
    }
end

local function sync_ledger(session, state, cursor)
    for index = cursor + 1, #state.ledger do
        local stored, stored_err = session_memory.append_lineage_event(
            session,
            state.ledger[index]
        )
        if not stored then
            return nil, stored_err
        end
    end
    return #state.ledger
end

local function append_budget_event(state, event, generation, source_refs)
    return lineage.append_event(state, {
        kind = "lineage_budget_spent",
        generation = generation,
        packet_id = state.current_packet_id,
        corpse_id = state.current_corpse_id,
        payload = event,
        source_refs = source_refs or event.source_refs,
    })
end

local function finish_report(state, report, session, cursor)
    local synced, sync_err = sync_ledger(session, state, cursor)
    if not synced then
        return nil, sync_err
    end
    report.lineage = assert(lineage.snapshot(state))
    report.session = copy_value(session)
    report.budget = assert(lineage_budget.snapshot(state.budget))
    report.final_status = state.status
    report.terminal = copy_value(state.terminal)
    return report, synced
end

local function terminate_loud(state, session, cursor, reason)
    if state and state.status ~= "complete" and state.status ~= "exhausted"
        and state.status ~= "suspended" and state.status ~= "terminated" then
        lineage.finish(state, {
            status = "terminated",
            cause = "invariant_failure",
            error = tostring(reason),
            source_refs = {},
        })
    end
    if state and session then
        sync_ledger(session, state, cursor or 0)
    end
    return nil, tostring(reason)
end

function lineage_runner.run(task, substrate, options)
    options = options or {}
    if type(task) ~= "string" or task == "" then
        return nil, "lineage runner task must be non-empty string"
    end
    if options.packet_runner_options ~= nil
        and type(options.packet_runner_options) ~= "table" then
        return nil, "packet_runner_options must be table"
    end
    if options.packet_runner_options and options.packet_runner_options.on_packet_birth ~= nil then
        return nil, "lineage runner owns on_packet_birth"
    end
    if options.packet_runner_options and options.packet_runner_options.packet_options
        and options.packet_runner_options.packet_options.id ~= nil then
        return nil, "lineage runner owns Packet identity allocation"
    end
    if options.packet_runner ~= nil and type(options.packet_runner) ~= "function" then
        return nil, "packet_runner must be function"
    end

    local domain, domain_err = prepare_flow(options)
    if not domain then
        return nil, stage_error("flow_domain", domain_err)
    end
    local session, session_err = prepare_session(options)
    if not session then
        return nil, stage_error("session", session_err)
    end
    local state, state_err = lineage.create(task, {
        lineage_id = options.lineage_id,
        id_source = options.id_source,
        session_id = session.session_id,
        work_mode = options.work_mode or "plan",
        completion_contract_id = options.completion_contract_id or "plan.v0",
        content_truth_status = options.content_truth_status,
        substrate_session_id = options.substrate_session_id,
        history_enabled = options.history_enabled == true,
        allow_recovery = options.allow_recovery ~= false,
        emergency_max_generations = options.emergency_max_generations,
        carrier = options.carrier or {},
        budget = options.lineage_budget or {},
    })
    if not state then
        return nil, stage_error("lineage", state_err)
    end
    for _, existing in ipairs(session.lineage_ids or {}) do
        if existing == state.lineage_id then
            return nil, stage_error("session", "lineage id already exists; resume is not implemented")
        end
    end
    local indexed, index_err = session_memory.append_lineage(session, state.lineage_id)
    if not indexed then
        return nil, stage_error("session", index_err)
    end

    local report = {
        kind = "lineage_runner_result",
        protocol_version = lineage_runner.protocol_version,
        lineage_id = state.lineage_id,
        session_id = session.session_id,
        generations = {},
        corpses = {},
        carriers = {},
        assessments = {},
        final_status = nil,
    }
    local ledger_cursor, initial_sync_err = sync_ledger(session, state, 0)
    if not ledger_cursor then
        return terminate_loud(state, session, 0, stage_error("session_ledger", initial_sync_err))
    end

    local ingress = {
        prompt = task,
        packet_options = {
            lineage_id = state.lineage_id,
            generation = 1,
            birth_kind = "user",
            work_mode = state.work_mode,
            metadata = {work_mode = state.work_mode},
            substrate_session_id = state.substrate_session_id,
        },
        source_refs = {state.task.task_id},
    }
    local runner = options.packet_runner or tension_runner.run

    while true do
        local next_generation = state.current_generation + 1
        local ceiling = state.policy.emergency_max_generations
        if type(ceiling) == "number" and next_generation > ceiling then
            assert(lineage.finish(state, {
                status = "suspended",
                cause = "emergency_generation_limit",
                source_refs = {state.current_corpse_id},
            }))
            local finished, finish_err = finish_report(state, report, session, ledger_cursor)
            if not finished then
                return terminate_loud(state, session, ledger_cursor, finish_err)
            end
            return state, finished
        end

        local local_budget, local_budget_err = packet_budget_for(
            options,
            next_generation,
            state
        )
        if not local_budget then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("packet_budget", local_budget_err)
            )
        end
        local allocation = economic_allocation(local_budget)
        local allocatable, allocation_err = lineage_budget.can_allocate(
            state.budget,
            allocation
        )
        if not allocatable then
            if not tostring(allocation_err):match("^lineage budget cannot allocate ") then
                return terminate_loud(
                    state,
                    session,
                    ledger_cursor,
                    stage_error("packet_budget", allocation_err)
                )
            end
            assert(lineage.finish(state, {
                status = "exhausted",
                cause = "lineage_budget_cannot_allocate",
                error = allocation_err,
                source_refs = {state.current_corpse_id},
            }))
            local finished, finish_err = finish_report(state, report, session, ledger_cursor)
            if not finished then
                return terminate_loud(state, session, ledger_cursor, finish_err)
            end
            return state, finished
        end

        local transaction, transaction_err = lineage.begin_generation(
            state,
            allocation,
            {packet_budget = local_budget}
        )
        if not transaction then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("generation", transaction_err)
            )
        end

        local inherited_graves = nil
        if state.policy.history_enabled then
            local inherited_err
            inherited_graves, inherited_err = session_memory.inherit_graves(
                session,
                {enabled = true}
            )
            if not inherited_graves then
                return terminate_loud(
                    state,
                    session,
                    ledger_cursor,
                    stage_error("history", inherited_err)
                )
            end
        end

        local packet_options = merge(
            options.packet_runner_options and options.packet_runner_options.packet_options,
            ingress.packet_options
        )
        packet_options.session_id = session.session_id
        packet_options.budget = copy_value(local_budget)
        local runner_options = merge(options.packet_runner_options, {
            work_mode = state.work_mode,
            packet_options = packet_options,
            packet_life = {
                protocol_version = "vertical_packet_life.v0",
                flow_domain = domain,
                projection_adapter = options.projection_adapter or "vertical_single.v0",
            },
            inherited_graves = inherited_graves,
        })
        local birth_committed = false
        runner_options.on_packet_birth = function(instance, receipt)
            local committed, commit_err = lineage.commit_birth(
                state,
                transaction,
                instance,
                receipt
            )
            if not committed then
                return nil, commit_err
            end
            birth_committed = true
            return true
        end

        local called, instance, life_result = pcall(
            runner,
            ingress.prompt,
            substrate,
            runner_options
        )
        if not called then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("packet_runner", instance)
            )
        end
        if not instance then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("packet_runner", life_result)
            )
        end
        if not birth_committed then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                "packet_runner did not commit generation birth"
            )
        end
        if type(instance) ~= "table" or instance.status ~= "dead" then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                "packet_runner returned non-terminal Packet"
            )
        end

        local dead, corpse_err = corpse.capture(instance, {
            trace_tail_count = options.corpse_trace_tail_count or 32,
            id_source = options.id_source,
        })
        if not dead then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("corpse", corpse_err)
            )
        end
        local corpse_ok, corpse_verify_err = corpse.verify(dead)
        if not corpse_ok then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("corpse", corpse_verify_err)
            )
        end
        local registered, register_err = lineage.register_corpse(state, dead)
        if not registered then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("corpse", register_err)
            )
        end
        local packet_indexed, packet_index_err = session_memory.append_packet(
            session,
            dead.packet_id
        )
        if not packet_indexed then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("session", packet_index_err)
            )
        end
        local grave_record, grave_err = session_memory.add_grave(
            session,
            grave_input(dead)
        )
        if not grave_record then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("grave", grave_err)
            )
        end
        assert(lineage.append_event(state, {
            kind = "grave_classified",
            generation = dead.generation,
            packet_id = dead.packet_id,
            corpse_id = dead.corpse_id,
            payload = {
                grave_kind = grave_record.grave_kind,
                death_cause = grave_record.death_cause,
            },
            source_refs = {dead.corpse_id},
        }))

        local packet_charge, packet_charge_err = lineage_budget.reconcile_packet(
            state.budget,
            dead
        )
        if not packet_charge then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("lineage_budget", packet_charge_err)
            )
        end
        assert(append_budget_event(
            state,
            packet_charge,
            dead.generation,
            {dead.corpse_id, dead.packet_id}
        ))

        local assessment, assessment_err = completion.evaluate(state, dead)
        if not assessment then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("completion", assessment_err)
            )
        end
        local assessment_event = assert(lineage.append_event(state, {
            kind = "completion_evaluated",
            generation = dead.generation,
            packet_id = dead.packet_id,
            corpse_id = dead.corpse_id,
            payload = assessment,
            source_refs = assessment.evidence_refs,
            content_truth_statuses = assessment.basis_truth_statuses,
        }))

        report.generations[#report.generations + 1] = {
            generation = dead.generation,
            packet_id = dead.packet_id,
            birth = copy_value(life_result and life_result.birth),
            life = copy_value(life_result),
            corpse_id = dead.corpse_id,
            assessment_id = assessment.assessment_id,
        }
        report.corpses[#report.corpses + 1] = copy_value(dead)
        report.assessments[#report.assessments + 1] = copy_value(assessment)

        local synced, sync_err = sync_ledger(session, state, ledger_cursor)
        if not synced then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("session_ledger", sync_err)
            )
        end
        ledger_cursor = synced

        if assessment.task_state == "complete" then
            assert(lineage.finish(state, {
                status = "complete",
                cause = "completion_contract_satisfied",
                assessment_id = assessment.assessment_id,
                final_corpse_id = dead.corpse_id,
                source_refs = {assessment_event.id, dead.corpse_id},
            }))
            local finished, finish_err = finish_report(state, report, session, ledger_cursor)
            if not finished then
                return terminate_loud(state, session, ledger_cursor, finish_err)
            end
            return state, finished
        end

        if assessment.task_state == "unsafe" then
            assert(lineage.finish(state, {
                status = "terminated",
                cause = "unsafe_terminal",
                assessment_id = assessment.assessment_id,
                source_refs = {assessment_event.id, dead.corpse_id},
            }))
            local finished, finish_err = finish_report(state, report, session, ledger_cursor)
            if not finished then
                return terminate_loud(state, session, ledger_cursor, finish_err)
            end
            return state, finished
        end

        if assessment.task_state == "unknown" then
            assert(lineage.finish(state, {
                status = "suspended",
                cause = "unknown_completion_contract",
                assessment_id = assessment.assessment_id,
                source_refs = {assessment_event.id, dead.corpse_id},
            }))
            local finished, finish_err = finish_report(state, report, session, ledger_cursor)
            if not finished then
                return terminate_loud(state, session, ledger_cursor, finish_err)
            end
            return state, finished
        end

        if assessment.task_state ~= "unfinished"
            or assessment.terminal_recoverable ~= true then
            assert(lineage.finish(state, {
                status = "suspended",
                cause = "terminal_not_recoverable",
                assessment_id = assessment.assessment_id,
                source_refs = {assessment_event.id, dead.corpse_id},
            }))
            local finished, finish_err = finish_report(state, report, session, ledger_cursor)
            if not finished then
                return terminate_loud(state, session, ledger_cursor, finish_err)
            end
            return state, finished
        end

        if state.budget.exhausted == true then
            assert(lineage.finish(state, {
                status = "exhausted",
                cause = "lineage_budget_exhausted",
                assessment_id = assessment.assessment_id,
                source_refs = {assessment_event.id, dead.corpse_id},
            }))
            local finished, finish_err = finish_report(state, report, session, ledger_cursor)
            if not finished then
                return terminate_loud(state, session, ledger_cursor, finish_err)
            end
            return state, finished
        end

        if state.policy.allow_recovery ~= true then
            assert(lineage.finish(state, {
                status = "suspended",
                cause = "recovery_disabled_by_policy",
                assessment_id = assessment.assessment_id,
                source_refs = {assessment_event.id, dead.corpse_id},
            }))
            local finished, finish_err = finish_report(state, report, session, ledger_cursor)
            if not finished then
                return terminate_loud(state, session, ledger_cursor, finish_err)
            end
            return state, finished
        end

        local recovery, recovery_err = carrier.build_recovery(
            state,
            dead,
            assessment,
            {
                max_bytes = state.policy.carrier.max_bytes,
                id_source = options.id_source,
            }
        )
        if not recovery then
            assert(lineage.finish(state, {
                status = "suspended",
                cause = recovery_err,
                assessment_id = assessment.assessment_id,
                source_refs = {assessment_event.id, dead.corpse_id},
            }))
            local finished, finish_err = finish_report(state, report, session, ledger_cursor)
            if not finished then
                return terminate_loud(state, session, ledger_cursor, finish_err)
            end
            return state, finished
        end
        local recovery_valid, recovery_verify_err = carrier.verify(recovery, {
            lineage_id = state.lineage_id,
            source_corpse_id = dead.corpse_id,
            target_generation = dead.generation + 1,
            max_bytes = state.policy.carrier.max_bytes,
        })
        if not recovery_valid then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("carrier", recovery_verify_err)
            )
        end
        local carrier_charge, carrier_charge_err = lineage_budget.charge(
            state.budget,
            "carrier:" .. recovery.carrier_id,
            {carrier_bytes = recovery.payload_bytes},
            {recovery.carrier_id, dead.corpse_id}
        )
        if not carrier_charge then
            assert(lineage.finish(state, {
                status = "exhausted",
                cause = "lineage_budget_cannot_pay_carrier",
                error = carrier_charge_err,
                source_refs = {dead.corpse_id},
            }))
            local finished, finish_err = finish_report(state, report, session, ledger_cursor)
            if not finished then
                return terminate_loud(state, session, ledger_cursor, finish_err)
            end
            return state, finished
        end
        assert(append_budget_event(
            state,
            carrier_charge,
            dead.generation,
            {recovery.carrier_id, dead.corpse_id}
        ))
        assert(lineage.append_event(state, {
            kind = "carrier_built",
            generation = dead.generation,
            packet_id = dead.packet_id,
            corpse_id = dead.corpse_id,
            carrier_id = recovery.carrier_id,
            payload = {
                carrier_hash = recovery.carrier_hash,
                payload_bytes = recovery.payload_bytes,
                target_generation = recovery.target_generation,
            },
            source_refs = recovery.source_refs,
            content_truth_statuses = {
                recovery.semantic_truth_status,
                recovery.applicability_truth_status,
            },
        }))
        local continued, continued_err = lineage.mark_continued(
            state,
            dead,
            recovery
        )
        if not continued then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("continuation", continued_err)
            )
        end
        local next_ingress, ingress_err = network_ingress.prepare(state, recovery)
        if not next_ingress then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("network_ingress", ingress_err)
            )
        end
        report.carriers[#report.carriers + 1] = copy_value(recovery)
        ingress = next_ingress

        local continuation_sync, continuation_sync_err = sync_ledger(
            session,
            state,
            ledger_cursor
        )
        if not continuation_sync then
            return terminate_loud(
                state,
                session,
                ledger_cursor,
                stage_error("session_ledger", continuation_sync_err)
            )
        end
        ledger_cursor = continuation_sync
    end
end

return lineage_runner
