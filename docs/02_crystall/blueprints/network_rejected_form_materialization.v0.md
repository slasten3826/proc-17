# NETWORK Rejected-Form Materialization Blueprint v0

Status:

```text
layer: crystall (◈)
date: 2026-08-12
source table:
  docs/01_table/yellowprints/network_rejected_form_materialization_yellowprint.v0.md
cross-table audit:
  docs/00_chaos/dissolve_network_table_cross_audit_2026-08-12.md
crystall cross-audit:
  docs/00_chaos/dissolve_network_crystall_cross_audit_2026-08-12.md
depends on:
  docs/02_crystall/blueprints/qa_rejected_lineage_recovery.v0.md
  docs/02_crystall/blueprints/lineage_mechanics.v0.md
  docs/02_crystall/blueprints/vertical_packet_life_gate.v0.md
crystall cross-read: satisfied
implementation authority: yes; exact QA-rejected v1 path only
scope: exact qa_rejected recovery ingress only
ordinary recovery prompt migration: forbidden
persistent cold-corpus claim: forbidden
router/full-tree promotion: forbidden
```

## 0. Crystallized Claim

NETWORK is not a semantic carrier dump. For one exact QA-rejected continuation
it validates lineage transport, then projects four distinct things:

```text
full recovery carrier          lineage-owned transport/history, not field data
current work                   child-local semantic material
historical QA evidence         immutable addressed history
inherited rejected form        child-local applicability proposal
```

FLOW materializes only the two child-local entities. This split is required so
that DISSOLVE can remove old-form applicability without leaving the same form
alive through `chaos.raw_prompt` or a catch-all `network_carrier` unit.

## 1. Exact Implementation Surface

Add:

```text
core/network_projection_schema.lua
runtime/network_projection.lua
tests/test_network_rejected_projection.lua
tests/test_network_rejected_materialization.lua
```

Modify:

```text
runtime/carrier.lua
runtime/lineage.lua
runtime/lineage_runner.lua
runtime/network_ingress.lua
runtime/packet_birth.lua
core/packet.lua
organs/flow.lua
runtime/qualified_pressure.lua
runtime/upper_coverage.lua
organs/observe.lua
runtime/operator_registry.lua
tests/test_network_ingress.lua
tests/test_carrier.lua
tests/test_lineage.lua
tests/test_lineage_runner.lua
tests/run.lua
```

`core/network_projection_schema.lua` owns only closed normalization,
verification, equality and identity projection. `core.packet` may depend on
this schema without creating a core -> runtime dependency.

`runtime/network_projection.lua` owns pure derivation from verified runtime
records. It owns no lineage status, Packet, field, trace, substrate call,
carrier mutation or persistence.

## 2. Pure Projection API

```lua
network_projection.derive(lineage, corpse, assessment_event, carrier, options)
  -> projection | nil, err

network_projection.verify(projection, context)
  -> true | nil, err

network_projection.qa_subprojection(qa_history, context)
  -> rejected_form | nil, status_or_err
```

`derive` requires:

```text
current verified lineage and corpse
assessment_event.kind = completion_evaluated
assessment_event.payload is exact lineage.completion.v0 assessment
assessment id/event coordinates agree with corpse/lineage
verified carrier built from same corpse/assessment
carrier target_generation = corpse.generation + 1
```

It performs no body or ledger writes.

## 3. QA History Identity

Normalize and verify `carrier.qa_history.v1`, then derive:

```lua
historical_qa_id = "qa-history:" .. digest.record(normalized_qa_history)
```

The id is absent when QA history is absent. It is not stored in a mutable QA
registry and it does not replace carrier/corpse verification.

Any projection containing a rejected form must bind this exact id. A changed
check/verdict/projection/source ref changes the id and every dependent
projection identity.

## 4. Re-Entry Projection Schema

`core.network_projection_schema` owns the exact closed schema and
`network_projection.verify` combines that schema check with runtime-coordinate
checks:

