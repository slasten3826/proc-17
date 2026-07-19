# Post-Collapse Plan Delivery Blueprint v0

Status:

```text
crystall
source chaos: docs/00_chaos/post_collapse_plan_delivery_notes_2026-07-19.md
source table: docs/01_table/yellowprints/post_collapse_plan_delivery_yellowprint.v0.md
implementation authorized for bounded explicit treatment
default authority promotion forbidden
```

## 1. Goal

Implement one exact body-owned plan terminal chain:

```text
exact current plan at ☴
  -> plan_completion_review
  -> ☱ writes complete assessment
  -> plan_delivery
  -> △ assembles plan.result.v0 from Packet
  -> packet.manifest_packet freezes dead/complete corpse
```

The implementation must turn the current honest
`stalled(no_qualified_need)` boundary into a terminal result only when every
fact named below exists.

## 2. Non-Goals

```text
no direct ☴ -> △ topology edge
no build completion
no repository mutation
no LLM completion classifier
no partial-plan terminal policy
no multi-formation merge
no generic semantic MANIFEST promotion
no qualified DISSOLVE
no default router promotion
```

## 3. New Runtime Surface

New module:

```text
runtime/plan_completion.lua
```

New action modes:

```text
plan_completion_review -> ☱
plan_delivery          -> △
```

New trace event:

```text
plan_completion_assessment, writer ☱ only
```

New protocols:

```text
packet.work_regime.v0
plan.completion_inspection.v0
plan.delivery_candidate.v0
plan.completion_assessment.v0
plan.result.v0
```

## 4. Packet Birth Contract

`packet.new` resolves work mode before constructing areas:

```lua
canonical = options.work_mode
compat = options.metadata and options.metadata.work_mode

if canonical == nil then canonical = compat end
if canonical == nil then canonical = "build" end
require canonical == "plan" or canonical == "build"
if compat ~= nil then require compat == canonical end
```

The Packet stores:

```lua
instance.regime.work = {
  protocol_version = "packet.work_regime.v0",
  mode = canonical,
}
instance.metadata.work_mode = canonical
```

The birth trace payload includes `work_mode=canonical`.

`runtime/tension_runner.lua` copies `options.packet_options`, resolves mode in
the same order (`options.work_mode`, packet option, metadata compatibility,
then `build`), rejects every disagreement, and supplies the canonical mode to
direct or vertical birth. It never mutates the mode afterward.

Existing direct callers that supply only `metadata.work_mode` remain valid.

## 5. Plan Completion API

```lua
plan_completion.inspect(instance, options)
  -> inspection | nil, err

plan_completion.resolve_candidate(instance, input)
  -> candidate | nil, err

plan_completion.review_scope(instance, candidate, runtime_inspection)
  -> scope | nil, err

plan_completion.build_assessment(instance, candidate, reconciliation_record)
  -> assessment | nil, err

plan_completion.find_assessment(instance, candidate)
  -> assessment_record | nil, reason

plan_completion.resolve_assessment(instance, input)
  -> assessment_record, candidate | nil, err

plan_completion.project(instance, assessment_record, candidate)
  -> plan_result, residue, sources | nil, err

plan_completion.verify_review_effect(instance, plan, payload)
  -> true | nil, err

plan_completion.verify_delivery_effect(instance, plan, payload)
  -> true | nil, err
```

All functions except trace lookup and projection are pure reads. The module has
no mutation right. ☱ appends assessments through `packet.append_event`; △
returns a payload that the tension runner later seals through
`packet.manifest_packet`.

## 6. Inspection Algorithm

`inspect` executes this exact order:

```text
1. validate Packet and packet.regime.work
2. non-plan -> absent
3. derive bounded structure inspection
4. incomplete structure scan -> incomplete_scope
5. any missing exact formation -> absent (ENCODE still owns it)
6. zero current exact formations -> absent
7. more than one current formation -> ambiguous
8. resolve formation event and all linked proof records
9. linked loss omission/truncation -> partial
10. resolve formed field units in frozen formation order
11. missing/dissolved/foreign unit -> blocked
12. derive bounded latest upper coverage
13. missing exact current material coverage -> stale
14. apply shape/choice partition
15. latest validation rejected -> blocked
16. build complete_candidate
```

Unsupported prose diagnostics do not enter step 5. Only exact strict structure
candidates participate.

## 7. Candidate Identity

Candidate fields are exactly those in the table. Canonical identity is:

```lua
candidate_id = "plan-candidate:" .. json.encode({
  packet_id,
  generation,
  work_mode,
  formation_event_ref,
  requested_shape,
  formed_unit_ids,
  formed_unit_versions,
  activation_partition,
  coverage_event_refs,
  crystallization_event_ref,
  identity_map_ref,
  identity_map_event_ref,
  loss_record_ref,
  choice_event_ref,
  material_fingerprint,
  scope_refs,
  provenance_refs,
  source_truth_status,
})
```

Exact unit refs use the existing form:

```text
coverage:field_unit:<id>:<version>
```

`scope_refs` contains exactly those refs. Camera refs are joined later by
`review_scope`; they are not part of material identity.

