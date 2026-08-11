package.path = "./?.lua;./?/init.lua;" .. package.path

local case_manifest = require("runtime.edge_case_manifest")
local edge_credit = require("runtime.edge_credit")
local edge_report = require("runtime.edge_current_report")
local json = require("core.json")
local campaign = require("tests.support.current_edge_campaign")

local function assert_true(value, message)
    if not value then error(message or "assertion failed", 2) end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": "
            .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
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

local function contains(values, expected)
    for _, value in ipairs(values or {}) do
        if value == expected then return true end
    end
    return false
end

local revision = "fixture:i10:current-report"
local first = campaign.build(revision)
local value = first.report

-- CR01: unlike epochs remain separate; their union cannot become a closure.
assert_true(edge_report.verify(value), "CR01 current report verifies")
assert_true(#value.epochs >= 4, "CR02 campaign preserves distinct epochs")
assert_true(contains(value.promotion_blockers, "cross_epoch_union_non_promotable"),
    "CR01 cross-epoch union is diagnostic only")
assert_eq(value.promotion_authorized, false, "CR01 report cannot promote")
for _, epoch in ipairs(value.epochs) do
    assert_eq(epoch.ledger_gate, "green", "CR01 ledger gate")
    assert_eq(epoch.provenance_gate, "green", "CR01 provenance gate")
    assert_eq(epoch.instrument_error_count, 0, "CR01 no hidden instrument error")
end

-- CR03: every owner vocabulary row is visible, including zero counts.
local reasons = edge_credit.eligibility_reason_ids()
assert_eq(#value.eligibility_reasons, #reasons,
    "CR03 eligibility vocabulary is complete")
for index, reason in ipairs(reasons) do
    assert_eq(value.eligibility_reasons[index].reason, reason,
        "CR03 reason order is canonical")
end
-- CR02: a named life does not turn a missing case green.
local current = case_manifest.current()
assert_eq(#value.case_status,
    #current.required_l0 + #current.required_l1,
    "CR04 every current case has a row")
assert_true(contains(value.promotion_blockers, "case_manifest_incomplete"),
    "CR04 missing cases remain an explicit blocker")

-- The diagnostic index names physical and eligible directions separately.
assert_true(#value.diagnostic_union.physical_directions > 0,
    "CR05 campaign observed physical movement")
assert_true(#value.diagnostic_union.eligible_directions > 0,
    "CR06 campaign observed eligible movement")
assert_true(#value.diagnostic_union.eligible_directions
        <= #value.diagnostic_union.physical_directions,
    "CR06 eligible movement is a subset of physical movement")

-- CR05/CR06: promotion and stale-digest tampering reject.
local promoted = copy_value(value)
promoted.promotion_authorized = true
assert_eq(edge_report.verify(promoted), nil,
    "CR05 report cannot be edited into promotion authority")

local omitted_reason = copy_value(value)
table.remove(omitted_reason.eligibility_reasons)
assert_eq(edge_report.verify(omitted_reason), nil,
    "CR03 zero-count reason rows cannot disappear")

local changed_epoch = copy_value(value)
changed_epoch.epochs[1].physical_direction_count =
    changed_epoch.epochs[1].physical_direction_count + 1
assert_eq(edge_report.verify(changed_epoch), nil,
    "CR06 epoch summary cannot be restamped")

-- CR10: the same immutable corpus and revision produce the same report identity.
local second = assert(edge_report.build(first.corpus, {
    implementation_revision = revision,
}))
assert_eq(second.report_id, value.report_id,
    "CR10 current report is deterministic")
assert_eq(json.encode(second), json.encode(value),
    "CR10 deterministic report has identical content")

print("test_edge_current_report ok")
