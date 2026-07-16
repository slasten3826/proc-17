# Runtime Camera And Reconciliation Hypothesis Notes

Status:

```text
chaos / treatment hypothesis and measured outcome
trigger: lower-eye staleness audit and machinist camera insight
source diagnosis: docs/00_chaos/pressure_witness_repair_notes.md
authority: shadow evidence only
live route: unchanged
mandatory lower rails: unchanged
diagnosis outcome: PARTIALLY CONFIRMED 2026-07-16
treatment outcome: PARTIALLY CONFIRMED 2026-07-16
treatment record: docs/00_chaos/runtime_camera_treatment_results_2026-07-16.md
```

## 1. Trigger

The current lower eye is implemented as a sampled observation:

```text
Packet enters ☱
☱ reads current runtime revisions
☱ writes a lower observation
the body completes and charges the ☱ tick
budget revision changes
the lower observation is stale before routing
```

The machinist supplied a different physical reading:

```text
☱ is not an eye that opens and blinks
☱ is a camera that is already on while the body acts
```

That reading explains why the current model creates an extra tick. The Packet
does not need to visit ☱ merely to discover a body fact that the body itself
just produced and recorded.

## 2. Core Hypothesis

Split the current lower-eye implementation into two mechanisms:

```text
runtime camera
  continuous body-owned telemetry
  captures the completed effect and economics of every operator tick
  no separate operator transition
  no additional step charge beyond the tick already being recorded
  no LLM

☱ RUNTIME operator
  reads accumulated runtime frames
  reconciles significant unintegrated consequences with CALM
  owns relation momentum and foundation integration
  records what was reconciled and what remains unresolved
  advances a reconciliation watermark
```

Short form:

```text
camera records
☱ reconciles
```

The camera belongs to the runtime region under ☱ authority, but continuous
recording is body infrastructure, not an implicit ☱ operator tick.

## 3. Why ☱ Must Still Be An Operator

If ☱ becomes only passive telemetry, it stops being an operation and violates
the ProcessLang body model in which operators transform Packet state.

The distinguishing effect of a ☱ tick is therefore not "look". It is:

```text
integrate consequences into the current executable form
```

Possible concrete effects owned by ☱:

```text
reconcile CALM work state with runtime-confirmed effects
activate or update relation momentum
reinforce or weaken foundation patterns from recurrence
classify completion / usable partial / unresolved runtime state
convert unintegrated runtime events into typed pressure sources
expose semantic uncertainty that may justify ☱ -> ☴
```

Routine telemetry alone does not justify a ☱ tick.

## 4. Proposed Tick Boundary

Current body order is approximately:

```text
begin tick
run organ
record destination arrival
advance clock
charge budget
apply operator loss/physics
check mortality
derive pressure
route
```

The camera hypothesis inserts one body-owned stage:

```text
begin tick
run organ
record destination arrival
advance clock
charge budget
apply operator loss/physics
capture immutable runtime frame
check mortality
derive pressure from current Packet + runtime frame
route
```

`capture runtime frame` is included in the current body tick. It is not another
walk edge, another substrate call, or another `steps += 1`.

## 5. Runtime Frame

A frame should contain facts and provenance, not a route recommendation.

Candidate envelope:

```lua
{
  kind = "runtime_frame",
  seq = integer,
  packet_id = string,
  generation = integer,
  tick = integer,
  operator = glyph,
  source_event_refs = table,
  revisions_before = table,
  revisions_after = table,
  changed_components = table,
  budget_state = table,
  loss_state = table,
  progress_state = table,
  evidence_fingerprint = string,
  effect_refs = table,
  event_truth_status = "runtime_confirmed",
}
```

The exact schema belongs to table and crystall. Chaos-level laws:

```text
frame is immutable after append
frame records causes/refs where the body knows them
frame does not contain semantic interpretation from LLM
frame does not select the next operator
frame creation does not increment identity loss
frame creation does not create a separate operator tick
```

