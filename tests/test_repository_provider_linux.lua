package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local provider_module, provider_err = H.optional_require("runtime.repository_provider")
local suite = H.new("repository-provider-linux")

local function require_provider()
    return suite:require_module(
        provider_module,
        provider_err,
        "runtime.repository_provider"
    )
end

local function quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function command(text)
    local ok, why, code = os.execute(text)
    if ok ~= true then
        error("fixture command failed: " .. tostring(why) .. ":" .. tostring(code), 2)
    end
end

local function write(path, content)
    local file = assert(io.open(path, "wb"))
    assert(file:write(content))
    assert(file:close())
end

local function read(path)
    local file = io.open(path, "rb")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

local function with_root(callback)
    local root = os.tmpname()
    os.remove(root)
    command("mkdir -p " .. quote(root .. "/projects/repo/src"))
    local ok, value = pcall(callback, root, root .. "/projects", root .. "/projects/repo")
    command("rm -rf " .. quote(root))
    if not ok then
        error(value, 0)
    end
    return value
end

local function open(provider, base, repository_path)
    return provider.open_repository({
        project_base = base,
        repository_path = repository_path or "repo",
    })
end

local function error_code(value)
    return type(value) == "table" and value.code or tostring(value)
end

local function create(provider, handle, path, content, extra)
    local request = {
        protocol_version = "repository.create_text_file.request.v0",
        relative_path = path,
        content = content,
        content_bytes = #content,
        precondition = "absent",
        file_mode = 384,
    }
    for key, value in pairs(extra or {}) do
        request[key] = value
    end
    return provider.create_text_file(handle, request)
end

suite:check("native build gate names missing toolchain/provider", function()
    local provider = require_provider()
    local available, diagnostic = provider.available()
    H.assert_true(available, "step 7 must supply the exact native provider: "
        .. tostring(diagnostic))
    H.assert_eq(provider.provider_id, "linux.openat2.renameat2.v0", "provider identity")
    H.assert_eq(provider.contract_id, "repository.provider.create_readback.v0",
        "provider contract identity")
end)

suite:check("P0 exact absent target creates and independently reads", function()
    local provider = require_provider()
    with_root(function(_, base)
        local handle = assert(open(provider, base))
        local result = assert(create(provider, handle, "src/main.lua", "return true\n"))
        H.assert_eq(result.outcome, "created", "create outcome")
        local observed = assert(provider.read_text_file(handle, {
            relative_path = "src/main.lua",
            max_bytes = 13,
        }))
        H.assert_eq(observed.outcome, "observed", "read outcome")
        H.assert_eq(observed.target_kind, "regular_file", "regular target")
        H.assert_eq(observed.content, "return true\n", "exact bytes")
        assert(provider.close(handle))
    end)
end)

suite:check("P9 symlink repository root cannot be opened", function()
    local provider = require_provider()
    with_root(function(root, base)
        command("ln -s " .. quote(root .. "/projects/repo") .. " "
            .. quote(root .. "/projects/repo-link"))
        local handle, err = open(provider, base, "repo-link")
        H.assert_nil(handle, "symlink root denied")
        H.assert_true(error_code(err) == "path_symlink"
            or error_code(err) == "root_invalid", "root denial is typed")
    end)
end)

suite:check("P10 symlink parent cannot escape repository", function()
    local provider = require_provider()
    with_root(function(root, base)
        command("mkdir -p " .. quote(root .. "/outside"))
        command("ln -s " .. quote(root .. "/outside") .. " "
            .. quote(root .. "/projects/repo/link"))
        local handle = assert(open(provider, base))
        local result, err = create(provider, handle, "link/escaped.lua", "escape denied\n")
        H.assert_nil(result, "symlink parent denied")
        H.assert_true(error_code(err) == "path_symlink"
            or error_code(err) == "path_containment_denied", "parent denial typed")
        H.assert_nil(read(root .. "/outside/escaped.lua"), "outside target unchanged")
    end)
end)

