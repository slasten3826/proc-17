# QA Check And Verdict Yellowprint v0

Status:

```text
layer: table (checked)
date: 2026-07-23
scope: body-owned QA evidence, infrastructure failure and deterministic verdict
runtime implementation authorized: no
QA execution authorized: no
router/pressure promotion authorized: no
crystallization authorized: yes; QA TABLE cross-audit 2026-07-23
gate record: docs/00_chaos/qa_table_cross_audit_2026-07-23.md
```

## 2026-07-29 Post-QN20 Treatment Boundary

This document remains the original body-evidence policy, but its unimplemented
record schemas and handoff details are partially superseded by:

```text
qa_body_evidence_verdict_v1_yellowprint.v0.md
qa_body_transaction_reconciliation_yellowprint.v0.md
```

Keep the dedicated-writer, deterministic-verdict, subject-ceiling,
split-brain, completion/economics and terminal-retention laws. Do not implement
sections 3-7 from the old payload shapes: `cleanup="complete"`, the v0 provider
error projection and caller-shaped report handoff are archaeology. The
post-QN20 treatment preserves exact RUN v1 cause/finality and admits body
evidence only through a strict private receipt/result join.

Runtime implementation remains unauthorized until the post-QN20 treatment is
crystallized.

Primary chaos source:

[`../../00_chaos/second_qa_hand_threat_model_2026-07-23.md`](../../00_chaos/second_qa_hand_threat_model_2026-07-23.md)

Companion TABLE contracts:

```text
qa_contract_profile_yellowprint.v0.md
qa_execution_capability_yellowprint.v0.md
completion_scope_candidate_seal_yellowprint.v0.md
nested_work_layer_derivation_yellowprint.v0.md
stage_transition_generation_recovery_yellowprint.v0.md
```

## 0. Selected Decisions

```text
QV01 provider output is never body evidence by itself
QV02 one dedicated body writer joins request, private receipt and trusted report
QV03 a clean contained candidate outcome creates exactly one qa.check.v0
QV04 infrastructure failure creates qa.execution_failure.v0, never qa.check.v0
QV05 trusted schema/identity contradiction remains a loud harness failure
QV06 candidate accepted and candidate rejected are both check observations first
QV07 one deterministic ☱ assembly creates the final candidate verdict
QV08 v0 has exactly one required aggregate check and therefore no skipped tail
QV09 both accepted and rejected checks require a final verdict before ▲
QV10 no final verdict exists while required evidence is missing or incomplete
QV11 current seal alignment is checked at dispatch, check write and verdict assembly
QV12 a final verdict binds the exact request, check, seal, contract and environment
QV13 the substrate has zero check, verdict and applicability authority
QV14 QA execution creates economics but no identity loss by itself
QV15 an exact replay returns existing detached evidence without a second body event
QV16 an infrastructure execution failure reaches existing effect_failure mortality
QV17 manifest/corpse preserve exact bounded QA evidence outside trace_tail
QV18 QA acceptance proves declared contract satisfaction, not universal correctness
```

## 1. Closed Evidence Claim

This table admits exactly three body-facing outcome families:

```text
qa.check.v0
  a clean, contained candidate execution was mechanically observed

qa.execution_failure.v0
  the host could not prove a complete trustworthy candidate execution

qa.candidate_verdict.v0
  deterministic body logic classified a complete current required-check set
```

They are not aliases. Absence of one cannot be filled by another.

The table does not claim that a passing test makes arbitrary software correct.
It claims only that the exact candidate satisfied the exact birth-bound QA
contract in the exact registered environment.

## 2. Causal Chain And Owners

```text
Packet birth / lineage transition
  writes immutable qa.contract.v0

exact current candidate seal + aligned body evidence
  lets body derive qa.check_request.v0

private capability registry + trusted supervisor
  writes one private execution receipt and one normalized report/error

☶ body evidence writer
  joins current body state + request + receipt + report/error
  writes qa.check.v0 OR qa.execution_failure.v0

☱ final verdict assembler
  reads the exact complete required check set
  writes qa.candidate_verdict.v0

completion/work-layer/△
  read only body-owned check/verdict/failure records
```

