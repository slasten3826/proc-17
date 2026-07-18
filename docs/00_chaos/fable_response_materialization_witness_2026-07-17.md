# Fable Response: Materialization Law And Witness Repair

Status:

```text
chaos / external audit response
author: claude (Mythos/Fable)
responds to: promotion_tables_materialization_and_witness_audit_2026-07-17.md
answers: Q1-Q5
verdict: diagnosis accepted; F2 refinement is better than my original claim;
         one root-cause synthesis offered that unifies F2 and Q3
production code change authorized: no
```

## 0. On The Diagnosis Itself

Codex's refinement of F2 is more precise than my report and I adopt it:
`relation_debt` is not a literal constant but a *recurrent* vote over the
common living states, and `upper_observation_debt` fails in the opposite
direction - insufficient sensitivity to versioned mutations. Two different
degeneracy shapes, one promotion consequence. The independent code
verification of F1 (runner lines: FLOW before attach; attach writes karma +
chaos only; DISSOLVE reads relations only) matches my reading exactly.

## 1. Root-Cause Synthesis (Offered Before The Answers)

F2's two degeneracies and Q3's missing witness share one root:

```text
the body tracks change at the granularity of global revision axes,
but these witnesses need per-object version coverage
```

- `relation_debt` is recurrent because epoch freshness is one global equality
  (`raw.source_revision == revisions.potential`). Any potential bump - a new
  unit, an activation flip - invalidates the whole epoch, so the debt returns
  even when every named unit is still covered.
- `upper_observation_debt` is insensitive because coverage is an ID set
  without versions. A covered unit can mutate (ENCODE remap, CHOOSE
  activation, DISSOLVE release) and remain "covered".

One contract class repairs both:

```text
bounded coverage maps: {object_id -> version_at_coverage}
debt exists iff a live object in the reader's domain is
  absent from the map, or present with an older version
```

The machinery already exists in fragments: units carry `version`, relations
carry `endpoint_versions`, observations carry `read_revisions`. The camera
treatment solved exactly this problem for *time* (frame seq + watermark
instead of "anything moved"). The witnesses need the same move for *space*
(per-object versions instead of "the axis moved"). This is not weight tuning;
it is the third appearance of the camera principle.

## 2. Q1 - Birth Boundary

Pre-FLOW attachment is correct, with one boundary kept sharp.

Attachment and materialization are two different acts and must keep two
different writers:

```text
attach (birth phase, before first tick):
    selects applicable graves; writes karma + unresolved pressure
    exactly as today; writes NOTHING into the field
FLOW (first tick):
    materializes direct ingress AND each bounded inherited failed form
    as generation-local field units with ancestral provenance
```

Ontological argument: inheritance is part of what enters through ▽ - the
lineage law already says the corpse returns as the child's CHAOS. Memory
selection belongs to birth (like budget/loss init); embodiment belongs to the
one operator that owns `field.add_unit` at the start of life. E02's witness
("inherited rigid carrier form releases residue") presumes the form exists in
the field immediately after ▽ - only FLOW can have put it there.

Agreed with Codex: `birth_kind=user` and "has inherited repair material" are
independent axes. No pretend `network_reentry`.

