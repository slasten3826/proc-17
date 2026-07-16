# Runtime Camera Treatment Results - 2026-07-16

Status:

```text
runtime-confirmed local experiment
camera body contract: CONFIRMED IN SHADOW
pressure treatment: PARTIALLY CONFIRMED
tree promotion: FORBIDDEN
hard rails: RETAINED
```

Source chain:

```text
runtime_camera_reconciliation_hypothesis_notes.md
pressure_ablation_diagnostic_results_2026-07-16.md
operator_tree_physics_yellowprint.v0.md Amendment A1
packet_body_physics_yellowprint.v0.md Amendment A1
operator_tree_physics.v0.md Amendment A1
packet_body_physics.v0.md Amendment A1
```

## 1. Manifested Treatment

The body now captures one immutable `runtime_frame` after the economics and
loss physics of every completed runner tick. Capture does not create another
operator tick, step charge, substrate call, or identity loss.

`☱ RUNTIME` is no longer treated as the camera shutter. It reads pending
frames, writes a bounded `runtime_reconciliation`, and advances a monotonic
`reconciled_through` watermark. Its own subsequent routine frame remains
telemetry and does not request another ☱.

The new shadow reader emits at most one binary
`runtime_reconciliation_debt`. It requires a significant, unintegrated frame.
Clock movement, an expected step charge, loss revision alone, CALM existence
alone, and `head_seq > reconciled_through` alone are not witnesses.

The old sampled policy remains available as `pressure_policy=sampled` only for
L0 control and archaeology. The default shadow treatment is
`pressure_policy=camera_reconciliation`. Live routing remains legacy.

## 2. Trace Prerequisite

`core/packet.lua` now recursively snapshots trace payloads. Caller mutation
after append cannot rewrite a stored event. Runtime frames and reconciliation
records therefore have immutable trace evidence instead of mutable aliases.

## 3. L0/L1 Comparison

Command:

```text
lua tests/smoke_runtime_camera_treatment.lua
```

Observed:

```text
mode   live_equal  steps  calls  loss   L0 lower/mismatch   L1 debt/lower/mismatch   final pending/significant
plan   true        8      3      0.500  6/5                 5/0/0                    1/0
build  true        9      3      0.500  6/5                 5/0/0                    2/0
```

Interpretation:

```text
the L0 duplicate source is reproduced by the control
L1 removes both sampled lower debt and duplicate runtime mismatch
L1 retains five bounded consequences requiring reconciliation
the final pending frames are routine telemetry, not debt
live routes are byte-for-byte equivalent at the transition level
steps, substrate calls, and identity loss are unchanged
```

## 4. Unit And Integration Evidence

Confirmed by `tests/test_runtime_camera.lua` and the full runner suite:

```text
routine budget-only frame creates no ☱ pressure
CALM change creates exactly one bounded reconciliation debt
successful reconciliation discharges that debt
watermark advances monotonically
unresolved refs survive in the immutable reconciliation record
camera capture adds no paid step
every completed runner tick produces exactly one frame
☱ own routine frame does not recreate debt
dead Packet rejects capture and reconciliation
trace and camera readers cannot mutate stored history
runtime_mismatch emits nothing without an independent comparator
```

Mortality remains unchanged: all eight mortality cases pass, including budget
death and identity-loss death.

A live DeepSeek plan smoke reached the lower camera twice:

```text
trace:              ☴☵☴☳☴☱☲☱
ticks/frames:       8/8
reconciled_through: 7
death:              budget_exhausted
```

Frame 8 is the final ☱ routine frame captured after reconciliation through
frame 7. It remains visible without recreating significant debt.

## 5. Partial Result And Open Pressure

The treatment grows a real ☱ witness after ☲ and ☶, but under binary weights
that witness may tie with another positive candidate. Canonical tie-break can
therefore select another neighbor. This is not repaired by inventing a larger
weight: the experiment proves support, not calibrated authority.

Still open:

```text
an independent CALM/runtime mismatch comparator
paired lower-rail cases with one justified recall and one justified bypass
semantic uncertainty carried from ☱ toward ☴
Packet-local normal completion and manifest pressure
☷ consumption of the exact rigidity witness that selected it
measured pressure normalization beyond binary.v0
```

## 6. Decision

```text
continuous runtime camera                         keep
runtime reconciliation and watermark             keep
runtime_reconciliation_debt in shadow             keep
sampled lower-eye policy as diagnostic control    keep
duplicate sampled runtime_mismatch in L1           removed
routine budget/loss as generic ☱ pressure          removed
hard lower rails                                   keep
tree authority promotion                           no
step 10                                            still blocked
```

The treatment fixes the false camera pressure without claiming that the full
Tree has learned how much each real consequence should weigh.
