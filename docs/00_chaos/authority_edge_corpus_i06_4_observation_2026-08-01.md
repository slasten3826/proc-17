# Authority Edge Corpus I06.4 Observation

```text
layer: CHAOS
date: 2026-08-01
status: runtime_observation
source blueprint:
  docs/02_crystall/blueprints/authority_epoch_edge_credit.v0.md
slice: I06.4 edge-evidence-corpus.v1
source baseline commit: 1d3433a
implementation commit: pending
runner v3 integration: absent
promotion decision: forbidden
```

## 0. Result

`runtime/edge_corpus.lua` now assembles finished instrument records without
acquiring any Packet or routing authority:

```text
verified one-life edge-stats.v3 -> exact evidence-epoch bucket
verified life projection       -> immutable post-life body record
implementation provenance      -> separate revision/truth coordinate
two completed lives            -> observer-ablation pair
closed case evaluator          -> retained L0 evidence
live-provider document         -> retained L1 evidence
selected bucket                -> closure report
```

Every mutating API is a deep-copy transaction. Failed projection, provenance,
merge, pair, harness, case or bound verification leaves the corpus digest
unchanged. Evidence is never evicted, merged across epochs or rewritten from a
red record into a green record.

## 1. Corpus Laws Exercised

The implementation verifies and retains:

```text
one unique non-empty evidence_run_id per life
one matching immutable life projection
one separate implementation-provenance record
same-epoch edge-stats merge only
different evidence epochs as separate buckets
bounded lives, pairs, cases, documents and harness records
unit/archaeology evidence as visible but promotion-ineligible
physical route refs separately from corpus-eligible route refs
```

Closure always uses the 38-direction authority surface. A diagnostic corpus
cannot become complete even when every count is present. A full-tree corpus
also requires a valid document-owned target decision, a green observer pair,
all 14 L0 and four L1 cases, clean common provenance and one eligible execution
for every direction. The report proves evidence closure only; it cannot set
runtime authority.

## 2. Observer Pair Boundary

Pair comparison has two independent channels:

```text
body channel:
  edge_life_projection.same_observer_neutral

ledger channel:
  life-local route ordinal, edge, direction, phase, authority,
  eligibility and final credit after local-ref normalization
```

Body or ledger deltas produce retained red evidence. A physics-epoch delta also
produces red and names `physics_epoch_id`; it is a failed ablation, not a
malformed record. Packet/session/lineage/generation/work identity mismatch,
invalid observer roles, changed instrument bounds or malformed projection
reject the transaction because they do not form a comparable pair.

## 3. Falsification Found During Assembly

The first I06.3 fixture gave both observer lives the target
`evidence_epoch_id`. That was impossible in a real observer ablation because
observer configuration enters evidence identity.

The repaired law is recorded in TABLE Amendment A7 and CRYSTALL section 13.3:

```text
primary and ordinary control lives -> target evidence epoch
observer control life              -> its own evidence epoch
all pair lives                     -> target physics epoch and revision
each cited pair                    -> contains the target evidence epoch
P12 target                         -> unique epoch common to all family pairs
```

The transient case view now carries both target physics and evidence ids. The
old same-evidence synthetic fixture is no longer capable of proving the real
pair law.

## 4. Case History

The corpus preserves contradictory and retry history:

```text
L0 green + later red     -> red dominates; no cherry-pick
L1 blocked + later green -> green may satisfy; blocked record remains visible
missing case             -> no fabricated missing record
failed P13 harness       -> separate bounded harness evidence, no synthetic life
```

The corpus added the missing named writer
`add_harness_evidence`. P13's evaluator is its reader. L1 document insertion
derives its target only from matching L1 lives under one implementation
revision and one evidence epoch.

## 5. Runtime Controls

The ordinary deterministic battery covers:

```text
CO01-CO05 same/unlike buckets and provenance gates
CO06 retained red physics delta
CO07 physical-only visibility
CO08 exact eligible route filtering
CO09 diagnostic cannot complete
CO10 reused evidence run is atomic rejection
CO11 tampered projection is atomic rejection
CO12 retained red body delta
CO13 bounded rejection without eviction
CO14 missing full-tree decision blocks
CO15 equal body plus ledger delta is red
CA10 missing case blocks a direction-complete campaign
CA11 L0 red dominates green
CA12 L1 blocked retry remains visible beside green
EM04 observer epochs pair but never raw-merge
EM09 implementation revision remains a closure coordinate
```

The expensive exact-surface control is separately runnable:

```sh
PROC17_EDGE_CORPUS_CAMPAIGN=1 lua tests/test_edge_corpus.lua
```

It grows 38 credited directions through public edge-credit and edge-stats
transactions, then proves that the missing case campaign still prevents
closure. It is deliberately not repeated inside every ordinary suite run.

## 6. Verification

```text
targeted corpus battery: green
38/38 corpus campaign: green
full suite: 122/122 green
mortality battery: 8/8 green
luac: green
git diff --check: green
```

The full-surface campaign is an offline proof workload and currently takes
minutes because every incremental route phase re-verifies the growing source
ledger. This cost is not Packet budget, substrate usage or routing latency. It
is retained as campaign evidence rather than hidden as ordinary runtime cost.

## 7. Next Boundary

`I06.5` is the final pure-instrument audit and regression observation. `I07`
then connects exactly one v3 instrument to `tension_runner` behind the rollout
switch. Until I07, no ordinary Packet life writes this corpus automatically.

The newly fixed P10 predicate is ready for the DISSOLVE experiment:

```text
one grown life
real credited direction through ☷
visible loss record produced by the same life
no document-authored green status
```

The instrument can therefore test the semantic-garbage-collection hypothesis
after runner integration without changing its case contract after seeing the
answer.
