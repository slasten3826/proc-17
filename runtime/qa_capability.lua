local candidate_seal = require("runtime.candidate_seal")
local digest = require("core.digest")
local packet = require("core.packet")
local qa_environment = require("runtime.qa_environment")
local qa_process = require("runtime.qa_process")
local qa_request = require("runtime.qa_request")
local qa_schema = require("core.qa_schema")
local repository_capability = require("runtime.repository_capability")
local repository_inventory = require("runtime.repository_inventory")

local qa_capability = {
    protocol_version = "qa.capability_registry.v0",
}

local states = setmetatable({}, {__mode = "k"})
local leases = setmetatable({}, {__mode = "k"})

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

local function diagnostic(code, detail)
    return {
        protocol_version = "qa.execution_diagnostic.v0",
        code = code,
        detail = detail or code,
        event_truth_status = "runtime_confirmed",
    }
end

local function registry_state(registry)
    local state = states[registry]
    if not state then
        return nil, "private QA capability registry required"
    end
    return state
end

local function next_revision(state)
    local revision = state.next_revision
    state.next_revision = revision + 1
    return revision
end

local function grant_projection(grant)
    return copy_value({
        protocol_version = "qa.execution_grant.v1",
        grant_id = grant.grant_id,
        session_id = grant.session_id,
        packet_id = grant.packet_id,
        lineage_id = grant.lineage_id,
        generation = grant.generation,
        process_contract_id = grant.process_contract_id,
        context = grant.context,
        stage_id = grant.stage_id,
        repository_id = grant.repository_id,
        candidate_seal_id = grant.candidate_seal_id,
        candidate_seal_event_ref = grant.candidate_seal_event_ref,
        artifact_alignment_id = grant.artifact_alignment_id,
        qa_contract_id = grant.qa_contract_id,
        check_id = grant.check_id,
        profile_id = grant.profile_id,
        environment_id = grant.environment_id,
        request_id = grant.request_id,
        request_ref = grant.request_ref,
        state = grant.state,
        revision = grant.revision,
    })
end

local function grant_identity(request, session_id, request_ref)
    return {
        protocol_version = "qa.execution_grant.v1",
        session_id = session_id,
        packet_id = request.packet_id,
        lineage_id = request.lineage_id,
        generation = request.generation,
        process_contract_id = request.process_contract_id,
        context = request.context,
        stage_id = request.stage_id,
        repository_id = request.repository_id,
        candidate_seal_id = request.candidate_seal_id,
        candidate_seal_event_ref = request.candidate_seal_event_ref,
        artifact_alignment_id = request.artifact_alignment_id,
        qa_contract_id = request.qa_contract_id,
        check_id = request.check_id,
        profile_id = request.profile_id,
        environment_id = request.environment_id,
        request_id = request.request_id,
        request_ref = request_ref,
    }
end

local function grant_matches(grant, identity)
    for key, value in pairs(identity) do
        if grant[key] ~= value then
            return false
        end
    end
    return true
end

local function verify_sealed_candidate(state, instance, request)
    local seal, seal_event, seal_err = candidate_seal.current(instance)
    if not seal then
        return nil, nil, nil, seal_err
    end
    local seal_ok, seal_validation_err = candidate_seal.validate_seal(
        instance,
        seal
    )
    if not seal_ok then
        return nil, nil, nil, seal_validation_err
    end
    if seal.candidate_seal_id ~= request.candidate_seal_id
        or seal_event.id ~= request.candidate_seal_event_ref then
        return nil, nil, nil, "QA request no longer names current seal"
    end
    local closure, closure_err = repository_capability.observe_candidate_closure(
        state.repository_registry,
        {
            root_authority_id = seal.root_authority_id,
            lifecycle_id = seal.lifecycle_id,
            request_id = seal.request_id,
        }
    )
    if not closure then
        return nil, nil, nil, closure_err
    end
    local root, root_err = repository_capability.root_authority(
        state.repository_registry,
        {root_authority_id = seal.root_authority_id}
    )
    if not root then
        return nil, nil, nil, root_err
    end
    if root.state ~= "sealed"
        or root.lineage_id ~= request.lineage_id
        or root.owner_generation ~= request.generation
        or root.repository_id ~= request.repository_id
        or root.root_fingerprint ~= seal.root_fingerprint
        or root.lifecycle_id ~= seal.lifecycle_id
        or root.closure_id ~= closure.closure_id
        or root.active_grant_count ~= 0
        or root.active_dispatch_count ~= 0
        or closure.closure_id ~= seal.authority_closure_ref
        or closure.request_id ~= seal.request_id
        or closure.root_authority_id ~= seal.root_authority_id
        or closure.lifecycle_id ~= seal.lifecycle_id
        or closure.root_fingerprint ~= seal.root_fingerprint
        or closure.inventory_id ~= seal.inventory_id
        or closure.inventory_digest ~= seal.inventory_digest
        or not repository_inventory.same(
            closure.inventory_bounds,
            seal.inventory_bounds
        ) then
        return nil, nil, nil,
            "QA candidate seal contradicts private repository finality"
    end
    return copy_value(seal), copy_value(seal_event), copy_value(closure)
