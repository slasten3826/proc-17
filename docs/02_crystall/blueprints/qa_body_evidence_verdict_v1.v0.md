# QA Body Evidence And Verdict v1 Blueprint

Status:

```text
layer: crystall (◈)
date: 2026-07-29
source table:
  docs/01_table/yellowprints/qa_body_evidence_verdict_v1_yellowprint.v0.md
gate record:
  docs/00_chaos/qa_body_transaction_table_cross_audit_2026-07-29.md
crystall audit:
  docs/00_chaos/qa_body_transaction_crystall_cross_audit_2026-07-29.md
depends on:
  docs/02_crystall/blueprints/qa_body_execution_after_qn20.v0.md
  docs/02_crystall/blueprints/qa_contract_profile.v0.md
  docs/02_crystall/blueprints/completion_scope.v0.md
companion crystall:
  docs/02_crystall/blueprints/qa_body_transaction_reconciliation.v0.md
implementation authority: yes; exact M2-M4 evidence slices only
software acceptance authority: forbidden; lineage remains sole owner
router/pressure promotion: forbidden
```

## 0. Crystallized Claim

Private execution becomes Packet truth only through two actor-owned body acts:

```text
☶ exact private receipt join
  -> one accepted/rejected qa.check.v0
  OR one qa.execution_failure.v0

☱ complete exact current check set
  -> one accepted/rejected qa.candidate_verdict.v0
```

Candidate failure is a successful observation. Infrastructure failure is not a
candidate verdict. Accepted and rejected candidates traverse the same phase
depth and both reach `▲` only after ☱ assembles a verdict.

## 1. Exact Implementation Surface

New modules:

```text
core/qa_evidence_schema.lua
runtime/qa_evidence.lua
runtime/qa_verdict.lua
```

Modify:

```text
runtime/qa_request.lua
runtime/qa_process.lua
core/packet.lua
runtime/body.lua
organs/logic.lua
organs/runtime.lua
runtime/completion_scope.lua
runtime/work_layer.lua
logic/manifest.lua
runtime/corpse.lua
runtime/carrier.lua
tests/test_qa_check_verdict.lua
tests/test_qa_contract.lua
```

`core/qa_evidence_schema.lua` is a pure exact-schema module. It owns no Packet,
registry, provider, handle or mutable record. `qa_request`, `qa_process`, the
body writers and the Packet append gate reuse its normalized subrecord
validators so finality/cause/cost is not implemented twice.

## 2. Dedicated Event Vocabulary

Add exactly:

```text
qa_check_request
qa_check
qa_execution_failure
qa_candidate_verdict
```

All four enter `packet.event_types` and `dedicated_event_types`. Actor rights:

```lua
qa_check_request = {['☶'] = true}
qa_check = {['☶'] = true}
qa_execution_failure = {['☶'] = true}
qa_candidate_verdict = {['☱'] = true}
```

No generic append path may write them.

## 3. Packet QA Append Gate

```lua
packet.append_qa_event(instance, event)
  -> detached_event | nil, err
```

The gate performs, in order:

```text
living/mutable Packet check
exact dedicated QA event type
actor right and current actor-tick lease
truth_status = runtime_confirmed
cost shape for that exact event type
core.qa_evidence_schema validation of payload
deep copy
same schema validation after copy
append
increment revisions.evidence exactly once
```

The gate derives neither ids nor body causality. Those belong to the sole body
writer. It rejects unknown keys, metatables, cycles and a payload whose id does
not equal the digest of every other normalized field.

## 4. Sole Body Writers

`runtime/body.lua` adds:

```lua
body.record_qa_request(instance, payload)
body.record_qa_check(instance, payload)
body.record_qa_execution_failure(instance, payload)
body.record_qa_candidate_verdict(instance, payload)
```

Each function:

```text
asserts its exact actor tick
normalizes and validates payload before copy
deep-copies
revalidates after copy
calls packet.append_qa_event
returns detached payload + event
```

The body writer supplies `operator`, event truth and event cost. The caller
cannot supply or override them. The Packet gate owns the evidence revision, so
the body writer does not increment it a second time.

## 5. Evidence API

