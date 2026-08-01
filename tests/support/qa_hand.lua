local digest = require("core.digest")
local fixture = require("tests.support.repository_hands")
local logic = require("organs.logic")
local capabilities = require("runtime.repository_capability")
local candidate_seal = require("runtime.candidate_seal")
local repository_action = require("runtime.repository_action")
local repository_intent = require("runtime.repository_intent")
local work_completion = require("runtime.work_completion")
local qa_capability = require("runtime.qa_capability")
local qa_environment = require("runtime.qa_environment")
local qa_schema = require("core.qa_schema")
local json = require("core.json")

local qa_fixture = {}
local counter = 0

local function copy(value, seen)
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
        result[copy(key, seen)] = copy(child, seen)
    end
    return result
end

local function sha(label)
    return "sha256:" .. assert(digest.sha256("qa-fixture:" .. tostring(label)))
end

function qa_fixture.hard_limits()
    return {
        protocol_version = "qa.resource_limits.v0",
        wall_time_ms = 30000,
        cpu_time_ms = 20000,
        address_space_bytes = 268435456,
        max_processes = 1,
        max_open_files = 64,
        max_file_bytes = 16777216,
        scratch_bytes = 67108864,
        scratch_entries = 4096,
        stdout_bytes = 1048576,
        stderr_bytes = 1048576,
    }
end

function qa_fixture.environment_input(label)
    label = label or "environment"
    return {
        protocol_version = "qa.environment.v1",
        profile_id = "qa.profile.lua54_test_suite.v0",
        provider_id = "linux.qa_supervisor.lua54.v0",
        provider_build_id = sha(label .. ":provider"),
        supervisor_abi = "proc17.qa_supervisor.v0",
        supervisor_build_id = sha(label .. ":supervisor"),
        runtime_dependency_closure_id = sha(label .. ":closure"),
        runtime_name = "Lua 5.4",
        runtime_build_id = sha(label .. ":runtime"),
        runtime_heap_limit_bytes = 67108864,
        platform = "linux",
        machine_arch = "x86_64",
        kernel_identity_id = sha(label .. ":kernel"),
        isolation_feature_set_id = sha(label .. ":features"),
        isolation_policy_digest = sha(label .. ":policy"),
        hard_limits_digest = "sha256:" .. assert(digest.record(qa_fixture.hard_limits())),
        event_truth_status = "runtime_confirmed",
    }
end

function qa_fixture.contract_input(environment, options)
    options = options or {}
    local lineage_id = options.lineage_id or "lineage-qa-hand"
    local process_contract_id = options.process_contract_id or "build.only.v0"
    local stage_id = options.stage_id or ("stage:" .. lineage_id .. ":1:build")
    return {
        protocol_version = "qa.contract.v0",
        lineage_id = lineage_id,
        process_contract_id = process_contract_id,
        context = "software_task.v0",
        stage_id = stage_id,
        execution_policy = "single_required_check.v0",
        required_checks = {{
            ordinal = 1,
            required = true,
            kind = "lua54_test_suite.v0",
            profile_id = "qa.profile.lua54_test_suite.v0",
            environment_id = assert(environment.environment_id),
            entrypoint = {
                relative_path = options.entrypoint or "tests/run.lua",
                expected_kind = "regular_file",
            },
            invocation = {
                stdin = "closed",
                arguments = {},
                expected_exit_codes = {0},
            },
            resource_limits = qa_fixture.hard_limits(),
            output_policy = {
                authority = "exit_status_only",
                retain_raw_output = false,
            },
        }},
        source_refs = {"fixture:qa-policy", "fixture:qa-environment"},
        event_truth_status = "runtime_confirmed",
        content_truth_status = "runtime_confirmed",
    }
end