## 8. Shape Resolution

### 8.1 Non-choice shapes

For `work_sequence`, `work_hierarchy`, and `artifact_set`:

```text
every formed id exists
activation is live or selected
none is suppressed or dissolved
deliverable_ids == frozen formed order
selected_ids == {}
suppressed_ids == {}
```

Hierarchy connections come from the linked `calm.current` formation and every
endpoint must be one of the exact formed ids.

### 8.2 One-member alternative

```text
formation choice contract names exactly one id
choice inspection status is confirmation
unit activation is live or selected
deliverable_ids = {sole id}
selected_ids = {sole id}
suppressed_ids = {}
choice_event_ref = nil
```

Confirmation does not fabricate a CHOOSE event or loss.

### 8.3 Collapsed alternative set

```text
formation contract names N >= 2 ids
one exact alternative_collapse event references formation
event selected_ids has one member
event suppressed_ids contains every other formation id
current versions equal event post_versions
current activations equal selected/suppressed partition
every post-version has current field-native material coverage
deliverable_ids = selected_ids
```

Any partition mismatch is `blocked`, not a new choice guess.

## 9. Coverage Resolver

Use `upper_coverage.derive` with bounded limits. Reject a truncated view.

For each formed unit, select the latest entry keyed by:

```text
object_id + material observation class
```

Require:

```text
entry.version == current unit.version
entry.sensor == field_native
entry.observation_class == material
```

Return sorted unique observation event refs. Content truth status is the common
unit status or `mixed`.

## 10. Loss Resolver

Resolve formation payload references to:

```text
crystallization event
boundary loss record
identity map
```

Require the existing structure proof invariants plus:

```text
loss.kind == structure_projection_loss
loss.omitted_count == 0
loss.omitted_edge_count == 0
loss.truncated == false
loss.loss_log_truncated == false
```

The numeric amount is retained in residue and candidate fingerprint. It is not
a completion threshold.

## 11. Review Scope

`review_scope` requires the existing camera inspection to have debt and at
least one significant frame reason resolving to the candidate's formation,
crystallization, identity map or choice event.

It returns:

```lua
{
  through_seq = integer,
  significant_frame_refs = string[],
  scope_refs = sorted_union(
    candidate.scope_refs,
    runtime_inspection.source_refs
  ),
  provenance_refs = sorted_union(
    candidate.provenance_refs,
    candidate.coverage_event_refs,
    {"consumer:runtime.plan_completion.v0"}
  ),
}
```

Routine pending frames may be reconciled by the same ☱ tick but do not create
the witness.

## 12. Review Action Plan

`pressure_action` adds strict `runtime.plan_completion_input` normalization.
The input contains only identity, ids, versions, coverage refs, optional choice
ref, watermark and significant frame refs.

Action preconditions:

```lua
object_versions = candidate.formed_unit_versions
relevant_revisions = current {
  potential, calm, constraints, evidence, history
}
```

`plan_completion_review` is non-mergeable.

`qualified_pressure` builds one blocking witness only when:

```text
current operator == ☴
inspection.state == complete_candidate
no matching current assessment exists
review_scope succeeds
ablate_plan_completion_consumer ~= true
```

## 13. Runtime Organ Treatment

Registry must pass `runtime` options to both readiness and run.

Without `plan_completion_input`, existing runtime behavior is unchanged.

With a qualified input, readiness:

```text
rederives exact candidate
rederives reconciliation inspection
rederives review scope
requires exact input/scope equality
returns source_refs = committed action scope
```

Execution order inside ☱:

```text
1. rederive readiness
2. camera.reconcile through committed watermark
3. build complete assessment referencing reconciliation event
4. append plan_completion_assessment as ☱
5. run existing progress/foundation/budget/loss snapshot
6. measure tension
7. record lower observation
8. return runtime_eye_payload with assessment and effect scope
```

The assessment does not replace reconciliation completion state. Generic
`body.progress` may remain `incomplete`; plan completion is a separate typed
interpretation.

## 14. Assessment Identity And Reuse

Assessment identity hashes its complete body except `assessment_id`.

Before appending, ☱ searches trace backward for a valid assessment with the
same candidate id and current exact versions. If found, execution must not be
requested because the review witness is already discharged. A direct duplicate
organ call returns `plan_completion_already_assessed` rather than writing a
second event.

Only complete assessments are stored in v0.

## 15. Delivery Action Plan

`qualified_pressure` at current operator ☱:

```text
derives current complete candidate
resolves matching current assessment
builds terminal_boundary plan_delivery witness
```

`delivery_scope_refs` is:

```text
assessment event id
+ candidate exact unit refs
```

Action preconditions capture the same exact object versions and current
`potential/calm/constraints/evidence/history` revisions.

`pressure_action` adds strict `manifest.plan_input` normalization.
`plan_delivery` is non-mergeable.

Producer is disabled by:

```text
ablate_plan_delivery_consumer == true
```

## 16. MANIFEST Treatment

Registry passes `manifest` options to readiness/run through the existing option
root. Qualified action scope cannot be overridden by top-level runner result.

