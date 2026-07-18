local json = require("core.json")
local sandbox = require("core.sandbox")
local packet_core = require("core.packet")

local packet_memory = {}

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

packet_memory.default_root = "sandbox/packets"

local function enabled(options)
    options = options or {}
    if options.enabled ~= nil then
        return options.enabled == true
    end
    if type(options.memory) == "table" and options.memory.enabled ~= nil then
        return options.memory.enabled == true
    end
    return false
end

local function require_enabled(options)
    if enabled(options) then
        return true
    end
    return nil, "packet memory is disabled"
end

local function copy_array(source, start_index)
    local result = {}
    if type(source) ~= "table" then
        return result
    end
    for index = start_index or 1, #source do
        result[#result + 1] = copy_value(source[index])
    end
    return result
end

local function safe_packet_id(packet_id)
    if type(packet_id) ~= "string" or packet_id == "" then
        return nil, "packet id is required"
    end
    if not packet_id:match("^[%w%._%-]+$") then
        return nil, "packet id contains unsafe characters"
    end
    return packet_id
end

local function safe_root(root)
    root = root or packet_memory.default_root
    local ok, reason = sandbox.check_path(root)
    if not ok then
        return nil, reason
    end
    if not sandbox.is_workspace_path(root) then
        return nil, "packet memory root must be under sandbox"
    end
    return root
end

local function memory_path(packet_id, options)
    local id, id_err = safe_packet_id(packet_id)
    if not id then
        return nil, id_err
    end
    local root, root_err = safe_root(options and options.root)
    if not root then
        return nil, root_err
    end
    return root .. "/" .. id .. ".json"
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

local function ensure_dir(path)
    local ok = os.execute("mkdir -p " .. "'" .. tostring(path):gsub("'", "'\\''") .. "'")
    if ok == true or ok == 0 then
        return true
    end
    return nil, "mkdir failed"
end

function packet_memory.capsule(instance, options)
    options = options or {}
    if type(instance) ~= "table" or type(instance.id) ~= "string" then
        return nil, "packet instance required"
    end

    local trace_tail_count = options.trace_tail_count or 8
    if type(trace_tail_count) ~= "number" or trace_tail_count < 0 then
        return nil, "invalid trace_tail_count"
    end
    trace_tail_count = math.floor(trace_tail_count)

    local trace = instance.trace or {}
    local tail_start = #trace - trace_tail_count + 1
    if tail_start < 1 then
        tail_start = 1
    end

    return {
        kind = "packet_memory_capsule",
        protocol_version = instance.protocol_version,
        packet_id = instance.id,
        lineage_id = instance.lineage_id,
        generation = instance.generation,
        parent_id = instance.parent_id,
        parent_corpse_id = instance.parent_corpse_id,
        birth_kind = instance.birth_kind,
        carrier_id = instance.carrier_id,
        substrate_session_id = instance.substrate_session_id,
        flow_mark = copy_value(instance.ingress and instance.ingress.flow_mark),
        status = instance.status,
        terminal = copy_value(instance.terminal),
        death = copy_value(instance.death),
        residue = copy_value(instance.residue or {}),
        manifest = copy_value(instance.manifest),
        trace_tail = copy_array(trace, tail_start),
        loss_records = copy_array(instance.boundary and instance.boundary.loss_records or {}),
        runtime = {
            foundation = copy_value(instance.runtime and instance.runtime.foundation or {}),
        },
        saved_at = os.time(),
        truth_status = "runtime_confirmed",
    }
end

function packet_memory.save(instance, options)
    options = options or {}
    local enabled_ok, enabled_err = require_enabled(options)
    if not enabled_ok then
        return nil, enabled_err
    end
    local capsule, cap_err = packet_memory.capsule(instance, options)
    if not capsule then
        return nil, cap_err
    end

    local path, path_err = memory_path(capsule.packet_id, options)
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
    local write_ok, write_err = write_all(path, json.encode(capsule))
    if not write_ok then
        return nil, write_err
    end
    return capsule, path
end

function packet_memory.load(packet_id, options)
    options = options or {}
    local enabled_ok, enabled_err = require_enabled(options)
    if not enabled_ok then
        return nil, enabled_err
    end
    local path, path_err = memory_path(packet_id, options)
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
    if type(decoded) ~= "table" or decoded.kind ~= "packet_memory_capsule" then
        return nil, "invalid packet memory capsule"
    end
    return decoded
end

function packet_memory.inherit(capsule, options)
    local enabled_ok, enabled_err = require_enabled(options)
    if not enabled_ok then
        return nil, enabled_err
    end
    if type(capsule) ~= "table" or capsule.kind ~= "packet_memory_capsule" then
        return nil, "packet memory capsule required"
    end
    return {
        kind = "inherited_packet_residue",
        source_packet_id = capsule.packet_id,
        source_lineage_id = capsule.lineage_id,
        source_generation = capsule.generation,
        source_parent_corpse_id = capsule.parent_corpse_id,
        source_status = capsule.status,
        source_terminal = copy_value(capsule.terminal),
        source_death = copy_value(capsule.death),
        residue = copy_value(capsule.residue or {}),
        manifest = copy_value(capsule.manifest),
        loss_records = copy_value(capsule.loss_records or {}),
        trace_tail = copy_value(capsule.trace_tail or {}),
        truth_status = "runtime_confirmed",
    }
end

function packet_memory.attach(instance, inherited_residue, options)
    options = options or {}
    local memory_enabled = enabled(options)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "attach memory")
    if not mutable then
        return nil, mutable_err
    end
    if memory_enabled ~= true and not (instance.runtime and instance.runtime.memory and instance.runtime.memory.enabled == true) then
        return nil, "packet memory is disabled"
    end
    if type(inherited_residue) ~= "table" then
        return nil, "inherited residue required"
    end
    instance.runtime = instance.runtime or {}
    instance.runtime.memory = instance.runtime.memory or {}
    instance.runtime.memory.enabled = true
    instance.runtime.memory.inherited_residue = instance.runtime.memory.inherited_residue or {}
    instance.runtime.memory.inherited_residue[#instance.runtime.memory.inherited_residue + 1]
        = copy_value(inherited_residue)
    if instance.revisions then
        instance.revisions.history = (instance.revisions.history or 0) + 1
    end
    return instance
end

return packet_memory
