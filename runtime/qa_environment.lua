local digest = require("core.digest")
local qa_schema = require("core.qa_schema")

local qa_environment = {
    protocol_version = "qa.environment_registry.v0",
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
        protocol_version = "qa.environment_diagnostic.v0",
        code = code,
        detail = type(detail) == "string" and detail or code,
        event_truth_status = "runtime_confirmed",
    }
end

local function registry_state(registry)
    local state = states[registry]
    if not state then
        return nil, "private QA environment registry required"
    end
    return state
end

local function public_state(record)
    return {
        protocol_version = "qa.environment_state.v0",
        environment_id = record.public_projection.environment_id,
        profile_id = record.public_projection.profile_id,
        provider_id = record.public_projection.provider_id,
        state = record.state,
        revision = record.revision,
        quarantine_reason = record.quarantine_reason,
        event_truth_status = "runtime_confirmed",
    }
end

function qa_environment.new(session_id, native_adapter)
    if type(session_id) ~= "string" or session_id == ""
        or #session_id > 1024 or session_id:find("[%z\1-\31\127]") then
        return nil, "QA environment session_id must be a bounded non-empty string"
    end
    local probe_function = type(native_adapter) == "table"
        and (native_adapter.probe_environment or native_adapter.probe)
    if type(native_adapter) ~= "table"
        or type(probe_function) ~= "function" then
        return nil, "QA environment native adapter is invalid"
    end
    if native_adapter.provider_id ~= qa_schema.provider_id
        or native_adapter.supervisor_abi ~= qa_schema.supervisor_abi then
        return nil, "QA environment native adapter identity mismatch"
    end
    local registry = {protocol_version = qa_environment.protocol_version}
    states[registry] = {
        session_id = session_id,
        native_adapter = native_adapter,
        probe_function = probe_function,
        record = nil,
        revision = 0,
        next_lease = 1,
        last_diagnostic = nil,
    }
    return registry
end

function qa_environment.probe(registry)
    local state, state_err = registry_state(registry)
    if not state then
        return nil, diagnostic("private_registry_required", state_err)
    end
    if state.record then
        if state.record.state == "available" then
            return copy_value(state.record.public_projection)
        end
        return nil, diagnostic(
            state.record.state == "quarantined"
                and "environment_quarantined" or "environment_unavailable",
            state.record.quarantine_reason
        )
    end

    local returned = table.pack(pcall(state.probe_function))
    if returned[1] ~= true then
        state.revision = state.revision + 1
        state.last_diagnostic = diagnostic("environment_probe_invariant_failure",
            tostring(returned[2]))
        return nil, copy_value(state.last_diagnostic)
    end
    local observed, probe_error = returned[2], returned[3]
    if observed == nil then
        state.revision = state.revision + 1
        local code = type(probe_error) == "table" and probe_error.code
            or "environment_probe_unavailable"
        local detail = type(probe_error) == "table"
            and (probe_error.diagnostic or probe_error.detail or probe_error.message)
            or tostring(probe_error or code)
        state.last_diagnostic = diagnostic(code, detail)
        return nil, copy_value(state.last_diagnostic)
    end

    local normalized, normalized_err = qa_schema.normalize_environment(observed)
    if not normalized then
        state.revision = state.revision + 1
        state.last_diagnostic = diagnostic("environment_probe_invalid", normalized_err)
        return nil, copy_value(state.last_diagnostic)
    end
    state.revision = state.revision + 1
    state.record = {
        public_projection = copy_value(normalized),
        native_adapter = state.native_adapter,
        supervisor_identity = normalized.supervisor_build_id,
        runtime_identity = normalized.runtime_build_id,
        isolation_policy = normalized.isolation_policy_digest,
        hard_limits = qa_schema.hard_limits(),
        state = "available",
        revision = state.revision,
        quarantine_reason = nil,
    }
    return copy_value(normalized)
end

function qa_environment.inspect(registry, environment_id)
    local state, state_err = registry_state(registry)
    if not state then
        return nil, state_err
    end
    if type(environment_id) ~= "string" or environment_id == "" then
        return nil, "QA environment_id is required"
    end
    if not state.record
        or state.record.public_projection.environment_id ~= environment_id then
        return nil, "QA environment not found"
    end
    return copy_value(public_state(state.record))
end

function qa_environment.resolve(registry, environment_id, profile_id)
    local state, state_err = registry_state(registry)
    if not state then
        return nil, state_err
    end
    local record = state.record
    if not record or record.public_projection.environment_id ~= environment_id then
        return nil, "QA environment not found"
    end
    if profile_id ~= qa_schema.profile_id
        or record.public_projection.profile_id ~= profile_id then
        return nil, "QA environment profile mismatch"
    end
    if record.state ~= "available" then
        return nil, "QA environment is " .. tostring(record.state)
    end
    local lease_digest, lease_err = digest.record({
        session_id = state.session_id,
        environment_id = environment_id,
        profile_id = profile_id,
        revision = record.revision,
        serial = state.next_lease,
    })
    if not lease_digest then
        return nil, lease_err
    end
    state.next_lease = state.next_lease + 1
    local lease = {
        protocol_version = "qa.environment_lease.v0",
        lease_id = "qa-environment-lease:" .. lease_digest,
        environment_id = environment_id,
        profile_id = profile_id,
    }
    leases[lease] = {
        registry = registry,
        record = record,
        revision = record.revision,
    }
    return lease
