# QA Provider Candidate Transaction Blueprint v0

E6 note 2026-07-28: sections 5.5 and 5.6 preserve the historical v0 witness
schemas. Their executable successors are the v1 schemas and ordering in
`qa_hostile_execution_campaign.v0.md` section 18. Body-execution schemas in
this document are unchanged.

Post-QN20 amendment 2026-07-29: the physical pre-inventory/RUN/post-inventory
block becomes the shared engine specified by
`qa_body_execution_after_qn20.v0.md`. Provider-witness authority, ids, public
v1 report/error protocols, QN outputs and residue remain exact; no Packet body
reader is added. Audit:
`docs/00_chaos/qa_body_transaction_crystall_cross_audit_2026-07-29.md`.

Status:

```text
layer: crystall (◈)
date: 2026-07-26
chapter: 8.5.5D provider physics
source table:
  docs/01_table/yellowprints/qa_provider_candidate_transaction_yellowprint.v0.md
  docs/01_table/yellowprints/qa_execution_capability_yellowprint.v0.md
gate record:
  docs/00_chaos/qa_first_candidate_table_cross_audit_2026-07-26.md
crystall audit:
  docs/00_chaos/qa_first_candidate_crystall_cross_audit_2026-07-26.md
depends on:
  docs/02_crystall/blueprints/candidate_seal_transaction.v0.md
  docs/02_crystall/blueprints/qa_execution_capability.v0.md
  docs/02_crystall/blueprints/qa_native_supervisor.v0.md
  docs/02_crystall/blueprints/qa_detached_source_staging.v0.md
implementation authority: yes; exact D1-D7 provider-witness order only
Packet QA request/grant/receipt authority: forbidden
body QA evidence/verdict authority: forbidden
router/pressure/completion authority: forbidden
```

## 0. Crystallized Claim

Step D proves one physical statement:

```text
one exact sealed source can be executed once by the measured native provider
and classified by a trusted harness without changing the Packet
```

The implementation is not a shortened body QA transaction. It contains no
body request, QA grant, execution receipt, check/failure event or verdict.

## 1. Exact Implementation Surface

Add:

```text
runtime/repository_inventory.lua
runtime/qa_provider_witness.lua
tests/test_qa_provider_witness.lua
tests/test_qa_provider_witness_hostile.lua
```

Modify:

```text
runtime/repository_capability.lua
runtime/candidate_seal.lua
runtime/qa_provider.lua
runtime/qa_environment.lua
tests/test_qa_source_bridge.lua
tests/test_qa_native_supervisor.lua
tests/red_qa_hand.lua
tests/support/qa_control_catalog.lua
native files owned by qa_detached_source_staging.v0.md
```

`runtime/qa_provider_witness.lua` is trusted orchestration for the D harness.
It is not imported by an organ, router, pressure reader, completion reader or
the public CLI. Its returned records are detached observations, never
capabilities.

## 2. C2 - Repository Source Binding v1

### 2.1 Exact schema

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

Exact-key law:

```text
all listed non-optional keys are present
qa_request_id is the only optional key and is absent, not false/empty, in D
unknown keys, metatables, cycles and non-plain nested bounds are rejected
```

### 2.2 Conditional validation

Common validation requires:

```text
exact protocol and truth status
all identity strings non-empty
generation positive integer
inventory_bounds passes the shared canonical bounds validator
candidate seal validates as current historical evidence
private root state is exactly sealed
private closure projection is exact and digest-valid
binding coordinates equal root claim, closure and body seal
binding.inventory_bounds == closure.inventory_bounds == seal.inventory_bounds
binding.inventory_id/digest == closure and seal inventory identity
source state is available and unreserved
```

Mode validation:

| Mode | `closure_request_id` | `qa_request_id` | `transaction_id` owner |
|---|---|---|---|
| `provider_witness` | exact closure request | key absent | deterministic D transaction derivation |
| `body_execution` | exact closure request | exact body request | private QA execution registry |

