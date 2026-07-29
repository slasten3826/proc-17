package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")
local budget = require("runtime.budget")
local execution = require("runtime.qa_execution")
local runner = require("runtime.tension_runner")
local fixture = require("tests.support.repository_hands")
local fixtures = require("tests.support.qa_hostile_fixtures")
local owned = require("tests.support.owned_temp_root")
local repeated = require("tests.support.qa_repeated_residue")
local support = require("tests.support.qa_provider_witness")

local observer_path = "./native/tests/proc17_qa_residue_observer.so"
local observer_symbol = "luaopen_proc17_qa_residue_observer"

local function load_observer()
    local loader, load_err = package.loadlib(observer_path, observer_symbol)
    assert(loader, "body residue observer load failed: " .. tostring(load_err))
    return assert(loader())
end

local fixture_by_id = {}
for _, item in ipairs(fixtures.items) do fixture_by_id[item.id] = item end

local function read_fixture(id)
    local item = assert(fixture_by_id[id], "unknown body fixture " .. tostring(id))
    local bytes = assert(fixtures.read(item))
    assert(bytes:sub(1, #fixtures.marker) == fixtures.marker)
    return bytes
end

local function event(instance, event_type)
    local found
    for _, candidate in ipairs(instance.trace or {}) do
        if candidate.type == event_type then
            assert(found == nil, "duplicate " .. event_type)
            found = candidate
        end
    end
    return assert(found, "missing " .. event_type)
end

local active_sentinel

local function run_campaign()
    assert(package.loaded["runtime.repository_provider"] == nil)
    assert(package.loaded["runtime.qa_provider"] == nil)
    local context = assert(support.open_campaign())
    local observer = load_observer()
    local observer_session = assert(observer.open())
    active_sentinel = assert(owned.create_sentinel())
    local sentinel = active_sentinel
    local baseline, baseline_projection = assert(observer.capture(
        observer_session, "baseline", nil))
    repeated.assert_clean_projection(baseline_projection, "baseline")

    local executed, matched = 0, 0
    for _, expected in ipairs(repeated.schedule()) do
        local body_weak = setmetatable({}, {__mode = "v"})
        local observer_weak = setmetatable({}, {__mode = "v"})
        local observer_subject
        local live_body_after_gc
        local live_observer_after_gc
        local bytes = read_fixture(expected.fixture_id)
        local body_ok, _, cleanup_ok = assert(
            support.with_body_candidate_in_campaign(
                context,
                bytes,
                function(grown)
                    local identity = assert(owned.identity(grown.root))
                    observer_subject = assert(observer.bind_owned_root(
                        observer_session, identity))
                    repeated.track(body_weak,
                        grown, grown.instance, grown.registry,
                        grown.qa_registry, grown.qa_environment_registry,
                        grown.body_services, grown.root)
                    repeated.track(observer_weak, observer_subject)

                    fixture.move_to(grown.instance, "☱")
                    fixture.move_to(grown.instance, "☶")
                    local before = budget.snapshot(grown.instance)
                    local instance, tick = assert(runner.execute_qa_tick(
                        grown.instance,
                        grown.body_services
                    ))
                    assert(tick.status == "applied")
                    local check = event(instance, "qa_check").payload
                    assert(check.outcome == expected.expected_outcome)
                    assert(check.reason == expected.expected_reason)
                    local after = budget.snapshot(instance)
                    assert((after.spent.steps or 0) - (before.spent.steps or 0) == 1)
                    assert((after.spent.tool_calls or 0)
                        - (before.spent.tool_calls or 0) == 1)
                    assert((after.spent.test_runs or 0)
                        - (before.spent.test_runs or 0) == 1)

                    local replay_before = budget.snapshot(instance)
                    local replay, replay_err = execution.execute(
                        instance,
                        grown.body_services
                    )
                    assert(replay, tostring(replay_err))
                    local replay_after = budget.snapshot(instance)
                    assert(replay_after.event_count == replay_before.event_count)
                    assert(#instance.trace > 0)
                    assert(owned.probe_sentinel(sentinel))

                    local iteration_snapshot, iteration_projection =
                        assert(observer.capture(
                            observer_session, "iteration", observer_subject))
                    repeated.track(observer_weak,
                        iteration_snapshot, iteration_projection)
                    repeated.assert_clean_projection(
                        iteration_projection, "iteration")
                    repeated.assert_zero_delta(assert(observer.compare(
                        baseline, iteration_snapshot)))
                    executed = executed + 1
                    matched = matched + 1
                    return true
                end,
                function(prior_identity)
                    assert(owned.absent(prior_identity))
                    assert(owned.probe_sentinel(sentinel))
                    repeated.collect_twice()
                    live_body_after_gc = repeated.live_count(body_weak)
                    assert(live_body_after_gc == 0,
                        "body campaign retained Packet-side objects")

                    local cleanup_snapshot, cleanup_projection =
                        assert(observer.capture(
                            observer_session, "post_cleanup", observer_subject))
                    repeated.track(observer_weak,
                        cleanup_snapshot, cleanup_projection)
                    repeated.assert_clean_projection(
                        cleanup_projection, "post_cleanup")
                    repeated.assert_zero_delta(assert(observer.compare(
                        baseline, cleanup_snapshot)))
                    observer_subject = nil
                    cleanup_snapshot = nil
                    cleanup_projection = nil
                    repeated.collect_twice()
                    live_observer_after_gc = repeated.live_count(observer_weak)
                    assert(live_observer_after_gc == 0,
                        "body campaign retained observer objects")
                    return true
                end
            )
        )
        assert(body_ok == true and cleanup_ok == true)
        assert(live_body_after_gc == 0 and live_observer_after_gc == 0)
    end

    assert(executed == repeated.iteration_count)
    assert(matched == repeated.iteration_count)
    repeated.collect_twice()
    assert(owned.probe_sentinel(sentinel))
    local final_snapshot, final_projection = assert(observer.capture(
        observer_session, "final", nil))
    repeated.assert_clean_projection(final_projection, "final")
    repeated.assert_zero_delta(assert(observer.compare(
        baseline, final_snapshot)))
    return {
        declared = repeated.iteration_count,
        executed = executed,
        matched = matched,
        residue = {
            fd = 0,
            process = 0,
            namespace = 0,
            mount = 0,
            root = 0,
            source = 0,
            memory_finality = 0,
            lua = 0,
            sentinel = 0,
            body = 0,
        },
    }
end

assert(owned.use_prebuilt_helper())
local ok, result = xpcall(run_campaign, debug.traceback)
if active_sentinel then
    local cleaned, cleanup_err = owned.cleanup_sentinel(active_sentinel)
    if not cleaned then
        error("body campaign sentinel cleanup failed: "
            .. tostring(cleanup_err), 0)
    end
end
if not ok then error(result, 0) end
print("PROC17_QA_BODY_RESIDUE_V0 " .. json.encode(result))
