# Pressure Need And Action Composition Blueprint v0

Status:

```text
crystall / roadmap step 5 witness qualification
date: 2026-07-19
chaos: docs/00_chaos/pressure_need_and_composition_notes_2026-07-19.md
table: docs/01_table/yellowprints/pressure_need_and_action_composition_yellowprint.v0.md
implementation authorization: shadow-qualified policy only
live route authority change: forbidden
numeric calibration: forbidden
promotion corpus growth: forbidden until W0 manifest
```

## 0. Selected Contract

```text
coverage says an organ can inspect changed scope
need says a named body operation requires or materially benefits from it
action plan says exactly how the selected organ will act
effect over the same scope discharges the need
composition selects only strict body-derived dominance
unresolved competition remains typed ambiguity
```

The first relation chain is:

```text
new exact structural candidate
-> relation causal affordance toward ☰
-> raw relation
-> exact formation need toward ☵
-> relation-guided CALM form
```

The first upper chain is:

```text
significant exact unit/version delta
-> compatible sensor plan toward ☴
-> upper observation coverage for that class/version
```

## 1. Policy And Migration Boundary

Existing controls remain byte-for-behavior controls:

```text
pressure.binary.v0
pressure policy sampled/camera_reconciliation
tree pressure binary selection
legacy and current tree authority settings
```

New opt-in identities:

```text
pressure derivation: pressure.qualified_need.v0
action plan:         pressure.action_plan.v0
witness:             pressure.witness.v1
composition:         pressure.class_order.v0
```

Required flags during implementation:

```lua
pressure_policy = "qualified_need_v0"
router_mode = "shadow" | existing explicit tree test override
```

`qualified_need_v0` may emit predictions and diagnostics. It may not become the
default live authority under this blueprint.

## 2. Target Files

New modules:

```text
runtime/relation_inspection.lua
  pure exact CONNECT scope/candidate inspection

runtime/upper_coverage.lua
  derived class-compatible upper observation coverage and deltas

runtime/pressure_action.lua
  action-plan validation, identity, compatibility, merge and context projection

runtime/pressure_composition.lua
  witness validation, class ordering and typed ambiguity
```

Modified modules:

```text
organs/connect.lua
  use relation_inspection for both readiness and execution

organs/observe.lua
  accept only body action scope in qualified mode
  semantic own-output coverage commit

organs/encode.lua
  accept exact relation-formation action plan

runtime/body.lua
  observation_class validation and semantic observation commit boundary

runtime/field.lua
  pure unit-plan validation needed before semantic observation commit

runtime/pressure.lua
  new qualified readers; preserve binary readers unchanged

runtime/operator_registry.lua
  readiness/execution context from validated action plan

runtime/tree_router.lua
  qualified candidate action and composition result

core/packet.lua
  route event records validated selected action plan

runtime/tension_runner.lua
  next tick reads action plan from committed arrival/route evidence

runtime/edge_stats.lua
  qualification/ambiguity/action-ref instrumentation only
```

Tests:

```text
tests/test_relation_need.lua
tests/test_upper_observation_need.lua
tests/test_pressure_action.lua
tests/test_pressure_composition.lua
tests/test_qualified_pressure_shadow.lua
```

Do not combine this treatment with age, weights, lineage, hands or default
promotion.

## 3. Canonical Identity Encoding

Derived identities use `core.json.encode` over bounded normalized tables. The
encoder already sorts map keys. Arrays are sorted/deduplicated by the owning
normalizer before encoding.

```lua
identity_string = "pressure-id:" .. json.encode({
  protocol_version = string,
  kind = string,
  target_operator = glyph,
  causal_class = string,
  source_domain = string,
  scope_refs = sorted_unique_string_array,
  provenance_refs = sorted_unique_string_array,
})
```

No ad hoc delimiter parsing and no collision-prone local hash is introduced.
The identity string is bounded by the same scope limits as its witness.

## 4. Pure Relation Inspection API

```lua
local relation_inspection = require("runtime.relation_inspection")

inspection, err = relation_inspection.derive(instance, {
  policy_id = "connect.structural.v1",
  bounds = {max_units=64, max_relations=128},
})

same = relation_inspection.same(left, right)
refs = relation_inspection.scope_refs(inspection)
```

`derive` is pure over Packet-owned copies. It must not append trace, mutate
coverage, call substrate, or allocate Packet identities.

