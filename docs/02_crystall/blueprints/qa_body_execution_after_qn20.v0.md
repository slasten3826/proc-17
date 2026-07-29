# QA Body Execution After QN20 Blueprint v0

Status:

```text
layer: crystall (◈)
date: 2026-07-29
source table:
  docs/01_table/yellowprints/qa_body_execution_after_qn20_yellowprint.v0.md
gate record:
  docs/00_chaos/qa_body_transaction_table_cross_audit_2026-07-29.md
crystall audit:
  docs/00_chaos/qa_body_transaction_crystall_cross_audit_2026-07-29.md
depends on:
  docs/02_crystall/blueprints/qa_provider_candidate_transaction.v0.md
  docs/02_crystall/blueprints/qa_contract_profile.v0.md
  docs/02_crystall/blueprints/candidate_seal_transaction.v0.md
companion crystall:
  docs/02_crystall/blueprints/qa_body_evidence_verdict_v1.v0.md
  docs/02_crystall/blueprints/qa_body_transaction_reconciliation.v0.md
implementation authority: yes; exact M1-M2 execution slices only
candidate process authority: existing native RUN v1 only
generic command authority: permanently forbidden
router/pressure promotion: forbidden
```

## 0. Crystallized Claim

The first-hand body transaction reuses the physical machine already proven by
QN16-QN20. It does not create a second launcher or a second interpretation of
candidate finality:

```text
one shared private candidate engine
  <- provider-witness adapter, harness authority only
  <- body-execution adapter, request/receipt authority only
```

The engine may touch a candidate only while it simultaneously holds:

```text
one exact root-bound repository source callback
one exact measured-environment provider callback
one normalized immutable RUN v1 plan
```

Neither provider is a caller-selected `host_services` value on the body path.

## 1. Exact Implementation Surface

New modules:

```text
runtime/qa_candidate_transaction.lua
runtime/qa_execution.lua
```

Complete existing closed foundation:

```text
runtime/qa_capability.lua
runtime/qa_environment.lua
```

Modify without changing public QN records:

```text
runtime/repository_capability.lua
runtime/qa_provider_witness.lua
organs/logic.lua
runtime/tension_runner.lua
tests/test_qa_execution.lua
tests/test_qa_provider_witness.lua
tests/test_qa_native_supervisor.lua
```

No change is authorized in:

```text
native RUN v1 ABI or launcher
native supervisor policy
qa.provider_witness_report.v1
qa.provider_witness_error.v1
provider-witness transaction/witness ids
candidate-seal closure identity
repository write grants
logic/spells.lua or any shell-command surface
```

## 2. Shared Candidate Engine API

```lua
local transaction = require("runtime.qa_candidate_transaction")

transaction.execute(repository_registry, source_lease, plan,
  with_environment)
  -> private_pending | nil, err
```

`plan` is the exact normalized internal record:

```lua
{
  protocol_version = "qa.candidate_transaction_plan.v0",
  transaction_kind = "provider_witness" | "body_execution",
  physical_transaction_id = "qa-provider-transaction:<sha256>",
  physical_witness_id = "qa-provider-witness:<sha256>",
  profile_id = "qa.profile.lua54_test_suite.v0",
  environment_id = "qa-environment:<sha256>",

  repository_id = string,
  root_authority_id = string,
  lifecycle_id = string,
  root_fingerprint = string,
  closure_id = string,
  closure_request_id = string,
  candidate_seal_id = string,
  candidate_seal_event_ref = string,
  inventory_id = string,
  inventory_digest = string,
  inventory_bounds = repository_inventory_bounds,

  native_request = qa.native_run_request.v1,
}
```

For `body_execution`, the adapter proves the request-causal source seed before
constructing this plan. For `provider_witness`, the existing witness seed is
used. The shared engine accepts neither seed and derives no authority id.

`with_environment` has one internal shape:

```lua
with_environment(function(exact_qa_provider, measured_environment)
  -> detached_pending_piece | nil, err
end)
```

It is called exactly once and only inside the repository source callback.
The engine verifies that `measured_environment.environment_id` and profile
equal the plan before calling `exact_qa_provider.run` once.

## 3. Exact Physical Order

The engine executes this order without retry:

```text
T01 validate plan and RUN v1 identity
T02 enter repository_capability.with_qa_source once
T03 receive exact opaque handle + exact root-bound inventory provider
T04 bounded pre-inventory through that provider
T05 prove root continuity and pre == immutable seal inventory
T06 enter measured-environment callback once
T07 revalidate exact provider/environment pair
T08 call exact QA provider RUN v1 once
T09 bounded post-inventory through the same repository provider/handle
T10 prove root continuity and post == pre
T11 derive consumed or quarantined source disposition
T12 leave both callbacks with detached pending data only
T13 finish source exactly once
T14 return one untagged private pending join
```

If a trusted contradiction occurs after source acquisition, T13 is attempted
before the contradiction is raised loudly. Cleanup failure is loud and cannot
be normalized into candidate rejection.

The engine never:

```text
reads or writes Packet
mints/begins/commits a body QA grant
appends a body event
assembles a verdict
charges a budget
stores the pending join
accepts a host path, fd, command, argv or environment map
```

## 4. Repository Callback Amendment

The exact private API becomes:

```lua
repository_capability.with_qa_source(registry, lease, consumer)
  -> detached_consumer_result | nil, err

consumer(exact_repository_handle, exact_root_bound_provider)
  -> detached_result | nil, err
```

The provider is the same object retained beside the handle at candidate-seal
commit. It is not resolved from `host_services`.

The callback detacher rejects recursively:

```text
the exact handle object
the exact provider object
userdata, functions, threads and metatable-bearing values
fd/descriptor/handle/host_path/repository_handle fields
cycles and non-string/non-integer keys
```

The extra provider argument is backward-compatible for existing consumers;
Lua callbacks may ignore it. After extraction, `qa_provider_witness` must use
it and must not use an independently supplied repository provider for
inventory.

Source lease and disposition protocols remain exactly the promoted v1/v0
protocols. No source handle or provider crosses the callback.

One new detached denial protocol is permitted only at the reservation edge:

```lua
{
  protocol_version = "repository.qa_source_reservation_denial.v0",
  denial_id = "repository-qa-source-denial:<sha256>",
  transaction_kind = "body_execution",
  transaction_id = "qa-provider-transaction:<sha256>",
  qa_request_id = "qa-check-request:<sha256>",
  session_id = string,
  lineage_id = string,
  generation = positive_integer,
  repository_id = string,
  root_authority_id = string,
  lifecycle_id = string,
  root_fingerprint = string,
  closure_id = string,
  closure_request_id = string,
  candidate_seal_id = string,
  candidate_seal_event_ref = string,
  inventory_id = string,
  inventory_digest = string,
  inventory_bounds = repository_inventory_bounds,
  code = "source_reservation_unavailable",
  source_acquisition = "not_acquired",
  source_lease_created = false,
  provider_entry_observed = false,
  event_truth_status = "runtime_confirmed",
}
```

Every field except `denial_id` participates in identity. The repository
registry may return it only after the binding schema, request-causal digest and
all private root/closure coordinates validate, but the exact source is already
reserved or terminal. It is not stored as a fourth ledger; the QA transaction
immediately consumes it into its private result and receipt.

## 5. Measured-Environment Callback Amendment

Add two read-only private operations:

```lua
qa_environment.validate_lease(registry, lease)
  -> detached_environment_projection | nil, diagnostic

qa_environment.with_environment(registry, lease, consumer)
  -> detached_consumer_result | nil, diagnostic_or_err
```

Both require:

```text
lease belongs to this registry
lease points to the same current record object
record revision equals retained lease revision
record state = available
environment/profile/provider/supervisor ABI equal retained projection
```

`with_environment` revalidates immediately before callback entry and yields
the exact native adapter stored in that record plus a detached measured
projection. Its output detacher rejects the adapter object, functions,
userdata, metatables and cycles.

These operations write no environment revision and no transaction state. The
environment registry remains a prerequisite witness, not a fourth execution
ledger.

## 6. Body QA Registry API

The exact trusted surface is:

```lua
local capability = require("runtime.qa_capability")

capability.new(session_id, environment_registry, repository_registry)
  -> registry | nil, err

capability.mint(registry, instance, request, request_ref)
  -> detached_grant | nil, diagnostic

capability.begin(registry, request_id, request_ref)
  -> private_execution_lease, detached_state | nil, diagnostic

capability.with_execution(registry, private_execution_lease, consumer)
  -> detached_consumer_result | nil, err

capability.commit(registry, private_execution_lease, normalized_result)
  -> detached_receipt | nil, err

capability.with_receipt(registry, execution_receipt_id, consumer)
  -> detached_consumer_result | nil, err

capability.quarantine(registry, private_execution_lease, reason)
  -> detached_state | nil, err

capability.find_receipt(registry, request_id)
  -> detached_receipt | nil, reason
```

