local digest = require("core.digest")

local qa_schema = {
    contract_protocol = "qa.contract.v0",
    profile_protocol = "qa.profile.v0",
    environment_v0_protocol = "qa.environment.v0",
    environment_protocol = "qa.environment.v1",
    environment_v1_protocol = "qa.environment.v1",
    resource_limits_protocol = "qa.resource_limits.v0",
    profile_id = "qa.profile.lua54_test_suite.v0",
    provider_id = "linux.qa_supervisor.lua54.v0",
    supervisor_abi = "proc17.qa_supervisor.v0",
    check_kind = "lua54_test_suite.v0",
    execution_policy = "single_required_check.v0",
    runtime_heap_limit_bytes = 67108864,
}

local MAX_ID_BYTES = 1024
local MAX_REF_BYTES = 4096
local MAX_SOURCE_REFS = 256

local limit_names = {
    "protocol_version",
    "wall_time_ms",
    "cpu_time_ms",
    "address_space_bytes",
    "max_processes",
    "max_open_files",
    "max_file_bytes",
    "scratch_bytes",
    "scratch_entries",
    "stdout_bytes",
    "stderr_bytes",
}

local hard_limits = {
    protocol_version = qa_schema.resource_limits_protocol,
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

local function same_value(left, right, seen)
    if type(left) ~= type(right) then
        return false
    end
    if type(left) ~= "table" then
        return left == right
    end
    seen = seen or {}
    local prior = seen[left]
    if prior ~= nil then
        return prior == right
    end
    seen[left] = right
    for key, value in pairs(left) do
        if not same_value(value, right[key], seen) then
            return false
        end
    end
    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end
    return true
end

local function validate_plain_tree(value, name, active, seen)
    if type(value) ~= "table" then
        return nil, name .. " must be a plain table"
    end
    if getmetatable(value) ~= nil then
        return nil, name .. " must not have a metatable"
    end
    active = active or {}
    seen = seen or {}
    if active[value] then
        return nil, name .. " must be acyclic"
    end
    if seen[value] then
        return true
    end
    active[value] = true
    for key, child in pairs(value) do
        local key_type = type(key)
        if key_type ~= "string" and key_type ~= "number" then
            return nil, name .. " contains an unsupported key type"
        end
        local child_type = type(child)
        if child_type == "table" then
            local ok, err = validate_plain_tree(child, name, active, seen)
            if not ok then
                return nil, err
            end
        elseif child_type ~= "string" and child_type ~= "number"
            and child_type ~= "boolean" then
            return nil, name .. " contains an unsupported value type"
        end
    end
    active[value] = nil
    seen[value] = true
    return true
end

local function key_set(names)
    local result = {}
    for _, name in ipairs(names) do
        result[name] = true
    end
    return result
end

local function exact_keys(value, names, optional, label)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, label .. " must be a plain table"
    end
    local allowed = key_set(names)
    optional = optional or {}
    for key in pairs(value) do
        if not allowed[key] then
            return nil, label .. " contains unknown key: " .. tostring(key)
        end
    end
    for _, key in ipairs(names) do
        if value[key] == nil and not optional[key] then
            return nil, label .. " is missing key: " .. key
        end
    end
    return true
end

local function dense_array(value, label, expected_length)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, label .. " must be a dense array"
    end
    local count = 0
    local maximum = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            return nil, label .. " must be a dense array"
        end
        count = count + 1
        maximum = math.max(maximum, key)
    end
    if count ~= maximum then
        return nil, label .. " must be a dense array"
    end
    if expected_length ~= nil and count ~= expected_length then
        return nil, label .. " must contain exactly " .. tostring(expected_length) .. " item(s)"
    end
    return true
end

local function bounded_string(value, label, maximum, allow_empty)
    if type(value) ~= "string" or (not allow_empty and value == "") then
        return nil, label .. " must be a non-empty string"
    end
    if #value > maximum then
        return nil, label .. " exceeds its byte ceiling"
    end
    if value:find("[%z\1-\31\127]") then
        return nil, label .. " contains a control byte"
    end
    if utf8.len(value) == nil then
        return nil, label .. " must be valid UTF-8"
    end
    return value
end

local function positive_integer(value, label)
    if type(value) ~= "number" or value < 1 or value ~= math.floor(value) then
        return nil, label .. " must be a positive integer"
    end
    return value
end

local function prefixed_digest(value, prefix)
    return type(value) == "string"
        and #value == #prefix + 64
        and value:sub(1, #prefix) == prefix
        and value:sub(#prefix + 1):match("^[0-9a-f]+$") ~= nil
end

local function normalize_source_refs(value, label)
    local array_ok, array_err = dense_array(value, label)
    if not array_ok then
        return nil, array_err
    end
    if #value > MAX_SOURCE_REFS then
        return nil, label .. " exceeds its item ceiling"
    end
    local result = {}
    local seen = {}
    for index, item in ipairs(value) do
        local normalized, err = bounded_string(
            item,
            label .. "[" .. tostring(index) .. "]",
            MAX_REF_BYTES
        )
        if not normalized then
            return nil, err
        end
        if not seen[normalized] then
            seen[normalized] = true
            result[#result + 1] = normalized
        end
    end
    table.sort(result)
    return result
end

local function validate_relative_path(value)
    local normalized, err = bounded_string(value, "QA entrypoint path", 1024)
    if not normalized then
        return nil, err
    end
    if normalized:sub(1, 1) == "/" or normalized:sub(-1) == "/"
        or normalized:find("//", 1, true) then
        return nil, "QA entrypoint path must be normalized and relative"
    end
    local components = 0
    for component in normalized:gmatch("[^/]+") do
        components = components + 1
        if component == "." or component == ".." or component:sub(1, 1) == "." then
            return nil, "QA entrypoint path contains a forbidden component"
        end
        if #component > 255 then
            return nil, "QA entrypoint path component exceeds its byte ceiling"
        end
    end
    if components < 1 or components > 64 then
        return nil, "QA entrypoint path has an invalid component count"
    end
    return normalized
end

function qa_schema.hard_limits()
    return copy_value(hard_limits)
end

function qa_schema.normalize_limits(input)
    local tree_ok, tree_err = validate_plain_tree(input, "QA resource limits")
    if not tree_ok then
        return nil, tree_err
    end
    local keys_ok, keys_err = exact_keys(input, limit_names, nil, "QA resource limits")
    if not keys_ok then
        return nil, keys_err
    end
    if input.protocol_version ~= qa_schema.resource_limits_protocol then
        return nil, "unsupported QA resource limits protocol"
    end
    local result = {protocol_version = qa_schema.resource_limits_protocol}
    for _, name in ipairs(limit_names) do
        if name ~= "protocol_version" then
            local normalized, err = positive_integer(input[name], "QA limit " .. name)
            if not normalized then
                return nil, err
            end
            if normalized > hard_limits[name] then
                return nil, "QA limit exceeds hard profile ceiling: " .. name
            end
            result[name] = normalized
        end
    end
    if result.max_processes ~= 1 then
        return nil, "QA max_processes must be exactly one"
    end
    if result.cpu_time_ms % 1000 ~= 0 then
        return nil, "QA cpu_time_ms must be a positive multiple of 1000"
    end
    return result
end

local function build_profile()
    local value = {
        protocol_version = qa_schema.profile_protocol,
        profile_id = qa_schema.profile_id,
        provider_id = qa_schema.provider_id,
        language_runtime = "lua-5.4",
        invocation_kind = "sealed_lua_test_entrypoint",
        source_cwd = true,
        stdin = "closed",
        caller_arguments = "forbidden",
        caller_environment = "forbidden",
        shell = "forbidden",
        network = "forbidden",
        child_processes = "forbidden",
        native_modules = "forbidden",
        source_writes = "forbidden",
        scratch_writes = "bounded",
        lua_policy = {
            ignore_host_environment = true,
            package_path = "./?.lua;./?/init.lua",
            package_cpath = "",
        },
        hard_limits = copy_value(hard_limits),
        event_truth_status = "runtime_confirmed",
    }
    local policy_digest, err = digest.record(value)
    assert(policy_digest, err)
    value.policy_digest = "sha256:" .. policy_digest
    return value
end

function qa_schema.profile()
    return copy_value(build_profile())
end

function qa_schema.verify_profile(value)
    local tree_ok, tree_err = validate_plain_tree(value, "QA profile")
    if not tree_ok then
        return nil, tree_err
    end
    if not same_value(value, build_profile()) then
        return nil, "QA profile does not match the closed v0 profile"
    end
    return true
end

local environment_names = {
    "protocol_version", "environment_id", "profile_id", "provider_id",
    "provider_build_id", "supervisor_abi", "supervisor_build_id",
    "runtime_dependency_closure_id", "runtime_name", "runtime_build_id",
    "platform", "machine_arch", "kernel_identity_id",
    "isolation_feature_set_id", "isolation_policy_digest",
    "hard_limits_digest", "event_truth_status",
}

function qa_schema.normalize_environment_v0(input)
    local tree_ok, tree_err = validate_plain_tree(input, "QA environment")
    if not tree_ok then
        return nil, tree_err
    end
    local keys_ok, keys_err = exact_keys(input, environment_names,
        {environment_id = true}, "QA environment")
    if not keys_ok then
        return nil, keys_err
    end
    if input.protocol_version ~= qa_schema.environment_v0_protocol
        or input.profile_id ~= qa_schema.profile_id
        or input.provider_id ~= qa_schema.provider_id
        or input.supervisor_abi ~= qa_schema.supervisor_abi
        or input.runtime_name ~= "Lua 5.4"
        or input.platform ~= "linux"
        or input.event_truth_status ~= "runtime_confirmed" then
        return nil, "QA environment envelope is not the closed v0 environment"
    end
    local machine_arch, arch_err = bounded_string(input.machine_arch,
        "QA machine architecture", 128)
    if not machine_arch then
        return nil, arch_err
    end
    for _, name in ipairs({
        "provider_build_id", "supervisor_build_id",
        "runtime_dependency_closure_id", "runtime_build_id",
        "kernel_identity_id", "isolation_feature_set_id",
        "isolation_policy_digest", "hard_limits_digest",
    }) do
        if not prefixed_digest(input[name], "sha256:") then
            return nil, "QA environment digest is invalid: " .. name
        end
    end
    local expected_limits_digest, digest_err = digest.record(hard_limits)
    if not expected_limits_digest then
        return nil, digest_err
    end
    if input.hard_limits_digest ~= "sha256:" .. expected_limits_digest then
        return nil, "QA environment hard limits do not match the profile"
    end
    local normalized = copy_value(input)
    normalized.environment_id = nil
    normalized.machine_arch = machine_arch
    local environment_digest, environment_err = digest.record(normalized)
    if not environment_digest then
        return nil, environment_err
    end
    normalized.environment_id = "qa-environment:" .. environment_digest
    if input.environment_id ~= nil
        and input.environment_id ~= normalized.environment_id then
        return nil, "QA environment identity mismatch"
    end
    return normalized
end

function qa_schema.verify_environment_v0(value)
    if type(value) ~= "table" or value.environment_id == nil then
        return nil, "QA environment identity is required"
    end
    local normalized, err = qa_schema.normalize_environment_v0(value)
    if not normalized then
        return nil, err
    end
    if not same_value(value, normalized) then
        return nil, "QA environment is not normalized"
    end
    return true
end

local environment_v1_names = {
    "protocol_version", "environment_id", "profile_id", "provider_id",
    "provider_build_id", "supervisor_abi", "supervisor_build_id",
    "runtime_dependency_closure_id", "runtime_name", "runtime_build_id",
    "runtime_heap_limit_bytes", "platform", "machine_arch",
    "kernel_identity_id", "isolation_feature_set_id",
    "isolation_policy_digest", "hard_limits_digest", "event_truth_status",
}

function qa_schema.normalize_environment_v1(input)
    local tree_ok, tree_err = validate_plain_tree(input, "QA v1 environment")
    if not tree_ok then
        return nil, tree_err
    end
    local keys_ok, keys_err = exact_keys(input, environment_v1_names,
        {environment_id = true}, "QA v1 environment")
    if not keys_ok then
        return nil, keys_err
    end
    if input.protocol_version ~= qa_schema.environment_v1_protocol
        or input.profile_id ~= qa_schema.profile_id
        or input.provider_id ~= qa_schema.provider_id
        or input.supervisor_abi ~= qa_schema.supervisor_abi
        or input.runtime_name ~= "Lua 5.4"
        or input.runtime_heap_limit_bytes ~= qa_schema.runtime_heap_limit_bytes
        or input.platform ~= "linux"
        or input.event_truth_status ~= "runtime_confirmed" then
        return nil, "QA environment envelope is not the closed v1 environment"
    end
    local machine_arch, arch_err = bounded_string(input.machine_arch,
        "QA machine architecture", 128)
    if not machine_arch then
        return nil, arch_err
    end
    for _, name in ipairs({
        "provider_build_id", "supervisor_build_id",
        "runtime_dependency_closure_id", "runtime_build_id",
        "kernel_identity_id", "isolation_feature_set_id",
        "isolation_policy_digest", "hard_limits_digest",
    }) do
        if not prefixed_digest(input[name], "sha256:") then
            return nil, "QA v1 environment digest is invalid: " .. name
        end
    end
    local expected_limits_digest, digest_err = digest.record(hard_limits)
    if not expected_limits_digest then
        return nil, digest_err
    end
    if input.hard_limits_digest ~= "sha256:" .. expected_limits_digest then
        return nil, "QA v1 environment hard limits do not match the profile"
    end
    local normalized = copy_value(input)
    normalized.environment_id = nil
    normalized.machine_arch = machine_arch
    local environment_digest, environment_err = digest.record(normalized)
    if not environment_digest then
        return nil, environment_err
    end
    normalized.environment_id = "qa-environment:" .. environment_digest
    if input.environment_id ~= nil
        and input.environment_id ~= normalized.environment_id then
        return nil, "QA v1 environment identity mismatch"
    end
    return normalized
end

function qa_schema.verify_environment_v1(value)
    if type(value) ~= "table" or value.environment_id == nil then
        return nil, "QA v1 environment identity is required"
    end
    local normalized, err = qa_schema.normalize_environment_v1(value)
    if not normalized then
        return nil, err
    end
    if not same_value(value, normalized) then
        return nil, "QA v1 environment is not normalized"
    end
    return true
end

function qa_schema.normalize_environment(value)
    return qa_schema.normalize_environment_v1(value)
end

function qa_schema.verify_environment(value)
    return qa_schema.verify_environment_v1(value)
end

local contract_names = {
    "protocol_version", "qa_contract_id", "lineage_id",
    "process_contract_id", "context", "stage_id", "execution_policy",
    "required_checks", "source_refs", "event_truth_status",
    "content_truth_status",
}
local check_names = {
    "check_id", "ordinal", "required", "kind", "profile_id",
    "environment_id", "entrypoint", "invocation", "resource_limits",
    "output_policy",
}

local function normalize_check(input)
    local keys_ok, keys_err = exact_keys(input, check_names, {check_id = true},
        "QA required check")
    if not keys_ok then
        return nil, keys_err
    end
    if input.ordinal ~= 1 or input.required ~= true
        or input.kind ~= qa_schema.check_kind
        or input.profile_id ~= qa_schema.profile_id
        or not prefixed_digest(input.environment_id, "qa-environment:") then
        return nil, "QA required check envelope is invalid"
    end
    local entrypoint_ok, entrypoint_err = exact_keys(input.entrypoint,
        {"relative_path", "expected_kind"}, nil, "QA entrypoint")
    if not entrypoint_ok then
        return nil, entrypoint_err
    end
    local relative_path, path_err = validate_relative_path(input.entrypoint.relative_path)
    if not relative_path then
        return nil, path_err
    end
    if input.entrypoint.expected_kind ~= "regular_file" then
        return nil, "QA entrypoint must require a regular file"
    end
    local invocation_ok, invocation_err = exact_keys(input.invocation,
        {"stdin", "arguments", "expected_exit_codes"}, nil, "QA invocation")
    if not invocation_ok then
        return nil, invocation_err
    end
    if input.invocation.stdin ~= "closed" then
        return nil, "QA invocation stdin must be closed"
    end
    local arguments_ok, arguments_err = dense_array(input.invocation.arguments,
        "QA invocation arguments", 0)
    if not arguments_ok then
        return nil, arguments_err
    end
    local exits_ok, exits_err = dense_array(input.invocation.expected_exit_codes,
        "QA expected exit codes", 1)
    if not exits_ok then
        return nil, exits_err
    end
    if input.invocation.expected_exit_codes[1] ~= 0 then
        return nil, "QA expected exit code must be exactly zero"
    end
    local output_ok, output_err = exact_keys(input.output_policy,
        {"authority", "retain_raw_output"}, nil, "QA output policy")
    if not output_ok then
        return nil, output_err
    end
    if input.output_policy.authority ~= "exit_status_only"
        or input.output_policy.retain_raw_output ~= false then
        return nil, "QA output policy is invalid"
    end
    local limits, limits_err = qa_schema.normalize_limits(input.resource_limits)
    if not limits then
        return nil, limits_err
    end
    local normalized = {
        ordinal = 1,
        required = true,
        kind = qa_schema.check_kind,
        profile_id = qa_schema.profile_id,
        environment_id = input.environment_id,
        entrypoint = {
            relative_path = relative_path,
            expected_kind = "regular_file",
        },
        invocation = {
            stdin = "closed",
            arguments = {},
            expected_exit_codes = {0},
        },
        resource_limits = limits,
        output_policy = {
            authority = "exit_status_only",
            retain_raw_output = false,
        },
    }
    local check_digest, check_err = digest.record(normalized)
    if not check_digest then
        return nil, check_err
    end
    normalized.check_id = "qa-check-contract:" .. check_digest
    if input.check_id ~= nil and input.check_id ~= normalized.check_id then
        return nil, "QA required check identity mismatch"
    end
    return normalized
end

function qa_schema.normalize_contract(input)
    local tree_ok, tree_err = validate_plain_tree(input, "QA contract")
    if not tree_ok then
        return nil, tree_err
    end
    local keys_ok, keys_err = exact_keys(input, contract_names,
        {qa_contract_id = true}, "QA contract")
    if not keys_ok then
        return nil, keys_err
    end
    if input.protocol_version ~= qa_schema.contract_protocol
        or (input.process_contract_id ~= "build.only.v0"
            and input.process_contract_id ~= "software.create.v0")
        or input.context ~= "software_task.v0"
        or input.execution_policy ~= qa_schema.execution_policy
        or input.event_truth_status ~= "runtime_confirmed"
        or (input.content_truth_status ~= "runtime_confirmed"
            and input.content_truth_status ~= "mixed") then
        return nil, "QA contract envelope is invalid"
    end
    local lineage_id, lineage_err = bounded_string(input.lineage_id,
        "QA contract lineage_id", MAX_ID_BYTES)
    if not lineage_id then
        return nil, lineage_err
    end
    local stage_id, stage_err = bounded_string(input.stage_id,
        "QA contract stage_id", MAX_ID_BYTES)
    if not stage_id then
        return nil, stage_err
    end
    local checks_ok, checks_err = dense_array(input.required_checks,
        "QA required_checks", 1)
    if not checks_ok then
        return nil, checks_err
    end
    local check, check_err = normalize_check(input.required_checks[1])
    if not check then
        return nil, check_err
    end
    local source_refs, refs_err = normalize_source_refs(input.source_refs,
        "QA contract source_refs")
    if not source_refs then
        return nil, refs_err
    end
    local normalized = {
        protocol_version = qa_schema.contract_protocol,
        lineage_id = lineage_id,
        process_contract_id = input.process_contract_id,
        context = "software_task.v0",
        stage_id = stage_id,
        execution_policy = qa_schema.execution_policy,
        required_checks = {check},
        source_refs = source_refs,
        event_truth_status = "runtime_confirmed",
        content_truth_status = input.content_truth_status,
    }
    local contract_digest, contract_err = digest.record(normalized)
    if not contract_digest then
        return nil, contract_err
    end
    normalized.qa_contract_id = "qa-contract:" .. contract_digest
    if input.qa_contract_id ~= nil and input.qa_contract_id ~= normalized.qa_contract_id then
        return nil, "QA contract identity mismatch"
    end
    return normalized
end

function qa_schema.verify_contract(value)
    if type(value) ~= "table" or value.qa_contract_id == nil then
        return nil, "QA contract identity is required"
    end
    local normalized, err = qa_schema.normalize_contract(value)
    if not normalized then
        return nil, err
    end
    if not same_value(value, normalized) then
        return nil, "QA contract is not normalized"
    end
    return true
end

function qa_schema.same(left, right)
    return same_value(left, right)
end

return qa_schema
