# Truth Decay Observation Notes

Status:

```text
chaos
author: claude (Mythos/Fable)
observation only — machinist has an addition pending, do not implement
from dissipative math reading against proc-17 epistemics
```

## Observation

`truth_status = runtime_confirmed` is an eternal stamp.

Set once, true forever.

Dissipative axiom A5 says otherwise:

```text
truth(p, t) := stable_reproduction(p, window_t)
```

Truth requires feeding. Unfed truth weakens.

By the body's own axioms this is a regression into the static
column of the table: "истина вечна" — ZFC mode.

## The Conflation

One field currently serves two different claims:

```text
archival:  "event E was confirmed at tick 42"
           historical fact, never decays, fine as is

current:   "what E confirmed is still true now"
           this is what consumers actually read into the status
           and this one decays
```

Concrete: a spell ran, reality_changed = true, stamped
runtime_confirmed at tick 42. Two hundred ticks later the codebase
changed and the same test would fail. The trace still says
runtime_confirmed. Any reader — router, descendant via grave,
foundation — consumes a corpse of a confirmation as live truth.

This is causal decay from the canon's own decay typology:
structure intact, interpretation intact, reproducible link dead.

## Machinist Line

```text
даже у спеллов должен быть срок годности
```

Spell evidence ages like everything else the body eats.

## The Asymmetry

Mortality is already implemented for everyone except truth:

```text
packets   -> budget death
graves    -> compost
truth     -> immortal
```

Hell is connected for all residents but one.

## Mechanism Already Named In Canon

DISSIPATIVE_OPERATORS describes ☲ CYCLE as:

```text
циклы поддержки истины
```

The re-confirmation operator exists in the grammar.
proc-17 just never routes confirmations through ☲ again.

## Possible Shape (not a decision)

```text
runtime_confirmed carries confirmed_at
readers compute staleness against a window
stale confirmation degrades to semantic_proposal,
  not to false — "was fact, is hypothesis again"
☲ re-confirmation resets the clock
```

## Hold

Machinist said there is something more attached to this observation.

Keep as observation. Do not draw a yellowprint from this alone.

Update 2026-07-15: the addition arrived — ProcessChain/ProcessNet
(dissipative ledger docs) plus design discussion. Recorded in
meat_god_theology_and_truth_rent_notes.md. Still no yellowprint
until the machinist confirms the frame.
