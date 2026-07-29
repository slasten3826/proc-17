package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local evidence = require("runtime.qa_evidence")
local packet = require("core.packet")
local qa_request = require("runtime.qa_request")
local fixture = require("tests.support.qa_hand")

local suite = H.new("qa-request-body")

local function prepare(grown)
    return assert(qa_request.prepare(grown.instance, {
        qa_environment = grown.qa_environment,
    }))
end

suite:check("M2.1 request enters body through sole writer", function()
    local grown = fixture.grow_body({label = "qa-request-body-write"})
    local request = prepare(grown)
    local revision_before = grown.instance.revisions.evidence
    local stored, event = assert(evidence.record_request(grown.instance, request))
    H.assert_eq(stored.request_id, request.request_id, "body stores exact request")
    H.assert_eq(event.type, "qa_check_request", "dedicated event type")
    H.assert_eq(event.operator, "☶", "logic owns request fact")
    H.assert_eq(event.truth_status, "runtime_confirmed", "event truth is fixed")
    H.assert_eq(grown.instance.revisions.evidence, revision_before + 1,
        "Packet gate increments evidence once")
    local events = fixture.events(grown.instance, "qa_check_request")
    H.assert_eq(#events, 1, "one request event")
    for _, key in ipairs({
        "steps", "substrate_calls", "tool_calls",
        "file_writes", "test_runs", "loss",
    }) do
        H.assert_eq(events[1].cost[key], 0, "request has zero " .. key)
    end
    local found, found_event = assert(qa_request.find(
        grown.instance,
        request.request_id
    ))
    H.assert_eq(found.request_id, request.request_id, "reader finds body fact")
    H.assert_eq(found_event.id, event.id, "reader returns exact event")
end)

suite:check("M2.1 exact replay is idempotent and detached", function()
    local grown = fixture.grow_body({label = "qa-request-body-replay"})
    local request = prepare(grown)
    local first, first_event = assert(evidence.record_request(
        grown.instance,
        request
    ))
    local trace_count = #grown.instance.trace
    local revision = grown.instance.revisions.evidence
    first.request_id = "mutated"
    first_event.payload.request_id = "mutated"
    local second, second_event = assert(evidence.record_request(
        grown.instance,
        request
    ))
    H.assert_eq(#grown.instance.trace, trace_count, "replay appends nothing")
    H.assert_eq(grown.instance.revisions.evidence, revision,
        "replay increments no revision")
    H.assert_eq(second.request_id, request.request_id,
        "detached mutation changes no body fact")
    H.assert_eq(second_event.payload.request_id, request.request_id,
        "detached event mutation changes no trace")
end)

suite:check("M2.1 generic trace path cannot forge request", function()
    local grown = fixture.grow_body({label = "qa-request-generic-denial"})
    local request = prepare(grown)
    local before = fixture.snapshot(grown.instance)
    local event, err = packet.append_trace(grown.instance, {
        type = "qa_check_request",
        operator = "☶",
        truth_status = "runtime_confirmed",
        payload = request,
        cost = {},
    })
    H.assert_nil(event, "generic writer denied")
    H.assert_contains(err, "dedicated writer", "denial names dedicated path")
    H.assert_eq(#grown.instance.trace, before.trace_count, "trace unchanged")
    H.assert_eq(grown.instance.revisions.evidence, before.revisions.evidence,
        "evidence revision unchanged")
end)

suite:check("M2.1 actor and Packet coordinates are enforced", function()
    local owner = fixture.grow_body({label = "qa-request-owner"})
    local foreign = fixture.grow_body({label = "qa-request-foreign"})
    local request = prepare(owner)
    local foreign_before = fixture.snapshot(foreign.instance)
    local value, event, err = evidence.record_request(foreign.instance, request)
    H.assert_nil(value, "foreign request denied")
    H.assert_nil(event, "foreign request appends nothing")
    H.assert_true(err ~= nil, "foreign denial is loud")
    H.assert_eq(#foreign.instance.trace, foreign_before.trace_count,
        "foreign trace unchanged")

    fixture.move_to(owner.instance, "☱")
    local owner_before = fixture.snapshot(owner.instance)
    value, event, err = evidence.record_request(owner.instance, request)
    H.assert_nil(value, "wrong actor tick denied")
    H.assert_nil(event, "wrong actor appends nothing")
    H.assert_true(err ~= nil, "actor denial is loud")
    H.assert_eq(#owner.instance.trace, owner_before.trace_count,
        "owner trace unchanged")
end)

suite:check("M2.1 malformed and contradictory requests are inert", function()
    local grown = fixture.grow_body({label = "qa-request-malformed"})
    local request = prepare(grown)
    local malformed = fixture.copy(request)
    malformed.command = {"lua", "tests/run.lua"}
    local before = fixture.snapshot(grown.instance)
    local value, event, err = evidence.record_request(grown.instance, malformed)
    H.assert_nil(value, "unknown field denied")
    H.assert_nil(event, "malformed request appends nothing")
    H.assert_true(err ~= nil, "malformed denial is loud")

    assert(evidence.record_request(grown.instance, request))
    local changed = fixture.copy(request)
    changed.source_refs[#changed.source_refs + 1] = "fixture:changed"
    value, event, err = evidence.record_request(grown.instance, changed)
    H.assert_nil(value, "changed request denied")
    H.assert_nil(event, "changed request appends nothing")
    H.assert_true(err ~= nil, "changed request is loud")
    H.assert_eq(#fixture.events(grown.instance, "qa_check_request"), 1,
        "one canonical request remains")
    H.assert_eq(before.revisions.evidence + 1,
        grown.instance.revisions.evidence, "only canonical append has mass")
end)

suite:check("M2.1 replay refuses a corrupted stored envelope", function()
    local grown = fixture.grow_body({label = "qa-request-corrupt-trace"})
    local request = prepare(grown)
    assert(evidence.record_request(grown.instance, request))
    local request_events = fixture.events(grown.instance, "qa_check_request")
    H.assert_eq(#request_events, 1, "fixture grew one request")
    for _, event in ipairs(grown.instance.trace) do
        if event.type == "qa_check_request" then
            event.cost.forged_axis = 1
        end
    end
    local value, event, err = evidence.record_request(grown.instance, request)
    H.assert_nil(value, "corrupted replay returns no request")
    H.assert_nil(event, "corrupted replay appends no replacement")
    H.assert_true(err ~= nil, "trace corruption is loud")
    H.assert_eq(#fixture.events(grown.instance, "qa_check_request"), 1,
        "corruption is never healed by latest-wins")
end)

suite:check("M2.1 dead Packet cannot acquire QA evidence", function()
    local grown = fixture.grow_body({label = "qa-request-dead"})
    local request = prepare(grown)
    assert(packet.die(grown.instance, "cancelled", {cause = "cancelled"}))
    local revision = grown.instance.revisions.evidence
    local value, event, err = evidence.record_request(grown.instance, request)
    H.assert_nil(value, "corpse records no request")
    H.assert_nil(event, "corpse appends no event")
    H.assert_true(err ~= nil, "corpse denial is loud")
    H.assert_eq(grown.instance.status, "dead", "death remains final")
    H.assert_eq(grown.instance.revisions.evidence, revision,
        "corpse evidence revision is frozen")
end)

suite:check("M2.1 unimplemented QA payloads fail closed", function()
    local grown = fixture.grow_body({label = "qa-check-malformed-gate"})
    local event, err = packet.append_qa_event(grown.instance, {
        type = "qa_check",
        operator = "☶",
        truth_status = "runtime_confirmed",
        payload = {outcome = "accepted", exit_code = 9},
        cost = {},
    })
    H.assert_nil(event, "malformed trusted check rejected")
    H.assert_true(err ~= nil, "malformed trusted check is loud")
    H.assert_eq(grown.instance.status, "running", "loud invariant invents no death")
end)

suite:finish()
print("test_qa_request_body ok")
