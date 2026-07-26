# QA Provider Candidate Transaction Yellowprint v0

Status:

```text
layer: table (candidate)
date: 2026-07-26
chapter: 8.5 second QA hand
roadmap slice: 8.5.5D provider physics
runtime implementation authorized: no
candidate execution through Packet body: forbidden
private execution receipt authorized: forbidden
qa_check / qa_execution_failure / qa_verdict authorized: forbidden
crystallization authorized: yes; D0 TABLE cross-audit 2026-07-26
gate record: docs/00_chaos/qa_first_candidate_table_cross_audit_2026-07-26.md
```

Primary CHAOS source:

[`../../00_chaos/second_qa_hand_first_candidate_transaction_notes_2026-07-26.md`](../../00_chaos/second_qa_hand_first_candidate_transaction_notes_2026-07-26.md)

Companion TABLE contracts:

```text
qa_detached_source_staging_yellowprint.v0.md
qa_execution_capability_yellowprint.v0.md
qa_contract_profile_yellowprint.v0.md
qa_check_verdict_yellowprint.v0.md
candidate_seal_transaction_yellowprint.v0.md
```

## 0. Selected Decisions

```text
PT01 D is a trusted provider witness, not a Packet QA execution
PT02 D grows a real disposable repository through the first hand and seals it
PT03 clean and rejected witnesses use different roots and one-use source leases
PT04 the only execution entry is qa_provider.run inside with_qa_source
PT05 no second witness helper or public command surface is introduced
PT06 pre/post source reads use repository_provider.inventory_tree exactly
PT07 inventory normalization is shared pure logic, not a second host reader
PT08 pre and post reproduce the seal inventory under its closure request and bounds
PT09 the source binding separates closure_request_id from future qa_request_id
PT10 repository.qa_source_binding.v1 replaces the ambiguous v0 key
PT11 D has transaction_kind=provider_witness and no qa_request_id
PT12 one atomic callback performs pre-inventory, one RUN and post-inventory
PT13 accepted means only exact expected exit in one measured environment
PT14 Lua load/runtime error is rejected/unexpected_exit, not provider corruption
PT15 empty stdout/stderr are valid and use the SHA-256 empty-stream digest
PT16 all provider witness reports require containment, reap, EOF, source stability and cleanup
PT17 infrastructure uncertainty never becomes candidate rejection
PT18 D report cost is observed but has zero Packet and lineage accounting authority
PT19 D creates no grant, private receipt, body event, pressure, readiness or verdict
PT20 D leaves Packet trace, budget, loss, revisions, status and death unchanged
PT21 root state remains sealed and source-write authority remains terminally closed
PT22 exact source lease replay starts no second supervisor
PT23 QN16 is the only red control authorized to become green in D
PT24 all other execution, verdict and tree controls remain red until their own slices
PT25 the native adapter writes process observation, never pre/post inventory fact
PT26 the D assembler alone joins process observation and source observations
PT27 D witness report/error protocols are distinct from future body provider protocols
PT28 no final witness escapes before the source lease has terminal disposition
```

## 1. Why D Exists

The future body transaction joins four authorities:

```text
body request
private execution grant/receipt
provider result
body check/failure event
```

Only the provider physics is ready. Creating a private receipt now would
deliberately produce:

```text
private receipt exists
body outcome event absent
```

That is the split-brain state the QA design forbids. D therefore stops one
boundary earlier. It proves that the exact provider can execute a sealed
candidate and return a detached report to a trusted test harness. It grants no
new fact to a living Packet.

## 2. Authority Ceiling

### Authorized in D

```text
trusted test harness
real first-hand repository creation
real candidate seal
real private repository QA source lease
real production repository inventory reader
real production QA provider/launcher/supervisor
detached provider witness report or witness error
external assertions over unchanged Packet and sealed root
```

### Forbidden in D

```text
qa_request.prepare/record
qa_capability.mint/begin/commit
qa.execution_grant.v0
qa.execution_receipt.v0
qa_check_request body event
qa_check body event
qa_execution_failure body event
qa.candidate_verdict.v0
completion/work-layer/pressure/tree consumption
Packet-triggered dispatch
```

