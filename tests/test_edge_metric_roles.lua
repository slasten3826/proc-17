package.path = "./?.lua;./?/init.lua;" .. package.path

local edge_stats = require("runtime.edge_stats")
local edge_stats_v2 = require("runtime.edge_stats_v2")
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
        max_ticks = 12,
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

assert_eq(shadow.edge_stats.protocol_version, "edge-stats.v3", "shadow uses v3")
assert_eq(tree.edge_stats.protocol_version, "edge-stats.v3", "tree uses v3")
assert_eq(assert(edge_stats.summary(tree.edge_stats)).protocol_version,
    "edge-stats.v3", "summary names its schema")

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
    assert_eq(stats.shadow_ticks, nil, "v3 has no ambiguous shadow tick aggregate")
    assert_eq(stats.agreement_count, nil, "v3 has no cross-observer agreement")
    assert_eq(stats.divergence_count, nil, "v3 has no cross-observer divergence")
    for _, rail in pairs(stats.rails or {}) do
        assert_eq(rail.debt_bypass_proposals, nil,
            "v3 has no role-changing flat rail counters")
        for channel_id, channel in pairs(rail.channels) do
            assert_channel_conservation(channel, rail.id .. "." .. channel_id)
        end
    end
end

-- Authority roles are separate evidence epochs. v3 refuses the old practice
-- of adding unlike shadow and Tree ledgers into one root aggregate.
local mixed = assert(edge_stats.summary(shadow.edge_stats))
local before_count = mixed.comparison_count
local merged, merge_err = edge_stats.merge(mixed, tree.edge_stats)
assert_eq(merged, nil, "unlike authority epochs cannot merge")
assert_eq(merge_err.code, "evidence_epoch_mismatch",
    "role boundary is an epoch fact")
assert_eq(mixed.comparison_count, before_count,
    "failed epoch merge leaves target untouched")
assert_true(edge_stats.verify(mixed), "failed epoch merge leaves valid ledger")

local protocol_target = assert(edge_stats.summary(shadow.edge_stats))
local accepted, protocol_err = edge_stats.merge(
    protocol_target,
    edge_stats_v2.new({kind = "historical_role_fixture"})
)
assert_eq(accepted, nil, "v2 role history cannot be laundered into v3")
assert_eq(protocol_err.code, "edge_stats_protocol_mismatch",
    "historical protocol error is typed")
assert_true(edge_stats.verify(protocol_target),
    "historical rejection leaves canonical ledger valid")

print("test_edge_metric_roles ok")
