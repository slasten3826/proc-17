# DISSOLVE Pressure-Relief Reader Yellowprint v0

```text
layer: TABLE
date: 2026-08-13
source chaos:
  docs/00_chaos/dissolve_pressure_relief_first_measurement_notes_2026-08-13.md
audit evidence:
  docs/00_chaos/dissolve_pressure_relief_cross_table_audit_r1_r5_notes_2026-08-20.md
depends on:
  docs/01_table/yellowprints/qualified_dissolve_inherited_form_yellowprint.v0.md
  docs/01_table/yellowprints/pressure_need_and_action_composition_yellowprint.v0.md
  docs/01_table/yellowprints/operator_tree_physics_yellowprint.v0.md
scope:
  dissolve.inherited_rejected_form_release.v0 only
runtime authority change: no
DISSOLVE event schema change: no
new mutable ledger: forbidden
runtime implementation authorization: yes; explicitly granted 2026-08-20
cross-table audit: completed 2026-08-20; amended by A1
crystallization readiness: satisfied 2026-08-20
crystallization authorized: yes by explicit machinist instruction 2026-08-20
crystall result:
  docs/02_crystall/blueprints/dissolve_pressure_relief.v0.md
router/default authority change: no
general semantic-GC formula: not authorized
```

## 0. Purpose

Define the first named post-effect reader for DISSOLVE pressure aftermath:

```text
selected qualified obligation
-> committed action
-> executed exact release
-> same-coordinate causal comparison
-> real-coordinate successor observation
-> typed discharge view
```

The reader answers one bounded question:

```text
Did the exact causal obligation that selected this DISSOLVE effect cease to
hold because the body changed, rather than merely because the Packet moved?
```

It does not decide whether a form is garbage, select a route, execute an
operator, mutate the field, certify its own effect, or claim that total Packet
tension became smaller.

## 1. Selected Decisions

| ID | Decision |
|---|---|
| PRD01 | Pressure relief is read after the effect; ☷ cannot write it into its own effect event. |
| PRD02 | v0 measures typed discharge of the selected obligation, not global scalar `Z`. |
| PRD03 | Before/after causal comparison uses the same source topology coordinate. |
| PRD04 | The real post-effect coordinate is read separately for successor obligations. |
| PRD05 | Route arrival alone is never evidence of relief. |
| PRD06 | Exact witness absence and same-obligation absence are both required. |
| PRD07 | Exact release state/event/readiness joins are required; absence alone is insufficient. |
| PRD08 | New successor pressure is retained, not subtracted from the completed release. |
| PRD09 | The reader is pure and writes no Packet event, cache, watermark or second ledger. |
| PRD10 | Missing evidence means `not_measurable`, never zero relief. |
| PRD11 | Contradictory trusted evidence is an invariant failure, never Packet mortality. |
| PRD12 | Multiple selected witnesses or merged DISSOLVE actions are unsupported in v0. |
| PRD13 | One committed body route is the request root; all downstream refs are resolved from trace. |
| PRD14 | Same-coordinate derivation runs only at the named post-router, pre-successor-mutation capture boundary. |
| PRD15 | Runtime frame, actual pressure snapshot and post derivation must agree on release, coordinate and revision vector. |
| PRD16 | The returned schema represents `not_measurable`, `not_discharged` and discharged outcomes without laundering absence into zero. |

## 2. The Topology False Green

The selected witness targets `☷` while the Packet is at `▽`. After route
arrival the Packet is at `☷`, where a self-loop is illegal:

```text
before effect at ▽: inherited release witness is visible
before effect at ☷: the same witness is invisible by topology alone
```

Therefore this comparison is invalid:

```text
pre-effect actual snapshot at ▽
versus
post-effect actual snapshot at ☷
```

It confounds two independent changes:

```text
Packet coordinate changed: ▽ -> ☷
body state changed: inherited form live -> dissolved
```

The reader must isolate them with a same-coordinate post-effect derivation.

## 3. Three Views, Not One

### 3.1 Selected pre-effect view

The authoritative pre-effect source is the qualified pressure snapshot named
by the committed Tree route:

```text
actual coordinate: ▽
selected target: ☷
selected witness count: exactly 1
selected action mode: inherited_rejected_form_release
```

