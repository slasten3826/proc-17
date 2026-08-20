# DISSOLVE Pressure-Relief Reader Blueprint v0

```text
layer: CRYSTALL
date: 2026-08-20
source table:
  docs/01_table/yellowprints/dissolve_pressure_relief_reader_yellowprint.v0.md
cross-table audit:
  docs/00_chaos/dissolve_pressure_relief_cross_table_audit_r1_r5_notes_2026-08-20.md
scope:
  dissolve.inherited_rejected_form_release.v0 only
implementation authority: yes; R8 explicitly authorized 2026-08-20
runtime authority change: forbidden
router/default change: forbidden
Packet event/schema change: forbidden
new mutable ledger: forbidden
general scalar Z or semantic-GC claim: forbidden
```

## 0. Crystallized Claim

Implement one bounded diagnostic reader that can establish this exact fact:

```text
the qualified inherited-form obligation selected at ▽
was executed through one committed ▽ -> ☷ body route
and ceased to be executable because ☷ changed the exact target state
```

The reader separates three views:

```text
selected pre-effect body evidence at ▽
pure same-coordinate post-effect control at ▽
actual post-effect successor evidence at ☷
```

It returns a detached typed value. It never appends an event, commits a route,
charges a budget or loss, calls a substrate, changes a watermark, or certifies
the DISSOLVE event from the event alone.

This crystall does not implement DISSOLVE-as-time, general garbage collection,
multiple simultaneous release obligations, or a scalar pressure formula.

## 1. Exact Code Surface

R8 adds:

```text
runtime/dissolve_pressure_relief.lua
```

R8 modifies only:

```text
runtime/tension_runner.lua
```

R9 adds:

```text
tests/test_dissolve_pressure_relief_reader.lua
tests/test_dissolve_pressure_relief_reader_hostile.lua
tests/test_dissolve_pressure_relief_runner.lua
```

and registers those files in:

```text
tests/run.lua
```

No R8/R9 change is authorized in:

```text
core/packet.lua
core/dissolve_schema.lua
runtime/qualified_pressure.lua
runtime/pressure_composition.lua
runtime/pressure_action.lua
runtime/field.lua
runtime/camera.lua
runtime/router.lua
runtime/edge_credit.lua
runtime/edge_stats_v3.lua
organs/dissolve.lua
organs/observe.lua
```

If implementation proves one of those modules must change, stop and amend this
crystall before changing it. A convenient implementation is not evidence that
the contract surface was wrong.

The new module may require only:

```text
core.packet
core.digest
core.dissolve_schema
core.network_projection_schema
runtime.field
runtime.qualified_pressure
runtime.pressure_action
runtime.edge_credit
organs.dissolve (readiness only)
```

It has no substrate, host-service, filesystem, repository, QA provider, grave,
lineage, router or Packet-writer dependency.

## 2. Module API

`runtime/dissolve_pressure_relief.lua` exports exactly:

```lua
reader.protocol_version = "dissolve.pressure_relief.v0"
reader.request_protocol_version = "dissolve.pressure_relief.request.v0"
reader.error_protocol_version = "dissolve.pressure_relief.error.v0"

reader.measure(instance, request, trusted_context)
  -> detached_view | nil, typed_error | nil

reader.verify(view)
  -> true | nil, error_string
```

No resolver, identity helper, trace index or mutable state is exported.

Private exact v0 bounds are:

```lua
{
  max_stored_trace_events = 8192,
  max_body_trace_events = 4096,
  max_source_refs = 256,
  max_successor_witnesses = 64,
  max_reason_codes = 8,
  max_string_bytes = 262144,
}
```

Exceeding a bound returns `unsupported_v0`; it does not truncate evidence or
turn the excess into absence.

The request is one exact plain table:

```lua
{
  protocol_version = "dissolve.pressure_relief.request.v0",
  packet_id = string,
  generation = positive_integer,
  route_event_ref = "event-...",
}
```

