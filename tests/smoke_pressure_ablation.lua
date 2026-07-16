package.path = "./?.lua;./?/init.lua;" .. package.path

local ablation = require("runtime.pressure_ablation")
local catalog = require("runtime.edge_catalog")
local tension_runner = require("runtime.tension_runner")
local fake = require("substrates.fake")

local profiles = ablation.profiles
local rail_target = {
    ["☵"] = "☴",
    ["☳"] = "☴",
    ["☲"] = "☱",
    ["☶"] = "☱",
}

local function run_life(work_mode, max_ticks)
    local packet, result = tension_runner.run("build notes app", fake, {
        work_mode = work_mode,
        router_mode = "shadow",
        pressure_policy = "sampled",
        max_ticks = max_ticks,
        packet_options = {
            budget = {steps = 32, substrate_calls = 8, encode_items = 8, loss = 10},
        },
        choose = {
            limits = {max_selected = 1, max_killed_sample = 8},
        },
    })
    assert(packet, result and result.message or result)
    assert(result.edge_stats_errors == nil, "edge statistics reader failed")
    return result
end

local function new_report(profile)
    return {
        profile = profile,
        ticks = 0,
        agreement = 0,
        divergence = 0,
        no_edge = 0,
        removed_contributions = 0,
        removed_components = 0,
        predictions = {},
        contribution_ticks = {},
        selected_edges = {},
        selected_directions = {},
        rails = {},
        normal_manifest_cases = 0,
        normal_manifest_predictions = {},
    }
end

local reports = {}
for _, profile in ipairs(profiles) do
    reports[profile] = new_report(profile)
end

local function note_contributions(report, decision)
    local present = {}
    for _, candidate in ipairs(decision.candidates or {}) do
        for _, contribution in ipairs(candidate.contributions or {}) do
            present[contribution.kind] = true
        end
    end
    for kind in pairs(present) do
        report.contribution_ticks[kind] = (report.contribution_ticks[kind] or 0) + 1
    end
end

local function note_removals(report, decision)
    report.removed_contributions = report.removed_contributions + #(decision.removed or {})
    for _, removal in ipairs(decision.removed or {}) do
        report.removed_components = report.removed_components
            + #(removal.removed_components or {})
    end
end

local function note_rail(report, from, predicted)
    local eye = rail_target[from]
    if not eye then
        return
    end
    local rail = report.rails[from]
    if not rail then
        rail = {cases = 0, recall = 0, bypass = 0, no_edge = 0}
        report.rails[from] = rail
    end
    rail.cases = rail.cases + 1
    if predicted == eye then
        rail.recall = rail.recall + 1
    elseif predicted == nil then
        rail.no_edge = rail.no_edge + 1
    else
        rail.bypass = rail.bypass + 1
    end
end

