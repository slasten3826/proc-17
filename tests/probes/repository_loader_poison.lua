package.path = "./?.lua;./?/init.lua;" .. package.path

local hostile_directory = assert(arg[1], "hostile module directory required")
package.cpath = hostile_directory .. "/?.so"

local provider = require("runtime.repository_provider")
local available, diagnostic = provider.available()

assert(available == true, tostring(diagnostic))
assert(provider.provider_id == "linux.openat2.renameat2.v0")
assert(provider.contract_id == "repository.provider.create_readback.v0")
print("repository_loader_poison probe ok")