end

function qa_capability.new(session_id, environment_registry, repository_registry)
    if type(session_id) ~= "string" or session_id == ""
        or #session_id > 1024 or session_id:find("[%z\1-\31\127]") then
        return nil, "QA capability session_id must be a bounded non-empty string"
    end
    if type(environment_registry) ~= "table"
        or type(repository_registry) ~= "table" then
        return nil,
            "QA capability requires private environment and repository registries"
    end
    local registry = {protocol_version = qa_capability.protocol_version}
    states[registry] = {
        session_id = session_id,
        environment_registry = environment_registry,
        repository_registry = repository_registry,
        grants = {},
        receipts = {},
        receipts_by_id = {},
        next_revision = 1,
    }
    return registry
end

function qa_capability.mint(registry, instance, request, request_ref)
    local state, state_err = registry_state(registry)
    if not state then
        return nil, diagnostic("private_registry_required", state_err)
    end
    local mutable, mutable_err = packet.assert_mutable(instance, "mint QA grant")
    if not mutable then
        return nil, diagnostic("packet_not_eligible", mutable_err)
    end
    local actor, actor_err = packet.assert_actor_tick(instance, "☶", "mint QA grant")
    if not actor then
        return nil, diagnostic("packet_not_eligible", actor_err)
    end
    if instance.session_id ~= state.session_id
        or instance.status ~= "running"
        or not instance.regime or not instance.regime.work
        or instance.regime.work.mode ~= "build" then
        return nil, diagnostic("packet_not_eligible",
            "QA grant requires one living build Packet in its own session")
    end
    local verified, verified_err = qa_request.verify(instance, request)
    if not verified then
        return nil, diagnostic("request_invalid", verified_err)
    end
    local body_request, body_event, find_err = qa_request.find(
        instance,
        request.request_id
    )
    if not body_request then
        return nil, diagnostic("request_event_absent", find_err)
    end
    if body_event.id ~= request_ref
        or body_event.operator ~= "☶"
        or body_event.truth_status ~= "runtime_confirmed"
        or not qa_schema.same(body_request, request) then
        return nil, diagnostic("request_event_ref_mismatch",
            "private mint requires the exact body request event")
    end

    local identity = grant_identity(request, state.session_id, request_ref)
    local existing = state.grants[request.request_id]
    if existing then
        if not grant_matches(existing, identity) then
            return nil, diagnostic("grant_conflict",
                "existing QA grant contradicts current request")
        end
        return grant_projection(existing)
    end

    local seal, seal_event, closure, seal_err = verify_sealed_candidate(
        state,
        instance,
        request
    )
    if not seal then
        return nil, diagnostic("candidate_not_sealed", seal_err)
    end
    local environment_lease, environment_err = qa_environment.resolve(
        state.environment_registry,
        request.environment_id,
        request.profile_id
    )
    if not environment_lease then
        return nil, diagnostic("environment_unavailable", environment_err)
    end
    local measured, measured_err = qa_environment.validate_lease(
        state.environment_registry,
        environment_lease
    )
    if not measured
        or measured.environment_id ~= request.environment_id
        or measured.profile_id ~= request.profile_id then
        return nil, diagnostic("environment_unavailable", measured_err)
    end

    local grant_digest, grant_err = digest.record(identity)
    if not grant_digest then
        return nil, diagnostic("grant_identity_invalid", grant_err)
    end
    local grant = copy_value(identity)
    grant.grant_id = "qa-grant:" .. grant_digest
    grant.state = "active"
    grant.revision = next_revision(state)
    grant.request = copy_value(request)
    grant.seal = seal
    grant.seal_event = seal_event
    grant.closure = closure
    grant.environment_lease = environment_lease
    grant.physical_transaction_id = nil
    grant.physical_witness_id = nil
    grant.execution_entered = false
    grant.pending_result = nil
    grant.pending_result_id = nil
    grant.execution_receipt = nil
    state.grants[request.request_id] = grant
    return grant_projection(grant)
