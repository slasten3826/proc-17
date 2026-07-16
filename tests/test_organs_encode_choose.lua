package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local body = require("runtime.body")
local encode_organ = require("organs.encode")
local choose_organ = require("organs.choose")

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

local function contains_secret(value)
    if type(value) == "string" then
        return value:find("do_not_encode", 1, true) ~= nil
    end
    if type(value) == "table" then
        for key, child in pairs(value) do
            if contains_secret(key) or contains_secret(child) then
                return true
            end
        end
    end
    return false
end

local p = packet.new("build notes app", {
    budget = {steps = 8, encode_items = 8},
    host = {secret = "do_not_encode"},
})

packet.append_chaos(p, {
    operator = "☴",
    text = "write files\nrun tests\nobserve results",
    truth_status = "semantic_proposal",
})

local encoded_packet, encoded_payload = encode_organ.run(p)
assert_true(encoded_packet, "encode organ should return packet")
assert_eq(encoded_payload.kind, "encode_organ_payload", "encode payload kind")
assert_eq(p.calm.current.kind, "encoded_field", "calm current kind")
assert_eq(p.calm.current.source_area, "chaos", "encode source area")
assert_eq(p.calm.current.source_refs[1], "chaos:fragment:1", "first source ref")
assert_eq(#p.calm.work_units, 3, "chaos fragment lines become units without raw prompt")
assert_eq(#p.boundary.crystallizations, 1, "crystallization stored")
assert_eq(#p.boundary.loss_records, 1, "loss stored")
assert_eq(#p.boundary.loss_records[1].loss.loss_log, 0, "non-truncated organ loss log empty")
assert_eq(encoded_payload.trace_event_id, p.boundary.crystallizations[1].trace_event_id, "encode keeps crystallization ref")
assert_eq(p.trace[#p.trace].type, "identity_map", "encode shadow identity map is trace-visible")
assert_eq(#p.field.unit_order, 3, "encode creates one canonical unit per encoded item")
assert_eq(#p.field.identity_maps, 1, "encode records one field identity map")
assert_eq(#encoded_payload.field_shadow.member_unit_ids, 3, "encode exposes canonical member refs")
assert_eq(p.calm.current.field_shadow.named_reader, "organs.choose", "shadow field names its reader")
assert_true(not contains_secret(p.calm.current), "encode must not encode substrate secret")

local limited = packet.new("limit encode", {
    budget = {steps = 8, encode_items = 2},
})
packet.append_chaos(limited, {
    operator = "☴",
    text = "a\nb\nc",
    truth_status = "semantic_proposal",
})
local limited_packet, limited_payload = encode_organ.run(limited)
assert_true(limited_packet, "limited encode organ should return packet")
assert_eq(#limited_payload.loss.loss_log, 1, "organ payload carries loss log")
assert_eq(#limited.boundary.loss_records[1].loss.loss_log, 1, "packet boundary stores loss log")
assert_eq(limited.calm.current.loss_log[1].content_preview, "c", "calm delta carries loss preview")

local before_units = p.calm.work_units
local chosen_packet, choice_payload = choose_organ.run(p, {
    limits = {max_selected = 1, max_killed_sample = 1},
    semantic_ranking = {
        truth_status = "semantic_proposal",
        items = {
            {id = "line:2", reason = "run tests first"},
        },
    },
})

assert_true(chosen_packet, "choose organ should return packet")
assert_eq(choice_payload.kind, "choose_collapse_payload", "choice payload kind")
assert_eq(choice_payload.selected[1].id, "line:2", "choice selected ranked item")
assert_eq(choice_payload.not_chosen_count, 2, "choice killed alternatives count")
assert_eq(#choice_payload.killed_alternatives, 1, "choice detail log remains bounded")
assert_eq(#choice_payload.suppressed_ids, 2, "choice retains every suppressed id")
assert_eq(#p.boundary.choices, 1, "choice stored in boundary")
assert_eq(p.trace[#p.trace].type, "choice", "choice trace event")
assert_true(p.calm.work_units == before_units, "choose must not rewrite work units")
assert_eq(choice_payload.field_shadow.status, "applied", "choice applies shadow activation")
local selected_unit_id = p.calm.current.field_shadow.legacy_to_unit_id["line:2"]
assert_eq(p.field.units[selected_unit_id].activation, "selected", "ranked canonical unit selected")
for _, legacy_id in ipairs({"line:1", "line:3"}) do
    local unit_id = p.calm.current.field_shadow.legacy_to_unit_id[legacy_id]
    assert_eq(p.field.units[unit_id].activation, "suppressed", "unchosen canonical unit suppressed")
end
assert_eq(choice_payload.can_continue, nil, "choose must not decide continuation")
assert_eq(choice_payload.next_action, nil, "choose must not choose next action")
assert_eq(p.death, nil, "choose must not kill packet")

local cycle_payload = body.decide_cycle(p, {
    cycle_key = "encode_choose",
    turn_count = 0,
    max_turns = 4,
    required_budget = {steps = 1},
})

assert_eq(cycle_payload.decision, "again", "cycle should see encode-created pending work")
assert_eq(cycle_payload.progress.needed_count, 3, "cycle needed from calm work")
assert_eq(cycle_payload.progress.remaining_count, 3, "cycle remaining from pending work")

print("test_organs_encode_choose ok")
