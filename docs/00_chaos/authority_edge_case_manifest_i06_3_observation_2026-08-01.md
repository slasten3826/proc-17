# Authority Edge Case Manifest I06.3 Observation

```text
layer: CHAOS
date: 2026-08-01
status: runtime_observation
source blueprint:
  docs/02_crystall/blueprints/authority_epoch_edge_credit.v0.md
slice: I06.3 tree-authority-cases.v0
source baseline commit: 1d3433a
implementation commit: pending
runner v3 integration: absent
promotion decision: forbidden
```

## 0. Result

`runtime/edge_case_manifest.lua` now owns a closed, body-readable manifest of
the evidence campaign:

```text
14 L0 deterministic cases
4 L1 live-provider cases
fixed evaluator identities and versions
required control channels for every case
the complete 12-family observer-pair obligation for P12
the synthetic-harness prohibition for P13
```

The caller may supply evidence references, controls and grown life pairs. It
cannot supply a verdict, replace an evaluator or silently add a case.

## 1. Named Readers And Writers

The manifest is static body data. The case evaluator is its named reader and
the future edge corpus is the only promotion-facing writer of evaluated case
records.

The slice also closes two supporting record contracts:

```text
edge-harness-evidence.v0
  writer: deterministic corpus harness
  reader: P13 evaluator and corpus closure

edge-case-evidence.v0
  writer: this evaluator
  reader: corpus closure
```

L1 remains document evidence rather than a fabricated runtime fact. Its
verifier requires provider, model, artifact, prompt, usage, source and
independent verifier references.

## 2. Runtime Predicates

L0 evaluation verifies the referenced immutable life projections, target
evidence epoch and implementation revision before applying case semantics.
The predicates cover:

```text
clean completion and typed terminal outcomes
recovery generation identity
manifest honesty
accepted and rejected validation paths
tick-limit pending execution
CONNECT and DISSOLVE directions
real CHOOSE suppression with positive loss
all observer families
the synthetic-life negative harness
```

`P10` is deliberately strict: a DISSOLVE direction alone is insufficient and
a loss record alone is insufficient. Both must be visible in one grown life.
That makes the future DISSOLVE campaign measurable without changing this
manifest after seeing the result.

## 3. Boundary Controls

Evaluation rejects:

```text
unknown case or evaluator version
unit or archaeology evidence offered as L0
unresolved life, observer-pair or evidence references
epoch or implementation-revision mismatch
wrong control-reference kind
an incomplete P12 observer-family set
synthetic Packet or observer-pair evidence in P13
caller-authored status or truth status
```

The per-call projection cache is transient verification work keyed by the
immutable projection id. It is not retained as a second mutable source of
truth.

## 4. Verification

```text
targeted CA01-CA09: green
full suite: 121/121 green
mortality battery: 8/8 green
luac: green
git diff --check: green
```

The remaining blueprint controls are intentionally owned by the next slice:

```text
CA10: a red case dominates a green duplicate
CA11: an L1 green retry may satisfy closure while preserving blocked history
CA12: a failed P13 harness blocks closure
```

They require corpus history and therefore cannot be proved honestly inside the
stateless case evaluator.

## 5. Next Boundary

`I06.4` must now bind these obligations to grown lives:

```text
same-epoch edge-stats.v3 buckets
immutable exact and observer-neutral life projections
implementation provenance
observer pairs
case evidence and retained red history
diagnostic versus full-tree closure
```

Until that corpus exists, the manifest states what must be measured but grants
no authority and proves no full-tree claim.
