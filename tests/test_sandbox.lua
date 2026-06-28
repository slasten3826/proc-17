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
assert_true(sandbox.check_path("README.md"), "relative path should be accepted")

local ok = sandbox.can_read_file({mode = "chaos"}, "README.md")
assert_true(ok, "relative read should be allowed")

ok = sandbox.can_write_file({mode = "chaos"}, "core/new.lua")
assert_false(ok, "chaos should not write implementation")

ok = sandbox.can_write_file({mode = "chaos"}, "docs/00_chaos/note.md")
assert_true(ok, "chaos should write chaos docs")

ok = sandbox.can_write_file({mode = "manifest"}, "core/new.lua")
assert_true(ok, "manifest should write implementation")

ok = sandbox.can_run_command({mode = "manifest"}, "ls")
assert_false(ok, "shell commands should be denied")

print("test_sandbox ok")
