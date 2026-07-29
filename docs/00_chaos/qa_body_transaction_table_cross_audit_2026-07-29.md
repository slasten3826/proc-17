# QA Body Transaction Post-QN20 TABLE Cross-Audit

Status:

```text
layer: chaos (cross-table audit evidence + document decision)
date: 2026-07-29
scope: second QA hand body transaction after promoted QN20 physics
audit result: accepted after in-place precision amendments
TABLE gate: satisfied
CRYSTALL authorized: exact body-transaction surface only
runtime implementation authorized: no
router/pressure promotion authorized: no
lineage software acceptance authorized: no
independent implementation audit completed: no; no implementation exists
```

## 0. Audited Corpus

Primary CHAOS source:

```text
docs/00_chaos/qa_body_transaction_after_qn20_notes_2026-07-29.md
```

New TABLE owners:

```text
docs/01_table/yellowprints/qa_body_execution_after_qn20_yellowprint.v0.md
docs/01_table/yellowprints/qa_body_evidence_verdict_v1_yellowprint.v0.md
docs/01_table/yellowprints/qa_body_transaction_reconciliation_yellowprint.v0.md
```

Earlier TABLE owners checked and marked partially superseded:

```text
docs/01_table/yellowprints/qa_execution_capability_yellowprint.v0.md
docs/01_table/yellowprints/qa_check_verdict_yellowprint.v0.md
```

Runtime and evidence claims checked at their joins:

```text
core/packet.lua
core/qa_schema.lua
runtime/budget.lua
runtime/qa_capability.lua
runtime/qa_environment.lua
runtime/qa_process.lua
runtime/qa_provider_witness.lua
runtime/qa_request.lua
runtime/repository_capability.lua
runtime/tension_runner.lua
tests/red_qa_hand.lua
tests/test_qa_contract.lua
tests/test_qa_execution.lua
tests/test_qa_check_verdict.lua
tests/support/qa_control_catalog.lua
```

The worktree also contains active QN20 and unrelated CLI work. This audit did
not revert, reinterpret or authorize those changes.

## 1. Audit Question

```text
Can CRYSTALL now specify the first Packet-owned execution of one exact sealed
candidate by reusing the promoted QN20 physical transaction, without granting
provider-witness output body authority, inventing source finality, losing RUN
v1 evidence or charging one execution twice?
```

Answer after the precision amendments recorded below:

```text
yes
```

This answer authorizes transcription into CRYSTALL. It does not authorize
runtime code or promotion.

## 2. Runtime-Confirmed Baseline

Observed base:

```text
HEAD: 1f7c971
date exercised: 2026-07-29
QA expected-red matrix: 44 green / 40 red / 0 skip
contract/profile: 14 green / 1 red
body execution: 5 green / 15 red
body verdict: 0 green / 24 red
native QN surface: 20 green / 0 red
fixture guard: 5 green / 0 red
```

The red matrix is healthy. The remaining red controls correspond exactly to
withheld body execution, verdict and terminal-retention authority:

```text
QC15                                      1
QE01, QE04, QE08-QE20                    15
QV01-QV24                                24
                                          --
                                          40
```

Current runtime facts used by the tables:

```text
repository.qa_source_binding.v1 already separates provider_witness from
body_execution;

provider_witness rejects qa_request_id and independently verifies its source
transaction digest;

body_execution requires qa_request_id but still lacks independent transaction
digest verification;

qa_environment.resolve already returns an opaque lease bound to one measured
record revision;

qa_capability mint/begin/commit remain deliberately closed stubs;

runtime.qa_execution, runtime.qa_evidence, runtime.qa_verdict and
packet.append_qa_event do not yet exist;

RUN v1 has one exact eight-field finality schema;

the runner already owns the only Packet budget mutation surface.
```

## 3. Closed Causal Chain

The accepted future body chain is:

```text
exact current seal + alignment + birth QA contract + measured environment
  -> pure qa.check_request.v0 derivation
  -> dedicated ☶ request event
  -> private active QA grant with opaque environment lease
  -> begin revalidates environment and makes transaction sticky
  -> independently verified body_execution source binding
  -> exact source lease OR typed not_acquired reservation denial
  -> shared QN20 physical engine when a source exists
  -> full private RUN v1 candidate report/error
  -> private execution receipt
  -> strict ☶ body join
  -> qa.check.v0 OR qa.execution_failure.v0
  -> deterministic ☱ verdict for a check
  -> terminal QA projection
  -> corpse QA envelope outside trace_tail
```

