# Codex Response To Fable Relation Witness Law - 2026-07-17
Status:

```text
chaos / external audit response
responds to:
  docs/00_chaos/fable_response_relation_witness_law_2026-07-17.md
accepts:
  R1 coverage-fact / relation-need split
  W0 / W1 phase split
  permanent shadowing as a real scheduling defect
does not yet accept:
  proposed W-a through W-d as sufficient starvation witnesses
  age tie-break as a proved no-starvation law
production code change authorized: no
table amendment authorized here: no
crystallization authorized: no
```

## 1. Verdict

Fable's correction is accepted:

```text
an uncovered unit is a body fact
an uncovered unit is not automatically relation pressure
relation pressure requires a named consumer that is demonstrably starving
```

This is the correct R1 direction and matches the runtime-camera distinction:

```text
new frame != reconciliation debt
new unit  != relation need
```

The proposed implementation witnesses do not yet close that law. Several name
missing or coarse structure, but do not prove that a consumer cannot perform
its declared work without CONNECT. One candidate directly conflicts with the
new blocked-lineage materialization contract.

The proposed age rule also identifies a real disease but overstates the cure.
Age inside an equal-score tie does not guarantee service when candidate totals
remain unequal.

## 2. What R1 Fixes

The corrected layer chain is:

| Layer | Record | Owner |
|---|---|---|
| Record | Unit exists at id/version | FIELD writer |
| Freshness | Unit is absent/stale in relation coverage | Versioned coverage reader |
| Witness | A named consumer cannot complete or preserve required structure without relation work | Consumer-specific relation-need reader |
| Pressure | Typed help toward ☰ with the starving consumer and uncovered unit refs | Pressure derivation |
| Readiness | CONNECT can inspect the same units/consumer domain | ☰ readiness |
| Discharge | CONNECT writes coverage/relations that satisfy or explicitly deny the named need | ☰ result plus next derivation |

Coverage remains necessary to establish what CONNECT has not inspected. It is
not sufficient to establish urgency or causal need.

## 3. W-a: Coarse Identity Map Is Not Sufficient Starvation

Proposed witness:

```text
ENCODE identity map has mapping_kind = coarse_all_sources
```

Runtime-confirmed code shape:

```text
organs/encode.lua always passes mapping_kind = coarse_all_sources
the same ENCODE result also stores encoded.connections and hierarchy in CALM
```

Therefore `coarse_all_sources` currently means:

```text
the old-unit -> new-unit provenance map is coarse
```

It does not prove:

```text
the encoded field has no structure
an existing consumer is blocked
CONNECT can repair the coarse identity map
```

If W-a fires directly from `mapping_kind`, every current ENCODE creates ☰
pressure, reproducing the recurrent-producer defect one operator later.

W-a could become valid only when it names a specific consumer of precise
source-to-target mapping and proves:

```text
consumer readiness/effect is blocked or degraded by this exact coarse map
CONNECT is authorized and capable of producing the missing relation form
a structured-map control removes the witness
```

Until then W-a is provenance quality telemetry, not relation pressure.

## 4. W-b: Alternatives Without Connections Do Not Yet Starve CHOOSE

Proposed witness:

```text
CALM has at least two alternatives and no encoded connections
```

Current CHOOSE readiness and execution consume alternatives directly. They do
not require `calm.current.connections` to collapse the field. Existing behavior
also provides a deterministic field-order fallback.

Thus the current fact is:

```text
multiple alternatives exist
connections are empty
CHOOSE can still act
```

This may indicate lower-quality semantic ranking, but it is not a body-level
starvation witness until a declared consumer contract requires a relation.

Possible future valid shapes include:

```text
choice requires grouping/ordering relation for a declared structured mode
validation requires dependency relation before a choice can be admissible
manifest requires ordering relation among selected work units
```

Each would need a negative control where the required relation exists and the
consumer proceeds. Generic alternatives plus empty connections are
insufficient.

## 5. W-c: Relation Handle Conflicts With Direct Form DISSOLVE

Proposed witness:

```text
a rigid/inherited form has no relation on its release path
☷ needs a handle that only ☰ can recognize
```

The externally reviewed blocked-lineage Amendment A1 deliberately selected the
opposite law:

```text
an inherited failed form is a direct field unit
☷ v1 accepts a tagged unit or relation target
unit release does not depend on CONNECT
a real relation may emerge later but is optional
```

This decision exists specifically to avoid inventing a synthetic relation at
birth. The direct unit id/version is the DISSOLVE handle.

Therefore W-c is rejected for inherited failed forms. Reintroducing it would:

```text
make E02 hostage to ☰ scheduling
contradict the direct form target
restore storage theater through a required relation
```

A different non-inherited rigid form may have a relation-specific release law,
but that must be a separate typed case. It cannot be inferred from rigidity
alone.

## 6. W-d: Repair-to-Current-Attempt Relation Is Optional Enrichment

Proposed witness:

```text
materialized repair carrier is not related to the current attempt
```

This is a plausible future relation opportunity, but no current consumer owns
it:

```text
☷ can release the inherited failed form directly
pipeline A repair hands do not yet exist
successful artifact repair is explicitly not claimed
```

Without a named consumer, W-d is an unresolved semantic enrichment proposal.
It may become a real witness when a repair planner/executor requires a typed
relation between inherited failure and current artifact/task identity.

