package.path = "./?.lua;./?/init.lua;" .. package.path

local fake = require("tools.fake")

local result = fake.run({
    action = "inspect_task",
    input = {task = "hello"},
})

if result.ok ~= true then
    error("fake tool should succeed")
end

if result.output.task ~= "hello" then
    error("fake tool did not echo task")
end

local bad = fake.run({action = "nope"})
if bad.ok ~= false then
    error("invalid fake tool action should fail")
end

local denied = fake.run({
    action = "write_file",
    input = {
        mode = "chaos",
        path = "core/new.lua",
        content = "return {}",
    },
})

if denied.ok ~= false then
    error("chaos mode should deny implementation write")
end

local allowed_chaos = fake.run({
    action = "write_file",
    input = {
        mode = "chaos",
        path = "docs/00_chaos/new_note.md",
        content = "raw",
    },
})

if allowed_chaos.ok ~= true then
    error("chaos mode should allow chaos docs write")
end

local allowed_manifest = fake.run({
    action = "write_file",
    input = {
        mode = "manifest",
        path = "core/new.lua",
        content = "return {}",
    },
})

if allowed_manifest.ok ~= true then
    error("manifest mode should allow implementation write")
end

print("test_tools ok")
