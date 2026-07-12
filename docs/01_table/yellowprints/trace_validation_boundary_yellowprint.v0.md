# Trace Validation Boundary Yellowprint v0

Status:

```text
table
from docs/00_chaos/trace_validation_boundary_notes.md
no code yet
```

## Boundary Law

```text
LLM proposes traces.
Body validates traces.
LLM interprets validated traces only.
```

This is a body boundary, not a prompt improvement.

The substrate may be useful and still wrong about topology.

The body must not allow substrate prose to override local validation.

Substrate must not be asked to output validity.

Validity belongs to the body.

## Channel Split

Trace work must travel through separate channels:

```text
trace_channel
semantic_channel
runtime_channel
```

`trace_channel` carries:

```text
trace_id
glyph sequence
raw trace line
```

`semantic_channel` carries:

```text
purpose
requested interpretation
meaning after validation
```

`runtime_channel` carries:

```text
local validation result
first invalid transition
validator source
residue
retry count / budget pressure
```

The channels can live inside one packet, but must stay separately addressable.

## Pipeline

```text
substrate text
  -> extract trace candidates
  -> normalize glyph sequence
  -> validate against local body law
  -> classify valid/invalid
  -> if valid: pass trace_channel + validation result to semantic interpretation
  -> if invalid: return exact failure to substrate for retry or preserve residue
```

## Candidate Extraction

v0 should be strict.

Only lines with explicit trace marker count:

```text
TRACE <id>: <glyphs>
Trace <id>: <glyphs>
trace <id>: <glyphs>
```

The substrate output should not include:

```text
validity
believed validity
first transition to check
adjacency reasoning
```

Those are body responsibilities.

Reason:

```text
Loose extraction from prose produced false candidates.
Plan-mode explanations contained many glyphs that were not intended as traces.
```

Non-goal:

```text
Do not extract every glyph sequence from arbitrary prose in v0.
```

## Normalization

Input line:

```text
TRACE 1: ▽ ☰ ☷ ☴
```

Normalized trace:

```text
{"▽", "☰", "☷", "☴"}
```

Rules:

```text
ignore spaces between glyphs
ignore punctuation outside glyphs
preserve glyph order
reject unknown glyphs
require at least two operators
```

## Validation

Validation is local and deterministic.

The validator checks:

```text
operator exists
each adjacent pair is valid
first invalid transition
position of first invalid transition
```

Self-repeat is not a special rule.

It is invalid only because current topology has no self-adjacency:

```text
☱☱ invalid because ☱ is not adjacent to ☱
```

If future canon adds self-adjacency, validator follows canon.

## Canon Source

v0 should validate against current body topology:

```text
core/topology.lua
```

But crystall should include a consistency proof against procesis canon:

```text
/home/slasten/work/stak2/02_crystall/processlang/canon.lua
```

The future body should not depend on external path at runtime.

Possible stable shape:

```text
vendor/procesis/canon.lua
core/topology.lua adapter or compatibility layer
```

Open until crystall:

```text
Does proc-17 vendor canon.lua, or does it generate topology from canon.lua?
```

## Valid Result Shape

Each extracted candidate should become:

```lua
{
  kind = "trace_validation_result",
  id = string,
  raw_line = string,
  trace = {"▽", "☰", "☷", "☴"},
  trace_text = "▽☰☷☴",
  valid = true,
  invalid_at = nil,
  invalid_transition = nil,
  truth_status = "runtime_confirmed",
  channel = "runtime_channel",
  validator_source = "local_body_topology",
}
```

## Invalid Result Shape

Invalid candidate:

```lua
{
  kind = "trace_validation_result",
  id = string,
  raw_line = string,
  trace = {"☱", "☱"},
  trace_text = "☱☱",
  valid = false,
  invalid_at = 1,
  invalid_transition = "☱☱",
  residue = "invalid operator transition",
  truth_status = "runtime_confirmed",
  channel = "runtime_channel",
  validator_source = "local_body_topology",
}
```

Invalid traces must not disappear.

They become residue.

## Interpretation Gate

Only valid traces may be interpreted.

Interpretation input should contain:

```text
trace_channel.trace
trace_channel.trace_text
runtime_channel.validation_result
optional operator names from local body law
```

No invalid trace goes to semantic interpretation unless the task explicitly asks
to explain why it is invalid.

If interpretation is requested, it is a second substrate call or a separate
semantic step after validation.

The first substrate call proposes traces only.

## Reversed Traces

A reversed trace is accepted if every reversed transition is adjacent.

Reason:

```text
topology adjacency is the law
not canonical order
```

Canonical order may be a reading preference later, not v0 validity.

## Failure Modes

```text
no TRACE lines found -> empty validation result, no interpretation
unknown glyph -> invalid result with residue
one-glyph trace -> invalid result with residue
invalid transition -> invalid result with first invalid transition
substrate includes validity fields -> ignore them as semantic noise
all candidates invalid -> body returns exact failure and may request retry
retry budget exhausted -> packet residue / death
```

## Retry Loop

For invalid traces:

```text
body feedback:
TRACE <id> invalid at index N: X→Y
Generate another TRACE line.
Do not explain validity.
```

The retry loop is bounded by packet budget.

It must not become:

```text
ask LLM forever
```

## What To Observe Before Crystall

Need one more observation pass over this table:

```text
Is strict TRACE-line extraction too narrow?
Should valid trace interpretation be a separate packet?
Should local validation live in ☶ LOGIC or a separate trace boundary module used by ☶?
Should invalid traces enter ☷ DISSOLVE residue later?
Should retry be owned by ☲ CYCLE or by a trace-validator helper?
```

No code yet.
