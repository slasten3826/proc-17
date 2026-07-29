# QA E10 / QN20 Red Observer Contract Checkpoint

Status:

```text
layer: CHAOS evidence/checkpoint
date: 2026-07-29
chapter: 8.5.5E10.3
source:
  docs/02_crystall/blueprints/qa_repeated_residue_campaign.v0.md
scope: red-first observer and harness contracts only
observer implementation: absent by design
production semantic change: none
Packet/body QA authority: forbidden
truth status:
  contract shape: document_decision
  syntax and test observations: runtime_confirmed
```

## 1. What Changed

The old QN20 frontier failed because Make had no
`qa-supervisor-leak-loop-test` rule. That failure named no physical property and
could not constrain an implementation.

E10.3 replaces that empty boundary with executable red contracts:

```text
native/tests/proc17_qa_residue_observer.h
native/tests/test_proc17_qa_residue_observer.c
tests/test_qa_repeated_residue_observer.lua
make -C native qa-residue-observer-contract-syntax
make -C native qa-residue-observer-test
make -C native qa-supervisor-leak-loop-test
```

There is still no observer module. The red state is intentional and now names
the missing organ exactly.

## 2. Frozen Native Boundary

The test-only C ABI is fixed as `qa.residue_observer.c.v0`. It exposes opaque
session, subject and snapshot owners plus read-only capture and comparison. It
also exposes three test-only hooks needed to falsify parser and observer-order
claims. No function can kill, reap, unmount, close foreign descriptors or
remove roots.

The native harness owns 15 deliberate defects:

```text
RO01 clean exact baseline/final
RO02 equal-count fd identity exchange
RO03 direct live child
RO04 direct zombie without observer reap
RO05 retained namespace fd
RO06 private /qa mount
RO07 extra owned-root grammar entry
RO08 parent namespace identity change
RO09 truncated proc and mount records
RO10 repeated equal snapshots
RO11 arbitrary root bind
RO12 observer scan-fd closure
RO13 exact production supervisor process
RO14 unreadable fixed-comm supervisor zombie
RO15 observer-owned descriptor before final fd scan
```

The harness dynamically loads the fixed test-only module and fixed ABI symbol.
It does not link an observer implementation into itself or any production
artifact. Test teardown occurs only after residue has been asserted.

## 3. Frozen Lua Boundary

The Lua harness requires exactly this closed API:

```text
protocol_version = qa.residue_observer.lua54.v0
open
bind_owned_root
capture
compare
```

Seven controls require:

```text
RL01 exact closed API and protocol
RL02 opaque locked session/snapshot and baseline projection
RL03 no caller configuration and no arbitrary-root authority
RL04 closed scope order
RL05 one verified subject across iteration and post-cleanup phases
RL06 session-bound and direction-bound comparison
RL07 detached scalar-only final evidence
```

The harness also names the required fixture phase API before implementation:
`identity`, `absent` and `with_root_phases`. It does not add those operations in
this slice.

## 4. Make And Control Wiring

QN20 now has a dedicated probe instead of sharing the generic QN16-QN18 hostile
target loop. The Make dependency chain is staged:

```text
syntax contract
  -> native observer falsifiers + Lua API contract
  -> future repeated-residue campaign
```

At E10.3 the second node fails because
`native/tests/proc17_qa_residue_observer.so` is absent. Once E10.4 supplies and
passes the observer, the same target advances to the still-absent 32-run
campaign. A later missing organ cannot be hidden by an earlier missing rule.

Generated observer artifacts are excluded from Git and owned by
`make -C native clean`.

## 5. Runtime Evidence

Observed on 2026-07-29:

```text
make -C native qa-residue-observer-contract-syntax
  exit 0

make -C native qa-residue-observer-test
  expected exit nonzero
  native: green=0 red=15
  Lua:    green=0 red=7
  common cause: observer module absent

lua tests/test_qa_native_supervisor.lua
  green=19 red=0 skip=1
  QN20 remains explicitly deferred

lua tests/red_qa_hand.lua
  expected exit nonzero
  control matrix: green=43 red=41 skip=0
  QN20 is the one native red control

lua tests/run.lua
  107 suites, all tests ok

lua tests/smoke_mortality_battery.lua
  8/8

GCC -fanalyzer on the native harness
  found and repaired a test-helper close-ownership defect
  final pass clean after excluding intentional execveat fd transfer warnings

production binary observer marker scan
  no observer protocol or symbol in supervisor, launcher or first hand
```

The red frontier did not change color or count. It gained a precise reader and
22 concrete falsifiers.

## 6. Non-Claims

E10.3 does not claim that:

```text
host residue is observable yet;
the observer is implemented;
fixture phases exist;
one clean transaction passes;
the 32-transaction campaign exists;
QN20 is promotable;
production code contains any observer surface.
```

## 7. Next Step

E10.4 implements the test-only observer and memory-finality join against these
fixed red contracts. The contracts may be corrected if execution finds a false
assumption, but they may not be weakened merely to make the observer green.
