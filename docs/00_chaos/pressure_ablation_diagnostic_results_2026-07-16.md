# Pressure Ablation Diagnostic Results - 2026-07-16

Status:

```text
chaos / runtime experiment result
diagnosis: PARTIALLY CONFIRMED
camera treatment: NOT TESTED
tree authority: NOT PROMOTED
mandatory rails: UNCHANGED
```

Sources:

```text
docs/00_chaos/fable_cold_shadow_audit_raw_2026-07-16.md
docs/00_chaos/pressure_witness_repair_notes.md
docs/00_chaos/runtime_camera_reconciliation_hypothesis_notes.md
runtime/pressure_ablation.lua
tests/test_pressure_ablation.lua
tests/smoke_pressure_ablation.lua
```

Commands:

```sh
lua tests/run.lua
lua tests/smoke_pressure_ablation.lua
```

Observed baseline:

```text
40/40 Lua suites pass
pressure ablation smoke passes
fake substrate only
same plan/build control lives as edge evidence corpus
16 total shadow decisions
no live route, budget, loss, or substrate-call mutation by ablation
```

## 1. Profiles

```text
C0  current pressure.binary.v0 contributions
A   remove runtime_mismatch
B   remove budget/loss components from lower_observation_debt;
    remove debt only when no other changed component remains
AB  combine A and B
```

All counterfactuals are recalculated from the same recorded C0 candidate sets.
Readiness, exclusions, Packet state, and authoritative legacy movement are
identical across profiles.

## 2. Per-tick Result

```text
mode  tick  from  live(reason)                         C0  A   B   AB  lower_delta
plan  1     ☴     ☵  missing_calm                      ☰   ☰  ☰   ☰   missing
plan  2     ☵     ☴  mandatory_eye_tick                ☱   ☰  ☱   ☰   missing
plan  3     ☴     ☳  calm_alternatives                 ☱   ☰  ☱   ☰   missing
plan  4     ☳     ☴  mandatory_eye_tick                ☱   ☵  ☱   ☵   missing
plan  5     ☴     ☱  choice_observed                   ☱   ☰  ☱   ☰   missing
plan  6     ☱     ☲  remaining_work                    ☵   ☵  ☵   ☵   -
plan  7     ☲     ☱  mandatory_eye_tick                ☱   ☵  ☵   ☵   budget
plan  8     ☱     ☲  remaining_work                    ☵   ☵  ☵   ☵   -

build 1     ☴     ☵  missing_calm                      ☰   ☰  ☰   ☰   missing
build 2     ☵     ☴  mandatory_eye_tick                ☱   ☰  ☱   ☰   missing
build 3     ☴     ☳  calm_alternatives                 ☱   ☰  ☱   ☰   missing
build 4     ☳     ☴  mandatory_eye_tick                ☱   ☵  ☱   ☵   missing
build 5     ☴     ☱  choice_observed                   ☱   ☰  ☱   ☰   missing
build 6     ☱     ☶  missing_build_evidence            ☵   ☵  ☵   ☵   -
build 7     ☶     ☱  mandatory_eye_tick                ☱   ☲  ☱   ☲   budget,constraints
build 8     ☱     △  logic_stamp_no_new_evidence       ☵   ☵  ☵   ☵   -
```

## 3. Aggregate Result

| Profile | Agreement | Divergence | No edge | Removed contributions | E05 | E12 | E15 |
|---|---:|---:|---:|---:|---:|---:|---:|
| C0 | 4 | 12 | 0 | 0 | 2 | 6 | 2 |
| A | 0 | 16 | 0 | 10 | 6 | 4 | 0 |
| B | 3 | 13 | 0 | 2 | 2 | 6 | 2 |
| AB | 0 | 16 | 0 | 12 | 6 | 4 | 0 |

Directional detail:

| Profile | `☴->☰` | `☵->☱` | `☱->☵` | `☳->☱` | `☱->△` |
|---|---:|---:|---:|---:|---:|
| C0 | 2 | 2 | 4 | 2 | 0 |
| A | 6 | 0 | 4 | 0 | 0 |
| B | 2 | 2 | 4 | 2 | 0 |
| AB | 6 | 0 | 4 | 0 | 0 |

Lower rail detail:

| Profile | `☲->☱` recall | `☶->☱` recall |
|---|---:|---:|
| C0 | 1/1 | 1/1 |
| A | 0/1 | 0/1 |
| B | 0/1 | 1/1 |
| AB | 0/1 | 0/1 |

Every profile observed one normal legacy manifest case. Every profile predicted
`☵`, not `△`.

## 4. D1 Is Confirmed

`runtime_mismatch` is not an independent mismatch witness.

Removing it:

```text
removes 10 contributions
changes all legacy/shadow agreements from 4 to 0
removes every ☵ -> ☱ prediction
removes every ☳ -> ☱ prediction
removes both apparent lower-rail recalls
```

Therefore the current `runtime_mismatch` reader must not survive as implemented.
It needs a real comparator or must emit nothing.

## 5. The Strong D2 Forecast Is Partially Rejected

The cold-audit forecast expected budget/loss exclusion to collapse most lower
pressure. It removed only two contributions:

```text
plan ☲ tick: lower delta = budget
build ☶ tick: lower delta = budget + constraints
```

In the second case the contribution survived because `constraints` remained.

Ten of twelve lower-eye contributions were not stale budget views. They were:

```text
missing lower observation before the first explicit ☱ tick
```

This is more direct evidence for the machinist's camera interpretation:

```text
the current body treats lower sight as switched off
until the Packet explicitly visits ☱
```

However, this does not yet prove that every pre-☱ change is irrelevant. ENCODE,
CHOOSE, and LOGIC may create consequences that genuinely require runtime
reconciliation. A continuous camera removes `missing sight`; it does not remove
the need to classify unintegrated effects.

## 6. E05, E12, And E15 Need Directional Reading

### E05

E05 did not disappear. It increased from 2 to 6 after D1 ablation.

Interpretation:

```text
removing dominant ☱ pressure exposes ☰ as canonical winner among tied scores
```

This confirms E05 as tie-break-sensitive, not as a grown physical relation
witness. The exact cold-audit prediction "E05 disappears" is rejected.

### E12

Aggregate E12 remained, but direction changed in meaning:

```text
☵ -> ☱  2 -> 0 after D1 ablation
☱ -> ☵  remains 4 through encoding_debt
```

The forward E12 evidence was a duplicate-mismatch artifact. The reverse E12
pressure is independent and survives this diagnosis.

### E15

E15 fell from 2 to 0. Its only selected direction in this corpus was
`☳ -> ☱`, entirely dependent on the duplicate mismatch.

## 7. Lower Rails Are Not Symmetric Cases

`☲ -> ☱` was supported only by budget staleness plus duplicate mismatch. It
disappeared under either A or B.

`☶ -> ☱` retained lower debt under B because LOGIC changed constraints. It
still lost the route under A because continuation toward ☲ tied or outweighed
the single remaining lower contribution.

Consequences:

```text
CYCLE lower rail currently has no independent physical witness in this corpus
LOGIC lower rail has a plausible constraints/reconciliation witness,
but binary scoring is insufficient to make it authoritative
```

Both rails remain live scaffolding.

## 8. Normal Manifest Gap Is Confirmed

At the live transition:

```text
☱ -> △ because logic_stamp_no_new_evidence
```

all four shadow profiles predict:

```text
☱ -> ☵
```

The gap is independent of D1 and routine lower freshness. Tree authority remains
blocked until completion and manifestable material are Packet-local pressure.

## 9. What The Experiment Did Not Prove

It did not prove:

```text
that no varying pressure signals exist
that all lower observation debt is noise
that camera + reconciliation is already correct
that either lower rail can be removed
that E05 or reverse E12 are physically valid
that binary.v0 can or cannot survive after witness repair
```

No profile produced `no_viable_edge`; other signals remain active. Their
physical quality requires separate witnesses and semantic-effect tests.

## 10. Decision

```text
remove or replace current runtime_mismatch implementation          yes
exclude routine budget delta as generic lower-eye pressure        supported
replace sampled lower sight with camera/reconciliation experiment proceed in shadow
remove lower rails                                                  no
promote tree router                                                 no
tune weights                                                        no
```

Next treatment experiment:

```text
L0 current sampled lower-eye debt
L1 continuous runtime frames + significant reconciliation debt
```

Before L1 evidence is accepted, trace payload immutability must be repaired.
