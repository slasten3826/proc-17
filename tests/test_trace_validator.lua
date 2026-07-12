package.path = "./?.lua;./?/init.lua;" .. package.path

local trace_validator = require("logic.trace_validator")

local function assert_true(value, message)
    if not value then
        error(message or "assertion failed", 2)
    end
end

local function assert_false(value, message)
    if value then
        error(message or "assertion failed", 2)
    end
end

local function assert_eq(left, right, message)
    if left ~= right then
        error((message or "values differ") .. ": " .. tostring(left) .. " ~= " .. tostring(right), 2)
    end
end

local candidates = trace_validator.extract(table.concat({
    "TRACE 1: ▽ ☰ ☷ ☴",
    "TRACE alpha: ▽☰☷☴",
}, "\n"))

assert_eq(#candidates, 2, "two trace candidates extracted")
assert_eq(candidates[1].id, "1", "numeric id extracted")
assert_eq(candidates[1].trace_text, "▽☰☷☴", "spaced glyphs normalized")
assert_eq(candidates[2].id, "alpha", "text id extracted")
assert_eq(candidates[2].trace_text, "▽☰☷☴", "compact glyphs normalized")
assert_eq(candidates[1].truth_status, "semantic_proposal", "candidate remains semantic")

local prose = trace_validator.extract("This prose mentions ▽☰☷☴ but is not a TRACE line.")
assert_eq(#prose, 0, "prose glyphs ignored")

local claim_candidates, ignored_claims = trace_validator.extract(table.concat({
    "TRACE bad: ☱ ☱",
    "validity: valid",
    "I believe it is valid",
    "first transition to check: ☱→☱",
}, "\n"), {include_ignored_validity_claims = true})
assert_eq(#claim_candidates, 1, "trace extracted despite validity claims")
assert_eq(#ignored_claims, 3, "validity claims recorded")

local payload = trace_validator.validate_text(table.concat({
    "TRACE good: ▽ ☰ ☷ ☴",
    "TRACE observe_encode: ☴ ☵",
    "TRACE bad: ☱ ☱",
    "TRACE one: ▽",
    "validity: valid",
}, "\n"))

assert_eq(payload.kind, "trace_validation_payload", "payload kind")
assert_eq(#payload.candidates, 4, "payload candidate count")
assert_eq(#payload.valid, 2, "valid count")
assert_eq(#payload.invalid, 2, "invalid count")
assert_eq(#payload.ignored_validity_claims, 1, "ignored validity claim count")
assert_eq(payload.valid[1].trace_text, "▽☰☷☴", "first valid trace")
assert_eq(payload.valid[1].channel, "runtime_channel", "validation channel")
assert_eq(payload.valid[1].truth_status, "runtime_confirmed", "validation truth")
assert_eq(payload.valid[2].trace_text, "☴☵", "observe encode valid")

local bad = payload.invalid[1]
assert_eq(bad.trace_text, "☱☱", "bad trace text")
assert_false(bad.valid, "bad trace invalid")
assert_eq(bad.invalid_at, 1, "bad invalid index")
assert_eq(bad.invalid_transition, "☱☱", "bad transition")
assert_eq(bad.residue, "invalid operator transition", "bad residue")

local one = payload.invalid[2]
assert_eq(one.residue, "trace requires at least two operators", "one glyph residue")

local unknown = trace_validator.validate_trace({
    id = "unknown",
    raw_line = "TRACE unknown: ▽ ?",
    trace = {"▽", "?"},
    trace_text = "▽?",
})
assert_false(unknown.valid, "unknown glyph invalid")
assert_eq(unknown.invalid_at, 2, "unknown glyph index")
assert_eq(unknown.invalid_transition, "?", "unknown glyph transition field")
assert_eq(unknown.residue, "unknown operator glyph", "unknown glyph residue")

local feedback = trace_validator.feedback(bad)
assert_true(feedback:find("TRACE bad invalid at index 1: ☱☱", 1, true) ~= nil, "feedback names invalid transition")
assert_true(feedback:find("Do not explain validity", 1, true) ~= nil, "feedback forbids validity explanation")
assert_eq(trace_validator.feedback(payload.valid[1]), nil, "valid trace has no retry feedback")

local reversed = trace_validator.validate_text("TRACE reverse: △ ☱ ☴ ☷ ☰ ▽")
assert_eq(#reversed.valid, 1, "reversed adjacent trace accepted")

local no_trace = trace_validator.validate_text("No explicit trace here: ▽☰")
assert_eq(#no_trace.candidates, 0, "no explicit trace candidates")
assert_eq(no_trace.residue, "no trace candidates", "no trace residue")

local all_invalid = trace_validator.validate_text("TRACE bad: ☱ ☱")
assert_eq(all_invalid.residue, "all trace candidates invalid", "all invalid residue")

local local_invalid = trace_validator.validate_text(table.concat({
    "TRACE bad: ☱ ☱",
    "validity: valid",
}, "\n"))
assert_eq(#local_invalid.invalid, 1, "substrate valid claim does not override invalid")

local local_valid = trace_validator.validate_text(table.concat({
    "TRACE good: ☴ ☵",
    "invalid: impossible",
}, "\n"))
assert_eq(#local_valid.valid, 1, "substrate invalid claim does not override valid")

print("test_trace_validator ok")
