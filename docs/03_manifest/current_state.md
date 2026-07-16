# Current State - 2026-07-16

Status: active packet-first body

Current transition:

```text
working process physics -> body that performs and verifies real work
```

proc-17 already controls packet movement, operator position, cost, truth status,
terminal death, and inheritance. Its next architectural boundary is not another
interpretation layer. It is the closed work loop: selected work must change the
sandbox, create fresh runtime evidence, and become completed work inside the
packet.

## Runtime Shape

The active runner is pressure-routed:

```text
▽ birth -> ☴ -> ☵ -> ☴ -> ☳ -> ☴ -> ☱ -> (☶ / ☲ / ☴ / △)
```

This is not a fixed full trace. `runtime/router.lua` chooses the next operator
from packet state. Topology constrains allowed movement, and ☴ or ☱ must observe
the body after state-changing operators. `core/packet.lua` commits every route,
so `packet.operator`, route events, and executed tick events share one position.
`runtime/operator_registry.lua` now resolves and dispatches the organ at that
position; it does not choose the next position.

The authoritative route is still the legacy pressure router. By default the
tension runner now also executes `pressure.binary.v0` and the full-tree router
in shadow. The shadow observes the same post-tick state and records a prediction,
but cannot change Packet position, economics, loss, or semantic state.

Two runners remain intentionally:

- `runtime/runner.lua` is the old fixed single-pass smoke rail.
- `runtime/tension_runner.lua` is the active pressure-driven route engine.

## Implemented Layers

### Packet physics

`core/packet.lua` owns the mortal task instance:

- CHAOS, CALM, BOUNDARY, substrate/physis, and trace areas;
- truth status on trace events;
- lineage/generation identity and a revisioned task-shaped field/regime root;
- canonical upper/lower eye observations carrying the exact revisions they read;
- body-owned operator position with atomic topology-checked transitions;
- budget and identity-loss state;
- lifecycle states, terminal records, death causes, and residue;
- crystallization and manifestation boundaries.

`runtime/budget.lua` charges runtime economics. `runtime/loss.lua` accumulates
identity loss from ENCODE and CHOOSE. CYCLE spends budget but does not create
identity loss. Budget, loss, foundation, grave, packet memory, organs, and body
mutators all reject a terminal Packet; read snapshots do not mutate its corpse.

### Operators and movement

- `organs/flow.lua`: materializes user or lineage ingress as newborn potential.
- `organs/connect.lua`: records bounded candidate relations as one transient
  `E_raw` epoch without activating or preserving them.
- `organs/dissolve.lua`: subtractively weakens or dissolves active relations
  under runtime-confirmed reasons and returns mechanical residue when preserved.
- `organs/observe.lua`: asks the substrate, records a confirmed upper-eye act,
  and appends proposal content to CHAOS and the canonical field.
- `organs/encode.lua`: forms packet-native structure in CALM with visible loss,
  shadow field units, and an explicit identity map.
- `organs/choose.lua`: selects under pressure, records killed alternatives, and
  changes canonical unit activation without rewriting identity or carrier.
- `organs/runtime.lua`, `organs/cycle.lua`, `organs/logic.lua`, and
  `organs/manifest.lua`: expose the lower operators through the same organ
  contract as the upper field operators.
- `logic/cycle.lua`: decides bounded continuation without choosing task meaning.
- `logic/spells.lua`: executes configured validation spells and records whether reality changed.
- `logic/manifest.lua`: classifies and assembles the outward result.
- `runtime/router.lua`: derives movement from packet pressure.
- `runtime/tension_runner.lua`: executes the routed life and commits movement
  through the Packet body.

`runtime/operator_registry.lua` contains exactly ten descriptors in canonical
ProcessLang order. Every descriptor names its read areas, write areas, required
capabilities, loss profile, readiness witness, and executable organ. The active
tension runner dispatches every tick through this registry instead of a private
operator `if` chain. These rights are declarations in v0; lower storage APIs
remain responsible for enforcing their concrete mutations.

CONNECT and DISSOLVE are registered, implemented, and directly testable, but
intentionally remain unreachable from the live legacy router. They now appear
as audited shadow candidates; any real authority remains a later promotion, not
an immediate replacement of the current rails.

### Named pressure and shadow routing

`runtime/pressure.lua` derives binary, provenance-bearing contributions for
relation debt, rigidity, both eye debts, encoding, choice, runtime mismatch,
validation, continuation, manifestation, and grave inheritance. Absence of a
witness emits no contribution. Every current coefficient is exactly `1` and
the policy identifies itself as `vibed_control`, not measured physics.

`runtime/tree_router.lua` audits every canon-adjacent neighbor in stable
ProcessLang order. It applies same-life direction, registry availability,
capability, readiness, affordability, and positive-pressure filters. Excluded
candidates remain visible, and failure produces typed `no_viable_edge` rather
than a hidden fallback. Router movement remains separate from semantic ☳ and
creates no CHOOSE loss.