function qa_fixture.native_adapter(options)
    options = options or {}
    local measured_environment = copy(
        options.environment or qa_fixture.environment_input("probe")
    )
    local state = {
        probes = 0,
        runs = 0,
        report = copy(options.report),
        error = copy(options.error),
    }
    local adapter = {
        protocol_version = "qa.native_launcher.v0",
        abi_version = "proc17.qa.launcher.lua54.v0",
        provider_id = "linux.qa_supervisor.lua54.v0",
        supervisor_abi = "proc17.qa_supervisor.v0",
        expected_supervisor_build_id = measured_environment.supervisor_build_id,
        runtime_build_id = measured_environment.runtime_build_id,
        policy_digest = measured_environment.isolation_policy_digest,
        limits = qa_fixture.hard_limits(),
    }

    function adapter.probe_environment()
        state.probes = state.probes + 1
        if options.probe_error then
            return nil, copy(options.probe_error)
        end
        return copy(measured_environment)
    end

    local function stream(limit)
        return {
            protocol_version = "qa.stream_measurement.v1",
            observed_bytes = 0,
            hashed_bytes = 0,
            sha256 = "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
            limit_bytes = limit,
            limit_reached = false,
            eof_observed = true,
            raw_retained = false,
        }
    end

    local function default_report(request)
        local limits = qa_fixture.hard_limits()
        local reason = options.reason or "expected_exit"
        local exit_code = reason == "expected_exit" and 0
            or (options.exit_code or 70)
        local termination_kind = options.termination_kind or "exit"
        local termination = {kind = termination_kind}
        if termination_kind == "exit" then
            termination.exit_code = exit_code
        elseif termination_kind == "signal" then
            termination.signal = options.signal or 9
        end
        return {
            protocol_version = "qa.provider_process_observation.v1",
            operation = "run_lua54_test_suite",
            transaction_id = request.transaction_id,
            witness_id = request.witness_id,
            profile_id = request.profile_id,
            environment_id = request.environment_id,
            outcome = reason,
            candidate_started = true,
            source_staging_policy = "qa.source_staging.detached_mount.v0",
            source_staging_complete = true,
            termination = termination,
            cause = {
                protocol_version = "qa.first_cause.v1",
                kind = reason,
                monotonic_sequence = 1,
                observed_value = termination.exit_code
                    or termination.signal or 0,
            },
            finality = {
                source_staging_complete = true,
                candidate_started = true,
                candidate_terminal_observed = true,
                process_tree_reaped = true,
                stdout_eof_observed = true,
                stderr_eof_observed = true,
                scratch_observation_complete = true,
                namespace_cleanup_complete = true,
            },
            stdout = stream(limits.stdout_bytes),
            stderr = stream(limits.stderr_bytes),
            resources = {
                protocol_version = "qa.resource_measurement.v1",
                wall_time_ms = options.wall_time_ms or 2,
                cpu_user_ms = 1,
                cpu_system_ms = 1,
                max_rss_bytes = 4096,
                address_space_limit_bytes = limits.address_space_bytes,
                runtime_heap_peak_bytes = 1024,
                runtime_heap_limit_bytes = qa_schema.runtime_heap_limit_bytes,
                runtime_heap_denied = false,
                max_processes = limits.max_processes,
                max_open_files = limits.max_open_files,
                max_file_bytes = limits.max_file_bytes,
            },
            scratch = {
                protocol_version = "qa.scratch_measurement.v1",
                stored_regular_bytes = 0,
                stored_entries = 0,
                limit_bytes = limits.scratch_bytes,
                limit_entries = limits.scratch_entries,
                byte_capacity_exhausted = false,
                entry_capacity_exhausted = false,
                inventory_complete = true,
            },
            cleanup_complete = true,
            cost = {
                protocol_version = "qa.cost.v1",
                tool_calls = 1,
                qa_executions = 1,
                wall_time_ms = options.wall_time_ms or 2,
                cpu_time_ms = 2,
                scratch_written_bytes = 0,
                stdout_observed_bytes = 0,
                stderr_observed_bytes = 0,
            },
            event_truth_status = "runtime_confirmed",
        }
    end

    function adapter.run(_, request)
        state.runs = state.runs + 1
        state.last_request = copy(request)
        if options.run_error then
            error(options.run_error, 0)
        end
        if options.error_code then
            return nil, {
                protocol_version = "qa.provider_process_error.v1",
                operation = "run_lua54_test_suite",
                transaction_id = request.transaction_id,
                witness_id = request.witness_id,
                profile_id = request.profile_id,
                environment_id = request.environment_id,
                class = options.error_class or "unavailable",
                code = options.error_code,
                stage = options.error_stage or "preflight",
                candidate_start_state = options.candidate_start_state
                    or "not_started",
                cleanup_state = options.cleanup_state or "complete",
                launcher_reaped = options.launcher_reaped or "complete",
                result_eof = options.result_eof or "complete",
                measured_cost = copy(options.measured_cost),
                event_truth_status = "runtime_confirmed",
            }
        end
        if state.error then
            return nil, copy(state.error)
        end
        return copy(state.report or default_report(request))
    end

    adapter.run_lua54_test_suite = adapter.run

    return adapter, state