Importability of `runtime/qa_provider.lua` is not authority. The production
entrypoint still requires the private repository userdata obtainable only
inside one consumed `with_qa_source` callback.

## 3. Identity Vocabulary Amendment

The current private source binding v0 uses `request_id` for the candidate-seal
closure request. The future QA body contract also owns a different
`qa.check_request.v0.request_id`. One field cannot honestly name both.

The v0 source binding is therefore superseded before D by:

```lua
{
  protocol_version = "repository.qa_source_binding.v1",
  transaction_kind = "provider_witness" | "body_execution",

  session_id = string,
  lineage_id = string,
  generation = positive_integer,
  repository_id = string,
  root_authority_id = string,
  lifecycle_id = string,
  root_fingerprint = string,
  closure_id = string,
  candidate_seal_id = string,
  candidate_seal_event_ref = string,

  closure_request_id = string,
  qa_request_id = string | nil,
  inventory_id = string,
  inventory_digest = string,
  inventory_bounds = repository_inventory_bounds,
  transaction_id = string,
  event_truth_status = "runtime_confirmed",
}
```

Mode law:

| `transaction_kind` | `closure_request_id` | `qa_request_id` | Legal caller |
|---|---|---|---|
| `provider_witness` | required and equal to sealed closure | absent | trusted D harness only |
| `body_execution` | required and equal to sealed closure | required and equal to body request | future QA capability registry only |

`transaction_id` is neither request id. It names consumption of one private
source lease. A failed first use remains sticky and never releases the source
for another transaction.

Private v0 source bindings are in-memory and non-persistent. No historical
record is rewritten; the implementation must reject v0 once D is promoted.

## 4. D Witness Record

The trusted harness derives one detached, command-free witness description:

```lua
{
  protocol_version = "qa.provider_witness.v0",
  witness_id = "qa-provider-witness:<sha256>",
  transaction_id = "qa-provider-transaction:<sha256>",

  session_id = string,
  packet_id = string,
  lineage_id = string,
  generation = positive_integer,
  process_contract_id = string,
  context = "software_task.v0",
  stage_id = string,
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

  profile_id = "qa.profile.lua54_test_suite.v0",
  environment_id = string,
  entrypoint = {
    relative_path = "tests/run.lua",
    bytes = non_negative_integer,
    sha256 = "sha256:<64-lower-hex>",
  },
  expected_exit_codes = {0},
  resource_limits = qa_resource_limits,
  event_truth_status = "runtime_confirmed",
}
```

Every field except `witness_id` and `transaction_id` participates in canonical
witness identity. The two ids use distinct tagged hashes of the exact witness
and transaction role; neither is random authority.

There is no command, executable, argv, environment, cwd, host path, mount
option, raw stdin or retry field.

The witness is test-owned evidence. It is never appended to Packet trace and
never accepted by the future body execution API.

## 5. Preconditions

D may reserve a source only when all are true:

```text
Packet is the exact living build generation that produced the seal
candidate seal body event verifies and is current
private candidate closure verifies and agrees with the body seal
root state is exactly sealed
source-write grant is terminally closed
entrypoint artifact exists in the seal with exact bytes and digest
environment was freshly probed under detached-source-staging policy
profile and resource limits equal the environment contract
source is unreserved
Packet snapshot was taken before source reservation
```

D does not require or synthesize a `qa.contract.v0` body binding. The fixed
profile coordinates are harness-owned for this physical experiment. The body
contract becomes mandatory in the future `body_execution` transaction.

## 6. One Inventory Reader

Inside the private source callback, both observations call exactly:

```lua
repository_provider.inventory_tree(repository_userdata, inventory_bounds)
```

No filesystem walk, `io.open`, shell command, native QA-side inventory or
candidate-supplied manifest may replace it.

The existing candidate-seal inventory normalizer is factored into a pure shared
component. That refactor may accept raw provider output plus exact sealed
coordinates, but it performs no host read and owns no authority. It must produce
the same normalized inventory as candidate seal for:

```text
same closure_request_id
same root_fingerprint
same inventory_bounds
same exact root and entries
```

Required D equality:

```text
pre.inventory_id     == seal.inventory_id     == closure.inventory_id
pre.inventory_digest == seal.inventory_digest == closure.inventory_digest
post.inventory_id    == pre.inventory_id
post.inventory_digest== pre.inventory_digest
pre.entries          == post.entries          == sealed exact inventory
```

Inventory provider cost is retained separately from candidate RUN cost. It is
not folded into the candidate's process measurements.

## 7. Native RUN Request

The strict Lua adapter derives the only native request:

```lua
{
  protocol_version = "qa.native_run_request.v0",
  operation = "run_lua54_test_suite",
  transaction_id = string,
  witness_id = string,
  profile_id = "qa.profile.lua54_test_suite.v0",
  environment_id = string,
  entrypoint_relative_path = "tests/run.lua",
  expected_exit_code = 0,
  resource_limits = qa_resource_limits,
}
```

The adapter rejects unknown keys and validates every value before entering the
native launcher. The launcher serializes a fixed RUN wire frame; the candidate
does not parse the request frame.

Only this call is legal:

```lua
qa_provider.run(repository_userdata, native_request)
```

and only while `repository_capability.with_qa_source` owns the callback. A
second helper that also accepts repository userdata would create another
execution surface and is forbidden.

The call returns one strictly normalized private process result:

```text
qa.provider_process_observation.v0
or
qa.provider_process_error.v0
```

These records contain only facts available by the time the native candidate
world has terminated and cleaned up. In particular, they cannot contain the
post-inventory id or claim whole-transaction source stability: the only legal
post-inventory is taken by D7 after this call returns. These are private
intermediate records, not the future body-facing
`qa.provider_candidate_report.v0` / `qa.provider_error.v0` protocols.

## 8. Exact D Transaction

| Phase | Operation | Failure consequence |
|---|---|---|
| D0 | grow one disposable repository through first hand | harness failure before QA |
| D1 | derive/verify candidate seal and witness | no source reservation |
| D2 | snapshot Packet and root projections | no authority change |
| D3 | reserve `repository.qa_source_binding.v1` | typed reservation failure; no run |
| D4 | enter one `with_qa_source` callback | source lease becomes sticky/attempted |
| D5 | take and normalize pre-inventory | mismatch: no run; consume/quarantine by certainty |
| D6 | call `qa_provider.run` exactly once | private process observation/error continues to D7 |
| D7 | take and normalize post-inventory | drift: no clean report; quarantine |
| D8 | validate process result with pre/post/identity into private pending join | impossible result: loud + quarantine |
| D9 | leave callback with pending join only | private userdata cannot escape |
| D10 | finish source lease once | consumed for definitive result; quarantined for ambiguity |
| D11 | assemble final witness report/error from pending join + terminal disposition | finish failure: no clean witness escapes |
| D12 | verify unchanged Packet and sealed root | any mutation rejects D implementation |
| D13 | assert one exact control delta | QN16 only becomes green |

Pre-inventory, RUN and post-inventory are one callback because the source lease
is intentionally one-use. Splitting them across callbacks would require replay
authority and create an unobserved interval between source checks.

The harness uses protected cleanup around D4-D10. A Lua assertion failure in
the harness does not silently abandon a used source handle.

## 9. Provider Witness Report

A fully contained D outcome is assembled only after D10 as:

```lua
{
  protocol_version = "qa.provider_witness_report.v0",
  operation = "run_lua54_test_suite",
  transaction_id = string,
  witness_id = string,
  profile_id = string,
  environment_id = string,

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
  cost = qa_cost,
  event_truth_status = "runtime_confirmed",
}
```

The strict native adapter writes the process observation. D8 creates only a
private pending join. The D transaction assembler is the sole writer of the
final witness report after D10 because only then it can join:

```text
verified witness and transaction identities
strict process observation
pre-inventory
post-inventory
repository source disposition
```

The pending join has no protocol identity, is never returned and cannot be
stored as success. If `finish_qa_source` fails or its resulting disposition
contradicts the pending classification, no witness report is emitted.

