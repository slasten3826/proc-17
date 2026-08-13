# NETWORK Rejected-Form Materialization Yellowprint v0

Status:

```text
layer: TABLE treatment
date: 2026-08-12
sources:
  docs/00_chaos/dissolve_network_rejected_generation_target_notes_2026-08-12.md
  docs/01_table/yellowprints/qa_rejected_lineage_recovery_yellowprint.v0.md
  docs/01_table/yellowprints/lineage_mechanics_yellowprint.v0.md
  docs/01_table/yellowprints/l1_continuing_flow_birth_mark_yellowprint.v0.md
amends:
  recovery carrier -> NETWORK -> packet ingress -> FLOW projection
  semantic OBSERVE input for structured recovery ingress
runtime implementation authorized: yes through exact crystall only
cross-table audit:
  docs/00_chaos/dissolve_network_table_cross_audit_2026-08-12.md
crystallization readiness: ready
crystallization authorized: yes; machinist instruction 2026-08-12
crystallized as:
  docs/02_crystall/blueprints/network_rejected_form_materialization.v0.md
router promotion authorized: no
```

## 0. Purpose

Turn one verified recovery carrier into distinct generation-local entities so
that DISSOLVE can release old-form applicability without erasing evidence or
leaving an aliased copy in semantic input.

```text
verified transport is not semantic material
current work is not historical QA evidence
historical QA evidence is not a current child verdict
rejected-form applicability is not the original task
```

## 1. Selected Decisions

```text
NM01 NETWORK verifies and projects; FLOW alone materializes field units.
NM02 On the QA-rejected treatment path, the full carrier payload is not copied
     into one semantically live field unit.
NM03 QA-recovery raw_prompt is an exact mirror of current-work projection only.
NM04 Full carrier/history remains lineage-owned transport evidence addressed by
     refs; persistent cold storage is a separate contract.
NM05 One exact rejected ancestor candidate creates one applicability unit.
NM06 Accepted/no-QA/infrastructure history creates no rejected-form unit.
NM07 Historical failure stays runtime-confirmed; child applicability stays inherited_proposal.
NM08 FLOW materialization cannot classify QA or choose a route.
NM09 Semantic OBSERVE reads explicit active units, not the full carrier fallback.
NM10 Grave records do not participate in this projection.
```

## 2. Four Entities At The Boundary

| Entity | Owner/lifetime | Enters field? | Semantic sensor may read? |
|---|---|---:|---:|
| Full verified recovery carrier | Lineage/NETWORK transport | No | No implicit read |
| Current work projection | Child generation | Yes, live | Yes |
| Historical QA evidence | Corpse/carrier/lineage history | No as a current verdict | Only through an explicit bounded residue projection |
| Rejected-form applicability | Child generation | Yes, live until released | Not as task content |

The complete carrier may remain in lineage reports and may later be persisted
by the cold-corpus contract. Its presence in host memory does not grant it
body-semantic authority, and this table does not claim persistence exists.

## 3. NETWORK Re-entry Projection

After `carrier.verify`, but before lineage commits continuation, NETWORK's pure
projector derives one immutable projection from this exact input tuple:

```text
verified current corpse
verified lineage.completion.v0 assessment
the exact completion_evaluated lineage event that contains that assessment
verified recovery carrier built from the same corpse and assessment
target generation coordinates
```

The projector never infers an assessment or recovery basis from the position
of a value inside `carrier.source_refs`.

```lua
{
  protocol_version = "network.reentry_projection.v1",
  projection_id = "network-projection:<sha256>",
  carrier_id = string,
  carrier_hash = string,
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
  rejected_form = inherited_rejected_form_projection_v0 | nil,
  historical_qa_id = "qa-history:<sha256>" | nil,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "mixed" | carrier_semantic_truth_status,
}
```

Identity covers every field except `projection_id`. It binds the carrier hash,
not only its human-readable id. `source_manifest_ref` is the verified corpse's
`manifest_trace_ref`; it is not guessed from QA source refs.

