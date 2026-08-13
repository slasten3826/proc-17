# Qualified DISSOLVE Inherited-Form Blueprint v0

Status:

```text
layer: crystall (◈)
date: 2026-08-12
source table:
  docs/01_table/yellowprints/qualified_dissolve_inherited_form_yellowprint.v0.md
cross-table audit:
  docs/00_chaos/dissolve_network_table_cross_audit_2026-08-12.md
crystall cross-audit:
  docs/00_chaos/dissolve_network_crystall_cross_audit_2026-08-12.md
depends on:
  docs/02_crystall/blueprints/network_rejected_form_materialization.v0.md
  docs/02_crystall/blueprints/pressure_need_and_action_composition.v0.md
  docs/02_crystall/blueprints/object_version_coverage.v0.md
crystall cross-read: satisfied
implementation authority: yes; direct inherited-form treatment only
scope: direct inherited_rejected_form unit only
raw/formed relation DISSOLVE semantics: unchanged
semantic-age/every-tick collection: deferred
router/full-tree promotion: forbidden
```

## 0. Crystallized Claim

The first production-grown DISSOLVE treatment is:

```text
FLOW materializes one exact inherited_rejected_form applicability unit
-> body derives a blocking need with an exact action
-> Tree selects ▽ -> ☷
-> ☷ atomically changes live applicability into preserved residue
-> exact changed versions derive one ☷ -> ☴ consequence
```

DISSOLVE changes what binds the child. It does not change what happened to the
ancestor, decide what the child should build, call a model, or prove repair.

## 1. Exact Implementation Surface

Add:

```text
core/dissolve_schema.lua
tests/test_inherited_form_dissolve.lua
tests/test_inherited_form_dissolve_hostile.lua
tests/test_dissolve_network_life.lua
```

Modify:

```text
core/packet.lua
runtime/body.lua
runtime/field.lua
runtime/qualified_pressure.lua
runtime/pressure_action.lua
runtime/upper_coverage.lua
organs/dissolve.lua
organs/observe.lua
runtime/operator_registry.lua
runtime/edge_catalog.lua only if evidence naming needs precision, never adjacency
tests/test_pressure_action.lua
tests/test_qualified_pressure_shadow.lua
tests/test_dissolve.lua
tests/test_edge_stats_v3.lua
tests/run.lua
```

Do not add a substrate call, grave reader, mutable release registry, global
route override, second unit allocator or new death cause.

## 2. Exact Schema Module

`core/dissolve_schema.lua` is pure and owns:

```lua
normalize_inherited_reason(value)
normalize_release(value)
normalize_residue_carrier(value)
same(left, right)
release_identity(value_without_release_id)
```

It rejects:

```text
unknown keys
metatables and cycles
unbounded strings/arrays/source refs
non-canonical ref order
invalid prefixed digests
foreign truth-status vocabulary
raw artifact/output/authority fields
```

It owns no Packet, trace, field, route or mutable cache.

## 3. Dedicated Packet Event

Add exactly one event type:

```text
unit_dissolution
```

It is dedicated and actor-restricted:

```lua
dedicated_event_types.unit_dissolution = true
event_actor_rights.unit_dissolution = {['☷'] = true}
```

Add:

```lua
packet.append_unit_dissolution(instance, event)
  -> detached_event | nil, err
```

The gate requires:

```text
living mutable Packet
current ☷ actor tick
exact event keys
truth_status=runtime_confirmed
cost={}
payload normalized by core.dissolve_schema
deep-copy and post-copy revalidation
```

Generic `append_trace` cannot forge the event. Appending the event itself does
not increment `potential`; the atomic field transaction owns that revision.

## 4. Named Qualified Consumer

Add to `runtime/qualified_pressure.lua`:

```lua
local inherited_form_consumer = {
    id = "dissolve.inherited_rejected_form.v0",
    causal_class = "blocking_demand",
}
```

Add:

```lua
qualified.inherited_form_witnesses(instance, context, options)
  -> witnesses, diagnostics | nil, err
```

It derives at most one witness. Positive predicate:

```text
Packet alive, current generation and Tree authority
current operator adjacent to ☷
exact network.reentry_projection.v1 in ingress
projection basis=qa_rejected and rejected_form present
exactly one current-generation field unit:
  kind=inherited_rejected_form
  created_by=▽
  activation=live or selected
  carrier equals projection.rejected_form
  content_truth_status=inherited_proposal
no matching unit_dissolution event
consumer not ablated
```

Trusted contradictions return diagnostics/invariant error, not scalar
pressure. Honest absence returns no witness.

## 5. Witness And Scope

Witness:

```lua
{
  protocol_version = "pressure.witness.v1",
  witness_id = deterministic_existing_identity,
  kind = "inherited_rejected_form_release_need",
  current_operator = current,
  target_operator = "☷",
  target_edge = canonical_edge(current, "☷"),
  direction = "help",
  causal_class = "blocking_demand",
  source_domain = "network_inherited_rejected_form",
  scope_refs = sorted_unique{
    exact_unit_version_ref,
    network_projection_id,
    carrier_id,
    source_corpse_id,
    historical_qa_id,
    candidate_seal_id,
    verdict_id,
  },
  provenance_refs = sorted_unique{
    "consumer:dissolve.inherited_rejected_form.v0",
    ...projection source refs,
  },
  action_plan = exact_release_action,
  calculation_status = "runtime_confirmed",
  source_truth_status = "inherited_proposal",
  derivation_version = "pressure.qualified_need.v0",
}
```

The witness asserts that one applicability form needs release. It does not
assert that the ancestor verdict is a current-child verdict.

## 6. Pressure Action Mode

Extend the existing maps with:

```lua
mode_targets.inherited_rejected_form_release = "☷"
mode_option_roots.inherited_rejected_form_release = "dissolve"
mode_effect_types.inherited_rejected_form_release = "dissolve_organ_payload"
```

The mode is deliberately absent from `mergeable_modes`.

Exact options:

```lua
{
  dissolve = {
    scope = "unit",
    target = {
      kind = "unit",
      id = unit_id,
      version = unit_version,
    },
    reason = {
      kind = "rejected",
      subtype = "ancestor_candidate",
      network_projection_id = string,
      carrier_id = string,
      source_corpse_id = string,
      historical_qa_id = "qa-history:<sha256>",
      candidate_seal_id = string,
      verdict_id = string,
    },
    preserve_residue = true,
  },
}
```

Extend generic preconditions with one optional mode-specific key:

```lua
planned_residue_unit_id = string | nil
```

For this mode require:

```lua
{
  packet_id = instance.id,
  generation = instance.generation,
  object_versions = {[unit_id] = unit_version},
  planned_residue_unit_id = field.plan_unit_ids(instance, 1)[1],
  raw_epoch = nil,
  relevant_revisions = {potential = instance.revisions.potential},
}
```

For every other current mode `planned_residue_unit_id` must be nil. The action
scope must equal the witness scope exactly.

Expected effect:

```lua
{
  event_type = "dissolve_organ_payload",
  scope_refs = exact_witness_scope,
  discharge_reader = "inherited_rejected_form_release_need",
}
```

## 7. Action Validation And Dispatch

`pressure_action` must add exact normalization and mode-contract checks:

```text
target id/version equals sole object-version precondition
planned residue id is present and syntactically a field-unit id
potential revision is the only relevant global revision
raw epoch absent
preserve_residue exactly true
reason coordinates agree with action scope
caller options cannot override action-owned dissolve input
```

`verify_preconditions` additionally requires:

```text
current unit version exact
current potential revision exact
current next planned field id exact
```

`registry_context` writes the normalized action only under
`options.dissolve`; no harness reason can be merged into it.

`verify_effect` calls `core.dissolve_schema` and verifies:

```text
payload.mode=inherited_rejected_form_release
payload release target/version/reason equals plan
payload residue id equals planned id
payload effect_scope_refs equals plan scope
one exact release event exists
target and residue current field states match the release
```

## 8. Independent Readiness

`organs/dissolve.readiness` branches on `options.scope == "unit"` before the
existing relation view.

It independently re-derives:

```text
current exact target/version and current generation
kind=inherited_rejected_form
activation live/selected
created_by=▽ and creation ref in current ingress projection
carrier schema/equality against ingress rejected_form
all projection/carrier/corpse/QA/seal/verdict joins
applicability=inherited_proposal
no prior release for this target before-version/projection
preserve_residue=true
planned residue id equals current allocator output
```

It returns the exact action scope refs, not a subset:

```lua
{
  operator = "☷",
  ready = boolean,
  reason = "inherited_rejected_form_releasable"
         | "nothing_dissolvable"
         | "already_released"
         | typed_mismatch,
  target = {kind="unit", id=string, version=integer} | nil,
  source_refs = exact_action_scope,
  required_capabilities = {},
  missing_capabilities = {},
  event_truth_status = "runtime_confirmed",
}
```

Caller reason text alone can never make readiness true.

## 9. Sole Atomic Body Writer

The transaction spans two body-owned surfaces: append-only trace and field.
Therefore `runtime/body.lua`, not `runtime/field.lua`, owns the public writer:

```lua
body.release_inherited_rejected_form(instance, input)
  -> release, residue_unit | nil, err
```

The body API requires the current actor to be ☷. It is the only public API
allowed to set an `inherited_rejected_form` unit to `dissolved`. Amend generic
`field.set_activation` to reject that kind with:

```text
inherited rejected form requires atomic release transaction
```

`runtime/field.lua` adds two lower-level helpers used only by the body
transaction:

```lua
field.prepare_inherited_form_release(instance, "☷", input)
  -> immutable_plan | nil, err

field.commit_inherited_form_release(instance, "☷", immutable_plan, event_id)
  -> residue_unit | nil, err
```

`prepare` is pure. `commit` accepts only an exact current plan and a dedicated
event id from the same body transaction; it cannot append trace or choose a
different target/residue. Generic callers cannot use either helper as a
release shortcut.

The body transaction performs all fallible validation before append:

```text
Packet mutability and ☷ lease
exact target/version/activation/generation
exact ingress/reason/projection joins
potential revision precondition
planned next field unit id
normalized residue carrier and release payload
all unit/source-ref bounds
absence of prior release
```

It then snapshots only the touched in-memory surfaces, with ownership split
explicitly:

```text
body: trace length
field: target unit, planned residue slot, unit_order length, next_unit_id,
       revisions.potential
```

Commit transaction:

```text
1 append dedicated unit_dissolution event
2 target activation live/selected -> dissolved
3 target version N -> N+1 and activation_source -> release event
4 insert planned rejected_form_residue version 1 using same event as creation
5 append residue id to unit_order and advance next_unit_id
6 increment revisions.potential exactly once for the atomic transaction
```

The field commit runs under protected execution and restores every field
snapshot on any error. The body transaction truncates the just-appended trace
event whenever field commit does not complete exactly. Any append error,
invariant failure or Lua exception therefore restores both owned surfaces and
returns loud failure. There are no external effects in this transaction.

The event is appended first only after every later value is pre-built and
validated. The rollback still exists as defense against implementation faults.

## 10. Release Identity And Event

Reserve `residue_unit_id` through the existing field allocator before computing
the release identity. Do not derive a unit id from the release id.

Release payload:

```lua
{
  protocol_version = "dissolve.inherited_rejected_form_release.v0",
  release_id = "dissolve-release:<sha256>",
  target = {
    kind = "unit",
    id = string,
    before_version = integer,
    after_version = integer,
    before_activation = "live" | "selected",
    after_activation = "dissolved",
  },
  reason = exact_normalized_reason,
  residue_unit_id = planned_field_unit_id,
  released_mass = {forms = 1, relations = 0},
  irreversible_identity_loss = 0,
  source_refs = sorted_unique_string_array,
  event_truth_status = "runtime_confirmed",
  content_truth_status = "mixed",
}
```

`release_id` is the digest of every normalized field except itself. Event:

```lua
{
  type = "unit_dissolution",
  operator = "☷",
  truth_status = "runtime_confirmed",
  payload = release,
  cost = {},
}
```

The runner pays the ordinary operator tick. The event does not duplicate cost.

