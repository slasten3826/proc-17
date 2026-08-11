package.path = "./?.lua;./?/init.lua;" .. package.path

local json = require("core.json")
local campaign = require("tests.support.current_edge_campaign")

local revision = arg[1]
if type(revision) ~= "string" or revision == "" then
    error("usage: lua tests/run_current_edge_report.lua <implementation-revision> [--json]")
end

local result = campaign.build(revision)
local report = result.report

if arg[2] == "--json" then
    print(json.encode(report))
    return
end

local function direction_text(rows)
    local result = {}
    for _, row in ipairs(rows) do
        result[#result + 1] = row.direction
    end
    return #result > 0 and table.concat(result, ",") or "none"
end

print("protocol: " .. report.protocol_version)
print("report_id: " .. report.report_id)
print("source_revision: " .. report.source_revision)
print("authority_surface_id: " .. report.authority_surface_id)
print("case_manifest_id: " .. report.case_manifest_id)
print("observed_lives: " .. tostring(#report.observed_life_ids))
print("observed_epochs: " .. tostring(#report.epochs))
for index, epoch in ipairs(report.epochs) do
    print(table.concat({
        "epoch[" .. tostring(index) .. "]",
        "evidence=" .. epoch.evidence_epoch_id,
        "physics=" .. epoch.physics_epoch_id,
        "mode=" .. epoch.authority_epoch.configured.router_mode,
        "policy=" .. epoch.authority_epoch.physics.live_policy.routing_policy,
        "observer=" .. epoch.authority_epoch.instrumentation.observer_mode,
        "lives=" .. tostring(#epoch.life_ids),
        "physical=" .. tostring(epoch.physical_direction_count),
        "eligible=" .. tostring(epoch.eligible_direction_count),
        "observer_gate=" .. epoch.observer_gate,
        "l0_gate=" .. epoch.l0_case_gate,
        "l1_gate=" .. epoch.l1_case_gate,
        "closure=" .. epoch.closure_status,
    }, " "))
end
print("physical_union: "
    .. direction_text(report.diagnostic_union.physical_directions))
print("eligible_union: "
    .. direction_text(report.diagnostic_union.eligible_directions))
for _, row in ipairs(report.eligibility_reasons) do
    print("eligibility_reason: " .. row.reason .. "="
        .. tostring(row.observed_count))
end
for _, row in ipairs(report.case_status) do
    local counts = {green = 0, missing = 0, blocked = 0, red = 0}
    for _, status in ipairs(row.statuses) do
        counts[status.status] = counts[status.status] + 1
    end
    print(table.concat({
        "case: " .. row.case_id,
        "green=" .. tostring(counts.green),
        "missing=" .. tostring(counts.missing),
        "blocked=" .. tostring(counts.blocked),
        "red=" .. tostring(counts.red),
    }, " "))
end
print("promotion_authorized: false")
print("promotion_blockers: " .. table.concat(report.promotion_blockers, ","))
