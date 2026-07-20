package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local owned_temp_root = require("tests.support.owned_temp_root")
local native_build = require("tests.support.repository_native_build")
local built, build_err = native_build.ensure_loader_fixtures()
local provider_module, provider_err
if built then
    provider_module, provider_err = H.optional_require("runtime.repository_provider")
else
    provider_err = build_err
end
local suite = H.new("repository-provider-linux")

local function require_provider()
    H.assert_true(built, tostring(build_err))
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
    return owned_temp_root.with_root(function(root)
        return callback(root.path, root.project_base, root.repository, root)
    end)
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

suite:check("P0a exact absent target returns a bounded create receipt", function()
    local provider = require_provider()
    with_root(function(_, base, repo)
        local handle = assert(open(provider, base))
        local result = assert(create(provider, handle,
            "src/main.lua", "return true\n"))
        H.assert_eq(result.protocol_version, "repository.provider_result.v0",
            "result protocol")
        H.assert_eq(result.operation, "create_text_file", "operation identity")
        H.assert_eq(result.outcome, "created", "create outcome")
        H.assert_eq(result.bytes, 12, "exact byte count")
        H.assert_true(result.mutation_primitive_entered, "mutation is priced")
        H.assert_true(result.published, "publication is explicit")
        H.assert_eq(result.cost.tool_calls, 1, "one provider call")
        H.assert_eq(result.cost.file_writes, 1, "one bounded file write")
        H.assert_eq(read(repo .. "/src/main.lua"), "return true\n",
            "test observer sees exact final bytes")

        result.outcome = "caller-forged"
        local replay, replay_err = create(provider, handle,
            "src/main.lua", "return true\n")
        H.assert_nil(replay, "identical replay is not implicit success")
        H.assert_eq(error_code(replay_err), "target_exists", "replay conflict")
        H.assert_eq(read(repo .. "/src/main.lua"), "return true\n",
            "replay preserves exact bytes")
        assert(provider.close(handle))
    end)
end)

suite:check("P0b zero-byte target is an exact create", function()
    local provider = require_provider()
    with_root(function(_, base, repo)
        local handle = assert(open(provider, base))
        local result = assert(create(provider, handle, "src/empty.lua", ""))
        H.assert_eq(result.bytes, 0, "zero-byte receipt")
        H.assert_eq(read(repo .. "/src/empty.lua"), "", "empty file exists")
        local observed = assert(provider.read_text_file(handle, {
            relative_path = "src/empty.lua",
            max_bytes = 1,
        }))
        H.assert_eq(observed.target_kind, "regular_file", "empty target is regular")
        H.assert_eq(observed.bytes, 0, "empty observation has zero bytes")
        H.assert_eq(observed.content, "", "empty observation is exact")
        assert(provider.close(handle))
    end)
end)

