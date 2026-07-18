# Blocked Lineage Yellowprint v0

Status:

```text
table
from docs/00_chaos/tree_authority_promotion_corpus_notes.md
     docs/00_chaos/fable_step4_cold_audit_2026-07-17.md
     docs/00_chaos/codex_response_to_fable_step4_audit_2026-07-17.md
transition step: 4.3B
scope: blocked corpse -> carrier -> grave -> descendant pressure
production code change authorized: no
```

## 1. Selected Model

| Question | Decision |
|---|---|
| Is blocked neutral? | No |
| Is every blocked life a warning? | No |
| Add a fourth top-level grave bucket? | No in v0 |
| Selected grave shape | Existing `bequest` with `bequest_kind=repair` |
| Why bequest? | Work remains unfinished and a bounded failed form must cross generations |
| Does repair mean repeat unchanged? | No; the failed form is carried specifically so it can be released/reformed |
| Missing failed-form identity | Classification error, never neutral fallback |
| First routing reader | Repair rigidity contribution toward ☷ DISSOLVE |
| Next body stage | DISSOLVE releases failed carrier, then upper observation may inspect the changed field |
| Claim before hands exist | Inheritance and routing are real; successful repair is not yet claimed |

Using a bequest subtype preserves current grave/session storage while separating
repair inheritance from ordinary progress bequests. A generic warning would say
"do not repeat" without describing what to change. A new top-level grave kind
would duplicate storage, compost, and attachment machinery before evidence
requires it.

## 2. Classification Table

| Death cause / evidence | Grave kind | Subtype | Required payload | Missing-payload behavior |
|---|---|---|---|---|
| `complete` | neutral | none | terminal/death provenance | Existing behavior |
| `blocked` + failed forms | bequest | repair | failed forms + validation/runtime refs | Classify repair bequest |
| `blocked` without failed forms | none | none | none | Loud `blocked_repair_carrier_missing` error |
| `budget_exhausted` with progress | bequest | progress | progress/remaining work | Existing behavior |
| `budget_exhausted` without progress | warning | loop/depletion | do_not_repeat/last operator | Existing behavior |
| `identity_loss` | warning | coherence | loss provenance | Existing behavior |
| `stalled`/`effect_failure` + do_not_repeat | warning | typed failure | failure/candidate refs | Existing behavior |
| `cancelled` without warning | neutral | none | cancellation evidence | Existing behavior |

No blocked path may reach the default neutral branch.

## 3. Failed-Form Carrier

The manifest residue receives a bounded projection named `failed_forms`.

### Root fields

| Field | Type | Rule |
|---|---|---|
| `kind` | string | `failed_validation_carrier` |
| `validation_event_ref` | event id | Required |
| `runtime_reconciliation_event_ref` | event id | Required |
| `completion_state` | string | Must equal `blocked` |
| `failed_count` | integer | Exact total failures before truncation |
| `items` | array | At most 8 entries |
| `truncated` | boolean | True when failed_count exceeds stored items |
| `truth_status` | string | `runtime_confirmed` for projection act |

### Per-form fields

| Field | Rule | Inherited raw? |
|---|---|---|
| `id` | Stable validation-event/index identity | Yes |
| `name` | UTF-8/string, bounded to 128 bytes | Yes |
| `spell_kind` | Bounded to 64 bytes | Yes |
| `intention_hash` | Existing spell hash | Yes |
| `referent` | Only sandbox-approved relative/path referent, max 256 bytes | Conditional |
| `referent_hash` | Existing content hash when available | Yes |
| `executed` | Boolean | Yes |
| `exit_code` | Number/string scalar | Yes |
| `failure_fingerprint` | Hash of kind, exit code and bounded failure material | Yes |
| `source_validation_event_ref` | Same source validation evidence | Yes |

### Forbidden inherited fields

```text
raw command_or_code
raw stdout
raw stderr
unbounded stack traces
absolute paths outside sandbox
substrate prose presented as failure evidence
```

The descendant can identify and re-run a referent-bearing spell without
inheriting arbitrary command output. Command-only spells with no safe referent
are marked `referent_status=opaque` and do not satisfy the v0 actionable repair
gate.

## 4. Writer-To-Reader Chain