No row may write another row's fact. In particular, the provider cannot write a
check, ☶ cannot invent a provider receipt, and ☱ cannot rerun the candidate.

## 3. Strict Handoff Gate

The body writer accepts no caller-supplied result table. It joins records by
identity from the body and private registry:

```text
living build Packet
exact current qa.check_request.v0 derived from that Packet
exact consumed private transaction and execution receipt
strictly normalized provider candidate report OR provider error
same Packet/lineage/generation/stage/repository
same seal/contract/check/profile/environment
candidate alignment still aligned
no prior current check or execution-failure record for the request
```

The writer re-derives request identity and verifies every source reference. A
matching string id without its authoritative record grants nothing.

Outcomes:

| Handoff state | Body action |
|---|---|
| exact clean candidate report | write one `qa.check.v0` |
| exact typed provider infrastructure error | write one `qa.execution_failure.v0` |
| provider report/error malformed or identity-impossible | loud harness failure; write neither |
| private receipt/body evidence split | loud invariant; no rerun |
| current seal alignment diverged | typed conflict; no check/verdict advancement |
| foreign/stale request | deny; no body mutation |

## 4. QA Check Record

Conceptual body event payload:

```lua
{
  protocol_version = "qa.check.v0",
  qa_check_id = "qa-check:<sha256>",

  packet_id = string,
  lineage_id = string,
  generation = integer,
  process_contract_id = string,
  context = "software_task.v0",
  stage_id = string,
  repository_id = string,

  candidate_seal_id = string,
  candidate_seal_event_ref = string,
  artifact_alignment_id = string,
  qa_contract_id = string,
  check_id = string,
  profile_id = "qa.profile.lua54_test_suite.v0",
  environment_id = string,

  request_id = string,
  request_ref = string,
  execution_receipt_id = string,

  outcome = "accepted" | "rejected",
  reason = "expected_exit"
    | "unexpected_exit"
    | "signal"
    | "wall_timeout"
    | "cpu_limit"
    | "memory_limit"
    | "output_limit"
    | "scratch_limit"
    | "sandbox_policy_violation",

  termination = {
    kind = "exit" | "signal" | "supervisor_kill",
    exit_code = integer | nil,
    signal = integer | nil,
  },

  source = {
    pre_inventory_id = string,
    post_inventory_id = string,
    stable = true,
  },
  stdout = bounded_stream_measurement,
  stderr = bounded_stream_measurement,
  resources = bounded_resource_measurement,
  scratch = bounded_scratch_measurement,
  cleanup = "complete",
  runtime_cost = qa_cost,

  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed" | "mixed",
}
```

Every field except `qa_check_id` participates in canonical identity. The id is
derived, never accepted as evidence about its own contents.

The body event has:

```text
type = qa_check
operator = ☶
truth_status = runtime_confirmed
payload = detached qa.check.v0
cost = exact runtime_cost projection admitted by budget law
```

Raw stdout/stderr, private handles, host paths, provider pointers and scratch
contents are absent.

## 5. Candidate Outcome Law

Accepted is narrow:

```text
provider outcome = accepted
reason = expected_exit
termination = exit 0
source stable
cleanup complete
no bound/policy violation
all measurements within the exact profile envelope
```

Every cleanly contained non-success termination admitted by the profile is a
candidate rejection:

| Observation | Check outcome |
|---|---|
| nonzero exit | rejected / `unexpected_exit` |
| candidate signal/crash | rejected / `signal` |
| watchdog proves wall timeout and reaps candidate | rejected / `wall_timeout` |
| kernel/supervisor proves CPU bound | rejected / `cpu_limit` |
| kernel/supervisor proves memory bound | rejected / `memory_limit` |
| bounded output ceiling reached | rejected / `output_limit` |
| bounded scratch ceiling reached | rejected / `scratch_limit` |
| candidate attempts a denied sandbox action | rejected / `sandbox_policy_violation` |

