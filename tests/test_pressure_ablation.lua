package.path = "./?.lua;./?/init.lua;" .. package.path

local ablation = require("runtime.pressure_ablation")

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

local function contribution(kind, component)
    return {
        kind = kind,
        source_ref = "observation:lower:1",
        source_refs = {
            "observation:lower:1",
            component and ("revision:" .. component .. ":2") or "revision:calm:1",
        },
        current_operator = "☲",
        target_operator = "☱",
        target_edge = "☱-☲",
        direction = "help",
        amount = 1,
        reason = "test",
        changed_components = component and {
            {component = component, observed = 1, current = 2},
        } or {},
    }
end

local snapshot = {
    kind = "edge_pressure_snapshot",
    current_operator = "☲",
    derivation_version = "pressure.binary.v0",
    contributions = {
        contribution("runtime_mismatch"),
        contribution("lower_observation_debt", "budget"),
    },
}

local c0 = assert(ablation.apply(snapshot, "C0"))
assert_eq(#c0.contributions, 2, "C0 preserves every contribution")
assert_eq(#c0.ablation.removed, 0, "C0 removes nothing")

local a = assert(ablation.apply(snapshot, "A"))
assert_eq(#a.contributions, 1, "A removes duplicate runtime mismatch")
assert_eq(a.contributions[1].kind, "lower_observation_debt", "A keeps lower debt")

local b = assert(ablation.apply(snapshot, "B"))
assert_eq(#b.contributions, 1, "B removes budget-only lower debt")
assert_eq(b.contributions[1].kind, "runtime_mismatch", "B keeps mismatch")

local ab = assert(ablation.apply(snapshot, "AB"))
assert_eq(#ab.contributions, 0, "AB removes both degenerate sources")
assert_eq(#snapshot.contributions, 2, "ablation never mutates source snapshot")

local mixed = {
    kind = "edge_pressure_snapshot",
    current_operator = "☲",
    derivation_version = "pressure.binary.v0",
    contributions = {
        {
            kind = "lower_observation_debt",
            source_ref = "observation:lower:1",
            source_refs = {
                "observation:lower:1",
                "revision:budget:2",
                "revision:evidence:3",
            },
            current_operator = "☲",
            target_operator = "☱",
            target_edge = "☱-☲",
            direction = "help",
            amount = 1,
            changed_components = {
                {component = "budget", observed = 1, current = 2},
                {component = "evidence", observed = 2, current = 3},
            },
        },
    },
}

local mixed_b = assert(ablation.apply(mixed, "B"))
assert_eq(#mixed_b.contributions, 1, "B preserves debt with a meaningful component")
assert_eq(#mixed_b.contributions[1].changed_components, 1, "B removes only ignored components")
assert_eq(mixed_b.contributions[1].changed_components[1].component, "evidence",
    "evidence delta remains visible")
assert_eq(#mixed.contributions[1].changed_components, 2, "partial filtering keeps source immutable")

local shadow = {
    kind = "shadow_route_decision",
    current_operator = "☲",
    live_to = "☱",
    predicted_to = "☱",
    predicted_reason = "highest_positive_pressure",
    candidates = {
        {
            to = "☵",
            contributions = {},
            positive = 0,
            resistance = 0,
            total = 0,
            exclusions = {},
            excluded = false,
            readiness = {ready = true},
        },
        {
            to = "☱",
            contributions = snapshot.contributions,
            positive = 2,
            resistance = 0,
            total = 2,
            exclusions = {},
            excluded = false,
            readiness = {ready = true},
        },
    },
}

local c0_route = assert(ablation.reselect(shadow, "C0"))
assert_eq(c0_route.predicted_to, "☱", "C0 reproduces current winner")
local ab_route = assert(ablation.reselect(shadow, "AB"))
assert_eq(ab_route.predicted_to, nil, "AB exposes no positive pressure in synthetic case")
assert_true(ab_route.divergence:match("no_viable_edge") ~= nil,
    "counterfactual no-edge remains typed")
assert_eq(shadow.candidates[2].total, 2, "reselection never mutates source candidates")

local invalid, invalid_err = ablation.apply(snapshot, "unknown")
assert_eq(invalid, nil, "unknown profile rejected")
assert_true(type(invalid_err) == "string", "unknown profile explains rejection")

print("test_pressure_ablation ok")
