# Authority Measurement I06.5 Observation

```text
layer: CHAOS
date: 2026-08-01
status: runtime_observation
scope: final pure-instrument audit before runner integration
source baseline commit: 1d3433a
implementation commit: pending
default runner authority instrument: unchanged edge-stats.v2
promotion decision: forbidden
```

## 0. Slice Verdict

The pure authority instrument is internally complete:

```text
authority epoch identity
selection eligibility carry
route evidence chain
physical edge statistics
promotion predicates
atomic same-epoch merge
immutable post-life projection
observer-neutral comparison
closed L0/L1 case manifest
bucketed evidence corpus
closure report
```

None of these modules is currently called by the ordinary runner v2 path. The
slice therefore proves the instrument as a detached machine, not yet as a live
body organ.

## 1. Changed Runtime Modules

```text
runtime/edge_credit.lua
runtime/edge_stats_v3.lua
runtime/edge_life_projection.lua
runtime/edge_case_manifest.lua
runtime/edge_corpus.lua

supporting truth-carry repair:
  runtime/pressure_composition.lua
  runtime/router.lua
  core/packet.lua
```

The supporting repair gives body and observer trace events separate
Packet-local identity lanes. It does not change route ranking or organ effects.

## 2. New Protocol Records

```text
authority_epoch.v0
edge-stats.v3
edge-credit.v0
route-evidence.v0
edge-life-projection.v0
tree-authority-cases.v0
edge-case-evidence.v0
edge-harness-evidence.v0
edge-evidence-corpus.v1
authority-target-decision.v0
```

Every durable record has a named verifier and reader. No v2 record can be
restamped into v3, and no corpus record can mutate Packet truth.

## 3. Observed Epoch Identities

Canonical qualified Tree physics under the current implementation:

```text
physics:
  sha256:4f490b981531b8c8a1e1757df9851b435f9aef30c2b080e55402cec28a265b90

legacy observer enabled:
  sha256:1feaeaa15522f4c2e7fde6f4b72ba832ca459582401638f108e3d911405dfc92

legacy observer disabled:
  sha256:7af91634d1d298e95c767220370a89f97c0673b46158af7d3d437e9c2ffb19e1
```

The evidence ids differ while physics remains exact. Raw ledgers reject merge;
the corpus stores a verified pair across buckets.

## 4. Masslessness Evidence Available Before I07

The post-life projector hashes the Packet before and after capture and rejects
any mutation. Independently grown observer pairs prove:

```text
same neutral Packet/corpse projection
same normalized route phases and promotion outcomes
different only in verified observer refs/evidence identity
```

The ordinary runner still writes v2 only, so the stronger v3 off/on exact
Packet ablation belongs to I07/I08. No claim stronger than the current evidence
is made here.

## 5. Final Controls

```text
targeted edge-credit/statistics/projection/manifest/corpus suites: green
ordinary corpus hostile battery: green
full 38-direction corpus campaign: green
full suite: 122/122 green
mortality battery: 8/8 green
luac: green
git diff --check: green
```

The 38-direction campaign uses public route-evidence transactions. It observes:

```text
physical_direction_count = 38
eligible_direction_count = 38
l0_case_gate = missing
closure_status = partial
```

Thus ledger coverage cannot launder a missing experimental case. A missing or
forged target decision also blocks a full-tree claim. Diagnostic claims remain
diagnostic regardless of counts.

QA/repository authority was not touched by I06. Their complete ordinary and
hostile suites pass inside the full regression; no separate QA promotion claim
is created.

## 6. Falsifications Retained

```text
real observer lives cross evidence epochs
sparse Lua arrays cannot hide corpus records
malformed controls return typed rejection, not harness exception
observer plus changed bounds is not a valid ablation pair
physics delta is retained red
body delta is retained red
ledger-only delta is retained red
L0 red dominates an earlier green
L1 transient blocked history survives a later green
```

The full-surface campaign is intentionally an offline workload. Incremental
verification of all source bundles takes minutes; this is audit cost, not
Packet economics or substrate usage.

## 7. Known Red Boundaries

```text
I07 runner integration absent
I08 exact v3 off/on masslessness campaign absent
I09 canonical v3 cutover forbidden
I10 current evidence manifest absent
P10 has a predicate but no runner-grown DISSOLVE/loss corpus life yet
no authority_target_decision exists for product promotion
```

The next executable slice is I07: opt-in `authority_instrument="v3"` in
`tension_runner`, with omitted options retaining the unchanged v2 path. That
slice is also the first point where the DISSOLVE hypothesis can be measured on
ordinary grown lives rather than hand-fed pure records.
