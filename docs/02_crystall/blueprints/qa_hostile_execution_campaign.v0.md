# QA Hostile Execution Campaign Blueprint v0

Status:

```text
layer: CRYSTALL
date: 2026-07-28
chapter: 8.5.5E
sources:
  docs/01_table/yellowprints/qa_hostile_execution_campaign_yellowprint.v0.md
  docs/00_chaos/qa_hostile_execution_table_cross_audit_2026-07-28.md
  docs/00_chaos/qa_measurement_e4_topology_audit_2026-07-28.md
  docs/00_chaos/qa_measurement_e4_status_amendment_cross_audit_2026-07-28.md
scope: C1-C10 private provider physics
implementation authorized: no; crystall cross-audit required
Packet/body QA authority: forbidden
```

Gate amendment 2026-07-28:

```text
cross-crystall audit satisfied
E1-E10 implementation authorized in exact order by:
  docs/00_chaos/qa_hostile_execution_crystall_cross_audit_2026-07-28.md
Packet/body QA authority remains forbidden
```

## 0. Crystall Contract

This blueprint is complete only when:

```text
QN17-QN20 execute their named corpora and turn green;
QN01-QN16 remain green;
ordinary and mortality suites remain green;
the red matrix changes exactly 40/44 -> 44/40;
no QE/QV/body/completion/tree control changes;
Packet, public root and body economics remain ablated.
```

## 1. Ownership Map

| Slice | Primary owner | Responsibility |
|---|---|---|
| C1 | `native/proc17_qa_wire.h` | v1 RUN kinds/codecs/phase framing |
| C2 | `core/qa_schema.lua`, `runtime/qa_process.lua` | exact environment/process schemas and validators |
| C3 | policy/build/environment identity owners | measured heap and feature rotation |
| C4 | `native/proc17_qa_supervisor.c` | ready handshake, first-cause ledger, finality |
| C5 | supervisor stream/scratch observers | independent bounded measurements |
| C6 | `native/proc17_qa_launcher.c` | multi-frame phase/reap/EOF state machine |
| C7 | provider/process/witness adapters | strict normalization and source disposition |
| C8 | hostile candidate harness | QN17 production corpus |
| C9 | test-only fault harness | QN18/QN19 without production hooks |
| C10 | repeated-run harness | QN20 named residue channels and color audit |

No slice owns a Packet writer.

## 2. C1 - RUN v1 Wire

### 2.1 Envelope compatibility

The existing envelope codec remains bounded and keeps PROBE v0 kinds. Add
distinct RUN v1 kinds rather than silently changing kinds 3/4:

```c
PROC17_QA_WIRE_RUN_REQUEST_V1 = 5
PROC17_QA_WIRE_RUN_STARTED_V1 = 6
PROC17_QA_WIRE_RUN_RESULT_V1  = 7
PROC17_QA_WIRE_RUN_ERROR_V1   = 8
```

Historical RUN v0 kinds remain codec-testable but are no longer emitted or
accepted by the production provider.

### 2.2 Frame stream

The result descriptor carries length-delimited existing wire envelopes:

```text
pre-start failure: ERROR_V1, EOF
candidate path:    STARTED_V1, RESULT_V1, EOF
incomplete path:   zero/STARTED frame, EOF or launcher-observed crash
```

Each frame retains the request transaction nonce. `read_frame` becomes a
bounded `read_next_frame` with no buffering beyond one maximum frame.

### 2.3 Request payload

RUN request v1 carries the same public authority as v0:

```text
transaction/witness/profile/environment digests
exact source identity
existing fixed hard limits
expected exit 0
entrypoint tests/run.lua
```

It contains no fault selector, command, argv, stdin, environment, cwd or raw
path.

### 2.4 Started payload

Fixed fields:

```text
identity join
phase ordinal = 1
source staging policy/id digest
private candidate process token digest
ready_state = prepared_under_policy
```

The launcher validates the source staging summary against the exact source fd
as it already does for the terminal stage payload.

### 2.5 Result payload

Fixed sections:

```text
identity + ordinal 2
candidate reason and termination
first-cause kind and monotonic sequence
eight finality booleans
stdout v1 measurement
stderr v1 measurement
resource v1 measurement
scratch v1 measurement
source stage summary
```

Static assertions bind every offset and total size. Reserved bytes must be
zero. Codec tests flip every enum/boolean/reserved region.

### 2.6 Error payload

Fixed sections:

```text
identity + ordinal
class/code/stage enums
start-state enum
namespace-cleanup-state enum
bounded measured cost presence/value
source stage summary when known
```

Unknown tri-state is an explicit enum, not an all-zero alias.
Launcher reap and result EOF are not supervisor-wire fields. The launcher adds
those facts to the sanitized Lua error only after observing them itself.

## 3. C2 - Strict Lua Schemas

### 3.1 Environment

Add `qa.environment.v1` with one new fixed measured field:

```lua
runtime_heap_limit_bytes = 67108864
```

