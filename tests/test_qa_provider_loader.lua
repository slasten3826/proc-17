package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local native_build = require("tests.support.qa_native_build")
local owned = require("tests.support.owned_temp_root")
local suite = H.new("qa-provider-loader")

local built, build_err = native_build.ensure_loader_fixtures()
local provider, provider_err
if built then
    package.loaded["runtime.qa_provider"] = nil
    provider, provider_err = H.optional_require("runtime.qa_provider")
else
    provider_err = build_err
end

local function require_provider()
    H.assert_true(built, tostring(build_err))
    return suite:require_module(provider, provider_err, "runtime.qa_provider")
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
    local loader_path = runtime_dir .. "/qa_provider.lua"
    copy_file("runtime/qa_provider.lua", loader_path)
    if native_source then
        copy_file(native_source, native_dir .. "/proc17_qa_launcher.so")
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

suite:check("L0 exact provider shell loads with a detached identity", function()
    local current = require_provider()
    local status = current.availability()
    H.assert_true(status.available, "exact QA provider is available")
    H.assert_eq(status.code, "provider_available", "availability code")
    H.assert_eq(status.provider_id, "linux.qa_supervisor.lua54.v0", "provider id")
    H.assert_eq(current.supervisor_abi, "proc17.qa_supervisor.v0", "supervisor ABI")
end)

suite:check("L1 public adapter API is closed", function()
    local current = require_provider()
    local expected = {
        protocol_version = true,
        provider_id = true,
        supervisor_abi = true,
        availability = true,
        probe = true,
        run = true,
    }
    for key in pairs(current) do
        H.assert_true(expected[key], "unexpected QA provider export: " .. tostring(key))
    end
    for key in pairs(expected) do
        H.assert_true(current[key] ~= nil, "missing QA provider export: " .. key)
    end
    H.assert_nil(current.native_path, "native path remains private")
    H.assert_nil(current.native_module, "native module remains private")
end)

suite:check("L2 missing exact sibling remains unavailable without fallback", function()
    owned.with_root(function(root)
        local loader_path = prepare_body(root)
        local original_cpath = package.cpath
        package.cpath = "./native/?.so;" .. original_cpath
        local copied = assert(load_copy(loader_path))
        package.cpath = original_cpath
        local status = copied.availability()
        H.assert_false(status.available, "missing exact sibling remains closed")
        H.assert_eq(status.code, "provider_unavailable", "absence is typed")
        local environment, err = copied.probe()
        H.assert_nil(environment, "absence cannot fabricate an environment")
        H.assert_eq(err.stage, "native_module_absent", "absence stage")
    end)
end)

suite:check("L3 present wrong ABI fails loudly", function()
    owned.with_root(function(root)
        local loader_path = prepare_body(root,
            "native/tests/proc17_qa_launcher_wrong_abi.so")
        local chunk = assert(loadfile(loader_path))
        local ok, err = pcall(chunk)
        H.assert_false(ok, "wrong ABI cannot become a provider")
        H.assert_contains(err, "native ABI mismatch",
            "failure names the exact ABI")
    end)
end)

suite:check("L4 availability records are detached", function()
    local current = require_provider()
    local first = current.availability()
    first.code = "caller-forged"
    first.provider_id = "caller-forged"
    local second = current.availability()
    H.assert_eq(second.code, "provider_available", "status survives alias attack")
    H.assert_eq(second.provider_id, "linux.qa_supervisor.lua54.v0",
        "identity survives alias attack")
end)

suite:check("L5 malformed candidate request fails before native boundary", function()
    local current = require_provider()
    local ok, err = pcall(current.run, {}, {})
    H.assert_false(ok, "malformed D request cannot enter native code")
    H.assert_contains(err, "native RUN v1 request",
        "closed request schema rejects the call")
end)

suite:finish()
print("test_qa_provider_loader ok")
