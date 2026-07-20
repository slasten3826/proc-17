local digest = require("core.digest")

local capability = {
    protocol_version = "repository.capability_registry.v0",
}

local states = setmetatable({}, {__mode = "k"})
local effect_leases = setmetatable({}, {__mode = "k"})

local allowed_provider_id = "linux.openat2.renameat2.v0"
local allowed_provider_contract = "repository.provider.create_readback.v0"
local required_provider_limits = {
    max_relative_path_bytes = 1024,
    max_component_bytes = 255,
    max_components = 64,
    max_content_bytes = 1048576,
    file_mode = 384,
}
local allowed_operations = {
    create_text_file = true,
}
local create_request_keys = {
    protocol_version = true,
    action_id = true,
    grant_id = true,
    grant_revision = true,
    root_fingerprint = true,
    relative_path = true,
    content = true,
    content_bytes = true,
    content_sha256 = true,
    precondition = true,
}
local allowed_policy = {
    file_mode = true,
}
local internal_components = {
    [".git"] = true,
    [".agents"] = true,
    [".codex"] = true,
    packets = true,
    graves = true,
    compost = true,
    trace = true,
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

local function diagnostic(code, message)
    return {
        protocol_version = "repository.capability_diagnostic.v0",
        code = code,
        message = message or code,
        event_truth_status = "runtime_confirmed",
    }
end

local function validate_keys(value, allowed, name)
    if type(value) ~= "table" then
        return nil, name .. " must be table"
    end
    for key in pairs(value) do
        if not allowed[key] then
            return nil, name .. " contains unknown key: " .. tostring(key)
        end
    end
    return true
end

local function validate_plain_record(value, allowed, name)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, name .. " must be a plain table"
    end
    local ok, err = validate_keys(value, allowed, name)
    if not ok then
        return nil, err
    end
    for key in pairs(allowed) do
        if value[key] == nil then
            return nil, name .. " is missing key: " .. key
        end
    end
    return true
end

local function non_empty(value, name)
    if type(value) ~= "string" or value == "" then
        return nil, name .. " must be a non-empty string"
    end
    return value
end

local function positive_integer(value, name)
    if type(value) ~= "number" or value < 1 or value ~= math.floor(value) then
        return nil, name .. " must be a positive integer"
    end
    return value
end

local function identity_component(value, name)
    if type(value) ~= "number" or value < 0 or value ~= math.floor(value) then
        return nil, name .. " must be a non-negative integer"
    end
    return value
end

local function split_path(value)
    local result = {}
    for component in value:gmatch("[^/]+") do
        result[#result + 1] = component
    end
    return result
end

local function validate_project_base(value)
    if type(value) ~= "string" or value == "" or value:sub(1, 1) ~= "/" then
        return nil, "project_base must be an absolute trusted host path"
    end
    if value == "/" or value:find("[%z\1-\31]") then
        return nil, "project_base is not a permitted host path"
    end
    if value:sub(-1) == "/" or value:find("//", 1, true) then
        return nil, "project_base must be normalized"
    end
    for _, component in ipairs(split_path(value)) do
        if component == "." or component == ".." then
            return nil, "project_base must not contain dot components"
        end
    end
    return value
end

local function validate_repository_path(value)
    if type(value) ~= "string" or value == "" or value:sub(1, 1) == "/"
        or value:sub(-1) == "/" or value:find("//", 1, true)
        or value:find("[%z\1-\31]") then
        return nil, "repository_path must be a normalized relative path"
    end
    for _, component in ipairs(split_path(value)) do
        if component == "." or component == ".." or internal_components[component] then
            return nil, "repository_path names a forbidden component"
        end
        if not component:match("^[A-Za-z0-9][A-Za-z0-9._-]*$") then
            return nil, "repository_path contains an unsupported component"
        end
    end
    return value
end

local function normalize_operations(value)
    local ok, err = validate_keys(value, allowed_operations, "operations")
    if not ok then
        return nil, err
    end
    local private = {}
    local public = {}
    for name in pairs(allowed_operations) do
        if type(value[name]) ~= "boolean" then
            return nil, "operations." .. name .. " must be boolean"
        end
        private[name] = value[name]
        if value[name] then
            public[#public + 1] = name
        end
    end
    table.sort(public)
    return private, public
end

local function normalize_bounds(value)
    local allowed = {
        max_relative_path_bytes = true,
        max_content_bytes = true,
        max_effects_per_generation = true,
    }
    local ok, err = validate_keys(value, allowed, "bounds")
    if not ok then
        return nil, err
    end
    local result = {}
    for name in pairs(allowed) do
        local normalized, normalized_err = positive_integer(value[name], "bounds." .. name)
        if not normalized then
            return nil, normalized_err
        end
        result[name] = normalized
    end
    return result
end

local function normalize_policy(value)
    local ok, err = validate_keys(value, allowed_policy, "policy")
    if not ok then
        return nil, err
    end
    local mode, mode_err = positive_integer(value.file_mode, "policy.file_mode")
    if not mode then
        return nil, mode_err
    end
    if mode ~= required_provider_limits.file_mode then
        return nil, "policy.file_mode must be exactly 0600"
    end
    return {file_mode = mode}
end

local function validate_provider(provider, provider_id)
    if type(provider) ~= "table" or provider.provider_id ~= provider_id
        or provider.contract_id ~= allowed_provider_contract then
        return nil, "provider identity or contract mismatch"
    end
    for _, method in ipairs({
        "available",
        "open_repository",
        "revalidate",
        "create_text_file",
        "read_text_file",
        "close",
    }) do
        if type(provider[method]) ~= "function" then
            return nil, "provider method missing: " .. method
        end
    end
    local limits_ok, limits_err = validate_keys(
        provider.limits,
        required_provider_limits,
        "provider limits"
    )
    if not limits_ok then
        return nil, limits_err
    end
    for name, expected in pairs(required_provider_limits) do
        if provider.limits[name] ~= expected then
            return nil, "provider limit mismatch: " .. name
        end
    end
    return true, copy_value(provider.limits)
end

local function normalize_identity(value, input, provider_id)
    if type(value) ~= "table" or type(value.project_base) ~= "table"
        or type(value.root) ~= "table" then
        return nil, "provider returned invalid repository identity"
    end
    local base_device, base_device_err = identity_component(
        value.project_base.device,
        "project base device"
    )
    if not base_device then
        return nil, base_device_err
    end
    local base_inode, base_inode_err = identity_component(
        value.project_base.inode,
        "project base inode"
    )
    if not base_inode then
        return nil, base_inode_err
    end
    local root_device, root_device_err = identity_component(value.root.device, "root device")
    if not root_device then
        return nil, root_device_err
    end
    local root_inode, root_inode_err = identity_component(value.root.inode, "root inode")
    if not root_inode then
        return nil, root_inode_err
    end
    if value.repository_path ~= nil and value.repository_path ~= input.repository_path then
        return nil, "provider repository identity path mismatch"
    end
    if type(value.host_path) ~= "string" or value.host_path == "" then
        return nil, "provider repository identity lacks host path"
    end
    local fingerprint, fingerprint_err = digest.record({
        provider_id = provider_id,
        project_base = {device = base_device, inode = base_inode},
        repository_path = input.repository_path,
        root = {device = root_device, inode = root_inode},
    })
    if not fingerprint then
        return nil, fingerprint_err
    end
    return {
        project_base_identity = {device = base_device, inode = base_inode},
        root_identity = {
            host_path = value.host_path,
            device = root_device,
            inode = root_inode,
            fingerprint = "repository-root:" .. fingerprint,
        },
    }
end

local function state_for(registry)
    local state = states[registry]
    if not state then
        return nil, "invalid repository capability registry"
    end
    return state
end

local function projection(grant)
    return copy_value({
        protocol_version = "repository.capability_projection.v0",
        grant_id = grant.grant_id,
        revision = grant.revision,
        state = grant.state,
        session_id = grant.session_id,
        lineage_id = grant.lineage_id,
        repository_id = grant.repository_id,
        provider_id = grant.provider_id,
        root_fingerprint = grant.root_identity.fingerprint,
        operations = grant.public_operations,
        bounds = grant.bounds,
        policy_digest = grant.policy_digest,
        event_truth_status = "runtime_confirmed",
    })
end

local function close_handle(grant)
    if grant.repository_handle == nil then
        return true
    end
    local called, closed, err = pcall(grant.provider.close, grant.repository_handle)
    grant.repository_handle = nil
    if not called then
        return nil, "provider close failed: " .. tostring(closed)
    end
    if closed ~= true then
        return nil, "provider close failed: " .. tostring(err or closed)
    end
    return true
end

function capability.new(options)
    options = options or {}
    local allowed = {session_id = true, providers = true, id_source = true}
    local ok, err = validate_keys(options, allowed, "repository capability options")
    if not ok then
        return nil, err
    end
    local session_id, session_err = non_empty(options.session_id, "session_id")
    if not session_id then
        return nil, session_err
    end
    if type(options.providers) ~= "table" then
        return nil, "providers must be table"
    end
    if options.id_source ~= nil and type(options.id_source) ~= "function" then
        return nil, "id_source must be function"
    end
    local providers = {}
    local provider_limits = {}
    for provider_id, provider in pairs(options.providers) do
        if provider_id ~= allowed_provider_id then
            return nil, "unsupported repository provider: " .. tostring(provider_id)
        end
        local provider_ok, normalized_limits = validate_provider(provider, provider_id)
        if not provider_ok then
            return nil, normalized_limits
        end
        providers[provider_id] = provider
        provider_limits[provider_id] = normalized_limits
    end
    local registry = {protocol_version = capability.protocol_version}
    states[registry] = {
        session_id = session_id,
        providers = providers,
        provider_limits = provider_limits,
        grants = {},
        grant_order = {},
        next_serial = 1,
        next_revision = 1,
        id_source = options.id_source,
    }
    return registry
end

function capability.mint(registry, input)
    local state, state_err = state_for(registry)
    if not state then
        return nil, state_err
    end
    local allowed = {
        lineage_id = true,
        repository_id = true,
        provider_id = true,
        project_base = true,
        repository_path = true,
        operations = true,
        bounds = true,
        policy = true,
    }
    local ok, err = validate_keys(input, allowed, "repository grant")
    if not ok then
        return nil, err
    end
    local lineage_id, lineage_err = non_empty(input.lineage_id, "lineage_id")
    if not lineage_id then
        return nil, lineage_err
    end
    local repository_id, repository_err = non_empty(input.repository_id, "repository_id")
    if not repository_id then
        return nil, repository_err
    end
    if input.provider_id ~= allowed_provider_id then
        return nil, "unsupported repository provider"
    end
    local project_base, base_err = validate_project_base(input.project_base)
    if not project_base then
        return nil, base_err
    end
    local repository_path, path_err = validate_repository_path(input.repository_path)
    if not repository_path then
        return nil, path_err
    end
    local operations, public_operations = normalize_operations(input.operations)
    if not operations then
        return nil, public_operations
    end
    local bounds, bounds_err = normalize_bounds(input.bounds)
    if not bounds then
        return nil, bounds_err
    end
    local policy, policy_err = normalize_policy(input.policy)
    if not policy then
        return nil, policy_err
    end
    local provider = state.providers[input.provider_id]
    if not provider then
        return nil, "repository provider is not registered"
    end
    local ceilings = state.provider_limits[input.provider_id]
    if bounds.max_relative_path_bytes > ceilings.max_relative_path_bytes then
        return nil, "bounds.max_relative_path_bytes exceeds provider ceiling"
    end
    if bounds.max_content_bytes > ceilings.max_content_bytes then
        return nil, "bounds.max_content_bytes exceeds provider ceiling"
    end
    local called, available, availability = pcall(provider.available)
    if not called then
        return nil, "repository provider availability failed: " .. tostring(available)
    end
    if available ~= true then
        return nil, "repository provider unavailable: " .. tostring(availability)
    end
    local opened, handle, identity_or_err, open_err = pcall(provider.open_repository, {
        project_base = project_base,
        repository_path = repository_path,
    })
    if not opened then
        return nil, "repository provider open failed: " .. tostring(handle)
    end
    if handle == nil then
        return nil, identity_or_err or open_err or "repository provider open failed"
    end
    local identity, identity_err = normalize_identity(
        identity_or_err,
        {repository_path = repository_path},
        input.provider_id
    )
    if not identity then
        pcall(provider.close, handle)
        return nil, identity_err
    end
    local policy_digest, policy_digest_err = digest.record(policy)
    if not policy_digest then
        pcall(provider.close, handle)
        return nil, policy_digest_err
    end
    local serial = state.next_serial
    state.next_serial = state.next_serial + 1
    local seed = {
        serial = serial,
        session_id = state.session_id,
        lineage_id = lineage_id,
        repository_id = repository_id,
        provider_id = input.provider_id,
        root_fingerprint = identity.root_identity.fingerprint,
        operations = public_operations,
        bounds = bounds,
        policy_digest = policy_digest,
    }
    local grant_id
    if state.id_source then
        local id_ok, supplied = pcall(
            state.id_source,
            "repository-grant",
            serial,
            copy_value(seed)
        )
        if not id_ok or type(supplied) ~= "string" or supplied == "" then
            pcall(provider.close, handle)
            return nil, "repository grant id source failed"
        end
        grant_id = supplied
    else
        local id_digest, id_err = digest.record(seed)
        if not id_digest then
            pcall(provider.close, handle)
            return nil, id_err
        end
        grant_id = "repository-grant:" .. id_digest
    end
    if state.grants[grant_id] then
        pcall(provider.close, handle)
        return nil, "repository grant id collision"
    end
    local grant = {
        protocol_version = "repository.capability_grant.v0",
        grant_id = grant_id,
        revision = state.next_revision,
        state = "active",
        session_id = state.session_id,
        lineage_id = lineage_id,
        repository_id = repository_id,
        provider_id = input.provider_id,
        provider = provider,
        repository_handle = handle,
        project_base_identity = identity.project_base_identity,
        root_identity = identity.root_identity,
        operations = operations,
        public_operations = public_operations,
        bounds = bounds,
        policy = policy,
        policy_digest = policy_digest,
        effect_counts = {},
        action_dispatches = {},
    }
    state.next_revision = state.next_revision + 1
    state.grants[grant_id] = grant
    state.grant_order[#state.grant_order + 1] = grant_id
    return projection(grant)
end

local function validate_resolution_context(context)
    local allowed = {
        session_id = true,
        lineage_id = true,
        generation = true,
        repository_id = true,
        operation = true,
        semantic_grant_id = true,
    }
    local ok, err = validate_keys(context, allowed, "capability resolution context")
    if not ok then
        return nil, err
    end
    for _, name in ipairs({"session_id", "lineage_id", "repository_id", "operation"}) do
        local _, value_err = non_empty(context[name], name)
        if value_err then
            return nil, value_err
        end
    end
    local _, generation_err = positive_integer(context.generation, "generation")
    if generation_err then
        return nil, generation_err
    end
    if not allowed_operations[context.operation] then
        return nil, "unsupported repository operation"
    end
    if context.semantic_grant_id ~= nil
        and type(context.semantic_grant_id) ~= "string" then
        return nil, "semantic_grant_id must be string when present"
    end
    return true
end

function capability.resolve(registry, context)
    local state, state_err = state_for(registry)
    if not state then
        return nil, state_err
    end
    local context_ok, context_err = validate_resolution_context(context)
    if not context_ok then
        return nil, context_err
    end
    local matches = {}
    local revoked = false
    local quarantined = false
    for _, grant_id in ipairs(state.grant_order) do
        local grant = state.grants[grant_id]
        local exact_scope = grant.session_id == context.session_id
            and grant.lineage_id == context.lineage_id
            and grant.repository_id == context.repository_id
            and grant.operations[context.operation] == true
        if exact_scope then
            if grant.state == "active" then
                matches[#matches + 1] = grant
            elseif grant.state == "revoked" then
                revoked = true
            elseif grant.state == "quarantined" then
                quarantined = true
            end
        end
    end
    if #matches > 1 then
        return nil, diagnostic("ambiguous_capability")
    end
    if #matches == 1 then
        return projection(matches[1])
    end
    if revoked then
        return nil, diagnostic("revoked_capability")
    end
    if quarantined then
        return nil, diagnostic("quarantined_capability")
    end
    return nil, diagnostic("missing_capability")
end

function capability.project(registry, grant_id)
    local state, state_err = state_for(registry)
    if not state then
        return nil, state_err
    end
    local grant = state.grants[grant_id]
    if not grant then
        return nil, diagnostic("missing_capability")
    end
    return projection(grant)
end

function capability.revoke(registry, grant_id)
    local state, state_err = state_for(registry)
    if not state then
        return nil, state_err
    end
    local grant = state.grants[grant_id]
    if not grant then
        return nil, diagnostic("missing_capability")
    end
    if grant.state == "active" or grant.state == "quarantined" then
        grant.state = "revoked"
        grant.revision = state.next_revision
        state.next_revision = state.next_revision + 1
        local closed, close_err = close_handle(grant)
        if not closed then
            return nil, close_err
        end
    end
    return projection(grant)
end

local function exact_action_grant(state, action)
    if type(action) ~= "table" or type(action.capability) ~= "table"
        or type(action.target) ~= "table" or type(action.content) ~= "table"
        or type(action.action_id) ~= "string" or action.action_id == ""
        or type(action.session_id) ~= "string" or action.session_id == ""
        or type(action.lineage_id) ~= "string" or action.lineage_id == ""
        or type(action.generation) ~= "number" or action.generation < 1
        or action.generation ~= math.floor(action.generation)
        or action.operation ~= "create_text_file"
        or type(action.target.relative_path) ~= "string"
        or type(action.content.bytes) ~= "number"
        or type(action.content.sha256) ~= "string" then
        return nil, "repository effect action envelope is invalid"
    end

    local grant = state.grants[action.capability.grant_id]
    if not grant then
        return nil, diagnostic("missing_capability")
    end
    if grant.state == "revoked" then
        return nil, diagnostic("grant_revoked")
    end
    if grant.state == "quarantined" then
        return nil, diagnostic("grant_quarantined")
    end
    if grant.state ~= "active" then
        return nil, "repository grant has invalid private state"
    end

    if state.session_id ~= action.session_id
        or grant.session_id ~= action.session_id
        or grant.lineage_id ~= action.lineage_id
        or grant.repository_id ~= action.capability.repository_id
        or grant.provider_id ~= action.capability.provider_id
        or grant.grant_id ~= action.capability.grant_id
        or grant.revision ~= action.capability.revision
        or grant.root_identity.fingerprint ~= action.capability.root_fingerprint
        or grant.policy_digest ~= action.capability.policy_digest
        or grant.operations[action.operation] ~= true then
        return nil, "repository action contradicts private grant identity"
    end
    if #action.target.relative_path > grant.bounds.max_relative_path_bytes
        or action.content.bytes > grant.bounds.max_content_bytes then
        return nil, diagnostic("capability_bounds_exceeded")
    end
    return grant
end

function capability.begin_effect(registry, action, instance)
    local state, state_err = state_for(registry)
    if not state then
        return nil, state_err
    end
    local action_ok, action_err = require("runtime.repository_action").validate(
        instance, action)
    if not action_ok then
        return nil, action_err
    end
    local grant, grant_err = exact_action_grant(state, action)
    if not grant then
        return nil, grant_err
    end

    if grant.action_dispatches[action.action_id] then
        return nil, diagnostic("action_already_dispatched")
    end
    local generation_key = tostring(action.generation)
    local used = grant.effect_counts[generation_key] or 0
    if used >= grant.bounds.max_effects_per_generation then
        return nil, diagnostic("effect_limit_exhausted")
    end

    -- Consumed authority is never refunded, even when the provider denies the call.
    grant.effect_counts[generation_key] = used + 1
    grant.action_dispatches[action.action_id] = true

    local lease = setmetatable({}, {__metatable = "repository.effect_lease.v0"})
    effect_leases[lease] = {
        registry = registry,
        grant = grant,
        grant_revision = grant.revision,
        action_id = action.action_id,
        relative_path = action.target.relative_path,
        content_bytes = action.content.bytes,
        content_sha256 = action.content.sha256,
        precondition = action.target.precondition,
        create_called = false,
        create_succeeded = false,
        read_called = false,
    }
    return lease
end

local function lease_state(registry, lease)
    local state = effect_leases[lease]
    if not state or state.registry ~= registry then
        return nil, "invalid repository effect lease"
    end
    if state.grant.state == "revoked" then
        return nil, diagnostic("grant_revoked")
    end
    if state.grant.state == "quarantined" then
        return nil, diagnostic("grant_quarantined")
    end
    if state.grant.state ~= "active"
        or state.grant.revision ~= state.grant_revision
        or state.grant.repository_handle == nil then
        return nil, "repository effect lease grant state changed"
    end
    return state
end

function capability.effect_create(registry, lease, request)
    local state, state_err = lease_state(registry, lease)
    if not state then
        return nil, state_err
    end
    if state.create_called then
        return nil, "repository effect create lease already consumed"
    end
    local request_ok, request_err = validate_plain_record(
        request, create_request_keys, "repository effect request")
    if not request_ok then
        return nil, request_err
    end
    if request.protocol_version ~= "repository.create_text_file.request.v0"
        or request.action_id ~= state.action_id
        or request.grant_id ~= state.grant.grant_id
        or request.grant_revision ~= state.grant.revision
        or request.root_fingerprint ~= state.grant.root_identity.fingerprint
        or request.relative_path ~= state.relative_path
        or request.content_bytes ~= state.content_bytes
        or request.content_sha256 ~= state.content_sha256
        or request.precondition ~= state.precondition
        or type(request.content) ~= "string"
        or #request.content ~= state.content_bytes
        or digest.sha256(request.content) ~= state.content_sha256 then
        return nil, "repository effect request contradicts lease"
    end

    state.create_called = true
    local result, err = state.grant.provider.create_text_file(
        state.grant.repository_handle,
        {
            protocol_version = "repository.create_text_file.request.v0",
            relative_path = state.relative_path,
            content = request.content,
            content_bytes = state.content_bytes,
            precondition = state.precondition,
            file_mode = state.grant.policy.file_mode,
        }
    )
    if result ~= nil then
        state.create_succeeded = true
    end
    return result, err
end

function capability.effect_read_back(registry, lease)
    local state, state_err = lease_state(registry, lease)
    if not state then
        return nil, state_err
    end
    if not state.create_succeeded then
        return nil, "repository effect read-back requires writer success"
    end
    if state.read_called then
        return nil, "repository effect read-back lease already consumed"
    end
    state.read_called = true
    return state.grant.provider.read_text_file(
        state.grant.repository_handle,
        {
            relative_path = state.relative_path,
            max_bytes = state.content_bytes + 1,
        }
    )
end

function capability.effect_root_matches(registry, lease, root)
    local state, state_err = lease_state(registry, lease)
    if not state then
        return nil, state_err
    end
    return type(root) == "table"
        and root.device == state.grant.root_identity.device
        and root.inode == state.grant.root_identity.inode
end

function capability.quarantine_effect(registry, lease, reason)
    local state, state_err = lease_state(registry, lease)
    if not state then
        return nil, state_err
    end
    local grant = state.grant
    if grant.state == "active" then
        grant.state = "quarantined"
        grant.revision = states[registry].next_revision
        states[registry].next_revision = states[registry].next_revision + 1
        grant.quarantine_reason = copy_value(reason)
        local closed, close_err = close_handle(grant)
        if not closed then
            return nil, close_err
        end
    end
    return projection(grant)
end

return capability
