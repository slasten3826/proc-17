package.path = "./?.lua;./?/init.lua;" .. package.path

local suites = {
    "tests.test_repository_fixture_guard",
    "tests.test_repository_provider_loader",
    "tests.test_repository_provider_root",
    "tests.test_repository_prewrite_security",
    "tests.test_repository_capability",
    "tests.test_repository_intent",
    "tests.test_repository_action",
    "tests.test_repository_effect",
    "tests.test_repository_provider_linux",
    "tests.test_repository_effect_linux",
    "tests.test_repository_progress",
    "tests.test_repository_hostile_audit",
    "tests.test_repository_route",
    "tests.test_repository_manifest",
}

local failures = {}
local green = 0

for _, name in ipairs(suites) do
    package.loaded[name] = nil
    local ok, err = pcall(require, name)
    if ok then
        green = green + 1
        print("repository-hands-suite GREEN " .. name)
    else
        failures[#failures + 1] = name .. ": " .. tostring(err)
        print("repository-hands-suite RED " .. name)
    end
end

print(string.format(
    "repository-hands red baseline: green=%d red=%d total=%d",
    green,
    #failures,
    #suites
))

if #failures > 0 then
    os.exit(1)
end

print("repository hands tests ok")
