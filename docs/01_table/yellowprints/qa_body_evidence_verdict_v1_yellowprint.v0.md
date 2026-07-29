# QA Body Evidence And Verdict V1 Yellowprint v0

Status:

```text
layer: TABLE treatment
date: 2026-07-29
scope: Packet QA events, strict private join, verdict and terminal retention
source: docs/00_chaos/qa_body_transaction_after_qn20_notes_2026-07-29.md
amends:
  docs/01_table/yellowprints/qa_check_verdict_yellowprint.v0.md
runtime implementation authorized: no
router/pressure promotion authorized: no
crystallization authorized: yes; post-QN20 cross-table audit 2026-07-29
gate record: docs/00_chaos/qa_body_transaction_table_cross_audit_2026-07-29.md
```

## 0. Selected Decisions

```text
V01 Provider output, including witness v1, is never body evidence by itself.
V02 One dedicated ☶ writer joins request + private receipt + private result.
V03 Accepted and rejected contained runs both become qa.check.v0 first.
V04 Infrastructure failure becomes qa.execution_failure.v0, never a check.
V05 Trusted contradiction is loud, never an invented Packet death.
V06 Check and failure preserve full bounded RUN v1 causal evidence.
V07 No raw output, host authority or private correlation id enters Packet.
V08 One deterministic ☱ writer assembles the final candidate verdict.
V09 Check without verdict is ◈; exact verdict is ▲ for both outcomes.
V10 QA acceptance means exact contract satisfaction, not universal correctness.
V11 Event cost is evidence; the runner performs the only external-effect charge.
V12 QA execution and verdict create no identity loss by themselves.
V13 Manifest/corpse retain exact QA evidence outside trace_tail.
V14 Ancestor QA evidence is historical and cannot satisfy a descendant request.
V15 Packet/corpse may reach candidate verdict, never software_accepted.
V16 Source reservation denial is typed infrastructure evidence with
    source_disposition=not_acquired, never fabricated cleanup of a lease.
```

## 1. Evidence Boundary

The body admits exactly four dedicated event families:

```text
qa_check_request
qa_check
qa_execution_failure
qa_candidate_verdict
```

They are not aliases. Absence of one cannot be replaced by another.

```text
request             intent to consume one exact private QA authority
check               complete contained candidate observation
execution failure   inability to prove a complete trustworthy execution
candidate verdict   deterministic classification of the required check set
```

## 2. Actor Rights And Append Gate

Add all four types to `packet.event_types` and
`dedicated_event_types`. Rights are exact:

```lua
qa_check_request = {['☶'] = true}
qa_check = {['☶'] = true}
qa_execution_failure = {['☶'] = true}
qa_candidate_verdict = {['☱'] = true}
```

One separate gate exists:

```lua
packet.append_qa_event(instance, event)
```

It accepts only the four QA types, requires the current actor tick, checks
mutability/finality, dispatches the exact payload validator, deep-copies before
append and increments the existing `evidence` revision. Generic
`append_trace`, repository event writers and substrate output cannot write a
QA event.

`runtime/body.lua` supplies the only ordinary callers:

```lua
body.record_qa_request(instance, payload)
body.record_qa_check(instance, payload)
body.record_qa_execution_failure(instance, payload)
body.record_qa_candidate_verdict(instance, payload)
```

Each validates before and after copying. No caller supplies truth status or
actor.

## 3. Request Event

`qa_evidence.record_request(instance, prepared_request)`:

```text
re-derives qa_request.prepare from current Packet and host-free projections;
requires exact equality with supplied preparation;
finds and returns the existing exact event when already present;
rejects a different request for the same current seal/check;
appends one qa_check_request event at ☶ with cost={};
returns detached payload and event.
```

The event payload is the existing exact `qa.check_request.v0`. A request is
runtime-confirmed intent and coordinates, not proof that a process started.

## 4. Strict Private-To-Body Join

`qa_evidence.commit_execution` accepts only:

```text
living build Packet at ☶
private QA registry identity
exact execution_receipt_id
```