For `provider_witness`, derive:

```lua
transaction_seed = {
  protocol_version = "qa.provider_source_transaction_seed.v0",
  transaction_kind = "provider_witness",
  session_id = binding.session_id,
  lineage_id = binding.lineage_id,
  generation = binding.generation,
  repository_id = binding.repository_id,
  root_authority_id = binding.root_authority_id,
  lifecycle_id = binding.lifecycle_id,
  root_fingerprint = binding.root_fingerprint,
  closure_id = binding.closure_id,
  closure_request_id = binding.closure_request_id,
  candidate_seal_id = binding.candidate_seal_id,
  candidate_seal_event_ref = binding.candidate_seal_event_ref,
  inventory_id = binding.inventory_id,
  inventory_digest = binding.inventory_digest,
  inventory_bounds = binding.inventory_bounds,
}

transaction_id = "qa-provider-transaction:" .. digest.record(transaction_seed)
```

The id is deterministic audit identity, not authority. The private root and
opaque source lease remain the authority.

For `body_execution`, `transaction_id` must equal the exact private
`qa.execution_transaction.v0.transaction_id` supplied by the QA registry. The
source registry does not invent or reinterpret that identity.

### 2.3 Private lease state

The source lease retains detached copies of:

```lua
{
  transaction_kind,
  closure_request_id,
  qa_request_id,
  transaction_id,
  candidate_seal_id,
  candidate_seal_event_ref,
  inventory_id,
  inventory_digest,
  inventory_bounds,
}
```

It also retains the existing private root/source references and root revision.
No new handle, descriptor or path is projected.

The source state remains:

```text
available -> reserved -> attempted -> consumed
                                  \-> quarantined
```

There is no return to `available`. A failed first callback does not release the
transaction id or source authority.

### 2.4 v0 disposition

`repository.qa_source_binding.v0` is rejected by the validator after D is
promoted. Existing v0 leases are in-memory and cannot survive the process in
which the code is upgraded. No compatibility alias is permitted because it
would preserve the ambiguous `request_id` vocabulary.

### 2.5 C2 controls

```text
SB01 exact provider_witness binding reserves one lease
SB02 provider_witness with qa_request_id is rejected
SB03 body_execution without qa_request_id is rejected
SB04 closure_request_id cannot be replaced by QA request id
SB05 transaction_id cannot be either request id
SB06 foreign session/lineage/generation/root/closure/seal is rejected
SB07 changed inventory bounds/id/digest is rejected
SB08 v0 binding is rejected after promotion
SB09 returned binding/lease projection mutation changes no private state
SB10 failed first callback never restores source availability
```

## 3. C3 - Shared Pure Inventory Normalizer

### 3.1 Module API

```lua
local repository_inventory = require("runtime.repository_inventory")

repository_inventory.normalize_bounds(value)
  -> normalized_bounds | nil, err

repository_inventory.normalize_provider_result(raw, coordinates)
  -> normalized_observation | nil, err, failure_class

repository_inventory.same(left, right)
  -> true | false
```

The module has no imports of:

```text
runtime/repository_provider.lua
runtime/repository_capability.lua
io, os, package.loadlib, shell or filesystem APIs
```

It is pure structured-data validation, canonicalization and hashing.

### 3.2 Coordinates

```lua
coordinates = {
  request_id = string,
  root_fingerprint = string,
  inventory_bounds = repository_inventory_bounds,
  root_continuity = "proven",
}
```

The caller may construct this record only after its authority-specific root
check returned true.

Authority-specific checks remain separate:

```lua
repository_capability.candidate_inventory_root_matches(
  registry, candidate_seal_lease, raw.root_before, raw.root_after)

repository_capability.qa_source_inventory_root_matches(
  registry, qa_source_lease, raw.root_before, raw.root_after)
```

Both compare raw provider identities to the private root identity. Neither
normalizes entries or reads the host.

### 3.3 Sole host reader

The only host read remains:

```lua
repository_provider.inventory_tree(repository_userdata, inventory_bounds)
```

Seal and D execute that API under different opaque leases, then call the same
pure normalizer. No QA-native walk, Lua file read or second digest path exists.

### 3.4 Normalized observation

```lua
{
  status = "observed" | "unstable" | "bound_exceeded",
  inventory = repository_seal_inventory | nil,
  root_before_ref = string,
  root_after_ref = string,
  provider_cost = repository_inventory_cost,
}
```

For `observed`, `inventory` is exactly the C1 schema, including canonical
`inventory_bounds`. Its digest/id algorithms are owned by
`candidate_seal_transaction.v0.md` and are not duplicated here.

For `unstable` or `bound_exceeded`, no inventory identity is fabricated. Root
refs and provider cost remain detached evidence for authority-specific failure
classification.

### 3.5 Equality

`repository_inventory.same` compares the complete normalized inventory:

```text
protocol, request id and root fingerprint
canonical inventory bounds
entry order and every entry field
observed counts
inventory digest/id
source refs and truth status
```

It returns false for a bounds-only difference. It never accepts caller subsets.

### 3.6 C3 controls

```text
IN01 candidate seal and D normalize the same raw observation identically
IN02 bounds-only difference changes digest/id and same() is false
IN03 QA source root check cannot consume candidate seal lease and vice versa
IN04 malformed raw provider result is loud under both callers
IN05 unstable/bound-exceeded result creates no inventory id
IN06 normalizer imports no host reader or private registry
IN07 provider inventory executes once per pre/post observation
IN08 raw content is discarded before normalized inventory escapes
```

## 4. C7 - Private Process Observation And Error

### 4.1 Provider API

```lua
qa_provider.run(repository_userdata, native_request)
  -> process_observation
  | nil, process_error
```

The function is legal only inside one active
`repository_capability.with_qa_source` callback. The repository userdata is the
existing private value passed by that callback; no wrapper may retain it after
return.

### 4.2 Process observation

```lua
{
  protocol_version = "qa.provider_process_observation.v0",
  operation = "run_lua54_test_suite",
  transaction_id = string,
  witness_id = string,
  profile_id = "qa.profile.lua54_test_suite.v0",
  environment_id = string,

  outcome = "expected_exit"
    | "unexpected_exit"
    | "signal"
    | "wall_timeout"
    | "cpu_limit"
    | "memory_limit"
    | "output_limit"
    | "scratch_limit"
    | "sandbox_policy_violation",

  candidate_started = true,
  source_staging_policy = "qa.source_staging.detached_mount.v0",
  source_staging_complete = true,
  termination = {
    kind = "exit" | "signal" | "supervisor_kill",
    exit_code = integer | nil,
    signal = integer | nil,
  },
  stdout = qa_stream_measurement,
  stderr = qa_stream_measurement,
  resources = qa_resource_measurement,
  scratch = qa_scratch_measurement,
  cleanup_complete = true,
  cost = qa_cost,
  event_truth_status = "runtime_confirmed",
}
```

This record deliberately has no:

```text
pre/post inventory
source_stable whole-transaction claim
closure/QA request id
body check/verdict meaning
raw output/path/fd/device/inode/mount identity
```

### 4.3 Process error

```lua
{
  protocol_version = "qa.provider_process_error.v0",
  operation = "run_lua54_test_suite",
  transaction_id = string,
  witness_id = string,
  profile_id = string,
  environment_id = string,
  class = "unavailable" | "world" | "ambiguous",
  code = closed_process_error_code,
  stage = "preflight" | "source_staging" | "namespace" | "launch"
    | "supervision" | "postflight" | "cleanup",
  candidate_started = boolean,
  source_staging_complete = true | false | nil,
  cleanup_complete = true | false | nil,
  cost = qa_cost,
  event_truth_status = "runtime_confirmed",
}
```

Required staging pair:

```text
class=world
code=source_staging_failed
stage=source_staging
candidate_started=false
source_staging_complete=false
cleanup_complete=true
```