end

function qa_fixture.grow_body(options)
    options = options or {}
    counter = counter + 1
    local label = options.label or ("qa-body-" .. tostring(counter))
    local session_id = options.session_id or ("session-" .. label)
    local lineage_id = options.lineage_id or ("lineage-" .. label)
    local stage_id = options.stage_id or ("stage:" .. lineage_id .. ":1:build")
    local environment_input = copy(
        options.environment or qa_fixture.environment_input(label)
    )
    local adapter_options = copy(options.adapter_options or {})
    adapter_options.environment = environment_input
    local adapter, adapter_state = qa_fixture.native_adapter(adapter_options)
    local environment_registry = assert(qa_environment.new(session_id, adapter))
    local environment = assert(qa_environment.probe(environment_registry))
    local contract = assert(qa_schema.normalize_contract(
        qa_fixture.contract_input(environment, {
            lineage_id = lineage_id,
            stage_id = stage_id,
            process_contract_id = options.process_contract_id,
            entrypoint = options.entrypoint,
        })
    ))
    local grown = qa_fixture.grow_sealed({
        label = label,
        session_id = session_id,
        lineage_id = lineage_id,
        repository_id = options.repository_id,
        process_contract_id = contract.process_contract_id,
        stage_id = stage_id,
        qa_contract = contract,
        items = options.items,
        provider_options = options.provider_options,
    })
    local qa_registry = assert(qa_capability.new(
        session_id,
        environment_registry,
        grown.repository_registry
    ))
    grown.qa_adapter = adapter
    grown.qa_adapter_state = adapter_state
    grown.qa_environment_registry = environment_registry
    grown.qa_environment = environment
    grown.qa_contract = contract
    grown.qa_registry = qa_registry
    grown.body_services = {
        qa_enabled = options.qa_enabled ~= false,
        qa_capabilities = qa_registry,
        qa_environment = copy(environment),
    }
    return grown
end