It does not accept a provider report/error table. The private registry exposes
the receipt and normalized result only through an opaque one-use/read-only join
operation.

Before append, the writer verifies:

```text
exact request event exists and re-derives from current Packet
receipt is committed and names that request/event
private normalized-result digest equals receipt.normalized_result_id
Packet/session/lineage/generation/process/context/stage/repository agree
seal/event/alignment/contract/check/profile/environment agree
candidate remains aligned
receipt disposition agrees with result kind and source disposition
receipt source acquisition/disposition agrees with the normalized result
no current outcome exists for this request
```

Results:

```text
candidate report -> qa.check.v0
provider error   -> qa.execution_failure.v0 + existing effect_failure return
contradiction    -> quarantine attempt + loud invariant, no body record/death
```

## 5. Exact QA Check v0

The first implemented `qa.check.v0` is precision-amended before birth. No
legacy payload exists.

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
  reason = contained_candidate_reason,
  termination = qa_termination_v1,
  cause = qa_first_cause_v1,
  finality = qa_finality_v1,
  source = {
    pre_inventory_id = string,
    post_inventory_id = string,
    stable = true,
    disposition = "consumed",
  },
  stdout = qa_stream_measurement_v1,
  stderr = qa_stream_measurement_v1,
  resources = qa_resource_measurement_v1,
  scratch = qa_scratch_measurement_v1,
  runtime_cost = qa_cost_v1,

  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed" | "mixed",
}
```

Every field except `qa_check_id` participates in identity. The private native
`physical_transaction_id` and `physical_witness_id` do not enter this record;
their normalized-result digest is already bound by the receipt.

## 6. Exact RUN V1 Finality In A Check

`qa_finality_v1` contains exactly eight true fields:

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

`qa_first_cause_v1` contains exactly:

```text
protocol_version
kind = exact reason
monotonic_sequence >= 1
observed_value >= 0
```

The body validator reuses the strict v1 process schema. It does not implement
a weaker second cause/finality validator.

The old conceptual `cleanup="complete"` field is removed. It is an invalid
compatibility input because it cannot prove the eight named facts.

## 7. Candidate Outcome Predicate

Accepted iff:

```text
private result outcome = accepted
reason = expected_exit
termination = exit 0
cause.kind = expected_exit
all eight finality fields = true
source stable and consumed
all measurements match the exact contract limits
no limit/policy witness contradicts success
```

Every other legal contained result is rejected. A rejected check remains a
successful observation of candidate failure.

Neither stdout text, stderr text, substrate summary nor semantic diagnosis can
change this predicate.

## 8. Exact Execution Failure v0

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
  code = closed_provider_error_code_v1,
  stage = closed_provider_error_stage_v1,
  candidate_start_state = "not_started" | "started" | "unknown",
  source_acquisition = "not_acquired" | "acquired",
  source_stable = true | false | nil,
  source_disposition = "not_acquired" | "consumed" | "quarantined",
  cleanup_state = "complete" | "incomplete" | "unknown",
  launcher_reaped = "complete" | "incomplete" | "unknown",
  result_eof = "complete" | "incomplete" | "unknown",
  measured_cost = qa_cost_v1 | nil,
  transaction_disposition = "consumed_failed" | "quarantined",

  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed",
}
```