Result:

```lua
{
  protocol_version = "connect.inspection.v0",
  inspection_id = canonical_identity,
  policy_id = string,
  generation = integer,
  source_potential_revision = integer, -- atomic guard/telemetry
  coverage_entries = object_coverage_entry[],
  coverage_delta = object_version_delta,
  coverage_meta = {
    total_count = integer,
    omitted_count = integer,
    truncated = boolean,
  },
  candidates = candidate[],
  candidate_delta = {
    missing = candidate[],
    stale = candidate[],
    current = candidate[],
    unsupported = candidate[],
  },
  event_truth_status = "runtime_confirmed",
}
```

Candidate:

```lua
{
  candidate_key = canonical_identity,
  kind = string,
  from = unit_id,
  to = unit_id,
  endpoint_versions = {[unit_id]=integer},
  predicate_id = string,
  scope_refs = {
    "coverage:field_unit:<id>:<version>",
    "coverage:field_unit:<id>:<version>",
  },
  provenance_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = string,
}
```

### 4.1 One detector, three readers

```text
relation-need reader  reads candidate_delta
CONNECT readiness     reads coverage_delta and selected action scope
CONNECT execution     re-derives and compares inspection_id before mutation
```

The current private candidate functions move into this module. CONNECT must not
retain a second implementation.

### 4.2 Candidate delta law

A current raw relation represents a candidate only when all match:

```text
policy identity
kind
directional endpoint ids
exact endpoint versions
registered predicate/source identity
```

An unrelated uncovered unit may keep CONNECT probe readiness true but does not
enter `candidate_delta.missing`.

Truncated candidate scope is never called complete. A candidate omitted by a
bound cannot produce a qualified positive witness; the inspection reports
`qualification_status=incomplete_scope`.

## 5. Relation Witness Readers

New readers under `pressure.qualified_need.v0`:

```text
relation_recognition_need
relation_formation_need
```

### 5.1 Recognition

For each new supported candidate:

```lua
{
  kind = "relation_recognition_need",
  target_operator = "☰",
  causal_class = "causal_affordance",
  source_domain = "relation_candidate",
  scope_refs = candidate.scope_refs,
  provenance_refs = candidate.provenance_refs + {
    "consumer:encode.relation_formation.v0",
  },
  action_plan = connect_plan,
}
```

The initial consumer registry contains exactly:

```lua
{
  id = "encode.relation_formation.v0",
  accepted_candidate_predicates = {
    "connect.parent_carrier.v0",
    "connect.l1_registered_projection.v0",
  },
  causal_class = "causal_affordance",
}
```

Fixture projection witnesses are marked `promotion_source=fixture`; they may
test mechanics but cannot satisfy production promotion evidence.

A future blocking consumer requires a new registered contract and tests. It is
not caller input.

### 5.2 Formation

For each exact `available`/`observed` raw relation accepted by the live R1
consumer, derive one compatible plan per raw epoch:

```lua
{
  kind = "relation_formation_need",
  target_operator = "☵",
  causal_class = inherited consumer class,
  source_domain = "raw_relation",
  scope_refs = exact relation/endpoint coverage refs,
  provenance_refs = {raw snapshot event, consumer contract ref},
  action_plan.options.encode.relation_input = exact relation_input,
}
```

Relations in terminal/stale/replaced phases do not create formation pressure.
Contradictory dispositions remain loud invariant failures.

## 6. Composite Upper Coverage API

```lua
local upper_coverage = require("runtime.upper_coverage")

view, err = upper_coverage.derive(instance, {
  generation = instance.generation,
  max_observations = 256,
  max_objects = 256,
})

needs, err = upper_coverage.needs(instance, view, options)
```

Derived view:

```lua
{
  protocol_version = "upper.coverage_view.v0",
  generation = integer,
  entries = {
    {
      object_id = unit_id,
      version = integer,
      observation_class = "semantic" | "material" | "relation",
      sensor = "semantic" | "field_native" | "relation_native",
      observation_event_ref = string,
    },
  },
  observation_count = integer,
  omitted_observation_count = integer,
  object_count = integer,
  omitted_object_count = integer,
  truncated = boolean,
  event_truth_status = "runtime_confirmed",
}
```

For each `(object_id, observation_class)`, the newest compatible exact version
wins. The view is ephemeral; immutable observation records remain the source of
truth.