The environment id includes this value plus the rotated supervisor build,
policy and feature identities. It remains `runtime_confirmed` and cannot be
supplied by substrate content.

### 3.2 Process normalizer API

```lua
qa_process.normalize_request_v1(value)
  -> exact_request | nil, err

qa_process.normalize_result_v1(raw, request)
  -> process_observation | loud invariant

qa_process.normalize_error_v1(raw, request)
  -> process_error | loud invariant
```

The normalizer has no compatibility coercion from v0 tables.

Implementation amendment 2026-07-28:

`STARTED` and its candidate-process token remain entirely inside the native
launcher phase machine. The Lua normalizer receives only a sanitized terminal
table after the native STARTED/terminal join has been validated. No pid, fd,
token, mount identity, raw frame or frame digest crosses the module ABI. See
`docs/00_chaos/qa_started_native_visibility_amendment_2026-07-28.md`.

### 3.3 Result invariant

`process_observation` exists only when every finality member is true. It carries:

```text
exact reason and first cause
exact termination
independent stream measurements
resource and scratch measurements
cleanup complete
runtime-confirmed cost
```

### 3.4 Error invariant

`process_error` carries tri-state start/cleanup facts. It never contains a
candidate outcome. Impossible combinations are loud, including:

```text
not_started with a valid STARTED ref
started without matching STARTED ref
complete cleanup with failed reap/EOF where those are required
candidate reason inside error
unknown identity
```

## 4. C3 - Identity Rotation

### 4.1 Feature set

The production environment records these exercised features in its feature-set
digest:

```text
run-v1-phase-attestation
first-cause-ledger
dual-stream-bounded-drain
runtime-heap-denial-witness
scratch-final-inventory
decomposed-cleanup-finality
```

Implementation precision amendment 2026-07-28:

This is the final post-E5 feature set, not an E2 declaration. E2 rotates the
environment for the already measured heap law and current build/wire identity.
Each of E3-E5 adds and exercises only its own feature before rotating identity
again. A future feature is never predeclared `runtime_confirmed`.

### 4.2 Build/policy

Changes to wire, policy, supervisor or fixed heap law rotate:

```text
supervisor build id
runtime dependency closure id where inputs changed
policy digest
isolation feature-set id
environment id
```

The launcher is rebuilt against the exact new supervisor digest. Historical
environment ids remain valid historical evidence but unavailable for new
contracts.

### 4.3 Production exclusion audit

Production artifacts fail if strings/symbols include a fault-selection ABI.
The loader must reject every test-fault build by supervisor/launcher identity.

## 5. C4 - Supervisor Phase Machine

### 5.1 Process topology

```text
launcher process
  -> execveat production supervisor
      -> namespace controller (new user/mount/pid/net/ipc/uts)
          -> candidate process (fresh restricted Lua)
```

### 5.2 Pre-chunk start attestation

The trusted candidate prelude writes STARTED directly to the launcher-owned
result pipe before any candidate chunk is loaded.

E4.0a amendment 2026-07-28 supersedes the original nine-step prelude below.
The original sequence remains visible in repository history; it could not both
close every non-stdio descriptor and retain the C5 status witness needed after
Lua starts.

The executable sequence is:

```text
candidate process
  1. prepare environment
  2. apply rlimits
  3. drop capabilities
  4. install seccomp
  5. derive one private candidate-process token
  6. encode and atomically write one bounded RUN_STARTED_V1
  7. close the public STARTED descriptor
  8. send private READY(sequence=1)
  9. block until exact private RELEASE(sequence=2)
 10. close every candidate-Lua-reachable non-stdio descriptor
 11. load and execute the candidate chunk
```

The frame is no larger than Linux `PIPE_BUF`; one write owns it. If STARTED
cannot be written completely, the prelude exits without loading candidate
bytes. The top-level supervisor emits only the later terminal frame after the
candidate/controller is reaped, so frame order is fixed. Candidate code cannot
access, suppress or forge the attestation descriptor.

The controller creates one
`AF_UNIX/SOCK_SEQPACKET|SOCK_CLOEXEC` pair before candidate fork. The candidate
retains exactly one endpoint as C-private state; it is never projected as a Lua
fd, userdata, path, environment value, protocol field or corpus value. Its fixed
packet is exactly 184 bytes:

```text
offset  bytes  field
0       8      magic = "P17QAST\0"
8       2      version = 1
10      2      kind: READY=1, RELEASE=2, HEAP_DENIED=3
12      4      packet_bytes = 184
16      8      conversation sequence
24      128    transaction/witness/profile/environment identity join
152     32     private candidate-process token
```

Exact legal conversation:

```text
candidate  -> READY(sequence=1), after public STARTED write and close
controller -> RELEASE(sequence=2), after READY validation and wall-timer arm
candidate  -> zero or one HEAP_DENIED(sequence=3)
candidate terminal -> status endpoint EOF
```

