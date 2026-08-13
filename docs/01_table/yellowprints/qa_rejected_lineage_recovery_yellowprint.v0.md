# QA-Rejected Lineage Recovery Yellowprint v0

Status:

```text
layer: TABLE treatment
date: 2026-08-12
sources:
  docs/00_chaos/dissolve_network_rejected_generation_target_notes_2026-08-12.md
  docs/01_table/yellowprints/lineage_completion_continuation_separation_yellowprint.v0.md
  docs/01_table/yellowprints/completion_scope_candidate_seal_yellowprint.v0.md
  docs/01_table/yellowprints/qa_body_evidence_verdict_v1_yellowprint.v0.md
amends:
  lineage completion classification for software.create.v0
  blocked_lineage_yellowprint.v0 for the exact QA-rejected branch only
runtime implementation authorized: yes through exact crystall only
cross-table audit:
  docs/00_chaos/dissolve_network_table_cross_audit_2026-08-12.md
crystallization readiness: ready
crystallization authorized: yes; machinist instruction 2026-08-12
crystallized as:
  docs/02_crystall/blueprints/qa_rejected_lineage_recovery.v0.md
router promotion authorized: no
```

## 0. Purpose

Teach lineage completion to distinguish two facts that currently collapse into
the same Packet death cause:

```text
generic blocked terminal
exact rejected candidate generation
```

An exact rejected QA generation is finished as history but the software task
is unfinished. It may therefore produce a fresh recovery generation without
making every `blocked` death recoverable.

## 1. Selected Decisions

```text
LQ01 qa_rejected is a contract-specific completion result, not a new death cause.
LQ02 Only an exact verified rejected terminal projection activates this result.
LQ03 Generic blocked remains blocked and terminally non-recoverable.
LQ04 QA infrastructure failure is not candidate rejection.
LQ05 The corpse proves historical rejection; it does not prove child failure.
LQ06 Intrinsic recoverability is derived before wallet and recovery policy.
LQ07 Grave classification neither grants nor denies QA continuation.
LQ08 Recovery always means a fresh generation and fresh repository identity.
LQ09 Accepted and rejected evidence use the same exactness standard.
LQ10 No substrate diagnosis participates in this classification.
```

## 2. Exact Rejected-Generation Predicate

`runtime/completion.lua` may derive `terminal_recovery_basis=qa_rejected` only
when every row is true.

| Surface | Required fact |
|---|---|
| Lineage | Current lineage/corpse/Packet coordinates match |
| Contract | `completion_contract_id=software.create.v0` |
| Packet contract | Corpse `process_contract_id=software.create.v0`, context/stage agree with lineage |
| Corpse | Hash verifies under `corpse.v0` |
| Packet mode | `work_mode=build` |
| Terminal | `terminal_kind=manifest`, `death_cause=blocked` |
| Manifest | `mode=qa_terminal_delivery` |
| QA envelope | Exact normalized `corpse.qa_evidence.v1` |
| Check | Exact `qa.check.v0`, outcome `rejected` |
| Verdict | Exact `qa.candidate_verdict.v0`, verdict `rejected` |
| Projection | Exact `qa.terminal_projection.v1`, verdict `rejected` |
| Join | Seal, alignment, contract, check, verdict and request identities all agree |
| Retention | Manifest projection equals corpse QA projection |
| Evidence | Corpse completion refs contain terminal, manifest and QA source refs |

Any mismatch is an invariant error from a trusted body record. Mere absence is
not silently promoted to rejection.

## 3. Contract-Specific Completion Matrix

This matrix is evaluated before the generic terminal allowlist.

| `software.create.v0` evidence | Packet cause | Task state | Terminal recoverable | Basis | Continuation meaning |
|---|---|---|---:|---|---|
| Exact accepted check/verdict/projection | `complete` | Existing software-acceptance path | false | none | No rejected-form recovery |
| Exact rejected check/verdict/projection | `blocked` | `unfinished` | true | `qa_rejected` | Fresh candidate generation may be considered |
| Rejected check, no final verdict | any | not classified here | false | none | Verdict assembly was incomplete |
| Valid non-QA terminal after a verdict but no QA terminal projection | any | not classified here | false | none | No rejected-generation claim exists |
| Manifest claims QA terminal delivery but omits/contradicts projection | any | no assessment | n/a | n/a | Loud manifest/corpse invariant |
| `qa.execution_failure.v0` | `effect_failure` | Existing infrastructure-failure path | false | none | Never a rejected candidate |
| Generic validation rejection | `blocked` | `blocked` | false | none | Not QA candidate evidence |
| Malformed/conflicting QA evidence | any | no assessment | n/a | n/a | Loud trusted invariant |

"Existing software-acceptance path" remains owned by the completion-scope and
stage/root contracts. This treatment does not collapse `software_accepted` and
`root_delivery` merely to create an accepted control.

Crystall precision amendment: those contracts do not yet have an implemented
lineage-level reader. Until that reader exists, the exact accepted control is
reported as `unknown` with named missing requirement
`lineage_software_scope_reader`; it is not falsely accepted and never receives
the rejected recovery basis.

## 4. Rejected Assessment Projection

The existing `lineage_completion_assessment` schema is sufficient. No new
mutable lifecycle object is introduced.

```lua
{
  kind = "lineage_completion_assessment",
  protocol_version = "lineage.completion.v0",
  assessment_id = string,
  contract_id = "software.create.v0",
  task_state = "unfinished",
  terminal_recoverable = true,
  terminal_recovery_basis = "qa_rejected",
  progress = {
    rejected_generation = integer,
    candidate_seal_id = string,
    verdict_id = string,
  },
  remaining_work = {
    count = 1,
    kind = "fresh_candidate_generation",
    stage_id = string,
  },
  evidence_refs = string[],
  manifest_refs = string[],
  missing_requirements = {},
  event_truth_status = "runtime_confirmed",
  basis_truth_statuses = string[],
}
```

