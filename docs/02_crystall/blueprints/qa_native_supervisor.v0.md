# QA Native Supervisor Blueprint v0

Status:

```text
layer: crystall (◈)
date: 2026-07-23
source table:
  docs/01_table/yellowprints/qa_execution_capability_yellowprint.v0.md
crystall audit:
  docs/00_chaos/qa_crystall_cross_audit_2026-07-23.md
depends on:
  docs/02_crystall/blueprints/qa_contract_profile.v0.md
  docs/02_crystall/blueprints/qa_execution_capability.v0.md
implementation authority: environment probe, hostile native fixtures and one
  exact Linux supervisor after the hostile-red gate
production candidate execution authority: forbidden until step 8.5.5 gate
platform: Linux x86_64 v0 only
fallback: forbidden
amended 2026-07-26: D RUN and detached-source construction are owned by
  docs/02_crystall/blueprints/qa_detached_source_staging.v0.md
amendment gate:
  docs/00_chaos/qa_first_candidate_table_cross_audit_2026-07-26.md
amendment crystall audit:
  docs/00_chaos/qa_first_candidate_crystall_cross_audit_2026-07-26.md
```

## 0A. 2026-07-26 D Amendment

This blueprint keeps ownership of the complete supervisor architecture,
memory-erasure boundary, namespace roles, seccomp, resources and cleanup.

For step D, these narrower sections are superseded:

```text
section 5 generic native request -> exact qa.native_run_request.v0
section 7 fd list             -> fixed fd3..fd6 ABI
section 10 direct source bind -> detached staging state machine
section 16 probe mount path   -> same staging function as RUN
```

The implementation authority for those details is:

```text
qa_detached_source_staging.v0.md
```

The old text remains architectural archaeology and must not be used as a
fallback when detached staging fails.

## 0. Native Decision

The candidate must not inherit the proc-17 process image.

Selected shape:

```text
proc-17 Lua process
  -> fixed in-process launcher module
  -> fork
  -> execveat one exact opened static supervisor executable
  -> clone3 one namespace-init process
  -> fork one candidate task inside the new PID/mount/user/network world
  -> create a fresh Lua state only in that candidate task
```

Rejected shape:

```text
fork proc-17 and run candidate Lua without exec
```

That rejected child would retain substrate sessions, private capability
registries, prompts, host paths and every other proc-17 secret in its address
space even if Lua globals were hidden. `execveat` is the memory-erasure
boundary.

The namespace-init and outer supervisor are trusted mechanics. Exactly one task
runs candidate code. `max_processes=1` refers to candidate authority, not the
trusted containment processes required to supervise it.

## 1. Exact Native Surface

New files:

```text
native/proc17_qa_launcher.c
native/proc17_qa_supervisor.c
native/proc17_qa_wire.h
native/proc17_qa_policy.h
native/proc17_repository_handle_abi.h
native/proc17_sha256.c
native/proc17_sha256.h
native/tests/test_proc17_qa_launcher.c
native/tests/test_proc17_qa_supervisor.c
native/tests/proc17_qa_launcher_wrong_abi.c
native/tests/qa_fixtures/*.fixture
```

Generated build input:

```text
native/generated/proc17_qa_build_identity.h
```

Build outputs:

```text
native/proc17_qa_launcher.so
native/proc17_qa_supervisor
```

Modify:

```text
native/Makefile
native/proc17_repository_fs.c
runtime/qa_provider.lua
```

The repository provider's public Lua API and provider id do not change. Its
internal userdata receives a versioned shared prefix so the launcher can borrow
the exact root descriptor without exposing it to Lua.

## 2. Build And Dependency Closure

`proc17_qa_supervisor` is a static PIE containing the admitted Lua 5.4 static
library and the fixed candidate runtime wrapper.

Required build properties:

```text
-static-pie
-fPIE
-fstack-protector-strong
-D_FORTIFY_SOURCE=3
-Wall -Wextra -Werror
linker RELRO/NOW where meaningful for static PIE
no DT_NEEDED entries
no PT_INTERP dynamic loader dependency
embedded Lua version exactly 5.4
```

The build fails closed if the static Lua archive, static libc closure or
required compiler/linker mode is unavailable. It must not silently build a
dynamic supervisor under the same provider/environment identity.

Build order:

