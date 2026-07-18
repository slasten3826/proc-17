package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local body = require("runtime.body")
local field = require("runtime.field")
local flow_domain = require("runtime.flow_domain")
local registry = require("runtime.operator_registry")
local pressure = require("runtime.pressure")
local freshness = require("runtime.freshness")
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

local serial = 0
local function domain(label)
    serial = serial + 1
    return assert(flow_domain.new({2, 5, 11, 17, 23}, {
        stream_id = label .. "-" .. tostring(serial),
        source_ref = "fixture:" .. label .. ":" .. tostring(serial),
    }))
end

local function route_tick(life, target, options)
    assert(life:transition(target, "grown_life_" .. target))
    return assert(life:tick(options or {}))
end

-- Life A: one addressable physical sample is probed once and honestly empty.
local life_a = assert(vertical_life.new(domain("life-a"), "empty probe", "vertical_single.v0"))
route_tick(life_a, "☰", {connect = {}})
local raw_a = life_a.instance.field.relations.raw
assert_eq(raw_a.outcome, "empty", "A empty outcome")
assert_eq(raw_a.object_coverage.stored_count, 1, "A covers one addressable L1 sample")
assert_eq(#raw_a.items, 0, "A stores no invented relation")
assert_eq(#life_a.instance.field.relations.active, 0, "A retains nothing")
local a_again = assert(registry.readiness("☰", life_a.instance, {options = {connect = {}}}))
assert_true(not a_again.ready, "A exact empty probe discharges repetition")

-- Life B: native sight observes a raw relation without retaining or calling substrate.
local life_b = assert(vertical_life.new(domain("life-b"), "native sight", "vertical_pair.v0"))
route_tick(life_b, "☰", {connect = {}})
local relation_b = life_b.instance.field.relations.raw.items[1]
local b_units = #life_b.instance.field.unit_order
local b_substrate = life_b.instance.runtime.budget.spent.substrate_calls
route_tick(life_b, "☴", {observe = {
    sensor = "relation_native",
    relation_input = {
        raw_epoch = 1,
        relation_ids = {relation_b.id},
        endpoint_versions = relation_b.endpoint_versions,
    },
}})
assert_eq(#life_b.instance.field.unit_order, b_units, "B sight creates no unit")
assert_eq(life_b.instance.runtime.budget.spent.substrate_calls, b_substrate,
    "B sight spends no substrate call")
assert_eq(#life_b.instance.field.relations.active, 0, "B sight retains nothing")
assert_eq(life_b.instance.calm.current, nil, "B sight creates no CALM")
assert_eq(assert(field.raw_relation_phase(life_b.instance, 1, relation_b.id)).phase,
    "observed", "B phase observed")

-- Life C: DISSOLVE releases raw potentiality without activating it.
local life_c = assert(vertical_life.new(domain("life-c"), "raw release", "vertical_pair.v0"))
route_tick(life_c, "☰", {connect = {}})
local relation_c = life_c.instance.field.relations.raw.items[1]
local c_loss = life_c.instance.tension.loss
local c_payload = route_tick(life_c, "☷", {dissolve = {
    scope = "raw",
    raw_epoch = 1,
    relation_id = relation_c.id,
    endpoint_versions = relation_c.endpoint_versions,
    preserve_residue = true,
    reason = {
        kind = "explicitly_released",
        policy_id = "vertical.fixture.explicit_release.v0",
    },
}})
assert_eq(c_payload.mode, "raw_release", "C release mode")
assert_eq(assert(field.raw_relation_phase(life_c.instance, 1, relation_c.id)).phase,
    "released", "C phase released")
assert_eq(#life_c.instance.field.relations.active, 0, "C never activates relation")
assert_eq(life_c.instance.tension.loss, c_loss, "C creates no identity loss")
assert_true(c_payload.residue ~= nil, "C residue remains a bounded unit")

-- Life D: relation formation traverses the lower body and reaches honest terminal.
local domain_d = domain("life-d")
local life_d = assert(vertical_life.new(domain_d, "formed terminal", "vertical_pair.v0", {
    packet_options = {
        budget = {steps = 32, substrate_calls = 4, encode_items = 8, loss = 1},
        metadata = {work_mode = "plan"},
    },
}))
route_tick(life_d, "☰", {connect = {}})
local relation_d = life_d.instance.field.relations.raw.items[1]
local encoded_d = route_tick(life_d, "☵", {encode = {
    relation_input = {
        raw_epoch = 1,
        relation_ids = {relation_d.id},
        endpoint_versions = relation_d.endpoint_versions,
    },
}})
route_tick(life_d, "☲", {work_mode = "plan", max_ticks = 16})
route_tick(life_d, "☶", {work_mode = "plan"})
route_tick(life_d, "☱", {work_mode = "plan"})
local manifested_d = route_tick(life_d, "△", {work_mode = "plan"})
assert_eq(encoded_d.formation_basis, "relation_guided", "D exact relation formation")
assert_eq(life_d.instance.tension.loss, 0.5, "D formation loss enters lethal ledger")
assert_eq(life_d.instance.runtime.budget.spent.steps, 6, "D charges each Packet tick once")
assert_eq(life_d.instance.runtime.budget.spent.substrate_calls, 0,
    "D uses no hidden substrate call")
assert_eq(#life_d.instance.field.relations.active, 0, "D runtime cannot activate raw relation")
assert_eq(life_d.instance.status, "dead", "D terminates")
assert_eq(life_d.instance.death.cause, "complete", "D terminal cause follows accepted evidence")
assert_eq(manifested_d.sources.birth_event ~= nil, true, "D manifest names birth")
assert_eq(manifested_d.sources.raw_relation_event ~= nil, true, "D manifest names raw relation")
assert_eq(manifested_d.sources.relation_formation_event ~= nil, true,
    "D manifest names relation formation")
assert_eq(domain_d.status, "open", "D death leaves L1 domain alive")
assert_eq(life_d.result.authority, "harness_override", "D route authority is fixture-only")
assert_eq(life_d.result.promotion_eligible, false, "D cannot count as router promotion")

-- Life E1: one formed unit re-arms relation coverage exactly once.
local life_e1 = assert(vertical_life.new(domain("life-e1"), "relation rearm", "vertical_pair.v0"))
route_tick(life_e1, "☰", {connect = {}})
local relation_e1 = life_e1.instance.field.relations.raw.items[1]
local formed_e1 = route_tick(life_e1, "☵", {encode = {
    relation_input = {
        raw_epoch = 1,
        relation_ids = {relation_e1.id},
        endpoint_versions = relation_e1.endpoint_versions,
    },
}})
local formed_id = formed_e1.relation_formation.formed_unit_ids[1]
local e1_ready = assert(registry.readiness("☰", life_e1.instance, {
    options = {connect = {}},
}))
assert_true(e1_ready.ready, "E1 new formed unit re-arms CONNECT")
assert_eq(#e1_ready.source_refs, 1, "E1 readiness names only one uncovered object")
assert_eq(e1_ready.source_refs[1],
    "coverage:field_unit:" .. formed_id .. ":1", "E1 exact formed version ref")
route_tick(life_e1, "☰", {connect = {}})
assert_true(not assert(registry.readiness("☰", life_e1.instance, {
    options = {connect = {}},
})).ready, "E1 covering epoch discharges readiness")

-- Life E2: upper coverage sees one CHOOSE version change and then discharges it.
local life_e2 = assert(vertical_life.new(
    domain("life-e2"), "alpha\nbeta", "vertical_pair.v0"
))
route_tick(life_e2, "☰", {connect = {}})
local ordinary_e2 = route_tick(life_e2, "☵", {encode = {}})
local choice_ids = ordinary_e2.field_shadow.member_unit_ids
route_tick(life_e2, "☴", {observe = {
    sensor = "field_native",
    unit_ids = choice_ids,
}})
local choice_e2 = route_tick(life_e2, "☳", {choose = {
    limits = {max_selected = 1, max_killed_sample = 8},
}})
assert_eq(#choice_e2.suppressed_ids, 1, "E2 CHOOSE suppresses one covered unit")
local suppressed_id = choice_e2.field_shadow.suppressed_unit_ids[1]
local e2_ready = assert(registry.readiness("☴", life_e2.instance, {
    options = {observe = {sensor = "field_native", unit_ids = choice_ids}},
}))
assert_true(e2_ready.ready, "E2 changed version re-arms upper sight")
local suppressed_ref = "coverage:field_unit:" .. suppressed_id .. ":2"
local suppressed_seen = false
for _, ref in ipairs(e2_ready.source_refs) do
    if ref == suppressed_ref then
        suppressed_seen = true
    end
end
assert_true(suppressed_seen, "E2 names current suppressed version")
route_tick(life_e2, "☴", {observe = {
    sensor = "field_native",
    unit_ids = choice_ids,
}})
assert_true(not assert(registry.readiness("☴", life_e2.instance, {
    options = {observe = {sensor = "field_native", unit_ids = choice_ids}},
})).ready, "E2 second sight discharges version delta")

-- Life F: vertical integration preserves causal truth rent for real evidence.
local scratch = "sandbox/vertical_truth_rent.py"
local function write_file(content)
    local handle = assert(io.open(scratch, "w"))
    handle:write(content)
    handle:close()
end
write_file("value = 1\n")
local life_f = assert(vertical_life.new(domain("life-f"), "truth rent", "vertical_pair.v0", {
    packet_options = {
        budget = {steps = 32, substrate_calls = 4, encode_items = 8, loss = 1},
        metadata = {work_mode = "build"},
    },
}))
route_tick(life_f, "☰", {connect = {}})
local relation_f = life_f.instance.field.relations.raw.items[1]
route_tick(life_f, "☵", {encode = {relation_input = {
    raw_epoch = 1,
    relation_ids = {relation_f.id},
    endpoint_versions = relation_f.endpoint_versions,
}}})
route_tick(life_f, "☲", {work_mode = "build", max_ticks = 16})
route_tick(life_f, "☶", {
    work_mode = "build",
    logic = {spells = {{
        kind = "py_compile_python_file",
        name = "vertical_truth_rent",
        intention = "vertical_truth_rent",
        path = scratch,
    }}},
})
assert(life_f:transition("☱", "truth_rent_read"))
assert_eq(#assert(pressure.read("validation_debt", life_f.instance, {
    options = {work_mode = "build"},
})), 0, "F unchanged referent has no debt")
local fingerprint_a = freshness.evidence_fingerprint(life_f.instance)
write_file("value = 2\n")
assert_true(freshness.evidence_fingerprint(life_f.instance) ~= fingerprint_a,
    "F changed referent changes evidence fingerprint")
assert_eq(#assert(pressure.read("validation_debt", life_f.instance, {
    options = {work_mode = "build"},
})), 1, "F changed referent creates one debt")
route_tick(life_f, "☶", {
    work_mode = "build",
    logic = {spells = {{
        kind = "py_compile_python_file",
        name = "vertical_truth_rent",
        intention = "vertical_truth_rent",
        path = scratch,
    }}},
})
assert(life_f:transition("☱", "truth_rent_recheck"))
assert_eq(#assert(pressure.read("validation_debt", life_f.instance, {
    options = {work_mode = "build"},
})), 0, "F recast discharges debt")
assert_eq(#assert(pressure.read("validation_debt", life_f.instance, {
    options = {work_mode = "build"},
})), 0, "F unchanged B does not recur")
os.remove(scratch)

print("test_vertical_packet_life ok")
