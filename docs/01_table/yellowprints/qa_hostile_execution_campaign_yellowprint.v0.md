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

E4.0a gate amendment 2026-07-28:

```text
private status + allocator-survival amendment accepted by:
  docs/00_chaos/qa_measurement_e4_status_amendment_cross_audit_2026-07-28.md
implementation authority follows CRYSTALL section 15 only
RUN v1 and Packet/body QA authority remain forbidden
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

### 5.1 E4.0a private status and release boundary

Implementation amendment 2026-07-28:

The public STARTED pipe is not the controller channel. The candidate prelude
also owns exactly one C-private endpoint of a controller-created
`AF_UNIX/SOCK_SEQPACKET|SOCK_CLOEXEC` pair. It has no Lua name, userdata,
environment field, path, integer projection or public protocol representation.

The fixed private packet is 184 bytes:

```text
offset  bytes  field
0       8      magic = "P17QAST\0"
8       2      version = 1
10      2      kind: READY=1, RELEASE=2, HEAP_DENIED=3
12      4      packet_bytes = 184
16      8      conversation sequence
24      128    transaction/witness/profile/environment identity join
152     32     private candidate process token
```

No reserved or variable-length region exists. Exact legal conversation:

```text
candidate  -> READY(sequence=1), after public STARTED write+close
controller -> RELEASE(sequence=2), after READY validation and wall-timer arm
candidate  -> zero or one HEAP_DENIED(sequence=3)
candidate terminal -> endpoint EOF
```

The candidate blocks before loading candidate bytes until exact RELEASE. A
missing, duplicate, malformed, reordered or identity/token-mismatched packet is
infrastructure failure. Public STARTED followed by private READY/RELEASE failure
remains `started` infrastructure failure, never candidate rejection.

The amended descriptor law is:

```text
the public STARTED descriptor closes before candidate bytes;
all candidate-reachable non-stdio descriptors close before candidate bytes;
exactly one C-private status endpoint remains until candidate termination;
Lua cannot name, enumerate, read, write or close that endpoint;
status EOF is required before candidate finality can complete.
```

The trusted path uses record-preserving `write`/`read` on the seqpacket socket,
not `send`/`recv`; no network-shaped syscall is added to candidate seccomp.
Reads use a 185-byte buffer and accept exactly 184 bytes, so oversized records
cannot truncate into validity. The trusted prelude ignores `SIGPIPE` before
seccomp and changes the candidate endpoint to nonblocking after RELEASE.

The controller is the only first-cause writer. `HEAP_DENIED` is a bounded
wakeup witness; it does not itself own or duplicate allocator truth.

### 5.2 Split phase authority amendment (E5.0, 2026-07-28)

The candidate and controller do not share one mutable phase object. The
candidate owns a short-lived `STARTED` writer state that proves one atomic
public write and close. The controller owns the supervision phase state.

Only the private status decoder, after validating exact `READY(sequence=1)`,
may record `started_attested` in the controller state. This attests that the
fixed trusted prelude already wrote and closed public STARTED. The controller
then arms the wall timer, authorizes release and writes exact `RELEASE(2)`.

The launcher independently validates the actual public STARTED frame. READY is
therefore a controller-side causal witness, not an alias or replacement for
public STARTED. Shared phase/cause memory and direct caller assertion remain
forbidden.

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

### 6.1 Private controller report amendment

E4.5 transports namespace-local evidence in one exact 572-byte private record,
not a public wire kind. It binds the identity join and private process token;
reason, termination and immutable first cause; the first seven finality facts;
status EOF, stable allocator observation, zero/one HEAP_DENIED count, allocator
current reservation and both sticky failure flags; both streams, resources,
scratch and source-stage summary. Reserved bytes are zero and multi-byte fields
use QA network byte order.

The namespace controller cannot set `namespace_cleanup_complete`. The
top-level supervisor validates the private record only after reaping the
controller, then writes that eighth fact and assembles the existing public
RESULT. A malformed record, abnormal controller exit, identity/token mismatch,
missing status EOF, unstable allocator page or notification/page disagreement
suppresses candidate RESULT and is infrastructure ambiguity.
An observed in-budget host allocator failure follows the same suppression law;
it is not projected as candidate `unexpected_exit`.

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

E4.3 arbitration amendment 2026-07-28:

One `poll()` return is one observation epoch. The controller classifies every
ready source before cause selection. Zero distinct cause kinds continues; one
claims the slot; multiple distinct kinds are infrastructure ambiguity. Two
stream crossings collapse only to the same `output_limit` kind while retaining
both measurements. Descriptor order and canonical tie-break never select
physical cause. After a cause exists, wait status is finality rather than a new
cause candidate.

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

Candidate wall time starts when the controller arms an absolute monotonic
timer immediately before private RELEASE. Candidate CPU/RSS comes only from
`wait4(candidate_pid)`; namespace-controller rusage and the outer watchdog are
infrastructure evidence. Simultaneous new pidfd/timer readiness without an
existing cause is ambiguous, not guessed.

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

E4.0a allocator-survival amendment:

One fixed anonymous shared telemetry record is initialized before candidate
fork. The trusted candidate allocator is its only post-fork writer; the
controller is read-only and reads it after HEAP_DENIED notification or
candidate reap. Candidate Lua receives neither its address nor an API that can
reach it.

```text
protocol/version              fixed private C ABI
ceiling_bytes                 immutable policy value
current_bytes                 atomic, allocator-owned
peak_bytes                    atomic monotonic maximum
ceiling_denied                atomic sticky boolean
system_allocation_failed      atomic sticky boolean
status_notification_failed    atomic sticky boolean
```

The record is the sole allocator measurement truth. The private status packet
only wakes the controller. A denial notification without `ceiling_denied`, a
denial flag without its exact notification, an unlocked/non-stable ABI, or a
notification failure is infrastructure ambiguity. Abrupt candidate death may
leave `current_bytes` nonzero but cannot erase `peak_bytes` or sticky flags.

Every mutable telemetry field uses a proved lock-free interprocess atomic.
Layout, size, alignment and lock-free support are build/runtime gates. A host
that cannot prove them is unavailable before candidate start; process-local
locks and shared phase/cause fields are forbidden.

`current_bytes` and `peak_bytes` measure allocator reservations, not RSS. An
in-budget request is published before entering host `malloc/realloc`; host
failure sets its separate sticky flag and rolls current back, while peak keeps
the maximum authorized reservation. This ordering prevents abrupt death
between host allocation and telemetry publication from erasing the peak.

`memory_limit` requires the exact HEAP_DENIED notification,
`ceiling_denied=true` and `system_allocation_failed=false`. A run where both
failure flags are true is infrastructure ambiguity. System allocation failure
can never establish or be laundered into `memory_limit`.

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

The walk is bound by `PROC17_QA_SCRATCH_MAX_DEPTH = 64`, which is part of the
isolation policy digest. Depth zero is `/qa/scratch`; direct children have
depth one. The controller pins and records the scratch root plus the exact
empty `home` and `tmp` directories before release. Those trusted directories
do not count as candidate entries, while their descendants do.

Rules:

```text
stored_regular_bytes <= limit_bytes
stored_entries <= limit_entries
capacity exhaustion is a final kernel/filesystem observation, not proof of the
earlier write that caused candidate termination
Step E therefore never derives scratch_limit from this record
candidate error text or exit code cannot add the missing causal witness
baseline replacement/mutation/disappearance, symlink/special objects,
depth/count/byte overflow, mount crossing or observation failure is
infrastructure ambiguity
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
| private ready/release phase | candidate prelude + namespace controller | namespace controller phase machine | no |
| terminal/cause fact | kernel + supervisor | launcher v1 decoder | no |
| stream facts | launcher/supervisor bounded drains | strict process normalizer | no raw content |
| allocator telemetry | trusted Lua allocator | namespace controller telemetry reader | no direct |
| allocator denial notification | trusted Lua allocator | namespace controller first-cause writer | no |
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
HE23 no candidate byte loads before exact private RELEASE
HE24 READY before public STARTED close is infrastructure failure
HE25 malformed/duplicate/reordered private status is infrastructure failure
HE26 Lua cannot name or operate the private status endpoint or allocator record
HE27 abrupt candidate death preserves allocator peak and sticky flags
HE28 allocator notification/telemetry mismatch is infrastructure ambiguity
HE29 shared phase/cause state is forbidden; only allocator measurement is shared
HE30 missing private status EOF suppresses candidate result
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

