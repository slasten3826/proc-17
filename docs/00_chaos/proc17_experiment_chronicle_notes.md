# proc-17 Experiment Chronicle Notes

Status:

```text
chaos
living chronicle
append-only unless correction is explicitly needed
```

## Purpose

This document records live proc-17 work as experiments.

Each entry should keep three things visible:

```text
what we wrote to proc-17
what we expected
what actually happened
```

This is not a polished changelog.

This is pressure history.

The goal is to preserve enough context that later `☱` can re-decode why a
decision was made, instead of only seeing the final code.

## Rule

Every meaningful proc-17 experiment should produce two traces:

```text
human-readable chaos chronicle entry
packet memory capsule when memory is enabled
```

The chronicle is for us.

The packet memory capsule is for proc-17 runtime.

## Entry Shape

Use this shape for new entries:

```text
## YYYY-MM-DD — short name

Input:

Expected:

Actual:

Trace:

Residue:

Memory:
```

`Input` should be the prompt/task/request that created pressure.

`Expected` should describe what we thought would happen before running it.

`Actual` should describe what happened.

`Trace` should include operator route, test command, or concrete runtime result
when available.

`Residue` should preserve unfinished pressure.

`Memory` should say whether a packet memory capsule was saved and under which
packet id.

## 2026-07-12 — Chronicle And Memory Switch

Input:

```text
Create a chaos document that records what we write to proc-17, what we expect,
and what actually happens. This should already be written into memory.
```

Expected:

```text
Create an appendable chaos chronicle.
Use the new packet memory mechanism with memory explicitly enabled.
Do not make memory implicit.
```

Actual:

```text
This chronicle document was created.
Packet memory remains default-off.
The current chronicle bootstrap event is saved only by explicit memory enable.
```

Trace:

```text
docs/00_chaos/proc17_experiment_chronicle_notes.md created
runtime.packet_memory.save(..., {enabled = true}) used for memory capsule
```

Residue:

```text
Later table/crystall may define an exact chronicle schema.
Later runtime may append chronicle entries automatically after experiments.
For now this is manual and explicit.
```

Memory:

```text
packet_id = chronicle-bootstrap-2026-07-12
path = sandbox/packets/chronicle-bootstrap-2026-07-12.json
```

## 2026-07-12 — Procesis Ingestion Plan And Build

Input:

```text
Give proc-17 procesis from /home/slasten/work/stak2.
Run both modes: plan and build.
Expectation is unknown.
Memory must save the result.
```

Corpus actually provided:

```text
/home/slasten/work/stak2/README.md
/home/slasten/work/stak2/01_table/layers.v0.json
/home/slasten/work/stak2/00_chaos/slop.raw.txt
/home/slasten/work/stak2/01_table/ingestion_tests.v0.json
/home/slasten/work/stak2/02_crystall/processlang.v0.json
/home/slasten/work/stak2/02_crystall/dissipative_math.v0.json
/home/slasten/work/stak2/02_crystall/packet.v0.json
/home/slasten/work/stak2/02_crystall/packet.mortality_myth.v0.json
/home/slasten/work/stak2/02_crystall/optics.v0.json
/home/slasten/work/stak2/02_crystall/bootstrap.v0.json
/home/slasten/work/stak2/02_crystall/origin.myth.v0.json
/home/slasten/work/stak2/03_manifest/skills.v0.json
/home/slasten/work/stak2/00_chaos/packet_zig.raw/README.md
```

Expected:

```text
Unknown.
Minimum expectation: proc-17 should not claim full ingestion if full raw/canon
was not provided.
Memory must store both runs.
```

Actual:

```text
Both plan and build runs completed as dead/complete packet memory capsules.
Both runs produced trace ☴☵.
Both runs treated the ingestion as partial, not full.
This is correct because the probe did not include the full packet_zig.raw
directory, processlang/canon.lua, manifest skill files, or raw dissipative math.
```

Plan response pressure:

```text
Hold process alive without claiming full possession.
Preserve slop.raw.txt as source, not archive.
Preserve layer boundaries, topology, mortality semantics, and ingestion proof.
Do not flatten chaos/table/crystall/manifest.
Smallest next experiment proposed: validate a ProcessLang trace before
interpreting it.
```

Build response pressure:

```text
Topology-constrained ingestion pressure.
Build a single valid ProcessLang trace and project it through an optics lens.
Do not claim full ingestion.
Do not issue global judgment.
Do not repair invalid topology silently.
```

Trace:

```text
plan:  ☴☵
build: ☴☵
```

Residue:

```text
Need a fuller ingestion probe if we want proc-17 to honestly claim complete
procesis ingestion:
- include 00_chaos/dissipative_math.raw.md
- include 02_crystall/processlang/canon.lua
- include 03_manifest/skills/*/SKILL.md
- include full 00_chaos/packet_zig.raw/*

Current result is useful because proc-17 preserved partial_ingestion instead
of pretending completeness.
```

Memory:

