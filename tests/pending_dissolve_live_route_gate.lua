package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")
local field = require("runtime.field")
local flow_domain = require("runtime.flow_domain")
local tension_runner = require("runtime.tension_runner")
local H = require("tests.support.red_contract")

local suite = H.new("dissolve-live-route")

local function domain(label)
    return assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = "dissolve-r3:" .. label,
        source_ref = "fixture:dissolve-r3:" .. label,
    }))
end

local function options(label, max_ticks, overrides)
    local value = {
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        legacy_shadow = false,
        work_mode = "plan",
        max_ticks = max_ticks,
        packet_life = {
            protocol_version = "vertical_packet_life.v0",
            flow_domain = domain(label),
            projection_adapter = "vertical_pair.v0",
        },
        packet_options = {
            id = "packet:dissolve-r3:" .. label,
            lineage_id = "lineage:dissolve-r3:" .. label,
            session_id = "session:dissolve-r3",
            budget = {
                steps = 64,
                substrate_calls = 8,
                tool_calls = 4,
                encode_items = 32,
                loss = 10,
            },
        },
    }
    for key, item in pairs(overrides or {}) do
        value[key] = item
    end
    return value
end

local function run(label, max_ticks, substrate, overrides)
    local instance, result = assert(tension_runner.run(
        "grow an exact DISSOLVE R3 diagnostic",
        substrate,
        options(label, max_ticks, overrides)
    ))
    return instance, result
end

local function first_raw(instance)
    local raw = instance.field and instance.field.relations
        and instance.field.relations.raw or {}
    return raw.items and raw.items[1]
end

local function raw_phase(instance)
    local relation = assert(first_raw(instance), "raw relation required")
    return assert(field.raw_relation_phase(
        instance,
        relation.epoch,
        relation.id
    )).phase
end

local function has_tick(result, operator)
    for _, tick in ipairs(result.ticks or {}) do
        if tick.operator == operator then
            return true
        end
    end
    return false
end

local function has_route(result, from, to)
    for _, route in ipairs(result.routes or {}) do
        if route.from == from and route.to == to then
            return true
        end
    end
    return false
end

local function last_derivation(instance)
    local found
    for _, event in ipairs(instance.trace or {}) do
        if event.type == "route_derivation" then
            found = event.payload
        end
    end
    return found
end

local alternative_proposal = {
    protocol_version = "packet.structure.proposal.v0",
    receiver_contract_id = "calm.work_structure.v0",
    shape = "alternative_set",
    items = {
        {key = "retain", kind = "work_item", value = "retain", source_keys = {}},
        {key = "replace", kind = "work_item", value = "replace", source_keys = {}},
    },
    edges = {},
    choice = {kind = "mutually_exclusive"},
}

local alternative_substrate = {
    ask = function()
        return {text = json.encode(alternative_proposal)}
    end,
}

suite:check("R3-01 CONNECT leaves one current raw relation", function()
    local instance, result = run("current", 1, nil)
    H.assert_eq(raw_phase(instance), "available",
        "first CONNECT tick must leave the raw identity current")
    H.assert_true(has_route(result, "☰", "☵"),
        "current raw identity immediately commits relation formation")
    H.assert_false(has_tick(result, "☷"),
        "current relation must not create DISSOLVE work")
end)

suite:check("R3-02 ordinary continuation encodes before any endpoint mutation", function()
    local instance, result = run("ordinary-continuation", 4, nil)
    H.assert_eq(raw_phase(instance), "encoded",
        "ordinary continuation consumes raw identity through ENCODE")
    H.assert_false(has_tick(result, "☳"),
        "ordinary relation life has no endpoint-mutating CHOOSE tick")
    H.assert_false(has_tick(result, "☷"),
        "ordinary relation life cannot reach DISSOLVE")
end)

suite:check("R3-03 real alternative work does not manufacture a stale fixture", function()
    local instance, result = run(
        "competing-body-mutation",
        12,
        alternative_substrate
    )
    local derivation = assert(last_derivation(instance),
        "competing life must retain its route derivation")
    H.assert_eq(derivation.outcome, "ambiguous_pressure",
        "CONNECT recognition and structure formation remain distinct work")
    H.assert_false(has_tick(result, "☳"),
        "the body cannot claim a CHOOSE mutation that never executed")
    H.assert_false(first_raw(instance),
        "the body cannot claim a raw relation that CONNECT never executed")
end)

suite:check("R3-04 one ordinary body-visible stale fact executes DISSOLVE", function()
    local instance, result = run("desired-positive", 8, nil)
    H.assert_eq(raw_phase(instance), "released",
        "ordinary life has no writer for stale/release fact before ENCODE")
    H.assert_true(has_tick(result, "☷"),
        "qualified body did not execute a DISSOLVE destination tick")
end)

suite:finish()