```text
1. locate and validate the exact Lua 5.4 headers/static archive
2. hash the static Lua archive and normalized compile policy
3. build the static supervisor
4. hash the exact supervisor bytes
5. emit proc17_qa_build_identity.h with supervisor/runtime identities
6. build the launcher module against that expected supervisor identity
7. verify ELF closure and run the supervisor self-test
```

`runtime/qa_provider.lua` hashes the bounded launcher-module bytes before
`package.loadlib`; that digest is `provider_build_id`. The launcher opens the
fixed sibling supervisor with no-follow semantics, hashes the opened bytes and
requires equality with the compiled expected digest before `execveat`.

The host-same-authority replacement threat remains inside the trusted host
boundary, as it does for the first repository hand. Candidate/task data cannot
select or replace either file.

## 3. Launcher Lua ABI

The module exports exactly:

```c
int luaopen_proc17_qa_launcher(lua_State *L);
```

Returned table:

```lua
{
  protocol_version = "qa.native_launcher.v0",
  abi_version = "proc17.qa.launcher.lua54.v0",
  provider_id = "linux.qa_supervisor.lua54.v0",
  supervisor_abi = "proc17.qa_supervisor.v0",
  expected_supervisor_build_id = "sha256:<hex>",
  runtime_build_id = "sha256:<hex>",
  policy_digest = "sha256:<hex>",
  limits = exact_native_hard_limits,
  probe_environment = C_function,
  run_lua54_test_suite = C_function,
}
```

The key set is exact. The Lua adapter rejects unknown/missing keys, wrong ABI,
wrong provider id, wrong limits or non-functions.

`run_lua54_test_suite` accepts exactly:

```text
argument 1: internal repository-handle userdata
argument 2: strict native-request plain table
```

It accepts no path to the repository, executable, command, argv, environment,
cwd, mount or syscall list.

## 4. Shared Repository Handle ABI

`native/proc17_repository_handle_abi.h` owns an internal prefix:

```c
#define PROC17_REPOSITORY_HANDLE_MAGIC UINT64_C(0x5031375245504f30)
#define PROC17_REPOSITORY_HANDLE_ABI 1U
#define PROC17_REPOSITORY_HANDLE_METATABLE \
    "proc17.repository.handle.internal.v0"

struct proc17_repository_handle_prefix_v0 {
    uint64_t abi_magic;
    uint32_t abi_version;
    uint32_t struct_bytes;
    int project_base_fd;
    int repository_fd;
    int closed;
    uint32_t reserved;
    uint64_t project_device;
    uint64_t project_inode;
    uint64_t project_mount_id;
    uint64_t repository_device;
    uint64_t repository_inode;
    uint64_t repository_mount_id;
};
```

The repository module initializes and validates this prefix. The QA launcher:

```text
checks the exact Lua metatable
checks magic, ABI and minimum struct_bytes
checks closed == false
duplicates repository_fd with F_DUPFD_CLOEXEC
observes the duplicate with statx(AT_EMPTY_PATH)
requires device/inode/mount identity equality
never reads the flexible path tail
never returns the descriptor number to Lua
```

The duplicate belongs to one native transaction and is closed on every branch.
Changing this internal prefix requires rebuilding both native components and a
new launcher build/environment identity.

## 5. Native Request Contract

The Lua adapter normalizes to:

```lua
{
  protocol_version = "qa.native_request.v0",
  transaction_nonce = "sha256:<random-32-bytes>",
  request_digest = "sha256:<hex>",
  profile_digest = "sha256:<hex>",
  environment_digest = "sha256:<hex>",
  entrypoint = string,
  resource_limits = qa_resource_limits,
}
```

The nonce is private random transaction identity, not Packet entropy. The three
digests are raw 32-byte values on the wire. Entrypoint obeys the already
validated repository relative-path law.

The launcher independently rejects:

```text
unknown/missing table keys
non-canonical digest encoding
path NUL/control/dot/dot-dot/leading-dot components
path or limit beyond compiled hard ceilings
cpu_time_ms not a positive multiple of 1000
max_processes other than 1
```

## 6. Binary Wire Protocol

The launcher and supervisor communicate through fixed pipes. They do not use
JSON, shell quoting, environment variables, inherited argv data or native C
struct dumps.

Frame envelope, encoded field-by-field in big-endian order:

```text
8 bytes   magic: "P17QA0\0\0"
2 bytes   protocol version: 0
2 bytes   message kind
4 bytes   payload byte count
32 bytes  transaction nonce
N bytes   exact payload
32 bytes  sha256 of every preceding frame byte
```