Implementation amendment 2026-07-28:

The sequence above is the original TABLE decomposition and remains archaeology.
Executable numbering is superseded by CRYSTALL section 15. At checkpoint
`a194b1a`, E1-E3 of that sequence are complete; E4 begins with E4.0a, the
private status and allocator-survival amendment in sections 5.1 and 9 here.

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

## 24. E6 Provider Witness V1 Amendment

Amended 2026-07-28 from runtime evidence after E5.

The Step-D final objects are exact closed schemas:

```text
qa.provider_witness_report.v1
  identity + accepted/rejected reason
  termination + cause + all finality
  exact pre/post inventory ids
  source disposition = consumed
  stream/resource/scratch/cost v1

qa.provider_witness_error.v1
  identity + closed class/code/stage
  candidate start tri-state
  source stable state + terminal disposition
  cleanup/reap/EOF tri-states
  optional measured cost v1
```

No boolean may replace an `unknown` process fact. No zero cost is fabricated
when no process measurement exists. `cleanup=true` is not copied beside the
authoritative finality record.

The source callback returns only an untagged pending join. The repository
registry writes terminal disposition before the witness assembler may create a
v1 report/error. A failed disposition creates no final witness object.

Packet ablation includes `runtime.budget`. Step D receives no lineage budget
handle, imports no lineage writer and changes no Packet/public-root/economic
state. This amendment authorizes no body QA transaction or red-control delta.