| Stage | Writer | Record | Named reader | Activation |
|---|---|---|---|---|
| Validation | ☶ LOGIC | full spell results | △ MANIFEST projector | Manifesting blocked life |
| Manifest | △ assembler | bounded failed-form carrier | `packet.manifest_packet` / corpse residue | Terminal cause blocked |
| Finality | Packet | blocked corpse residue | `grave.classify` | Grave creation |
| Grave | `grave.classify` | repair bequest | `grave.attach` / session memory | Same-session selected inheritance |
| Attachment | `grave.attach` | `grave_repair_pressure` in unresolved chaos | repair-rigidity pressure reader | Descendant has unreleased repair bequest |
| Pressure | repair-rigidity reader | typed help toward ☷ | tree router candidate scoring | Current operator adjacent to ☷ |
| Readiness | ☷ DISSOLVE readiness | same source refs/reason | ☷ run | Candidate selected and affordable |
| Release | ☷ DISSOLVE | repair release/consumption evidence | ☴ upper observation and future ENCODE | DISSOLVE tick completes |
| Observation | ☴ OBSERVE | changed/released form observation | field/ENCODE path | Topology and pressure select next stage |

Every transition carries the original validation and reconciliation refs or a
trace event that transitively references them.

## 5. Repair Pressure Shape

The attachment projection is distinct from an ordinary progress bequest:

```lua
{
  kind = "grave_repair_pressure",
  source_packet_id = string,
  source_grave_ref = string,
  bequest_kind = "repair",
  failed_forms = bounded_carrier,
  validation_event_ref = string,
  runtime_reconciliation_event_ref = string,
  applicability_truth_status = "grave_pressure",
  status = "unreleased" | "released",
}
```

The death remains runtime-confirmed. Applicability to the descendant remains
`grave_pressure`; inheritance does not turn ancestral failure into current
runtime truth.

## 6. Reader And Activation Law

| Condition | Repair-rigidity contribution |
|---|---|
| No repair bequest attached | Absent |
| Repair bequest attached but carrier invalid/opaque | Absent plus typed unsupported reason |
| Unreleased valid repair carrier, ☷ adjacent | Help toward ☷ with source refs |
| Carrier already released in this Packet | Absent |
| Different session | Absent |
| Grave memory disabled | Absent |

The pressure reader must not select ☷ directly. It contributes pressure;
availability, readiness, affordability, topology, and the tree policy still own
selection.

## 7. DISSOLVE Contract At The Repair Boundary

| Input | Requirement |
|---|---|
| Reason | Derived from `grave_repair_pressure`, never harness option |
| Source refs | Repair pressure + ancestor validation/reconciliation provenance |
| Target | Failed carrier identity, not arbitrary field content |
| Mutation | Release/deactivate inherited failed form and expose bounded residue/potential |
| Loss | Conditional identity loss from removed rigid form |
| Trace | Runtime-confirmed relation/potential mutation and release event |
| Next sight | Mutation creates upper-observation debt; no hardcoded route is required |

One repair source may be released at most once per descendant Packet. Repeated
release without new evidence is an invariant defect, not a cheap loop.

## 8. Session And Generation Table

| Case | Expected inheritance |
|---|---|
| Fresh session, no explicit parent | None |
| Same session, matching selected ancestor | One repair bequest |
| Different session, same prompt | None |
| Grave disabled | None |
| Generation N+1 with parent corpse ref | Repair bequest and matching lineage id |
| Repeated attach of same grave | Idempotent or loud duplicate; never double pressure |

Prompt similarity alone cannot cross a session boundary.

## 9. Fresh Grave And Compost Boundary

Repair bequests use the existing fresh `bequests` bucket. If compost is
exercised, its key must include `bequest_kind=repair`; otherwise repair deaths
would merge with ordinary progress bequests.

For v0 promotion:

| Claim | Status |
|---|---|
| Fresh repair inheritance | Required |
| Repair subtype survives fresh session storage/load | Required |
| Repair compost preserves subtype/fingerprint counts | Required only if corpus crosses fresh-grave cap |
| Compost pattern changes routing | Not claimed until it gains a named reader |

The promotion record must keep unread compost patterns as an explicit boundary.

## 10. Pending-Gate Matrix

| Gate case | Grown requirement | Expected initial state |
|---|---|---|
| blocked_not_neutral | Real rejected tree ancestor | Red |
| carrier_has_failed_identity | Same ancestor, referent-bearing failed spell | Red |
| carrier_is_bounded | More than eight failures | Missing |
| forbidden_raw_fields_absent | Command/stdout/stderr source fixture | Missing |
| repair_bequest_attaches | Same-session descendant | Red |
| cross_session_isolation | Different session | Likely green library behavior |
| repair_pressure_is_conditional | Matched descendants with/without grave | Red/missing |
| dissolve_consumes_same_refs | Autonomous ▽→☷ life | Red/missing |
| repair_release_once | One descendant, repeated routing opportunity | Missing |
| observer_is_massless | Repair life observer on/off | Missing |
| grave_disabled_control | Orphan descendant | Missing |