The reader does not accept a caller-supplied witness. It resolves the route,
route derivation, pressure snapshot, selected candidate, witness and action
plan through their stored identities.

### 3.2 Same-coordinate post-effect control

After the release, the reader performs one pure qualified-pressure derivation
over current body state while holding the comparison coordinate equal to the
pre-effect coordinate `▽`:

```text
body state: real post-effect state
comparison coordinate: pre-effect ▽
route/action authority: none
trace append: none
```

This is a counterfactual topology control, not a claim that the living Packet
returned to `▽`. Its calculation is runtime-confirmed; its coordinate is
explicitly tagged `same_coordinate_control` and may never be committed as a
route snapshot.

### 3.3 Real successor view

The reader separately consumes the first actual qualified pressure snapshot
derived after the destination tick:

```text
actual coordinate: ☷
expected current treatment successor: upper_observation_need -> ☴
```

This view reports what the living Packet must do next. It does not participate
in the discharge subtraction because it is a different topology coordinate
and may contain different causal obligations.

## 4. Required Input Chain

```lua
{
  packet_id = string,
  generation = positive_integer,
  route_event_ref = "event-...",
}
```

The caller supplies one source identity: the committed body route that selected
`▽ -> ☷`. It may not supply destination, effect, frame, witness, count or
successor payloads. Every downstream identity and semantic field is resolved
from the Packet's append-only body trace.

The root route must verify as a Tree-authority body event and expose:

```text
derivation_ref
pressure_snapshot_ref
one selected unexcluded ready candidate to ☷
one inherited_rejected_form_release action plan
selected_action_plan_id equal to that plan
```

The derivation and pre-effect pressure snapshot must contain the same selected
candidate, witness and action plan. Byte-equal nested copies are verified by
their deterministic identities; no copy becomes a second authority.

Required append-only order:

```text
pre-effect qualified tension_measure
< route_derivation
< committed route ▽->☷
< destination operator_tick ☷
< unit_dissolution
< post-effect runtime frame
< actual post-effect qualified tension_measure at ☷
< actual post-effect route_derivation
```

The first three records must agree on:

```text
pressure_snapshot_ref
derivation_ref
selected target ☷
selected_action_plan_id
selected witness identity and action plan
```

### 4.1 Body-only arrival reconstruction

The destination tick is the first subsequent body-lane event after the root
route. It must be `operator_tick` at `☷`. Observer-instrumentation events are a
different identity lane and may be skipped; no intervening body route, tick,
death, manifest or freeze event is admissible.

The exact `unit_dissolution` must occur after that tick and before the next body
actor-lease opener or terminal boundary. Its own writer has already enforced
membership in the current ☷ tick; the reader reconstructs and verifies the
same boundary historically.

When edge-credit v3 evidence is present, its commit ref, destination tick ref
and effect refs must agree exactly with the body-derived chain. A mismatch is
an invariant failure. Absence of optional instrumentation does not invalidate
sufficient body evidence and does not authorize synthetic arrival records.

### 4.2 Post-effect capture boundary

The reader runs at one exact massless runner hook:

```text
after router.after_tick has appended the first actual post-effect
qualified tension_measure at ☷ and its route_derivation

before commit_route, no-viable death handling, or any successor body tick
```

At invocation all must hold:

```text
instance.operator = ☷
post runtime_frame.operator = ☷
actual post pressure current_operator = ☷
instance.revisions = runtime_frame.revisions_after
instance.revisions = actual post pressure source_revisions
runtime frame source_event_refs include destination tick and release
runtime frame effect_refs include the exact release
post route_derivation.pressure_snapshot_ref names the actual post snapshot
```

The hook returns detached reader output through the runner result. It appends no
Packet event and executes no route. If current revisions have advanced beyond
the joined snapshot, historical same-coordinate reconstruction is unavailable
in v0 and the result is `not_measurable`; the reader must not inspect the later
field and call it post-effect state.

## 5. Selected Obligation Identity

v0 requires one selected executable witness:

