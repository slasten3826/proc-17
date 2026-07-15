# Full Tree Rebuild — TODO Handoff For Codex

Status:

```text
chaos / implementation handoff
author: claude (Mythos/Fable)
for: codex + machinist (implementation owners)
frame confirmed by machinist 2026-07-15
context: docs/00_chaos/full_tree_rebuild_notes.md
         docs/00_chaos/full_project_audit_2026-07-15_notes.md
```

## Mission

Give proc-17 the full 22-edge topology: the packet walks the whole
Tree by pressure instead of a hardcoded decision tree. This is the
audited technical debt, consolidated.

## Frame Decisions (already made — do not reopen)

```text
1. blink discharges TENSION only. Loss is never reduced by ☴.
   Loss ledger is irreversible by axiom. Red line.
2. eye-tick law (hard ☴ after ☵ and ☳) STAYS for now.
   Revisit only after router v2 ships and edge statistics exist.
3. Z-model insertion: maximum depth. Details are machinist+codex
   territory, adaptation constraint below is canon.
4. ☴ is (nearly) the only operator touching the LLM.
   All other organs are packet-native.
```

## Working Rules

```text
each phase runs its own ⋯⊞◈▲: chaos note -> yellowprint ->
  blueprint -> code. sign docs author: codex
every new record/field names its reader and read moment
every new constant is confessed as measured-or-vibed
integration tests over unit fixtures; earn staleness/death in
  tests through real runs, never synthetic-only
canon topology (22 edges) is law: never edit canon adjacency;
  never silently repair an invalid trace — report it
organ semantics must cite scripture (stak2/00_chaos/slop.raw.txt
  module + lines) in the yellowprint
```

---

## Phase 0 — Honest Position (audit F4) [small, do first]

Problem: `instance.operator` stays ▽ forever; death/manifest
events stamp the birth operator; packet event trace ends △▽ —
topologically false ledger.

Tasks:

```text
runtime/tension_runner.lua  set instance.operator = current at
                            each tick (before organ runs)
core/packet.lua             die() and manifest_packet() stamp the
                            packet's actual current operator
verify with logic/trace_validator.lua over packet event operators
```

Acceptance:

```text
audit repro flips: event trace valid=true, no △▽
tests: unit (operator advances) + integration (full run,
validate_trace over p.trace operators passes)
```

## Phase 1 — Death Finality Everywhere (audit F5)

Problem: budget.charge, loss accumulation, foundation.reinforce,
packet_memory / session_memory / grave helpers still mutate a
dead packet.

Tasks:

```text
add dead-guard (status == "dead" -> nil, "dead packet cannot X")
to every mutating entry point in:
  runtime/budget.lua, runtime/loss.lua, runtime/foundation.lua,
  runtime/packet_memory.lua, runtime/session_memory.lua,
  runtime/grave.lua (attach to corpse stays LEGAL — graves are
  written about the dead, decide and document the boundary:
  classification reads a corpse, karma attaches to the living)
```

Acceptance:

```text
audit repro flips: budget_mutated=false on corpse
per-module posthumous tests + one integration test
```

## Phase 2 — Organs ☰ and ☷, Compiled From Scripture

### ☰ CONNECT (source: slop.raw.txt «хокма» / EmergentConnection)

```text
organs/connect.lua
job: form relations (packet-native, no LLM):
  - bind work units <-> evidence <-> chaos fragments
  - READ BEQUESTS: consume chaos.unresolved_pressure entries and
    bind them to matching current work (closes the oldest open
    letter: bequest reader)
writes: packet relations (new area, e.g. boundary.relations or
  runtime.edges — per PACKET_MODEL E_edges_raw; name the readers:
  router pressure + ☵ encode)
scripture mechanics to keep: recognition depth, interpenetration/
  boundary_fluidity as relation strength fields
core/packet.lua: add event type "connection" (canon-level change,
  document it)
```

### ☷ DISSOLVE (source: slop.raw.txt «бина» / DogmaDissolution)