Unknown keys, metatables, cycles, empty strings, a foreign Packet/generation,
or a non-body/non-Tree/non-`▽ -> ☷` route are invalid requests. The caller may
not supply a witness, action, effect, frame, count, revision, successor or
field value.

`trusted_context` is runner-owned and accepts only:

```lua
nil

or

{
  edge_credit = nil | {
    commit = verified_detached_edge_credit_v3_commit,
    arrival = verified_detached_edge_credit_v3_arrival,
  },
}
```

The `edge_credit` pair is corroboration only. It cannot create body evidence,
fill a missing body ref, or change the derived outcome. Direct tests may
supply it only after `edge_credit.verify_record` succeeds for both records and
`arrival.commit_ref == commit.record_id`.

## 3. Typed Failure Boundary

`measure` returns no view on a request or trusted-world failure. Its second
return is:

```lua
{
  kind = "dissolve_pressure_relief_error",
  protocol_version = "dissolve.pressure_relief.error.v0",
  code = "invalid_measurement_request"
       | "unsupported_v0"
       | "runtime_invariant_failure"
       | "reader_failure",
  stage = closed_stage_name,
  message = non_empty_string,
  source_refs = sorted_unique_string_array,
}
```

Closed stages are:

```text
request
body_trace
selected_obligation
arrival
effect
runtime_frame
actual_post
same_coordinate_control
successor
edge_credit
view
purity
```

Classification law:

| Condition | Result |
|---|---|
| malformed caller request or wrong route root | `invalid_measurement_request` |
| valid route selects more than one release witness or a merged action | `unsupported_v0` |
| contradictory runtime-confirmed body records | `runtime_invariant_failure` |
| Lua throw, identity encoder failure or reader self-mutation | `reader_failure` |
| sufficient selected route but bounded aftermath evidence is absent | a valid `not_measurable` view |
| sufficient aftermath exists but the selected obligation survives | a valid `not_discharged` view |

No error becomes Packet mortality. The runner reports it as a loud harness
stage failure. No `not_measurable` outcome becomes an error merely because the
measurement could not be completed.

## 4. Canonical Body-Trace Resolver

The reader obtains one detached canonical body lane through:

```lua
packet.body_trace_tail(instance.trace, #instance.trace)
```

It must not duplicate the observer-lane compatibility rules or scan the raw
trace as if every event belonged to body identity. It builds one invocation-
local map `event.id -> {event, body_index}` and rejects duplicate body ids.
The map is never cached.

### 4.1 Root route

`route_event_ref` resolves exactly one event with:

```text
type = route
truth_status = runtime_confirmed
payload.authority = tree
payload.from = ▽
payload.to = ☷
payload.derivation_ref = body route_derivation
payload.pressure_snapshot_ref = body qualified tension_measure
payload.selected_action_plan_id = selected action plan id
```

The route, derivation and pressure snapshot must agree on:

```text
current coordinate ▽
selected target ☷
selected candidate identity
selected witness identity
selected action identity
pressure snapshot identity
```

The selected candidate must be unexcluded, ready, uniquely selected and based
on exactly one witness. The witness/action contract is fixed in Section 5.

### 4.2 Destination body interval

Starting after the route body index:

```text
the first subsequent body event must be operator_tick at ☷
the exact unit_dissolution must be inside that actor tick
the release must occur before the next actor-tick opener or terminal boundary
```

Observer-instrumentation events are absent from the canonical body lane and do
not interrupt this interval. A body route, actor tick, manifest, freeze or
death before the expected destination tick is an invariant contradiction.

An absent release event after an otherwise valid arrival produces:

```text
measurement_status = not_measurable
reason_codes = {"release_event_absent"}
```

It never produces relief.

### 4.3 Frame and actual post route

The release interval must be followed by:

```text
one runtime_frame for the same ☷ tick
one qualified tension_measure at actual coordinate ☷
one route_derivation naming that pressure snapshot
```