suite:check("P0c repository-root target uses the same bounded parent law", function()
    local provider = require_provider()
    with_root(function(_, base, repo)
        local handle = assert(open(provider, base))
        local result = assert(create(provider, handle, "main.lua", "root file\n"))
        H.assert_eq(result.outcome, "created", "root-level create")
        H.assert_eq(read(repo .. "/main.lua"), "root file\n", "exact root-level bytes")
        assert(provider.close(handle))
    end)
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

suite:check("P0d missing target is bounded evidence without content", function()
    local provider = require_provider()
    with_root(function(_, base)
        local handle = assert(open(provider, base))
        local observed = assert(provider.read_text_file(handle, {
            relative_path = "src/missing.lua",
            max_bytes = 1,
        }))
        H.assert_eq(observed.outcome, "observed", "missing observation exists")
        H.assert_eq(observed.target_kind, "missing", "exact target is missing")
        H.assert_nil(observed.bytes, "missing target has no byte claim")
        H.assert_nil(observed.content, "missing target leaks no content")
        H.assert_eq(observed.cost.tool_calls, 1, "one bounded observation call")
        H.assert_eq(observed.cost.file_writes, 0, "observation cannot write")
        H.assert_true(not observed.mutation_primitive_entered,
            "observation enters no mutation primitive")
        assert(provider.close(handle))
    end)
end)

suite:check("P0e non-regular final objects are classified without reading", function()
    local provider = require_provider()
    with_root(function(_, base, repo)
        command("mkdir " .. quote(repo .. "/src/directory"))
        command("ln -s missing-referent " .. quote(repo .. "/src/link"))
        command("mkfifo " .. quote(repo .. "/src/fifo"))
        local handle = assert(open(provider, base))
        for _, path in ipairs({
            "src/directory",
            "src/link",
            "src/fifo",
        }) do
            local observed = assert(provider.read_text_file(handle, {
                relative_path = path,
                max_bytes = 8,
            }))
            H.assert_eq(observed.target_kind, "other", path .. " is not read")
            H.assert_nil(observed.bytes, path .. " has no byte claim")
            H.assert_nil(observed.content, path .. " has no content")
            H.assert_eq(observed.cost.file_writes, 0, path .. " cannot mutate")
        end
        assert(provider.close(handle))
    end)
end)

suite:check("P0f repository-root file has the same exact read law", function()
    local provider = require_provider()
    with_root(function(_, base)
        local handle = assert(open(provider, base))
        assert(create(provider, handle, "main.lua", "root bytes\n"))
        local observed = assert(provider.read_text_file(handle, {
            relative_path = "main.lua",
            max_bytes = 11,
        }))
        H.assert_eq(observed.target_kind, "regular_file", "root target is regular")
        H.assert_eq(observed.content, "root bytes\n", "root bytes are exact")
        assert(provider.close(handle))
    end)
end)

suite:check("TH-E02 read request envelope is exact and zero-call on denial", function()
    local provider = require_provider()
    with_root(function(_, base)
        local handle = assert(open(provider, base))
        local malformed = {
            {},
            {relative_path = "src/main.lua"},
            {relative_path = "src/main.lua", max_bytes = 0},
            {relative_path = "src/main.lua", max_bytes = 1048578},
            {relative_path = "../outside", max_bytes = 1},
            {relative_path = "src/main.lua", max_bytes = 1, command = "cat"},
        }
        for index, request in ipairs(malformed) do
            local observed, err = provider.read_text_file(handle, request)
            H.assert_nil(observed, "malformed read denied " .. index)
            H.assert_eq(error_code(err), "invalid_request",
                "malformed read is typed " .. index)
            H.assert_eq(err.cost.tool_calls, 0, "denial enters no provider call")
            H.assert_eq(err.cost.file_writes, 0, "denial enters no mutation")
        end
        assert(provider.close(handle))
    end)
end)

suite:check("TH-E02b closed read handle is an explicit contract failure", function()
    local provider = require_provider()
    with_root(function(_, base)
        local handle = assert(open(provider, base))
        assert(provider.close(handle))
        local observed, err = provider.read_text_file(handle, {
            relative_path = "src/main.lua",
            max_bytes = 1,
        })
        H.assert_nil(observed, "closed handle cannot observe")
        H.assert_eq(error_code(err), "handle_closed", "closed handle is typed")
        H.assert_eq(err.cost.tool_calls, 0, "closed handle performs no call")
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

suite:check("P10b read-back cannot follow a symlink parent", function()
    local provider = require_provider()
    with_root(function(root, base)
        command("mkdir -p " .. quote(root .. "/outside"))
        write(root .. "/outside/secret.lua", "must not be read\n")
        command("ln -s " .. quote(root .. "/outside") .. " "
            .. quote(root .. "/projects/repo/link-read"))
        local handle = assert(open(provider, base))
        local observed, err = provider.read_text_file(handle, {
            relative_path = "link-read/secret.lua",
            max_bytes = 32,
        })
        H.assert_nil(observed, "symlink parent is denied")
        H.assert_true(error_code(err) == "path_symlink"
            or error_code(err) == "path_containment_denied",
            "symlink-parent denial is typed")
        H.assert_eq(err.cost.file_writes, 0, "denial cannot mutate")
        assert(provider.close(handle))
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

suite:check("TH-P08 non-directory parent is typed and unchanged", function()
    local provider = require_provider()
    with_root(function(_, base, repo)
        write(repo .. "/not-directory", "sentinel\n")
        local handle = assert(open(provider, base))
        local result, err = create(provider, handle,
            "not-directory/main.lua", "must not write\n")
        H.assert_nil(result, "non-directory parent denied")
        H.assert_eq(error_code(err), "parent_not_directory", "parent type code")
        H.assert_eq(read(repo .. "/not-directory"), "sentinel\n",
            "parent bytes unchanged")
    end)
end)

suite:check("TH-M16 writable-by-others parent is denied before mutation", function()
    local provider = require_provider()
    with_root(function(_, base, repo)
        local handle = assert(open(provider, base))
        for _, mode in ipairs({"0770", "0777"}) do
            command("chmod " .. mode .. " " .. quote(repo .. "/src"))
            local result, err = create(provider, handle,
                "src/main.lua", "must not write\n")
            H.assert_nil(result, "shared writable parent denied")
            H.assert_eq(error_code(err), "parent_not_private",
                "unsafe parent policy is typed")
            H.assert_eq(err.cost.file_writes, 0, "denial precedes mutation")
            H.assert_nil(read(repo .. "/src/main.lua"), "no final target")
        end
        command("chmod 0700 " .. quote(repo .. "/src"))
        assert(provider.close(handle))
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

suite:check("TH-P16 existing hard link is never opened or truncated", function()
    local provider = require_provider()
    with_root(function(root, base, repo)
        write(root .. "/outside-hardlink.lua", "outside-before\n")
        command("ln " .. quote(root .. "/outside-hardlink.lua") .. " "
            .. quote(repo .. "/src/main.lua"))
        local handle = assert(open(provider, base))
        local result, err = create(provider, handle,
            "src/main.lua", "must not truncate\n")
        H.assert_nil(result, "hard-linked final denied")
        H.assert_eq(error_code(err), "target_exists", "hard link is conflict")
        H.assert_eq(read(root .. "/outside-hardlink.lua"), "outside-before\n",
            "outside link bytes unchanged")
        H.assert_eq(read(repo .. "/src/main.lua"), "outside-before\n",
            "repository link bytes unchanged")
        assert(provider.close(handle))
    end)
end)

suite:check("TH-P09 no-replace denies existing directory and fifo", function()
    local provider = require_provider()
    with_root(function(root, base, repo)
        command("mkdir " .. quote(repo .. "/src/existing-dir"))
        command("mkfifo " .. quote(repo .. "/src/existing-fifo"))
        local handle = assert(open(provider, base))
        for _, path in ipairs({"src/existing-dir", "src/existing-fifo"}) do
            local result, err = create(provider, handle, path, "must not replace\n")
            H.assert_nil(result, "existing non-regular target denied")
            H.assert_eq(error_code(err), "target_exists", "existing type is conflict")
        end
        command("test -d " .. quote(repo .. "/src/existing-dir"))
        command("test -p " .. quote(repo .. "/src/existing-fifo"))
        H.assert_true(root ~= "", "owned root remains named")
    end)
end)

suite:check("TH-P14/P15 native request enforces NUL and hard ceilings", function()
    local provider = require_provider()
    with_root(function(_, base, repo)
        local handle = assert(open(provider, base))
        local cases = {
            {string.rep("a", 1025), "x\n", 384},
            {"src/main.lua\0suffix", "x\n", 384},
            {".proc17-tmp-forged", "x\n", 384},
            {"src/main.lua", string.rep("x", 1048577), 384},
            {"src/main.lua", "x\n", 420},
        }
        for _, values in ipairs(cases) do
            local result, err = create(provider, handle, values[1], values[2], {
                file_mode = values[3],
            })
            H.assert_nil(result, "native hard-bound request denied")
            H.assert_eq(error_code(err), "invalid_request", "hard-bound denial typed")
        end
        H.assert_nil(read(repo .. "/src/main.lua"), "denied cases create no target")
    end)
end)

suite:check("TH-P14b native create parser independently rejects malformed bytes", function()
    require_provider()
    local initializer = assert(package.loadlib(
        "./native/proc17_repository_fs.so",
        "luaopen_proc17_repository_fs"
    ))
    local native = initializer()
    with_root(function(_, base, repo)
        local handle = assert(native.open_repository(base, "repo"))
        local cases = {
            {"src/main.lua\0suffix", "x\n", 384},
            {".proc17-tmp-forged", "x\n", 384},
            {"src/main.lua", "bad\0content", 384},
            {"src/main.lua", "bad\255content", 384},
            {"src/main.lua", string.rep("x", 1048577), 384},
            {"src/main.lua", "x\n", 420},
        }
        for _, values in ipairs(cases) do
            local result, err = native.create_text_file(
                handle, values[1], values[2], values[3])
            H.assert_nil(result, "native malformed request has no result")
            H.assert_eq(error_code(err), "invalid_request", "native parser code")
            H.assert_eq(err.cost.tool_calls, 0, "parser enters no syscall")
            H.assert_eq(err.cost.file_writes, 0, "parser enters no mutation")
        end
        assert(native.close(handle))
        H.assert_nil(read(repo .. "/src/main.lua"), "direct denials create no target")
    end)
end)

suite:check("TH-E02c native read parser independently enforces its hard bound", function()
    require_provider()
    local initializer = assert(package.loadlib(
        "./native/proc17_repository_fs.so",
        "luaopen_proc17_repository_fs"
    ))
    local native = initializer()
    with_root(function(_, base)
        local handle = assert(native.open_repository(base, "repo"))
        local cases = {
            {"src/main.lua\0suffix", 1},
            {".proc17-tmp-forged", 1},
            {"src/main.lua", 0},
            {"src/main.lua", 1048578},
            {"src/main.lua", 1.5},
        }
        for index, values in ipairs(cases) do
            local result, err = native.read_text_file(
                handle, values[1], values[2])
            H.assert_nil(result, "native malformed read denied " .. index)
            H.assert_eq(error_code(err), "invalid_request", "native read parser code")
            H.assert_eq(err.cost.tool_calls, 0, "native parser enters no syscall")
            H.assert_eq(err.cost.file_writes, 0, "native parser cannot mutate")
        end
        assert(native.close(handle))
    end)
end)

suite:check("TH-P14c adapter request envelope is exact before native dispatch", function()
    local provider = require_provider()
    with_root(function(_, base, repo)
        local handle = assert(open(provider, base))
        local cases = {
            {protocol_version = "wrong"},
            {content_bytes = 99},
            {precondition = "overwrite"},
            {command = {"touch", "outside"}},
        }
        for _, extra in ipairs(cases) do
            local result, err = create(provider, handle, "src/main.lua", "x\n", extra)
            H.assert_nil(result, "malformed envelope denied")
            H.assert_eq(error_code(err), "invalid_request", "envelope denial typed")
            H.assert_eq(err.cost.tool_calls, 0, "denial enters no provider call")
            H.assert_eq(err.cost.file_writes, 0, "denial enters no mutation")
        end
        H.assert_nil(read(repo .. "/src/main.lua"), "envelope denials create no file")
    end)
end)

suite:check("P14 replaced root identity invalidates handle", function()
    local provider = require_provider()
    with_root(function(root, base)
        local handle = assert(open(provider, base))
        command("mv " .. quote(root .. "/projects/repo") .. " "
            .. quote(root .. "/projects/repo-old"))
        command("mkdir " .. quote(root .. "/projects/repo"))
        command("mkdir " .. quote(root .. "/projects/repo/src"))
        local valid, err = provider.revalidate(handle)
        H.assert_nil(valid, "replacement root invalidates grant handle")
        H.assert_eq(error_code(err), "root_changed", "root change is typed")
        local result = create(provider, handle, "src/main.lua", "must not write\n")
        H.assert_nil(result, "stale handle cannot write")
        H.assert_nil(read(root .. "/projects/repo/src/main.lua"), "replacement root unchanged")
    end)
end)

suite:check("TH-E06 root replacement between create and read-back is denied", function()
    local provider = require_provider()
    with_root(function(root, base)
        local handle = assert(open(provider, base))
        assert(create(provider, handle, "src/main.lua", "created-before-race\n"))
        command("mv " .. quote(root .. "/projects/repo") .. " "
            .. quote(root .. "/projects/repo-old"))
        command("mkdir " .. quote(root .. "/projects/repo"))
        command("mkdir " .. quote(root .. "/projects/repo/src"))
        local observed, err = provider.read_text_file(handle, {
            relative_path = "src/main.lua",
            max_bytes = 21,
        })
        H.assert_nil(observed, "read-back cannot move to replacement root")
        H.assert_eq(error_code(err), "root_changed", "read-back root race typed")
        H.assert_nil(read(root .. "/projects/repo/src/main.lua"),
            "replacement root remains untouched")
    end)
end)

suite:check("TH-E05 native read-back is expected-plus-one bounded", function()
    local provider = require_provider()
    with_root(function(_, base)
        local handle = assert(open(provider, base))
        assert(create(provider, handle, "src/main.lua", "123456789"))
        local observed = assert(provider.read_text_file(handle, {
            relative_path = "src/main.lua",
            max_bytes = 6,
        }))
        H.assert_eq(observed.target_kind, "regular_file", "target remains regular")
        H.assert_eq(observed.bytes, 6, "reader returns at most supplied hard bound")
        H.assert_eq(#observed.content, 6, "content allocation stays bounded")
    end)
end)

if os.getenv("PROC17_TEST_BIND_MOUNT") == "1" then
    suite:check("P15 cross-device parent is denied", function()
        require_provider()
        error("test-only mount namespace fixture is not implemented", 0)
    end)
else
    suite:skip("P15 cross-device parent", "PROC17_TEST_BIND_MOUNT is not enabled")
end

suite:check("P16 native fault harness proves atomic final visibility", function()
    require_provider()
    local file = io.open("native/tests/test_proc17_repository_fs.c", "rb")
    H.assert_true(file ~= nil, "native fault-injection test source required")
    if file then file:close() end
    local ok = os.execute("make -C native test-create")
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