## 6. Runtime Head And Reconciliation Watermark

The camera has a monotonic head:

```text
runtime_head = newest completed runtime frame sequence
```

☱ owns a reconciliation watermark:

```text
reconciled_through = newest frame whose significant consequences
                     were considered by a completed ☱ tick
```

The existence of frames after the watermark is not sufficient by itself to
create pressure. Some frames contain only routine telemetry.

Candidate debt law:

```text
runtime_reconciliation_debt exists when
there is at least one relevant, significant, unintegrated effect
after reconciled_through
```

Not:

```text
runtime_head > reconciled_through therefore always go to ☱
```

Otherwise routine budget frames would recreate the current constant debt under
a different name.

## 7. Routine Versus Significant Runtime Delta

Examples that should normally remain telemetry-only:

```text
one expected body step was charged
clock advanced by one
an already-accounted operator event entered trace
an expected scalar phase changed and its consumer is already known
```

Examples that may create runtime reconciliation debt:

```text
new effect evidence changed a work-unit status
actual execution contradicts current CALM expectation
relation recurrence justifies momentum update
foundation pattern changed confidence class
tool/test result is runtime-confirmed but not attached to current work
an effect exists but no body rule can classify it
```

Examples that should create direct non-☱ pressure unless reconciliation is
otherwise needed:

```text
budget crossed exhausted threshold        mortality or △
loss crossed near-death threshold         mortality or △
fresh accepted evidence completes work    △ when adjacent
repeatable work remains                    ☲ when adjacent
validation is missing                      ☶ when adjacent
```

The table must decide exact classes. The camera itself only records facts.

## 8. Replacement Candidate For Lower Observation Debt

Current reader:

```text
lower_observation_debt
  any monitored lower revision differs from the sampled observation
  target ☱
```

Treatment hypothesis:

```text
runtime_reconciliation_debt
  relevant body-confirmed frames remain unintegrated
  target ☱
```

This does not erase lower observations from history. Existing observations can
remain valid historical records. They simply stop being the sole clock for
whether runtime needs another operator tick.

`runtime_mismatch` remains a separate pressure kind and must receive a real
comparator. It cannot alias reconciliation debt.

## 9. What Happens During A ☱ Tick

Candidate transaction:

```text
1. read frames after reconciled_through through current runtime_head
2. classify bounded significant effects using body rules
3. reconcile CALM/evidence/relations/foundation
4. append one runtime_reconciliation record
5. advance reconciled_through to the consumed head
6. leave unresolved refs visible
7. complete the normal body tick and capture its runtime frame
```

The frame created by the ☱ tick itself must not immediately demand another ☱
merely because it contains routine budget charge or expected reconciliation
writes.

Possible laws to test:

```text
self-produced expected reconciliation deltas are acknowledged by the same act
unresolved effects remain debt
new external/downstream effects after reconciliation create new debt
```

The exact settlement mechanism is open:

```text
post-tick acknowledged watermark
typed self-produced frame classification
or an explicit reconciliation coverage record
```

## 10. Relationship To ☴ And LLM

The runtime camera does not call an LLM.

If runtime contains a fact the body cannot semantically interpret:

```text
☱ records unresolved semantic runtime pressure
router may select ☱ -> ☴
☴ sends a bounded runtime frame projection to the substrate
substrate returns semantic_proposal
later organs encode, choose, validate, or reject that proposal
```

Therefore:

```text
LLM may see runtime through ☴
LLM does not live inside ☱
☱ retains ownership of runtime facts
```

## 11. Asymmetry Of The Two Eyes

The previous phrase "the eyes speak one measurement language" may remain true
while their cadence differs:

```text
☴ upper eye
  sampled
  active and potentially substrate-mediated
  observes semantic/external uncertainty

☱ lower runtime region
  continuously instrumented by the body camera
  explicit operator tick only for reconciliation
  observes no external reality beyond body-owned effects
```

