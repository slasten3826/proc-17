package.path = "./?.lua;./?/init.lua;" .. package.path

local tension_runner = require("runtime.tension_runner")
local reconciliation = require("runtime.reconciliation")
local fake = require("substrates.fake")

local function route_text(result)
    local out = {}
    for _, route in ipairs(result.routes or {}) do
        out[#out + 1] = route.from .. route.to
    end
    return table.concat(out, "|")
end

local function contribution_count(result, kind)
    local count = 0
    for _, shadow in ipairs(result.shadow_routes or {}) do
        local seen = false
        for _, candidate in ipairs(shadow.candidates or {}) do
            for _, value in ipairs(candidate.contributions or {}) do
                if value.kind == kind then
                    seen = true
                end
            end
        end
        if seen then
            count = count + 1
        end
    end
    return count
end

local function run(mode, policy, max_ticks)
    return assert(tension_runner.run("build notes app", fake, {
        work_mode = mode,
        router_mode = "shadow",
        pressure_policy = policy,
        max_ticks = max_ticks,
        packet_options = {
            budget = {steps = 32, substrate_calls = 8, encode_items = 8, loss = 10},
        },
        choose = {
            limits = {max_selected = 1, max_killed_sample = 8},
        },
    }))
end

print("runtime camera L0/L1 treatment")
print("mode   live_equal  steps  calls  loss   L0(lower/mismatch)  L1(reconcile/lower/mismatch)  pending/significant")

for _, case in ipairs({
    {mode = "plan", max_ticks = 8},
    {mode = "build", max_ticks = 14},
}) do
    local l0_packet, l0 = run(case.mode, "sampled", case.max_ticks)
    local l1_packet, l1 = run(case.mode, "camera_reconciliation", case.max_ticks)
    local live_equal = route_text(l0) == route_text(l1)
    assert(live_equal, "shadow treatment cannot change live route")
    assert(l0_packet.runtime.budget.spent.steps == l1_packet.runtime.budget.spent.steps,
        "treatment cannot change body steps")
    assert(l0_packet.runtime.budget.spent.substrate_calls == l1_packet.runtime.budget.spent.substrate_calls,
        "treatment cannot change substrate calls")
    assert(l0_packet.tension.loss == l1_packet.tension.loss,
        "treatment cannot change identity loss")
    assert(l1_packet.runtime.camera.head_seq == #l1.ticks,
        "every completed tick receives one camera frame")

    local pending = assert(reconciliation.inspect(l1_packet))
    local l0_lower = contribution_count(l0, "lower_observation_debt")
    local l0_mismatch = contribution_count(l0, "runtime_mismatch")
    local l1_debt = contribution_count(l1, "runtime_reconciliation_debt")
    local l1_lower = contribution_count(l1, "lower_observation_debt")
    local l1_mismatch = contribution_count(l1, "runtime_mismatch")
    assert(l0_lower > 0 and l0_mismatch > 0, "L0 reproduces sampled defect")
    assert(l1_debt > 0, "L1 observes real unreconciled consequences")
    assert(l1_lower == 0, "L1 removes sampled lower pressure")
    assert(l1_mismatch == 0, "L1 removes duplicate mismatch")
    assert(pending.has_debt == false, "final RUNTIME frame does not self-recreate debt")

    print(string.format(
        "%-6s %-11s %-6d %-6d %-6.3f %2d/%-17d %2d/%d/%-20d %d/%d",
        case.mode,
        tostring(live_equal),
        l1_packet.runtime.budget.spent.steps or 0,
        l1_packet.runtime.budget.spent.substrate_calls or 0,
        l1_packet.tension.loss or 0,
        l0_lower,
        l0_mismatch,
        l1_debt,
        l1_lower,
        l1_mismatch,
        pending.pending_frame_count,
        pending.significant_frame_count
    ))
end

print("smoke_runtime_camera_treatment ok")
