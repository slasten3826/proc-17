# Nested Layer Glyphs Yellowprint v0

Status:

```text
table
from docs/00_chaos/nested_layer_glyphs_notes.md
```

## Minimal Vocabulary

Do not add new phase names.

Use:

```text
mode
layer
context
```

Allowed modes:

```text
plan
build
```

Allowed layers:

```text
⋯
⊞
◈
▲
```

Context is free text or stable enum depending on caller:

```text
project
document
packet
experiment
trace
artifact
```

## Matrix

```text
plan ⋯
meaning: first idea form
allowed output: raw notes, hypotheses, pressure, questions
must not: write implementation

plan ⊞
meaning: structure check
allowed output: table, comparison, validation plan, relation map
must not: pretend runtime proof

plan ◈
meaning: blueprint / contract
allowed output: spec, interface, invariant, acceptance criteria
must not: skip unresolved residue

plan ▲
meaning: exported plan
allowed output: decision memo, task packet, ready-to-build plan
must not: call it working code

build ⋯
meaning: first working artifact
allowed output: minimal file, prototype, vertical slice
must not: polish before movement

build ⊞
meaning: run / observe / validate
allowed output: command result, trace validation, runtime map, failure boundary
must not: accept semantic proposal as runtime truth
must not: ask substrate to validate body law

build ◈
meaning: fix concrete bad noise
allowed output: targeted patch, tightened rule, focused test
must not: refactor unrelated parts

build ▲
meaning: bounded repeat until manifest/death
allowed output: final artifact, completion residue, death cause, next pressure
must not: loop without budget or stop condition
```

## Suggested Packet Shape

Future implementation may add:

```lua
packet.runtime.mode = "plan" | "build"
packet.runtime.layer = "⋯" | "⊞" | "◈" | "▲"
packet.runtime.context = "packet" | "experiment" | "artifact" | ...
```

Do not add this until a test needs it.

## System Prompt Pressure

If implemented, substrate prompt should say:

```text
mode says why the body works.
layer says at what abstraction depth the current work happens.
The same layer glyphs can recur inside tasks; do not rename them.
Context disambiguates.
```

## Router Pressure

No routing changes in v0.

The first version should only make mode/layer visible.

Routing may use layer later if experiments show pressure:

```text
build ⊞ prefers ☶ / local validators
build ◈ prefers targeted patch after concrete failure
build ▲ prefers ☲ / △ boundaries
```

This is residue, not current contract.