Truncation is conservative: an omitted observation/object cannot establish
freshness and cannot yield a promotion-qualified negative claim.

## 7. Observation Classification

`body.record_observation` gains validated fields:

```lua
sensor = "semantic" | "field_native" | "relation_native"
observation_classes = string[]
```

Compatibility:

| Sensor | Classes it may claim |
|---|---|
| semantic | semantic, material for exact included units |
| field_native | material only |
| relation_native | relation; material only for exact endpoint versions it actually reads |

The classifier derives needs from current unit/event state:

```text
user_prompt/network_carrier unresolved -> semantic
created_by ☵                         -> material
activation_source.actor ☳ or ☷       -> material
raw relation + explicit inspect plan  -> relation
l1_physical_sample alone              -> none
grave unit alone                      -> none in generic upper policy
unknown mutation                      -> unclassified diagnostic
```

Unknown classes are not silently dropped from audit. They set
`qualification_status=unclassified_upper_mutation` and block the affected
promotion case.

### 7.1 Upper witness reader

`upper_observation_need` derives one plan per compatible sensor mode:

```lua
{
  kind = "upper_observation_need",
  target_operator = "☴",
  causal_class = "blocking_demand",
  source_domain = "upper_observation:<class>",
  scope_refs = exact current object/version refs,
  provenance_refs = mutation/creation event refs,
  action_plan = semantic | field_native | relation_native plan,
}
```

The blocking class is a body maintenance law over the selected significant
mutations in Section 7, not a claim that every revision or every field unit
requires sight. Terminal boundary may still preempt it.

## 8. Semantic Own-Output Commit

Target API:

```lua
observation, unit_or_err = body.commit_upper_observation(instance, {
  sensor = "semantic",
  observation_classes = {"semantic", "material"},
  read_units = validated input coverage,
  sensor_output = validated planned field unit,
  planned_unit_id = string,
  ...
})
```

Preparation before first mutation validates:

```text
actor/tick lease
planned deterministic unit id
unit kind/carrier/source refs/truth statuses
observation scopes and classes
bounds and exact input coverage
planned output coverage entry at version 1
```

Commit order may append the observation then unit under one trusted body call.
All expected validation failures occur before the first append. A failure after
the first append is `invariant_failure`; it is not converted to Packet death or
rolled back as an expected error.

The committed coverage includes the planned output at version 1, so unchanged
semantic output cannot immediately request another OBSERVE.

## 9. Action Plan API

```lua
local action = require("runtime.pressure_action")

plan, err = action.build(kind, input)
ok, err   = action.validate(plan)
same      = action.same(left, right)
merged, err = action.merge(left, right)
context, err = action.registry_context(plan, base_context)
```

Canonical plan:

```lua
{
  protocol_version = "pressure.action_plan.v0",
  plan_id = canonical_identity,
  witness_id = canonical_identity,
  target_operator = glyph,
  mode = string,
  scope_refs = sorted_unique_string_array,
  provenance_refs = sorted_unique_string_array,
  preconditions = {
    packet_id = string,
    generation = integer,
    object_versions = {[unit_id]=integer},
    raw_epoch = integer | nil,
    relevant_revisions = table,
  },
  options = table,
  expected_effect = {
    event_type = string,
    scope_refs = string[],
    discharge_reader = string,
  },
  event_truth_status = "runtime_confirmed",
  content_truth_status = string,
}
```

Allowed mode/target pairs:

```text
connect_probe           -> ☰
relation_formation      -> ☵
semantic_observe        -> ☴
field_native_observe    -> ☴
relation_native_observe -> ☴
```

`terminal_boundary` is part of the composition vocabulary but this blueprint
does not add a MANIFEST action mode. Current MANIFEST still receives part of
its result projection from the runner. Until a separate body-owned terminal
action contract removes that dependency, terminal composition tests are
algorithmic/honesty controls and cannot qualify production terminal routing.

Unknown options, target mismatch, caller candidates, tool arguments and
semantic route directives are rejected.

### 9.1 Merge law

Compatible plans share target, mode, policy and precondition epoch. Their
scopes may be merged deterministically when the organ has one atomic bounded
operation for that union.

Initial merge support:

```text
field_native_observe exact unit ids
relation_formation relations from one raw epoch
connect_probe under one policy/bounds
```

