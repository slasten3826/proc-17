# DISSOLVE Pressure Relief First Measurement

```text
layer: CHAOS
date: 2026-08-13
status: runtime_confirmed bounded observation
baseline revision: de33611
executable witness: tests/test_dissolve_pressure_relief.lua
runtime authority change: none
DISSOLVE event schema change: none
general pressure_relief formula authorized: no
TABLE materialized as:
  docs/01_table/yellowprints/dissolve_pressure_relief_reader_yellowprint.v0.md
CRYSTALL authorized by this record: no; cross-table audit required
```

## 1. Question

The conserved semantic-GC hypothesis kept three accounts separate:

```text
released_mass
irreversible_identity_loss
pressure_relief
```

The direct inherited-form treatment already measures the first two. This
experiment asks the remaining narrow question:

```text
What happens to the exact qualified pressure that selected ☷ after the
selected release executes?
```

It does not ask whether all Packet pressure falls, whether the body becomes
calm, or whether a general semantic collector is implemented.

## 2. Controlled Life

The experiment grows a real QA-rejected ancestor and its recovery descendant
through the existing fixture. It does not synthesize a grave, carrier,
NETWORK projection, inherited form, pressure witness or DISSOLVE event.

Before the effect, at `▽`, the qualified snapshot contains exactly one
witness:

```text
kind: inherited_rejected_form_release_need
causal class: blocking_demand
target: ☷
source domain: network_inherited_rejected_form
```

Pressure composition selects `☷` from that exact witness and action plan. The
selection pass is proven massless by a Packet digest check.

The selected action then executes the existing atomic release transaction:

```text
one inherited rejected form: live -> dissolved
one bounded rejected-form residue: created
released_mass: {forms=1, relations=0}
irreversible_identity_loss: 0
```

## 3. Observed Aftermath

The initial measurement compared the pre-effect snapshot at `▽` with the
post-effect snapshot at `☷`. Audit exposed a false-green route: merely arriving
at `☷` hides a witness targeting `☷`, because `☷ -> ☷` is not a legal edge.
That disappearance cannot prove relief.

The corrected experiment therefore uses two post-effect reads:

```text
same-coordinate comparison:
  rederive from the changed body as if current_operator were still ▽
  this isolates world-state change from topology change

real successor read:
  derive at the actual current operator ☷
  this reports the next lawful obligation of the living Packet
```

Before the effect, an arrival-only control confirms both sides of the trap:

```text
actual coordinate ☷: old witness absent before release
controlled coordinate ▽: same old witness still present before release
```

After the effect, qualified pressure is derived again from current body state
under both coordinates.

Observed result:

| Quantity | Before | After |
|---|---:|---:|
| Exact selected release witness | 1 | 0 |
| Any inherited-form release witness | 1 | 0 |
| Post-release upper OBSERVE witness | 0 | 1 |
| Total qualified witness count | 1 | 1 |

The first two rows use the controlled `▽ -> ▽` comparison. The successor row
uses the real post-effect coordinate `☷`. The aggregate row uses the
same-coordinate comparison and also happens to be `1 -> 1` in the real
successor snapshot.

The successor witness is causally different:

```text
kind: upper_observation_need
causal class: blocking_demand
target: ☴
source domain: upper_observation:material+semantic
scope: current work + dissolved form + bounded residue
```

It has a different `witness_id`, target, source domain and object-version
scope. It asks the body to observe the field made visible by release. It does
not claim that the old form still needs release.

## 4. What The Experiment Falsifies

For this controlled life:

```text
total witness count: 1 -> 1
naive aggregate count delta: 0
exact selected obligation: present -> absent
```

Therefore this candidate definition is false:

```text
pressure_relief = max(0, total_pressure_before - total_pressure_after)
```

Changing the subtraction direction does not repair the model. A zero
total-count delta would call the release ineffective even though the exact
pressure that selected it was discharged and its exact target became
unreleasable.

More generally, pressure witnesses from different causal domains are not
fungible merely because they share a causal class or count as one item. A
release can remove one obligation while creating another legitimate
obligation. DISSOLVE does not promise global calm.

## 5. Supported Interpretation

The first runtime-supported interpretation is:

```text
pressure relief is a typed causal discharge comparison
```

For the current treatment, the comparison must join at least:

```text
selected pre-effect witness id
selected action-plan id
exact release/effect identity
same-coordinate post-effect absence of that witness
post-effect target state and version
real-coordinate successor witnesses reported separately
```

The observed discharge magnitude is one selected witness. This is a fact
about one v0 treatment, not authorization for a universal numeric formula.
Future TABLE work may decide that `pressure_relief` is a typed record or vector
rather than the scalar proposed in early CHAOS.

## 6. Why It Is Not Written By ☷

The DISSOLVE event cannot honestly write its own pressure relief. At commit
time it knows the release effect, released mass and preserved residue. Relief
exists only after qualified pressure is re-derived from the resulting body
state.

Writing relief into `unit_dissolution` would turn an expected consequence into
a self-certified fact. The event schema therefore remains unchanged.

## 7. Falsifiers Preserved

```text
PR01 the exact selected witness survives a successful exact release
PR02 the released target remains ready for the same release action
PR03 post-effect derivation mutates Packet state
PR04 the successor OBSERVE witness reuses the release witness identity
PR05 a release is called relieving solely because aggregate witness count fell
PR06 an unrelated successor obligation is subtracted as if it were the same Z
PR07 a DISSOLVE event self-declares post-effect relief
PR08 no-rigidity control receives release credit without a release witness
PR09 route arrival alone is accepted as proof that target pressure discharged
PR10 before/after snapshots at different topology coordinates are compared
     without an explicit same-coordinate control
```

## 8. Disposition

Runtime-confirmed now:

```text
the exact pressure selecting direct inherited-form DISSOLVE is discharged
the aggregate qualified-witness count does not fall in the controlled life
release transforms the immediate obligation from ☷ release to ☴ observation
```

Still open:

```text
the general pressure_relief schema and named production reader
comparison rules for multiple witnesses and merged action plans
comparison across causal classes or source domains
semantic support age and mark/sweep eligibility
raw and formed relation collection
any claim that later insight was caused by release
```

The next architectural move is now materialized as a TABLE contract for the
post-effect reader. It compares matched causal obligations, requires an
explicit same-coordinate topology control and retains new successor pressure
without laundering it into failure of the completed release. Cross-table audit
must close before CRYSTALL or runtime implementation.
