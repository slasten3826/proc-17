# Nested Layer Glyphs Yellowprint v0

Status:

```text
table
from docs/00_chaos/nested_layer_glyphs_notes.md
partially superseded 2026-07-20
```

Supersession boundary:

```text
the original mode/layer/context distinction remains useful archaeology
the suggested mutable packet.runtime.layer is rejected as authority
build ◈ no longer grants an in-place targeted patch on the primary proc-17 path
rejected immutable candidates produce a final QA verdict, a bounded terminal
manifest projection and, when lineage recovery is affordable, a fresh generation
```

Current sources for those corrected laws:

```text
docs/00_chaos/nested_work_layer_runtime_integration_2026-07-20.md
docs/00_chaos/f4_rejected_generation_terminal_projection_notes_2026-07-21.md
docs/01_table/yellowprints/documentation_profiles_economy_yellowprint.v0.md
docs/01_table/yellowprints/documentation_layer_snapshots_truth_yellowprint.v0.md
docs/01_table/yellowprints/documentation_corpus_assembly_reentry_yellowprint.v0.md
docs/01_table/yellowprints/nested_work_layer_derivation_yellowprint.v0.md
docs/01_table/yellowprints/completion_scope_candidate_seal_yellowprint.v0.md
docs/01_table/yellowprints/stage_transition_generation_recovery_yellowprint.v0.md
```

The original rows below are retained as archaeology and must not be executed as
an alternative current contract.

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
