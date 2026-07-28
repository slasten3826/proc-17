# QA QN18 Trusted Fault E8 Manifest

manifest status: implemented and promoted
date: 2026-07-28
authority: named nine-row trusted-runtime fault campaign
execution path: production state machines plus distinct test-only closure
body QA authority: absent

## 1. Manifested Campaign

QN18 now executes rather than skips. One parameterless campaign validates all
nine inert trusted-fault records and joins observations from their named
owners:

```text
production Lua loader
production launcher identity verifier
production supervisor request decoder
production launcher v1 collector
production provider-witness source transaction
```

The test selector is a closed native enum. It never enters candidate bytes,
wire frames, environment, production Lua or a public provider API.

## 2. Exact Result

```text
trusted rows declared       9
trusted rows executed       9
trusted rows matched        9
candidate outcomes          0
source quarantines          2
production exclusions       6
```

Both malformed-frame rows execute seven variants. Crash-before and crash-after
retain distinct STARTED evidence. Result-channel loss and reap ambiguity retain
different codes and unknown finality where the host fact was not observed.

## 3. Distinct Test Closure

The fault launcher and supervisor are separately compiled under
`PROC17_QA_FAULT_TESTING`, carry non-production identities and live only under
`native/tests/`. Production artifacts contain no fault symbol, selector,
fixture id or fault-test identity. Production rejects both fault artifacts at
its normal identity boundaries.

The test closure reuses the production wire and collector state machines; it
does not add a production fault command.

## 4. Source Law

Malformed trusted terminal bytes are loud invariant failures, but source
finality happens first. The provider transaction quarantines a contradictory
source and denies replay. Independent postflight drift also quarantines and
returns typed `source_drift`. Neither path creates a candidate witness.

## 5. Promotion Ledger

The only authorized matrix change is:

```text
QN18 red -> green
QA matrix 41 green / 43 red -> 42 green / 42 red
```

QN18 is mandatory in the ordinary native QA suite. QN19/QN20 remain the only
native deferred controls; body QE/QV controls remain expected red.

## 6. Runtime Evidence

```text
qa-supervisor-trusted-fault-test   9/9, zero candidate outcomes
ordinary native QA suite           18 green / 0 red / 2 deferred
production static closure          green
production artifact/API audit      six exclusions green
ASan/UBSan native driver           seven exact rows green
GCC -fanalyzer collector           green
post-run process/root audit        empty
QA red control matrix              42 green / 42 red / 0 skip
full ordinary suite                all tests ok
mortality battery                  8/8
```

## 7. Non-Claims

This manifest does not claim QN19 ambiguity-lattice completeness, QN20 repeated
residue freedom, body-owned QA evidence/verdict, software acceptance, generic
commands, retry/resume or universal leak freedom.

## 8. Next Boundary

E9/QN19 must exercise the wider cleanup and source-disposition ambiguity
lattice without weakening the typed distinctions or production exclusion
proved here. QN20 remains a separate repeated-run campaign after that.
