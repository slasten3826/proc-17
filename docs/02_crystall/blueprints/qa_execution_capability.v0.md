# QA Execution Capability Blueprint v0

PARTIALLY SUPERSEDED 2026-07-29 by:

```text
docs/02_crystall/blueprints/qa_body_execution_after_qn20.v0.md
docs/02_crystall/blueprints/qa_body_transaction_reconciliation.v0.md
```

QN16-QN20 promoted the physical candidate transaction after this blueprint was
written. Do not implement sections 3-18 as an independent body-specific
physical engine. Keep this document as architecture history and use the
post-QN20 crystall for grant ordering, paired private providers, RUN v1
finality, signed not-acquired evidence, receipt and implementation slices.

Status:

```text
layer: crystall (◈)
date: 2026-07-23
source table:
  docs/01_table/yellowprints/qa_execution_capability_yellowprint.v0.md
gate record:
  docs/00_chaos/qa_table_cross_audit_2026-07-23.md
crystall audit:
  docs/00_chaos/qa_crystall_cross_audit_2026-07-23.md
depends on:
  docs/02_crystall/blueprints/qa_contract_profile.v0.md
  docs/02_crystall/blueprints/qa_native_supervisor.v0.md
  docs/02_crystall/blueprints/candidate_seal_transaction.v0.md
implementation authority: private registries, request/source transactions and
  strict adapter only after the hostile-red battery exists
candidate process authority: forbidden until step 8.5.5 promotion gate
generic command authority: permanently forbidden
router/pressure promotion: forbidden
amended 2026-07-26: source binding v1 separates closure, QA request and
  transaction identity; provider-witness D remains outside body transaction
amendment gate:
  docs/00_chaos/qa_first_candidate_table_cross_audit_2026-07-26.md
amendment crystall audit:
  docs/00_chaos/qa_first_candidate_crystall_cross_audit_2026-07-26.md
```

## 0. Crystallized Claim

The second hand is one private transaction, not a command API:

```text
one living build Packet
one exact current candidate seal
one exact birth-bound QA contract/check/environment
one body-owned request event
one private one-use grant and source lease
one trusted isolated process transaction
one private receipt
one body-owned outcome write
```

No public string, id or table is sufficient authority. The candidate never
runs in the proc-17 Lua process and never receives a handle to the host,
repository registry or substrate session.

## 1. Exact Implementation Surface

New Lua modules:

```text
runtime/qa_request.lua
runtime/qa_capability.lua
runtime/qa_provider.lua
runtime/qa_execution.lua
tests/test_qa_request.lua
tests/test_qa_capability.lua
tests/test_qa_execution.lua
tests/test_qa_execution_hostile.lua
```

Modify behind the QA gate:

```text
runtime/repository_capability.lua   private sealed-source lease
runtime/repository_provider.lua     same exact inventory reader, no new public root
runtime/body.lua                    request/outcome writers from companion crystall
organs/logic.lua                    one exact QA branch at ☶
runtime/operator_registry.lua       typed effect_failure handoff only
runtime/tension_runner.lua          existing effect-cost/death path only
tests/run.lua
```

Native files are owned by `qa_native_supervisor.v0.md`. This blueprint does not
authorize `io.popen`, `os.execute`, `tools.run_command`, `logic/spells.lua` or a
new shell wrapper.

## 2. Public Request API

```lua
local qa_request = require("runtime.qa_request")

qa_request.prepare(instance, host_services)
  -> detached_request | nil, diagnostic

qa_request.verify(instance, request)
  -> true | nil, err

qa_request.find(instance, request_id)
  -> detached_request, event | nil, reason
```

Preparation is pure. It reads the exact eligibility projection, candidate seal
and sealed entrypoint artifact. It does not mint a grant, inventory the world,
load a provider, append trace or spend budget.

Exact request:

```lua
{
  protocol_version = "qa.check_request.v0",
  request_id = "qa-check-request:<sha256>",

  packet_id = string,
  lineage_id = string,
  generation = positive_integer,
  process_contract_id = "build.only.v0" | "software.create.v0",
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

  entrypoint = {
    relative_path = string,
    work_unit_id = string,
    work_unit_version = positive_integer,
    bytes = non_negative_integer,
    sha256 = "sha256:<hex>",
    completion_ref = string,
    verification_ref = string,
  },

  expected_exit_codes = {0},
  resource_limits = qa_resource_limits,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed" | "mixed",
}
```

Every field except `request_id` participates in canonical identity. There are
no optional command, executable, argv, environment, cwd, mount, namespace,
syscall, retry or stdin fields. Unknown keys are rejected.

