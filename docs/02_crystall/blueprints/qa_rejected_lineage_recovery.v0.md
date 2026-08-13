# QA-Rejected Lineage Recovery Blueprint v0

Status:

```text
layer: crystall (◈)
date: 2026-08-12
source table:
  docs/01_table/yellowprints/qa_rejected_lineage_recovery_yellowprint.v0.md
cross-table audit:
  docs/00_chaos/dissolve_network_table_cross_audit_2026-08-12.md
crystall cross-audit:
  docs/00_chaos/dissolve_network_crystall_cross_audit_2026-08-12.md
depends on:
  docs/02_crystall/blueprints/lineage_completion_continuation_separation.v0.md
  docs/02_crystall/blueprints/qa_body_evidence_verdict_v1.v0.md
  docs/02_crystall/blueprints/stage_transition_generation_recovery.v0.md
crystall cross-read: satisfied
implementation authority: yes; exact bounded slice only
scope: exact software.create.v0 QA-rejected terminal only
generic blocked recovery authority: forbidden
grave continuation authority: forbidden
router/full-tree promotion: forbidden
```

## 0. Crystallized Claim

For one exact `software.create.v0` build generation:

```text
rejected qa.check.v0
+ rejected qa.candidate_verdict.v0
+ matching qa.terminal_projection.v1
+ honest blocked terminal manifest/corpse
```

means:

```text
the rejected generation is historically finished
the software task is intrinsically unfinished
fresh-generation recovery is intrinsically possible
```

It does not mean:

```text
generic blocked is recoverable
the rejected repository may be reopened
the lineage can afford or is allowed to continue
the child has already failed QA
grave may grant recovery
```

## 1. Exact Implementation Surface

Modify:

```text
runtime/completion.lua
runtime/carrier.lua
runtime/lineage_runner.lua
tests/support/qa_hand.lua
tests/run.lua
```

Add:

```text
tests/test_qa_rejected_lineage_recovery.lua
```

`runtime/completion.lua` remains the sole intrinsic completion classifier.
No QA recovery status is cached in lineage, grave, carrier or session memory.

The full stage/root lineage reader and fresh physical repository allocator from
`stage_transition_generation_recovery.v0` are not implemented by this slice.
Their absence is handled explicitly in sections 5 and 8; neither fact may be
invented locally merely to make this treatment end-to-end.

## 2. Contract Dispatch Order

`completion.evaluate(lineage, corpse)` applies this order:

```text
1 verify lineage/corpse identity and corpse hash
2 classify unsafe/cancelled terminal
3 dispatch by lineage.completion_contract_id
4 for software.create.v0, inspect exact terminal QA claim
5 return exact accepted/rejected result or loud trusted contradiction
6 only when no contract-specific terminal applies, use that contract's ordinary
  incomplete/blocked rules
7 unknown completion contract -> unknown
```

The `qa_rejected` predicate runs before the generic terminal allowlist. It does
not add `blocked` to `RECOVERABLE_TERMINALS`.

## 3. Exact Rejected Predicate

Add one private pure reader:

```lua
exact_software_qa_terminal(lineage, corpse)
  -> "accepted", normalized_evidence
   | "rejected", normalized_evidence
   | nil, "absent"
   | nil, nil, loud_err
```

It verifies:

```text
lineage completion contract = software.create.v0
corpse process contract = software.create.v0
corpse context = software_task.v0
corpse stage agrees with lineage/current build stage
corpse work mode = build
corpse terminal kind = manifest
corpse manifest mode = qa_terminal_delivery
corpse.qa_evidence normalizes exactly through core.qa_evidence_schema
check/verdict/terminal projection all exist
check outcome = verdict = terminal projection verdict
request/check/verdict/seal/alignment/contract/profile/environment joins agree
manifest.qa_terminal_projection equals corpse.qa_evidence.terminal_projection
manifest_trace_ref and every QA source ref occur in completion_evidence_refs
```

Classification:

```text
no QA-terminal claim and no terminal projection -> absent
complete exact tuple -> accepted or rejected
QA-terminal claim with missing/foreign/conflicting tuple -> loud invariant
execution_failure without candidate verdict -> absent from this predicate
```

