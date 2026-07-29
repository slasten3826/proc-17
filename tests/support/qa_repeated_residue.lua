local digest = require("core.digest")

local repeated = {}

repeated.protocol_version = "qa.repeated_residue_campaign.v0"
repeated.cycle_count = 8
repeated.iteration_count = 32
repeated.cycle = {
    {slot = "A", fixture_id = "candidate-clean-exit",
        outcome = "accepted", reason = "expected_exit"},
    {slot = "B", fixture_id = "candidate-lua-error",
        outcome = "rejected", reason = "unexpected_exit"},
    {slot = "C", fixture_id = "candidate-stdout-flood",
        outcome = "rejected", reason = "output_limit"},
    {slot = "D", fixture_id = "candidate-allocator-exhaustion",
        outcome = "rejected", reason = "memory_limit"},
}

repeated.campaign_id = "qa-qn20-campaign:" .. assert(digest.record({
    protocol_version = repeated.protocol_version,
    cycle_count = repeated.cycle_count,
    cycle = repeated.cycle,
}))

local zero_delta_fields = {
    "fd_opened", "fd_missing", "fd_identity_changed", "fd_flags_changed",
    "direct_live_children", "direct_zombies",
    "matching_supervisor_processes", "unresolved_supervisor_zombies",
    "qa_host_mounts", "owned_source_host_mounts",
    "owned_roots_added", "owned_roots_missing",
}

function repeated.schedule()
    local result = {}
    for cycle = 1, repeated.cycle_count do
        for _, item in ipairs(repeated.cycle) do
            result[#result + 1] = {
                iteration = #result + 1,
                cycle = cycle,
                slot = item.slot,
                fixture_id = item.fixture_id,
                expected_outcome = item.outcome,
                expected_reason = item.reason,
            }
        end
    end
    assert(#result == repeated.iteration_count)
    return result
end

function repeated.assert_clean_projection(projection, scope)
    assert(type(projection) == "table", "host projection required")
    assert(projection.protocol_version == "qa.residue_host_projection.v0")
    assert(projection.scope == scope)
    assert(projection.direct_live_child_count == 0)
    assert(projection.direct_zombie_count == 0)
    assert(projection.matching_supervisor_process_count == 0)
    assert(projection.unresolved_supervisor_zombie_count == 0)
    assert(projection.qa_host_mount_count == 0)
    if scope == "baseline" or scope == "final" or scope == "post_cleanup" then
        assert(projection.owned_root_count == 0)
    elseif scope == "iteration" then
        assert(projection.owned_root_count == 1)
    end
    assert(projection.event_truth_status == "runtime_confirmed")
    return true
end

function repeated.assert_zero_delta(delta)
    assert(type(delta) == "table", "host delta required")
    assert(delta.protocol_version == "qa.residue_host_delta.v0")
    assert(delta.exact == true, "host delta is not exact")
    assert(delta.parent_namespace_changed == false)
    for _, key in ipairs(zero_delta_fields) do
        assert(delta[key] == 0, key .. " residue is nonzero")
    end
    assert(delta.event_truth_status == "runtime_confirmed")
    return true
end

function repeated.track(weak, ...)
    local values = table.pack(...)
    for index = 1, values.n do
        assert(values[index] ~= nil, "cannot weak-track nil")
        weak[#weak + 1] = values[index]
    end
    return values.n
end

function repeated.live_count(weak)
    local count = 0
    for _ in pairs(weak) do count = count + 1 end
    return count
end

function repeated.collect_twice()
    collectgarbage("collect")
    collectgarbage("collect")
end

function repeated.body_root_digest(instance, root_projection)
    return "sha256:" .. assert(digest.record({
        status = instance.status,
        operator = instance.operator,
        current_tick = instance.current_tick,
        trace = instance.trace,
        revisions = instance.revisions,
        tension = instance.tension,
        death = instance.death,
        manifest = instance.manifest,
        runtime_budget = instance.runtime and instance.runtime.budget or nil,
        loss = instance.tension and instance.tension.loss or nil,
        root = root_projection,
    }))
end

function repeated.root_identity_id(identity)
    return "qa-root:" .. assert(digest.record(identity))
end

function repeated.report_id(report)
    return "qa-report:" .. assert(digest.record(report))
end

return repeated