function qa_fixture.grow_sealed(options)
    options = options or {}
    counter = counter + 1
    local label = options.label or ("qa-sealed-" .. tostring(counter))
    local lineage_id = options.lineage_id or ("lineage-" .. label)
    local session_id = options.session_id or "session-qa-hand"
    local repository_id = options.repository_id or ("repo-" .. label)
    local packet_options = copy(options.packet_options or {})
    packet_options.session_id = session_id
    packet_options.lineage_id = lineage_id
    packet_options.repository_id = repository_id
    packet_options.work_mode = "build"
    packet_options.process_contract_id = options.process_contract_id or "build.only.v0"
    packet_options.stage_id = options.stage_id or ("stage:" .. lineage_id .. ":1:build")
    if options.qa_contract then
        packet_options.qa_contract = copy(options.qa_contract)
    end

    local instance = fixture.packet(options.items or {{
        path = "tests/run.lua",
        content = "return true\n",
    }}, {
        label = label,
        session_id = session_id,
        lineage_id = lineage_id,
        repository_id = repository_id,
        packet_options = packet_options,
    })
    local intent = assert(repository_intent.derive(instance, {
        max_items = instance.regime.encoding.bounds.max_output_units,
    }))
    local registry, grant, provider, state = fixture.new_registry(capabilities, {
        session_id = session_id,
        grant = {
            lineage_id = lineage_id,
            repository_id = repository_id,
            repository_path = repository_id,
            bounds = {
                max_relative_path_bytes = 128,
                max_content_bytes = 4096,
                max_effects_per_generation = 8,
            },
            policy = {file_mode = 384},
        },
        provider_options = options.provider_options,
    })
    local action = assert(repository_action.authorize(instance, intent, registry, {
        session_id = instance.session_id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        repository_id = instance.repository_id,
        work_mode = "build",
    }))
    fixture.move_to(instance, "☶")
    local _, validation = assert(logic.run(instance, {
        work_mode = "build",
        repository_effect = {action = action},
    }, {repository_capabilities = registry}))
    fixture.move_to(instance, "☱")
    assert(work_completion.record(instance, assert(work_completion.derive(instance, {
        action = action,
        attempt_ref = validation.attempt_ref,
        receipt_ref = validation.receipt_ref,
        verification_ref = validation.verification_ref,
        validation_ref = validation.trace_event_id,
    }))))
    local services = {repository_capabilities = registry}
    local seal_request = assert(candidate_seal.prepare(instance, services))
    fixture.move_to(instance, "☶")
    local sealed = assert(candidate_seal.execute(instance, seal_request, services))
    return {
        instance = instance,
        repository_registry = registry,
        repository_grant = grant,
        repository_provider = provider,
        repository_state = state,
        action = action,
        seal = sealed.seal,
        seal_event = sealed.event,
        closure = sealed.closure,
        services = services,
    }
end

function qa_fixture.events(instance, event_type)
    local result = {}
    for _, event in ipairs(instance and instance.trace or {}) do
        if event.type == event_type then
            result[#result + 1] = copy(event)
        end
    end
    return result
end

function qa_fixture.snapshot(instance)
    return {
        trace_count = #(instance.trace or {}),
        budget = copy(instance.physis and instance.physis.budget),
        loss_remaining = instance.tension and instance.tension.loss_remaining,
        revisions = copy(instance.revisions),
    }
end

function qa_fixture.run_alignment_split_case()
    local execution = require("runtime.qa_execution")
    local grown = qa_fixture.grow_body({label = "qa-alignment-split"})
    local original_commit = qa_capability.commit
    local mutated = false
    qa_capability.commit = function(...)
        local receipt, receipt_err = original_commit(...)
        if receipt and not mutated then
            local artifact = assert(grown.seal.artifacts[1])
            local unit = assert(
                grown.instance.field.units[artifact.work_unit_id]
            )
            unit.version = unit.version + 1
            mutated = true
        end
        return receipt, receipt_err
    end
    local ok, value = pcall(
        execution.execute,
        grown.instance,
        grown.body_services
    )
    qa_capability.commit = original_commit
    return {
        loud = not ok,
        detail = value,
        check_count = #qa_fixture.events(grown.instance, "qa_check"),
        failure_count = #qa_fixture.events(
            grown.instance,
            "qa_execution_failure"
        ),
        qa_runs = grown.qa_adapter_state.runs,
        alignment_mutated = mutated,
    }
end

function qa_fixture.run_timeout_cleanup_pair()
    local execution = require("runtime.qa_execution")
    local timeout = qa_fixture.grow_body({
        label = "qa-contained-timeout",
        adapter_options = {
            reason = "wall_timeout",
            termination_kind = "supervisor_kill",
        },
    })
    assert(execution.execute(timeout.instance, timeout.body_services))
    local cleanup = qa_fixture.grow_body({
        label = "qa-cleanup-ambiguity",
        adapter_options = {
            error_code = "namespace_cleanup_incomplete",
            error_class = "ambiguous",
            error_stage = "cleanup",
            candidate_start_state = "started",
            cleanup_state = "incomplete",
            launcher_reaped = "complete",
            result_eof = "complete",
        },
    })
    local cleanup_outcome, cleanup_effect = execution.execute(
        cleanup.instance,
        cleanup.body_services
    )
    return {
        timeout = {
            check_outcome = qa_fixture.events(
                timeout.instance,
                "qa_check"
            )[1].payload.outcome,
            execution_failure = qa_fixture.events(
                timeout.instance,
                "qa_execution_failure"
            )[1],
        },
        cleanup = {
            outcome = cleanup_outcome,
            effect = cleanup_effect,
            check = qa_fixture.events(cleanup.instance, "qa_check")[1],
            execution_failure = qa_fixture.events(
                cleanup.instance,
                "qa_execution_failure"
            )[1].payload,
        },
    }