The reader accepts no caller-authored verdict, summary or `qa_rejected` flag.

## 4. Rejected Assessment

An exact rejected tuple additionally requires:

```text
corpse.death_cause = blocked
check.outcome = rejected
verdict.verdict = rejected
terminal_projection.verdict = rejected
```

It returns the existing assessment schema:

```lua
{
  kind = "lineage_completion_assessment",
  protocol_version = "lineage.completion.v0",
  assessment_id = "lineage-assessment:<sha256>",
  contract_id = "software.create.v0",
  task_state = "unfinished",
  terminal_recoverable = true,
  terminal_recovery_basis = "qa_rejected",
  progress = {
    rejected_generation = corpse.generation,
    candidate_seal_id = evidence.verdict.candidate_seal_id,
    verdict_id = evidence.verdict.verdict_id,
  },
  remaining_work = {
    count = 1,
    kind = "fresh_candidate_generation",
    stage_id = corpse.stage_id,
  },
  evidence_refs = sorted_unique_exact_refs,
  manifest_refs = {corpse.manifest_trace_ref},
  missing_requirements = {},
  event_truth_status = "runtime_confirmed",
  basis_truth_statuses = exact_basis_statuses,
}
```

Required refs are the sorted union of:

```text
corpse id/hash and terminal trace ref
manifest trace ref
candidate seal id/event ref and artifact alignment id
QA contract/request/check/verdict ids and event refs
terminal projection source refs
```

`assessment_id` covers every field except itself. Wallet, recovery policy,
carrier size and future repository allocation are absent from the identity.

## 5. Accepted And Non-Rejected Boundaries

Exact accepted QA belongs to the existing completion-scope/stage/root contract.
The current in-memory runner does not yet implement that lineage reader, so
this crystall preserves accepted evidence but returns an honest pending
assessment:

```text
task_state = unknown
terminal_recoverable = false
terminal_recovery_basis = nil
missing_requirements = {"lineage_software_scope_reader"}
```

It does not define a second acceptance path and does not call an absent reader
"existing runtime behavior".

```text
exact accepted + complete -> unknown pending named lineage software reader
generic blocked -> blocked, terminal_recoverable=false
validation blocked without QA verdict -> blocked
QA execution failure -> existing effect-failure/blocked policy, never rejection
rejected evidence under unknown contract -> unknown, no carrier
```

If an exact accepted tuple conflicts with terminal cause or manifest outcome,
the result is loud rather than coerced into either completion or recovery.

## 6. Completion Ledger Binding

The runner appends the assessment through the existing event:

```lua
{
  kind = "completion_evaluated",
  generation = corpse.generation,
  packet_id = corpse.packet_id,
  corpse_id = corpse.corpse_id,
  payload = assessment,
  source_refs = assessment.evidence_refs,
}
```

The exact returned event is retained in the local continuation transaction and
passed to the NETWORK projector. No reader infers it from ledger position or
from the position of `assessment_id` in `carrier.source_refs`.

The lineage state does not gain a mutable `current_assessment` cache.

## 7. Carrier Boundary

`carrier.build_recovery` retains its current intrinsic preconditions:

```text
task_state=unfinished
terminal_recoverable=true
non-empty terminal_recovery_basis
current verified corpse/lineage ancestry
```

For the rejected case it additionally verifies:

```text
assessment.contract_id = software.create.v0
assessment.terminal_recovery_basis = qa_rejected
assessment evidence names the exact frozen QA envelope
carrier.qa_history.v1 equals the corpse QA envelope
carrier prior manifest equals the corpse manifest
```

The carrier continues to include `assessment_id` in normalized source refs.
It does not acquire a writable recovery-status field and does not itself
authorize continuation.

The carrier must not contain:

```text
ancestor repository authority or root handle
reopen/patch instruction
private QA receipt/provider identity
child verdict
grave-selected recovery policy
```

## 8. Runner Decision Order

After `completion_evaluated`:

