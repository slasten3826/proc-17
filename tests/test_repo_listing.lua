package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local repo_listing = require("organs.repo_listing")

local payload, err = repo_listing.build({
    prefix = ".",
    max_depth = 3,
    max_entries = 256,
})

if not payload then
    error("repo listing should succeed: " .. tostring(err))
end

if payload.kind ~= "repo_listing_payload" then
    error("repo listing payload kind mismatch")
end

if payload.truth_status ~= "runtime_confirmed" then
    error("repo listing payload should be runtime_confirmed")
end

local saw_readme = false
for _, entry in ipairs(payload.entries) do
    if entry.truth_status ~= "runtime_confirmed" then
        error("repo listing entry should be runtime_confirmed")
    end
    if entry.path == "README.md" then
        saw_readme = true
    end
    if entry.path == ".git" or entry.path:sub(1, 5) == ".git/" then
        error("repo listing should omit ignored .git paths")
    end
end

if not saw_readme then
    error("repo listing should include README.md")
end

local denied = repo_listing.build({
    prefix = "../",
})

if denied ~= nil then
    error("repo listing should deny parent traversal")
end

local absolute = repo_listing.build({
    prefix = "/tmp",
})

if absolute ~= nil then
    error("repo listing should deny absolute path")
end

local truncated = repo_listing.build({
    prefix = ".",
    max_entries = 1,
})

if not truncated or truncated.truncated ~= true then
    error("repo listing should mark max_entries truncation")
end

local p = packet.new("repo listing test")
packet.enter(p, "☰")
packet.enter(p, "☴")

local attached = repo_listing.attach(p, {
    prefix = ".",
    max_entries = 8,
})

if not attached then
    error("repo listing attach should succeed")
end

local event = p.trace[#p.trace]
if event.type ~= "observation" then
    error("repo listing attach should append observation")
end

if event.payload.kind ~= "repo_listing" then
    error("repo listing observation kind mismatch")
end

print("test_repo_listing ok")
