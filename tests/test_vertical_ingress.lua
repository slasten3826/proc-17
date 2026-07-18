package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local field = require("runtime.field")
local flow = require("organs.flow")
local flow_domain = require("runtime.flow_domain")
local packet_birth = require("runtime.packet_birth")
local tension_runner = require("runtime.tension_runner")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": " .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function new_domain(id)
    return assert(flow_domain.new({11, 22, 33, 44, 55}, {
        stream_id = id,
        source_ref = "fixture:" .. id,
        adapter_id = "fixture.integer_ring.v0",
    }))
end

local pair_domain = new_domain("vertical-pair")
local pair, pair_birth = assert(packet_birth.create(pair_domain, "semantic prompt", {
    projection_adapter = "vertical_pair.v0",
    packet_options = {id = "vertical-pair-packet"},
}))
assert_eq(pair_birth.flow_ref.birth_seq, 1, "pair birth receipt")
assert_eq(#pair.ingress.l1_projection.units, 2, "pair adapter emits two samples")
assert_eq(#pair.ingress.l1_projection.relation_candidates, 1,
    "pair adapter declares one structural candidate")

local _, pair_flow = assert(flow.run(pair))
assert_eq(#pair_flow.unit_ids, 3, "FLOW materializes prompt and two L1 samples")
assert_eq(#pair_flow.materialized, 3, "FLOW reports every materialized unit")
assert_eq(pair_flow.materialized[1].provenance_class, "prompt", "prompt stays distinct")
assert_eq(pair_flow.materialized[2].provenance_class, "l1_projection", "L1 sample class")
assert_eq(pair_flow.materialized[3].provenance_class, "l1_projection", "second L1 sample class")
assert_eq(pair_flow.flow_ref.birth_seq, 1, "FLOW reports exact birth ref")

local pair_view = assert(field.view(pair, {created_by = "▽", limit = 8}))
assert_eq(pair_view.total_count, 3, "field contains only materialized carriers")
for index = 2, 3 do
    local unit = pair_view.units[index]
    assert_eq(unit.content_truth_status, "non_semantic_measurement",
        "L1 projection cannot become semantic truth")
    assert_eq(unit.migration.adapter_id, "vertical_pair.v0", "adapter provenance retained")
    assert_eq(unit.migration.flow_ref.birth_seq, 1, "sample owns exact flow ref")
    assert_true(unit.carrier.protocol_version == nil, "flow mark is not materialized as a unit")
end
assert_eq(pair.calm.current, nil, "FLOW projection creates no CALM form")
assert_eq(#pair.field.relations.raw.items, 0, "FLOW projection creates no raw relation")
assert_eq(#pair.field.relations.active, 0, "FLOW projection creates no retained relation")

local duplicate, duplicate_err = flow.run(pair)
assert_true(not duplicate, "FLOW cannot materialize ingress twice")
assert_eq(duplicate_err, "FLOW already materialized", "duplicate FLOW rejection")
assert_eq(field.view(pair, {created_by = "▽", limit = 8}).total_count, 3,
    "duplicate FLOW cannot append units")

local single_domain = new_domain("vertical-single")
local single = assert(packet_birth.create(single_domain, "single prompt", {
    projection_adapter = "vertical_single.v0",
}))
local _, single_flow = assert(flow.run(single))
assert_eq(#single_flow.unit_ids, 2, "single adapter emits prompt plus one sample")
assert_eq(#single.ingress.l1_projection.relation_candidates, 0,
    "single adapter cannot invent relation")

local rollback_domain = new_domain("vertical-rollback")
local before = assert(flow_domain.snapshot(rollback_domain))
local rejected, rejected_err = packet_birth.create(rollback_domain, "bad projection", {
    projection_adapter = "unknown.v0",
})
assert_true(not rejected, "unknown projection adapter rejects birth")
assert_true(tostring(rejected_err):find("unknown L1 projection adapter", 1, true) ~= nil,
    "projection rejection is explicit")
local after = assert(flow_domain.snapshot(rollback_domain))
assert_eq(after.birth_seq, before.birth_seq, "projection failure does not consume birth sequence")
assert_eq(after.snapshot.tick, before.snapshot.tick, "projection failure does not consume L1 tick")

local grave_domain = new_domain("vertical-grave-preflight")
local invalid_run, invalid_err = tension_runner.run("never born", nil, {
    packet_life = {
        protocol_version = "vertical_packet_life.v0",
        flow_domain = grave_domain,
        projection_adapter = "vertical_single.v0",
    },
    inherited_graves = {{kind = "grave", grave_kind = "unknown"}},
})
assert_true(not invalid_run, "invalid grave fails before Packet birth")
assert_true(tostring(invalid_err):find("grave_preflight", 1, true) ~= nil,
    "grave preflight stage is visible")
assert_eq(grave_domain.birth_seq, 0, "invalid grave does not consume L1 birth")

local legacy = packet.new("legacy prompt", {id = "legacy-ingress-control"})
local _, legacy_flow = assert(flow.run(legacy))
assert_eq(#legacy_flow.unit_ids, 1, "default FLOW remains one-unit control")
assert_eq(legacy_flow.integration_protocol, nil, "default FLOW has no vertical integration")

print("test_vertical_ingress ok")
