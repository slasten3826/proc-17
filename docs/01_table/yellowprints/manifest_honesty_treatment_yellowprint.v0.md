# Manifest Honesty Treatment Yellowprint v0

Status:

```text
table
from docs/00_chaos/tree_manifest_rejection_laundering_notes.md
     docs/00_chaos/tree_manifest_honesty_red_gate_results_2026-07-17.md
scope: transition step 4.2
implemented and confirmed: 2026-07-17
```

## 1. Observed Boundary

```text
validation.status                  rejected
runtime reconciliation            blocked
tree route                        ☱ -> △
manifest residue                  rejection preserved
manifest output                   text, no outcome
terminal cause                    complete
```

The route to MANIFEST is not itself the defect. A blocked life may terminate
through △ if △ reports the blockage honestly.

## 2. Treatment Options

| Option | Primary output | Terminal/corpse | Decision |
|---|---|---|---|
| Keep rejection only in residue | clean | `complete` | rejected: current laundering |
| Return to OBSERVE | no manifest | no terminal | rejected for 4.2: restores legacy policy instead of fixing MANIFEST |
| Mark output only | `blocked` | `complete` | rejected: grave and terminal still lie |
| Mark terminal only | clean | `blocked` | rejected: machine/human output still lies |
| Dual classification | `blocked` | `blocked` | selected |

## 3. Selected Witnesses

MANIFEST reads two Packet-owned witnesses:

| Witness | Source | Truth |
|---|---|---|
| latest validation verdict | `boundary.validations` / validation trace | runtime-confirmed |
| latest runtime completion state | `runtime_reconciliation` trace | runtime-confirmed |

In v0, either `rejected_count > 0` or `completion_state == blocked` is enough to
classify the boundary outcome as `blocked`. This redundancy prevents one missing
projection from laundering the other.

Other runtime completion states do not override MANIFEST in v0. In particular,
`incomplete` is not promoted to a terminal cause because the current runtime
progress model does not yet describe every legitimate manifest witness. Only
the already-proven negative witness is treated here.

## 4. Outward Projection

For a blocked life, one canonical outcome is projected to:

```text
manifest.output.status       blocked
manifest.summary.status      blocked
manifest.assembly.outcome    blocked
manifest.terminal_cause      blocked
terminal.cause               blocked
death.cause                  blocked
residue.cause                blocked
```

The substrate text is preserved unchanged. It remains semantic content; the
body-owned status describes whether that content passed runtime validation.

For an unblocked manifest, the same fields use `complete`.

## 5. Boundary Semantics

```text
stop_reason = manifested    means the Packet reached and executed △
terminal.cause = blocked    means the manifested work did not pass validation
```

These statements are compatible. Delivery completed; requested work did not.

## 6. Core Invariants

```text
manifest terminal cause must be a registered Packet death cause
manifest residue cause must equal terminal cause
cause mismatch fails before manifest trace or Packet finality mutation
blocked output never changes substrate text
legacy observation remains read-only
tree route remains unchanged
```

## 7. Acceptance

```text
the 4.1 grown-life gate becomes fully green
the gate is renamed from pending and registered in tests/run.lua
normal accepted manifestation remains complete
blocked terminal, death and residue agree
main suites and mortality remain green
```

Treatment result:

```text
manifest honesty gate: 4/4 green
normal accepted control: complete
main suites: 45 green
mortality: 8/8 green
route delta: none
```
