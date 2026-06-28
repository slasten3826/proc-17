package.path = "./?.lua;./?/init.lua;" .. package.path

local topology = require("core.topology")

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

assert_true(topology.is_adjacent("▽", "☰"), "FLOW -> CONNECT should be valid")
assert_true(topology.is_adjacent("OBSERVE", "RUNTIME"), "OBSERVE -> RUNTIME should be valid")
assert_false(topology.is_adjacent("▽", "△"), "FLOW -> MANIFEST should be invalid")

local ok = topology.validate_trace({"▽", "☰", "☴", "☱", "△"})
assert_true(ok, "valid trace should pass")

local invalid, err = topology.validate_trace({"▽", "△"})
assert_false(invalid, "invalid trace should fail")
assert_true(err.index == 1, "invalid trace error index")

print("test_topology ok")
