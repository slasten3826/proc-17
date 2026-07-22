package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local native_build = require("tests.support.repository_native_build")
local owned = require("tests.support.owned_temp_root")
local suite = H.new("repository-provider-loader")

local built, build_err = native_build.ensure_loader_fixtures()
local provider, provider_err
if built then
    package.loaded["runtime.repository_provider"] = nil
    provider, provider_err = H.optional_require("runtime.repository_provider")
else
    provider_err = build_err
end

local function require_provider()
    H.assert_true(built, tostring(build_err))
    return suite:require_module(provider, provider_err,
        "runtime.repository_provider")
end

local function quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function command(command_text)
    local ok, why, code = os.execute(command_text)
    if ok ~= true or (code ~= nil and code ~= 0) then
        error("test fixture command failed: "
            .. tostring(why) .. ":" .. tostring(code), 2)
    end
end

local function copy_file(source, target)
    local input = assert(io.open(source, "rb"))
    local bytes = assert(input:read("*a"))
    assert(input:close())
    local output = assert(io.open(target, "wb"))
    assert(output:write(bytes))
    assert(output:close())
end

local function prepare_body(root, native_source)
    local runtime_dir = assert(owned.assert_owned_path(root, root.path .. "/runtime"))
    local native_dir = assert(owned.assert_owned_path(root, root.path .. "/native"))
    command("mkdir -p " .. quote(runtime_dir) .. " " .. quote(native_dir))
    local loader_path = runtime_dir .. "/repository_provider.lua"
    copy_file("runtime/repository_provider.lua", loader_path)
    if native_source then
        copy_file(native_source, native_dir .. "/proc17_repository_fs.so")
    end
    return loader_path
end

local function load_copy(path)
    local chunk, err = loadfile(path)
    if not chunk then
        return nil, err
    end
    return chunk()
end

local function native_fixture()
    local function refused()
        return nil, "fixture refusal"
    end
    return {
        protocol_version = "repository.native_provider.v0",
        abi_version = "proc17.repository.fs.lua54.v0",
        provider_id = "linux.openat2.renameat2.v0",
        contract_id = "repository.provider.create_readback.v0",
        limits = {
            max_relative_path_bytes = 1024,
            max_component_bytes = 255,
            max_components = 64,
            max_content_bytes = 1048576,
            file_mode = 384,
        },
        open_repository = refused,
        revalidate = refused,
        create_text_file = refused,
        read_text_file = refused,
        inventory_tree = refused,
        close = refused,
    }
end

suite:check("L0 exact Lua 5.4 provider shell builds and loads", function()
    local current = require_provider()
    H.assert_eq(current.protocol_version, "repository.provider_adapter.v0",
        "adapter protocol")
    H.assert_eq(current.native_abi, "proc17.repository.fs.lua54.v0",
        "native ABI")
    local available, diagnostic = current.available()
    H.assert_true(available, "exact shell is available")
    H.assert_eq(diagnostic.code, "provider_shell_loaded", "shell state is explicit")
    H.assert_eq(diagnostic.event_truth_status, "runtime_confirmed",
        "load evidence is runtime truth")
end)

suite:check("L1 provider API and limits are exact", function()
    local current = require_provider()
    local expected = {
        protocol_version = true,
        provider_id = true,
        contract_id = true,
        native_abi = true,
        limits = true,
        available = true,
        open_repository = true,
        revalidate = true,
        create_text_file = true,
        read_text_file = true,
        inventory_tree = true,
        close = true,
    }
    for key in pairs(current) do
        H.assert_true(expected[key], "unexpected provider export: " .. tostring(key))
    end
    for key in pairs(expected) do
        H.assert_true(current[key] ~= nil, "missing provider export: " .. key)
    end
    H.assert_eq(current.provider_id, "linux.openat2.renameat2.v0", "provider id")
    H.assert_eq(current.contract_id, "repository.provider.create_readback.v0",
        "contract id")
    H.assert_eq(current.limits.max_relative_path_bytes, 1024, "path bytes")
    H.assert_eq(current.limits.max_component_bytes, 255, "component bytes")
    H.assert_eq(current.limits.max_components, 64, "component count")
    H.assert_eq(current.limits.max_content_bytes, 1048576, "content bytes")
    H.assert_eq(current.limits.file_mode, 384, "exact mode")
    H.assert_nil(current.native_path, "trusted host path is not projected")
    H.assert_nil(current.native_handle, "raw handle is not projected")
    H.assert_nil(current.inject_fault, "fault hook is not production API")
end)

