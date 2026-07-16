package.path = "./?.lua;./?/init.lua;" .. package.path

local fs = require("tools.fs")

local path = "docs/00_chaos/_fs_tool_test.tmp"
os.remove(path)
os.remove("sandbox/projects/fs_tool_test/main.py")
os.remove("sandbox/projects/fs_tool_test")
os.remove("sandbox/projects")
os.remove("sandbox")

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

local workspace_denied = fs.run({
    action = "write_file",
    input = {
        context = "workspace",
        path = "README.md",
        content = "bad",
    },
})

if workspace_denied.ok ~= false then
    error("workspace write should deny repo root path")
end

local sandbox_dir = fs.run({
    action = "make_dir",
    input = {
        context = "workspace",
        path = "sandbox",
    },
})

if sandbox_dir.ok ~= true then
    error("workspace make_dir sandbox should succeed: " .. tostring(sandbox_dir.error))
end

local projects_dir = fs.run({
    action = "make_dir",
    input = {
        context = "workspace",
        path = "sandbox/projects",
    },
})

if projects_dir.ok ~= true then
    error("workspace make_dir projects should succeed: " .. tostring(projects_dir.error))
end

local project_dir = fs.run({
    action = "make_dir",
    input = {
        context = "workspace",
        path = "sandbox/projects/fs_tool_test",
    },
})

if project_dir.ok ~= true then
    error("workspace make_dir project should succeed: " .. tostring(project_dir.error))
end

local workspace_written = fs.run({
    action = "write_file",
    input = {
        context = "workspace",
        path = "sandbox/projects/fs_tool_test/main.py",
        content = "print('workspace ok')\n",
    },
})

if workspace_written.ok ~= true then
    error("workspace create_only write should succeed: " .. tostring(workspace_written.error))
end

if workspace_written.metadata.write_mode ~= "create_only" then
    error("workspace write should default to create_only")
end

local duplicate = fs.run({
    action = "write_file",
    input = {
        context = "workspace",
        path = "sandbox/projects/fs_tool_test/main.py",
        content = "print('overwrite')\n",
    },
})

if duplicate.ok ~= false then
    error("workspace create_only write should deny existing file")
end

local workspace_read = fs.run({
    action = "read_file",
    input = {
        context = "workspace",
        path = "sandbox/projects/fs_tool_test/main.py",
    },
})

if workspace_read.ok ~= true or workspace_read.output.content ~= "print('workspace ok')\n" then
    error("workspace read should return created file")
end

local listed = fs.run({
    action = "list_dir",
    input = {
        path = ".",
        limits = {
            max_depth = 1,
            max_entries = 128,
            max_path_bytes = 240,
        },
    },
})

if listed.ok ~= true then
    error("fs list_dir should succeed: " .. tostring(listed.error))
end

local saw_readme = false
for _, entry in ipairs(listed.output.entries) do
    if entry.path == "README.md" then
        saw_readme = true
    end
end

if not saw_readme then
    error("fs list_dir should include README.md")
end

os.remove(path)
os.remove("sandbox/projects/fs_tool_test/main.py")
os.remove("sandbox/projects/fs_tool_test")
os.remove("sandbox/projects")
os.remove("sandbox")

print("test_fs_tool ok")
