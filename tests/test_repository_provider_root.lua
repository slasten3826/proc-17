package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local capabilities = require("runtime.repository_capability")
local fixture = require("tests.support.repository_hands")
local native_build = require("tests.support.repository_native_build")
local owned = require("tests.support.owned_temp_root")
local suite = H.new("repository-provider-root")

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

local function command(text)
    local ok, why, code = os.execute(text)
    if ok ~= true or (code ~= nil and code ~= 0) then
        error("fixture command failed: " .. tostring(why) .. ":" .. tostring(code), 2)
    end
end

local function read_command(text)
    local stream = assert(io.popen(text, "r"))
    local output = assert(stream:read("*a"))
    local ok, why, code = stream:close()
    if ok ~= true or (code ~= nil and code ~= 0) then
        error("fixture observation failed: "
            .. tostring(why) .. ":" .. tostring(code), 2)
    end
    return output
end

local function open(current, root, repository_path, project_base)
    return current.open_repository({
        project_base = project_base or root.project_base,
        repository_path = repository_path or "repo",
    })
end

local function error_code(value)
    return type(value) == "table" and value.code or tostring(value)
end

local function process_id()
    local file = assert(io.open("/proc/self/stat", "rb"))
    local text = assert(file:read("*l"))
    assert(file:close())
    return assert(text:match("^(%d+)"), "cannot observe process id")
end

local function descriptor_count()
    local pid = process_id()
    local output = read_command("find /proc/" .. pid
        .. "/fd -mindepth 1 -maxdepth 1 -printf '.\\n'")
    local count = 0
    for _ in output:gmatch("\n") do
        count = count + 1
    end
    return count
end

local function tree_snapshot(root)
    assert(owned.assert_owned_path(root, root.repository))
    return read_command("find " .. quote(root.path)
        .. " -xdev -printf '%P\\t%y\\t%m\\t%s\\n' | sort")
end

suite:check("ROOT0 exact root opens as opaque identity", function()
    local current = require_provider()
    owned.with_root(function(root)
        local handle, identity = assert(open(current, root))
        H.assert_eq(type(handle), "userdata", "native handle is opaque userdata")
        H.assert_eq(getmetatable(handle), "repository.handle.v0",
            "metatable is protected by a public type tag")
        H.assert_eq(identity.repository_path, "repo", "relative identity")
        H.assert_eq(identity.host_path, root.repository, "private host identity")
        H.assert_true(type(identity.project_base.device) == "number",
            "base device is numeric")
        H.assert_true(type(identity.project_base.inode) == "number",
            "base inode is numeric")
        H.assert_true(type(identity.root.device) == "number", "root device is numeric")
        H.assert_true(type(identity.root.inode) == "number", "root inode is numeric")
        assert(current.close(handle))
    end)
end)

suite:check("ROOT1 stable root revalidates without mutation", function()
    local current = require_provider()
    owned.with_root(function(root)
        local before = tree_snapshot(root)
        local handle, identity = assert(open(current, root))
        local result = assert(current.revalidate(handle))
        H.assert_eq(result.protocol_version, "repository.provider_result.v0",
            "typed result")
        H.assert_eq(result.operation, "revalidate", "operation")
        H.assert_eq(result.outcome, "valid", "stable identity")
        H.assert_eq(result.root.device, identity.root.device, "same root device")
        H.assert_eq(result.root.inode, identity.root.inode, "same root inode")
        H.assert_false(result.mutation_primitive_entered, "no mutation primitive")
        H.assert_false(result.published, "nothing published")
        H.assert_eq(result.cost.file_writes, 0, "no write cost")
        assert(current.close(handle))
        H.assert_eq(tree_snapshot(root), before, "open/revalidate/close changes no tree")
    end)
end)

suite:check("ROOT2 repository-root symlink is denied", function()
    local current = require_provider()
    owned.with_root(function(root)
        command("ln -s " .. quote(root.repository) .. " "
            .. quote(root.project_base .. "/repo-link"))
        local handle, err = open(current, root, "repo-link")
        H.assert_nil(handle, "symlink root has no handle")
        H.assert_true(error_code(err) == "path_symlink"
            or error_code(err) == "path_containment_denied", "symlink denial typed")
    end)
end)

