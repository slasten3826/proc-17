package.path = "./?.lua;./?/init.lua;" .. package.path

local modes = require("core.modes")

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

assert_true(modes.is_valid("chaos"), "chaos mode should be valid")
assert_false(modes.is_valid("nope"), "invalid mode should fail")

assert_false(modes.can_write_code("chaos"), "chaos must not write code")
assert_false(modes.can_write_code("table"), "table must not write code")
assert_false(modes.can_write_code("crystall"), "crystall must not write code")
assert_true(modes.can_write_code("manifest"), "manifest can write code")

local ok = modes.can_write_path("chaos", "docs/00_chaos/note.md")
assert_true(ok, "chaos should write chaos docs")

ok = modes.can_write_path("chaos", "core/new.lua")
assert_false(ok, "chaos should not write implementation")

ok = modes.can_write_path("table", "docs/01_table/yellowprints/x.md")
assert_true(ok, "table should write table docs")

ok = modes.can_write_path("crystall", "docs/02_crystall/blueprints/x.md")
assert_true(ok, "crystall should write crystall docs")

ok = modes.can_write_path("manifest", "core/new.lua")
assert_true(ok, "manifest should write implementation")

print("test_modes ok")
