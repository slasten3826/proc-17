# QA Body Execution After QN20 Yellowprint v0

Status:

```text
layer: TABLE treatment
date: 2026-07-29
scope: shared private candidate physics and request-causal body execution
source: docs/00_chaos/qa_body_transaction_after_qn20_notes_2026-07-29.md
amends:
  docs/01_table/yellowprints/qa_execution_capability_yellowprint.v0.md
runtime implementation authorized: no
router/pressure promotion authorized: no
crystallization authorized: yes; post-QN20 cross-table audit 2026-07-29
gate record: docs/00_chaos/qa_body_transaction_table_cross_audit_2026-07-29.md
```

## 0. Selected Decisions

```text
E01 QN16-QN20 physics is reused, never independently reimplemented.
E02 Provider-witness output has zero body authority, including v1 output.
E03 One shared private candidate engine serves two authority adapters.
E04 Provider-witness and body-execution source bindings remain distinct.
E05 A body source transaction is physically bound to one Packet request id.
E06 The QA grant becomes sticky before source reservation/provider entry.
E07 Source reservation is not falsely described as atomic with grant mint.
E08 One request can create at most one physical transaction and one receipt.
E09 Native RUN v1 ABI and environment identity do not rotate in this treatment.
E10 Native transaction_id/witness_id are physical correlation ids only.
E11 Full RUN v1 cause/finality reaches the private body result without loss.
E12 Source acquisition is resolved first; every acquired source is terminal
    before any adapter assembles a final object.
E13 The private receipt commits before any Packet outcome event.
E14 Split brain is loud and never repaired by rerunning candidate code.
E15 The runner is the sole Packet-budget writer for QA execution cost.
E16 Shared-engine extraction changes no QN16-QN20 result or residue vector.
E17 Mint retains an opaque measured-environment lease; begin revalidates it.
E18 A source lease that was never acquired is recorded as not_acquired, never
    rewritten as consumed or quarantined.
```

## 1. Treatment Boundary

This table does not replace the native supervisor, launcher, provider adapter,
repository source bridge or QN campaigns. It changes the ownership topology
above the already promoted physical transaction.

Before:

```text
qa_provider_witness
  owns source reservation + inventory + RUN + source finality
  -> provider witness report/error v1
  -> harness readers only
```

Selected treatment:

```text
provider-witness adapter ------+
                               +-> shared private candidate engine
body-execution adapter --------+   -> terminal private physical result
```

The engine owns physical execution. Each adapter owns its own authority
envelope and final protocol. The engine owns no Packet writer, verdict,
completion reader or route.

## 2. Shared Private Candidate Engine

The future implementation has one trusted module boundary conceptually named:

```text
runtime/qa_candidate_transaction.lua
```

It receives only:

```text
one opaque repository QA source lease already reserved for one transaction;
one immutable normalized physical plan;
one private source callback which yields the opaque handle together with the
exact root-bound repository inventory provider;
one private measured-environment dispatch callback which yields the exact QA
provider together with its exact measured projection.
```

It performs exactly:

```text
revalidate source/root identity
bounded pre-inventory
require pre == immutable candidate seal
one RUN v1 provider call
bounded post-inventory
require pre == post
terminal source disposition
return one private terminal result
```

The engine does not:

```text
derive a Packet request
mint or begin a QA grant
append a Packet event
commit a QA receipt
assemble a verdict
charge Packet or lineage budget
retry a process
interpret raw output semantically
```

The repository inventory provider cannot be supplied independently through
`host_services`. `repository_capability` already stores the exact provider
beside the retained QA source handle. Its private source callback yields both
to the engine for the duration of one attempted lease. Existing
provider-witness consumers may ignore the added callback argument, preserving
their public behavior.

Its terminal result is an untagged, ephemeral private join. It is neither a
durable protocol nor a body record. The calling adapter must consume it
immediately after source finality. It cannot be stored in Packet, trace,
manifest, corpse, carrier, grave or documentation corpus.

## 3. Two Authority Adapters

### 3.1 Provider-witness adapter

```text
transaction_kind = provider_witness
qa_request_id = absent
transaction identity = existing provider-witness source seed
final output = qa.provider_witness_report.v1 OR
               qa.provider_witness_error.v1
first reader = QN harness
body reader = forbidden
```

The adapter must remain behaviorally identical under ablation. Existing
provider-witness plans, reports, errors and tests remain valid.