`runtime/router.lua` records each pressure snapshot and legacy/tree comparison
as append-only trace data. `runtime/edge_stats.lua` reads those comparisons into
the run report. Its v1 ledger distinguishes candidate, committed transition,
and executed destination evidence and preallocates all E01-E22 rows through
`runtime/edge_catalog.lua`. It also audits the four temporary eye rails.
`legacy` and `shadow` modes are available; `tree` authority is explicitly
rejected until promotion evidence exists.

### Task-shaped field

`runtime/field.lua` now owns deterministic potential/relation ids, actor rights,
bounded read views, revision increments, raw relation epochs, RUNTIME-only
activation, subtractive relation mutations, unit activation, and ENCODE identity
maps. All six implemented upper-field operators write through this API.

This is intentionally a shadow migration. Existing CHAOS input, CALM structures,
loss accounting, and `runtime/router.lua` remain behavior-authoritative. The
field records the same life in parallel and names its current reader, but routing
does not consume it yet. This keeps the migration observable and reversible.

### Two eyes and revision freshness

`boundary.observations.upper` and `boundary.observations.lower` now use one
shared envelope. Each record separates the confirmed act of observation from
the truth status of its content and stores a bounded scope plus the Packet
revisions actually read.

`☴` emits the upper record around substrate observation. `☱` emits the same
shape for CALM, evidence, foundation, budget, and loss. The old
`chaos.observations` name is an alias of the canonical upper store, while the
old tension snapshot remains a compatibility projection.

`runtime/freshness.lua` compares an immutable observation's read revisions with
the current revision vector and returns `fresh`, `stale`, or `missing`. It does
not mutate history. Potential, CALM, constraints, evidence, history, budget,
and loss writers now advance their owned revision axes where those mutations
already exist. Eye freshness is recorded and testable but remains shadow-only;
the legacy router does not consume it yet.

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

MANIFEST is a terminal kind, not a temporary living status. Both successful
manifestation and internal death produce a typed terminal record, seal the
trace, and leave `status = dead`.

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
lua tests/run.lua                    39 suites passed
lua tests/smoke_mortality_battery.lua 8/8 cases passed
luac -p over all Lua sources         passed
```

A local eight-tick fake-substrate ablation confirms that enabling shadow mode
does not alter the live route, step/substrate budget, or identity loss. The
control trace currently contains both agreements and divergences, so the shadow
policy is not merely copying legacy decisions.

The first merged plan/build edge corpus records:

```text
6/22 edges complete in every legal direction
1/22 partial
15/22 without an executed direction
```

Upper eye debt was bypassed by the shadow prediction in every observed
`☵ -> ☴` and `☳ -> ☴` rail case. Lower eye debt recreated both observed lower
rails. All rail promotion states remain `insufficient_evidence`. The complete
matrix is preserved in
[`full_tree_edge_evidence.v0.md`](full_tree_edge_evidence.v0.md).

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
2. **Canonical field is shadow-only.** FLOW/OBSERVE/ENCODE/CHOOSE mirror their
   state through the field API, but current ENCODE input, CALM consumers, and the
   router still use compatibility projections.
3. **Relations have no live authority yet.** Raw snapshots, RUNTIME activation,
   weakening, dissolution, and residue are canonical and tested. ☰/☷ now have
   registry contracts, but the legacy router cannot select them and ☱ does not
   yet apply relation momentum.
4. **Freshness does not yet govern live routing.** Both eyes now expose revision
   freshness and the shadow router consumes it as named debt, while the legacy
   router still counts raw records; stale inputs can influence its real route.
5. **The sandbox is not ready for hands.** Shell execution exists in spells,
   while the public sandbox command policy denies all commands. Filesystem path
   checks are lexical and need protection against symlink escape.
6. **Memory has writers without readers.** Bequests enter unresolved pressure,
   but ENCODE does not consume it. Compost patterns are stored but do not yet
   affect router or foundation.
7. **Session lifecycle is not runner-owned.** Session and packet memory modules
   exist as libraries, not one automatic birth-to-grave lifecycle.
8. **Pressure routing is shadow v0.** It is a deterministic, binary function of
   explicit Packet records. Its constants are unmeasured, several readiness
   contexts are incomplete, and it has no live authority.
9. **User surfaces are absent.** The machine CLI and Go TUI have designs only.

Several modules are currently standalone or partially integrated, including
`runtime/pressure_snapshot.lua`, `runtime/trace_store.lua`,
`runtime/packet_memory.lua`, `runtime/session_memory.lua`, `tools/fs.lua`,
`logic/repo_selection.lua`, and `logic/trace_validator.lua`.

## Next Architecture Target

Before granting the body repository mutation, continue the packet-physics
migration without switching the live router prematurely. The shared eye
envelope, operator registry, and first shadow router are complete. The remaining
sequence is:

1. grow destination execution for shadow-selected E05, E12, and E15;
2. grow the reverse E11 direction and dedicated E01/E02/E04 lives;
3. promote field consumers only after old/new behavior comparisons are green;
4. make evidence freshness affect live routing and validation;
5. promote tree authority only through an explicit reviewed record;
6. replace the shell-shaped sandbox boundary with explicit capabilities.

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
