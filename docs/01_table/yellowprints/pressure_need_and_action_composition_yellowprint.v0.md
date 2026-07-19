# Pressure Need And Action Composition Yellowprint v0

Status:

```text
table / roadmap step 5 witness qualification
date: 2026-07-19
source: docs/00_chaos/pressure_need_and_composition_notes_2026-07-19.md
runtime implementation authorized: no
pressure calibration authorized: no
promotion corpus authorized: no
default router promotion authorized: no
```

Relationship to earlier tables:

```text
pressure_witness_versioned_coverage_yellowprint.v0
  retained as the exact coverage contract
  its Observation O1 remains authoritative: coverage is not sufficient need

relation_consumer_causality_yellowprint.v0
  amended by Step 4: relation-guided ENCODE is now an executable R1 consumer
  RUNTIME raw activation remains rejected for vertical_packet_life.v0

tree_authority_promotion_corpus_yellowprint.v0
  remains blocked until this table's W0 controls are runtime-confirmed
```

## 0. Selected Decisions

```text
D1 coverage, need, readiness, action and effect remain separate records
D2 generic relation coverage gap creates no route contribution
D3 a new exact structural candidate plus relation-guided ENCODE is an accepted
   causal-affordance hypothesis, subject to matched controls
D4 a blocking relation demand requires an explicit live consumer contract
D5 upper sight uses object id + version + compatible sensor class
D6 significant upper mutations create a one-service observation obligation
D7 every qualified witness carries a body-derived bounded action plan
D8 composition is class/causality first; no invented scalar weights
D9 incomparable equal-class actions produce typed ambiguity for promotion
D10 canonical tie-break remains control behavior, never adaptive evidence
```

## 1. Five-Layer Boundary

| Layer | Question | Stored or derived | Authority |
|---|---|---|---|
| Fact | What exact object/version/event exists? | Stored body state/trace | Runtime-confirmed event writer |
| Coverage | Has an organ inspected the exact current scope? | Stored capture + derived delta | Object coverage |
| Need | What declared operation is blocked or materially changed? | Derived each pressure tick | Named consumer/invariant reader |
| Action | What exact bounded organ invocation can discharge it? | Derived with need | Body planner, never substrate route choice |
| Effect | Did execution write the expected record over the same refs? | Stored immutable event/state | Target organ/body API |

Invalid collapses:

```text
coverage == need
readiness == pressure
glyph == executable action
organ visit == discharge
canonical winner == physical dominance
```

## 2. Relation Inventory After Vertical Packet Life

| Surface | Current fact | Consequence |
|---|---|---|
| Exact relation coverage | Implemented | Can state what CONNECT has not inspected |
| Structural candidate detector | Implemented inside CONNECT | Must become a pure shared plan before pressure may read it |
| Raw relation phase | Implemented and derived | Can distinguish available/observed/encoded/released/stale/replaced |
| Relation-guided ENCODE | Implemented | First real named L2 relation consumer |
| Raw DISSOLVE | Implemented | Consumer only when a typed release reason exists |
| Relation-native OBSERVE | Implemented | Consumer only when inspection is explicitly required |
| RUNTIME raw activation | Forbidden in vertical protocol | Cannot justify relation pressure |

The initial accepted R1 relation consumer is:

```text
consumer_contract = encode.relation_formation.v0
causal_class       = causal_affordance
```

It becomes `blocking_demand` only when a separate body-owned representation
contract says that the requested form requires this relation kind/scope.

## 3. Exact Relation Inspection Plan

CONNECT requires one pure, bounded inspection result used by pressure,
readiness and execution:

```lua
{
  protocol_version = "connect.inspection.v0",
  policy_id = string,
  generation = integer,
  object_coverage_delta = object_version_delta,
  candidates = {
    {
      candidate_key = string,
      kind = string,
      from = unit_id,
      to = unit_id,
      endpoint_versions = {[unit_id]=integer},
      predicate_id = string,
      source_refs = string[],
      event_truth_status = "runtime_confirmed",
      content_truth_status = string,
    },
  },
  candidate_delta = {
    missing = candidate[],
    stale = candidate[],
    current = candidate[],
    unsupported = candidate[],
  },
  truncated = boolean,
  event_truth_status = "runtime_confirmed",
}
```

Candidate identity is deterministic over:

```text
policy id
relation kind
ordered directional endpoints
endpoint versions
predicate id and immutable predicate/source event
```

Candidate identity is not inferred from semantic prose. A detector may only use
registered body-visible predicates already allowed by the L2 crystall.

### 3.1 Readiness versus pressure