end

local function source_seed(grant)
    return {
        protocol_version = "qa.body_source_transaction_seed.v0",
        transaction_kind = "body_execution",
        session_id = grant.session_id,
        lineage_id = grant.lineage_id,
        generation = grant.generation,
        repository_id = grant.repository_id,
        root_authority_id = grant.seal.root_authority_id,
        lifecycle_id = grant.seal.lifecycle_id,
        root_fingerprint = grant.seal.root_fingerprint,
        closure_id = grant.closure.closure_id,
        closure_request_id = grant.closure.request_id,
        candidate_seal_id = grant.candidate_seal_id,
        candidate_seal_event_ref = grant.candidate_seal_event_ref,
        qa_request_id = grant.request_id,
        inventory_id = grant.seal.inventory_id,
        inventory_digest = grant.seal.inventory_digest,
        inventory_bounds = copy_value(grant.seal.inventory_bounds),
    }
end

local function physical_identity(grant)
    local seed = source_seed(grant)
    local transaction_digest, transaction_err = digest.record(seed)
    if not transaction_digest then
        return nil, nil, transaction_err
    end
    local transaction_id = "qa-provider-transaction:" .. transaction_digest
    local witness_seed = {
        protocol_version = "qa.body_physical_witness_seed.v0",
        transaction_id = transaction_id,
        request_id = grant.request_id,
        profile_id = grant.profile_id,
        environment_id = grant.environment_id,
        entrypoint = copy_value(grant.request.entrypoint),
        resource_limits = copy_value(grant.request.resource_limits),
    }
    local witness_digest, witness_err = digest.record(witness_seed)
    if not witness_digest then
        return nil, nil, witness_err
    end
    return transaction_id, "qa-provider-witness:" .. witness_digest
end

local function execution_state(grant)
    return copy_value({
        protocol_version = "qa.execution_state.v1",
        grant_id = grant.grant_id,
        request_id = grant.request_id,
        request_ref = grant.request_ref,
        state = grant.state,
        revision = grant.revision,
        physical_transaction_id = grant.physical_transaction_id,
        event_truth_status = "runtime_confirmed",
    })
end

function qa_capability.begin(registry, request_id, request_ref)
    local state, state_err = registry_state(registry)
    if not state then
        return nil, diagnostic("private_registry_required", state_err)
    end
    local grant = state.grants[request_id]
    if not grant or grant.request_ref ~= request_ref then
        return nil, diagnostic("grant_absent", "exact private QA grant is absent")
    end
    if grant.state ~= "active" then
        return nil, diagnostic("grant_not_active",
            "QA execution authority was already consumed")
    end
    local measured, measured_err = qa_environment.validate_lease(
        state.environment_registry,
        grant.environment_lease
    )
    if not measured
        or measured.environment_id ~= grant.environment_id
        or measured.profile_id ~= grant.profile_id then
        return nil, diagnostic("environment_lease_stale", measured_err)
    end
    local transaction_id, witness_id, identity_err = physical_identity(grant)
    if not transaction_id then
        return nil, diagnostic("transaction_identity_invalid", identity_err)
    end

    grant.physical_transaction_id = transaction_id
    grant.physical_witness_id = witness_id
    grant.state = "running"
    grant.revision = next_revision(state)
    local lease = setmetatable({}, {
        __metatable = "qa.execution_lease.v1",
    })
    leases[lease] = {
        registry = registry,
        grant = grant,
        running_revision = grant.revision,
    }
    return lease, execution_state(grant)