At the runner capture hook:

```text
instance.operator = ☷
instance.revisions = frame.revisions_after
instance.revisions = post snapshot.source_revisions
frame.operator = ☷
post snapshot.current_operator = ☷
frame.source_event_refs includes destination tick and release
frame.effect_refs includes release
post derivation.pressure_snapshot_ref names the post snapshot
```

Missing records use the closed `not_measurable` reason from TABLE. Existing
records that disagree use `runtime_invariant_failure`.

If live revisions no longer equal both stored revision vectors, return:

```text
not_measurable: capture_window_advanced
```

Do not inspect the later field and describe it as the historical aftermath.

## 5. Selected Obligation Contract

The pre-effect witness is exactly:

```text
kind = inherited_rejected_form_release_need
target_operator = ☷
causal_class = blocking_demand
source_domain = network_inherited_rejected_form
consumer_contract = dissolve.inherited_rejected_form.v0
calculation_status = runtime_confirmed
```

Its action is exactly:

```text
mode = inherited_rejected_form_release
target_operator = ☷
expected_effect.event_type = dissolve_organ_payload
expected_effect.discharge_reader = inherited_rejected_form_release_need
```

The route, derivation and snapshot must contain byte-equivalent detached
copies with the same deterministic ids. The reader then validates the action
through `pressure_action.validate`. It does not normalize a malformed stored
plan into a convenient valid one.

The selected witness must bind one exact target unit/version, one planned
residue id and the NETWORK projection identities:

```text
network_projection_id
carrier_id
source_corpse_id
historical_qa_id
candidate_seal_id
verdict_id
```

## 6. Same-Obligation Identity

The reader derives:

```text
pressure-obligation:<sha256>
```

from the canonical envelope already fixed by TABLE:

```lua
{
  protocol_version = "dissolve.pressure_obligation_identity.v0",
  packet_id = instance.id,
  generation = instance.generation,
  treatment = "dissolve.inherited_rejected_form_release.v0",
  consumer_contract = "dissolve.inherited_rejected_form.v0",
  witness_kind = "inherited_rejected_form_release_need",
  source_domain = "network_inherited_rejected_form",
  target_operator = "☷",
  action_mode = "inherited_rejected_form_release",
  target_unit_id = selected target id,
  network_projection_id = verified projection id,
  carrier_id = verified carrier id,
  source_corpse_id = verified corpse id,
  historical_qa_id = verified QA id,
  candidate_seal_id = verified seal id,
  verdict_id = verified verdict id,
}
```

Encoding is `digest.record(envelope)`. No concatenated ad hoc encoding is
allowed. Target version and all trace/route/time ids are excluded on purpose.

For every post witness of the same treatment family, the reader independently
derives the same envelope. A changed witness id with an equal obligation key
is unresolved debt, not relief.

## 7. Exact Effect And Final-State Join

The unique `unit_dissolution` payload must verify with
`dissolve_schema.verify_release`. The complete organ payload is intentionally
not a reader input: it is a runner-result projection, not Packet body evidence.
The reader therefore verifies the effect directly through the canonical
release schema and current capture-window field join:

```text
selected target id/version = release target before id/version
selected reason/source refs = release reason/source refs
planned residue id = release residue id
target current version = release after version
target current activation = dissolved
target activation source event = release event
residue current id/version = release residue
residue created_event_id = release event
residue carrier release_id = release release_id
released_mass = {forms=1, relations=0}
irreversible_identity_loss = 0
```

Any present contradiction is an invariant failure. The reader cannot infer a
release from current target state without its event and residue.

It must not synthesize a `dissolve_organ_payload` merely to call
`pressure_action.verify_effect`; that would make a reader-created copy testify
for the runtime payload it is supposed to inspect.

### 7.1 Old-action finality

The reader performs two independent checks:

```text
pressure_action.verify_preconditions(old_plan, instance)
  must fail on stale target object version

dissolve.readiness(instance, old_plan-derived options)
  must return ready=false, reason=already_released
```

The readiness options are reconstructed only from the verified old plan:

```lua
options = copy(plan.options.dissolve)
options.qualified_action = {
  plan_id = plan.plan_id,
  scope_refs = copy(plan.scope_refs),
  planned_residue_unit_id = plan.preconditions.planned_residue_unit_id,
  potential_revision = plan.preconditions.relevant_revisions.potential,
}
```

The reader calls `organs.dissolve.readiness`, never `organs.dissolve.run`.

## 8. Same-Coordinate Control

At the exact capture window the reader derives one control snapshot:

```lua
qualified_pressure.derive(instance, {operator = "▽"}, {
  current_operator = "▽",
  router_mode = "tree",
})
```

The implementation may add only existing bounded reader options required to
reproduce `qualified_need_v0`; it may not accept those options from the caller.

Purity is enforced twice:

```text
reader hashes the complete Packet immediately before and after control derive
runner hashes the complete Packet immediately before and after reader.measure
```

Both use `digest.record(instance)`. Any difference is a loud purity failure.

The control snapshot is never appended. It is explicitly labeled:

```text
coordinate = ▽
coordinate_status = same_coordinate_control
authority = diagnostic
```

Discharge requires:

```text
exact old witness_id absent
same-obligation key count = 0
old action preconditions stale
old action readiness = already_released
```

Aggregate witness count is calculated only as a diagnostic and cannot satisfy
any discharge predicate.

## 9. Actual Successor Classification

The reader consumes the actual stored post-effect snapshot/derivation at ☷. It
does not derive a second actual successor view.

The expected successor is exactly one:

```text
kind = upper_observation_need
target_operator = ☴
source_domain = upper_observation:material+semantic
action mode = semantic_observe
presentation_policy = network.rejected_form_after_release.v0
```

It must bind the exact current-work, dissolved-form and residue unit versions
and the same NETWORK/release identity established in Section 7. Executability
comes from the stored post derivation. A missing substrate may make the
candidate non-executable without undoing a verified release.

All other successor witness ids are retained in a separately sorted array.
They are never merged with or subtracted from the selected release debt.

## 10. Derived View Schema

R8 returns exactly:

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
    successor_witness_ids = sorted_unique_string_array,
    successor_obligation_count = nonnegative_integer,
    expected_successor = nil | {
      witness_id = string,
      action_plan_id = string,
      presentation_policy = "network.rejected_form_after_release.v0",
      executable = boolean,
    },
    other_successor_witness_ids = sorted_unique_string_array,
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

R8 implements a strict normalizer/verifier for this schema with these rules:

```text
plain acyclic tables only
unknown keys rejected at every fixed-shape level
all arrays bounded, dense, sorted and unique where declared
all nested values detached
calculation_status exactly runtime_confirmed
authority exactly diagnostic
measurement_id absent during normalization, then assigned last
measurement_id = pressure-relief:<digest.record(view_without_id)>
```

Outcome/count matrix:

| Classification | `measurement_status` | discharged | unresolved |
|---|---|---:|---:|
| `not_measurable` | `not_measurable` | `nil` | `nil` |
| `not_discharged` | `not_discharged` | `0` | `1` |
| `discharged_with_successor_obligation` | `discharged` | `1` | `0` |
| `discharged_without_successor_obligation` | `discharged` | `1` | `0` |

Reason codes are exactly the TABLE Section 11 closed sets. Successful
discharge has an empty `reason_codes` array. A valid view cannot combine
reason codes from different outcome families.

Closed `not_measurable` reasons:

```text
destination_tick_absent
release_event_absent
post_effect_runtime_frame_absent
actual_post_pressure_snapshot_absent
actual_post_route_derivation_absent
capture_window_advanced
same_coordinate_control_unavailable
```

Closed `not_discharged` reasons:

```text
exact_selected_witness_survived
same_obligation_survived
old_action_preconditions_remain_fresh
old_action_readiness_remains_releasable
```

`verify(view)` recomputes `measurement_id` and rejects any mismatch.

## 11. Runner Hook

### 11.1 Option and result surface

`prepare_options` adds:

```lua
dissolve_pressure_relief_reader = "off" | "v0"
```

Default is `off` through R8/R9. The key is runner-only and must be removed by
`body_options`; no organ, router or substrate receives it.

`result` adds:

```lua
dissolve_pressure_relief_reader = "off" | "v0"
dissolve_pressure_relief_measurements = {}
```

The array is bounded by body ticks and receives detached verified views in
capture order. v0 treats a duplicate measurement id as a loud invariant
failure, not a second relief credit.

### 11.2 Arrival locals

Before the existing pending-arrival locals are cleared, runner preserves only
for the current body tick:

```lua
arrived_route_ref = pending_arrival.trace_event_id
arrived_action_mode = committed_plan and committed_plan.mode
arrival_evidence = optional detached v3 arrival returned by
                   record_arrival_evidence
credit_commit = optional detached v3 commit already held by pending_credit
```

`record_arrival_evidence` may be amended to return its existing verified
arrival record in addition to success. It must not alter edge-credit schemas,
decisions or error policy.

Runner combines `credit_commit` and `arrival_evidence` into the optional
trusted-context pair. The locals are discarded after the current tick. They
are not Packet state or a new ledger.

### 11.3 Exact invocation point

When all are true:

```text
reader option = v0
current operator tick = ☷
arrived action mode = inherited_rejected_form_release
router.after_tick returned and appended actual post pressure + derivation
```

runner invokes the reader immediately after `router.after_tick` returns and
before either branch below:

```text
is_committable_route / no-viable death handling
commit_route / successor transition
```

Invocation:

```lua
before = assert(digest.record(instance))
ok, view, err = pcall(reader.measure, instance, {
  protocol_version = reader.request_protocol_version,
  packet_id = instance.id,
  generation = instance.generation,
  route_event_ref = arrived_route_ref,
}, {
  edge_credit = credit_commit and arrival_evidence and {
    commit = credit_commit,
    arrival = arrival_evidence,
  } or nil,
})
after = assert(digest.record(instance))
```

If `ok` is false, `view` is nil, `reader.verify(view)` fails, or hashes differ,
runner returns:

```text
nil, dissolve_pressure_relief:<typed code or purity failure>
```

It does not call `packet.die`, append an instrumentation event, or continue to
route commit. A valid `not_measurable` view is appended to the result array and
the Packet continues normally.

## 12. Optional Edge-Credit Corroboration

When `trusted_context.edge_credit` is present:

```text
edge_credit.verify_record succeeds for commit and arrival
commit.kind = route_evidence_commit
commit.route_trace_ref = body-derived committed route event
arrival.kind = route_evidence_arrival
arrival.route_evidence_id = commit.route_evidence_id
arrival.commit_ref = commit.record_id
arrival.destination_tick_ref = body-derived ☷ tick
arrival.effect_refs contain the exact unit_dissolution event
no foreign effect ref is accepted as the selected release
```

The reader may use the route's existing edge-credit provenance to resolve the
commit correspondence, but body trace remains the authority for arrival and
effect. Any disagreement is `runtime_invariant_failure` at stage
`edge_credit`. Absence is normal and creates no reason code.

## 13. PR-T01 Through PR-T20 Implementation Map

### 13.1 Focused positive and outcome tests

`tests/test_dissolve_pressure_relief_reader.lua` owns:

| Control | Test construction |
|---|---|
| PR-T01 | Grow the real rejected ancestor -> carrier -> child -> E02 release life; capture at hook; expect discharged with successor. |
| PR-T02 | Verified committed arrival with release omitted in a detached hostile trace; expect `not_measurable`, nil counts. |
| PR-T05 | Replace only post witness version/id while retaining the same obligation envelope; expect not discharged. |
| PR-T06 | Controlled readiness remains releasable; expect not discharged. |
| PR-T07 | Aggregate `1 -> 1`, selected release debt gone, successor retained; expect discharged. |
| PR-T08 | Aggregate falls while selected same-obligation debt remains; expect not discharged. |
| PR-T09 | Exact upper OBSERVE successor retained outside release debt. |
| PR-T10 | Post snapshot omitted; expect exact not-measurable reason. |
| PR-T12 | Grown no-rigidity control route is rejected as no selected treatment; no credit. |
| PR-T14 | Two selected release witnesses or merged release plan; expect unsupported v0. |
| PR-T16 | No substrate after release; discharge remains valid and successor executable=false. |
| PR-T20 | Exact successor plus unrelated successor; both arrays preserved correctly. |

The positive case is grown. Mutated detached lives are hostile reader tests,
never promotion evidence.

### 13.2 Hostile identity, order and purity tests

`tests/test_dissolve_pressure_relief_reader_hostile.lua` owns:

| Control | Required rejection |
|---|---|
| PR-T03 | Effect exists but current target remains live -> invariant failure. |
| PR-T04 | Target changes without matching release/residue -> invariant failure. |
| PR-T11 | Inject a mutating same-coordinate derivation -> purity failure. |
| PR-T13 | Add any downstream caller field -> invalid request. |
| PR-T17 | Advance one body mutation after post snapshot -> capture-window advanced without reading later field as aftermath. |
| PR-T18 | Frame and post snapshot revision vectors disagree -> invariant failure. |
| PR-T19 | Verified v3 commit+arrival pair names a foreign route/tick/effect -> invariant failure. |

### 13.3 Runner masslessness test

`tests/test_dissolve_pressure_relief_runner.lua` grows one life twice with
reader `off` and `v0`. PR-T15 requires equality of:

```text
body routes
ticks and organ payloads
Packet digest after removing observer-only result fields
revision vector
budget and loss ledgers
death/corpse/manifest
edge-credit and edge-stats records
substrate call count
```

Only these result fields may differ:

```text
dissolve_pressure_relief_reader
dissolve_pressure_relief_measurements
```

An injected reader error must return a loud runner error while leaving the
Packet without a fabricated death.

## 14. Implementation Order

R8 must proceed in this order:

```text
R8.1 strict request, error and view normalization
R8.2 canonical body-lane resolver and selected-obligation join
R8.3 effect/final-state/old-readiness join
R8.4 same-obligation identity and pure same-coordinate control
R8.5 actual successor classification and measurement identity
R8.6 runner option, transient arrival local and exact capture hook
```

After every coherent Lua slice:

```text
luac -p changed Lua
focused reader test available for that slice
git diff --check
```

Do not run the full suite after every substep. R10 runs the full publication
gate once the final code state is stable.

## 15. Acceptance Gate

R7 is accepted when this document fixes without runtime invention:

```text
one module and one exact public API
one caller request root
one canonical body-lane resolver
one optional non-authoritative v3 corroboration surface
one exact post-router/pre-successor hook
one detached result lane
one typed harness/world failure boundary
two independent purity guards
one closed output/count law
one test owner for every PR-T01 through PR-T20 control
```

R7 did not authorize R8 by itself. The machinist separately authorized R8 on
2026-08-20; implementation now proceeds in the Section 14 order.

## 16. Explicit Deferrals

```text
persisted aftermath corpus
cross-generation relief aggregation
multiple selected or merged DISSOLVE obligations
raw/formed relation relief
semantic support roots and object age
mark/sweep eligibility
non-zero irreversible DISSOLVE loss
scalar/vector calibration of Z
compost consumption of release history
claim that DISSOLVE causes later semantic insight
default router or full-tree promotion
DeepSeek Harness integration or duplicated harness functionality
```