The word `rejected` means the candidate failed the declared profile under a
working containment system. It never means the containment system failed.

## 6. Infrastructure Failure Record

Conceptual body payload:

```lua
{
  protocol_version = "qa.execution_failure.v0",
  failure_id = "qa-execution-failure:<sha256>",

  packet_id = string,
  lineage_id = string,
  generation = integer,
  process_contract_id = string,
  context = "software_task.v0",
  stage_id = string,
  repository_id = string,

  candidate_seal_id = string,
  candidate_seal_event_ref = string,
  artifact_alignment_id = string,
  qa_contract_id = string,
  check_id = string,
  profile_id = string,
  environment_id = string,

  request_id = string,
  request_ref = string,
  execution_receipt_id = string,

  class = "unavailable" | "world" | "ambiguous",
  code = qa_provider_error_code_v0,
  stage = "preflight" | "namespace" | "launch" | "supervision"
    | "postflight" | "cleanup",
  candidate_started = boolean,
  source_stable = true | false | nil,
  cleanup_complete = true | false | nil,
  transaction_disposition = "consumed_failed" | "quarantined",
  runtime_cost = qa_cost,

  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed",
}
```

This record has no `outcome`, `qa_check_id` or verdict contribution. It cannot
be counted as a rejected check.

The body operation returns the same typed evidence through the existing
`effect_failure` contract. The tree runner records the failed external effect,
charges actual cost, kills the Packet with `death_cause=effect_failure`, and
leaves the lineage blocked under the existing completion law. It does not
automatically rebuild or retry against an ambiguous world.

Pre-dispatch `not_ready` conditions create neither this record nor candidate
execution cost. They are readiness facts, not attempted effects.

## 7. Trusted Invariant Failure

Examples:

```text
provider report has impossible protocol/version/identity
accepted report carries nonzero exit or unstable source
private receipt says completed but provider report says no transaction
measurement is negative, non-finite or exceeds an impossible hard envelope
body check exists without the matching private receipt
two different records claim the same exact request
```

These conditions mean proc-17's trusted physics is contradictory. The adapter
or body writer returns a loud error to the harness. It must not append a
plausible `qa.execution_failure.v0`, kill the Packet honestly, or continue.

## 8. Exactly-One Check Policy

The v0 contract contains exactly one required aggregate check. Therefore:

```text
required_checks = 1
no optional checks
no fail-fast tail
no skipped record
no parallel scheduling
one request -> one candidate transaction -> one check OR execution failure
```

The aggregate Lua test suite may execute many assertions inside the candidate
process. Their internal count is diagnostic candidate content; the body still
owns one required check identity.

This removes the dangerous state "one failure observed, unknown required tail"
from v0 without pretending that future multi-check scheduling is solved.

## 9. Final Verdict Assembly

Conceptual pure preparation plus one body write:

```text
qa_verdict.prepare(instance, qa_contract_id)
  -> detached candidate verdict OR not_ready/conflict

☱ qa_verdict.commit(instance, prepared)
  -> one immutable body event
```

Read set:

```text
living build Packet and verified birth contract
exact current candidate seal
current artifact alignment = aligned
exact qa.contract.v0 and its complete required set
exact current qa.check.v0 for every required check
absence of current qa.execution_failure.v0 for the request/check
absence of conflicting, foreign or stale check/verdict evidence
```

No provider call and no substrate call occurs during preparation or commit.

## 10. Candidate Verdict Record