## 11. Residue Unit

Exact carrier:

```lua
{
  protocol_version = "dissolve.rejected_form_residue.v0",
  source_packet_id = string,
  source_corpse_id = string,
  source_generation = integer,
  historical_qa_id = "qa-history:<sha256>",
  candidate_seal_id = string,
  qa_contract_id = string,
  verdict_id = string,
  rejected_check_refs = sorted_unique_string_array,
  failure_summary = {
    check_reason = bounded_string,
    termination = normalized_bounded_record,
    cause = normalized_bounded_record,
    finality = normalized_bounded_record,
  },
  release_id = string,
  ancestor_evidence_truth_status = "runtime_confirmed",
  prior_applicability_truth_status = "inherited_proposal",
  release_truth_status = "runtime_confirmed",
}
```

Field unit:

```lua
{
  id = planned_residue_unit_id,
  kind = "rejected_form_residue",
  carrier = exact_carrier,
  source_refs = exact_release_source_refs + release_id,
  event_truth_status = "runtime_confirmed",
  content_truth_status = "mixed",
  activation = "live",
  created_by = "☷",
  created_event_id = unit_dissolution_event.id,
  generation = instance.generation,
  version = 1,
}
```

No artifact bytes, raw streams, repair commands or authority cross this unit.

## 12. Organ Effect

`organs/dissolve.run` unit branch calls readiness, then the sole atomic body
writer.
It returns:

```lua
{
  kind = "dissolve_organ_payload",
  mode = "inherited_rejected_form_release",
  status = "applied",
  readiness = exact_readiness,
  reads = {
    target_unit_id = string,
    target_before_version = integer,
    network_projection_id = string,
  },
  writes = {
    target_after_version = integer,
    target_activation = "dissolved",
    residue_unit_id = string,
  },
  dissolution = exact_release,
  residue = detached_residue_unit,
  released_mass = {forms=1, relations=0},
  loss = {
    kind = "dissolution_loss",
    amount = 0,
    irreversible = false,
    truth_status = "runtime_confirmed",
  },
  trace_event_id = unit_dissolution_event.id,
  effect_scope_refs = exact_action_scope,
  event_truth_status = "runtime_confirmed",
  content_truth_status = "mixed",
}
```

Existing raw and active-relation branches remain byte-for-byte behaviorally
unchanged except shared helper refactors proven by their existing suites.

## 13. Exactly Once And Finality

The release reader derives prior release only from dedicated events joined to
the current target/projection. There is no mutable `released=true` registry.

```text
zero matching events + live exact target -> eligible
one matching event + dissolved target + residue -> discharged
more than one event -> invariant failure
event without matching mutation/residue -> invariant failure
dissolved target without event/residue -> invariant failure
dead/terminal Packet -> all APIs reject before writes
```

Identical direct replay returns `already_released`/not ready and performs no
mutation, cost, loss or event append.

## 14. Route Precedence

At the first child FLOW completion:

```text
semantic current-work witness is deferred by exact live prerequisite
relation recognition remains at most causal_affordance
inherited-form release is blocking_demand
pressure precedence: terminal_boundary > blocking_demand > causal_affordance
-> ▽ -> ☷ without tie-only victory
```

No router special case for glyphs or unit kinds is added.

Consumer ablation removes the witness and therefore the release/route. It does
not fabricate a fallback route; the untreated life may stall or take another
qualified neighbor and is retained as control evidence.

## 15. One Post-Release OBSERVE Action

Amend `upper_coverage.classify` explicitly:

| Unit/state | Need class | Sensor | Presentation |
|---|---|---|---|
| `network_current_work`, live | semantic | semantic | base prompt, once |
| `inherited_rejected_form`, live | none | none | release prerequisite owns it |
| Same form, dissolved by ☷ | material | semantic | covered, carrier excluded |
| `rejected_form_residue`, live | semantic | semantic | bounded residue, once |

After release, these needs group into one `semantic_observe` action. Extend its
exact options with an optional closed field:

```lua
presentation_policy = "network.rejected_form_after_release.v0" | nil
```