```lua
local evidence = require("runtime.qa_evidence")

evidence.record_request(instance, prepared_request)
  -> detached_request, event | nil, err

evidence.commit_execution(instance, qa_registry, execution_receipt_id)
  -> detached_check_or_failure, event, effect_failure
  | nil, nil, nil, loud_err

evidence.current(instance, candidate_seal_id, qa_contract_id)
  -> detached_current_view | nil, reason

evidence.verify_request(instance, value)
evidence.verify_check(instance, value)
evidence.verify_failure(instance, value)
  -> true | nil, err
```

`current` returns one exact derived view:

```lua
{
  protocol_version = "qa.current_evidence.v0",
  candidate_seal_id = string,
  qa_contract_id = string,
  request = qa.check_request.v0 | nil,
  request_ref = string | nil,
  check = qa.check.v0 | nil,
  check_ref = string | nil,
  execution_failure = qa.execution_failure.v0 | nil,
  execution_failure_ref = string | nil,
  verdict = qa.candidate_verdict.v0 | nil,
  verdict_ref = string | nil,
  conflicts = string[],
}
```

This is derived from append-only trace plus exact current seal/contract. It is
not cached and is not a second mutable truth store.

## 6. Request Recording

`record_request` normalizes the supplied preparation and calls
`qa_request.verify` against the current Packet. That verification re-reads the
birth contract, current seal/event, current artifact alignment and exact
entrypoint evidence. The ordinary caller is `qa_execution`, which prepared the
request only after the detached measured environment passed current
eligibility.

Environment availability is deliberately not re-invented by this body writer:
mint resolves its exact private environment lease and begin revalidates that
lease before any authority transition.

Before append it requires:

```text
supplied request exactly equals rederived normalized request
no different request exists for current seal/check
same request event, if present, has exact payload and actor
```

Identical replay returns the existing event. A changed request under the same
current seal/check is loud. Recording costs `{}` and grants no process
authority by itself.

## 7. Strict Receipt Join

`commit_execution` accepts only:

```text
one living build Packet in current ☶ tick
one exact private QA registry object
one execution_receipt_id
```

It calls `qa_capability.with_receipt`; it never accepts a provider report,
provider error or detached receipt as evidence. Inside the callback it verifies:

```text
request event exists and still rederives from current Packet
receipt committed and names that exact request/event
stored result digest equals receipt.normalized_result_id
Packet/session/lineage/generation/process/context/stage/repository agree
seal/event/alignment/contract/check/profile/environment agree
candidate remains aligned
source acquisition/disposition agrees across result and receipt
transaction disposition agrees with result kind
no current conflicting outcome exists
```

Then and only then:

```text
candidate report -> append qa.check.v0
provider error -> append qa.execution_failure.v0 and return effect_failure
trusted contradiction -> quarantine attempt + loud error, no body record/death
```

Receipt commit therefore precedes body evidence, but receipt alone never
becomes Packet truth.

## 8. Exact Check Schema

`core.qa_evidence_schema.normalize_check` implements the TABLE
`qa.check.v0` without aliases. Required nested structures are the normalized
RUN v1 structures already used by `qa_process`:

```text
qa_termination_v1
qa_first_cause_v1
qa_finality_v1
qa_stream_measurement_v1
qa_resource_measurement_v1
qa_scratch_measurement_v1
qa_cost_v1
```

The eight finality fields are exactly:

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

All must be true. `cleanup="complete"`, v0 reports and provider-witness reports
are invalid compatibility inputs.

Check identity:

```text
qa_check_id = qa-check:<digest(all normalized fields except qa_check_id)>
```

Physical transaction/witness ids remain private and do not enter the check;
the receipt binds their normalized-result digest.

## 9. Candidate Outcome Predicate

Accepted iff all hold:

```text
private result outcome = accepted
reason = expected_exit
termination = exit 0
cause.kind = expected_exit
all eight finality fields true
source stable and consumed
measurements obey exact QA contract limits
no limit/policy witness contradicts success
```

Every other legal contained candidate result is rejected. Output text,
substrate language and semantic diagnosis have zero authority over this
predicate.

## 10. Exact Execution Failure

`core.qa_evidence_schema.normalize_failure` implements the TABLE
`qa.execution_failure.v0` exactly. It admits only the closed provider codes and
stages from the execution crystall.

For no source lease, the tuple is exactly:

```text
candidate_start_state = not_started
source_acquisition = not_acquired
source_stable = nil
source_disposition = not_acquired
cleanup_state = complete
launcher_reaped = complete
result_eof = complete
measured_cost = nil
transaction_disposition = consumed_failed
```

All acquired-source failures require terminal `consumed|quarantined` source
disposition. Impossible topology is loud and writes no event.