local rows = {}
for _, life in ipairs({
    {mode = "plan", result = run_life("plan", 8)},
    {mode = "build", result = run_life("build", 14)},
}) do
    assert(#life.result.shadow_routes == #life.result.routes,
        "every live route must have one shadow decision")
    for index, shadow in ipairs(life.result.shadow_routes) do
        assert(shadow.predicted_reason ~= "prediction_error", "C0 shadow prediction failed")
        local live = life.result.routes[index]
        local row = {
            mode = life.mode,
            tick = index,
            from = shadow.current_operator,
            live_to = live.to,
            live_reason = live.reason,
            predictions = {},
            lower_components = {},
        }
        local lower_seen = {}
        for _, candidate in ipairs(shadow.candidates or {}) do
            for _, contribution in ipairs(candidate.contributions or {}) do
                if contribution.kind == "lower_observation_debt" then
                    if #(contribution.changed_components or {}) == 0 then
                        lower_seen[contribution.freshness or "missing"] = true
                    end
                    for _, changed in ipairs(contribution.changed_components or {}) do
                        lower_seen[changed.component] = true
                    end
                end
            end
        end
        for component in pairs(lower_seen) do
            row.lower_components[#row.lower_components + 1] = component
        end
        table.sort(row.lower_components)
        for _, profile in ipairs(profiles) do
            local decision = assert(ablation.reselect(shadow, profile))
            local report = reports[profile]
            report.ticks = report.ticks + 1
            row.predictions[profile] = decision.predicted_to or "-"
            local prediction_key = decision.predicted_to or "none"
            report.predictions[prediction_key] = (report.predictions[prediction_key] or 0) + 1
            if decision.agreement then
                report.agreement = report.agreement + 1
            else
                report.divergence = report.divergence + 1
            end
            if decision.predicted_to == nil then
                report.no_edge = report.no_edge + 1
            else
                local edge = assert(catalog.get(decision.current_operator, decision.predicted_to))
                report.selected_edges[edge.id] = (report.selected_edges[edge.id] or 0) + 1
                local direction = decision.current_operator .. "->" .. decision.predicted_to
                report.selected_directions[direction] =
                    (report.selected_directions[direction] or 0) + 1
            end
            note_contributions(report, decision)
            note_removals(report, decision)
            note_rail(report, decision.current_operator, decision.predicted_to)
            if live.reason == "logic_stamp_no_new_evidence" then
                report.normal_manifest_cases = report.normal_manifest_cases + 1
                report.normal_manifest_predictions[prediction_key] =
                    (report.normal_manifest_predictions[prediction_key] or 0) + 1
            end
            if profile == "C0" then
                assert(decision.predicted_to == shadow.predicted_to,
                    "C0 counterfactual must reproduce recorded shadow")
            end
        end
        rows[#rows + 1] = row
    end
end

print("pressure ablation per-tick routes")
print("mode  tick  from  live(reason)                         C0  A   B   AB  lower_delta")
for _, row in ipairs(rows) do
    print(string.format(
        "%-5s %-5d %-5s %-4s %-35s %-3s %-3s %-3s %-3s %s",
        row.mode,
        row.tick,
        row.from,
        row.live_to,
        row.live_reason,
        row.predictions.C0,
        row.predictions.A,
        row.predictions.B,
        row.predictions.AB,
        #row.lower_components > 0 and table.concat(row.lower_components, ",") or "-"
    ))
end

local function count(map, key)
    return map[key] or 0
end

print("\npressure ablation summaries")
for _, profile in ipairs(profiles) do
    local report = reports[profile]
    print(string.format(
        "%s ticks=%d agree=%d diverge=%d no_edge=%d removed=%d components=%d E05=%d E12=%d E15=%d",
        profile,
        report.ticks,
        report.agreement,
        report.divergence,
        report.no_edge,
        report.removed_contributions,
        report.removed_components,
        count(report.selected_edges, "E05"),
        count(report.selected_edges, "E12"),
        count(report.selected_edges, "E15")
    ))
    for _, from in ipairs({"☵", "☳", "☲", "☶"}) do
        local rail = report.rails[from] or {cases = 0, recall = 0, bypass = 0, no_edge = 0}
        print(string.format(
            "  rail %s cases=%d recall=%d bypass=%d no_edge=%d",
            from,
            rail.cases,
            rail.recall,
            rail.bypass,
            rail.no_edge
        ))
    end
    local manifest = report.normal_manifest_predictions
    print(string.format(
        "  normal_manifest cases=%d predicted_triangle=%d predicted_encode=%d predicted_none=%d",
        report.normal_manifest_cases,
        count(manifest, "△"),
        count(manifest, "☵"),
        count(manifest, "none")
    ))
    print(string.format(
        "  contribution_ticks runtime_mismatch=%d lower_eye=%d upper_eye=%d",
        count(report.contribution_ticks, "runtime_mismatch"),
        count(report.contribution_ticks, "lower_observation_debt"),
        count(report.contribution_ticks, "upper_observation_debt")
    ))
    print(string.format(
        "  directions ☴->☰=%d ☵->☱=%d ☱->☵=%d ☳->☱=%d ☱->☳=%d ☱->△=%d",
        count(report.selected_directions, "☴->☰"),
        count(report.selected_directions, "☵->☱"),
        count(report.selected_directions, "☱->☵"),
        count(report.selected_directions, "☳->☱"),
        count(report.selected_directions, "☱->☳"),
        count(report.selected_directions, "☱->△")
    ))
end

assert(reports.C0.agreement > 0, "control corpus must contain current shadow agreements")
assert(reports.A.agreement == 0, "removing duplicate mismatch must expose zero legacy agreement")
assert(count(reports.C0.selected_directions, "☵->☱") > 0,
    "C0 must expose ENCODE to RUNTIME selections")
assert(count(reports.A.selected_directions, "☵->☱") == 0,
    "A must remove ENCODE to RUNTIME duplicate-mismatch selections")
assert(count(reports.C0.selected_directions, "☳->☱") > 0,
    "C0 must expose CHOOSE to RUNTIME selections")
assert(count(reports.A.selected_directions, "☳->☱") == 0,
    "A must remove CHOOSE to RUNTIME duplicate-mismatch selections")
assert(count(reports.A.selected_directions, "☱->☵") > 0,
    "A must preserve reverse RUNTIME to ENCODE pressure")
assert(count(reports.A.selected_edges, "E05") > count(reports.C0.selected_edges, "E05"),
    "removing mismatch must expose more canonical CONNECT tie-break selections")
assert(reports.A.rails["☲"].recall == 0 and reports.A.rails["☶"].recall == 0,
    "A must remove both apparent lower-rail recalls")
for _, profile in ipairs(profiles) do
    assert(count(reports[profile].normal_manifest_predictions, "△") == 0,
        profile .. " must retain the diagnosed normal-manifest gap")
end

print("smoke_pressure_ablation ok")