```lua
{
  protocol_version = "qa.candidate_verdict.v0",
  verdict_id = "qa-verdict:<sha256>",

  packet_id = string,
  lineage_id = string,
  generation = integer,
  process_contract_id = string,
  context = "software_task.v0",
  stage_id = string,
  repository_id = string,

  candidate_seal_id = string,
  candidate_seal_event_ref = string,
  artifact_alignment_id = string,
  qa_contract_id = string,
  profile_id = string,
  environment_id = string,

  verdict = "accepted" | "rejected",
  required_checks = 1,
  accepted_checks = 0 | 1,
  rejected_checks = 0 | 1,
  check_ids = {string},
  check_refs = {string},
  request_refs = {string},
  runtime_cost = qa_cost,

  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed" | "mixed",
}
```

Rules:

```text
one accepted check -> accepted verdict
one rejected check -> rejected verdict
zero checks -> not_ready
execution failure -> not_ready/infrastructure conflict, no verdict
accepted and rejected check for one current request -> loud conflict
check for another seal/contract/environment -> ignored as current evidence + conflict ref
alignment diverged -> no verdict even if the historical check was accepted
```

All fields except `verdict_id` participate in canonical identity. `runtime_cost`
is the exact sum/projection of included check cost; verdict assembly adds no
external-effect cost.

The body event has:

```text
type = qa_candidate_verdict
operator = ☱
truth_status = runtime_confirmed
cost = {}
```

## 11. Symmetric Work-Layer Projection

Accepted and rejected observations receive the same epistemic sequence:

| Current exact state | Glyph | Reason | Missing requirement |
|---|---|---|---|
| sealed, no check/failure/verdict | `⊞` | `candidate_sealed_qa_missing` | one bounded QA execution |
| accepted check, final verdict absent | `◈` | `qa_acceptance_verdict_pending` | deterministic accepted verdict |
| rejected check, final verdict absent | `◈` | `qa_rejection_verdict_pending` | deterministic rejected verdict |
| QA infrastructure failure | `⊞` | `qa_infrastructure_incomplete` | typed Packet effect-failure terminalization; no verdict |
| final accepted verdict, alignment aligned | `▲` | `software_acceptance_candidate_ready` | △ terminal manifest/corpse |
| final rejected verdict, alignment aligned | `▲` | `rejected_generation_recovery_ready` | △ rejected-generation terminal projection/corpse |
| any post-seal alignment divergence | `⊞` | `candidate_sealed_body_conflict` | fresh-generation PLAN; no current acceptance |

This corrects the old asymmetry where a rejected check needed verdict assembly
but an accepted check jumped directly to `▲`.

The QA hand does not itself choose glyphs or routes. It writes evidence. The
pure work-layer reader derives the projection from that evidence.

## 12. Completion Scope Consequences

Candidate states become:

```text
unsealed
sealed
qa_acceptance_observed
qa_rejection_observed
qa_infrastructure_incomplete
qa_accepted
qa_rejected
unsupported
```

Meanings:

| Candidate state | Required proof |
|---|---|
| `sealed` | exact seal, no current QA body outcome |
| `qa_acceptance_observed` | exact accepted check, final verdict absent |
| `qa_rejection_observed` | exact rejected check, final verdict absent |
| `qa_infrastructure_incomplete` | exact execution failure, no check/verdict |
| `qa_accepted` | exact final accepted verdict |
| `qa_rejected` | exact final rejected verdict |

Only `qa_accepted` may expose `software_acceptance_ready`. Only `qa_rejected`
may expose `rejected_generation_recovery_ready`. Neither living Packet may
claim lineage-owned `software_accepted`.

## 13. Terminal Manifest And Corpse Retention

An accepted terminal manifest binds:

```text
candidate seal id/ref
artifact alignment id/ref
qa contract/profile/environment ids
accepted qa check id/ref
accepted final verdict id/ref
bounded execution measurements and runtime cost
```

A rejected-generation terminal manifest binds the same coordinates plus:

```text
rejected qa check id/ref and reason
rejected final verdict id/ref
bounded mechanical termination/resource/output facts
preserved truth statuses and completeness status
```

These refs live in the full manifest and corpse manifest. `trace_tail` remains
diagnostic and may omit the original execution tick without losing lineage
truth.