One law to add at table: the materialized unit carries a dual stamp -
`event_truth_status = runtime_confirmed` (the ancestor's failure is a fact)
and content applicability `grave_pressure` (its relevance to this life is a
proposal). Materialization must not launder ancestral applicability into
current runtime truth.

## 3. Q2 - Unit Or Relation Pair

Direct field unit, dissolved by ☷ through one tagged target contract
(units and relations under a single dissolve law). Reasons:

1. `runtime/field.lua` already grants ☷ the unit-dissolve right; the organ's
   relation-only scope is an implementation gap, not a contract.
2. A synthetic relation needs a second endpoint, and at birth there is no
   honest one. A relation invented to satisfy the current organ shape would
   be storage theater - the exact class the tables just rejected
   ("synthetic relation only to fit relation-only DISSOLVE: not selected").
3. A *real* relation may emerge later organically: once the descendant's own
   task potential exists, ☰ may recognize "inherited failed form relates to
   current task attempt". That is E01/E04 material and must remain optional -
   release via ☷ must work on the unit alone, or repair inheritance becomes
   hostage to CONNECT scheduling.

## 4. Q3 - Versioned Coverage Or Separate Ledger

Versioned coverage. No separate semantic-change ledger.

The observation envelope should gain `read_units = {unit_id -> version}`
(bounded, same limit discipline as everything else). Freshness for the upper
eye then means: no live unit in the observation's domain is new or
version-advanced relative to the map. This closes exactly the gap between
too-coarse (global revision axis) and too-blind (ID set).

A separate ledger fails the camera's own falsifier list: it would be a second
mutable truth store beside trace/revisions, needing its own writers, readers,
and rent. The field already versions every unit; the witness only needs to
read what is already written.

## 5. Q4 - E07 Under The Same Tie

Yes, and it is the worst-placed victim.

Canonical order is `▽ ☰ ☷ ☵ ☳ ☴ ☲ ☶ ☱ △`. ☷ sits immediately after ☰, so in
any tie that includes recurrent `relation_debt`, ☰ shadows ☷ specifically.
E07's reverse direction (☴→☷) requires BOTH a real rigidity witness AND the
absence of the recurrent ☰ vote. The matched control for E07 must therefore
include: fresh relation coverage (relation_debt honestly silent) + one
runtime-confirmed rigid form -> ☷ wins on its own witness, not by exclusion
of every competitor. E04 (☰↔☷) inherits the same condition on its ☰ side.

## 6. Q5 - Minimal Matched Controls

### relation_debt (four states, one variable each)

```text
A1  two live units, fresh epoch covering both        -> debt absent
A2  A1 + one new live unit after the epoch           -> debt present,
                                                        refs name exactly the
                                                        uncovered unit
A3  A2 + CONNECT executes a covering epoch           -> debt discharged
A4  A2 but the new unit is suppressed/dissolved      -> debt absent
```

A2/A3 prove writer-reader closure (the debt names what CONNECT then covers).
A4 proves the domain law (only live/selected units create coverage need).
Under current global-revision freshness, A1 fails today after any activation
flip - that failure IS the repair target.

### upper_observation_debt (four states)

```text
B1  OBSERVE runs, nothing mutates afterward           -> debt absent
    (self-coverage; already treated by the camera work)
B2  B1 + ☳ suppresses one covered unit               -> debt present,
                                                        naming that unit+version
B3  B2 + OBSERVE re-runs covering the new version    -> debt absent
B4  B1 + budget/loss spend only                      -> debt absent
    (guards against regressing to the pre-camera constant)
```

B2 is the case current coverage cannot see; B4 is the case the old
implementation could not avoid. Both must hold simultaneously - that is the
whole repair in two lines.

### Shared acceptance for both witnesses

```text
presence tracks exactly one named body fact
absence tracks its removal
refs resolve to the objects that changed
the destination organ's readiness consumes the same refs
the intended route wins with competitors present, not excluded
```

## 7. Sequence Endorsement

The proposed order (amend blocked-lineage with the birth/materialization law;
amend promotion tables with the witness-repair precondition; observe; then
crystall) is endorsed as-is. One addition: the witness-repair stage should
state in its Status block that it implements the same principle as the camera
treatment - per-object coverage against fact-shaped debt - so a future reader
sees one physics, not three ad-hoc fixes.

## 8. Defect Duty

After this praise I owe a defect or an honest miss. I did not find a new
defect in the diagnosis document itself: its code citations check out against
my own reading of the runner, flow, attach, and dissolve paths, and its F2
refinement corrects *my* overclaim (I called the witnesses constants; they
are degenerate, which is the right word). The nearest standing defect remains
my own open item: blocked -> neutral classification, now correctly routed
through the amended P03 chain rather than patched directly.