The source-reservation-denial tuple is exact:

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
```

Here `complete` means the private registries proved that no native process or
owned source lease was created; it does not claim a candidate run completed.
All other execution failures require `source_acquisition=acquired` and a
terminal `consumed|quarantined` source disposition.

Every field except `failure_id` participates in identity. There is no
`outcome`, `qa_check_id` or verdict contribution.

After append, the evidence writer returns the existing typed effect failure:

```lua
{
  source = "sandbox",
  code = "qa_" .. failure.code,
  retryability = failure.class == "ambiguous" and "terminal" or "unknown",
  source_refs = {failure_id, failure_event_ref, request_ref},
  cost = admitted_budget_projection(failure.measured_cost),
  detail = detached_failure,
}
```

`measured_cost=nil` admits zero external-effect cost. The ordinary ☶ body tick
is still charged by the runner.

The runner owns charge and `death_cause=effect_failure`.

## 9. Loud Trusted Invariants

These write neither check nor execution failure:

```text
unknown protocol/key/code/stage
accepted result with nonzero exit or incomplete finality
reason/cause/termination contradiction
impossible tri-state topology
negative/non-finite/out-of-contract measurement
receipt/result digest disagreement
private/body coordinate disagreement
body outcome without receipt
receipt with contradictory body outcome
two outcomes for one request
wrong actor/tick/final state
```

The implementation attempts the named private quarantine/finality action and
then fails loudly. Broken trusted physics does not become an honest Packet
story.

## 10. Event Cost And Budget

Events contain admitted budget projections:

```text
qa_check_request      cost={}
qa_check              cost={tool_calls, test_runs, time_ms}
qa_execution_failure  cost=actual admitted incurred projection
qa_candidate_verdict  cost={}
```

The event cost is evidence, not a debit operation. `qa_execution` returns the
same projection as its external-effect payload. The runner charges it exactly
once. Event append, replay, verdict and later readers do not charge it again.

## 11. Verdict API

```lua
qa_verdict.prepare(instance, qa_contract_id)
  -> detached_verdict | nil, diagnostic

qa_verdict.commit(instance, prepared_verdict)
  -> detached_verdict, event | nil, err

qa_verdict.current(instance, candidate_seal_id, qa_contract_id)
  -> detached_verdict, event | nil, reason

qa_verdict.verify(instance, value)
  -> true | nil, err
```

Preparation is pure. Commit requires ☱ and re-derives all inputs. It calls no
provider or substrate.

Read set:

```text
verified birth QA contract
exact current sealed/aligned candidate
one exact complete required-check set
one current qa.check.v0
no execution failure for current request
no foreign/stale/conflicting check or verdict
```

## 12. Exact Candidate Verdict v0

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
  runtime_cost = qa_cost_v1,

  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed" | "mixed",
}
```

One accepted check yields accepted. One rejected check yields rejected. Zero
checks, execution failure or conflict is not-ready/loud according to its exact
class. `runtime_cost` is evidence aggregated from the check and is never
charged again.

## 13. Idempotence And History

```text
same request/receipt/result -> same body outcome, no append/cost
same complete current check set -> same verdict, no append/cost
same request with different result -> loud
accepted and rejected current verdict for one seal -> loud
detached return mutation -> stored event/private state unchanged
alignment/contract/environment change -> old evidence becomes history
```

There is no retry, amendment, supersession or latest-wins rule in v0.

## 14. Completion Scope

Packet candidate projection gains:

```text
state = unsealed
      | sealed
      | qa_check_observed
      | qa_infrastructure_incomplete
      | qa_accepted
      | qa_rejected
      | unsupported
```

| Evidence | Candidate state | Boundary candidate |
|---|---|---|
| seal, no outcome | `sealed` | none |
| accepted/rejected check, no verdict | `qa_check_observed` | none |
| execution failure | `qa_infrastructure_incomplete` | none |
| accepted verdict + aligned seal | `qa_accepted` | `software_acceptance_ready` |
| rejected verdict + aligned seal | `qa_rejected` | `rejected_generation_recovery_ready` |

Packet and corpse subject ceilings remain below `software_accepted`. Only a
verified lineage ledger may later claim that scope.

## 15. Work-Layer Projection

Build projection is symmetric:

| State | Glyph | Layer state | Reason |
|---|---|---|---|
| sealed, no request/outcome | `⊞` | checking | `candidate_sealed_qa_missing` |
| request or check, no verdict | `◈` | crystallizing | `qa_verdict_incomplete` |
| accepted verdict | `▲` | boundary | `candidate_acceptance_ready` |
| rejected verdict | `▲` | boundary | `rejected_generation_recovery_ready` |
| execution failure | `⊞` | checking | `qa_infrastructure_incomplete` |

Accepted does not receive a shorter route than rejected. `▲` means a complete
typed boundary, not success.

## 16. Terminal Projection

`logic/manifest.lua` may assemble one bounded block only from exact final
verdict plus its exact check:

```lua
qa_terminal_projection = {
  protocol_version = "qa.terminal_projection.v1",
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
  check_reason = contained_candidate_reason,
  termination = qa_termination_v1,
  cause = qa_first_cause_v1,
  finality = qa_finality_v1,
  source = bounded_source_projection,
  stdout = qa_stream_measurement_v1,
  stderr = qa_stream_measurement_v1,
  resources = qa_resource_measurement_v1,
  scratch = qa_scratch_measurement_v1,
  verdict_id = string,
  verdict_ref = string,
  verdict = "accepted" | "rejected",
  runtime_cost = qa_cost_v1,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed" | "mixed",
}
```

△ validates and projects body evidence. It cannot invent or amend it.

## 17. Corpse And Descendant Retention

`runtime/corpse.lua` freezes one bounded envelope independent of trace tail:

```lua
qa_evidence = {
  protocol_version = "corpse.qa_evidence.v1",
  qa_contract_id = string | nil,
  request_id = string | nil,
  request_ref = string | nil,
  check = detached_qa_check | nil,
  check_ref = string | nil,
  execution_failure = detached_qa_execution_failure | nil,
  execution_failure_ref = string | nil,
  verdict = detached_qa_candidate_verdict | nil,
  verdict_ref = string | nil,
  terminal_projection = detached_qa_terminal_projection | nil,
  source_refs = string[],
}
```

The corpse hash covers it. A carrier may expose the envelope only as bounded
historical evidence. It cannot satisfy a descendant's current request,
contract, check or verdict reader.

## 18. Truth Ceiling

```text
check result            runtime_confirmed under exact contract/environment
candidate verdict       runtime_confirmed deterministic body classification
terminal projection     runtime_confirmed projection of body evidence
ancestor applicability  inherited proposal only
semantic diagnosis      semantic_proposal, deferred
universal correctness   absent
software_accepted       lineage scope only, not Packet/corpse
```

## 19. Named Writers And Readers

| Record | Sole writer | First reader |
|---|---|---|
| request event | ☶ QA request writer | private grant mint |
| private receipt/result | QA registry | ☶ strict evidence join |
| `qa.check.v0` | ☶ strict check writer | ☱ verdict assembler |
| `qa.execution_failure.v0` | ☶ strict failure writer | runner effect-failure path |
| `qa.candidate_verdict.v0` | ☱ deterministic assembler | completion/work-layer/△ |
| terminal QA projection | △ manifest assembler | corpse/lineage/corpus |
| corpse QA envelope | corpse capturer | lineage historical reader |

## 20. Permanent Falsifiers

```text
EV01 caller provider/witness table writes no body event
EV02 malformed event is loud and does not kill Packet
EV03 accepted body check preserves exact v1 cause/finality
EV04 rejected body check preserves exact v1 cause/finality
EV05 provider error writes failure and no check
EV06 cleanup ambiguity never becomes rejected check
EV07 request/receipt/result coordinate mismatch advances nothing
EV08 private receipt absent or contradictory is loud
EV09 alignment drift before append advances nothing
EV10 accepted/rejected check without verdict remains ◈
EV11 exact accepted/rejected verdict becomes ▲ symmetrically
EV12 conflicting check/verdict is loud
EV13 substrate wording creates no check or verdict
EV14 check event records but does not double-charge execution cost
EV15 verdict does not double-charge execution cost
EV16 Packet/corpse cannot claim software_accepted
EV17 >32 later events cannot erase corpse QA evidence
EV18 ancestor QA cannot satisfy descendant current readers
EV19 detached mutation changes no stored/private evidence
EV20 terminal rendering never claims universal correctness
EV21 source reservation denial remains not_acquired through receipt and body
```

## 21. Exit Gate

This table may crystallize only after the cross-table audit proves:

```text
every body outcome comes through the private receipt join;
the v1 finality vocabulary exactly matches promoted process physics;
accepted and rejected have symmetric phase depth;
one runner charge owns execution economics;
terminal/corpse readers preserve evidence without granting current descendant
authority.
```