## 25. E7 QN17 Harness Precision Amendment

Amended 2026-07-28 from the E6 production witness boundary.

The dedicated QN17 harness is the only executable reader of candidate fixture
bytes. It remains outside `tests/run.lua` and executes only `class=candidate`.
It requires a closed count of 17 and validates marker, embedded id, local
filename and byte ceiling before materialization.

The exact bytes are written unchanged as `tests/run.lua` by the first hand into
one fresh identity-owned root per row. The harness does not use `load`,
`loadfile`, `dofile`, direct repository filesystem writes or QN16 candidate
directories. Every row crosses candidate seal, source lease, production RUN v1
and provider witness v1.

Expected reason/outcome comes from a closed matrix independent of the
descriptive fixture `pressure` field. Entry bytes and SHA-256 must bind the
original inert record. Every successful row also requires:

```text
report protocol = qa.provider_witness_report.v1
cause.kind = reason
all eight finality facts = true
source disposition = consumed
seal inventory id = pre inventory id = post inventory id
no raw content, path, fd, repository handle or process token
```

The target must print and enforce exactly:

```text
executed=17 matched=17 source_drifts=0 cleanup_ambiguities=0
```

The only authorized control change is QN17 red to green, producing
`41 green / 43 red`. QN18-QN20 and every body QE/QV control remain unchanged.

## 26. E8 QN18 Trusted-Fault Precision Amendment

Amended 2026-07-28 from the production E5-E7 boundaries.

### 26.1 Faults have named owners

The nine `class=trusted_fault` records are inert test instructions. They are
never candidate source and never production request data.

```text
wrong launcher ABI          production Lua loader
wrong supervisor identity  production launcher identity verifier
malformed request           production supervisor decoder
malformed result            production launcher collector + source finality
crash before/after STARTED  production launcher collector
lost result pipe            production launcher collector
wait/reap ambiguity         production launcher collector
postflight source drift     production provider-witness transaction
```

The campaign may join evidence from these owners but may not reassign the
underlying fact.