end

local function execution_lease(registry, lease, allow_terminal)
    local state, state_err = registry_state(registry)
    if not state then
        return nil, nil, state_err
    end
    local retained = leases[lease]
    if not retained or retained.registry ~= registry then
        return nil, nil, "private QA execution lease required"
    end
    local grant = retained.grant
    if state.grants[grant.request_id] ~= grant then
        return nil, nil, "private QA grant identity changed"
    end
    if grant.state ~= "running" and not (allow_terminal
        and (grant.state == "completed"
            or grant.state == "consumed_failed"
            or grant.state == "quarantined")) then
        return nil, nil, "private QA execution lease is not running"
    end
    return retained, state
end

local function body_source_binding(grant)
    local seed = source_seed(grant)
    return {
        protocol_version = "repository.qa_source_binding.v1",
        transaction_kind = "body_execution",
        session_id = seed.session_id,
        lineage_id = seed.lineage_id,
        generation = seed.generation,
        repository_id = seed.repository_id,
        root_authority_id = seed.root_authority_id,
        lifecycle_id = seed.lifecycle_id,
        root_fingerprint = seed.root_fingerprint,
        closure_id = seed.closure_id,
        candidate_seal_id = seed.candidate_seal_id,
        candidate_seal_event_ref = seed.candidate_seal_event_ref,
        closure_request_id = seed.closure_request_id,
        qa_request_id = seed.qa_request_id,
        inventory_id = seed.inventory_id,
        inventory_digest = seed.inventory_digest,
        inventory_bounds = copy_value(seed.inventory_bounds),
        transaction_id = grant.physical_transaction_id,
        event_truth_status = "runtime_confirmed",
    }
end

local function native_request(grant)
    local value = {
        protocol_version = "qa.native_run_request.v1",
        operation = "run_lua54_test_suite",
        transaction_id = grant.physical_transaction_id,
        witness_id = grant.physical_witness_id,
        profile_id = grant.profile_id,
        environment_id = grant.environment_id,
        entrypoint_relative_path = grant.request.entrypoint.relative_path,
        expected_exit_code = grant.request.expected_exit_codes[1],
        resource_limits = copy_value(grant.request.resource_limits),
    }
    return assert(qa_process.normalize_request_v1(value))
end

local function candidate_transaction_plan(grant)
    return {
        protocol_version = "qa.candidate_transaction_plan.v0",
        transaction_kind = "body_execution",
        physical_transaction_id = grant.physical_transaction_id,
        physical_witness_id = grant.physical_witness_id,
        profile_id = grant.profile_id,
        environment_id = grant.environment_id,
        repository_id = grant.repository_id,
        root_authority_id = grant.seal.root_authority_id,
        lifecycle_id = grant.seal.lifecycle_id,
        root_fingerprint = grant.seal.root_fingerprint,
        closure_id = grant.closure.closure_id,
        closure_request_id = grant.closure.request_id,
        candidate_seal_id = grant.candidate_seal_id,
        candidate_seal_event_ref = grant.candidate_seal_event_ref,
        inventory_id = grant.seal.inventory_id,
        inventory_digest = grant.seal.inventory_digest,
        inventory_bounds = copy_value(grant.seal.inventory_bounds),
        native_request = native_request(grant),
    }
end

local forbidden_result_keys = {
    registry = true,
    environment_registry = true,
    repository_registry = true,
    lease = true,
    environment_lease = true,
    source_lease = true,
    adapter = true,
    provider = true,
    handle = true,
    fd = true,
    descriptor = true,
    host_path = true,
    userdata = true,
}