`with_execution` yields only to trusted runtime code:

```text
detached exact grant coordinates
opaque environment lease
private environment registry reference
private repository registry reference
```

`with_receipt` yields the exact stored receipt and exact normalized private
result together. Both callbacks deep-detach their return and reject authority
leakage. The public lookup never exposes the normalized result.

## 7. Grant And Transaction State

The detached grant projection is exactly the TABLE
`qa.execution_grant.v1`. Private state additionally retains:

```text
exact environment registry + opaque environment lease
exact repository registry
current candidate closure/root coordinates
normalized request and exact request event ref
physical body source seed and ids after begin
private normalized result after execution
```

State machine:

```text
absent -> active       mint; no source/process/cost
active -> running      begin; sticky and atomic
running -> completed   candidate report committed
running -> consumed_failed  typed pre-entry/infrastructure error committed
running -> quarantined trusted ambiguity/contradiction
```

Forbidden:

```text
running -> active
terminal -> running
one request -> another request
one generation/seal/environment -> another
failed first attempt -> released authority
```

Mint resolves and stores the opaque environment lease. Begin first validates
that lease, then atomically stores `running`, revision and the request-causal
physical ids. A validation denial leaves `active`; every denial after the
running commit is terminal or loud.

## 8. Request-Causal Physical Identity

The body source transaction seed is copied exactly from TABLE section 5. Its
digest is verified independently by both `qa_capability` and the
`repository.qa_source_binding.v1` body branch.

Native ids remain:

```text
physical_transaction_id = qa-provider-transaction:<digest(body seed)>
physical_witness_id = qa-provider-witness:<digest(body physical witness seed)>
```

The native prefixes are ABI correlation domains only. The private grant,
source binding and receipt all carry `transaction_kind=body_execution` or the
exact body request id so a provider-witness seed cannot satisfy this path.

## 9. Body Source Reservation

After sticky begin, the body adapter derives the exact
`repository.qa_source_binding.v1` and calls `reserve_qa_source` once.

Only the exact `repository.qa_source_reservation_denial.v0` above, returned
before a lease exists, may become the exact
`source_acquisition=not_acquired` private provider error. It proves that this
transaction created no source lease, entered no provider and incurred no
external cost.

Generic capability diagnostics (`repository_root_missing`, candidate not
sealed, binding mismatch), malformed denial records, foreign registry state,
digest contradiction, missing private source or impossible trusted tuples are
loud. They are not converted into `not_acquired`.

## 10. Private Body Result Normalization

The body adapter consumes the shared pending join and constructs exactly one
of the TABLE schemas:

```text
qa.provider_candidate_report.v1
qa.provider_error.v1
```

The closed acquired-source error codes are:

```text
source_preflight_unavailable
source_preflight_mismatch
source_drift
supervisor_unavailable
source_staging_failed
supervisor_crashed
result_pipe_lost
terminal_frame_missing
reap_ambiguous
output_observation_incomplete
scratch_observation_incomplete
namespace_cleanup_incomplete
```

The only closed no-source code is:

```text
source_reservation_unavailable
```

The closed stages are:

```text
preflight source_staging namespace launch supervision postflight cleanup
```

The `not_acquired` result uses `source_reservation_unavailable`,
`class=unavailable`, `stage=preflight` and the exact tuple from TABLE section
10. No generic repository diagnostic, unknown provider code or impossible
topology is admitted.

Candidate report normalization reuses `qa_process` RUN v1 validators; it does
not duplicate cause, finality, measurement or error-topology validation.

## 11. Receipt Commit

`capability.commit` accepts only a running private lease and one normalized
private result returned by the body adapter. It verifies:

```text
all request/grant/physical/environment coordinates
terminal source disposition or exact not_acquired proof
result topology and result digest
transaction has no prior result/receipt
transaction disposition follows result kind
```

It stores the exact result privately, constructs the exact TABLE
`qa.execution_receipt.v1`, then returns a detached receipt. Receipt identity
contains every field except its own id.

Replay laws:

```text
same committed transaction/result -> same receipt, no process/cost
same request with a different result -> loud
running transaction -> no second begin or provider entry
receipt without exact body outcome -> split-brain loud, never rerun
```

## 12. Body Execution Adapter

