local owned_temp_root = {}

local helper_path = "./native/tests/proc17_fixture_guard"
local built = false
local prebuilt = false
local self_tested = false

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

local function validate_sentinel(identity)
    if type(identity) ~= "table"
        or identity.protocol_version ~= "qa.test_sentinel_identity.v0"
        or type(identity.path) ~= "string"
        or not identity.path:match(
            "^/tmp/proc17%-qa%-sentinel%-[A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9]$")
        or type(identity.device) ~= "string"
        or not identity.device:match("^%d+$")
        or type(identity.inode) ~= "string"
        or not identity.inode:match("^%d+$")
        or type(identity.mount_id) ~= "string"
        or not identity.mount_id:match("^%d+$")
        or type(identity.size) ~= "string"
        or not identity.size:match("^%d+$")
        or type(identity.sha256) ~= "string"
        or not identity.sha256:match("^[0-9a-f]+$")
        or #identity.sha256 ~= 64 then
        return nil, "fixture guard returned malformed sentinel identity"
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

local function require_helper()
    if prebuilt or built then
        return true
    end
    return owned_temp_root.ensure_helper()
end

local function run_helper_self_test()
    if self_tested then
        return true
    end
    local passed, why, code = command_ok(helper_path .. " self-test")
    if not passed then
        return nil, "fixture helper self-test failed: "
            .. tostring(why) .. ":" .. tostring(code)
    end
    self_tested = true
    return true
end

function owned_temp_root.use_prebuilt_helper()
    local ok, err = run_helper_self_test()
    if not ok then
        return nil, err
    end
    prebuilt = true
    return true
end

function owned_temp_root.create_sentinel()
    local ready, ready_err = require_helper()
    if not ready then return nil, ready_err end
    local stream, stream_err = io.popen(helper_path .. " sentinel-create", "r")
    if not stream then return nil, stream_err end
    local output = stream:read("*a")
    local closed, why, code = stream:close()
    if closed ~= true or (code ~= nil and code ~= 0) then
        return nil, "fixture helper sentinel create failed: "
            .. tostring(why) .. ":" .. tostring(code)
    end
    local path, device, inode, mount_id, size, sha256 = output:match(
        "^([^\t\n]+)\t(%d+)\t(%d+)\t(%d+)\t(%d+)\t([0-9a-f]+)\n?$"
    )
    local identity = {
        protocol_version = "qa.test_sentinel_identity.v0",
        path = path,
        device = device,
        inode = inode,
        mount_id = mount_id,
        size = size,
        sha256 = sha256,
    }
    local valid, valid_err = validate_sentinel(identity)
    if not valid then return nil, valid_err end
    return identity
end

function owned_temp_root.probe_sentinel(identity)
    local valid, valid_err = validate_sentinel(identity)
    if not valid then return nil, valid_err end
    local ok, why, code = command_ok(table.concat({
        helper_path, "sentinel-probe", identity.path, identity.device,
        identity.inode, identity.mount_id, identity.size, identity.sha256,
    }, " "))
    if not ok then
        return nil, "fixture helper sentinel probe failed: "
            .. tostring(why) .. ":" .. tostring(code)
    end
    return true
end

function owned_temp_root.cleanup_sentinel(identity)
    local valid, valid_err = validate_sentinel(identity)
    if not valid then return nil, valid_err end
    local ok, why, code = command_ok(table.concat({
        helper_path, "sentinel-cleanup", identity.path, identity.device,
        identity.inode, identity.mount_id,
    }, " "))
    if not ok then
        return nil, "fixture helper sentinel cleanup failed: "
            .. tostring(why) .. ":" .. tostring(code)
    end
    return true
end

function owned_temp_root.self_test()
    local ok, err = owned_temp_root.ensure_helper()
    if not ok then
        return nil, err
    end
    return run_helper_self_test()
end

function owned_temp_root.new()
    local ok, err = require_helper()
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

function owned_temp_root.identity(root)
    if type(root) ~= "table" then
        return nil, "fixture root must be a table"
    end
    local valid, valid_err = validate_identity(
        root.path, root.device, root.inode, root.mount_id)
    if not valid then
        return nil, valid_err
    end
    return {
        protocol_version = "repository.test_owned_root_identity.v0",
        path = root.path,
        device = root.device,
        inode = root.inode,
        mount_id = root.mount_id,
    }
end

local function validate_detached_identity(identity)
    if type(identity) ~= "table"
        or identity.protocol_version
            ~= "repository.test_owned_root_identity.v0" then
        return nil, "fixture identity protocol mismatch"
    end
    local allowed = {
        protocol_version = true,
        path = true,
        device = true,
        inode = true,
        mount_id = true,
    }
    for key in pairs(identity) do
        if not allowed[key] then
            return nil, "fixture identity contains undeclared field"
        end
    end
    return validate_identity(identity.path, identity.device,
        identity.inode, identity.mount_id)
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

function owned_temp_root.absent(prior_identity)
    local ready, ready_err = require_helper()
    if not ready then
        return nil, ready_err
    end
    local valid, valid_err = validate_detached_identity(prior_identity)
    if not valid then
        return nil, valid_err
    end
    local command = table.concat({
        helper_path,
        "absent",
        prior_identity.path,
        prior_identity.device,
        prior_identity.inode,
        prior_identity.mount_id,
    }, " ")
    local ok, why, code = command_ok(command)
    if not ok then
        return nil, "fixture helper absence check failed: "
            .. tostring(why) .. ":" .. tostring(code)
    end
    return true
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

function owned_temp_root.with_root_phases(body_callback, after_cleanup_callback)
    if type(body_callback) ~= "function"
        or type(after_cleanup_callback) ~= "function" then
        return nil, "fixture phase callbacks must be functions"
    end
    local root, root_err = owned_temp_root.new()
    if not root then
        return nil, root_err
    end
    local prior_identity = assert(owned_temp_root.identity(root))
    local body_called, body_first, body_second = pcall(body_callback, root)
    local cleaned, cleanup_err = owned_temp_root.cleanup(root)
    root = nil
    local after_called, after_first, after_second = pcall(
        after_cleanup_callback, prior_identity)
    if not cleaned then
        error(cleanup_err, 0)
    end
    if not body_called then
        error(body_first, 0)
    end
    if not after_called then
        error(after_first, 0)
    end
    return body_first, body_second, after_first, after_second
end

return owned_temp_root
