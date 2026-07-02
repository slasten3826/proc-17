package.path = "./?.lua;./?/init.lua;" .. package.path

local tests = {
    "tests.test_json",
    "tests.test_modes",
    "tests.test_sandbox",
    "tests.test_topology",
    "tests.test_packet",
    "tests.test_substrates",
    "tests.test_tools",
    "tests.test_fs_tool",
    "tests.test_encode",
    "tests.test_choose",
    "tests.test_cycle",
    "tests.test_body",
    "tests.test_observe",
    "tests.test_organs_encode_choose",
    "tests.test_manifest",
    "tests.test_operator_hints",
    "tests.test_repo_selection",
    "tests.test_runner",
    "tests.test_router",
    "tests.test_tension_runner",
}

for _, name in ipairs(tests) do
    require(name)
end

print("all tests ok")
