local digest = require("core.digest")
local json = require("core.json")
local repository_intent = require("runtime.repository_intent")

local inventory = {
    protocol = "repository.seal_inventory.v0",
    default_bounds = {
        protocol_version = "repository.inventory_bounds.v0",
        max_entries = 256,
        max_depth = 64,
        max_path_bytes = 1024,
        max_component_bytes = 255,
        max_file_bytes = 1048576,
        max_total_bytes = 8388608,
    },
}

local bounds_keys = {
    protocol_version = true, max_entries = true, max_depth = true,
    max_path_bytes = true, max_component_bytes = true,
    max_file_bytes = true, max_total_bytes = true,
}
local result_keys = {
    protocol_version = true, operation = true, outcome = true,
    root_before = true, root_after = true, stable = true, entries = true,
    bounds_observed = true, mutation_primitive_entered = true,
    published = true, cost = true,
}
local entry_keys = {
    relative_path = true, kind = true, identity_before = true,
    identity_after = true, bytes = true, content = true,
}
local entry_required = {
    relative_path = true, kind = true, identity_before = true,
    identity_after = true,
}
local observed_bounds_keys = {
    max_entries = true, max_depth = true, max_path_bytes = true,
    max_component_bytes = true, max_file_bytes = true,
    max_total_bytes = true, observed_entries = true,
    observed_total_bytes = true,
}
local identity_keys = {device = true, inode = true}
local cost_keys = {tool_calls = true, file_writes = true, time_ms = true}

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

local function exact_keys(value, allowed, required, name)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, name .. " must be a plain table"
    end
    for key in pairs(value) do
        if not allowed[key] then
            return nil, name .. " contains unknown key: " .. tostring(key)
        end
    end
    for key in pairs(required or allowed) do
        if value[key] == nil then
            return nil, name .. " is missing key: " .. key
        end
    end
    return true
end

local function non_empty(value)
    return type(value) == "string" and value ~= ""
end

local function positive_integer(value)
    return type(value) == "number" and value >= 1 and value == math.floor(value)
end

local function non_negative_integer(value)
    return type(value) == "number" and value >= 0 and value == math.floor(value)
end

local function non_negative_number(value)
    return type(value) == "number" and value >= 0
        and value == value and value < math.huge
end

local function strict_array(value, name)
    if type(value) ~= "table" or getmetatable(value) ~= nil then
        return nil, name .. " must be an array"
    end
    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then
            return nil, name .. " must be an array"
        end
        count = count + 1
    end
    if count ~= #value then
        return nil, name .. " must be a dense array"
    end
    return true
end

local function sorted_unique(values)
    local result, seen = {}, {}
    for _, value in ipairs(values or {}) do
        if non_empty(value) and not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    table.sort(result)
    return result
end

local function same(left, right)
    return json.encode(left) == json.encode(right)
end

local function validate_identity(value, name)
    local ok, err = exact_keys(value, identity_keys, identity_keys, name)
    if not ok then
        return nil, err
    end
    if not non_negative_integer(value.device)
        or not non_negative_integer(value.inode) then
        return nil, name .. " is invalid"
    end
    return true
end

local function identity_ref(value)
    local value_digest, value_err = digest.record(value)
    if not value_digest then
        return nil, value_err
    end
    return "filesystem-identity:" .. value_digest
end