No candidate byte is loaded before RELEASE. Missing, duplicate, malformed,
reordered or identity/token-mismatched packets are infrastructure failure.
STARTED followed by a failed READY/RELEASE join remains a started
infrastructure failure, never candidate rejection.

The candidate uses only record-preserving `write`/`read` on the seqpacket
endpoint. A 185-byte receive buffer accepts exactly 184 bytes and rejects
truncation. The trusted prelude installs `SIGPIPE=SIG_IGN` before seccomp and
sets the endpoint nonblocking after RELEASE. `send`, `recv`, `sendmsg` and
`recvmsg` are not added to candidate seccomp.

#### 5.2.1 Split process-local phase state (E5.0 amendment)

The candidate owns a dedicated one-shot STARTED writer state; it does not own
the controller phase ledger. The namespace controller owns a separate
process-local phase state. After the private status decoder validates exact
`READY(1)`, it performs the sole legal `started_attested` transition in that
controller state. The controller then arms the wall timer, authorizes candidate
release and sends `RELEASE(2)`.

This is a two-channel join, not duplicated truth. READY proves the fixed
candidate-prelude ordering to the controller; the launcher separately validates
the public STARTED frame and process token. No shared mutable phase/cause state
is introduced, and neither witness can substitute for the other.

### 5.3 First-cause ledger

The namespace controller owns one immutable private record:

```c
struct proc17_qa_first_cause {
    uint16_t kind;
    uint64_t monotonic_sequence;
    uint64_t observed_value;
};
```

Only compare-and-set from `NONE` is legal. Writers are trusted timer, wait,
allocator notification plus telemetry, stream crossing, scratch denial and
seccomp/wait evidence. The controller is the only process permitted to perform
that compare-and-set. A candidate status packet is evidence submitted to the
controller, never a cause write. Later cleanup failures do not rewrite
candidate cause; they suppress the candidate result and produce infrastructure
ambiguity.

E4.3 arbitration amendment 2026-07-28:

Every successful `poll()` return is one observation epoch. Classify all ready
sources first. Exactly one distinct cause kind may claim the slot; multiple
distinct kinds produce infrastructure ambiguity. Two stream crossings are one
`output_limit` kind with two measurements. Descriptor index, enum order and
canonical tie-break are forbidden as physical ordering. Once cause is set,
later wait status supplies termination/finality only.

### 5.4 Terminal state

The controller does not exit until it has attempted:

```text
candidate termination observation
whole candidate-tree kill if required
candidate reap with rusage
stdout and stderr EOF
scratch final observation
private status EOF
stable allocator telemetry observation
```

The top-level supervisor sets namespace cleanup complete only after the
controller itself is reaped and its report is internally consistent.

### 5.5 Exact private controller report

E4.5 fixes the controller-to-supervisor record at 572 bytes:

```text
header(16) + identity(128) + private process token(32)
+ reason/termination(12) + first cause(20)
+ local finality(7) + status EOF(1) + allocator stable(1)
+ HEAP_DENIED count(1) + allocator failure flags(2) + reserved(4)
+ allocator current reservation(8)
+ stdout(64) + stderr(64) + resources(88) + scratch(40)
+ source stage(84)
```

The header is `P17QACR\0`, version 1, exact byte count and four zero bytes.
All multi-byte values use QA network byte order. The first seven public
finality members must be true and namespace-clean must still be absent in the
controller phase state. Status EOF, stable post-reap allocator telemetry and
notification/page agreement are additional private prerequisites.

After exact successful controller reap and namespace cleanup, the top-level
supervisor validates identity and token, copies the immutable evidence and
sets only `namespace_cleanup_complete`. It never re-derives first cause.
Failure of any prerequisite emits no candidate RESULT.
`system_allocation_failed=true` is one such failure: the E4.5 join takes the
infrastructure branch rather than hiding host allocation failure in a
candidate `unexpected_exit`.

## 6. C5 - Measurements

### 6.1 Streams

Create separate `O_CLOEXEC|O_NONBLOCK` parent drains for stdout and stderr.
The poll set contains:

```text
stdout read fd
stderr read fd
candidate pidfd
wall timerfd
private `SOCK_SEQPACKET` ready/release/status endpoint
```

For each stream maintain:

```text
uint64 observed_bytes
uint64 hashed_bytes (capped at stream limit)
sha256(first hashed_bytes)
limit_crossed
eof_observed
```

After first output crossing, set first cause once, kill the candidate tree and
continue draining until both EOFs or infrastructure failure.

### 6.2 Allocator

E4.0a supersedes post-`lua_close` transfer. A terminal transfer cannot preserve
measurements when wall, CPU or output enforcement kills the candidate before
its trusted epilogue.

Create one fixed anonymous `MAP_SHARED` allocator telemetry record before
candidate fork. The controller changes its inherited mapping to read-only; the
trusted candidate allocator is the only post-fork writer. Lua receives neither
the address nor an API that can reach the record.

The fixed private ABI contains:

```text
protocol/version              fixed
ceiling_bytes                 immutable
current_bytes                 atomic
peak_bytes                    atomic monotonic maximum
ceiling_denied                atomic sticky boolean
system_allocation_failed      atomic sticky boolean
status_notification_failed    atomic sticky boolean
```

The allocator publishes measurement updates with release ordering; the
controller observes them with acquire ordering after HEAP_DENIED notification
or candidate reap. Abrupt death may leave `current_bytes` nonzero but cannot
erase `peak_bytes` or any sticky flag.

Mutable fields use proved lock-free interprocess atomics. Static ABI assertions
cover size, offset and alignment, and the provider refuses availability before
candidate start when the target cannot prove lock-free operation. No
process-local lock, process-shared mutex, shared phase field or shared cause
field is permitted.

Current and peak are allocator-reservation measurements, not RSS. The
allocator publishes an in-budget reservation and peak before entering host
`malloc/realloc`. Host failure first sets `system_allocation_failed`, then
rolls current back; peak retains the maximum authorized request. Therefore a
kill inside the host allocator cannot erase the observed peak.

On the first policy-ceiling refusal, the allocator atomically sets
`ceiling_denied` and sends exactly one HEAP_DENIED(sequence=3) packet. The
packet is only a wakeup witness. The shared record is the sole allocator
measurement truth, and the controller first-cause slot is the sole cause truth.

`memory_limit` requires exact HEAP_DENIED, `ceiling_denied=true` and
`system_allocation_failed=false`. A run where both failure flags are true is
infrastructure ambiguity; system allocation failure can never establish or be
laundered into memory limit. Notification/page mismatch, status notification
failure, unstable ABI, inaccessible telemetry or a second denial packet is
infrastructure ambiguity. Candidate text cannot set any trusted field.

### 6.3 CPU and wall

Use pidfd/timerfd/wait4 facts. Configure the declared CPU ceiling as the
`RLIMIT_CPU` soft limit and one bounded second later as the hard emergency
limit. `SIGXCPU` before the wall timer is the exact v0 CPU-limit witness; the
controller then owns whole-tree termination/reap. A hard SIGKILL without the
earlier SIGXCPU witness falls back to `signal` or infrastructure ambiguity,
never a guessed CPU limit.

Arm the candidate timerfd with an absolute `CLOCK_MONOTONIC` deadline before
private RELEASE. Candidate metrics come only from exact
`wait4(candidate_pid)`. `wait4(namespace_controller)` and the outer watchdog
remain cleanup/infrastructure evidence. If candidate pidfd and timer are both
newly ready in one epoch before a cause exists, return infrastructure
ambiguity.

### 6.4 Scratch

After candidate reap, the namespace controller walks only `/qa/scratch` with a
closed no-follow bounded walker and records regular-byte/entry totals. It also
records final trusted filesystem byte/inode capacity state.

The exact internal depth bound is
`PROC17_QA_SCRATCH_MAX_DEPTH = 64`, included in the isolation policy digest.
Depth zero is the pinned scratch root and direct children have depth one. This
bound constrains observer work; it is not a result field or terminal cause.

The controller snapshots the exact trusted initialization (`home`, `tmp` and
their identities) before candidate release. Final measurements are candidate
delta over that baseline; trusted baseline directories do not count as
candidate entries. Mutation or disappearance of a baseline object is
infrastructure ambiguity.

The walker rejects symlinks, special files outside the exact initialized set,
depth/count overflow and observation errors as infrastructure ambiguity. It
also records final `statvfs` byte/inode exhaustion, but that post-terminal fact
does not prove which write caused termination.

Stored use may equal but never exceed configured bounds. Step E maps the
scratch-exhaustion fixture to `unexpected_exit` and does not emit
`scratch_limit`. That reason remains reserved until a future trusted write-
denial hook can set first cause before candidate termination.

E4.4 exposes a fixed private 40-byte projection to E4.5: four QA network-order
u64 values (`stored_regular_bytes`, `stored_entries`, `limit_bytes`,
`limit_entries`), then the byte-capacity, entry-capacity and
inventory-complete booleans, followed by five zero bytes. The enclosing report
owns the protocol tag.

## 7. C6 - Launcher State Machine

### 7.1 Concurrent ownership

The launcher owns:

```text
supervisor pidfd
result-frame fd
exact opened supervisor identity
source userdata callback lifetime
request identity
```

It polls pidfd and result fd until terminal reap plus EOF. It does not block on
one frame while ignoring supervisor death.

### 7.2 Sequence validation

```text
ERROR before STARTED -> exact pre-start infrastructure error
STARTED then RESULT  -> candidate result candidate
STARTED then ERROR   -> exact post-start infrastructure error
STARTED then EOF     -> result_pipe_lost/terminal_frame_missing
supervisor death     -> supervisor_crashed with known/unknown start state
duplicate/out-of-order/malformed frame -> trusted invariant
```

The launcher reports its own reap/EOF facts only. It does not claim internal
namespace cleanup when no trusted frame proves it.