The first pending gate remains outside `tests/run.lua` until the complete
classification/carrier/reader chain is green. A test that checks only
`grave_kind ~= neutral` is insufficient.

## 11. Rejected Alternatives

| Alternative | Rejection reason |
|---|---|
| `blocked -> warning` | Conflates repair with prohibition and lacks failed-form carrier semantics |
| `blocked -> neutral + residue` | Current laundering defect |
| New top-level `repair` bucket | Duplicates grave/session/compost machinery before evidence requires it |
| Raw spell result inheritance | Unbounded and may leak commands/output/secrets |
| LLM chooses grave kind | Makes lineage non-deterministic and unauditable |
| Immediate direct route command | Gives grave authority instead of pressure |
| Claim successful repair before hands | Body cannot change failed artifact yet |

## 12. Acceptance

```text
blocked can never classify neutral
repair bequest cannot exist without bounded failed-form identity
same-session descendant receives exactly one applicable repair carrier
different-session/orphan controls receive none
named pressure reader activates only under its declared condition
DISSOLVE consumes the same provenance without harness reason
release creates runtime evidence and cannot repeat freely
observer ablation is physically identical
no successful repair claim is made before pipeline A hands
```

## Amendment A1: Birth Materialization And Direct Form Release

Status:

```text
TABLE DECISION AFTER EXTERNAL AUDIT
date: 2026-07-17
sources:
  docs/00_chaos/promotion_tables_materialization_and_witness_audit_2026-07-17.md
  docs/00_chaos/fable_response_materialization_witness_2026-07-17.md
existing birth law:
  docs/01_table/yellowprints/grave_attach_at_birth_yellowprint.v0.md
supersedes section 4 ordering, section 5 mutable release status, and
  relation-only assumptions in sections 6-7 where incompatible
extends sections 10 and 12
production code change authorized: no
crystallization authorized: no
```

### A1.1 Confirmed discontinuity

The original writer-to-reader chain skipped embodiment:

```text
grave.attach wrote grave_repair_pressure into CHAOS
pressure proposed ☷
☷ expected a field target that did not exist
```

Current runtime order also contradicts the older grave-at-birth table:

```text
implemented: Packet birth -> FLOW tick -> grave.attach
required:    Packet birth -> grave.attach -> FLOW tick
```

The older table already says attachment occurs after Packet construction and
before the first tick. This amendment completes that law; it does not invent a
second inheritance phase.

### A1.2 Selected birth order

| Order | Stage | Owner | Write | Explicit prohibition |
|---:|---|---|---|---|
| 1 | Construct newborn and birth event | Packet constructor | Identity, generation, immutable birth fact | No inherited field units yet |
| 2 | Select and attach applicable graves | lineage/session birth phase | Karma buckets plus unresolved grave pressure | Must not write FIELD |
| 3 | Materialize ingress | ▽ FLOW, first operator tick | Direct ingress unit plus bounded inherited failed-form units | Must not classify graves or choose route |
| 4 | Derive entry pressure | Named pressure readers | Contributions over materialized Packet state | Must not mutate inherited forms |
| 5 | Select and execute first adjacent organ | Tree router plus registry | Audited route and destination tick | No harness-injected repair route |

Attachment is body-owned birth preparation, not an operator tick. FLOW remains
the sole operator that embodies newborn CHAOS as generation-local field
potential.

`birth_kind` and inheritance are independent axes:

```text
user birth + no graves
user birth + same-session repair inheritance
network_reentry + no repair inheritance
network_reentry + applicable repair inheritance
recovery birth + applicable repair inheritance
```

No inherited repair material changes `birth_kind` by itself.

### A1.3 Materialized failed-form unit

For every actionable item in the bounded failed-form carrier, FLOW creates one
direct field unit:

```lua
{
  kind = "inherited_failed_form",
  carrier = {
    failed_form_id = string,
    source_packet_id = string,
    source_grave_ref = string,
    validation_event_ref = string,
    runtime_reconciliation_event_ref = string,
    referent = bounded_sandbox_referent,
    referent_hash = string | nil,
    failure_fingerprint = string,
    failure_truth_status = "runtime_confirmed",
    applicability_truth_status = "grave_pressure",
  },
  source_refs = {
    source_grave_ref,
    validation_event_ref,
    runtime_reconciliation_event_ref,
  },
  event_truth_status = "runtime_confirmed",
  content_truth_status = "grave_pressure",
  activation = "live",
  created_by = "▽",
  generation = child_generation,
  version = 1,
}
```

The dual stamp is mandatory:

```text
the ancestor failed                         runtime-confirmed historical fact
FLOW materialized a bounded child unit      runtime-confirmed body event
the failed form applies to this child       grave-pressure hypothesis
```

