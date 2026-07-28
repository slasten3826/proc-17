# QA Measurement E4.3 Arbitration Notes

Status:

```text
layer: CHAOS implementation decision
date: 2026-07-28
checkpoint: E4.2 verified, RUN v0 still authoritative
scope: candidate clock, wait4 metrics and simultaneous cause readiness
runtime authority granted by this note: no
```

## 1. Problem

The controller will poll independent evidence sources:

```text
stdout
stderr
private allocator status
candidate pidfd
candidate wall timerfd
```

One `poll()` return can mark several sources ready. Iterating descriptors in
array order and claiming the first would turn implementation order into
runtime truth. A timer and an already-dead candidate, or heap denial and output
crossing, may have no observable total order.

## 2. Observation Epoch Law

One successful poll return creates one private observation epoch.

```text
read every ready source far enough to classify its bounded event;
reject malformed/incomplete trusted evidence before cause selection;
collect the set of positive terminal-cause candidates;
zero cause kinds         -> continue observation;
one distinct cause kind  -> controller claims the immutable first-cause slot;
multiple distinct kinds  -> infrastructure ambiguity, no candidate result.
```

Two streams crossing in one epoch collapse to the one semantic kind
`output_limit`; both stream measurements remain independent. Distinct kinds
never win by descriptor index, enum value or canonical tie-break.

Once first cause is claimed, the later termination signal/exit is finality
evidence and cannot compete with or rewrite it. A pidfd terminal event becomes
the fallback cause only when no earlier positive cause exists.

## 3. Terminal Fallback

Exact candidate wait status derives:

```text
exit 0       -> expected_exit
exit nonzero -> unexpected_exit
SIGXCPU      -> cpu_limit
SIGSYS       -> sandbox_policy_violation
other signal -> signal
```

A hard `SIGKILL` without an earlier exact cause is generic `signal`, never an
inferred CPU or wall limit. If pidfd and wall timer are both newly ready in one
epoch before any cause exists, their order is unknowable and the result is
infrastructure ambiguity.

## 4. Candidate Clock Boundary

The namespace controller owns one candidate clock:

```text
validate private READY;
read CLOCK_MONOTONIC;
arm one-shot timerfd at absolute start + declared wall limit;
send RELEASE;
record terminal/reap time after exact candidate wait4.
```

The measured wall interval begins immediately before RELEASE, after all setup.
It includes the bounded release handoff and ends at controller observation of
candidate terminality. The outer namespace watchdog remains infrastructure
time and can never become candidate `wall_timeout`.

## 5. Candidate Resource Boundary

Only `wait4(candidate_pid, ..., &rusage)` supplies candidate CPU and RSS.
`wait4(namespace_controller)` is cleanup evidence for the top supervisor and
must not enter candidate resources.

Linux `ru_maxrss` is converted from KiB to bytes with checked arithmetic. User,
system and wall time are projected as floor milliseconds from validated native
time fields. Invalid signs/ranges or overflow are infrastructure failures.

The v1 CPU limit uses:

```text
soft RLIMIT_CPU = declared whole-second CPU limit
hard RLIMIT_CPU = soft + one bounded emergency second
```

The current policy is exactly divisible into whole seconds. No rounding policy
is invented for other profiles.

## 6. Writers And Readers

| Fact | Writer | Reader |
|---|---|---|
| absolute wall deadline | namespace controller | timerfd/kernel + arbiter |
| readiness epoch | kernel poll result | controller arbiter |
| first cause | controller CAS | private controller report |
| candidate wait status/rusage | kernel wait4 | resource assembler |
| namespace wait status/rusage | top supervisor wait | cleanup assembler only |

No timestamp, pidfd, timerfd or raw wait structure reaches Lua or Packet.

## 7. Falsifiers

```text
descriptor array order selects a cause
two distinct cause kinds in one epoch produce a candidate result
later SIGKILL rewrites output/heap/wall first cause
pidfd + timer simultaneous readiness guesses wall or exit
namespace-controller rusage becomes candidate rusage
outer watchdog becomes candidate wall_timeout
timer arms after RELEASE
bare SIGKILL becomes cpu_limit
invalid/overflowing native time becomes zero or saturation
E4.3 changes RUN v0 or the 40/44 matrix
```

## 8. Next Action

Amend the existing hostile-execution TABLE/CRYSTALL first-cause and CPU/wall
sections with this law. Then implement a production-linked but unrouted
controller clock/arbiter module and exercise it with real clean, wall and CPU
children plus pure simultaneous-epoch falsifiers.