After append, `commit_execution` returns:

```lua
{
  source = "sandbox",
  code = "qa_" .. failure.code,
  retryability = failure.class == "ambiguous" and "terminal" or "unknown",
  source_refs = {failure.failure_id, failure_event.id, failure.request_ref},
  cost = admitted_budget_projection(failure.measured_cost),
  detail = detached_failure,
}
```

This enters the existing runner `effect_failure` path. The writer neither
charges nor kills directly.

## 11. Idempotence And Split Brain

```text
same request + same receipt/result + same body event
  -> return existing detached outcome; no append/process/cost

receipt + no body outcome
  -> loud split brain; no rerun

body outcome + no matching receipt
  -> loud split brain; no rerun

same request + different result
  -> quarantine attempt + loud

accepted and rejected outcomes for one request
  -> loud, never latest-wins

stale alignment/contract/environment
  -> no current append; old evidence remains history
```

## 12. Verdict API

```lua
local verdict = require("runtime.qa_verdict")

verdict.prepare(instance, qa_contract_id)
  -> detached_verdict | nil, diagnostic

verdict.commit(instance, prepared_verdict)
  -> detached_verdict, event | nil, err

verdict.current(instance, candidate_seal_id, qa_contract_id)
  -> detached_verdict, event | nil, reason

verdict.verify(instance, value)
  -> true | nil, err
```

Preparation is pure. It reads:

```text
verified birth QA contract
exact current sealed/aligned candidate
one exact complete required-check set
one current qa.check.v0
no current execution failure
no foreign/stale/conflicting check or verdict
```

Commit is legal only in ☱, rederives preparation and appends through the
dedicated body writer. It calls no provider, substrate or semantic model.

## 13. Exact Verdict Schema

`core.qa_evidence_schema.normalize_verdict` implements the TABLE
`qa.candidate_verdict.v0` exactly.

For v0, `required_checks=1` and:

```text
one accepted check -> accepted_checks=1, rejected_checks=0, verdict=accepted
one rejected check -> accepted_checks=0, rejected_checks=1, verdict=rejected
```

Zero checks is not ready. Multiple, foreign or conflicting checks are loud.
`runtime_cost` is copied evidence from the exact check and is never debited by
verdict assembly.

Verdict identity:

```text
verdict_id = qa-verdict:<digest(all normalized fields except verdict_id)>
```

## 14. Organ Integration

At ☶, `organs/logic.lua` recognizes only this explicit manually grown option:

```lua
logic = {
  qa_execution = {
    action = "execute_current_candidate",
  },
}
```

Its readiness calls `qa_execution.inspect`; its run calls
`qa_execution.execute`. The success payload is:

```lua
{
  mode = "qa_execution",
  outcome_kind = "check" | "execution_failure",
  request_id = string,
  evidence_id = string,
  effect_cost = admitted_budget_projection,
}
```

At ☱, `organs/runtime.lua` recognizes only this explicit manually grown option:

```lua
runtime = {
  qa_verdict = {
    action = "assemble_current_candidate_verdict",
    qa_contract_id = "qa-contract:<sha256>",
  },
}
```

It calls `qa_verdict.prepare/commit` and returns:

```lua
{
  mode = "qa_verdict",
  verdict_id = string,
  verdict = "accepted" | "rejected",
}
```

Verdict commit occurs before the existing ordinary runtime-camera
reconciliation in that ☱ tick. The camera then observes the newly appended
verdict together with any older pending frames. The returned ordinary runtime
payload adds `mode="qa_verdict"`, `verdict_id` and `verdict`; it does not skip
or duplicate the camera, tension or lower-observation path.

The ☶ QA branch does not call the generic validation recorder: request and
check/failure are already dedicated evidence events. On a check it returns
`instance, qa_execution_payload`; on infrastructure failure it returns
`nil, effect_failure` after the dedicated failure event exists.

No default readiness, pressure reader, route weight or automatic transition is
authorized. Actor-invalid direct calls remain red.

## 15. Completion And Work-Layer Readers

`completion_scope.inspect_build_packet` reads current QA evidence before
deriving candidate state:

```text
seal only                     -> sealed
check, no verdict             -> qa_check_observed
execution failure             -> qa_infrastructure_incomplete
accepted current verdict      -> qa_accepted
rejected current verdict      -> qa_rejected
conflict/unsupported          -> unsupported or loud by exact class
```

