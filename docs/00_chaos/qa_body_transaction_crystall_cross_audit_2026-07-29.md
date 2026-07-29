# QA Body Transaction Crystall Cross-Audit - 2026-07-29

Status:

```text
layer: CHAOS audit residue
truth status: document_decision backed by source/runtime inspection
scope: post-QN20 QA body execution, evidence, verdict and retention crystall
audited:
  docs/02_crystall/blueprints/qa_body_execution_after_qn20.v0.md
  docs/02_crystall/blueprints/qa_body_evidence_verdict_v1.v0.md
  docs/02_crystall/blueprints/qa_body_transaction_reconciliation.v0.md
source tables:
  docs/01_table/yellowprints/qa_body_execution_after_qn20_yellowprint.v0.md
  docs/01_table/yellowprints/qa_body_evidence_verdict_v1_yellowprint.v0.md
  docs/01_table/yellowprints/qa_body_transaction_reconciliation_yellowprint.v0.md
result: crystall gate satisfied after the precision amendments below
runtime code changed by this round: no
```

## 0. Question

Can the three TABLE treatments now be implemented without inventing:

```text
a second physical QA engine
a caller-selected provider
a weaker candidate-finality schema
a fake cross-registry atomic transaction
a Packet writer for provider-witness evidence
a second budget writer
a router promotion
a lineage-level software acceptance claim
```

After the amendments recorded below, yes.

## 1. Inspected Runtime Boundaries

The audit checked the blueprints against the current implementation:

```text
runtime/qa_process.lua
  exact RUN v1 observation/error/finality/error topology

runtime/qa_provider_witness.lua
  current duplicated physical pre/RUN/post transaction

runtime/repository_capability.lua
  retained root-bound provider + source handle
  one-use source lease and terminal disposition

runtime/qa_environment.lua
  opaque lease exists; validation/callback readers do not yet exist

runtime/qa_capability.lua
  foundation registry exists; mint/begin/commit remain intentionally closed

runtime/qa_request.lua and runtime/qa_contract.lua
  current request/birth/seal/alignment verification

core/packet.lua and runtime/body.lua
  actor gates and dedicated repository-writer precedent

organs/logic.lua, organs/runtime.lua, runtime/operator_registry.lua
  current actor option shapes and effect-failure boundary

runtime/tension_runner.lua
  runner-owned body/effect budget debits

tests/red_qa_hand.lua and QA control catalog
  exact 84-control surface and current 44/40 baseline
```

No implementation was inferred from module names alone.

## 2. Finding A - Generic Reservation Error Could Not Prove Not-Acquired

Class:

```text
evidence underspecification / high before implementation
```

The first crystall draft allowed a generic
`repository.capability_diagnostic.v0` to become the body
`source_acquisition=not_acquired` fact. That diagnostic does not bind the exact
body transaction, request, root, closure and seal, and therefore cannot prove
that this transaction created no source lease or provider entry.

Disposition applied:

```text
new exact detached repository.qa_source_reservation_denial.v0
all body/root/request coordinates and denial id are digest-bound
source_lease_created=false and provider_entry_observed=false are explicit
only the repository registry may produce it after full private validation
generic/malformed/foreign diagnostics stay loud
body normalizes it to source_reservation_unavailable only
the QA registry immediately consumes it into result + receipt
no fourth persistent ledger is introduced
```

This makes `not_acquired` positive evidence instead of an interpretation of an
error string.

## 3. Finding B - Request Writer Was Asked To Re-Probe A Private World

Class:

```text
reader ownership ambiguity / medium before implementation
```

The first evidence crystall wording said `record_request` re-ran
`qa_request.prepare`, but its API receives only Packet + prepared request and
must not receive a native provider or private environment record.

Disposition applied:

```text
qa_execution.prepare/inspect proves current measured-environment eligibility
record_request normalizes and calls qa_request.verify
qa_request.verify re-reads birth contract, seal/event, alignment and artifact
mint resolves the exact opaque environment lease
begin revalidates that private lease before becoming running
shared engine revalidates it again immediately before native entry
```

Each reader now proves only facts it owns.

## 4. Finding C - Manual Corpus Inputs Were Not Named

Class:

```text
integration underspecification / medium before implementation
```

“Explicit manually grown option” was not enough for code. Two implementations
could choose different option surfaces and both claim compliance.

Disposition applied:

```text
☶ logic.qa_execution.action = execute_current_candidate
☱ runtime.qa_verdict.action = assemble_current_candidate_verdict
```

These are actor-valid corpus entrances only. They do not add readiness to the
default router, pressure, weights or promotion policy.

## 5. Finding D - Verdict Must Not Turn Off The Runtime Camera

Class:

```text
organ-semantics ambiguity / medium before implementation
```

The first crystall could be read as an early-return verdict branch in ☱. That
would make RUNTIME cease being a camera exactly on verdict ticks, unlike its
existing repository and plan-completion branches.

Disposition applied:

```text
qa_verdict commit occurs before ordinary reconciliation
the existing camera/tension/lower-observation path still executes once
the camera can observe the newly appended verdict in the same ☱ tick
the final runtime payload adds qa_verdict mode/ids only
no duplicate camera or second verdict is permitted
```

The dedicated ☶ QA branch is different: it does not emit a generic validation
event because request/check/failure already have dedicated writers.

## 6. Physical-Engine Audit

The final execution crystall has one lower machine:

```text
root-bound source callback
  + measured-environment provider callback
  + immutable RUN v1 plan
  -> pre == seal -> RUN once -> post == pre -> terminal source
```

Provider binding is exact:

```text
repository provider comes from the same private root record as the handle
QA provider comes from the same private environment record as environment_id
neither provider is an independent body host-service value
callback detachers reject provider/handle/function/userdata leakage
```

The provider-witness adapter keeps its harness-only report/error protocols and
gains no body reader. Shared physics does not imply shared applicability.

## 7. Identity Audit

The chain is consistent across all three crystall documents:

```text
qa_contract_id
  -> request_id + request_ref
  -> grant_id
  -> request-causal qa-provider-transaction:<sha256>
  -> qa-provider-witness:<sha256> physical correlation
  -> source disposition or signed not-acquired denial
  -> normalized_result_id
  -> qa-execution-receipt:<sha256>
  -> qa-check:<sha256> OR qa-execution-failure:<sha256>
  -> qa-verdict:<sha256>
  -> terminal projection
  -> corpse hash
```

Physical correlation ids stop at the private receipt. Packet evidence keeps
their result digest binding but does not expose those ids as body authority.

## 8. RUN V1 Evidence Audit

No weaker cleanup alias survives. A check preserves:

```text
termination
first cause
all eight finality booleans
pre/post source inventory identity
bounded stdout/stderr measurements
resource measurements
scratch measurements
measured QA cost
```

The accepted predicate is deterministic. Every other legal contained result is
rejected. Infrastructure topology uses the exact closed RUN v1 error set plus:

```text
source_reservation_unavailable
source_preflight_unavailable
source_preflight_mismatch
source_drift
```

Trusted malformed topology remains loud and writes no honest Packet death.

## 9. Event And Actor Audit

Rights are non-overlapping:

```text
☶ qa_check_request
☶ qa_check
☶ qa_execution_failure
☱ qa_candidate_verdict
```

All are dedicated event types. Generic trace/repository/substrate writers
cannot append them. The Packet gate owns exactly one evidence revision bump;
body wrappers do not duplicate it.

Receipt precedes body outcome. Check/failure precedes verdict/runner.
Verdict precedes terminal projection. Corpse captures the complete QA envelope
outside `trace_tail`.

## 10. Candidate/Infrastructure Audit

The protocols remain disjoint:

```text
contained candidate failure -> rejected check -> rejected verdict -> ▲
incomplete execution world  -> execution failure -> effect_failure death
trusted physics contradiction -> loud harness failure, no invented mortality
```

Accepted and rejected candidates have equal phase depth. `▲` means a complete
typed generation boundary, not universal correctness or lineage acceptance.

## 11. Economics Audit

One measured execution projection is copied through provider, receipt and body
evidence. Only `tension_runner` debits it:

```text
successful accepted/rejected execution -> qa_execution payload -> one debit
typed execution failure -> effect_failure payload -> one debit
not_acquired -> nil external cost -> ordinary ☶ body tick only
check/verdict/manifest/corpse/replay -> zero additional debit
```

QA mechanics add no identity loss.

## 12. Red-Matrix Audit

Current exact control surface:

```text
84 total
44 green / 40 red / 0 skip
```

Authorized deltas:

```text
M1 shared engine extraction       +0  -> 44 / 40
M2 execution + strict join       +28  -> 72 / 12
M3 verdict + shadow readers      +10  -> 82 / 2
M4 corpse/descendant retention    +2  -> 84 / 0
```

Arithmetic:

```text
M2 = 15 QE + 13 QV
M3 = 1 QC + 9 QV
M4 = 2 QV
15 + 13 + 1 + 9 + 2 = 40
```

Each control has a named owning slice. No terminal control may green in M2 and
no corpse control may green in M3.

## 13. Supersession Decision

After this audit:

```text
qa_body_execution_after_qn20.v0
  supersedes the body-execution portions of qa_execution_capability.v0

qa_body_evidence_verdict_v1.v0
  supersedes qa_check_verdict.v0 schemas/readers before their first runtime
  implementation

qa_provider_candidate_transaction.v0
  remains authoritative for promoted provider-witness/native physics, but its
  physical pre/RUN/post block is extracted into the shared engine with exact
  public output/residue preservation
```

Old documents remain archaeology and must receive explicit banners. They are
not deleted or silently edited into a false history.

## 14. Authorized Implementation Surface

The cross-audit authorizes only the four exact slices in
`qa_body_transaction_reconciliation.v0.md`:

```text
M1 shared engine extraction
M2 body execution and strict outcome join
M3 deterministic verdict and shadow readers
M4 terminal/corpse historical retention
```

Still forbidden:

```text
router/pressure promotion
automatic rejected-generation recovery
lineage software_accepted
multiple checks/profiles
provider retry/persistent resume
semantic diagnosis
generic command execution
CLI/TUI acceptance policy
public signature/admission policy
```

## 15. Audit Verdict

```text
crystall consistency: satisfied after Findings A-D amendments
named writers/readers: closed
provider substitution: closed by paired private callbacks
not_acquired evidence: closed by signed repository denial
RUN v1 finality preservation: closed
economics writer count: one
red-matrix ownership: exact
implementation authority: granted for M1-M4 only
router/lineage promotion authority: not granted
```

The next action is implementation slice M1, preceded by replacement of any
remaining placeholder controls with exact falsifiers while preserving the
44/40 baseline.
