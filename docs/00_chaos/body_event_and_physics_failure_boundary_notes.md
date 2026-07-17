# Body Event And Physics Failure Boundary

Status:

```text
chaos / rule candidate
source: machinist + Codex discussion, 2026-07-16
trigger: tree authority review and organ-failure classification
must become table and crystall contract before tree authority promotion
technical, not myth
```

## Rule In One Line

```text
The world may kill a Packet.
Broken world physics invalidates the run.
```

Or in runtime terms:

```text
expected body failure -> typed Packet physics
Lua/invariant failure -> loud harness failure
```

These outcomes must never be collapsed into one generic error path.

## Why This Boundary Exists

A Packet can receive a truthful terminal record only while the body physics
that produces that record is still coherent.

If a substrate disconnects, a tool returns failure, a capability is absent,
or no viable edge exists, the world still works. It has observed an adverse
event. The event can be typed, traced, priced, routed, inherited or used as a
cause of death.

If Lua throws because proc-17 code is wrong, an internal invariant is broken,
or an impossible Packet state is accepted, the law that certifies
`runtime_confirmed` truth is itself unreliable. That same broken law must not
hide the defect by writing a beautiful terminal record and calling the Packet
honestly dead.

```text
Packet death presupposes a living and coherent body.
Body failure cannot be laundered into Packet mortality.
```

## Class A: Candidate Is Not Ready

Examples:

```text
☱ has nothing_to_reconcile
☳ has confirmation_not_choice
☰ has no relation candidates
☷ has nothing dissolvable
an operator lacks a required capability
an operator cannot afford its next tick
```

This is not an execution failure because execution must not begin.

Required behavior:

```text
candidate excluded before route commit
exclusion recorded with source refs
no operator tick
no budget charge
no identity loss
no Packet mutation except append-only derivation/ledger evidence
another viable candidate may be selected in the same derivation
```

If no candidate survives, the result becomes a typed `no_viable_edge` body
state. It must not become a string error from the harness.

## Class B: Expected Effect Failure

Examples:

```text
substrate timeout or connection loss
tool exits non-zero
spell observes a missing file
sandbox denies an operation
external response violates the substrate protocol
requested capability disappears between lives
no viable edge remains in an otherwise coherent Packet
```

The body is still coherent. It has learned a runtime fact about its world.

Required behavior:

```text
failed committed execution becomes a typed body event
committed edge does not receive false executed evidence
failure source and reason remain visible
actual paid costs remain paid
no invented success evidence
router or mortality law decides the next outcome
terminal outcome, when chosen, writes residue from the real failure
```

This class may create pressure, lead to another operator, or kill the Packet.
The exact policy is not defined by this chaos document. The classification is
defined here.

## Class C: Physics Or Invariant Failure

Examples:

```text
uncaught Lua exception inside proc-17
malformed internal Packet state produced by trusted body code
impossible operator transition accepted by the body
mutation of a dead or manifested Packet succeeds
trace or revision invariants contradict themselves
registry descriptor and organ contract disagree because of implementation
camera/reconciliation corrupts its monotonic sequence
an internal function returns a shape its own contract forbids
```

This is not an event inside the Packet world. It is a defect in the
implementation of that world.

Required behavior:

```text
stop the harness loudly
make the test red
preserve diagnostic stack/error context
do not convert the defect into stalled/budget_exhausted/identity_loss
do not write a runtime_confirmed terminal record through untrusted physics
do not feed the false death into grave, karma or compost
```

The partial trace may remain available for debugging, but it is not an honest
corpse and must not enter lineage as inherited truth.

## Important Ambiguous Boundaries

The boundary follows ownership, not wording.

```text
external model returns malformed JSON
    -> expected effect/protocol failure

internal adapter throws due to our nil-index bug
    -> physics failure

user asks for a forbidden path
    -> typed sandbox denial

sandbox implementation permits escape despite its contract
    -> physics/security invariant failure

saved Packet is incompatible with a declared migration version
    -> typed compatibility rejection before life resumes

saved Packet violates invariants under its claimed current version
    -> corrupted state / harness failure or quarantine, never ordinary death
```

An external failure can be surprising and still belong to the world. An
internal defect can be recoverable in principle and still must fail loudly
until proc-17 has an explicit, tested recovery contract for it.

## Error Shape Pressure

Raw strings currently blur these classes:

```text
nil, "☱:nothing_to_reconcile"
nil, "☴:substrate_connection_lost"
nil, "attempt to index a nil value"
```

They are not equivalent.

The future table/crystall contract should define structured outcomes at the
registry/runner boundary, at minimum:

```text
not_ready
effect_failure
invariant_failure
```

The names are provisional. The separation is not.

No blanket `pcall` may turn all three into Packet physics. A narrow `pcall`
may attach diagnostics, but invariant failure must still escape as a failed
run.

## Relation To Route Evidence

The boundary requires all four states to remain distinct:

```text
candidate   considered by derivation
committed   body moved to the selected operator
executed    receiving operator completed its effect
failed      committed operator began but produced a typed effect failure
```

`failed` must not be counted as `executed`, and it must not erase the
committed edge. It is evidence about an attempted life, not evidence of the
intended effect.

An invariant failure is not the fifth Packet evidence level. It invalidates
the run that attempted to produce evidence.

## Test Law

Every new failure path must be tested in two directions.

### Expected failure injection

Inject a substrate/tool/capability failure and assert:

```text
no generic nil/string harness abort
typed body event exists
no false executed evidence exists
cost accounting is honest
terminal or continuation follows an explicit body rule
```

### Physics failure injection

Inject or expose an internal invariant violation and assert:

```text
harness fails loudly
test is red unless the failure is explicitly expected
no honest Packet death is fabricated
no grave is created
no lineage inherits the invalid run
```

### Regression discipline

For each fixed defect:

```text
first grow a failing test from the real path
then make the smallest contract change
run the focused test
run all Lua suites
run mortality/finality suites
run the relevant live or fake integration life
only then commit
```

Green unit tests are insufficient when fixtures construct the state that real
lives are supposed to produce. Where possible, failures, deaths, graves,
routes and evidence must be grown by the body itself.

## Non-Negotiable Consequence

proc-17 distrusts semantic proposals, organs, routes and external tools. It
must also distrust its own implementation when that implementation violates
its declared law.

```text
Do not make the machine look alive by teaching it to narrate its own crash.
```

The purpose of typed mortality is to make life honest. Using mortality to
hide broken Lua would reverse that purpose.