local function detach_result(value, forbidden, seen)
    local kind = type(value)
    if kind == "nil" or kind == "boolean" or kind == "number"
        or kind == "string" then
        return value
    end
    if kind ~= "table" or forbidden[value] or getmetatable(value) ~= nil then
        return nil, "QA execution callback returned private authority"
    end
    seen = seen or {}
    if seen[value] then
        return nil, "QA execution callback returned cyclic data"
    end
    seen[value] = true
    local result = {}
    for key, child in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            return nil, "QA execution callback returned invalid key"
        end
        if type(key) == "string" and forbidden_result_keys[key] then
            return nil, "QA execution callback returned forbidden field: " .. key
        end
        local detached, detached_err = detach_result(child, forbidden, seen)
        if detached_err then
            return nil, detached_err
        end
        result[key] = detached
    end
    seen[value] = nil
    return result
end

function qa_capability.with_execution(registry, private_lease, consumer)
    local retained, state, lease_err = execution_lease(
        registry,
        private_lease,
        false
    )
    if not retained then
        return nil, lease_err
    end
    local grant = retained.grant
    if grant.execution_entered then
        return nil, "QA execution callback was already entered"
    end
    if type(consumer) ~= "function" then
        return nil, "QA execution consumer must be function"
    end
    grant.execution_entered = true
    local context = {
        protocol_version = "qa.execution_context.v1",
        grant = grant_projection(grant),
        request = copy_value(grant.request),
        request_ref = grant.request_ref,
        seal = copy_value(grant.seal),
        closure = copy_value(grant.closure),
        physical_transaction_id = grant.physical_transaction_id,
        physical_witness_id = grant.physical_witness_id,
        source_binding = body_source_binding(grant),
        native_request = native_request(grant),
        candidate_transaction_plan = candidate_transaction_plan(grant),
        event_truth_status = "runtime_confirmed",
    }
    local returned = table.pack(pcall(
        consumer,
        copy_value(context),
        grant.environment_lease,
        state.environment_registry,
        state.repository_registry
    ))
    if returned[1] ~= true or returned[2] == nil then
        grant.state = "quarantined"
        grant.revision = next_revision(state)
        return nil, "QA execution consumer failed: "
            .. tostring(returned[1] and returned[3] or returned[2])
    end
    if returned.n > 3 then
        grant.state = "quarantined"
        grant.revision = next_revision(state)
        return nil, "QA execution consumer returned too many values"
    end
    local forbidden = {
        [registry] = true,
        [private_lease] = true,
        [grant.environment_lease] = true,
        [state.environment_registry] = true,
        [state.repository_registry] = true,
    }
    local detached, detached_err = detach_result(returned[2], forbidden)
    if not detached then
        grant.state = "quarantined"
        grant.revision = next_revision(state)
        return nil, detached_err
    end
    local result_id, result_err = digest.record(detached)
    if not result_id then
        grant.state = "quarantined"
        grant.revision = next_revision(state)
        return nil, result_err
    end
    grant.pending_result = copy_value(detached)
    grant.pending_result_id = "qa-provider-result:" .. result_id
    return copy_value(detached)
end

