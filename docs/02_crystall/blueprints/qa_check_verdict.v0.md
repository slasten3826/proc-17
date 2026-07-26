# QA Check And Verdict Blueprint v0

Status:

```text
layer: crystall (◈)
date: 2026-07-23
source table:
  docs/01_table/yellowprints/qa_check_verdict_yellowprint.v0.md
gate record:
  docs/00_chaos/qa_table_cross_audit_2026-07-23.md
crystall audit:
  docs/00_chaos/qa_crystall_cross_audit_2026-07-23.md
depends on:
  docs/02_crystall/blueprints/qa_contract_profile.v0.md
  docs/02_crystall/blueprints/qa_execution_capability.v0.md
implementation authority: dedicated body schemas/writers and deterministic
  verdict after hostile transaction controls are green
software acceptance authority: forbidden; lineage remains sole owner
router/pressure promotion: forbidden until grown-life corpus
```

## 0. Crystallized Claim

The second hand produces body truth in two acts:

```text
☶ observes one exact contained execution
  -> qa.check.v0 accepted OR rejected

☱ reads the complete exact required set
  -> qa.candidate_verdict.v0 accepted OR rejected
```

An incomplete testing world produces a different record:

```text
☶ -> qa.execution_failure.v0 -> existing effect_failure mortality
```

Provider output is never body evidence by itself. Candidate acceptance and
candidate rejection take the same path through `◈`; success receives no shorter
epistemic route.

## 1. Exact Implementation Surface

New:

```text
runtime/qa_evidence.lua
runtime/qa_verdict.lua
tests/test_qa_evidence.lua
tests/test_qa_verdict.lua
tests/test_qa_terminal_retention.lua
```

Modify:

```text
core/packet.lua                  four event types, dedicated QA append gate
runtime/body.lua                strict detached QA event writers
organs/logic.lua                ☶ request/check/failure branch
organs/runtime.lua              ☱ deterministic verdict branch
runtime/operator_registry.lua   existing effect_failure result only
runtime/completion_scope.lua    body-owned QA reader
runtime/work_layer.lua          symmetric accepted/rejected ◈ rows
logic/manifest.lua              terminal QA projection
runtime/corpse.lua              full QA evidence outside trace_tail
runtime/carrier.lua             rejected terminal projection as history only
tests/run.lua
```

No provider, registry or private handle is read by completion/work-layer/manifest
code. Those readers consume only immutable body events.

## 2. Event Vocabulary And Actor Rights

Add to `packet.event_types` and `dedicated_event_types`:

```text
qa_check_request
qa_check
qa_execution_failure
qa_candidate_verdict
```

Dedicated actor rights:

```lua
qa_check_request = {['☶'] = true}
qa_check = {['☶'] = true}
qa_execution_failure = {['☶'] = true}
qa_candidate_verdict = {['☱'] = true}
```

Add a separate gate:

```lua
packet.append_qa_event(instance, event)
```

It accepts only the four QA event types, verifies actor/tick/mutability and then
uses the existing deep-copying append path. Generic `append_trace` cannot write
these dedicated types.

`runtime/body.lua` gains:

```lua
body.record_qa_request(instance, payload)
body.record_qa_check(instance, payload)
body.record_qa_execution_failure(instance, payload)
body.record_qa_candidate_verdict(instance, payload)
```

Each function validates before and after deep copy, appends under its exact
actor, returns a detached payload/event and increments only the named evidence
revision. No function accepts a truth-status override.

## 3. Evidence API

```lua
local qa_evidence = require("runtime.qa_evidence")

qa_evidence.record_request(instance, prepared_request)
  -> detached_request, event | nil, err

qa_evidence.commit_execution(instance, qa_registry, execution_receipt_id)
  -> detached_check_or_failure, event | nil, effect_failure_or_err, loud

qa_evidence.current(instance, qa_contract_id, candidate_seal_id)
  -> detached_evidence_view | nil, err

qa_evidence.verify_request(instance, value) -> true | nil, err
qa_evidence.verify_check(instance, value) -> true | nil, err
qa_evidence.verify_failure(instance, value) -> true | nil, err
```

`commit_execution` does not accept a provider report table. It asks the exact
private QA registry for the committed receipt and normalized result, then joins
them to current body state. A receipt id supplied without that private state has
zero authority.

## 4. Strict Handoff Join

Before writing an outcome, `qa_evidence` verifies:

