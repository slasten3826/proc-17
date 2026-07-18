# L1 Standalone Parity Results - 2026-07-18

Status:

```text
chaos / crystall-manifest observation
date: 2026-07-18
table: docs/01_table/yellowprints/l1_body_boundary_yellowprint.v0.md
crystall: docs/02_crystall/blueprints/l1_standalone.v0.md
manifest: l1/field.lua
P1 exact port: GREEN
P2 non-trivial bounded dynamics: PARTIALLY CONFIRMED
P3 causal value to proc-17: RED / NOT TESTED
Packet integration: none
```

## 1. What Was Manifested

One standalone Lua 5.4 module:

```text
l1/field.lua
```

Public operations:

```text
initialize
tick
snapshot
freeze
```

The module imports no Packet, operator, topology, budget, loss, substrate,
camera, pressure, or router module.

## 2. P1 Exact Museum Parity

Full fixture:

```text
source count = 7965
ticks = 15930
variant = C
interpreter = Lua 5.4.8
```

Observed from the new module:

| Tick | Position | Carry | Fingerprint | Density | Distinct core | Distinct L1 trace |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 2 | 29525 | 6887 | 7955 | 1168 | 794 |
| 7965 | 1 | 29861 | 0 | 7964 | 1642 | 4444 |
| 15930 | 1 | 338 | 29188 | 7964 | 2715 | 1140 |

Every value equals the museum stand oracle previously reproduced by Codex and
Fable independently.

Small full-trajectory fixture:

```text
source = {1,2,3,4,5,6,7,8}
ticks = 16
```

Fingerprint trajectory from tick 0 through 16:

```text
29523, 0, 29524, 1, 29525, 4, 29527, 8, 29521,
4, 29521, 3, 29521, 4, 29523, 4, 29520
```

All 17 values equal the independently executed museum law. Matching only the
final state is not used as evidence.

P1 verdict:

```text
GREEN
```

## 3. Lifecycle And Boundaries

Confirmed:

```text
same source/config is deterministic
snapshot does not mutate state
one tick changes no non-visited ring position
position and tick counters advance exactly once
freeze is idempotent
frozen state rejects mutation and remains observable
non-C variants, floats, missing provenance, short and over-bound sources reject
full source sequence is not retained after initialization
```

No Packet identity loss, budget, trace event, or route was created.

## 4. Pre-registered V7/V8 Result

Matched sources:

```text
S1 = {1,2,3,4,5,6,7,8}
S2 = {1,2,3,4,5,6,7,9}
ticks = 0..16
```

Only the pre-registered metrics were read:

| System | Distinct outputs | Repeated outputs | First S1/S2 divergence tick |
|---|---:|---:|---:|
| L1(C) | 11 | 6 | 7 |
| Static hash | 1 | 16 | 0 |
| Seeded PRNG | 17 | 0 | 0 |

The result rejects one easy overclaim:

```text
L1 is not "better" because it produces more different numbers.
```

The seeded PRNG produced more distinct outputs over this run.

The actual distinguishing observation is temporal locality:

```text
S1 and S2 differ only at the last ring position
global hash/PRNG folding sees the difference at tick 0
L1 fingerprints remain equal until tick 7
the difference appears when the positional process reaches its local domain
```

This is evidence of position-dependent propagation rather than generic input
hashing. It is not evidence that the propagation helps coding or routing.

## 5. Registered L1 Checkpoints

For S1:

| Tick | Fingerprint | Density | Distinct core | Distinct L1 trace | Position | Carry |
|---:|---:|---:|---:|---:|---:|---:|
| 0 | 29523 | 8 | 8 | 4 | 1 | 1 |
| 1 | 0 | 8 | 8 | 4 | 2 | 29523 |
| 8 | 29521 | 7 | 7 | 7 | 1 | 3 |
| 16 | 29520 | 8 | 5 | 5 | 1 | 4 |

The small field becomes less distinct in `core` over 16 ticks, while the full
7965-cell fixture grows from 1168 distinct core values at tick 1 to 2715 at
tick 15930. Non-collapse and richness are scale/run dependent; one fixture
must not be generalized into a universal law.

## 6. P2 And P3 Verdicts

P2:

```text
determinism                    confirmed
temporal variation             confirmed
bounded snapshots              confirmed
position-dependent propagation confirmed on one matched pair
advantage over generic PRNG     not confirmed
general non-collapse law        not confirmed
```

Therefore:

```text
P2 = PARTIALLY CONFIRMED
```

P3:

```text
no named proc-17 reader
no shadow body tick
no pressure contribution
no route ablation
```

Therefore:

```text
P3 = RED / NOT TESTED
```

## 7. Regression Result

Command:

```text
lua tests/run.lua
```

Result:

```text
all tests ok
tree-authority gate: 10/10 green
tree-instrumentation gate: 7/7 green
manifest-honesty gate: 4/4 green
```

The new L1 test runs inside the ordinary suite and exact museum parity adds no
observable effect to existing proc-17 lives.

## 8. Next Pressure

Do not integrate L1 into Packet merely because P1 is green.

The next decision must choose one of:

```text
more standalone matched sources/ring sizes to test the P2 boundary
or
one named bounded reader and a shadow-only P3 experiment
```

Either path requires its own table/crystall amendment. Current production
body, pressure, and promotion remain unchanged.