end

local function lease_state(registry, lease)
    local state, state_err = registry_state(registry)
    if not state then
        return nil, diagnostic("private_registry_required", state_err)
    end
    local retained = leases[lease]
    if not retained or retained.registry ~= registry then
        return nil, diagnostic("environment_lease_invalid",
            "exact private QA environment lease required")
    end
    local record = retained.record
    local projection = record and record.public_projection
    local adapter = record and record.native_adapter
    if state.record ~= record or record.revision ~= retained.revision
        or record.state ~= "available"
        or type(projection) ~= "table"
        or projection.environment_id ~= lease.environment_id
        or projection.profile_id ~= lease.profile_id
        or projection.profile_id ~= qa_schema.profile_id
        or projection.provider_id ~= qa_schema.provider_id
        or projection.supervisor_abi ~= qa_schema.supervisor_abi
        or adapter ~= state.native_adapter
        or type(adapter) ~= "table"
        or adapter.provider_id ~= projection.provider_id
        or adapter.supervisor_abi ~= projection.supervisor_abi
        or type(adapter.run) ~= "function" then
        return nil, diagnostic("environment_lease_stale",
            "measured QA environment lease no longer names one exact provider")
    end
    if adapter.expected_supervisor_build_id ~= nil
        and adapter.expected_supervisor_build_id
            ~= projection.supervisor_build_id then
        return nil, diagnostic("environment_lease_stale",
            "QA supervisor identity changed after measurement")
    end
    if adapter.runtime_build_id ~= nil
        and adapter.runtime_build_id ~= projection.runtime_build_id then
        return nil, diagnostic("environment_lease_stale",
            "QA runtime identity changed after measurement")
    end
    if adapter.policy_digest ~= nil
        and adapter.policy_digest ~= projection.isolation_policy_digest then
        return nil, diagnostic("environment_lease_stale",
            "QA isolation policy changed after measurement")
    end
    return retained, state
end

function qa_environment.validate_lease(registry, lease)
    local retained, retained_err = lease_state(registry, lease)
    if not retained then
        return nil, retained_err
    end
    return copy_value(retained.record.public_projection)
end

local forbidden_environment_keys = {
    adapter = true,
    provider = true,
    native_adapter = true,
    run = true,
    probe = true,
    probe_environment = true,
    fd = true,
    descriptor = true,
    handle = true,
    host_path = true,
    userdata = true,
}

local function detach_environment_result(value, forbidden_adapter, seen)
    local kind = type(value)
    if kind == "nil" or kind == "boolean" or kind == "number"
        or kind == "string" then
        return value
    end
    if kind ~= "table" or value == forbidden_adapter
        or getmetatable(value) ~= nil then
        return nil, "QA environment consumer returned private authority"
    end
    seen = seen or {}
    if seen[value] then
        return nil, "QA environment consumer returned cyclic data"
    end
    seen[value] = true
    local result = {}
    for key, child in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            return nil, "QA environment consumer returned invalid key"
        end
        if type(key) == "string" and forbidden_environment_keys[key] then
            return nil, "QA environment consumer returned forbidden field: "
                .. key
        end
        local detached, detached_err = detach_environment_result(
            child,
            forbidden_adapter,
            seen
        )
        if detached_err then
            return nil, detached_err
        end
        result[key] = detached
    end
    seen[value] = nil
    return result
end

function qa_environment.with_environment(registry, lease, consumer)
    local retained, retained_err = lease_state(registry, lease)
    if not retained then
        return nil, retained_err
    end
    if type(consumer) ~= "function" then
        return nil, "QA environment consumer must be function"
    end
    local adapter = retained.record.native_adapter
    local returned = table.pack(pcall(
        consumer,
        adapter,
        copy_value(retained.record.public_projection)
    ))
    if returned[1] ~= true then
        return nil, "QA environment consumer failed: " .. tostring(returned[2])
    end
    if returned.n > 3 then
        return nil, "QA environment consumer returned too many values"
    end
    if returned[2] == nil then
        local detached_failure, failure_err = detach_environment_result(
            returned[3], adapter)
        if failure_err then
            return nil, failure_err
        end
        return nil, detached_failure or "QA environment consumer failed"
    end
    local detached, detached_err = detach_environment_result(
        returned[2], adapter)
    if detached_err then
        return nil, detached_err
    end
    return detached
end

function qa_environment.quarantine(registry, environment_id, reason)
    local state, state_err = registry_state(registry)
    if not state then
        return nil, state_err
    end
    if type(reason) ~= "string" or reason == "" or #reason > 4096
        or reason:find("[%z\1-\31\127]") then
        return nil, "QA environment quarantine reason is invalid"
    end
    local record = state.record
    if not record or record.public_projection.environment_id ~= environment_id then
        return nil, "QA environment not found"
    end
    if record.state ~= "quarantined" then
        state.revision = state.revision + 1
        record.state = "quarantined"
        record.revision = state.revision
        record.quarantine_reason = reason
    end
    return copy_value(public_state(record))
end

return qa_environment
