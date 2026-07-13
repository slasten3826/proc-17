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
assert_eq(#session.grave.bequests, 1, "bequest stored in session grave")

local neutral = assert(session_memory.add_grave(session, {
    packet_id = "dead-complete",
    status = "dead",
    death = {cause = "complete"},
    residue = {},
}))
assert_eq(neutral.grave_kind, "neutral", "neutral grave classified")
assert_eq(#session.grave.neutral, 1, "neutral stored in session grave")

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