Without `plan_input`, existing compatibility assembly remains unchanged.

With `plan_input`:

```text
readiness resolves current assessment and candidate
readiness.source_refs equals committed action scope
run calls plan_completion.project
run emits exact manifest_payload mode=plan_delivery
```

Qualified assembly must not call `last_payload(result, operator)` and must not
read `options.result`.

## 17. Plan Projection

Projection resolves field units in frozen formation order.

Deliverable item:

```lua
{
  id = unit.id,
  key = unit.carrier.key,
  kind = unit.carrier.kind,
  value = deep_copy(unit.carrier.value),
  position = unit.carrier.position,
  activation = unit.activation,
  content_truth_status = unit.content_truth_status,
}
```

Suppressed items use the same projection but enter residue only.

`output.text` is canonical `json.encode(plan_result)`. The structured result is
also stored at `output.structured`.

No item value or connection is accepted from the action plan.

## 18. Effect Verification

### 18.1 Review

`verify_review_effect` requires:

```text
payload.kind == runtime_eye_payload
payload.mode == plan_completion_review
payload.effect_scope_refs == action.scope_refs
assessment event exists, writer ☱, truth runtime_confirmed
assessment candidate/scope/reconciliation match action input
candidate still resolves after effect
```

### 18.2 Delivery

`verify_delivery_effect` requires:

```text
payload.kind == manifest_payload
payload.mode == plan_delivery
payload.effect_scope_refs == action.scope_refs
payload.output.type/status == plan/complete
payload.assembly == plan_delivery.v0 + packet_state
payload.terminal_cause == complete
payload.truth_status == runtime_confirmed
payload.content_truth_status == assessment content status
reprojected plan_result == payload.output.structured
payload.output.text == json.encode(reprojected result)
source and residue refs match Packet records
```

The tension runner invokes this verifier before `packet.manifest_packet`.

## 19. Pressure Ordering

The new producer is appended to qualified derivation after structure/choice and
upper inspection. Class composition, not producer call order, selects:

```text
unobserved version -> upper blocking action
unresolved set     -> choice blocking action
complete candidate -> runtime review blocking action
complete assessment -> terminal delivery action
```

If two same-class actions remain simultaneously executable, existing typed
ambiguity applies. The implementation may not silently impose the intended
trace by producer order.

## 20. Provenance Resolver

`pressure_composition.provenance_resolves` accepts two new static consumer refs:

```text
consumer:runtime.plan_completion.v0
consumer:manifest.plan_delivery.v0
```

Every other provenance ref must resolve to Packet trace, field, relation or
ingress data through existing rules.

## 21. Registry Declaration

Update descriptor declarations:

```text
☱ reads: plan candidate, camera, work regime
☱ writes: plan completion assessment
△ reads: plan completion assessment, exact field material
```

No new capability is required. Both actions are body-internal.

## 22. Errors

Typed absence/diagnostics:

```text
plan_mode_absent
plan_material_absent
plan_material_partial
plan_material_ambiguous
plan_material_stale
plan_material_blocked
plan_runtime_effect_absent
plan_completion_already_assessed
plan_assessment_absent
plan_assessment_stale
```

Invariant failures remain loud:

```text
forged candidate/action identity
scope mismatch
unknown action field
mode/target mismatch
assessment event malformed or wrong actor
Packet/result projection mismatch
caller overrides action-owned runtime/manifest scope
```

## 23. Test Files

Add:

```text
tests/test_plan_completion.lua
tests/test_plan_delivery.lua
tests/test_post_collapse_plan_life.lua
```

Extend:

```text
tests/test_packet.lua
tests/test_pressure_action.lua
tests/test_operator_registry.lua where declaration assertions require it
tests/run.lua
```

Permanent gates are B0-B4, I0-I13, R0-R5, D0-D4, P0-P7 and A0-A2 from the
yellowprint. Tests must grow formation/choice/assessment records through real
organs whenever the behavior under test depends on their effects.

## 24. Historical Regression

Required after focused gates:

```text
lua tests/run.lua
lua tests/smoke_mortality_battery.lua
lua tests/smoke_runtime_camera_treatment.lua
lua tests/smoke_pressure_ablation.lua
focused exact ENCODE/CHOOSE tests
all Lua sources through luac -p
git diff --check
```

The live DeepSeek strict-boundary smoke is optional for body physics. If run,
its new expected terminal traces become:

```text
sequence:     ☴☵☴☱△
alternatives: ☴☵☴☳☴☱△
```

## 25. Promotion Gate

Success permits only:

```text
bounded plan completion/review/delivery producers accepted inside
explicit qualified_need_v0 treatment
```

It does not permit:

```text
router default change
full-tree promotion
build-agent readiness claim
generic natural-language plan completion claim
```

## 26. Implementation Order

```text
1. Packet work regime and birth controls
2. plan_completion inspection/projection and I controls
3. assessment event and runtime review execution
4. review action schema/producer/effect controls
5. Packet-local manifest delivery
6. delivery action schema/producer/effect controls
7. grown lives and route-only boundaries
8. ablations
9. full regression
10. treatment manifest
```