When `carrier.qa_history.v1` is present, `historical_qa_id` is the prefixed
digest of its exact canonical normalized value. When history is absent the id
is nil. This gives the historical envelope an address without creating a
second mutable QA record. A projection containing `rejected_form` has top-level
`content_truth_status=mixed`; otherwise it preserves the carrier semantic
truth status.

`completion_assessment_id`, `completion_event_ref` and
`terminal_recovery_basis` must agree with the exact ledger event. The
continuation event later binds this already-derived `projection_id`; it does
not manufacture or reinterpret those fields.

## 4. Current Work Projection

The first recovery projection is deliberately bounded:

```lua
{
  protocol_version = "network.current_work.v0",
  original_task = bounded_task_payload,
  remaining_work = bounded_remaining_work,
  prior_generation = integer,
  continuation_basis = string,
  process_contract_id = string,
  context = "software_task.v0",
  stage_id = string,
  source_refs = string[],
  content_truth_status = string,
}
```

`continuation_basis` is copied from the verified completion assessment. On the
selected QA-rejected path it is exactly `qa_rejected`.

It does not contain:

```text
the full prior manifest
candidate artifact bytes
raw stdout/stderr
provider/private QA state
grants, handles, commands or live parent identity
the full Packet trace
```

Those remain cold-addressable through corpse/carrier refs. A later named reader
may request a separately bounded projection; OBSERVE may not fetch them merely
because they exist in the carrier.

`network_ingress.prepare.prompt` is the canonical JSON encoding of
`current_work`, not of the full carrier payload. Packet birth verifies that
`chaos.raw_prompt` and the ingress `current_work` projection agree exactly.

## 5. Rejected-Form Projection

NETWORK creates this projection only from one exact rejected QA envelope:

```lua
{
  protocol_version = "network.inherited_rejected_form.v0",
  projection_id = "rejected-form:<sha256>",
  source_packet_id = string,
  source_corpse_id = string,
  source_corpse_hash = string,
  source_generation = integer,
  target_generation = integer,
  historical_qa_id = "qa-history:<sha256>",
  candidate_seal_id = string,
  candidate_seal_event_ref = string,
  artifact_alignment_id = string,
  qa_contract_id = string,
  verdict_id = string,
  verdict_ref = string,
  rejected_check_ids = string[],
  rejected_check_refs = string[],
  failure_summary = {
    check_reason = string,
    termination = bounded_typed_record,
    cause = bounded_typed_record,
    finality = bounded_typed_record,
  },
  terminal_manifest_ref = string,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  applicability_truth_status = "inherited_proposal",
}
```

The projection carries identity and bounded mechanical failure evidence, not
the rejected artifact bytes or raw output. One rejected candidate produces one
projection even if a future QA contract contains several rejected checks.
`terminal_manifest_ref` equals the enclosing re-entry projection's
`source_manifest_ref`; `historical_qa_id` equals its historical QA id.

The normalized top-level `source_refs` include at least:

```text
carrier id and hash
source corpse id and hash
completion assessment id and completion event ref
source manifest ref
historical QA id when present
all rejected-form mechanical source refs when present
```

## 6. Projection Derivation Matrix

| Carrier QA state | `rejected_form` | Result |
|---|---:|---|
| No QA history | absent | Ordinary recovery projection |
| Exact accepted check/verdict/projection | absent | Accepted history never becomes rigidity |
| Exact rejected check/verdict/projection | exactly one | Rejected applicability projection |
| QA execution failure | absent | Infrastructure evidence is not rejected form |
| Check without verdict | error/unsupported continuation boundary | No guessed rejection |
| Verdict without terminal projection | error | Manifest honesty mismatch |
| Carrier/history mismatch | NETWORK rejection | No Packet birth |
| Foreign/tampered corpse, seal or generation | NETWORK rejection | No Packet birth |

The rejected-form subprojector may be tested against accepted history even
when normal lineage policy would not continue an accepted software
generation. Such a control does not create a complete re-entry projection or
authorize continuation without a recoverable completion assessment.

## 7. Packet Ingress Extension

`packet.ingress.v0` gains an optional exact field:

```lua
network_projection = network_reentry_projection_v1 | nil
```

| Birth | Required state |
|---|---|
| User generation 1 | `network_projection=nil` |
| Recovery birth | Exact projection bound to `carrier_id`, lineage and target generation |
| Non-QA recovery | Projection present, `rejected_form=nil` |
| QA-rejected recovery | Projection present with exact rejected form |

`packet_birth` transports the already verified projection into the immutable
newborn ingress. It does not derive QA meaning and does not inspect the full
carrier.

The birth event records `network_projection_id`, not the full projection.

### 7.1 Boundary transaction order

Projection validity must be known before lineage commits continuation:

```text
1. append the exact completion_evaluated event
2. build and verify the recovery carrier from that assessment
3. purely derive and verify network.reentry_projection.v1 from the exact
   corpse + assessment event + carrier tuple
4. lineage continuation decision atomically binds carrier_id + projection_id
   + completion_assessment_id
5. NETWORK prepare revalidates that exact selected tuple against the ledger
6. generation allocation/birth names the same projection_id
7. FLOW materializes the projection once
```

`network_ingress.prepare` currently requires a lineage already marked
`continuing`. The implementation may retain that post-decision gate, but the
pure projection derivation must move before `mark_continued`; otherwise an
invalid projection could be discovered only after continuation was recorded.

The existing `continuation_decided` lineage event is the ledger fact. Its
payload gains `network_projection_id`; no second mutable projection registry is
introduced. Any current convenience cache is re-derived/validated against that
event before use.

## 8. FLOW Materialization

For the first `qa_rejected` structured treatment path, FLOW does not create the
legacy catch-all semantic `network_carrier` unit. It creates explicit units.
Other recovery causes retain their current transport path until a separate
matched semantic-continuity ablation authorizes migration; this DISSOLVE slice
must not silently change budget/stall recovery prompts.

### 8.1 Current work unit

```lua
{
  kind = "network_current_work",
  carrier = current_work_projection,
  source_refs = {projection_id, carrier_id, source_corpse_id},
  event_truth_status = "runtime_confirmed",
  content_truth_status = current_work.content_truth_status,
  activation = "live",
  created_by = "▽",
  generation = target_generation,
  version = 1,
}
```

### 8.2 Rejected applicability unit

When present:

```lua
{
  kind = "inherited_rejected_form",
  carrier = rejected_form_projection,
  source_refs = rejected_form_projection.source_refs,
  event_truth_status = "runtime_confirmed",
  content_truth_status = "inherited_proposal",
  activation = "live",
  created_by = "▽",
  generation = target_generation,
  version = 1,
}
```

Materialization is one FLOW tick. The payload names every unit and its exact
provenance class.

## 9. Semantic OBSERVE Law

Under the QA-rejected `network.reentry_projection.v1` path:

```text
semantic OBSERVE input is assembled from explicitly scoped active semantic units
chaos.raw_prompt may be used only after exact equality with current_work
the full serialized recovery carrier is never the fallback prompt
inherited_rejected_form is not semantic task material while live
dissolved units are excluded from active semantic scope
historical residue enters only through its own typed bounded unit
```

Exact prompt assembly after release is:

```text
base = canonical JSON(current_work) == chaos.raw_prompt
append = bounded rejected_form_residue presentation, once
do not append network_current_work again merely because it is in coverage
do not append inherited_rejected_form, live or dissolved
```

Thus object coverage may include the current-work and dissolved-form units
without duplicating either carrier in the model prompt.

Before rejected-form release, the current-work semantic need is deferred by an
exact prerequisite rather than defeated by a scalar weight:

```text
same network projection has one live inherited_rejected_form
-> release prerequisite is active
-> semantic current-work witness is not emitted yet
-> DISSOLVE may discharge the prerequisite
```

After release, OBSERVE receives current work plus the bounded historical
residue defined by the DISSOLVE table. This ordering prevents the ancestor form
from silently framing the child's first semantic read.

## 10. Truth Boundary

