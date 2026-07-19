# Post-Collapse Plan Delivery Yellowprint v0

Status:

```text
table
source chaos: docs/00_chaos/post_collapse_plan_delivery_notes_2026-07-19.md
bounded branch: exact plan delivery
authority: explicit qualified_need_v0 only
default router promotion: forbidden
```

## 0. Table Decision

The lawful chain is:

```text
current exact plan material at ☴
  -> plan_completion_review action
  -> ☱ assessment
  -> plan_delivery action
  -> △ Packet-local assembly
```

This table accepts two new action modes and one immutable assessment event. It
does not accept a direct `☴ -> △` edge, a mutable completion flag, semantic
`done`, build completion, or caller-owned manifest material.

## 1. Locked Decisions

```text
D0  the body-owned work mode is a birth fact
D1  plan completion is a positive derived witness, not absence of other pressure
D2  exact plan delivery uses the canonical ☴ -> ☱ -> △ path
D3  ☱ owns completion assessment; △ owns outward assembly
D4  plan items remain semantic content and are not marked executed
D5  only one current exact formation may be delivered in v0
D6  all four strict structure shapes are supported under shape-specific checks
D7  truncated/omitted formation is partial and cannot use complete delivery
D8  caller result ticks and selected ids are compatibility-only inputs
D9  default authority remains shadow
D10 qualified action/effect scopes must match exactly at both edges
```

## 2. Q1: Packet Work Mode

Canonical Packet field:

```lua
packet.regime.work = {
  protocol_version = "packet.work_regime.v0",
  mode = "plan" | "build",
}
```

Birth API:

```lua
packet.new(prompt, {
  work_mode = "plan" | "build",
})
```

Rules:

| Input state | Result |
|---|---|
| option and metadata mode absent | `build` compatibility default |
| option absent, valid metadata mode present | seed canonical mode from metadata |
| valid explicit mode | store exact mode in `regime.work.mode` |
| `metadata.work_mode` absent | mirror canonical mode into metadata |
| metadata mode equals canonical mode | accepted compatibility mirror |
| metadata mode differs | loud birth error |
| unknown mode | loud birth error |
| post-birth mutation request | no API; invariant violation if forged in tests |

The birth event records `work_mode`. The value creates no revision because it
is immutable for one Packet life.

Runner law:

```text
runner options may transport mode into packet.new
runner options may not override an already declared conflicting Packet mode
all later pressure readers read packet.regime.work.mode
```

Old readers may consume `metadata.work_mode` during migration. It is a mirror,
not a second authority.

## 3. Q2: Completion Candidate

Target module:

```text
runtime/plan_completion.lua
```

Pure API:

```lua
plan_completion.inspect(instance, options) -> inspection | nil, err
```

Inspection:

```lua
{
  protocol_version = "plan.completion_inspection.v0",
  work_mode = "plan" | "build",
  state = "complete_candidate" | "absent" | "partial"
        | "blocked" | "ambiguous" | "stale" | "incomplete_scope",
  candidate = plan_delivery_candidate | nil,
  diagnostics = diagnostic[],
  event_truth_status = "runtime_confirmed",
}
```

Candidate:

```lua
{
  protocol_version = "plan.delivery_candidate.v0",
  candidate_id = string,
  packet_id = string,
  generation = integer,
  work_mode = "plan",
  formation_event_ref = string,
  source_unit_ref = string,
  requested_shape = "work_sequence" | "work_hierarchy"
                  | "artifact_set" | "alternative_set",
  formed_unit_ids = string[],
  formed_unit_versions = {[id]=integer},
  activation_partition = {
    deliverable_ids = string[],
    selected_ids = string[],
    suppressed_ids = string[],
  },
  coverage_event_refs = string[],
  crystallization_event_ref = string,
  identity_map_ref = string,
  identity_map_event_ref = string,
  loss_record_ref = string,
  choice_event_ref = string | nil,
  choice_set_ref = string | nil,
  material_fingerprint = string,
  scope_refs = string[],
  provenance_refs = string[],
  source_truth_status = string,
  event_truth_status = "runtime_confirmed",
}
```

