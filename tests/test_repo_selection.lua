package.path = "./?.lua;./?/init.lua;" .. package.path

local selection = require("logic.repo_selection")

local listing = {
    kind = "repo_listing_payload",
    entries = {
        {path = "organs/repo_listing.lua", kind = "file", truth_status = "runtime_confirmed"},
        {path = "tools/fs.lua", kind = "file", truth_status = "runtime_confirmed"},
        {path = "docs/02_crystall", kind = "directory", truth_status = "runtime_confirmed"},
        {path = "docs/02_crystall/blueprints/repo_listing_eye.v0.md", kind = "file", truth_status = "runtime_confirmed"},
    },
}

local payload, err = selection.validate({
    listing = listing,
    text = "Read `organs/repo_listing.lua` next because it is relevant.",
})

if not payload then
    error("repo selection should validate listed file: " .. tostring(err))
end

if payload.kind ~= "repo_selection_payload" then
    error("repo selection payload kind mismatch")
end

if #payload.accepted_paths ~= 1 then
    error("repo selection should accept one listed file")
end

if payload.accepted_paths[1].path ~= "organs/repo_listing.lua" then
    error("repo selection accepted wrong path")
end

if payload.accepted_paths[1].truth_status ~= "runtime_confirmed" then
    error("repo selection accepted path should be runtime_confirmed")
end

if payload.reasons[1].truth_status ~= "semantic_proposal" then
    error("repo selection reason should stay semantic_proposal")
end

local absent = selection.validate({
    listing = listing,
    text = "Read `missing/file.lua` next.",
})

if #absent.accepted_paths ~= 0 then
    error("repo selection should not accept absent path")
end

if absent.rejected_paths[1].reason ~= "absent_from_listing" then
    error("repo selection should reject absent path")
end

local directory = selection.validate({
    listing = listing,
    text = "Read docs/02_crystall next.",
})

if #directory.accepted_paths ~= 0 then
    error("repo selection should reject directory by default")
end

if directory.rejected_paths[1].reason ~= "directory_not_allowed" then
    error("repo selection should mark directory_not_allowed")
end

local allowed_directory = selection.validate({
    listing = listing,
    text = "Read docs/02_crystall next.",
    allow_directories = true,
})

if #allowed_directory.accepted_paths ~= 1 then
    error("repo selection should allow directory when configured")
end

local limited = selection.validate({
    listing = listing,
    text = "Read organs/repo_listing.lua and tools/fs.lua next.",
    max_paths = 1,
})

if #limited.accepted_paths ~= 1 then
    error("repo selection should accept only max_paths")
end

if #limited.rejected_paths ~= 1 or limited.rejected_paths[1].reason ~= "max_paths_exceeded" then
    error("repo selection should reject paths beyond max_paths")
end

local duplicate = selection.validate({
    listing = listing,
    text = "Read organs/repo_listing.lua and `organs/repo_listing.lua` again.",
})

if #duplicate.accepted_paths ~= 1 then
    error("repo selection should deduplicate repeated paths")
end

local unparsed = selection.validate({
    listing = listing,
    text = "Need a broader listing.",
})

if #unparsed.accepted_paths ~= 0 then
    error("repo selection should not accept anything from no path text")
end

if unparsed.unparsed_text ~= "Need a broader listing." then
    error("repo selection should preserve unparsed text")
end

local markdown = selection.validate({
    listing = listing,
    text = "1. **tools/fs.lua** - file facade\n2. **missing/ghost.lua** - invalid\n3. **docs/02_crystall** - directory\nThis sentence mentions docs and logic as words only.",
})

if #markdown.accepted_paths ~= 1 or markdown.accepted_paths[1].path ~= "tools/fs.lua" then
    error("repo selection should accept markdown bold path")
end

local saw_missing = false
local saw_directory = false
for _, rejected in ipairs(markdown.rejected_paths) do
    if rejected.path == "missing/ghost.lua" and rejected.reason == "absent_from_listing" then
        saw_missing = true
    end
    if rejected.path == "docs/02_crystall" and rejected.reason == "directory_not_allowed" then
        saw_directory = true
    end
    if rejected.path == "docs" or rejected.path == "logic" then
        error("repo selection should not reject plain directory words")
    end
end

if not saw_missing then
    error("repo selection should reject markdown absent path")
end

if not saw_directory then
    error("repo selection should reject markdown directory path")
end

print("test_repo_selection ok")