### 3.2 Body-execution adapter

```text
transaction_kind = body_execution
qa_request_id = exact current qa.check_request.v0 id
transaction identity = body source seed in section 5
final output = private qa.provider_candidate_report.v1 OR
               private qa.provider_error.v1
first reader = private receipt commit
direct body reader = forbidden
```

The body adapter is reachable only with the private QA registry and one opaque
running execution lease. A caller-supplied request, report, receipt id or source
binding grants no execution authority.

## 4. Body QA Grant

Private grant state conceptually contains:

```lua
{
  protocol_version = "qa.execution_grant.v1",
  grant_id = "qa-grant:<sha256>",

  session_id = string,
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
  state = "active" | "running" | "completed"
    | "consumed_failed" | "quarantined",
  revision = positive_integer,
}
```

Every identity field participates in `grant_id`. Private environment and
repository registries remain weak-key authority references outside this
detached conceptual projection.

Mint requires:

```text
living build Packet at ☶
exact normalized request re-derived from current body
exact dedicated request event and event ref
exact current sealed/aligned candidate
birth-bound QA contract/check
available exact measured environment
no prior grant/transaction/receipt for this request
```

Mint launches nothing, reserves no source and charges nothing.

### 4.1 Measured-environment lease

Mint resolves and privately retains one opaque `qa.environment_lease.v0` for
the exact `environment_id` and profile. The detached grant exposes the
environment identity, not the lease, adapter or registry record.

Before changing `active` to `running`, begin calls a read-only environment
lease validator. It must prove:

```text
same private environment registry and record
same environment/profile identity
same measured record revision
record state = available
```

Failure leaves the grant active, launches nothing, reserves no source and
costs no external effect. The environment lease is a capability reference,
not a second execution ledger: running/consumed truth remains solely in the QA
grant transaction.

Immediately before native entry, the shared engine dereferences the same
opaque lease through a private environment callback and revalidates it. Drift
after sticky begin is an infrastructure failure. By that point the source
reservation is already attempted, so the engine must terminally dispose any
acquired source before assembling an error.

The body adapter cannot pass a provider separately from this callback. That
would permit one provider implementation to execute under another provider's
measured `environment_id`. The provider-witness adapter may wrap its existing
already-verified provider/projection pair in the same callback shape, but the
extraction must leave all QN evidence exact.

## 5. Physical Body Transaction Identity

`begin` atomically changes the private grant from `active` to `running` and
derives one physical source/process transaction identity from:

```lua
{
  protocol_version = "qa.body_source_transaction_seed.v0",
  transaction_kind = "body_execution",
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
  qa_request_id = string,
  inventory_id = string,
  inventory_digest = string,
  inventory_bounds = normalized_bounds,
}
```

The physical id remains:

```text
qa-provider-transaction:<sha256>
```

The `provider` word is retained solely because it is part of the promoted RUN
v1 native ABI. The seed's `transaction_kind` and `qa_request_id` determine
authority. The prefix cannot turn a body transaction into a provider-witness
transaction.

The repository source-binding validator must verify this digest independently
for `transaction_kind=body_execution`, just as it already verifies the
provider-witness branch. A non-empty arbitrary transaction id is insufficient.

## 6. Native Correlation Identity

RUN v1 requires:

```text
transaction_id = qa-provider-transaction:<sha256>
witness_id     = qa-provider-witness:<sha256>
```

For body execution, `witness_id` is derived from:

```lua
{
  protocol_version = "qa.body_physical_witness_seed.v0",
  transaction_id = physical_transaction_id,
  request_id = exact_request_id,
  profile_id = exact_profile_id,
  environment_id = exact_environment_id,
  entrypoint = exact_entrypoint_projection,
  resource_limits = exact_limits,
}
```

This is a physical request/result correlation id. It does not appear in the
Packet QA check, verdict or terminal projection. It grants no provider-witness
reader and does not rotate the native ABI or measured environment identity.

## 7. Grant And Source Ordering

Selected order:

```text
request event exists
  -> mint active QA grant
  -> begin sticky running transaction
  -> reserve body_execution source lease
  -> enter shared engine
```

This replaces the old prose claim that mint atomically reserves authority in
two independent registries.

Failure table:

| Point | QA grant | Source | Provider | Consequence |
|---|---|---|---|---|
| eligibility/mint denial | absent | untouched | not entered | not-ready, zero cost |
| begin denial | active/absent | untouched | not entered | no effect |
| source reservation denial | consumed_failed | not acquired; unchanged or pre-existing terminal | not entered | private failure, no retry |
| preflight mismatch | consumed_failed | consumed | not entered | provider error |
| provider unavailable after begin | consumed_failed or quarantined | terminal | not/partially entered | provider error |
| contained candidate result | completed | consumed | entered once | candidate report |
| source/cleanup ambiguity | quarantined | quarantined | entered at most once | provider error |
| trusted contradiction | quarantined | terminal attempt required | entered at most once | loud |

No row returns the grant or source to active/available.

`not_acquired` is a positive runtime fact from the repository registry: the
exact reserve operation denied before producing a lease and the provider-entry
counter remained unchanged. It is not an alias for `consumed`, `quarantined`
or an unknown cleanup state.

Only a closed expected registry denial after binding schema, digest and private
coordinates have all validated may become this typed outcome. Malformed
binding, transaction-digest disagreement, foreign private coordinates or an
impossible registry state are trusted-physics contradictions: quarantine is
attempted where meaningful, then the harness fails loudly with no body record.

## 8. Source Binding

The exact body binding remains
`repository.qa_source_binding.v1` and contains:

```text
transaction_kind = body_execution
qa_request_id = exact request id
closure_request_id = exact candidate-seal closure request
transaction_id = independently verified body source transaction id
all current session/lineage/generation/repository/root/closure/seal/inventory
coordinates
```

The binding contains no command, host path, fd, userdata, environment table,
private grant or Packet object.

The provider-witness branch must continue to reject `qa_request_id`. The body
branch must continue to require it. Neither branch may accept the other's
transaction identity seed.

## 9. Private Body Candidate Report v1

After a cleanly contained result and terminal consumed source, the body adapter
may assemble one private record:

```lua
{
  protocol_version = "qa.provider_candidate_report.v1",
  operation = "run_lua54_test_suite",
  request_id = string,
  physical_transaction_id = string,
  physical_witness_id = string,
  profile_id = string,
  environment_id = string,
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
  cost = qa_cost_v1,
  event_truth_status = "runtime_confirmed",
}
```

The report is private QA registry material. It cannot be passed as a caller
table to the body writer. Accepted requires `expected_exit` and exit 0. Every
other legal contained reason is rejected.

No v0 candidate report and no provider-witness report is a compatibility input.

## 10. Private Body Provider Error v1

After terminal source disposition, or after an exact reservation denial proves
that no source was acquired, an infrastructure outcome may assemble:

```lua
{
  protocol_version = "qa.provider_error.v1",
  request_id = string,
  physical_transaction_id = string,
  physical_witness_id = string,
  profile_id = string,
  environment_id = string,
  class = "unavailable" | "world" | "ambiguous",
  code = closed_provider_error_code,
  stage = closed_provider_error_stage,
  candidate_start_state = "not_started" | "started" | "unknown",
  source_acquisition = "not_acquired" | "acquired",
  source_stable = true | false | nil,
  source_disposition = "not_acquired" | "consumed" | "quarantined",
  cleanup_state = "complete" | "incomplete" | "unknown",
  launcher_reaped = "complete" | "incomplete" | "unknown",
  result_eof = "complete" | "incomplete" | "unknown",
  measured_cost = qa_cost_v1 | nil,
  event_truth_status = "runtime_confirmed",
}
```

The `not_acquired` tuple is closed:

```text
candidate_start_state = not_started
source_acquisition = not_acquired
source_disposition = not_acquired
source_stable = nil
cleanup_state = complete
launcher_reaped = complete
result_eof = complete
measured_cost = nil
```

It is legal only for a typed source-reservation denial after sticky begin and
with proof that native/provider entry did not occur. Every result after a
source lease exists uses `source_acquisition=acquired` and a terminal
`consumed|quarantined` disposition.

Unknown fields, impossible causal tuples or malformed trusted records are loud
and do not become this protocol.

## 11. Private Execution Receipt v1

The QA registry commits one receipt before body outcome append:

```lua
{
  protocol_version = "qa.execution_receipt.v1",
  execution_receipt_id = "qa-execution-receipt:<sha256>",

  request_id = string,
  request_ref = string,
  grant_id = string,
  physical_transaction_id = string,
  packet_id = string,
  lineage_id = string,
  generation = positive_integer,
  process_contract_id = string,
  context = "software_task.v0",
  stage_id = string,
  repository_id = string,
  candidate_seal_id = string,
  artifact_alignment_id = string,
  qa_contract_id = string,
  check_id = string,
  profile_id = string,
  environment_id = string,

  result_kind = "candidate_report" | "provider_error",
  source_acquisition = "not_acquired" | "acquired",
  source_disposition = "not_acquired" | "consumed" | "quarantined",
  normalized_result_id = "qa-provider-result:<sha256>",
  transaction_disposition = "completed" | "consumed_failed"
    | "quarantined",
  cost = qa_cost_v1 | nil,
  committed = true,
}
```

Every field except `execution_receipt_id` participates in identity. The private
registry retains the exact normalized result beside the receipt. Public lookup
returns only a detached receipt projection. The strict body join obtains the
result only through an opaque registry operation, never from caller input.

There is no v0 receipt alias because no v0 receipt was ever implemented.

## 12. Replay And Split Brain

```text
no transaction, no receipt, no body outcome
  -> request may begin once

running transaction
  -> no second begin or provider entry

receipt + exact matching body outcome
  -> return existing detached outcome, zero new event/process/cost

receipt + absent/different body outcome
  -> quarantine, loud, no rerun

body outcome + absent/different receipt
  -> loud, no rerun

same request + different result
  -> loud conflict, never latest-wins
```

## 13. Economics

Private v1 cost is projected to existing Packet budget axes exactly once:

```lua
{
  tool_calls = cost.tool_calls,
  test_runs = cost.qa_executions,
  time_ms = cost.wall_time_ms,
}
```

The private registry and provider never mutate Packet budget. The body event
records the measured cost as evidence but does not debit it. The runner charges
the projection once from the committed ☶ external-effect result. A normal body
tick still pays one step. Verdict assembly never charges the test again.

## 14. Named Writers And Readers

| Fact | Sole writer | First reader |
|---|---|---|
| request proposal | pure `qa_request` | ☶ request writer |
| request event | ☶ dedicated writer | QA grant mint |
| QA grant | private QA registry | transaction begin |
| physical transaction id | QA transaction begin | source binding/native correlation |
| body source lease | repository registry | shared engine |
| source not_acquired denial | repository registry | body adapter/receipt commit |
| ephemeral terminal physical result | shared engine | selected adapter |
| witness report/error v1 | witness adapter | QN harness |
| body report/error v1 | body adapter | receipt commit |
| execution receipt/result | QA registry | strict body evidence join |
| execution cost projection | body effect result | runner budget writer |

## 15. Permanent Falsifiers

```text
EX01 provider-witness report cannot commit body receipt
EX02 provider-witness binding rejects qa_request_id
EX03 body binding requires and digests qa_request_id
EX04 arbitrary body transaction_id is rejected by source bridge
EX05 body transaction cannot use provider-witness seed
EX06 grant mint requires exact request event but reserves no source
EX07 begin is sticky before source reservation
EX08 failed first source/provider attempt never restores grant
EX09 source reaches terminal disposition before final private result
EX10 request replay enters no second provider
EX11 receipt commits before body outcome
EX12 receipt/body split is loud and never reruns
EX13 v1 cause/finality survives private body normalization
EX14 native ABI/environment identity is unchanged
EX15 shared-engine extraction leaves all QN16-QN20 outputs exact
EX16 QA-disabled ablation has zero Packet/provider mass
EX17 external cost has one runner charge and no second event charge
EX18 detached grant/receipt/result mutation changes no private state
EX19 stale/quarantined measured-environment lease cannot begin a transaction
EX20 reserve denial records not_acquired and cannot invent source finality
EX21 provider cannot be substituted independently of measured environment
EX22 malformed/foreign reserve denial is loud, never normalized not_acquired
EX23 repository inventory provider is the exact root-bound private provider
```

## 16. Explicit Deferrals

```text
Packet check/failure/verdict schemas and readers
router/pressure promotion
multiple/optional profiles or checks
provider retry
raw diagnostics
generic command execution
cross-host or persistent transaction recovery
```

## 17. Exit Gate

This table may crystallize only after the post-QN20 cross-table audit confirms:

```text
the shared engine has no independent authority entrance;
body request identity physically reaches source and native correlation;
full v1 finality is available to the companion evidence table;
the receipt/body split law has one named reader;
economics has one writer;
QN16-QN20 remain unchanged under extraction.
```
