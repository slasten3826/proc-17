# QA Detached Source Staging And RUN Blueprint v0

Status:

```text
layer: crystall (◈)
date: 2026-07-26
chapter: 8.5.5D provider physics
source table:
  docs/01_table/yellowprints/qa_detached_source_staging_yellowprint.v0.md
  docs/01_table/yellowprints/qa_provider_candidate_transaction_yellowprint.v0.md
gate record:
  docs/00_chaos/qa_first_candidate_table_cross_audit_2026-07-26.md
crystall audit:
  docs/00_chaos/qa_first_candidate_crystall_cross_audit_2026-07-26.md
depends on:
  docs/02_crystall/blueprints/qa_native_supervisor.v0.md
  docs/02_crystall/blueprints/qa_contract_profile.v0.md
implementation authority: yes; detached staging, environment reprobe and D RUN only
Packet/body/verdict authority: forbidden
generic executable/command authority: permanently forbidden
platform: Linux x86_64 v0 only
fallback: forbidden
```

## 0. Crystallized Native Claim

```text
one already-open sealed repository fd
  -> one identity-checked detached read-only source mount
  -> one exact candidate process under the measured Lua 5.4 profile
  -> one bounded private process observation or process error
```

A pathname may help the kernel construct the mount. It never becomes source
authority and never crosses the native boundary.

## 1. Exact Native Surface

Modify:

```text
native/proc17_qa_policy.h
native/proc17_qa_wire.h
native/proc17_qa_launcher.c
native/proc17_qa_launcher_internal.h
native/proc17_qa_supervisor.c
native/tests/test_proc17_qa_wire.c
native/tests/test_proc17_qa_launcher.c
native/tests/test_proc17_qa_supervisor.c
native/tests/qa_fixtures/
runtime/qa_provider.lua
tests/test_qa_native_supervisor.lua
```

No second launcher module, supervisor binary, source-staging helper process or
Lua-callable staging function is added.

## 2. C4 - Detached Source Staging State Machine

### 2.1 Owned state

The namespace-init process owns one zero-initialized staging state:

```c
struct proc17_qa_source_stage {
    int source_fd;                 /* fixed fd 3, borrowed then closed */
    int detached_mount_fd;         /* -1 until OPEN_TREE_CLONE succeeds */
    int temporary_self_bind_live;  /* boolean */
    int detached_attached;         /* boolean */
    int host_tmp_hidden;           /* boolean */
    int candidate_started;         /* boolean */
    struct proc17_qa_mount_identity original;
    struct proc17_qa_mount_identity detached;
    struct proc17_qa_mount_identity attached;
};
```

The locator buffer is bounded to `PATH_MAX`, zeroed before use and erased once
the detached mount exists. It is not included in the result frame.

### 2.2 Identity observation

```c
struct proc17_qa_mount_identity {
    uint64_t device;
    uint64_t inode;
    uint64_t mount_id;
};
```

Observation uses descriptor/path `statx` with mount-id support. Missing mount
id support makes the environment unavailable; `fstat`-only identity is not a
fallback.

Equality functions are separate:

```text
same_original(a,b): device + inode + mount_id all equal
same_object(a,b):   device + inode equal
same_staged(a,b):   device + inode + mount_id all equal
```

The detached staged mount id is not compared to the original mount id.

### 2.3 Exact syscall order

After the namespace init has entered the fresh user/mount namespace and made
mount propagation private, execute exactly:

```text
S0  statx(fd3, "", AT_EMPTY_PATH) -> original
    require original == launcher-supplied source identity

S1  readlink("/proc/self/fd/3") into bounded internal locator
    require absolute, nonempty, no " (deleted)" suffix

S2  statx(locator, follow final procfd link) -> locator_before
    require same_original(locator_before, original)

S3  mount(locator, locator, NULL, MS_BIND, NULL)
    set temporary_self_bind_live=true

S4  statx(locator) -> self_bind_identity
    require same_original(self_bind_identity, original)

S5  open_tree(AT_FDCWD, locator, OPEN_TREE_CLONE|OPEN_TREE_CLOEXEC)
    no AT_RECURSIVE import of host submounts
    set detached_mount_fd

S6  statx(detached_mount_fd, "", AT_EMPTY_PATH) -> detached
    require same_object(detached, original)

S7  umount2(locator, MNT_DETACH)
    require success; set temporary_self_bind_live=false
    erase locator; no pathname fallback remains

S8  mount_setattr(detached_mount_fd, "", AT_EMPTY_PATH|AT_RECURSIVE,
      RDONLY|NOSUID|NODEV|NOEXEC)
    reobserve all four flags on detached mount

S9  mount private tmpfs over host /tmp
    set host_tmp_hidden=true
    construct empty candidate root and /qa/source target inside it

S10 move_mount(detached_mount_fd, "", AT_FDCWD, source_target,
      MOVE_MOUNT_F_EMPTY_PATH)
    set detached_attached=true; close detached_mount_fd

S11 statx(source_target) -> attached
    require same_staged(attached, detached)
    require all four mount policy flags

S12 attempt bounded create under source_target
    require EROFS and no new path

S13 close fd3 and every setup-only descriptor
    pivot into the empty root using the existing supervisor sequence

S14 only now fork/create the candidate task
    set candidate_started=true before candidate code enters Lua
```

After S7 there is no legal operation that resolves the host source by path.
After S9 the old host `/tmp` is not visible. Source physically located beneath
host `/tmp` therefore remains reachable only through the detached mount fd.

### 2.4 Staging attestation on native wire

The private `RUN_RESULT` payload contains:

```c
struct proc17_qa_source_staging_attestation_v0 {
    uint16_t policy_code;          /* detached_mount_v0 only */
    struct identity original;
    struct identity detached;
    struct identity attached;
    uint32_t mount_policy_flags;   /* exact four required bits */
    uint8_t temporary_self_bind_detached;
    uint8_t candidate_started_after_attestation;
};
```

The launcher validates:

```text
original == its pre-exec source identity
detached device/inode == original device/inode
attached == detached including staged mount id
all four flags exact
temporary self-bind detached=true
candidate started only after complete attestation
```

Raw identities and this attestation do not enter the Lua process observation.
The launcher projects only the measured staging-policy identity and success
fact after validation.

### 2.5 Cleanup machine

Cleanup always walks owned state in reverse:

```text
candidate pid/task, if any: terminate whole candidate world and reap
attached detached mount: dies with private mount namespace teardown
detached mount fd: close if still open
temporary self-bind: umount2(MNT_DETACH) if live
private tmpfs/root: detach inside namespace
fd3/fd4/fd5/fd6 and internal pipes: close by owner
namespace init and outer supervisor: reap
```

Classification:

```text
failure before candidate start + every owned resource terminal
  -> private process error world/source_staging_failed

identity contradiction, impossible state transition or malformed attestation
  -> trusted invariant; launcher loud

any unproven mount/fd/process cleanup or source continuity
  -> private process error ambiguous; source lease must quarantine
```

The cleanup function returns a proof bitset. A zero error return without every
required terminal bit is itself a trusted contradiction.

### 2.6 C4 controls

```text
DS01 source below host /tmp stages after /tmp is hidden
DS02 locator substitution before self-bind starts no candidate
DS03 wrong detached device/inode never reaches move_mount
DS04 cloned mount id different from original is legal
DS05 attached mount id different from detached is rejected
DS06 source create/write/rename/unlink returns EROFS
DS07 self-bind is absent after setup
DS08 setup failure has candidate_started=false
DS09 cleanup ambiguity cannot return candidate report
DS10 candidate inherits none of fd3..fd6
DS11 raw locator/identity/attestation cannot cross to Lua
DS12 PROBE and RUN call the same staging function
```

## 3. C5 - Environment Identity Rotation