Ambiguous cleanup never uses `cleanup_complete=true`.

### 4.4 Strict normalization

`runtime/qa_provider.lua` validates, in order:

```text
exact Lua request schema and environment identity
native module/provider/ABI/build identity
exact RUN wire identity returned by launcher
transaction/witness/profile/environment equality
source staging attestation already validated and stripped by launcher
closed disposition/reason/error enums
candidate-start/termination consistency
every measurement and hard limit
empty-stream digest law
cleanup consistency
absence of raw/private fields
```

Impossible combinations are loud, for example:

```text
expected_exit without exit 0
unexpected_exit with exit 0
candidate outcome with candidate_started=false
candidate outcome with incomplete staging or cleanup
preflight error with candidate_started=true
zero-byte stream with nonempty digest
limit reason without corresponding reached measurement
```

`pcall` catches a native exception only to close/quarantine private authority;
it does not normalize trusted corruption into a process error.

### 4.5 Cost projection

```lua
qa_cost = {
  tool_calls = 1,
  qa_executions = 1,
  wall_time_ms = exact_native_wall_time,
  cpu_time_ms = exact_native_user_plus_system_cpu,
  scratch_written_bytes = exact_scratch_bytes,
  stdout_observed_bytes = exact_stdout_bytes,
  stderr_observed_bytes = exact_stderr_bytes,
}
```

The provider observes this cost. It has no writer into Packet or lineage
economics in D.

### 4.6 C7 controls

```text
PO01 clean RUN normalizes to expected_exit observation
PO02 Lua error normalizes to unexpected_exit observation
PO03 clean staging failure normalizes to process error, not candidate outcome
PO04 malformed/impossible native result is loud
PO05 process observation has no pre/post source claim
PO06 raw native staging identities never cross adapter
PO07 cost equals native measurements and is never estimated
PO08 detached result mutation changes no provider/private state
```

## 5. C8 - D Witness And Final Assembler

### 5.1 Module API

```lua
local witness = require("runtime.qa_provider_witness")

witness.prepare(instance, host_services, options)
  -> detached_plan | nil, diagnostic

witness.execute(instance, host_services, plan)
  -> qa_provider_witness_report
  | nil, qa_provider_witness_error_or_loud
```

`prepare` is pure. `execute` is trusted D orchestration and is not registered as
an organ/tool/router action.

### 5.2 Witness identity

The detached plan contains the exact TABLE `qa.provider_witness.v0` record.
Derivation order:

```text
validate current Packet/birth coordinates
validate exact current candidate seal and private closure
validate entrypoint artifact and detached environment/profile
normalize inventory bounds and resource limits
derive provider source transaction id using C2
hash witness seed with witness_id=nil and transaction_id excluded
prefix qa-provider-witness:
derive native request from the final witness
derive source binding v1 from the same coordinates
```

The witness seed contains every TABLE witness field except both ids. The two ids
use distinct tagged digest domains. Returned plan tables are deep-detached.

### 5.3 Exact execution order

```text
D0 grow/receive one disposable real first-hand sealed Packet/root
D1 rederive and verify plan, seal, closure, environment and profile
D2 snapshot Packet and public root projections
D3 reserve exact source binding v1(provider_witness)
D4 enter one with_qa_source callback; lease becomes attempted
D5 repository_provider.inventory_tree -> root check -> pure normalize pre
D6 require pre == seal == closure including inventory bounds
D7 qa_provider.run exactly once -> process observation/error
D8 repository_provider.inventory_tree -> root check -> pure normalize post
D9 create private pending join; leave callback with no userdata
D10 finish source lease once with derived disposition
D11 assemble final witness report/error from pending join + terminal disposition
D12 verify Packet/public-root ablation
D13 assert QN16-only control delta
```

The callback encloses D5-D9. Protected cleanup guarantees that Lua assertion or
adapter failure cannot leave an attempted source lease silently unfinished.

### 5.4 Pending join

