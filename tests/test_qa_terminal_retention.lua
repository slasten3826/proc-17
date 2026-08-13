package.path = "./?.lua;./?/init.lua;" .. package.path

local H = require("tests.support.red_contract")
local corpse = require("runtime.corpse")
local evidence_schema = require("core.qa_evidence_schema")
local fixture = require("tests.support.qa_hand")

local suite = H.new("qa-terminal-retention")

local function keys(value)
    local result = {}
    for key in pairs(value or {}) do result[#result + 1] = key end
    table.sort(result)
    return table.concat(result, "|")
end

local function forbidden_authority(value, seen)
    if type(value) ~= "table" then return nil end
    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true
    local forbidden = {
        command = true,
        grant = true,
        handle = true,
        host_path = true,
        lease = true,
        provider = true,
        registry = true,
        root_handle = true,
    }
    for key, child in pairs(value) do
        if forbidden[key] then return key end
        local nested = forbidden_authority(child, seen)
        if nested then return nested end
    end
    return nil
end

suite:check("M4 accepted verdict terminalizes symmetrically", function()
    local life = assert(fixture.grow_terminal_qa_life({
        label = "qa-terminal-accepted",
    }))
    H.assert_eq(life.instance.status, "dead")
    H.assert_eq(life.instance.death.cause, "complete")
    H.assert_eq(life.terminal.mode, "qa_terminal_delivery")
    H.assert_eq(life.terminal.qa_terminal_projection.verdict, "accepted")
    H.assert_true(evidence_schema.verify_terminal_projection(
        life.terminal.qa_terminal_projection
    ))
    H.assert_eq(life.corpse_record.qa_evidence.verdict.verdict, "accepted")
end)

suite:check("M4 rejected verdict uses the same terminal depth", function()
    local accepted = assert(fixture.grow_terminal_qa_life({
        label = "qa-terminal-shape-accepted",
    }))
    local rejected = assert(fixture.grow_terminal_qa_life({
        label = "qa-terminal-shape-rejected",
        adapter_options = {reason = "unexpected_exit", exit_code = 70},
    }))
    H.assert_eq(rejected.instance.status, "dead")
    H.assert_eq(rejected.instance.death.cause, "blocked")
    H.assert_eq(rejected.terminal.qa_terminal_projection.verdict, "rejected")
    H.assert_eq(
        keys(accepted.terminal.qa_terminal_projection),
        keys(rejected.terminal.qa_terminal_projection),
        "accepted and rejected projection schemas differ"
    )
end)

suite:check("M4 corpse retention is independent of trace tail", function()
    local life = assert(fixture.grow_terminal_qa_life({
        label = "qa-terminal-long-tail",
        tail_events = 40,
    }))
    H.assert_true(life.qa_event_distance_from_tail > 32)
    for _, event in ipairs(life.corpse_record.trace_tail) do
        H.assert_false(event.type == "qa_candidate_verdict",
            "verdict fixture must actually fall outside trace tail")
    end
    H.assert_eq(
        life.corpse_record.qa_evidence.verdict.verdict_id,
        life.verdict.verdict_id
    )
    H.assert_true(corpse.verify(life.corpse_record))
end)

suite:check("M4 tampered corpse QA envelope is rejected", function()
    local life = assert(fixture.grow_terminal_qa_life({
        label = "qa-terminal-tamper",
    }))
    local tampered = fixture.copy(life.corpse_record)
    tampered.qa_evidence.terminal_projection.verdict = "rejected"
    local valid, err = corpse.verify(tampered)
    H.assert_nil(valid)
    H.assert_true(type(err) == "string" and err ~= "")
end)

suite:check("M4 descendant receives bounded history but no current check", function()
    local observed = assert(fixture.grow_qa_descendant())
    local history = observed.carrier.payload.qa_history
    H.assert_eq(history.applicability_truth_status, "inherited_proposal")
    H.assert_eq(observed.descendant_current_check_count, 0)
    H.assert_eq(#fixture.events(observed.descendant, "qa_check"), 0)
    H.assert_eq(
        history.qa_evidence.verdict.verdict_id,
        observed.ancestor_verdict_id
    )
    H.assert_nil(forbidden_authority(history),
        "historical QA envelope leaks authority")
end)

suite:finish()
print("test_qa_terminal_retention ok")
