# QA Measurement E4 Topology Audit

Status:

```text
layer: CHAOS implementation audit
date: 2026-07-28
checkpoint: a194b1a (E3 complete)
scope: E4.0 / C5 measurements
runtime authority granted by this note: no
production execution: RUN v0
body QA authority: absent
```

## 1. Verdict

The C5 measurement model fits the physical process tree already present in the
supervisor. The namespace child is already the natural controller: it mounts
the isolated world, forks the candidate, owns the candidate pidfd and wall
timer, drains output and reaps the candidate before it exits.

C5 must not be inserted by extending the current v0 result fields in place.
The current path deliberately collapses evidence that v1 must keep separate.
E4 should build a production-linked but unrouted v1 controller path beside it;
E5 will later select that path atomically with RUN v1.

One contract contradiction was found before code:

```text
C4 prelude: close every remaining non-stdio descriptor before Lua
C5 poll set: retain a private ready/status descriptor
C5 allocator: transfer a fixed allocator record after Lua closes
```

All three statements cannot be literal at once. Section 7 records the proposed
resolution. TABLE/CRYSTALL must receive the narrow amendment before E4 code can
retain that descriptor.

## 2. Actual Process Tree

```text
Lua/provider process
  launcher callback owns exact sealed source userdata
    -> fork + execveat exact static supervisor
       supervisor fds: 3 source, 4 request, 5 result, 6 self image
       top-level supervisor parses request and verifies source/self
         -> clone3 namespace controller
            user/mount/pid/net/ipc/uts namespaces
            controller builds mounts and pivots root
              -> fork candidate
                 candidate applies environment/rlimits/capability drop/seccomp
                 candidate creates fresh restricted Lua state
            controller drains output, waits candidate, then exits
       top-level supervisor waits controller and emits one v0 terminal frame
  launcher polls supervisor pidfd + result fd + outer watchdog
```

This is close to the crystallized C4/C5 topology. No additional orchestration
process is required.

## 3. Current Descriptor Ownership

| Descriptor/channel | Current writer | Current reader | Current lifetime |
|---|---|---|---|
| request pipe | launcher | top supervisor fd 4 | closed after request parse |
| public result pipe | top supervisor fd 5 | launcher | one v0 terminal frame, then supervisor exit/EOF |
| source fd | launcher callback/top supervisor fd 3 | namespace controller mount setup | controller closes after staging |
| namespace synchronization | top supervisor | namespace controller | uid/gid mapping barrier only |
| source-stage report | namespace controller | top supervisor | one early native struct |
| candidate output | candidate stdout and stderr merged into one pipe | namespace controller | drained through one v0 observer |
| candidate pidfd | none | namespace controller | candidate terminal observation |
| namespace pidfd | none | top supervisor | outer cleanup/watchdog observation |

The candidate currently executes `close_range(3, UINT_MAX)` before
`prepare_candidate`. This correctly removes inherited supervisor authority for
v0, but it also means E3 STARTED and the C5 allocator status cannot simply be
wired through the existing child path.

## 4. Expected Gaps, Not Regressions

These are missing C5 capabilities, not defects in the admitted RUN v0 claim.

### G1 - stdout and stderr are merged

`run_lua_task` duplicates one pipe onto both fd 1 and fd 2. The observer hashes
the merged byte order and discards the digest. C5 requires two independent
ordered measurements and two EOF facts.

### G2 - candidate metrics are reported from the wrong process boundary

`run_namespace_probe` currently measures wall time around namespace setup and
uses `wait4` rusage for the namespace controller. C5 requires candidate wall
time and the rusage returned when the controller reaps the candidate. The
controller must transport those fixed measurements to the top supervisor.

### G3 - candidate start is declared before candidate birth

`namespace_probe_child` sets `stage.candidate_started = 1` before
`run_lua_task` forks. That field is sufficient only for the historical v0
probe. It cannot be reused as STARTED v1 evidence.

### G4 - allocator evidence is incomplete and discarded

The existing allocator stores only `used` and `ceiling`. It does not preserve
peak use, distinguish policy-ceiling denial from host allocation failure, or
return a final record to the controller.

Required private distinction:

```text
ceiling_denied   -> may establish memory_limit first cause
system_failed    -> never laundered into memory_limit
```

Only `runtime_heap_denied` crosses the sanitized v1 resource record. A system
allocation failure remains candidate unexpected exit or infrastructure
failure according to the rest of the evidence.

### G5 - CPU and wall clocks are collapsed

The current candidate RLIMIT_CPU uses equal soft and hard values. The v1 policy
requires the declared soft limit and a one-second hard emergency limit so that
SIGXCPU is a positive CPU witness. The current outer namespace watchdog remains
an infrastructure ceiling; it is not candidate wall time.

### G6 - scratch has containment but no terminal measurement

The tmpfs byte/inode limits and trusted `home`/`tmp` creation already exist.
Production RUN does not inventory scratch after candidate reap. C5 must capture
baseline object identities before release, then perform one bounded no-follow
walk and capacity observation after reap.

### G7 - controller evidence is compressed into an exit byte

The namespace controller currently returns only an exit status plus one early
source-stage struct. Signals, first cause, separate EOFs, allocator state,
candidate rusage and scratch state cannot survive that boundary. v1 needs one
fixed private controller report. It is evidence consumed by the top supervisor,
not a second public result protocol.

### G8 - launcher accepts one frame only

`collect_probe_result` accumulates the entire result pipe and decodes one frame.
RUN v1 requires STARTED followed by TERMINAL. This belongs to E5/C6 and must not
be pulled into E4.

## 5. Exact Future Ownership

