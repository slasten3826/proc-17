package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")

local encoded = json.encode({b = true, a = {1, "x"}})
local decoded = json.decode(encoded)

if decoded.b ~= true then
    error("json boolean roundtrip failed")
end

if decoded.a[1] ~= 1 or decoded.a[2] ~= "x" then
    error("json array roundtrip failed")
end

print("test_json ok")
