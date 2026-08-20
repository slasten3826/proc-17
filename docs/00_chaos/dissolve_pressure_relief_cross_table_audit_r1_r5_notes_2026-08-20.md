# DISSOLVE Pressure-Relief Cross-Table Audit R1-R5

```text
layer: CHAOS / audit evidence
date: 2026-08-20
status: completed
physical baseline: de33611c0037
runtime code changed by audit: no
router/default authority changed: no
audited TABLE:
  docs/01_table/yellowprints/dissolve_pressure_relief_reader_yellowprint.v0.md
audit disposition: TABLE amended; R7 exact CRYSTALL completed
crystall result:
  docs/02_crystall/blueprints/dissolve_pressure_relief.v0.md
next gate: R8 pure reader implementation, awaiting machinist instruction
```

This document records the bounded R1-R5 audit required by:

```text
docs/00_chaos/dissolve_pressure_relief_execution_and_codex_budget_plan_2026-08-14.md
```

It audits one treatment only:

```text
dissolve.inherited_rejected_form_release.v0
-> dissolve.pressure_relief.v0
```

No general semantic-GC law, scalar `Z`, router promotion or DeepSeek Harness
integration was evaluated or authorized.

## 1. Method

The audit followed source identities instead of rereading the repository as an
undifferentiated corpus. For each required fact it located:

```text
authoritative writer
stored identity
next named reader
append-only ordering law
current hostile control
failure behavior when the fact is absent or contradictory
```

Primary runtime surfaces:

```text
runtime/qualified_pressure.lua
runtime/pressure_action.lua
runtime/pressure_composition.lua
runtime/router.lua
core/packet.lua
runtime/tension_runner.lua
organs/dissolve.lua
runtime/body.lua
runtime/field.lua
core/dissolve_schema.lua
runtime/camera.lua
runtime/upper_coverage.lua
organs/observe.lua
```

Focused controls run cold during the audit:

```text
test_dissolve_pressure_relief                green
test_inherited_form_dissolve                 green
test_inherited_form_dissolve_hostile         green
test_inherited_form_dissolve_life            green
test_upper_observation_need                  green
```

The full suite was not rerun because R1-R6 changed no runtime code.

## 2. Result In One Screen

The physical release chain is coherent:

```text
NETWORK + exact field version
-> qualified witness
-> immutable action plan
-> selected candidate
-> recorded derivation
-> committed body route
-> destination actor tick
-> normalized unit_dissolution
-> rollback-protected field/residue commit
-> runtime frame
-> post-effect qualified pressure
-> one exact successor upper-observation action
```

No defect was found in the atomic release transaction or in the exact
post-release OBSERVE treatment.

The draft reader TABLE was not ready for CRYSTALL. Five specification gaps
would have forced the implementation to invent policy:

```text
F1 no legal capture window for historical same-coordinate state
F2 declared failure outcomes absent from the returned schema
F3 body route-to-destination reconstruction not specified without v3 ledger
F4 runtime-frame and successor snapshot joins only described as loose order
F5 same-obligation digest input not canonicalized
```

All five are TABLE defects. None requires a runtime fix before R7.

## 3. R1: Selected Pressure And Action Provenance

Result: pass, with F5 precision amendment.

The selected release witness is derived only when all of these agree:

```text
one current-generation inherited_rejected_form unit
exact unit id and version
verified NETWORK projection and rejected-form payload
birth/migration provenance
consumer:dissolve.inherited_rejected_form.v0
one preallocated residue unit id
current potential revision
```

`qualified_pressure.build_witness` deterministically derives `witness_id` and
then delegates to `pressure_action.build`. The action plan binds:

```text
Packet id and generation
target operator ☷
target unit version
residue allocation
potential revision
normalized reason and source refs
expected effect type and discharge reader
```

Composition revalidates witness shape, provenance, action preconditions,
registry availability, readiness and affordability before a candidate can be
selected. The route derivation stores the full selected candidate and action
plan, and the committed body route copies the candidate from the recorded
derivation rather than trusting a fresh caller projection.

Every field required for the same-obligation comparison exists. The draft did
not define the exact canonical envelope hashed into
`pressure-obligation:<sha256>`, leaving CRYSTALL to choose cross-Packet and
cross-generation identity fields. F5 closes that choice in TABLE.

## 4. R2: Route, Arrival And Evidence Roles

Result: physical ordering pass; TABLE amendment required by F3.

Body authority writes:

```text
tension_measure
< route_derivation
< route
< destination operator_tick
```

`packet.commit_transition` verifies that a Tree route names an actual pressure
snapshot and derivation, selects an unexcluded ready candidate recorded in
that derivation, and stores the selected action plan in the body route event.
`tension_runner.arrival_context` then reconstructs the action only from that
committed route payload.

When edge-credit v3 is enabled, a separate massless ledger explicitly binds:

```text
route derivation -> route commit -> destination tick -> effect refs
```

The draft correctly prohibited this instrument from replacing body evidence.
However, it did not say how a reader reconstructs route-to-tick ownership when
the optional instrument is absent. The body already has a sufficient closed
law: the destination tick is the first subsequent body-lane event after the
committed route and must open the route target's actor lease. Observer-lane
events are not body events. No intervening body route, tick or terminal event
is admissible.

F3 records this algorithm and makes v3 corroborating evidence whose presence
must agree, never a second authority.

## 5. R3: Atomic DISSOLVE Effect And Final State

Result: pass, no TABLE contradiction.

The unit treatment is protected at four boundaries:

```text
dissolve.readiness independently reconstructs target, NETWORK reason and scope
body.release_inherited_rejected_form normalizes release and residue identities
field.prepare_inherited_form_release validates the complete transaction first
field.commit_inherited_form_release commits target + residue + revision together
```

