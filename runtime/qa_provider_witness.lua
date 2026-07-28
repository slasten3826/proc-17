local digest = require("core.digest")
local qa_schema = require("core.qa_schema")
local candidate_seal = require("runtime.candidate_seal")
local capabilities = require("runtime.repository_capability")
local repository_inventory = require("runtime.repository_inventory")

local witness = {
    protocol_version = "qa.provider_witness_runtime.v1",
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

local function same(left, right)
    return qa_schema.same(left, right)
end

local function diagnostic(code, detail)
    return {
        protocol_version = "qa.provider_witness_diagnostic.v0",
        code = code,
        detail = type(detail) == "string" and detail or code,
        event_truth_status = "runtime_confirmed",
    }
end

local function provider_transaction_id(instance, seal, event, closure)
    local seed = {
        protocol_version = "qa.provider_source_transaction_seed.v0",
        transaction_kind = "provider_witness",
        session_id = instance.session_id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        repository_id = instance.repository_id,
        root_authority_id = seal.root_authority_id,
        lifecycle_id = seal.lifecycle_id,
        root_fingerprint = seal.root_fingerprint,
        closure_id = closure.closure_id,
        closure_request_id = closure.request_id,
        candidate_seal_id = seal.candidate_seal_id,
        candidate_seal_event_ref = event.id,
        inventory_id = seal.inventory_id,
        inventory_digest = seal.inventory_digest,
        inventory_bounds = copy_value(seal.inventory_bounds),
    }
    return "qa-provider-transaction:" .. assert(digest.record(seed))
end

local function find_entrypoint(seal)
    local found
    for _, artifact in ipairs(seal.artifacts or {}) do
        if artifact.relative_path == "tests/run.lua" then
            if found then
                return nil, "provider witness entrypoint is ambiguous"
            end
            found = artifact
        end
    end
    if not found then
        return nil, "provider witness entrypoint is absent"
    end
    return found
end

local function packet_snapshot(instance)
    local value = {
        status = instance.status,
        operator = instance.operator,
        current_tick = instance.current_tick,
        trace = copy_value(instance.trace),
        revisions = copy_value(instance.revisions),
        tension = copy_value(instance.tension),
        runtime_budget = copy_value(
            instance.runtime and instance.runtime.budget or nil),
        field = copy_value(instance.field),
        death = copy_value(instance.death),
        manifest = copy_value(instance.manifest),
    }
    return assert(digest.record(value))
end

local function source_binding(plan)
    local value = plan.witness
    return {
        protocol_version = "repository.qa_source_binding.v1",
        transaction_kind = "provider_witness",
        session_id = value.session_id,
        lineage_id = value.lineage_id,
        generation = value.generation,
        repository_id = value.repository_id,
        root_authority_id = value.root_authority_id,
        lifecycle_id = value.lifecycle_id,
        root_fingerprint = value.root_fingerprint,
        closure_id = value.closure_id,
        candidate_seal_id = value.candidate_seal_id,
        candidate_seal_event_ref = value.candidate_seal_event_ref,
        closure_request_id = value.closure_request_id,
        inventory_id = value.inventory_id,
        inventory_digest = value.inventory_digest,
        inventory_bounds = copy_value(value.inventory_bounds),
        transaction_id = value.transaction_id,
        event_truth_status = "runtime_confirmed",
    }
end

local function native_request(value)
    return {
        protocol_version = "qa.native_run_request.v1",
        operation = "run_lua54_test_suite",
        transaction_id = value.transaction_id,
        witness_id = value.witness_id,
        profile_id = value.profile_id,
        environment_id = value.environment_id,
        entrypoint_relative_path = value.entrypoint.relative_path,
        expected_exit_code = value.expected_exit_codes[1],
        resource_limits = copy_value(value.resource_limits),
    }
end

local function verify_closure(seal, closure)
    return type(closure) == "table"
        and closure.closure_id == seal.authority_closure_ref
        and closure.request_id == seal.request_id
        and closure.root_authority_id == seal.root_authority_id
        and closure.lifecycle_id == seal.lifecycle_id
        and closure.root_fingerprint == seal.root_fingerprint
        and closure.inventory_id == seal.inventory_id
        and closure.inventory_digest == seal.inventory_digest
        and repository_inventory.same(
            closure.inventory_bounds, seal.inventory_bounds)
end

function witness.prepare(instance, host_services, options)
    host_services = host_services or {}
    options = options or {}
    if type(instance) ~= "table" or instance.status ~= "running"
        or type(instance.regime) ~= "table"
        or type(instance.regime.work) ~= "table"
        or instance.regime.work.mode ~= "build" then
        return nil, diagnostic("packet_not_eligible",
            "provider witness requires one living build Packet")
    end
    local registry = host_services.repository_capabilities
    local provider = host_services.repository_provider
    local process_provider = host_services.qa_provider
    if type(registry) ~= "table" or type(provider) ~= "table"
        or type(provider.inventory_tree) ~= "function"
        or provider.provider_id ~= "linux.openat2.renameat2.v0"
        or type(process_provider) ~= "table"
        or type(process_provider.run) ~= "function" then
        return nil, diagnostic("host_services_invalid")
    end
    local environment, environment_err = qa_schema.normalize_environment(
        options.environment or host_services.qa_environment)
    if not environment then
        return nil, diagnostic("environment_invalid", environment_err)
    end
    local environment_ok, normalized_err = qa_schema.verify_environment(environment)
    if not environment_ok then
        return nil, diagnostic("environment_invalid", normalized_err)
    end
    local seal, event, seal_err = candidate_seal.current(instance)
    if not seal then
        return nil, diagnostic("candidate_seal_invalid", seal_err)
    end
    local seal_ok, seal_validation_err = candidate_seal.validate_seal(instance, seal)
    if not seal_ok then
        return nil, diagnostic("candidate_seal_invalid", seal_validation_err)
    end
    local closure, closure_err = capabilities.observe_candidate_closure(registry, {
        root_authority_id = seal.root_authority_id,
        lifecycle_id = seal.lifecycle_id,
        request_id = seal.request_id,
    })
    if not closure or not verify_closure(seal, closure) then
        return nil, diagnostic("candidate_closure_invalid", closure_err)
    end
    local root, root_err = capabilities.root_authority(registry, {
        root_authority_id = seal.root_authority_id,
    })
    if not root or root.state ~= "sealed" or root.active_grant_count ~= 0
        or root.active_dispatch_count ~= 0 then
        return nil, diagnostic("candidate_root_not_terminal", root_err)
    end
    local entrypoint, entrypoint_err = find_entrypoint(seal)
    if not entrypoint then
        return nil, diagnostic("entrypoint_invalid", entrypoint_err)
    end
    local transaction_id = provider_transaction_id(instance, seal, event, closure)
    local value = {
        protocol_version = "qa.provider_witness.v0",
        witness_id = nil,
        transaction_id = nil,
        session_id = instance.session_id,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        process_contract_id = instance.process_contract_id,
        context = instance.work_context,
        stage_id = instance.stage_id,
        repository_id = instance.repository_id,
        root_authority_id = seal.root_authority_id,
        lifecycle_id = seal.lifecycle_id,
        root_fingerprint = seal.root_fingerprint,
        closure_id = closure.closure_id,
        closure_request_id = closure.request_id,
        candidate_seal_id = seal.candidate_seal_id,
        candidate_seal_event_ref = event.id,
        inventory_id = seal.inventory_id,
        inventory_digest = seal.inventory_digest,
        inventory_bounds = copy_value(seal.inventory_bounds),
        profile_id = qa_schema.profile_id,
        environment_id = environment.environment_id,
        entrypoint = {
            relative_path = entrypoint.relative_path,
            bytes = entrypoint.bytes,
            sha256 = "sha256:" .. entrypoint.sha256,
        },
        expected_exit_codes = {0},
        resource_limits = qa_schema.hard_limits(),
        event_truth_status = "runtime_confirmed",
    }
    value.witness_id = "qa-provider-witness:" .. assert(digest.record(value))
    value.transaction_id = transaction_id
    return copy_value({
        protocol_version = "qa.provider_witness_plan.v0",
        witness = value,
        environment = environment,
        binding = source_binding({witness = value}),
        native_request = native_request(value),
        event_truth_status = "runtime_confirmed",
    })
end

local function inventory_observation(provider, handle, registry, lease, value)
    local raw, provider_err = provider.inventory_tree(
        handle, copy_value(value.inventory_bounds))
    if not raw then
        return nil, provider_err or "repository inventory failed", "provider"
    end
    local root_ok, root_err = capabilities.qa_source_inventory_root_matches(
        registry, lease, raw.root_before, raw.root_after)
    if root_ok ~= true then
        return nil, root_err or "QA source inventory root changed",
            root_ok == nil and "trusted" or "identity"
    end
    local normalized, normalize_err, normalize_class =
        repository_inventory.normalize_provider_result(
        raw,
        {
            request_id = value.closure_request_id,
            root_fingerprint = value.root_fingerprint,
            inventory_bounds = value.inventory_bounds,
            root_continuity = "proven",
        }
    )
    if not normalized then
        return nil, normalize_err,
            normalize_class == "malformed" and "trusted" or normalize_class
    end
    if normalized.status ~= "observed" or not normalized.inventory then
        return nil, "QA source inventory is not an exact observation", "world"
    end
    return normalized
end

local function matches_seal(observation, value)
    local inventory = observation and observation.inventory
    return type(inventory) == "table"
        and inventory.inventory_id == value.inventory_id
        and inventory.inventory_digest == value.inventory_digest
        and repository_inventory.same(
            inventory.inventory_bounds, value.inventory_bounds)
end

local function disposition(transaction_id, state, reason)
    return {
        protocol_version = "repository.qa_source_disposition.v0",
        transaction_id = transaction_id,
        state = state,
        reason = reason,
        event_truth_status = "runtime_confirmed",
    }
end

local function report_from_pending(value, pending)
    local process = pending.process
    if pending.disposition ~= "consumed"
        or type(process) ~= "table"
        or process.protocol_version ~= "qa.provider_process_observation.v1"
        or process.cleanup_complete ~= true then
        error("QA provider witness report pending join is invalid", 0)
    end
    return {
        protocol_version = "qa.provider_witness_report.v1",
        operation = "run_lua54_test_suite",
        transaction_id = value.transaction_id,
        witness_id = value.witness_id,
        profile_id = value.profile_id,
        environment_id = value.environment_id,
        outcome = process.outcome == "expected_exit" and "accepted" or "rejected",
        reason = process.outcome,
        termination = copy_value(process.termination),
        cause = copy_value(process.cause),
        finality = copy_value(process.finality),
        source = {
            pre_inventory_id = pending.pre_inventory_id,
            post_inventory_id = pending.post_inventory_id,
            stable = true,
            disposition = "consumed",
        },
        stdout = copy_value(process.stdout),
        stderr = copy_value(process.stderr),
        resources = copy_value(process.resources),
        scratch = copy_value(process.scratch),
        cost = copy_value(process.cost),
        event_truth_status = "runtime_confirmed",
    }
end

local function process_error_projection(process)
    if process == nil then
        return "not_started", "complete", "complete", "complete", nil
    end
    if type(process) ~= "table" then
        error("QA provider witness process error evidence is invalid", 0)
    end
    if process.protocol_version == "qa.provider_process_observation.v1" then
        if process.candidate_started ~= true
            or process.cleanup_complete ~= true then
            error("QA provider witness contained process evidence is invalid", 0)
        end
        return "started", "complete", "complete", "complete", process.cost
    end
    if process.protocol_version == "qa.provider_process_error.v1" then
        return process.candidate_start_state, process.cleanup_state,
            process.launcher_reaped, process.result_eof, process.measured_cost
    end
    error("QA provider witness process protocol is not v1", 0)
end

local function error_from_pending(value, pending)
    if pending.disposition ~= "consumed"
        and pending.disposition ~= "quarantined" then
        error("QA provider witness error lacks terminal source disposition", 0)
    end
    local candidate_start_state, cleanup_state, launcher_reaped, result_eof,
        measured_cost = process_error_projection(pending.process)
    return {
        protocol_version = "qa.provider_witness_error.v1",
        transaction_id = value.transaction_id,
        witness_id = value.witness_id,
        profile_id = value.profile_id,
        environment_id = value.environment_id,
        class = pending.class,
        code = pending.code,
        stage = pending.stage,
        candidate_start_state = candidate_start_state,
        source_stable = pending.source_stable,
        source_disposition = pending.disposition,
        cleanup_state = cleanup_state,
        launcher_reaped = launcher_reaped,
        result_eof = result_eof,
        measured_cost = copy_value(measured_cost),
        event_truth_status = "runtime_confirmed",
    }
end

function witness.execute(instance, host_services, plan)
    host_services = host_services or {}
    local current, current_err = witness.prepare(instance, host_services, {
        environment = type(plan) == "table" and plan.environment or nil,
    })
    if not current then
        return nil, current_err
    end
    if not same(current, plan) then
        return nil, diagnostic("witness_plan_changed")
    end
    local registry = host_services.repository_capabilities
    local provider = host_services.repository_provider
    local process_provider = host_services.qa_provider
    local value = current.witness
    local packet_before = packet_snapshot(instance)
    local root_before = assert(capabilities.root_authority(registry, {
        root_authority_id = value.root_authority_id,
    }))
    local lease, lease_err = capabilities.reserve_qa_source(
        registry, current.binding)
    if not lease then
        return nil, lease_err
    end

    local pending, callback_err = capabilities.with_qa_source(
        registry,
        lease,
        function(handle)
            local pre, pre_err, pre_class = inventory_observation(
                provider, handle, registry, lease, value)
            if not pre then
                local trusted = pre_class == "trusted" or pre_class == "identity"
                return {
                    kind = "error",
                    disposition = trusted and "quarantined" or "consumed",
                    loud = trusted,
                    code = trusted and "trusted_inventory_contradiction"
                        or "source_preflight_unavailable",
                    class = trusted and "ambiguous" or "world",
                    stage = "preflight",
                    process = nil,
                    source_stable = false,
                    detail = pre_err,
                }
            end
            if not matches_seal(pre, value) then
                return {
                    kind = "error",
                    disposition = "consumed",
                    code = "source_preflight_mismatch",
                    class = "world",
                    stage = "preflight",
                    process = nil,
                    source_stable = true,
                }
            end
            local process, process_err = process_provider.run(
                handle, current.native_request)
            local post, post_err, post_class = inventory_observation(
                provider, handle, registry, lease, value)
            if not post or not repository_inventory.same(
                pre.inventory, post.inventory) then
                local trusted = post_class == "trusted" or post_class == "identity"
                return {
                    kind = "error",
                    disposition = "quarantined",
                    loud = trusted,
                    code = trusted and "trusted_inventory_contradiction"
                        or "source_drift",
                    class = "ambiguous",
                    stage = "postflight",
                    process = process or process_err,
                    source_stable = false,
                    detail = post_err,
                }
            end
            if process then
                return {
                    kind = "report",
                    disposition = "consumed",
                    process = process,
                    pre_inventory_id = pre.inventory.inventory_id,
                    post_inventory_id = post.inventory.inventory_id,
                }
            end
            if type(process_err) ~= "table"
                or process_err.protocol_version
                    ~= "qa.provider_process_error.v1" then
                error("QA provider returned an invalid process error", 0)
            end
            local clean = process_err.cleanup_state == "complete"
                and process_err.candidate_start_state == "not_started"
            return {
                kind = "error",
                disposition = clean and "consumed" or "quarantined",
                code = process_err.code,
                class = process_err.class,
                stage = process_err.stage,
                process = process_err,
                source_stable = true,
            }
        end
    )
    if not pending then
        local finished, finish_err = capabilities.finish_qa_source(
            registry, lease,
            disposition(value.transaction_id, "quarantined",
                "provider_witness_callback_failed"))
        if not finished then
            error("QA provider witness cleanup failed: " .. tostring(finish_err), 0)
        end
        error("QA provider witness callback failed: " .. tostring(callback_err), 0)
    end
    local finish_reason = pending.disposition == "quarantined"
        and (pending.code or "provider_witness_ambiguous")
        or nil
    local finished, finish_err = capabilities.finish_qa_source(
        registry, lease,
        disposition(value.transaction_id, pending.disposition, finish_reason))
    if not finished then
        error("QA provider witness source finality failed: " .. tostring(finish_err), 0)
    end
    if pending.loud then
        error("QA provider witness trusted contradiction after finality: "
            .. tostring(pending.detail or pending.code), 0)
    end
    local final_report
    local final_error
    if pending.kind == "report" then
        final_report = report_from_pending(value, pending)
    elseif pending.kind == "error" then
        final_error = error_from_pending(value, pending)
    else
        error("QA provider witness pending join kind is invalid", 0)
    end
    local root_after = assert(capabilities.root_authority(registry, {
        root_authority_id = value.root_authority_id,
    }))
    if packet_snapshot(instance) ~= packet_before or not same(root_after, root_before) then
        error("QA provider witness changed Packet or public root state", 0)
    end
    if final_report then
        return copy_value(final_report)
    end
    return nil, copy_value(final_error)
end

return witness