local function path_shape(path)
    local depth, component_max = 0, 0
    for component in path:gmatch("[^/]+") do
        depth = depth + 1
        component_max = math.max(component_max, #component)
    end
    return depth, component_max
end

function inventory.normalize_bounds(value)
    value = value or inventory.default_bounds
    local ok, err = exact_keys(value, bounds_keys, bounds_keys,
        "repository inventory bounds")
    if not ok then
        return nil, err
    end
    if value.protocol_version ~= "repository.inventory_bounds.v0" then
        return nil, "unsupported repository inventory bounds"
    end
    for _, key in ipairs({
        "max_entries", "max_depth", "max_path_bytes", "max_component_bytes",
        "max_file_bytes", "max_total_bytes",
    }) do
        if not positive_integer(value[key]) then
            return nil, "repository inventory bound is invalid: " .. key
        end
    end
    if value.max_entries > 4096 or value.max_depth > 64
        or value.max_path_bytes > 1024 or value.max_component_bytes > 255
        or value.max_file_bytes > 1048576 or value.max_total_bytes > 67108864 then
        return nil, "repository inventory bounds exceed trusted ceiling"
    end
    return copy_value(value)
end

function inventory.normalize_provider_result(raw, coordinates)
    local coordinate_ok, coordinate_err = exact_keys(coordinates, {
        request_id = true,
        root_fingerprint = true,
        inventory_bounds = true,
        root_continuity = true,
    }, nil, "repository inventory coordinates")
    if not coordinate_ok then
        return nil, coordinate_err, "malformed"
    end
    local bounds, bounds_err = inventory.normalize_bounds(
        coordinates.inventory_bounds)
    if not bounds then
        return nil, bounds_err, "malformed"
    end
    if not non_empty(coordinates.request_id)
        or not non_empty(coordinates.root_fingerprint)
        or coordinates.root_continuity ~= "proven" then
        return nil, "repository inventory coordinates are invalid", "malformed"
    end
    local raw_ok, raw_err = exact_keys(raw, result_keys, result_keys,
        "repository provider inventory")
    if not raw_ok then
        return nil, raw_err, "malformed"
    end
    if raw.protocol_version ~= "repository.provider_inventory_result.v0"
        or raw.operation ~= "inventory_tree"
        or (raw.outcome ~= "observed" and raw.outcome ~= "bound_exceeded")
        or type(raw.stable) ~= "boolean"
        or raw.mutation_primitive_entered ~= false
        or raw.published ~= false then
        return nil, "repository provider inventory envelope is contradictory",
            "malformed"
    end
    local before_ok, before_err = validate_identity(raw.root_before,
        "inventory root_before")
    if not before_ok then
        return nil, before_err, "malformed"
    end
    local after_ok, after_err = validate_identity(raw.root_after,
        "inventory root_after")
    if not after_ok then
        return nil, after_err, "malformed"
    end
    local cost_ok, cost_err = exact_keys(raw.cost, cost_keys, cost_keys,
        "repository inventory cost")
    if not cost_ok then
        return nil, cost_err, "malformed"
    end
    if raw.cost.tool_calls ~= 1 or raw.cost.file_writes ~= 0
        or not non_negative_number(raw.cost.time_ms) then
        return nil, "repository inventory economics are impossible", "malformed"
    end
    local observed_ok, observed_err = exact_keys(raw.bounds_observed,
        observed_bounds_keys, observed_bounds_keys, "repository observed bounds")
    if not observed_ok then
        return nil, observed_err, "malformed"
    end
    for key in pairs(bounds_keys) do
        if key ~= "protocol_version" and raw.bounds_observed[key] ~= bounds[key] then
            return nil, "repository provider changed inventory bound: " .. key,
                "malformed"
        end
    end
    if not non_negative_integer(raw.bounds_observed.observed_entries)
        or not non_negative_integer(raw.bounds_observed.observed_total_bytes) then
        return nil, "repository observed bounds contain invalid counts", "malformed"
    end
    local array_ok, array_err = strict_array(raw.entries,
        "repository provider inventory entries")
    if not array_ok then
        return nil, array_err, "malformed"
    end

    local entries, seen = {}, {}
    local total_bytes = 0
    local previous_path
    local stable = raw.stable and same(raw.root_before, raw.root_after)
    for index, entry in ipairs(raw.entries) do
        local entry_ok, entry_err = exact_keys(entry, entry_keys,
            entry_required, "repository provider inventory entry")
        if not entry_ok then
            return nil, entry_err, "malformed"
        end
        local path, path_err = repository_intent.validate_relative_path(
            entry.relative_path)
        if not path then
            return nil, path_err, "malformed"
        end
        if seen[path] or (previous_path and path <= previous_path) then
            return nil, "repository provider inventory order is not canonical",
                "malformed"
        end
        seen[path], previous_path = true, path
        if entry.kind ~= "directory" and entry.kind ~= "regular_file"
            and entry.kind ~= "symlink" and entry.kind ~= "special" then
            return nil, "repository provider inventory kind is invalid", "malformed"
        end
        local first_ok, first_err = validate_identity(entry.identity_before,
            "inventory entry identity_before")
        if not first_ok then
            return nil, first_err, "malformed"
        end
        local last_ok, last_err = validate_identity(entry.identity_after,
            "inventory entry identity_after")
        if not last_ok then
            return nil, last_err, "malformed"
        end
        stable = stable and same(entry.identity_before, entry.identity_after)
        local depth, component_max = path_shape(path)
        if index > bounds.max_entries or depth > bounds.max_depth
            or #path > bounds.max_path_bytes
            or component_max > bounds.max_component_bytes then
            return nil, "repository provider exceeded path inventory bounds",
                "malformed"
        end
        local bytes, sha256
        if entry.kind == "regular_file" then
            if not non_negative_integer(entry.bytes)
                or type(entry.content) ~= "string"
                or #entry.content ~= entry.bytes
                or entry.bytes > bounds.max_file_bytes then
                return nil, "repository provider returned invalid bounded file",
                    "malformed"
            end
            total_bytes = total_bytes + entry.bytes
            if total_bytes > bounds.max_total_bytes then
                return nil, "repository provider exceeded aggregate byte bound",
                    "malformed"
            end
            sha256 = digest.sha256(entry.content)
            if not sha256 then
                return nil, "repository file digest failed", "malformed"
            end
            bytes = entry.bytes
        elseif entry.bytes ~= nil or entry.content ~= nil then
            return nil, "repository non-file entry exposed content", "malformed"
        end
        local stable_ref, stable_ref_err = identity_ref({
            before = entry.identity_before,
            after = entry.identity_after,
        })
        if not stable_ref then
            return nil, stable_ref_err, "malformed"
        end
        entries[#entries + 1] = {
            relative_path = path,
            kind = entry.kind,
            bytes = bytes,
            sha256 = sha256,
            stable_identity_ref = stable_ref,
        }
    end
    if raw.bounds_observed.observed_entries ~= #entries
        or raw.bounds_observed.observed_total_bytes ~= total_bytes then
        return nil, "repository provider observed bounds disagree with entries",
            "malformed"
    end
    local before_ref = assert(identity_ref(raw.root_before))
    local after_ref = assert(identity_ref(raw.root_after))
    local base = {
        root_before_ref = before_ref,
        root_after_ref = after_ref,
        provider_cost = copy_value(raw.cost),
    }
    if not stable then
        base.status = "unstable"
        return base
    end
    if raw.outcome == "bound_exceeded" then
        base.status = "bound_exceeded"
        return base
    end

    local seed = {
        request_id = coordinates.request_id,
        root_fingerprint = coordinates.root_fingerprint,
        inventory_bounds = bounds,
        entries = entries,
        observed_entry_count = #entries,
        observed_total_bytes = total_bytes,
    }
    local inventory_digest, inventory_digest_err = digest.record(seed)
    if not inventory_digest then
        return nil, inventory_digest_err, "malformed"
    end
    local normalized = {
        protocol_version = inventory.protocol,
        inventory_id = nil,
        request_id = coordinates.request_id,
        root_fingerprint = coordinates.root_fingerprint,
        root_continuity = "proven",
        inventory_bounds = bounds,
        entries = entries,
        observed_entry_count = #entries,
        observed_total_bytes = total_bytes,
        inventory_digest = inventory_digest,
        source_refs = sorted_unique({coordinates.request_id, before_ref, after_ref}),
        event_truth_status = "runtime_confirmed",
    }
    local inventory_id, inventory_id_err = digest.record(normalized)
    if not inventory_id then
        return nil, inventory_id_err, "malformed"
    end
    normalized.inventory_id = "repository-seal-inventory:" .. inventory_id
    base.status = "observed"
    base.inventory = normalized
    return base
end

function inventory.same(left, right)
    return same(left, right)
end

return inventory