The `unit_dissolution` event is append-only and can be written only inside a
current ☷ actor tick. The field commit accepts only that exact current-tick
event. A failed commit rolls back both trace append and field mutation.

The release and final state mutually bind:

```text
target id and before/after version
live/selected -> dissolved activation
target activation_source -> unit_dissolution event
release id -> residue carrier
residue created_event_id -> unit_dissolution event
released_mass = {forms=1, relations=0}
irreversible_identity_loss = 0
```

The old action fails object-version preconditions while independent DISSOLVE
readiness returns `already_released`. Multiple releases or a release that
contradicts current target/residue state fail loudly.

## 6. R4: Camera And Post-Effect State

Result: runtime order pass; high TABLE gap F1 and join gap F4.

The ordinary runner order is:

```text
destination operator_tick ☷
< unit_dissolution
< body budget/physics completion
< runtime_frame ☷
< post-effect tension_measure ☷
< post-effect route_derivation
< next route commit or typed no-viable handling
```

The frame carries the destination tick and release in `source_event_refs`, the
release in `effect_refs`, and the exact post-effect revision vector in
`revisions_after`. The following qualified pressure snapshot carries the same
vector in `source_revisions`.

The draft proposed deriving the same-coordinate control from current Packet
state but did not name when the reader runs. A later ☴ tick can add an
observation unit and change coverage, revisions and witnesses. No historical
field snapshot exists from which to reconstruct the earlier world. A reader
invoked after that mutation would be pure but causally wrong.

F1 therefore fixes the v0 capture boundary:

```text
after router.after_tick has appended the actual post pressure snapshot and its
route_derivation, before commit_route or no-viable death handling
```

At that point:

```text
Packet operator is still ☷
current revisions equal frame.revisions_after
current revisions equal actual snapshot.source_revisions
no successor body mutation has occurred
```

The reader may be enabled as a massless runner observer at this exact gate. It
returns detached result data and never appends Packet trace.

F4 makes the frame, pressure snapshot and post derivation exact joined
records, not merely events that happened in a convenient order.

## 7. R5: Successor Upper OBSERVE

Result: physical treatment pass; output precision amendment required by F4.

After the exact release, `upper_coverage` derives three versioned needs:

```text
current work                       semantic
dissolved inherited form          material
rejected-form residue              semantic
```

They are grouped into one `semantic_observe` witness whose source domain is
`upper_observation:material+semantic`. Its exact action carries all three unit
versions and the closed presentation policy:

```text
network.rejected_form_after_release.v0
```

OBSERVE independently verifies the same projection, release event, target and
residue before presenting current work plus bounded residue. It does not expose
the full inherited-form carrier.

The pressure-relief reader must validate this exact witness and action when it
is present, while retaining every other successor witness separately. The
post-effect route derivation supplies executability/readiness information, so
a missing substrate can report a present but non-executable successor without
retroactively changing release discharge.

## 8. Findings

### F1: Same-coordinate state has no historical reconstruction

```text
class: TABLE underspecification
severity: high before implementation
runtime defect: no
```

The proposed reader consumes current field state, but the draft allows no
exact invocation window. Running after the successor tick measures a later
field. Amend with the capture boundary in Section 6 and require exact revision
equality before deriving the control. A mismatch is `not_measurable`; a
trusted frame/snapshot contradiction is loud.

### F2: Declared outcomes cannot be represented

```text
class: TABLE schema contradiction
severity: high before implementation
runtime defect: no
```

Sections 7 and 12 require `not_measurable` and `not_discharged`, but the
derived schema permits only two discharged classifications and hardcodes all
counts to successful values. Amend the schema with an explicit measurement
status, closed classifications, reason codes and nullable discharge counts.
Missing evidence must never be serialized as zero discharge.

### F3: Body arrival reconstruction was implicit

```text
class: TABLE causal-join underspecification
severity: medium
runtime defect: no
```

The draft said that destination tick and release belong to the committed
arrival but gave no body-only reconstruction rule. Amend the request to accept
one committed route root and derive the rest from body-lane order. When v3
arrival evidence exists, require exact agreement; when absent, do not invent
instrument evidence.

### F4: Post frame, pressure and successor were only loosely ordered

```text
class: TABLE identity underspecification
severity: medium
runtime defect: no
```

Amend with exact frame refs, revision equality, first post-effect qualified
snapshot, its route derivation, and exact successor witness/action binding.

### F5: Same-obligation key lacked a canonical envelope

```text
class: TABLE identity precision
severity: low
runtime defect: no
```

Amend with a versioned record including Packet, generation and treatment
identity plus every previously named semantic field. Target version remains
excluded deliberately.

## 9. R6 Disposition

| Finding | Disposition | Runtime change |
|---|---|---|
| F1 | exact capture window and revision gate added to TABLE | none |
| F2 | measurement outcome schema repaired | none |
| F3 | route-root body reconstruction law added | none |
| F4 | frame/post-derivation/successor joins made exact | none |
| F5 | canonical same-obligation identity added | none |

The amended TABLE fed the exact R7 crystall on 2026-08-20. This audit and the
crystall do not authorize implementation by themselves; the machinist must
open R8 explicitly.

R7 then found one output-representation defect outside the R1-R5 finding set:
the `not_discharged` outcome could not expose non-successful controlled-post
values. TABLE Amendment A2 closes it without a runtime change.

## 10. Preserved Boundaries

```text
☷ still cannot certify its own relief
the reader remains pure and detached
edge-credit remains optional corroboration, not body truth
missing evidence never becomes zero
successor pressure is not subtracted from discharged release debt
instrument or reader failure never becomes Packet death
general semantic GC remains deferred
router/default authority remains unchanged
```