Provider-witness output is absent from this authority chain. It remains a
harness-only observation of the same lower physical engine.

## 4. Finding A: Old Body Physics Duplicated Promoted QN20

Class:

```text
architecture duplication / high before crystallization
```

The 2026-07-23 execution table described a future body-specific implementation
of source inventory, process execution and cleanup. QN16-QN20 have since
promoted those mechanics through the provider-witness adapter. Implementing
the old table literally would create two physical engines with independently
drifting finality rules.

Disposition applied:

```text
one private qa_candidate_transaction engine owns physical mechanics;
provider-witness and body-execution are separate authority adapters;
each adapter owns a distinct final protocol;
the shared engine has no Packet writer or reader;
QN16-QN20 behavior and residue vector are extraction invariants.
```

The old execution table is marked partially superseded instead of deleted.

## 5. Finding B: Provider Witness Must Never Become Body Evidence

Class:

```text
authority laundering risk / high
```

The promoted witness has stronger RUN v1 evidence than the old conceptual body
report. That does not give it body authority. Accepting it directly would let a
trusted test harness bypass request, grant, receipt and body actor gates.

Disposition applied:

```text
qa.provider_witness_report.v1 / error.v1 -> QN harness readers only
qa.provider_candidate_report.v1 / error.v1 -> private receipt commit only
Packet writer input -> private registry + execution_receipt_id only
caller/provider report table -> always denied
```

Shared mechanics do not imply shared applicability.

## 5A. Finding B2: Repository Reader Could Be Substituted

Class:

```text
private provider binding gap / medium before crystallization
```

The first treatment allowed the shared engine to receive a repository
inventory provider separately from its source lease. A caller could therefore
pair the correct sealed handle with a different trusted-looking reader.

The repository registry already stores the exact provider beside the retained
QA source handle. Precision amendment applied:

```text
with_qa_source privately yields handle + exact root-bound provider together;
the engine has no independent repository-provider argument;
both pre/post inventories use that exact provider;
neither provider nor handle may escape the callback;
existing provider-witness consumers may ignore the added callback argument,
and QN16-QN20 output/residue must remain exact.
```

No fourth provider registry or public projection is introduced.

## 6. Finding C: Environment Lease Could Become Stale

Class:

```text
missing reader at authority transition / medium before implementation
```

The first TABLE draft required an available measured environment at mint but
did not name who rechecks that fact at begin. The existing environment registry
can quarantine the exact record after an opaque lease was issued. A grant that
trusted only `environment_id` could therefore start under stale authority.

Precision amendment applied:

```text
mint privately retains qa.environment_lease.v0;
begin read-only revalidates registry, record, revision, identity and available
state before changing the grant;
failure leaves the grant active and creates no source/process/effect cost;
the shared engine revalidates through a private environment callback
immediately before native entry;
that callback yields the exact provider and measured projection together, so
the body adapter cannot substitute a provider under an old environment id;
drift after sticky begin is typed infrastructure failure and any acquired
source must still reach terminal disposition.
```

The environment lease is a prerequisite capability, not a second execution
ledger. Transaction progress remains owned by the QA registry.

## 7. Finding D: A Denied Source Lease Has No Disposition

Class:

```text
causal-schema contradiction / high before crystallization
```

The selected safe order is:

```text
sticky QA begin -> repository source reservation
```

Therefore reservation can fail after replay authority is consumed but before a
source lease exists. The first TABLE draft allowed only `consumed` or
`quarantined`. Either value would fabricate the finality of an authority that
was never acquired.

Precision amendment applied:

```text
source_acquisition = not_acquired | acquired
source_disposition = not_acquired | consumed | quarantined
```

The only legal `not_acquired` tuple is:

```text
candidate_start_state = not_started
source_acquisition = not_acquired
source_disposition = not_acquired
source_stable = nil
cleanup_state = complete
launcher_reaped = complete
result_eof = complete
measured_cost = nil
transaction_disposition = consumed_failed
provider entry count unchanged
```

Here cleanup/reap/EOF are complete because the trusted registries proved that
no owned source or process was created. They do not claim a candidate run.
Every acquired source still requires `consumed|quarantined` before a private
result can be committed.

Only a closed expected denial after source-binding schema, digest and private
coordinates validate may become `not_acquired`. Malformed bindings, arbitrary
transaction ids, foreign coordinates and impossible registry state remain
loud trusted-physics contradictions with no body failure record.

This fact propagates through provider error, receipt and
`qa.execution_failure.v0` without vocabulary conversion.

## 8. Finding E: Cross-Registry Atomicity Was Fictional

Class:

```text
transaction ownership overclaim / high before implementation
```

The old execution table described grant mint and repository source reservation
as one atomic act. They are independent private registries and no current Lua
primitive can make both mutations atomic.

Disposition applied:

```text
mint: private grant only, no source or process
begin: sticky replay authority in QA registry
reserve: separate repository operation with request-causal digest
failure: closed partial-state row, never rollback to active
receipt/body split: loud and never repaired by rerun
```

The implementation must expose each real boundary and test its interrupted
state. It may not hide two calls under an `atomic_*` name.

## 9. Finding F: Old Body Evidence Was Weaker Than RUN V1

Class:

```text
evidence regression / high before crystallization
```

The old check schema used `cleanup="complete"`. RUN v1 now proves eight exact
facts:

```text
source_staging_complete
candidate_started
candidate_terminal_observed
process_tree_reaped
stdout_eof_observed
stderr_eof_observed
scratch_observation_complete
namespace_cleanup_complete
```

Disposition applied:

```text
qa.check.v0 preserves termination, first cause, all eight finality fields,
source pre/post identity, bounded stream/resource/scratch measurements and
measured cost;

qa.execution_failure.v0 preserves the exact tri-state infrastructure facts;

raw bytes, paths, descriptors, handles, private correlation ids and provider
authority never enter Packet evidence.
```

No compatibility alias exists because the body schemas have never been
implemented or persisted.

## 10. Identity And Split-Brain Audit

The three tables use one chain:

```text
qa_contract_id
  -> request_id + request event ref
  -> grant_id
  -> request-causal physical transaction id
  -> source lease/disposition or exact not_acquired denial
  -> normalized private result id
  -> execution_receipt_id
  -> qa_check_id OR qa_execution_failure_id
  -> qa_verdict_id
  -> terminal projection
  -> corpse hash
```

Native prefixes remain:

```text
qa-provider-transaction:<sha256>
qa-provider-witness:<sha256>
```

They are ABI correlation prefixes, not authority labels. The body seed includes
the exact `qa_request_id`; the repository registry must independently recompute
it. The physical ids do not enter Packet check, verdict or terminal evidence.

Every split has a consequence:

| Split | Consequence |
|---|---|
| request without grant | pending/denied, zero provider effect |
| active grant without begin | pending, one legal begin |
| running grant without source | exact reserve denial or loud missing outcome |
| acquired source without terminal disposition | quarantine attempt + loud |
| private result without receipt | quarantine + loud |
| receipt without body outcome | loud, no rerun |
| body outcome without receipt | loud forgery/split, no rerun |
| check without verdict | valid ◈ phase |
| failure without death | runner consumes once |
| verdict without projection | valid ▲ boundary phase |

No split is repaired by rerunning candidate code.

## 11. Economics Audit

One external execution produces one measured projection:

```text
tool_calls <- qa_cost.tool_calls
test_runs  <- qa_cost.qa_executions
time_ms    <- qa_cost.wall_time_ms
```

Ownership is exact:

| Layer | Records cost | Debits Packet budget |
|---|---:|---:|
| native/provider | yes | no |
| private result/receipt | yes | no |
| body event/effect payload | yes | no |
| tension runner | yes | yes, once |
| verdict/manifest/corpse | historical only | no |

`not_acquired` has `measured_cost=nil` and therefore zero external-effect
charge. Its ordinary ☶ tick still costs one step. QA mechanics create no
identity loss.