end

function qa_fixture.run_qa_execution_tick(options)
    options = options or {}
    local tension_runner = require("runtime.tension_runner")
    local grown = qa_fixture.grow_body(options)
    qa_fixture.move_to(grown.instance, "☱")
    qa_fixture.move_to(grown.instance, "☶")
    local spent_before = copy(grown.instance.runtime.budget.spent or {})
    local loss_before = grown.instance.tension.loss_remaining
    local instance, result = assert(tension_runner.execute_qa_tick(
        grown.instance,
        grown.body_services
    ))
    local spent_after = instance.runtime.budget.spent or {}
    return {
        instance = instance,
        result = result,
        grown = grown,
        qa_runs = grown.qa_adapter_state.runs,
        step_delta = (spent_after.steps or 0) - (spent_before.steps or 0),
        test_run_delta = (spent_after.test_runs or 0)
            - (spent_before.test_runs or 0),
        tool_call_delta = (spent_after.tool_calls or 0)
            - (spent_before.tool_calls or 0),
        loss_delta = grown.instance.tension.loss_remaining - loss_before,
    }
end

local function first_event(instance, event_type)
    for index, event in ipairs(instance and instance.trace or {}) do
        if event.type == event_type then return event, index end
    end
    return nil
end

function qa_fixture.grow_terminal_qa_life(options)
    options = options or {}
    local packet_core = require("core.packet")
    local budget = require("runtime.budget")
    local corpse_module = require("runtime.corpse")
    local operator_registry = require("runtime.operator_registry")
    local tension_runner = require("runtime.tension_runner")

    local execution = assert(qa_fixture.run_qa_execution_tick(options))
    local grown = execution.grown
    qa_fixture.move_to(grown.instance, "☱")
    assert(tension_runner.execute_qa_verdict_tick(
        grown.instance,
        grown.qa_contract.qa_contract_id
    ))
    local verdict_event, verdict_index = assert(first_event(
        grown.instance,
        "qa_candidate_verdict"
    ))
    local check_event = assert(first_event(grown.instance, "qa_check"))

    for index = 1, (options.tail_events or 0) do
        assert(packet_core.append_trace(grown.instance, {
            type = "tension_measure",
            operator = "☱",
            truth_status = "runtime_confirmed",
            payload = {
                kind = "qa_terminal_retention_padding",
                ordinal = index,
                source_ref = verdict_event.id,
            },
            cost = {},
        }))
    end

    assert(packet_core.commit_transition(grown.instance, {
        from = "☱",
        to = "△",
        reason = "qa_terminal_fixture_boundary",
        authority = "harness_override",
    }))
    assert(packet_core.begin_tick(grown.instance, "△", {}))
    local tick_lease = assert(packet_core.assert_actor_tick(
        grown.instance,
        "△",
        "grow terminal QA fixture"
    ))
    local context = {
        options = {work_mode = "build"},
        manifest = {
            qa_terminal = {
                action = "project_current_candidate",
                qa_contract_id = grown.qa_contract.qa_contract_id,
            },
        },
        result = {ticks = {}},
    }
    local terminal_execution = assert(operator_registry.execute(
        "△",
        grown.instance,
        context
    ))
    assert(terminal_execution.status == "applied")
    assert(budget.charge(grown.instance, {
        operator = "△",
        event_id = tick_lease.id,
        cost = {steps = 1},
        source = "body_tick",
        truth_status = "runtime_confirmed",
    }))
    assert(packet_core.manifest_packet(
        grown.instance,
        terminal_execution.payload
    ))
    local record = assert(corpse_module.capture(grown.instance, {
        corpse_id = "corpse:" .. grown.instance.id .. ":qa-terminal",
        trace_tail_count = 32,
    }))
    assert(corpse_module.verify(record))
    local distance = #grown.instance.trace - verdict_index
    return {
        instance = grown.instance,
        grown = grown,
        terminal = terminal_execution.payload,
        check = copy(check_event.payload),
        verdict = copy(verdict_event.payload),
        corpse_record = record,
        corpse = {
            record = record,
            qa = {
                check_id = record.qa_evidence.check.qa_check_id,
                verdict_id = record.qa_evidence.verdict.verdict_id,
            },
        },
        qa_event_distance_from_tail = distance,
    }
