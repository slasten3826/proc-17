local packet_core = require("core.packet")
local lineage_runner = require("runtime.lineage_runner")
local session_memory = require("runtime.session_memory")
local tension_runner = require("runtime.tension_runner")
local fixture = require("tests.support.plan_life")

local function id_source()
    local counts = {}
    return function(kind)
        counts[kind] = (counts[kind] or 0) + 1
        return kind .. "-lineage-test-" .. tostring(counts[kind])
    end
end

local function base_options(overrides)
    local options = {
        session_id = "lineage-runner-session",
        lineage_id = "lineage-runner-main",
        work_mode = "plan",
        completion_contract_id = "plan.v0",
        flow_source = {2, 3, 5, 7, 11},
        flow_options = {
            stream_id = "lineage-runner-stream",
            source_ref = "test:lineage-runner",
        },
        projection_adapter = "vertical_single.v0",
        packet_budget = {steps = 16, substrate_calls = 8, loss = 1},
        lineage_budget = {
            steps = 64,
            substrate_calls = 16,
            generations = 4,
            carrier_bytes = 65536,
        },
        carrier = {max_bytes = 65536},
        allow_recovery = true,
        history_enabled = false,
        emergency_max_generations = 4,
        packet_runner_options = {
            router_mode = "tree",
            pressure_policy = "qualified_need_v0",
            ablate_relation_consumer = true,
            legacy_shadow = false,
            max_ticks = 20,
        },
        id_source = id_source(),
    }
    for key, value in pairs(overrides or {}) do
        options[key] = value
    end
    return options
end

local substrate = fixture.substrate(fixture.proposal(
    "work_sequence",
    {"inspect", "change", "verify"}
))

