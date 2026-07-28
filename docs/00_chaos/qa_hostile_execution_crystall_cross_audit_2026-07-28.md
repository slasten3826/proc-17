# QA Hostile Execution CRYSTALL Cross-Audit

Status:

```text
layer: chaos (crystall audit evidence + document decision)
date: 2026-07-28
chapter: 8.5.5E
audited blueprint: qa_hostile_execution_campaign.v0.md
audit result: accepted after precision amendments
CRYSTALL gate: satisfied
implementation authorized: E1-E10 in exact order
Packet/body QA authority: forbidden
```

## 0. Audited Surface

```text
docs/00_chaos/second_qa_hand_hostile_campaign_notes_2026-07-28.md
docs/01_table/yellowprints/qa_hostile_execution_campaign_yellowprint.v0.md
docs/00_chaos/qa_hostile_execution_table_cross_audit_2026-07-28.md
docs/02_crystall/blueprints/qa_hostile_execution_campaign.v0.md
```

Implementability was checked against the current wire, policy, supervisor,
launcher, strict Lua adapters, provider-witness transaction, source registry,
hostile fixture guard and red-battery control catalog.

## 1. Audit Result

The blueprint can be implemented without inventing policy in code.

Its central boundary is coherent:

```text
positive pre-chunk STARTED attestation
  + first-cause witness
  + terminal/reap/EOF/scratch/namespace finality
  = candidate observation

missing proof
  = infrastructure error

contradictory trusted proof
  = source finality/quarantine attempt, then loud invariant failure
```

No path yields a body check or verdict.

## 2. Precision Amendment A: Start Attestation

The first crystall draft used a two-phase controller release. That left the
word `started` slightly stronger than its witness: STARTED could be emitted
before the final release reached the candidate process.

The blueprint was amended in place:

```text
trusted candidate prelude applies environment/limits/capability/seccomp;
prelude writes one complete RUN_STARTED_V1 directly to the launcher result
pipe;
prelude closes that private descriptor;
only then does it load candidate bytes.
```

The frame is bounded to Linux `PIPE_BUF` and written once. The terminal frame
is emitted later by the top-level supervisor after reap, so write order cannot
interleave. Candidate Lua never sees the descriptor.

This is implementable from the current nested candidate process in
`run_lua_task`; descriptor closure already occurs before restricted Lua and can
be reordered around one trusted write.

## 3. Precision Amendment B: Scratch Cause

The first table/crystall direction treated a final full tmpfs as a possible
scratch-limit cause witness. That is insufficient: post-terminal fullness does
not prove which failed write ended the candidate.

The accepted correction is conservative:

```text
Step E records bounded final scratch use and capacity state;
candidate-scratch-exhaustion remains unexpected_exit;
scratch_limit is not emitted;
a future trusted pre-terminal write-denial hook is required to promote it.
```

Hard scratch containment and cleanup are still tested. Only the causal label is
withheld.

## 4. CPU Cause Implementability

The existing policy has a declared CPU ceiling and the supervisor owns rlimit,
pidfd, timerfd and wait4. The blueprint refines enforcement:

```text
soft RLIMIT_CPU = declared CPU ceiling
hard RLIMIT_CPU = bounded one-second emergency margin
SIGXCPU before wall timer = exact CPU first cause
```

This creates a positive kernel witness. A bare SIGKILL cannot be called CPU
limit. The wall-loop fixture remains a CPU spin under closed stdin and is
expected to hit this same witness.

## 5. Memory Cause Implementability

The bounded Lua allocator already owns `used` and `ceiling`. Adding peak and
denied fields does not expose candidate authority. The ceiling becomes a fixed
measured environment field rather than a request knob.

The normalizer may emit memory limit only when the allocator's trusted denial
flag and Lua failure agree. A candidate-written error string cannot set it.

## 6. Output Implementability

The current supervisor already owns a nonblocking output drain, pidfd and
timerfd. C5 replaces the merged pipe with two instances and keeps only:

```text
count
bounded prefix digest
limit crossing
EOF
```

No raw retention is introduced. Continuing drain after kill is necessary and
possible because the trusted controller owns both read ends and waits for EOF
before candidate finality.

## 7. Scratch Implementability

The namespace controller owns `/qa/scratch` before pivoted candidate execution
ends. It can snapshot the trusted baseline, perform a no-follow final walk and
call `statvfs` before the namespace exits.

The baseline `home` and `tmp` directories are excluded from candidate delta.
Their mutation is infrastructure ambiguity. The walker is bounded by the same
entry/byte policy and cannot follow candidate links.

## 8. Launcher Phase Implementability

The current launcher already owns:

```text
opened supervisor identity
supervisor process lifecycle
result pipe
source callback
request nonce
```

It currently reads one terminal frame. C6 changes this into a small closed
phase machine over at most two frames while polling supervisor pidfd and result
EOF. No second process manager or mutable truth store is needed.

The phase record is local transaction state and dies after normalization. It is
not persisted beside the private repository registry.

