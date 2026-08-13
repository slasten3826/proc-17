# Qualified DISSOLVE Inherited-Form Yellowprint v0

Status:

```text
layer: TABLE treatment
date: 2026-08-12
sources:
  docs/00_chaos/dissolve_network_rejected_generation_target_notes_2026-08-12.md
  docs/00_chaos/dissolve_r3_raw_stale_growth_red_observation_2026-08-12.md
  docs/01_table/yellowprints/network_rejected_form_materialization_yellowprint.v0.md
  docs/01_table/yellowprints/pressure_need_and_action_composition_yellowprint.v0.md
  docs/01_table/yellowprints/operator_tree_physics_yellowprint.v0.md
amends:
  qualified pressure/action vocabulary
  DISSOLVE tagged target contract
  upper observation significance after release
runtime implementation authorized: yes through exact crystall only
cross-table audit:
  docs/00_chaos/dissolve_network_table_cross_audit_2026-08-12.md
crystallization readiness: ready
crystallization authorized: yes; machinist instruction 2026-08-12
crystallized as:
  docs/02_crystall/blueprints/qualified_dissolve_inherited_form.v0.md
router promotion authorized: no
```

## 0. Purpose

Define the first production-grown direct-unit DISSOLVE treatment:

```text
NETWORK/FLOW materialized one exact inherited rejected form
-> body derives one qualified release prerequisite
-> Tree commits ▽ -> ☷
-> ☷ releases form applicability exactly once
-> historical rejection survives as bounded residue
-> changed field creates ☷ -> ☴ observation work
```

This is the E02 treatment. It does not promote all 22 edges and does not claim
that semantic age has been implemented.

## 1. Selected Decisions

```text
QD01 The first target is a direct field unit, not a synthetic relation.
QD02 The release need is body-derived and blocking, never a harness reason.
QD03 Exact unit id + version + carrier/verdict refs define the action.
QD04 Readiness independently re-derives the same target and provenance.
QD05 Release changes applicability, not historical QA truth or task identity.
QD06 Release is exactly once and a dissolved form cannot be reactivated.
QD07 Preserved residue means zero irreversible identity loss.
QD08 Released mass and identity loss are different measurements.
QD09 The effect creates a one-service upper semantic/material obligation.
QD10 Existing raw/relation DISSOLVE modes remain unchanged.
QD11 No substrate call occurs during DISSOLVE.
QD12 Instrumentation and observer settings have zero body mass.
```

## 2. Qualified Need Predicate

The named consumer is:

```text
consumer id: dissolve.inherited_rejected_form.v0
causal class: blocking_demand
target: ☷
```

One witness exists only when all facts hold:

| Fact | Requirement |
|---|---|
| Packet | Alive, current generation and Tree authority |
| Topology | Current operator is adjacent to ☷ |
| Ingress | Exact verified `network.reentry_projection.v1` |
| Unit | Kind `inherited_rejected_form`, current generation |
| Activation | `live` or `selected`; v0 expects `live` from FLOW |
| Version | Exact current positive version |
| Carrier | Exact `network.inherited_rejected_form.v0` |
| Join | Projection/carrier/corpse/seal/verdict/check refs agree |
| Verdict | Historical final verdict is `rejected` |
| Applicability | `inherited_proposal` |
| Prior effect | No release event for this unit version/projection |

Absent facts create no witness. Contradictory trusted facts are invariant
errors, not pressure.

## 3. Witness Shape

```lua
{
  protocol_version = "pressure.witness.v1",
  witness_id = string,
  kind = "inherited_rejected_form_release_need",
  current_operator = glyph,
  target_operator = "☷",
  target_edge = canonical_edge,
  direction = "help",
  causal_class = "blocking_demand",
  source_domain = "network_inherited_rejected_form",
  scope_refs = {
    exact_unit_version_ref,
    network_projection_id,
    carrier_id,
    source_corpse_id,
    historical_qa_id,
    candidate_seal_id,
    verdict_id,
  },
  provenance_refs = {
    "consumer:dissolve.inherited_rejected_form.v0",
    ...exact_source_refs,
  },
  action_plan = pressure_action_plan,
  calculation_status = "runtime_confirmed",
  source_truth_status = "inherited_proposal",
  derivation_version = "pressure.qualified_need.v0",
}
```

The witness says a release operation is currently required. It does not say
the ancestor verdict is a current child verdict.

## 4. Action Plan Amendment

Add one mode to `pressure.action_plan.v0`:

```text
mode: inherited_rejected_form_release
target_operator: ☷
option root: dissolve
effect type: dissolve_organ_payload
mergeable: no in v0
```

Exact options:

```lua
{
  dissolve = {
    scope = "unit",
    target = {
      kind = "unit",
      id = string,
      version = integer,
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

Preconditions:

```lua
{
  packet_id = string,
  generation = integer,
  object_versions = {[target_unit_id] = target_version},
  planned_residue_unit_id = string,
  raw_epoch = nil,
  relevant_revisions = {potential = integer},
}
```

The action scope and object version must be exact. A later unit version requires
a newly derived witness/action; a stale committed plan cannot execute.

## 5. Readiness Contract

`organs/dissolve.readiness` receives the committed action options and returns:

```lua
{
  operator = "☷",
  ready = boolean,
  reason = "inherited_rejected_form_releasable"
         | "nothing_dissolvable"
         | "already_released"
         | typed_mismatch,
  target = {kind = "unit", id = string, version = integer} | nil,
  source_refs = string[],
  required_capabilities = {},
  missing_capabilities = {},
  event_truth_status = "runtime_confirmed",
}
```

Readiness independently verifies:

```text
exact live target/version
target belongs to current generation
target was created by FLOW from current network projection
rejected-form carrier schema and all source joins
no prior matching release
preserve_residue=true
```

It may not trust a caller-supplied reason merely because the action plan was
valid when committed.

## 6. Atomic Unit Release

The current generic `field.set_activation` is not sufficient as the complete
writer because it requires a current-tick reason event and does not own
release/residue atomicity. The crystall must assign one body-owned transaction
that performs:

```text
1. revalidate target, version, reason, projection refs and potential revision
2. reserve the next deterministic field unit id and build bounded residue
3. stage one immutable unit-release event with its final event id
4. stage target activation live -> dissolved and version N -> N+1 using that event
5. stage the residue unit using the same event as its creation event
6. commit trace + field + potential revision as one body transaction
7. leave every body surface unchanged if staging or validation fails
```

No public API may leave a release event without mutation, mutation without
event, or dissolved target without its required residue. The one release event
is both the target activation source and the residue unit creation event.

## 7. Release Event

```lua
{
  type = "unit_dissolution",
  operator = "☷",
  truth_status = "runtime_confirmed",
  payload = {
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
    reason = exact_reason,
    residue_unit_id = string,
    released_mass = {
      forms = 1,
      relations = 0,
    },
    irreversible_identity_loss = 0,
    source_refs = string[],
    event_truth_status = "runtime_confirmed",
    content_truth_status = "mixed",
  },
  cost = {},
}
```

The identity projection excludes only `release_id`; every other payload field
participates in its digest. `residue_unit_id` is planned independently from the
release id by the existing field allocator:

```text
field.plan_unit_ids(instance, 1)[1]
at the exact committed potential revision
```

The action binds this planned id and revision before execution. Only then is
`release_id` computed over the payload containing that unit id. The residue
carrier may refer to `release_id`; the residue unit id may not be derived from
it. This removes an otherwise circular identity contract without introducing
a second field-unit numbering law. The body tick cost is paid by the runner
and is not duplicated inside the event.

## 8. Historical Residue Unit

```lua
{
  kind = "rejected_form_residue",
  carrier = {
    protocol_version = "dissolve.rejected_form_residue.v0",
    source_packet_id = string,
    source_corpse_id = string,
    source_generation = integer,
    historical_qa_id = "qa-history:<sha256>",
    candidate_seal_id = string,
    qa_contract_id = string,
    verdict_id = string,
    rejected_check_refs = string[],
    failure_summary = {
      check_reason = string,
      termination = bounded_typed_record,
      cause = bounded_typed_record,
      finality = bounded_typed_record,
    },
    release_id = string,
    ancestor_evidence_truth_status = "runtime_confirmed",
    prior_applicability_truth_status = "inherited_proposal",
    release_truth_status = "runtime_confirmed",
  },
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "mixed",
  activation = "live",
  created_by = "☷",
  generation = child_generation,
  version = 1,
}
```

The residue contains no rejected artifact bytes and no repair instruction. It
tells later readers what failed, under which exact evidence, and that the old
form no longer binds this generation.

## 9. Loss And Garbage Accounting

| Quantity | Value | Meaning |
|---|---:|---|
| Body step cost | Existing one-tick charge | DISSOLVE consumed runtime |
| Released form mass | 1 | One current applicability constraint left the live set |
| Released relation mass | 0 | No relation was fabricated or removed |
| Irreversible identity loss | 0 | Exact historical identity survives in target + residue + event |
| Substrate calls | 0 | Release is body-native |

Claiming zero loss while omitting the residue or source refs is invalid. A
future compost policy may later aggregate old residues, but that is a separate
writer/reader law.

## 10. Route And Causal Precedence

At QA-recovery ingress:

```text
FLOW creates current work + live rejected-form unit
semantic OBSERVE for current work is deferred by the live release prerequisite
relation recognition remains at most causal_affordance
DISSOLVE contributes blocking_demand
-> ▽ -> ☷
```

After release:

```text
live prerequisite is absent
target version/activation changed
new historical residue exists
upper semantic/material coverage is stale for exact versions
-> ☷ -> ☴
```

The aftermath produces one merged semantic action, not competing semantic and
field-native actions:

```text
semantic class: current work + rejected-form residue
material class: dissolved target version + new residue version
planned sensor: semantic (it is compatible with both classes)
one exact unit/version scope -> one ☴ tick
```

Splitting this into `semantic_observe` and `field_native_observe` would create
two non-mergeable action modes for the same neighbor and make the route
ambiguous. The semantic sensor may cover the dissolved target materially
without presenting that target's carrier as semantic content.

This is dependency ordering, not a larger scalar weight and not a hardcoded
route. In an ordinary ingress without a rejected form, the semantic OBSERVE
witness is not deferred.

## 11. Upper Observation Amendment

`rejected_form_residue` is a typed semantic-history consequence:

| Unit state | Required sight |
|---|---|
| Live inherited rejected form before release | No semantic read as task material |
| Dissolved rejected form after release | Material coverage inside the combined semantic action; carrier excluded from prompt material |
| New rejected-form residue | Semantic + material coverage with current work |

The semantic call receives the current-work projection and bounded residue. It
does not receive the full recovery carrier or dissolved form carrier.

`network_current_work` is covered but not appended twice: its canonical
serialization is already the base `chaos.raw_prompt`. Only the bounded residue
presentation is appended to that base.

Coverage scope and prompt material are deliberately distinct here. The exact
dissolved unit/version remains in `read_units`, while the semantic presentation
policy emits only `network_current_work` and `rejected_form_residue`. This is
not hidden omission: the excluded carrier is named by the release/residue refs
and its exclusion is part of the action contract.

One compatible observation of exact versions discharges the obligation. No
`☴ -> ☴` self-loop is introduced.

## 12. Exactly-Once And Finality

| State | Pressure | Direct invocation |
|---|---|---|
| Live exact target, no release | One witness | May apply once |
| Dissolved target, one release | Absent | `already_released` / not ready |
| One target, two release events | Invariant failure | Never accepted |
| Release event, target still live | Invariant failure | Never accepted |
| Target dissolved, residue absent | Invariant failure | Never accepted |
| Dead Packet | No mutation | Corpse finality rejects |

Dissolved units cannot be reactivated by any operator.

## 13. Existing DISSOLVE Modes

This treatment does not reinterpret:

```text
raw relation release in vertical fixtures
active relation weakening/dissolution
stale/replaced raw phase derivation
future suppressed-form garbage collection
future semantic age
```

They share the operator but not this action schema or promotion evidence.

## 14. Matched Falsifiers

| ID | One changed fact | Required result |
|---|---|---|
| QD-T01 | No rejected-form unit | No ☷ witness |
| QD-T02 | Accepted-history control | No ☷ witness |
| QD-T03 | Exact live rejected form | One blocking ☷ witness |
| QD-T04 | Target version changes after commit | Action rejected as stale |
| QD-T05 | Foreign carrier/verdict ref | Invariant rejection |
| QD-T06 | Consumer ablated | Unit remains live; no ▽->☷ or release |
| QD-T07 | Ordinary treatment | ▽->☷ executes with matching refs |
| QD-T08 | Treatment aftermath | ☷->☴ executes over changed target/residue |
| QD-T09 | Repeat direct release | No second effect |
| QD-T10 | Residue omitted with zero loss | Reject/rollback atomically |
| QD-T11 | Observer off/on | Route, state, loss, budget and corpse identical |
| QD-T12 | Substrate absent | DISSOLVE still executes; later semantic OBSERVE may block honestly |
| QD-T13 | Generic blocked/grave form | Does not satisfy QA-specific witness |
| QD-T14 | Dead child | All release APIs reject without writes |
| QD-T15 | Same target tuple, replayed identity planning | Same residue/release ids; still one effect |

The positive pair must begin with a real contained QA rejection, corpse,
lineage assessment, carrier, NETWORK validation and FLOW materialization.

## 15. Acceptance

```text
one body-grown rejected form creates one qualified blocking need
the committed action pins exact unit/version/provenance
readiness re-derives rather than trusts
release is atomic, append-only and exactly once
historical rejection survives while applicability leaves the live set
released mass is recorded separately from identity loss
no substrate call or harness reason is used
the route emerges as ▽->☷->☴ under matched current physics
ablation removes the effect and changes the descendant trajectory
observer instrumentation remains massless
```
