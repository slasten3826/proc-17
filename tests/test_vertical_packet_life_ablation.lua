package.path = "./?.lua;./?/init.lua;" .. package.path

local field = require("runtime.field")
local flow_domain = require("runtime.flow_domain")
local registry = require("runtime.operator_registry")
local tension_runner = require("runtime.tension_runner")
local fake = require("substrates.fake")
local vertical_life = require("tests.support.vertical_life")

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

local function route_tick(life, target, options)
    assert(life:transition(target, "ablation_" .. target))
    return assert(life:tick(options or {}))
end

local serial = 0
local function domain(label)
    serial = serial + 1
    return assert(flow_domain.new({3, 7, 13, 19, 29}, {
        stream_id = label .. "-" .. tostring(serial),
        source_ref = "fixture:" .. label .. ":" .. tostring(serial),
    }))
end

local function walk(result)
    local values = {}
    for _, tick in ipairs(result.ticks or {}) do
        values[#values + 1] = tick.operator
    end
    return table.concat(values)
end

-- OFF: absent and unknown integration protocols are identical legacy controls.
local off_packet, off_result = assert(tension_runner.run("ablation control", fake, {
    work_mode = "plan",
    max_ticks = 6,
    packet_options = {
        budget = {steps = 32, substrate_calls = 8, encode_items = 8, loss = 2},
    },
}))
local unknown_packet, unknown_result = assert(tension_runner.run("ablation control", fake, {
    work_mode = "plan",
    max_ticks = 6,
    packet_life = {protocol_version = "unknown.integration.v0"},
    packet_options = {
        budget = {steps = 32, substrate_calls = 8, encode_items = 8, loss = 2},
    },
}))
assert_eq(walk(off_result), walk(unknown_result), "OFF route is unchanged by unknown protocol")
for _, axis in ipairs({"steps", "substrate_calls", "estimated_tokens"}) do
    assert_eq(off_packet.runtime.budget.spent[axis], unknown_packet.runtime.budget.spent[axis],
        "OFF economics match on " .. axis)
end
assert_eq(off_packet.tension.loss, unknown_packet.tension.loss, "OFF loss is unchanged")
assert_eq(off_packet.ingress.integration_protocol, nil, "OFF packet has no vertical ingress")
assert_eq(unknown_packet.ingress.integration_protocol, nil,
    "unknown protocol cannot touch vertical ingress")

-- Remove raw relation: relation-guided ENCODE cannot claim formation.
local no_raw = assert(vertical_life.new(domain("no-raw"), "no raw", "vertical_pair.v0"))
assert(no_raw:transition("☰", "skip_connect_effect"))
assert(no_raw:transition("☵", "attempt_without_raw"))
local no_raw_ready = assert(registry.readiness("☵", no_raw.instance, {
    options = {encode = {relation_input = {
        raw_epoch = 1,
        relation_ids = {"relation:1"},
        endpoint_versions = {["unit:2"] = 1, ["unit:3"] = 1},
    }}},
}))
assert_true(not no_raw_ready.ready, "missing raw relation blocks guided ENCODE")
assert_eq(no_raw_ready.reason, "raw relation epoch not found", "missing raw reason")
assert_eq(no_raw.instance.calm.current, nil, "missing raw relation cannot create CALM")

-- Disable relation reader: unrelated native field sight cannot consume raw identity.
local no_reader = assert(vertical_life.new(
    domain("no-reader"), "reader disabled", "vertical_pair.v0"
))
route_tick(no_reader, "☰", {connect = {}})
local no_reader_relation = no_reader.instance.field.relations.raw.items[1]
route_tick(no_reader, "☴", {observe = {
    sensor = "field_native",
    unit_ids = {no_reader_relation.from, no_reader_relation.to},
}})
assert_eq(assert(field.raw_relation_phase(
    no_reader.instance, 1, no_reader_relation.id
)).phase, "available", "non-relation reader cannot consume or observe raw identity")
assert_eq(no_reader.instance.calm.current, nil, "disabled relation reader creates no hidden form")

-- Remove only the Packet's audit mark after FLOW: L2 semantics/routes/economics stay equal.
local mark_control = assert(vertical_life.new(
    domain("mark-control"), "mark control", "vertical_pair.v0"
))
local mark_masked = assert(vertical_life.new(
    domain("mark-masked"), "mark control", "vertical_pair.v0"
))
mark_masked.instance.ingress.flow_mark = nil -- explicit ablation, not a valid production Packet
route_tick(mark_control, "☰", {connect = {}})
route_tick(mark_masked, "☰", {connect = {}})
assert_eq(#mark_control.instance.field.relations.raw.items,
    #mark_masked.instance.field.relations.raw.items, "flow mark does not create relation")
assert_eq(mark_control.instance.field.relations.raw.items[1].kind,
    mark_masked.instance.field.relations.raw.items[1].kind,
    "flow mark does not choose relation semantics")
assert_eq(mark_control.instance.runtime.budget.spent.steps,
    mark_masked.instance.runtime.budget.spent.steps, "flow mark does not change step cost")
assert_eq(mark_control.instance.tension.loss, mark_masked.instance.tension.loss,
    "flow mark does not change identity loss")

-- Disable projection: the seam cannot remain green on the semantic prompt alone.
local no_projection = assert(vertical_life.new(
    domain("no-projection"), "prompt is not L1", nil
))
local no_projection_ready = assert(registry.readiness("☰", no_projection.instance, {
    options = {connect = {}},
}))
assert_true(not no_projection_ready.ready, "no projection means no fixture relation domain")
assert_eq(no_projection_ready.reason, "no_addressable_units",
    "semantic prompt cannot impersonate L1 projection")

local function formed_life(label, work_mode)
    local life = assert(vertical_life.new(domain(label), label, "vertical_pair.v0", {
        packet_options = {
            budget = {steps = 32, substrate_calls = 4, encode_items = 8, loss = 1},
            metadata = {work_mode = work_mode},
        },
    }))
    route_tick(life, "☰", {connect = {}})
    local relation = life.instance.field.relations.raw.items[1]
    route_tick(life, "☵", {encode = {relation_input = {
        raw_epoch = 1,
        relation_ids = {relation.id},
        endpoint_versions = relation.endpoint_versions,
    }}})
    route_tick(life, "☲", {work_mode = work_mode, max_ticks = 16})
    return life
end

-- Disable lower update: manifest may still terminate, but full L3 continuity is absent.
local no_lower = formed_life("no-lower", "plan")
route_tick(no_lower, "☶", {work_mode = "plan"})
local no_lower_manifest = route_tick(no_lower, "△", {work_mode = "plan"})
assert_eq(no_lower_manifest.sources.runtime_reconciliation_event, nil,
    "no lower update cannot claim runtime reconciliation")
assert_eq(no_lower.instance.status, "dead", "partial vertical route still obeys terminality")

-- Rejected validation remains outwardly blocked through the complete vertical lower path.
local missing_path = "sandbox/vertical_ablation_missing.py"
os.remove(missing_path)
local rejected = formed_life("rejected", "build")
local rejected_logic = route_tick(rejected, "☶", {
    work_mode = "build",
    logic = {spells = {{
        kind = "py_compile_python_file",
        name = "vertical_ablation_missing",
        intention = "vertical_ablation_missing",
        path = missing_path,
    }}},
})
assert_eq(rejected_logic.status, "rejected", "validation fixture genuinely rejects")
route_tick(rejected, "☱", {work_mode = "build"})
local rejected_manifest = route_tick(rejected, "△", {work_mode = "build"})
assert_eq(rejected_manifest.output.status, "blocked", "manifest exposes blocked result")
assert_eq(rejected.instance.death.cause, "blocked", "blocked result becomes blocked corpse")

print("test_vertical_packet_life_ablation ok")
