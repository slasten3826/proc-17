# QA Hostile Execution Campaign Yellowprint v0

Status:

```text
layer: TABLE
date: 2026-07-28
chapter: 8.5.5E
source: docs/00_chaos/second_qa_hand_hostile_campaign_notes_2026-07-28.md
scope: QN17-QN20 provider physics only
crystallization authorized: no; cross-table audit required
runtime implementation authorized: no
Packet QA authority: forbidden
body check/verdict/completion/tree authority: forbidden
```

Gate amendment 2026-07-28:

```text
cross-table audit satisfied
CRYSTALL authorized by:
  docs/00_chaos/qa_hostile_execution_table_cross_audit_2026-07-28.md
runtime implementation remains forbidden until crystall audit
```

## 0. Table Thesis

Step E promotes no new body fact. It strengthens the private provider boundary
so that later body code can receive one of two honest inputs:

```text
definitive candidate observation
typed infrastructure failure
```

A trusted contradiction remains loud and is neither input.

## 1. Scope And Non-Scope

Owned here:

```text
native RUN v1 phase/result/error vocabulary
candidate-cause witness rules
hostile candidate outcome corpus
trusted fault-only harness
cleanup ambiguity disposition
bounded repeated-run residue corpus
QN17-QN20 exact promotion delta
```

Not owned here:

```text
qa_check_request
private body QA grant or execution receipt
qa_check / qa_execution_failure body events
qa_verdict
Packet economics
completion/work-layer/manifest/corpse readers
router pressure or promotion
generic commands, argv, stdin, environment or cwd
```

## 2. Existing Contracts Preserved

The campaign preserves without aliases:

```text
qa.profile.lua54_test_suite.v0
entrypoint tests/run.lua
expected exit code 0
stdin closed
arguments empty
raw output retention false
exact current candidate seal
one-use repository source lease
detached read-only/noexec source staging
fresh static Lua process
```

The provider-witness protocol remains private and cannot enter body writers.

## 3. Native Protocol Revision

Step E introduces a closed native revision:

```text
qa.native_run_request.v1
qa.native_run_started.v1
qa.native_run_result.v1
qa.native_run_error.v1
```

`v0` remains archaeology for the QN16/D evidence record. The production
provider migrates atomically; it does not accept mixed v0/v1 request/result
pairs.

Every v1 record binds:

```text
transaction_id
witness_id
profile_id
environment_id
request nonce/digest
protocol version
```

Unknown keys, enum values, phases, duplicate frames and trailing bytes are
trusted invariant failures.

## 4. Phase Machine

The trusted launcher observes one closed sequence:

```text
REQUEST_WRITTEN
  -> zero or one STARTED frame
  -> zero or one TERMINAL frame
  -> supervisor process terminal/reap
  -> result-pipe EOF
```

Legal successful sequence:

```text
request -> started(ordinal=1) -> terminal(ordinal=2) -> reap -> EOF
```

Legal pre-start infrastructure failure:

```text
request -> terminal_error(ordinal=1, start_state=not_started)
        -> reap -> EOF
```

All other incomplete sequences become typed infrastructure ambiguity only when
the launcher can still prove its own reap/EOF facts. Contradictory or malformed
sequences are loud after private source quarantine.

## 5. Start Attestation

`qa.native_run_started.v1` contains exactly:

```lua
{
  protocol_version = "qa.native_run_started.v1",
  transaction_id = digest_id,
  witness_id = digest_id,
  profile_id = exact_profile_id,
  environment_id = exact_environment_id,
  phase_ordinal = 1,
  source_staging_policy = "qa.source_staging.detached_mount.v0",
  source_staging_complete = true,
  candidate_process_token = bounded_private_digest,
  event_truth_status = "runtime_confirmed",
}
```

The process token is private launcher/supervisor evidence. It never enters Lua,
provider witness, trace or corpus.

Implementation amendment 2026-07-28:

`STARTED` is a C-private wire phase. The native launcher validates its token,
identity, source and terminal join before returning one sanitized terminal
table. There is no raw STARTED table or process-token field in the Lua ABI.
See `docs/00_chaos/qa_started_native_visibility_amendment_2026-07-28.md`.

STARTED means the isolated candidate process exists after environment, limits,
capability drop and seccomp installation, immediately before candidate chunk
execution. It does not mean success or terminality.

## 6. Candidate Result

`qa.native_run_result.v1` is legal only with a matching STARTED frame and all
finality flags true:

```lua
{
  protocol_version = "qa.native_run_result.v1",
  identity_fields = exact_join,
  phase_ordinal = 2,
  disposition = "contained_candidate",
  reason = candidate_reason,
  termination = exact_termination,
  finality = {
    candidate_terminal_observed = true,
    process_tree_reaped = true,
    stdout_eof_observed = true,
    stderr_eof_observed = true,
    scratch_observation_complete = true,
    namespace_cleanup_complete = true,
  },
  stdout = stream_measurement,
  stderr = stream_measurement,
  resources = resource_measurement,
  scratch = scratch_measurement,
  cause = cause_witness,
  event_truth_status = "runtime_confirmed",
}
```

One false/missing finality member invalidates the candidate result and routes to
infrastructure ambiguity. It cannot be normalized as a partial rejection.

## 7. Infrastructure Error

`qa.native_run_error.v1` contains:

```lua
{
  protocol_version = "qa.native_run_error.v1",
  identity_fields = exact_join,
  phase_ordinal = 1 | 2,
  class = "unavailable" | "world" | "ambiguous",
  code = closed_error_code,
  stage = closed_error_stage,
  candidate_start_state = "not_started" | "started" | "unknown",
  cleanup_state = "complete" | "incomplete" | "unknown",
  launcher_reaped = true | false | "unknown",
  result_eof = true | false | "unknown",
  measured_cost = bounded_cost_or_nil,
  event_truth_status = "runtime_confirmed",
}
```

Ownership amendment 2026-07-28:

The table above is the sanitized native-to-Lua terminal record, not the
supervisor wire payload. The supervisor ERROR frame carries start state,
namespace-cleanup state, measured cost and source-stage summary only.
`launcher_reaped` and `result_eof` are appended by the launcher after it
observes those facts itself. No wire writer may attest to a later launcher's
observation.

Closed error codes for Step E:

```text
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

Malformed trusted frames, identity contradictions and impossible combinations
are not members of this error protocol. They are loud invariants.

## 8. Candidate Reason Derivation

The supervisor records the first causally terminal event in a private monotonic
cause slot. Later measurements may validate but cannot replace it.

| Reason | Required cause witness |
|---|---|
| `expected_exit` | wait status exit 0; no earlier terminal cause |
| `unexpected_exit` | wait status nonzero; no stronger limit/policy witness |
| `signal` | wait status signal; no stronger limit/policy witness |
| `wall_timeout` | monotonic wall timer fired first; supervisor kill sent; complete reap |
| `cpu_limit` | kernel CPU-limit termination or exact CPU-limit event; wall timer did not win |
| `memory_limit` | trusted bounded allocator denied allocation under declared heap ceiling |
| `output_limit` | trusted stdout or stderr observed-count crossing caused termination |
| `scratch_limit` | reserved until a trusted write-denial hook exists; not emitted by Step E |
| `sandbox_policy_violation` | SIGSYS under active exact seccomp policy; no candidate-accessible signal forgery |

No reason is derived from error text, fixture id, filename, elapsed-time guess
or exit code alone.

## 9. Measured Environment Amendment

The measured QA environment binds two separate memory ceilings:

```text
address_space_bytes = 268435456
runtime_heap_bytes  = 67108864
```

`runtime_heap_bytes` is a fixed provider policy value, not a caller-selectable
request field. It is added to the measured environment schema, policy digest
and environment identity. The v1 request binds that exact environment id while
retaining the existing closed resource-limit surface. The bounded Lua allocator
owns exact current/peak/denied measurements.

The environment schema is revised explicitly to `qa.environment.v1`. Existing
contracts bound to the historical environment id become unavailable and must
not silently upgrade. The profile id and its command-free invocation surface
remain unchanged.

Resource measurement contains:

```lua
{
  wall_time_ms,
  cpu_user_ms,
  cpu_system_ms,
  max_rss_bytes,
  address_space_limit_bytes,
  runtime_heap_peak_bytes,
  runtime_heap_limit_bytes,
  runtime_heap_denied,
  max_processes,
  max_open_files,
  max_file_bytes,
}
```

`memory_limit` requires `runtime_heap_denied=true`. RLIMIT_AS remains a hard
containment boundary, but an otherwise unexplained allocation failure remains
`unexpected_exit` or infrastructure failure according to complete evidence.

## 10. Stream Measurement

stdout and stderr use separate pipes and separate records:

```lua
{
  protocol_version = "qa.stream_measurement.v1",
  observed_bytes = non_negative_integer,
  hashed_bytes = non_negative_integer,
  sha256 = tagged_digest,
  limit_bytes = hard_limit,
  limit_reached = boolean,
  eof_observed = true,
  raw_retained = false,
}
```

Rules:

```text
hashed_bytes <= observed_bytes
hashed_bytes <= limit_bytes
limit_reached iff observed_bytes > limit_bytes
digest covers exactly the first hashed_bytes in stream order
the parent drains/discards bounded chunks until EOF after termination
no raw bytes cross the native adapter
```

If either EOF is missing, no candidate result exists.

## 11. Scratch Measurement

Scratch uses a trusted final walk plus filesystem capacity observation:

```lua
{
  protocol_version = "qa.scratch_measurement.v1",
  stored_regular_bytes = non_negative_integer,
  stored_entries = non_negative_integer,
  limit_bytes = hard_limit,
  limit_entries = hard_limit,
  byte_capacity_exhausted = boolean,
  entry_capacity_exhausted = boolean,
  inventory_complete = true,
}
```

Rules:

```text
stored_regular_bytes <= limit_bytes
stored_entries <= limit_entries
capacity exhaustion is a final kernel/filesystem observation, not proof of the
earlier write that caused candidate termination
Step E therefore never derives scratch_limit from this record
candidate error text or exit code cannot add the missing causal witness
```

No impossible `stored > bound` requirement remains.

## 12. QN17 Exact Fixture Matrix

All candidate fixtures execute only inside production supervisor identity.

| Fixture id | Expected reason | Expected provider outcome |
|---|---|---|
| candidate-clean-exit | expected_exit | accepted |
| candidate-nonzero-exit | unexpected_exit | rejected |
| candidate-lua-error | unexpected_exit | rejected |
| candidate-cpu-loop | cpu_limit | rejected |
| candidate-wall-loop | cpu_limit in v0 profile; fixture is CPU spin under closed stdin | rejected |
| candidate-allocator-exhaustion | memory_limit with allocator denial | rejected |
| candidate-stdout-flood | output_limit, stdout crossing | rejected |
| candidate-stderr-flood | output_limit, stderr crossing | rejected |
| candidate-scratch-exhaustion | unexpected_exit; scratch remains within bound and final observation is complete | rejected |
| candidate-source-mutation | expected_exit plus exact source stability | accepted |
| candidate-host-path-probe | expected_exit | accepted |
| candidate-socket-attempt | expected_exit; Lua/native surface absent | accepted |
| candidate-fork-attempt | expected_exit; process API absent | accepted |
| candidate-exec-attempt | expected_exit; exec API absent | accepted |
| candidate-native-module-attempt | expected_exit; native loader absent | accepted |
| candidate-fd-escape | expected_exit; descriptor namespace absent | accepted |
| candidate-sigsys | expected_exit; tests API closure only | accepted |

The actual seccomp SIGSYS path remains independently proven by QN13. QN17 does
not relabel the API-closure fixture as a syscall event.

Every row also requires:

```text
pre inventory == seal inventory == post inventory
source lease terminal once
all candidate finality flags true
no host sentinel visibility
Packet/public root/economics ablation equality
```

## 13. QN18 Trusted Fault Matrix

Fault selection exists only in test-owned native builds with a distinct build
identity.

| Fault id | Expected boundary |
|---|---|
| trusted-wrong-launcher-abi | production loader rejects before RUN |
| trusted-wrong-supervisor-identity | launcher rejects exact identity before candidate |
| trusted-malformed-request-frames | supervisor rejects; no STARTED frame |
| trusted-malformed-result-frames | source quarantine then loud invariant failure |
| trusted-crash-before-start | infrastructure `supervisor_crashed`, start not_started/unknown |
| trusted-crash-after-start | infrastructure `supervisor_crashed`, start started |
| trusted-lost-result-pipe | infrastructure `result_pipe_lost`, never candidate outcome |
| trusted-wait-reap-ambiguity | infrastructure `reap_ambiguous` |
| trusted-postflight-source-drift | provider ambiguous `source_drift`, source quarantined |

Production exclusion controls require:

```text
no fault key in request/result schema
no environment variable fault selector
no fault function in Lua module API
no fault symbol in production shared/static closure
test build id rejected by production loader
```

## 14. QN19 Disposition Matrix

| Evidence state | Native/provider result | Source disposition |
|---|---|---|
| definitive candidate + complete source | witness report | consumed |
| definitive pre-start world error + complete source/cleanup | witness error | consumed |
| STARTED without definitive terminal/reap/EOF/scratch/namespace proof | ambiguous error | quarantined |
| postflight source drift | ambiguous source_drift | quarantined |
| malformed/contradictory trusted result | loud after best-effort quarantine | quarantined or loud unknown, never consumed as clean |

No row maps ambiguity to accepted or rejected.

## 15. QN20 Residue Contract

The repeated campaign runs 32 transactions over 32 fresh sealed roots,
alternating clean exit and Lua runtime error. Resource-termination cleanup is
already exercised in QN17 and is not repeated 32 times.

Before the loop, after every iteration and after final Lua GC/handle closure,
the trusted harness records:

```text
launcher/provider process descriptor count
the exact launcher-owned pid/pidfd ledger and terminal reap state
the count of mountinfo entries carrying the unique proc17 harness identity
harness temporary-root identity set
repository source lease terminal projection
host sentinel identities
Packet/public-root/economics ablation digest
```

Acceptance:

```text
descriptor count returns to baseline each iteration
every launcher-owned child has one terminal reap and no live pidfd
no proc17 harness mount identity remains visible in the host namespace
each temporary root is removed only by its identity-owned cleanup
every source lease is consumed/quarantined exactly once
host sentinels are unchanged
Packet/root/economics ablation remains equal
```

The claim is named-channel residue freedom, not universal proof of zero heap
leaks or stable RSS.

## 16. Harness Topology

```text
ordinary Lua runner
  -> reads fixture metadata only
  -> invokes one fixed Make target

