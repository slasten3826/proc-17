local json = require("core.json")
local flow_domain = require("runtime.flow_domain")
local tension_runner = require("runtime.tension_runner")

local fixture = {}
local counter = 0

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

function fixture.proposal(shape, values, edges)
    local items = {}
    for index, value in ipairs(values or {"inspect", "change", "verify"}) do
        items[index] = {
            key = "item-" .. tostring(index),
            kind = shape == "artifact_set" and "artifact" or "work_item",
            value = value,
            source_keys = {},
        }
    end
    local result = {
        protocol_version = "packet.structure.proposal.v0",
        receiver_contract_id = "calm.work_structure.v0",
        shape = shape,
        items = items,
        edges = copy_value(edges or {}),
    }
    if shape == "alternative_set" then
        result.choice = {kind = "mutually_exclusive"}
    end
    return result
end

function fixture.substrate(envelope)
    return {
        ask = function()
            return {text = type(envelope) == "string" and envelope or json.encode(envelope)}
        end,
    }
end

function fixture.options(label, max_ticks, overrides)
    counter = counter + 1
    local id = label .. "-" .. tostring(counter)
    local domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = id,
        source_ref = "fixture:" .. id,
    }))
    local options = {
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        ablate_relation_consumer = true,
        work_mode = "plan",
        max_ticks = max_ticks,
        legacy_shadow = false,
        packet_life = {
            protocol_version = "vertical_packet_life.v0",
            flow_domain = domain,
            projection_adapter = "vertical_single.v0",
        },
    }
    for key, value in pairs(overrides or {}) do
        options[key] = value
    end
    return options
end

function fixture.run(label, shape, values, max_ticks, overrides, envelope)
    local proposal = envelope or fixture.proposal(shape, values)
    return tension_runner.run(
        label,
        fixture.substrate(proposal),
        fixture.options(label, max_ticks, overrides)
    )
end

function fixture.operators(result)
    local values = {}
    for _, tick in ipairs(result and result.ticks or {}) do
        values[#values + 1] = tick.operator
    end
    return values
end

function fixture.walk(result)
    return table.concat(fixture.operators(result))
end

function fixture.last_route_to(result, target)
    for index = #(result and result.routes or {}), 1, -1 do
        local route = result.routes[index]
        if route.to == target then
            return route
        end
    end
    return nil
end

function fixture.events(instance, event_type)
    local values = {}
    for _, event in ipairs(instance and instance.trace or {}) do
        if event.type == event_type then
            values[#values + 1] = event
        end
    end
    return values
end

return fixture
