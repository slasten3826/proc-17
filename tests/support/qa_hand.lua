local digest = require("core.digest")
local fixture = require("tests.support.repository_hands")
local logic = require("organs.logic")
local capabilities = require("runtime.repository_capability")
local candidate_seal = require("runtime.candidate_seal")
local repository_action = require("runtime.repository_action")
local repository_intent = require("runtime.repository_intent")
local work_completion = require("runtime.work_completion")

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
        expected_supervisor_build_id = sha("supervisor"),
        runtime_build_id = sha("runtime"),
        policy_digest = sha("policy"),
        limits = qa_fixture.hard_limits(),
    }

    function adapter.probe_environment()
        state.probes = state.probes + 1
        if options.probe_error then
            return nil, copy(options.probe_error)
        end
        return copy(options.environment or qa_fixture.environment_input("probe"))
    end

    function adapter.run_lua54_test_suite(_, request)
        state.runs = state.runs + 1
        state.last_request = copy(request)
        if state.error then
            return nil, copy(state.error)
        end
        return copy(state.report)
    end

    return adapter, state
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
        budget = copy(instance.tension and instance.tension.budget),
        loss_remaining = instance.tension and instance.tension.loss_remaining,
        revisions = copy(instance.revisions),
    }
end

qa_fixture.copy = copy
qa_fixture.sha = sha

return qa_fixture
