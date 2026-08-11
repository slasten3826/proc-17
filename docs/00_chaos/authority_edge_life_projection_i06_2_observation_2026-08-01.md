# Authority Edge Life Projection I06.2 Observation

```text
layer: CHAOS
date: 2026-08-01
status: runtime_observation
source blueprint:
  docs/02_crystall/blueprints/authority_epoch_edge_credit.v0.md
slice: I06.2 edge-life-projection.v0
source baseline commit: 1d3433a
implementation commit: pending
runner v3 integration: absent
promotion decision: forbidden
```

## 0. Result

`runtime/edge_life_projection.lua` now produces a bounded immutable post-life
record with two views:

```text
exact:
  raw whitelisted body/result/corpse components

observer-neutral:
  exact named observer refs removed
  closed host wall-time paths normalized
  derived raw corpse hash excluded
  every other value retained
```

The projector computes the Packet digest before and after observation. A
successful capture proves that the measurement itself did not mutate the body.

## 1. Falsification Found During The Slice

The first synthetic named-ref control passed. The first independently grown
observer pair failed across six physical component groups even after the
observer event was removed.

Root cause:

```text
one process-global event counter
observer consumes one event id
all later body refs shift
witness ids and action ids embed shifted refs
one observer event causes a whole-life identity cascade
```

The finding and disposition are preserved in:

```text
docs/00_chaos/authority_observer_reference_cascade_i06_notes_2026-08-01.md
TABLE Amendment A6
CRYSTALL section 12.3 amendment
```

The writer was repaired instead of teaching the comparator to rewrite
arbitrary strings:

```text
body ids:      event-<Packet-local ordinal>
observer ids: observer-event-<Packet-local observer ordinal>
```

Both ordinals derive from the append-only trace. No second mutable counter was
created.

## 2. Captured Components

The projection owns a closed component map:

```text
identity and work contract
operator/status/walk
committed routes
budget and loss
substrate/tool-call state
CHAOS/CALM/field/revisions/effects
repository coordinates/results
QA coordinates/results
manifest/death/residue/terminal
full Packet trace
verified corpse when present
```

The `substrate` compatibility alias is not copied twice; capture rejects if it
diverges from `physis`. Unknown Packet or physical runner surfaces fail loudly.
Known observer and edge-ledger result fields are absent by construction.

## 3. Plain-Data And Bounds Law

Capture rejects:

```text
cycles
metatables
functions
userdata
threads
nested live Packets
unknown root surfaces
invalid or mismatched corpse
absent/ambiguous/wrong observer refs
projection larger than max_projection_bytes
```

Returned records are deep detached. Mutating or discarding Packet, runner
result and corpse after capture cannot alter verification or comparison.

## 4. Runtime-Confirmed Pair Evidence

Two independently grown pairs are green:

```text
Tree authority:
  legacy observer disabled versus enabled
  one named observer decision removed
  body event id sequence exact
  corpse included

Legacy authority:
  router_mode legacy versus shadow
  Tree pressure snapshot + Tree observer decision removed
  both modes project live_authority=legacy_control
  corpse included
```

Both pairs are raw-red and observer-neutral-green. An unnamed event with the
same payload kind remains comparison-significant. A changed `metadata.time`
also remains red, proving that host-time normalization is path-closed rather
than a generic key filter.

## 5. Verification

```text
targeted LP01-LP12: green
Packet/router/corpse/trace regression: green
full suite: 120/120 green
mortality battery: 8/8 green
luac: green
git diff --check: green
```

No route, budget, loss, revision, repository or QA authority changed. The only
body-level repair is trace identity ownership required to remove pre-existing
observer address mass.

## 6. Remaining I06

```text
I06.3 edge_case_manifest:
  body-owned closed registry of 14 L0 and 4 L1 obligations

I06.4 edge_corpus:
  same-epoch buckets, immutable life projections, observer pairs and closure

I06.5:
  complete regression and slice observation
```

The projector is now usable as an instrument input. It does not yet decide
which corpus claims are required or whether any authority surface is complete.
