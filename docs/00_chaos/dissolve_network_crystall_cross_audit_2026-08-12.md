# DISSOLVE / NETWORK CRYSTALL Cross-Audit

Status:

```text
layer: chaos audit of crystall (◈)
date: 2026-08-12
decision truth status: document_decision
three-blueprint cross-read: satisfied after C1-C7 dispositions below
runtime implementation authority: yes, exact bounded treatment only
router/full-tree promotion authority: no
general semantic-age DISSOLVE authority: no
```

Audited together:

```text
docs/02_crystall/blueprints/qa_rejected_lineage_recovery.v0.md
docs/02_crystall/blueprints/network_rejected_form_materialization.v0.md
docs/02_crystall/blueprints/qualified_dissolve_inherited_form.v0.md
```

Read back against the current implementations of completion scope, completion,
lineage, carrier, NETWORK ingress, lineage runner, Packet birth, FLOW, Packet
trace, body, field, qualified pressure, pressure action, DISSOLVE, OBSERVE and
the contained QA hand.

This audit does not claim that the treatment already runs. Its purpose is to
make the next code pass mechanical rather than policy-creative.

## 0. Decision

The three blueprints form one implementable causal chain:

```text
real rejected QA candidate generation
-> honest blocked terminal manifest and corpse
-> exact contract-specific completion assessment: unfinished / recoverable
-> bounded carrier plus pure NETWORK projection
-> continuation ledger binds carrier + assessment event + projection
-> fresh child Packet in a distinct pre-provisioned material repository
-> FLOW materializes current work + inherited rejected form
-> qualified blocking demand selects DISSOLVE
-> one body transaction releases applicability and preserves residue
-> one qualified OBSERVE action reads current work plus bounded residue
```

The selected target is deliberately narrow. It proves one real direct-unit
DISSOLVE treatment and the edges `▽ -> ☷ -> ☴`. It does not complete raw stale
relation collection, semantic age, arbitrary thought decay or all 22 edges.

## 1. Runtime Read-Back

The current body has the required lower-level precedents but not the selected
composition:

| Current fact | Consequence for implementation |
|---|---|
| `completion_scope.inspect_lineage` returns `unsupported` with named missing readers | Accepted QA cannot be called `software_accepted` by this slice |
| `completion.evaluate` has no exact QA-terminal dispatch | Add one contract-specific rejected reader before generic blocked classification |
| `lineage.mark_continued` records only corpse/carrier | Extend the existing input/event; do not replace the API |
| `network_ingress.v0` serializes the full carrier | Keep v0 for ordinary recovery; add v1 only for exact QA-rejected projection |
| Packet birth and FLOW already own ingress/materialization | NETWORK projects; FLOW remains the sole field materializer |
| FLOW currently emits a catch-all `network_carrier` unit | The exact v1 branch must emit zero such aliases |
| Field owns deterministic unit ids and per-unit versions | Reuse its allocator; do not add release-specific numbering |
| Generic `field.set_activation` cannot atomically append release + mutate target + create residue | Reject the selected kind there and add one body-owned transaction |
| Packet has dedicated actor-restricted event writers | Add `unit_dissolution` through the same authority pattern |
| Qualified pressure/action already carry exact object versions and refs | Extend the vocabulary; do not add a router exception |

## 2. Cross-Crystall Findings And Dispositions

### C1. Accepted lineage reader is absent

The TABLE phrase "existing software-acceptance path" names canonical
ownership, not implemented behavior. The runtime lineage inspector explicitly
reports:

```text
lineage_stage_scope_reader
lineage_software_scope_reader
lineage_root_delivery_reader
```

Disposition:

```text
exact accepted QA control -> task_state=unknown
terminal_recoverable=false
missing_requirements includes lineage_software_scope_reader
no rejected-form recovery basis
```

The selected code may preserve and validate accepted evidence for a matched
control, but may not invent acceptance.

### C2. Fresh physical repository allocator is absent

Recovery law requires a fresh Packet and fresh repository after rejected QA.
The main lineage runner does not yet own `runtime.repository_generation` or an
equivalent trusted allocator.

Disposition:

```text
ancestor had repository + no independently provisioned fresh child root
-> suspend before continuation_decided
-> fresh_repository_allocation_required
```

The grown integration fixture may use the existing repository
capability/provider test machinery to pre-provision one distinct empty root.
It must prove different public repository id, different root
authority/fingerprint and absence of every ancestor grant/handle. The host
fixture supplies material environment only; it cannot author the assessment,
carrier, projection, pressure, route or release.

Production automatic allocation remains a separate stage-transition slice.

### C3. Core/runtime dependency would be inverted

`core.packet` must validate ingress but cannot require a runtime projector.

Disposition:

```text
core/network_projection_schema.lua
  closed normalization, verification, equality and identity projection

runtime/network_projection.lua
  pure derivation from verified runtime records
```

Packet birth stores a detached schema-valid projection and checks only its
Packet-local coordinates. Runtime owns semantic derivation.

### C4. Existing boundary APIs must remain compatible

Ordinary recovery currently depends on:

```lua
lineage.mark_continued(state, corpse, carrier, input)
network_ingress.prepare(lineage, carrier, options)
```

Disposition: extend their existing `input`/`options` with
`network_projection`. Require it only for exact QA-rejected recovery. Ordinary
v0 recovery remains behaviorally unchanged until a separate migration and
ablation.

### C5. Release crosses trace and field ownership