Semantic/relation-native/field-native plans are not cross-mode mergeable.
Incompatible plans produce `ambiguous_action`.

## 10. Same-Scope Verification

```lua
ok, err = action.verify_readiness(plan, readiness)
ok, err = action.verify_effect(plan, payload_or_event)
```

Required equality is over normalized `scope_refs`:

```text
witness == plan == readiness == effect
```

`provenance_refs` are separately required to resolve to Packet records or
registered body contracts. They are not inserted into organ scope merely to
make arrays equal.

Under the single-threaded runner, a qualified plan that becomes stale between
route commit and target tick is an invariant failure. Normal expected
not-readiness must be excluded before route commit.

## 11. Qualified Witness API

`runtime.pressure` retains existing binary readers and adds a separate
qualified order:

```text
relation_recognition_need
relation_formation_need
upper_observation_need
```

Witness validation requires:

```text
known kind and adjacent target
registered causal class
non-empty exact scope refs
all provenance refs resolvable
valid action plan with matching witness id/target/scope
bounded source domain
typed source/content truth
```

Snapshot:

```lua
{
  kind = "qualified_pressure_snapshot",
  derivation_version = "pressure.qualified_need.v0",
  calibration_status = "unmeasured_qualified",
  current_operator = glyph,
  witnesses = pressure_witness_v1[],
  unqualified = diagnostic[],
  source_revisions = table,
  event_truth_status = "runtime_confirmed",
}
```

Historical binary contributions may be copied into `unqualified` diagnostics.
They cannot silently become `pressure.witness.v1`.

The existing honest MANIFEST reader may supply a terminal-class test fixture,
but receives `qualification_status=deferred_harness_result_dependency` for
promotion purposes under this treatment.

## 12. Composition API

```lua
local composition = require("runtime.pressure_composition")

result, err = composition.select(instance, candidates, {
  policy = "pressure.class_order.v0",
  allow_control_fallback = boolean,
})
```

Class order:

```text
terminal_boundary > blocking_demand > causal_affordance
```

Algorithm:

```text
1. apply lifecycle/topology/safety/capability/affordability exclusions
2. validate and merge each candidate's action plans
3. call registry readiness with that candidate's validated action context
4. verify readiness scope equality
5. retain candidates carrying at least one qualified executable witness
6. retain only the highest present causal class
7. select when exactly one candidate remains
8. otherwise return typed ambiguity
```

Optional explicit dependency dominance requires one witness to name
`blocks_witness_ids` with resolvable body evidence. No generic dependency solver
is included in v0.

Results:

```text
selected
ambiguous_pressure
ambiguous_action
no_qualified_need
no_viable_edge
invariant_failure
```

When `allow_control_fallback=true`, canonical order may produce a separate
`control_selected` result after ambiguity. The record must preserve the
original ambiguity and set:

```text
promotion_eligible = false
selection_reason = canonical_control_fallback
```

## 13. Route-To-Execution Carry

The selected action plan is recorded in:

```text
route_derivation selected candidate
committed route event selected_candidate.action_plan
```

At the target tick, `tension_runner` reads the committed arrival's selected
action plan and asks `pressure_action.registry_context` for exact organ options.

The runner must not reconstruct the plan from CLI options. User/harness options
remain available only under legacy/control or explicit fixture authority.

Qualified tree execution rejects:

```text
missing committed plan
plan target != current operator
plan id differs from derivation/route copy
caller options override action-owned scope
precondition object/version mismatch
```

The route record, not a runner-local mutable field, is the source of action
authority.

## 14. Discharge Law

No service/age ledger is introduced.

After target execution:

```text
effect verifier checks the committed payload/event scope
next pressure derivation recomputes the fact
absent/transformed fact = discharged
unchanged fact = still live; visit was not service
```

Typed empty CONNECT may discharge probe readiness by coverage while leaving no
relation need, because generic gap was never the need. If a future blocking
demand survives an honest empty probe, it transforms to a typed unsupported
consumer result under that consumer's contract; this blueprint does not invent
the future contract.

## 15. Permanent Red Tests

### 15.1 Relation R0-R9

