local provider = {
    protocol_version = "repository.provider_adapter.v0",
    provider_id = "linux.openat2.renameat2.v0",
    contract_id = "repository.provider.create_readback.v0",
    native_abi = "proc17.repository.fs.lua54.v0",
}

local native_protocol = "repository.native_provider.v0"
local native_symbol = "luaopen_proc17_repository_fs"
local limits = {
    max_relative_path_bytes = 1024,
    max_component_bytes = 255,
    max_components = 64,
    max_content_bytes = 1048576,
    file_mode = 384,
}

local native_keys = {
    protocol_version = true,
    abi_version = true,
    provider_id = true,
    contract_id = true,
    limits = true,
    open_repository = true,
    revalidate = true,
    create_text_file = true,
    read_text_file = true,
    inventory_tree = true,
    close = true,
}
local limit_keys = {
    max_relative_path_bytes = true,
    max_component_bytes = true,
    max_components = true,
    max_content_bytes = true,
    file_mode = true,
}
local provider_error_keys = {
    protocol_version = true,
    class = true,
    code = true,
    stage = true,
    errno = true,
    mutation_primitive_entered = true,
    published = true,
    cost = true,
    residue = true,
}
local provider_error_required = {
    protocol_version = true,
    class = true,
    code = true,
    stage = true,
    mutation_primitive_entered = true,
    published = true,
    cost = true,
}
local cost_keys = {
    tool_calls = true,
    file_writes = true,
    time_ms = true,
}
local identity_keys = {
    project_base = true,
    root = true,
    repository_path = true,
    host_path = true,
}
local filesystem_identity_keys = {
    device = true,
    inode = true,
}
local revalidation_result_keys = {
    protocol_version = true,
    operation = true,
    outcome = true,
    root = true,
    mutation_primitive_entered = true,
    published = true,
    cost = true,
}
local create_result_keys = {
    protocol_version = true,
    operation = true,
    outcome = true,
    bytes = true,
    root = true,
    mutation_primitive_entered = true,
    published = true,
    cost = true,
}
local read_result_keys = {
    protocol_version = true,
    operation = true,
    outcome = true,
    target_kind = true,
    bytes = true,
    content = true,
    root = true,
    mutation_primitive_entered = true,
    published = true,
    cost = true,
}
local read_result_required = {
    protocol_version = true,
    operation = true,
    outcome = true,
    target_kind = true,
    root = true,
    mutation_primitive_entered = true,
    published = true,
    cost = true,
}
local inventory_result_keys = {
    protocol_version = true, operation = true, outcome = true,
    root_before = true, root_after = true, stable = true, entries = true,
    bounds_observed = true, mutation_primitive_entered = true,
    published = true, cost = true,
}
local inventory_entry_keys = {
    relative_path = true, kind = true, identity_before = true,
    identity_after = true, bytes = true, content = true,
}
local inventory_entry_required = {
    relative_path = true, kind = true, identity_before = true,
    identity_after = true,
}
local inventory_bounds_keys = {
    protocol_version = true, max_entries = true, max_depth = true,
    max_path_bytes = true, max_component_bytes = true,
    max_file_bytes = true, max_total_bytes = true,
}
local observed_inventory_bounds_keys = {
    max_entries = true, max_depth = true, max_path_bytes = true,
    max_component_bytes = true, max_file_bytes = true,
    max_total_bytes = true, observed_entries = true,
    observed_total_bytes = true,
}
local residue_keys = {
    protocol_version = true,
    kind = true,
    relative_name = true,
}

local function copy_record(value, seen)
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
        result[copy_record(key, seen)] = copy_record(child, seen)
    end
    return result
end

local function fail(message)
    error("repository native provider contract failure: " .. message, 0)
end

local function exact_plain_record(value, allowed, name, required)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        fail(name .. " must be a plain table")
    end
    for key in pairs(value) do
        if not allowed[key] then
            fail(name .. " contains unknown key: " .. tostring(key))
        end
    end
    for key in pairs(required or allowed) do
        if value[key] == nil then
            fail(name .. " is missing key: " .. key)
        end
    end
end

local function non_negative_integer(value)
    return type(value) == "number"
        and value >= 0
        and value == math.floor(value)
end