trusted campaign harness
  -> fixture guard reads inert bytes
  -> first hand materializes disposable root
  -> candidate seal closes source
  -> production provider executes candidate fixture
  -> provider witness assembler validates pre/post/finality
  -> identity-owned cleanup removes disposable harness state
```

Trusted fault targets use separate test-only binaries and never materialize
their instruction files as candidate source.

Required targets:

```text
qa-supervisor-hostile-fixtures-test     -> QN17
qa-supervisor-trusted-fault-test        -> QN18
qa-supervisor-cleanup-ambiguity-test    -> QN19
qa-supervisor-leak-loop-test            -> QN20
```

A target must execute its complete named corpus and print a closed count. Empty
targets, aliases to QN16 and skipped rows fail.

## 17. Writers And Readers

| Fact | Writer | First reader | May reach Packet? |
|---|---|---|---|
| start attestation | production supervisor | trusted launcher phase machine | no |
| terminal/cause fact | kernel + supervisor | launcher v1 decoder | no |
| stream facts | launcher/supervisor bounded drains | strict process normalizer | no raw content |
| allocator denial | trusted Lua allocator | supervisor result assembler | no direct |
| scratch facts | trusted namespace final inventory | strict process normalizer | no direct |
| native infrastructure error | launcher phase machine | strict process normalizer | no |
| process observation/error | strict Lua adapter | provider witness assembler | no |
| source disposition | repository registry | witness assembler/replay tests | no |
| QN control outcome | trusted test harness | red battery | test evidence only |

Absent by law:

```text
Packet QA request writer
execution receipt writer
qa_check writer
qa_verdict writer
completion/router reader
```

## 18. Truth Status

```text
kernel/supervisor/launcher measurements       runtime_confirmed
provider witness after source finality        runtime_confirmed
applicability to a future body QA request     not yet represented
fixture expected matrix                       document_decision
test-only injected fault                      test_control, never production fact
```

## 19. Exact Promotion Delta

Input:

```text
red matrix 40 green / 44 red
native     16 green / 4 red
```

Output:

```text
red matrix 44 green / 40 red
native     20 green / 0 red
```

Only QN17-QN20 may change. Body QE/QV and completion/router controls remain
red. Ordinary and mortality suites remain green.

## 20. Permanent Controls

```text
HE01 v0/v1 mixed phase sequence rejects
HE02 duplicate STARTED or TERMINAL rejects loudly
HE03 final candidate result with one false finality bit becomes ambiguity
HE04 absent STARTED never becomes not_started without positive proof
HE05 exit 70 without denial remains unexpected_exit
HE06 generic SIGKILL cannot become timeout/CPU reason
HE07 memory_limit requires allocator denial
HE08 stdout/stderr remain independent and raw-free
HE09 missing stream EOF yields ambiguity
HE10 scratch stored use never exceeds declared bound
HE11 Step E cannot emit scratch_limit without a future trusted write-denial hook
HE12 wall fixture cannot claim wall_timeout under current bytes
HE13 SIGSYS fixture cannot claim SIGSYS under API-only bytes
HE14 every QN17 fixture executes only inside production supervisor
HE15 fault controls are absent from production ABI and identity
HE16 crash/lost pipe never becomes candidate rejection
HE17 cleanup ambiguity quarantines source
HE18 malformed trusted terminal is loud after finality attempt
HE19 QN20 restores every named residue channel on every iteration
HE20 QN17-QN20 are the only red-to-green controls
HE21 Packet/public root/economics remain unchanged
HE22 old environment contract cannot silently accept revised provider identity
```

## 21. Implementation Order Constraint

CRYSTALL must preserve this dependency order:

```text
E1 v1 schemas and reason/finality validator
E2 supervisor cause ledger and separate stream/scratch/resource witnesses
E3 launcher phase machine and typed infrastructure errors
E4 strict Lua adapter/provider witness migration
E5 QN17 production hostile corpus
E6 QN18 test-only trusted fault corpus
E7 QN19 ambiguity/source disposition corpus
E8 QN20 repeated residue corpus and exact matrix audit
```

Every slice runs ordinary, mortality, native and expected-red matrices. No later
slice begins after an unauthorized color change.

## 22. Explicit Deferrals

```text
body QA execution transaction (8.5.6)
check/verdict/completion/tree readers
generic toolchain or command profiles
parallel checks, retry or resume
raw diagnostic retention
universal leak-freedom claim
wall-timeout production fixture under the closed-stdin profile
repository/candidate compost
```

## 23. TABLE Exit Gate

Before CRYSTALL:

```text
all T1-T12 chaos questions have an owner above
cross-table audit checks existing QA contract/provider/candidate-seal joins
the v1 revision does not widen public request authority
the expected-red delta remains exactly four controls
```