suite:check("ROOT3 project-base symlink is denied", function()
    local current = require_provider()
    owned.with_root(function(root)
        local linked_base = root.path .. "/projects-link"
        command("ln -s " .. quote(root.project_base) .. " " .. quote(linked_base))
        local handle, err = open(current, root, "repo", linked_base)
        H.assert_nil(handle, "symlink base has no handle")
        H.assert_eq(error_code(err), "path_symlink", "base symlink denial typed")
    end)
end)

suite:check("ROOT3b proc magic-link project base is denied", function()
    local current = require_provider()
    local handle, err = current.open_repository({
        project_base = "/proc/self/root/tmp",
        repository_path = "proc17-missing-repository",
    })
    H.assert_nil(handle, "magic-link base has no handle")
    H.assert_eq(error_code(err), "path_symlink", "magic-link denial typed")
end)

suite:check("ROOT4 missing and non-directory roots are typed", function()
    local current = require_provider()
    owned.with_root(function(root)
        local missing, missing_err = open(current, root, "missing")
        H.assert_nil(missing, "missing root has no handle")
        H.assert_eq(error_code(missing_err), "root_missing", "missing root code")

        local path = root.project_base .. "/not-directory"
        local file = assert(io.open(path, "wb"))
        assert(file:write("sentinel\n"))
        assert(file:close())
        local regular, regular_err = open(current, root, "not-directory")
        H.assert_nil(regular, "regular file root has no handle")
        H.assert_eq(error_code(regular_err), "root_invalid", "non-directory code")
    end)
end)

suite:check("ROOT5 repository replacement invalidates handle", function()
    local current = require_provider()
    owned.with_root(function(root)
        local handle = assert(open(current, root))
        command("mv " .. quote(root.repository) .. " "
            .. quote(root.project_base .. "/repo-old"))
        command("mkdir " .. quote(root.repository))
        command("mkdir " .. quote(root.repository .. "/src"))
        local valid, err = current.revalidate(handle)
        H.assert_nil(valid, "replacement cannot inherit identity")
        H.assert_eq(error_code(err), "root_changed", "replacement code")
        assert(current.close(handle))
    end)
end)

suite:check("ROOT6 project-base replacement invalidates handle", function()
    local current = require_provider()
    owned.with_root(function(root)
        local handle = assert(open(current, root))
        local old_base = root.path .. "/projects-old"
        command("mv " .. quote(root.project_base) .. " " .. quote(old_base))
        command("mkdir " .. quote(root.project_base))
        command("mkdir " .. quote(root.repository))
        local valid, err = current.revalidate(handle)
        H.assert_nil(valid, "replacement base cannot inherit authority")
        H.assert_eq(error_code(err), "root_changed", "base replacement code")
        assert(current.close(handle))
    end)
end)

suite:check("ROOT7 renamed-away root invalidates named identity", function()
    local current = require_provider()
    owned.with_root(function(root)
        local handle = assert(open(current, root))
        command("mv " .. quote(root.repository) .. " "
            .. quote(root.project_base .. "/repo-moved"))
        local valid, err = current.revalidate(handle)
        H.assert_nil(valid, "missing named root is stale")
        H.assert_eq(error_code(err), "root_changed", "rename code")
        assert(current.close(handle))
    end)
end)

suite:check("ROOT8 close is idempotent and closed handle stays closed", function()
    local current = require_provider()
    owned.with_root(function(root)
        local handle = assert(open(current, root))
        H.assert_true(current.close(handle), "first close succeeds")
        H.assert_true(current.close(handle), "second close is a no-op")
        local valid, err = current.revalidate(handle)
        H.assert_nil(valid, "closed handle cannot revalidate")
        H.assert_eq(error_code(err), "handle_closed", "closed state is typed")
    end)
end)

suite:check("ROOT9 explicit close and GC return descriptors to baseline", function()
    local current = require_provider()
    owned.with_root(function(root)
        collectgarbage("collect")
        local baseline = descriptor_count()
        local handles = {}
        for index = 1, 32 do
            handles[index] = assert(open(current, root))
        end
        H.assert_true(descriptor_count() >= baseline + 64,
            "each live handle retains base and root descriptors")
        for _, handle in ipairs(handles) do
            assert(current.close(handle))
        end
        H.assert_eq(descriptor_count(), baseline, "explicit close restores baseline")

        for index = 1, 32 do
            handles[index] = assert(open(current, root))
        end
        H.assert_true(descriptor_count() >= baseline + 64,
            "GC sample owns descriptors before collection")
        handles = nil
        collectgarbage("collect")
        collectgarbage("collect")
        H.assert_eq(descriptor_count(), baseline, "GC restores descriptor baseline")
    end)
end)