```lua
{
  kind = "inherited_rejected_form_release_need",
  target_operator = "☷",
  causal_class = "blocking_demand",
  source_domain = "network_inherited_rejected_form",
  consumer_contract = "dissolve.inherited_rejected_form.v0",
  action_plan = {
    mode = "inherited_rejected_form_release",
    target_operator = "☷",
    ...
  },
}
```

Two identities are retained:

```text
exact witness identity:
  witness_id, including exact old unit version and source refs

same-obligation key:
  consumer contract
  witness kind/source domain/target operator/action mode
  target unit id
  network projection id
  carrier/corpse/history/seal/verdict ids
```

The same-obligation key deliberately excludes the target version. Otherwise a
bug could increment the unit version, emit a new witness id for the same
unresolved release, and be counted as relief.

The key is not free-form concatenation. It is the SHA-256 identity of this
canonical envelope:

```lua
{
  protocol_version = "dissolve.pressure_obligation_identity.v0",
  packet_id = string,
  generation = positive_integer,
  treatment = "dissolve.inherited_rejected_form_release.v0",
  consumer_contract = "dissolve.inherited_rejected_form.v0",
  witness_kind = "inherited_rejected_form_release_need",
  source_domain = "network_inherited_rejected_form",
  target_operator = "☷",
  action_mode = "inherited_rejected_form_release",
  target_unit_id = string,
  network_projection_id = string,
  carrier_id = string,
  source_corpse_id = string,
  historical_qa_id = string,
  candidate_seal_id = string,
  verdict_id = string,
}
```

Canonical serialization uses the repository's structured identity mechanism.
The returned form is `pressure-obligation:<sha256>`. Target version, trace event
ids, route ids and measurement time are deliberately excluded. Every included
field is resolved from the selected witness/action and verified NETWORK
projection; no caller value enters the digest.

## 6. Effect Join

The reader accepts only one exact `unit_dissolution` whose payload verifies as
`dissolve.inherited_rejected_form_release.v0` and whose effect matches the
selected action plan.

| Selected source | Effect/final state | Requirement |
|---|---|---|
| action target id/version | release target before id/version | exact |
| action reason refs | release reason/source refs | exact |
| planned residue id | release residue id | exact |
| expected event type | destination payload/effect | exact |
| release target after version | current target version | exact |
| release after activation | current target activation | `dissolved` |
| release event id | target activation source | exact |
| release id | residue carrier release id | exact |
| residue id/version | current residue | exact, live and current generation |
| released mass | release schema | `{forms=1, relations=0}` |
| irreversible identity loss | release schema | `0` |

The old action must no longer be executable. Independent post-effect readiness
must return `already_released`, and its exact preconditions must be stale on
the target object version.

## 7. Discharge Predicate

The selected obligation is discharged only if all conditions hold:

```text
P1 complete selected pre-effect identity chain verifies
P2 exact destination effect and final-state join verifies
P3 same-coordinate post derivation is pure
P4 exact selected witness_id is absent from same-coordinate post derivation
P5 no witness with the same-obligation key exists there
P6 selected old action is stale and readiness says already_released
P7 actual post-effect snapshot is later than the release and uses coordinate ☷
P8 successor witnesses are classified independently
```

Outcome law:

```text
P1 cannot establish one selected treatment
  -> invalid request or unsupported v0; no relief view

P1 is valid but P2, P3 or P7 lacks required body evidence
  -> not_measurable; no zero discharge count is emitted

P1/P2/P3/P7 verify but P4, P5 or P6 fails
  -> not_discharged

P1-P8 verify
  -> discharged_with_successor_obligation
     or discharged_without_successor_obligation
```

An unresolved caller ref, wrong root event type or root route that did not
select this treatment is a typed invalid measurement request, not
`not_measurable`. Contradictory runtime-confirmed body records fail loudly as a
harness/world invariant. Neither class becomes Packet mortality.

## 8. Derived View

The planned pure reader returns a detached value:

```lua
{
  protocol_version = "dissolve.pressure_relief.v0",
  measurement_id = "pressure-relief:<sha256>",
  treatment = "dissolve.inherited_rejected_form_release.v0",
  packet_id = string,
  generation = positive_integer,
  measurement_status = "not_measurable"
                     | "not_discharged"
                     | "discharged",
  reason_codes = sorted_unique_string_array,

  selected = {
    pre_coordinate = "▽",
    pressure_snapshot_ref = string,
    route_derivation_ref = string,
    route_event_ref = string,
    witness_id = string,
    same_obligation_key = "pressure-obligation:<sha256>",
    action_plan_id = string,
    causal_class = "blocking_demand",
    target_operator = "☷",
  },

  effect = nil | {
    destination_tick_ref = string,
    release_event_ref = string,
    post_effect_runtime_frame_ref = string,
    release_id = string,
    target = {
      id = string,
      before_version = positive_integer,
      after_version = positive_integer,
      after_activation = "dissolved",
    },
    residue_unit_id = string,
    released_mass = {forms = 1, relations = 0},
    irreversible_identity_loss = 0,
  },

  controlled_post = nil | {
    coordinate = "▽",
    coordinate_status = "same_coordinate_control",
    exact_selected_witness_count = nonnegative_integer,
    same_obligation_count = nonnegative_integer,
    old_action_preconditions_fresh = boolean,
    old_action_readiness = "already_released" | "releasable",
  },

  actual_post = nil | {
    coordinate = "☷",
    pressure_snapshot_ref = string,
    route_derivation_ref = string,
    successor_witness_ids = string[],
    successor_obligation_count = nonnegative_integer,
    expected_successor = nil | {
      witness_id = string,
      action_plan_id = string,
      presentation_policy = "network.rejected_form_after_release.v0",
      executable = boolean,
    },
    other_successor_witness_ids = string[],
  },

  pressure_relief = {
    measure = "typed_selected_obligation_discharge",
    selected_obligation_count = 1,
    discharged_obligation_count = nil | 0 | 1,
    unresolved_selected_obligation_count = nil | 0 | 1,
    classification = "not_measurable"
                   | "not_discharged"
                   | "discharged_with_successor_obligation"
                   | "discharged_without_successor_obligation",
  },

  aggregate_diagnostic = nil | {
    pre_witness_count = nonnegative_integer,
    controlled_post_witness_count = nonnegative_integer,
    actual_post_witness_count = nonnegative_integer,
    controlled_count_delta = integer,
    authoritative_for_relief = false,
  },

  source_refs = sorted_unique_string_array,
  calculation_status = "runtime_confirmed",
  authority = "diagnostic",
}
```

Count law:

| Measurement status | Discharged count | Unresolved count |
|---|---:|---:|
| `not_measurable` | `nil` | `nil` |
| `not_discharged` | `0` | `1` |
| `discharged` | `1` | `0` |

`nil` is mandatory for unmeasured facts. It is not serialized as zero.

`measurement_id` is derived from every field except itself. Returned values
are deep copies. The view is not appended to Packet trace in v0.

For the first measured life:

```text
selected obligation: 1 -> 0
successor obligation: 0 -> 1 upper_observation_need
aggregate witness count under same-coordinate comparison: 1 -> 1
classification: discharged_with_successor_obligation
```

## 9. Successor Classification

The current treatment expects one actual post-effect witness:

```text
kind: upper_observation_need
target: ☴
source domain: upper_observation:material+semantic
presentation policy: network.rejected_form_after_release.v0
scope: current work + dissolved form version + rejected-form residue
```

The reader reports this witness but does not require global pressure to fall.
A successor is not remaining release debt merely because both witnesses use
`blocking_demand`.

The expected successor verifies through the actual post snapshot and its route
derivation. It must bind:

```text
one upper_observation_need witness
target operator ☴
source domain upper_observation:material+semantic
one semantic_observe action plan
exact current-work, dissolved-form and residue unit versions
presentation policy network.rejected_form_after_release.v0
the same release/projection identity verified by the effect join
```

The post derivation reports whether that exact witness is executable. A missing
substrate may make it non-executable while leaving the witness and completed
release intact. Every additional post-effect witness is retained in
`other_successor_witness_ids`; none is silently merged with release debt.

Unexpected successor pressure does not retroactively falsify a verified
release. It is retained in `actual_post` and may make the treatment
`not_measurable` only when it contradicts trusted release/field identity.

## 10. Writer And Reader Ledger

