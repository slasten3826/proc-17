package.path = "./?.lua;./?/init.lua;" .. package.path

local fs = require("tools.fs")

local path = "docs/00_chaos/_fs_tool_test.tmp"
os.remove(path)

local denied = fs.run({
    action = "write_file",
    input = {
        mode = "chaos",
        path = "core/_fs_tool_test.tmp",
        content = "bad",
    },
})

if denied.ok ~= false then
    error("chaos mode should deny implementation fs write")
end

local unsafe = fs.run({
    action = "read_file",
    input = {
        path = "../README.md",
    },
})

if unsafe.ok ~= false then
    error("fs tool should deny parent traversal")
end

local written = fs.run({
    action = "write_file",
    input = {
        mode = "chaos",
        path = path,
        content = "fs tool ok",
    },
})

if written.ok ~= true then
    error("chaos docs fs write should succeed: " .. tostring(written.error))
end

local read = fs.run({
    action = "read_file",
    input = {
        path = path,
    },
})

if read.ok ~= true then
    error("fs read should succeed: " .. tostring(read.error))
end

if read.output.content ~= "fs tool ok" then
    error("fs read content mismatch")
end

os.remove(path)

print("test_fs_tool ok")