```lua
{
  protocol_version = "network.reentry_projection.v1",
  projection_id = "network-projection:<sha256>",
  carrier_id = string,
  carrier_hash = sha256,
  lineage_id = string,
  source_packet_id = string,
  source_corpse_id = string,
  source_generation = integer,
  target_generation = integer,
  process_contract_id = string,
  context = "software_task.v0",
  stage_id = string,
  completion_assessment_id = string,
  completion_event_ref = string,
  terminal_recovery_basis = string,
  source_manifest_ref = string,
  current_work = network_current_work_v0,
  rejected_form = network_inherited_rejected_form_v0 | nil,
  historical_qa_id = "qa-history:<sha256>" | nil,
  source_refs = sorted_unique_string_array,
  event_truth_status = "runtime_confirmed",
  content_truth_status = string,
}
```

`projection_id` is the prefixed digest of every other normalized field.

Required top-level refs include:

```text
carrier id/hash
corpse id/hash
completion assessment id/event ref
source manifest ref
historical QA id when present
all rejected-form source refs when present
```

## 5. Current Work Projection

Exact schema:

```lua
{
  protocol_version = "network.current_work.v0",
  original_task = bounded_string,
  remaining_work = bounded_plain_record,
  prior_generation = integer,
  continuation_basis = string,
  process_contract_id = string,
  context = "software_task.v0",
  stage_id = string,
  source_refs = sorted_unique_string_array,
  content_truth_status = string,
}
```

On this path:

```text
continuation_basis = assessment.terminal_recovery_basis = qa_rejected
prior_generation = corpse.generation
process/context/stage agree across lineage/corpse/carrier
```

Bounds:

```text
canonical serialized current_work <= options.max_current_work_bytes
max_current_work_bytes <= carrier max_bytes
remaining_work is plain, acyclic and bounded
```

Forbidden content:

```text
full prior manifest
artifact bytes or ancestor repository identity
raw stdout/stderr
provider/private receipt state
grants, handles, commands or host paths
full Packet trace
```

## 6. Rejected-Form Projection

Create exactly one projection only when:

```text
assessment basis = qa_rejected
carrier QA history is exact
check outcome = rejected
verdict = rejected
terminal projection verdict = rejected
all seal/alignment/contract/check/verdict joins agree
```

Closed schema:

```lua
{
  protocol_version = "network.inherited_rejected_form.v0",
  projection_id = "rejected-form:<sha256>",
  source_packet_id = string,
  source_corpse_id = string,
  source_corpse_hash = sha256,
  source_generation = integer,
  target_generation = integer,
  historical_qa_id = "qa-history:<sha256>",
  candidate_seal_id = string,
  candidate_seal_event_ref = string,
  artifact_alignment_id = string,
  qa_contract_id = string,
  verdict_id = string,
  verdict_ref = string,
  rejected_check_ids = sorted_unique_string_array,
  rejected_check_refs = sorted_unique_string_array,
  failure_summary = {
    check_reason = bounded_string,
    termination = normalized_bounded_record,
    cause = normalized_bounded_record,
    finality = normalized_bounded_record,
  },
  terminal_manifest_ref = string,
  source_refs = sorted_unique_string_array,
  event_truth_status = "runtime_confirmed",
  applicability_truth_status = "inherited_proposal",
}
```

The subprojection contains no artifact bytes, repair instruction, repository
authority, raw output or current-child verdict. Its `projection_id` covers
every other field.

## 7. Projection Matrix

| Input | Result |
|---|---|
| Exact rejected assessment + history | Complete projection with one rejected form |
| Exact accepted QA history passed to subprojector control | No rejected form |
| No QA history in ordinary recovery control | No rejected form |
| QA execution failure | No rejected form |
| Rejected assessment without exact history | Error; no continuation |
| Check without verdict | Error/unsupported boundary |
| Verdict without terminal projection | Loud contradiction |
| Foreign/tampered corpse/carrier/history | Loud rejection |

Accepted/no-QA controls exercise only the pure subprojector. They do not grant
lineage continuation to an intrinsically complete/nonrecoverable generation.

## 8. Continuation Transaction Amendment

Retain the compatibility API shape and extend its existing `input` options:

```lua
lineage.mark_continued(state, corpse, carrier, input)
  -> true | nil, err

input.network_projection = projection | nil
```

