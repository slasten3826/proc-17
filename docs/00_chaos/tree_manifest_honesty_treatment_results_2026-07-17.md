# Tree Manifest Honesty Treatment Results - 2026-07-17

Status:

```text
chaos / runtime evidence
transition step: 4.2
manifest honesty gate: GREEN
production treatment: active
main suite registration: active
```

## Before

The grown rejected life already contained every internal witness:

```text
validation                         rejected
runtime completion                blocked
legacy observer                   ☱ -> ☴ semantic repair
manifest residue                  rejection present
primary output                    text, unclassified
terminal/death                    complete
```

Step 4.1 measured `3 green / 1 red` and made no production change.

## Treatment

MANIFEST now reads the latest Packet-owned `runtime_reconciliation` event as a
named source alongside the latest validation. Deterministic assembly derives
one outcome:

```text
blocked runtime or rejected validation -> blocked
otherwise                               -> complete
```

That outcome is projected through the primary output, summary, assembly,
terminal payload, Packet terminal, death, and corpse residue. The substrate
text is retained unchanged.

`core/packet.lua` now recognizes `blocked` as a death cause and rejects a
manifest whose explicit residue cause contradicts its terminal cause. This
check happens before manifest or terminal state is written.

## Grown Rejected Life

```text
manifest.output.type               text
manifest.output.text               fake substrate response
manifest.output.status             blocked
manifest.summary.status            blocked
manifest.assembly.outcome          blocked
manifest.terminal_cause            blocked
terminal.cause                     blocked
death.cause                        blocked
residue.cause                      blocked
result.stop_reason                 manifested
```

`manifested` means △ successfully delivered the result. `blocked` means the
delivered work did not pass runtime validation. No route was rewritten and no
legacy repair loop regained authority.

## Accepted Control

A real accepted tree build remains:

```text
manifest.output.status             complete
terminal.cause                     complete
```

This separates failure honesty from a blanket reclassification of all
manifestation.

## Gate Reader Defect

The first treatment run still reported the final case as red even though
`output.status=blocked` existed. The gate helper built a sparse Lua array whose
first value (`output.outcome`) was nil and traversed it with `ipairs`; Lua
stopped before reading `output.status`.

The reader was corrected to inspect each named projection explicitly. The gate
was not weakened. It now requires agreement across output, summary, assembly,
terminal, death, and corpse residue.

## Verification

```text
manifest honesty gate              4/4 green
tree authority gate                10/10 green
tree instrumentation gate          7/7 green
main Lua suites                    45 green
mortality battery                  8/8 green
runtime camera treatment           green
pressure ablation                  green
all Lua syntax                     green
```

The former pending gate is now
`tests/test_tree_manifest_honesty.lua` and is registered in `tests/run.lua`.

## Remaining Boundary

This treatment classifies rejection; it does not decide whether a future life
should retry, repair, inherit it as a bequest, or avoid it as a warning. Those
are grave, lineage, and routing policies outside step 4.2.