This policy is legal only when the exact unit set contains:

```text
one current work unit for ingress projection
one dissolved inherited form for same projection/release
one residue for same release
```

`organs/observe` verifies those joins and builds:

```text
canonical base = instance.chaos.raw_prompt = json(current_work)
append = one canonical bounded residue presentation
```

It excludes current-work duplication and the inherited-form carrier while
retaining all exact versions in `read_units`. The semantic observation records
both `semantic` and `material` classes, discharging the combined obligation in
one tick. No `☴ -> ☴` self-loop is introduced.

## 16. Registry Rights

Amend the ☷ descriptor:

```text
reads += field.potential units, ingress.network_projection
writes += field.potential activation, unit_dissolution, residue unit
```

Amend ☴ descriptive reads for the explicit presentation policy. Registry
metadata remains descriptive; schema, actor and transaction APIs enforce the
rights.

## 17. Loss And Accounting

```text
ordinary body tick: charged once by runner
substrate calls: 0 during ☷
released form mass: 1
released relation mass: 0
irreversible identity loss: 0 only because exact residue/history survives
potential revision: +1 atomic transaction epoch
target object version: +1
residue object version: 1
```

Omitting residue or source refs while claiming zero loss is a trusted
invariant failure.

## 18. Test Contract

Unit/hostile cases:

```text
QD01 no rejected-form unit -> no witness
QD02 accepted/no-QA control -> no witness
QD03 exact live form -> one blocking witness/action
QD04 target version changes after commit -> stale, no writes
QD05 foreign carrier/verdict/QA id -> invariant rejection
QD09 exact replay -> no second effect
QD10 malformed/omitted residue -> transaction leaves all snapshots equal
QD14 dead child -> every release API inert
QD15 stable tuple -> stable planned unit/release identities
```

Grown integration cases:

```text
QD06 consumer ablated -> form remains live, no E02/release
QD07 ordinary consumer -> ▽->☷ executes with exact pressure/action/readiness refs
QD08 aftermath -> ☷->☴ executes one merged observation
QD11 observer instrumentation off/on -> route/state/loss/budget/corpse identical
QD12 no substrate -> ☷ succeeds; later ☴ blocks honestly
QD13 generic blocked/grave material -> does not satisfy QA-specific consumer
```

The positive life must start with the real QA-rejected ancestor grown for the
lineage crystall and continue through body-derived completion, carrier,
NETWORK, continuation, birth and FLOW. The trusted test host may supply only
the separately verified fresh empty child root described by the lineage
crystall; it cannot supply any semantic record, target or route. Hand-created
field targets do not count as promotion evidence.

Retain green regressions:

```text
tests/test_raw_dissolve.lua
tests/test_relation_phase.lua
tests/test_dissolve.lua
tests/smoke_mortality_battery.lua
full tests/run.lua
```

The separate `pending_dissolve_live_route_gate.lua` raw-stale RED remains RED
until its own writer/choreography campaign. This direct-unit treatment does not
claim to solve it.

## 19. Edge Evidence

Record the grown treatment under current authority epoch/revision:

```text
E02 ▽ -> ☷
  committed and executed
  selected witness kind inherited_rejected_form_release_need
  causal class blocking_demand
  action/readiness/effect refs exact
  no tie-only or forced-exclusion success

E07 ☷ -> ☴
  committed and executed
  one semantic action covers material + semantic consequence
  exact released target/residue/current-work versions
```

Consumer ablation is the matched control. Edge evidence alone does not promote
Tree authority or declare all DISSOLVE behavior complete.

## 20. Acceptance

```text
one body-grown inherited form creates one named blocking need
action pins exact target/version/projection and planned residue id
readiness independently re-derives all joins
one atomic writer creates release + target mutation + residue or nothing
history survives while child applicability leaves the live set
release is exactly once and dead-Packet finality holds
route emerges as ▽->☷->☴ without router special cases
post-release observation is one bounded semantic/material action
raw/formed DISSOLVE and ordinary recovery remain unchanged
```

This is the first conditional garbage-collection treatment. It is not yet the
general law that DISSOLVE runs every tick or measures semantic age.
