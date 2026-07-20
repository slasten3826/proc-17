local owned_temp_root = {}

local helper_path = "./native/tests/proc17_fixture_guard"
local built = false

local function command_ok(command)
    local ok, why, code = os.execute(command)
    return ok == true and (code == nil or code == 0), why, code
end

local function validate_identity(path, device, inode, mount_id)
    if type(path) ~= "string"
        or not path:match("^/tmp/proc17%-repository%-hand%-[A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9]$")
        or type(device) ~= "string" or not device:match("^%d+$")
        or type(inode) ~= "string" or not inode:match("^%d+$")
        or type(mount_id) ~= "string" or not mount_id:match("^%d+$") then
        return nil, "fixture guard returned malformed identity"
    end
    return true
end

function owned_temp_root.ensure_helper()
    if built then
        return true
    end
    local ok, why, code = command_ok("make -C native fixture-helper")
    if not ok then
        return nil, "fixture helper build failed: "
            .. tostring(why) .. ":" .. tostring(code)
    end
    built = true
    return true
end

function owned_temp_root.self_test()
    local ok, err = owned_temp_root.ensure_helper()
    if not ok then
        return nil, err
    end
    local passed, why, code = command_ok(helper_path .. " self-test")
    if not passed then
        return nil, "fixture helper self-test failed: "
            .. tostring(why) .. ":" .. tostring(code)
    end
    return true
end

function owned_temp_root.new()
    local ok, err = owned_temp_root.ensure_helper()
    if not ok then
        return nil, err
    end
    local stream, stream_err = io.popen(helper_path .. " create", "r")
    if not stream then
        return nil, stream_err
    end
    local output = stream:read("*a")
    local closed, why, code = stream:close()
    if closed ~= true or (code ~= nil and code ~= 0) then
        return nil, "fixture helper create failed: "
            .. tostring(why) .. ":" .. tostring(code)
    end
    local path, device, inode, mount_id = output:match(
        "^([^\t\n]+)\t(%d+)\t(%d+)\t(%d+)\n?$"
    )
    local valid, valid_err = validate_identity(path, device, inode, mount_id)
    if not valid then
        return nil, valid_err
    end
    return {
        protocol_version = "repository.test_owned_root.v0",
        path = path,
        device = device,
        inode = inode,
        mount_id = mount_id,
        project_base = path .. "/projects",
        repository = path .. "/projects/repo",
        cleaned = false,
    }
end

local function invoke(root, operation, device, inode, mount_id)
    local valid, err = validate_identity(root.path, device, inode, mount_id)
    if not valid then
        return nil, err
    end
    local command = table.concat({
        helper_path,
        operation,
        root.path,
        device,
        inode,
        mount_id,
    }, " ")
    local ok, why, code = command_ok(command)
    if not ok then
        return nil, "fixture helper " .. operation .. " failed: "
            .. tostring(why) .. ":" .. tostring(code)
    end
    return true
end

function owned_temp_root.probe(root)
    return invoke(root, "probe", root.device, root.inode, root.mount_id)
end

function owned_temp_root.probe_as(root, device, inode, mount_id)
    return invoke(root, "probe", device, inode, mount_id)
end

function owned_temp_root.cleanup(root)
    if root.cleaned then
        return true
    end
    local ok, err = invoke(root, "cleanup",
        root.device, root.inode, root.mount_id)
    if not ok then
        return nil, err
    end
    root.cleaned = true
    return true
end

function owned_temp_root.cleanup_as(root, device, inode, mount_id)
    return invoke(root, "cleanup", device, inode, mount_id)
end

function owned_temp_root.assert_owned_path(root, path)
    if type(path) ~= "string"
        or path:sub(1, #root.path + 1) ~= root.path .. "/" then
        return nil, "path is outside the identity-owned fixture"
    end
    return path
end

function owned_temp_root.with_root(callback)
    local root, root_err = owned_temp_root.new()
    if not root then
        return nil, root_err
    end
    local called, first, second = pcall(callback, root)
    local cleaned, cleanup_err = owned_temp_root.cleanup(root)
    if not cleaned then
        error(cleanup_err, 0)
    end
    if not called then
        error(first, 0)
    end
    return first, second
end

return owned_temp_root
