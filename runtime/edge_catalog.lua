local topology = require("core.topology")
local digest = require("core.digest")
local json = require("core.json")

local edge_catalog = {
    protocol_version = "edge-catalog.v0",
    surface_protocol = "operator-tree.authority-surface.v0",
}

local canonical_index = {}
for index, glyph in ipairs(topology.order) do
    canonical_index[glyph] = index
end

function edge_catalog.edge(left, right)
    left = topology.resolve(left)
    right = topology.resolve(right)
    if not left or not right then
        return nil
    end
    if canonical_index[left] <= canonical_index[right] then
        return left .. "-" .. right
    end
    return right .. "-" .. left
end

local function both(left, right)
    return {left .. "->" .. right, right .. "->" .. left}
end

local definitions = {
    {id = "E01", left = "▽", right = "☰", directions = {"▽->☰"}, witness = "multi-unit ingress produces raw relations"},
    {id = "E02", left = "▽", right = "☷", directions = {"▽->☷"}, witness = "inherited rigid carrier form releases residue"},
    {id = "E03", left = "▽", right = "☴", directions = {"▽->☴"}, witness = "raw ingress reaches upper observation"},
    {id = "E04", left = "☰", right = "☷", directions = both("☰", "☷"), witness = "false relation dissolves and surviving units reconnect"},
    {id = "E05", left = "☰", right = "☴", directions = both("☰", "☴"), witness = "relation snapshot and newly observed endpoints cross"},
    {id = "E06", left = "☰", right = "☵", directions = both("☰", "☵"), witness = "motif encodes and remapped units reconnect"},
    {id = "E07", left = "☷", right = "☴", directions = both("☷", "☴"), witness = "dissolution consequence and rigidity observation cross"},
    {id = "E08", left = "☷", right = "☳", directions = both("☷", "☳"), witness = "released alternatives choose and choice residue dissolves"},
    {id = "E09", left = "☴", right = "☵", directions = both("☴", "☵"), witness = "observed proposal encodes and changed form earns eye debt"},
    {id = "E10", left = "☴", right = "☳", directions = both("☴", "☳"), witness = "observed alternatives collapse and consequences return to sight"},
    {id = "E11", left = "☴", right = "☱", directions = both("☴", "☱"), witness = "semantic and runtime mismatch crosses both eyes"},
    {id = "E12", left = "☵", right = "☱", directions = both("☵", "☱"), witness = "encoded form installs and runtime mismatch requests recode"},
    {id = "E13", left = "☵", right = "☳", directions = both("☵", "☳"), witness = "encoded alternatives choose and selected path re-encodes"},
    {id = "E14", left = "☵", right = "☲", directions = both("☵", "☲"), witness = "repeatable encode transform cycles under body condition"},
    {id = "E15", left = "☳", right = "☱", directions = both("☳", "☱"), witness = "commitment installs and runtime exposes another branch"},
    {id = "E16", left = "☳", right = "☶", directions = both("☳", "☶"), witness = "selected path validates and admissible set requires choice"},
    {id = "E17", left = "☱", right = "☶", directions = both("☱", "☶"), witness = "runtime evidence request and verdict return cross"},
    {id = "E18", left = "☱", right = "☲", directions = both("☱", "☲"), witness = "bounded recurrence returns to progress accounting"},
    {id = "E19", left = "☲", right = "☶", directions = both("☲", "☶"), witness = "iterative result validates and rule requests rerun"},
    {id = "E20", left = "☱", right = "△", directions = {"☱->△"}, witness = "runtime completion or near-death manifests"},
    {id = "E21", left = "☲", right = "△", directions = {"☲->△"}, witness = "runtime-confirmed recurrence terminal condition manifests"},
    {id = "E22", left = "☶", right = "△", directions = {"☶->△"}, witness = "fresh accepted evidence manifests directly"},
}

local one_way_directions = {
    E01 = "▽->☰",
    E02 = "▽->☷",
    E03 = "▽->☴",
    E20 = "☱->△",
    E21 = "☲->△",
    E22 = "☶->△",
}

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