Before private resolution, ☶ writes exactly one event:

```text
type = qa_check_request
operator = ☶
truth_status = runtime_confirmed
payload = exact detached qa.check_request.v0
cost = {}
```

The event id is `request_ref`. Re-preparing an identical current request finds
the same event. A second different request for the same current seal/check is a
conflict, not supersession.

## 3. Private QA Registry

```lua
local qa_capability = require("runtime.qa_capability")

qa_capability.new(session_id, environment_registry, repository_registry)
  -> registry | nil, err

qa_capability.mint(registry, instance, request, request_ref)
  -> detached_grant_projection | nil, diagnostic

qa_capability.begin(registry, request_id, request_ref)
  -> private_lease | nil, diagnostic

qa_capability.commit(registry, private_lease, normalized_result)
  -> detached_receipt | nil, err

qa_capability.quarantine(registry, private_lease, reason)
  -> detached_state | nil, err

qa_capability.find_receipt(registry, request_id)
  -> detached_receipt | nil, reason
```

The registry is a weak-key private object. Detached projections never contain
the private registry key, environment lease, repository source lease, native
adapter, path or descriptor.

## 4. Exact Private Grant

```lua
{
  protocol_version = "qa.execution_grant.v0",
  grant_id = "qa-grant:<opaque-random>",
  session_id = string,
  packet_id = string,
  lineage_id = string,
  generation = positive_integer,
  process_contract_id = string,
  stage_id = string,
  repository_id = string,
  root_authority_id = string,
  candidate_seal_id = string,
  candidate_seal_event_ref = string,
  qa_contract_id = string,
  check_id = string,
  profile_id = string,
  environment_id = string,
  request_id = string,
  request_ref = string,
  resource_limits = qa_resource_limits,

  state = "active" | "running" | "consumed" | "revoked"
    | "quarantined",
  revision = positive_integer,
  transaction_id = string | nil,

  private_environment_lease = private,
  private_source_lease = private,
}
```

Mint validates the body request event, every current identity, terminal sealed
root state and exact available environment. It reserves but does not expose one
read-only source lease. It launches nothing.

Grant ids are opaque audit labels. Supplying a copied id without the exact
registry entry and current state grants nothing.

## 5. Repository Source Bridge

The repository capability registry remains the sole owner of root truth. QA
does not copy the repository handle or invent a second root registry.

New private-only API:

```lua
repository_capability.reserve_qa_source(repository_registry, binding)
  -> private_source_lease | nil, diagnostic

repository_capability.with_qa_source(repository_registry, source_lease, consumer)
  -> consumer_results | nil, err

repository_capability.finish_qa_source(repository_registry, source_lease,
  disposition)
  -> true | nil, err
```

Binding requires:

```text
same session/lineage/generation/repository/root authority
same candidate seal and closure receipt
same normalized inventory bounds committed by closure and body seal
root lifecycle state exactly sealed
no quarantine or split-brain marker
one QA transaction identity
```

The exact binding protocol is `repository.qa_source_binding.v1` from
`qa_provider_candidate_transaction.v0.md`. In body mode:

```text
transaction_kind = body_execution
closure_request_id = candidate-seal closure request
qa_request_id = exact qa.check_request.v0 request id
transaction_id = private qa.execution_transaction.v0 transaction id
```

`repository.qa_source_binding.v0` is not a compatibility input. Its ambiguous
`request_id` cannot prove both closure and body-request identity.

The private source lease stores only a private reference to the already-open
repository userdata and exact sealed identities. `with_qa_source` invokes one
trusted internal consumer with that userdata; it never returns the userdata,
integer descriptor or host path in its result.

The native launcher validates the shared internal userdata ABI and duplicates
the exact root descriptor with `F_DUPFD_CLOEXEC`. Lua never sees the duplicated
descriptor. Candidate seal/root state stays sealed before, during and after QA.

The source lease is one-use and sticky. Failure of the first effect does not
release it for another request or generation.

### 5.1 Step-D provider witness exclusion

Step D uses the same v1 source bridge with:

```text
transaction_kind = provider_witness
qa_request_id absent
```

It does not call any API in sections 2-4, does not create the transaction in
section 6 and cannot create the receipt in section 12. Its test-owned witness
report/error protocols are invalid inputs to the body writer described here.

## 6. Transaction State Machine

Private transaction:

```lua
{
  protocol_version = "qa.execution_transaction.v0",
  transaction_id = "qa-transaction:<opaque-random>",
  grant_id = string,
  request_id = string,
  request_ref = string,
  state = "running" | "completed" | "consumed_failed" | "quarantined",
  revision = positive_integer,
  provider_entered = boolean,
  candidate_started = boolean,
  normalized_result_id = string | nil,
  execution_receipt_id = string | nil,
}
```

`begin` atomically changes the grant to `running`, creates this transaction and
consumes replay authority before any provider/inventory call.

There is no transition:

```text
running -> active
consumed/quarantined -> active
request A -> request B
generation/seal/environment A -> B
provider failure -> internal retry
```

## 7. Exact Causal Transaction

`runtime/qa_execution.lua` exposes one trusted body service:

```lua
qa_execution.inspect(instance, host_services)
  -> detached_readiness | nil, err

qa_execution.execute(instance, host_services)
  -> detached_check_or_failure | nil, effect_failure_or_err, loud
```

Exact order:

```text
1. derive and verify current eligibility and request
2. find exact prior request/receipt/body evidence for idempotence
3. append or reuse the one ☶ qa_check_request body event
4. mint one exact private grant and reserve one sealed-source lease
5. atomically begin/consume the grant transaction
6. revalidate root identity and take exact bounded pre-inventory through the
   existing repository provider
7. compare pre-inventory byte-for-byte with the immutable candidate seal
8. resolve the exact private environment lease
9. invoke the exact native launcher once with the opaque repository userdata
10. reap/normalize the native result
11. revalidate root identity and take exact bounded post-inventory
12. require pre == seal == post before any clean candidate report
13. commit one private execution receipt
14. ask the dedicated ☶ body writer to append qa_check OR
    qa_execution_failure
15. return detached evidence; never rerun to repair a split state
```

The existing candidate-seal inventory normalizer/comparator is reused. The QA
adapter does not implement a second tree digest.

If the environment becomes unavailable after the request event but before
`begin`, the request remains an honest pending body request and no provider
cost is charged. Once `begin` succeeds, every incomplete world outcome is a
typed provider error or a loud invariant; it is never returned to `active`.

## 8. Provider Adapter API

Amendment: `qa_provider.run` first returns the private
`qa.provider_process_observation.v0` or `qa.provider_process_error.v0` defined
by `qa_provider_candidate_transaction.v0.md`. Those records contain no
pre/post inventory claim. The complete body transaction later joins them with
source observations and its exact QA request before constructing the body
provider report/error below.

```lua
local qa_provider = require("runtime.qa_provider")

qa_provider.availability() -> detached_availability
qa_provider.probe() -> raw_environment_report | nil, provider_error
qa_provider.run(repository_userdata, native_request)
  -> native_candidate_result | nil, native_provider_error
```

The adapter:

```text
derives one fixed module path from its own trusted source identity
hashes the bounded module bytes before load
uses package.loadlib with one exact symbol
validates exact protocol/provider/ABI/build fields and key set
passes only the repository userdata and a closed native request
pcall-wraps the C boundary only to classify trusted corruption as loud
strictly normalizes every return field
```

It has no function accepting an executable path or command. The native request
contains only a private transaction nonce, request digest, root identity,
entrypoint path and exact numeric limits. Packet/lineage prose does not enter
the native process.

## 9. Measurement Schemas

Bounded stream:

```lua
{
  protocol_version = "qa.stream_measurement.v0",
  observed_bytes = non_negative_integer,
  hashed_bytes = non_negative_integer,
  sha256 = "sha256:<hex>",
  limit_bytes = positive_integer,
  limit_reached = boolean,
}
```

`sha256` covers exactly the first `hashed_bytes=min(observed_bytes,
limit_bytes)` bytes. The supervisor terminates on overflow and drains only the
fixed pipe remainder; `observed_bytes` is bounded by the configured limit plus
the fixed pipe-capacity allowance in the isolation policy.

Resources:

```lua
{
  protocol_version = "qa.resource_measurement.v0",
  wall_time_ms = non_negative_integer,
  cpu_user_ms = non_negative_integer,
  cpu_system_ms = non_negative_integer,
  max_rss_bytes = non_negative_integer,
  address_space_limit_bytes = positive_integer,
  max_open_files = positive_integer,
  max_file_bytes = positive_integer,
  max_processes = 1,
}
```

Scratch:

```lua
{
  protocol_version = "qa.scratch_measurement.v0",
  observed_entries = non_negative_integer,
  observed_regular_bytes = non_negative_integer,
  limit_entries = positive_integer,
  limit_bytes = positive_integer,
  limit_reached = boolean,
}
```

