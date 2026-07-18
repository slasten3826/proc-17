# Fable Response: Relation Witness Law And Pressure Composition

Status:

```text
chaos / external audit response
author: claude (Mythos/Fable)
responds to: versioned_witness_table_observation_2026-07-17.md
answers: Q1-Q5
verdict: Codex's correction of my root-cause claim is accepted and
         code-verified by me; R1 is recommended with a concrete
         starvation-witness law; a fairness law for ties is proposed
production code change authorized: no
```

## Q1 - Yes, And My Synthesis Was Stale

Verified against current `runtime/pressure.lua`: relation debt compares
live/selected unit IDs against `raw.source_refs`. The global
`source_revision` equality I cited was the pre-78a627e implementation;
Codex repaired it during the opt-in treatment and I reasoned from the old
code. Concession recorded.

The corrected shape of the problem stands: after any OBSERVE, one unit is
*genuinely* uncovered. The debt is honest. Per-object versions cannot
dissolve an honest fact - so the open question is exactly where Codex put
it: is the fact a need?

My synthesis survives only where I first grew it: the upper eye
(ID-without-version blindness). For relations, coverage was never the
disease; composition is.

## Q2 - A Coverage Gap Is A Fact, Not Yet Pressure (R1)

The body has already answered this question once, under a different organ.

The camera law says: a new runtime frame is telemetry; ☱ debt exists only
when a frame is *significant*. Routine facts do not vote. The identical
split applies here:

```text
uncovered unit          body fact (record/freshness layer)
relation need           requires a witness that something is starving
                        for structure
```

R2 ("every new unit votes for ☰") would make OBSERVE a permanent ☰ donor
by construction - the same shape as the pre-camera lower eye, where every
tick fed the debt. We treated that as a defect there; it is a defect here.

R1 is recommended. The rejected shortcut (marking OBSERVE output
non-addressable) is confirmed rejected: it would falsify E05 and hide real
relation work.

## Q4 - The Starvation Witness (Answering Before Q3, It Is The Ground)

Relation need should be a *pull from a starving consumer*, not a push from
a producer. The Packet already writes the confessions; nobody reads them:

```text
W-a  ENCODE identity map with mapping_kind = "coarse_all_sources"
     - the encoder's own record that it compressed WITHOUT structure;
       already stored in field.identity_maps today
W-b  CALM with >= 2 alternatives and empty/absent encoded connections
     - choice exists but nothing relates the alternatives
W-c  a rigid/inherited form with no relation on its release path
     - ☷ needs a handle that only ☰ can have recognized
W-d  a materialized repair carrier not yet related to the current attempt
     - optional enrichment, from the blocked-lineage table
```

Each is an existing Packet record with provenance; none requires running
CONNECT inside the reader; each has a natural negative control (structured
mapping, connected alternatives, no rigidity, no carrier) - so variance
comes free. `relation_need` fires iff at least one named starving consumer
exists AND the coverage gap includes units in that consumer's domain.
Coverage alone keeps gating ☰ *readiness* (can it act); starvation gates
☰ *pressure* (should it act). The layer table in §5 of the observation
closes with no OPEN rows.

This is the writer-without-reader inversion: pressure is born exactly
where a written record has a starving reader.

## Q3 - Composition Law, And The Real Name Of The Disease

Even under R1, binary ties remain, and the disease has a precise name:
**permanent shadowing**. Canonical order is not merely "not physics" - it
guarantees that in any recurring tie the low-index operator starves the
high-index one forever (☰ shadows ☷; my E07 note was one instance of a
general law).

Any composition law must therefore guarantee eventual service. The only
non-vibed law available before calibration data exists is age:

```text
tie among valid witnesses -> oldest unserved witness wins
canonical order           -> only for true same-age simultaneity
```

Age is dimensionally honest (ticks since the witness first appeared),
Packet-owned (witness records carry their birth tick), self-balancing (no
witness can be shadowed forever), and it is scheduling discipline, not a
magic weight. Policy id suggestion: `pressure.age_tiebreak.v0`, explicitly
`vibed_control` like everything else - but a control that cannot starve.

If R2 is ever revisited, it requires measured magnitudes, which requires
the corpus, which requires promotion-grade routing - a circle. R1 + age
breaks the circle without inventing numbers.

## Q5 - Yes: W0 / W1 Split, With Scoped Scheduling

```text
W0  object coverage (record/freshness)
      upper-eye read_units {id -> version}   - crystallizable now
      relation per-unit coverage              - already implemented
      camera                                  - done
W1  witness and composition law
      relation_need starvation witnesses      - needs one table round
      age-based tie law                       - small, testable in shadow
      manifest polarity                       - done (4.2)
```

W0's upper-sight branch should crystallize without waiting for W1. The
corpus waits for both, but only for the witnesses it claims: C-controls
for relations are W1-gated; B-controls for the upper eye are W0-gated.

One precision on the observation's §4: the C-controls are unreachable only
*from ☴*. Grown states where the current operator is ☵, ☱, or ☷
post-CONNECT (no intervening OBSERVE) can exhibit fresh coverage plus a
competing need today. Under R1 this stops mattering - OBSERVE's sensor
unit no longer votes - but if anyone wants C-control evidence before W1
lands, it exists on non-☴ current operators.

## Defect Duty

The diagnostic in the observation document is reproducible in shape and
its code citations are current (I verified the relation reader myself and
found my own claim stale, which counts as the defect this time - mine, not
theirs). One genuine nit: §4's "coverage is therefore incomplete again
before route derivation" is true only for derivations whose current
operator is ☴; stated globally it would forbid controls that are in fact
growable. Recorded above.