| Claim | Status |
|---|---|
| Ancestor QA run/check/verdict occurred | Preserved runtime-confirmed history |
| NETWORK verified and derived this projection | Runtime-confirmed act |
| FLOW materialized child-local units | Runtime-confirmed act |
| Old candidate should bind the child | `inherited_proposal` only |
| Child has already failed QA | Forbidden inference |
| Releasing old form makes new candidate correct | No claim |

## 11. Bounds And Forbidden Data

| Surface | Bound |
|---|---|
| Current work serialized bytes | Within existing carrier max and a smaller named projection limit |
| Rejected check ids/refs | QA contract bound; v0 currently one |
| Source refs | Sorted, unique, bounded |
| Rejected-form units | At most one per carrier/candidate |
| Full carrier field copies | Zero |

Forbidden in either FLOW unit:

```text
private QA correlation/receipt identity
provider handles or grants
raw commands
raw stdout/stderr bytes
absolute host paths
ancestor mutable tables or live Packet state
```

## 12. Writer-To-Reader Chain

| Record | Writer | Named reader | Moment |
|---|---|---|---|
| Recovery carrier | Carrier builder | NETWORK verifier | Before birth |
| Re-entry projection | NETWORK | packet birth verifier, FLOW | Accepted ingress |
| Projection-bound continuation | Lineage runner | NETWORK prepare, generation transaction | Before status becomes continuing |
| Current work unit | FLOW | semantic pressure/OBSERVE | After release prerequisite |
| Rejected-form unit | FLOW | DISSOLVE pressure/readiness | Immediately after FLOW |
| Completion assessment/event | completion + lineage ledger | NETWORK projector, continuation decision | Before continuation |
| Historical QA id | NETWORK pure projector | DISSOLVE residue assembler/audit | Release |
| Full carrier | Lineage/cold store | Audit/resume by explicit ref | Never implicit semantic read |

## 13. Matched Falsifiers

| ID | One changed fact | Required result |
|---|---|---|
| NM-T01 | Pure projection control with no QA history | Current-work unit only |
| NM-T02 | Pure projection control with accepted QA history | Current-work unit only; no rejected form |
| NM-T03 | Rejected QA history | Current work + one rejected-form unit |
| NM-T04 | Same carrier, tampered hash | NETWORK rejects before birth |
| NM-T05 | Same carrier, foreign target generation | NETWORK rejects before birth |
| NM-T06 | Rejected verdict, missing terminal projection | No Packet birth |
| NM-T07 | QA infrastructure failure | No rejected-form unit |
| NM-T08 | Structured recovery prompt | Encodes current work, not full carrier |
| NM-T09 | OBSERVE before release | Current-work semantic action deferred |
| NM-T10 | Full carrier inserted as live field unit | Contract rejects |
| NM-T11 | Ancestor evidence inspected in child | Current child QA check count remains zero |
| NM-T12 | Observer on/off | Projection and FLOW body state identical |
| NM-T13 | Projection derivation fails | No continuation event/status transition |
| NM-T14 | Continuation event names another projection | NETWORK rejects before birth |
| NM-T15 | Same carrier, foreign assessment/event/basis | Projection or NETWORK prepare rejects |

NM-T03 must be grown from a real rejected ancestor and an autonomous lineage
assessment. A hand-built assessment or projection cannot satisfy promotion.
Because the current runner has no fresh physical-root allocator, the trusted
test host may pre-provision only a distinct empty child root. It cannot author
any semantic/lineage record or route; production continuation suspends when
that fresh material environment is absent.
NM-T01/NM-T02 are matched projector controls; they do not authorize ordinary
non-rejected lineage recovery to migrate to the structured path.

## 14. Acceptance

```text
NETWORK validates before Packet birth
transport, current work, history and applicability are separate entities
the full carrier has no implicit semantic path
FLOW is the only field materializer
exact rejection creates exactly one direct unit
projection identity binds the exact completion event and historical QA digest
accepted/no-QA/infrastructure controls create none
truth statuses remain dual and are never laundered
semantic OBSERVE cannot bypass a live release prerequisite
grave has no role in QA materialization
```