Maximum frame is 4096 bytes. Short, oversized, trailing, wrong-magic,
wrong-version, unknown-kind or digest-mismatched frames are trusted protocol
failures.

Request payload fixed order:

```text
32 request digest
32 profile digest
32 environment digest
8  root device
8  root inode
8  root mount id
10 x 8 resource-limit integers in schema order
2 entrypoint byte count
N entrypoint bytes
```

Result payload uses closed numeric enums and fixed-width integers for:

```text
candidate/provider disposition
reason/error/stage codes
candidate-started/source-stable/cleanup flags
termination kind/exit/signal
wall and rusage measurements
stdout/stderr counts and SHA-256 digests
scratch counts
supervisor/source identities
```

The launcher translates numeric enums into the closed Lua vocabularies. Unknown
numeric values are loud native-contract failures.

## 7. Fixed Descriptor Contract

Amendment: step D uses fd 6 for the already-open supervisor executable during
post-exec self hashing. The exact fd3..fd6 ownership/closure law is defined in
`qa_detached_source_staging.v0.md` C6 and replaces the list below.

Before `execveat`, the launcher child owns exactly:

```text
fd 0  closed/EOF-safe supervisor stdin
fd 1  inherited nowhere; closed
fd 2  inherited nowhere; closed
fd 3  duplicated exact repository root, read-only, CLOEXEC cleared for exec
fd 4  request pipe, read end
fd 5  result pipe, write end
```

The parent opens, validates and allocates every descriptor before `fork`. The
fork child performs only async-signal-safe descriptor operations,
`PR_SET_PDEATHSIG`, `execveat` and `_exit`; it does not allocate, call Lua,
inspect environment strings or acquire a lock inherited from the proc-17
process.

The exact supervisor executable is invoked by its already-open descriptor:

```c
execveat(supervisor_fd, "", fixed_argv, empty_envp, AT_EMPTY_PATH)
```

`fixed_argv` contains only the fixed supervisor program name and protocol mode.
The request is read from fd 4. Every other descriptor is closed using
`close_range` with a bounded fallback loop only if that exact fallback is part
of a distinct exercised feature-set identity.

The supervisor sets `PR_SET_PDEATHSIG=SIGKILL` before any fork. Candidate output
descriptors are created internally after exec and are never inherited from
proc-17.

## 8. Process Roles And Watchdogs

Three trusted/untrusted roles:

```text
outer supervisor
  lives outside the new PID namespace
  owns user/group mapping, hard outer deadline, namespace-init pidfd and final
  wire report

namespace init (PID 1 inside)
  owns mount construction, candidate pipes, candidate wait/rusage, scratch
  observation and namespace-local cleanup

candidate task
  owns one fresh restricted Lua state and no supervisory descriptor
```

Outer deadline:

```text
requested candidate wall_time_ms
+ fixed setup_cleanup_grace_ms = 5000
```

The policy digest binds the grace. Expiry kills namespace init by pidfd,
reaps it and relies on PID-namespace teardown to kill all remaining tasks.
Failure to prove reap/pipe EOF becomes `process_cleanup_ambiguous`, never a
candidate timeout.

Namespace init owns the candidate wall timer at the exact requested limit. A
proved timer expiry followed by complete candidate kill/reap/postflight is
`wall_timeout` candidate rejection.

## 9. Namespace Creation Order

Exact production order:

```text
1. outer supervisor validates request frame and exact root statx identity
2. clone3 namespace init with CLONE_NEWUSER | CLONE_NEWNS | CLONE_NEWPID |
   CLONE_NEWNET | CLONE_NEWIPC | CLONE_NEWUTS and SIGCHLD
3. child blocks on a private synchronization pipe
4. outer writes "deny" to /proc/<pid>/setgroups
5. outer maps container uid/gid 0 to exactly its own effective uid/gid
6. outer signals mapping completion
7. namespace init verifies uid/gid 0, sets hostname "proc17-qa"
8. mount propagation becomes MS_PRIVATE recursively
9. construct isolated root and mounts
10. install fixed rlimits and candidate pipes/timers
11. fork exactly one candidate task
12. candidate closes supervisor descriptors, drops all capabilities, sets
    no_new_privs and installs seccomp
13. candidate creates a fresh Lua state and runs the sealed entrypoint
14. namespace init drains bounded output and waits with wait4
15. namespace init observes scratch, closes mounts/descriptors and reports
16. outer validates/reaps init and emits one result frame
```