An exact QA-rejected carrier requires `input.network_projection`; ordinary
compatibility recovery may omit it until separately migrated.

It verifies the exact tuple and appends:

```lua
{
  kind = "continuation_decided",
  carrier_id = carrier.carrier_id,
  payload = {
    decision = "continue",
    target_generation = carrier.target_generation,
    network_projection_id = projection.projection_id,
    completion_assessment_id = projection.completion_assessment_id,
    completion_event_ref = projection.completion_event_ref,
  },
  source_refs = sorted_unique{
    corpse.corpse_id,
    carrier.carrier_id,
    projection.projection_id,
    projection.completion_assessment_id,
    projection.completion_event_ref,
  },
}
```

The event is the ledger truth. Lineage may keep only ids required by its
current in-memory state; it does not keep a mutable projection copy.

Required runner order:

```text
completion event
carrier build/verify
pure projection derive/verify
when the ancestor had a repository: acquire and verify one distinct fresh
  child material environment, or suspend without continuation
mark_continued with exact projection
NETWORK prepare revalidation
next begin_generation/birth
```

Projection failure occurs before `continuation_decided` and before status
becomes `continuing`.

## 9. NETWORK Prepare

Retain the compatibility API and extend options:

```lua
network_ingress.prepare(lineage, carrier, options)
  -> network_packet_ingress | nil, err

options.network_projection = projection | nil
```

It re-verifies:

```text
lineage status continuing
carrier identity/hash/bounds/current ancestry
continuation_decided names exact carrier/projection/assessment/event
projection verifies against carrier and target generation
QA-rejected projection contains exact rejected form
```

On the selected path it returns:

```lua
{
  kind = "network_packet_ingress",
  protocol_version = "network.ingress.v1",
  prompt = canonical_json(projection.current_work),
  network_projection = detached_exact_projection,
  packet_options = {
    lineage_id = projection.lineage_id,
    generation = projection.target_generation,
    parent_id = projection.source_packet_id,
    parent_corpse_id = projection.source_corpse_id,
    birth_kind = "recovery",
    carrier_id = projection.carrier_id,
    work_mode = "build",
    process_contract_id = projection.process_contract_id,
    context = projection.context,
    stage_id = projection.stage_id,
    ...existing bounded metadata...
  },
  source_refs = {carrier_id, source_corpse_id, projection_id},
  event_truth_status = "runtime_confirmed",
  content_truth_status = projection.content_truth_status,
}
```

The full carrier may remain in lineage reports, but is not copied into this
semantic ingress or returned as an implicit field payload.

NETWORK never derives, transports or copies a repository id. If the rejected
ancestor had a repository, the trusted repository-hands host/test boundary
must independently bind one pre-verified fresh public repository id into the
child's birth options. The projection, carrier and raw prompt contain no root
authority. Without that fresh material environment the main runner suspends
before `continuation_decided`, as specified by the lineage crystall.

Ordinary non-QA recovery remains on `network.ingress.v0` compatibility behavior
until a separate ablation authorizes migration.

## 10. Packet Birth And Ingress

The lineage runner transports the trusted value through:

```lua
runner_options.packet_life.network_projection = ingress.network_projection
```

`tension_runner` passes that value explicitly to
`packet_birth.create(..., {network_projection=...})`; it is not accepted from
ordinary caller-owned `packet_options`. Packet birth writes it into the
birth-owned exact ingress:

```lua
packet.ingress.v0.network_projection = projection | nil
```

Rules:

```text
user generation 1 -> nil
QA-rejected recovery -> exact projection required
projection lineage/generation/carrier/current_work agree with Packet options/prompt
repository id, when present, came from the separately verified fresh material
  environment and is absent from projection/carrier semantic transport
birth event records projection_id only
Packet stores a detached exact projection
```

`core.packet.init_ingress` performs closed schema validation through
`core.network_projection_schema` and checks Packet-local coordinates. It does
not require a runtime module and does not rederive QA meaning.

## 11. FLOW Materialization

