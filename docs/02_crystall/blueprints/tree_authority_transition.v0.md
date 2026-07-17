# Tree Authority Transition Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/tree_authority_transition_yellowprint.v0.md
implementation target: staged tree authority promotion
production code unchanged at blueprint creation
Gate A implemented and confirmed: 2026-07-17
Gate B implemented and confirmed: 2026-07-17
edge evidence roles v2 confirmed: 2026-07-17
manifest honesty red gate confirmed: 2026-07-17
manifest honesty treatment confirmed: 2026-07-17
current transition checkpoint: 4.2 complete
next checkpoint: promotion corpus
```

## 1. Objective

Replace legacy live route authority with full-tree pressure authority without:

```text
committing unready organs
turning expected world failures into harness aborts
turning Lua/invariant failures into false Packet deaths
losing route derivation evidence
making normal build manifestation unreachable
breaking mortality, finality or shadow isolation
```

Legacy remains an explicit control policy.

## 2. Target Modules

```text
core/packet.lua                    route/failure event types and death causes
runtime/tree_router.lua            authoritative derivation result
runtime/router.lua                 authority modes and legacy shadow
runtime/operator_registry.lua      structured execution boundary
runtime/tension_runner.lua         entry, commit, execution and terminal handling
runtime/pressure.lua               Packet-local normal manifest witness
runtime/edge_stats.lua             failed arrival and tree-live evidence
organs/manifest.lua                Packet-owned manifest input
substrates/contract.lua            typed external effect failures
tests/test_tree_authority.lua       permanent Gate A contract
tests/test_tree_instrumentation.lua permanent Gate B contract
tests/test_tree_router.lua
tests/test_shadow_router.lua
tests/test_tension_runner.lua
tests/test_manifest.lua
tests/run.lua                       Gate A registered after green
```

No calibration weight changes belong to the authority implementation commit.

## 3. Structured Outcome Contracts

### 3.1 Readiness

Existing registry readiness remains:

```lua
{
  operator = glyph,
  ready = boolean,
  reason = string,
  source_refs = table,
  event_truth_status = "runtime_confirmed",
}
```

Tree derivation calls readiness before commit. `ready=false` is not an organ
execution result.

### 3.2 Applied execution

Registry success becomes or is wrapped as:

```lua
{
  kind = "operator_execution_outcome",
  status = "applied",
  operator = glyph,
  payload = table,
  readiness = table,
}
```

### 3.3 Expected effect failure

External adapters/organs return a typed failure object:

```lua
{
  kind = "effect_failure",
  source = "substrate" | "tool" | "sandbox" | "storage",
  code = string,
  message = string | nil,
  source_refs = table,
  retryability = "unknown" | "retryable" | "terminal",
  cost = table, -- only externally confirmed usage; body tick is separate
  event_truth_status = "runtime_confirmed",
}
```

Registry wraps it as:

```lua
{
  kind = "operator_execution_outcome",
  status = "effect_failure",
  operator = glyph,
  failure = table,
  readiness = table,
}
```

The first implementation does not retry. It records, charges the attempted
tick once, captures the resulting frame and dies with cause
`effect_failure`.

### 3.4 Invariant failure

Untyped errors, Lua exceptions and trusted contract violations are returned
or raised outside the structured effect outcome. `tension_runner` propagates
them as harness failures. It must not call `packet.die` for them.

## 4. Route Derivation Record

Add Packet event type:

```text
route_derivation
```

Authoritative derivation trace payload:

```lua
{
  kind = "route_derivation",
  current_operator = glyph,
  pressure_snapshot_ref = string,
  candidates = table,
  outcome = "selected" | "no_viable_edge",
  selected_to = glyph | nil,
  no_viable_cause = string | nil,
  policy = string,
  policy_status = string,
  threshold = number,
}
```

`runtime/tree_router.lua` remains pure over the supplied snapshot. A body
adapter in `runtime/router.lua` appends the derivation event and returns a
decision carrying its trace ref.

## 5. Commit Contract

Extend `packet.commit_transition` trace payload to preserve:

```lua
derivation_ref
pressure_snapshot_ref
selected_candidate
policy
threshold
```

For tree authority:

```text
decision.from equals current Packet operator
decision.to is adjacent and same-life legal
selected_candidate.to equals decision.to
selected_candidate.readiness.ready is true
derivation_ref names an immutable route_derivation event
```

Violation is an invariant failure, not stalled Packet death.

Legacy/control route events may carry `derivation_ref=nil` and must be marked
with `authority="legacy_control"`.

## 6. Tree Authority API

`runtime/router.lua` keeps:

```lua
router.after_tick(instance, tick, options)
```

Mode behavior:

```text
legacy:
  legacy decision only

shadow:
  legacy live decision
  tree derivation recorded as shadow evidence

tree:
  pressure snapshot -> candidates -> tree selection
  selected decision or typed no_viable_edge
  optional legacy prediction attached as shadow evidence