No raw output, private receipt contents, lease, provider handle, host path or
repair instruction crosses △ or corpse.

## 14. Idempotence And Conflict Law

```text
same request + same private receipt + same normalized report
  -> same qa_check/qa_execution_failure identity, no second append

same complete check set + same seal/alignment/contract/environment
  -> same verdict identity, no second append

same request + different candidate outcome
  -> loud conflict, never supersession

same check + changed seal/alignment/contract/environment
  -> historical evidence only, not current contribution

caller mutates detached returned record
  -> stored event and next projection unchanged
```

V0 has no check amendment, retry, supersession or "latest wins" policy.

## 15. Truth Status Matrix

| Fact | Truth status |
|---|---|
| exact process termination and measured bounds | `runtime_confirmed` |
| source stability and cleanup proved by trusted supervisor | `runtime_confirmed` |
| body act of writing check/failure/verdict | `runtime_confirmed` |
| host/lineage policy that this check is required | preserved contract status, possibly `mixed` |
| claim that accepted verdict proves universal correctness | absent |
| substrate diagnosis of rejected output | `semantic_proposal` |
| applicability of ancestor rejection to descendant | later proposal/lineage contract, not current verdict |

The final verdict is deterministic runtime truth about contract satisfaction,
not metaphysical truth about all possible software behavior.

## 16. Economics And Loss

```text
denied/not_ready before dispatch
  no candidate process cost

clean accepted/rejected check
  one QA execution/tool-call charge plus measured wall/CPU/scratch/output cost

infrastructure failure after dispatch
  actual measured cost charged before effect_failure death

verdict preparation/commit
  body tick only; no external tool cost

QA execution itself
  no identity loss merely for running
```

Packet-local budget and cumulative lineage economics remain separate. Exact
replay with no process does not charge a second QA execution.

## 17. Named Writers And Readers

| Record | Writer | First named reader |
|---|---|---|
| `qa.check_request.v0` | body request derivation | private grant/dispatch resolver |
| private execution receipt | capability registry | ☶ body evidence writer/idempotence check |
| provider candidate report | trusted adapter | ☶ body evidence writer |
| provider infrastructure error | trusted adapter | ☶ body failure writer |
| `qa.check.v0` | ☶ body evidence writer | ☱ verdict assembler |
| `qa.execution_failure.v0` | ☶ body failure writer | operator registry/tree runner effect-failure path |
| `qa.candidate_verdict.v0` | ☱ deterministic assembler | completion/work-layer/△ |
| accepted/rejected terminal QA projection | △ manifest writer | corpse/lineage/corpus |

There is no storage row without an explicit reader.

## 18. Failure Classification

| Condition | Class | Packet/body consequence |
|---|---|---|
| no seal/contract/profile/alignment | not_ready | no process, no check, no death |
| contained candidate fails test/limit/policy | candidate rejection | rejected check, then rejected verdict |
| provider cannot prove launch/supervision/postflight/cleanup | infrastructure failure | execution-failure evidence, existing effect_failure death |
| provider report malformed or trusted identities conflict | invariant failure | harness loud, no honest Packet outcome |
| accepted check but Packet dies before verdict | ordinary mortality | no final acceptance; fresh generation under existing stage law |
| final rejected verdict | generation evidence | △/corpse then fresh repository generation if lineage can afford it |

Infrastructure failure does not classify the candidate and does not enter grave
as QA rejection. Existing grave classification sees the Packet death cause,
not a fabricated candidate verdict.

## 19. Permanent Controls

### Body handoff

| ID | Control | Expected result |
|---|---|---|
| QV-T01 | caller supplies complete-looking provider report | zero authority/no body event |
| QV-T02 | exact request + receipt + accepted report | one accepted check |
| QV-T03 | exact request + receipt + rejected report | one rejected check |
| QV-T04 | exact request + infrastructure error | one execution failure, no check |
| QV-T05 | malformed trusted report | loud harness failure |
| QV-T06 | foreign/stale seal/contract/check/environment | no advancement |
| QV-T07 | alignment changes before body write | conflict, no check/verdict |
| QV-T08 | private receipt absent | loud split-brain/no rerun |

