# QA QN20 Repeated Residue E10 Manifest

manifest status: implemented and promoted
date: 2026-07-29
authority: fixed one-load campaign plus read-only host observation
execution path: production repository and QA providers
body QA authority: absent

## 1. Manifested Boundary

QN20 executes 32 fresh QA transactions in one long-lived Lua process. Providers
are loaded and probed once. Every iteration receives fresh body, lineage,
source and repository identities, then proves its own transaction finality,
replay denial, host residue delta, root absence and ownership release before
the campaign advances.

## 2. Exact Result

```text
declared                 32
executed                 32
matched                  32
accepted                  8
ordinary rejected         8
output terminated         8
memory terminated         8
replay denials            32
replay launches            0
fd/process/namespace       0
mount/root/source          0
memory finality            0
Lua/sentinel/body          0
```

The zeroes apply only to the named channels and exact owned identities in the
QN20 contract.

## 3. One-Load Law

Make owns every build and exits before the campaign process starts. The Lua
campaign loads the production providers and test-only observer once, freezes
their identities, creates its external sentinel, and only then records the
baseline. Provider reload, callable replacement, module-table replacement or
environment drift is a typed campaign failure.

## 4. Per-Iteration Finality

Each row joins:

```text
production provider terminal witness
consumed source and exact replay denial
post-transaction host snapshot
fixture-guarded root cleanup
post-cleanup host snapshot
body/support and observer weak-set release
sentinel continuity
```

Final-only cleanliness cannot hide a transient leak between rows.

## 5. Production Separation

The residue observer and campaign vocabulary exist only in test artifacts. No
observer symbol or QN20 marker is linked into production libraries or loaded by
the body runtime. The observer cannot reap processes, close foreign
descriptors, unmount namespaces, delete roots or write Packet truth.

## 6. Defects Closed During Promotion

Execution found two real reader defects:

1. consumed QA source state was masked by the intentionally absent private
   handle; sticky state now wins before handle availability;
2. a long kernel-worker name and `/proc` exit race exceeded the observer's
   provisional process parser; the bounded ABI and status fallback now preserve
   exact observation without ignoring the process.

Both were reproduced before treatment and are covered by the promoted battery.

## 7. Promotion Ledger

```text
QN20 red/deferred -> green
ordinary native QA 19/0/1 -> 20/0/0
QA matrix          43/41  -> 44/40
```

QN01-QN19 did not change. The remaining 40 expected-red controls belong to the
future Packet/body QA hand.

## 8. Runtime Evidence

```text
QN20 campaign                         32/32 exact
ordinary native QA                   20 green / 0 red / 0 deferred
expected-red QA matrix               44 green / 40 red / 0 skip
provider identity/drift controls      5/5
full ordinary suite                  107 suites, all tests ok
mortality battery                     8/8
GCC -fanalyzer changed boundary       green
ASan/UBSan fixture guard              green
production symbol/runtime exclusion   green
post-run root/sentinel/process sweep  empty
git diff --check                      green
```

## 9. Non-Claims

This manifest does not prove universal host stillness, arbitrary-provider
cleanup, Packet-owned QA requests, check execution, verdicts, QA economics,
software acceptance, retry/resume or a general command hand.

## 10. Next Boundary

The private execution enclosure is complete through QN20. The next ordered
work is the first body-owned QA slice while preserving all QN01-QN20 gates.