For an ingress with `network.reentry_projection.v1` and
`terminal_recovery_basis=qa_rejected`, `organs/flow.run` takes a dedicated
branch before the legacy catch-all unit.

In one FLOW tick it writes exactly:

```text
one network_current_work unit
one inherited_rejected_form unit
zero network_carrier units
```

Current-work unit:

```lua
{
  kind = "network_current_work",
  carrier = projection.current_work,
  source_refs = {projection_id, carrier_id, source_corpse_id},
  event_truth_status = "runtime_confirmed",
  content_truth_status = current_work.content_truth_status,
  activation = "live",
  created_by = "▽",
  generation = target_generation,
  version = 1,
}
```

Rejected-form unit:

```lua
{
  kind = "inherited_rejected_form",
  carrier = projection.rejected_form,
  source_refs = projection.rejected_form.source_refs,
  event_truth_status = "runtime_confirmed",
  content_truth_status = "inherited_proposal",
  activation = "live",
  created_by = "▽",
  generation = target_generation,
  version = 1,
}
```

FLOW verifies projection equality and materializes. It does not classify QA,
choose a route, invoke a substrate or interpret the failure summary.

## 12. Pre-Release Pressure Gate

`qualified_pressure.upper_witnesses` must not emit a semantic current-work
witness while the same projection has one live exact
`inherited_rejected_form` prerequisite.

This is an exact dependency predicate:

```text
same network projection id
one live current-work unit
one live inherited-form unit
no matching release event
```

It is not a scalar penalty or hardcoded route. The DISSOLVE crystall owns the
positive release witness.

Absent/accepted/non-QA paths do not acquire this deferral.

## 13. Post-Release Observation Presentation

After DISSOLVE, one qualified semantic action may cover:

```text
network_current_work exact version
dissolved inherited_rejected_form exact version
rejected_form_residue exact version
```

Coverage and prompt presentation are distinct:

```text
base prompt = chaos.raw_prompt = canonical_json(current_work)
append exactly one bounded rejected_form_residue presentation
do not append network_current_work again
do not append inherited_rejected_form carrier in any activation
never fall back to serialized full carrier
```

`upper_coverage.classify` must classify the three unit kinds explicitly. An
unknown kind remains a diagnostic; broad `created_by` inference cannot silently
authorize semantic presentation.

## 14. Writer/Reader And Registry Amendments

Update operator descriptors:

```text
FLOW reads ingress.network_projection; writes explicit current/form units
DISSOLVE later reads/writes direct field units
OBSERVE reads current work + residue presentation policy
```

Every declared read/write receives a test. Registry metadata remains
descriptive instrumentation; enforcement stays in module APIs and Packet/body
writers.

## 15. Grown Test Contract

Required tests:

```text
NM01 no-QA pure subprojection -> no rejected form
NM02 accepted pure subprojection -> no rejected form
NM03 grown rejected ancestor -> one exact rejected form
NM04 tampered carrier hash -> reject before continuation
NM05 foreign target generation -> reject
NM06 rejected verdict without terminal projection -> loud
NM07 QA infrastructure failure -> no rejected form
NM08 QA-recovery prompt equals current_work, not full carrier
NM09 semantic current-work witness deferred before release
NM10 zero live network_carrier aliases on selected path
NM11 child current QA evidence remains empty before child QA
NM12 observer on/off -> projection/FLOW body identity equal
NM13 projection failure -> no continuation_decided event
NM14 mismatched projection in continuation event -> NETWORK reject
NM15 foreign assessment/event/basis -> projection or prepare reject
```

The positive case consumes the grown fixture from the lineage crystall. No
hand-built assessment, carrier, projection or field unit satisfies NM03.

## 16. Acceptance

```text
projection is pure and precedes continuation authority
continuation ledger binds carrier + projection + assessment event
full carrier has no semantic alias on QA-rejected path
FLOW alone materializes child field units
historical QA and child applicability remain separate truth classes
semantic work waits for exact release prerequisite
ordinary recovery behavior remains unchanged
```

Passing this crystall creates the target for ☷ but does not yet authorize its
release. The qualified DISSOLVE crystall is mandatory next.
