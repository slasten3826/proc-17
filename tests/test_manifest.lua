package.path = "./?.lua;./?/init.lua;" .. package.path

local manifest = require("logic.manifest")

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": " .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local payload, err = manifest.assemble({
    work_mode = "build",
    substrate_result = {
        text = "```python\nprint('ok')\n```",
    },
    sources = {
        substrate_result_event = "event-8",
        choice_event = "event-17",
    },
})
assert_true(payload, err)
assert_eq(payload.kind, "manifest_payload", "manifest kind")
assert_eq(payload.output.type, "code", "code fence type")
assert_eq(payload.output.language, "python", "code fence language")
assert_eq(payload.output.status, "complete", "normal output status")
assert_eq(payload.summary.type, "code", "summary type")
assert_eq(payload.summary.status, "complete", "normal summary status")
assert_eq(payload.summary.source_event, "event-8", "summary source")
assert_eq(payload.assembly.outcome, "complete", "normal assembly outcome")
assert_eq(payload.terminal_cause, "complete", "normal terminal cause")

payload, err = manifest.assemble({
    work_mode = "plan",
    substrate_result = {
        text = "Blueprint:\n1. authenticate\n2. menu",
    },
})
assert_true(payload, err)
assert_eq(payload.output.type, "plan", "plan mode type")

payload, err = manifest.assemble({
    work_mode = "build",
    substrate_result = {
        text = "manifest: none\nresidue: unsupported contradiction",
    },
})
assert_true(payload, err)
assert_eq(payload.output.type, "residue", "residue marker type")

payload, err = manifest.assemble({
    work_mode = "build",
    substrate_result = {
        text = "  ",
    },
})
assert_true(payload, err)
assert_eq(payload.output.type, "empty", "empty text type")

payload, err = manifest.assemble({
    work_mode = "build",
    substrate_result = {
        text = "plain answer",
    },
    choose_context = {
        selected_count = 2,
        not_chosen_count = 3,
        loss_kind = "attention_collapse",
        last_choice_event = "event-17",
    },
    logic_context = {
        accepted_count = 1,
        rejected_count = 0,
        last_validation_event = "event-19",
    },
})
assert_true(payload, err)
assert_eq(payload.output.type, "text", "plain answer type")
assert_eq(payload.residue.choice.not_chosen_count, 3, "choice residue")
assert_eq(payload.residue.validation.accepted_count, 1, "validation residue")

payload, err = manifest.assemble({
    work_mode = "build",
    substrate_result = {
        text = "generated text survives rejected validation",
    },
    logic_context = {
        accepted_count = 0,
        rejected_count = 1,
        rejection_reasons = {"missing_artifact"},
        last_validation_event = "event-23",
    },
    runtime_context = {
        completion_state = "blocked",
        reconciliation_event = "event-25",
        event_truth_status = "runtime_confirmed",
    },
})
assert_true(payload, err)
assert_eq(payload.output.text, "generated text survives rejected validation",
    "blocked manifest preserves substrate text")
assert_eq(payload.output.status, "blocked", "blocked output status")
assert_eq(payload.summary.status, "blocked", "blocked summary status")
assert_eq(payload.assembly.outcome, "blocked", "blocked assembly outcome")
assert_eq(payload.assembly.runtime_completion_state, "blocked",
    "assembly names runtime witness")
assert_eq(payload.terminal_cause, "blocked", "blocked terminal cause")
assert_eq(payload.residue.cause, "blocked", "blocked residue cause")
assert_eq(payload.residue.runtime.reconciliation_event, "event-25",
    "runtime reader provenance survives")

payload, err = manifest.assemble({})
assert_true(not payload, "missing substrate result should fail")
assert_eq(err, "missing_substrate_result", "missing substrate result error")

print("test_manifest ok")
