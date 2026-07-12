# Trace Validation Boundary Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/trace_validation_boundary_yellowprint.v0.md
no code yet
```

## Purpose

Define the executable contract for ProcessLang trace validation in proc-17.

This boundary prevents substrate prose from becoming topology truth.

## Law

```text
LLM proposes traces.
Body validates traces.
LLM interprets validated traces only.
```

Validation is never a substrate responsibility.

The substrate must not be asked:

```text
is this trace valid?
```

The body answers that locally.

## Channels

Trace work uses three separately addressable channels.

```lua
trace_channel = {
  trace_id = string,
  raw_line = string,
  trace = {"▽", "☰", "☷", "☴"},
  trace_text = "▽☰☷☴",
}
```

```lua
semantic_channel = {
  purpose = string | nil,
  interpretation = string | nil,
  requested_action = string | nil,
}
```

```lua
runtime_channel = {
  validation = trace_validation_result,
  validator_source = "local_body_topology",
  retry_count = number,
  residue = table,
}
```

The channels may be stored together in one packet payload.

They must not collapse into one prose field.

## Module

Expected module:

```text
logic/trace_validator.lua
```

Expected supporting source:

```text
core/topology.lua
```

Future supporting source:

```text
vendor/procesis/canon.lua
```

v0 implementation may use `core/topology.lua` directly.

But v0 tests must prove that current topology agrees with vendored or local
procesis canon once canon is added.

## Public API

```lua
trace_validator.extract(text, options) -> candidates
trace_validator.validate_trace(trace_channel, options) -> result
trace_validator.validate_text(text, options) -> payload
trace_validator.feedback(result) -> string
```

## Extraction Contract

Only explicit TRACE lines count.

Accepted input lines:

```text
TRACE <id>: <glyphs>
Trace <id>: <glyphs>
trace <id>: <glyphs>
```

Examples:

```text
TRACE 1: ▽ ☰ ☷ ☴
TRACE alpha: ▽☰☷☴
```

Ignored in v0:

```text
glyphs embedded in explanation prose
validity claims
adjacency reasoning
first-transition commentary
```

Reason:

```text
prose glyph extraction produced false trace candidates
```

## Candidate Shape

Extraction returns:

```lua
{
  kind = "trace_candidate",
  channel = "trace_channel",
  id = "1",
  raw_line = "TRACE 1: ▽ ☰ ☷ ☴",
  trace = {"▽", "☰", "☷", "☴"},
  trace_text = "▽☰☷☴",
  truth_status = "semantic_proposal",
}
```

Extraction does not validate.

Extraction does not interpret.

## Validation Result Shape

Valid trace:

```lua
{
  kind = "trace_validation_result",
  channel = "runtime_channel",
  id = "1",
  raw_line = "TRACE 1: ▽ ☰ ☷ ☴",
  trace = {"▽", "☰", "☷", "☴"},
  trace_text = "▽☰☷☴",
  valid = true,
  invalid_at = nil,
  invalid_transition = nil,
  residue = nil,
  validator_source = "local_body_topology",
  truth_status = "runtime_confirmed",
}
```

Invalid trace:

```lua
{
  kind = "trace_validation_result",
  channel = "runtime_channel",
  id = "bad",
  raw_line = "TRACE bad: ☱ ☱",
  trace = {"☱", "☱"},
  trace_text = "☱☱",
  valid = false,
  invalid_at = 1,
  invalid_transition = "☱☱",
  residue = "invalid operator transition",
  validator_source = "local_body_topology",
  truth_status = "runtime_confirmed",
}
```

## validate_text Payload

```lua
{
  kind = "trace_validation_payload",
  candidates = {},
  valid = {},
  invalid = {},
  ignored_validity_claims = {},
  truth_status = "runtime_confirmed",
}
```

`ignored_validity_claims` records lines that tried to declare validity.

These lines do not affect validation.

## Body Authority Rules

```text
substrate validity claims are ignored
local validation wins
invalid traces are not interpreted
valid traces may be interpreted later
```

If substrate output includes:

```text
validity: valid
I believe it is valid
first transition to check
```

the validator may record this as semantic noise, but must not use it.

## Interpretation Gate

Semantic interpretation input must be built only from validated traces.

Allowed interpretation input:

```lua
{
  trace_channel = candidate,
  runtime_channel = {
    validation = valid_result,
  },
}
```

Invalid traces may only be sent to the substrate if the task is explicitly:

```text
explain why this trace is invalid
```

Otherwise invalid traces become residue.

## Retry Contract

v0 helper:

```lua
trace_validator.feedback(result) -> string
```

For invalid result:

```text
TRACE <id> invalid at index <n>: <left>→<right>.
Generate another TRACE line.
Do not explain validity.
```

Retry routing is not implemented in this blueprint.

Future owner:

```text
☲ CYCLE controls retry budget
☶ LOGIC owns validation result
☴ OBSERVE asks substrate for a new candidate if routed
```

## Placement

`logic/trace_validator.lua` belongs under `☶ LOGIC` authority because it creates
runtime-confirmed validation.

It is not an `☴ OBSERVE` responsibility.

It is not a `☵ ENCODE` responsibility.

It may later be called by the runner as a build `⊞` validation step.

## Failure Modes

```text
no TRACE lines -> payload with empty candidates and residue "no trace candidates"
unknown glyph -> invalid result
one glyph only -> invalid result "trace requires at least two operators"
invalid transition -> invalid result with first invalid transition
substrate validity claims -> ignored_validity_claims
all invalid -> no interpretation; retry or residue
retry budget exhausted -> packet residue/death, handled outside validator
```

## Tests Required Before Code Acceptance

Extraction:

```text
extracts "TRACE 1: ▽ ☰ ☷ ☴"
extracts "TRACE alpha: ▽☰☷☴"
does not extract glyphs from prose-only lines
records but ignores validity prose
```

Validation:

```text
▽☰☷☴ valid
☴☵ valid
☱☱ invalid at 1 with transition ☱☱
unknown glyph invalid
one-glyph trace invalid
reversed valid trace accepted if each transition is adjacent
```

Authority:

```text
substrate says valid but local invalid -> invalid
substrate says invalid but local valid -> valid
```

Feedback:

```text
invalid result produces exact correction prompt
valid result produces no retry feedback
```

No code until this blueprint is accepted.