Detailed QA cost:

```lua
{
  protocol_version = "qa.cost.v0",
  tool_calls = 1,
  qa_executions = 0 | 1,
  wall_time_ms = non_negative_integer,
  cpu_time_ms = non_negative_integer,
  scratch_written_bytes = non_negative_integer,
  stdout_observed_bytes = non_negative_integer,
  stderr_observed_bytes = non_negative_integer,
}
```

`qa_executions=1` only when candidate code started. A failed launcher still
records `tool_calls=1` and actual time.

## 10. Clean Candidate Report

This is a future `transaction_kind=body_execution` schema. The D-only
`qa.provider_witness_report.v0` is neither an alias nor an accepted input.

Strict normalized adapter output:

```lua
{
  protocol_version = "qa.provider_candidate_report.v0",
  operation = "run_lua54_test_suite",
  request_id = string,
  profile_id = "qa.profile.lua54_test_suite.v0",
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
  stdout = qa_stream_measurement,
  stderr = qa_stream_measurement,
  resources = qa_resource_measurement,
  scratch = qa_scratch_measurement,
  cleanup = "complete",
  cost = qa_cost,
}
```

Accepted requires exact exit zero, no limit/policy event, complete cleanup and
stable source. Every other cleanly contained candidate result is rejected.
`sandbox_policy_violation` requires a positively observed seccomp/SIGSYS policy
termination, not an inferred suspicious message.

## 11. Infrastructure Error

This is a future body-transaction schema. D uses
`qa.provider_witness_error.v0` only after its source lease reaches terminal
disposition.

```lua
{
  protocol_version = "qa.provider_error.v0",
  operation = "run_lua54_test_suite",
  request_id = string,
  profile_id = string,
  environment_id = string,
  class = "unavailable" | "world" | "ambiguous",
  code = "provider_unavailable"
    | "environment_identity_changed"
    | "supervisor_launch_failed"
    | "namespace_unavailable"
    | "mount_setup_failed"
    | "source_preflight_mismatch"
    | "source_drift"
    | "supervision_failed"
    | "wait_reap_failed"
    | "measurement_incomplete"
    | "scratch_cleanup_ambiguous"
    | "process_cleanup_ambiguous",
  stage = "preflight" | "namespace" | "launch" | "supervision"
    | "postflight" | "cleanup",
  candidate_started = boolean,
  source_stable = true | false | nil,
  cleanup_complete = true | false | nil,
  cost = qa_cost,
}
```

Unknown key/code, impossible identity/cost or a clean report claiming unstable
source is trusted-physics corruption and fails loudly. It is not converted into
this protocol.

## 12. Private Execution Receipt

Step D is forbidden from entering this section. A provider witness report does
not satisfy `result_kind`, cannot create `normalized_result_id` and cannot be
replayed as body evidence.

The private registry commits before body outcome append:

```lua
{
  protocol_version = "qa.execution_receipt.v0",
  execution_receipt_id = "qa-execution-receipt:<sha256>",

  request_id = string,
  request_ref = string,
  grant_id = string,
  packet_id = string,
  lineage_id = string,
  generation = positive_integer,
  stage_id = string,
  repository_id = string,
  candidate_seal_id = string,
  qa_contract_id = string,
  check_id = string,
  profile_id = string,
  environment_id = string,

  result_kind = "candidate_report" | "provider_error",
  normalized_result_id = "qa-provider-result:<sha256>",
  transaction_disposition = "completed" | "consumed_failed"
    | "quarantined",
  cost = qa_cost,
  committed = true,
}
```

Every field except `execution_receipt_id` participates in identity. The body
gets only a detached receipt id plus the normalized result through a trusted
join; it never gets the private grant/lease/handle.

## 13. Split-Brain And Replay Law

```text
receipt + exact body outcome
  -> return same detached evidence; no process/event/cost

neither receipt nor body outcome
  -> one request may begin once

receipt exists, body outcome absent/different
  -> quarantine; loud; no rerun

body outcome exists, receipt absent/different
  -> loud; no rerun

same request, different normalized result
  -> loud conflict; never latest-wins
```

An append failure after private commit is not repaired by running the candidate
again. It remains a visible trusted split.

## 14. Economics Projection

The full `qa.cost.v0` remains QA evidence. Existing Packet budget accepts only:

```lua
{
  tool_calls = qa_cost.tool_calls,
  test_runs = qa_cost.qa_executions,
  time_ms = qa_cost.wall_time_ms,
}
```

