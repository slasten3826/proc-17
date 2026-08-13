package.path = "./?.lua;./?/init.lua;" .. package.path

local corpse = require("runtime.corpse")
local digest = require("core.digest")
local edge_catalog = require("runtime.edge_catalog")
local edge_life_projection = require("runtime.edge_life_projection")
local flow_domain = require("runtime.flow_domain")
local packet_core = require("core.packet")
local tension_runner = require("runtime.tension_runner")
local fixture = require("tests.support.qa_hand")

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy(key, seen)] = copy(child, seen)
    end
    return result
end

local function find_unit(instance, kind)
    local found
    for _, id in ipairs(instance.field and instance.field.unit_order or {}) do
        local unit = instance.field.units[id]
        if unit and unit.kind == kind then
            assert(found == nil, "duplicate " .. kind)
            found = unit
        end
    end
    return found
end

local function events(instance, event_type)
    local result = {}
    for _, event in ipairs(instance.trace or {}) do
        if event.type == event_type then result[#result + 1] = event end
    end
    return result
end

local function direction(ledger, from, to)
    local definition = assert(edge_catalog.get(from, to))
    return assert(ledger.edges[definition.edge].directions[from .. "->" .. to])
end

local frozen_time = 1786579200

local function run_life(label, instrument, options)
    options = options or {}
    local grown = assert(fixture.grow_qa_descendant({
        label = "qa-dissolve-life-ancestor",
        session_id = "session-qa-dissolve-life",
        packet_options = {id = "packet:qa-dissolve-life-ancestor"},
        child_packet_id = "packet:qa-dissolve-fixture-child",
        child_stream_id = "stream:qa-dissolve-fixture-child",
        fresh_repository_id = "repo-qa-dissolve-life-child",
    }))
    local packet_options = copy(grown.ingress.packet_options)
    packet_options.id = "packet:qa-dissolve-life-child"
    packet_options.repository_id = grown.fresh_repository_id
    packet_options.budget = {
        steps = 32,
        substrate_calls = 8,
        tool_calls = 8,
        encode_items = 16,
        loss = 10,
    }
    local domain = assert(flow_domain.new({2, 3, 5, 7, 11}, {
        stream_id = "stream:qa-dissolve-life-child",
        source_ref = grown.network_projection.projection_id,
    }))
    local runner_options = {
        authority_instrument = instrument,
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        legacy_shadow = false,
        work_mode = "build",
        max_ticks = options.max_ticks or 2,
        ablate_relation_consumer = true,
        ablate_inherited_form_consumer = options.ablate_consumer == true,
        packet_options = packet_options,
        packet_life = {
            protocol_version = "vertical_packet_life.v0",
            flow_domain = domain,
            projection_adapter = "vertical_single.v0",
            network_projection = grown.ingress.network_projection,
        },
    }
    if instrument == "off" then
        runner_options.authority_instrument_test_override = true
    else
        runner_options.edge_evidence = {
            case_id = label,
            corpus_layer = "unit",
            evidence_run_id = "run:dissolve-network-life",
        }
    end
    local calls = 0
    local substrate
    if options.substrate ~= false then
        substrate = {
            ask = function()
                calls = calls + 1
                return {
                    text = "bounded post-release observation",
                    usage = {
                        prompt_tokens = 1,
                        completion_tokens = 1,
                        total_tokens = 2,
                    },
                }
            end,
        }
    end
    local instance, result = assert(tension_runner.run(
        grown.ingress.prompt,
        substrate,
        runner_options
    ))
    return {
        instance = instance,
        result = result,
        substrate_calls = calls,
    }
end

local function frozen(callback)
    local original = os.time
    os.time = function() return frozen_time end
    local values = table.pack(pcall(callback))
    os.time = original
    if not values[1] then error(values[2], 0) end
    return table.unpack(values, 2, values.n)
end

local measured = frozen(function()
    return run_life("QD07_QD08", "v3", {})
end)
assert_eq(measured.result.entry_route.from, "▽")
assert_eq(measured.result.entry_route.to, "☷")
assert_eq(measured.result.ticks[1].operator, "☷")
assert_eq(measured.result.routes[1].from, "☷")
assert_eq(measured.result.routes[1].to, "☴")
assert_eq(measured.result.ticks[2].operator, "☴")
assert_eq(measured.substrate_calls, 1)
assert_eq(#events(measured.instance, "unit_dissolution"), 1)
local released = assert(find_unit(measured.instance, "inherited_rejected_form"))
assert_eq(released.activation, "dissolved")
assert(find_unit(measured.instance, "rejected_form_residue"))

local e02 = direction(measured.result.edge_stats, "▽", "☷")
assert_eq(e02.physical.committed_count, 1)
assert_eq(e02.physical.executed_count, 1)
local e07 = direction(measured.result.edge_stats, "☷", "☴")
assert_eq(e07.physical.committed_count, 1)
assert_eq(e07.physical.executed_count, 1)

local ablated = frozen(function()
    return run_life("QD06", "v3", {ablate_consumer = true})
end)
assert(ablated.result.entry_route == nil
        or ablated.result.entry_route.to ~= "☷",
    "consumer ablation retained the DISSOLVE route")
assert_eq(#events(ablated.instance, "unit_dissolution"), 0)
assert_eq(assert(find_unit(
    ablated.instance,
    "inherited_rejected_form"
)).activation, "live")

local substrate_free = frozen(function()
    return run_life("QD12", "v3", {max_ticks = 1, substrate = false})
end)
assert_eq(substrate_free.result.entry_route.to, "☷")
assert_eq(substrate_free.result.ticks[1].operator, "☷")
if substrate_free.result.routes[1] then
    assert_eq(substrate_free.result.routes[1].to, "☴")
else
    assert_eq(substrate_free.result.stop_reason, "stalled")
    assert(substrate_free.result.no_viable_edge,
        "missing substrate produced no typed routing boundary")
end
assert_eq(substrate_free.substrate_calls, 0)
assert_eq(#events(substrate_free.instance, "unit_dissolution"), 1)

local off, on = frozen(function()
    return run_life("QD11", "off", {}), run_life("QD11", "v3", {})
end)
for _, life in ipairs({off, on}) do
    if life.instance.status ~= "dead" then
        assert(packet_core.die(life.instance, "cancelled", {
            cause = "masslessness_control",
        }))
    end
    life.corpse = assert(corpse.capture(life.instance, {
        corpse_id = "corpse:qa-dissolve-life-child:masslessness",
        trace_tail_count = 32,
    }))
    life.projection = assert(edge_life_projection.capture(
        life.instance,
        life.result,
        life.corpse,
        {life_id = "life:qa-dissolve-masslessness"}
    ))
end
local same, differences = edge_life_projection.same_exact(
    off.projection,
    on.projection
)
assert(same, "authority instrument changed DISSOLVE life: "
    .. table.concat(differences or {}, ","))
assert_eq(assert(digest.record(off.corpse)), assert(digest.record(on.corpse)),
    "authority instrument changed DISSOLVE corpse")

print("test_inherited_form_dissolve_life ok")