```text
Packet is living, build mode and currently at ☶
exact qa_check_request body event exists in this ☶ causal path
request re-derives byte-for-byte from current Packet/seal/contract
private receipt is committed and names that exact request event
normalized result digest equals receipt.normalized_result_id
Packet/lineage/generation/process/context/stage/repository all agree
seal id/event, current alignment, contract/check/profile/environment all agree
candidate alignment remains aligned
no current outcome exists for the request
```

The join has exactly three results:

```text
candidate report -> qa.check.v0
provider error   -> qa.execution_failure.v0 + effect_failure return
contradiction    -> loud invariant, no body record/death
```

A change in current alignment before body append is a typed conflict and
quarantines the private transaction. It does not turn a stale report into a
check.

## 5. Exact Check Record

```lua
{
  protocol_version = "qa.check.v0",
  qa_check_id = "qa-check:<sha256>",

  packet_id = string,
  lineage_id = string,
  generation = positive_integer,
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
  stdout = qa_stream_measurement,
  stderr = qa_stream_measurement,
  resources = qa_resource_measurement,
  scratch = qa_scratch_measurement,
  cleanup = "complete",
  runtime_cost = qa_cost,

  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed" | "mixed",
}
```

Every field except `qa_check_id` participates in canonical identity. The event:

```text
type = qa_check
operator = ☶
truth_status = runtime_confirmed
cost = {tool_calls=1, test_runs=1, time_ms=<measured wall>}
```

The event cost is the admitted projection, not a second budget charge. The
runner charges it exactly once from the organ effect payload.

## 6. Candidate Outcome Predicate

Accepted iff all are true:

```text
provider outcome accepted
reason expected_exit
termination exit 0
source stable
cleanup complete
all measurements valid and within the exact contract
no policy/resource bound reached
```

Every other clean candidate report maps mechanically to rejected. No stdout,
stderr, substrate summary or semantic diagnosis can override the predicate.

Truth ceiling:

```text
accepted = this exact candidate satisfied this exact required check under this
           exact profile/environment
accepted != universally correct software
```

## 7. Exact Infrastructure Failure Record

```lua
{
  protocol_version = "qa.execution_failure.v0",
  failure_id = "qa-execution-failure:<sha256>",

  packet_id = string,
  lineage_id = string,
  generation = positive_integer,
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

Every field except `failure_id` participates in identity. The event:

```text
type = qa_execution_failure
operator = ☶
truth_status = runtime_confirmed
cost = admitted actual budget projection
```

The record has no `outcome`, `qa_check_id` or verdict contribution.

After append, `commit_execution` returns the existing typed effect failure with
this record in `detail`. The operator registry and runner must recognize the
typed return unchanged, charge actual cost, append normal operator-failure
evidence and kill the Packet with `effect_failure`.

## 8. Loud Trusted Invariants

These do not write `qa.execution_failure.v0`:

```text
provider/native report has unknown keys/version/code
accepted report has nonzero exit, unstable source or incomplete cleanup
negative/non-finite/impossible measurements or cost
receipt result digest differs from registry result
body outcome exists without private receipt
private receipt exists with a contradictory body outcome
two different outcomes claim one request
event actor or causal order is impossible
```

They return a loud error to the harness. The Packet is not given a plausible
death for broken trusted physics.

## 9. Verdict API

```lua
local qa_verdict = require("runtime.qa_verdict")

qa_verdict.prepare(instance, qa_contract_id)
  -> detached_verdict | nil, diagnostic

qa_verdict.commit(instance, prepared_verdict)
  -> detached_verdict, event | nil, err

qa_verdict.current(instance, candidate_seal_id, qa_contract_id)
  -> detached_verdict, event | nil, reason