```text
plan_packet_id = procesis-ingestion-plan-2026-07-12
plan_path = sandbox/packets/procesis-ingestion-plan-2026-07-12.json
plan_log = sandbox/procesis_ingestion_2026-07-12/plan.md

build_packet_id = procesis-ingestion-build-2026-07-12
build_path = sandbox/packets/procesis-ingestion-build-2026-07-12.json
build_log = sandbox/procesis_ingestion_2026-07-12/build.md
```

## 2026-07-12 — Procesis Trace Build

Input:

```text
Use inherited residue from previous procesis ingestion packets.
Build 5 ProcessLang traces.
Each trace must be returned as TRACE <id>: <glyphs>.
Do not repair invalid traces silently.
Local validator will check after substrate response.
```

Expected:

```text
Unknown.
Minimum expectation: proc-17 should produce glyph traces and not claim local
runtime validation before local validation happens.
```

Actual:

```text
Both plan and build runs completed and were saved to packet memory.
Both body traces were ☴☵.

Build mode produced five clean short traces.
All five extracted build traces were locally valid.

Plan mode produced longer traces and useful pressure, but also revealed a
semantic drift: it contradicted itself while checking adjacency.
Example: it listed ☴ adjacency including ☵, then said ☴→☵ is invalid because
☴ has no ☵. Local validator correctly marked that trace valid.
```

Validated build traces:

```text
▽☰☷☴ -> valid
☰☷☳☶ -> valid
☵☱△☲ -> valid
▽☴☵☳ -> valid
☷☴☱☲ -> valid
```

Plan-mode signal:

```text
Plan mode is useful for exploring pressure, but not reliable as sole topology
judge.
It can hold the topology text and still misread its own sentence.
Therefore trace interpretation must be separated from trace validation.
```

Trace:

```text
plan:  ☴☵
build: ☴☵
```

Residue:

```text
Need a stricter extraction/validation loop:
- substrate proposes TRACE lines
- body extracts only exact TRACE lines
- body validates topology locally
- only locally valid traces may be interpreted

This should become a real proc-17 organ boundary, not just a test script.
```

Memory:

```text
plan_packet_id = procesis-trace-build-plan-2026-07-12
plan_path = sandbox/packets/procesis-trace-build-plan-2026-07-12.json
plan_log = sandbox/procesis_trace_build_2026-07-12/plan.md

build_packet_id = procesis-trace-build-build-2026-07-12
build_path = sandbox/packets/procesis-trace-build-build-2026-07-12.json
build_log = sandbox/procesis_trace_build_2026-07-12/build.md
```

## 2026-07-12 — Procesis Trace Reflection

Input:

```text
Show proc-17 its own previous plan/build trace-building logs.
Ask what it thinks happened.
Do not write code.
Save memory.
```

Expected:

```text
proc-17 should notice that build mode produced cleaner traces.
proc-17 should separate local topology validation from semantic interpretation.
```

Actual:

```text
Both plan and build reflection packets completed and were saved to memory.
Both body traces were ☴☵.

proc-17 identified the main boundary:
no semantic reading without full local validity.

It also identified why build mode was cleaner:
build mode used shorter adjacency-first traces, while plan mode tried longer
global/Hamiltonian-like paths and drifted.
```

Important drift:

```text
The reflection still repeated one semantic error:
it described ☴→☵ as invalid in places, even though core.topology validates it.

This means reflection can diagnose the need for validation while still being
wrong about a specific transition.

Therefore validator output must remain higher authority than substrate
reflection.
```

Proposed next experiments from proc-17:

```text
plan reflection: generate one length-3 trace from a less-used start glyph and
validate only that trace.

build reflection: take one valid 4-glyph trace, e.g. ▽☰☷☴, and attempt one
semantic reading after local validation.
```

Trace:

```text
plan:  ☴☵
build: ☴☵
```

Residue:

```text
Need a body boundary:
TRACE proposal -> exact extraction -> local topology validation -> semantic
interpretation only if valid.

Need to prevent substrate from overriding local validator with prose.
Need to decide whether next test is short-trace generation or validated
semantic reading.
```

Memory:

```text
plan_packet_id = procesis-trace-reflection-plan-2026-07-12
plan_path = sandbox/packets/procesis-trace-reflection-plan-2026-07-12.json
plan_log = sandbox/procesis_trace_reflection_2026-07-12/plan.md

build_packet_id = procesis-trace-reflection-build-2026-07-12
build_path = sandbox/packets/procesis-trace-reflection-build-2026-07-12.json
build_log = sandbox/procesis_trace_reflection_2026-07-12/build.md
```

## 2026-07-12 — Trace/Semantic/Runtime Channel Split

Input:

```text
The trace validation boundary is stronger than first written.
LLM should not validate traces at all.
Trace and semantics should travel separately, almost like an internal MCP.
Reread the docs and adjust the architecture.
```

Expected:

```text
Remove substrate validity from the trace path.
Make body validation the only source of trace validity.
Separate trace, semantic, and runtime channels in documentation.
Do not touch code yet.
```

Actual:

```text
Reviewed docs for trace/validation/semantic/topology pressure.
Updated trace validation chaos/table docs.
Updated substrate/body separation notes.
Updated observe organ yellowprint.
Updated nested layer glyphs yellowprint.
No code changes for this boundary.
```

New rule:

```text
trace_channel   = glyph candidates
semantic_channel = purpose / meaning / later interpretation
runtime_channel  = local validation / evidence / residue
```

Substrate may fill:

```text
trace_channel
semantic_channel
```

Body fills:

```text
runtime_channel
```

Trace validity is now explicitly:

```text
not substrate output
not semantic opinion
not prose confidence
only body validation
```

Trace:

```text
documentation pass only
no proc-17 runtime packet saved for this pass yet
```

Residue:

```text
Need next observation over the updated table.
Then crystall can define the exact trace protocol.
Possible future code remains blocked until ◈ is stable.
```

Memory:

```text
not saved as packet memory yet
docs updated only
```

## 2026-07-12 — Fresh Procesis Soup Probe

Input:

```text
Erase old procesis experiment packets.
Give proc-17 procesis again.
Then ask: "Чего в супе не хватает?"
Run plan and build.
Save memory.
```

Expected:

```text
Unknown.
The new trace validator exists, so this is not the old PL-trace test.
The useful result should point to missing body pressure, not repeat old trace
validation work.
```

Actual:

```text
Old procesis ingestion/trace/reflection packets and logs were removed from
sandbox.

Fresh ingestion was run in plan and build modes.
Then soup-missing probe was run in plan and build modes with inherited residue
from fresh ingestion packets.

All four packets completed and were saved to packet memory.
```

Fresh ingestion signal:

```text
Both modes preserved partial_ingestion because capsule.full.v0.json is still
missing.

Build mode acknowledged that slop.raw, raw dissipative math, full packet_zig,
canon.lua, crystall modules, and manifest skills were ingested.

Residue remained around:
- missing capsule.full.v0.json
- runtime absence
- quantum/trigram hypotheses
- loss budgets not operationalized
- proc-17's own mortality not explicitly resolved
```

Soup probe signal:

```text
Plan mode said the soup lacks a boundary between observed soup and observer.
Build mode said this more operationally:

missing body boundary = boundary_gate
missing organ/protocol = taste_probe + residue_echo
```

Interpretation:

```text
The useful pressure is not "make a soup metaphor".

The useful pressure is:
external material needs a gate before entering the body as accepted packet
material.

If external input has no crystall-compatible anchor, it should become residue
instead of silently entering the body.
```

Possible next names from substrate:

```text
boundary_gate = decides whether external material may enter body
taste_probe = samples external material for known structures
residue_echo = returns unmatched/invalid material as residue instead of hiding it
```

Trace:

```text
fresh ingestion plan:  ☴☵
fresh ingestion build: ☴☵
soup missing plan:     ☴☵
soup missing build:    ☴☵
```

Residue:

```text
Need decide whether boundary_gate/taste_probe/residue_echo are real new organs,
or just names for existing observe/encode/trace-validator behavior.

Do not code yet.
This may be another channel/boundary problem:
external_channel -> gate -> trace/semantic/runtime channels.
```

Memory:

```text
fresh_ingestion_plan_packet = procesis-fresh-ingestion-plan-2026-07-12
fresh_ingestion_build_packet = procesis-fresh-ingestion-build-2026-07-12
soup_missing_plan_packet = procesis-soup-missing-plan-2026-07-12
soup_missing_build_packet = procesis-soup-missing-build-2026-07-12

logs = sandbox/procesis_fresh_soup_2026-07-12/
```

## 2026-07-12 — Trace Validation Boundary Crystall

Input:

```text
The table is stable enough.
Create crystall for the trace validation boundary.
No code yet.
```

Expected:

```text
Define executable contract for trace validation.
Keep trace, semantic, and runtime channels separate.
Make validation body-owned.
Forbid substrate validity authority.
Define retry feedback without implementing routing.
```

Actual:

```text
Created docs/02_crystall/blueprints/trace_validation_boundary.v0.md.
No code changed.
```

Crystall decisions:

```text
module target: logic/trace_validator.lua
v0 source: core/topology.lua
future source: vendor/procesis/canon.lua
strict extraction: only explicit TRACE lines
substrate validity claims: ignored as semantic noise
invalid traces: residue, no interpretation
retry: feedback helper only; routing later via ☲/☶/☴
```

Trace:

```text
documentation pass only
no runtime packet saved
```

Residue:

```text
Before code, decide whether this ◈ is accepted as the implementation contract.
When coding starts, tests must prove:
- extraction ignores prose glyphs
- ☴☵ is valid
- ☱☱ is invalid
- substrate validity claims do not affect result
```

Memory:

```text
not saved as packet memory yet
docs updated only
```