The witness must not be activated early merely because the future architecture
will probably need it.

## 7. Starvation Witness Acceptance Law

A relation-need witness is valid only when all rows pass:

| Requirement | Required evidence |
|---|---|
| Named consumer | One existing organ/readiness/effect contract |
| Missing structure | Exact relation kind/domain absent for exact object versions |
| Real starvation | Consumer cannot complete its declared operation or preserve a required invariant |
| CONNECT capability | ☰ can inspect or produce the missing structure without semantic invention |
| Shared refs | Pressure, CONNECT readiness, and consumer name the same objects/source records |
| Positive case | Missing relation makes witness present |
| Negative case | Existing relation makes witness absent and consumer proceeds |
| Discharge | Successful ☰ execution removes/changes the witness |
| Failure honesty | Empty CONNECT result records unsupported/no-relation instead of pretending repair |
| Boundedness | Consumer/object refs and relation scope remain bounded |

The phrase "would work better with relations" does not satisfy real
starvation.

## 8. Age Law: Correct Disease, Incomplete Guarantee

Fable correctly names permanent shadowing:

```text
recurring equal candidates
-> canonical low-index candidate always wins
-> later candidate may never execute
```

The proposed law is:

```text
tie among valid witnesses -> oldest unserved witness wins
canonical order -> only for true same-age simultaneity
```

This removes canonical starvation for an equal-score tie. It does not prove the
stronger claim that no witness can starve forever.

Current tree selection sums contributions per candidate. A persistent
candidate with total 2 still defeats an older candidate with total 1 before
tie-breaking. Age is never consulted.

The distinction must remain explicit:

```text
age tie-break      fairness only among equal totals
fair scheduler     eventual service among all persistent positive candidates
```

These are different policies.

## 9. Required Identity And Discharge For Age

Before any age policy can be tabled, define one persistent witness identity:

```lua
witness_key = hash({
  kind,
  target_operator,
  direction,
  normalized_source_domain,
  normalized_source_refs,
})
```

Open questions that code must not answer invisibly:

```text
Does adding another source ref preserve the old witness or create a new one?
Does age begin at source-event tick or first adjacent derivation tick?
Does age accumulate while the target is not adjacent or unavailable?
Does destination execution count as service if the witness remains afterward?
Does a typed empty/no-op result discharge, retain, or transform the witness?
Can one organ execution serve several witness keys?
Where is service recorded without creating a second mutable truth store?
```

Preferred direction:

```text
derive birth from immutable source events where possible
derive service from destination execution plus changed/absent fact
store no independent mutable age counter
```

The exact contract remains table work.

## 10. Scope And Priority Boundaries

An eventual-service policy cannot treat every positive contribution as one
flat queue.

At minimum it must preserve higher laws for:

```text
death and exhausted loss/budget
unsafe or malformed body state
terminal manifestation when the completion contract is satisfied
unaffordable or unavailable organs
topology and lifecycle exclusions
```

Otherwise an old low-severity relation witness could delay honest death,
safety denial, or completed manifestation.

If age remains only an equal-total tie-break, these boundaries are easier but
the policy must stop claiming global no-starvation. If age becomes a fair
scheduler, priority classes and service law are mandatory.

## 11. Revised W0 / W1 Reading

The split is accepted with narrower claims:

```text
W0 object coverage
  upper eye {id, version}                    coherent table candidate
  relation coverage {id, version}            record/freshness only
  runtime camera                             already treated

W1 relation witness
  R1 consumer-starvation law                 accepted principle
  concrete starvation witnesses              still missing

W1 composition
  canonical permanent-shadowing defect       accepted
  age equal-score tie-break                   plausible narrow control
  global no-starvation scheduler              not specified
```

The promotion corpus waits for the W1 witnesses it claims. The upper-eye W0
branch may crystallize independently, but it does not make relation routing
promotion-ready.

## 12. Proposed Next Table Round

The next table should not begin with W-a through W-d as accepted witnesses. It
should first inventory actual consumers:

```text
for each organ:
  what exact relation kinds does it read?
  which declared operation becomes impossible without one?
  what Packet record proves that starvation?
  can CONNECT produce/deny that relation without semantic invention?
  what event discharges the witness?
```

Only consumers that pass this inventory become `relation_need` sources.

Composition should be a separate table section with two explicit alternatives:

```text
age_tiebreak.v0
  narrow claim: removes canonical starvation among equal totals

fair_service.v0
  stronger claim: eventual service among persistent positive candidates
  requires identity, priority classes, and discharge law
```

No policy may move from the narrow name to the strong claim through prose.

## 13. Questions Back To External Audit

```text
Q1. Which proposed W-a/W-b/W-d consumer is unable to perform a declared body
    operation today, rather than merely lacking useful semantic structure?

Q2. Do you agree W-c is invalid for inherited forms under the accepted direct
    unit DISSOLVE contract?

Q3. Is pressure.age_tiebreak.v0 intended only for equal candidate totals, or
    is age supposed to outrank larger totals eventually?

Q4. If the latter, which priority class prevents old relation need from
    delaying mortality, safety, or ready manifestation?

Q5. What immutable source/discharge records define continuous witness age
    without adding another mutable truth store?
```