No new budget axis is invented in this step. Scratch/output/CPU measurements
remain bounded evidence for later economics. Exact replay adds no second cost.

Infrastructure failure maps to existing `substrates.contract.effect_failure`:

```lua
{
  source = "sandbox",
  code = "qa_" .. provider_error.code,
  retryability = provider_error.class == "ambiguous" and "terminal"
    or "unknown",
  source_refs = {failure_id, failure_event_ref, request_ref},
  cost = existing_budget_projection,
  detail = detached_qa_execution_failure,
}
```

The runner then uses its existing committed-effect accounting and
`death_cause=effect_failure`. No new mortality path is created.

## 15. Failure Classification

| Point | Evidence class | Consequence |
|---|---|---|
| before request eligibility | not-ready | no event/process/cost |
| pending request, environment no longer resolvable before begin | not-ready | request remains pending; no process/cost |
| contained exit/signal/limit/policy result | candidate report | body check, then verdict |
| pre/post source mismatch or provider cannot prove world | provider error | body execution failure, effect death |
| cleanup/reap ambiguity | ambiguous provider error | quarantine, no check/verdict |
| malformed native/registry identity | invariant | loud harness failure |
| body append split after receipt | invariant | loud, no rerun |

Task failure never crashes the harness. Trusted-physics contradiction never
gets beautified as an honest Packet death.

## 16. Named Writers And Readers

| Record/state | Writer | First named reader |
|---|---|---|
| request preparation | pure `qa_request` | ☶ request event writer |
| request event | ☶ body writer | private grant mint/begin |
| QA grant | private QA registry | transaction begin |
| sealed-source lease | repository registry | trusted QA execution service |
| private environment lease | environment registry | provider adapter |
| transaction | QA registry | provider/receipt commit |
| pre/post inventory | existing repository provider/normalizer | QA result join |
| native report/error | native supervisor + strict adapter | receipt/body writer |
| execution receipt | QA registry | idempotence and body writer |
| check/failure body event | companion evidence writer | verdict/runner |

## 17. Permanent Controls

```text
QE01 QA disabled -> no provider load/process/trace/budget/loss delta
QE02 public request has no command/executable/argv/env/cwd surface
QE03 public ids without private registry grant zero authority
QE04 unsealed/diverged/foreign candidate calls no provider
QE05 exact request event is required before grant begin
QE06 source lease exposes no path/fd/userdata in detached values
QE07 source root remains sealed and write grants remain closed
QE08 request/lease replay launches no second supervisor
QE09 failed first attempt does not release source/grant authority
QE10 pre/post inventories reuse candidate-seal normalization and agree exactly
QE11 source drift creates no candidate check/verdict
QE12 candidate rejection and infrastructure failure remain distinct
QE13 malformed trusted report is loud
QE14 receipt/body split is loud and never rerun
QE15 clean accepted/rejected outcome charges once
QE16 pre-dispatch denial charges no candidate process
QE17 cross-session/lineage/generation/stage/seal/environment grant is denied
QE18 detached mutation changes no registry/receipt state
QE19 foreign-lineage alias of repository id/root cannot mint QA authority
QE20 repeated hostile lives leave no process/fd/mount/scratch residue
```

## 18. Implementation Order

```text
1. red schema/request/grant/replay/split-brain tests with a non-executing fake
2. private QA and sealed-source lease registries
3. strict provider adapter loader and unavailable-only stub
4. native hostile probes from the companion crystall
5. exact pre/post inventory transaction
6. one isolated candidate transaction
7. private receipt and body-outcome join
8. existing effect_failure integration
9. green hostile corpus, leak/replay loops and ablation
10. only then expose readiness to the tree body
```

## 19. Acceptance Gate

Production dispatch remains off until:

```text
all QE controls have executable tests
dangerous fixtures can only run behind the native isolated provider
environment probe proves the exact production path without SKIP
source cannot mutate under hostile candidates
process, descriptor, namespace, mount and scratch cleanup loops are green
candidate/infrastructure/invariant matched pairs are green
QA-disabled ablation is exact
```

## 20. Explicit Deferrals

```text
generic commands and external executable selection
networked/multi-process/service QA
dependency installation or package managers
writable source overlays
raw output persistence or prompt ingestion
provider retry/resume after restart
parallel QA transactions
QA child Packet
same-root recovery after Packet death
```

## 21. Crystall Thesis

```text
The second hand receives no words to execute. It receives one already-owned
question, one already-dead write surface and one lease that consequence consumes
before the world is touched.
```
