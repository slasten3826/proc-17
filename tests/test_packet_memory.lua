package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local packet_memory = require("runtime.packet_memory")

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

local p = packet.new("remember failed route", {
    id = "packet-memory-test",
    lineage_id = "lineage-memory-test",
    generation = 2,
    parent_id = "packet-memory-parent",
    parent_corpse_id = "corpse-memory-parent",
    birth_kind = "network_reentry",
    carrier_id = "carrier-memory-parent",
    substrate_session_id = "substrate-memory-session",
})

assert(packet.commit_transition(p, {from = "▽", to = "☴", reason = "memory_chaos_fixture"}))
assert(packet.begin_tick(p, "☴", {}))
packet.append_chaos(p, {
    operator = "☴",
    text = "a\nb\nc",
    truth_status = "semantic_proposal",
})

assert(packet.commit_transition(p, {from = "☴", to = "☵", reason = "memory_crystal_fixture"}))
assert(packet.begin_tick(p, "☵", {}))
packet.crystallize(p, {
    source_chaos_refs = {"chaos:fragment:1"},
    calm_delta = {
        kind = "encoded_field",
        loss_log = {
            {
                kind = "omitted_item",
                reason = "max_items",
                content_preview = "c",
            },
        },
    },
    loss = {
        kind = "field_compression",
        amount = 1,
        loss_percentage = 0.6,
        loss_log = {
            {
                kind = "omitted_item",
                reason = "max_items",
                content_preview = "c",
            },
        },
    },
    status = "accepted",
})

assert(packet.commit_transition(p, {from = "☵", to = "☱", reason = "memory_test_runtime"}))
assert(packet.commit_transition(p, {from = "☱", to = "△", reason = "memory_test_manifest"}))
assert(packet.manifest_packet(p, {
    output = {
        type = "text",
        content = "do not repeat truncated encode",
    },
    truth_status = "runtime_confirmed",
}, {
    cause = "complete",
    do_not_repeat = "hide encode loss",
}))

local disabled_save, disabled_save_err = packet_memory.save(p, {
    root = "sandbox/packets",
})
assert_true(not disabled_save, "memory save disabled by default")
assert_eq(disabled_save_err, "packet memory is disabled", "disabled save reason")

local capsule, path = packet_memory.save(p, {
    enabled = true,
    root = "sandbox/packets",
    trace_tail_count = 4,
})

assert_true(capsule, "capsule saved")
assert_eq(capsule.kind, "packet_memory_capsule", "capsule kind")
assert_eq(capsule.packet_id, "packet-memory-test", "capsule packet id")
assert_eq(capsule.lineage_id, "lineage-memory-test", "capsule lineage id")
assert_eq(capsule.generation, 2, "capsule generation")
assert_eq(capsule.parent_corpse_id, "corpse-memory-parent", "capsule parent corpse")
assert_eq(capsule.birth_kind, "network_reentry", "capsule birth kind")
assert_eq(capsule.carrier_id, "carrier-memory-parent", "capsule carrier")
assert_eq(capsule.substrate_session_id, "substrate-memory-session", "capsule substrate session")
assert_eq(capsule.status, "dead", "capsule status")
assert_eq(capsule.terminal.kind, "manifest", "capsule terminal kind")
assert_eq(capsule.residue.do_not_repeat, "hide encode loss", "capsule residue")
assert_eq(#capsule.loss_records, 1, "capsule loss records")
assert_true(#capsule.trace_tail <= 4, "trace tail limit")
assert_eq(path, "sandbox/packets/packet-memory-test.json", "save path")

local loaded = assert(packet_memory.load("packet-memory-test", {
    enabled = true,
    root = "sandbox/packets",
}))
assert_eq(loaded.packet_id, capsule.packet_id, "loaded packet id")
assert_eq(loaded.residue.do_not_repeat, "hide encode loss", "loaded residue")

local disabled_inherit, disabled_inherit_err = packet_memory.inherit(loaded)
assert_true(not disabled_inherit, "inherit disabled by default")
assert_eq(disabled_inherit_err, "packet memory is disabled", "disabled inherit reason")

local inherited = assert(packet_memory.inherit(loaded, {enabled = true}))
assert_eq(inherited.kind, "inherited_packet_residue", "inherited kind")
assert_eq(inherited.source_packet_id, "packet-memory-test", "inherited source")
assert_eq(inherited.source_lineage_id, "lineage-memory-test", "inherited source lineage")
assert_eq(inherited.source_generation, 2, "inherited source generation")
assert_eq(inherited.source_parent_corpse_id, "corpse-memory-parent", "inherited source parent corpse")
assert_eq(inherited.truth_status, "runtime_confirmed", "inherited truth")
assert_eq(inherited.residue.do_not_repeat, "hide encode loss", "inherited residue")

local child = packet.new("try again with memory", {
    id = "packet-memory-child",
    parent_id = loaded.packet_id,
    memory_enabled = true,
    inherited_residue = {inherited},
})
assert_eq(child.parent_id, "packet-memory-test", "child parent")
assert_eq(child.runtime.memory.enabled, true, "child memory enabled")
assert_eq(#child.runtime.memory.inherited_residue, 1, "child inherited at birth")
assert_eq(child.trace[1].payload.inherited_residue_count, 1, "birth traces inherited count")

local disabled_child = packet.new("disabled memory ignores inheritance", {
    id = "packet-memory-disabled-child",
    inherited_residue = {inherited},
})
assert_eq(disabled_child.runtime.memory.enabled, false, "memory disabled by default")
assert_eq(#disabled_child.runtime.memory.inherited_residue, 0, "disabled packet ignores inherited residue")

local attached_child = packet.new("attach later", {id = "packet-memory-attached"})
local disabled_attach, disabled_attach_err = packet_memory.attach(attached_child, inherited)
assert_true(not disabled_attach, "attach disabled by default")
assert_eq(disabled_attach_err, "packet memory is disabled", "disabled attach reason")

assert(packet_memory.attach(attached_child, inherited, {enabled = true}))
assert_eq(attached_child.runtime.memory.enabled, true, "attach enables memory")
assert_eq(#attached_child.runtime.memory.inherited_residue, 1, "attached inherited")

local bad_save, bad_save_err = packet_memory.save(packet.new("bad", {id = "../bad"}), {
    enabled = true,
    root = "sandbox/packets",
})
assert_true(not bad_save, "unsafe packet id rejected")
assert_eq(bad_save_err, "packet id contains unsafe characters", "unsafe id reason")

local bad_root, bad_root_err = packet_memory.save(p, {
    enabled = true,
    root = "docs/packets",
})
assert_true(not bad_root, "non-sandbox root rejected")
assert_eq(bad_root_err, "packet memory root must be under sandbox", "bad root reason")

print("test_packet_memory ok")