suite:check("L2 loaded provider reaches root boundary without fabrication", function()
    local current = require_provider()
    local handle, err = current.open_repository({
        project_base = "/proc/proc17-provider-root-does-not-exist",
        repository_path = "repo",
    })
    H.assert_nil(handle, "missing root cannot create a repository handle")
    H.assert_eq(err.protocol_version, "repository.provider_error.v0",
        "typed provider error")
    H.assert_eq(err.code, "root_missing", "kernel absence is preserved")
    H.assert_eq(err.stage, "open_project_base", "root-open boundary")
    H.assert_false(err.mutation_primitive_entered, "no mutation primitive")
    H.assert_false(err.published, "nothing published")
    H.assert_eq(err.cost.tool_calls, 1, "one provider observation")
    H.assert_eq(err.cost.file_writes, 0, "no file write")
    H.assert_eq(err.cost.time_ms, 0, "no runtime cost")
end)

suite:check("L3 absent exact module stays unavailable without fallback", function()
    owned.with_root(function(root)
        local loader_path = prepare_body(root)
        local copied = assert(load_copy(loader_path))
        local available, diagnostic = copied.available()
        H.assert_false(available, "missing exact sibling stays closed")
        H.assert_eq(diagnostic.code, "provider_unavailable", "absence is typed")
        local handle, err = copied.open_repository({
            project_base = root.project_base,
            repository_path = "repo",
        })
        H.assert_nil(handle, "absence cannot produce a handle")
        H.assert_eq(err.stage, "native_module_absent", "absence stage")
        H.assert_eq(err.cost.tool_calls, 0, "absence has zero cost")
    end)
end)

suite:check("L4 present wrong ABI fails loudly", function()
    owned.with_root(function(root)
        local loader_path = prepare_body(root,
            "native/tests/proc17_repository_fs_wrong_abi.so")
        local chunk = assert(loadfile(loader_path))
        local ok, err = pcall(chunk)
        H.assert_false(ok, "wrong ABI cannot become a provider")
        H.assert_contains(err, "native ABI mismatch", "failure names ABI")
    end)
end)

suite:check("L5 every malformed native identity is loud", function()
    owned.with_root(function(root)
        local loader_path = prepare_body(root,
            "native/tests/proc17_repository_fs_wrong_abi.so")
        local expected_path = root.path .. "/native/proc17_repository_fs.so"
        local cases = {
            {
                fragment = "provider identity mismatch",
                mutate = function(value)
                    value.provider_id = "hostile.provider"
                end,
            },
            {
                fragment = "provider contract mismatch",
                mutate = function(value)
                    value.contract_id = "hostile.contract"
                end,
            },
            {
                fragment = "native limit mismatch",
                mutate = function(value)
                    value.limits.max_content_bytes = 1048577
                end,
            },
            {
                fragment = "contains unknown key",
                mutate = function(value)
                    value.inject_fault = function() end
                end,
            },
            {
                fragment = "is missing key",
                mutate = function(value)
                    value.create_text_file = nil
                end,
            },
        }
        for _, case in ipairs(cases) do
            local candidate = native_fixture()
            case.mutate(candidate)
            local original_loadlib = package.loadlib
            package.loadlib = function(path, symbol)
                H.assert_eq(path, expected_path, "loader uses exact sibling path")
                H.assert_eq(symbol, "luaopen_proc17_repository_fs",
                    "loader uses exact initializer")
                return function()
                    return candidate
                end
            end
            local chunk = assert(loadfile(loader_path))
            local ok, err = pcall(chunk)
            package.loadlib = original_loadlib
            H.assert_false(ok, "malformed native module cannot load")
            H.assert_contains(err, case.fragment, "malformed identity is named")
        end
    end)
end)

suite:check("L6 availability reports are detached", function()
    local current = require_provider()
    local _, first = current.available()
    first.code = "caller-forged"
    first.provider_id = "caller-forged"
    local _, second = current.available()
    H.assert_eq(second.code, "provider_shell_loaded", "status survives alias attack")
    H.assert_eq(second.provider_id, "linux.openat2.renameat2.v0",
        "identity survives alias attack")
end)

suite:finish()
print("test_repository_provider_loader ok")
