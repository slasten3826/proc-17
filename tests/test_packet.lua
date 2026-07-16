package.path = "./?.lua;./?/init.lua;" .. package.path

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

local function assert_error(expected, callback, message)
    local ok, err = pcall(callback)
    assert_true(not ok, message or "expected error")
    assert_true(tostring(err):find(expected, 1, true) ~= nil,
        (message or "wrong error") .. ": " .. tostring(err))
end

local p = packet.new("build a small body", {id = "packet-test"})

assert_eq(p.protocol_version, "packet.next.v1", "protocol")
assert_eq(p.lineage_id, "packet-test", "standalone lineage defaults to packet id")
assert_eq(p.generation, 1, "standalone generation")
assert_eq(p.birth_kind, "user", "standalone birth kind")
assert_eq(p.parent_corpse_id, nil, "standalone has no parent corpse")
assert_eq(p.carrier_id, nil, "standalone has no carrier")
assert_eq(p.status, "born", "status")
assert_eq(p.operator, "▽", "operator")
assert_eq(p.chaos.raw_prompt, "build a small body", "dirty prompt in chaos")
assert_true(type(p.physis.budget) == "table", "physis budget exists")
assert_true(p.substrate == p.physis, "substrate compatibility alias points to physis")
assert_true(type(p.boundary.crystallizations) == "table", "boundary exists")
assert_true(type(p.calm.structures) == "table", "calm exists")
assert_true(type(p.tension) == "table", "tension exists")
assert_eq(p.revisions.potential, 0, "potential revision starts at zero")
assert_eq(p.revisions.relations_raw, 0, "raw relation revision starts at zero")
assert_eq(p.revisions.relations_active, 0, "active relation revision starts at zero")
assert_eq(p.revisions.momentum, 0, "momentum revision starts at zero")
assert_eq(p.revisions.calm, 0, "calm revision starts at zero")
assert_eq(p.revisions.constraints, 0, "constraint revision starts at zero")
assert_eq(p.revisions.evidence, 0, "evidence revision starts at zero")
assert_eq(p.revisions.history, 0, "history revision starts at zero")
assert_eq(p.revisions.scalars, 0, "scalar revision starts at zero")
assert_eq(p.revisions.budget, 0, "budget revision starts at zero")
assert_eq(p.revisions.loss, 0, "loss revision starts at zero")
assert_eq(p.field.protocol_version, "field.v0", "field protocol")
assert_eq(p.field.next_unit_id, 1, "first field unit id")
assert_eq(p.field.next_relation_id, 1, "first field relation id")
assert_eq(#p.field.unit_order, 0, "field starts without units")
assert_eq(p.field.relations.raw.epoch, 0, "raw relation epoch")
assert_eq(p.field.relations.raw.source_revision, 0, "raw relation source revision")
assert_eq(p.regime.cycle.phase, 0, "cycle phase starts at zero")
assert_true(type(p.regime.encoding.bounds) == "table", "encoding bounds exist")
assert_true(type(p.regime.choice.bounds) == "table", "choice bounds exist")
assert_eq(#p.trace, 1, "birth trace")
assert_eq(p.trace[1].type, "birth", "birth event")
assert_eq(p.trace[1].payload.lineage_id, "packet-test", "birth traces lineage")
assert_eq(p.trace[1].payload.generation, 1, "birth traces generation")
assert_eq(p.trace[1].payload.birth_kind, "user", "birth traces kind")

local child = packet.new("continue from carrier", {
    id = "packet-child",
    lineage_id = "lineage-test",
    generation = 2,
    parent_id = "packet-parent",
    parent_corpse_id = "corpse-parent",
    birth_kind = "network_reentry",
    carrier_id = "carrier-parent",
    substrate_session_id = "substrate-session-test",
})
assert_eq(child.lineage_id, "lineage-test", "child lineage")
assert_eq(child.generation, 2, "child generation")
assert_eq(child.parent_id, "packet-parent", "child parent packet")
assert_eq(child.parent_corpse_id, "corpse-parent", "child parent corpse")
assert_eq(child.birth_kind, "network_reentry", "child birth kind")
assert_eq(child.carrier_id, "carrier-parent", "child carrier")
assert_eq(child.substrate_session_id, "substrate-session-test", "child substrate session")
assert_eq(child.trace[1].payload.parent_corpse_id, "corpse-parent", "birth traces parent corpse")
assert_eq(child.trace[1].payload.carrier_id, "carrier-parent", "birth traces carrier")

assert_error("generation must be integer >= 1", function()
    packet.new("invalid generation", {generation = 0})
end, "zero generation rejected")
assert_error("generation > 1 requires lineage id", function()
    packet.new("missing lineage", {generation = 2, parent_corpse_id = "corpse"})
end, "lineage required for descendants")
assert_error("generation > 1 requires parent corpse id", function()
    packet.new("missing corpse", {generation = 2, lineage_id = "lineage"})
end, "parent corpse required for descendants")
assert_error("network_reentry birth requires carrier id", function()
    packet.new("missing carrier", {birth_kind = "network_reentry"})
end, "carrier required for reentry")
assert_error("user birth generation 1 cannot have parent corpse", function()
    packet.new("impossible parent", {parent_corpse_id = "corpse"})
end, "standalone user birth rejects parent corpse")

local isolated = packet.new("fresh mutable roots", {id = "packet-isolated"})
child.revisions.potential = 9
child.field.units["unit:1"] = {id = "unit:1"}
child.regime.encoding.bounds.max_units = 3
assert_eq(isolated.revisions.potential, 0, "revision vectors are not shared")
assert_eq(isolated.field.units["unit:1"], nil, "fields are not shared")
assert_eq(isolated.regime.encoding.bounds.max_units, nil, "regime bounds are not shared")

local moving = packet.new("move through the tree", {id = "packet-moving"})
local entry_route = assert(packet.commit_transition(moving, {
    from = "▽",
    to = "☴",
    reason = "test_entry",
}))
assert_eq(entry_route.type, "route", "route event type")
assert_eq(entry_route.payload.from, "▽", "route event source")
assert_eq(entry_route.payload.to, "☴", "route event target")
assert_eq(entry_route.operator, "☴", "route event stores committed position")
assert_eq(moving.operator, "☴", "valid route moves packet")
assert_eq(moving.status, "running", "first route starts packet life")
assert_eq(entry_route.packet_id, "packet-moving", "route event scopes packet")
assert_eq(entry_route.generation, 1, "route event scopes generation")

local tick_event = assert(packet.begin_tick(moving, "☴", {"chaos:raw_prompt"}))
assert_eq(tick_event.type, "operator_tick", "tick event type")
assert_eq(tick_event.operator, moving.operator, "tick agrees with packet position")

local position_before_invalid = moving.operator
local trace_before_invalid = #moving.trace
local wrong_source, wrong_source_err = packet.commit_transition(moving, {
    from = "☱",
    to = "△",
})
assert_true(not wrong_source, "route with stale source rejected")
assert_eq(wrong_source_err, "route source does not match packet position", "stale source reason")
assert_eq(moving.operator, position_before_invalid, "stale source does not move packet")
assert_eq(#moving.trace, trace_before_invalid, "stale source does not write trace")

local invalid_edge, invalid_edge_err = packet.commit_transition(moving, {
    from = "☴",
    to = "☲",
})
assert_true(not invalid_edge, "non-adjacent route rejected")
assert_eq(invalid_edge_err, "invalid operator transition", "invalid edge reason")
assert_eq(moving.operator, position_before_invalid, "invalid edge does not move packet")
assert_eq(#moving.trace, trace_before_invalid, "invalid edge does not write trace")

local return_to_flow, return_to_flow_err = packet.commit_transition(moving, {
    from = "☴",
    to = "▽",
})
assert_true(not return_to_flow, "living packet cannot return to flow")
assert_eq(return_to_flow_err, "living packet cannot return to flow", "flow return boundary reason")
assert_eq(moving.operator, position_before_invalid, "flow return does not move packet")
assert_eq(#moving.trace, trace_before_invalid, "flow return does not write trace")

local manifested = packet.new("manifest through terminal", {id = "packet-manifested"})
assert(packet.commit_transition(manifested, {from = "▽", to = "☴", reason = "entry"}))
assert(packet.commit_transition(manifested, {from = "☴", to = "☱", reason = "runtime_ready"}))
assert(packet.commit_transition(manifested, {from = "☱", to = "△", reason = "manifest_ready"}))
local manifested_packet, manifest_event, terminal_event = packet.manifest_packet(manifested, {
    output = {type = "text", content = "finished"},
    truth_status = "runtime_confirmed",
}, {
    cause = "complete",
    manifest_type = "text",
})
assert_true(manifested_packet, manifest_event)
assert_eq(manifest_event.type, "manifest", "manifest event preserved")
assert_eq(terminal_event.type, "terminal", "manifest writes terminal event")
assert_eq(manifested.status, "dead", "manifest terminal freezes packet")
assert_eq(manifested.operator, "△", "manifest corpse remains at boundary")
assert_eq(manifested.terminal.kind, "manifest", "manifest terminal kind")
assert_eq(manifested.terminal.cause, "complete", "manifest terminal cause")
assert_eq(manifested.terminal.manifest_ref, manifest_event.id, "terminal references manifest")
assert_eq(manifested.death.terminal_event_id, terminal_event.id, "death references terminal event")
assert_eq(manifested.trace[#manifested.trace].type, "terminal", "terminal seals manifest trace")

local ok, event = packet.append_chaos(p, {
    operator = "☴",
    kind = "substrate_fragment",
    text = "candidate structure",
})

assert_true(ok, "append chaos returns packet")
assert_eq(event.type, "chaos_append", "chaos append event")
assert_eq(#p.chaos.fragments, 1, "chaos fragment stored")
assert_eq(#p.trace, 2, "chaos append traced")

local bad, bad_err = packet.crystallize(p, {
    calm_delta = {kind = "work_shape"},
})

assert_true(not bad, "crystallization without loss must fail")
assert_eq(bad_err, "crystallization requires loss table", "loss required")

local crystal_packet, crystal_event = packet.crystallize(p, {
    source_chaos_refs = {event.id},
    calm_delta = {
        kind = "work_shape",
        units = {
            {id = "packet_core", status = "done"},
        },
    },
    loss = {
        kind = "compression",
        amount = 0.12,
    },
    status = "accepted",
})

assert_true(crystal_packet, "crystallization succeeds")
assert_eq(crystal_event.type, "crystallization", "crystallization event")
assert_eq(crystal_event.operator, "☵", "crystallization operator")
assert_eq(#p.boundary.crystallizations, 1, "boundary crystallization stored")
assert_eq(#p.boundary.loss_records, 1, "loss record stored")
assert_eq(#p.calm.structures, 1, "calm structure stored")
assert_eq(p.calm.current.kind, "work_shape", "current calm set")
assert_eq(p.calm.status, "accepted", "calm status")
assert_eq(p.revisions.calm, 1, "crystallization advances calm revision")

local tension_packet, tension_event = packet.measure_tension(p, {
    chaos_pressure = 7,
    calm_rigidity = 3,
    boundary_load = 2,
    unresolved_delta = 4,
    action_pressure = "hold",
})

assert_true(tension_packet, "tension measure succeeds")
assert_eq(tension_event.type, "tension_measure", "tension event")
assert_eq(p.tension.unresolved_delta, 4, "tension stored")

local dead, death_event = packet.die(p, "identity_loss", {
    cause = "identity_loss",
    do_not_repeat = "continue after semantic drift",
})

assert_true(dead, "death succeeds")
assert_eq(death_event.type, "death", "death event")
assert_eq(p.status, "dead", "dead status")
assert_eq(p.death.cause, "identity_loss", "death cause")
assert_eq(p.residue.do_not_repeat, "continue after semantic drift", "death residue")
assert_eq(p.terminal.kind, "internal_death", "internal death terminal kind")
assert_eq(p.terminal.cause, "identity_loss", "internal death terminal cause")
assert_eq(p.death.terminal_event_id, p.terminal.event_id, "death and terminal agree")
assert_eq(p.trace[#p.trace].type, "terminal", "terminal seals internal death trace")

local first_terminal_event_id = p.terminal.event_id
local second_death, second_death_err = packet.die(p, "budget_exhausted", {
    cause = "budget_exhausted",
    do_not_repeat = "overwrite first death",
})
assert_true(not second_death, "second death rejected")
assert_eq(second_death_err, "dead packet cannot die", "second death error")
assert_eq(p.death.cause, "identity_loss", "first death preserved")
assert_eq(p.residue.do_not_repeat, "continue after semantic drift", "first residue preserved")
assert_eq(p.terminal.event_id, first_terminal_event_id, "first terminal preserved")

local post_manifest, post_manifest_err = packet.manifest_packet(p, {
    output = {type = "text", content = "corpse output"},
})
assert_true(not post_manifest, "posthumous manifest rejected")
assert_eq(post_manifest_err, "dead packet cannot manifest", "posthumous manifest error")
assert_eq(p.status, "dead", "corpse stays dead")

local post_chaos, post_chaos_err = packet.append_chaos(p, {
    operator = "☴",
    kind = "posthumous",
})
assert_true(not post_chaos, "posthumous chaos rejected")
assert_eq(post_chaos_err, "dead packet cannot append chaos", "posthumous chaos error")

local post_crystal, post_crystal_err = packet.crystallize(p, {
    calm_delta = {kind = "posthumous"},
    loss = {kind = "posthumous", amount = 0.1},
})
assert_true(not post_crystal, "posthumous crystallization rejected")
assert_eq(post_crystal_err, "dead packet cannot crystallize", "posthumous crystallization error")

local post_tension, post_tension_err = packet.measure_tension(p, {
    chaos_pressure = 99,
})
assert_true(not post_tension, "posthumous tension rejected")
assert_eq(post_tension_err, "dead packet cannot measure tension", "posthumous tension error")

local trace_length_at_death = #p.trace
local post_trace, post_trace_err = packet.append_trace(p, {
    type = "cycle",
    operator = "☲",
    truth_status = "semantic_proposal",
    payload = {kind = "posthumous"},
})
assert_true(not post_trace, "posthumous trace rejected")
assert_eq(post_trace_err, "dead packet cannot append trace", "posthumous trace error")
assert_eq(#p.trace, trace_length_at_death, "ledger frozen after death")

print("test_packet ok")