`candidate_id` hashes every field except itself. It is deterministic and is
never accepted from the caller.

## 4. Candidate Derivation

Derivation order is fixed:

```text
1. validate packet.regime.work
2. reject non-plan mode with state=absent
3. run structure_inspection.derive with bounded complete scope
4. require zero missing exact formations
5. require exactly one current exact formation
6. resolve and re-verify its formation event, identity map and loss record
7. resolve current field units in frozen formation order
8. derive exact latest material coverage for every current version
9. apply shape-specific activation/choice checks
10. reject latest applicable validation=rejected
11. build material fingerprint and immutable candidate
```

Diagnostic precedence:

| Condition | State | Qualified plan witness |
|---|---|---|
| work mode is build | absent | none |
| no exact formation | absent | none |
| strict structure source scan truncated | incomplete_scope | none |
| exact formation missing | absent; ENCODE owns next action | none |
| malformed/repair formation | blocked | none |
| more than one current exact formation | ambiguous | none |
| linked formation loss truncated/omitted | partial | none |
| formed unit missing/dissolved | blocked | none |
| current unit version not materially covered | stale; OBSERVE owns next action | none |
| alternative collapse outstanding | absent; CHOOSE owns next action | none |
| latest validation rejected | blocked | none |
| all exact checks pass | complete_candidate | review witness allowed |

Unsupported prose diagnostics do not become plan material. They do not make an
otherwise unique exact formation true or false; multiple exact formations,
not unrelated unsupported text, define v0 ambiguity.

## 5. Q3: Shape Matrix

| Shape | Complete v0 condition | Deliverable partition |
|---|---|---|
| `work_sequence` | every formed unit current, non-dissolved and covered; zero omission | all frozen-order units |
| `work_hierarchy` | sequence condition plus every declared connection resolves exact endpoints | all frozen-order units |
| `artifact_set` | every artifact unit current and covered; zero omission | all frozen-order units |
| `alternative_set`, one member | choice inspection says confirmation; member current and covered | sole live member as confirmed selection |
| `alternative_set`, two or more | exact choice event selects one, suppresses all others; every post-choice version covered | selected member only; suppressed members enter residue |

For every shape:

```text
formed order comes from structure_formation
content comes from current field units
connections come from the linked CALM structure
identity comes from field ids and identity map
truth status comes from the formation source
```

The table rejects implicit ordering from Lua map iteration or current field
view order.

## 6. Exact Coverage Law

The candidate requires one latest compatible material coverage entry for each
current formed unit version:

```text
coverage.object_id == formed id
coverage.version == current field version
coverage.observation_class == material
coverage.sensor == field_native
```

For an exact alternative collapse, coverage must include both selected and
suppressed post-action versions. Observing only the selected survivor is
insufficient to confirm the consequence of choice.

Coverage scope is bounded by the same upper limits as qualified observation.
Truncation yields `incomplete_scope`, not completion.

## 7. Exact Loss Law

The linked crystallization loss must be:

```text
kind = structure_projection_loss
omitted_count = 0
omitted_edge_count = 0
truncated = false
loss_log_truncated = false
```

Its non-zero shape-policy amount remains visible and does not block complete
delivery by itself. Omission blocks the complete branch regardless of amount.

Alternative choice loss remains visible in residue. It does not alter plan
completion if the exact selected/suppressed partition is coherent and the
Packet survives identity mortality.

## 8. Completion Review Consumer

Consumer declaration:

```lua
{
  id = "runtime.plan_completion.v0",
  causal_class = "blocking_demand",
  accepted_work_mode = "plan",
  accepted_candidate_protocol = "plan.delivery_candidate.v0",
}
```

Producer is active only when current operator is adjacent to ☱ and the exact
candidate has no current assessment.

Witness:

```lua
{
  protocol_version = "pressure.witness.v1",
  kind = "plan_completion_review_need",
  current_operator = "☴",
  target_operator = "☱",
  causal_class = "blocking_demand",
  source_domain = "plan_completion_candidate",
  scope_refs = review_scope_refs,
  provenance_refs = candidate.provenance_refs + {
    "consumer:runtime.plan_completion.v0",
  },
  action_plan = plan_completion_review_action,
  source_truth_status = candidate.source_truth_status,
  calculation_status = "runtime_confirmed",
}
```

