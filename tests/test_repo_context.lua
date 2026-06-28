package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local repo_context = require("organs.repo_context")

local payload, err = repo_context.build({
    files = {"README.md"},
    max_bytes_per_file = 64,
})

if not payload then
    error("repo context should read allowed file: " .. tostring(err))
end

if payload.kind ~= "repo_context_payload" then
    error("repo context payload kind mismatch")
end

if payload.files[1].truth_status ~= "runtime_confirmed" then
    error("repo context file should be runtime_confirmed")
end

if payload.files[1].path ~= "README.md" then
    error("repo context path mismatch")
end

if payload.files[1].bytes > 64 then
    error("repo context should enforce max_bytes_per_file")
end

local denied = repo_context.build({
    files = {"../README.md"},
})

if denied ~= nil then
    error("repo context should deny unsafe path")
end

local p = packet.new("repo context test")
packet.enter(p, "☰")
packet.enter(p, "☴")

local attached = repo_context.attach(p, {
    files = {"README.md"},
    max_bytes_per_file = 32,
})

if not attached then
    error("repo context attach should succeed")
end

local event = p.trace[#p.trace]
if event.type ~= "observation" then
    error("repo context attach should append observation")
end

if event.payload.kind ~= "repo_context" then
    error("repo context observation kind mismatch")
end

if event.truth_status ~= "runtime_confirmed" then
    error("repo context observation should be runtime_confirmed")
end

print("test_repo_context ok")