## 9. Environment/Profile Join

The profile remains:

```text
qa.profile.lua54_test_suite.v0
```

because invocation authority does not change. The environment becomes v1 and
rotates identity because measured runtime policy changes. Existing QA contract
law already binds an exact environment id, so historical contracts become
unavailable without mutation.

No fallback to the v0 environment is authorized.

## 10. Provider/Source Join

The provider witness assembler already has the correct terminal ordering:

```text
process fact
-> post inventory
-> source disposition
-> report/error assembly
```

C7 revises private schemas but preserves ordering. Ambiguity quarantines the
source; malformed trusted state attempts quarantine/finality and then raises.

No private execution receipt is introduced, so body split-brain remains
impossible in Step E.

## 11. Hostile Harness Safety

QN17 fixtures become executable only through:

```text
guarded inert bytes
-> fresh identity-owned root with trusted parent initialization
-> first-hand create of tests/run.lua
-> exact candidate seal
-> one-use source lease
-> production provider/supervisor
```

The trusted harness may create the empty `candidate/tests` parent before the
first hand creates the file; this is existing D practice. The candidate seal
inventory binds the resulting exact tree. No fixture is loaded by the ordinary
Lua process.

## 12. Fault Harness Safety

QN18/QN19 need failures that candidate data cannot lawfully request. Separate
test binaries are therefore necessary and safe only under all three controls:

```text
compile-time test-only selector outside production wire/API
distinct binary/build identity
production loader rejection test
```

The tests exercise the same source files and state machines, but a green fault
test never upgrades the test binary into a production environment.

## 13. Residue Claim Audit

QN20 was narrowed to observable owned channels:

```text
launcher-owned pids/pidfds
provider/launcher descriptors
mount entries carrying unique harness identity
identity-owned temporary roots
source lease finality
host sentinels
Packet/root/economics ablation
```

It does not hash unrelated host mounts, globally reap children or claim zero
heap leak from RSS. Thirty-two alternating basic transactions are sufficient
to exercise repeated setup/teardown without repeating expensive CPU/resource
fixtures.

## 14. Authority Audit

Forbidden and absent from the blueprint:

```text
Packet-triggered provider call
qa_capability body grant
qa.execution_receipt.v0
qa_check / qa_execution_failure event
qa_verdict
completion/work-layer/manifest/corpse reader
router pressure
Packet/lineage budget charge
generic command or candidate-selected profile
```

Provider witness output remains private test evidence. Turning QN17-QN20 green
does not make software acceptance possible yet.

## 15. Control Audit

The 22 HE controls cover every new claim. Required color sequence:

```text
E1-E6: no red-control delta
E7:    QN17 only
E8:    QN18 only
E9:    QN19 only
E10:   QN20 only
```

Final expected red battery:

```text
44 green / 40 red / 0 skip
```

The red battery still exits nonzero because the body execution/verdict modules
remain absent. A zero exit would be a false promotion.

## 16. Implementation Stop Conditions

Stop the current slice immediately if:

```text
ordinary or mortality regression appears;
QN01-QN16 changes color;
an unauthorized QE/QV control changes color;
a production fault selector appears;
source disposition cannot be proven;
candidate cause requires message/filename inference;
hostile fixture executes outside supervisor;
Packet/public root/economics ablation changes;
the implementation needs policy not named by TABLE/CRYSTALL.
```

Return to CHAOS/TABLE rather than inventing the missing rule in C.

## 17. Authorized Implementation Order

```text
E1 wire v1 and Lua schemas
E2 environment identity rotation and old-environment denial
E3 pre-chunk STARTED and first-cause/finality state
E4 dual streams, allocator witness and scratch observation
E5 launcher phase machine and exact fault-free v1 run
E6 provider witness v1/source disposition migration
E7 QN17 hostile candidate corpus
E8 QN18 trusted fault corpus
E9 QN19 cleanup ambiguity corpus
E10 QN20 repeated residue corpus and matrix audit
```

The implementation may split one step further for testing but may not reorder
authority dependencies.

## 18. Decision

Implementation amendment 2026-07-28:

E1 found that the original C2 API exposed a raw STARTED record to Lua while
the same contract prohibited its private process token from crossing the
native boundary. The stronger native-privacy law wins: STARTED is validated
inside the C launcher and Lua normalizes only the sanitized terminal v1 table.
The correction is recorded in
`qa_started_native_visibility_amendment_2026-07-28.md`; E1 remains authorized.

The same E1 review found that supervisor ERROR wire bytes cannot own the later
launcher reap/EOF facts. Those fields now exist only in the sanitized Lua
terminal record assembled by the launcher. The wire owns namespace cleanup;
the launcher owns reap and EOF.

```text
document_decision:
  qa_hostile_execution_campaign.v0 is accepted after the two precision
  amendments;

  E1-E10 implementation is authorized in exact order;

  authorization is limited to private provider physics and QN17-QN20;

  Packet QA request/check/verdict/completion/tree authority remains forbidden.
```
