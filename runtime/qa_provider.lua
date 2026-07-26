local digest = require("core.digest")
local qa_process = require("runtime.qa_process")
local qa_schema = require("core.qa_schema")

local qa_provider = {
    protocol_version = "qa.provider_adapter.v0",
    provider_id = qa_schema.provider_id,
    supervisor_abi = qa_schema.supervisor_abi,
}

local NATIVE_PROTOCOL = "qa.native_launcher.v0"
local NATIVE_ABI = "proc17.qa.launcher.lua54.v0"
local NATIVE_SYMBOL = "luaopen_proc17_qa_launcher"
local MODULE_NAME = "proc17_qa_launcher.so"
local MODULE_BYTE_CEILING = 16 * 1024 * 1024

local native_keys = {
    protocol_version = true,
    abi_version = true,
    provider_id = true,
    supervisor_abi = true,
    expected_supervisor_build_id = true,
    runtime_build_id = true,
    policy_digest = true,
    limits = true,
    probe_environment = true,
    run_lua54_test_suite = true,
}

local probe_keys = {
    protocol_version = true,
    provider_id = true,
    supervisor_abi = true,
    supervisor_build_id = true,
    runtime_dependency_closure_id = true,
    runtime_name = true,
    runtime_build_id = true,
    platform = true,
    machine_arch = true,
    kernel_identity_id = true,
    isolation_feature_set_id = true,
    isolation_policy_digest = true,
    event_truth_status = true,
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

local function fail(message)
    error("QA native provider contract failure: " .. tostring(message), 0)
end

local function exact_record(value, keys, label)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        fail(label .. " must be a plain table")
    end
    for key in pairs(value) do
        if not keys[key] then
            fail(label .. " contains unknown key: " .. tostring(key))
        end
    end
    for key in pairs(keys) do
        if value[key] == nil then
            fail(label .. " is missing key: " .. key)
        end
    end
end

local function tagged_sha(value)
    return type(value) == "string"
        and value:match("^sha256:[0-9a-f][0-9a-f]+$") ~= nil
        and #value == 71
end

local function derive_native_path()
    local information = debug.getinfo(1, "S")
    local source = information and information.source
    if type(source) ~= "string" or source:sub(1, 1) ~= "@" then
        fail("loader source is not a filesystem file")
    end
    local path = source:sub(2)
    if path == "" or path:find("[%z\1-\31\127]")
        or path:find("\\", 1, true) or path:find("//", 1, true) then
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
        or components[#components] ~= "qa_provider.lua" then
        fail("loader source does not have the required runtime identity")
    end
    components[#components] = nil
    components[#components] = nil
    components[#components + 1] = "native"
    components[#components + 1] = MODULE_NAME
    return (absolute and "/" or "") .. table.concat(components, "/")
end

local function read_module(path)
    local file = io.open(path, "rb")
    if not file then
        return nil, "absent"
    end
    local bytes = file:read(MODULE_BYTE_CEILING + 1)
    local closed, close_err = file:close()
    if closed ~= true then
        fail("cannot close native module probe: " .. tostring(close_err))
    end
    if type(bytes) ~= "string" then
        fail("cannot read native module bytes")
    end
    if #bytes > MODULE_BYTE_CEILING then
        fail("native module exceeds its byte ceiling")
    end
    return bytes
end

local function native_error(code, stage, detail)
    return {
        protocol_version = "qa.provider_error.v0",
        code = code,
        stage = stage,
        detail = type(detail) == "string" and detail or code,
        event_truth_status = "runtime_confirmed",
    }
end

local native_path = derive_native_path()
local module_bytes, module_state = read_module(native_path)
local native
local provider_build_id

if module_bytes then
    provider_build_id = "sha256:" .. assert(digest.sha256(module_bytes))
    local initializer, load_err = package.loadlib(native_path, NATIVE_SYMBOL)
    if type(initializer) ~= "function" then
        fail("cannot load exact native initializer: " .. tostring(load_err))
    end
    local initialized = table.pack(pcall(initializer))
    if initialized[1] ~= true then
        fail("native initializer failed: " .. tostring(initialized[2]))
    end
    if initialized.n ~= 2 then
        fail("native initializer returned an invalid value count")
    end
    native = initialized[2]
    exact_record(native, native_keys, "native launcher")
    if native.protocol_version ~= NATIVE_PROTOCOL then
        fail("native protocol mismatch")
    end
    if native.abi_version ~= NATIVE_ABI then
        fail("native ABI mismatch")
    end
    if native.provider_id ~= qa_schema.provider_id then
        fail("native provider identity mismatch")
    end
    if native.supervisor_abi ~= qa_schema.supervisor_abi then
        fail("native supervisor ABI mismatch")
    end
    if not tagged_sha(native.expected_supervisor_build_id)
        or not tagged_sha(native.runtime_build_id)
        or not tagged_sha(native.policy_digest) then
        fail("native build identity is malformed")
    end
    if not qa_schema.same(native.limits, qa_schema.hard_limits()) then
        fail("native hard limits mismatch")
    end
    if type(native.probe_environment) ~= "function"
        or type(native.run_lua54_test_suite) ~= "function" then
        fail("native functions are missing")
    end
end

local availability_state = {
    protocol_version = "qa.provider_availability.v0",
    available = native ~= nil,
    code = native and "provider_available" or "provider_unavailable",
    provider_id = qa_schema.provider_id,
    supervisor_abi = qa_schema.supervisor_abi,
    provider_build_id = provider_build_id,
    event_truth_status = "runtime_confirmed",
}

function qa_provider.availability()
    return copy_value(availability_state)
end

function qa_provider.probe()
    if not native then
        return nil, native_error("provider_unavailable", "native_module_absent",
            module_state)
    end
    local returned = table.pack(pcall(native.probe_environment))
    if returned[1] ~= true then
        fail("native probe raised: " .. tostring(returned[2]))
    end
    if returned[2] == nil then
        if returned.n ~= 3 or type(returned[3]) ~= "table" then
            fail("native probe returned an invalid unavailable result")
        end
        return nil, copy_value(returned[3])
    end
    if returned.n ~= 2 then
        fail("native probe returned an invalid value count")
    end
    local observed = returned[2]
    exact_record(observed, probe_keys, "native environment probe")
    if observed.protocol_version ~= "qa.native_probe.v0"
        or observed.provider_id ~= qa_schema.provider_id
        or observed.supervisor_abi ~= qa_schema.supervisor_abi
        or observed.supervisor_build_id ~= native.expected_supervisor_build_id
        or observed.runtime_name ~= "Lua 5.4"
        or observed.runtime_build_id ~= native.runtime_build_id
        or observed.platform ~= "linux"
        or observed.machine_arch ~= "x86_64"
        or observed.isolation_policy_digest ~= native.policy_digest
        or observed.event_truth_status ~= "runtime_confirmed" then
        fail("native environment probe identity mismatch")
    end
    for _, key in ipairs({
        "supervisor_build_id", "runtime_dependency_closure_id",
        "runtime_build_id", "kernel_identity_id", "isolation_feature_set_id",
        "isolation_policy_digest",
    }) do
        if not tagged_sha(observed[key]) then
            fail("native environment probe digest is malformed: " .. key)
        end
    end
    local limits_digest = assert(digest.record(qa_schema.hard_limits()))
    local normalized, normalize_err = qa_schema.normalize_environment({
        protocol_version = qa_schema.environment_protocol,
        profile_id = qa_schema.profile_id,
        provider_id = qa_schema.provider_id,
        provider_build_id = provider_build_id,
        supervisor_abi = observed.supervisor_abi,
        supervisor_build_id = observed.supervisor_build_id,
        runtime_dependency_closure_id = observed.runtime_dependency_closure_id,
        runtime_name = observed.runtime_name,
        runtime_build_id = observed.runtime_build_id,
        platform = observed.platform,
        machine_arch = observed.machine_arch,
        kernel_identity_id = observed.kernel_identity_id,
        isolation_feature_set_id = observed.isolation_feature_set_id,
        isolation_policy_digest = observed.isolation_policy_digest,
        hard_limits_digest = "sha256:" .. limits_digest,
        event_truth_status = "runtime_confirmed",
    })
    if not normalized then
        fail("normalized environment rejected: " .. tostring(normalize_err))
    end
    return normalized
end

function qa_provider.run(repository_userdata, native_request)
    local normalized_request, request_err = qa_process.normalize_request(native_request)
    if not normalized_request then
        fail(request_err)
    end
    if not native then
        return nil, {
            protocol_version = "qa.provider_process_error.v0",
            operation = "run_lua54_test_suite",
            transaction_id = normalized_request.transaction_id,
            witness_id = normalized_request.witness_id,
            profile_id = normalized_request.profile_id,
            environment_id = normalized_request.environment_id,
            class = "unavailable",
            code = "provider_unavailable",
            stage = "preflight",
            candidate_started = false,
            cleanup_complete = true,
            cost = {
                protocol_version = "qa.cost.v0",
                tool_calls = 1,
                qa_executions = 0,
                wall_time_ms = 0,
                cpu_time_ms = 0,
                scratch_written_bytes = 0,
                stdout_observed_bytes = 0,
                stderr_observed_bytes = 0,
            },
            event_truth_status = "runtime_confirmed",
        }
    end
    local returned = table.pack(pcall(native.run_lua54_test_suite,
        repository_userdata, normalized_request))
    if returned[1] ~= true then
        fail("native candidate boundary raised: " .. tostring(returned[2]))
    end
    if returned.n == 2 and type(returned[2]) == "table" then
        return qa_process.normalize_result(returned[2], normalized_request)
    end
    if returned.n == 3 and returned[2] == nil and type(returned[3]) == "table" then
        return nil, qa_process.normalize_native_error(returned[3], normalized_request)
    end
    fail("native candidate boundary returned an invalid value count")
end

return qa_provider