| Record/surface | Writer | Named reader in this contract | When read |
|---|---|---|---|
| pre qualified pressure snapshot | qualified pressure + router trace gate | pressure-relief reader | aftermath derivation |
| route derivation and committed route | router + Packet transition gate | pressure-relief reader | aftermath derivation |
| destination tick | Packet tick gate | pressure-relief reader | effect join |
| `unit_dissolution` | atomic ☷ transaction | pressure-relief reader | effect join |
| target/residue final state | same atomic field transaction | pressure-relief reader | effect join |
| runtime frame | runtime camera | pressure-relief reader | ordering/correspondence |
| actual post pressure snapshot | qualified pressure + router trace gate | pressure-relief reader | successor classification |
| actual post route derivation | router | pressure-relief reader | snapshot identity and successor executability |
| same-coordinate control | pure reader-local derivation | pressure-relief reader only | same invocation; never stored |
| derived relief view | pure pressure-relief reader at named runner hook | focused tests, runner result reader, later exact corpus reader | returned outside Packet trace |

No new record is born without a reader. If a later corpus persists this view,
that corpus requires a separate schema, retention law and named report reader.

## 11. Authority And Failure Policy

The reader may:

```text
read immutable trace and current field state
invoke pure qualified-pressure derivation with an explicit control coordinate
invoke pure action/readiness verification
derive identities, counts and classification
return a detached diagnostic view
run only at the Section 4.2 capture boundary
```

It may not:

```text
append trace
move the Packet or commit a route
execute ☷ or ☴
change target/residue activation
charge budget or loss
call a substrate or tool
alter edge credit
turn not_measurable into zero
grant corpus or router promotion
```

Closed `not_measurable` reason codes:

```text
destination_tick_absent
release_event_absent
post_effect_runtime_frame_absent
actual_post_pressure_snapshot_absent
actual_post_route_derivation_absent
capture_window_advanced
same_coordinate_control_unavailable
```

Closed `not_discharged` reason codes:

```text
exact_selected_witness_survived
same_obligation_survived
old_action_preconditions_remain_fresh
old_action_readiness_remains_releasable
```

Optional v3 arrival evidence being absent is not a reason code. Body evidence
is authoritative. If v3 evidence exists and disagrees, the records contradict
and the derivation fails loudly.

Unknown request keys, caller-supplied downstream refs/payloads, an unresolved
route root, or a route root that did not select this treatment are typed
`invalid_measurement_request` errors. They return no diagnostic view.

Lua errors, malformed trusted records and impossible joins are harness/world
failures and stay loud. They are never converted into Packet death or a
pleasant zero-relief result.

## 12. Matched Controls And Falsifiers

| ID | One changed fact | Required result |
|---|---|---|
| PR-T01 | Exact grown release life | `discharged_with_successor_obligation` |
| PR-T02 | Route arrives at ☷, effect not executed | `not_measurable: release_event_absent`; never zero relief |
| PR-T03 | Effect event exists, target remains live | invariant failure |
| PR-T04 | Target changes without matching effect/residue | invariant failure |
| PR-T05 | Old witness id changes but same-obligation witness survives | `not_discharged` |
| PR-T06 | Old action readiness remains releasable | `not_discharged` |
| PR-T07 | Aggregate count stays `1 -> 1`, selected obligation disappears | discharged |
| PR-T08 | Aggregate count falls, selected obligation survives | not discharged |
| PR-T09 | Successor OBSERVE witness present | retained separately; no debit against release |
| PR-T10 | Required post snapshot absent | `not_measurable: actual_post_pressure_snapshot_absent` |
| PR-T11 | Same-coordinate derivation mutates Packet | invariant failure |
| PR-T12 | No-rigidity life | no selected treatment; no relief credit |
| PR-T13 | Caller supplies any downstream ref, count or witness payload | `invalid_measurement_request` |
| PR-T14 | Two selected release witnesses/merged plan | unsupported v0, no partial credit |
| PR-T15 | Reader enabled/disabled | route, state, budget, loss, corpse and edge credit identical |
| PR-T16 | Substrate absent after release | release can still be discharged; successor may be non-executable |
| PR-T17 | Reader invoked after successor body mutation | `not_measurable: capture_window_advanced`; later field is not read as aftermath |
| PR-T18 | Existing frame/post snapshot revisions disagree | invariant failure |
| PR-T19 | v3 arrival refs disagree with body-derived tick/effect | invariant failure; body trace retained |
| PR-T20 | Expected successor witness plus unrelated successor | expected witness verified; unrelated witness retained separately |

