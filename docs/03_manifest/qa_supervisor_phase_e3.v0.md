# QA Supervisor Phase E3 Manifest

manifest status: implemented, production-linked, unrouted safety slice
date: 2026-07-28
authority: native supervisor-private phase state
execution protocol: production RUN v0
body QA authority: absent

## 1. Implemented Surface

`E3` adds the C4 phase mechanism to the production supervisor binary:

```text
private identity join              transaction/witness/profile/environment
private candidate token           getrandom entropy bound to the identity join
STARTED emission                  one bounded RUN_STARTED_V1 pipe write
candidate release                 denied until STARTED write and descriptor close
first-cause record                first valid cause wins; later causes cannot rewrite it
finality state                    eight monotonic facts; no clearing transition
candidate-result readiness        denied until start, release, cause and all finality facts
```

The STARTED writer owns its result descriptor. Every validation, encoding,
write or close failure consumes that descriptor and leaves candidate release
unauthorized. A second STARTED attempt is rejected and cannot create another
frame.

The eight finality members are:

```text
source staging complete
candidate started
candidate terminal observed
whole candidate tree reaped
stdout EOF observed
stderr EOF observed
scratch observation complete
namespace cleanup complete
```

## 2. Production Boundary

`native/proc17_qa_phase.c` is compiled into the exact static production
supervisor. This rotates the supervisor digest and the launcher's expected
supervisor identity. It is not a detached mock implementation.

The live launcher still sends `RUN v0`, and the current supervisor `RUN v0`
path does not call this module. Therefore E3 proves the phase mechanism and
its linkage, not production RUN v1 execution. Routing it early would mix C4
with the still-unimplemented C5 measurements and make failures unauditable.

No fault selector, test command, raw process token or STARTED table was added
to the production Lua ABI.

## 3. Runtime Evidence

```text
native phase test                        green under -Werror
STARTED exact-frame/identity join        green
full-pipe STARTED failure                candidate release denied
duplicate STARTED                       rejected; new descriptor consumed
first-cause overwrite attempt            original record unchanged
missing/invalid finality                candidate result suppressed
ASan/UBSan phase run                     green (leak scan unavailable under ptrace)
native supervisor integration            16 green / 0 red / 4 skip
QA control matrix                        40 green / 44 red / 0 skip
```

The exact QA color delta remains zero.

## 4. Non-Claims

`E3` does not claim dual-stream draining, allocator observation, scratch
measurement, production RUN v1 routing, hostile-candidate coverage, cleanup
residue freedom, source disposition or body-owned QA verdicts.

## 5. Next Authorized Slice

`E4` implements C5 stream, allocator and scratch witnesses without promoting
the launcher. `E5` may route the fault-free RUN v1 path only after those
measurements and this phase mechanism can be joined end to end.
