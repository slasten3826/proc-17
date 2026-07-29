# QA Execution Capability Yellowprint v0

Status:

```text
layer: table (checked)
date: 2026-07-23
scope: private QA authority, isolated process transaction and trusted report
runtime implementation authorized: no
QA execution authorized: no
router/pressure promotion authorized: no
crystallization authorized: yes; QA TABLE cross-audit 2026-07-23
gate record: docs/00_chaos/qa_table_cross_audit_2026-07-23.md
latest amendment: 2026-07-26 detached source staging and provider-witness boundary
amendment cross-audit: satisfied 2026-07-26
amendment gate record: docs/00_chaos/qa_first_candidate_table_cross_audit_2026-07-26.md
```

## 2026-07-29 Post-QN20 Treatment Boundary

This document remains architecture and threat-model archaeology, but its
unimplemented body-transaction details are partially superseded by:

```text
qa_body_execution_after_qn20_yellowprint.v0.md
qa_body_transaction_reconciliation_yellowprint.v0.md
```

Keep the command-free request, private-authority ceiling, isolation laws,
source immutability, split-brain rule and named trust boundaries. Do not
implement sections 5, 7, 13, 14 or 16 directly where they still claim:

```text
atomic grant mint plus source reservation across two registries
qa.provider_candidate_report.v0 / qa.provider_error.v0
qa.execution_receipt.v0 as the final body transaction vocabulary
one body-specific implementation of physics now promoted by QN16-QN20
```

The post-QN20 treatment selects sticky grant begin before source reservation,
one shared private physical engine, request-causal body source identity and
full RUN v1 cause/finality. Runtime implementation remains unauthorized until
that treatment is crystallized.

Primary chaos source:

[`../../00_chaos/second_qa_hand_threat_model_2026-07-23.md`](../../00_chaos/second_qa_hand_threat_model_2026-07-23.md)

Companion TABLE contracts:

```text
qa_contract_profile_yellowprint.v0.md
qa_check_verdict_yellowprint.v0.md
qa_detached_source_staging_yellowprint.v0.md
qa_provider_candidate_transaction_yellowprint.v0.md
candidate_seal_transaction_yellowprint.v0.md
repository_candidate_lifecycle_yellowprint.v0.md
capability_safe_repository_hands_yellowprint.v0.md
```

## 0A. 2026-07-26 Amendment Boundary

This table remains the target contract for the future Packet-owned QA
transaction. It no longer owns two narrower decisions introduced by step D:

```text
detached source mount construction
trusted provider-witness transaction before body authority exists
```

Their owners are:

```text
qa_detached_source_staging_yellowprint.v0.md
qa_provider_candidate_transaction_yellowprint.v0.md
```

The amendment has three exact consequences.

First, section 8's direct-bind sequence is superseded by the fd-authoritative
detached staging sequence. Its policy claims remain live: the candidate sees
the exact sealed source, read-only, nosuid, nodev and noexec; source copies and
writable overlays remain forbidden.

Second, step D is not an early form of the transaction in sections 5-7 and 16.
It is a trusted provider witness with this authority ceiling:

```text
provider witness report may exist in the trusted harness
private QA grant/receipt may not exist
qa_check_request / qa_check / qa_execution_failure may not exist
Packet trace, budget, loss, revisions, status and death remain unchanged
```

Third, the ambiguous private source-binding key `request_id` is retired before
step D. `repository.qa_source_binding.v1` separates:

| Coordinate | Meaning |
|---|---|
| `closure_request_id` | candidate-seal closure request that owns the sealed source |
| `qa_request_id` | future Packet-owned `qa.check_request.v0` identity |
| `transaction_id` | one private source-lease consumption; neither request identity |

`transaction_kind=provider_witness` requires `closure_request_id`, forbids
`qa_request_id`, and is callable only by the trusted D harness.
`transaction_kind=body_execution` requires both request identities and remains
reserved for the future QA capability registry.

This is a vocabulary repair, not a migration of persistent history: the v0
source bindings are private, in-memory and must be rejected once D is promoted.

Step D also uses distinct test-owned result protocols:

```text
qa.provider_witness_report.v0
qa.provider_witness_error.v0
```