local function sorted_unique(values)
    local seen = {}
    local result = {}
    for _, value in ipairs(values or {}) do
        if type(value) ~= "string" or value == "" or seen[value] then
            return nil
        end
        seen[value] = true
        result[#result + 1] = value
    end
    table.sort(result)
    return result
end

local function surface_error()
    return {
        class = "instrument_contract",
        code = "authority_surface_mismatch",
        stage = "authority_epoch",
    }
end

local function exact_keys(value, allowed)
    if type(value) ~= "table" then
        return false
    end
    for key in pairs(value) do
        if not allowed[key] then
            return false
        end
    end
    for key in pairs(allowed) do
        if value[key] == nil then
            return false
        end
    end
    return true
end

local function surface_seed(surface)
    return {
        kind = surface.kind,
        protocol_version = surface.protocol_version,
        topology_version = surface.topology_version,
        catalog_version = surface.catalog_version,
        edges = copy_value(surface.edges),
        edge_count = surface.edge_count,
        legal_direction_count = surface.legal_direction_count,
    }
end

local function build_surface()
    local edges = {}
    local seen_ids = {}
    local seen_pairs = {}
    local seen_directions = {}
    local legal_direction_count = 0

    for index, definition in ipairs(definitions) do
        local left = topology.resolve(definition.left)
        local right = topology.resolve(definition.right)
        local pair = edge_catalog.edge(definition.left, definition.right)
        local directions = sorted_unique(definition.directions)
        if not left or not right
            or left ~= definition.left or right ~= definition.right
            or not topology.is_adjacent(left, right)
            or not topology.is_adjacent(right, left)
            or pair ~= definition.edge
            or seen_ids[definition.id]
            or seen_pairs[pair]
            or not directions
        then
            return nil, surface_error()
        end

        local expected_one_way = one_way_directions[definition.id]
        if expected_one_way then
            if #directions ~= 1 or directions[1] ~= expected_one_way then
                return nil, surface_error()
            end
        else
            local expected = sorted_unique(both(left, right))
            if json.encode(directions) ~= json.encode(expected) then
                return nil, surface_error()
            end
        end

        for _, direction in ipairs(directions) do
            if direction ~= left .. "->" .. right
                and direction ~= right .. "->" .. left
            then
                return nil, surface_error()
            end
            if seen_directions[direction] then
                return nil, surface_error()
            end
            seen_directions[direction] = true
            legal_direction_count = legal_direction_count + 1
        end

        seen_ids[definition.id] = true
        seen_pairs[pair] = true
        edges[index] = {
            edge_id = definition.id,
            left = left,
            right = right,
            legal_directions = directions,
        }
    end

    if #edges ~= 22 or legal_direction_count ~= 38 then
        return nil, surface_error()
    end

    local surface = {
        kind = "operator_tree_authority_surface",
        protocol_version = edge_catalog.surface_protocol,
        topology_version = topology.version,
        catalog_version = edge_catalog.protocol_version,
        edges = edges,
        edge_count = #edges,
        legal_direction_count = legal_direction_count,
        event_truth_status = "runtime_confirmed",
    }
    local record_digest, digest_err = digest.record(surface_seed(surface))
    if not record_digest then
        return nil, digest_err
    end
    surface.surface_id = "sha256:" .. record_digest
    return surface
end

local by_id = {}
local by_edge = {}
for _, definition in ipairs(definitions) do
    definition.edge = edge_catalog.edge(definition.left, definition.right)
    by_id[definition.id] = definition
    by_edge[definition.edge] = definition
end

function edge_catalog.list()
    local result = {}
    for index, definition in ipairs(definitions) do
        result[index] = copy_value(definition)
    end
    return result
end

function edge_catalog.get(value, right)
    if right ~= nil then
        return copy_value(by_edge[edge_catalog.edge(value, right)])
    end
    return copy_value(by_id[value] or by_edge[value])
end

function edge_catalog.authority_surface()
    local surface, err = build_surface()
    if not surface then
        return nil, err
    end
    return copy_value(surface)
end

function edge_catalog.verify_authority_surface(surface)
    if not exact_keys(surface, {
        kind = true,
        protocol_version = true,
        topology_version = true,
        catalog_version = true,
        edges = true,
        edge_count = true,
        legal_direction_count = true,
        surface_id = true,
        event_truth_status = true,
    }) or surface.kind ~= "operator_tree_authority_surface"
        or surface.protocol_version ~= edge_catalog.surface_protocol
        or surface.topology_version ~= topology.version
        or surface.catalog_version ~= edge_catalog.protocol_version
        or surface.event_truth_status ~= "runtime_confirmed"
        or type(surface.edges) ~= "table"
        or type(surface.edge_count) ~= "number"
        or type(surface.legal_direction_count) ~= "number"
        or type(surface.surface_id) ~= "string"
    then
        return nil, surface_error()
    end

    for _, edge in ipairs(surface.edges) do
        if not exact_keys(edge, {
            edge_id = true,
            left = true,
            right = true,
            legal_directions = true,
        }) then
            return nil, surface_error()
        end
    end

    local current, current_err = build_surface()
    if not current then
        return nil, current_err
    end
    local computed, digest_err = digest.record(surface_seed(surface))
    if not computed then
        return nil, surface_error()
    end
    if surface.surface_id ~= "sha256:" .. computed
        or json.encode(surface) ~= json.encode(current)
    then
        return nil, surface_error()
    end
    return true
end

return edge_catalog
