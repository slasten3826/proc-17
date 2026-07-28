# QA Measurement E4.0a Status Amendment Cross-Audit

Status:

```text
layer: CHAOS cross-audit evidence + document decision
date: 2026-07-28
checkpoint: a194b1a (E3 complete)
scope: E4.0a private status, release and allocator-survival boundary
audit result: accepted
TABLE/CRYSTALL amendment: satisfied
E4.1-E4.6 implementation authorized: yes, in order
RUN v1 authority: no; E5 only
Packet/body QA authority: forbidden
```

## 0. Audited Surface

```text
docs/00_chaos/qa_measurement_e4_topology_audit_2026-07-28.md
docs/01_table/yellowprints/qa_hostile_execution_campaign_yellowprint.v0.md
docs/02_crystall/blueprints/qa_hostile_execution_campaign.v0.md
docs/00_chaos/qa_hostile_execution_crystall_cross_audit_2026-07-28.md
native/proc17_qa_supervisor.c
native/proc17_qa_phase.c
native/proc17_qa_phase.h
```

This audit checks implementability and ownership only. No runtime, wire,
environment identity, QA color or route changes in E4.0a.

## 1. Decision

Accept the hybrid boundary:

```text
one private SOCK_SEQPACKET endpoint = bounded phase/wakeup transport
one anonymous shared telemetry record = allocator measurement truth
one controller first-cause slot = terminal-cause truth
```

No one of these records substitutes for another. The socket does not own heap
truth; telemetry does not own lifecycle or cause; the cause slot does not own
raw measurements.

## 2. Contradiction Closed

The pre-amendment contracts simultaneously required:

```text
close every non-stdio descriptor before Lua;
retain a ready/status descriptor during execution;
transfer final allocator measurements after Lua closes.
```

That world is impossible. The accepted descriptor law is narrower:

```text
public STARTED descriptor closes before candidate bytes;
every Lua-reachable non-stdio descriptor closes before candidate bytes;
exactly one C-private status endpoint survives until candidate death;
allocator telemetry survives as a descriptor-free mapping;
status EOF and stable telemetry are terminal finality requirements.
```

## 3. STARTED And RELEASE Mean Different Facts

The earlier crystall audit rejected a controller release barrier because it
treated STARTED as proof that candidate instructions had begun. That meaning
was too strong.

The precise facts are:

```text
STARTED = the isolated candidate exists, policy is installed and public start
          attestation is irreversibly emitted;
READY   = the same trusted prelude reached the private controller barrier;
RELEASE = the controller validated READY and armed candidate wall time;
first candidate byte = only after exact RELEASE.
```

This is not a second start authority. STARTED remains the public native phase;
READY/RELEASE is private causal ordering that prevents unmeasured execution.
A failed join after STARTED is therefore a started infrastructure failure, not
a candidate outcome.

## 4. Private Packet Closure

The 184-byte packet is closed over:

```text
magic/version/size
kind
conversation sequence
exact transaction/witness/profile/environment join
private candidate-process token
```

`SOCK_SEQPACKET` preserves one packet boundary. The legal language has three
messages only: READY(1), RELEASE(2), and zero or one HEAP_DENIED(3). EOF closes
the conversation. Unknown kinds, partial/wrong-size packets, duplicates,
reordering and identity/token mismatch are infrastructure failures.

The endpoint has no Lua projection. Candidate semantic code cannot discover,
close, write or retain it as output.

Implementation precision discovered by the first native test:

```text
candidate seccomp already permits read/write/fcntl;
candidate seccomp does not permit send/recv/sendmsg/recvmsg;
therefore seqpacket records travel through write/read;
the receive buffer is 185 bytes and only an exact 184-byte read is valid;
SIGPIPE is ignored by trusted prelude before seccomp;
the candidate endpoint becomes nonblocking after RELEASE.
```