### 3.1 Policy and feature identity

Add one required feature bit:

```c
PROC17_QA_FEATURE_DETACHED_SOURCE_STAGING = 1U << 15
```

It enters `PROC17_QA_REQUIRED_PROBE_FEATURES` and therefore
`isolation_feature_set_id`.

Change the policy version from:

```text
proc17.qa.isolation_policy.x86_64.v0
```

to:

```text
proc17.qa.isolation_policy.x86_64.v1
```

The policy digest commits to:

```text
exact S0-S14 order
identity comparison roles
mount flags and nonrecursive source import
fixed descriptor contract including fd6
cleanup proof requirements
RUN request/result enum tables and resource ceilings
```

### 3.2 Build identities

Rebuilding changed sources must rotate:

```text
supervisor_build_id
provider_build_id when launcher module bytes change
runtime_dependency_closure_id only when its admitted static closure changes
```

`environment_id` is rederived by the existing `core.qa_schema` algorithm from
the changed feature, policy and build coordinates. No new environment-id
algorithm is introduced.

### 3.3 Probe law

`probe_environment` opens the internal immutable probe source as fd3 and calls
the same source-staging function used by RUN. It must exercise:

```text
detached clone and original/staged identity split
self-bind removal
host /tmp hiding after detachment
move_mount continuity
read-only/nosuid/nodev/noexec source
candidate inability to write source
complete mount/fd/process teardown
```

The probe may add assertions around that function. It may not keep its old
direct-bind path.

An old step-C environment remains valid historical evidence but is not
resolvable for D. A contract naming it becomes `not_ready`; no record is
rewritten in place.

### 3.4 C5 controls

```text
EN01 detached staging feature absent -> environment unavailable
EN02 old feature/policy id cannot satisfy D request
EN03 changed supervisor/launcher bytes rotate environment identity
EN04 probe path and RUN staging function pointer are identical
EN05 probe SKIP/fallback publishes no available environment
EN06 old environment record remains immutable historical evidence
```

## 4. C6 - Native RUN ABI

### 4.1 Fixed descriptor ABI

Before supervisor `execveat`:

```text
fd 0  EOF-safe supervisor stdin
fd 1  closed
fd 2  closed
fd 3  duplicated exact sealed repository root
fd 4  authenticated request-frame read end
fd 5  authenticated result-frame write end
fd 6  exact opened supervisor executable for post-exec self hashing
```

Rules:

```text
fd6 closes immediately after self hash/ABI verification
fd3 closes after detached staging and before candidate creation
fd4 closes after exact request frame consumption
fd5 closes after exact result write or terminal error cleanup
candidate inherits none of fd3..fd6
all unrelated descriptors are closed before exec/candidate creation
```

Descriptor numbers are ABI constants shared by launcher and supervisor tests.

### 4.2 Lua native request

`runtime/qa_provider.lua` accepts only:

```lua
{
  protocol_version = "qa.native_run_request.v0",
  operation = "run_lua54_test_suite",
  transaction_id = "qa-provider-transaction:<sha256>",
  witness_id = "qa-provider-witness:<sha256>",
  profile_id = "qa.profile.lua54_test_suite.v0",
  environment_id = "qa-environment:<sha256>",
  entrypoint_relative_path = "tests/run.lua",
  expected_exit_code = 0,
  resource_limits = qa_resource_limits,
}
```

Unknown keys, malformed tagged identities, noncanonical paths, changed profile,
nonzero expected exit or limits unequal to the selected environment are
rejected before the native call.

The launcher obtains root device/inode/mount id from repository userdata. Lua
cannot supply those fields.

### 4.3 Existing wire envelope

Keep without version change:

```text
magic P17QA0\0\0
version 0
maximum frame 4096 bytes
PROBE_REQUEST=1
PROBE_RESULT=2
RUN_REQUEST=3
RUN_RESULT=4
```

`RUN_REQUEST` payload, exact big-endian order:

```text
32 transaction digest (tag removed and verified)
32 witness digest
32 profile digest
32 environment digest
8  root device
8  root inode
8  root mount id
10 x 8 resource-limit integers in qa_resource_limits schema order
4  expected exit code (must be 0)
2  entrypoint byte count
N  entrypoint UTF-8 bytes
```

The existing frame nonce is the 32-byte transaction digest. Payload transaction
digest must equal envelope nonce; disagreement is malformed trusted input.

### 4.4 RUN result dispositions

`RUN_RESULT` is the single result kind. Its payload begins with one disposition:

| Code | Meaning |
|---:|---|
| 1 | contained candidate outcome |
| 2 | typed provider/process error |

Candidate outcome reason codes:

```text
1 expected_exit
2 unexpected_exit
3 signal
4 wall_timeout
5 cpu_limit
6 memory_limit
7 output_limit
8 scratch_limit
9 sandbox_policy_violation
```

Provider error class codes:

```text
1 unavailable
2 world
3 ambiguous
```

Provider error stage codes include exactly:

```text
preflight
source_staging
namespace
launch
supervision
postflight
cleanup
```

The full payload carries, in fixed order:

```text
transaction and witness digests
profile/environment digests
disposition + reason or error class/code/stage
candidate_started and cleanup-complete flags
termination kind/exit/signal
wall, user CPU and system CPU measurements
stdout/stderr observed counts, limit flags and SHA-256 digests
scratch bytes/entries and limit flags
source-staging attestation from C4
```

Every enum has a closed numeric table in one shared header. Unknown/reserved
values, impossible flag combinations, short/trailing bytes and digest mismatch
are loud native-contract failures.

### 4.5 Silent stream law

For a stream with no bytes:

```text
observed_bytes = 0
limit_reached = false
sha256 = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

RUN does not inherit the probe's nonempty-output expectation.

### 4.6 Candidate fixtures

Add two fixed inert sources to the hostile fixture manifest:

```text
clean_silent/tests/run.lua
  executes successfully, writes no stdout/stderr, uses no scratch

runtime_error_silent/tests/run.lua
  raises one fixed Lua error, writes no stdout/stderr, uses no scratch
```

The supervisor maps an unhandled Lua load/runtime error to:

```c
#define PROC17_QA_CANDIDATE_LUA_ERROR_EXIT 70
```

The ordinary Lua test runner may reach their bytes only through the existing
fixture guard. Execution occurs only through the production native supervisor.

Expected classifications:

```text
clean_silent -> contained / expected_exit / exit 0
runtime_error_silent -> contained / unexpected_exit / exit 70
```

### 4.7 C6 controls

```text
NW01 every malformed RUN request/frame is rejected before candidate
NW02 envelope nonce and payload transaction digest must agree
NW03 root identity comes only from repository userdata
NW04 fd6 self digest mismatch starts no namespace
NW05 candidate sees none of fd3..fd6
NW06 clean silent stream hashes equal SHA-256 empty digest
NW07 Lua runtime error is contained candidate outcome, not provider corruption
NW08 unknown result enum is loud
NW09 incomplete measurement cannot become contained outcome
NW10 raw output/source identities/paths never enter Lua result
```

## 5. Supersession Map

This blueprint supersedes only:

```text
qa_native_supervisor.v0.md section 5 generic qa.native_request wording for D
qa_native_supervisor.v0.md section 7 descriptor list without fd6
qa_native_supervisor.v0.md section 10 direct procfd bind mount sequence
qa_native_supervisor.v0.md probe claim wherever it used a distinct direct-bind path
```

It preserves the existing memory-erasure boundary, namespace roles, Lua state,
seccomp policy, rlimits, watchdog, bounded output/scratch and complete-reap
contracts.

## 6. Blueprint Thesis

```text
The sealed fd is the authority, the transient pathname is construction debris,
and the detached mount is the only source object allowed to enter the candidate
world. RUN proves process physics; it still proves nothing to the Packet.
```