```text
complete/unsafe/unknown/nonrecoverable branches first
then cumulative lineage budget
then allow_recovery policy
then build and verify one bounded carrier
then invoke the pure NETWORK projection stage
only a valid projection may feed continuation_decided
```

Wallet and policy may change the selected lineage outcome but never the
assessment or its id.

Any committed fresh continuation preserves:

```text
same lineage/process contract/context/stage
generation N -> N+1
new Packet id
new repository id and physical root claim
parent corpse/carrier/projection refs
```

It never reuses the rejected repository or candidate seal as current state.

### 8.1 Fresh repository implementation boundary

The current main runner has no `runtime.repository_generation` allocator. For
an ancestor with a repository identity:

```text
no separately provisioned verified child root
-> suspend before continuation_decided
-> cause = fresh_repository_allocation_required
```

For this DISSOLVE treatment's grown evidence, the trusted test/host boundary
may pre-provision a distinct empty repository fixture using the existing
repository capability/provider machinery. The test must prove:

```text
child repository id differs from ancestor repository id
child root authority/fingerprint differs from ancestor root
no ancestor grant/handle enters child Packet ingress
```

The pre-provisioned fixture supplies material environment only. It cannot
author the completion assessment, carrier, NETWORK projection, DISSOLVE need
or route. Production automatic allocation remains delegated to the existing
stage-transition blueprint.

## 9. Grave Amendment

`grave.classify` and `grave_input` remain death-only. They do not receive QA
metadata for policy selection.

Matched assertion:

```text
same death-only grave input, QA envelope present/absent elsewhere
-> identical grave kind and grave policy output
```

QA recovery changes because the completion reader sees exact corpse evidence,
not because grave changes class.

## 10. Failure Classes

| Failure | Class | Result |
|---|---|---|
| Corpse hash mismatch | trusted invariant | loud, no assessment |
| Claimed QA terminal with partial/conflicting tuple | trusted invariant | loud, no assessment |
| No QA terminal claim | honest absence | ordinary contract classification |
| QA provider/cleanup failure | infrastructure | not `qa_rejected` |
| Empty lineage wallet | economics | same assessment, exhausted lineage |
| Recovery disabled | policy | same assessment, suspended lineage |
| Carrier too large | material boundary | same assessment, suspended lineage |
| Fresh repository unavailable | world/capability boundary | suspend `fresh_repository_allocation_required`; no reuse |

Lua/schema errors remain loud harness failures and never become Packet death.

## 11. Grown Test Contract

`tests/test_qa_rejected_lineage_recovery.lua` must grow one real rejected
candidate through the contained QA hand, verdict tick, manifest, death and
corpse capture. Synthetic corpses/assessments do not satisfy positive gates.

Required cases:

```text
LQ01 exact grown rejection -> unfinished/recoverable/qa_rejected
LQ02 same corpse, empty wallet -> identical assessment id and fields
LQ03 same corpse, recovery disabled -> identical assessment id and fields
LQ04 same terminal cause without QA tuple -> blocked/nonrecoverable
LQ05 rejected check without verdict -> not qa_rejected
LQ06 QA-terminal claim missing projection -> loud
LQ07 execution failure -> not qa_rejected
LQ08 exact accepted control -> unknown pending lineage reader; no rejected recovery basis
LQ09 foreign seal/check/verdict join -> loud
LQ10 QA metadata does not change grave classification
LQ11 funded exact rejection -> at most one carrier/continuation candidate
LQ12 pre-provisioned child allocation -> same stage, increasing generation,
     distinct repository id/root authority/fingerprint
```

The grown fixture is retained for the NETWORK and DISSOLVE suites; those suites
must not replace it with hand-built projection records.

## 12. Acceptance

```text
software.create.v0 rejection is read from exact corpse evidence
generic blocked remains nonrecoverable
assessment identity is economy/policy invariant
completion event is an explicit input to the next boundary
grave cannot grant QA continuation
fresh continuation cannot reuse ancestor repository authority
no substrate diagnosis participates
```

Passing this crystall alone does not birth a descendant. NETWORK projection is
the next mandatory boundary.