Failure before candidate start is infrastructure. Failure after start is a
clean candidate outcome only when supervision, source handoff, measurement and
cleanup remain fully proved.

## 10. Isolated Mount World

Amendment: the direct procfd bind sequence below is superseded for PROBE and
RUN. Conforming code must use the private self-bind -> detached `open_tree` ->
detach -> `mount_setattr` -> `move_mount` sequence in
`qa_detached_source_staging.v0.md`. Failure has no path/copy fallback.

Namespace init first mounts a private tmpfs over its own `/tmp`; all setup paths
therefore exist only in its mount namespace and leave no host directory residue.
It creates a root mountpoint inside that tmpfs.

Final candidate tree:

```text
/
└── qa
    ├── source    exact repository-root descriptor bind, read-only
    └── scratch   private bounded tmpfs, read-write
        ├── home
        └── tmp
```

Source mount:

```text
non-recursive bind from /proc/self/fd/3 before pivot
mount_setattr with RDONLY | NOSUID | NODEV | NOEXEC
no nested host submount import
root statx identity rechecked before and after bind
```

Scratch mount:

```text
tmpfs size=<scratch_bytes>,nr_inodes=<scratch_entries>,mode=0700
NOSUID | NODEV | NOEXEC
```

The root mount itself is read-only after setup. `pivot_root` enters it, the old
root is detached with `umount2(MNT_DETACH)` and removed. `/proc`, `/sys`, `/dev`,
host `/tmp`, agent sockets, sibling repositories and proc-17 storage are absent.

The source and scratch mounts are distinct, so scratch hard links cannot alias
source objects. The source mount is never an overlay and never copied into a
writable layer.

## 11. Candidate Environment And Lua State

Supervisor calls `clearenv()` and installs exactly:

```text
HOME=/qa/scratch/home
TMPDIR=/qa/scratch/tmp
LANG=C
LC_ALL=C
TZ=UTC
```

Candidate cwd is `/qa/source`; stdin is an already-closed pipe and therefore
EOF. `PATH`, loader variables, agent sockets and host secrets are absent.

A fresh Lua state is created after the candidate fork with a bounded allocator.
Admitted libraries:

```text
base
package
coroutine
table
io
os
string
math
utf8
```

Then the wrapper enforces:

```text
package.path = "./?.lua;./?/init.lua"
package.cpath = ""
package.loadlib = nil
C-module searchers removed
debug library absent
io.popen = nil
io.tmpfile = nil
os.execute = nil
os.tmpname = nil
LUA_INIT and host Lua environment ignored
arg is a fixed table naming only the sealed entrypoint
```

`io.open`, `os.remove`, `os.rename` and Lua file loading remain available so
candidate code can use bounded scratch; mount policy makes source mutation fail.
No candidate file selects the runtime or native code.

The wrapper loads the exact relative entrypoint with `luaL_loadfilex(..., "t")`
and executes it with `lua_pcall`. Binary chunks are rejected. A normal Lua error
becomes a nonzero candidate exit, not supervisor corruption.

## 12. Seccomp Policy

After root construction and fork, the candidate task:

```text
drops every capability from effective/permitted/inheritable sets
sets PR_SET_NO_NEW_PRIVS
installs one architecture-checked seccomp-BPF allowlist
uses SECCOMP_RET_KILL_PROCESS for every unlisted syscall
```

The x86_64 v0 allowlist is generated from this closed set:

```text
read write readv writev close
openat openat2 newfstatat fstat statx lseek pread64
fcntl readlinkat access faccessat2 getcwd getdents64
mkdir mkdirat unlink unlinkat rename renameat renameat2 symlinkat
ftruncate fsync fdatasync umask
brk mmap mprotect munmap mremap madvise
rt_sigaction rt_sigprocmask rt_sigreturn sigaltstack
clock_gettime gettimeofday time nanosleep clock_nanosleep
futex set_tid_address set_robust_list rseq arch_prctl
getpid gettid getuid geteuid getgid getegid uname getrandom
exit exit_group
```

Arguments are restricted where the policy has a stable safe predicate. In
particular, `openat/openat2` remain path-authorized by the isolated mount world;
seccomp cannot safely classify path strings.

Not admitted includes:

```text
clone clone3 fork vfork execve execveat
socket socketpair connect bind listen accept sendmsg recvmsg
mount umount2 pivot_root open_tree move_mount mount_setattr fsopen fsmount
ptrace process_vm_readv process_vm_writev
bpf perf_event_open keyctl add_key request_key userfaultfd io_uring_setup
unshare setns chroot
kill tkill tgkill pidfd_send_signal
```

If the real admitted Lua profile needs another syscall, its hostile test must
first prove the reason and the policy/environment identity changes. The
implementation may not add a broad fallback allowlist to make a test green.

A candidate killed with SIGSYS under an otherwise complete transaction is
`sandbox_policy_violation`. An unknown supervisor/filter state is infrastructure
failure.

## 13. Resource Enforcement

Before candidate code:

```text
RLIMIT_CPU       exact cpu_time_ms / 1000 seconds; cpu limit must be integral
RLIMIT_AS        address_space_bytes
RLIMIT_NOFILE    max_open_files
RLIMIT_FSIZE     max_file_bytes
RLIMIT_CORE      0
RLIMIT_NPROC     1 plus seccomp denial of process creation
fixed stack ceiling bound by isolation policy digest
scratch tmpfs    exact bytes and inode ceiling
```

Wall time is enforced by a parent monotonic timerfd/poll loop. CPU usage and
max RSS come from `wait4/rusage`. A custom Lua allocator sets a private
`memory_limit_reached` marker before refusing an allocation; only that positive
marker permits reason `memory_limit`. Other candidate allocation failures are
ordinary unexpected exits.

`RLIMIT_CPU` SIGXCPU/SIGKILL with complete reap permits `cpu_limit`. SIGXFSZ or
positively observed scratch exhaustion permits `scratch_limit`. A bound is not
inferred merely from candidate error text.

## 14. Output And Scratch Observation

Candidate stdout/stderr are separate nonblocking supervisor-owned pipes. The
supervisor:

```text
hashes incrementally with the shared SHA-256 implementation
retains no raw byte in the final report
records exact observed and hashed byte counts
kills the candidate on the first proven overflow
continues bounded drain to EOF to avoid deadlock
never allocates proportional to output size
```

After candidate reap, namespace init enumerates scratch descriptor-relatively
without following symlinks and records bounded entry/regular-byte counts.
Unknown object types are measurements only because scratch is disposable; any
enumeration ambiguity is infrastructure failure.

No output or scratch content enters the result frame.

## 15. Native Result Classification

Clean candidate result requires:

```text
candidate task started
candidate and namespace-init reaped
all output pipes reached EOF
all measurements complete and within representable bounds
source descriptor identity remained exact inside supervisor
scratch namespace destruction is guaranteed by complete PID/mount teardown
result frame is complete
```

Then:

| Positive observation | Native candidate reason |
|---|---|
| exit 0, no bound/policy event | `expected_exit` |
| other normal exit | `unexpected_exit` |
| ordinary signal | `signal` |
| exact parent wall timer + cleanup | `wall_timeout` |
| exact CPU bound + cleanup | `cpu_limit` |
| allocator marker + cleanup | `memory_limit` |
| stdout/stderr overflow + cleanup | `output_limit` |
| tmpfs/file bound evidence + cleanup | `scratch_limit` |
| SIGSYS from installed exact filter + cleanup | `sandbox_policy_violation` |

Source tree inventory is not recomputed here. The Lua transaction surrounds
the native run with the existing repository provider's exact pre/post
inventory. Native root identity plus those inventories compose the final source
stability claim without creating a second tree-hash implementation.

## 16. Environment Probe

`probe_environment` executes the exact supervisor binary in a fixed probe mode
through the same `fork -> execveat` path. A conforming probe exercises, rather
than merely detects:

```text
static supervisor self-identity and embedded Lua self-test
clone3 user/mount/PID/net/IPC/UTS namespaces
uid/gid mapping and setgroups denial
private mount propagation
tmpfs source/scratch/root construction and pivot_root
mount_setattr read-only source policy
no_new_privs and the exact candidate seccomp program
pidfd, timerfd, wait/reap and output-pipe paths
source-write, fork, exec and socket denial fixtures
complete namespace/mount/scratch cleanup
```

The probe uses an internal immutable fixture, not a user repository. Any SKIP,
partial primitive or weaker fallback returns unavailable and produces no
`qa.environment.v0` under this provider id.

Host observations recorded during crystallization:

```text
Linux 6.18.36_1 x86_64
GCC 14.2.1
Lua 5.4.8
glibc 2.41
unprivileged user namespace ceiling present
required syscall/header declarations present
static liblua5.4 archive present
```

These observations justify building the red probe. They are not runtime proof.

## 17. Cleanup And Ambiguity

Clean completion requires all owned resources to reach a named terminal state:

```text
candidate wait status collected
namespace init wait status collected
pidfds closed
request/result/output/sync pipes closed
repository descriptor duplicate closed
supervisor executable descriptor closed
anonymous mount namespace destroyed
scratch tmpfs destroyed
no private transaction left running
```

PID-namespace death guarantees remaining candidate tasks are killed only after
namespace init itself is proved reaped. If reap, EOF, mount lifetime or report
completion cannot be proved, the launcher returns an ambiguous provider error.
It must not report a clean timeout/rejection.

Repeated hostile tests additionally compare `/proc/self/fd` counts and child
process state around the launcher call. That host observation is diagnostic
evidence for leak controls, not candidate-visible `/proc`.

## 18. Failure Ownership

| Failure | Owner/class |
|---|---|
| malformed Lua native request | trusted adapter invariant, loud |
| wrong launcher/supervisor ABI/build | provider unavailable before candidate |
| execveat fails | `supervisor_launch_failed` |
| namespace/user-map/mount primitive absent | `namespace_unavailable`/`mount_setup_failed` |
| candidate exits/fails under complete containment | clean candidate report |
| outer watchdog cannot prove cleanup | ambiguous `process_cleanup_ambiguous` |
| native frame malformed/impossible | trusted native invariant, loud |
| repository pre/post inventory drift | Lua transaction `source_drift`, not native candidate result |

The native provider reports mechanics only. It cannot write body evidence or a
QA verdict.

## 19. Hostile Native Corpus

Dangerous candidate fixtures are stored as inert `.fixture` bytes and may only
be copied into a temporary sealed test repository consumed by the future QA
provider. The normal Lua test runner never `dofile`s or executes them.

Required fixtures:

```text
clean exit 0
nonzero exit and Lua error
infinite CPU loop
infinite wall sleep/loop
allocator exhaustion
stdout flood and stderr flood
scratch byte/inode exhaustion
source create/overwrite/rename/unlink attempts
host /home, /proc, /sys, /dev and sibling probes
socket/network attempt
fork/clone attempt
exec attempt
native-module load attempt
descriptor enumeration/escape attempt
SIGSYS policy violation
```

Trusted fault fixtures:

```text
wrong launcher ABI
wrong supervisor digest/ABI
short/oversized/corrupt request and result frames
supervisor crash before/after candidate start
lost result pipe
forced wait/reap ambiguity
postflight source drift injected by the trusted harness
```

## 20. Implementation Order

```text
1. wire codec and parser unit tests, all malformed cases red/green
2. shared repository userdata prefix with first-hand regression tests
3. static supervisor build/self-identity gate
4. fork/execveat launcher with no candidate mode
5. exact environment probe and unavailable behavior
6. namespace/mount root construction and teardown
7. restricted fresh Lua state with clean/nonzero fixtures
8. seccomp/resource/output/scratch enforcement
9. outer watchdog, fault injection and ambiguity classification
10. repeated leak/cleanup loops under sanitizers where available
11. expose one strict `run_lua54_test_suite` call to Lua adapter
```

## 21. Promotion Gate

Candidate execution remains disabled unless:

```text
the supervisor is static and exact-build verified
the production environment probe passes without SKIP/fallback
every dangerous fixture is contained and correctly classified
source writes/network/process creation/native loading are denied
timeouts/output/scratch/memory are bounded and reaped
ambiguous cleanup never becomes candidate rejection
wrong ABI/frame/build cases fail closed
100+ repeated hostile transactions leave no fd/process/mount/scratch delta
ASan/UBSan native suites are green where the toolchain supports them
```

## 22. Explicit Deferrals

```text
non-Linux and non-x86_64 providers
dynamic supervisor/runtime closure
Landlock as an additional policy layer
cgroup-based memory/CPU accounting
network, services or multiple candidate processes
external binaries/package managers/compilers
raw output retention
privileged helper or root fallback
persistent/resumable supervisor transactions
```

## 23. Crystall Thesis

```text
The second hand may execute only after proc-17 has erased itself from the child,
built an empty world around one sealed root and made every exit from that world
observable. A weaker world is not the same hand in degraded mode; it is no hand.
```