### 7.3 Native Lua return

`run_lua54_test_suite` returns exactly one detached v1 result or error table.
No pid, fd, path, mount id, process token, raw frame or output byte crosses.

Malformed trusted state raises a Lua error after the source callback marks the
attempt ambiguous; it is not returned as an ordinary native error.

## 8. C7 - Provider Witness Migration

### 8.1 Private protocols

Revise exact private reports where shape changed:

```text
qa.provider_witness_report.v1
qa.provider_witness_error.v1
```

There is no v0 input alias. Historical v0 reports stay detached evidence.

### 8.2 Mapping

```text
expected_exit -> accepted
all other definitive candidate reasons -> rejected
native/process infrastructure error -> witness error
trusted invariant -> source quarantine/finality attempt, then loud
```

### 8.3 Source join

Candidate report assembly still requires:

```text
pre inventory == exact candidate seal
post inventory == pre inventory
source lease final disposition = consumed
```

Ambiguity/drift uses `quarantined`. A report cannot exist before terminal source
disposition.

### 8.4 Ablation

Before/after each E witness compare:

```text
Packet canonical state and complete trace
budget/loss/field revisions
current candidate seal projection
public repository root projection
lineage economics
```

Only private source-lease lifecycle and test-owned evidence may change.

## 9. C8 - QN17 Harness

### 9.1 Activation

A dedicated trusted Lua harness reads each candidate fixture through
`qa_hostile_fixtures` after marker/id/class/size validation. For each row it:

```text
creates a fresh identity-owned root
materializes tests/run.lua through the real first hand
seals the exact candidate
reserves one provider-witness source lease
executes through production provider v1
asserts the TABLE fixture matrix
asserts pre == seal == post and complete finality
closes handles and removes only the identity-owned fixture root
```

The ordinary runner never executes fixture bytes.

### 9.2 Native target

```make
qa-supervisor-hostile-fixtures-test
```

invokes only the dedicated harness and requires an exact closed count:

```text
candidate rows executed = 17
candidate rows matched  = 17
source drifts           = 0
cleanup ambiguities     = 0
```

### 9.3 QN17 gate

The target fails on one skipped fixture, alternate reason, missing finality,
raw leak or ablation delta.

## 10. C9 - QN18/QN19 Harness

### 10.1 Test-only builds

Compile fault binaries from production sources with one test-only internal
header and `PROC17_QA_FAULT_TESTING`. They have:

```text
distinct build ids
no production loader acceptance
no installed/shared production filename
no candidate-visible selector
```

Fault selection is a closed test-driver enum passed outside the production wire
and source.

### 10.2 QN18 target

```make
qa-supervisor-trusted-fault-test
```

executes all nine trusted fixture instructions and asserts the TABLE matrix.
Malformed results are caught as loud test success only after expected private
finality/quarantine assertions.

### 10.3 QN19 target

```make
qa-supervisor-cleanup-ambiguity-test
```

grows at least these states:

```text
STARTED + terminal frame missing
STARTED + reap ambiguity
STARTED + one stream EOF missing
STARTED + scratch observation incomplete
postflight source drift
```

Every state yields no candidate witness and a quarantined source lease. The
target asserts zero accepted/rejected outcomes.

### 10.4 Production exclusion

Audit production artifacts with exact symbol/string/API tests and attempt to
load the fault build through the production loader. Any acceptance fails QN18.

## 11. C10 - QN20 Harness

### 11.1 Loop

```make
qa-supervisor-leak-loop-test
```

runs 32 fresh transactions alternating clean and Lua-error candidates.

### 11.2 Owned residue ledger

The harness owns a private record per iteration:

```lua
{
  iteration,
  root_identity,
  source_lease_id,
  launcher_owned_pid_tokens,
  fd_count_before,
  fd_count_after,
  matching_host_mounts_before,
  matching_host_mounts_after,
  root_cleanup_state,
  source_disposition,
  packet_ablation_digest,
}
```

No absolute path or fd enters public test output.

### 11.3 Acceptance

After every iteration:

```text
fd count restored
all owned pidfds closed and children reaped once
zero host mount entries match the unique harness identity
source lease terminal once
temporary root identity cleaned once
Packet/root/economics ablation unchanged
```

Repeat after final GC. The target prints `iterations=32 residue=0` only when all
named channels are exact.

## 12. Control Matrix

### C1-C3

```text
HE01 mixed v0/v1 rejected
HE02 duplicate/out-of-order phases loud
HE03 false finality suppresses candidate result
HE04 missing STARTED remains unknown
HE22 old environment cannot upgrade
```

### C4-C7