They cannot be supplied where this table requires the future body-facing
`qa.provider_candidate_report.v0` or `qa.provider_error.v0`. The native adapter
first writes a private process observation; only the transaction owner that has
performed post-inventory may assemble either class of final report.

## 0. Selected Decisions

```text
QE01 QA execution uses a new private capability family, never repository grants
QE02 the public request cannot express a command, executable path, env or cwd
QE03 one exact grant binds Packet, generation, seal, contract, check and environment
QE04 grants are minted only after exact seal and aligned current evidence
QE05 one execution lease is private, opaque and one-use
QE06 one request can launch at most one candidate transaction
QE07 the first provider is linux.qa_supervisor.lua54.v0
QE08 the provider launches one exact trusted supervisor without a shell
QE09 the supervisor owns an embedded/admitted Lua 5.4 runtime
QE10 candidate code never executes in the proc-17 Lua process
QE11 candidate code receives an empty isolated root with source and scratch only
QE12 source is exact, read-only, nosuid, nodev and noexec
QE13 scratch is private tmpfs, writable, noexec and hard bounded
QE14 network, child processes, native modules and inherited descriptors are denied
QE15 no_new_privs, namespace isolation, syscall policy and rlimits are mandatory
QE16 source root identity and exact inventory are verified before and after execution
QE17 output is streamed through bounded supervisor-owned pipes and hashed
QE18 the whole candidate process is terminated/reaped on every outcome
QE19 clean candidate outcomes and infrastructure failures use different protocols
QE20 malformed trusted reports remain loud harness failures
QE21 source drift or cleanup ambiguity quarantines the execution transaction
QE22 exact replay never launches a second process
QE23 private completion without matching body evidence is split-brain and loud
QE24 no private handle, host path or raw output enters Packet evidence
QE25 missing isolation primitives make the provider unavailable with no fallback
QE26 the provider performs no internal retry
```

## 1. Closed Physical Claim

This table defines the maximum future v0 exception to command denial:

```text
One exact sealed and aligned build Packet may consume one private one-use lease
to run its one required Lua 5.4 QA entrypoint inside one bounded Linux sandbox.
```

It does not authorize execution today. It does not define the body-owned check
or final verdict; those belong to the evidence companion table.

## 2. Why This Is Not `run_command`

The existing public command-shaped surfaces are not eligible foundations:

```text
core/sandbox.lua          correctly denies every command
logic/spells.lua          uses io.popen and shell strings
tools/contract.lua        names generic run_command without isolation authority
```

Widening any of them would give semantic data a path to general host execution.
The QA provider instead accepts one exact protocol with no executable selector.

Public request meaning:

```text
run the one check already committed in this birth-bound QA contract against
this exact current seal under this exact registered environment
```

It cannot mean:

```text
run these words
run this binary
run in this directory
use these environment variables
mount these paths
allow these syscalls
```

## 3. Trust And Provider Boundary

Production v0 has two host-side components:

```text
Lua adapter/provider
  validates public request and private lease
  invokes only the exact trusted supervisor protocol
  validates every returned field
  appends no body event itself

native supervisor executable
  starts outside candidate control
  creates the isolated child/root
  embeds or owns the exact admitted Lua 5.4 runtime
  measures, terminates, reaps and reports
```

The supervisor executable and adapter module use a fail-closed trusted install
path, exact provider id and exact ABI/build identity. Task cwd, `package.cpath`,
PATH and candidate files cannot substitute either component.

The host adapter may start the exact supervisor by fixed native process APIs.
No candidate field participates in executable selection and no shell is
involved. The supervisor clears inherited environment and file descriptors
before candidate code exists.

## 4. Private Environment Registry

Conceptual private registry:

```lua
{
  protocol_version = "qa.private_registry.v0",
  session_id = string,

  environments = {
    [environment_id] = {
      public_projection = qa_environment,
      provider_handle = private,
      supervisor_identity = private,
      runtime_identity = private,
      kernel_feature_identity = private,
      isolation_policy = private,
      hard_limits = private,
      state = "available" | "unavailable" | "quarantined",
    },
  },

  grants = private_map,
  transactions = private_map,
}
```

The detached environment projection from the contract table is derived from
this record. Mutating the projection cannot alter provider selection or policy.

Environment quarantine prevents new grants until a trusted host creates a new
registry/environment identity. Candidate output cannot clear it.

## 5. Private QA Grant

