# Logic Stamp Yellowprint v0

Status:

```text
table
author: claude (Mythos/Fable)
from docs/00_chaos/logic_stamp_notes.md
frame confirmed by machinist 2026-07-15
```

## Goal

One court visit per evidence state.

☶ stamps its verdict with a fingerprint of the evidence it judged.
The router refuses to route back to ☶ while the fingerprint is
unchanged. New evidence stales the stamp and reopens the court.

## Core Rules

1. **The stamp is a record with a referent.**

```text
logic_stamp = {
  verdict            (validation status logic ruled)
  evidence_fingerprint (hash of the evidence state judged)
  stamped_at_tick
}
```

2. **Fingerprint = deterministic hash of the evidence list**
   (count + per-item intention_hash : cast_tick : success).
   Zero evidence is a valid referent: «judged with nothing».

3. **Logic stamps on every build-mode validation** —
   no_spell, rejected, and accepted alike.

4. **The router is the stamp's named reader.**
   In `route_runtime`, the `missing_build_evidence` rule becomes:

```text
stamp exists AND fingerprint unchanged
    -> △, "logic_stamp_no_new_evidence"
otherwise
    -> ☶, "missing_build_evidence"
```

5. **Expiry is by referent change only.** No time decay on the
   stamp itself: judging is not a perishable fact about a file,
   it is a memoized verdict keyed by what was judged. (The
   evidence items INSIDE keep their own truth-rent clocks.)

6. **Freshness module owns the fingerprint** — same home as the
   other referent readers; logic writes through it, router reads
   through it.

## Loop Budget Consequence

The measured 8-tick ☱☶ loop collapses to:

```text
☱ -> ☶ (court, stamp) -> ☱ -> △ (manifest with honest verdict)
```

The packet delivers what it has; validation status rides in the
manifest residue. No more starving at a full table.

## Non-Goals

```text
eternal spells (rejected as trojan — see chaos note)
absolute re-entry ban (stamp must expire on new evidence)
hands / body-side spell minting (separate pipeline)
stamping plan-mode placeholder validations with routing effect
  (plan mode has no ☱→☶ evidence pressure)
```

## Integration Lesson

The loop was found by a live battery, so the fix must be proven
by the same battery:

```text
re-run smoke_deepseek_coding_battery after the stamp
expected: stop_reason=manifested, manifest carries the code,
verdicts flip from substrate_could_body_could_not
to reality_confirmed
```

Unit fixtures lie; the loop must be killed where it lived.
