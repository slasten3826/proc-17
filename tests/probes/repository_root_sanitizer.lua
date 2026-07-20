package.path = "./?.lua;./?/init.lua;" .. package.path

local fixture_root = assert(arg[1], "identity-owned fixture root required")
assert(fixture_root:match(
    "^/tmp/proc17%-repository%-hand%-[A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9]$"
), "sanitizer probe refuses non-fixture root")

local provider = require("runtime.repository_provider")
local available = provider.available()
assert(available == true, "native provider must already be built")

local input = {
    project_base = fixture_root .. "/projects",
    repository_path = "repo",
}

for _ = 1, 128 do
    local handle = assert(provider.open_repository(input))
    assert(provider.revalidate(handle))
    assert(provider.close(handle))
    assert(provider.close(handle))
end

local handles = {}
for index = 1, 128 do
    handles[index] = assert(provider.open_repository(input))
end
handles = nil
collectgarbage("collect")
collectgarbage("collect")

for _, malformed in ipairs({
    {project_base = "/", repository_path = "repo"},
    {project_base = "/tmp/../tmp", repository_path = "repo"},
    {project_base = "/tmp", repository_path = "../repo"},
    {project_base = "/tmp", repository_path = "repo\0suffix"},
    {project_base = "/tmp", repository_path = string.rep("a", 1025)},
}) do
    local handle, err = provider.open_repository(malformed)
    assert(handle == nil)
    assert(type(err) == "table" and err.code == "invalid_request")
end

print("repository_root_sanitizer probe ok")