```text
candidate C prelude
  owns public STARTED write descriptor until one atomic frame is written
  owns one private status write descriptor invisible to Lua
  owns stdout/stderr write descriptors
  owns no source, request, supervisor, mount or public terminal authority

namespace controller
  owns candidate pidfd and wall timerfd
  owns stdout/stderr drains
  owns private status read descriptor
  is the sole writer of first-cause state
  owns candidate wait4/rusage and scratch observation
  emits one fixed private controller report after all local finality attempts

top-level supervisor
  owns the public terminal result descriptor
  validates the controller report after controller reap
  alone marks namespace_cleanup_complete
  emits TERMINAL or typed infrastructure ERROR

launcher
  owns supervisor pidfd, public result read descriptor and outer watchdog
  validates STARTED/TERMINAL/reap/EOF sequence
  exposes only one sanitized terminal Lua table
```

The top-level supervisor derives the eighth finality fact after controller
reap. The controller report carries the first seven facts and the immutable
first cause. This is a writer/reader boundary, not two mutable ledgers.

## 6. Why Existing v0 Must Stay Intact Through E4

Changing `run_lua_task` directly would combine four migrations:

```text
merged -> separate streams
exit byte -> typed controller report
one terminal frame -> STARTED + TERMINAL
v0 result -> v1 result
```

A failure would not identify which contract broke. E4 therefore adds and
exercises C5 machinery through native test harnesses while RUN v0 remains the
control line. E5 performs the one explicit authority switch.

The allocator is the exception to code duplication: the existing bounded
allocator should be extended in place or moved into one shared internal module.
Two independent heap-ceiling implementations would create two calculators of
the same runtime truth.

## 7. Descriptor Contradiction And Proposed Amendment

### Precision correction after abrupt-death analysis

The first audit pass proposed transporting the final allocator record through
the status pipe after `lua_close`. That is insufficient: CPU, wall and output
termination can kill the candidate before its trusted epilogue runs, while the
v1 resource record still requires exact heap peak/denial evidence.

The corrected design separates notification from truth:

```text
private status socket       bounded wakeup/handshake events only
shared allocator telemetry  sole allocator-owned measurement record
controller first-cause      sole cause authority
```

The telemetry page is not a second phase/cause ledger. The candidate allocator
is its only writer; the controller reads it after a notification or candidate
reap. No candidate semantic code receives its address.

### Option A - private status socket plus allocator telemetry (recommended)

Keep exactly one `O_CLOEXEC` private `AF_UNIX/SOCK_SEQPACKET` endpoint in the
candidate after STARTED. It has no Lua userdata, library function, path,
environment variable or public number. The isolated root has no proc/dev fd
namespace from which Lua can recover it. One bidirectional endpoint supports a
READY/RELEASE barrier without retaining a second candidate descriptor.

The trusted C allocator updates one fixed anonymous shared telemetry record.
On its first policy-ceiling refusal it writes one bounded HEAP_DENIED
notification to the status socket. The notification wakes the controller but
does not duplicate heap truth. The controller reads the telemetry record and
claims first cause. Abrupt candidate death cannot erase the record.

Amended prelude law:

```text
close the public STARTED descriptor before candidate bytes;
close every candidate-reachable non-stdio descriptor;
retain exactly one C-private status endpoint until candidate termination;
retain one descriptor-free allocator telemetry mapping owned by trusted C;
observe status EOF and stable telemetry before candidate result completion.
```

This preserves a single first-cause writer: the controller receives the event
and claims the E3 slot. The candidate never writes cause truth directly.

### Option B - shared phase/cause state (rejected)

Using shared memory for phase transitions or first cause would create
cross-process mutable authority and require process-shared CAS arbitration.
Using shared memory without the status socket would also fail to wake the
controller when Lua catches an allocation error and keeps running. Only the
single-writer allocator measurement record is admitted.

### Option C - dedicated exit code (rejected)

An exit code arrives too late to order allocator denial against output/wall
events and cannot transport peak/current accounting after signal termination.

## 8. E4 Implementation Map

```text
E4.0a TABLE/CRYSTALL amendment for private status + allocator telemetry
E4.1  independent bounded stdout/stderr accumulators and real dual-pipe witness
E4.2  one allocator implementation with current/peak/ceiling/denial/failure
E4.3  controller poll arbitration for pidfd/timerfd/status and candidate wait4
E4.4  bounded no-follow scratch baseline/final observer
E4.5  fixed controller report + E3 finality join, production-linked but unrouted
E4.6  hostile/full batteries, manifest and checkpoint
```

## 9. Required Falsifiers

```text
stdout bytes never enter stderr digest and vice versa
first byte beyond a stream limit sets one cause and still drains both EOFs
empty stream hashes exactly SHA-256(empty)
host malloc failure cannot set runtime_heap_denied
allocator denial cannot be rewritten by later wall/cleanup events
abrupt SIGKILL cannot erase allocator peak/denial telemetry
status notification and allocator telemetry mismatch is infrastructure
missing/private-status EOF suppresses candidate result
Lua cannot name, enumerate, read, write or close the private status descriptor
candidate rusage is not namespace-controller rusage
outer watchdog never becomes candidate wall_timeout
baseline home/tmp replacement is infrastructure ambiguity
symlink/special/depth/count scratch ambiguity never becomes rejection
one missing finality member suppresses the candidate result
RUN v0 behavior and the 40/44 QA matrix remain unchanged through E4
```

## 10. Non-Claims

This audit changes no runtime, schema, route, feature identity or QA color. It
does not authorize retaining the private descriptor until the amendment in
E4.0a is accepted. It does not authorize RUN v1; that remains E5.