```text
HE05 exit 70 does not invent a limit
HE06 SIGKILL does not invent cause
HE07 allocator denial required for memory limit
HE08 streams independent and raw-free
HE09 missing EOF is ambiguity
HE10 stored scratch respects bound
HE11 no scratch-limit claim without a trusted write-denial hook
HE16 crash/pipe fault remains infrastructure
HE17 ambiguity quarantines
HE18 trusted contradiction loud after finality attempt
HE21 Packet/root/economics zero mass
HE23 no candidate byte loads before exact private RELEASE
HE24 READY before public STARTED close is infrastructure failure
HE25 malformed/duplicate/reordered private status is infrastructure failure
HE26 Lua cannot reach private status or allocator telemetry
HE27 abrupt candidate death preserves allocator peak/sticky flags
HE28 allocator notification/telemetry mismatch is infrastructure ambiguity
HE29 no shared phase/cause state exists
HE30 missing private status EOF suppresses candidate result
```

### C8-C10

```text
HE12 wall fixture claims CPU, not wall
HE13 API fixture claims no SIGSYS
HE14 every hostile fixture crosses production boundary
HE15 fault controls absent from production
HE19 32 iterations restore named residue
HE20 exact four-control promotion only
```

## 13. Expected Color Sequence

```text
baseline       40 green / 44 red
after C1-C7    40 green / 44 red
after C8/QN17  41 green / 43 red
after C9/QN18  42 green / 42 red
after C9/QN19  43 green / 41 red
after C10/QN20 44 green / 40 red
```

The implementation stops if any other control changes.

## 14. Verification Battery

After every implementation slice:

```text
lua tests/run.lua
lua tests/smoke_mortality_battery.lua
lua tests/test_qa_native_supervisor.lua
lua tests/test_qa_provider_witness.lua
lua tests/red_qa_hand.lua              # expected nonzero until body work
make -C native qa-wire-test
make -C native qa-static-closure-test
strict compiler warnings
production symbol/string/API audit
git diff --check
```

After C8-C10, run each target independently from a cold native build.

## 15. Implementation Order

```text
E1 C1/C2 wire and Lua schemas; no execution delta
E2 C3 environment rotation and QN01-QN16 migration
E3 C4 ready handshake/first-cause/finality
E4.0a TABLE/CRYSTALL private status and allocator-survival amendment
E4.1 C5 independent stream witnesses
E4.2 C5 allocator witness
E4.3 C5 candidate CPU/wall witness
E4.4 C5 scratch witness
E4.5 C5 controller report/finality join, production-linked but unrouted
E4.6 C5 batteries, manifest and checkpoint
E5 C6 launcher state machine and fault-free v1 path
E6 C7 provider witness migration and source disposition
E7 C8 QN17 campaign
E8 C9 QN18 campaign
E9 C9 QN19 campaign
E10 C10 QN20 campaign and exact matrix audit
```

Each step is independently revertible before the next authority surface.

## 16. Non-Claims

This crystall does not prove:

```text
universal software correctness
body-owned QA evidence or verdict
arbitrary commands/toolchains/languages
zero heap leak in all dependencies
wall-timeout from the current wall-loop Lua fixture
candidate-issued SIGSYS from the current API-closure fixture
safe retry/resume/parallel execution
```

## 17. Exit Gate

Implementation may begin only after a crystall cross-audit confirms:

```text
the ready handshake is pre-execution and unforgeable;
every reason has one physical writer;
v1 does not widen request authority;
fault hooks cannot enter production identity;
source disposition agrees with repository registry law;
QN17-QN20 are the only authorized color changes.
```

## 18. E6/C7 Provider Witness V1 Precision Amendment

Amended 2026-07-28 after the E5 production switch.

### 18.1 Final report

`qa.provider_witness_report.v1` has exactly these top-level fields:

```text
protocol_version, operation, transaction_id, witness_id, profile_id,
environment_id, outcome, reason, termination, cause, finality, source,
stdout, stderr, resources, scratch, cost, event_truth_status
```

`source` has exactly:

```text
pre_inventory_id, post_inventory_id, stable=true, disposition=consumed
```

Cause, finality and all measurements are detached copies of the already strict
process observation v1. The report has no second cleanup boolean.

### 18.2 Final error

`qa.provider_witness_error.v1` has exactly:

```text
protocol_version, transaction_id, witness_id, profile_id, environment_id,
class, code, stage, candidate_start_state, source_stable,
source_disposition, cleanup_state, launcher_reaped, result_eof,
measured_cost, event_truth_status
```

Process tri-states and optional cost are preserved without coercion. A
pre-provider source error is `not_started` with no measured process cost.

### 18.3 Ordering and authority

The source callback returns an untagged pending join only. Final v1 object
assembly occurs after successful terminal `finish_qa_source`. Trusted
contradiction attempts quarantine/finality and then raises. No v0 report/error
is accepted as an alias.

E6 changes no Packet, public root, Packet budget or lineage economics. It
creates no body request, execution receipt, outcome event, verdict or reader.
The required red-matrix delta is zero.

## 19. E7/C8 QN17 Executable Harness Amendment

Source: `docs/00_chaos/qa_e7_qn17_hostile_candidate_campaign_notes_2026-07-28.md`.

### 19.1 Trusted entrypoint

