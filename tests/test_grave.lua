package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local grave = require("runtime.grave")

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

local missing, missing_err = grave.classify({packet_id = "no-death"})
assert_true(not missing, "missing death rejected")
assert_eq(missing_err, "grave classification requires death", "missing death error")

local identity = assert(grave.classify({
    packet_id = "identity",
    status = "dead",
    death = {cause = "identity_loss"},
    residue = {
        do_not_repeat = "packet coherence exhausted by loss",
        last_operator = "☳",
    },
}))
assert_eq(identity.grave_kind, "warning", "identity loss warning")
assert_eq(identity.warning.pattern.last_operator, "☳", "warning pattern operator")
assert_eq(identity.death_truth_status, "runtime_confirmed", "death truth")
assert_eq(identity.applicability_truth_status, "grave_pressure", "applicability pressure")

local warning = assert(grave.classify({
    packet_id = "loop",
    status = "dead",
    death = {cause = "budget_exhausted"},
    residue = {
        do_not_repeat = "loop consumed budget without progress",
        remaining_work_count = 3,
        last_operator = "☲",
    },
}))
assert_eq(warning.grave_kind, "warning", "budget no progress warning")
assert_eq(warning.warning.do_not_repeat, "loop consumed budget without progress", "warning do_not_repeat")
assert_eq(warning.warning.pattern.death_cause, "budget_exhausted", "warning death cause")

local bequest = assert(grave.classify({
    packet_id = "martyr",
    status = "dead",
    death = {cause = "budget_exhausted"},
    residue = {
        done_count = 2,
        remaining_work_count = 1,
        progress = {done_count = 2, remaining_count = 1},
    },
    trace_tail = {
        {operator = "☴"},
        {operator = "☵"},
    },
}))
assert_eq(bequest.grave_kind, "bequest", "budget with progress bequest")
assert_eq(bequest.bequest.remaining_work_count, 1, "bequest remaining work")
assert_eq(bequest.bequest.progress.done_count, 2, "bequest progress")
assert_eq(#bequest.bequest.trace_tail, 2, "bequest trace tail")

local nested_progress = assert(grave.classify({
    packet_id = "nested",
    death = {cause = "budget_exhausted"},
    residue = {
        progress = {done_count = 1, remaining_count = 4},
    },
}))
assert_eq(nested_progress.grave_kind, "bequest", "nested progress bequest")

local complete = assert(grave.classify({
    packet_id = "complete",
    status = "dead",
    death = {cause = "complete"},
    residue = {manifest_type = "code"},
}))
assert_eq(complete.grave_kind, "neutral", "complete neutral")
assert_eq(complete.warning, nil, "complete no warning")
assert_eq(complete.bequest, nil, "complete no bequest")

local cancelled = assert(grave.classify({
    packet_id = "cancelled",
    status = "dead",
    death = {cause = "cancelled"},
    residue = {},
}))
assert_eq(cancelled.grave_kind, "neutral", "plain cancelled neutral")

local cancelled_warning = assert(grave.classify({
    packet_id = "cancelled-warning",
    status = "dead",
    death = {cause = "cancelled"},
    residue = {do_not_repeat = "host guard ended unsafe loop"},
}))
assert_eq(cancelled_warning.grave_kind, "warning", "cancelled warning when residue says so")

local inherited = assert(grave.classify({
    kind = "inherited_packet_residue",
    source_packet_id = "parent",
    source_status = "dead",
    source_death = {cause = "identity_loss"},
    residue = {do_not_repeat = "identity loss"},
    trace_tail = {{operator = "☳"}},
}))
assert_eq(inherited.source_packet_id, "parent", "inherited source packet")
assert_eq(inherited.grave_kind, "warning", "inherited normalized")

local p = packet.new("packet instance", {id = "packet-grave"})
packet.die(p, "budget_exhausted", {
    cause = "budget_exhausted",
    completed_work_count = 1,
    remaining_work_count = 2,
})
local from_packet = assert(grave.classify(p))
assert_eq(from_packet.source_packet_id, "packet-grave", "packet source id")
assert_eq(from_packet.grave_kind, "bequest", "packet instance normalized")

local child = packet.new("grave attach child", {id = "grave-child"})
local attach_payload = assert(grave.attach(child, {
    {
        packet_id = "dead-loop",
        status = "dead",
        death = {cause = "budget_exhausted"},
        residue = {
            do_not_repeat = "loop consumed budget without progress",
            last_operator = "☲",
        },
    },
    {
        packet_id = "dead-progress",
        status = "dead",
        death = {cause = "budget_exhausted"},
        residue = {
            done_count = 1,
            remaining_work_count = 2,
            progress = {done_count = 1, remaining_count = 2},
        },
        trace_tail = {{operator = "☵"}},
    },
    {
        packet_id = "dead-complete",
        status = "dead",
        death = {cause = "complete"},
        residue = {},
    },
}))
assert_eq(attach_payload.kind, "grave_attach_payload", "attach payload kind")
assert_eq(attach_payload.attached_count, 3, "attach count")
assert_eq(attach_payload.warning_count, 1, "warning attach count")
assert_eq(attach_payload.bequest_count, 1, "bequest attach count")
assert_eq(attach_payload.neutral_count, 1, "neutral attach count")
assert_eq(attach_payload.truth_status, "runtime_confirmed", "attach truth")
assert_eq(#child.runtime.karma.warnings, 1, "warning attached to karma")
assert_eq(#child.runtime.karma.bequests, 1, "bequest attached to karma")
assert_eq(#child.runtime.karma.neutral, 1, "neutral attached to karma")
assert_eq(#child.chaos.unresolved_pressure, 1, "bequest creates chaos pressure")
assert_eq(child.chaos.unresolved_pressure[1].kind, "grave_bequest_pressure", "bequest pressure kind")
assert_eq(child.chaos.unresolved_pressure[1].source_packet_id, "dead-progress", "bequest pressure source")
assert_eq(child.chaos.unresolved_pressure[1].death_truth_status, "runtime_confirmed", "pressure death truth")
assert_eq(child.chaos.unresolved_pressure[1].applicability_truth_status, "grave_pressure", "pressure applicability")

local single_child = packet.new("single grave attach")
local single_attach = assert(grave.attach(single_child, {
    packet_id = "single-dead",
    status = "dead",
    death = {cause = "identity_loss"},
    residue = {do_not_repeat = "identity exhausted"},
}))
assert_eq(single_attach.attached_count, 1, "single attach count")
assert_eq(#single_child.runtime.karma.warnings, 1, "single warning attached")

local empty_child = packet.new("empty grave attach")
local empty_attach = assert(grave.attach(empty_child, {}))
assert_eq(empty_attach.attached_count, 0, "empty attach count")
assert_eq(#empty_child.runtime.karma.warnings, 0, "empty warning count")
assert_eq(#empty_child.chaos.unresolved_pressure, 0, "empty pressure count")

print("test_grave ok")
