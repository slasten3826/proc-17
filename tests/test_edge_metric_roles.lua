package.path = "./?.lua;./?/init.lua;" .. package.path

local edge_stats = require("runtime.edge_stats")
local tension_runner = require("runtime.tension_runner")
local fake = require("substrates.fake")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function run(mode)
    return tension_runner.run("build metric role witness", fake, {
        router_mode = mode,
        work_mode = "build",
        max_ticks = 64,
        packet_options = {
            budget = {
                steps = 64,
                substrate_calls = 16,
                tool_calls = 8,
                encode_items = 16,
                loss = 10,
            },
        },
        logic = {
            spells = {
                {
                    kind = "check_file_exists",
                    name = "README exists",
                    intention = "grow role-separated edge evidence",
                    path = "README.md",
                },
            },
        },
    })
end

local function rail_cases(stats, channel_id)
    local total = 0
    for _, rail in pairs(stats.rails or {}) do
        total = total + (rail.channels[channel_id].cases or 0)
    end
    return total
end

local function assert_channel_conservation(channel, message)
    assert_eq(channel.target_count + channel.no_target_count, channel.cases,
        message .. " target conservation")
    assert_eq(channel.eye_target_count + channel.debt_bypass_count
            + channel.fresh_direct_count,
        channel.target_count,
        message .. " target classification")
    assert_eq(channel.debt_eye_target_count + channel.fresh_eye_target_count,
        channel.eye_target_count,
        message .. " eye classification")
end

local _, shadow = assert(run("shadow"))
local _, tree = assert(run("tree"))

assert_eq(shadow.edge_stats.protocol_version, "edge-stats.v2", "shadow uses v2")
assert_eq(tree.edge_stats.protocol_version, "edge-stats.v2", "tree uses v2")
assert_eq(assert(edge_stats.summary(tree.edge_stats)).protocol_version,
    "edge-stats.v2", "summary names its schema")

assert_true(shadow.edge_stats.observers.tree.comparison_count > 0,
    "shadow life records tree observer")
assert_eq(shadow.edge_stats.observers.legacy.comparison_count, 0,
    "shadow life has no legacy observer")
assert_true(rail_cases(shadow.edge_stats, "tree_shadow") > 0,
    "shadow life records counterfactual rail predictions")
assert_eq(rail_cases(shadow.edge_stats, "tree_authority"), 0,
    "shadow life cannot create authority rail evidence")

assert_true(tree.edge_stats.observers.legacy.comparison_count > 0,
    "tree life records legacy observer")
assert_eq(tree.edge_stats.observers.tree.comparison_count, 0,
    "tree life has no tree observer comparison")
assert_true(rail_cases(tree.edge_stats, "tree_authority") > 0,
    "tree life records authoritative rail derivations")
assert_eq(rail_cases(tree.edge_stats, "tree_shadow"), 0,
    "legacy observer cannot create tree shadow rail evidence")

for _, stats in ipairs({shadow.edge_stats, tree.edge_stats}) do
    assert_eq(stats.shadow_ticks, nil, "v2 removes ambiguous shadow tick aggregate")
    assert_eq(stats.agreement_count, nil, "v2 removes cross-observer agreement")
    assert_eq(stats.divergence_count, nil, "v2 removes cross-observer divergence")
    for _, rail in pairs(stats.rails or {}) do
        assert_eq(rail.debt_bypass_proposals, nil,
            "v2 removes role-changing flat rail counters")
        for channel_id, channel in pairs(rail.channels) do
            assert_channel_conservation(channel, rail.id .. "." .. channel_id)
        end
    end
end

local mixed = edge_stats.new({kind = "mixed_authority_corpus"})
assert(edge_stats.merge(mixed, shadow.edge_stats))
assert(edge_stats.merge(mixed, tree.edge_stats))
assert_eq(mixed.comparison_count,
    shadow.edge_stats.comparison_count + tree.edge_stats.comparison_count,
    "root retains only neutral comparison total")
assert_eq(mixed.observers.tree.comparison_count,
    shadow.edge_stats.observers.tree.comparison_count,
    "tree observer history remains separate")
assert_eq(mixed.observers.legacy.comparison_count,
    tree.edge_stats.observers.legacy.comparison_count,
    "legacy observer history remains separate")
assert_eq(rail_cases(mixed, "tree_shadow"),
    rail_cases(shadow.edge_stats, "tree_shadow"),
    "mixed corpus preserves shadow rail channel")
assert_eq(rail_cases(mixed, "tree_authority"),
    rail_cases(tree.edge_stats, "tree_authority"),
    "mixed corpus preserves authority rail channel")

local old = edge_stats.new({kind = "old_protocol_fixture"})
old.protocol_version = "edge-stats.v1"
local target = edge_stats.new({kind = "protocol_guard"})
local merged, merge_err = edge_stats.merge(target, old)
assert_eq(merged, nil, "v1 cannot be laundered into v2")
assert_eq(merge_err, "edge statistics protocol mismatch", "protocol error is typed")
assert_eq(target.comparison_count, 0, "failed merge leaves target untouched")
local recorded, record_err = edge_stats.record_transition(old, {from = "▽", to = "☴"})
assert_eq(recorded, nil, "v1 ledger cannot receive v2 writes")
assert_eq(record_err, "edge statistics protocol mismatch", "writer version guard is typed")

local poisoned = edge_stats.new({kind = "observer_metadata_fixture"})
poisoned.observers.tree.observed_authority = "tree"
local clean = edge_stats.new({kind = "observer_metadata_guard"})
local accepted, observer_err = edge_stats.merge(clean, poisoned)
assert_eq(accepted, nil, "observer cannot silently change observed authority")
assert_true(tostring(observer_err):match("observer authority mismatch") ~= nil,
    "observer metadata error is explicit")

print("test_edge_metric_roles ok")