| Inspection state | CONNECT readiness | Relation pressure |
|---|---:|---:|
| No coverage delta | false from this plan | none |
| Coverage delta, no candidate/demand | true for bounded probe | none |
| New supported candidate with R1 affordance | true | causal affordance |
| Exact blocking demand over same scope | true | blocking demand |
| Candidate already represented at exact versions | maybe ready for unrelated scope | none for candidate |
| Candidate unsupported by all consumers | probe may record unsupported | none after typed unsupported record |

This allows diagnostic/manual empty probes without making them autonomous
route pressure.

## 4. Relation Need And Phase Transformation

### 4.1 Pre-CONNECT need

```lua
{
  kind = "relation_need",
  phase = "recognition",
  causal_class = "causal_affordance" | "blocking_demand",
  consumer_contract = string,
  candidate_keys = string[],
  endpoint_versions = table,
  coverage_refs = string[],
  scope_refs = string[],
  provenance_refs = string[],
  content_truth_status = string,
}
```

Required join:

```text
exact uncovered/stale scope
AND new candidate or explicit typed demand over that scope
AND current named consumer accepting the relation kind
```

### 4.2 Post-CONNECT formation need

Once raw relations exist, the recognition need is absent. A new derived phase
may target ENCODE:

```lua
{
  kind = "relation_formation_need",
  phase = "formation",
  causal_class = inherited from recognition/demand,
  consumer_contract = "encode.relation_formation.v0",
  relation_input = {
    raw_epoch = integer,
    relation_ids = string[],
    endpoint_versions = table,
    source_event_refs = string[],
  },
}
```

| Raw phase | Formation pressure |
|---|---|
| `available` or `observed` and consumer still live | present |
| `encoded` | absent/discharged |
| `released`, `stale`, `replaced`, `expired` | absent; another typed law may act |
| contradictory terminal disposition | invariant failure |

No mutable need object crosses phases. The chain is re-derived from current
field and trace.

## 5. Upper Observation Coverage Classes

Object version is necessary but not sufficient to claim that the right kind of
observation occurred.

Canonical derived key:

```text
(field_unit_id, version, observation_class)
```

Initial classes:

| Observation class | Sufficient sensor | Meaning |
|---|---|---|
| `semantic` | semantic substrate sensor | Semantic ingress/current was presented to substrate |
| `material` | field-native or semantic sensor | Body-owned field state/version was inspected |
| `relation` | relation-native sensor | Exact raw relation and endpoint versions were inspected |

One sensor may satisfy more than one class only when its committed scope proves
that it actually read those refs. `field_native` never satisfies `semantic`.

Upper coverage is a bounded derived union of immutable observation envelopes:

```text
for each object/class, newest compatible exact observed version wins
no mutable merged coverage map is stored as truth
truncation remains visible and conservative
```

## 6. Upper Significance And Sensor Table

| Mutation/fact | Required class | Planned sensor | Need class | Default result |
|---|---|---|---|---|
| New user prompt or NETWORK carrier with unresolved semantics | semantic | semantic | blocking body observation obligation | pressure |
| Semantic OBSERVE's own output at version 1 | semantic + material | same atomic commit | already served | no pressure |
| New unit created by ENCODE | material | field_native | body consequence observation | pressure once |
| CHOOSE selection/suppression version change | material | field_native | body consequence observation | pressure once |
| DISSOLVE unit release/version change | material | field_native | body consequence observation | pressure once |
| Exact raw relation with explicit inspection demand | relation | relation_native | demand class inherited | pressure once |
| L1 physical sample with no reader demand | none by default | none | telemetry | no pressure |
| Grave unit with no consumer-specific sight law | none by default | none | separate lineage pressure | no generic pressure |
| Budget/loss/clock-only movement | none | none | lower-body telemetry | no upper pressure |
| Unknown unit/mutation kind | unclassified | none | diagnostic/block promotion | no promoted pressure |

"Pressure once" means until one compatible observation commits the exact
current version. A later version legitimately creates a new obligation.

## 7. Body-Derived Action Plan

```lua
{
  protocol_version = "pressure.action_plan.v0",
  plan_id = string,
  witness_id = string,
  target_operator = glyph,
  mode = "connect_probe" | "relation_formation"
       | "semantic_observe" | "field_native_observe"
       | "relation_native_observe",
  scope_refs = string[],
  provenance_refs = string[],
  options = table,
  expected_effect = {
    event_type = string,
    source_refs = string[],
    discharge_reader = string,
  },
  event_truth_status = "runtime_confirmed",
  content_truth_status = string,
}
```

Allowed v0 options:

| Mode | Body-owned options |
|---|---|
| `connect_probe` | policy id, exact unit ids, bounds |
| `relation_formation` | exact `relation_input` |
| `semantic_observe` | exact semantic unit ids/scope; substrate prompt formatting remains adapter work |
| `field_native_observe` | exact unit ids and versions |
| `relation_native_observe` | exact raw epoch/relation ids/endpoint versions |

