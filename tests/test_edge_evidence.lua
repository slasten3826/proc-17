package.path = "./?.lua;./?/init.lua;" .. package.path

local topology = require("core.topology")
local catalog = require("runtime.edge_catalog")
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
        error((message or "values differ") .. ": " .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local definitions = catalog.list()
assert_eq(#definitions, 22, "catalog contains every canonical Tree edge")
local unique = {}
for index, definition in ipairs(definitions) do
    assert_eq(definition.id, string.format("E%02d", index), "edge ids remain stable")
    assert_true(topology.is_adjacent(definition.left, definition.right), definition.id .. " must be canonical")
    assert_true(not unique[definition.edge], definition.id .. " duplicates a canonical edge")
    unique[definition.edge] = true
    if definition.left == "▽" or definition.right == "△" then
        assert_eq(#definition.directions, 1, definition.id .. " follows one-life boundary direction")
    else
        assert_eq(#definition.directions, 2, definition.id .. " keeps both internal directions")
    end
end

local function run(work_mode, max_ticks)
    return tension_runner.run("build notes app", fake, {
        work_mode = work_mode,
        router_mode = "shadow",
        max_ticks = max_ticks,
        packet_options = {
            budget = {steps = 32, substrate_calls = 8, encode_items = 8, loss = 10},
        },
        choose = {
            limits = {max_selected = 1, max_killed_sample = 8},
        },
    })
end

local plan_packet, plan = assert(run("plan", 8))
local build_packet, build = assert(run("build", 14))
assert_true(plan_packet ~= nil and build_packet ~= nil, "both grown lives complete their harness run")
assert_eq(plan.edge_stats_errors, nil, "plan evidence ledger has a reader for every record")
assert_eq(build.edge_stats_errors, nil, "build evidence ledger has a reader for every record")

local corpus = edge_stats.new({kind = "fake_plan_build_corpus"})
assert(edge_stats.merge(corpus, plan.edge_stats))
assert(edge_stats.merge(corpus, build.edge_stats))
local summary = assert(edge_stats.summary(corpus))

assert_eq(summary.edge_count, 22, "summary never drops unvisited edges")
for _, id in ipairs({"E03", "E09", "E10", "E17", "E18", "E20"}) do
    local edge = assert(catalog.get(id))
    assert_eq(corpus.edges[edge.edge].coverage, "complete", id .. " has grown all legal directions")
end
assert_eq(corpus.edges[assert(catalog.get("E11")).edge].coverage, "partial",
    "cross-eye edge currently has only one grown direction")
assert_eq(corpus.edges[assert(catalog.get("E01")).edge].coverage, "untested",
    "FLOW-CONNECT remains honestly untested, not inferred from candidate visibility")
assert_true(#summary.untested_ids > 0, "incomplete corpus exposes its missing edge ids")

local plan_cycle_edge = plan.edge_stats.edges[assert(catalog.get("E18")).edge]
assert_true(plan_cycle_edge.committed_count > plan_cycle_edge.executed_count,
    "the final committed route before tick_limit is not falsely counted as executed")

for _, id in ipairs({
    "rail.encode_observe",
    "rail.choose_observe",
    "rail.cycle_runtime",
    "rail.logic_runtime",
}) do
    local rail = corpus.rails[id]
    assert_true(rail.cases > 0, id .. " has at least one grown case")
    assert_eq(rail.promotion_status, "insufficient_evidence", id .. " cannot self-promote")
end

assert_eq(corpus.rails["rail.encode_observe"].eye_debt_cases, 0,
    "ENCODE does not make already covered semantic units unobserved")
assert_true(corpus.rails["rail.encode_observe"].fresh_direct_proposals > 0,
    "current shadow can bypass the upper eye when no semantic unit is uncovered")
assert_true(corpus.rails["rail.choose_observe"].debt_bypass_proposals > 0,
    "current shadow attempts an unresolved upper-eye bypass after CHOOSE")
assert_true(corpus.rails["rail.cycle_runtime"].eye_debt_cases > 0,
    "cycle consequence creates bounded runtime reconciliation debt")
assert_true(corpus.rails["rail.logic_runtime"].eye_debt_cases > 0,
    "logic consequence creates bounded runtime reconciliation debt")

local failure_source = edge_stats.new({kind = "failure_source"})
local failed_route = {from = "▽", to = "☴"}
assert(edge_stats.record_transition(failure_source, failed_route))
assert(edge_stats.record_failure(failure_source, failed_route, {
    kind = "effect_failure",
    code = "connection_lost",
}))
local failure_corpus = edge_stats.new({kind = "failure_corpus"})
assert(edge_stats.merge(failure_corpus, failure_source))
local failed_edge = failure_corpus.edges[assert(catalog.get("▽", "☴")).edge]
assert_eq(failed_edge.failed_count, 1, "corpus merge preserves failed arrivals")
assert_eq(failed_edge.executed_count, 0, "failed arrival is not executed evidence")
assert_eq(failed_edge.directions["▽->☴"].failure_kinds.connection_lost, 1,
    "corpus merge preserves typed failure kind")

print("test_edge_evidence ok")