The report is test-owned and has no body reader. The protocol name is
deliberately distinct from the future `qa.provider_candidate_report.v0` so two
different schemas cannot masquerade under one version.

Raw source ids, mount ids, paths, fds, raw stdout/stderr and candidate-returned
Lua values are absent.

### 9.1 D-clean

Required exact classification:

```text
Lua text load succeeds
lua_pcall succeeds
candidate exits 0
source stable
all streams reach EOF
candidate and namespace init reaped
cleanup complete
no resource or sandbox bound reached

=> outcome=accepted
=> reason=expected_exit
=> termination.kind=exit
=> termination.exit_code=0
```

### 9.2 D-rejected

The fixed fixture raises one Lua load/runtime error. Required classification:

```text
candidate world was constructed correctly
Lua load or lua_pcall fails
candidate exits fixed nonzero status
source stable
reap/EOF/cleanup complete

=> outcome=rejected
=> reason=unexpected_exit
=> termination.kind=exit
=> termination.exit_code=exact nonzero status
```

This is candidate evidence. It is not `qa_check=rejected`, a failure crystal,
an infrastructure failure or Packet death.

## 10. Silent Stream Law

`bounded_stream_measurement` is exact:

```lua
{
  observed_bytes = non_negative_integer,
  sha256 = "sha256:<64-lower-hex>",
  limit_bytes = positive_integer,
  limit_reached = boolean,
}
```

For no output:

```text
observed_bytes = 0
sha256 = sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
limit_reached = false
```

The environment probe's non-empty output witness is probe-specific. RUN must
not inherit it. Empty output says nothing about success; exit/containment facts
decide the outcome.

## 11. Resource And Scratch Measurements

The exact native schema is selected in CRYSTALL, but TABLE requires one
canonical source for each projected quantity:

| Quantity | Native owner | Projection law |
|---|---|---|
| wall time | parent monotonic clock | non-negative elapsed duration |
| user/system CPU | kernel wait/rusage | non-negative measured duration |
| termination | wait state | one exact exit/signal/supervisor-kill form |
| stdout/stderr bytes+digest | parent bounded drain | exact observed stream |
| scratch bytes/entries | trusted final bounded inventory | exact final use |
| configured limits | environment/request join | must equal hard accepted limits |

No field may be estimated by the substrate. Missing measurement makes the
result an infrastructure error, not a partially clean report.

The clean and ordinary-error fixtures are expected to use zero scratch bytes
and entries. That expectation is a witness assertion, not a universal profile
law.

## 12. Provider Witness Error Boundary

A D transaction that cannot assemble a candidate witness report returns only:

```lua
{
  protocol_version = "qa.provider_witness_error.v0",
  transaction_id = string,
  witness_id = string,
  profile_id = string,
  environment_id = string,
  class = "unavailable" | "world" | "ambiguous",
  code = closed_error_code,
  stage = closed_error_stage,
  candidate_started = boolean,
  source_stable = true | false | nil,
  cleanup_complete = true | false | nil,
  cost = qa_cost,
  event_truth_status = "runtime_confirmed",
}
```

D adds the closed staging pair:

```text
code  = source_staging_failed
stage = source_staging
```

Classification:

| Condition | Result |
|---|---|
| malformed request/userdata/wire | trusted invariant, loud |
| pre-inventory differs from seal | provider world error; candidate not started |
| detached staging fails with proven cleanup | `world/source_staging_failed` |
| candidate Lua error with complete world | witness report `rejected/unexpected_exit` |
| post-inventory differs | `ambiguous/source_drift`; quarantine |
| reap/EOF/cleanup uncertain | ambiguous provider error; quarantine |
| impossible native report | trusted invariant, loud + quarantine |

`candidate_started=true` is forbidden for preflight/source-staging errors.
Candidate reports require `candidate_started=true` internally even though that
private field is normalized away from the final report.

`qa.provider_witness_error.v0` is assembled from the private process error,
source observations and lease disposition. It is not the future body-facing
`qa.provider_error.v0`; mapping the same physical failure into that protocol
requires an exact body request and private QA transaction, both absent in D.

