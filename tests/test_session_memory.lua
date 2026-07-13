package.path = "./?.lua;./?/init.lua;" .. package.path

local session_memory = require("runtime.session_memory")

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

local generated = assert(session_memory.create(nil, {label = "fresh"}))
assert_true(generated.session_id:match("^[%w%._%-]+$") ~= nil, "generated session id is safe")
assert_eq(generated.label, "fresh", "generated session label")
assert_eq(#generated.grave.warnings, 0, "generated warning grave empty")
assert_eq(#generated.grave.bequests, 0, "generated bequest grave empty")
assert_eq(#generated.grave.neutral, 0, "generated neutral grave empty")
assert_eq(#generated.compost.patterns, 0, "generated compost empty")
assert_eq(generated.compost.next_insert_id, 1, "generated compost insert id")

local session = assert(session_memory.create("session-grave-test", {
    label = "grave scope",
}))
assert_eq(session.kind, "proc17_session", "session kind")
assert_eq(session.protocol_version, "session.v0", "session protocol")
assert_eq(session.session_id, "session-grave-test", "session id")
assert_eq(#session.packet_ids, 0, "new session packet ids empty")
assert_eq(#session.grave.warnings, 0, "new session warning grave empty")

assert(session_memory.append_packet(session, "packet-a"))
assert(session_memory.append_packet(session, "packet-b"))
assert_eq(#session.packet_ids, 2, "packet ids appended")
assert_eq(session.current_packet_id, "packet-b", "current packet updated")

local warning = assert(session_memory.add_grave(session, {
    packet_id = "dead-loop",
    status = "dead",
    death = {cause = "budget_exhausted"},
    residue = {
        do_not_repeat = "loop consumed budget without progress",
        last_operator = "☲",
    },
}))
assert_eq(warning.grave_kind, "warning", "warning grave classified")
assert_eq(warning.grave_insert_id, 1, "warning insert id assigned")
assert_eq(#session.grave.warnings, 1, "warning stored in session grave")
assert_eq(#session.grave.bequests, 0, "warning not stored as bequest")

local bequest = assert(session_memory.add_grave(session, {
    packet_id = "dead-progress",
    status = "dead",
    death = {cause = "budget_exhausted"},
    residue = {
        done_count = 1,
        remaining_work_count = 2,
        progress = {done_count = 1, remaining_count = 2},
    },
}))
assert_eq(bequest.grave_kind, "bequest", "bequest grave classified")
assert_eq(bequest.grave_insert_id, 2, "bequest insert id assigned")
assert_eq(#session.grave.bequests, 1, "bequest stored in session grave")

local neutral = assert(session_memory.add_grave(session, {
    packet_id = "dead-complete",
    status = "dead",
    death = {cause = "complete"},
    residue = {},
}))
assert_eq(neutral.grave_kind, "neutral", "neutral grave classified")
assert_eq(neutral.grave_insert_id, 3, "neutral insert id assigned")
assert_eq(#session.grave.neutral, 1, "neutral stored in session grave")

local below = assert(session_memory.compost(session, {
    max_fresh_graves = 3,
    now = 100,
}))
assert_eq(below.kind, "session_compost_payload", "below compost payload")
assert_eq(below.composted_count, 0, "below limit no compost")
assert_eq(below.fresh_grave_count_before, 3, "below before count")
assert_eq(below.fresh_grave_count_after, 3, "below after count")
assert_eq(#session.compost.patterns, 0, "below no pattern")

local disabled, disabled_err = session_memory.inherit_graves(session)
assert_true(not disabled, "grave inheritance disabled by default")
assert_eq(disabled_err, "session grave inheritance is disabled", "disabled grave inheritance reason")

local inherited = assert(session_memory.inherit_graves(session, {enabled = true}))
assert_eq(#inherited, 3, "inherits only session graves")
assert_eq(inherited[1].grave_kind, "warning", "warning inherited first")
assert_eq(inherited[2].grave_kind, "bequest", "bequest inherited second")
assert_eq(inherited[3].grave_kind, "neutral", "neutral inherited third")

local other = assert(session_memory.create("session-grave-other"))
local other_inherited = assert(session_memory.inherit_graves(other, {enabled = true}))
assert_eq(#other_inherited, 0, "second session starts with empty grave")
assert_eq(#other.compost.patterns, 0, "second session compost remains empty")

local saved, path = assert(session_memory.save(session, {
    root = "sandbox/sessions",
}))
assert_eq(saved.session_id, "session-grave-test", "saved session id")
assert_eq(path, "sandbox/sessions/session-grave-test.json", "session save path")

local loaded = assert(session_memory.load("session-grave-test", {
    root = "sandbox/sessions",
}))
assert_eq(loaded.session_id, "session-grave-test", "loaded session id")
assert_eq(loaded.current_packet_id, "packet-b", "loaded current packet")
assert_eq(#loaded.grave.warnings, 1, "loaded warning grave")
assert_eq(#loaded.grave.bequests, 1, "loaded bequest grave")
assert_eq(#loaded.grave.neutral, 1, "loaded neutral grave")
assert_eq(#loaded.compost.patterns, 0, "loaded compost empty")
assert_eq(loaded.compost.next_insert_id, 4, "loaded compost insert id")

local compost_session = assert(session_memory.create("session-compost-test"))
assert(session_memory.add_grave(compost_session, {
    packet_id = "dead-loop-a",
    status = "dead",
    death = {cause = "budget_exhausted"},
    residue = {
        do_not_repeat = "loop consumed budget without progress",
        last_operator = "☱",
    },
}))
assert(session_memory.add_grave(compost_session, {
    packet_id = "dead-loop-b",
    status = "dead",
    death = {cause = "budget_exhausted"},
    residue = {
        do_not_repeat = "loop consumed budget without progress",
        last_operator = "☱",
    },
}))
assert(session_memory.add_grave(compost_session, {
    packet_id = "dead-progress",
    status = "dead",
    death = {cause = "budget_exhausted"},
    residue = {
        done_count = 1,
        remaining_work_count = 2,
        progress = {done_count = 1, remaining_count = 2},
        last_operator = "☱",
    },
}))
assert(session_memory.add_grave(compost_session, {
    packet_id = "dead-complete",
    status = "dead",
    death = {cause = "complete"},
    residue = {last_operator = "△"},
}))

local composted = assert(session_memory.compost(compost_session, {
    max_fresh_graves = 1,
    now = 200,
}))
assert_eq(composted.composted_count, 3, "over limit compost count")
assert_eq(composted.fresh_grave_count_before, 4, "over limit before count")
assert_eq(composted.fresh_grave_count_after, 1, "over limit after count")
assert_eq(#compost_session.grave.warnings, 0, "old warnings removed")
assert_eq(#compost_session.grave.bequests, 0, "old bequest removed")
assert_eq(#compost_session.grave.neutral, 1, "newest neutral remains fresh")
assert_eq(#compost_session.compost.patterns, 2, "same warning merged plus bequest pattern")

local warning_pattern = compost_session.compost.patterns[1]
assert_eq(warning_pattern.kind, "compost_pattern", "warning compost kind")
assert_eq(warning_pattern.grave_kind, "warning", "warning compost grave kind")
assert_eq(warning_pattern.death_cause, "budget_exhausted", "warning compost death")
assert_eq(warning_pattern.last_operator, "☱", "warning compost operator")
assert_eq(warning_pattern.do_not_repeat, "loop consumed budget without progress", "warning compost do_not_repeat")
assert_eq(warning_pattern.count, 2, "warning compost count merges")
assert_eq(warning_pattern.first_seen_at, 200, "warning first seen")
assert_eq(warning_pattern.last_seen_at, 200, "warning last seen")
assert_eq(warning_pattern.source_packet_id, nil, "compost drops packet id")
assert_eq(warning_pattern.trace_tail, nil, "compost drops trace")
assert_eq(warning_pattern.residue, nil, "compost drops residue")
assert_eq(warning_pattern.manifest, nil, "compost drops manifest")

local bequest_pattern = compost_session.compost.patterns[2]
assert_eq(bequest_pattern.grave_kind, "bequest", "bequest compost grave kind")
assert_eq(bequest_pattern.do_not_repeat, nil, "bequest compost no warning penalty")
assert_eq(bequest_pattern.count, 1, "bequest compost count")

local neutral_compost = assert(session_memory.compost(compost_session, {
    max_fresh_graves = 0,
    now = 300,
}))
assert_eq(neutral_compost.composted_count, 1, "neutral compost count")
assert_eq(neutral_compost.fresh_grave_count_after, 0, "neutral compost empties fresh")
assert_eq(#compost_session.compost.patterns, 3, "neutral pattern added")
assert_eq(compost_session.compost.patterns[3].grave_kind, "neutral", "neutral compost grave kind")

local old_shape = {
    kind = "proc17_session",
    protocol_version = "session.v0",
    session_id = "old-shape",
    created_at = 1,
    updated_at = 1,
    packet_ids = {},
    grave = {
        warnings = {},
        bequests = {},
        neutral = {},
    },
}
local old_saved = assert(session_memory.save(old_shape, {
    root = "sandbox/sessions",
}))
assert_eq(old_saved.compost.next_insert_id, 1, "old shape save ensures compost")
local old_loaded = assert(session_memory.load("old-shape", {
    root = "sandbox/sessions",
}))
assert_eq(old_loaded.compost.next_insert_id, 1, "old shape load ensures compost")
assert_eq(#old_loaded.compost.patterns, 0, "old shape load patterns empty")

local unsafe = session_memory.create("../bad")
assert_true(not unsafe, "unsafe session id rejected")

local bad_append, bad_append_err = session_memory.append_packet(session, "../bad")
assert_true(not bad_append, "unsafe packet id rejected in session")
assert_eq(bad_append_err, "packet id contains unsafe characters", "unsafe packet id reason")

local bad_root, bad_root_err = session_memory.save(session, {
    root = "docs/sessions",
})
assert_true(not bad_root, "non-sandbox session root rejected")
assert_eq(bad_root_err, "session memory root must be under sandbox", "bad session root reason")

print("test_session_memory ok")