The TABLE requires one body transaction, while an early crystall draft placed
the public writer in `field.lua`. That would make field responsible for an
append-only Packet trace it does not own.

Disposition:

```text
body.release_inherited_rejected_form
  owns the complete trace + field transaction and rollback

field.prepare_inherited_form_release
  pure exact plan over current field state

field.commit_inherited_form_release
  commits only the prevalidated field part against the dedicated event id
```

All fallible values are built before append. Field restores its touched
surfaces on failure; body removes the just-appended event if field commit does
not complete. Lua/internal errors remain loud harness failures, never Packet
mortality.

### C6. Repository identity must not ride through NETWORK semantics

NETWORK has no right to derive a fresh repository id from lineage/generation
text and must not carry root authority in the projection, carrier semantics or
raw prompt.

Disposition: the trusted repository-hands boundary binds the separately
verified public repository id directly into child birth options. NETWORK sees
only the fact that the required fresh material environment exists; it does not
create or semantically transport that identity.

### C7. "Autonomous descendant" was too strong for current runtime

The positive evidence must be body-grown, but the current body cannot
autonomously allocate the required fresh physical root.

Disposition: autonomy is required for all semantic and lineage facts:

```text
QA execution/check/verdict/terminal projection
manifest/death/corpse
completion assessment/event
carrier and NETWORK projection
continuation decision
FLOW target
pressure/action/readiness/route/effect
```

Only the fresh empty material root may be pre-provisioned by the trusted test
host. Hand-built corpses, assessments, projections, field targets or selected
routes never count.

## 3. Writer/Reader Closure

| Record | Sole/authoritative writer | First named reader |
|---|---|---|
| Rejected QA check | Contained QA hand/body | Verdict assembler |
| Rejected verdict | Deterministic verdict assembler | △ terminal projection |
| QA terminal projection | △ | Corpse/completion reader |
| Completion assessment/event | Completion + lineage ledger | Carrier/NETWORK |
| Recovery carrier | Carrier builder | NETWORK verifier |
| Re-entry projection | Pure NETWORK projector | Continuation, birth and FLOW |
| Current-work unit | FLOW | Qualified semantic reader after release |
| Inherited rejected form | FLOW | DISSOLVE witness/readiness |
| Unit-dissolution event | Body-owned ☷ transaction | Discharge/coverage/audit |
| Rejected-form residue | Same body transaction | Qualified OBSERVE presentation |
| Upper observation | ☴ | Later pressure/structure work |

No new mutable registry is introduced for assessment, projection ownership or
release status. Current state is derived from immutable records plus current
field versions.

## 4. Authority And Truth Boundaries

```text
ancestor QA failure fact               runtime_confirmed
ancestor terminal/death/corpse         runtime_confirmed
intrinsic completion assessment        runtime_confirmed derivation
applicability to child                 inherited_proposal
release event and field mutation       runtime_confirmed
residue                                mixed
post-release semantic interpretation   semantic_proposal
```

DISSOLVE removes inherited applicability. It does not erase the ancestor fact,
diagnose repair, certify the child, choose a task or call a model.

## 5. Implementation Dependency Order

The code pass is divided into independently testable slices:

```text
I1  core schemas: NETWORK projection and DISSOLVE release/residue
I2  exact QA-rejected completion assessment and ledger event binding
I3  pure NETWORK projection plus carrier/continuation verification
I4  ingress/birth/FLOW materialization with zero full-carrier alias
I5  qualified DISSOLVE witness and nonmergeable pressure action
I6  independent readiness plus body/field atomic release transaction
I7  post-release coverage and one bounded OBSERVE presentation
I8  grown ancestor/descendant, ablation and E02/E07 evidence
```

Every slice runs its focused tests, the full suite and mortality regression
before the next slice gains authority. A failing internal invariant stops the
harness loudly; it is never translated into a pretty Packet death.

## 6. Required Falsification Gates

At minimum the implementation must prove:

```text
exact rejection vs generic blocked vs QA infrastructure failure
assessment identity unchanged by wallet/recovery policy
accepted evidence remains honest unknown pending lineage reader
fresh-root absence suspends before continuation
projection failure produces no continuation event
zero network_carrier semantic aliases on exact v1 path
FLOW creates exactly current-work + inherited-form units
consumer ablation removes ▽->☷ and the release
stale/foreign/replayed actions produce zero writes
injected transaction failure restores trace and field byte-for-byte
successful release is exactly once and preserves bounded residue
dead Packet cannot release
post-release observation is one action, not a self-loop
observer instrumentation has zero body mass
grown E02/E07 evidence is not tie-only or forced by the harness
```

The existing raw-stale pending gate remains a separate expected RED. This
direct-unit treatment must not make it green by changing its oracle or by
adding a router exception.

## 7. Explicit Deferrals

```text
automatic fresh physical repository allocation
accepted software/root lineage readers
persistent cold-corpus storage
ordinary recovery prompt migration
generic grave-repair recovery
semantic age / every-tick collection
raw stale-relation growth choreography
arbitrary form/relation garbage collection
all 22-edge corpus completion
Tree/router promotion
```

## 8. Final Decision

The CRYSTALL stage is complete for the exact QA-rejected direct-unit DISSOLVE
treatment.

```text
cross-read: passed after explicit amendments C1-C7
implementation: authorized in slices I1-I8
positive integration: requires real grown semantic lineage plus one
  pre-provisioned distinct material root
production auto-continuation without fresh root: forbidden
promotion/generalization: forbidden
```

The next action is implementation slice I1, not another conceptual expansion.