## 12. Work-Layer And Truth Audit

The tables agree on the initial body projection:

```text
sealed, no outcome        -> build ⊞
request/check, no verdict -> build ◈
accepted verdict          -> build ▲ acceptance boundary
rejected verdict          -> build ▲ recovery boundary
execution failure         -> build ⊞, then effect_failure death
```

`▲` means a complete typed generation boundary, not universal correctness.
Packet and corpse may report the candidate verdict. Only a future verified
lineage-ledger reader may report `software_accepted`.

Provider wording, substrate output and semantic diagnosis have zero check,
verdict or applicability authority.

## 13. Red-Matrix And Milestone Audit

The milestone arithmetic covers every current red control exactly once:

```text
M0 documentary/red repair       44 green / 40 red
M1 shared-engine extraction     44 green / 40 red
M2 body execution + join       +28 -> 72 green / 12 red
M3 verdict + shadow readers    +10 -> 82 green /  2 red
M4 corpse + descendant history  +2 -> 84 green /  0 red
```

Set equality:

```text
M2 = QE01, QE04, QE08-QE20
   + QV01-QV08, QV13-QV15, QV21-QV22

M3 = QC15
   + QV09-QV12, QV16-QV18, QV23-QV24

M4 = QV19-QV20
```

Counts:

```text
28 + 10 + 2 = 40
no duplicate control
no omitted control
no authorized skip
```

Before M1 implementation, the placeholder `transaction_surface` and
`outcome_surface` probes must be replaced with exact grown falsifiers while the
matrix remains 44/40. Module presence is not evidence.

## 14. Reader Audit

Every admitted record has a named first reader:

| Record | Writer | First reader |
|---|---|---|
| request event | ☶ body writer | QA grant mint |
| environment lease | environment registry | begin/native callback |
| grant/transaction | QA registry | body adapter |
| source lease or denial | repository registry | shared engine/body adapter |
| private result | selected adapter | receipt commit |
| receipt/result | QA registry | strict ☶ join |
| check | ☶ | ☱ verdict assembler |
| execution failure | ☶ | runner effect-failure path |
| verdict | ☱ | completion/work-layer/△ |
| terminal projection | △ | corpse/lineage |
| corpse envelope | corpse capturer | historical lineage/corpus reader |

Provider-witness records still have only QN harness readers. This audit does
not create a body reader for them.

## 15. Crystall Readiness

| TABLE owner | Verdict |
|---|---|
| `qa_body_execution_after_qn20_yellowprint.v0.md` | ready after Findings C/D amendments |
| `qa_body_evidence_verdict_v1_yellowprint.v0.md` | ready after Findings D/F amendments |
| `qa_body_transaction_reconciliation_yellowprint.v0.md` | ready after partial-state reconciliation |
| old `qa_execution_capability_yellowprint.v0.md` | archaeology plus still-live safety laws; body details superseded |
| old `qa_check_verdict_yellowprint.v0.md` | archaeology plus still-live policy laws; payload details superseded |

CRYSTALL may now define exact implementation slices for:

```text
red-probe repair
shared physical-engine extraction with zero QN delta
environment-lease revalidation
private grant/begin/source/result/receipt transaction
dedicated Packet QA event gate
strict check/failure join
deterministic verdict and shadow completion/work-layer readers
terminal projection and corpse retention
```

Each slice must name its allowed red-to-green delta. No slice may combine a
test rewrite and unrelated authority promotion.

## 16. Explicitly Unresolved And Unauthorized

```text
tree/router promotion
automatic ☱->☶ QA routing
multiple/optional QA profiles
semantic diagnosis of rejection
automatic rejected-generation recovery
lineage software acceptance
CLI/TUI acceptance rendering
generic command execution
provider retry/resume
QA cleanup/compost policy
production popularity/signature policy
```

These are not blockers for CRYSTALL of the first body transaction.

## 17. Decision

```text
TABLE treatment: accepted
precision amendments: applied in place
old TABLE archaeology: marked partially superseded
crystallization gate: open for the exact post-QN20 body transaction
runtime/code gate: closed
router/lineage acceptance gates: closed
```

The next action is CRYSTALL, not implementation.