suite:check("ROOT10 forged handles fail loudly", function()
    local current = require_provider()
    for _, value in ipairs({42, "handle", {}, io.stdout}) do
        local ok, err = pcall(current.revalidate, value)
        H.assert_false(ok, "forged handle is a harness failure")
        H.assert_contains(err, "handle", "failure names handle contract")
    end
end)

suite:check("ROOT11 real provider mints private capability only", function()
    local current = require_provider()
    owned.with_root(function(root)
        local registry = assert(capabilities.new({
            session_id = "session-repository-root",
            providers = {[current.provider_id] = current},
        }))
        local projection = assert(capabilities.mint(registry, fixture.grant_input({
            lineage_id = "lineage-repository-root",
            repository_id = "root-fixture",
            project_base = root.project_base,
            repository_path = "repo",
        })))
        H.assert_nil(projection.host_path, "projection has no absolute path")
        H.assert_nil(projection.repository_handle, "projection has no handle")
        H.assert_nil(projection.provider, "projection has no provider")
        assert(capabilities.revoke(registry, projection.grant_id))
    end)
end)

suite:check("ROOT11b native root parser independently rejects malformed bounds", function()
    local current = require_provider()
    local components = {}
    for index = 1, 65 do
        components[index] = "a"
    end
    local cases = {
        {project_base = "/", repository_path = "repo"},
        {project_base = "/tmp/../tmp", repository_path = "repo"},
        {project_base = "/tmp//proc17", repository_path = "repo"},
        {project_base = "/tmp/proc17\0suffix", repository_path = "repo"},
        {project_base = "/tmp", repository_path = "/repo"},
        {project_base = "/tmp", repository_path = "../repo"},
        {project_base = "/tmp", repository_path = "packets"},
        {project_base = "/tmp", repository_path = string.rep("a", 256)},
        {project_base = "/tmp", repository_path = table.concat(components, "/")},
        {project_base = "/tmp", repository_path = string.rep("a", 1025)},
        {project_base = "/tmp", repository_path = "repo\0suffix"},
    }
    for _, input in ipairs(cases) do
        local handle, err = current.open_repository(input)
        H.assert_nil(handle, "malformed root input has no handle")
        H.assert_eq(error_code(err), "invalid_request", "native parser code")
        H.assert_eq(err.cost.tool_calls, 0, "parser rejection enters no syscall")
        H.assert_false(err.mutation_primitive_entered, "parser cannot mutate")
    end
end)

suite:check("ROOT11c nested repository identity resolves beneath base", function()
    local current = require_provider()
    owned.with_root(function(root)
        local handle, identity = assert(current.open_repository({
            project_base = root.path,
            repository_path = "projects/repo",
        }))
        H.assert_eq(identity.host_path, root.repository, "nested exact host identity")
        assert(current.close(handle))
    end)
end)

suite:check("ROOT12 step 7.6 admits only no-replace create and bounded read", function()
    local file = assert(io.open("native/proc17_repository_fs.c", "rb"))
    local source = assert(file:read("*a"))
    assert(file:close())
    for _, required in ipairs({
        "O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC",
        "SYS_getrandom",
        "SYS_renameat2",
        "RENAME_NOREPLACE",
        "fchmod(temp_fd, file_mode)",
        "sync_private_file(temp_fd)",
        "sync_parent_directory(parent_fd)",
        "remove_private_temp(parent_fd, result->temp_name)",
        "O_PATH | O_NOFOLLOW | O_CLOEXEC",
        "O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC",
        "PROC17_MAX_READ_BYTES",
        "same_file_version",
        "reobserve_named_target",
    }) do
        H.assert_contains(source, required, "required bounded primitive")
    end
    for _, forbidden in ipairs({
        "O_TRUNC",
        "O_APPEND",
        "O_TMPFILE",
        "pwrite(",
        "rename(",
        "renameat(",
    }) do
        H.assert_false(source:find(forbidden, 1, true) ~= nil,
            "broader mutation primitive present: " .. forbidden)
    end
end)

suite:finish()
print("test_repository_provider_root ok")
