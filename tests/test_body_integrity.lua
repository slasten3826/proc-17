package.path = "./?.lua;./?/init.lua;" .. package.path

local packet = require("core.packet")
local body = require("runtime.body")
local budget = require("runtime.budget")
local loss = require("runtime.loss")
local field = require("runtime.field")
local flow = require("organs.flow")
local foundation = require("runtime.foundation")
local freshness = require("runtime.freshness")
local pressure = require("runtime.pressure")
local spells = require("logic.spells")
local grave = require("runtime.grave")
local packet_memory = require("runtime.packet_memory")
local session_memory = require("runtime.session_memory")

local failures = {}

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

local function check(name, callback)
    local ok, err = pcall(callback)
    if not ok then
        failures[#failures + 1] = name .. ": " .. tostring(err)
    end
end

local function route(instance, target, with_tick)
    local event, err = packet.commit_transition(instance, {
        from = instance.operator,
        to = target,
        reason = "body_integrity_fixture",
    })
    assert_true(event, err)
    if with_tick ~= false then
        local tick, tick_err = packet.begin_tick(instance, target, {})
        assert_true(tick, tick_err)
        return tick
    end
    return event
end

local function write_file(path, content)
    local file = assert(io.open(path, "w"))
    file:write(content)
    file:close()
end

check("I01-I04 caller fragment and returned event isolation", function()
    local instance = packet.new("alias-safe chaos")
    route(instance, "☴")
    local fragment = {
        operator = "☴",
        kind = "integrity_probe",
        nested = {value = "before"},
    }
    local _, event = assert(packet.append_chaos(instance, fragment))
    fragment.nested.value = "caller-after"
    assert_eq(instance.chaos.fragments[1].nested.value, "before",
        "caller cannot mutate stored CHAOS")
    event.payload.nested.value = "returned-after"
    assert_eq(instance.trace[#instance.trace].payload.nested.value, "before",
        "returned event cannot mutate trace")
end)

check("I02 crystallization projections are independent", function()
    local instance = packet.new("alias-safe crystallization")
    route(instance, "☴")
    route(instance, "☵")
    local record = {
        calm_delta = {
            kind = "integrity_form",
            units = {{id = "unit-a", status = "pending"}},
            work_units = {{id = "work-a", status = "pending"}},
        },
        loss = {kind = "integrity_loss", amount = 0.1, detail = {value = "before"}},
    }
    assert(packet.crystallize(instance, record))
    record.calm_delta.units[1].status = "caller-after"
    record.loss.detail.value = "caller-after"
    assert_eq(instance.boundary.crystallizations[1].calm_delta.units[1].status, "pending",
        "caller cannot rewrite crystallization history")
    assert_eq(instance.boundary.loss_records[1].loss.detail.value, "before",
        "caller cannot rewrite loss history")

    instance.calm.current.units[1].status = "current-after"
    assert_eq(instance.boundary.crystallizations[1].calm_delta.units[1].status, "pending",
        "current CALM cannot rewrite crystallization history")
    assert_eq(instance.calm.structures[1].units[1].status, "pending",
        "current CALM cannot rewrite structural history")
end)

check("I03 corpse and caller residue isolation", function()
    local instance = packet.new("alias-safe corpse")
    local residue = {cause = "cancelled", nested = {value = "before"}}
    assert(packet.begin_terminal(instance, {
        kind = "internal_death",
        cause = "cancelled",
        operator = "▽",
    }))
    local corpse = assert(packet.freeze(instance, "cancelled", residue))
    residue.nested.value = "caller-after"
    assert_eq(instance.residue.nested.value, "before", "caller cannot mutate Packet residue")
    corpse.residue.nested.value = "corpse-after"
    assert_eq(instance.residue.nested.value, "before", "corpse projection cannot mutate Packet residue")
end)

check("I01-I04 extended body boundaries own inputs", function()
    local options = {
        metadata = {nested = {value = "before"}},
        host = {nested = {value = "before"}},
        sandbox = {nested = {value = "before"}},
        memory_enabled = true,
        inherited_residue = {{nested = {value = "before"}}},
    }
    local born = packet.new("owned birth options", options)
    options.metadata.nested.value = "caller-after"
    options.host.nested.value = "caller-after"
    options.sandbox.nested.value = "caller-after"
    options.inherited_residue[1].nested.value = "caller-after"
    assert_eq(born.metadata.nested.value, "before", "Packet owns metadata")
    assert_eq(born.physis.host.nested.value, "before", "Packet owns host options")
    assert_eq(born.physis.sandbox.nested.value, "before", "Packet owns sandbox options")
    assert_eq(born.runtime.memory.inherited_residue[1].nested.value, "before",
        "Packet owns inherited birth residue")

    local manifested = packet.new("owned manifest")
    route(manifested, "☴", false)
    route(manifested, "☱", false)
    route(manifested, "△", false)
    local manifest_input = {
        output = {type = "text", nested = {value = "before"}},
        truth_status = "runtime_confirmed",
    }
    assert(packet.manifest_packet(manifested, manifest_input))
    manifest_input.output.nested.value = "caller-after"
    assert_eq(manifested.manifest.output.nested.value, "before", "Packet owns manifest payload")

    local heir = packet.new("owned grave")
    local grave_input = {
        packet_id = "integrity-ancestor",
        status = "dead",
        death = {cause = "budget_exhausted"},
        residue = {
            do_not_repeat = "integrity loop",
            nested = {value = "before"},
        },
    }
    assert(grave.attach(heir, grave_input))
    grave_input.residue.nested.value = "caller-after"
    assert_eq(heir.runtime.karma.warnings[1].residue.nested.value, "before",
        "Packet owns attached grave")

    local inherited = {
        kind = "inherited_packet_residue",
        source_packet_id = "integrity-memory",
        residue = {nested = {value = "before"}},
    }
    assert(packet_memory.attach(heir, inherited, {enabled = true}))
    inherited.residue.nested.value = "caller-after"
    assert_eq(heir.runtime.memory.inherited_residue[1].residue.nested.value, "before",
        "Packet owns attached packet memory")

    local session = assert(session_memory.create("body-integrity-session"))
    local session_input = {
        packet_id = "integrity-session-ancestor",
        status = "dead",
        death = {cause = "budget_exhausted"},
        residue = {
            do_not_repeat = "session integrity loop",
            nested = {value = "before"},
        },
    }
    local returned_grave = assert(session_memory.add_grave(session, session_input))
    session_input.residue.nested.value = "caller-after"
    returned_grave.residue.nested.value = "returned-after"
    assert_eq(session.grave.warnings[1].residue.nested.value, "before",
        "session owns grave independently of caller and return value")
end)

check("I05-I06 wrong-position and missing-tick writes are rejected", function()
    local wrong = packet.new("wrong actor")
    local trace_before = #wrong.trace
    local choice, choice_err = body.record_choice(wrong, {
        kind = "choice_payload",
        selected = {"illegal"},
    })
    assert_true(not choice, "CHOOSE writer must fail while Packet is at FLOW")
    assert_true(tostring(choice_err):find("position", 1, true) ~= nil,
        "wrong actor error names position")
    assert_eq(#wrong.trace, trace_before, "wrong actor leaves trace unchanged")
    assert_eq(#wrong.boundary.choices, 0, "wrong actor leaves boundary unchanged")

    route(wrong, "☴")
    route(wrong, "☳")
    local forged_trace_before = #wrong.trace
    local forged, forged_err = packet.append_trace(wrong, {
        type = "validation",
        operator = "☳",
        truth_status = "runtime_confirmed",
        payload = {kind = "forged_validation"},
    })
    assert_true(not forged, "current glyph cannot forge another organ's event type")
    assert_true(tostring(forged_err):find("no right", 1, true) ~= nil,
        "event right denial is explicit")
    assert_eq(#wrong.trace, forged_trace_before, "event right denial leaves trace unchanged")

    local unticked = packet.new("missing tick")
    route(unticked, "☴", false)
    local appended, append_err = packet.append_chaos(unticked, {
        operator = "☴",
        kind = "unticked",
    })
    assert_true(not appended, "organ write without current tick must fail")
    assert_true(tostring(append_err):find("tick", 1, true) ~= nil,
        "missing tick error names tick")
end)

check("I07 matching current tick accepts write", function()
    local instance = packet.new("matching actor")
    route(instance, "☴")
    assert(packet.append_chaos(instance, {
        operator = "☴",
        kind = "matched",
    }))
end)

check("I08 field source belongs to current visit", function()
    local instance = packet.new("old source event")
    assert(flow.run(instance))
    route(instance, "☴")
    route(instance, "☵")
    local _, old_event = assert(packet.crystallize(instance, {
        calm_delta = {kind = "old-form"},
        loss = {kind = "old-loss", amount = 0},
    }))
    route(instance, "☴")
    route(instance, "☵")

    local unit, unit_err = field.add_unit(instance, "☵", {
        kind = "illegal_old_source",
        carrier = "old",
        source_refs = {"unit:1"},
        created_event_id = old_event.id,
        event_truth_status = "runtime_confirmed",
        content_truth_status = "semantic_proposal",
    })
    assert_true(not unit, "old visit event cannot authorize current field mutation")
    assert_true(tostring(unit_err):find("current operator tick", 1, true) ~= nil,
        "old source error names current tick")
end)

check("I04 boundary and foundation return independent payloads", function()
    local choice_packet = packet.new("choice alias")
    route(choice_packet, "☴")
    route(choice_packet, "☳")
    local choice_input = {kind = "choice_payload", nested = {value = "before"}}
    local recorded = assert(body.record_choice(choice_packet, choice_input))
    choice_input.nested.value = "caller-after"
    assert_eq(choice_packet.boundary.choices[1].nested.value, "before",
        "choice boundary owns its payload")
    recorded.nested.value = "returned-after"
    assert_eq(choice_packet.boundary.choices[1].nested.value, "before",
        "returned choice cannot mutate boundary")

    local logic_packet = packet.new("foundation alias")
    route(logic_packet, "☴")
    route(logic_packet, "☳")
    route(logic_packet, "☶")
    local result = {
        kind = "spell_result",
        name = "integrity",
        spell_kind = "integrity",
        intention_hash = "integrity",
        success = true,
        truth_status = "runtime_confirmed",
        nested = {value = "before"},
    }
    local pattern = assert(foundation.reinforce(logic_packet, result))
    result.nested.value = "caller-after"
    assert_eq(logic_packet.runtime.evidence[1].nested.value, "before",
        "foundation evidence owns spell result")
    pattern.last_result.nested.value = "returned-after"
    local stored_pattern
    for _, value in pairs(logic_packet.runtime.foundation.patterns) do
        stored_pattern = value
    end
    assert_eq(stored_pattern.last_result.nested.value, "before",
        "returned foundation pattern cannot mutate store")
end)

check("I09-I10b invalid costs are atomic and ledgers are owned", function()
    local malformed_usage, malformed_usage_err = budget.from_usage({prompt_tokens = "many"})
    assert_true(not malformed_usage, "malformed substrate usage must be rejected")
    assert_true(tostring(malformed_usage_err):find("finite number", 1, true) ~= nil,
        "malformed usage has typed validation error")

    local invalid_limit = packet.new("invalid limit", {budget = {steps = -1}})
    local initialized = budget.init(invalid_limit)
    assert_true(not initialized, "negative configured limit must be rejected")
    assert_eq(invalid_limit.runtime.budget, nil, "invalid limit cannot initialize runtime budget")

    local invalid_costs = {
        {steps = -1},
        {steps = 0 / 0},
        {steps = math.huge},
        {steps = 0.5},
        {unknown_axis = 1},
        {steps = "one"},
        {steps = 1, tool_calls = -1},
    }
    for index, cost in ipairs(invalid_costs) do
        local instance = packet.new("invalid cost " .. tostring(index), {budget = {steps = 3}})
        assert(budget.init(instance))
        local before = budget.snapshot(instance)
        local revision_before = instance.revisions.budget
        local record = budget.charge(instance, {
            operator = "▽",
            cost = cost,
            source = "integrity_probe",
        })
        assert_true(not record, "invalid cost " .. tostring(index) .. " must be rejected")
        local after = budget.snapshot(instance)
        assert_eq(after.spent.steps, before.spent.steps, "invalid cost cannot alter spent")
        assert_eq(after.remaining.steps, before.remaining.steps, "invalid cost cannot alter remaining")
        assert_eq(after.event_count, before.event_count, "invalid cost cannot append budget event")
        assert_eq(instance.revisions.budget, revision_before, "invalid cost cannot advance revision")
    end

    local economy = packet.new("economic ledger ownership", {
        budget = {steps = 3, loss = 1},
    })
    assert(budget.init(economy))
    local budget_record = assert(budget.charge(economy, {
        operator = "▽",
        cost = {steps = 1},
        source = "integrity_probe",
    }))
    budget_record.cost.steps = 99
    assert_eq(economy.runtime.budget.events[1].cost.steps, 1,
        "returned budget record cannot rewrite ledger")

    assert(loss.init(economy))
    local loss_detail = {nested = {value = "before"}}
    local loss_record = assert(loss.apply(economy, {
        operator = "☵",
        amount = 0.25,
        kind = "integrity_loss",
        detail = loss_detail,
    }))
    loss_detail.nested.value = "caller-after"
    loss_record.detail.nested.value = "returned-after"
    assert_eq(economy.tension.loss_events[1].detail.nested.value, "before",
        "loss ledger owns detail independently")

    local loss_before = loss.snapshot(economy)
    local loss_revision_before = economy.revisions.loss
    for _, amount in ipairs({-1, math.huge}) do
        local applied = loss.apply(economy, {amount = amount})
        assert_true(not applied, "invalid loss amount must be rejected")
        assert_eq(loss.snapshot(economy).loss, loss_before.loss,
            "invalid loss cannot change accumulated identity loss")
        assert_eq(economy.revisions.loss, loss_revision_before,
            "invalid loss cannot advance revision")
    end
    local nan_loss = loss.apply(economy, {amount = 0 / 0})
    assert_true(not nan_loss, "NaN loss must be rejected")
end)

check("I11-I12 changed referent re-arms LOGIC exactly once", function()
    local scratch = "sandbox/body_integrity_truth_rent.py"
    write_file(scratch, "value = 1\n")

    local instance = packet.new("causal truth rent", {metadata = {work_mode = "build"}})
    route(instance, "☴")
    route(instance, "☳")
    route(instance, "☶")
    instance.calm.current = {kind = "validated-form"}

    local cast = assert(spells.run({
        kind = "py_compile_python_file",
        name = "body_integrity_truth_rent",
        intention = "body_integrity_truth_rent",
        path = scratch,
        tick = 1,
    }))
    assert(foundation.reinforce(instance, cast))
    local fingerprint_a = freshness.evidence_fingerprint(instance)
    instance.runtime.logic_stamp = {
        evidence_fingerprint = fingerprint_a,
        trace_event_id = "fixture:logic:a",
    }
    route(instance, "☱", false)
    assert_eq(#assert(pressure.read("validation_debt", instance, {
        options = {work_mode = "build"},
    })), 0, "fresh stamp has no validation debt")

    write_file(scratch, "value = 2\n")
    local fingerprint_b = freshness.evidence_fingerprint(instance)
    assert_true(fingerprint_b ~= fingerprint_a, "referent change must change evidence fingerprint")
    assert_eq(#assert(pressure.read("validation_debt", instance, {
        options = {work_mode = "build"},
    })), 1, "referent change creates one validation debt")

    route(instance, "☶")
    local recast = assert(spells.run({
        kind = "py_compile_python_file",
        name = "body_integrity_truth_rent",
        intention = "body_integrity_truth_rent",
        path = scratch,
        tick = 2,
    }))
    assert(foundation.reinforce(instance, recast))
    instance.runtime.logic_stamp = {
        evidence_fingerprint = freshness.evidence_fingerprint(instance),
        trace_event_id = "fixture:logic:b",
    }
    route(instance, "☱", false)
    assert_eq(#assert(pressure.read("validation_debt", instance, {
        options = {work_mode = "build"},
    })), 0, "recast and restamp discharge debt")
    assert_eq(#assert(pressure.read("validation_debt", instance, {
        options = {work_mode = "build"},
    })), 0, "unchanged referent does not create recurrent debt")

    os.remove(scratch)
end)

if #failures > 0 then
    error("body integrity failures:\n- " .. table.concat(failures, "\n- "))
end

print("test_body_integrity ok")