```text
PR-R0 fresh/no candidate -> no witness
PR-R1 single empty candidate domain -> readiness without pressure
PR-R2 exact pair candidate -> one affordance witness and connect plan
PR-R3 CONNECT effect -> recognition gone, formation appears
PR-R4 relation ENCODE -> formation gone, raw encoded
PR-R5 unrelated formed unit -> probe readiness without relation need
PR-R6 new parent candidate -> exact new need only
PR-R7 endpoint version change -> stale old/new exact need
PR-R8 consumer ablation -> no relation pressure
PR-R9 semantic content -> no truth promotion
```

### 15.2 Upper U0-U10

```text
PR-U0 empty -> no witness
PR-U1 prompt -> semantic exact plan
PR-U2 semantic commit covers own output
PR-U3 budget/loss/clock -> no upper witness
PR-U4 ENCODE unit -> field-native plan
PR-U5 field-native effect discharges
PR-U6 CHOOSE versions -> exact field-native plan
PR-U7 second sight does not recur
PR-U8 DISSOLVE version -> exact field-native plan
PR-U9 L1 sample alone -> no generic upper witness
PR-U10 unknown class -> diagnostic and promotion block
```

### 15.3 Action/composition C0-C9

```text
PR-C0 gap-only cannot qualify
PR-C1 blocking beats affordance independent of canonical order
PR-C2 honest terminal beats nonterminal; blocked honesty unchanged
PR-C3 equal independent blocking needs -> ambiguous_pressure
PR-C4 unique affordance survives control-only noise
PR-C5 compatible plans merge deterministically
PR-C6 incompatible same-target modes -> ambiguous_action
PR-C7 fact ablation removes winner
PR-C8 visit without effect does not discharge
PR-C9 canonical fallback is promotion-ineligible
```

### 15.4 Integration controls

```text
qualified policy shadow on/off changes instrumentation only
legacy and binary tree routes/economics/loss remain identical
fixture projection never enters production promotion class
selected action executes without harness-supplied organ scope
route/plan/readiness/effect refs remain equal
all ambiguity appears in edge statistics as typed result
```

## 16. Failure Boundary

| Failure | Body classification |
|---|---|
| No qualified need | ordinary `no_qualified_need` result |
| Several independent needs | `ambiguous_pressure` |
| Incompatible plans for one glyph | `ambiguous_action` |
| Target not ready before commit | candidate exclusion |
| External substrate/tool failure during effect | existing typed effect failure / Packet mortality law |
| Malformed action schema | invariant/configuration error, loud harness failure |
| Plan changed between derivation and route | invariant failure |
| Plan stale before target tick in single runner | invariant failure |
| Effect scope differs from committed plan | invariant failure |
| Unknown upper mutation | typed diagnostic; affected promotion case red |

Expected-world absence/ambiguity stays inside body diagnostics. Lua corruption,
forged refs and impossible post-commit mismatch remain loud and never become a
beautiful Packet death.

## 17. Implementation Order

```text
I0 add red diagnostic tests reproducing 2026-07-19 mismatches
I1 implement pure relation_inspection; migrate CONNECT to one detector
I2 implement upper_coverage and observation-class validation
I3 implement semantic own-output commit boundary
I4 implement pressure_action identity/validation/merge
I5 implement qualified relation and upper readers
I6 implement pressure_composition with strict ambiguity
I7 carry selected action through route event into registry execution
I8 run R/U/C controls under shadow only
I9 run full suite, mortality, camera and pressure ablations
I10 write W0 treatment manifest; decide whether deterministic corpus may begin
```

Observe after every item. Any failed falsifier stops the sequence before the
next architectural item.

## 18. Explicit Non-Goals

```text
default router promotion
38/38 corpus construction
numeric Z/Tau calibration
age or fairness scheduling
semantic relation discovery
production L1 adapter
multi-sensor OBSERVE
body-owned MANIFEST action/result projection
new active relation graph or RUNTIME raw activation
lineage runner
repository hands
CLI/TUI
```

## 19. Crystall Acceptance

Implementation may begin only if the following remain true on reread:

```text
one pure CONNECT inspection feeds pressure/readiness/effect
coverage gap alone never becomes relation pressure
relation-guided ENCODE is the exact named initial consumer
upper coverage is class-compatible as well as version-exact
own semantic output is covered without a self-loop
the route carries an executable body action, not only a glyph
scope equality is separate from supporting provenance
strict ambiguity is an accepted result
binary control and live authority remain unchanged
promotion waits for a separate W0 manifest
```
