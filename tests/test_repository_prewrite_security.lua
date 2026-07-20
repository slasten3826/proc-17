package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local fixture = require("tests.support.repository_hands")
local owned = require("tests.support.owned_temp_root")
local native_build = require("tests.support.repository_native_build")
local capabilities = require("runtime.repository_capability")
local built, build_err = native_build.ensure_loader_fixtures()
local provider_module, provider_err
if built then
    provider_module, provider_err = H.optional_require("runtime.repository_provider")
else
    provider_err = build_err
end
local suite = H.new("repository-prewrite-security")

local function require_provider()
    H.assert_true(built, tostring(build_err))
    return suite:require_module(
        provider_module,
        provider_err,
        "runtime.repository_provider"
    )
end

local function command_ok(command)
    local ok, _, code = os.execute(command)
    return ok == true and (code == nil or code == 0)
end

suite:check("B2/TH-M13 first hand admits only mode 0600", function()
    local provider = fixture.fake_provider()
    local registry = assert(capabilities.new({
        session_id = "session-repository-hands",
        providers = {[provider.provider_id] = provider},
    }))
    for _, mode in ipairs({420, 448, 493, 511}) do
        local projection = capabilities.mint(registry, fixture.grant_input({
            policy = {file_mode = mode},
        }))
        H.assert_nil(projection, "broader file mode must be rejected: " .. tostring(mode))
    end
    assert(capabilities.mint(registry, fixture.grant_input({
        repository_id = "repo-mode-0600",
        policy = {file_mode = 384},
    })))
end)

suite:check("B3/TH-RS01 provider publishes fixed hard ceilings", function()
    local provider = require_provider()
    H.assert_eq(provider.limits.max_relative_path_bytes, 1024, "path ceiling")
    H.assert_eq(provider.limits.max_component_bytes, 255, "component ceiling")
    H.assert_eq(provider.limits.max_components, 64, "component-count ceiling")
    H.assert_eq(provider.limits.max_content_bytes, 1048576, "content ceiling")
    H.assert_eq(provider.limits.file_mode, 384, "mode ceiling")
end)

suite:check("B1/TH-L01-L02 task cpath cannot substitute native provider", function()
    require_provider()
    owned.with_root(function(root)
        local hostile = root.repository .. "/proc17_repository_fs.so"
        local file = assert(io.open(hostile, "wb"))
        assert(file:write("not a native module\n"))
        assert(file:close())
        local command = "lua tests/probes/repository_loader_poison.lua " .. root.repository
        H.assert_true(command_ok(command), "loader must ignore hostile package.cpath")
    end)
end)

suite:check("TH-L07/L09 production provider exposes no handles or test hooks", function()
    local provider = require_provider()
    H.assert_nil(provider.test_cross_device_fixture, "mount fixture is not production API")
    H.assert_nil(provider.inject_fault, "fault injection is not production API")
    H.assert_nil(provider.native_handle, "native handle is not public API")
end)

suite:check("TH-L08 runtime provider source has no shell or weak path fallback", function()
    local file = assert(io.open("runtime/repository_provider.lua", "rb"))
    local source = assert(file:read("*a"))
    assert(file:close())
    for _, forbidden in ipairs({
        "os.execute",
        "io.popen",
        "os.getenv",
        "package.cpath",
        "require(\"proc17_repository_fs\")",
        "realpath",
        "readlink",
        "runtime.trace_store",
        "tools.fs",
    }) do
        H.assert_false(source:find(forbidden, 1, true) ~= nil,
            "forbidden runtime fallback: " .. forbidden)
    end
end)

suite:check("TH-L08 native provider source has no helper-process fallback", function()
    local file = assert(io.open("native/proc17_repository_fs.c", "rb"))
    local source = assert(file:read("*a"))
    assert(file:close())
    for _, forbidden in ipairs({
        "system(",
        "popen(",
        "execve(",
        "realpath(",
    }) do
        H.assert_false(source:find(forbidden, 1, true) ~= nil,
            "forbidden native fallback: " .. forbidden)
    end
end)

suite:check("B8/TH-L10 native build products are ignored", function()
    local file = assert(io.open(".gitignore", "rb"))
    local source = assert(file:read("*a"))
    assert(file:close())
    H.assert_contains(source, "native/*.so", "native modules ignored")
    H.assert_contains(source, "native/tests/test_proc17_repository_fs",
        "native test binary ignored")
    H.assert_contains(source, "native/tests/proc17_fixture_guard",
        "fixture guard binary ignored")
end)

suite:finish()
print("test_repository_prewrite_security ok")
