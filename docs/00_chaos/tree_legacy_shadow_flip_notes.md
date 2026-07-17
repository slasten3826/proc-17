# Tree Live / Legacy Shadow Flip Notes

Status:

```text
chaos
transition step: 3 of 5
Gate B: not yet measured at document creation
default router mode remains shadow
```

## Pressure

Gate A proved that an explicitly selected tree life can move and manifest
without asking the legacy router for permission. It did not yet make the old
authority observable from the other side.

The third step reverses only instrumentation:

```text
before: legacy moves, tree observes
after:  tree moves, legacy observes
```

This is not the default-authority flip. `router_mode=shadow` remains the default
until Gate C. The new behavior exists only inside explicit `router_mode=tree`.

## Authority Law

For a tree life:

```text
tree derivation is computed first
tree decision is the only decision eligible for commit
legacy prediction is computed against the same post-tick Packet state
legacy target is never entered or executed
legacy prediction cannot create semantic state, revisions, budget or loss
```

The observer may append one bounded trace record and update the external run
report. Those are measurements, not body motion.

## Entry Is Part Of The Experiment

FLOW entry is a real tree derivation and must receive a legacy comparison too.
The historical legacy entry prediction is the old `runner_entry` target
(`☴` unless an explicit compatibility start operator is supplied).

The complete current build walk is:

```text
▽ -> ☴ -> ☰ -> ☵ -> ☲ -> ☶ -> ☱ -> △
```

`result.routes` excludes `entry_route`; tests and renderers must join them
explicitly instead of silently dropping `▽ -> ☴`.

## Observer Record

Proposed legacy observer payload:

```lua
{
  kind = "shadow_route_decision",
  observer = "legacy",
  live_authority = "tree",
  current_operator = glyph,
  predicted_to = glyph | nil,
  predicted_reason = string,
  live_to = glyph | nil,
  agreement = boolean,
  divergence = string | nil,
  instrumentation_status = "observed" | "unavailable",
  policy = "legacy.control.v0",
  truth_status = "runtime_confirmed",
}
```

Legacy has no rule for several full-tree sources such as CONNECT. This is not a
Packet stall and not a reason to fall back to legacy. It becomes
`instrumentation_status=unavailable` with the exact reason preserved.

A returned unsupported-source result is expected instrumentation absence. A Lua
exception or corrupt observer contract remains a harness/instrumentation defect;
it must not be converted into Packet death.

## Tree Evidence Reader

The current edge ledger records committed and executed tree routes but does not
yet read their candidate audit. Gate B requires a named reader for every live
tree derivation:

```text
all canonical candidates -> candidate_count and exclusions
selected tree target -> selection_count
committed route -> committed_count plus authority and derivation ref
applied destination -> executed_count
typed external failure -> failed_count, never executed_count
```

Legacy-shadow records contribute comparison counts only. They must not be
misread as tree candidates or temporary-eye evidence.

## Ablation Switch

Within explicit tree mode:

```lua
legacy_shadow = true   -- default for tree lives after Gate B
legacy_shadow = false  -- measurement control
```

The switch may alter only:

```text
trace length and legacy-shadow events
shadow_routes report
observer comparison statistics
```

It must not alter:

```text
entry route or live route sequence
executed operators and tick count
substrate/tool calls
budget and identity loss
Packet revisions
validation/evidence
manifest/death/terminal outcome
```

## Gate B Falsifiers

Gate B is red if any of these occurs:

```text
legacy prediction changes a tree target
legacy unsupported source aborts or kills the Packet
observer on/off changes economics, loss, revisions or terminal result
FLOW entry lacks a comparison
tree candidate audits remain unread by edge statistics
legacy comparison pollutes tree candidate or rail counts
```

Only after this ablation is green can tree lives become the promotion corpus of
step 4.

## Red Baseline - 2026-07-17

The independent pending gate started at:

```text
green = 3
red   = 3
```

Already green before implementation:

```text
the ignored observer switch cannot change tree physics
disabled observer has no records
legacy never commits a route in tree mode
```

Red for the intended missing readers:

```text
0 legacy observations for 7 tree derivations
no typed legacy absence at CONNECT
edge_stats.tree_derivation_count is absent
```

This isolates Gate B from Gate A: live tree authority already works. The missing
work is exactly reversed observation and evidence reading.

## Treatment Result - 2026-07-17

The independent gate became permanent as
`tests/test_tree_instrumentation.lua` and finished at:

```text
green = 7
red   = 0
```

The same explicit tree life was run with the legacy observer enabled and
disabled. Both lives produced:

```text
walk: ▽ -> ☴ -> ☰ -> ☵ -> ☲ -> ☶ -> ☱ -> △
ticks: 7
steps spent: 7
substrate calls: 1
identity loss: 0.500
terminal: manifested / complete
```

With the observer enabled, it added exactly seven append-only measurement
events: one for every tree derivation, including FLOW entry. It changed no
route, tick, budget field, loss, Packet revision, validation, evidence, or
terminal result. Observer data is absent from committed route payloads and is
reported separately.

Measured comparison:

```text
legacy observer ticks: 7
agreements:             2
divergences:            5
unavailable:            1 (legacy has no CONNECT source rule)
tree derivations read:  7
edge-stat errors:       0
```

Tree candidate audits now have a named reader in `runtime/edge_stats.lua`.
Legacy observations update only observer comparison counters; they cannot add
tree candidates, selected edges, committed edges, executed edges, or rail
evidence.

Gate B is confirmed. This does not change the default router mode and does not
claim that the current pressure witnesses are calibrated. Step 4 must grow the
promotion corpus and expose incorrect tree behavior without letting legacy
correct it.
