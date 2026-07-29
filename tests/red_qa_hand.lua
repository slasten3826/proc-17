package.path = "./?.lua;./?/init.lua;" .. package.path

local suites = {
    "tests.test_qa_fixture_guard",
    "tests.test_qa_contract",
    "tests.test_qa_execution",
    "tests.test_qa_native_supervisor",
    "tests.test_qa_check_verdict",
}

local failures = {}
local green = 0

_G.PROC17_QA_RED_BATTERY = true
_G.PROC17_QA_RED_COUNTS = {green = 0, red = 0, skip = 0}

for _, name in ipairs(suites) do
    package.loaded[name] = nil
    local ok, err = pcall(require, name)
    if ok then
        green = green + 1
        print("qa-hand-suite GREEN " .. name)
    else
        failures[#failures + 1] = name .. ": " .. tostring(err)
        print("qa-hand-suite RED " .. name)
    end
end

local controls = _G.PROC17_QA_RED_COUNTS
_G.PROC17_QA_RED_BATTERY = nil
_G.PROC17_QA_RED_COUNTS = nil

print(string.format(
    "qa-hand control matrix: green=%d red=%d skip=%d total=%d",
    controls.green,
    controls.red,
    controls.skip,
    controls.green + controls.red + controls.skip
))

if controls.green ~= 82 or controls.red ~= 2 or controls.skip ~= 0 then
    error("QA hand red matrix drifted from exact M3 82/2", 0)
end

print(string.format(
    "qa-hand red baseline: green=%d red=%d total=%d",
    green,
    #failures,
    #suites
))

if #failures > 0 then
    os.exit(1)
end

print("qa hand tests ok")
