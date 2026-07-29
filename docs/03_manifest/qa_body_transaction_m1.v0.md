# QA Body Transaction M1 Manifest v0

Status:

```text
layer: manifest
date: 2026-07-29
slice: M0 exact falsifiers + M1 shared physical engine
body authority: closed
router/pressure authority: unchanged
QA control matrix: 44 green / 40 red / 0 skip
```

## 1. Manifested Change

The proven provider-witness transaction no longer owns a private copy of the
candidate physics. One shared engine now executes:

```text
bounded pre-inventory
exact seal comparison
one measured-environment RUN
bounded post-inventory
terminal source disposition
```

Implementation:

```text
runtime/qa_candidate_transaction.lua
runtime/repository_capability.lua
runtime/qa_environment.lua
runtime/qa_provider_witness.lua
```

The repository inventory provider travels with the sealed source handle. A
caller-supplied `host_services.repository_provider` cannot select the provider
used by the transaction. The QA provider travels with the measured environment
lease. Neither private provider object may escape its callback.

## 2. Preserved Public Physics

The provider-witness adapter retains its existing public protocols, physical
ids, error classification, source dispositions and Packet/public-root
ablation. The extraction added no Packet event, budget debit, verdict, route,
pressure or mortality behavior.

Runtime-confirmed campaigns after extraction:

```text
QN17 declared=17 executed=17 matched=17
     source_drifts=0 cleanup_ambiguities=0

QN18 declared=9 executed=9 matched=9
     candidate_outcomes=0 source_quarantines=2

QN19 declared=6 executed=6 matched=6
     candidate_outcomes=0 source_quarantines=6 replays=0

QN20 declared=32 executed=32 matched=32
     replay_launches=0
     fd/process/namespace/mount/root/source/memory/lua/sentinel/body residue=0
```

Full verification:

```text
lua tests/run.lua                         111 suite markers, all tests ok
lua tests/smoke_mortality_battery.lua     8/8
git diff --check                          clean
```

## 3. Falsifier Repair

The generic QE/QV placeholder loops were removed. Every post-QN20 red control
now names a concrete grown state and a forbidden result. Controls that need a
future runner, terminal life or lineage fixture fail on that exact missing
producer rather than on a shared unconditional error.

Current expected-red arithmetic remains:

```text
fixture guard       5 green
contract           14 green / 1 red
execution           5 green / 15 red
native             20 green
verdict              0 green / 24 red
total              44 green / 40 red / 0 skip
```

## 4. Closed Boundary

M1 does not put QA inside the Packet. The following remain absent by law:

```text
runtime/qa_execution.lua
runtime/qa_evidence.lua
runtime/qa_verdict.lua
QA request/check/failure/verdict body writers
runner-owned QA cost debit
terminal and descendant QA retention
```

The next authorized slice is M2: private grant/begin/source/result/receipt,
strict receipt-to-body join, and one runner-owned external-cost debit. M2 may
change only the colors enumerated in the reconciliation crystall; M1 itself
was required to change none.
