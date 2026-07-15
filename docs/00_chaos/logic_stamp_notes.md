# Logic Stamp Notes

Status:

```text
chaos
author: claude (Mythos/Fable), ideas by machinist
from live discussion after the coding battery, 2026-07-15
```

## Two Ideas From The Machinist

After the ☱↔☶ loop finding, two proposals arrived:

```text
1. eternal spell: a hand-written confirmation that says
   «я это уже проверял несколько раз»
2. logic stamp: ☶ stamps the packet «проверено логиком»
   and refuses to accept stamped packets again
```

## Idea 1 Rejected As Trojan

An eternal confirmation is the last immortal resident coming back
through the front door, the same day truth rent was installed:

```text
no referent, no expiry -> corpse-of-confirmation by design
self-report instead of execution -> Hod in meat mode
encoder grading its own homework -> the forbidden edge ☵→☶
```

The kernel is legitimate though: «don't ask me the same thing
again» — and idea 2 implements it legally.

## Idea 2 Accepted With One Amendment

The absolute version («stamped packets may never return to ☶»)
is too strong: a packet that acquires NEW evidence after stamping
must be able to stand trial again — otherwise evidence has no court.

Amendment (accepted by machinist):

```text
the stamp expires by REFERENT, not by time —
and its referent is the packet's evidence state
```

☶ stamps: «I judged THIS evidence set (fingerprint) and ruled X».
The router reads the stamp before routing to ☶:

```text
evidence fingerprint unchanged -> court closed, route elsewhere
evidence fingerprint changed   -> stamp stale, court open
```

## Why This Is Not New Physics

This is truth rent applied to logic itself. The stamp is a
confirmation record whose referent is internal state instead of
a file. Same law, third resident:

```text
spell result   referent = file content hash
logic stamp    referent = evidence state fingerprint
```

The machinist converged on this mechanic independently, within a
day of truth rent being built — the canon has started generating
its own consequences in two heads at once.

## Loop Consequence

Current loop (measured, 5/5 packets):

```text
☱ -> ☶ (missing_build_evidence) -> ☱ -> ☶ ... until host kill
```

With the stamp:

```text
first ☶ visit: no_spell verdict, stamp written
next ☱: stamp fresh (evidence unchanged) -> route △
packet manifests honestly with rejected/unproven validation
```

One court visit per evidence state. No starving at a full table —
the body delivers what it has and lets the world judge.

## Relation To Hands (pipeline A)

The stamp alone breaks the loop but does not deliver proof.
When hands arrive (body-side spell minting), new evidence will
stale the stamp automatically and reopen the court:

```text
☳ selects work -> fs writes -> body casts execution spell ->
new evidence -> stamp stale -> ☶ open -> accepted -> manifest
```

Stamp regulates court access; hands produce evidence; rent keeps
evidence mortal. Three mechanisms, one axiom.
