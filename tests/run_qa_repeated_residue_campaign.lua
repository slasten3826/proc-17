package.path = "./?.lua;./?/init.lua;" .. package.path

local digest = require("core.digest")
local capabilities = require("runtime.repository_capability")
local witness = require("runtime.qa_provider_witness")
local fixtures = require("tests.support.qa_hostile_fixtures")
local owned = require("tests.support.owned_temp_root")
local repeated = require("tests.support.qa_repeated_residue")
local support = require("tests.support.qa_provider_witness")

local observer_path = "./native/tests/proc17_qa_residue_observer.so"
local observer_symbol = "luaopen_proc17_qa_residue_observer"

local function load_observer()
    local loader, load_err = package.loadlib(observer_path, observer_symbol)
    assert(loader, "QN20 observer load failed: " .. tostring(load_err))
    local api = assert(loader())
    assert(api.protocol_version == "qa.residue_observer.lua54.v0")
    return api
end

local fixture_by_id = {}
for _, item in ipairs(fixtures.items) do fixture_by_id[item.id] = item end

local function read_fixture(id)
    local item = assert(fixture_by_id[id], "unknown QN20 fixture " .. tostring(id))
    assert(item.class == "candidate")
    local bytes = assert(fixtures.read(item))
    assert(bytes:sub(1, #fixtures.marker) == fixtures.marker,
        "QN20 fixture lost its inert marker")
    return bytes
end

local function finality_projection(report)
    local finality = assert(report.finality)
    local result = {}
    for _, key in ipairs({
        "source_staging_complete", "candidate_started",
        "candidate_terminal_observed", "process_tree_reaped",
        "stdout_eof_observed", "stderr_eof_observed",
        "scratch_observation_complete", "namespace_cleanup_complete",
    }) do
        assert(finality[key] == true, "QN20 finality missing " .. key)
        result[key] = true
    end
    return result
end

local function root_projection(grown, plan)
    return assert(capabilities.root_authority(grown.registry, {
        root_authority_id = plan.witness.root_authority_id,
    }))
end

local function frozen_context_digest(context)
    return assert(digest.record(assert(support.inspect_campaign(context))))
end

local active_sentinel

local function run_campaign()
    assert(package.loaded["runtime.repository_provider"] == nil,
        "repository provider was loaded before QN20")
    assert(package.loaded["runtime.qa_provider"] == nil,
        "QA provider was loaded before QN20")

    local context = assert(support.open_campaign())
    local context_digest = frozen_context_digest(context)
    local observer = load_observer()
    local observer_session = assert(observer.open())
    active_sentinel = assert(owned.create_sentinel())
    local sentinel = active_sentinel
    local baseline, baseline_projection = assert(observer.capture(
        observer_session, "baseline", nil))
    repeated.assert_clean_projection(baseline_projection, "baseline")

    local records = {}
    local roots_seen = {}
    local packets_seen = {}
    local transactions_seen = {}
    local accepted = 0
    local ordinary_rejected = 0
    local output_terminated = 0
    local memory_terminated = 0
    local replay_denials = 0
    local replay_launches = 0

    for _, expected in ipairs(repeated.schedule()) do
        assert(frozen_context_digest(context) == context_digest,
            "QN20 provider context drift before iteration")
        local body_weak = setmetatable({}, {__mode = "v"})
        local observer_weak = setmetatable({}, {__mode = "v"})
        local observer_subject
        local durable
        local tracked_body = 0
        local tracked_observer = 0
        local body_live_after_gc
        local observer_live_after_gc
        local post_cleanup_delta

        local bytes = read_fixture(expected.fixture_id)
        local body_ok, _, cleanup_ok = assert(support.with_candidate_in_campaign(
            context, bytes,
            function(grown)
                local identity = assert(owned.identity(grown.root))
                observer_subject = assert(observer.bind_owned_root(
                    observer_session, identity))
                local plan = assert(witness.prepare(grown.instance, grown.services))
                local root_before = root_projection(grown, plan)
                local body_before = repeated.body_root_digest(
                    grown.instance, root_before)
                tracked_body = repeated.track(body_weak,
                    grown, grown.instance, grown.registry, plan,
                    grown.services, grown.root)
                tracked_observer = repeated.track(
                    observer_weak, observer_subject)

                local report = assert(witness.execute(
                    grown.instance, grown.services, plan))
                tracked_body = tracked_body
                    + repeated.track(body_weak, report)
                assert(report.outcome == expected.expected_outcome,
                    expected.fixture_id .. " outcome mismatch")
                assert(report.reason == expected.expected_reason,
                    expected.fixture_id .. " reason mismatch")
                assert(report.source.stable == true)
                assert(report.source.disposition == "consumed")
                assert(report.source.pre_inventory_id
                    == report.source.post_inventory_id)

                local replay, replay_err = witness.execute(
                    grown.instance, grown.services, plan)
                assert(replay == nil, "QN20 source replayed")
                assert(type(replay_err) == "table"
                    and replay_err.code == "repository_qa_source_already_reserved",
                    "QN20 replay denial is not the reserve boundary: "
                        .. tostring(type(replay_err) == "table"
                            and replay_err.code or replay_err))
                replay_denials = replay_denials + 1

                local root_after = root_projection(grown, plan)
                local body_after = repeated.body_root_digest(
                    grown.instance, root_after)
                assert(body_after == body_before,
                    "QN20 witness changed Packet or public root")
                assert(owned.probe_sentinel(sentinel))

                local iteration_snapshot, iteration_projection =
                    assert(observer.capture(
                        observer_session, "iteration", observer_subject))
                tracked_observer = tracked_observer + repeated.track(
                    observer_weak, iteration_snapshot, iteration_projection)
                repeated.assert_clean_projection(
                    iteration_projection, "iteration")
                local iteration_delta = assert(observer.compare(
                    baseline, iteration_snapshot))
                repeated.assert_zero_delta(iteration_delta)

                local root_identity_id = repeated.root_identity_id(identity)
                assert(not roots_seen[root_identity_id],
                    "QN20 reused a root identity")
                assert(not packets_seen[grown.instance.id],
                    "QN20 reused a Packet identity")
                assert(not transactions_seen[plan.witness.transaction_id],
                    "QN20 reused a transaction identity")
                roots_seen[root_identity_id] = true
                packets_seen[grown.instance.id] = true
                transactions_seen[plan.witness.transaction_id] = true

                durable = {
                    protocol_version = "qa.repeated_residue_iteration.v0",
                    campaign_id = repeated.campaign_id,
                    iteration = expected.iteration,
                    cycle = expected.cycle,
                    slot = expected.slot,
                    fixture_id = expected.fixture_id,
                    packet_id = grown.instance.id,
                    lineage_id = grown.instance.lineage_id,
                    generation = grown.instance.generation,
                    root_identity_id = root_identity_id,
                    candidate_seal_id = grown.sealed.candidate_seal_id,
                    transaction_id = plan.witness.transaction_id,
                    expected_outcome = expected.expected_outcome,
                    observed_outcome = report.outcome,
                    expected_reason = expected.expected_reason,
                    observed_reason = report.reason,
                    report_id = repeated.report_id(report),
                    finality = finality_projection(report),
                    memory_finality =
                        "private_allocator_terminal_validated_and_owner_reaped",
                    source_disposition = "consumed",
                    source_replay = "denied_before_provider",
                    root_cleanup = nil,
                    sentinel_exact = true,
                    body_root_digest_before = body_before,
                    body_root_digest_after = body_after,
                    body_root_exact = true,
                    tracked_body_weak_objects = tracked_body,
                    live_body_weak_objects_after_gc = nil,
                    tracked_observer_weak_objects = nil,
                    live_observer_weak_objects_after_gc = nil,
                    post_transaction_host_delta = iteration_delta,
                    post_cleanup_host_delta = nil,
                    expectation_truth_status = "document_decision",
                    observation_truth_status = "runtime_confirmed",
                }
                return true
            end,
            function(prior_identity)
                assert(owned.absent(prior_identity))
                assert(owned.probe_sentinel(sentinel))
                repeated.collect_twice()
                body_live_after_gc = repeated.live_count(body_weak)
                assert(body_live_after_gc == 0,
                    "QN20 retained body/support objects")

                local cleanup_snapshot, cleanup_projection =
                    assert(observer.capture(observer_session,
                        "post_cleanup", observer_subject))
                tracked_observer = tracked_observer + repeated.track(
                    observer_weak, cleanup_snapshot, cleanup_projection)
                repeated.assert_clean_projection(
                    cleanup_projection, "post_cleanup")
                post_cleanup_delta = assert(observer.compare(
                    baseline, cleanup_snapshot))
                repeated.assert_zero_delta(post_cleanup_delta)

                observer_subject = nil
                cleanup_snapshot = nil
                cleanup_projection = nil
                repeated.collect_twice()
                observer_live_after_gc = repeated.live_count(observer_weak)
                assert(observer_live_after_gc == 0,
                    "QN20 retained observer objects")
                return true
            end))
        assert(body_ok == true and cleanup_ok == true)
        durable.root_cleanup = "identity_absent"
        durable.live_body_weak_objects_after_gc = body_live_after_gc
        durable.tracked_observer_weak_objects = tracked_observer
        durable.live_observer_weak_objects_after_gc = observer_live_after_gc
        durable.post_cleanup_host_delta = post_cleanup_delta
        records[#records + 1] = durable

        if durable.observed_outcome == "accepted" then accepted = accepted + 1 end
        if durable.observed_reason == "unexpected_exit" then
            ordinary_rejected = ordinary_rejected + 1
        elseif durable.observed_reason == "output_limit" then
            output_terminated = output_terminated + 1
        elseif durable.observed_reason == "memory_limit" then
            memory_terminated = memory_terminated + 1
        end
        assert(frozen_context_digest(context) == context_digest,
            "QN20 provider context drift after iteration")
    end

    assert(#records == 32)
    assert(accepted == 8 and ordinary_rejected == 8)
    assert(output_terminated == 8 and memory_terminated == 8)
    assert(replay_denials == 32 and replay_launches == 0)
    repeated.collect_twice()
    assert(owned.probe_sentinel(sentinel))
    local final_snapshot, final_projection = assert(observer.capture(
        observer_session, "final", nil))
    repeated.assert_clean_projection(final_projection, "final")
    local final_delta = assert(observer.compare(baseline, final_snapshot))
    repeated.assert_zero_delta(final_delta)
    assert(frozen_context_digest(context) == context_digest)

    return {
        declared = 32,
        executed = #records,
        matched = #records,
        accepted = accepted,
        ordinary_rejected = ordinary_rejected,
        output_terminated = output_terminated,
        memory_terminated = memory_terminated,
        replay_denials = replay_denials,
        replay_launches = replay_launches,
        final_snapshot_exact = final_delta.exact,
    }
end

assert(owned.use_prebuilt_helper())
local ok, result = xpcall(function()
    return run_campaign()
end, debug.traceback)
if active_sentinel then
    local cleaned, cleanup_err = owned.cleanup_sentinel(active_sentinel)
    if not cleaned then
        error("QN20 sentinel cleanup failed: " .. tostring(cleanup_err), 0)
    end
end
if not ok then error(result, 0) end

print(string.format(
    "proc17 QN20 residue campaign ok: declared=%d executed=%d matched=%d accepted=%d ordinary_rejected=%d output_terminated=%d memory_terminated=%d replay_denials=%d replay_launches=%d fd=0 process=0 namespace=0 mount=0 root=0 source=0 memory_finality=0 lua=0 sentinel=0 body=0",
    result.declared, result.executed, result.matched, result.accepted,
    result.ordinary_rejected, result.output_terminated,
    result.memory_terminated, result.replay_denials, result.replay_launches))
