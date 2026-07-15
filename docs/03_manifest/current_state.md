# Current State - 2026-07-15

Status: active packet-first body

Current transition:

```text
working process physics -> body that performs and verifies real work
```

proc-17 already controls packet movement, cost, truth status, death, and
inheritance. Its next architectural boundary is not another interpretation
layer. It is the closed work loop: selected work must change the sandbox, create
fresh runtime evidence, and become completed work inside the packet.

## Runtime Shape

The active runner is pressure-routed:

```text
▽ birth -> ☴ -> ☵ -> ☴ -> ☳ -> ☴ -> ☱ -> (☶ / ☲ / ☴ / △)
```

This is not a fixed full trace. `runtime/router.lua` chooses the next operator
from packet state. Topology constrains allowed movement, and ☴ or ☱ must observe
the body after state-changing operators.

Two runners remain intentionally:

- `runtime/runner.lua` is the old fixed single-pass smoke rail.
- `runtime/tension_runner.lua` is the active pressure-driven route engine.

## Implemented Layers

### Packet physics

`core/packet.lua` owns the mortal task instance:

- CHAOS, CALM, BOUNDARY, substrate/physis, and trace areas;
- truth status on trace events;
- budget and identity-loss state;
- lifecycle states, death causes, and residue;
- crystallization and manifestation boundaries.

`runtime/budget.lua` charges runtime economics. `runtime/loss.lua` accumulates
identity loss from ENCODE and CHOOSE. CYCLE spends budget but does not create
identity loss.

### Operators and movement

- `organs/observe.lua`: asks the substrate and appends semantic proposals to CHAOS.
- `organs/encode.lua`: forms packet-native structure in CALM with visible loss.
- `organs/choose.lua`: selects under pressure and records killed alternatives.
- `logic/cycle.lua`: decides bounded continuation without choosing task meaning.
- `logic/spells.lua`: executes configured validation spells and records whether reality changed.
- `logic/manifest.lua`: classifies and assembles the outward result.
- `runtime/router.lua`: derives movement from packet pressure.
- `runtime/tension_runner.lua`: executes the routed life of the packet.

CONNECT and DISSOLVE remain packet laws and topology positions, but are not yet
implemented as live organs.

### Epistemics

The body distinguishes at least:

```text
semantic_proposal   substrate meaning, not runtime fact
runtime_confirmed   body-observed event or evidence
estimated           locally estimated usage, such as fallback token counts
grave_pressure      inherited applicability claim, not the ancestor's death fact
```

`runtime/freshness.lua` and `runtime/foundation.lua` track truth rent and stale
evidence. The build lower triangle has a LOGIC stamp so unchanged evidence is
not repeatedly validated forever.

### Mortality and lineage

The normal packet death mechanisms are internal:

- `budget_exhausted`: runtime economics are spent;
- `identity_loss`: encoding and choice have destroyed packet coherence;
- `complete`: the packet reaches MANIFEST with an assembled result.

`runtime/grave.lua` classifies residue:

- a no-progress death becomes a warning;
- a progress-bearing budget death becomes a bequest;
- identity loss becomes a warning;
- completed work is neutral.

Warnings can alter a descendant route. Session-scoped graves are bounded by
`runtime/session_memory.lua`; old individual graves compost into aggregate
patterns instead of persisting forever.

### Substrates and tools

Substrate adapters exist for fake and OpenAI-compatible models, including
DeepSeek. The substrate contributes semantic current but does not own runtime
truth or routing.

Tool contracts, fake tools, filesystem helpers, sandbox policy, and spell
execution exist. They are not yet assembled into a body-owned repository
mutation loop.

## Measured Evidence

Current local audit results:

```text
lua tests/run.lua                    30 suites passed
lua tests/smoke_mortality_battery.lua 8/8 cases passed
luac -p over all Lua sources         passed
```

The grave generation experiment has a control line:

```text
with grave: generation 1 dies in the loop; descendants manifest after 9 ticks
orphans:    each generation repeats the 14-tick budget death
```

The live coding battery produced five manifested code artifacts that passed
external validation after the LOGIC-stamp change. This proves that the body can
deliver useful code through the substrate. It does not yet prove autonomous
repository work: the battery harness extracts the artifact, writes it, and runs
the checks outside the body.

## Known Defects And Open Boundaries

1. **No hands.** Selected work units are recorded but not executed by the body;
   their status does not progress to `done` through real repository mutation.
2. **Trace ownership is incomplete.** The tension runner advances a local
   operator, but `packet.operator` remains stale. A real event trace can end in
   the invalid edge `△ -> ▽` when reconstructed from packet events.
3. **Death finality is partial.** Core packet mutations are guarded, but budget,
   loss, foundation, memory, and grave modules can still mutate a dead packet.
4. **Truth rent does not yet govern routing.** Freshness is observed, while the
   router still counts the raw evidence list; stale evidence can influence the
   next route as if it were fresh.
5. **The sandbox is not ready for hands.** Shell execution exists in spells,
   while the public sandbox command policy denies all commands. Filesystem path
   checks are lexical and need protection against symlink escape.
6. **Memory has writers without readers.** Bequests enter unresolved pressure,
   but ENCODE does not consume it. Compost patterns are stored but do not yet
   affect router or foundation.
7. **Session lifecycle is not runner-owned.** Session and packet memory modules
   exist as libraries, not one automatic birth-to-grave lifecycle.
8. **Pressure routing is v0.** It is a deterministic function of explicit packet
   fields, not yet the richer density-driven organogenesis envisioned in chaos.
9. **User surfaces are absent.** The machine CLI and Go TUI have designs only.

Several modules are currently standalone or partially integrated, including
`runtime/pressure_snapshot.lua`, `runtime/trace_store.lua`,
`runtime/packet_memory.lua`, `runtime/session_memory.lua`, `tools/fs.lua`,
`logic/repo_selection.lua`, and `logic/trace_validator.lua`.

## Next Architecture Target

Before granting the body repository mutation:

1. make the packet's current operator and event trace agree;
2. enforce finality across every packet-mutating module;
3. make evidence freshness affect routing and validation;
4. replace the shell-shaped sandbox boundary with explicit capabilities.

Then close the first real work loop:

```text
☵ forms executable work
☳ selects one work unit
hands mutate only the sandbox capability
☶ obtains fresh runtime evidence
☱ observes actual progress
the work unit becomes done
☲ continues or stops
△ assembles the verified result
```

The detailed audit and authorship reconstruction are preserved in
[`../00_chaos/full_project_audit_2026-07-15_notes.md`](../00_chaos/full_project_audit_2026-07-15_notes.md).