-- L0: an exact plan closes one lineage in one mortal life.
local one, one_report = assert(lineage_runner.run(
    "prepare an exact plan",
    substrate,
    base_options()
))
assert(one.status == "complete")
assert(one.current_generation == 1)
assert(#one_report.generations == 1)
assert(#one_report.corpses == 1)
assert(#one_report.carriers == 0)
assert(one_report.corpses[1].manifest.mode == "plan_delivery")
assert(one_report.corpses[1].manifest.content_truth_status == "semantic_proposal")
assert(one_report.assessments[1].task_state == "complete")
assert(one_report.budget.spent.generations == 1)
assert(one_report.session.current_lineage_id == one.lineage_id)

-- L1-L6/L9/L12: real local budget death births a clean descendant which completes.
local born = {}
local terminal_packets = {}
local function observing_runner(prompt, model, options)
    local original_hook = options.on_packet_birth
    options.on_packet_birth = function(instance, receipt)
        born[#born + 1] = {
            id = instance.id,
            session_id = instance.session_id,
            lineage_id = instance.lineage_id,
            generation = instance.generation,
            stage_id = instance.stage_id,
            parent_id = instance.parent_id,
            parent_corpse_id = instance.parent_corpse_id,
            carrier_id = instance.carrier_id,
            operator = instance.operator,
            calm_count = #(instance.calm.work_units or {}),
            field_count = #(instance.field.unit_order or {}),
            relation_count = #(instance.field.relations.active or {}),
            local_loss = instance.tension.loss,
        }
        return original_hook(instance, receipt)
    end
    local instance, result = tension_runner.run(prompt, model, options)
    if instance then
        terminal_packets[#terminal_packets + 1] = instance
    end
    return instance, result
end

local two_options = base_options({
    session_id = "lineage-runner-two-session",
    lineage_id = "lineage-runner-two",
    flow_options = {
        stream_id = "lineage-runner-two-stream",
        source_ref = "test:lineage-runner-two",
    },
    packet_runner = observing_runner,
    packet_budget_for_generation = function(generation)
        if generation == 1 then
            return {steps = 2, substrate_calls = 8, loss = 1}
        end
        return {steps = 16, substrate_calls = 8, loss = 1}
    end,
    lineage_budget = {
        steps = 32,
        substrate_calls = 16,
        generations = 3,
        carrier_bytes = 65536,
    },
    id_source = id_source(),
})
local two, two_report = assert(lineage_runner.run(
    "prepare an exact plan after recovery",
    substrate,
    two_options
))
assert(two.status == "complete")
assert(two.current_generation == 2)
assert(#two_report.generations == 2)
assert(#two_report.corpses == 2)
assert(#two_report.carriers == 1)
assert(two_report.corpses[1].death_cause == "budget_exhausted")
assert(two_report.assessments[1].task_state == "unfinished")
assert(two_report.assessments[1].terminal_recoverable == true)
assert(two_report.corpses[2].death_cause == "complete")
assert(two_report.assessments[2].task_state == "complete")
assert(two_report.corpses[2].parent_packet_id == two_report.corpses[1].packet_id)
assert(two_report.corpses[2].parent_corpse_id == two_report.corpses[1].corpse_id)
assert(two_report.corpses[2].ingress_carrier_id == two_report.carriers[1].carrier_id)
assert(two_report.carriers[1].source_corpse_id == two_report.corpses[1].corpse_id)
assert(two_report.carriers[1].target_generation == 2)

assert(#born == 2)
assert(born[1].generation == 1 and born[2].generation == 2)
assert(born[1].stage_id == born[2].stage_id,
    "recovery generations must retain one stage identity")
assert(two_report.corpses[1].stage_id == two_report.corpses[2].stage_id,
    "immutable recovery corpses must retain one stage identity")
assert(born[1].session_id == "lineage-runner-two-session")
assert(born[2].session_id == born[1].session_id)
assert(born[1].id ~= born[2].id)
assert(born[2].parent_id == born[1].id)
assert(born[2].parent_corpse_id == two_report.corpses[1].corpse_id)
assert(born[2].carrier_id == two_report.carriers[1].carrier_id)
assert(born[2].operator == "▽")
assert(born[2].calm_count == 0)
assert(born[2].field_count == 0)
assert(born[2].relation_count == 0)
assert(born[2].local_loss == 0)

assert(two_report.budget.spent.steps
    == two_report.corpses[1].final_budget.spent.steps
        + two_report.corpses[2].final_budget.spent.steps)
assert(two_report.budget.spent.generations == 2)
assert(two_report.budget.spent.carrier_bytes == two_report.carriers[1].payload_bytes)
assert(two_report.corpses[2].manifest.content_truth_status == "semantic_proposal")

for _, dead in ipairs(terminal_packets) do
    assert(dead.status == "dead")
    for _, event in ipairs(dead.trace or {}) do
        assert(event.operator ~= "NETWORK")
        assert(event.type ~= "network")
    end
end
local cannot_mutate, finality_err = packet_core.append_chaos(terminal_packets[1], {
    operator = "☴",
    text = "posthumous mutation",
})
assert(cannot_mutate == nil)
assert(finality_err:match("dead packet"))

-- L11: history changes only the inherited body channel; lineage still owns ancestry.
local history, history_report = assert(lineage_runner.run(
    "prepare an exact plan with inherited grave pressure",
    substrate,
    base_options({
        session_id = "lineage-runner-history-session",
        lineage_id = "lineage-runner-history",
        flow_options = {
            stream_id = "lineage-runner-history-stream",
            source_ref = "test:lineage-runner-history",
        },
        history_enabled = true,
        packet_budget_for_generation = function(generation)
            if generation == 1 then
                return {steps = 2, substrate_calls = 8, loss = 1}
            end
            return {steps = 16, substrate_calls = 8, loss = 1}
        end,
        lineage_budget = {
            steps = 32,
            substrate_calls = 16,
            generations = 3,
            carrier_bytes = 65536,
        },
        id_source = id_source(),
    })
))
assert(history.current_generation == 2)
assert(history.status == "complete")
assert(history_report.generations[1].life.grave.attached_count == 0)
assert(history_report.generations[2].life.grave.attached_count >= 1)
assert(history_report.corpses[2].parent_corpse_id == history_report.corpses[1].corpse_id)
assert(history_report.budget.spent.generations == 2)

-- L8: an oversized deterministic carrier suspends without a child.
local oversized, oversized_report = assert(lineage_runner.run(
    "prepare a plan with an intentionally tiny carrier boundary",
    substrate,
    base_options({
        session_id = "lineage-runner-oversize-session",
        lineage_id = "lineage-runner-oversize",
        flow_options = {
            stream_id = "lineage-runner-oversize-stream",
            source_ref = "test:lineage-runner-oversize",
        },
        packet_budget = {steps = 2, substrate_calls = 8, loss = 1},
        carrier = {max_bytes = 8},
        id_source = id_source(),
    })
))
assert(oversized.status == "suspended")
assert(oversized.terminal.cause == "carrier_too_large")
assert(#oversized_report.generations == 1)
assert(#oversized_report.carriers == 0)

-- L10: broken world machinery stays loud and creates no synthetic grave.
local failure_session = assert(session_memory.create("lineage-runner-failure-session"))
local failed, failed_err = lineage_runner.run(
    "runner failure must stay outside Packet mortality",
    substrate,
    base_options({
        session = failure_session,
        session_id = nil,
        lineage_id = "lineage-runner-failure",
        flow_options = {
            stream_id = "lineage-runner-failure-stream",
            source_ref = "test:lineage-runner-failure",
        },
        packet_runner = function()
            error("injected world failure")
        end,
        id_source = id_source(),
    })
)
assert(failed == nil)
assert(failed_err:match("packet_runner:"))
assert(failed_err:match("injected world failure"))
assert(#failure_session.packet_ids == 0)
assert(#failure_session.grave.warnings == 0)
assert(#failure_session.grave.bequests == 0)
assert(#failure_session.grave.neutral == 0)

local duplicate_session = assert(session_memory.create("lineage-runner-duplicate-session"))
assert(session_memory.append_lineage(duplicate_session, "lineage-runner-duplicate"))
local duplicate_lineage, duplicate_lineage_err = lineage_runner.run(
    "duplicate lineage ids must not merge ledgers",
    substrate,
    base_options({
        session = duplicate_session,
        session_id = nil,
        lineage_id = "lineage-runner-duplicate",
        flow_options = {
            stream_id = "lineage-runner-duplicate-stream",
            source_ref = "test:lineage-runner-duplicate",
        },
        id_source = id_source(),
    })
)
assert(duplicate_lineage == nil)
assert(duplicate_lineage_err:match("lineage id already exists"))

local reused_packet, reused_packet_err = lineage_runner.run(
    "caller cannot reuse one Packet identity across generations",
    substrate,
    base_options({
        session_id = "lineage-runner-packet-id-session",
        lineage_id = "lineage-runner-packet-id",
        packet_runner_options = {
            packet_options = {id = "caller-owned-packet"},
        },
        id_source = id_source(),
    })
)
assert(reused_packet == nil)
assert(reused_packet_err:match("owns Packet identity allocation"))

print("test_lineage_runner ok")