```

Remove the `tree_authority_not_promoted` return only for explicit tree mode in
the first implementation. Default remains `shadow` until Gate C.

Do not call `legacy_after_tick` as a prerequisite for tree derivation. Tree
authority must be able to operate when legacy has no supported source path.

## 7. FLOW Entry

After successful FLOW ingress:

```text
derive pressure with current_operator=▽
build tree candidates from ☰, ☷, ☴
record route_derivation
commit selected route or apply no_viable terminal law
```

`options.start_operator` behavior:

```text
legacy/shadow -> compatibility behavior unchanged
tree -> ignored unless options.tree_test_override=true
override route is marked authority="harness_override" and cannot count as
            tree promotion evidence
```

## 8. No-Viable Handling

Add death cause:

```text
stalled
```

Runner receives the full `no_viable_edge` derivation and:

```text
if cause == unsafe:
  use existing unsafe terminal cause
elseif economics are exhausted:
  use budget_exhausted or identity_loss mortality
else:
  die cause=stalled
  residue.stall_kind=no_viable.cause
  residue.candidate_audit_ref=derivation.trace_event_id
```

No route is committed and no additional step is charged for the derivation.

## 9. Failed Execution Handling

Add event type and death cause:

```text
operator_failure
effect_failure
```

When registry returns a typed effect failure after a committed arrival:

```text
append operator_failure event
record committed edge as failed, not executed
charge one attempted step and any confirmed external usage
apply no identity loss unless the organ contract produced real irreversible loss
capture runtime frame containing the failure event
die cause=effect_failure
residue names operator, failure code/source and committed route ref
```

Do not derive another route in v0.

When execution returns an untyped error or raises:

```text
propagate harness failure
do not call mortality/manifest/grave
do not classify the committed edge as failed Packet evidence
```

The partial trace is diagnostic only and cannot enter lineage.

## 10. Packet-Local Manifest

Extend `pressure.readers.manifest` with:

```text
current logic stamp exists
stamp evidence fingerprint equals current evidence fingerprint
work remains
no new body evidence has appeared since the stamp
```

Contribution:

```lua
{
  kind = "manifest",
  target_operator = "△",
  reason = "logic_stamp_no_new_evidence",
  source_refs = {logic_stamp trace ref, evidence fingerprint ref},
}
```

`organs/manifest.lua` must reconstruct bounded input from Packet-owned state:

```text
latest upper observation/semantic proposal
latest crystallization/choice/cycle refs
logic stamp and evidence refs
current CALM/progress/loss/budget summary
```

`options.result` compatibility use is marked in output provenance and cannot
be the only readiness witness in tree mode.

## 11. Legacy Shadow After Flip

When tree controls live movement:

```text
compute legacy_after_tick read-only
do not commit it
do not call its target organ
record predicted_to/reason and divergence from tree live route
```

Legacy prediction failure is instrumentation failure, not Packet physics.

The flip must pass an ablation proving tree lives are identical with legacy
shadow enabled and disabled in:

```text
live routes
steps/substrate calls/tool calls
identity loss
revisions
terminal outcome
```

Gate B treatment result:

```text
7/7 permanent instrumentation cases green
43 main suites green
one legacy observation per tree derivation, including FLOW
observer on/off changes only seven append-only measurement events
legacy CONNECT absence is typed unavailable instrumentation
tree candidate audits feed edge evidence without legacy pollution
```

## 12. Edge Statistics

Extend edge evidence with:

```text
failed_arrival_count
failure_refs
authority = tree | legacy_control | harness_override
derivation_ref
```

Rules:

```text
candidate does not imply committed
committed does not imply executed
effect failure adds failed arrival, not executed arrival
invariant failure invalidates the run and adds no promotion evidence
harness override adds no tree evidence
```

## 13. Red-To-Green Implementation Order

```text
M1 keep the pending tree-authority gate red and outside main suite
M2 structured effect outcome + stalled/effect terminal laws
M3 Packet-local manifest witness/material
M4 tree mode authority + FLOW derivation + commit evidence
M5 legacy shadow flip and edge evidence
M6 register Gate A when green; then grow the Gate C promotion corpus
M7 separate commit changes default from shadow to tree
```

Production changes may split M2-M5 into smaller commits. No step may weaken
the invariant-failure boundary merely to make the promotion gate green.

## 14. Acceptance

Gate A is satisfied when:

```text
permanent tree authority battery is fully green
all existing Lua suites remain green
8/8 mortality remains green
normal build manifests under explicit tree mode
rejected validation never commits an unready ☱
typed substrate failure creates effect_failure terminal
injected Lua exception remains a harness failure
every tree route event references immutable derivation evidence
tree FLOW entry is body-derived
```

Gate A treatment result:

```text
10/10 permanent gate cases green
42 main suites green
8/8 mortality cases green
normal build walk: ▽ ☴ ☰ ☵ ☲ ☶ ☱ △
```

This blueprint authorizes opt-in tree implementation only. It does not
authorize changing the default before the Gate C corpus evidence is recorded.