The pending join is an untagged private Lua record containing:

```text
verified witness identity
process observation/error
pre/post normalized inventories
derived required source disposition
detached measured cost
```

It has no `protocol_version`, digest id, storage API or external reader. It may
cross out of the source callback only after private userdata and raw inventory
content have been removed.

### 5.5 Final witness report

After exact `finish_qa_source(..., "consumed")` succeeds for a contained
candidate outcome, assemble:

```lua
{
  protocol_version = "qa.provider_witness_report.v0",
  operation = "run_lua54_test_suite",
  transaction_id = string,
  witness_id = string,
  profile_id = string,
  environment_id = string,
  outcome = "accepted" | "rejected",
  reason = process_outcome,
  termination = qa_termination,
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
  event_truth_status = "runtime_confirmed",
}
```

Mapping for D:

```text
process expected_exit   -> accepted / expected_exit
process unexpected_exit -> rejected / unexpected_exit
process signal/limit/policy outcome -> rejected / same exact process reason
```

Other contained candidate outcomes remain schema-valid physical observations
but cannot satisfy QN17-QN20 until their hostile campaigns are promoted.

### 5.6 Final witness error

After terminal lease disposition, infrastructure failure assembles:

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

Pre-inventory mismatch has `candidate_started=false`. Post-inventory drift has
`source_stable=false` and requires quarantine. A process error's source claim
is upgraded only from the D transaction's own pre/post observations.

### 5.7 Protocol firewall

The following substitutions are schema errors:

```text
witness report/error -> qa.provider_candidate_report/error
witness report/error -> QA body writer
body provider report/error -> D assembler input
process observation/error -> any body writer
```

No compatibility alias exists.

### 5.8 C8 controls

```text
WA01 prepare is pure and detached
WA02 foreign/stale seal, closure, environment or entrypoint starts no source lease
WA03 pre inventory mismatch starts no native RUN
WA04 provider runs exactly once inside one source callback
WA05 post inventory mismatch emits no witness report
WA06 pending join has no protocol/id/storage reader
WA07 final report cannot exist before terminal source disposition
WA08 witness protocol cannot enter body request/check/verdict APIs
WA09 clean/nonzero separate roots classify accepted/rejected exactly
WA10 returned witness mutation changes no private state
```

## 6. C9 - Source Disposition And Ablation

### 6.1 Disposition derivation

| Pending fact | Required disposition | Final D result |
|---|---|---|
| contained outcome + exact pre/post + complete cleanup | `consumed` | witness report |
| clean provider error before candidate + exact source + complete cleanup | `consumed` | witness error |
| source drift | `quarantined` | witness ambiguous error |
| cleanup/reap/EOF ambiguity | `quarantined` | witness ambiguous error |
| trusted contradiction after lease attempt | `quarantined` then loud | no ordinary result |

`finish_qa_source` validates that requested disposition agrees with the private
lease's attempted state. Exact replay returns the existing detached disposition
without reopening or rerunning.

If finish fails after a clean process observation:

```text
no witness report is assembled
best-effort private quarantine is attempted only through the registry API
failure to prove quarantine remains loud
```

### 6.2 Packet ablation snapshot

Before D3 and after D11, the hostile harness computes a canonical digest over:

```text
Packet status/death/residue
complete trace
budget and loss/tension
field units/relations/revisions
current operator and tick counters
candidate-seal projection
```

The digest and a structural equality check must both agree. The snapshot helper
has no mutator and is test-owned.

### 6.3 Root ablation

Public root projection before/after must agree on:

```text
sealed state and revision
root authority/lifecycle/fingerprint
closure and inventory identities/bounds
source-write terminal closure
```

Private source lease state may move to `consumed` or `quarantined`. That state
does not reopen or alter the public sealed root.

### 6.4 Economics ablation

The witness report/error carries measured `qa_cost`, but D calls no:

```text
budget.charge
loss accumulator
lineage budget writer
token/documentation accounting writer
```