Structure cannot promote the third statement into current runtime truth.

Opaque failed forms may remain attached as unresolved history, but FLOW does
not create an actionable `inherited_failed_form` unit for them in v0. A count
and typed unsupported reason remain visible.

### A1.4 Direct form target law

☷ v1 uses one tagged target contract:

```lua
target = {
  kind = "unit" | "relation",
  id = string,
}
```

| Target kind | Readiness domain | Legal mutation | Residue |
|---|---|---|---|
| `unit` | Live/selected form with runtime-visible rigidity/rejection/release reason | Set activation to `dissolved` | Bounded form residue with original source refs |
| `relation` | Active/weakened/locked relation with runtime-visible reason | Weaken or dissolve relation | Existing relation residue contract |

An inherited failed form is a direct unit target. No relation is required for
E02. A real relation may later be recognized by ☰, but repair release cannot be
held hostage by CONNECT scheduling.

A synthetic relation created only to satisfy the current relation-only organ
implementation is forbidden storage theater.

### A1.5 Immutable release accounting

The attachment pressure is historical input and is not mutated from
`unreleased` to `released`. A successful unit release appends a separate
runtime-confirmed record:

```lua
{
  kind = "grave_repair_release",
  source_pressure_ref = string,
  source_grave_ref = string,
  target = {kind = "unit", id = string, version = integer},
  reason = {kind = "rigid", subtype = "inherited_repair"},
  mutation_ref = string,
  residue_unit_ref = string | nil,
  loss_ref = string | nil,
  event_truth_status = "runtime_confirmed",
}
```

The repair-rigidity reader derives `already_released` by finding this record
for the same pressure/form pair. It does not rewrite the grave pressure.

```text
zero matching release records   eligible when all other conditions hold
one matching release record     pressure discharged
more than one                   invariant defect
```

### A1.6 Repaired writer-to-reader chain

| Stage | Writer | Record | Named reader | Activation |
|---|---|---|---|---|
| Validation | ☶ LOGIC | Full failed spell results | △ failed-form projector | Blocked manifestation |
| Manifest/finality | △ plus Packet lifecycle | Bounded failed-form corpse carrier | `grave.classify` | Terminal cause `blocked` |
| Grave | `grave.classify` | Repair bequest | Session/lineage birth selector | Same-session selected inheritance |
| Pre-FLOW attachment | `grave.attach` | Karma entry plus immutable `grave_repair_pressure` | ▽ FLOW materializer | Before first operator tick |
| Materialization | ▽ FLOW | `inherited_failed_form` field unit | Repair-rigidity reader and ☷ readiness | Actionable bounded carrier |
| Pressure | Repair-rigidity reader | Help toward ☷ with unit/version refs | Tree candidate scoring | Current operator adjacent to ☷ and no release record |
| Readiness | ☷ DISSOLVE | Tagged unit target plus same source refs | ☷ run | Candidate selected and affordable |
| Release | ☷ DISSOLVE | Dissolved unit, residue, immutable release record | Upper-observation debt and future ENCODE | Destination tick completes |
| Observation | ☴ OBSERVE | Versioned coverage of released/new potential | Field/ENCODE path | Tree pressure selects sight |

Every reader consumes the same failed-form identity or an immutable trace ref
that transitively names it.

### A1.7 Additional pending gates

| Gate case | Required evidence |
|---|---|
| `attach_precedes_flow` | FLOW sees selected repair pressure on its first and only ingress tick |
| `attach_does_not_write_field` | Field remains empty between Packet construction and FLOW |
| `flow_materializes_repair_unit` | Actionable carrier produces one generation-local unit per bounded item |
| `dual_truth_not_laundered` | Unit event is confirmed while applicability remains grave pressure |
| `user_birth_inheritance_independent` | Same-session user child inherits without becoming network re-entry |
| `direct_unit_release` | ▽→☷ executes without a synthetic relation or harness reason |
| `release_record_is_append_only` | Original pressure remains unchanged and one release record exists |
| `release_is_idempotent` | Second attempt is excluded; duplicate release is a loud invariant defect |
| `opaque_form_not_actionable` | Opaque carrier remains visible but creates no false dissolvable unit |

### A1.8 Amendment acceptance

This amendment may feed crystall only when the table observation confirms:

```text
grave selection precedes FLOW but never writes FIELD
FLOW embodies both direct ingress and applicable inherited failed forms
historical failure and present applicability retain separate truth statuses
E02 uses a direct form target
☷ has one tagged unit/relation law
release is append-only and exactly-once
same-session user birth is not mislabeled network_reentry
no claim of successful artifact repair is introduced
```