function qa_capability.commit(registry, private_lease, normalized_result)
    local retained, state, lease_err = execution_lease(
        registry,
        private_lease,
        true
    )
    if not retained then
        return nil, lease_err
    end
    local grant = retained.grant
    if grant.execution_receipt then
        local supplied_id = digest.record(normalized_result)
        if supplied_id and "qa-provider-result:" .. supplied_id
            == grant.pending_result_id then
            return copy_value(grant.execution_receipt)
        end
        return nil, "QA execution commit contradicts existing receipt"
    end
    if grant.state ~= "running" or not grant.execution_entered
        or not grant.pending_result then
        return nil, "QA execution result is not ready for commit"
    end
    if not qa_schema.same(normalized_result, grant.pending_result) then
        return nil, "QA execution commit changed callback result"
    end
    local result_schema = require("runtime.qa_private_result")
    local normalized, normalized_err = result_schema.normalize(
        normalized_result,
        {
            request = grant.request,
            request_ref = grant.request_ref,
            grant_id = grant.grant_id,
            physical_transaction_id = grant.physical_transaction_id,
            physical_witness_id = grant.physical_witness_id,
            inventory_id = grant.seal.inventory_id,
        }
    )
    if not normalized then
        return nil, normalized_err
    end
    if not qa_schema.same(normalized, grant.pending_result) then
        return nil, "QA execution result is not normalized"
    end
    local report = normalized.protocol_version
        == "qa.provider_candidate_report.v1"
    local source_acquisition = report and "acquired"
        or normalized.source_acquisition
    local source_disposition = report and normalized.source.disposition
        or normalized.source_disposition
    local disposition = report and "completed"
        or (source_disposition == "quarantined"
            and "quarantined" or "consumed_failed")
    local receipt = {
        protocol_version = "qa.execution_receipt.v1",
        execution_receipt_id = nil,
        request_id = grant.request_id,
        request_ref = grant.request_ref,
        grant_id = grant.grant_id,
        physical_transaction_id = grant.physical_transaction_id,
        packet_id = grant.packet_id,
        lineage_id = grant.lineage_id,
        generation = grant.generation,
        process_contract_id = grant.process_contract_id,
        context = grant.context,
        stage_id = grant.stage_id,
        repository_id = grant.repository_id,
        candidate_seal_id = grant.candidate_seal_id,
        artifact_alignment_id = grant.artifact_alignment_id,
        qa_contract_id = grant.qa_contract_id,
        check_id = grant.check_id,
        profile_id = grant.profile_id,
        environment_id = grant.environment_id,
        result_kind = report and "candidate_report" or "provider_error",
        source_acquisition = source_acquisition,
        source_disposition = source_disposition,
        normalized_result_id = grant.pending_result_id,
        transaction_disposition = disposition,
        cost = copy_value(report and normalized.cost or normalized.measured_cost),
        committed = true,
    }
    local receipt_digest, receipt_err = digest.record(receipt)
    if not receipt_digest then
        return nil, receipt_err
    end
    receipt.execution_receipt_id = "qa-execution-receipt:" .. receipt_digest
    grant.state = disposition
    grant.revision = next_revision(state)
    grant.pending_result = copy_value(normalized)
    grant.execution_receipt = copy_value(receipt)
    state.receipts[grant.request_id] = {
        receipt = copy_value(receipt),
        result = copy_value(normalized),
        grant = grant,
    }
    state.receipts_by_id[receipt.execution_receipt_id] =
        state.receipts[grant.request_id]
    return copy_value(receipt)
end

function qa_capability.quarantine(registry, private_lease, reason)
    local retained, state, lease_err = execution_lease(
        registry,
        private_lease,
        true
    )
    if not retained then
        return nil, lease_err
    end
    if type(reason) ~= "string" or reason == "" or #reason > 4096
        or reason:find("[%z\1-\31\127]") then
        return nil, "QA execution quarantine reason is invalid"
    end
    local grant = retained.grant
    if grant.state == "completed" or grant.state == "consumed_failed" then
        return nil, "committed QA execution cannot be quarantined"
    end
    if grant.state ~= "quarantined" then
        grant.state = "quarantined"
        grant.revision = next_revision(state)
        grant.quarantine_reason = reason
    end
    return execution_state(grant)
end

function qa_capability.find_receipt(registry, request_id)
    local state, state_err = registry_state(registry)
    if not state then
        return nil, state_err
    end
    local retained = state.receipts[request_id]
    if not retained then
        return nil, "QA execution receipt is absent"
    end
    return copy_value(retained.receipt)
end

function qa_capability.with_receipt(registry, execution_receipt_id, consumer)
    local state, state_err = registry_state(registry)
    if not state then
        return nil, state_err
    end
    local retained = state.receipts_by_id[execution_receipt_id]
    if not retained then
        return nil, "QA execution receipt is absent"
    end
    if type(consumer) ~= "function" then
        return nil, "QA receipt consumer must be function"
    end
    local returned = table.pack(pcall(
        consumer,
        copy_value(retained.receipt),
        copy_value(retained.result)
    ))
    if returned[1] ~= true then
        return nil, "QA receipt consumer failed: " .. tostring(returned[2])
    end
    if returned.n > 3 then
        return nil, "QA receipt consumer returned too many values"
    end
    if returned[2] == nil then
        return nil, returned[3] or "QA receipt consumer failed"
    end
    local forbidden = {
        [registry] = true,
        [state.environment_registry] = true,
        [state.repository_registry] = true,
    }
    return detach_result(returned[2], forbidden)
end

return qa_capability