local function non_negative_finite(value)
    return type(value) == "number"
        and value >= 0
        and value < math.huge
end

local function validate_cost(value, name)
    exact_plain_record(value, cost_keys, name)
    if not non_negative_integer(value.tool_calls)
        or not non_negative_integer(value.file_writes)
        or not non_negative_finite(value.time_ms) then
        fail(name .. " contains invalid economics")
    end
end

local function validate_filesystem_identity(value, name)
    exact_plain_record(value, filesystem_identity_keys, name)
    if not non_negative_integer(value.device)
        or not non_negative_integer(value.inode) then
        fail(name .. " contains invalid device/inode")
    end
end

local function derive_native_path()
    local info = debug.getinfo(1, "S")
    local source = info and info.source
    if type(source) ~= "string" or source:sub(1, 1) ~= "@" then
        fail("loader source is not a filesystem file")
    end
    local path = source:sub(2)
    if path == "" or path:find("[%z\1-\31]") or path:find("\\", 1, true)
        or path:find("//", 1, true) then
        fail("loader source path is not normalized")
    end

    local absolute = path:sub(1, 1) == "/"
    local components = {}
    for component in path:gmatch("[^/]+") do
        if component == ".." then
            fail("loader source path contains parent traversal")
        elseif component ~= "." then
            components[#components + 1] = component
        end
    end
    if #components < 2
        or components[#components - 1] ~= "runtime"
        or components[#components] ~= "repository_provider.lua" then
        fail("loader source does not have the required runtime identity")
    end

    components[#components] = nil
    components[#components] = nil
    components[#components + 1] = "native"
    components[#components + 1] = "proc17_repository_fs.so"
    return (absolute and "/" or "") .. table.concat(components, "/")
end

local function readable_file(path)
    local file = io.open(path, "rb")
    if not file then
        return false
    end
    local closed, err = file:close()
    if closed ~= true then
        fail("cannot close native module probe: " .. tostring(err))
    end
    return true
end

local function validate_native(value)
    exact_plain_record(value, native_keys, "native module")
    if value.protocol_version ~= native_protocol then
        fail("native protocol mismatch")
    end
    if value.abi_version ~= provider.native_abi then
        fail("native ABI mismatch")
    end
    if value.provider_id ~= provider.provider_id then
        fail("native provider identity mismatch")
    end
    if value.contract_id ~= provider.contract_id then
        fail("native provider contract mismatch")
    end
    exact_plain_record(value.limits, limit_keys, "native limits")
    for key, expected in pairs(limits) do
        if value.limits[key] ~= expected then
            fail("native limit mismatch: " .. key)
        end
    end
    for _, method in ipairs({
        "open_repository",
        "revalidate",
        "create_text_file",
        "read_text_file",
        "inventory_tree",
        "close",
    }) do
        if type(value[method]) ~= "function" then
            fail("native method missing: " .. method)
        end
    end
    return value
end

local function load_native(path)
    local initializer, load_err = package.loadlib(path, native_symbol)
    if type(initializer) ~= "function" then
        fail("exact native module cannot load: " .. tostring(load_err))
    end
    local results = table.pack(pcall(initializer))
    if results[1] ~= true then
        fail("native initializer failed: " .. tostring(results[2]))
    end
    if results.n ~= 2 then
        fail("native initializer must return exactly one value")
    end
    return validate_native(results[2])
end

local native_path = derive_native_path()
local native = readable_file(native_path) and load_native(native_path) or nil

provider.limits = copy_record(limits)

local function availability(code)
    return {
        protocol_version = "repository.provider_availability.v0",
        available = native ~= nil,
        code = code,
        provider_id = provider.provider_id,
        contract_id = provider.contract_id,
        native_abi = provider.native_abi,
        event_truth_status = "runtime_confirmed",
    }
end

local function unavailable(stage)
    return nil, {
        protocol_version = "repository.provider_error.v0",
        class = "world",
        code = "provider_unavailable",
        stage = stage,
        mutation_primitive_entered = false,
        published = false,
        cost = {tool_calls = 0, file_writes = 0, time_ms = 0},
    }
end

local initial_open_world = {
    path_symlink = "world",
    path_containment_denied = "world",
    root_missing = "world",
    root_invalid = "world",
    permission_denied = "world",
    provider_unavailable = "world",
    io_failure = "world",
}
local revalidation_world = {
    root_changed = "world",
    provider_unavailable = "world",
}
local create_root_world = {
    root_changed = "world",
    provider_unavailable = "world",
}
local read_root_world = {
    root_changed = "world",
    provider_unavailable = "world",
}
local read_path_world = {
    path_symlink = "world",
    path_containment_denied = "world",
    permission_denied = "world",
    provider_unavailable = "world",
    io_failure = "world",
}
local create_io_world = {
    no_space = "world",
    permission_denied = "world",
    io_failure = "world",
}
local provider_error_contracts = {
    open_repository = {
        validate_root_request = {invalid_request = "contract"},
        open_project_base = initial_open_world,
        observe_project_base = initial_open_world,
        open_repository_root = initial_open_world,
        observe_repository_root = initial_open_world,
        project_root_identity = {identity_unrepresentable = "contract"},
    },
    revalidate = {
        revalidate_handle = {handle_closed = "contract"},
        open_project_base = revalidation_world,
        observe_project_base = revalidation_world,
        open_repository_root = revalidation_world,
        observe_repository_root = revalidation_world,
        compare_root_identity = {root_changed = "world"},
        close_revalidation_descriptors = {io_failure = "world"},
    },
    close = {
        close_repository = {io_failure = "world"},
    },
    create_text_file = {
        create_handle = {handle_closed = "contract"},
        validate_create_request = {invalid_request = "contract"},
        open_project_base = create_root_world,
        observe_project_base = create_root_world,
        open_repository_root = create_root_world,
        observe_repository_root = create_root_world,
        compare_root_identity = {root_changed = "world"},
        open_parent = {
            parent_missing = "world",
            parent_not_directory = "world",
            path_symlink = "world",
            path_containment_denied = "world",
            permission_denied = "world",
            provider_unavailable = "world",
            io_failure = "world",
        },
        observe_parent_policy = {
            parent_not_private = "world",
            io_failure = "world",
        },
        getrandom = {
            provider_unavailable = "world",
            io_failure = "world",
        },
        open_temp = {
            temp_name_collision = "world",
            no_space = "world",
            permission_denied = "world",
            io_failure = "world",
        },
        set_temp_mode = create_io_world,
        observe_temp_identity = {
            temp_identity_invalid = "world",
            io_failure = "world",
        },
        write_temp = create_io_world,
        fsync_temp = create_io_world,
        close_temp = create_io_world,
        before_rename = {io_failure = "world"},
        rename_noreplace = {
            target_exists = "world",
            no_space = "world",
            permission_denied = "world",
            provider_unavailable = "world",
            io_failure = "world",
        },
        cleanup_unlink = {temp_cleanup_failed = "ambiguous"},
        after_rename = {ambiguous_effect = "ambiguous"},
        fsync_parent = {ambiguous_effect = "ambiguous"},
        close_transaction_descriptors = {ambiguous_effect = "ambiguous"},
    },
    read_text_file = {
        read_handle = {handle_closed = "contract"},
        validate_read_request = {invalid_request = "contract"},
        open_project_base = read_root_world,
        observe_project_base = read_root_world,
        open_repository_root = read_root_world,
        observe_repository_root = read_root_world,
        compare_root_identity = {root_changed = "world"},
        open_read_parent = {
            parent_missing = "world",
            parent_not_directory = "world",
            path_symlink = "world",
            path_containment_denied = "world",
            permission_denied = "world",
            provider_unavailable = "world",
            io_failure = "world",
        },
        classify_read_target = read_path_world,
        open_read_target = {
            target_changed = "world",
            path_symlink = "world",
            path_containment_denied = "world",
            permission_denied = "world",
            provider_unavailable = "world",
            io_failure = "world",
        },
        observe_read_target = {
            target_changed = "world",
            io_failure = "world",
        },
        allocate_read_buffer = {io_failure = "world"},
        read_target = {io_failure = "world"},
        verify_read_stability = {
            read_unstable = "world",
            io_failure = "world",
        },
        reobserve_read_target = {target_changed = "world"},
        close_read_descriptors = {io_failure = "world"},
    },
    inventory_tree = {
        inventory_handle = {handle_closed = "contract"},
        validate_inventory_request = {invalid_request = "contract"},
        open_project_base = {root_changed = "world", provider_unavailable = "world"},
        observe_project_base = {root_changed = "world", provider_unavailable = "world"},
        open_repository_root = {root_changed = "world", provider_unavailable = "world"},
        observe_repository_root = {root_changed = "world", provider_unavailable = "world"},
        compare_root_identity = {root_changed = "world"},
        open_inventory_root = {permission_denied = "world", io_failure = "world"},
        enumerate_inventory_tree = {
            permission_denied = "world", io_failure = "world",
        },
        reobserve_inventory_tree = {io_failure = "world"},
        verify_inventory_stability = {inventory_unstable = "world"},
        revalidate_inventory_root = {root_changed = "world"},
        close_inventory_descriptors = {io_failure = "world"},
        project_inventory_identity = {identity_unrepresentable = "contract"},
    },
}

local function validate_provider_error(operation, value)
    exact_plain_record(value, provider_error_keys,
        operation .. " provider error", provider_error_required)
    if value.protocol_version ~= "repository.provider_error.v0"
        or type(value.code) ~= "string" or value.code == ""
        or type(value.stage) ~= "string" or value.stage == ""
        or type(value.mutation_primitive_entered) ~= "boolean"
        or type(value.published) ~= "boolean" then
        fail(operation .. " returned malformed provider error")
    end
    if value.errno ~= nil
        and (not non_negative_integer(value.errno) or value.errno == 0) then
        fail(operation .. " returned invalid errno")
    end
    validate_cost(value.cost, operation .. " provider error cost")
    local stages = provider_error_contracts[operation]
    local codes = stages and stages[value.stage]
    local expected_class = codes and codes[value.code]
    if expected_class == nil or value.class ~= expected_class then
        fail(operation .. " returned unsupported error pair: "
            .. tostring(value.stage) .. "/" .. tostring(value.code))
    end

    if operation == "create_text_file" then
        local pre_call = value.stage == "validate_create_request"
            or value.stage == "create_handle"
        local pre_mutation = value.stage == "open_project_base"
            or value.stage == "observe_project_base"
            or value.stage == "open_repository_root"
            or value.stage == "observe_repository_root"
            or value.stage == "compare_root_identity"
            or value.stage == "open_parent"
            or value.stage == "observe_parent_policy"
            or value.stage == "getrandom"
        local post_publish = value.stage == "after_rename"
            or value.stage == "fsync_parent"
            or value.stage == "close_transaction_descriptors"
        local cleanup_ambiguous = value.stage == "cleanup_unlink"
        local expected_tool_calls = pre_call and 0 or 1
        local expected_file_writes = (pre_call or pre_mutation) and 0 or 1
        local expected_mutation = expected_file_writes == 1
        local expected_published = post_publish

        if value.cost.tool_calls ~= expected_tool_calls
            or value.cost.file_writes ~= expected_file_writes
            or value.mutation_primitive_entered ~= expected_mutation
            or value.published ~= expected_published then
            fail(operation .. " returned impossible stage economics")
        end
        if cleanup_ambiguous then
            exact_plain_record(value.residue, residue_keys,
                "create provider residue")
            if value.residue.protocol_version ~= "repository.provider_residue.v0"
                or value.residue.kind ~= "reserved_temp"
                or type(value.residue.relative_name) ~= "string"
                or #value.residue.relative_name ~= 44
                or not value.residue.relative_name:match(
                    "^%.proc17%-tmp%-%x+$") then
                fail(operation .. " returned malformed temporary residue")
            end
        elseif value.residue ~= nil then
            fail(operation .. " returned residue outside cleanup ambiguity")
        end
        return copy_record(value)
    end

    if operation == "read_text_file" then
        if value.mutation_primitive_entered ~= false
            or value.published ~= false
            or value.cost.file_writes ~= 0
            or value.residue ~= nil then
            fail(operation .. " reported mutation or residue")
        end
        local pre_call = value.stage == "read_handle"
            or value.stage == "validate_read_request"
        if value.cost.tool_calls ~= (pre_call and 0 or 1) then
            fail(operation .. " returned impossible tool-call cost")
        end
        return copy_record(value)
    end

    if operation == "inventory_tree" then
        if value.mutation_primitive_entered ~= false
            or value.published ~= false
            or value.cost.file_writes ~= 0
            or value.residue ~= nil then
            fail(operation .. " reported mutation or residue")
        end
        local pre_call = value.stage == "inventory_handle"
            or value.stage == "validate_inventory_request"
        if value.cost.tool_calls ~= (pre_call and 0 or 1) then
            fail(operation .. " returned impossible tool-call cost")
        end
        return copy_record(value)
    end

    if value.mutation_primitive_entered ~= false
        or value.published ~= false
        or value.cost.file_writes ~= 0
        or value.residue ~= nil then
        fail(operation .. " root operation reported mutation")
    end
    local zero_cost_stage = value.stage == "validate_root_request"
        or value.stage == "revalidate_handle"
        or value.stage == "close_repository"
    local expected_tool_calls = zero_cost_stage and 0 or 1
    if value.cost.tool_calls ~= expected_tool_calls then
        fail(operation .. " returned impossible tool-call cost")
    end
    return copy_record(value)
end

local function invoke_native(operation, ...)
    local called = table.pack(pcall(native[operation], ...))
    if called[1] ~= true then
        fail(operation .. " raised: " .. tostring(called[2]))
    end
    return called
end

local function validate_open_identity(value, input)
    exact_plain_record(value, identity_keys, "repository identity")
    validate_filesystem_identity(value.project_base, "project-base identity")
    validate_filesystem_identity(value.root, "repository-root identity")
    if value.repository_path ~= input.repository_path then
        fail("repository identity path mismatch")
    end
    local expected_host_path = input.project_base .. "/" .. input.repository_path
    if value.host_path ~= expected_host_path then
        fail("repository identity host path mismatch")
    end
    return copy_record(value)
end

local function validate_revalidation_result(value)
    exact_plain_record(value, revalidation_result_keys, "revalidation result")
    validate_filesystem_identity(value.root, "revalidated root identity")
    validate_cost(value.cost, "revalidation cost")
    if value.protocol_version ~= "repository.provider_result.v0"
        or value.operation ~= "revalidate"
        or value.outcome ~= "valid"
        or value.mutation_primitive_entered ~= false
        or value.published ~= false
        or value.cost.tool_calls ~= 1
        or value.cost.file_writes ~= 0 then
        fail("revalidate returned contradictory success")
    end
    return copy_record(value)
end

local create_request_keys = {
    protocol_version = true,
    relative_path = true,
    content = true,
    content_bytes = true,
    precondition = true,
    file_mode = true,
}

local function invalid_create_request()
    return nil, {
        protocol_version = "repository.provider_error.v0",
        class = "contract",
        code = "invalid_request",
        stage = "validate_create_request",
        mutation_primitive_entered = false,
        published = false,
        cost = {tool_calls = 0, file_writes = 0, time_ms = 0},
    }
end

local function valid_relative_path(value)
    if type(value) ~= "string" or #value == 0
        or #value > limits.max_relative_path_bytes
        or value:sub(1, 1) == "/" or value:sub(-1) == "/"
        or value:find("//", 1, true)
        or value:find("%z") or value:find("[%z\1-\31]") then
        return false
    end
    local count = 0
    for component in value:gmatch("[^/]+") do
        count = count + 1
        if count > limits.max_components
            or #component > limits.max_component_bytes
            or not component:match("^[A-Za-z0-9][A-Za-z0-9._-]*$")
            or component == ".git" or component == ".agents"
            or component == ".codex" or component == "packets"
            or component == "graves" or component == "compost"
            or component == "trace" then
            return false
        end
    end
    return count > 0
end

local function validate_create_request(value)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return invalid_create_request()
    end
    for key in pairs(value) do
        if not create_request_keys[key] then
            return invalid_create_request()
        end
    end
    for key in pairs(create_request_keys) do
        if value[key] == nil then
            return invalid_create_request()
        end
    end
    if value.protocol_version ~= "repository.create_text_file.request.v0"
        or not valid_relative_path(value.relative_path)
        or type(value.content) ~= "string"
        or #value.content > limits.max_content_bytes
        or value.content:find("\0", 1, true)
        or utf8.len(value.content) == nil
        or not non_negative_integer(value.content_bytes)
        or value.content_bytes ~= #value.content
        or value.precondition ~= "absent"
        or value.file_mode ~= limits.file_mode then
        return invalid_create_request()
    end
    return true
end

local function validate_create_result(value)
    exact_plain_record(value, create_result_keys, "create result")
    validate_filesystem_identity(value.root, "create root identity")
    validate_cost(value.cost, "create result cost")
    if value.protocol_version ~= "repository.provider_result.v0"
        or value.operation ~= "create_text_file"
        or value.outcome ~= "created"
        or not non_negative_integer(value.bytes)
        or value.bytes > limits.max_content_bytes
        or value.mutation_primitive_entered ~= true
        or value.published ~= true
        or value.cost.tool_calls ~= 1
        or value.cost.file_writes ~= 1 then
        fail("create_text_file returned contradictory success")
    end
    return copy_record(value)
end

local read_request_keys = {
    relative_path = true,
    max_bytes = true,
}

local function invalid_read_request()
    return nil, {
        protocol_version = "repository.provider_error.v0",
        class = "contract",
        code = "invalid_request",
        stage = "validate_read_request",
        mutation_primitive_entered = false,
        published = false,
        cost = {tool_calls = 0, file_writes = 0, time_ms = 0},
    }
end

local function validate_read_request(value)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return invalid_read_request()
    end
    for key in pairs(value) do
        if not read_request_keys[key] then
            return invalid_read_request()
        end
    end
    for key in pairs(read_request_keys) do
        if value[key] == nil then
            return invalid_read_request()
        end
    end
    if not valid_relative_path(value.relative_path)
        or not non_negative_integer(value.max_bytes)
        or value.max_bytes < 1
        or value.max_bytes > limits.max_content_bytes + 1 then
        return invalid_read_request()
    end
    return true
end

local function validate_read_result(value, request)
    exact_plain_record(value, read_result_keys, "read result",
        read_result_required)
    validate_filesystem_identity(value.root, "read root identity")
    validate_cost(value.cost, "read result cost")
    if value.protocol_version ~= "repository.provider_result.v0"
        or value.operation ~= "read_text_file"
        or value.outcome ~= "observed"
        or (value.target_kind ~= "regular_file"
            and value.target_kind ~= "missing"
            and value.target_kind ~= "other")
        or value.mutation_primitive_entered ~= false
        or value.published ~= false
        or value.cost.tool_calls ~= 1
        or value.cost.file_writes ~= 0 then
        fail("read_text_file returned contradictory success")
    end
    if value.target_kind == "regular_file" then
        if not non_negative_integer(value.bytes)
            or value.bytes > request.max_bytes
            or type(value.content) ~= "string"
            or #value.content ~= value.bytes then
            fail("read_text_file returned an invalid bounded observation")
        end
    elseif value.bytes ~= nil or value.content ~= nil then
        fail("read_text_file returned content for a non-regular target")
    end
    return copy_record(value)
end

local function invalid_inventory_request()
    return nil, {
        protocol_version = "repository.provider_error.v0",
        class = "contract",
        code = "invalid_request",
        stage = "validate_inventory_request",
        mutation_primitive_entered = false,
        published = false,
        cost = {tool_calls = 0, file_writes = 0, time_ms = 0},
    }
end

local function validate_inventory_request(value)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return invalid_inventory_request()
    end
    for key in pairs(value) do
        if not inventory_bounds_keys[key] then
            return invalid_inventory_request()
        end
    end
    for key in pairs(inventory_bounds_keys) do
        if value[key] == nil then
            return invalid_inventory_request()
        end
    end
    if value.protocol_version ~= "repository.inventory_bounds.v0" then
        return invalid_inventory_request()
    end
    local ceilings = {
        max_entries = 4096,
        max_depth = limits.max_components,
        max_path_bytes = limits.max_relative_path_bytes,
        max_component_bytes = limits.max_component_bytes,
        max_file_bytes = limits.max_content_bytes,
        max_total_bytes = 67108864,
    }
    for key, ceiling in pairs(ceilings) do
        if not non_negative_integer(value[key]) or value[key] < 1
            or value[key] > ceiling then
            return invalid_inventory_request()
        end
    end
    return true
end

local function strict_array(value, name)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        fail(name .. " must be an array")
    end
    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            fail(name .. " must be an array")
        end
        count = count + 1
    end
    if count ~= #value then
        fail(name .. " must be a dense array")
    end
end

local function valid_inventory_path(value, request)
    if type(value) ~= "string" or value == "" or value:sub(1, 1) == "/"
        or value:sub(-1) == "/" or #value > request.max_path_bytes
        or value:find("//", 1, true) or value:find("%z")
        or value:find("[%z\1-\31]") or utf8.len(value) == nil then
        return false
    end
    local depth = 0
    for component in value:gmatch("[^/]+") do
        depth = depth + 1
        if component == "." or component == ".."
            or #component > request.max_component_bytes
            or depth > request.max_depth then
            return false
        end
    end
    return depth > 0
end

local function validate_inventory_result(value, request)
    exact_plain_record(value, inventory_result_keys, "inventory result")
    validate_filesystem_identity(value.root_before, "inventory root_before")
    validate_filesystem_identity(value.root_after, "inventory root_after")
    validate_cost(value.cost, "inventory result cost")
    if value.protocol_version ~= "repository.provider_inventory_result.v0"
        or value.operation ~= "inventory_tree"
        or (value.outcome ~= "observed" and value.outcome ~= "bound_exceeded")
        or type(value.stable) ~= "boolean"
        or value.mutation_primitive_entered ~= false
        or value.published ~= false
        or value.cost.tool_calls ~= 1
        or value.cost.file_writes ~= 0 then
        fail("inventory_tree returned contradictory success")
    end
    exact_plain_record(value.bounds_observed, observed_inventory_bounds_keys,
        "inventory observed bounds")
    for key in pairs(inventory_bounds_keys) do
        if key ~= "protocol_version"
            and value.bounds_observed[key] ~= request[key] then
            fail("inventory_tree changed bound: " .. key)
        end
    end
    if not non_negative_integer(value.bounds_observed.observed_entries)
        or not non_negative_integer(value.bounds_observed.observed_total_bytes) then
        fail("inventory_tree returned invalid observed counts")
    end
    strict_array(value.entries, "inventory entries")
    if #value.entries > request.max_entries
        or #value.entries ~= value.bounds_observed.observed_entries then
        fail("inventory_tree entry count contradicts bounds")
    end
    local total = 0
    local previous
    for _, entry in ipairs(value.entries) do
        exact_plain_record(entry, inventory_entry_keys, "inventory entry",
            inventory_entry_required)
        if not valid_inventory_path(entry.relative_path, request)
            or (previous and entry.relative_path <= previous)
            or (entry.kind ~= "directory" and entry.kind ~= "regular_file"
                and entry.kind ~= "symlink" and entry.kind ~= "special") then
            fail("inventory_tree returned invalid canonical entry")
        end
        previous = entry.relative_path
        validate_filesystem_identity(entry.identity_before,
            "inventory entry identity_before")
        validate_filesystem_identity(entry.identity_after,
            "inventory entry identity_after")
        if entry.kind == "regular_file" then
            if not non_negative_integer(entry.bytes)
                or entry.bytes > request.max_file_bytes
                or type(entry.content) ~= "string"
                or #entry.content ~= entry.bytes then
                fail("inventory_tree returned invalid bounded file")
            end
            total = total + entry.bytes
            if total > request.max_total_bytes then
                fail("inventory_tree exceeded aggregate byte bound")
            end
        elseif entry.bytes ~= nil or entry.content ~= nil then
            fail("inventory_tree returned bytes for non-file entry")
        end
    end
    if total ~= value.bounds_observed.observed_total_bytes then
        fail("inventory_tree byte total contradicts bounds")
    end
    return copy_record(value)
end

local function exact_input(value, allowed, name)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        error(name .. " must be a plain table", 2)
    end
    for key in pairs(value) do
        if not allowed[key] then
            error(name .. " contains unknown key: " .. tostring(key), 2)
        end
    end
end

function provider.available()
    if native then
        return true, availability("provider_shell_loaded")
    end
    return false, availability("provider_unavailable")
end

function provider.open_repository(input)
    exact_input(input, {project_base = true, repository_path = true},
        "repository open input")
    if type(input.project_base) ~= "string" or input.project_base == ""
        or type(input.repository_path) ~= "string" or input.repository_path == "" then
        error("repository open input requires project_base and repository_path", 2)
    end
    if not native then
        return unavailable("native_module_absent")
    end
    local called = invoke_native("open_repository",
        input.project_base, input.repository_path)
    if called.n ~= 3 then
        fail("open_repository must return exactly two values")
    end
    if called[2] == nil then
        return nil, validate_provider_error("open_repository", called[3])
    end
    if type(called[2]) ~= "userdata"
        or getmetatable(called[2]) ~= "repository.handle.v0" then
        fail("open_repository returned a non-opaque handle")
    end
    return called[2], validate_open_identity(called[3], input)
end

local function require_handle(handle)
    if type(handle) ~= "userdata"
        or getmetatable(handle) ~= "repository.handle.v0" then
        error("repository provider handle must be opaque userdata", 3)
    end
end

function provider.revalidate(handle)
    if not native then
        return unavailable("native_module_absent")
    end
    require_handle(handle)
    local called = invoke_native("revalidate", handle)
    if called[2] == nil then
        if called.n ~= 3 then
            fail("revalidate failure must return exactly two values")
        end
        return nil, validate_provider_error("revalidate", called[3])
    end
    if called.n ~= 2 then
        fail("revalidate success must return exactly one value")
    end
    return validate_revalidation_result(called[2])
end

function provider.create_text_file(handle, request)
    if not native then
        return unavailable("native_module_absent")
    end
    require_handle(handle)
    local valid, request_err = validate_create_request(request)
    if not valid then
        return nil, copy_record(request_err)
    end
    local called = invoke_native("create_text_file",
        handle, request.relative_path, request.content, request.file_mode)
    if called[2] == nil then
        if called.n ~= 3 then
            fail("create_text_file failure must return exactly two values")
        end
        return nil, validate_provider_error("create_text_file", called[3])
    end
    if called.n ~= 2 then
        fail("create_text_file success must return exactly one value")
    end
    local result = validate_create_result(called[2])
    if result.bytes ~= request.content_bytes then
        fail("create_text_file byte count contradicts request")
    end
    return result
end

function provider.read_text_file(handle, request)
    if not native then
        return unavailable("native_module_absent")
    end
    require_handle(handle)
    local valid, request_err = validate_read_request(request)
    if not valid then
        return nil, copy_record(request_err)
    end
    local called = invoke_native("read_text_file",
        handle, request.relative_path, request.max_bytes)
    if called[2] == nil then
        if called.n ~= 3 then
            fail("read_text_file failure must return exactly two values")
        end
        return nil, validate_provider_error("read_text_file", called[3])
    end
    if called.n ~= 2 then
        fail("read_text_file success must return exactly one value")
    end
    return validate_read_result(called[2], request)
end

function provider.inventory_tree(handle, request)
    if not native then
        return unavailable("native_module_absent")
    end
    require_handle(handle)
    local valid, request_err = validate_inventory_request(request)
    if not valid then
        return nil, copy_record(request_err)
    end
    local called = invoke_native("inventory_tree",
        handle,
        request.max_entries,
        request.max_depth,
        request.max_path_bytes,
        request.max_component_bytes,
        request.max_file_bytes,
        request.max_total_bytes)
    if called[2] == nil then
        if called.n ~= 3 then
            fail("inventory_tree failure must return exactly two values")
        end
        return nil, validate_provider_error("inventory_tree", called[3])
    end
    if called.n ~= 2 then
        fail("inventory_tree success must return exactly one value")
    end
    return validate_inventory_result(called[2], request)
end

function provider.close(handle)
    if not native then
        return unavailable("native_module_absent")
    end
    require_handle(handle)
    local called = invoke_native("close", handle)
    if called[2] == nil then
        if called.n ~= 3 then
            fail("close failure must return exactly two values")
        end
        return nil, validate_provider_error("close", called[3])
    end
    if called.n ~= 2 or called[2] ~= true then
        fail("close must return exactly true")
    end
    return true
end

return provider
