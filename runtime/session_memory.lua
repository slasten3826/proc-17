local json = require("core.json")
local sandbox = require("core.sandbox")
local grave = require("runtime.grave")

local session_memory = {}

session_memory.default_root = "sandbox/sessions"
session_memory.protocol_version = "session.v0"

local function safe_id(id)
    if type(id) ~= "string" or id == "" then
        return nil, "session id is required"
    end
    if not id:match("^[%w%._%-]+$") then
        return nil, "session id contains unsafe characters"
    end
    return id
end

local function safe_packet_id(id)
    if type(id) ~= "string" or id == "" then
        return nil, "packet id is required"
    end
    if not id:match("^[%w%._%-]+$") then
        return nil, "packet id contains unsafe characters"
    end
    return id
end

local function safe_root(root)
    root = root or session_memory.default_root
    local ok, reason = sandbox.check_path(root)
    if not ok then
        return nil, reason
    end
    if not sandbox.is_workspace_path(root) then
        return nil, "session memory root must be under sandbox"
    end
    return root
end

local function ensure_dir(path)
    local ok = os.execute("mkdir -p " .. "'" .. tostring(path):gsub("'", "'\\''") .. "'")
    if ok == true or ok == 0 then
        return true
    end
    return nil, "mkdir failed"
end

local function write_all(path, content)
    local file, err = io.open(path, "w")
    if not file then
        return nil, err
    end
    file:write(content or "")
    file:close()
    return true
end

local function read_all(path)
    local file, err = io.open(path, "r")
    if not file then
        return nil, err
    end
    local content = file:read("*a")
    file:close()
    return content
end

local function session_path(session_id, options)
    local id, id_err = safe_id(session_id)
    if not id then
        return nil, id_err
    end
    local root, root_err = safe_root(options and options.root)
    if not root then
        return nil, root_err
    end
    return root .. "/" .. id .. ".json"
end

local function empty_grave()
    return {
        warnings = {},
        bequests = {},
        neutral = {},
    }
end

local function ensure_grave(session)
    session.grave = session.grave or empty_grave()
    session.grave.warnings = session.grave.warnings or {}
    session.grave.bequests = session.grave.bequests or {}
    session.grave.neutral = session.grave.neutral or {}
    return session.grave
end

local function copy_into(target, source)
    for _, item in ipairs(source or {}) do
        target[#target + 1] = item
    end
end

function session_memory.new_id()
    return string.format("session-%d-%04d", os.time(), math.random(0, 9999))
end

function session_memory.create(session_id, options)
    options = options or {}
    local id = session_id or session_memory.new_id()
    local safe, safe_err = safe_id(id)
    if not safe then
        return nil, safe_err
    end

    local now = os.time()
    return {
        kind = "proc17_session",
        protocol_version = session_memory.protocol_version,
        session_id = safe,
        label = options.label,
        created_at = now,
        updated_at = now,
        packet_ids = {},
        current_packet_id = nil,
        residue_policy = options.residue_policy or "last_packet",
        grave = empty_grave(),
    }
end

function session_memory.save(session, options)
    options = options or {}
    if type(session) ~= "table" or session.kind ~= "proc17_session" then
        return nil, "session required"
    end
    local path, path_err = session_path(session.session_id, options)
    if not path then
        return nil, path_err
    end
    local root, root_err = safe_root(options.root)
    if not root then
        return nil, root_err
    end
    local dir_ok, dir_err = ensure_dir(root)
    if not dir_ok then
        return nil, dir_err
    end
    ensure_grave(session)
    session.updated_at = os.time()
    local write_ok, write_err = write_all(path, json.encode(session))
    if not write_ok then
        return nil, write_err
    end
    return session, path
end

function session_memory.load(session_id, options)
    options = options or {}
    local path, path_err = session_path(session_id, options)
    if not path then
        return nil, path_err
    end
    local content, read_err = read_all(path)
    if not content then
        return nil, read_err
    end
    local ok, decoded = pcall(json.decode, content)
    if not ok then
        return nil, tostring(decoded)
    end
    if type(decoded) ~= "table" or decoded.kind ~= "proc17_session" then
        return nil, "invalid session file"
    end
    ensure_grave(decoded)
    return decoded
end

function session_memory.append_packet(session, packet_id)
    if type(session) ~= "table" or session.kind ~= "proc17_session" then
        return nil, "session required"
    end
    local id, id_err = safe_packet_id(packet_id)
    if not id then
        return nil, id_err
    end
    session.packet_ids = session.packet_ids or {}
    session.packet_ids[#session.packet_ids + 1] = id
    session.current_packet_id = id
    session.updated_at = os.time()
    ensure_grave(session)
    return session
end

function session_memory.add_grave(session, input)
    if type(session) ~= "table" or session.kind ~= "proc17_session" then
        return nil, "session required"
    end
    local record = input
    if not (type(record) == "table" and record.kind == "grave") then
        local classified, classify_err = grave.classify(input)
        if not classified then
            return nil, classify_err
        end
        record = classified
    end

    local session_grave = ensure_grave(session)
    if record.grave_kind == "warning" then
        session_grave.warnings[#session_grave.warnings + 1] = record
    elseif record.grave_kind == "bequest" then
        session_grave.bequests[#session_grave.bequests + 1] = record
    elseif record.grave_kind == "neutral" then
        session_grave.neutral[#session_grave.neutral + 1] = record
    else
        return nil, "unknown grave kind: " .. tostring(record.grave_kind)
    end
    session.updated_at = os.time()
    return record
end

function session_memory.inherit_graves(session, options)
    options = options or {}
    if options.enabled ~= true then
        return nil, "session grave inheritance is disabled"
    end
    if type(session) ~= "table" or session.kind ~= "proc17_session" then
        return nil, "session required"
    end
    local session_grave = ensure_grave(session)
    local out = {}
    copy_into(out, session_grave.warnings)
    copy_into(out, session_grave.bequests)
    copy_into(out, session_grave.neutral)
    return out
end

return session_memory
