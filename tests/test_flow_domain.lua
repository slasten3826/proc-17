package.path = "./?.lua;./?/init.lua;" .. package.path

local flow_domain = require("runtime.flow_domain")
local packet_birth = require("runtime.packet_birth")
local packet = require("core.packet")

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

local function birth_event(instance)
    for _, event in ipairs(instance.trace or {}) do
        if event.type == "birth" then
            return event
        end
    end
end

local source = {1, 2, 3, 4, 5, 6, 7, 8}
local domain = assert(flow_domain.new(source, {
    stream_id = "flow-domain-test",
    stream_epoch = 3,
    adapter_id = "fixture.small.v0",
    source_ref = "fixture:flow-domain",
}))
source[1] = 999

local initial = assert(flow_domain.snapshot(domain))
assert_eq(initial.birth_seq, 0, "new domain birth sequence")
assert_eq(initial.snapshot.tick, 0, "new domain L1 tick")
assert_eq(initial.snapshot.carry, 1, "domain owns initialized source")

local first, receipt = assert(packet_birth.create(domain, "first domain packet", {
    packet_options = {id = "flow-packet-1"},
}))
assert_eq(domain.birth_seq, 1, "first birth advances sequence")
assert_eq(domain.state.ticks, 1, "first birth advances L1 exactly once")
assert_eq(first.ingress.protocol_version, "packet.ingress.v0", "Packet ingress protocol")
assert_eq(first.ingress.flow_mark.birth_seq, 1, "Packet carries first mark")
assert_eq(receipt.flow_ref.stream_epoch, 3, "receipt carries stream epoch")
assert_eq(receipt.domain_event_ref, "flow-domain-test:3:birth:1", "deterministic birth event ref")
assert_eq(#domain.birth_events, 1, "domain records accepted birth")

local born = assert(birth_event(first))
assert_eq(born.payload.flow_mark.birth_seq, 1, "birth trace owns flow mark copy")
receipt.flow_mark.snapshot.fingerprint = -1
assert_true(first.ingress.flow_mark.snapshot.fingerprint ~= -1,
    "receipt cannot mutate Packet mark")
assert_true(domain.birth_events[1].snapshot.fingerprint ~= -1,
    "receipt cannot mutate domain event")

local before_failed = assert(flow_domain.snapshot(domain))
local invalid_graves, invalid_graves_err = packet_birth.create(domain, "invalid graves", {
    inherited_graves = "not-a-table",
})
assert_true(not invalid_graves, "invalid inherited graves reject before L1 transaction")
assert_eq(invalid_graves_err, "packet birth inherited_graves must be table",
    "invalid inherited graves error")
assert_eq(domain.birth_seq, before_failed.birth_seq,
    "invalid inherited graves do not consume birth sequence")
local failed, failed_err = packet_birth.create(domain, "invalid child", {
    packet_options = {generation = 2},
})
assert_true(not failed, "invalid Packet construction rejects birth")
assert_true(tostring(failed_err):find("lineage", 1, true) ~= nil,
    "birth construction failure remains visible")
local after_failed = assert(flow_domain.snapshot(domain))
assert_eq(after_failed.birth_seq, before_failed.birth_seq, "failed birth does not consume sequence")
assert_eq(after_failed.snapshot.tick, before_failed.snapshot.tick, "failed birth does not consume L1 tick")
assert_eq(after_failed.birth_event_count, before_failed.birth_event_count,
    "failed birth does not append domain event")
assert_true(not domain.busy, "failed birth clears serialization lock")

assert(packet.begin_terminal(first, {
    kind = "internal_death",
    cause = "cancelled",
    operator = "▽",
}))
local corpse = assert(packet.freeze(first, "cancelled", {cause = "cancelled"}))
assert_eq(corpse.flow_mark.birth_seq, 1, "corpse carries frozen birth mark")
corpse.flow_mark.birth_seq = 99
assert_eq(first.ingress.flow_mark.birth_seq, 1, "corpse mark cannot mutate Packet mark")
assert_eq(domain.status, "open", "Packet death does not freeze domain")

local second = assert(packet_birth.create(domain, "second domain packet", {
    packet_options = {id = "flow-packet-2"},
}))
assert_eq(second.ingress.flow_mark.birth_seq, 2, "second Packet gets new mark")
assert_eq(domain.birth_seq, 2, "domain continues across Packet death")
assert_eq(domain.state.ticks, 2, "domain L1 continues across Packet death")

local isolated = assert(flow_domain.new({1, 2, 3}, {
    stream_id = "isolated-domain",
    source_ref = "fixture:isolated",
}))
assert(packet_birth.create(isolated, "isolated packet"))
assert_eq(isolated.birth_seq, 1, "isolated domain advances itself")
assert_eq(domain.birth_seq, 2, "isolated domain cannot advance first domain")

assert(flow_domain.freeze(domain))
local frozen_birth, frozen_err = packet_birth.create(domain, "forbidden frozen birth")
assert_true(not frozen_birth, "frozen domain rejects birth")
assert_eq(frozen_err, "L1 flow domain is frozen", "frozen domain error")
assert_eq(domain.birth_seq, 2, "frozen rejection preserves sequence")

print("test_flow_domain ok")