suite:check("P11 final symlink is not followed or overwritten", function()
    local provider = require_provider()
    with_root(function(root, base)
        write(root .. "/outside.lua", "outside-before\n")
        command("ln -s " .. quote(root .. "/outside.lua") .. " "
            .. quote(root .. "/projects/repo/src/main.lua"))
        local handle = assert(open(provider, base))
        local result, err = create(provider, handle, "src/main.lua", "forged\n")
        H.assert_nil(result, "final symlink denied")
        H.assert_true(error_code(err) == "target_exists"
            or error_code(err) == "path_symlink", "final denial typed")
        H.assert_eq(read(root .. "/outside.lua"), "outside-before\n",
            "symlink referent unchanged")
    end)
end)

suite:check("P12 missing parent is typed and leaves no final", function()
    local provider = require_provider()
    with_root(function(_, base, repo)
        local handle = assert(open(provider, base))
        local result, err = create(provider, handle, "missing/main.lua", "x\n")
        H.assert_nil(result, "missing parent denied")
        H.assert_eq(error_code(err), "parent_missing", "missing parent code")
        H.assert_nil(read(repo .. "/missing/main.lua"), "no final target")
    end)
end)

suite:check("P13 no-replace preserves existing target bytes", function()
    local provider = require_provider()
    with_root(function(_, base, repo)
        write(repo .. "/src/main.lua", "before\n")
        local handle = assert(open(provider, base))
        local result, err = create(provider, handle, "src/main.lua", "after\n")
        H.assert_nil(result, "existing target denied")
        H.assert_eq(error_code(err), "target_exists", "no-replace is typed")
        H.assert_eq(read(repo .. "/src/main.lua"), "before\n", "existing bytes unchanged")
    end)
end)

suite:check("P14 replaced root identity invalidates handle", function()
    local provider = require_provider()
    with_root(function(root, base)
        local handle = assert(open(provider, base))
        command("mv " .. quote(root .. "/projects/repo") .. " "
            .. quote(root .. "/projects/repo-old"))
        command("mkdir -p " .. quote(root .. "/projects/repo/src"))
        local valid, err = provider.revalidate(handle)
        H.assert_nil(valid, "replacement root invalidates grant handle")
        H.assert_eq(error_code(err), "root_changed", "root change is typed")
        local result = create(provider, handle, "src/main.lua", "must not write\n")
        H.assert_nil(result, "stale handle cannot write")
        H.assert_nil(read(root .. "/projects/repo/src/main.lua"), "replacement root unchanged")
    end)
end)

if os.getenv("PROC17_TEST_BIND_MOUNT") == "1" then
    suite:check("P15 cross-device parent is denied", function()
        local provider = require_provider()
        H.assert_true(type(provider.test_cross_device_fixture) == "function",
            "explicit mount fixture hook required")
        assert(provider.test_cross_device_fixture())
    end)
else
    suite:skip("P15 cross-device parent", "PROC17_TEST_BIND_MOUNT is not enabled")
end

suite:check("P16 native fault harness proves atomic final visibility", function()
    require_provider()
    local file = io.open("native/tests/test_proc17_repository_fs.c", "rb")
    H.assert_true(file ~= nil, "native fault-injection test source required")
    if file then file:close() end
    local ok = os.execute("make -C native test")
    H.assert_true(ok == true, "native atomicity test target must pass")
end)

suite:check("P17 native request rejects command fields", function()
    local provider = require_provider()
    with_root(function(_, base, repo)
        local handle = assert(open(provider, base))
        local result, err = create(provider, handle, "src/main.lua", "x\n", {
            command = {"touch", "outside"},
        })
        H.assert_nil(result, "command-bearing request rejected")
        H.assert_true(error_code(err) == "invalid_request"
            or tostring(err):find("unknown", 1, true) ~= nil, "rejection is explicit")
        H.assert_nil(read(repo .. "/src/main.lua"), "unknown key creates no file")
    end)
end)

suite:finish()
print("test_repository_provider_linux ok")