The plan contains no arbitrary tool arguments, semantic answer, route decision,
or caller-injected relation candidate.

Same-ref gate:

```text
witness scope refs
== readiness scope refs
== action scope refs
== successful effect scope refs

provenance refs may additionally name predicate, consumer and source events;
they must resolve but must not be reported as fake organ operands
```

An executed target that writes no matching effect does not discharge the
witness.

## 8. Qualified Witness Schema

```lua
{
  protocol_version = "pressure.witness.v1",
  witness_id = string,
  kind = string,
  current_operator = glyph,
  target_operator = glyph,
  target_edge = string,
  direction = "help" | "resist",
  causal_class = "terminal_boundary"
               | "blocking_demand"
               | "causal_affordance",
  source_domain = string,
  scope_refs = string[],
  provenance_refs = string[],
  action_plan = pressure_action_plan,
  calculation_status = "runtime_confirmed" | "estimated",
  source_truth_status = string,
  derivation_version = string,
}
```

`witness_id` is deterministic from kind, target, causal class, source domain,
normalized exact scope refs and provenance refs for this derivation. It is not
a persistent mutable age identity.

One physical witness may contribute at most once to one target in one snapshot.
Several refs summarized by one witness do not automatically increase its
magnitude.

## 9. Composition Result Table

Hard lifecycle, topology, capability, affordability and safety exclusion runs
before need composition. Mortality remains a pre-route body boundary.

Selected v0 class order:

```text
terminal_boundary > blocking_demand > causal_affordance
```

This is an ordinal body law, not a calibrated scalar distance.

| Candidate state | Result |
|---|---|
| One executable candidate in highest present class | `unique_dominant` |
| Several candidates, one causally blocks the others' declared operation | `unique_dominant` with dependency refs |
| Several independent candidates in the same highest class | `ambiguous_pressure` |
| Same target, compatible plans with one atomic scope | deterministic merged plan |
| Same target, incompatible sensor/mode/effect plans | `ambiguous_action` |
| No qualified need but legacy binary contribution exists | control-only decision, not promotion evidence |
| Canonical order resolves equal qualified totals | execution may continue under control; qualification is red |

Terminal precedence applies only when MANIFEST readiness is honest. It cannot
launder rejected or unvalidated output.

Current boundary:

```text
the class-order contract includes terminal precedence
current MANIFEST still receives part of its result projection from the runner
C2 may test composition and existing manifest honesty
it cannot qualify production terminal action ownership until that dependency is removed
```

Age, fairness and measured magnitude remain deferred. The first implementation
must expose ambiguity rather than invent their answers.

## 10. Matched Relation Controls R0-R9

| ID | One changed variable | Expected result |
|---|---|---|
| R0 | Fresh exact coverage, no new candidate | No relation need |
| R1 | One uncovered L1 sample, detector returns no candidate | CONNECT readiness true; relation pressure absent; optional probe is empty |
| R2 | Same coverage gap but registered exact pair candidate exists | One causal-affordance need naming pair/versions/R1 consumer |
| R3 | Execute CONNECT with R2 plan | Recognition need disappears; exact formation need appears |
| R4 | Execute relation-guided ENCODE | Formation need disappears; raw phase is encoded |
| R5 | Add formed unit that creates no new candidate | CONNECT may be probe-ready; no new relation need |
| R6 | Add a body-visible parent relation involving the formed unit | New relation need names only new candidate domain |
| R7 | Advance one candidate endpoint version | Old candidate stale; exact new candidate need appears once |
| R8 | Disable relation-guided consumer only | Candidate remains telemetry; pressure disappears |
| R9 | Semantic candidate content | Structural witness remains typed; semantic truth is not promoted |

R2/R3/R4/R8 form the minimum causal-affordance ablation. The current Step 4
tests are supporting evidence, not a substitute for this matched set.

## 11. Matched Upper Controls U0-U10

| ID | One changed variable | Expected result |
|---|---|---|
| U0 | No upper-visible fact | No upper need |
| U1 | New unresolved user prompt | Semantic plan over exact prompt ref |
| U2 | Execute semantic OBSERVE | Prompt and planned output are covered; no self-repeat |
| U3 | Change only budget/loss/clock | No upper need |
| U4 | ENCODE creates a new formed unit | Field-native plan names exact unit/version |
| U5 | Execute field-native sight for U4 | Need disappears |
| U6 | CHOOSE changes selected/suppressed versions | One field-native plan names all exact changed versions |
| U7 | Execute field-native sight for U6 | Need disappears once |
| U8 | DISSOLVE changes one covered unit | Field-native plan names release version/event |
| U9 | One L1 physical sample without sight demand | No generic upper pressure |
| U10 | Unknown mutation class | Typed unclassified diagnostic; no promoted route |

