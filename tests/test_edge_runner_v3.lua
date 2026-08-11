package.path = "./?.lua;./?/init.lua;" .. package.path

local edge_catalog = require("runtime.edge_catalog")
local edge_life_projection = require("runtime.edge_life_projection")
local flow_domain = require("runtime.flow_domain")
local tension_runner = require("runtime.tension_runner")
local fake = require("substrates.fake")

local function assert_true(value, message)
    if not value then error(message or "assertion failed", 2) end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function contains(values, expected)
    for _, value in ipairs(values or {}) do
        if value == expected then return true end
    end
    return false
end

local function packet_options(id)
    return {
        id = "packet:" .. id,
        lineage_id = "lineage:" .. id,
        budget = {
            steps = 64,
            substrate_calls = 16,
            tool_calls = 8,
            encode_items = 16,
            loss = 10,
        },
    }
end

local function evidence(case_id)
    return {
        case_id = case_id,
        corpus_layer = "unit",
        evidence_run_id = "run:i07:runner-integration",
    }
end

local function direction(ledger, from, to)
    local definition = assert(edge_catalog.get(from, to))
    return assert(ledger.edges[definition.edge].directions[from .. "->" .. to])
end

local function totals(ledger)
    local result = {
        selected = 0,
        committed = 0,
        executed = 0,
        failed = 0,
        pending = 0,
    }
    for _, edge in pairs(ledger.edges or {}) do
        for _, value in pairs(edge.directions or {}) do
            local physical = value.physical
            result.selected = result.selected + physical.selected_count
            result.committed = result.committed + physical.committed_count
            result.executed = result.executed + physical.executed_count
            result.failed = result.failed + physical.failed_count
            result.pending = result.pending
                + physical.pending_at_host_ceiling_count
        end
    end
    return result
end

local function event_count(events, kind)
    local count = 0
    for _, event in ipairs(events or {}) do
        if event.kind == kind then count = count + 1 end
    end
    return count
end

local function selection_by_authority(events, authority, ordinal)
    local count = 0
    for _, event in ipairs(events or {}) do
        if event.kind == "route_evidence_selection"
            and event.route_authority == authority then
            count = count + 1
            if count == (ordinal or 1) then return event end
        end
    end
    return nil
end

-- I09 cutover: omitted selects canonical v3 and off remains test-gated.
local default_packet, default_result = assert(tension_runner.run(
    "i09 default v3",
    fake,
    {
        router_mode = "legacy",
        work_mode = "plan",
        max_ticks = 0,
        packet_options = packet_options("i09-default-v3"),
    }
))
assert_eq(default_result.authority_instrument, "v3",
    "omitted option selects v3")
assert_eq(default_result.edge_stats.protocol_version, "edge-stats.v3",
    "canonical v3 ledger exists")
assert_eq(default_result.edge_evidence.protocol_version, "edge-stats.v3",
    "canonical v3 summary exists")
assert_eq(default_result.edge_stats_v3, nil, "temporary ledger alias is absent")
assert_eq(default_result.edge_evidence_v3, nil, "temporary summary alias is absent")
assert_true(default_result.edge_credit ~= nil, "v3 writes edge credit")

local denied_off, denied_off_err = tension_runner.run("i07 denied off", fake, {
    authority_instrument = "off",
})
assert_eq(denied_off, nil, "off without override is rejected")
assert_eq(denied_off_err,
    "birth_config:authority_instrument off requires test override",
    "off gate is explicit")

local off_packet, off_result = assert(tension_runner.run("i07 explicit off", fake, {
    authority_instrument = "off",
    authority_instrument_test_override = true,
    router_mode = "legacy",
    work_mode = "plan",
    max_ticks = 0,
    packet_options = packet_options("i07-off"),
}))
assert_eq(off_result.edge_stats, nil, "off writes no canonical ledger")
assert_eq(off_result.edge_evidence, nil, "off writes no canonical summary")
assert_eq(off_result.edge_credit, nil, "off writes no credit ledger")

