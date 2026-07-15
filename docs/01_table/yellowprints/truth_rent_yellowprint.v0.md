# Truth Rent Yellowprint v0

Status:

```text
table
author: claude (Mythos/Fable)
from docs/00_chaos/truth_decay_observation_notes.md
and docs/00_chaos/meat_god_theology_and_truth_rent_notes.md
frame confirmed by machinist 2026-07-15
```

## Goal

Make confirmations mortal.

A `runtime_confirmed` stamp is an event, not an eternity.
Readers must be able to compute how alive it still is.

```text
clock       = universal physics (cheap field on every record)
clock read  = local economics (only where records act later by themselves)
```

## Core Rules

1. **The body clock must run.**
   `physis.clock.ticks` advances once per body tick, in one place,
   next to the budget charge. A standing clock is the null case of
   «читатель без часов».

2. **Every spell result carries a clock.**
   `cast_tick` (when) + `referent` (what it confirmed) +
   `referent_hash` (state of what it confirmed, when hashable).

3. **Two decay clocks, referent first.**

```text
referent hash (primary)   confirmation expires when the referent
                          CHANGES, not when time passes;
                          mismatch -> instant degradation
tick window (fallback)    for unhashable referents (command exit
                          codes, external world): older than window
                          -> stale
```

4. **Decay is computed by the reader, never stored.**
   Trace and evidence stay append-only. Nobody mutates history.
   The reader computes the zone at read time.

5. **Zones and degradation.**

```text
hot   referent verified now            -> keep runtime_confirmed
warm  no referent, inside tick window  -> keep runtime_confirmed
cold  referent changed OR window past  -> semantic_proposal
unclocked  record has no clock fields  -> semantic_proposal
```

Stale degrades to `semantic_proposal`, never to false:
«was fact, is hypothesis again». ☲ recast (a fresh spell run)
is a NEW event that resets the clock — rent is paid by a ledger
entry, not a ledger edit.

6. **Reading lives only in foundation.**
   Foundation is where spell results act later by themselves
   (patterns boost routing). `foundation.snapshot` computes
   freshness per pattern and stops laundering: the aggregate stamp
   certifies the counters, each pattern carries its own effective
   status, and `contains_stale` is explicit.

## Constants Confession

```text
warm_window default = 8 ticks   NAVAYED, not measured
```

Mark it tunable. Measure it the day the body runs real tasks.

## Non-Goals

```text
consensus, Keepers, VDF, neighborhoods, tokenomics
  (Byzantine machinery; the body has one observer)
auto-decay writers (no daemon mutates records)
degrading archival trace events (history is not current truth,
  the trace stays what it was)
foundation strength/stability decay curves (separate decision;
  this yellowprint only makes staleness VISIBLE to readers)
```

## Integration Lesson

Do not test freshness only with synthetic records.

At least one test must earn its staleness:

```text
cast a real py_compile spell on a scratch file
mutate the file
read through foundation
-> pattern is cold, effective status semantic_proposal
recast the spell
-> pattern is hot again, clock reset by the new event
```

## Defect Class Closed

```text
«читатель без часов» — consuming a corpse of a confirmation as
live truth. Review question extends to: кто это читает, когда,
и насколько свежим оно обязано быть.
```
