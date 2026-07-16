local topology = require("core.topology")

local edge_catalog = {}

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
        result[index] = definition
    end
    return result
end

function edge_catalog.get(value, right)
    if right ~= nil then
        return by_edge[edge_catalog.edge(value, right)]
    end
    return by_id[value] or by_edge[value]
end

return edge_catalog
