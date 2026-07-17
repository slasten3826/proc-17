# Current State - 2026-07-17

Status: active packet-first body

Current transition:

```text
legacy route authority -> opt-in full-tree authority -> measured promotion
```

proc-17 already controls packet movement, operator position, cost, truth status,
terminal death, and inheritance. Its next architectural boundary is not another
interpretation layer. It is the closed work loop: selected work must change the
sandbox, create fresh runtime evidence, and become completed work inside the
packet.

## Runtime Shape

The default control life remains legacy pressure-routed:

```text
▽ birth -> ☴ -> ☵ -> ☴ -> ☳ -> ☴ -> ☱ -> (☶ / ☲ / ☴ / △)
```

The mandatory eye rails in that trace are historical scaffolding. They remain
the default control through `router_mode=shadow`, where the tree observes but
does not move the Packet.

Explicit `router_mode=tree` now grants live authority to the canonical full-tree
derivation. FLOW entry and every later edge are selected from Packet pressure,
registry readiness, capability, affordability, and topology. A confirmed build
life followed:

```text
▽ ☴ ☰ ☵ ☲ ☶ ☱ △
```

`core/packet.lua` commits every route, so `packet.operator`, route events, and
executed tick events share one position. Tree commits additionally require an
immutable pressure snapshot, route derivation, and a ready selected candidate
from that derivation. `runtime/operator_registry.lua` dispatches the organ at
the committed position; it does not choose the next position.

Authority now depends on the explicit mode:

```text
legacy  legacy movement only
shadow  legacy movement, tree observation; current default
tree    tree movement, legacy read-only observation; opt-in experiment
```

Tree mode does not call the legacy router as a prerequisite. After deriving its
live decision, it records the legacy prediction as a read-only observer by
default. `legacy_shadow=false` disables that observer for ablation. The legacy
target is never committed or executed in a tree life.

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

CONNECT and DISSOLVE are registered, implemented, and directly testable. They
remain unreachable from the live legacy router, but CONNECT has now executed in
an opt-in tree-authority life. DISSOLVE still lacks a live rigidity corpus.

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

`runtime/router.lua` records pressure snapshots and immutable route derivations
as append-only trace data. In the default shadow mode it also records the
legacy/tree comparison. `runtime/edge_stats.lua` reads those records into the
run report. Its v1 ledger distinguishes candidate, committed transition,
executed destination, and failed-arrival evidence and preallocates all E01-E22
rows through `runtime/edge_catalog.lua`. It also audits the four temporary eye
rails. `legacy`, `shadow`, and explicit `tree` authority modes are available;
only the first two currently have comparison instrumentation.

### Task-shaped field

`runtime/field.lua` now owns deterministic potential/relation ids, actor rights,
bounded read views, revision increments, raw relation epochs, RUNTIME-only
activation, subtractive relation mutations, unit activation, and ENCODE identity
maps. All six implemented upper-field operators write through this API.

Compatibility projections still coexist with the canonical field. Explicit tree
lives now consume field-backed relation, encoding, choice, and observation
witnesses, while several CALM consumers still read legacy-shaped projections.
The migration remains observable and reversible, but the field is no longer
purely passive in opt-in tree mode.

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
already exist. Semantic-unit coverage drives upper-eye pressure in explicit
tree lives. Historical revision staleness remains available through the
`sampled` diagnostic policy; the legacy router does not consume either form.

The lower routing interpretation now has an L1 camera treatment. The runner
captures one immutable `runtime_frame` after each completed tick's cost and
loss physics without adding another tick or charge. `☱` reads significant
pending frames, appends a `runtime_reconciliation`, and advances a monotonic
watermark. Routine clock/budget telemetry remains visible but does not create
`runtime_reconciliation_debt`; a CALM, choice, validation, cycle, active
relation, evidence, history, momentum, or scalar consequence can. The sampled
lower-eye policy remains available only as an explicit L0 diagnostic control.

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

The execution boundary distinguishes expected world failure from broken body
physics. A well-formed external `effect_failure` becomes an `operator_failure`
trace event and an honest terminal Packet. Untyped Lua errors, malformed failure
objects, and trusted invariant violations remain loud harness failures and may
not enter graves or promotion evidence.

### Mortality and lineage

The normal packet death mechanisms are internal:

- `budget_exhausted`: runtime economics are spent;
- `identity_loss`: encoding and choice have destroyed packet coherence;
- `complete`: the packet reaches MANIFEST with an assembled result.
- `stalled`: a coherent tree derivation has no viable edge;
- `effect_failure`: an attempted external effect failed in a typed way.

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
lua tests/run.lua                    45 suites passed
tests/test_tree_authority.lua        10/10 Gate A cases passed
tests/test_tree_instrumentation.lua  7/7 Gate B cases passed
tests/test_edge_metric_roles.lua     passed
tests/test_tree_manifest_honesty.lua 4/4 Gate 4.2 cases passed
lua tests/smoke_mortality_battery.lua 8/8 cases passed
lua tests/smoke_runtime_camera_treatment.lua passed
lua tests/smoke_pressure_ablation.lua passed
lua tests/smoke_deepseek_tension_runner.lua passed through ☱ twice
luac -p over all Lua sources         passed
```

The first confirmed opt-in tree build produced:

```text
walk: ▽ ☴ ☰ ☵ ☲ ☶ ☱ △
7 ticks, one accepted validation, loss 0.5
manifested -> dead/complete
manifest input_provenance = packet_trace
```

The Gate A suite also confirms typed stalled birth, typed external failure,
rejected validation survival, strict derivation refs, and loud invariant
failure. The initial red baseline and treatment history are preserved in
[`../00_chaos/tree_authority_opt_in_results_2026-07-17.md`](../00_chaos/tree_authority_opt_in_results_2026-07-17.md).

Gate B reversed instrumentation without changing the default authority. The
confirmed tree life produced seven tree derivations and seven legacy observer
records. Observer ablation left routes, economics, loss, revisions, evidence,
and terminal state identical; only seven append-only measurement events were
removed. Legacy agreed twice, diverged five times, and reported one typed
unavailable source at CONNECT. The complete record is preserved in
[`../00_chaos/tree_legacy_shadow_flip_results_2026-07-17.md`](../00_chaos/tree_legacy_shadow_flip_results_2026-07-17.md).

Promotion measurements now use `edge-stats.v2`. Route comparisons are keyed by
the observer and observed authority; rail evidence is split between
`tree_shadow` counterfactual predictions and `tree_authority` derivations. The
old cross-observer agreement totals and role-changing flat rail counters were
removed. Mixed v1/v2 ledgers fail loudly instead of silently promoting
historical evidence. The contract is recorded in
[`../02_crystall/blueprints/edge_evidence_roles.v0.md`](../02_crystall/blueprints/edge_evidence_roles.v0.md).

Manifest honesty step 4.2 closes the rejected-validation laundering defect.
MANIFEST reads both the validation record and the latest runtime reconciliation,
preserves the semantic text, and projects a body-owned `blocked` outcome through
output, summary, assembly, terminal, death, and corpse residue. A normal
accepted build remains `complete`. The permanent grown-life gate is `4/4`
green; the treatment record is preserved in
[`../00_chaos/tree_manifest_honesty_treatment_results_2026-07-17.md`](../00_chaos/tree_manifest_honesty_treatment_results_2026-07-17.md).

A local L0/L1 fake-substrate treatment confirms that the continuous camera does
not alter the live route, step/substrate budget, or identity loss. In both plan
and build lives, sampled lower pressure produced six lower debts and five
duplicate mismatches. L1 produced five bounded reconciliation debts and zero
sampled lower debts or duplicate mismatches. The final one or two pending frames
were routine telemetry with zero significant debt.

The first merged plan/build edge corpus records:

```text
6/22 edges complete in every legal direction
1/22 partial
15/22 without an executed direction
```

Upper eye debt was bypassed by the shadow prediction in every observed
`☵ -> ☴` and `☳ -> ☴` rail case. Historical L0 lower debt selected both lower
rails because ☱ was counted twice. L1 now grows one real reconciliation witness
after ☲ and ☶, but tied binary pressure may select a different neighbor. All
rail promotion states remain `insufficient_evidence`. The historical matrix is preserved in
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
2. **Canonical field migration is incomplete.** FLOW/OBSERVE/ENCODE/CHOOSE and
   explicit tree routing consume field records, but CALM and several organ
   inputs still retain compatibility projections.
3. **Relation authority is partial.** CONNECT executes in an opt-in tree life;
   DISSOLVE has no live rigidity corpus and its readiness does not yet receive
   the exact rigidity witness that created its pressure. ☱ does not yet apply
   relation momentum.
4. **Camera pressure is uncalibrated.** Reconciliation debt can govern explicit
   tree lives, but all coefficients remain one and the default mode still grants
   movement to legacy control.
5. **The sandbox is not ready for hands.** Shell execution exists in spells,
   while the public sandbox command policy denies all commands. Filesystem path
   checks are lexical and need protection against symlink escape.
6. **Memory has writers without readers.** Bequests enter unresolved pressure,
   but ENCODE does not consume it. Compost patterns are stored but do not yet
   affect router or foundation.
7. **Session lifecycle is not runner-owned.** Session and packet memory modules
   exist as libraries, not one automatic birth-to-grave lifecycle.
8. **Tree authority is opt-in v0.** It is a deterministic, binary function of
   explicit Packet records and can manifest a build life, but its constants are
   unmeasured. The legacy observer and v2 evidence roles are isolated and
   measured; the promotion corpus is still open.
9. **User surfaces are absent.** The machine CLI and Go TUI have designs only.

Several modules are currently standalone or partially integrated, including
`runtime/pressure_snapshot.lua`, `runtime/trace_store.lua`,
`runtime/packet_memory.lua`, `runtime/session_memory.lua`, `tools/fs.lua`,
`logic/repo_selection.lua`, and `logic/trace_validator.lua`.

## Next Architecture Target

Gates A and B are complete. Finish the authority transition before granting
repository mutation:

1. grow a tree-life corpus containing manifest, stall, rejected validation,
   typed external failure, mortality, CONNECT, and a real DISSOLVE witness;
2. document calibration defects without hiding them behind legacy rails;
3. change the default from `shadow` to `tree` only in a separate reviewed step,
   preserving explicit legacy control.

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