## 13. Lease Disposition Without Receipt

The repository source lease still finishes exactly once:

```text
definitive witness report + source exact + cleanup complete
  -> repository source disposition = consumed

definitive clean witness error before candidate + cleanup complete
  -> repository source disposition = consumed

source drift, cleanup ambiguity or trusted result contradiction
  -> repository source disposition = quarantined
```

This is repository source-handle finality only. It is not
`qa.execution_receipt.v0` and does not satisfy future idempotent body replay.

No QA capability registry is created in D. The test-owned disposable root is
never used for a second witness.

## 14. Economics

The report carries measured provider cost:

```lua
qa_cost = {
  tool_calls = 1,
  qa_executions = 1,
  wall_time_ms = non_negative_number,
  cpu_time_ms = non_negative_number,
  scratch_written_bytes = non_negative_integer,
  stdout_observed_bytes = non_negative_integer,
  stderr_observed_bytes = non_negative_integer,
}
```

Projection law:

```text
wall_time_ms = deterministic projection of native monotonic duration
cpu_time_ms = deterministic projection of user + system CPU duration
scratch/stdout/stderr counts = exact measured counts
```

Pre/post repository inventory costs remain separate harness observations.

D does not charge:

```text
Packet budget
Packet loss
lineage budget
token budget
documentation budget
```

This zero-accounting rule does not claim execution is free. It says the writer
that may book QA cost into lineage economics has not been introduced yet.

## 15. Packet And Root Ablation

Before source reservation, the harness snapshots at minimum:

```text
Packet status/death/residue
trace length and canonical trace content
budget state
loss/tension state
field revisions and contents
current operator and tick counters
current candidate seal projection
repository root projection
```

After D, required equality is:

```text
Packet snapshot before == Packet snapshot after
```

The only permitted repository differences are private source-lease lifecycle
and handle closure for the disposable root. Public root projection remains:

```text
state = sealed
same root authority/lifecycle/closure/inventory
source-write authority closed
```

No body observer may detect D as a new event.

## 16. Named Writers And Readers

| Fact | Writer | First reader | Authority ceiling in D |
|---|---|---|---|
| candidate seal/closure | existing body + repository registry | witness derivation/source resolver | unchanged |
| provider witness | trusted D harness | D schema validator | no body authority |
| source binding v1 | trusted D harness | repository source resolver | one private source lease |
| pre/post raw inventory | production repository provider | shared pure inventory normalizer | no Packet event |
| native RUN request | strict QA adapter | launcher/supervisor | one fixed profile only |
| native staging/process facts | kernel + supervisor | launcher/strict adapter | private physics |
| private process observation/error | strict adapter | D transaction assembler | no source-stability or body authority |
| witness report/error | D transaction assembler | D harness assertions | detached runtime evidence only |
| repository source disposition | repository registry | cleanup/replay assertions | source finality only |
| D cost | supervisor/strict adapter | D harness | observation only |

Deliberately absent writers:

```text
qa_check_request writer
QA execution receipt writer
qa_check / qa_execution_failure writer
qa_verdict writer
completion/work-layer/tree reader
```

## 17. Expected Red/Green Delta

Input matrix after step C:

```text
39 green / 45 red
native supervisor: 15 green / 5 red
```

D authorizes exactly:

```text
QN16 clean and nonzero fixtures classify exactly: red -> green
```

Expected output matrix:

```text
40 green / 44 red
native supervisor: 16 green / 4 red
```

Remain red:

```text
QN17-QN20 hostile/fault/leak execution classifications
QE08-QE20 private QA grant/receipt/body execution chain
all qa_check, qa_verdict, completion and tree promotion controls
```

Any additional green control is authority leakage or accidental overclaim.

## 18. Permanent Controls