Conceptual grant:

```lua
{
  protocol_version = "qa.execution_grant.v0",
  grant_id = "qa-grant:<opaque>",
  session_id = string,
  packet_id = string,
  lineage_id = string,
  generation = integer,
  process_contract_id = string,
  stage_id = string,
  repository_id = string,
  root_authority_id = string,
  candidate_seal_id = string,
  candidate_seal_event_ref = string,
  qa_contract_id = string,
  check_id = string,
  profile_id = "qa.profile.lua54_test_suite.v0",
  environment_id = string,
  resource_limits = exact_limits,
  state = "active" | "running" | "consumed" | "revoked" | "quarantined",
  revision = integer,
  transaction_id = string | nil,
  private_source_handle = private,
}
```

The public grant projection omits `private_source_handle`, supervisor identity
and every executable/root path. A public `grant_id` is a semantic/audit id, not
authority; the private registry and exact current state are also required.

Grant mint gate:

```text
living build Packet
exact birth-bound qa_contract
exact required check
exact current candidate seal
candidate alignment = aligned
private repository root is sealed and belongs to the same generation
exact environment/profile is available
no prior current check/execution-failure/verdict for this request
no ambiguous active grant for the same check
```

Mint performs no process launch and spends no candidate-execution cost.

## 6. Public Check Request

The body derives, rather than accepts, the request:

```lua
{
  protocol_version = "qa.check_request.v0",
  request_id = "qa-check-request:<sha256>",

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

  entrypoint = {
    relative_path = string,
    work_unit_id = string,
    work_unit_version = integer,
    bytes = integer,
    sha256 = string,
    completion_ref = string,
    verification_ref = string,
  },

  expected_exit_codes = {0},
  resource_limits = exact_limits,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed" | "mixed",
}
```

There is no field for command, executable, argv, environment, cwd, source root,
scratch path, mount, namespace, syscall, retry or raw stdin.

Every field participates in request identity except `request_id`. The request
is detached and contains no authority.

Preparation is pure. Before any private lease is consumed, ☶ appends one body
event:

```text
type = qa_check_request
operator = ☶
truth_status = runtime_confirmed
payload = detached qa.check_request.v0
cost = {}
```

The resulting trace event id is `request_ref`. A lease resolver requires both
the canonical request id and this exact current body event. If append fails,
no lease may start. Re-deriving the same current request returns the same
identity and does not authorize duplicate request events or launches.

## 7. Lease And Transaction Lifecycle

Private state graph:

```text
active grant
  -- begin exact request --> running grant + one private transaction/lease

running
  -- exact clean candidate report --> consumed/completed
  -- typed infrastructure failure with proven cleanup --> consumed/failed
  -- source drift, cleanup ambiguity or provider ambiguity --> quarantined
  -- trusted report contradiction --> quarantined + loud harness failure
```

There is no transition:

```text
consumed -> active
quarantined -> active
running -> active by timeout
request A lease -> request B
seal/generation A lease -> seal/generation B
```

The execution lease is opaque and one-use. Validation and consumption happen
before supervisor entry. A provider panic cannot leave it reusable.

## 8. Source View Construction

Amendment: the seven-step direct-bind mechanics below are retained as
archaeology and policy intent, but are not implementation authority after
2026-07-26. The conforming construction is defined by
`qa_detached_source_staging_yellowprint.v0.md`: exact sealed fd -> private
self-bind -> detached `open_tree` clone -> immutable mount attributes ->
`move_mount` at `/qa/source`. A transient procfd-derived pathname is an
identity-checked construction aid, never source authority.

The provider obtains the source only through the private repository/root
identity already bound to the exact candidate seal.

Pre-launch sequence:

```text
1. revalidate private root identity and terminal sealed state
2. take one bounded no-follow inventory using seal bounds
3. compare exact path/kind/bytes/digest set to candidate seal artifacts
4. reject any extra, missing, changed, special or unstable object
5. open/retain only the exact private root identity for namespace construction
6. bind that root into the candidate namespace as /qa/source
7. remount recursively read-only, nosuid, nodev and noexec
```

V0 rejects writable overlays and source copies that become candidate-writable.
The tested source view is the sealed candidate, not a patched derivative.