The producer may also derive from another operator adjacent to ☱ in a future
treatment. v0 accepts the exact post-collapse/formation position `☴` only.

## 9. Q4: Review Scope

The producer joins the completion candidate with
`reconciliation.inspect(instance)`.

Required camera state:

```text
has_debt = true
through_seq == current camera head
at least one significant frame references formation or choice consequences
```

Review scope:

```text
exact refs for every current formed unit version
+ significant pending frame refs/reason refs
```

Review provenance:

```text
formation event
identity-map event
crystallization/loss event
all covering upper observation events
choice event when present
consumer contract ref
```

Preconditions:

```lua
{
  packet_id = instance.id,
  generation = instance.generation,
  object_versions = candidate.formed_unit_versions,
  relevant_revisions = {
    potential = instance.revisions.potential,
    calm = instance.revisions.calm,
    constraints = instance.revisions.constraints,
    evidence = instance.revisions.evidence,
    history = instance.revisions.history,
  },
}
```

Budget/loss revisions are intentionally excluded. Routine body payment cannot
invalidate plan material, and mortality is enforced independently before the
next route.

## 10. Review Action

New mode:

```text
plan_completion_review -> ☱
```

Action options:

```lua
options = {runtime = {plan_completion_input = {
  candidate_id = string,
  formation_event_ref = string,
  formed_unit_ids = string[],
  formed_unit_versions = {[id]=integer},
  coverage_event_refs = string[],
  choice_event_ref = string | nil,
  through_seq = integer,
  significant_frame_refs = string[],
}}}
```

Readiness must rederive the candidate and camera inspection, then require exact
equality with action input and action scope. Caller runtime options cannot
override any field.

Effect type:

```text
runtime_eye_payload
```

The payload must add:

```lua
mode = "plan_completion_review"
completion_assessment = plan_completion_assessment
assessment_event_id = string
effect_scope_refs = review_scope_refs
```

Normal runtime reconciliation, tension measurement and lower observation remain
present. Review does not replace the camera; it gives the reconciled consequence
a typed plan interpretation.

## 11. Q5: Completion Assessment

Event type:

```text
plan_completion_assessment
```

Actor right:

```text
☱ only
```

Payload:

```lua
{
  protocol_version = "plan.completion_assessment.v0",
  assessment_id = string,
  state = "complete",
  candidate_id = string,
  work_mode = "plan",
  formation_event_ref = string,
  requested_shape = string,
  formed_unit_ids = string[],
  formed_unit_versions = {[id]=integer},
  activation_partition = table,
  coverage_event_refs = string[],
  choice_event_ref = string | nil,
  crystallization_event_ref = string,
  identity_map_ref = string,
  loss_record_ref = string,
  runtime_reconciliation_ref = string,
  manifest_material_refs = string[],
  basis_revisions = table,
  basis_truth_statuses = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = string,
}
```

Only `state=complete` is written in v0. Partial, blocked, ambiguous, stale and
absent are derived diagnostics and do not create durable assessment events.
This prevents a growing ledger of failed guesses.

`assessment_id` hashes the complete payload except itself. A second review of
the same unchanged candidate resolves the existing assessment instead of
writing a duplicate.

## 12. Delivery Consumer

Consumer declaration:

```lua
{
  id = "manifest.plan_delivery.v0",
  causal_class = "terminal_boundary",
  assessment_protocol = "plan.completion_assessment.v0",
}
```

A delivery witness exists only when:

```text
current operator is ☱
latest matching assessment is complete
assessment candidate still rederives exactly
formed units and relevant revisions still match
Packet is living and affordable for one terminal tick
```

Witness:

```lua
{
  kind = "plan_delivery_need",
  target_operator = "△",
  causal_class = "terminal_boundary",
  source_domain = "plan_completion_assessment",
  scope_refs = delivery_scope_refs,
  provenance_refs = {
    assessment_event_ref,
    runtime_reconciliation_ref,
    formation_event_ref,
    "consumer:manifest.plan_delivery.v0",
  },
  action_plan = plan_delivery_action,
}
```

