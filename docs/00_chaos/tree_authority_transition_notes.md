# Tree Authority Transition Notes

Status:

```text
chaos
decision: legacy authority ends; full-tree authority is the target
implementation: not started
date: 2026-07-17
```

Sources:

```text
docs/00_chaos/fable_tree_authority_handoff_2026-07-16.md
docs/00_chaos/fable_tree_authority_review_2026-07-16.md
docs/00_chaos/body_event_and_physics_failure_boundary_notes.md
docs/00_chaos/lifting_of_the_emergency_myth_notes.md
```

## Decision

The old router dies as live authority.

It is not deleted. It remains an explicit control policy and, after the
instrumentation flip, an append-only shadow answer to the question:

```text
where would the emergency rails have sent this Packet?
```

The full-tree router becomes the only candidate for future default authority.
Promotion is staged. The decision to promote is final; the claim that the
current tree policy is already correct is not.

## What Is Being Lifted

The following transitions are emergency scaffolding, not ProcessLang law:

```text
☵ -> ☴
☳ -> ☴
☲ -> ☱
☶ -> ☱
```

They remain active only in explicit legacy/control lives. A tree-authority
life receives no mandatory eye rail. Eyes must be recreated by measured
pressure and readiness or be bypassed when their view is unnecessary.

This is an explicit ontological decision, not an accidental consequence of a
code refactor.

## Why The Transition Starts Now

Runtime camera treatment made ☱ conditional:

```text
routine telemetry -> no generic runtime pressure
significant unreconciled frame -> runtime_reconciliation_debt
```

The live legacy router still treats its selected target as unconditionally
executable. It can commit ☱ after a historical `last_choice` even when ☱
readiness says `nothing_to_reconcile`.

The resulting `☱:nothing_to_reconcile` harness abort is not a defect in the
camera. It is evidence that conditional organs and an unconditional
dispatcher can no longer coexist safely.

## New Route Lifecycle

```text
state
  -> pressure derivation
  -> canonical neighbor candidates
  -> lifecycle/capability/readiness/affordability filtering
  -> selected candidate
  -> committed route
  -> attempted operator execution
  -> applied effect OR typed effect failure OR invariant failure
  -> camera/economics/mortality
  -> next derivation OR terminal
```

The following distinctions become law:

```text
proposal != committed
committed != executed
commit carries its evidence
expected world failure != broken body physics
```

## Three Failure Boundaries

### Candidate not ready

The candidate is excluded inside one derivation. It receives no route commit,
tick, budget charge or identity loss.

### Expected effect failure

An already committed organ encounters a typed external failure. The attempt
is recorded and paid, but it receives no false executed evidence. The first
promotion implementation may terminate the Packet with exact residue instead
of inventing an unmeasured retry policy.

### Physics/invariant failure

Lua or trusted body code violates its own contract. The harness fails loudly.
No runtime-confirmed death, grave, karma or lineage is fabricated from an
invalid run.

## Terminal Pressure Before Promotion

The current tree policy cannot reproduce normal build manifest. Legacy uses:

```text
logic_stamp_no_new_evidence
```

Tree pressure currently sees manifest only when work reaches zero or economics
approach exhaustion. Before authority is enabled, the existing current
`runtime.logic_stamp.evidence_fingerprint` must become a Packet-visible
manifest witness when another validation pass cannot add evidence.

This witness is temporary but honest for the current handless body. A true
repair-to-manifest life waits for Pipeline A, where proc-17 can change an
artifact and grow new evidence.

Manifest material itself must be read from Packet records. `options.result`
may remain a compatibility carrier during migration, but it cannot decide △
readiness once tree authority becomes default.

## No Viable Edge

A closed single-threaded body cannot wait for itself to change:

```text
same state -> same derivation -> same no_viable_edge
```

Therefore v0 has no free hold or retry.

```text
no_viable_edge -> internal death cause stalled
residue.stall_kind -> exact cause
residue.candidate_audit -> all excluded candidates and reasons
```

Exact causes such as `missing_capability`, `unsafe`, `below_threshold` and
`stalled` must survive. They are not flattened into one vague message.

## Entry Is Also A Route

`▽ -> start_operator` is currently committed by the runner as
`reason=runner_entry`. That is hidden harness authority over the first road.

After FLOW has materialized ingress, the first same-life edge must be derived
through the same tree candidate protocol as every later edge. `start_operator`
may remain only as an explicit test/control override and cannot be the normal
tree-authority birth law.

## Evidence Ownership

The route result currently carries more evidence than immutable Packet trace.
`packet.commit_transition` drops `source_snapshot_ref`, candidates and selected
readiness information.

Tree authority is blocked until each committed route preserves at minimum:

```text
derivation_ref
pressure_snapshot_ref
selected candidate and readiness witness
policy and threshold
from / to / reason
```

The harness may copy this evidence. It may not be its sole owner.

## Promotion Sequence

```text
1. laws + red promotion gate
2. explicit router_mode=tree authority, default unchanged
3. live tree + legacy shadow instrumentation
4. tree-life evidence corpus
5. tree becomes default; legacy remains explicit control
```

Each step is separately testable and separately committable.

## What Is Not Fixed Before The First Tree Lives

These are calibration pressures, not correctness blockers for opt-in tree
authority:

```text
relation_debt attracts ☰ too often
upper_observation_debt remains insufficiently conditional
binary weights are vibed control values
canonical tie-break dominates equal pressures
the four old eye rails are not reproduced
```

The point of opt-in authority is to grow evidence about them. They block the
final default flip if the body cannot work, but they do not justify preserving
legacy live authority.

## Non-Negotiable Invariants

```text
tree never commits a candidate with readiness.ready=false
candidate rejection is free
attempted external effect failure is typed and paid once
invariant failure remains a loud harness failure
every committed edge references its derivation evidence
every executed edge has a successful receiving tick
same-life Packet never returns to ▽ or leaves △
death and manifest freeze the Packet
shadow cannot change live state/economics/route
normal build has at least one Packet-visible route to △
```

## First Evidence Gate

Before production code changes, grow a separate red test battery for:

```text
tree mode authority is unavailable today
normal build cannot manifest under tree today
rejected validation aborts through legacy today
typed substrate failure aborts through harness today
route commit discards derivation evidence today
entry is assigned by runner today
internal Lua failure still escapes loudly today and must keep doing so
```

The battery stays outside `tests/run.lua` while red. Main green tests remain
the legacy/control baseline. The promotion battery joins the main suite only
after its contracts become true.