The supervisor repeats root identity and exact inventory observation after the
candidate is reaped and before a clean report is committed. A mismatch is
`source_drift`, an infrastructure-incomplete outcome. It is never accepted or
ordinary candidate rejection.

The existing threat boundary still excludes a same-authority host actor that
changes and restores bytes entirely between observations. This table does not
claim host-global immutability.

## 9. Isolated Root Layout

The candidate namespace exposes only:

```text
/qa/source     exact sealed root, read-only, nosuid,nodev,noexec
/qa/scratch    private tmpfs, read-write,nosuid,nodev,noexec
```

Required scratch subpaths are supervisor-created:

```text
/qa/scratch/home
/qa/scratch/tmp
```

The namespace exposes no host `/`, `/home`, `/tmp`, `/proc`, `/sys`, `/dev`,
agent socket, repository sibling or proc-17 storage. Supervisor-owned stdin,
stdout and stderr descriptors are sufficient for v0.

The admitted Lua runtime is owned by the trusted supervisor/environment and is
not selected or loaded from `/qa/source`. Candidate native modules are disabled.

## 10. Mandatory Isolation Properties

The CRYSTALL must choose exact syscalls/order, but no implementation is
conforming without all of these properties:

```text
separate supervisor process and candidate address space
exact trusted supervisor exec with cleared environment and close-on-exec fds
fresh user, mount, PID, network, IPC and UTS isolation domains
private mount propagation
minimal empty root pivot/chroot before candidate execution
no_new_privs before candidate code
profile-specific syscall allowlist before candidate code
deny socket/network, ptrace, mount, namespace creation and privilege syscalls
deny fork/vfork/clone and further exec for max_processes=1
fixed rlimits for CPU, address space, descriptors, core and file size
parent-owned monotonic wall-time watchdog
tmpfs size and inode bounds for scratch
whole candidate termination and wait/reap
pre/post exact source inventory
identity-owned cleanup with ambiguity detection
```

If user namespaces, mount isolation, syscall filtering or any other mandatory
primitive is unavailable, `environment.state=unavailable`. There is no chroot-
only, rlimit-only, timeout-only or unsandboxed fallback.

The exact Linux/kernel assumptions and environmental SKIPs remain explicit in
the hostile corpus. A skipped primitive withholds the production claim.

## 11. Lua 5.4 Candidate Runtime

The supervisor executes the profile semantically equivalent to:

```text
Lua 5.4
ignore host environment
cwd = /qa/source
package.path = ./?.lua;./?/init.lua
package.cpath = empty
load and run the exact sealed entrypoint
stdin = EOF
```

The candidate cannot supply Lua options or a startup file. Environment hooks
such as `LUA_INIT` are absent.

The runtime may be embedded in the supervisor or provided by an exact private
runtime image. The selected form and build identity are part of
`environment_id`; CRYSTALL may not switch between them under one id.

## 12. Resource Enforcement

Contract limits are independently validated against provider hard ceilings.

Required enforcement/observation:

| Resource | Enforcement owner | Clean evidence |
|---|---|---|
| wall time | parent watchdog | monotonic elapsed microseconds |
| CPU | kernel rlimit plus wait/rusage | user/system CPU microseconds |
| address space | kernel rlimit | termination classification plus configured bound |
| processes | syscall deny + namespace | exactly one candidate task |
| descriptors | close discipline + rlimit | fixed inherited set, configured bound |
| file size | rlimit | configured bound and termination reason |
| scratch bytes/inodes | tmpfs mount options | final bounded inventory/usage |
| stdout/stderr | parent bounded drain | full observed counts/digests, limit status |

If output exceeds its bound, the supervisor continues only long enough to
terminate/reap safely. It never buffers beyond the hard ceiling or blocks on a
full pipe.

Resource enforcement reached by a correctly isolated candidate produces a
candidate-rejected report with an exact reason. Failure of the supervisor to
enforce, observe or clean is infrastructure failure or invariant corruption.

## 13. Provider Candidate Report

A clean contained candidate outcome has this trusted adapter shape:

```lua
{
  protocol_version = "qa.provider_candidate_report.v0",
  operation = "run_lua54_test_suite",
  request_id = string,
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
}
```

`accepted` requires `reason=expected_exit`, exact exit code zero, complete
source stability and cleanup, and no reached resource/policy bound.