## 13. Acceptance Gate

The R1-R5 cross-table audit completed on 2026-08-20 and proved, after Amendment
A1:

```text
the selected route chain exposes every required identity
one committed route root is sufficient to reconstruct the body chain
same-coordinate derivation cannot acquire route authority
same-coordinate derivation has one bounded capture window
effect verification joins release to current field state
runtime frame, actual successor snapshot and post derivation join exactly
the view requires no second mutable truth store
the reader cannot self-certify through the DISSOLVE event
aggregate pressure is explicitly diagnostic only
all PR-T01 through PR-T20 controls are implementable from named sources
```

TABLE fed the accepted R7 crystall on 2026-08-20. Runtime implementation was
separately authorized on 2026-08-20.

## 14. Explicit Deferrals

```text
general scalar or vector calibration of Z
multiple simultaneous/merged DISSOLVE obligations
raw relation and formed relation relief
semantic age, support marks and mark/sweep eligibility
cross-generation aggregation of relief
persisted relief corpus and compost policy
claim that release causes later semantic insight
default router or full-tree promotion
```

## 15. Audit Disposition And Next Document Step

Completed audit:

```text
docs/00_chaos/dissolve_pressure_relief_cross_table_audit_r1_r5_notes_2026-08-20.md
```

Disposition:

```text
R1 selected witness/action provenance            pass
R2 route/arrival roles                            pass after body-join amendment
R3 atomic release/final-state join                pass
R4 camera/post-effect ordering                    pass after capture amendment
R5 successor classification                       pass after exact-join amendment
R6 TABLE amendments                               complete
```

R7 result:

```text
docs/02_crystall/blueprints/dissolve_pressure_relief.v0.md
```

R8 may implement only that pure reader and exact runner hook. R8.1 completed
the strict schema layer; the next exact implementation step is R8.2.

## Amendment A1: R1-R5 Cross-Table Audit Precision

```text
layer: TABLE AMENDMENT
date: 2026-08-20
source:
  docs/00_chaos/dissolve_pressure_relief_cross_table_audit_r1_r5_notes_2026-08-20.md
status: incorporated into Sections 1 and 4-13
runtime change: none
```

This amendment closes five preimplementation findings through six precision
clauses:

```text
A1.1 one committed route root replaces caller-supplied downstream chain
A1.2 body-lane order defines destination tick and current actor-tick effect
A1.3 exact post-router/pre-successor-mutation capture boundary is mandatory
A1.4 output schema represents unmeasured, unresolved and discharged outcomes
A1.5 frame/snapshot/post-derivation/successor identities join exactly
A1.6 same-obligation identity uses one versioned canonical envelope
```

The amendment does not claim historical field reconstruction. It avoids that
claim by making late invocation explicitly unmeasurable in v0. A future
persisted aftermath corpus requires its own writer, schema, retention law and
reader; it may not silently widen this diagnostic view.

## Amendment A2: R7 Outcome Representation Closure

```text
layer: TABLE AMENDMENT
date: 2026-08-20
source:
  docs/02_crystall/blueprints/dissolve_pressure_relief.v0.md
status: incorporated into Sections 8 and 11
runtime change: none
```

The R7 schema audit found that the first Section 8 shape allowed a
`not_discharged` classification while fixing every `controlled_post` field to
the successful discharge values. That shape could name surviving debt only in
a reason string while its structured values lied.

Amendment A2 makes the four fields measured values:

```text
exact_selected_witness_count: nonnegative integer
same_obligation_count: nonnegative integer
old_action_preconditions_fresh: boolean
old_action_readiness: already_released | releasable
```

The discharge predicate still requires exactly `0`, `0`, `false` and
`already_released`. Any positive count, fresh precondition or releasable old
action yields the matching closed `not_discharged` reason. Contradictory or
unclassifiable readiness remains a loud invariant failure and is not added to
the view vocabulary.