### 26.2 Exact infrastructure results

| Observation | class/code/stage | start | reap | result EOF |
|---|---|---|---|---|
| child exits dirty before STARTED and pipe reaches EOF | unavailable / supervisor_crashed / supervision | not_started | complete | complete |
| STARTED then child exits dirty and pipe reaches EOF | unavailable / supervisor_crashed / supervision | started | complete | complete |
| result descriptor read fails | ambiguous / result_pipe_lost / supervision | known from STARTED ledger | complete after owned kill/reap, otherwise unknown | unknown |
| wait/reap ownership fails | ambiguous / reap_ambiguous / cleanup | known from STARTED ledger | unknown | observed value only |

Unknown facts remain unknown. A generic collector/system failure cannot be
reported as `result_pipe_lost`. Read-channel and reap ownership failures are
different physical witnesses.

Malformed trusted terminal bytes are not represented by the table above. They
are a loud trusted invariant after the source-finality layer has attempted
quarantine. They never become a process-error object or candidate outcome.

### 26.3 Frame sub-campaigns

Both malformed frame rows execute exactly:

```text
short, oversized, wrong_magic, wrong_version,
unknown_kind, digest_mismatch, trailing
```

Request variants cross the real supervisor decoder and emit zero STARTED
frames. Result variants cross the real launcher v1 collector and all fail as
trusted invariants. One passing variant does not satisfy the row.

### 26.4 Test-only closure

The distinct test closure consists of:

```text
native/tests/proc17_qa_fault_testing.h
native/tests/proc17_qa_launcher_fault_test.so
native/tests/proc17_qa_supervisor_fault_test
native/tests/test_proc17_qa_trusted_faults
```

Production sources may expose test-only seams only below
`PROC17_QA_FAULT_TESTING`. The production build never defines it. The test
launcher ABI and test supervisor digest differ from production. The selector
is a closed enum inside the parameterless native driver and is absent from the
wire, environment, Lua API and candidate source.

### 26.5 Production exclusion

QN18 fails unless all are true:

```text
production request/result schemas have no fault key
production Lua module exports no fault function
production supervisor/launcher artifacts contain no fault symbol, fixture id
or test build identity
production loader rejects the test launcher module
production launcher identity verifier rejects the test supervisor binary
```

### 26.6 Campaign gate

The parameterless target `qa-supervisor-trusted-fault-test` requires:

```text
declared=9 executed=9 matched=9 candidate_outcomes=0
```

It also requires trusted-invariant source quarantine and postflight-drift
source quarantine as separate policy witnesses. The only authorized matrix
change is QN18, from `41/43` to `42/42`.

## 27. E9 QN19 Cleanup-Ambiguity Precision Amendment

Amended 2026-07-28 from the E9 runtime diagnosis in
`docs/00_chaos/qa_e9_qn19_cleanup_ambiguity_notes_2026-07-28.md`.

### 27.1 Existing QN19 text is insufficient

Section 14 remains the high-level disposition law. This section supersedes its
implementation detail. Runtime diagnosis proved that the current field-wise
error validator accepts the impossible tuple:

```text
reap_ambiguous + preflight + not_started + cleanup complete
```

and provider witness consequently writes `consumed`. QN19 cannot promote until
one causal topology validator rejects that tuple and every equivalent
laundering attempt.

The same diagnosis found that `output_observation_incomplete`,
`scratch_observation_incomplete` and `namespace_cleanup_incomplete` have public
names but no production writer. They may not be promoted from caller-built Lua
fixtures alone.

### 27.2 Controller terminal v2

The one success-only private controller report becomes one fixed private union:

```text
protocol/version  proc17.qa.controller_terminal.v2
exact size        572 bytes
record kind       result | error
write count       exactly one
```

The common envelope binds the exact request identity, private process token and
source-stage summary. Reserved bytes are zero. The entire record remains
private and fits one bounded write.

`result` carries the existing reason, termination, first cause, seven complete
controller finality facts, stream/resource/scratch measurements and allocator
state.

`error` carries:

```text
controller-owned code = output_observation_incomplete
                      | scratch_observation_incomplete
subject               = stdout | stderr | scratch
seven controller finality facts with the named missing fact false
no candidate reason
no invented measurement or cost
all unused union bytes zero
```

The controller cannot write `namespace_cleanup_incomplete`. The top-level
supervisor derives namespace cleanup only after validating the private record,
observing its EOF and reaping the exact controller. Failure of that named
predicate becomes the public namespace error. Missing/malformed private bytes,
identity/token split and an impossible result/error union are loud trusted
invariants.

### 27.3 Exact error topology

One table-backed validator owns class, code, stage, phase/start and cleanup
relationships. Both `qa_process.normalize_error_v1` and provider-witness source
reuse classification consume it.

Only this family is reusable:

| code | class | stage | start | cleanup | reap | EOF | reuse class |
|---|---|---|---|---|---|---|---|
| supervisor_unavailable | unavailable | preflight or launch | not_started | complete | complete | complete | clean_prestart |
| source_staging_failed | world | source_staging | not_started | complete | complete | complete | clean_prestart |

Every other code has reuse class `non_reusable`, even if a caller supplies
`not_started` and complete cleanup words. Its exact legal combinations remain
closed; an illegal combination is `invalid`, not a conservative alias.

QN19 requires:

| Case | class / code / stage | start | cleanup | reap | EOF | source |
|---|---|---|---|---|---|---|
| terminal missing | ambiguous / terminal_frame_missing / postflight | started | unknown | complete | complete | quarantined |
| reap ambiguity | ambiguous / reap_ambiguous / cleanup | started | unknown | unknown | complete | quarantined |
| stream observation, two variants | ambiguous / output_observation_incomplete / postflight | started | incomplete | complete | complete | quarantined |
| scratch observation | ambiguous / scratch_observation_incomplete / postflight | started | incomplete | complete | complete | quarantined |
| namespace cleanup | ambiguous / namespace_cleanup_incomplete / cleanup | started | incomplete | complete | complete | quarantined |
| postflight source drift | ambiguous / source_drift / postflight | started | process-derived | process-derived | process-derived | quarantined |

`supervisor_crashed` remains the honest result when no valid private terminal
record names the internal failure. QN19 must not infer output, scratch or
namespace cause from a dirty exit alone.

### 27.4 Source disposition reader

Provider witness asks the shared topology validator for:

```text
clean_prestart -> consumed
non_reusable   -> quarantined
invalid        -> quarantine attempt, then loud
```

It may not recompute cleanliness from independent fields. Postflight source
drift is always non-reusable. A terminal source disposition is sticky before
handle close; close failure is loud and cannot roll the source back to active.
Every quarantined case denies exact replay before a second provider call.

### 27.5 Closed campaign

The parameterless target is:

```make
qa-supervisor-cleanup-ambiguity-test
```

The closed campaign owns six case ids and two stream variants. The native
driver owns the five host-process cases; repository postflight drift is grown
only by the Lua repository-inventory writer and has no fabricated native row.
The native record is:

```text
QN19_NATIVE_V0|case_id|class|code|stage|start|cleanup|reap|eof|variant_count
```

The Lua campaign binds those rows to current request identities through the
strict normalizer and grows one real sealed source transaction per row. It must
print and enforce:

```text
declared=6 executed=6 matched=6 stream_variants=2
candidate_outcomes=0 source_quarantines=6 replays=0
```

Native host-fact production and Lua source disposition are matched layers, not
one fabricated writer. Exactly five native rows plus one Lua-owned drift life
produce the six matched campaign cases. The case id never enters production
wire, environment, candidate bytes or public API. Production artifact/API
exclusion from QN18 is rerun unchanged.

### 27.6 Promotion gate

The only authorized transition is:

```text
QN19 red -> green
42 green / 42 red -> 43 green / 41 red
```

QN20 and every body QE/QV control remain red. QN19 authorizes no Packet QA
writer, verdict, retry or software acceptance.