-- EC05: a host ceiling closes the committed entry as pending, never executed.
local ec05_packet, ec05_result = assert(tension_runner.run("i07 EC05", fake, {
    authority_instrument = "v3",
    router_mode = "legacy",
    work_mode = "plan",
    max_ticks = 0,
    packet_options = packet_options("i07-ec05"),
    edge_evidence = evidence("EC05"),
}))
assert_true(ec05_result.authority_epoch ~= nil, "legacy v3 epoch exists")
assert_eq(ec05_result.edge_stats_v3, nil, "v3 has no temporary ledger alias")
assert_eq(ec05_result.edge_evidence_v3, nil, "v3 has no temporary summary alias")
assert_eq(ec05_result.edge_evidence.ledger_status, "valid", "EC05 ledger")
local ec05 = direction(ec05_result.edge_evidence, "▽", "☴")
assert_eq(ec05.physical.committed_count, 1, "EC05 committed")
assert_eq(ec05.physical.pending_at_host_ceiling_count, 1, "EC05 pending")
assert_eq(ec05.physical.executed_count, 0, "EC05 not executed")
assert_eq(ec05_packet.status, "running", "host ceiling leaves Packet physics alive")
assert_eq(ec05_packet.death, nil, "host ceiling creates no Packet death")

-- Shadow has its own evidence epoch while sharing legacy physical authority.
local shadow_packet, shadow_result = assert(tension_runner.run(
    "i07 shadow epoch",
    fake,
    {
        authority_instrument = "v3",
        router_mode = "shadow",
        work_mode = "plan",
        max_ticks = 1,
        packet_options = packet_options("i07-shadow"),
        edge_evidence = evidence("I07_SHADOW"),
    }
))
assert_true(shadow_result.authority_epoch ~= nil, "shadow v3 epoch exists")
assert_eq(shadow_result.edge_evidence.ledger_status, "valid",
    "shadow v3 ledger")
assert_true(shadow_result.edge_evidence.comparison_count > 0,
    "shadow observer is captured")

-- EC02: a body-grown fixture route executes but cannot receive promotion credit.
local domain = assert(flow_domain.new({2, 3, 5, 7}, {
    stream_id = "i07-ec02",
    source_ref = "fixture:i07-ec02",
}))
local ec02_packet, ec02_result = assert(tension_runner.run("i07 EC02", nil, {
    authority_instrument = "v3",
    router_mode = "tree",
    pressure_policy = "qualified_need_v0",
    legacy_shadow = false,
    work_mode = "plan",
    max_ticks = 1,
    packet_life = {
        protocol_version = "vertical_packet_life.v0",
        flow_domain = domain,
        projection_adapter = "vertical_pair.v0",
    },
    packet_options = packet_options("i07-ec02"),
    edge_evidence = evidence("EC02"),
}))
assert_true(ec02_result.authority_epoch ~= nil, "tree v3 epoch exists")
assert_eq(ec02_result.edge_evidence.ledger_status, "valid", "EC02 ledger")
local ec02 = direction(ec02_result.edge_evidence, "▽", "☰")
assert_eq(ec02.physical.executed_count, 1, "EC02 physically executes")
assert_eq(ec02.promotion.ineligible_executed_count, 1,
    "EC02 remains ineligible")
assert_eq(ec02.promotion.eligible_executed_count, 0,
    "EC02 receives no credit")
assert_true(ec02_packet.status ~= "born", "EC02 is body-grown")

-- EC06: a typed substrate failure closes the route as failed, never executed.
local failing_substrate = {
    ask = function()
        return nil, {
            kind = "effect_failure",
            source = "substrate",
            code = "connection_lost",
            message = "i07 injected typed failure",
            source_refs = {},
            retryability = "retryable",
            cost = {substrate_calls = 1},
            event_truth_status = "runtime_confirmed",
        }
    end,
}
local ec06_packet, ec06_result = assert(tension_runner.run(
    "i07 EC06",
    failing_substrate,
    {
        authority_instrument = "v3",
        router_mode = "tree",
        pressure_policy = "qualified_need_v0",
        legacy_shadow = false,
        work_mode = "plan",
        max_ticks = 8,
        packet_options = packet_options("i07-ec06"),
        edge_evidence = evidence("EC06"),
    }
))
assert_eq(ec06_packet.death.cause, "effect_failure", "EC06 body death")
assert_eq(ec06_result.edge_evidence.ledger_status, "valid", "EC06 ledger")
local ec06 = direction(ec06_result.edge_evidence, "▽", "☴")
assert_eq(ec06.physical.failed_count, 1, "EC06 failed")
assert_eq(ec06.physical.executed_count, 0, "EC06 not executed")
assert_eq(event_count(ec06_result.edge_credit.events, "edge_credit_decision"), 0,
    "EC06 cannot receive executed credit")