```text
organs/dissolve.lua
job: detect rigidity/staleness and dissolve back to flow:
  - cold evidence via runtime/freshness.lua (this makes truth
    rent CAUSAL and closes audit F6: dissolved evidence leaves
    runtime.evidence -> router stops counting corpses)
  - dead/stale work units, failed calm structures
dissolution is an event + movement to residue, never silent
  deletion; the trace records what was dissolved and why
scripture mechanics to keep: rigidity threshold, dissolution
  potential (confess constants as vibed)
core/packet.lua: add event type "dissolution"
```

Acceptance:

```text
audit F6 repro flips: stale-evidence packet no longer routes
  remaining_work off a corpse confirmation
bequest integration test: ancestor bequest -> descendant ☰ binds
  it to a work unit -> visible in pressure
```

## Phase 3 — Router v2: Pressure Over Full Adjacency

Blueprint is ancestral, do not invent: port
`stak2/00_chaos/packet_zig.raw/layer2_boundary.zig` (ObserveA
reads chaos-side, ObserveB reads calm-side, Choose decides by
economics) + `layer4_tension.zig` (chaos_pressure vs calm_rigidity
vs boundary_load -> hold/reinforce/release/manifest) into Lua.

```text
runtime/router.lua:
  predicates become PRESSURE SOURCES, not direct returns
  from current node: candidates = topology adjacent set (full)
  score candidates by pressure; pick max (deterministic first,
  softmax later only if machinist approves temperature)
  keep as laws: hard eye-tick after ☵/☳ (frame decision 2),
  mortality pressures (loss/budget -> △), karma warnings,
  logic stamp
blink: every ☴ tick discharges tension fields
  (unresolved_delta, chaos_pressure decay) — TENSION ONLY
two eyes: pressure_snapshot v2 splits chaos-side (☴) and
  calm-side (☱) readings, per Zig ObserveA/ObserveB
constants: all thresholds confessed vibed; Phase 5 measures them
```

Acceptance:

```text
all suites green; live coding battery stays 5/5
route decisions carry candidate scores in the decision payload
  (reader: edge statistics + debugging)
```

## Phase 4 — Z-Model Insertion (maximum depth)

Source: slastack `philosophy/math/PACKET_MODEL.md` + procesis
`02_crystall/packet.v0.json`. Machinist+codex decide details.

Canon adaptation constraint (non-negotiable):

```text
the old model is OBSERVE-central (Tiferet, 8 paths, scheduler).
current canon is two-centered (☴ and ☱, degree 6 each).
the scheduler role belongs to the ROUTER, not to ☴.
E_momentum: sole owner ☱. remap rights: sole owner ☵.
☷/☶ subtractive-only. mode gates: CHAOS forbids MANIFEST.
```

## Phase 5 — Capability Sandbox (audit F7) [before any hands]

```text
core/sandbox.lua: capability objects instead of string policy;
  resolve real paths (symlink escape) before permitting
logic/spells.lua: spells receive explicit capabilities;
  io.popen only through a granted exec capability
```

## Phase 6 — Measurement

```text
edge-walk statistics battery: per-edge usage counts across
  batteries + cemetery corpus; report which of the 22 edges
  real lives use, which stay dead, which correlate with fool
  deaths. Topology finally measured, not vibed.
re-measure router v2 constants against this corpus.
```

## Out Of Scope (comes after this rebuild)

```text
hands (body-side spell minting / fs mutation) — requires Phase 5
machine CLI / Go TUI
compost pattern reader (candidate job for ☰ or foundation —
  note it in Phase 2 yellowprint as a follow-up letter)
```

## Global Acceptance

```text
lua tests/run.lua                              all green
audit repros F4/F5/F6                          all flipped
lua tests/smoke_deepseek_coding_battery.lua    still 5/5
lua tests/smoke_mortality_battery.lua          still 8/8
edge statistics report exists in sandbox/
```