Every other cleanly contained candidate termination is `rejected` under the v0
profile. Raw output bytes and private paths/handles are absent.

## 14. Provider Infrastructure Error

Infrastructure failure uses a distinct protocol:

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

Examples:

| Condition | Error class |
|---|---|
| environment/profile absent before grant | not-ready, no provider call |
| trusted supervisor cannot start cleanly | `unavailable` or `world` |
| namespace/mount setup denied | `unavailable`; no fallback |
| source differs before candidate start | `world/source_drift` |
| source differs after candidate ran | `ambiguous/source_drift` |
| scratch/process cleanup cannot be proven | `ambiguous/cleanup` |
| provider returns impossible fields | not this protocol; loud invariant |

An infrastructure error never becomes an accepted/rejected candidate report.
`code` is a closed v0 vocabulary, not provider prose. Unknown codes are
malformed trusted output and therefore loud invariant failures.

## 15. Output And Leakage Boundary

The supervisor streams stdout/stderr through private bounded hashers.

Body-facing measurement:

```lua
{
  observed_bytes = integer,
  sha256 = string,
  limit_bytes = integer,
  limit_reached = boolean,
}
```

V0 retains no raw stdout/stderr in body events, trace, corpse, carrier, grave or
documentation corpus. Hostile output can contain prompt injection, binary data
or candidate secrets; digest/count evidence is sufficient for the first
mechanical verdict.

A later diagnostic-content store needs its own bounded truth and prompt-
ingestion contract.

## 16. Body Handoff And Split-Brain Law

This section applies only to `transaction_kind=body_execution`. Step D's
`provider_witness` transaction is deliberately forbidden from creating the
receipt or either body-facing side of this join. A D provider witness report is read by
trusted harness assertions only and cannot satisfy this section partially.

After a report is strictly validated, the private registry records one exact
execution receipt before the body event is appended.

Conceptual private receipt:

```lua
{
  protocol_version = "qa.execution_receipt.v0",
  execution_receipt_id = "qa-execution-receipt:<sha256>",

  request_id = string,
  request_ref = string,
  grant_id = string,
  packet_id = string,
  lineage_id = string,
  generation = integer,
  stage_id = string,
  repository_id = string,
  candidate_seal_id = string,
  qa_contract_id = string,
  check_id = string,
  profile_id = string,
  environment_id = string,

  result_kind = "candidate_report" | "provider_error",
  normalized_result_id = "qa-provider-result:<sha256>",
  transaction_disposition = "completed" | "consumed_failed" | "quarantined",
  cost = qa_cost,
  committed = true,
}
```

The receipt is private registry state. The body receives only its detached
audit id plus the normalized result required for strict joining; neither is an
authority handle. Every field except `execution_receipt_id` participates in
canonical receipt identity. `normalized_result_id` is a digest of every field
in the normalized provider report/error and cannot be supplied by the
candidate.

```text
private receipt exists + exact body check/failure exists
  idempotent replay returns same detached evidence, no process

neither exists
  request may execute once with a fresh lease

private receipt exists + body event absent/contradictory
  split-brain invariant; no rerun, grant quarantined, harness loud

body event exists + private receipt absent/contradictory
  split-brain invariant; harness loud
```

The provider does not invent a body event. A dedicated body writer validates
the request, private receipt and report according to the evidence companion
table.

## 17. Economics

Private report cost is measured, bounded and detached:

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

The body/lineage accounting table may project these values into existing budget
categories later. The provider cannot claim token usage or identity loss.

An infrastructure failure reports actual cost already incurred. Denied/not-
ready requests report no provider cost.

## 18. Named Writers And Readers

| Record/state | Writer | Named reader |
|---|---|---|
| environment private record | trusted host registry | grant mint/dispatch |
| detached environment projection | registry projector | QA contract binder |
| private QA grant | host/body capability boundary | request resolver |
| body check request event | ☶ request writer | private grant/dispatch resolver |
| private transaction/lease | grant begin operation | provider adapter |
| pre/post source inventories | trusted supervisor/provider | report validator |
| candidate report | trusted supervisor -> strict adapter | dedicated body check writer |
| infrastructure error | trusted supervisor -> strict adapter | body failure writer/runner |
| private execution receipt | capability registry | idempotence and body writer |
| body check/failure event | companion dedicated writer | verdict/completion readers |

