# Trace Validation Boundary Notes

Status:

```text
chaos
boundary pressure
no code yet
```

## Trigger

proc-17 generated ProcessLang traces after reading procesis.

Build mode produced short traces that local validation marked valid.

Plan mode produced useful exploration, but also drift:

```text
the substrate said ☴→☵ was invalid
local topology says ☴→☵ is valid
```

This is not a small mistake.

It reveals a body boundary:

```text
LLM may propose traces
LLM must not validate traces
LLM must not overrule local validation
```

Stronger form:

```text
LLM should not output trace validity at all.
```

Validity is not a semantic field.

Validity is body law.

## Law

```text
substrate proposes
body validates
substrate interprets only after body validation
```

or shorter:

```text
LLM proposes traces.
Body validates traces.
LLM interprets validated traces only.
```

Even shorter:

```text
trace first
validation second
semantics third
```

These must travel through separate channels.

## Why This Matters

ProcessLang topology is not commentary.

It is local law.

If the substrate is allowed to validate topology from prose, it will sometimes
contradict the body.

That contradiction must not become truth.

The body should be able to say:

```text
semantic proposal says invalid
local canon says valid
local canon wins
```

and:

```text
semantic proposal says valid
local canon says invalid
local canon wins
```

## Boundary Shape

The boundary should eventually look like:

```text
text response
  -> extract TRACE candidates
  -> normalize glyph sequence
  -> validate with local topology/canon
  -> mark valid/invalid
  -> pass only valid traces to semantic interpretation
```

No interpretation before validation.

No repair before validation.

No silent correction.

No substrate validity claim.

The substrate should provide:

```text
TRACE <id>: <glyphs>
purpose: optional semantic pressure
```

The body provides:

```text
valid / invalid
first invalid transition
```

Then, and only then, the substrate may receive validated traces for semantic
reading.

If a trace is invalid, preserve:

```text
trace
first invalid transition
position
residue
```

## Canon Position

`canon.lua` from procesis should become body law, not substrate memory.

The goal is not:

```text
make DeepSeek remember topology better
```

The goal is:

```text
make proc-17 body validate topology locally
```

The substrate can forget or misread.

The body must not.

## Current State

proc-17 already has:

```text
core/topology.lua
topology.validate_trace(trace)
```

But this is currently a local copy.

The body does not yet explicitly prove:

```text
core/topology.lua == procesis canon.lua
```

This proof is probably needed before the trace validator becomes a stronger
boundary.

## Possible Future Shape

Possible modules later:

```text
vendor/procesis/canon.lua
logic/trace_validator.lua
```

Possible flow:

```text
TRACE proposal from substrate
logic/trace_validator extracts exact glyph sequences
trace_validator validates against canon/topology
valid traces can be sent back to substrate for interpretation
invalid traces become residue
```

Retry flow:

```text
invalid trace
  -> body reports exact invalid transition
  -> substrate proposes another trace
  -> body validates again
  -> repeat until valid trace, budget stop, or packet death
```

## What Must Not Happen

Do not let substrate prose override local validation.

Do not interpret invalid traces.

Do not silently repair invalid traces.

Do not use trace validation as a creative task.

Do not make validator semantic.

Do not ask substrate whether a trace is valid.

The validator should be dumb.

It should only know:

```text
glyph exists
transition exists
first invalid transition
```

## Open Pressure

Need observation before table:

```text
What exactly counts as a trace candidate?
Should extraction require explicit TRACE lines only?
Should repeated glyphs always be invalid, or only invalid when topology lacks self-adjacency?
Should reversed traces be accepted if all transitions are adjacent?
Should body validate against core/topology.lua, procesis canon.lua, or both?
What does validated trace interpretation receive: glyphs only, or glyphs + operator names?
```

No code until this boundary is stable in table/crystall.

## Channel Split

This boundary implies an internal protocol split:

```text
trace_channel
semantic_channel
runtime_channel
```

`trace_channel` carries:

```text
glyphs
trace id
trace candidate
```

`semantic_channel` carries:

```text
purpose
meaning
interpretation
questions
```

`runtime_channel` carries:

```text
local validation
evidence
invalid transition
residue
budget/death
```

The channels may be present in one packet, but they must not collapse into one
field.
