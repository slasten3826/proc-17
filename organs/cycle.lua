local packet_core = require("core.packet")
local body = require("runtime.body")

local cycle_organ = {}

function cycle_organ.readiness(instance, options)
    options = options or {}
    local progress = body.progress(instance, {
        goal = options.goal,
        logic_status = options.logic_status,
    })
    local source_refs = {}
    for _, id in ipairs(progress.remaining or {}) do
        source_refs[#source_refs + 1] = "work:" .. tostring(id)
    end
    return {
        operator = "☲",
        ready = progress.needed_count > 0 or options.manifest_ready == true,
        reason = progress.needed_count > 0 and "ready" or "no_continuation_condition",
        source_refs = source_refs,
        required_capabilities = {},
        missing_capabilities = {},
        progress = progress,
        event_truth_status = "runtime_confirmed",
    }
end

function cycle_organ.run(instance, options)
    local mutable, mutable_err = packet_core.assert_mutable(instance, "run cycle")
    if not mutable then
        return nil, mutable_err
    end
    local payload, err = body.decide_cycle(instance, options or {})
    if not payload then
        return nil, err
    end
    return instance, payload
end

return cycle_organ