-- EC11: harness movement taints the epoch; the following Tree route reads it.
local ec11_packet, ec11_result = assert(tension_runner.run("i07 EC11", fake, {
    authority_instrument = "v3",
    router_mode = "tree",
    tree_test_override = true,
    legacy_shadow = false,
    work_mode = "plan",
    max_ticks = 1,
    packet_options = packet_options("i07-ec11"),
    edge_evidence = evidence("EC11"),
}))
assert_eq(ec11_result.edge_evidence.ledger_status, "valid", "EC11 ledger")
assert_eq(event_count(ec11_result.edge_credit.events, "authority_taint"), 1,
    "EC11 writes one monotonic taint")
local post_harness = assert(selection_by_authority(
    ec11_result.edge_credit.events,
    "tree"
))
assert_true(contains(post_harness.eligibility.reasons, "authority_tainted"),
    "post-harness Tree route reads taint")
assert_true(ec11_packet.status ~= "born", "EC11 executes real body tick")

-- The v3 physical report closes every real route exactly once.
local physical = totals(shadow_result.edge_evidence)
assert_eq(physical.selected, #shadow_result.routes + 1,
    "v3 selection count matches committed route attempts")
assert_eq(physical.committed, #shadow_result.routes + 1,
    "v3 commit count matches Packet routes")
assert_eq(physical.executed, #shadow_result.ticks,
    "v3 execution count matches completed ticks")
assert_eq(physical.failed, 0, "ordinary shadow life has no failure")
assert_eq(physical.pending, 1, "ordinary tick limit has one pending route")

-- Invalid epoch measurement is typed and has zero mass on the same body life.
local function matched_epoch_run(expected)
    return tension_runner.run("i07 invalid epoch masslessness", fake, {
        authority_instrument = "v3",
        expected_authority_epoch = expected,
        router_mode = "legacy",
        work_mode = "plan",
        max_ticks = 2,
        packet_options = packet_options("i07-invalid-epoch-pair"),
        edge_evidence = evidence("I07_INVALID_EPOCH"),
    })
end
local valid_packet, valid_result = assert(matched_epoch_run(nil))
local invalid_packet, invalid_result = assert(matched_epoch_run("malformed"))
assert_eq(invalid_result.authority_epoch, nil, "invalid epoch is absent")
assert_eq(invalid_result.authority_epoch_error.code,
    "invalid_authority_epoch_expectation", "invalid epoch is typed")
assert_eq(invalid_result.edge_evidence.ledger_status, "invalid",
    "invalid epoch invalidates measurement only")
local valid_projection = assert(edge_life_projection.capture(
    valid_packet,
    valid_result,
    nil,
    {life_id = "life:i07-valid-epoch"}
))
local invalid_projection = assert(edge_life_projection.capture(
    invalid_packet,
    invalid_result,
    nil,
    {life_id = "life:i07-invalid-epoch"}
))
local same_body, body_differences = edge_life_projection.same_observer_neutral(
    valid_projection,
    invalid_projection
)
assert_true(same_body, "invalid epoch changed Packet physics: "
    .. table.concat(body_differences or {}, ","))

local lied_packet, lied_err = tension_runner.run("i07 expected epoch lie", fake, {
    authority_instrument = "v3",
    expected_authority_epoch = {
        physics_epoch_id = "sha256:" .. string.rep("0", 64),
    },
    router_mode = "legacy",
    max_ticks = 0,
    packet_options = packet_options("i07-expected-lie"),
})
assert_eq(lied_packet, nil, "expected epoch lie is harness-fatal")
assert_eq(lied_err, "authority_instrument:authority_epoch_expectation_mismatch",
    "expected epoch lie stays loud")

print("test_edge_runner_v3 ok")
