# QA QN17 Hostile Candidate E7 Manifest

manifest status: implemented and promoted
date: 2026-07-28
authority: named 17-row hostile candidate containment corpus
execution path: production provider witness v1
body QA authority: absent

## 1. Manifested Campaign

QN17 now executes rather than skips. One parameterless trusted harness reads
the closed inert fixture corpus and sends only its 17 candidate rows through:

```text
fresh identity-owned root
-> first-hand tests/run.lua materialization
-> exact candidate seal
-> one source lease
-> production RUN v1
-> provider witness report v1
-> identity-owned cleanup
```

The bytes crossing the first hand are exactly the guarded fixture bytes. Their
size and SHA-256 match the sealed entrypoint. The harness never directly loads
them and has no selector, arbitrary path, command or alternate provider input.

## 2. Demonstrated Containment

The named corpus demonstrates:

```text
CPU spin                 stopped and classified by CPU-limit evidence
allocator exhaustion     stopped and classified by allocator denial
stdout/stderr floods      stopped by the independently named stream crossing
scratch exhaustion       bounded, completely observed, honest Lua failure
source mutation attempts source remains byte-identical and sealed
host/path probes          host surfaces remain absent
process/network/exec      APIs remain absent
native module loading     loader surface remains absent
descriptor escape         descriptor namespace remains absent
```

The fixture called `wall-loop` remains honestly classified as CPU spin under
closed stdin. The fixture called `sigsys` proves API closure and exits cleanly;
real seccomp SIGSYS evidence remains owned by QN13.

## 3. Exact Result

```text
candidate rows declared     17
candidate rows executed     17
candidate rows matched      17
source drifts                0
cleanup ambiguities          0
```

Every report has one runtime-confirmed cause, all eight finality facts, exact
seal/pre/post inventory identity, terminal consumed source disposition, v1
measurements and exactly one QA execution cost. No raw output, source bytes,
path, fd, repository handle or process token crosses the witness.

## 4. Promotion Ledger

The only authorized red-control transition is:

```text
QN17 red -> green
QA matrix 40 green / 44 red -> 41 green / 43 red
```

One attempted extra topology control temporarily produced `42/43`; it was
folded into the existing QF04 control rather than legitimized by changing the
matrix. QN17 is now mandatory in the ordinary native suite. QN18-QN20 remain
explicitly deferred.

## 5. Runtime Evidence

```text
qa-supervisor-hostile-fixtures-test  17/17, zero drift/ambiguity
ordinary native QA suite             17 green / 0 red / 3 skip
fixture topology and inert guard     green
production fault-selector audit      empty
post-run process/mount/root audit     empty
QA red control matrix                41 green / 43 red / 0 skip
full ordinary suite                  all tests ok
mortality battery                    8/8
```

## 6. Non-Claims

This manifest is bounded to the named Lua 5.4 corpus. It does not claim trusted
fault behavior, cleanup ambiguity handling, repeated residue freedom, body QA
evidence, verdict authority, universal correctness or safe arbitrary commands.

## 7. Next Boundary

E8/C9 QN18 must introduce test-only trusted faults without contaminating the
production binary, wire, environment or loader identity. A fault-test success
cannot become production authority.