end

function qa_fixture.grow_qa_descendant()
    local carrier = require("runtime.carrier")
    local lineage = require("runtime.lineage")
    local network_ingress = require("runtime.network_ingress")
    local packet_core = require("core.packet")
    local qa_evidence = require("runtime.qa_evidence")

    local ancestor = assert(qa_fixture.grow_terminal_qa_life({
        label = "qa-historical-descendant",
        adapter_options = {reason = "unexpected_exit", exit_code = 70},
    }))
    local dead = ancestor.corpse_record
    local state = assert(lineage.create("replace rejected candidate", {
        lineage_id = dead.lineage_id,
        session_id = "session-qa-historical-descendant",
        work_mode = "build",
        completion_contract_id = "software.create.v0",
        carrier = {max_bytes = 1048576},
        budget = {
            steps = 100,
            generations = 4,
            carrier_bytes = 1048576,
        },
    }))
    state.status = "evaluating_terminal"
    state.current_generation = dead.generation
    state.current_packet_id = dead.packet_id
    state.current_corpse_id = dead.corpse_id
    local assessment = {
        kind = "lineage_completion_assessment",
        assessment_id = "assessment:" .. dead.corpse_hash,
        task_state = "unfinished",
        terminal_recoverable = true,
        terminal_recovery_basis = "qa_rejected",
        remaining_work = {count = 1},
    }
    local record = assert(carrier.build_recovery(state, dead, assessment, {
        carrier_id = "carrier:" .. dead.corpse_id .. ":qa-recovery",
        max_bytes = 1048576,
    }))
    assert(lineage.mark_continued(state, dead, record))
    local ingress = assert(network_ingress.prepare(state, record, {
        max_bytes = 1048576,
    }))
    local descendant = packet_core.new(ingress.prompt, ingress.packet_options)
    local current = assert(qa_evidence.current(
        descendant,
        ancestor.verdict.candidate_seal_id,
        ancestor.verdict.qa_contract_id
    ))
    local current_check_count = current.check and 1 or 0
    local history = assert(ingress.carrier.payload.qa_history)
    return {
        ancestor = ancestor,
        carrier = record,
        ingress = ingress,
        descendant = descendant,
        descendant_current_check_count = current_check_count,
        historical_verdict_id = history.qa_evidence.verdict.verdict_id,
        ancestor_verdict_id = ancestor.verdict.verdict_id,
        applicability_truth_status = history.applicability_truth_status,
    }
end

function qa_fixture.run_repeated_body_campaign()
    local stream, stream_err = io.popen(
        "lua tests/run_qa_body_repeated_residue_campaign.lua 2>&1",
        "r"
    )
    if not stream then return nil, stream_err end
    local output = stream:read("*a")
    local closed, why, code = stream:close()
    if closed ~= true or (code ~= nil and code ~= 0) then
        return nil, "body residue campaign failed: " .. tostring(why)
            .. ":" .. tostring(code) .. "\n" .. output
    end
    local encoded = output:match("PROC17_QA_BODY_RESIDUE_V0 ([^\n]+)")
    if not encoded then
        return nil, "body residue campaign emitted no result\n" .. output
    end
    return json.decode(encoded)
end

function qa_fixture.move_to(instance, operator)
    fixture.move_to(instance, operator)
    return instance
end

qa_fixture.copy = copy
qa_fixture.sha = sha

return qa_fixture