## 13. Delivery Action

New mode:

```text
plan_delivery -> △
```

Delivery scope:

```text
assessment event ref
+ exact refs for every assessed formed unit version
```

Action options:

```lua
options = {manifest = {plan_input = {
  assessment_event_ref = string,
  assessment_id = string,
  candidate_id = string,
  formation_event_ref = string,
  formed_unit_ids = string[],
  formed_unit_versions = {[id]=integer},
  coverage_event_refs = string[],
  choice_event_ref = string | nil,
}}}
```

Implementation amendment 2026-07-19: `coverage_event_refs` and the optional
`choice_event_ref` repeat the candidate's exact material identity. They grant
no output-selection authority; MANIFEST rederives and compares them before
projecting Packet state.

Preconditions use exact object versions and current plan-relevant revisions.
The action contains no result text, selected value, output item, or semantic
completion claim.

Expected effect:

```text
event_type = manifest_payload
discharge_reader = plan_delivery_need
```

MANIFEST readiness rederives and resolves the assessment. It rejects missing,
stale, non-plan, non-complete or caller-mismatched input.

## 14. Q6: Packet-Local Material Projection

Target pure API:

```lua
plan_completion.project(instance, assessment) -> plan_result | nil, err
```

Plan result:

```lua
{
  protocol_version = "plan.result.v0",
  assessment_ref = string,
  formation_event_ref = string,
  shape = string,
  items = {
    {
      id = string,
      key = string,
      kind = string,
      value = json_value,
      position = integer,
      activation = "live" | "selected",
      content_truth_status = string,
    },
  },
  connections = table[],
  selection = {
    mode = "none" | "confirmation" | "alternative_collapse",
    selected_ids = string[],
    suppressed_ids = string[],
    choice_event_ref = string | nil,
  },
  content_truth_status = string,
}
```

`items` contains deliverable members only. Suppressed alternatives remain in
manifest residue with their ids, values, versions and choice provenance.

Projection reads:

```text
assessment refs
structure_formation event
current exact field units
linked calm.current structure/connection order
choice event when present
linked loss records
```

It reads no runner result, tick list or substrate response text.

## 15. Manifest Payload

Qualified `plan_delivery` emits:

```lua
{
  kind = "manifest_payload",
  mode = "plan_delivery",
  output = {
    type = "plan",
    status = "complete",
    text = canonical_json(plan_result),
    language = nil,
    structured = plan_result,
  },
  sources = {
    assessment_event = string,
    runtime_reconciliation_event = string,
    structure_formation_event = string,
    choice_event = string | nil,
    crystallization_event = string,
    identity_map_event = string,
    upper_observation_events = string[],
  },
  assembly = {
    rule = "plan_delivery.v0",
    work_mode = "plan",
    input_provenance = "packet_state",
    outcome = "complete",
  },
  residue = {
    structure_loss = table,
    choice_loss = table | nil,
    suppressed_items = table[],
    assumptions = {},
    unsupported = {},
    missing = {},
  },
  summary = {
    type = "plan",
    status = "complete",
    item_count = integer,
    suppressed_count = integer,
    source_event = assessment_event_ref,
  },
  terminal_cause = "complete",
  effect_scope_refs = delivery_scope_refs,
  truth_status = "runtime_confirmed",
  content_truth_status = assessment.content_truth_status,
}
```

Canonical JSON is a v0 machine projection. A future CLI/TUI may render the
structured result differently without changing body truth.

## 16. Q7: Mode Registry

| Action mode | Target | Option root | Effect type | Mergeable |
|---|---:|---|---|---|
| `plan_completion_review` | ☱ | `runtime` | `runtime_eye_payload` | no |
| `plan_delivery` | △ | `manifest` | `manifest_payload` | no |

Both modes require:

```text
exact scope
Packet id/generation preconditions
exact formed object versions
strict option keys
named discharge reader
body-owned readiness
body-owned effect verification
```

