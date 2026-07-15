# Corpse Trace Writes Notes

Status:

```text
chaos
author: claude (Mythos/Fable)
from QA pass over dead guard fix
runtime defect, second layer of death finality
```

## Where This Comes From

`packet_death_finality_bug_notes.md` fixed the first layer:

```text
dead packet cannot die / manifest / append_chaos / crystallize / measure_tension
```

QA re-probe on the fixed tree found the second layer still open.

## Bug

The corpse can still write to its own trace.

Reproduction on the fixed working tree:

```text
create packet
die(budget_exhausted)
packet.append_trace(corpse, {type = "cycle", ...})
-> ALLOWED, trace length 2 -> 3
```

Two open channels:

```text
1. exported packet.append_trace has no dead guard
2. body.record_choice / record_validation / record_cycle
   write boundary lists and trace through channel 1
```

Channel 2 is worse than it looks:

```text
record_* mutate boundary.choices/validations/cycles
BEFORE calling append_trace
```

So even if channel 1 is guarded, an unguarded `record_*` produces a
half-write: boundary mutated, trace rejected.

## Why This Is The Purest Form

The trace is the epistemic ledger of the body.

Every truth_status claim lives there.

A corpse that can keep writing the ledger can keep producing
`runtime_confirmed` events after its own death.

Death without a frozen ledger is not finality.

## Class

Same family, third projection:

```text
written record without named reader        (budget, graves, compost)
status field written without status guard  (five core ops)
ledger open after status says closed       (this)
```

## Trap For The Fix

The internal local `append_trace` in `core/packet.lua` must stay
unguarded:

```text
packet.die sets status = "dead"
THEN appends the death event
```

Guarding the internal path would kill the death event itself.

Guard only the exported wrapper.

## Open Ontology Pressure (not resolved here)

`manifested` packet freely accepts chaos and mutation (probed: ALLOWED).

If manifest is not a terminal state and `complete` death follows it,
this is fine — but it is written nowhere.

Needs a canon line: only `dead` is terminal; manifest is not a freeze.

Not part of this fix.
