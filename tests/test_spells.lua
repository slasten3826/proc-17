package.path = "./?.lua;./?/init.lua;" .. package.path

local spells = require("logic.spells")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": " .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function write(path, content)
    os.execute("mkdir -p sandbox")
    local file = assert(io.open(path, "w"))
    file:write(content)
    file:close()
end

write("sandbox/proc17_spell_valid.py", "print('ok')\n")
write("sandbox/proc17_spell_invalid.py", "def bad(:\n")
write("sandbox/proc17_spell_valid.json", "{\"ok\": true}\n")
write("sandbox/proc17_spell_invalid.json", "{bad json")

local exists = assert(spells.run({
    kind = "check_file_exists",
    name = "exists",
    path = "sandbox/proc17_spell_valid.py",
}))
assert_eq(exists.success, true, "existing file spell succeeds")
assert_eq(exists.truth_status, "runtime_confirmed", "exists truth")

local missing = assert(spells.run({
    kind = "check_file_exists",
    name = "missing",
    path = "sandbox/proc17_spell_missing.py",
}))
assert_eq(missing.success, false, "missing file spell fails")

local valid_py = assert(spells.run({
    kind = "py_compile_python_file",
    name = "py_compile",
    path = "sandbox/proc17_spell_valid.py",
}))
assert_eq(valid_py.success, true, "valid python compiles")

local invalid_py = assert(spells.run({
    kind = "py_compile_python_file",
    name = "py_compile",
    path = "sandbox/proc17_spell_invalid.py",
}))
assert_eq(invalid_py.success, false, "invalid python fails")

local valid_json = assert(spells.run({
    kind = "validate_json_file",
    name = "json",
    path = "sandbox/proc17_spell_valid.json",
}))
assert_eq(valid_json.success, true, "valid json passes")

local invalid_json = assert(spells.run({
    kind = "validate_json_file",
    name = "json",
    path = "sandbox/proc17_spell_invalid.json",
}))
assert_eq(invalid_json.success, false, "invalid json fails")

local denied, denied_err = spells.run({
    kind = "check_file_exists",
    name = "denied",
    path = "../outside",
})
assert_true(not denied, "parent traversal denied")
assert_eq(denied_err, "parent traversal is not allowed", "denied reason")

print("test_spells ok")
