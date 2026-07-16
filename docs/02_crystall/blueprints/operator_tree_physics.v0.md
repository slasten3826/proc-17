# Operator Tree Physics Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/operator_tree_physics_yellowprint.v0.md
depends on docs/02_crystall/blueprints/packet_body_physics.v0.md
implementation target for one full mortal Tree walk
code not changed by this document
```

## 1. Scope

This blueprint compiles the ten ProcessLang operators and twenty-two canonical
edges into one auditable, pressure-driven Packet runner.

It defines:

```text
operator registry and tick envelope
FLOW, CONNECT, and DISSOLVE integration
pressure readers and contribution records
candidate filtering and route selection
shadow comparison with the current router
freshness-based removal of mandatory eye rails
edge and promotion evidence
```

It does not implement cross-generation continuation. That belongs to the
Lineage Mechanics blueprint.

## 2. Canon And Runtime Direction

Canonical adjacency remains `core/topology.lua`, equivalent to
ProcessLang `canon.lua`.

```text
unique undirected edges = 22
operator count = 10
NETWORK@▽ is absent from both counts
```

Runtime direction overlay:

```text
▽ may be the first same-life tick and may leave through ☰, ☷, or ☴
no living Packet returns to ▽
internal edges permit either direction when readiness permits
△ is terminal and has no same-life successor
internal mortality may end a Packet at any current operator
```

Do not edit canon adjacency to encode lifecycle direction.

## 3. Target Files

```text
runtime/operator_registry.lua      NEW: ten organ contracts
runtime/pressure.lua               NEW: named readers and contributions
runtime/tree_router.lua            NEW: candidates and deterministic selection
runtime/router.lua                 legacy/tree/shadow authority switch
runtime/tension_runner.lua         explicit FLOW and generic operator dispatch
runtime/edge_stats.lua             NEW: shadow/live edge measurements
organs/flow.lua                    NEW
organs/connect.lua                 NEW
organs/dissolve.lua                NEW
organs/observe.lua                adapt to shared observation envelope
organs/encode.lua                 consume field view and emit identity map
organs/choose.lua                 mutate field activation
logic/cycle.lua                   retain bounded impulse contract
logic/spells.lua                  retain effect evidence contract
logic/manifest.lua                emit terminal materialization input
tests/test_pressure.lua            NEW
tests/test_tree_router.lua         NEW
tests/test_connect.lua             NEW
tests/test_dissolve.lua            NEW
tests/test_full_tree_edges.lua     NEW
tests/test_tension_runner.lua      migration and promotion coverage
tests/run.lua                     register suites
```

## 4. Operator Registry

### 4.1 API

```lua
registry.get(glyph) -> descriptor | nil
registry.available(glyph, instance, options) -> boolean, reason | nil
registry.readiness(glyph, instance, context) -> witness
registry.run(glyph, instance, context) -> payload | nil, err
```

### 4.2 Descriptor

```lua
{
  glyph = glyph,
  name = string,
  run = function,
  readiness = function,
  required_capabilities = table,
  loss_profile = "zero" | "mandatory" | "conditional" | "terminal",
  reads = table,
  writes = table,
}
```

The registry does not own topology or route policy.

### 4.3 Tick result envelope

The runner wraps each organ-specific payload:

```lua
{
  kind = "operator_tick_result",
  operator = glyph,
  status = "applied" | "no_op" | "rejected" | "failed",
  reads = table,
  writes = table,
  payload = table,
  invalidations = table,
  cost_refs = table,
  loss_refs = table,
  event_truth_status = "runtime_confirmed",
  content_truth_status = string,
  trace_event_id = string,
}
```

Readiness failure removes a candidate before execution. A no-op result is valid
only when state changed between readiness and execution or the organ reports a
specific race/staleness reason.

## 5. Generic Tick Transaction

```text
1. assert Packet mutable
2. begin tick and stamp current operator
3. construct bounded input view
4. run organ through registry
5. validate writes against descriptor rights
6. apply cost and loss
7. apply revision invalidations
8. append complete tick event
9. run mortality and safety guards
10. derive pressure from current Packet state
11. build/filter candidates
12. select and commit one adjacent transition
```

The organ cannot call the router or set `next_operator`.

## 6. Ten Organ Contracts

### 6.1 ▽ FLOW

Target:

```text
organs/flow.lua
```

Input:

```lua
{
  kind = "flow_ingress",
  birth_kind = "user" | "network_reentry" | "recovery",
  payload = any,
  media_type = string,
  source_refs = table,
  content_truth_status = string,
}
```

Effect:

```text
parse only the transport envelope
create one or more potential units through runtime/field.lua
initialize task scalars supplied by body policy
append explicit FLOW tick/birth transformation
```

FLOW must not encode CALM, preserve parent structure, or choose its next edge.

### 6.2 ☰ CONNECT

Target:

```text
organs/connect.lua
```

Readiness:

```text
at least two addressable current units
or one current unit plus one bounded external/history referent
```

Input view:

```lua
{
  unit_refs = table,
  existing_relation_refs = table,
  observation_refs = table,
  history_refs = table,
  bounds = table,
}
```

Effect:

```text
recognize candidate relations
write one new E_raw epoch through field.snapshot_raw_relations
record coverage and confidence without truth promotion
```

CONNECT has zero direct identity loss and does not write active relations or
momentum.

### 6.3 ☷ DISSOLVE

Target:

```text
organs/dissolve.lua
```

Readiness:

```text
one active relation/form with a runtime-visible reason:
stale, rigid, rejected, contradictory, unsupported, or explicitly released
```

Effect:

```text
weaken/dissolve the selected relation or form
preserve a dissolution record and source refs
return recoverable residue to potential units when present
invalidate dependent observations/CALM readiness
pay identity loss only when information or structure is irreversibly discarded
```

DISSOLVE never invents replacement relations and never routes directly.

### 6.4 ☴ OBSERVE

Read bounded upper state and optional substrate current. Append one upper-eye
observation. Semantic output remains proposal. New proposal material enters the
field through `field.add_unit` with provenance.

Zero direct identity loss. No inspected-state mutation and no route authority.

### 6.5 ☵ ENCODE

Consume a bounded field view, not concatenated unbounded CHAOS text.

Required output:

```text
CALM structure
identity map
relation/observation invalidation set
complete loss record including omissions
```

ENCODE never writes momentum or validates semantic truth.

### 6.6 ☳ CHOOSE

Read at least two live alternatives and explicit pressure. Change unit
activation through `field.set_activation`. Preserve selected and suppressed ids,
killed-alternative sample/count, and mandatory loss.

One remaining alternative without suppression is confirmation, not CHOOSE.

### 6.7 ☲ CYCLE

Read a runtime-confirmed recurrence condition. Emit exactly one bounded
continuation impulse and scalar phase update.

```text
zero direct identity loss
non-zero runtime budget
no semantic planning
no ownership of work count/reason
```

### 6.8 ☶ LOGIC

Read declared rules, capability contracts, candidate form, and effect evidence.
Write constraints, verdicts, and evidence produced by actual spells/tools.

LOGIC rejects unsupported form; it does not generate task meaning or silently
turn semantic proposals into runtime facts.

### 6.9 ☱ RUNTIME

Append one lower-eye observation. Reconcile CALM with execution/evidence,
update progress/counters, activate raw relations, and exclusively update
relation momentum.

It derives current history pressure from attached records but does not edit
grave/compost or choose the route.

### 6.10 △ MANIFEST

Read selected/validated form, evidence, output policy, economics, and terminal
reason. Assemble terminal output/residue, pay materialization loss, and invoke
the T1 terminal transaction.

No same-life tick follows.

## 7. Readiness Witness

```lua
{
  operator = glyph,
  ready = boolean,
  reason = string,
  source_refs = table,
  required_capabilities = table,
  missing_capabilities = table,
  event_truth_status = "runtime_confirmed",
}
```

Minimum reason codes:

```text
ready
scope_empty
no_relation_candidates
nothing_dissolvable
no_compressible_structure
confirmation_not_choice
no_continuation_condition
no_rule_or_target
runtime_view_empty
nothing_manifestable
missing_capability
stale_input
```

## 8. Pressure Module

Target:

```text
runtime/pressure.lua
```

### 8.1 API

```lua
pressure.derive(instance, tick_result, options) -> snapshot | nil, err
pressure.read(kind, instance, context) -> contribution[] | nil, err
```

### 8.2 Snapshot

```lua
{
  kind = "edge_pressure_snapshot",
  packet_id = string,
  generation = integer,
  tick = integer,
  current_operator = glyph,
  derivation_version = "pressure.binary.v0",
  source_revisions = table,
  contributions = table,
  event_truth_status = "runtime_confirmed",
}
```

### 8.3 Contribution

```lua
{
  kind = string,
  source_ref = string,
  target_operator = glyph,
  target_edge = string,
  direction = "help" | "resist",
  amount = number,
  reason = string,
  calculation_status = "runtime_confirmed" | "estimated",
  source_truth_status = string,
  freshness = string,
  derivation_version = string,
}
```

## 9. First Pressure Policy

Use an explicit shadow-only control policy:

```text
policy id: pressure.binary.v0
one witnessed pressure kind for an edge: help amount = 1
one witnessed resistance kind for an edge: resist amount = 1
absence of a witness: no contribution, not zero truth
hard lifecycle/sandbox/capability denial: candidate exclusion, not resistance
duplicate records supporting the same kind/edge collapse to one contribution
```

Candidate total:

```text
positive = sum(help amounts)
resistance = sum(resist amounts)
total = positive - resistance
```

This policy is deliberately uncalibrated and marked `vibed_control`. It may
predict in shadow mode but cannot gain live authority merely because tests are
green.

## 10. Named Pressure Readers

| Kind | Minimum source witness | Primary target |
|---|---|---|
| `relation_debt` | addressable units lack a fresh relation epoch/coverage | ☰ |
| `rigidity` | active relation/form is stale, rejected, contradictory, or overstable | ☷ |
| `upper_observation_debt` | upper observation revisions differ from relevant state | ☴ |
| `encoding_debt` | live potential lacks receiver-suitable CALM form | ☵ |
| `choice_pressure` | at least two live alternatives and affordable suppression | ☳ |
| `runtime_mismatch` | CALM/relation/evidence state is not installed or reconciled | ☱ or ☵ by adjacent direction |
| `lower_observation_debt` | lower observation revisions differ from runtime/economics/evidence | ☱ |
| `validation_debt` | selected/manifestable claim lacks fresh rule/effect evidence | ☶ |
| `continuation` | fresh runtime progress says bounded repeatable work remains | ☲ |
| `manifest` | completion/usable-partial/near-death contract is currently satisfied | △ when adjacent |
| `karma_help` | bequest/compost relation matches current refs | matching adjacent repair/continuation edge |
| `karma_resistance` | warning/compost relation matches current live path | matching edge/path |
| `capability_resistance` | required organ/tool absent | candidate exclusion |
| `safety_resistance` | sandbox/lifecycle policy denies action | candidate exclusion |

Each reader emits at most one contribution per kind/target edge under
`pressure.binary.v0`, with all supporting refs retained inside `source_refs` or
an attached evidence record.

Exact semantic/history matching remains outside v0 authority.

## 11. Eye Freshness Reader

```lua
pressure.eye_debt(instance, eye, scope) -> contribution | nil
```

Algorithm:

```text
find latest observation covering scope
if none: debt present
compare its read_revisions only with relevant current revisions
if any differ: debt present with changed components
otherwise: no eye debt
```

Upper relevant components:

```text
potential, relations_raw, relations_active, calm
```

Lower relevant components:

```text
relations_active, momentum, calm, constraints, evidence,
history, budget, loss, scalars
```

Eye debt does not forbid a direct non-eye edge when the receiving operator has
fresh, runtime-confirmed inputs independent of that view.

## 12. Candidate Construction

Target:

```text
runtime/tree_router.lua
```

```lua
tree_router.candidates(instance, snapshot, options) -> candidates
tree_router.select(instance, candidates, options) -> decision | nil, err
```

Filter order:

```text
1. canonical neighbors of current operator
2. same-life direction law
3. registered and available organ
4. sandbox and lifecycle safety
5. readiness witness
6. local budget/loss affordability
```

Candidate:

```lua
{
  to = glyph,
  edge = string,
  contributions = table,
  positive = number,
  resistance = number,
  total = number,
  readiness = table,
  affordable = boolean,
  exclusions = table,
}
```

Excluded candidates remain in the route audit with reasons but cannot win.

## 13. Selection And Decision

Shadow v0 selection:

```text
retain non-excluded candidates with total > 0
choose highest total
break exact ties by stable canonical operator order
if none remain, return explicit no_viable_edge outcome
```

Decision:

```lua
{
  kind = "tree_route_decision",
  policy = "pressure.binary.v0",
  from = glyph,
  to = glyph | nil,
  candidates = table,
  reason = string,
  source_snapshot_ref = string,
  event_truth_status = "runtime_confirmed",
}
```

The decision occurrence is confirmed. Its policy quality is not.

Router movement is not ☳. It pays runtime budget and does not suppress semantic
units or write a CHOOSE loss record.

## 14. No Viable Edge

`tree_router.select` returns a typed outcome, never a hidden default:

```lua
{
  kind = "no_viable_edge",
  cause = "complete" | "needs_input" | "missing_capability"
        | "unsafe" | "stalled" | "below_threshold",
  candidates = table,
  event_truth_status = "runtime_confirmed",
}
```

Handling remains in the Packet runner:

```text
complete and terminal-adjacent -> △
needs input/capability -> terminal residue or explicit body hold once crystallized
unsafe -> immediate death
stalled -> stalled death once cause is added
below threshold -> no free self-loop; explicit hold policy is still OPEN
```

No invalid jump toward △ is allowed.

## 15. Router Authority Switch

Extend `runtime/router.lua`:

```lua
router.after_tick(instance, tick, options)
```

Modes:

```text
legacy  current router controls; no tree prediction required
shadow  current router controls; tree router records prediction/divergence
tree    tree router controls; legacy prediction retained for rollback evidence
```

Default remains:

```text
shadow during development only after field and missing organs exist
legacy before that
tree only after explicit promotion
```

Shadow record:

```lua
{
  kind = "shadow_route_decision",
  current_operator = glyph,
  live_to = glyph,
  predicted_to = glyph | nil,
  candidates = table,
  agreement = boolean,
  divergence = string | nil,
  policy = string,
  event_truth_status = "runtime_confirmed",
}
```

Shadow mode may append trace/statistics only. It cannot mutate semantic state,
operator position, costs, loss, or the live route.

## 16. Mandatory Eye Rail Removal

Current rails:

```text
☵ -> ☴
☳ -> ☴
☲ -> ☱
☶ -> ☱
```

Removal is per rail, not one global delete.

For each rail require a battery containing:

```text
mutation that genuinely needs refreshed eye -> shadow selects eye
fresh direct-consumer case -> shadow may select direct edge
stale evidence/adversarial case -> direct edge does not bypass eye/logic
route and resulting behavior remain explainable from revision refs
```

Promotion record:

```lua
{
  rail = "☵-☴",
  cases = number,
  required_eye_recall = number,
  false_bypass_count = number,
  direct_edge_success_count = number,
  decision = "keep" | "remove",
  evidence_refs = table,
  truth_status = "runtime_confirmed",
}
```

No target metric is invented here; promotion thresholds remain explicit policy
after measured traces exist.

## 17. Full 22-Edge Witness Set

Every edge needs at least one grown integration trace in each implemented
direction. Boundary edges need only legal same-life direction.

| Id | Edge | Minimum witness |
|---|---|---|
| E01 | `▽-☰` | multi-unit ingress produces raw relations |
| E02 | `▽-☷` | inherited rigid carrier form releases residue |
| E03 | `▽-☴` | raw ingress reaches upper observation |
| E04 | `☰-☷` | false/rigid relation dissolves and surviving units reconnect |
| E05 | `☰-☴` | relation snapshot is observed; observation reveals new endpoints |
| E06 | `☰-☵` | motif encodes; remapped units reconnect |
| E07 | `☷-☴` | dissolution consequence is observed; observation finds rigidity |
| E08 | `☷-☳` | released alternatives are chosen; choice residue dissolves |
| E09 | `☴-☵` | observed proposal encodes; changed form earns eye debt |
| E10 | `☴-☳` | observed alternatives collapse; consequences return to sight |
| E11 | `☴-☱` | semantic/runtime mismatch crosses both eyes |
| E12 | `☵-☱` | encoded form installs; runtime mismatch requests recode |
| E13 | `☵-☳` | encoded alternatives choose; selected path re-encodes |
| E14 | `☵-☲` | repeatable encode transform cycles under body-owned condition |
| E15 | `☳-☱` | commitment installs; runtime exposes another branch |
| E16 | `☳-☶` | selected path validates; admissible set requires choice |
| E17 | `☱-☶` | runtime requests evidence; verdict/effect returns |
| E18 | `☱-☲` | remaining work emits one recurrence and returns to accounting |
| E19 | `☲-☶` | iterative result validates; rule requests bounded rerun |
| E20 | `☱-△` | runtime completion/near-death manifests |
| E21 | `☲-△` | runtime-confirmed recurrence terminal condition manifests |
| E22 | `☶-△` | fresh accepted evidence manifests directly |

Tests must grow the required state through operators where feasible. Hand-built
snapshots may test pure readers but do not satisfy integration witnesses.

## 18. Edge Statistics

Target:

```text
runtime/edge_stats.lua
```

Record by direction, policy, work mode, substrate fingerprint, and task class:

```text
candidate count
selection count
average positive/resistance/total
exclusion reason counts
legacy agreement/divergence
completion and terminal cause
budget/loss at selection
eye debt source revisions
no-viable-edge count
```

Statistics are observations, not automatic policy updates.

## 19. Writer-Reader Closure

| Written record | Writer | Required reader and read moment |
|---|---|---|
| readiness witness | operator registry | candidate filter in the same route derivation |
| operator tick result | Packet runner/organ | physics, revisions, pressure, and trace before movement |
| FLOW units | ▽ | ☰/☷/☴ pressure/readiness after birth |
| raw relation snapshot | ☰ | ☱ activation plus ☵/☴/☷ readers while fresh |
| dissolution record/residue | ☷ | field/freshness readers and later ☴/☳/☰ as pressure permits |
| encode identity map | ☵ | T1 invalidation reader and ☱ before momentum reuse |
| choice suppression record | ☳ | ☴/☱/☶ consequence readers and loss physics |
| cycle impulse | ☲ | ☱/☶/△ on the immediately following legal movement |
| validation/effect record | ☶ | freshness, ☱, router readiness, and △ |
| runtime observation/momentum | ☱ | pressure readers and adjacent lower/middle operators |
| pressure contribution/snapshot | named pressure readers | tree router and trace in the same tick |
| candidate set | tree router | selector, shadow comparison, edge statistics |
| route decision | selected router | T1 transition commit and trace validator immediately |
| shadow decision | router wrapper | edge statistics and explicit promotion review |
| rail promotion record | migration controller | router authority configuration and audit |
| edge statistics | edge_stats | human/machine review; never automatic canon mutation |

No storage module is a router reader. Session history must first enter the
Packet and become a derived pressure contribution.

## 20. Implementation Order

### Phase A: generic runner surface

```text
add registry around existing organs
make ▽ an explicit FLOW tick
use T1 transition commit so Packet position and trace agree
keep legacy router authority
```

### Phase B: missing upper organs

```text
manifest ☰ against field relations
manifest ☷ against active relations/forms
add organ and directional unit tests
```

### Phase C: pressure and shadow

```text
implement named readers
emit binary.v0 contributions with provenance
run tree router in shadow
collect edge and rail evidence
```

### Phase D: broaden edge corpus

```text
grow all 22 edge witnesses
run fake substrate, DeepSeek, and substrate-free physics cases
fix field/readiness defects before tuning pressure
```

### Phase E: authority promotion

```text
remove eye rails only with per-rail evidence
enable tree mode behind explicit switch
retain legacy rollback and comparisons for first live batteries
```

## 21. Required Tests

```text
registry contains exactly ten canonical operators
topology contains exactly twenty-two unique edges
every tick enforces declared read/write rights
FLOW is explicit and cannot be revisited in one life
CONNECT creates only raw relation snapshots
DISSOLVE preserves residue and conditional loss
RUNTIME alone creates/activates relations and writes momentum;
DISSOLVE/LOGIC only perform their declared weaken/lock mutations
router never calls substrate or mutates semantic field
router movement creates no CHOOSE loss
every candidate records exclusions and contributions
shadow decision cannot change live route or Packet economics
revision changes create component-specific eye debt
fresh direct edges remain possible where readiness permits
no viable edge is explicit and never becomes invalid jump/self-loop
all E01-E22 witnesses pass or are individually marked unimplemented before promotion
internal mortality wins before routing when exhausted
△ is terminal
```

## 22. Explicitly Open

```text
calibrated pressure normalization and weights
movement threshold for live authority
exact history matching
conditional loss for ☷, ☶, and ☱
body hold semantics below threshold
manifest-pressure propagation from a node not adjacent to △
organ/capability assembly for task-specific organs
rare-edge expected frequencies
per-rail promotion thresholds
tie policy after the deterministic shadow control
whether binary.v0 survives beyond shadow control
```

## 23. Acceptance

T2 is manifested correctly when:

```text
all ten operators execute through one registry contract
all twenty-two edges are representable without hidden jumps
FLOW and MANIFEST enforce one-life direction
eyes only observe and router alone commits movement
pressure is derived from named Packet records with provenance
router selection remains distinct from semantic CHOOSE
☰ and ☷ are real field organs, not list-processing placeholders
hard eye rails are removed only by measured freshness behavior
legacy/shadow/tree authority is explicit and reversible
the full integration battery and existing tests pass
```
