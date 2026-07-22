local digest = require("core.digest")

local capability = {
    protocol_version = "repository.capability_registry.v0",
}

local states = setmetatable({}, {__mode = "k"})
local effect_leases = setmetatable({}, {__mode = "k"})
local seal_leases = setmetatable({}, {__mode = "k"})

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
local candidate_seal_request_keys = {
    protocol_version = true,
    request_id = true,
    packet_id = true,
    lineage_id = true,
    generation = true,
    process_contract_id = true,
    context = true,
    stage_id = true,
    repository_id = true,
    root_authority_id = true,
    lifecycle_id = true,
    lifecycle_revision = true,
    root_fingerprint = true,
    grant_id = true,
    grant_revision = true,
    artifact_set_id = true,
    artifact_set_inspection_id = true,
    expected_files = true,
    expected_directories = true,
    inventory_bounds = true,
    source_refs = true,
    event_truth_status = true,
    content_truth_status = true,
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
        "inventory_tree",
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

local function map_count(value)
    local count = 0
    for _ in pairs(value or {}) do
        count = count + 1
    end
    return count
end

local function active_grant_count(root)
    local count = 0
    for _, grant in pairs(root.grant_ids or {}) do
        if grant.state == "active" then
            count = count + 1
        end
    end
    return count
end

local function root_authority_identity(state, provider_id, identity)
    local value, err = digest.record({
        session_id = state.session_id,
        provider_id = provider_id,
        project_base_identity = identity.project_base_identity,
        root_fingerprint = identity.root_identity.fingerprint,
    })
    if not value then
        return nil, err
    end
    return "root-authority:" .. value
end

local function root_projection(root)
    return copy_value({
        protocol_version = "repository.root_authority_projection.v0",
        root_authority_id = root.root_authority_id,
        root_fingerprint = root.root_fingerprint,
        lineage_id = root.lineage_id,
        repository_id = root.repository_id,
        state = root.state,
        revision = root.revision,
        lifecycle_id = root.claim and root.claim.lifecycle_id or nil,
        owner_generation = root.claim and root.claim.generation or nil,
        active_grant_count = active_grant_count(root),
        active_dispatch_count = map_count(root.in_flight_dispatches),
        seal_request_id = root.seal_request_id,
        closure_id = root.closure_id,
        inventory_digest = root.inventory_digest,
        event_truth_status = "runtime_confirmed",
    })
end

local function projection(grant)
    local root = grant.root_authority
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
        root_authority_id = root.root_authority_id,
        root_state = root.state,
        root_revision = root.revision,
        lifecycle_id = root.claim and root.claim.lifecycle_id or nil,
        owner_generation = root.claim and root.claim.generation or nil,
        active_dispatch_count = map_count(root.in_flight_dispatches),
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

local function quarantine_root(registry_state, root, reason)
    local normalized_reason = copy_value(reason or {
        code = "repository_root_quarantined",
    })
    local reason_id, reason_err = digest.record({reason = normalized_reason})
    if not reason_id then
        return nil, "repository quarantine reason is not digestible: "
            .. tostring(reason_err)
    end
    if root.state == "quarantined" then
        local existing_id = digest.record({reason = root.quarantine_reason})
        if existing_id ~= reason_id then
            return nil, "repository root received contradictory quarantine reason"
        end
        return root_projection(root)
    end
    if root.state == "sealed" then
        return nil, "sealed repository root cannot be reclassified as quarantined"
    end

    root.state = "quarantined"
    root.revision = registry_state.next_revision
    registry_state.next_revision = registry_state.next_revision + 1
    root.quarantine_reason = normalized_reason
    root.in_flight_dispatches = {}

    local first_close_err
    for _, grant in pairs(root.grant_ids) do
        if grant.state == "active" then
            grant.state = "quarantined"
            grant.revision = registry_state.next_revision
            registry_state.next_revision = registry_state.next_revision + 1
        end
        local closed, close_err = close_handle(grant)
        if not closed and not first_close_err then
            first_close_err = close_err
        end
    end
    if first_close_err then
        return nil, first_close_err
    end
    return root_projection(root)
end

local function with_provider_dispatch(registry, lease_state_value, phase, fn, ...)
    local root = lease_state_value.root
    local dispatch_digest, dispatch_err = digest.record({
        lifecycle_id = lease_state_value.lifecycle_id,
        action_id = lease_state_value.action_id,
        phase = phase,
    })
    if not dispatch_digest then
        return nil, dispatch_err
    end
    local dispatch_id = "repository-dispatch:" .. dispatch_digest
    if root.in_flight_dispatches[dispatch_id] then
        return nil, "repository provider dispatch is already in flight"
    end
    root.in_flight_dispatches[dispatch_id] = {
        dispatch_id = dispatch_id,
        action_id = lease_state_value.action_id,
        phase = phase,
    }
    local returned = table.pack(pcall(fn, ...))
    root.in_flight_dispatches[dispatch_id] = nil
    if returned[1] ~= true then
        local registry_state = assert(states[registry])
        local _, quarantine_err = quarantine_root(registry_state, root, {
            code = "repository_provider_panic",
            phase = phase,
            message = tostring(returned[2]),
        })
        if quarantine_err then
            error("repository provider panic and quarantine failed: "
                .. tostring(quarantine_err))
        end
        error("repository provider invariant failure: " .. tostring(returned[2]))
    end
    return table.unpack(returned, 2, returned.n)
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
        root_authorities = {},
        root_order = {},
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
    local root_authority_id, root_id_err = root_authority_identity(
        state,
        input.provider_id,
        identity
    )
    if not root_authority_id then
        pcall(provider.close, handle)
        return nil, root_id_err
    end
    local root = state.root_authorities[root_authority_id]
    local new_root = root == nil
    if root then
        if root.lineage_id ~= lineage_id or root.repository_id ~= repository_id then
            pcall(provider.close, handle)
            return nil, diagnostic("repository_root_logical_alias")
        end
        if root.state == "seal_pending" then
            pcall(provider.close, handle)
            return nil, diagnostic("repository_root_seal_pending")
        end
        if root.state == "sealed" then
            pcall(provider.close, handle)
            return nil, diagnostic("repository_root_sealed")
        end
        if root.state == "quarantined" then
            pcall(provider.close, handle)
            return nil, diagnostic("repository_root_quarantined")
        end
    else
        root = {
            protocol_version = "repository.root_authority.v0",
            root_authority_id = root_authority_id,
            session_id = state.session_id,
            provider_id = input.provider_id,
            project_base_identity = copy_value(identity.project_base_identity),
            root_identity = copy_value(identity.root_identity),
            root_fingerprint = identity.root_identity.fingerprint,
            lineage_id = lineage_id,
            repository_id = repository_id,
            state = "unclaimed",
            revision = state.next_revision,
            claim = nil,
            grant_ids = {},
            in_flight_dispatches = {},
            seal_transaction_id = nil,
            seal_request_id = nil,
            closure_id = nil,
            inventory_id = nil,
            inventory_digest = nil,
            closure_projection = nil,
            quarantine_reason = nil,
        }
        state.next_revision = state.next_revision + 1
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
        root_authority_id = root_authority_id,
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
        root_authority_id = root_authority_id,
        root_authority = root,
        operations = operations,
        public_operations = public_operations,
        bounds = bounds,
        policy = policy,
        policy_digest = policy_digest,
        effect_counts = {},
        action_dispatches = {},
    }
    state.next_revision = state.next_revision + 1
    if new_root then
        state.root_authorities[root_authority_id] = root
        state.root_order[#state.root_order + 1] = root_authority_id
    end
    root.grant_ids[grant_id] = grant
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
    local root_denial
    for _, grant_id in ipairs(state.grant_order) do
        local grant = state.grants[grant_id]
        local exact_scope = grant.session_id == context.session_id
            and grant.lineage_id == context.lineage_id
            and grant.repository_id == context.repository_id
            and grant.operations[context.operation] == true
        if exact_scope then
            if grant.state == "active" then
                local root = grant.root_authority
                if root.state == "unclaimed" then
                    matches[#matches + 1] = grant
                elseif root.state == "materializing" then
                    if root.claim and root.claim.lineage_id == context.lineage_id
                        and root.claim.generation == context.generation
                        and root.claim.repository_id == context.repository_id then
                        matches[#matches + 1] = grant
                    else
                        root_denial = root_denial
                            or "repository_root_claimed_by_other_generation"
                    end
                elseif root.state == "seal_pending" then
                    root_denial = root_denial or "repository_root_seal_pending"
                elseif root.state == "sealed" then
                    root_denial = root_denial or "repository_root_sealed"
                elseif root.state == "quarantined" then
                    root_denial = root_denial or "repository_root_quarantined"
                else
                    return nil, "repository root has invalid private state"
                end
            elseif grant.state == "revoked" then
                revoked = true
            elseif grant.state == "sealed" then
                root_denial = root_denial or "repository_root_sealed"
            elseif grant.state == "quarantined" then
                quarantined = true
            else
                return nil, "repository grant has invalid private state"
            end
        end
    end
    if #matches > 1 then
        return nil, diagnostic("ambiguous_capability")
    end
    if #matches == 1 then
        return projection(matches[1])
    end
    if root_denial then
        return nil, diagnostic(root_denial)
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

local function root_from_query(state, query)
    if type(query) ~= "table" then
        return nil, "repository root query must be table"
    end
    local ok, err = validate_keys(query, {
        root_authority_id = true,
        grant_id = true,
    }, "repository root query")
    if not ok then
        return nil, err
    end
    if (query.root_authority_id == nil) == (query.grant_id == nil) then
        return nil, "repository root query requires exactly one identity"
    end
    local root
    if query.root_authority_id ~= nil then
        local _, id_err = non_empty(query.root_authority_id, "root_authority_id")
        if id_err then
            return nil, id_err
        end
        root = state.root_authorities[query.root_authority_id]
    elseif query.grant_id ~= nil then
        local _, id_err = non_empty(query.grant_id, "grant_id")
        if id_err then
            return nil, id_err
        end
        local grant = state.grants[query.grant_id]
        root = grant and grant.root_authority or nil
    else
        return nil, "repository root query requires one identity"
    end
    if not root then
        return nil, diagnostic("repository_root_missing")
    end
    return root
end

function capability.root_authority(registry, query)
    local state, state_err = state_for(registry)
    if not state then
        return nil, state_err
    end
    local root, root_err = root_from_query(state, query)
    if not root then
        return nil, root_err
    end
    return root_projection(root)
end

function capability.candidate_lifecycle(registry, query)
    local state, state_err = state_for(registry)
    if not state then
        return nil, state_err
    end
    local root, root_err = root_from_query(state, query)
    if not root then
        return nil, root_err
    end
    local projection_value = root_projection(root)
    return copy_value({
        protocol_version = "repository.candidate_lifecycle_projection.v0",
        root_authority_id = projection_value.root_authority_id,
        lifecycle_id = projection_value.lifecycle_id,
        lineage_id = projection_value.lineage_id,
        generation = projection_value.owner_generation,
        repository_id = projection_value.repository_id,
        root_fingerprint = projection_value.root_fingerprint,
        state = projection_value.state,
        revision = projection_value.revision,
        active_grant_count = projection_value.active_grant_count,
        active_dispatch_count = projection_value.active_dispatch_count,
        seal_request_id = projection_value.seal_request_id,
        closure_id = projection_value.closure_id,
        inventory_digest = projection_value.inventory_digest,
        event_truth_status = "runtime_confirmed",
    })
end

local function strict_string_array(value, name)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, name .. " must be an array"
    end
    local seen = {}
    for index, item in ipairs(value) do
        if type(item) ~= "string" or item == "" or seen[item] then
            return nil, name .. " must contain unique non-empty strings"
        end
        seen[item] = true
        if value[index] ~= item then
            return nil, name .. " must be an array"
        end
    end
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key > #value
            or key ~= math.floor(key) then
            return nil, name .. " must be an array"
        end
    end
    return true
end

local function normalized_refs(value)
    local result = copy_value(value or {})
    table.sort(result)
    return result
end

local function validate_candidate_seal_request(value)
    local ok, err = validate_plain_record(
        value,
        candidate_seal_request_keys,
        "candidate seal request"
    )
    if not ok then
        return nil, err
    end
    if value.protocol_version ~= "repository.candidate_seal_request.v0"
        or value.event_truth_status ~= "runtime_confirmed"
        or (value.content_truth_status ~= "semantic_proposal"
            and value.content_truth_status ~= "mixed") then
        return nil, "candidate seal request protocol or truth status is invalid"
    end
    for _, key in ipairs({
        "request_id", "packet_id", "lineage_id", "process_contract_id",
        "context", "stage_id", "repository_id", "root_authority_id",
        "lifecycle_id", "root_fingerprint", "grant_id", "artifact_set_id",
        "artifact_set_inspection_id",
    }) do
        local _, value_err = non_empty(value[key], "candidate seal " .. key)
        if value_err then
            return nil, value_err
        end
    end
    for _, key in ipairs({"generation", "lifecycle_revision", "grant_revision"}) do
        local _, value_err = positive_integer(value[key], "candidate seal " .. key)
        if value_err then
            return nil, value_err
        end
    end
    if type(value.expected_files) ~= "table"
        or getmetatable(value.expected_files) ~= nil
        or type(value.inventory_bounds) ~= "table"
        or getmetatable(value.inventory_bounds) ~= nil then
        return nil, "candidate seal request contains invalid nested records"
    end
    local directories_ok, directories_err = strict_string_array(
        value.expected_directories,
        "candidate seal expected_directories"
    )
    if not directories_ok then
        return nil, directories_err
    end
    local refs_ok, refs_err = strict_string_array(
        value.source_refs,
        "candidate seal source_refs"
    )
    if not refs_ok then
        return nil, refs_err
    end
    local seed = copy_value(value)
    seed.request_id = nil
    local identity, identity_err = digest.record(seed)
    if not identity then
        return nil, identity_err
    end
    if value.request_id ~= "candidate-seal-request:" .. identity then
        return nil, "candidate seal request identity mismatch"
    end
    return true
end

local function seal_lease_state(registry, lease)
    local lease_value = seal_leases[lease]
    if not lease_value or lease_value.registry ~= registry then
        return nil, "invalid repository candidate seal lease"
    end
    if lease_value.consumed then
        return nil, "repository candidate seal lease already consumed"
    end
    local root = lease_value.root
    if root.state == "quarantined" then
        return nil, diagnostic("repository_root_quarantined")
    end
    if root.state == "sealed" then
        return nil, diagnostic("repository_root_sealed")
    end
    if root.state ~= "seal_pending"
        or root.revision ~= lease_value.pending_revision
        or root.seal_transaction_id ~= lease_value.transaction_id
        or root.seal_request_id ~= lease_value.request_id
        or not root.claim
        or root.claim.lifecycle_id ~= lease_value.lifecycle_id then
        return nil, "repository candidate seal private state changed"
    end
    if lease_value.grant.state ~= "active"
        or lease_value.grant.revision ~= lease_value.grant_revision
        or lease_value.grant.repository_handle == nil then
        return nil, "repository candidate seal grant state changed"
    end
    return lease_value
end

function capability.begin_candidate_seal(registry, request)
    local state, state_err = state_for(registry)
    if not state then
        return nil, state_err
    end
    local request_ok, request_err = validate_candidate_seal_request(request)
    if not request_ok then
        return nil, request_err
    end
    local root = state.root_authorities[request.root_authority_id]
    if not root then
        return nil, diagnostic("repository_root_missing")
    end
    if root.state == "seal_pending" then
        return nil, diagnostic("repository_root_seal_pending")
    end
    if root.state == "sealed" then
        return nil, diagnostic("repository_root_sealed")
    end
    if root.state == "quarantined" then
        return nil, diagnostic("repository_root_quarantined")
    end
    if root.state ~= "materializing" or not root.claim then
        return nil, diagnostic("repository_candidate_not_materializing")
    end
    if root.lineage_id ~= request.lineage_id
        or root.repository_id ~= request.repository_id
        or root.root_fingerprint ~= request.root_fingerprint
        or root.claim.lifecycle_id ~= request.lifecycle_id
        or root.claim.lineage_id ~= request.lineage_id
        or root.claim.generation ~= request.generation
        or root.claim.repository_id ~= request.repository_id
        or root.revision ~= request.lifecycle_revision then
        return nil, "candidate seal request contradicts private lifecycle"
    end
    if map_count(root.in_flight_dispatches) ~= 0 then
        return nil, diagnostic("repository_provider_dispatch_in_flight")
    end
    if root.seal_transaction_id ~= nil then
        return nil, "repository root has contradictory pending seal identity"
    end
    if active_grant_count(root) ~= 1 then
        return nil, diagnostic("repository_candidate_grant_ambiguous")
    end
    local grant = state.grants[request.grant_id]
    if not grant or grant.root_authority ~= root or grant.state ~= "active"
        or grant.revision ~= request.grant_revision
        or grant.repository_handle == nil then
        return nil, "candidate seal request contradicts private grant"
    end

    local transaction_digest, transaction_err = digest.record({
        root_authority_id = root.root_authority_id,
        lifecycle_id = root.claim.lifecycle_id,
        request_id = request.request_id,
        revision_before = root.revision,
    })
    if not transaction_digest then
        return nil, transaction_err
    end
    local revision_before = root.revision
    root.state = "seal_pending"
    root.revision = state.next_revision
    state.next_revision = state.next_revision + 1
    root.seal_transaction_id = "candidate-seal-transaction:" .. transaction_digest
    root.seal_request_id = request.request_id

    local lease = setmetatable({}, {
        __metatable = "repository.candidate_seal_lease.v0",
    })
    seal_leases[lease] = {
        registry = registry,
        root = root,
        grant = grant,
        grant_revision = grant.revision,
        lifecycle_id = root.claim.lifecycle_id,
        generation = root.claim.generation,
        request_id = request.request_id,
        transaction_id = root.seal_transaction_id,
        revision_before = revision_before,
        pending_revision = root.revision,
        action_id = root.seal_transaction_id,
        inventory_called = false,
        consumed = false,
    }
    return lease
end

function capability.inventory_candidate(registry, lease, input)
    local lease_value, lease_err = seal_lease_state(registry, lease)
    if not lease_value then
        return nil, lease_err
    end
    local allowed = {
        protocol_version = true,
        request_id = true,
        transaction_id = true,
        inventory_bounds = true,
    }
    local input_ok, input_err = validate_plain_record(
        input,
        allowed,
        "candidate inventory request"
    )
    if not input_ok then
        return nil, input_err
    end
    if input.protocol_version ~= "repository.candidate_inventory_request.v0"
        or input.request_id ~= lease_value.request_id
        or input.transaction_id ~= lease_value.transaction_id
        or type(input.inventory_bounds) ~= "table"
        or getmetatable(input.inventory_bounds) ~= nil then
        return nil, "candidate inventory request contradicts seal lease"
    end
    if lease_value.inventory_called then
        return nil, "candidate inventory lease already consumed"
    end
    lease_value.inventory_called = true
    return with_provider_dispatch(
        registry,
        lease_value,
        "inventory_tree",
        lease_value.grant.provider.inventory_tree,
        lease_value.grant.repository_handle,
        copy_value(input.inventory_bounds)
    )
end

function capability.candidate_inventory_root_matches(registry, lease, before, after)
    local lease_value, lease_err = seal_lease_state(registry, lease)
    if not lease_value then
        return nil, lease_err
    end
    local expected = lease_value.root.root_identity
    local function matches(value)
        return type(value) == "table"
            and value.device == expected.device
            and value.inode == expected.inode
    end
    return matches(before) and matches(after)
end

function capability.abort_candidate_seal(registry, lease, proof)
    local state, state_err = state_for(registry)
    if not state then
        return nil, state_err
    end
    local lease_value, lease_err = seal_lease_state(registry, lease)
    if not lease_value then
        return nil, lease_err
    end
    local proof_ok, proof_err = validate_plain_record(proof, {
        protocol_version = true,
        request_id = true,
        transaction_id = true,
        provider = true,
        source_refs = true,
        event_truth_status = true,
    }, "candidate seal abort proof")
    if not proof_ok then
        return nil, proof_err
    end
    local provider_ok, provider_err = validate_plain_record(proof.provider, {
        root_continuity = true,
        observation_postcondition = true,
        root_before_ref = true,
        root_after_ref = true,
    }, "candidate seal provider abort proof")
    if not provider_ok then
        return nil, provider_err
    end
    local refs_ok, refs_err = strict_string_array(
        proof.source_refs,
        "candidate seal abort source_refs"
    )
    if not refs_ok then
        return nil, refs_err
    end
    local root = lease_value.root
    local registry_proof = {
        closure_commit_absent = root.closure_id == nil
            and root.closure_projection == nil,
        current_transaction = root.state == "seal_pending"
            and root.seal_transaction_id == lease_value.transaction_id
            and root.seal_request_id == lease_value.request_id,
        in_flight_dispatches = map_count(root.in_flight_dispatches),
        root_revision = root.revision,
    }
    if not lease_value.inventory_called
        or proof.protocol_version ~= "repository.candidate_seal_abort_proof.v0"
        or proof.request_id ~= lease_value.request_id
        or proof.transaction_id ~= lease_value.transaction_id
        or proof.event_truth_status ~= "runtime_confirmed"
        or registry_proof.closure_commit_absent ~= true
        or registry_proof.current_transaction ~= true
        or registry_proof.in_flight_dispatches ~= 0
        or registry_proof.root_revision ~= lease_value.pending_revision
        or proof.provider.root_continuity ~= "proven"
        or (proof.provider.observation_postcondition ~= "stable_mismatch"
            and proof.provider.observation_postcondition ~= "bounded_no_closure")
        or type(proof.provider.root_before_ref) ~= "string"
        or proof.provider.root_before_ref == ""
        or type(proof.provider.root_after_ref) ~= "string"
        or proof.provider.root_after_ref == "" then
        return nil, "candidate seal abort proof is insufficient"
    end

    root.state = "materializing"
    root.revision = state.next_revision
    state.next_revision = state.next_revision + 1
    root.seal_transaction_id = nil
    root.seal_request_id = nil
    lease_value.consumed = true
    return root_projection(root)
end

function capability.commit_candidate_seal(registry, lease, input)
    local state, state_err = state_for(registry)
    if not state then
        return nil, state_err
    end
    local lease_value, lease_err = seal_lease_state(registry, lease)
    if not lease_value then
        return nil, lease_err
    end
    local input_ok, input_err = validate_plain_record(input, {
        protocol_version = true,
        request_id = true,
        transaction_id = true,
        inventory_id = true,
        inventory_digest = true,
        root_fingerprint = true,
        comparison = true,
        source_refs = true,
    }, "candidate seal commit")
    if not input_ok then
        return nil, input_err
    end
    local refs_ok, refs_err = strict_string_array(
        input.source_refs,
        "candidate seal commit source_refs"
    )
    if not refs_ok then
        return nil, refs_err
    end
    for _, key in ipairs({"inventory_id", "inventory_digest", "root_fingerprint"}) do
        local _, value_err = non_empty(input[key], "candidate seal commit " .. key)
        if value_err then
            return nil, value_err
        end
    end
    if not lease_value.inventory_called
        or input.protocol_version ~= "repository.candidate_seal_commit.v0"
        or input.request_id ~= lease_value.request_id
        or input.transaction_id ~= lease_value.transaction_id
        or input.root_fingerprint ~= lease_value.root.root_fingerprint
        or input.comparison ~= "exact" then
        return nil, "candidate seal commit contradicts private transaction"
    end

    local root = lease_value.root
    local revision_after = state.next_revision
    local receipt = {
        protocol_version = "repository.candidate_closure_receipt.v0",
        closure_id = nil,
        request_id = input.request_id,
        root_authority_id = root.root_authority_id,
        lifecycle_id = root.claim.lifecycle_id,
        root_fingerprint = root.root_fingerprint,
        grant_id = lease_value.grant.grant_id,
        lifecycle_revision_before = lease_value.revision_before,
        lifecycle_revision_after = revision_after,
        inventory_id = input.inventory_id,
        inventory_digest = input.inventory_digest,
        state = "sealed",
        source_refs = normalized_refs(input.source_refs),
        event_truth_status = "runtime_confirmed",
    }
    local receipt_seed = copy_value(receipt)
    receipt_seed.closure_id = nil
    local closure_digest, closure_err = digest.record(receipt_seed)
    if not closure_digest then
        return nil, closure_err
    end
    receipt.closure_id = "candidate-closure:" .. closure_digest

    root.state = "sealed"
    root.revision = revision_after
    state.next_revision = state.next_revision + 1
    root.closure_id = receipt.closure_id
    root.inventory_id = input.inventory_id
    root.inventory_digest = input.inventory_digest
    root.closure_projection = copy_value(receipt)
    lease_value.consumed = true

    local first_close_err
    for _, grant in pairs(root.grant_ids) do
        if grant.state == "active" then
            grant.state = "sealed"
            grant.revision = state.next_revision
            state.next_revision = state.next_revision + 1
        end
        local closed, close_err = close_handle(grant)
        if not closed and not first_close_err then
            first_close_err = close_err
        end
    end
    if first_close_err then
        return nil, "candidate closure committed but handle close failed: "
            .. tostring(first_close_err)
    end
    return copy_value(receipt)
end

function capability.quarantine_candidate_seal(registry, lease, reason)
    local state, state_err = state_for(registry)
    if not state then
        return nil, state_err
    end
    local lease_value = seal_leases[lease]
    if not lease_value or lease_value.registry ~= registry then
        return nil, "invalid repository candidate seal lease"
    end
    local result, result_err = quarantine_root(state, lease_value.root, reason)
    if result then
        lease_value.consumed = true
    end
    return result, result_err
end

function capability.observe_candidate_closure(registry, query)
    local state, state_err = state_for(registry)
    if not state then
        return nil, state_err
    end
    local query_ok, query_err = validate_plain_record(query, {
        root_authority_id = true,
        lifecycle_id = true,
        request_id = true,
    }, "candidate closure query")
    if not query_ok then
        return nil, query_err
    end
    local root = state.root_authorities[query.root_authority_id]
    if not root then
        return nil, diagnostic("repository_root_missing")
    end
    if root.state ~= "sealed" then
        return nil, diagnostic("repository_candidate_not_sealed")
    end
    if not root.claim or root.claim.lifecycle_id ~= query.lifecycle_id
        or root.seal_request_id ~= query.request_id then
        return nil, diagnostic("repository_candidate_closure_mismatch")
    end
    if type(root.closure_projection) ~= "table" then
        return nil, "sealed repository root lacks closure projection"
    end
    return copy_value(root.closure_projection)
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
        or grant.root_authority_id ~= action.capability.root_authority_id
        or grant.policy_digest ~= action.capability.policy_digest
        or grant.operations[action.operation] ~= true then
        return nil, "repository action contradicts private grant identity"
    end
    local root = grant.root_authority
    if root.state == "seal_pending" then
        return nil, diagnostic("repository_root_seal_pending")
    end
    if root.state == "sealed" then
        return nil, diagnostic("repository_root_sealed")
    end
    if root.state == "quarantined" then
        return nil, diagnostic("repository_root_quarantined")
    end
    if root.state ~= "unclaimed" and root.state ~= "materializing" then
        return nil, "repository root has invalid private state"
    end
    if root.state == "materializing"
        and (not root.claim
            or root.claim.lineage_id ~= action.lineage_id
            or root.claim.generation ~= action.generation
            or root.claim.repository_id ~= grant.repository_id) then
        return nil, diagnostic("repository_root_claimed_by_other_generation")
    end
    if #action.target.relative_path > grant.bounds.max_relative_path_bytes
        or action.content.bytes > grant.bounds.max_content_bytes then
        return nil, diagnostic("capability_bounds_exceeded")
    end
    return grant, root
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
    local replay_grant = type(action.capability) == "table"
        and state.grants[action.capability.grant_id] or nil
    local fixed_grant_identity = replay_grant
        and replay_grant.session_id == action.session_id
        and replay_grant.lineage_id == action.lineage_id
        and replay_grant.repository_id == action.capability.repository_id
        and replay_grant.provider_id == action.capability.provider_id
        and replay_grant.revision == action.capability.revision
        and replay_grant.root_authority_id == action.capability.root_authority_id
        and replay_grant.root_identity.fingerprint == action.capability.root_fingerprint
        and replay_grant.policy_digest == action.capability.policy_digest
    if fixed_grant_identity then
        if replay_grant.action_dispatches[action.action_id] then
            return nil, diagnostic("action_already_dispatched")
        end
        local preflight_used = replay_grant.effect_counts[tostring(action.generation)] or 0
        if preflight_used >= replay_grant.bounds.max_effects_per_generation then
            return nil, diagnostic("effect_limit_exhausted")
        end
    end
    local grant, root_or_err = exact_action_grant(state, action)
    if not grant then
        return nil, root_or_err
    end
    local root = root_or_err

    if grant.action_dispatches[action.action_id] then
        return nil, diagnostic("action_already_dispatched")
    end
    local generation_key = tostring(action.generation)
    local used = grant.effect_counts[generation_key] or 0
    if used >= grant.bounds.max_effects_per_generation then
        return nil, diagnostic("effect_limit_exhausted")
    end

    if root.state == "unclaimed" then
        local lifecycle_digest, lifecycle_err = digest.record({
            root_authority_id = root.root_authority_id,
            lineage_id = action.lineage_id,
            generation = action.generation,
            repository_id = grant.repository_id,
        })
        if not lifecycle_digest then
            return nil, lifecycle_err
        end
        root.state = "materializing"
        root.revision = state.next_revision
        state.next_revision = state.next_revision + 1
        root.claim = {
            lifecycle_id = "candidate-lifecycle:" .. lifecycle_digest,
            lineage_id = action.lineage_id,
            generation = action.generation,
            repository_id = grant.repository_id,
            first_action_id = action.action_id,
            claim_revision = root.revision,
        }
    end

    -- Claim and consumed authority are never refunded after this point.
    grant.effect_counts[generation_key] = used + 1
    grant.action_dispatches[action.action_id] = true

    local lease = setmetatable({}, {__metatable = "repository.effect_lease.v0"})
    effect_leases[lease] = {
        registry = registry,
        grant = grant,
        grant_revision = grant.revision,
        root = root,
        root_revision = root.revision,
        lifecycle_id = root.claim.lifecycle_id,
        generation = action.generation,
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
    if state.root.state == "seal_pending" then
        return nil, diagnostic("repository_root_seal_pending")
    end
    if state.root.state == "sealed" then
        return nil, diagnostic("repository_root_sealed")
    end
    if state.root.state == "quarantined" then
        return nil, diagnostic("repository_root_quarantined")
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
    if state.root.state ~= "materializing"
        or state.root.revision ~= state.root_revision
        or not state.root.claim
        or state.root.claim.lifecycle_id ~= state.lifecycle_id
        or state.root.claim.generation ~= state.generation then
        return nil, "repository effect lease root state changed"
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
    local result, err = with_provider_dispatch(
        registry,
        state,
        "create_text_file",
        state.grant.provider.create_text_file,
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
    return with_provider_dispatch(
        registry,
        state,
        "read_text_file",
        state.grant.provider.read_text_file,
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
    local registry_state, registry_err = state_for(registry)
    if not registry_state then
        return nil, registry_err
    end
    local lease_value = effect_leases[lease]
    if not lease_value or lease_value.registry ~= registry then
        return nil, "invalid repository effect lease"
    end
    return quarantine_root(registry_state, lease_value.root, reason)
end

return capability
