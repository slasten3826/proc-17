local qa_request = require("runtime.qa_request")
local repository_capability = require("runtime.repository_capability")

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

function qa_capability.new(session_id, environment_registry, repository_registry)
    if type(session_id) ~= "string" or session_id == ""
        or #session_id > 1024 or session_id:find("[%z\1-\31\127]") then
        return nil, "QA capability session_id must be a bounded non-empty string"
    end
    if type(environment_registry) ~= "table"
        or type(repository_registry) ~= "table" then
        return nil, "QA capability requires private environment and repository registries"
    end
    local registry = {protocol_version = qa_capability.protocol_version}
    states[registry] = {
        session_id = session_id,
        environment_registry = environment_registry,
        repository_registry = repository_registry,
        grants = {},
        receipts = {},
    }
    return registry
end

function qa_capability.mint(registry, instance, request, request_ref)
    local state, state_err = registry_state(registry)
    if not state then
        return nil, diagnostic("private_registry_required", state_err)
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
    if body_event.id ~= request_ref then
        return nil, diagnostic("request_event_ref_mismatch",
            "private mint requires the exact body request event")
    end
    if type(repository_capability.reserve_qa_source) ~= "function" then
        return nil, diagnostic("source_bridge_unavailable",
            "sealed-source capability bridge is not implemented")
    end

    -- Source authority now exists, but mint remains closed until the grant,
    -- environment and source reservations become one atomic transaction.
    -- No partial private lease is created by this foundation slice.
    return nil, diagnostic("grant_mint_not_promoted",
        "QA grant mint is closed before sealed-source authority exists")
end

function qa_capability.begin(registry, request_id, request_ref)
    local state, state_err = registry_state(registry)
    if not state then
        return nil, diagnostic("private_registry_required", state_err)
    end
    local grant = state.grants[request_id]
    if not grant or grant.request_ref ~= request_ref then
        return nil, diagnostic("grant_absent",
            "exact private QA grant is absent")
    end
    return nil, diagnostic("grant_begin_not_promoted",
        "QA execution transaction is not implemented")
end

function qa_capability.commit(registry, private_lease, normalized_result)
    local state, state_err = registry_state(registry)
    if not state then
        return nil, state_err
    end
    if not leases[private_lease] then
        return nil, "private QA execution lease required"
    end
    return nil, "QA execution receipt commit is not implemented"
end

function qa_capability.quarantine(registry, private_lease, reason)
    local state, state_err = registry_state(registry)
    if not state then
        return nil, state_err
    end
    local lease = leases[private_lease]
    if not lease or lease.registry ~= registry then
        return nil, "private QA execution lease required"
    end
    lease.state = "quarantined"
    lease.reason = tostring(reason)
    return copy_value({
        protocol_version = "qa.execution_state.v0",
        request_id = lease.request_id,
        state = lease.state,
        event_truth_status = "runtime_confirmed",
    })
end

function qa_capability.find_receipt(registry, request_id)
    local state, state_err = registry_state(registry)
    if not state then
        return nil, state_err
    end
    local receipt = state.receipts[request_id]
    if not receipt then
        return nil, "QA execution receipt is absent"
    end
    return copy_value(receipt)
end

return qa_capability
