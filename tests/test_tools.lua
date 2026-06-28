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

print("test_tools ok")
