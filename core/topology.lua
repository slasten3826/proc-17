local topology = {}

topology.version = "processlang.topology.v0"

topology.order = {"▽", "☰", "☷", "☵", "☳", "☴", "☲", "☶", "☱", "△"}

topology.operators = {
    ["▽"] = {name = "FLOW", adjacent = {"☰", "☷", "☴"}},
    ["☰"] = {name = "CONNECT", adjacent = {"▽", "☷", "☴", "☵"}},
    ["☷"] = {name = "DISSOLVE", adjacent = {"▽", "☰", "☴", "☳"}},
    ["☵"] = {name = "ENCODE", adjacent = {"☰", "☴", "☱", "☳", "☲"}},
    ["☳"] = {name = "CHOOSE", adjacent = {"☷", "☴", "☱", "☵", "☶"}},
    ["☴"] = {name = "OBSERVE", adjacent = {"▽", "☰", "☷", "☵", "☳", "☱"}},
    ["☲"] = {name = "CYCLE", adjacent = {"☵", "☶", "△", "☱"}},
    ["☶"] = {name = "LOGIC", adjacent = {"☳", "☲", "☱", "△"}},
    ["☱"] = {name = "RUNTIME", adjacent = {"☴", "△", "☵", "☳", "☶", "☲"}},
    ["△"] = {name = "MANIFEST", adjacent = {"☱", "☲", "☶"}},
}

topology.aliases = {}
for glyph, op in pairs(topology.operators) do
    topology.aliases[op.name] = glyph
end

function topology.resolve(value)
    if topology.operators[value] then
        return value
    end
    return topology.aliases[value]
end

function topology.is_operator(value)
    return topology.resolve(value) ~= nil
end

function topology.is_adjacent(left, right)
    local left_glyph = topology.resolve(left)
    local right_glyph = topology.resolve(right)
    if not left_glyph or not right_glyph then
        return false
    end

    for _, glyph in ipairs(topology.operators[left_glyph].adjacent) do
        if glyph == right_glyph then
            return true
        end
    end

    return false
end

function topology.validate_trace(trace)
    for index = 1, #trace - 1 do
        if not topology.is_adjacent(trace[index], trace[index + 1]) then
            return false, {
                index = index,
                left = trace[index],
                right = trace[index + 1],
                message = "invalid operator transition",
            }
        end
    end

    return true
end

return topology
