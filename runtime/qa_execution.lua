local digest = require("core.digest")
local packet = require("core.packet")
local qa_candidate_transaction = require("runtime.qa_candidate_transaction")
local qa_capability = require("runtime.qa_capability")
local qa_environment = require("runtime.qa_environment")
local qa_evidence = require("runtime.qa_evidence")
local qa_private_result = require("runtime.qa_private_result")
local qa_request = require("runtime.qa_request")
local repository_capability = require("runtime.repository_capability")

local execution = {
    protocol_version = "qa.body_execution.v0",
}

local function copy_value(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

local function diagnostic(code, detail)
    return {
        protocol_version = "qa.execution_diagnostic.v0",
        code = code,
        detail = detail or code,
        event_truth_status = "runtime_confirmed",
    }
end

local function loud(detail)
    error("QA execution invariant failure: " .. tostring(detail), 0)
end

local function admitted_cost(value)
    local cost = value and (value.runtime_cost or value.measured_cost) or {}
    return {
        tool_calls = cost and cost.tool_calls or 0,
        test_runs = cost and cost.qa_executions or 0,
        time_ms = cost and cost.wall_time_ms or 0,
    }
end

function execution.inspect(instance, host_services)
    if type(host_services) ~= "table" then
        return nil, diagnostic(
            "host_services_invalid",
            "QA execution host services must be table"
        )
    end
    if host_services.qa_enabled ~= true then
        return nil, diagnostic("qa_disabled", "QA body execution is disabled")
    end
    local mutable, mutable_err = packet.assert_mutable(
        instance,
        "inspect QA execution"
    )
    local actor, actor_err = packet.assert_actor_tick(
        instance,
        "☶",
        "inspect QA execution"
    )
    if not mutable or not actor
        or not instance.regime or not instance.regime.work
        or instance.regime.work.mode ~= "build" then
        return nil, diagnostic(
            "packet_not_eligible",
            mutable_err or actor_err
                or "QA execution requires a living build Packet at ☶"
        )
    end
    if type(host_services.qa_capabilities) ~= "table"
        or type(host_services.qa_environment) ~= "table" then
        return nil, diagnostic(
            "body_services_incomplete",
            "QA execution requires private capabilities and measured environment"
        )
    end
    local request, request_err = qa_request.prepare(instance, {
        qa_environment = host_services.qa_environment,
    })
    if not request then return nil, request_err end
    return {
        protocol_version = "qa.execution_readiness.v0",
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        request = copy_value(request),
        event_truth_status = "runtime_confirmed",
    }
end

local denial_keys = {
    protocol_version = true,
    denial_id = true,
    transaction_kind = true,
    transaction_id = true,
    qa_request_id = true,
    session_id = true,
    lineage_id = true,
    generation = true,
    repository_id = true,
    root_authority_id = true,
    lifecycle_id = true,
    root_fingerprint = true,
    closure_id = true,
    closure_request_id = true,
    candidate_seal_id = true,
    candidate_seal_event_ref = true,
    inventory_id = true,
    inventory_digest = true,
    inventory_bounds = true,
    code = true,
    source_acquisition = true,
    source_lease_created = true,
    provider_entry_observed = true,
    event_truth_status = true,
}

local function exact_reservation_denial(value, context)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, "QA source reservation returned no exact denial"
    end
    for key in pairs(value) do
        if not denial_keys[key] then
            return nil, "QA source denial contains unknown key: " .. tostring(key)
        end
    end
    for key in pairs(denial_keys) do
        if value[key] == nil then
            return nil, "QA source denial is missing key: " .. key
        end
    end
    local binding = context.source_binding
    local coordinate_map = {
        transaction_kind = "transaction_kind",
        transaction_id = "transaction_id",
        qa_request_id = "qa_request_id",
        session_id = "session_id",
        lineage_id = "lineage_id",
        generation = "generation",
        repository_id = "repository_id",
        root_authority_id = "root_authority_id",
        lifecycle_id = "lifecycle_id",
        root_fingerprint = "root_fingerprint",
        closure_id = "closure_id",
        closure_request_id = "closure_request_id",
        candidate_seal_id = "candidate_seal_id",
        candidate_seal_event_ref = "candidate_seal_event_ref",
        inventory_id = "inventory_id",
        inventory_digest = "inventory_digest",
    }
    for denial_key, binding_key in pairs(coordinate_map) do
        if value[denial_key] ~= binding[binding_key] then
            return nil, "QA source denial coordinate mismatch: " .. denial_key
        end
    end
    if value.protocol_version ~= "repository.qa_source_reservation_denial.v0"
        or value.transaction_kind ~= "body_execution"
        or value.code ~= "source_reservation_unavailable"
        or value.source_acquisition ~= "not_acquired"
        or value.source_lease_created ~= false
        or value.provider_entry_observed ~= false
        or value.event_truth_status ~= "runtime_confirmed" then
        return nil, "QA source denial envelope is invalid"
    end
    local seed = copy_value(value)
    seed.denial_id = nil
    local identity, identity_err = digest.record(seed)
    if not identity then return nil, identity_err end
    if value.denial_id ~= "repository-qa-source-denial:" .. identity then
        return nil, "QA source denial identity mismatch"
    end
    return true
end

local function not_acquired_pending()
    return {
        kind = "error",
        source_acquisition = "not_acquired",
        disposition = "not_acquired",
        class = "unavailable",
        code = "source_reservation_unavailable",
        stage = "preflight",
        source_stable = nil,
        process = nil,
    }
end

local function execute_private(context, environment_lease,
        environment_registry, repository_registry)
    local source_lease, source_err = repository_capability.reserve_qa_source(
        repository_registry,
        context.source_binding
    )
    local pending
    if not source_lease then
        local denial, denial_err = exact_reservation_denial(source_err, context)
        if not denial then
            return nil, "QA source reservation failed without proof: "
                .. tostring(denial_err)
        end
        pending = not_acquired_pending()
    else
        pending = qa_candidate_transaction.execute(
            repository_registry,
            source_lease,
            context.candidate_transaction_plan,
            function(consumer)
                return qa_environment.with_environment(
                    environment_registry,
                    environment_lease,
                    consumer
                )
            end
        )
    end
    if not pending then
        return nil, "QA candidate transaction returned no terminal result"
    end
    return qa_private_result.from_pending({
        request = context.request,
        request_ref = context.request_ref,
        grant_id = context.grant.grant_id,
        physical_transaction_id = context.physical_transaction_id,
        physical_witness_id = context.physical_witness_id,
        inventory_id = context.seal.inventory_id,
    }, pending)
end

local function current_outcome(instance, request)
    local current, current_err = qa_evidence.current(
        instance,
        request.candidate_seal_id,
        request.qa_contract_id
    )
    if not current then return nil, current_err end
    if #current.conflicts > 0 then
        return nil, "current QA evidence conflicts: "
            .. table.concat(current.conflicts, ",")
    end
    return current
end

function execution.execute(instance, host_services)
    local readiness, readiness_err = execution.inspect(instance, host_services)
    if not readiness then return nil, readiness_err end
    local request, request_event, request_err = qa_evidence.record_request(
        instance,
        readiness.request
    )
    if not request then loud(request_err) end
    local registry = host_services.qa_capabilities
    local current, current_err = current_outcome(instance, request)
    if not current then loud(current_err) end
    local receipt = qa_capability.find_receipt(registry, request.request_id)
    if receipt then
        if not current.check and not current.execution_failure then
            loud("private receipt exists without its body outcome")
        end
        local payload, _, effect, is_loud, join_err =
            qa_evidence.commit_execution(
                instance,
                registry,
                receipt.execution_receipt_id
            )
        if is_loud then loud(join_err) end
        if effect then return nil, effect, admitted_cost(payload) end
        return copy_value(payload), nil, admitted_cost(payload)
    elseif current.check or current.execution_failure then
        loud("body outcome exists without its private receipt")
    end

    local grant, grant_err = qa_capability.mint(
        registry,
        instance,
        request,
        request_event.id
    )
    if not grant then return nil, grant_err end
    if grant.state ~= "active" then
        loud("QA grant is terminal without a body-readable receipt: "
            .. tostring(grant.state))
    end
    local private_lease, begin_state_or_err = qa_capability.begin(
        registry,
        request.request_id,
        request_event.id
    )
    if not private_lease then loud(begin_state_or_err) end
    local private_result, private_err = qa_capability.with_execution(
        registry,
        private_lease,
        execute_private
    )
    if not private_result then loud(private_err) end
    local committed, commit_err = qa_capability.commit(
        registry,
        private_lease,
        private_result
    )
    if not committed then loud(commit_err) end
    local payload, _, effect, is_loud, join_err = qa_evidence.commit_execution(
        instance,
        registry,
        committed.execution_receipt_id
    )
    if is_loud then loud(join_err) end
    if effect then return nil, effect, admitted_cost(payload) end
    return copy_value(payload), nil, admitted_cost(payload)
end

return execution