```lua
local execution = require("runtime.qa_execution")

execution.inspect(instance, host_services)
  -> detached_readiness | nil, diagnostic

execution.execute(instance, host_services)
  -> detached_body_outcome
  | nil, effect_failure_or_loud_err
```

Required body host services:

```text
qa_enabled = true
qa_capabilities = exact private QA capability registry
qa_environment = detached exact measured projection for request derivation
```

The repository/environment registries and both providers are recovered only
through `qa_capabilities`; they are not independent body host-service inputs.

Exact orchestration:

```text
B01 inspect current sealed/aligned build candidate and exact birth contract
B02 prepare and append/reuse exact body request event
B03 replay-check body evidence and private receipt
B04 mint exact grant
B05 begin sticky transaction and revalidate environment lease
B06 reserve exact request-causal source
B07 if acquired, call shared engine with qa_environment callback
B08 normalize report/error after source finality
B09 commit private receipt
B10 strict evidence join appends check or execution failure
B11 return body outcome carrying one external-effect projection; never debit
    here, or return the typed effect failure as the second Lua value
```

`inspect` is pure and `qa_enabled=false` returns no readiness. Initial use is
manual/grown only; this blueprint does not add a pressure reader or route.

## 13. Provider-Witness Extraction

Refactor `qa_provider_witness.execute` to use the shared engine while keeping:

```text
prepare output exact
source/native ids exact
report/error tables exact
source disposition exact
Packet/public-root ablation exact
QN16-QN20 output and residue vectors exact
```

The witness adapter supplies an internal measured-environment callback around
its already verified provider/projection pair. It gains no QA body registry,
request, receipt, event writer or body reader.

## 14. Economics

`qa_execution.execute` returns the admitted projection:

```lua
{
  tool_calls = qa_cost.tool_calls,
  test_runs = qa_cost.qa_executions,
  time_ms = qa_cost.wall_time_ms,
}
```

The ☶ payload identifies `mode="qa_execution"` and carries that projection.
`tension_runner.apply_operator_physics` validates and debits it once with
`source="qa_execution"`. Request, check/failure append, receipt, verdict and
terminal readers never debit it.

On typed execution failure, the existing runner effect-failure path charges
the admitted incurred projection once and kills with `effect_failure`. A
pre-entry `not_acquired` error has no external projection; only the ordinary
body tick is charged.

## 15. Permanent Controls

```text
EX01 provider-witness report cannot commit body receipt
EX02 provider-witness binding rejects qa_request_id
EX03 body binding digests exact qa_request_id
EX04 arbitrary body transaction id is rejected
EX05 body transaction cannot use provider-witness seed
EX06 mint requires exact request event and reserves nothing
EX07 begin is sticky before source reservation
EX08 failed first attempt never restores grant
EX09 acquired source is terminal before private result
EX10 request replay enters no second provider
EX11 receipt commits before body outcome
EX12 receipt/body split is loud and never reruns
EX13 RUN v1 cause/finality survives normalization
EX14 native ABI and environment identity remain exact
EX15 shared extraction leaves QN16-QN20 output/residue exact
EX16 disabled QA has zero Packet/provider mass
EX17 runner is sole external-cost debit writer
EX18 detached mutation changes no private state
EX19 stale environment lease cannot begin
EX20 reserve denial remains not_acquired
EX21 QA provider cannot be substituted for measured environment
EX22 malformed reserve denial is loud
EX23 inventory provider is exact root-bound private provider
```

## 16. Implementation Slices

```text
M1 extract shared engine and dual-provider callbacks
   permitted QA matrix delta: none
   required: all QN output/residue exact

M2 complete grant/begin/body adapter/result/receipt/evidence handoff
   permitted execution greens:
     QE01 QE04 QE08-QE20
   permitted verdict greens owned by handoff:
     QV01-QV08 QV13-QV15 QV21-QV22
```

The integration blueprint owns the exact total matrix arithmetic and the
required grown fixtures.

## 17. Explicit Deferrals

```text
router/pressure promotion
automatic ☱->☶ routing
multiple checks or profiles
provider retry/resume
persistent transaction recovery
generic command execution
semantic diagnosis
lineage software acceptance
CLI/TUI acceptance workflow
```

## 18. Blueprint Thesis

The body does not become safer by copying the proven provider transaction. It
becomes safer by giving the same physical transaction a second, narrower
authority adapter whose request, source, environment, receipt and body event
must all name one causal execution.
