package.path = "./?.lua;./?/init.lua;" .. package.path

local sandbox = require("core.sandbox")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local function assert_false(value, message)
    if value then
        error(message or "assertion failed", 2)
    end
end

assert_false(sandbox.check_path("/tmp/x"), "absolute path should be denied")
assert_false(sandbox.check_path("../README.md"), "parent traversal should be denied")
assert_false(sandbox.check_path(".git/config"), "hidden control dirs should be denied")
assert_true(sandbox.check_path("README.md"), "relative path should be accepted")
assert_true(sandbox.is_workspace_path("sandbox/projects/hello/main.py"), "sandbox path should be workspace path")
assert_false(sandbox.is_workspace_path("README.md"), "repo root path should not be workspace path")

local ok = sandbox.can_read_file({mode = "chaos"}, "README.md")
assert_true(ok, "relative read should be allowed")

ok = sandbox.can_write_file({context = "workspace"}, "sandbox/projects/hello/main.py")
assert_true(ok, "workspace context should write under sandbox")

ok = sandbox.can_write_file({context = "workspace"}, "README.md")
assert_false(ok, "workspace context should deny repo root write")

ok = sandbox.can_write_file({context = "workspace"}, "sandbox/projects/.git/config")
assert_false(ok, "workspace context should deny git control path")

ok = sandbox.can_make_dir({context = "workspace"}, "sandbox/projects/hello")
assert_true(ok, "workspace context should create sandbox dir")

ok = sandbox.can_make_dir({context = "workspace"}, "docs/00_chaos/x")
assert_false(ok, "workspace context should deny docs dir")

ok = sandbox.can_write_file({mode = "chaos"}, "core/new.lua")
assert_false(ok, "chaos should not write implementation")

ok = sandbox.can_write_file({mode = "chaos"}, "docs/00_chaos/note.md")
assert_true(ok, "chaos should write chaos docs")

ok = sandbox.can_write_file({mode = "manifest"}, "core/new.lua")
assert_true(ok, "manifest should write implementation")

ok = sandbox.can_run_command({mode = "manifest"}, "ls")
assert_false(ok, "shell commands should be denied")

print("test_sandbox ok")