Every U control asserts that pressure refs equal OBSERVE readiness and committed
coverage refs.

## 12. Composition Controls C0-C9

| ID | Prepared qualified state | Required result |
|---|---|---|
| C0 | Coverage gap only | No qualified candidate from the gap |
| C1 | One blocking need plus one relation affordance | Blocking target wins by class, not canonical order |
| C2 | Honest terminal fixture plus nonterminal blocking need | Terminal target wins; blocked manifest remains forbidden; production action ownership remains open |
| C3 | Two independent blocking needs | `ambiguous_pressure`, no adaptive claim |
| C4 | One relation affordance and lower-class/control-only noise | Relation target is unique qualified candidate |
| C5 | Same target and compatible field-native refs | One deterministic merged action scope |
| C6 | Same OBSERVE target but semantic and relation-native plans | `ambiguous_action` unless a declared multi-sensor contract exists |
| C7 | Remove only winning witness fact | Winner disappears or changes |
| C8 | Execute winner but expected effect refs do not change | Witness remains; visit is not service |
| C9 | Canonical tie fallback enabled | Life may continue, but promotion record marks direction tie-only/red |

Crosswalk to the earlier C1-C6 route table:

```text
☴->☵ / ☳ / ☱ / ☷ require their own witnesses to become pressure.witness.v1
☴->☰ uses R2/R3 qualification, not generic coverage
post-CHOOSE -> ☴ uses U6/U7 qualification
```

This table does not silently qualify every historical `pressure.binary.v0`
reader. Unconverted readers remain control instrumentation.

## 13. Reader And Writer Matrix

| Record/fact | Writer | First named reader | Effect reader |
|---|---|---|---|
| Relation coverage | ☰ | CONNECT inspection/readiness | relation-need qualifier |
| Candidate preview | Pure CONNECT inspection | relation-need qualifier | CONNECT execution |
| Raw relation | ☰ | formation/release/observation need reader | ☵/☷/☴ exact mode |
| Relation formation | ☵ | raw phase derivation | CALM/loss/manifest readers |
| Upper read coverage | ☴ body commit | upper-need qualifier | OBSERVE readiness |
| Qualified witness | pressure derivation | tree candidate builder | same-tick route trace |
| Action plan | pressure derivation | registry readiness and selected organ | effect/discharge verifier |
| Ambiguity | composition | shadow metrics/promotion gate | later policy document |

Every new record has a named reader. Derived plans/witnesses live for one route
derivation and are stored only as immutable trace projections when audited.

## 14. False-Green Matrix

| False green | Rejecting control |
|---|---|
| Any coverage delta votes for ☰ | R1/R5/C0 |
| Candidate detector runs differently in pressure and CONNECT | R2/R3 same plan id/refs |
| Fixture pair alone called production pressure | R8 plus promotion source classification |
| ENCODE consumer only changes prose | R2-R4 require CALM/identity/loss delta |
| Upper reader names ids but ignores versions | U4/U6/U8 |
| Field-native sight discharges semantic prompt | U1/U2 class assertion |
| OBSERVE immediately chases its own output | U2 |
| Clock/budget creates upper pressure | U3 |
| Harness supplies selected sensor/relation input | action-plan provenance assertion |
| Several refs multiply pressure accidentally | witness dedup assertion |
| Canonical tie called adaptive choice | C3/C9 |
| Organ visit called discharge without effect | C8 |
| Unknown mutation silently ignored as supported | U10 promotion blocker |
| Terminal class launders rejected result | existing manifest honesty gate |

## 15. Implementation Sequence Predicted By The Table

```text
1. crystallize pure CONNECT inspection and exact candidate identity
2. crystallize composite upper coverage and significance classifier
3. crystallize witness/action schemas and same-ref verifier
4. crystallize class composition with typed ambiguity
5. implement all of the above behind pressure policy qualified.v1
6. run R, U and C matched controls with live route unchanged
7. amend failures in place; do not tune weights
8. only then begin the separate deterministic promotion corpus
```

## 16. Explicit Deferrals

```text
numeric pressure magnitude and normalization
age/fair scheduling
production L1 projection adapter
semantic relation detector
multi-sensor OBSERVE tick
body-owned MANIFEST action/result projection
qualification of every historical pressure reader
38/38 corpus growth
live substrate corpus
default router authority
```

## 17. Table Acceptance

This table may feed crystall when:

```text
relation coverage and relation need are visibly separate
Step 4's relation-guided ENCODE is the named R1 consumer
upper observation uses compatible sensor-class coverage
the body, not harness/substrate, owns exact action plans
composition exposes ambiguity instead of hiding it in canonical order
all R/U/C controls have one-variable changes and explicit false-green guards
no weight, age or promotion decision is smuggled into witness repair
```
