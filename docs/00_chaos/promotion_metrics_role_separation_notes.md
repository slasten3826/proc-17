# Promotion Metrics Role Separation Notes

Status:

```text
chaos
transition step: 4.0
source: post-Gate-B cold audit
scope: measurement language only
route physics: unchanged
```

## Pressure

Gate B correctly separated authority from observation, but the first statistics
schema still uses names born when only one direction of observation existed.

Two ambiguities become dangerous as soon as the promotion corpus merges lives
from both epochs:

```text
shadow mode: tree observes legacy authority
tree mode:   legacy observes tree authority
```

Top-level `agreement_count` and `divergence_count` add both relationships into
one number. The sum is arithmetically valid and epistemically ambiguous: a
reader cannot tell which policy disagreed with which authority.

Rail counters have the same problem in a second dimension. Under shadow mode,
`debt_bypass_proposals` describes a tree prediction with no authority. Under
tree mode, the same field is updated from the selected tree route. The number
changes from proposal evidence to authority evidence while retaining its old
name.

## Runtime Witness

The ambiguity was found immediately after Gate B exposed the rejected manifest
life:

```text
validation: rejected
tree authority at ☱:   △
legacy observer at ☱:  ☴ validation_rejected_semantic_repair
terminal: complete
```

The observation is valuable only while its roles remain explicit. A merged
`divergence_count = 1` is not enough to say who objected or who moved.

## Hypothesis

Promotion evidence needs two independent axes:

```text
comparison axis: observer -> observed live authority
rail axis:       evidence role -> target selected or predicted
```

The body must never infer either axis from the current router mode after the
fact. Every counter bucket carries its own role metadata.

## Proposed Shape

Observer comparisons remain keyed by observer identity:

```text
observers.tree    tree prediction compared with legacy live authority
observers.legacy  legacy prediction compared with tree live authority
```

Rail evidence becomes channelled:

```text
channels.tree_shadow     counterfactual prediction, no authority
channels.tree_authority  authoritative tree derivation
```

Counter names inside a channel are neutral:

```text
target, eye target, debt-eye target, debt bypass, fresh direct, no target
```

Words such as `proposal`, `live`, and `recall` belong in channel metadata or
derived reports, not in one shared storage counter.

## Compatibility Decision

The repository has no persisted or public consumer of `edge-stats.v1`.
Therefore v2 should remove the ambiguous top-level comparison and flat rail
counters rather than preserve aliases that future code may accidentally read.
Historical documents keep the v1 names as archaeology.

Merging unlike protocol versions must fail loudly. Quiet migration would turn
old ambiguous evidence into new typed evidence without proof.

## Falsifiers

The treatment is wrong if:

```text
observer identity can still be omitted from a comparison bucket
one rail counter receives both shadow and authority evidence
merging shadow and tree lives loses either observer's counts
legacy observation changes tree-authority rail counts
route, economics, loss, revisions, or terminal state change
v1 and v2 statistics merge silently
```

This is not pressure calibration and not manifest treatment. It only makes the
next experiment capable of telling the truth.

## Treatment Result - 2026-07-17

Implemented as `edge-stats.v2`.

The permanent mixed-epoch test grows one shadow life and one tree-authority
life, then merges their ledgers. Runtime-confirmed result:

```text
tree observer comparisons remain under observers.tree
legacy observer comparisons remain under observers.legacy
tree shadow rail evidence remains under channels.tree_shadow
tree authority rail evidence remains under channels.tree_authority
ambiguous root agreement/divergence fields are absent
ambiguous flat rail proposal fields are absent
v1 -> v2 merge is rejected before target mutation
observer authority metadata mismatch is rejected
```

Verification:

```text
tests/test_edge_metric_roles.lua green
tests/test_tree_instrumentation.lua 7/7 green
tests/run.lua 44 suites green
mortality 8/8 green
camera and pressure ablation green
```

No route, pressure reader, budget, loss, revision, or terminal rule changed.
Step 4.0 is confirmed.
