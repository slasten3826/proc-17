# QA E10 / QN20 Campaign Implementation Evidence

Status:

```text
layer: CHAOS implementation evidence
date: 2026-07-29
chapter: 8.5.5E10.5
source:
  docs/01_table/yellowprints/qa_repeated_residue_campaign_yellowprint.v0.md
  docs/02_crystall/blueprints/qa_repeated_residue_campaign.v0.md
implemented slices: C10.4, C10.5, C10.6, C10.7
QN20 promotion: runtime-confirmed
production semantic widening: none
Packet/body QA authority: absent
```

## 1. Boundary Closed

QN20 now runs 32 fresh production QA transactions inside one long-lived Lua
process. Repository and QA providers are built before process birth, loaded
once, and probed once. Their module identities, callable identities, provider
tables and environment digest are frozen before the observer baseline.

The fixed schedule is eight repetitions of four outcomes:

```text
A clean accepted
B ordinary Lua rejection
C stdout output-limit termination
D allocator memory-limit termination
```

Each row owns a fresh Packet/body, lineage, source, repository root and QA
transaction. No row reloads a provider or invokes Make. Every sealed source is
consumed once, exact replay is denied before another provider launch, and both
body/support and observer weak sets must become empty at their named GC
boundaries.

## 2. Joined Observation

The campaign joins existing production facts with a test-only host observer:

```text
production RUN/provider witness
  -> candidate outcome and process finality
  -> source consumed and exact replay denied

test-only residue observer
  -> pre-transaction baseline
  -> post-transaction process/namespace/mount/fd delta
  -> post-cleanup root/source delta
  -> final campaign delta

fixture guard
  -> exact root absence
  -> external sentinel identity and continuity

Lua weak ownership checks
  -> body/support release
  -> observer snapshot release
```

No observation is trusted because it appears only in the final summary. Each
iteration checks its own post-transaction and post-cleanup phases before the
next transaction starts.

## 3. Exact Runtime Result

The promoted campaign emitted:

```text
proc17 QN20 residue campaign ok: declared=32 executed=32 matched=32 accepted=8 ordinary_rejected=8 output_terminated=8 memory_terminated=8 replay_denials=32 replay_launches=0 fd=0 process=0 namespace=0 mount=0 root=0 source=0 memory_finality=0 lua=0 sentinel=0 body=0
```

This means only the named and bounded channels are zero. It is not a claim that
the host has no unrelated activity or that arbitrary future providers are
residue-free.

## 4. Defects Found By The Campaign

### 4.1 Sticky source state was hidden by a consumed handle

The first exact replay probe expected
`repository_qa_source_already_reserved`, but the capability reader first saw
the deliberately removed private handle and returned
`sealed repository root lacks private QA source`.

The authority state itself was correct: the source was consumed and could not
launch again. The reader order was wrong. `reserve_qa_source` now reports the
sticky `reserved/consumed` state before consulting the handle required only by
an available source. Focused source-bridge tests confirm that no authority was
reopened.

### 4.2 Long-lived host workers broke the observer parser

The standalone QN20 campaign passed, but the exact combined expected-red
battery later encountered a kernel worker whose process name exceeded the
observer's provisional 31-byte field. `/proc/<pid>/stat` also raced with
process exit. The observer rejected its own host snapshot.

The treatment was not to ignore the process. The test ABI now carries a bounded
128-byte name, retries the stat read three times, and falls back to the bounded
`Name/State/PPid` fields in `/proc/<pid>/status` when the stat record disappears
during observation. The same combined battery that found the defect is green.

This is useful evidence in its own right: one-load QN20 proved transaction
residue, while the longer combined epoch falsified an observer assumption that
the isolated campaign did not reach.

## 5. Verification Evidence

```text
make -C native fixture-test
  fixture guard green

make -C native qa-supervisor-leak-loop-test
  QN20 exact 32/32 campaign green

lua tests/test_qa_provider_witness.lua
  5/5, including provider/callable/module drift falsifiers

lua tests/test_qa_native_supervisor.lua
  ordinary native QA: 20 green / 0 red / 0 deferred

lua tests/red_qa_hand.lua
  expected nonzero
  exact control matrix: 44 green / 40 red / 0 skip

GCC -fanalyzer
  changed observer and fixture boundary clean

ASan + UBSan
  fixture guard self-test green
  LeakSan was not claimed in this exact run

lua tests/run.lua
  107 suites, all tests ok

lua tests/smoke_mortality_battery.lua
  8/8

production artifact/runtime exclusion
  no QN20 campaign marker or observer symbol in production libraries/runtime

post-run host sweep
  no owned QN20 roots, sentinels or supervisor processes remain

git diff --check
  green
```

## 6. Promotion Delta

Only QN20 changed color:

```text
ordinary native QA  19/0/1 -> 20/0/0
expected-red matrix 43/41  -> 44/40
QN01-QN19           unchanged green
QE/QV/body controls unchanged red
```

The test-only observer remains physically absent from production binaries and
runtime modules. It writes no Packet event and owns no capability to reap,
unmount, delete, accept or reject candidate software.

## 7. Named Writers And Readers

| Record | Writer | Reader | Truth status |
|---|---|---|---|
| fixed 32-row expectation | TABLE schedule | campaign comparator | document_decision |
| provider/environment identity | one-load campaign opener | pre-row and post-row drift guard | runtime_confirmed |
| provider transaction result | production QA provider witness | joined iteration verifier | runtime_confirmed |
| host residue snapshots | test-only native observer | baseline-directed comparator | runtime_confirmed |
| root/sentinel identity | fixed fixture guard | phase and finality verifier | runtime_confirmed |
| body/observer release | Lua weak ownership sets | GC boundary verifier | runtime_confirmed |
| promotion matrix | ordinary and expected-red harnesses | promotion record | runtime_confirmed |

No written QN20 record lacks a named reader.

## 8. Non-Claims And Next Boundary

QN20 closes repeated private-provider containment. It does not create the body
QA hand. Packet-owned QA request, receipt, check evidence, verdict, economics,
completion and software acceptance remain red.

The next chapter must therefore begin at that body boundary, not by widening
the native supervisor again. Its first slice must select one expected-red body
contract, give every new record one authority writer and one named reader, and
preserve the already promoted QN01-QN20 containment unchanged.

