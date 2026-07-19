local json = require("core.json")
local sandbox = require("core.sandbox")
local grave = require("runtime.grave")

local session_memory = {}

local function copy_value(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

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

local function safe_lineage_id(id)
    if type(id) ~= "string" or id == "" then
        return nil, "lineage id is required"
    end
    if not id:match("^[%w%._:%-]+$") then
        return nil, "lineage id contains unsafe characters"
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

local function empty_compost()
    return {
        next_insert_id = 1,
        patterns = {},
    }
end

local function ensure_grave(session)
    session.grave = session.grave or empty_grave()
    session.grave.warnings = session.grave.warnings or {}
    session.grave.bequests = session.grave.bequests or {}
    session.grave.neutral = session.grave.neutral or {}
    return session.grave
end

local function ensure_compost(session)
    session.compost = session.compost or empty_compost()
    session.compost.patterns = session.compost.patterns or {}
    if type(session.compost.next_insert_id) ~= "number" or session.compost.next_insert_id < 1 then
        session.compost.next_insert_id = 1
    end
    return session.compost
end

local function ensure_session_storage(session)
    ensure_grave(session)
    ensure_compost(session)
    session.lineage_ids = session.lineage_ids or {}
    session.lineage_ledger = session.lineage_ledger or {}
    return session
end

local function copy_into(target, source)
    for _, item in ipairs(source or {}) do
        target[#target + 1] = item
    end
end

local function fresh_grave_count(session)
    local session_grave = ensure_grave(session)
    return #(session_grave.warnings or {})
        + #(session_grave.bequests or {})
        + #(session_grave.neutral or {})
end

local function pattern_last_operator(record)
    local warning = record.warning or {}
    local pattern = warning.pattern or {}
    local residue = record.residue or {}
    local death = record.death or {}
    if record.grave_kind == "warning" then
        return pattern.last_operator or residue.last_operator or death.last_operator or "unknown"
    end
    return residue.last_operator or death.last_operator or "unknown"
end

local function pattern_do_not_repeat(record)
    if record.grave_kind ~= "warning" then
        return nil
    end
    local warning = record.warning or {}
    local pattern = warning.pattern or {}
    local residue = record.residue or {}
    return warning.do_not_repeat or pattern.do_not_repeat or residue.do_not_repeat
end

local function pattern_key(parts)
    return table.concat({
        parts.grave_kind or "",
        parts.death_cause or "",
        parts.last_operator or "",
        parts.do_not_repeat or "",
    }, "|")
end

local function compost_parts(record)
    local parts = {
        grave_kind = record.grave_kind,
        death_cause = record.death_cause,
        last_operator = pattern_last_operator(record),
        do_not_repeat = pattern_do_not_repeat(record),
    }
    parts.key = pattern_key(parts)
    return parts
end

local function find_pattern(patterns, key)
    for _, pattern in ipairs(patterns or {}) do
        if pattern.key == key then
            return pattern
        end
    end
    return nil
end

local function merge_pattern(session, record, now)
    local compost = ensure_compost(session)
    local parts = compost_parts(record)
    local existing = find_pattern(compost.patterns, parts.key)
    if existing then
        existing.count = (existing.count or 0) + 1
        existing.last_seen_at = now
        return existing
    end

    local created = {
        kind = "compost_pattern",
        key = parts.key,
        grave_kind = parts.grave_kind,
        death_cause = parts.death_cause,
        last_operator = parts.last_operator,
        do_not_repeat = parts.do_not_repeat,
        count = 1,
        first_seen_at = now,
        last_seen_at = now,
    }
    compost.patterns[#compost.patterns + 1] = created
    return created
end

local function collect_fresh_graves(session)
    local session_grave = ensure_grave(session)
    local out = {}
    local groups = {
        {key = "warnings", values = session_grave.warnings},
        {key = "bequests", values = session_grave.bequests},
        {key = "neutral", values = session_grave.neutral},
    }
    for _, group in ipairs(groups) do
        for index, record in ipairs(group.values or {}) do
            out[#out + 1] = {
                group = group.key,
                index = index,
                record = record,
                insert_id = type(record.grave_insert_id) == "number" and record.grave_insert_id or 0,
            }
        end
    end
    table.sort(out, function(left, right)
        if left.insert_id == right.insert_id then
            return left.index < right.index
        end
        return left.insert_id < right.insert_id
    end)
    return out
end

local function remove_candidates(session, candidates)
    local session_grave = ensure_grave(session)
    table.sort(candidates, function(left, right)
        if left.group == right.group then
            return left.index > right.index
        end
        return left.group < right.group
    end)
    for _, candidate in ipairs(candidates) do
        table.remove(session_grave[candidate.group], candidate.index)
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
        lineage_ids = {},
        current_lineage_id = nil,
        lineage_ledger = {},
        residue_policy = options.residue_policy or "last_packet",
        grave = empty_grave(),
        compost = empty_compost(),
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
    ensure_session_storage(session)
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
    ensure_session_storage(decoded)
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
    ensure_session_storage(session)
    return session
end

function session_memory.append_lineage(session, lineage_id)
    if type(session) ~= "table" or session.kind ~= "proc17_session" then
        return nil, "session required"
    end
    local id, id_err = safe_lineage_id(lineage_id)
    if not id then
        return nil, id_err
    end
    ensure_session_storage(session)
    for _, existing in ipairs(session.lineage_ids) do
        if existing == id then
            session.current_lineage_id = id
            return session
        end
    end
    session.lineage_ids[#session.lineage_ids + 1] = id
    session.current_lineage_id = id
    session.updated_at = os.time()
    return session
end

function session_memory.append_lineage_event(session, event)
    if type(session) ~= "table" or session.kind ~= "proc17_session" then
        return nil, "session required"
    end
    if type(event) ~= "table" or type(event.id) ~= "string"
        or type(event.lineage_id) ~= "string"
        or event.event_truth_status ~= "runtime_confirmed" then
        return nil, "valid lineage event required"
    end
    local id, id_err = safe_lineage_id(event.lineage_id)
    if not id then
        return nil, id_err
    end
    ensure_session_storage(session)
    if session.current_lineage_id ~= id then
        return nil, "lineage event does not belong to current session lineage"
    end
    for _, existing in ipairs(session.lineage_ledger) do
        if existing.lineage_id == id and existing.id == event.id then
            return session
        end
    end
    session.lineage_ledger[#session.lineage_ledger + 1] = copy_value(event)
    session.updated_at = os.time()
    return session
end

function session_memory.add_grave(session, input)
    if type(session) ~= "table" or session.kind ~= "proc17_session" then
        return nil, "session required"
    end
    local record = copy_value(input)
    if not (type(record) == "table" and record.kind == "grave") then
        local classified, classify_err = grave.classify(input)
        if not classified then
            return nil, classify_err
        end
        record = classified
    end

    local session_grave = ensure_grave(session)
    local compost = ensure_compost(session)
    record.grave_insert_id = compost.next_insert_id
    compost.next_insert_id = compost.next_insert_id + 1

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
    return copy_value(record)
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
    return copy_value(out)
end

function session_memory.compost(session, options)
    options = options or {}
    if type(session) ~= "table" or session.kind ~= "proc17_session" then
        return nil, "session required"
    end
    local max_fresh = options.max_fresh_graves
    if max_fresh == nil then
        max_fresh = 8
    end
    if type(max_fresh) ~= "number" or max_fresh < 0 then
        return nil, "max_fresh_graves must be number >= 0"
    end
    max_fresh = math.floor(max_fresh)

    ensure_session_storage(session)
    local now = options.now or os.time()
    local before = fresh_grave_count(session)
    local payload = {
        kind = "session_compost_payload",
        composted_count = 0,
        fresh_grave_count_before = before,
        fresh_grave_count_after = before,
        pattern_count = #(session.compost.patterns or {}),
        truth_status = "runtime_confirmed",
    }

    if before <= max_fresh then
        return payload
    end

    local candidates = collect_fresh_graves(session)
    local to_compost = {}
    local excess = before - max_fresh
    for index = 1, excess do
        local candidate = candidates[index]
        if candidate then
            to_compost[#to_compost + 1] = candidate
            merge_pattern(session, candidate.record, now)
        end
    end

    remove_candidates(session, to_compost)
    session.updated_at = now

    payload.composted_count = #to_compost
    payload.fresh_grave_count_after = fresh_grave_count(session)
    payload.pattern_count = #(session.compost.patterns or {})
    return payload
end

return session_memory
