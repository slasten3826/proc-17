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
    "tests.test_trace_store",
    "tests.test_cli",
}

for _, name in ipairs(tests) do
    require(name)
end

print("all tests ok")