### Check and verdict

| ID | Control | Expected result |
|---|---|---|
| QV-T09 | accepted check, verdict absent | build `◈`, acceptance verdict pending |
| QV-T10 | rejected check, verdict absent | build `◈`, rejection verdict pending |
| QV-T11 | accepted check, exact ☱ assembly | final accepted verdict and build `▲` |
| QV-T12 | rejected check, exact ☱ assembly | final rejected verdict and build `▲` |
| QV-T13 | execution failure | no verdict; build infrastructure-incomplete before effect death |
| QV-T14 | accepted and rejected records for same request | loud conflict |
| QV-T15 | exact replay | same detached record, no launch/append/cost |
| QV-T16 | mutate detached check/verdict | stored evidence unchanged |
| QV-T17 | substrate says pass/failure harmless | zero evidence/verdict delta |

### Terminal and lineage

| ID | Control | Expected result |
|---|---|---|
| QV-T18 | accepted verdict without △/corpse | no lineage software acceptance |
| QV-T19 | rejected verdict without △/corpse | no recovery carrier yet |
| QV-T20 | >32 later trace events before corpse | QA refs survive in full manifest |
| QV-T21 | old generation check offered to child | historical only; no current verdict |
| QV-T22 | QA execution failure offered as rejection | schema/type rejection |
| QV-T23 | timeout under proven containment | rejected check, not infrastructure error |
| QV-T24 | timeout cleanup cannot be proved | infrastructure failure, no check |
| QV-T25 | check cost replayed | no duplicate economics |
| QV-T26 | accepted verdict rendered as universal correctness | claim-ceiling violation |

Death/seal/lineage fixtures are grown by real producers. Provider corruption
and malicious process fixtures run only through the hostile QA harness.

## 20. Cross-Table Amendments Required

Before crystallization, companion tables must adopt:

```text
completion candidate states:
  qa_acceptance_observed
  qa_rejection_observed
  qa_infrastructure_incomplete
  qa_accepted
  qa_rejected

work-layer build rows:
  accepted check without verdict -> ◈
  rejected check without verdict -> ◈
  infrastructure failure -> ⊞ then existing effect_failure terminal path

stage law:
  accepted/rejected both require final verdict and △/corpse
  infrastructure failure never becomes accepted or rejected generation evidence
```

The old direct mapping `all required checks accepted -> qa_accepted` is
superseded. A check observation and a final body verdict are separate acts on
both branches.

## 21. Explicit Deferrals

```text
multiple required or optional checks
parallel/fail-fast scheduling and skipped records
provider-internal retry
same-root QA resume after Packet death
raw diagnostic output retention or prompt ingestion
semantic repair diagnosis
QA-produced source patching
external/legacy differential QA
QA result supersession
universal correctness claims
CLI/TUI QA rendering
```

## 22. Closed Chaos Questions

```text
Q8  accepted/rejected clean reports become checks; infrastructure becomes a
    different record; impossible trusted reports stay loud
Q9  timeout/signal/resource/policy are rejection only when containment and
    cleanup are proved; otherwise infrastructure failure
Q10 v0 has exactly one required aggregate check, so no skipped tail
Q11 body retains bounded counts/digests/measurements, never raw streams
Q12 request/receipt/check/verdict identities are canonical and one-use
Q13 final verdict binds complete exact current seal/alignment/contract/check/
    profile/environment evidence
Q14 actual QA cost is charged; verdict has no external cost; no QA identity loss
```

## 23. Table Thesis

```text
The second hand may expose a candidate to consequence, but it does not name
that consequence alone. The supervisor reports, ☶ makes body evidence, and ☱
judges only the complete exact record. A broken test is software evidence; a
broken testing world is not.
```