Boundary candidates:

```text
qa_accepted -> software_acceptance_ready
qa_rejected -> rejected_generation_recovery_ready
```

The Packet/corpse subject ceiling remains below `software_accepted`.

`work_layer` maps:

```text
sealed, no outcome          -> ⊞ checking / candidate_sealed_qa_missing
request/check, no verdict   -> ◈ crystallizing / qa_verdict_incomplete
accepted verdict            -> ▲ boundary / candidate_acceptance_ready
rejected verdict            -> ▲ boundary / rejected_generation_recovery_ready
execution failure           -> ⊞ checking / qa_infrastructure_incomplete
```

The readers are pure shadow projections and mutate no Packet.

## 16. Terminal Projection

`logic/manifest.lua` may add exactly one TABLE
`qa.terminal_projection.v1` block when an exact current verdict and its exact
check exist. It copies bounded normalized evidence and verifies every ref.

Rules:

```text
accepted and rejected projection have identical schema depth
△ cannot invent, repair or semantically reinterpret a check/verdict
rejected projection binds exact seal + verdict + check refs
no failure_crystal runtime object is created
execution failure cannot masquerade as rejected candidate projection
```

The projection is part of the manifest digest and terminal evidence.

## 17. Corpse Retention Outside Trace Tail

`runtime/corpse.lua` derives and freezes one TABLE
`corpse.qa_evidence.v1` envelope before hashing the corpse. It stores the exact
current request, check or execution failure, verdict and terminal projection
with event refs.

This envelope is independent of the 32-event `trace_tail`. More than 32 later
events therefore cannot erase the evidence used to classify a rejected
generation.

`runtime/carrier.lua` may expose the envelope only as bounded historical
evidence with inherited applicability. It cannot satisfy a descendant's
current request, check, contract or verdict reader.

## 18. Truth And Economics

```text
check                 runtime_confirmed under exact contract/environment
verdict               runtime_confirmed deterministic body classification
terminal projection   runtime_confirmed projection
ancestor applicability inherited proposal
semantic diagnosis    semantic_proposal, deferred
software_accepted     lineage-only, absent here
universal correctness absent
```

Event costs:

```text
qa_check_request      {}
qa_check              admitted external projection
qa_execution_failure  admitted incurred projection or {}
qa_candidate_verdict  {}
```

They are evidence only. The runner is the only debit writer.

## 19. Permanent Controls

```text
EV01 caller provider/witness table writes no body event
EV02 malformed event is loud and invents no death
EV03 accepted check preserves exact RUN v1 cause/finality
EV04 rejected check preserves exact RUN v1 cause/finality
EV05 provider error writes failure and no check
EV06 cleanup ambiguity never becomes rejected candidate
EV07 private/body coordinate mismatch advances nothing
EV08 receipt absent/contradictory is loud
EV09 alignment drift before append advances nothing
EV10 accepted/rejected check without verdict remains ◈
EV11 accepted/rejected verdict reaches ▲ symmetrically
EV12 conflicting check/verdict is loud
EV13 substrate wording creates no QA evidence
EV14 check append does not double-charge
EV15 verdict does not double-charge
EV16 Packet/corpse cannot claim software_accepted
EV17 QA evidence survives >32 later trace events
EV18 ancestor QA cannot satisfy descendant current readers
EV19 detached mutation changes no stored evidence
EV20 terminal rendering claims no universal correctness
EV21 source denial remains not_acquired through body evidence
```

## 20. Implementation Slices

```text
M2 strict event schemas, append gate, request/receipt join
   permitted verdict-battery greens:
     QV01-QV08 QV13-QV15 QV21-QV22

M3 deterministic verdict + completion/work-layer shadow readers
   permitted greens:
     QC15
     QV09-QV12 QV16-QV18 QV23-QV24

M4 terminal projection + corpse/descendant retention
   permitted greens:
     QV19 QV20
```

The integration crystall owns the total matrix and cross-layer fixtures.

## 21. Explicit Deferrals

```text
router/pressure promotion
automatic rejected-generation recovery
multiple checks/profiles
semantic failure diagnosis
lineage software acceptance
generic test command surface
CLI/TUI rendering policy
```

## 22. Blueprint Thesis

The provider can report what happened, but only the body can decide what that
report becomes inside one Packet. ☶ admits exact execution evidence; ☱
classifies the complete evidence set; △ only carries the already established
boundary through death.
