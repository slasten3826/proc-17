package.path = "./?.lua;./?/init.lua;" .. package.path

local authority_epoch = require("runtime.authority_epoch")
local edge_credit = require("runtime.edge_credit")
local edge_stats = require("runtime.edge_stats")
local json = require("core.json")

local function assert_true(value, message)
    if not value then error(message or "assertion failed", 2) end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function assert_same(left, right, message)
    assert_eq(json.encode(left), json.encode(right), message)
end

local function copy_value(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[copy_value(key, seen)] = copy_value(child, seen)
    end
    return result
end

local epoch, epoch_err = authority_epoch.resolve({
    router_mode = "legacy",
    pressure_policy = "qualified_need_v0",
})
assert_true(epoch ~= nil, epoch_err and epoch_err.code or epoch_err)

local life, life_err = edge_stats.make_life_source({
    packet_id = "packet:runtime-recorder",
    lineage_id = "lineage:runtime-recorder",
    generation = 1,
    session_id = "session:runtime-recorder",
    work_mode = "plan",
    case_id = "ER01",
    corpus_layer = "unit",
    evidence_run_id = "run:runtime-recorder",
    model = "fixture",
    prompt_hash = "sha256:" .. string.rep("a", 64),
})
assert_true(life ~= nil, life_err and life_err.code or life_err)

local identity = {
    life_id = life.life_id,
    packet_id = life.packet_id,
    lineage_id = life.lineage_id,
    generation = life.generation,
}
local decision = {
    kind = "route_decision",
    from = "▽",
    to = "☴",
    authority = "legacy_control",
    reason = "runtime_recorder_equivalence",
    truth_status = "runtime_confirmed",
}
local route_event = {
    id = "trace:runtime-recorder:route:1",
    type = "route",
    operator = "☴",
    truth_status = "runtime_confirmed",
    payload = {
        kind = "route_decision",
        from = "▽",
        to = "☴",
        authority = "legacy_control",
    },
}

-- ER01: runner-owned credit appends produce the same closed state as the
-- strict copy-and-verify transactions.
local strict_credit = assert(edge_credit.new(epoch, identity))
local runtime_credit = assert(edge_credit.new_runtime(epoch, identity))
local public_runtime_write, public_runtime_err = edge_credit.runtime_prepare(
    strict_credit,
    decision,
    {route_ordinal = 1}
)
assert_eq(public_runtime_write, nil,
    "public credit state cannot enter runtime fast path")
assert_eq(public_runtime_err.code, "runtime_credit_state_unavailable",
    "public credit fast-path denial is typed")
local strict_selection = assert(edge_credit.prepare(
    strict_credit,
    decision,
    {route_ordinal = 1}
))
local runtime_selection = assert(edge_credit.runtime_prepare(
    runtime_credit,
    decision,
    {route_ordinal = 1}
))
assert_same(runtime_selection, strict_selection,
    "runtime selection equals strict selection")

local strict_commit = assert(edge_credit.record_commit(
    strict_credit,
    strict_selection,
    route_event
))
local runtime_commit = assert(edge_credit.runtime_record_commit(
    runtime_credit,
    runtime_selection,
    route_event
))
assert_same(runtime_commit, strict_commit,
    "runtime commit equals strict commit")

local strict_pending = assert(edge_credit.record_pending(
    strict_credit,
    strict_commit,
    {stop_reason = "tick_limit"}
))
local runtime_pending = assert(edge_credit.runtime_record_pending(
    runtime_credit,
    runtime_commit,
    {stop_reason = "tick_limit"}
))
assert_same(runtime_pending, strict_pending,
    "runtime pending equals strict pending")
assert(edge_credit.finish_runtime(runtime_credit))
assert_same(runtime_credit, strict_credit,
    "closed runtime credit equals strict credit")

local replayed, replayed_err = edge_credit.runtime_prepare(
    runtime_credit,
    decision,
    {route_ordinal = 2}
)
assert_eq(replayed, nil, "closed credit state rejects new writes")
assert_eq(replayed_err.code, "runtime_credit_state_unavailable",
    "closed credit rejection is typed")

-- ER02: a rejected runtime credit operation rolls back its append tail.
local rejected_credit = assert(edge_credit.new_runtime(epoch, identity))
local bad_decision = copy_value(decision)
bad_decision.to = "not-an-operator"
local rejected, rejected_err = edge_credit.runtime_prepare(
    rejected_credit,
    bad_decision,
    {route_ordinal = 1}
)
assert_eq(rejected, nil, "invalid runtime selection rejects")
assert_eq(rejected_err.code, "route_outside_authority_surface",
    "invalid runtime selection is typed")
assert_eq(#rejected_credit.events, 0,
    "rejected runtime selection leaves no event tail")
assert(edge_credit.finish_runtime(rejected_credit))

local function source_bundle(record)
    return {
        life_id = life.life_id,
        records = {
            {
                source_kind = "packet_trace",
                original_source_id = record.id,
                source_record = record,
            },
        },
    }
end

-- ER03: deferred statistics construction is byte-equivalent to public strict
-- transactions and detaches queued source records immediately.
local strict_stats = assert(edge_stats.new(epoch, life))
local recorder = assert(edge_stats.begin_runtime(epoch, life))
assert_eq(next(recorder), nil,
    "runtime recorder exposes no pending observation state")
assert(edge_stats.record_selection(strict_stats, strict_selection))
assert(edge_stats.runtime_record_selection(recorder, runtime_selection))

local strict_route_source = copy_value(route_event)
assert(edge_stats.record_transition(
    strict_stats,
    strict_commit,
    source_bundle(strict_route_source)
))
assert(edge_stats.runtime_record_transition(
    recorder,
    runtime_commit,
    source_bundle(route_event)
))
route_event.payload.to = "mutated-after-queue"

assert(edge_stats.record_pending(strict_stats, strict_pending))
assert(edge_stats.runtime_record_pending(recorder, runtime_pending))
local runtime_stats, runtime_summary = assert(edge_stats.finish_runtime(recorder))
assert_same(runtime_stats, strict_stats,
    "runtime recorder ledger equals strict ledger")
assert_same(runtime_summary, assert(edge_stats.summary(strict_stats)),
    "runtime recorder summary equals strict summary")

local queued_after_close, queued_after_close_err =
    edge_stats.runtime_record_pending(recorder, runtime_pending)
assert_eq(queued_after_close, nil, "closed recorder rejects observations")
assert_eq(queued_after_close_err.code, "runtime_recorder_unavailable",
    "closed recorder rejection is typed")

-- ER04: an invalid queued observation becomes typed instrument evidence and
-- cannot leave a partially captured source or counter behind.
local rejected_recorder = assert(edge_stats.begin_runtime(epoch, life))
assert(edge_stats.runtime_record_observer(
    rejected_recorder,
    {kind = "invalid_observer"},
    source_bundle(strict_route_source)
))
local rejected_stats = assert(edge_stats.finish_runtime(rejected_recorder))
assert_eq(rejected_stats.ledger_status, "invalid",
    "rejected runtime observation invalidates only the instrument")
assert_eq(rejected_stats.errors[1].code, "observer_record_invalid",
    "rejected observation records exact error")
assert_eq(rejected_stats.source_usage.record_count, 0,
    "rejected observation captures no partial source")
assert_eq(rejected_stats.comparison_count, 0,
    "rejected observation increments no counter")
assert_true(edge_stats.verify(rejected_stats),
    "invalid instrument ledger remains structurally valid")

print("test_edge_runtime_recorder ok")
