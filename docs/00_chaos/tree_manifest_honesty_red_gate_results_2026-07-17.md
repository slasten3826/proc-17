# Tree Manifest Honesty Red Gate Results - 2026-07-17

Status:

```text
chaos / runtime evidence
transition step: 4.1
production treatment: none
manifest honesty gate: RED as expected
main suite registration: intentionally absent
```

## Command

```sh
lua tests/pending_tree_manifest_honesty_gate.lua
```

Baseline around the pending gate:

```text
pending gate syntax: green
main Lua suites: 44 green
mortality: 8/8 green
pending honesty gate: 3 green / 1 red
```

## Grown Life

The fixture is not a synthetic manifest table. A real tree-authority Packet
runs a file-existence spell against a missing sandbox path and grows:

```text
validation.status: rejected
reconciliation.completion_state: blocked
tree route at ☱: △
legacy observation at ☱: ☴ validation_rejected_semantic_repair
manifest.output.type: text
terminal.cause: complete
```

## Green Witnesses

### Rejection and blocked runtime are confirmed

LOGIC records a real rejected validation and the runtime camera independently
classifies completion as `blocked`.

### Legacy dissent is visible

The deposed router observes the exact disputed edge without changing it:

```text
live tree:     ☱ -> △
legacy shadow: ☱ -> ☴
reason: validation_rejected_semantic_repair
```

This is the first defect exposed by Gate B instrumentation in its intended
operating role.

### Rejection reaches internal residue

`organs/manifest.lua` reads the validation and `logic/manifest.lua` preserves:

```text
manifest.residue.validation.rejected_count = 1
manifest.residue.validation.rejection_reasons = non-empty
```

The writer exists and the datum reaches MANIFEST. The defect is not missing
transport into the organ.

## Red Witness

### blocked_runtime_is_outwardly_classified

The primary outward contract contains no `blocked` or `rejected` outcome in:

```text
manifest.output
manifest.summary
manifest.assembly
terminal.cause
```

Observed failure:

```text
blocked runtime was laundered into clean manifest: output=text terminal=complete
```

Residue alone is not sufficient outward classification. A machine CLI, TUI, or
caller reading the primary result sees the rejected life as an ordinary clean
completion.

## Treatment Freedom

The red gate does not prescribe one terminal design. It accepts either:

```text
terminal cause explicitly blocked/rejected
or
primary manifest output/summary/assembly explicitly blocked/rejected
```

It does not require discarding the substrate text, retrying through OBSERVE, or
choosing a specific output type. Those are step 4.2 design decisions.

## Boundary

This test remains outside `tests/run.lua` until green. Registering it while red
would break the stable body without treating the defect. Weakening it to accept
hidden residue would merely rename the laundering.

## Later Treatment

Step 4.2 made this historical gate green without changing its boundary claim.
The treatment and verification are preserved in
`tree_manifest_honesty_treatment_results_2026-07-17.md`. This document remains
the pre-treatment RED baseline.
