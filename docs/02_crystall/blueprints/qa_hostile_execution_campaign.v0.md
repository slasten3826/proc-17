# QA Hostile Execution Campaign Blueprint v0

Status:

```text
layer: CRYSTALL
date: 2026-07-28
chapter: 8.5.5E
sources:
  docs/01_table/yellowprints/qa_hostile_execution_campaign_yellowprint.v0.md
  docs/00_chaos/qa_hostile_execution_table_cross_audit_2026-07-28.md
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
result pipe before any candidate chunk is loaded:

```text
candidate process
  1. prepare environment
  2. apply rlimits
  3. drop capabilities
  4. install seccomp
  5. encode one bounded RUN_STARTED_V1 from a trusted private identity record
  6. write the complete frame atomically to the result pipe
  7. close the result/control descriptor
  8. close every remaining non-stdio descriptor
  9. load and execute the candidate chunk
```

The frame is no larger than Linux `PIPE_BUF`; one write owns it. If STARTED
cannot be written completely, the prelude exits without loading candidate
bytes. The top-level supervisor emits only the later terminal frame after the
candidate/controller is reaped, so frame order is fixed. Candidate code cannot
access, suppress or forge the attestation descriptor.

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
allocator status, stream crossing, scratch denial and seccomp/wait evidence.
Later cleanup failures do not rewrite candidate cause; they suppress the
candidate result and produce infrastructure ambiguity.

### 5.4 Terminal state

The controller does not exit until it has attempted:

```text
candidate termination observation
whole candidate-tree kill if required
candidate reap with rusage
stdout and stderr EOF
scratch final observation
private descriptor closure
```

The top-level supervisor sets namespace cleanup complete only after the
controller itself is reaped and its report is internally consistent.

## 6. C5 - Measurements

### 6.1 Streams

Create separate `O_CLOEXEC|O_NONBLOCK` parent drains for stdout and stderr.
The poll set contains:

```text
stdout read fd
stderr read fd
candidate pidfd
wall timerfd
private ready/status fd
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

Extend the existing bounded allocator state:

```text
current_bytes
peak_bytes
ceiling_bytes
denied
```

The candidate child transfers this fixed record to the controller after Lua
closes. If the allocator refuses and `lua_pcall` fails, first cause becomes
memory limit. Candidate text cannot set the flag.

### 6.3 CPU and wall

Use pidfd/timerfd/wait4 facts. Configure the declared CPU ceiling as the
`RLIMIT_CPU` soft limit and one bounded second later as the hard emergency
limit. `SIGXCPU` before the wall timer is the exact v0 CPU-limit witness; the
controller then owns whole-tree termination/reap. A hard SIGKILL without the
earlier SIGXCPU witness falls back to `signal` or infrastructure ambiguity,
never a guessed CPU limit.

### 6.4 Scratch

After candidate reap, the namespace controller walks only `/qa/scratch` with a
closed no-follow bounded walker and records regular-byte/entry totals. It also
records final trusted filesystem byte/inode capacity state.

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
E4 C5 stream, allocator and scratch witnesses
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