| ID | Falsifier | Required result |
|---|---|---|
| PT-T01 | grow clean real sealed root | exact seal/closure/root agreement |
| PT-T02 | grow nonzero real sealed root | separate root and source lease |
| PT-T03 | source binding uses ambiguous `request_id` v0 | schema rejection |
| PT-T04 | provider witness supplies `qa_request_id` | schema rejection |
| PT-T05 | body execution omits `qa_request_id` in future mode | schema rejection |
| PT-T06 | pre-inventory differs from seal | no native RUN |
| PT-T07 | alternate filesystem inventory reader appears | non-conforming implementation |
| PT-T08 | source lease callback invoked twice | no second callback/process |
| PT-T09 | qa_provider.run called outside source callback | no private userdata authority |
| PT-T10 | clean silent fixture | accepted/expected_exit with empty digests |
| PT-T11 | Lua load/runtime error | rejected/unexpected_exit |
| PT-T12 | `return false` without Lua error | expected exit; return value ignored |
| PT-T13 | post-inventory drift | no witness report; quarantine |
| PT-T14 | incomplete reap/EOF/cleanup | no witness report; quarantine |
| PT-T15 | provider returns raw output/path/fd/mount id | strict rejection |
| PT-T16 | provider result names foreign witness/transaction/environment | strict rejection + quarantine |
| PT-T17 | D calls qa_capability or body writer | control failure |
| PT-T18 | D changes Packet trace/budget/loss/revisions | control failure |
| PT-T19 | D reopens source-write authority | control failure |
| PT-T20 | D creates private execution receipt | split-brain prevention failure |
| PT-T21 | QN16 turns green | required D delta |
| PT-T22 | any other expected-red control turns green | D rejected |
| PT-T23 | source finish fails after clean process observation | no final witness report; quarantine/loud |

Both PT-T10 and PT-T11 execute fixture bytes only inside the production native
supervisor. The ordinary Lua test runner never loads those fixture files.

## 19. Cross-Contract Consequences

### Repository source bridge

`repository.qa_source_binding.v0` is replaced by v1 to distinguish:

```text
candidate-seal closure request identity
future QA body request identity
private source-consumption transaction identity
```

This is vocabulary repair, not a second authority registry.

### QA execution capability

The existing full body transaction remains the target for later 8.5.6. D is a
strict pre-body exception:

```text
provider witness report may exist in trusted harness
private QA execution receipt may not exist
body QA evidence may not exist
```

### QA check/verdict

No change. Provider `accepted/rejected` is still not a body check or final
verdict. The check/verdict table has no new reader in D.

### Candidate seal

The seal remains terminal and current. D reads it; D cannot mutate, replace or
reopen it.

## 20. Resolved CHAOS Questions

```text
Q3 expose only qa_provider.run inside the existing private source callback;
   no narrower duplicate helper and no Packet caller

Q4 repository_provider.inventory_tree is the sole pre/post host reader;
   inventory normalization is shared pure logic

Q5 clean empty streams require complete witness report identity,
   expected exit, source stability, termination, empty-stream count/digest,
   bounded resources/scratch, cleanup and measured cost

Q6 provider cost comes from supervisor clocks/wait/stream/scratch measurements;
   D observes it but no Packet or lineage writer books it
```

## 21. Explicit Deferrals

```text
signal/timeout/memory/output/scratch/seccomp green claims (step E)
trusted crash and repeated leak green claims (step E)
body request/grant/receipt/check/failure transaction (8.5.6)
verdict assembly and completion/work-layer promotion
generic commands or executable selection
raw diagnostic output retention
retry or resume
parallel or multiple checks
repository cleanup/compost
```

## 22. Required CRYSTALL Outputs

After TABLE cross-audit, CRYSTALL must specify without policy invention:

```text
repository.qa_source_binding.v1 exact validator and migration
shared pure inventory normalizer extraction
qa.native_run_request.v0 exact Lua and wire schemas
RUN result/error frame schemas
strict provider report/resource/scratch/cost normalizers
D-only witness report/error assembler and protocol separation
D harness transaction and protected source disposition
Packet/root ablation snapshots
QN16-only control delta
```

## 23. Table Thesis

```text
D lets the provider know what happened without yet letting the Packet know.
That temporary ignorance is not missing integration; it is the boundary that
prevents physical execution evidence from inventing body truth before its
writer exists.
```