The failed `send` probe returned `EPERM` and prevented an unnecessary syscall
surface expansion. Record boundaries remain supplied by `SOCK_SEQPACKET`.

## 5. Abrupt-Death Proof

A final allocator record sent after `lua_close` fails under every enforcement
path that kills the candidate before its epilogue:

```text
wall timeout
CPU enforcement
output enforcement
sandbox signal
controller emergency kill
```

The shared allocator record survives all of them because the controller owns a
read-only mapping and reads it after candidate reap. `current_bytes` may remain
nonzero after abrupt death; `peak_bytes` and sticky flags remain valid.

The measured quantity is allocator reservation, not host RSS. An in-budget
request is published before entering host allocation. If host allocation
returns failure, its sticky flag is published and current is rolled back; peak
continues to describe the maximum authorized reservation. This closes the
otherwise unavoidable kill window between `malloc` return and telemetry store.

The mapping is admitted only because it is single-writer measurement state.
Shared phase, release or cause fields remain forbidden.

## 6. Atomicity Gate

The telemetry ABI requires proved lock-free interprocess atomics with fixed
size, offset and alignment. Candidate allocator stores publish with release
ordering; controller loads use acquire ordering. After reap, the candidate can
no longer mutate the record.

A target that cannot prove the ABI and lock-free operations is unavailable
before candidate start. It may not substitute a process-local lock,
process-shared mutex or best-effort volatile field.

## 7. Memory Cause Join

The allocator has two non-equivalent failure facts:

```text
ceiling_denied            policy budget was exceeded
system_allocation_failed  host allocator could not satisfy an in-budget call
```

`memory_limit` requires all of:

```text
exact HEAP_DENIED notification
ceiling_denied = true
system_allocation_failed = false
controller first-cause claim succeeds
```

Both flags true, notification/page disagreement, failed notification or a
second HEAP_DENIED is infrastructure ambiguity. Candidate text and exit status
cannot establish memory limit.

## 8. Writer And Reader Audit

| Fact | Sole writer | Named reader |
|---|---|---|
| public STARTED | trusted candidate prelude | native launcher phase machine |
| READY/HEAP_DENIED | trusted candidate C path | namespace controller |
| RELEASE | namespace controller | trusted candidate prelude |
| allocator telemetry | trusted candidate allocator | namespace controller |
| first cause | namespace controller CAS | controller report assembler |
| local finality report | namespace controller | top-level supervisor |
| namespace cleanup finality | top-level supervisor after reap | launcher |

Every new record has a named reader and death point. None reaches Packet,
provider semantics, corpus or substrate content directly.

## 9. Authority And Ablation

E4 remains production-linked but unrouted:

```text
RUN v0 behavior remains the control line;
RUN v1 is not selected;
no Lua request/result schema changes in E4.0a;
no Packet trace, route, loss, budget or repository mutation changes;
no body check, verdict or completion authority appears.
```

The private process token stays native. L1 provenance and future public
candidate signatures are unrelated to this transport and grant no execution
authority.

## 10. Required Falsifiers

```text
candidate bytes execute before RELEASE
READY is sent before successful public STARTED write and close
timer is armed after RELEASE
Lua can name or operate the private endpoint or telemetry mapping
status packet becomes allocator truth or cause truth
allocator mapping gains a second writer
shared phase/cause state appears
abrupt SIGKILL erases peak or sticky flags
HEAP_DENIED without matching telemetry becomes memory_limit
system allocation failure becomes memory_limit
missing status EOF still permits candidate finality
E4 changes RUN v0 or the 40/44 red matrix
```

Any falsifier returns the implementation to TABLE. It is not normalized as
candidate rejection.

## 11. Exit Decision

The E4.0a TABLE/CRYSTALL amendment is internally coherent and implementable
without widening candidate or Lua authority. E4.1 may now build independent
stdout/stderr measurement beside RUN v0. E5 remains the only authority switch
to RUN v1.