Shared properties:

```text
bounded refs
versions/sequences
truth metadata
provenance
missing/unresolved scope
```

Different temporal physics is not an epistemic hierarchy.

## 12. Interaction With Existing Hard Rails

Current rails remain:

```text
☲ -> ☱
☶ -> ☱
```

The hypothesis predicts that they are sometimes unnecessary:

```text
☲ effect already recorded and direct next condition is body-confirmed
  -> no reconciliation debt required

☶ verdict already attached to target work and manifest readiness is known
  -> no reconciliation debt required
```

They may still be physically recreated when:

```text
cycle result changes runtime work/foundation in an unresolved way
logic effect must be integrated into CALM or relation momentum
```

No rail is removed until shadow evidence contains both classes.

## 13. Scope Of The First Experiment

The previously proposed C0/A/B/AB ablation remains the first diagnostic step.

It tests whether current lower-eye signals are degenerate. It does not by itself
prove the camera treatment.

After diagnosis, a separate treatment experiment should compare:

```text
L0 sampled lower-eye debt as currently implemented
L1 runtime camera + reconciliation debt in shadow only
```

Required treatment cases:

```text
routine budget-only tick does not request ☱
budget threshold crossing remains visible to mortality/manifest
new unintegrated evidence requests ☱
already integrated evidence permits a direct edge
☱ reconciliation does not request itself again through its own routine frame
semantic runtime uncertainty can request ☴ without truth promotion
live legacy route/economics remain identical while L1 is shadow-only
```

## 14. Falsification

Mark this hypothesis `REJECTED` or `PARTIALLY REJECTED` if experiments show any
of the following:

```text
continuous capture cannot be separated from an operator tick without hiding cost
reconciliation debt becomes another always-on constant
meaningful runtime changes are missed by the frame/watermark model
lower rails cannot be recreated in cases that genuinely require integration
Packet-local completion becomes less observable
camera state becomes a second mutable truth store beside trace/revisions
```

Do not delete the rejected amendment. Record the experiment and reason in the
same documents.

## 15. Non-goals

```text
do not give tree router live authority
do not remove hard rails
do not add LLM calls to ☱
do not tune pressure weights
do not make telemetry free in budget accounting
do not turn camera frames into permanent lineage memory
do not solve upper-eye self-produced staleness in this hypothesis
```

The upper eye remains a separate unresolved witness problem.

## 16. Proposed Work Order

```text
1. preserve this chaos hypothesis
2. annotate existing body/tree yellowprints without rewriting history
3. annotate existing body/tree blueprints as PENDING amendments
4. manifest C0/A/B/AB diagnostic harness first
5. record diagnostic result
6. only then manifest L1 runtime-camera shadow treatment
7. run treatment battery
8. mark amendments CONFIRMED, REJECTED, or PARTIALLY CONFIRMED
9. reconsider lower rail promotion only after measured evidence
```

## 17. Current Outcome Marker

```text
status: CAMERA CONFIRMED IN SHADOW / TREATMENT PARTIALLY CONFIRMED
diagnostic evidence: docs/00_chaos/pressure_ablation_diagnostic_results_2026-07-16.md
treatment evidence: docs/00_chaos/runtime_camera_treatment_results_2026-07-16.md
promotion consequence: none
```

Diagnostic update:

```text
D1 duplicate runtime_mismatch                         confirmed
budget-only staleness explains all lower debt         rejected
10/12 lower debts were missing pre-☱ observations     confirmed
camera interpretation                                 strengthened, not proven
LOGIC constraints may require real reconciliation     remains open
```

The L0/L1 treatment now confirms that routine economics can remain visible
without becoming generic ☱ pressure, while significant unintegrated frames
create bounded debt and reconciliation discharges it. Selection under tied
binary pressure, independent mismatch, semantic uncertainty, and manifestation
remain open. No rail removal or authority promotion follows from this result.
