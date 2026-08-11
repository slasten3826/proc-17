package.path = "./?.lua;./?/init.lua;" .. package.path

local canonical = require("runtime.edge_stats")
local fake = require("substrates.fake")
local tension_runner = require("runtime.tension_runner")

local function assert_true(value, message)
    if not value then error(message or "assertion failed", 2) end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function packet_options(label)
    return {
        id = "packet:i09:" .. label,
        lineage_id = "lineage:i09:" .. label,
        budget = {
            steps = 8,
            substrate_calls = 4,
            tool_calls = 4,
            encode_items = 4,
            loss = 4,
        },
    }
end

assert_eq(canonical.protocol_version, "edge-stats.v3",
    "I09 canonical facade is v3")
assert_eq(package.loaded["runtime.edge_stats_v2"], nil,
    "I09 live runner does not load historical v2")

local default_packet, default_result = assert(tension_runner.run(
    "i09 canonical default",
    fake,
    {
        router_mode = "legacy",
        work_mode = "plan",
        max_ticks = 0,
        packet_options = packet_options("default"),
        edge_evidence = {
            case_id = "I09_DEFAULT",
            corpus_layer = "unit",
            evidence_run_id = "run:i09:cutover",
        },
    }
))
assert_true(default_packet ~= nil, "I09 default grows a Packet")
assert_eq(default_result.authority_instrument, "v3",
    "I09 omitted option selects v3")
assert_eq(default_result.edge_stats.protocol_version, "edge-stats.v3",
    "I09 canonical mutable ledger is v3")
assert_eq(default_result.edge_evidence.protocol_version, "edge-stats.v3",
    "I09 canonical summary is v3")
assert_eq(default_result.edge_stats_v3, nil,
    "I09 temporary mutable alias is absent")
assert_eq(default_result.edge_evidence_v3, nil,
    "I09 temporary summary alias is absent")
assert_true(default_result.edge_credit ~= nil,
    "I09 canonical instrument retains credit ledger")

local explicit_packet, explicit_result = assert(tension_runner.run(
    "i09 explicit canonical",
    fake,
    {
        authority_instrument = "v3",
        router_mode = "legacy",
        work_mode = "plan",
        max_ticks = 0,
        packet_options = packet_options("explicit"),
    }
))
assert_true(explicit_packet ~= nil, "I09 explicit v3 remains accepted")
assert_eq(explicit_result.edge_stats.protocol_version, "edge-stats.v3",
    "I09 explicit v3 uses canonical namespace")

local denied_v2, denied_v2_err = tension_runner.run(
    "i09 denied historical v2",
    fake,
    {
        authority_instrument = "edge_stats_v2",
        packet_options = packet_options("denied-v2"),
    }
)
assert_eq(denied_v2, nil, "I09 live v2 option is rejected")
assert_eq(denied_v2_err,
    "birth_config:authority_instrument must be v3 or off",
    "I09 v2 rejection is explicit")

local off_packet, off_result = assert(tension_runner.run(
    "i09 permanent off ablation",
    fake,
    {
        authority_instrument = "off",
        authority_instrument_test_override = true,
        router_mode = "legacy",
        work_mode = "plan",
        max_ticks = 0,
        packet_options = packet_options("off"),
    }
))
assert_true(off_packet ~= nil, "I09 off ablation still grows the body")
assert_eq(off_result.edge_stats, nil, "I09 off writes no canonical ledger")
assert_eq(off_result.edge_evidence, nil, "I09 off writes no canonical summary")
assert_eq(off_result.edge_credit, nil, "I09 off writes no credit ledger")

local historical = require("runtime.edge_stats_v2")
assert_eq(historical.protocol_version, "edge-stats.v2",
    "I09 archaeology retains its own protocol")
local before = assert(canonical.summary(default_result.edge_stats))
local merged, merge_err = canonical.merge(
    default_result.edge_stats,
    historical.new({kind = "i09_archaeology"})
)
assert_eq(merged, nil, "I09 v2 cannot merge into v3")
assert_eq(merge_err.code, "edge_stats_protocol_mismatch",
    "I09 archaeology mismatch is typed")
assert_true(canonical.verify(default_result.edge_stats),
    "I09 rejected archaeology leaves canonical ledger valid")
assert_eq(canonical.summary(default_result.edge_stats).evidence_epoch_id,
    before.evidence_epoch_id,
    "I09 rejected archaeology leaves epoch unchanged")

print("test_edge_stats_cutover ok")