qa_verdict.verify(instance, value) -> true | nil, err
```

Preparation is pure and calls no provider/substrate. Commit requires the same
☱ tick, re-derives every source and rejects a stale supplied preparation.

Read set:

```text
verified birth QA contract
exact current immutable seal and aligned artifact view
complete one-element required-check set
exact current qa.check.v0
no current qa.execution_failure.v0
no foreign/stale/conflicting check or verdict
```

## 10. Exact Candidate Verdict

```lua
{
  protocol_version = "qa.candidate_verdict.v0",
  verdict_id = "qa-verdict:<sha256>",

  packet_id = string,
  lineage_id = string,
  generation = positive_integer,
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

One accepted check produces accepted verdict. One rejected check produces
rejected verdict. Zero checks or an execution failure is not-ready. The event:

```text
type = qa_candidate_verdict
operator = ☱
truth_status = runtime_confirmed
cost = {}
```

`runtime_cost` is a detached aggregation of the included check and is not
charged again. Every field except `verdict_id` participates in identity.

## 11. Idempotence And Conflict

```text
same request/receipt/result -> same check/failure, no append/cost
same complete check set/current identities -> same verdict, no append
same request with different result -> loud
same seal with accepted and rejected current verdict -> loud
same check after alignment/contract/environment change -> history only
mutated detached return -> stored trace/next read unchanged
```

There is no retry, amendment, supersession or latest-wins rule in v0.

## 12. Completion Scope Amendment

`runtime.completion_scope` adopts exact candidate states:

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

Reader precedence:

| Evidence | Candidate state | Boundary candidate |
|---|---|---|
| seal, no QA outcome | `sealed` | none |
| accepted check, no verdict | `qa_acceptance_observed` | none |
| rejected check, no verdict | `qa_rejection_observed` | none |
| execution failure | `qa_infrastructure_incomplete` | none |
| final accepted verdict + aligned seal | `qa_accepted` | `software_acceptance_ready` |
| final rejected verdict + aligned seal | `qa_rejected` | `rejected_generation_recovery_ready` |

Packet/corpse subject ceilings remain unchanged. Only lineage can later write
`software_accepted`.

## 13. Work-Layer Amendment

Build precedence becomes:

| Row | Exact current evidence | Glyph | State | Reason |
|---|---|---|---|---|
| B0 | sealed + artifact alignment diverged | `⊞` | checking | `candidate_sealed_body_conflict` |
| B1 | final accepted verdict | `▲` | boundary | `software_acceptance_candidate_ready` |
| B2 | final rejected verdict | `▲` | boundary | `rejected_generation_recovery_ready` |
| B3A | accepted check, verdict absent | `◈` | crystallizing_verdict | `qa_acceptance_verdict_pending` |
| B3R | rejected check, verdict absent | `◈` | crystallizing_verdict | `qa_rejection_verdict_pending` |
| B4 | execution failure before effect death | `⊞` | checking | `qa_infrastructure_incomplete` |
| B5 | seal, no QA outcome | `⊞` | checking | `candidate_sealed_qa_missing` |
| B6 | artifact set complete, no seal | `⋯` | forming | `artifact_set_complete_seal_missing` |
| B7 | incomplete artifact set | `⋯` | forming | `candidate_materialization_incomplete` |

The layer reader has no access to private QA state and writes no route.

## 14. Terminal Projection

`logic/manifest.lua` adds a bounded body-derived block:

```lua
qa_terminal_projection = {
  protocol_version = "qa.terminal_projection.v0",
  candidate_seal_id = string,
  candidate_seal_event_ref = string,
  artifact_alignment_id = string,
  qa_contract_id = string,
  profile_id = string,
  environment_id = string,
  request_id = string,
  request_ref = string,
  qa_check_id = string,
  qa_check_ref = string,
  check_outcome = "accepted" | "rejected",
  check_reason = qa_candidate_reason_v0,
  verdict_id = string,
  verdict_ref = string,
  verdict = "accepted" | "rejected",
  stdout = qa_stream_measurement,
  stderr = qa_stream_measurement,
  resources = qa_resource_measurement,
  scratch = qa_scratch_measurement,
  runtime_cost = qa_cost,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed" | "mixed",
}
```

△ may assemble it only from an exact final verdict and its exact check. It
cannot synthesize or amend the verdict. Accepted and rejected terminal
projections have the same schema.

## 15. Corpse Retention

`runtime/corpse.lua` always freezes a bounded QA evidence envelope independent
of `trace_tail`:

```lua
qa_evidence = {
  protocol_version = "corpse.qa_evidence.v0",
  qa_contract_id = string | nil,
  request_id = string | nil,
  request_ref = string | nil,
  check = detached_qa_check | nil,
  check_ref = string | nil,
  execution_failure = detached_qa_execution_failure | nil,
  execution_failure_ref = string | nil,
  verdict = detached_qa_candidate_verdict | nil,
  verdict_ref = string | nil,
  terminal_projection = qa_terminal_projection | nil,
  source_refs = string[],
}
```

The corpse hash covers the envelope. It permits these honest deaths:

```text
accepted/rejected check before verdict -> check survives, no boundary candidate
execution failure -> failure survives outside trace_tail, no candidate verdict
final verdict + △ -> full terminal projection survives
```

No raw output, private receipt body, lease, handle, path or scratch content is
retained. An ancestor envelope attached to a descendant is historical evidence
only and cannot satisfy the child's current QA reader.

## 16. Truth And Economics

```text
process termination/limits/source stability/cleanup  runtime_confirmed
body check/failure/verdict append                     runtime_confirmed
host policy sufficiency                              preserved mixed if mixed
semantic diagnosis of failure                        semantic_proposal, deferred
universal correctness                                absent
```

QA execution creates no identity loss merely by running. The body effect cost
is charged once; verdict assembly pays only its normal body tick. Exact replay
is free of duplicate external-effect cost.

## 17. Named Writers And Readers

| Record | Sole writer | First named reader |
|---|---|---|
| QA request event | ☶ request writer | private grant resolver |
| private receipt/result | QA registry/provider | ☶ evidence writer |
| `qa.check.v0` | ☶ strict evidence writer | ☱ verdict assembler |
| `qa.execution_failure.v0` | ☶ strict failure writer | operator registry/runner |
| `qa.candidate_verdict.v0` | ☱ deterministic assembler | completion/work-layer/△ |
| terminal QA projection | △ manifest assembler | corpse/lineage/corpus |
| corpse QA envelope | corpse capturer | lineage/corpus/recovery history |

No record is introduced without a reader.

## 18. Permanent Controls

```text
QV01 caller-supplied provider result has zero body authority
QV02 exact accepted report writes one accepted check
QV03 exact rejected report writes one rejected check
QV04 exact provider error writes one execution failure and no check
QV05 malformed trusted result is loud, not Packet mortality
QV06 foreign/stale seal/contract/environment cannot advance
QV07 alignment change before append writes no check/verdict
QV08 private receipt absent/contradictory is loud and no rerun
QV09 accepted check without verdict derives build ◈
QV10 rejected check without verdict derives build ◈
QV11 ☱ exact accepted set derives accepted verdict and build ▲
QV12 ☱ exact rejected set derives rejected verdict and build ▲
QV13 execution failure derives no verdict and enters effect_failure
QV14 conflicting accepted/rejected evidence is loud
QV15 exact replay writes/charges nothing twice
QV16 substrate pass/fail wording changes no evidence
QV17 accepted verdict before △/corpse is not lineage acceptance
QV18 rejected verdict before △/corpse cannot birth recovery
QV19 >32 later trace events cannot erase QA evidence from corpse
QV20 ancestor QA offered to child remains historical only
QV21 contained timeout is rejection; ambiguous cleanup is infrastructure
QV22 check/verdict detached mutation changes no stored evidence
QV23 final verdict does not charge QA execution twice
QV24 accepted rendering cannot exceed contract-satisfaction claim
```

All death/corpse/lineage controls use grown producers. Trusted corruption uses
the hostile provider harness.

## 19. Implementation Order

```text
1. red exact-schema/event-right/idempotence tests
2. core/body dedicated append gates
3. request event writer
4. fake private receipt join for accepted/rejected/infrastructure matched cases
5. qa.check and qa.execution_failure writers
6. existing effect_failure return/accounting integration
7. deterministic ☱ verdict preparation/commit
8. completion/work-layer readers in shadow
9. terminal manifest and corpse retention
10. grown living/corpse/descendant matched corpus
11. only then consider tree readiness/route promotion
```

## 20. Promotion Gates

```text
G0 every schema/id/actor right is closed
G1 candidate/infrastructure/invariant matched triples are green
G2 accepted and rejected use identical check -> verdict phase count
G3 private/body split-brain is loud and replay-safe
G4 effect failure charges and kills exactly once
G5 completion/work-layer observer ablation is exact
G6 full QA refs survive trace-tail truncation and corpse hashing
G7 ancestor evidence cannot advance descendant current state
G8 Packet/corpse never writes software_accepted
```

## 21. Explicit Deferrals

```text
multiple/optional checks and skipped records
raw diagnostic content ingestion
semantic repair diagnosis
provider retry or verdict supersession
QA source patching
external legacy differential testing
CLI/TUI rendering
default tree-route promotion
```

## 22. Crystall Thesis

```text
The supervisor reports what happened, ☶ admits that report into the body and ☱
judges only a complete exact set. A failed candidate is evidence about software;
a failed testing world is evidence about the hand.
```