Unknown fields, caller output material and mode/target mismatch fail loudly.

## 17. Q8: Discharge And Staleness Matrix

| Mutation/state | Review need | Delivery need |
|---|---|---|
| no assessment for current candidate | present | absent |
| complete assessment for current candidate | absent | present at ☱ |
| formed unit version changes | old assessment stale; upper/review may re-arm | absent |
| choice partition changes | review re-arms after coverage | absent |
| new exact formation appears | ambiguous or new candidate | old delivery absent |
| relevant constraint/evidence/history changes | review rederives | old delivery absent |
| only budget tick changes | unchanged if Packet remains alive | unchanged |
| Packet dies before △ | no living witness | no living witness |
| △ executes | Packet terminal | no successor |

The assessment is immutable history. Staleness is derived by comparison; old
events are never edited.

## 18. Q9: Terminal Verification Order

Required runner order remains:

```text
committed route to △
-> registry readiness with committed plan
-> MANIFEST organ execution
-> pressure_action.verify_readiness
-> pressure_action.verify_effect
-> append/charge/camera bookkeeping
-> packet.manifest_packet
-> terminal freeze and death
```

Route commit alone creates no manifest, terminal event or death. A tick ceiling
after committing the edge but before executing △ leaves the Packet living or
host-stopped under the existing ledger rule; it cannot claim arrival/execution.

Malformed body payload is a loud harness invariant failure, not a beautiful
Packet death. Typed external failure remains separate from this pure internal
assembly path.

## 19. Pressure Competition

Class ordering remains:

```text
terminal_boundary > blocking_demand > causal_affordance
```

But a higher class cannot exist before its exact source fact exists:

| Current fact | Produced action |
|---|---|
| unobserved formed/current versions | field-native OBSERVE |
| unresolved alternatives | alternative collapse |
| complete observed plan candidate, no assessment | plan completion review |
| current complete assessment | plan delivery |

This sequence is caused by discharge/re-arm facts, not a hardcoded rail.

## 20. Truth And Cost

| Surface | Truth/cost law |
|---|---|
| Work mode | runtime-confirmed immutable birth configuration |
| Completion candidate | runtime-confirmed derivation; not stored |
| Plan item values | semantic proposal |
| Review action | one ordinary ☱ step; zero identity loss |
| Assessment | runtime-confirmed act over proposal content |
| Delivery action | one ordinary △ step; zero identity loss |
| Manifest payload | runtime-confirmed assembly; content status preserved |
| Objective plan correctness | unsupported by this treatment |

ENCODE and CHOOSE loss are carried outward unchanged. Review and delivery do
not refund, multiply or conceal them.

## 21. Q10: Compatibility And Promotion

```text
legacy MANIFEST without qualified action             retained
runner result projection on compatibility path       retained and labelled
qualified plan completion under explicit tree mode   treatment candidate
default router authority                             unchanged shadow
generic natural-language completion                  unqualified
build completion                                     unqualified
full-tree promotion                                  blocked
```

The treatment is promotion-eligible only if:

```text
action source is body, not fixture
all inspection scopes are complete
route and effect use exact committed action
manifest input provenance is packet_state
positive, negative and ablation corpus is green
```

## 22. Named Readers

| Written record | Writer | Named reader |
|---|---|---|
| `regime.work` | Packet birth | plan completion inspection; system/compat readers |
| work mode in birth event | Packet birth | audit/lineage readers |
| completion assessment | ☱ | qualified delivery producer; MANIFEST readiness |
| assessment ref in action | router commit | MANIFEST organ/effect verifier |
| structured plan result | △ | packet terminal/corpse; future CLI/TUI/lineage |
| suppressed plan residue | △ | corpse/grave/lineage and outward surfaces |

Candidates, witnesses and staleness are derived and need no storage reader.

## 23. Permanent Test Matrix

### Birth controls

| ID | Case | Assertion |
|---|---|---|
| B0 | no mode | canonical build default stored in regime and metadata |
| B1 | explicit plan | plan stored and birth event stamped |
| B2 | explicit build | build stored |
| B3 | metadata mismatch | loud birth error |
| B4 | unknown mode | loud birth error |