Packet and lineage economic snapshots remain byte-identical. This is an
authority statement, not a claim that host execution costs nothing.

### 6.5 C9 controls

```text
AB01 clean outcome consumes source once
AB02 clean pre-candidate error consumes source once
AB03 drift/cleanup ambiguity quarantines source
AB04 finish failure emits no clean witness
AB05 replay starts no second callback/supervisor
AB06 Packet canonical and structural snapshots are identical
AB07 public root remains exact sealed projection
AB08 no Packet/lineage economics writer is reached
AB09 no fd/path/userdata/raw output survives detached return
```

## 7. C10 - QN16-Only Promotion

### 7.1 Native target

Add exactly one Make target consumed by existing QN16:

```text
qa-supervisor-basic-fixtures-test
```

The target builds and runs the production launcher/supervisor against only the
two C6 basic fixtures. It does not run QN17-QN20 hostile/fault/leak targets.

### 7.2 Integration witness

`tests/test_qa_provider_witness.lua` grows two separate real first-hand roots:

```text
clean root    -> seal -> D -> accepted/expected_exit
nonzero root  -> seal -> D -> rejected/unexpected_exit
```

Both use:

```text
real repository provider
real candidate seal and closure
source binding v1
production detached staging and RUN
pre == seal == post
Packet/root/economics ablations
```

Fixture bytes are reached only through the fixture guard and native provider.

### 7.3 Exact matrix delta

Before:

```text
39 green / 45 red
native supervisor 15 green / 5 red
```

After:

```text
40 green / 44 red
native supervisor 16 green / 4 red
```

Only:

```text
QN16 clean and nonzero fixtures classify exactly
```

changes red to green.

Remain red:

```text
QN17 hostile candidate containment campaign
QN18 trusted crash/pipe fault campaign
QN19 cleanup ambiguity campaign
QN20 repeated leak campaign
QE08-QE20 body grant/receipt/execution chain
all QV body evidence/verdict controls
all completion/work-layer/tree promotion controls
```

The promotion test snapshots the complete control catalog before/after and
fails if any id other than QN16 changes expected status.

### 7.4 Ordinary regression gate

Required after implementation:

```text
lua tests/run.lua -> all ordinary suites green
lua tests/smoke_mortality_battery.lua -> 8/8
lua tests/red_qa_hand.lua -> expected nonzero with exact 40/44 matrix
native sanitizer/hostile foundation suites remain green
git diff --check
```

### 7.5 Implementation order

```text
D1 C1 bounds commitment and shared pure normalizer
D2 source binding v1 migration and controls
D3 detached staging in PROBE; rotate environment identity
D4 RUN wire/parser and basic native fixtures
D5 strict process observation/error normalizers
D6 D witness transaction over real sealed roots
D7 disposition/ablation controls and QN16 promotion
```

No later slice begins when the previous slice changes an unauthorized control.

## 8. Named Writers And Readers

| Fact | Writer | First reader |
|---|---|---|
| source binding v1 | D witness derivation | repository source resolver |
| source lease/disposition | repository registry | callback/finish/replay controls |
| raw inventory | repository provider | shared pure normalizer |
| normalized inventory | pure normalizer after root proof | D equality join |
| native request | strict provider adapter | launcher/supervisor |
| process observation/error | strict provider adapter | D pending-join builder |
| pending join | D callback | source finish/final assembler |
| witness report/error | D final assembler | hostile harness assertions |
| D cost | supervisor/adapter | harness only |

No writer in this table has a body reader.

## 9. Explicit Deferrals

```text
Packet QA request/grant/receipt
body check/failure events and final verdict
hostile/fault/leak execution promotion QN17-QN20
completion/work-layer/tree readers
retry/resume/parallel checks
generic commands or executable selection
raw output retention
repository cleanup/compost
```

## 10. Blueprint Thesis

```text
D lets the provider finish one real thought about one sealed candidate. The
source lease must die before that thought receives a final name, and the Packet
must remain physically unable to hear it.
```