No writer has authority over another row's fact.

## 19. Permanent Controls

### Authority and request

| ID | Control | Expected result |
|---|---|---|
| QE-T01 | QA disabled | no provider load/process/trace/budget delta |
| QE-T02 | unsealed or diverged candidate | no grant/provider call |
| QE-T03 | foreign session/Packet/lineage/generation/stage/seal | no grant match |
| QE-T04 | public grant id without private state | zero authority |
| QE-T05 | mutate returned request/grant projection | private state unchanged |
| QE-T06 | add command/executable/argv/env/cwd/mount field | schema rejection |
| QE-T07 | lease replay | no second supervisor launch |
| QE-T08 | exact request replay after completion | same evidence, no launch |
| QE-T08a | request payload exists without body request event | no lease/launch |

### Isolation and source

| ID | Control | Expected result |
|---|---|---|
| QE-T09 | candidate writes/renames/deletes source | denied; pre/post inventory exact |
| QE-T10 | candidate opens host HOME/proc-17 stores | absent/denied |
| QE-T11 | candidate opens network/socket | absent/denied |
| QE-T12 | candidate forks or executes child | denied; one task reaped |
| QE-T13 | candidate loads native module | unavailable/denied |
| QE-T14 | symlink/special/extra source appears | preflight rejection, no launch |
| QE-T15 | source changes during run | infrastructure/source_drift, no check verdict |
| QE-T16 | tool writes cache beside source | denied; source exact |
| QE-T17 | mandatory namespace/seccomp primitive absent | provider unavailable, no fallback |

### Resources and failures

| ID | Control | Expected result |
|---|---|---|
| QE-T18 | infinite loop | bounded kill/reap and rejected timeout report |
| QE-T19 | memory pressure | bound holds; rejected resource report |
| QE-T20 | stdout/stderr flood | bounded drain/hash, rejected output report |
| QE-T21 | scratch byte/inode pressure | bounded, rejected report, cleanup |
| QE-T22 | supervisor/provider panic | no reusable lease; loud or typed infrastructure failure |
| QE-T23 | malformed report/impossible cost | quarantine and loud harness failure |
| QE-T24 | cleanup ambiguity | quarantine, no candidate report/verdict |
| QE-T25 | private receipt/body event split | no rerun; loud invariant |
| QE-T26 | repeated hostile lives | no process/fd/mount/scratch residue |
| QE-T27 | provider error names another request/profile/environment | strict rejection and transaction quarantine |

Real isolation controls use malicious fixtures through the QA supervisor, not
ordinary shell execution in the Lua test harness.

## 20. Cross-Contract Consequences

The evidence table must not accept a provider report directly from a caller.
It must join:

```text
body-derived request
private execution receipt
strictly normalized report/error
current Packet/seal/contract identities
```

The completion/work-layer reader consumes only body-owned check/verdict events,
never private registry state or provider output.

Candidate seal/root state stays terminal regardless of QA result.

## 21. Explicit Deferrals

```text
generic command execution
external executable profiles
multi-process/service/network QA
writable source overlays
dependency installation/download
raw log persistence or prompt ingestion
privileged/root supervisor fallback
resume after host process restart
retry inside provider
parallel QA transactions
more than one required check
QA child Packet
repository cleanup after terminal generation
```

## 22. Closed Chaos Questions

```text
Q4  mandatory properties: exact native supervisor, namespaces, no_new_privs,
    syscall policy, rlimits, watchdog, bounded tmpfs, no fallback
Q5  source view: fd-authoritative detached exact mount, pre/post inventory,
    read-only namespace; direct-bind mechanics superseded by the 2026-07-26
    detached-source staging table
Q6  scratch: private bounded tmpfs; source caches forbidden
Q7  request: derived ids/entrypoint/limits only; no command-shaped fields
Q8  clean candidate report and infrastructure error use distinct protocols
Q11 output: counts/digests only, no raw body content in v0
Q12 one-use request/lease/private receipt gives idempotence and split-brain law
Q15 private grant/transaction/environment writers and readers are named
Q16 native/fault/environmental hostile controls are required for isolation
```

## 23. Table Thesis

```text
The QA hand does not receive a command. It receives one already-owned question
about one already-sealed candidate, and the private body grants exactly enough
host physics to let that question meet consequence once.
```