### Inspection controls

| ID | Case | Expected state |
|---|---|---|
| I0 | build mode, exact plan form | absent |
| I1 | plan, no exact form | absent |
| I2 | current unobserved unit | stale |
| I3 | exact sequence, covered | complete_candidate |
| I4 | exact hierarchy with valid edges | complete_candidate |
| I5 | exact artifact set | complete_candidate |
| I6 | one-member alternative | complete_candidate/confirmation |
| I7 | unresolved alternatives | absent; choice missing |
| I8 | collapsed alternatives, post-versions covered | complete_candidate |
| I9 | collapsed alternatives, suppressed version uncovered | stale |
| I10 | omitted structure item/edge | partial |
| I11 | two current exact formations | ambiguous |
| I12 | rejected latest validation | blocked |
| I13 | dissolved/missing member | blocked |

### Action controls

| ID | Case | Assertion |
|---|---|---|
| R0 | candidate + significant frames | exact review witness/action |
| R1 | caller changes scope | rejected before ☱ |
| R2 | caller changes candidate id | rejected before ☱ |
| R3 | route committed, ☱ not executed | no assessment |
| R4 | ☱ executes exact action | one assessment and matching effect |
| R5 | duplicate unchanged review | no duplicate assessment |
| D0 | current assessment at ☱ | exact terminal witness/action |
| D1 | stale assessment | no terminal witness |
| D2 | caller injects text/items/result | rejected or ignored compatibility-only |
| D3 | route committed, △ not executed | no manifest/death |
| D4 | △ exact action | Packet-local non-empty plan result and terminal death |

### Grown lives

| ID | Trace/result |
|---|---|
| P0 | sequence: `☴☵☴☱△`, dead/complete |
| P1 | two alternatives: `☴☵☴☳☴☱△`, dead/complete |
| P2 | one alternative: `☴☵☴☱△`, dead/complete |
| P3 | same exact structure in build mode: no qualified plan terminal |
| P4 | malformed prose: no exact plan terminal |
| P5 | ceiling after route to ☱: no assessment |
| P6 | ceiling after route to △: no manifest/death |
| P7 | caller result A versus result B: qualified output equal |

### Ablations

| ID | Pair | Required delta/invariant |
|---|---|---|
| A0 | review producer active/ablated | ☱ prediction changes; shadow live physics equal |
| A1 | delivery producer active/ablated | △ prediction changes; shadow live physics equal |
| A2 | qualified result injection pair | Packet-local output equal |

## 24. False-Green Matrix

| False green | Rejecting control |
|---|---|
| model says done | I1/P4 |
| pending plan units called build-complete | I0 plus plan-specific assessment assertions |
| direct `☴ -> △` shortcut | topology and P0/P1 trace |
| route commit creates assessment | R3 |
| route commit creates manifest | D3/P6 |
| latest field-native OBSERVE causes empty output | D4 |
| MANIFEST reads runner ticks | P7/A2 |
| only selected alternative observed | I9 |
| truncation called complete | I10 |
| old assessment survives mutation | D1 |
| content truth promoted to runtime | D4 truth assertions |
| shadow observer changes live route/cost/loss | A0/A1 |

## 25. Implementation Sequence Predicted By The Table

```text
1. crystallize work regime, completion inspection, assessment and result schemas
2. make work mode a validated birth-owned Packet fact
3. implement pure plan completion inspection/projection with I controls
4. add assessment event right and ☱ review execution
5. add review action schema, producer, readiness and effect verification
6. add Packet-local qualified MANIFEST assembly
7. add delivery action schema, producer, readiness and effect verification
8. grow P0-P7 and R/D controls
9. run shadow ablations and historical/full regression
10. manifest treatment and choose the next bounded branch
```

## 26. Explicit Deferrals

```text
partial plan delivery
multiple-formation merge
build completion and repository hands
semantic quality validation of a plan
generic prose-to-completion inference
repair and qualified DISSOLVE
lineage completion/re-entry
default authority promotion
human rendering policy for CLI/TUI
```