One dedicated Lua entrypoint outside the ordinary suite imports both the inert
fixture manifest and the existing real-candidate support. The Make target
`qa-supervisor-hostile-fixtures-test` invokes only that entrypoint. The
entrypoint has no CLI parameters, fixture selector, path selector or alternate
provider input.

### 19.2 Closed matrix

The harness owns an exact 17-key expectation table containing only reason and
provider outcome plus reason-specific witness checks. It rejects missing,
duplicate and extra candidate fixture ids. The fixture `pressure` string is not
read for classification.

### 19.3 Per-row transaction

For each validated candidate record:

```text
fixture.read -> unchanged bytes
qa_provider_witness_support.with_candidate(bytes)
-> first-hand materialization
-> candidate seal
-> witness.prepare
-> assert entrypoint bytes/hash and seal inventory binding
-> witness.execute exactly once
-> assert report/source/cause/finality/measurement matrix
-> identity-owned root cleanup
```

`with_candidate` is the already exercised real first-hand path. E7 must not add
a test-only source writer or alternate supervisor. Witness-internal ablation is
part of every row.

### 19.4 Exact checks

All reports use `qa.provider_witness_report.v1`; errors fail QN17. All finality
members are true. Source pre/post inventory ids equal the witness plan's sealed
inventory id and disposition is `consumed`. The report contains measurement
records only; no content, path, fd, handle, raw stream or process token is
accepted.

Reason-specific evidence includes allocator denial for `memory_limit`, the
named stream crossing for output fixtures, complete bounded scratch inventory
for scratch exhaustion and exact source stability for source mutation.

### 19.5 Gate

The campaign succeeds only at:

```text
declared=17 executed=17 matched=17 source_drifts=0 cleanup_ambiguities=0
```

The expected red battery becomes `41 green / 43 red`. No QN18-QN20, QE or QV
control may change. The implementation adds no production fault selector and
no body QA authority.

## 20. E8/C9 QN18 Executable Harness Amendment

Source: `docs/00_chaos/qa_e8_qn18_trusted_fault_campaign_notes_2026-07-28.md`.

### 20.1 Production classifier repair

`proc17_qa_launcher_collect_v1` must preserve these real observation classes:

```text
result-channel read failure -> ambiguous/result_pipe_lost/supervision
waitpid ownership failure   -> ambiguous/reap_ambiguous/cleanup
malformed trusted bytes     -> trusted invariant
dirty child exit            -> unavailable/supervisor_crashed/supervision
```

The classifier copies the already observed STARTED state. It writes no clean
reap, EOF, cleanup or cost claim without the corresponding host witness.

### 20.2 Distinct test build

One internal header is visible only when `PROC17_QA_FAULT_TESTING` is defined.
The test build uses production launcher/supervisor/wire state machines but has:

```text
launcher ABI = proc17.qa.launcher.lua54.fault-test.v0
supervisor binary digest != production supervisor digest
test-only artifact names under native/tests/
closed driver-owned row enum
```

The driver is parameterless. Fault selection does not enter a frame, source,
environment variable or Lua function. Prefer synthetic trusted process
observations over a source hook whenever the production state machine can be
exercised directly.

### 20.3 Native result protocol

The native driver emits exactly seven bounded records, one for every native
row other than loader rejection and provider postflight drift:

```text
QN18_NATIVE_V0|fixture_id|boundary|start_state|terminal_state|variant_count
```

Allowed values are owned by an exact Lua expectation map. There is no free
diagnostic field. The malformed request/result rows require `variant_count=7`;
all other rows require `variant_count=1`.

### 20.4 Lua campaign

The parameterless Lua entrypoint validates all nine inert fixture records and
then joins:

```text
production-loader rejection of the fault launcher
seven exact native driver records
provider-witness postflight source drift
provider-witness quarantine-before-loud trusted contradiction
production artifact/API exclusion audit
```

The fixture `pressure` field is never read as an expected result.

### 20.5 Artifact exclusion

After both production and fault artifacts are built:

```text
fault artifacts have identities different from production
production loader rejects the fault launcher
production verifier rejects the fault supervisor
nm/strings/API inspection finds no test symbol, fixture id or selector in
production proc17_qa_launcher.so or proc17_qa_supervisor
```

Source-level `#ifdef PROC17_QA_FAULT_TESTING` is not sufficient evidence;
compiled-artifact inspection is mandatory.

### 20.6 Gate

The target succeeds only at:

```text
declared=9 executed=9 matched=9 candidate_outcomes=0
```

The expected red battery becomes `42 green / 42 red`. QN19/QN20 and every
body QE/QV control remain red. E8 authorizes no body execution request,
check evidence, verdict, completion reader or retry policy.

## 21. E9/C9 QN19 Executable Amendment

Source: `docs/00_chaos/qa_e9_qn19_cleanup_ambiguity_notes_2026-07-28.md` and
TABLE section 27.

### 21.1 Shared topology validator

`runtime/qa_process.lua` owns one closed data table for every native error code:

```text
allowed class
allowed stage
allowed phase/start
allowed cleanup/reap/EOF relation
source reuse class = clean_prestart | non_reusable
```

`normalize_error_v1` rejects a tuple outside that table. A second exported
reader validates an already normalized process error and returns its reuse
class. `runtime/qa_provider_witness.lua` uses that reader; it removes the local
`cleanup complete && not_started` policy.

The validator must reject at least these laundering probes:

```text
reap_ambiguous + not_started + complete
terminal_frame_missing + preflight
output_observation_incomplete + cleanup complete
scratch_observation_incomplete + not_started
namespace_cleanup_incomplete + postflight
supervisor_unavailable + started
```

An invalid provider error causes a quarantine attempt before loud failure and
cannot create a final witness object.

### 21.2 Private controller terminal v2

Keep implementation in `native/proc17_qa_report.[ch]`; do not add a second
mutable ledger. Replace the report parser/builder with an exact 572-byte v2
union and these operations:

```c
build_result(exact complete evidence)
build_error(exact controller-owned missing witness)
decode_and_validate(exact identity/token/stage)
finalize_after_controller_reap(namespace predicate)
```

The v2 header has an explicit kind. Result and error payload regions are
mutually exclusive and unused bytes must be zero. The controller error builder
accepts only stdout/stderr EOF loss and scratch-observation failure. It carries
the exact subject and internal finality vector but no candidate cause or cost.

The namespace controller writes one private terminal record only after its
cleanup path has killed/reaped the candidate where ownership remains. The
top-level supervisor waits for record EOF and exact controller reap before
projecting RESULT or ERROR. It appends only namespace cleanup. The launcher
later appends only top-supervisor reap and public result EOF.

### 21.3 Named namespace predicate

Extract the current literal namespace-complete argument into one pure predicate
over top-level observations:

```text
exact controller pidfd identity retained
private terminal record complete and EOF observed
exact controller wait/reap observed
controller exit compatible with terminal kind
no top-level controller authority descriptor left in flight
```

All true permits namespace cleanup complete. An unavailable member yields
`ambiguous/namespace_cleanup_incomplete/cleanup`; it does not fabricate RESULT.
A malformed or contradictory member is loud.

### 21.4 Production routing

Connect actual controller stream-drain/EOF failure and scratch ambiguity to the
v2 error builder. Connect the top-level namespace predicate to public ERROR.
Do not map every controller dirty exit to one of these names: absence of a
valid private error remains `supervisor_crashed` at the launcher.

Public ERROR after STARTED must carry the exact source-stage from the private
record. The top-level supervisor cannot reconstruct or omit it. ERROR never
contains launcher reap or result EOF; those are attached after collection.

### 21.5 QN19 native driver

Add:

```text
native/tests/test_proc17_qa_cleanup_ambiguity.c
tests/run_qa_cleanup_ambiguity_campaign.lua
qa-supervisor-cleanup-ambiguity-test
```

The parameterless native driver uses production collector and controller-
terminal codecs. Its closed enum grows five host-process rows; output
observation has stdout and stderr variants. Repository postflight drift is the
sixth campaign case and is grown only by the Lua inventory writer. The driver
emits only the fixed `QN19_NATIVE_V0` record and accepts no arguments,
environment selector, source path or candidate bytes.

The Lua campaign owns the six-case expectation map, rejects
extra/missing/duplicate native rows, binds each native row through `qa_process`
to the current request and executes a real provider-witness source transaction.
It grows postflight drift through two real repository inventories. Every case
must quarantine, deny replay and produce no candidate witness.

### 21.6 Red-first controls

Before implementation:

```text
the impossible reap_ambiguous clean-prestart tuple is accepted (red proof)
the QN19 Make target is absent
the ordinary native suite remains 18 green / 2 deferred
the QA matrix remains 42/42
```

After implementation:

```text
QN19 campaign 6/6; stream variants 2/2
source quarantines 6; replayed provider calls 0
ordinary native suite 19 green / 1 deferred
QA matrix 43 green / 41 red
```

No other control may change color.

### 21.7 Production exclusion and verification

Rerun QN18's digest, symbol, string, loader and API exclusions after building
QN19. Add scans for the QN19 record prefix and case ids. Production artifacts
may contain the real controller-terminal/error vocabulary, but no test selector
or campaign id.

Required verification:

```text
lua tests/run.lua
lua tests/smoke_mortality_battery.lua
lua tests/test_qa_native_supervisor.lua
lua tests/test_qa_provider_witness.lua
lua tests/red_qa_hand.lua             # exact expected nonzero 43/41
make -C native qa-supervisor-cleanup-ambiguity-test
make -C native qa-static-closure-test
ASan/UBSan focused native driver
GCC -fanalyzer changed native boundary
post-run process/root audit
git diff --check
```

### 21.8 Non-claims

E9 does not prove QN20 repeated residue freedom, body QA execution, check
evidence, verdict, QA economics, retry/resume or software acceptance.