Required evidence refs include:

```text
corpse id and terminal trace ref
manifest trace ref
candidate seal id and seal event ref
QA contract id
request/check/verdict ids and event refs
all exact rejected terminal projection source refs
```

`remaining_work.count=1` means one fresh candidate-generation obligation. It
does not mean one file patch or one retry of the rejected repository.

The assessment is appended as the payload of one exact
`completion_evaluated` lineage event before any NETWORK projection is derived.
Future readers bind `assessment_id` to that event directly; they may not infer
the assessment from the ordering of a generic `source_refs` array.

## 5. Intrinsic Fact Versus Economy

For one exact corpse, all assessment fields and `assessment_id` remain equal
under these changes:

```text
lineage wallet available / exhausted
allow_recovery true / false
carrier byte allowance sufficient / insufficient
```

Those facts change only the subsequent continuation decision:

| Assessment | Policy/economy | Runner outcome |
|---|---|---|
| QA-rejected, recoverable | funded and enabled | Attempt one bounded recovery carrier |
| Same | wallet exhausted | Lineage exhausted; assessment stays unfinished/recoverable |
| Same | recovery disabled | Lineage suspended; assessment stays unfinished/recoverable |
| Same | carrier cannot be built | Lineage suspended with exact carrier boundary cause |

## 6. Fresh-Generation Law

An authorized continuation must preserve:

```text
same lineage id
same process contract and build stage id
generation N -> N+1
new Packet id
new repository id/root claim
parent corpse and carrier refs
rejected ancestor seal remains immutable historical evidence
```

Forbidden:

```text
reopen or patch the rejected repository
reuse the ancestor candidate seal as current
turn ancestor check/verdict into a child check/verdict
let affordability rewrite the intrinsic assessment
let grave kind authorize the child
```

## 7. Grave Boundary Amendment

The older blocked-lineage repair-bequest design does not own exact QA
rejection.

| Input | Grave may do | Grave must not do |
|---|---|---|
| QA-rejected corpse | Classify by ordinary death-only law and preserve allowed history | Read QA outcome to select repair/continuation |
| Generic blocked validation carrier | Remains archaeological/open under its own contract | Masquerade as QA rejection |

Changing or removing QA metadata from the same death-only grave input must not
change `grave_kind`. The lineage assessment still changes when exact QA
evidence is present because lineage, not grave, is its named reader.

## 8. Writer-To-Reader Chain

| Fact | Writer | Named reader | Effect |
|---|---|---|---|
| QA check | ☶ QA body writer | ☱ verdict assembler, △ |
| QA verdict | ☱ deterministic assembler | △, completion reader |
| Rejected terminal projection | △ manifest assembler | corpse capturer |
| Frozen QA envelope | corpse capturer | completion and carrier |
| QA-rejected assessment | completion evaluator | lineage runner, carrier builder and NETWORK projector |
| `completion_evaluated` event | lineage ledger | NETWORK projector and continuation decision |
| Wallet/policy | lineage economics/policy | lineage runner only |
| Continuation decision | lineage runner | NETWORK preparation and generation transaction |

Every record has a reader. No reader may substitute a neighboring record when
its exact input is absent.

## 9. Failure Classification

| Failure | Class | Result |
|---|---|---|
| Corpse hash mismatch | Trusted invariant | Loud; no assessment |
| QA coordinate contradiction | Trusted invariant | Loud; no assessment |
| No QA-terminal claim and no rejected projection | Honest incompletion | Not `qa_rejected` |
| QA-terminal claim with missing/contradictory projection | Trusted invariant | Loud; no assessment |
| QA execution unavailable/ambiguous | Infrastructure evidence | Existing effect-failure path |
| Rejected verdict under unknown completion contract | Epistemic boundary | `unknown`, no recovery carrier |
| Exact QA rejection but no wallet | Economics | Exhausted after unchanged assessment |
| Exact QA rejection but carrier too large | Material boundary | Suspended after unchanged assessment |

## 10. Matched Falsifiers

| ID | One changed fact | Required result |
|---|---|---|
| LQ-T01 | Exact rejected QA terminal | unfinished + recoverable + `qa_rejected` |
| LQ-T02 | Same corpse, empty wallet | Same assessment id/fields |
| LQ-T03 | Same corpse, recovery disabled | Same assessment id/fields |
| LQ-T04 | Generic blocked corpse | blocked + non-recoverable |
| LQ-T05 | Rejected check without verdict | Not `qa_rejected` |
| LQ-T06 | Rejected verdict without terminal projection | Not `qa_rejected` |
| LQ-T07 | QA infrastructure failure | Not `qa_rejected` |
| LQ-T08 | Accepted exact QA terminal | No rejected recovery basis |
| LQ-T09 | Foreign seal/check/verdict ref | Loud contradiction |
| LQ-T10 | QA metadata added to grave input | Grave classification unchanged |
| LQ-T11 | Funded exact rejection | One carrier/child authorization at most |
| LQ-T12 | Recovery child | Fresh repository identity, same stage identity |

Positive evidence must come from a grown QA-rejected life. A caller-authored
assessment cannot satisfy LQ-T01 or LQ-T11.

## 11. Acceptance

```text
exact QA rejection is distinguishable from generic blocked
the distinction is derived from verified corpse evidence
software task remains unfinished while rejected generation is historical
intrinsic recoverability is independent from wallet and policy
grave has no QA continuation authority
recovery requires a fresh Packet and repository generation
infrastructure failure never becomes candidate rejection
all exact refs survive into the lineage assessment and carrier boundary
the continuation projection binds the exact assessment ledger event
```
