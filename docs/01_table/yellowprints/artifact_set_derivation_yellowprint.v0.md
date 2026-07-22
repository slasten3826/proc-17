# Artifact Set Derivation Yellowprint v0

Status:

```text
layer: table (⊞)
date: 2026-07-22
scope: body-owned derivation of one exact build candidate declaration
runtime implementation authorized: no
candidate seal implementation authorized: no
QA execution authorized: no
router promotion authorized: no
crystallization authorized: yes, by 2026-07-22 documentary gate
gate record:
  docs/00_chaos/candidate_seal_table_cross_audit_2026-07-22.md
crystallized as:
  docs/02_crystall/blueprints/artifact_set_derivation.v0.md
```

Primary chaos source:

[`../../00_chaos/candidate_seal_runtime_boundary_notes_2026-07-21.md`](../../00_chaos/candidate_seal_runtime_boundary_notes_2026-07-21.md)

Companion TABLE contracts:

```text
repository_candidate_lifecycle_yellowprint.v0.md
candidate_seal_transaction_yellowprint.v0.md
completion_scope_candidate_seal_yellowprint.v0.md
stage_transition_generation_recovery_yellowprint.v0.md
capability_safe_repository_hands_yellowprint.v0.md
```

This table refines the declaration side of
`completion_scope_candidate_seal_yellowprint.v0.md` §§3, 5, 8 and controls
C01-C06. It does not alter completion-scope ownership outside artifact-set
derivation.

## 0. Selected Decisions

```text
A01 the artifact-set declaration is a pure deterministic body derivation
A02 no caller, substrate or harness may supply the authoritative member list
A03 one runtime-confirmed Packet birth contract is the coordinate root
A04 build derivation requires one non-empty birth-bound repository_id
A05 v0 accepts exactly one current structure formation for repository artifacts
A06 several current repository formations are ambiguity, never an implicit merge
A07 live units enter directly; selected units require exact choice evidence
A08 suppressed, dissolved, stale and foreign-generation units never enter
A09 each declared member binds unit id/version, path, kind and provenance
A10 declaration truth confirms shape and provenance, not semantic sufficiency
A11 deterministic order and normalized records own artifact_set_id
A12 declaration has no independent event or mutable storage surface
A13 the candidate-seal request preserves the exact derived declaration
A14 inspection and completion remain separate from declaration
A15 stageful-v1 may add a stage-ledger ref; v0 birth evidence is sufficient
A16 no failure in derivation creates write authority or Packet success
```

## 1. Closed Physical Claim

This table defines one claim:

```text
Given one living build Packet, the body can derive exactly one detached
repository.artifact_set_contract.v0 containing all and only the current
generation's repository artifacts that belong to one exact current formation.
```

It does not prove:

```text
all declared artifacts are materialized
the files on disk match the declaration
the declared software is sufficient or correct
source-write authority is closed
the candidate is sealed
QA passed
```

Those are named readers and later boundaries.

## 2. Authority Chain

| Fact | Authority owner | Evidence | First named reader |
|---|---|---|---|
| process/work coordinates | Packet birth writer | runtime-confirmed birth event | artifact-set derivation |
| current repository identity | Packet birth + immutable Packet coordinate | exact non-empty equality | artifact-set derivation |
| structure membership | ENCODE formation event + current field | exact event/unit join | artifact-set derivation |
| selected alternative | CHOOSE event + current activation/version | exact choice join | artifact-set derivation |
| normalized path/kind | strict repository carrier parser | current unit carrier | declaration normalizer |
| declaration identity | pure body derivation | normalized digest | artifact-set inspector and seal planner |
| work completion | ☱ dedicated completion writer | effect/verification chain | artifact-set inspector |
| final filesystem bytes | trusted inventory provider | bounded stable inventory | candidate-seal verifier |

The substrate is absent from every authority-writer column. It may have
proposed artifact meaning. It cannot decide which proposal fragments become
the authoritative candidate declaration.

## 3. Birth Coordinate Gate

Derivation starts from the immutable first trace event, not from options passed
to the derivation call.

Required birth evidence:

```text
event.type = birth
event.truth_status = runtime_confirmed
payload.packet_id = instance.id
payload.lineage_id = instance.lineage_id
payload.generation = instance.generation
payload.work_mode = build
payload.process_contract_id is compatible with build
payload.context = software_task.v0
payload.stage_id = instance.stage_id and is non-empty
payload.repository_id = instance.repository_id and is non-empty
```

Any disagreement is an invariant/contract failure. A build Packet with no
repository identity may still exist for compatibility, but it cannot derive an
artifact set and therefore cannot begin candidate sealing.

The birth event ref is part of declaration identity and provenance.

## 4. Exact Formation Gate

### 4.1 Candidate unit domain

The derivation scans the current Packet field in canonical `unit_order` and
considers a unit only when all conditions hold:

```text
unit.generation = Packet generation
unit.activation = live | selected
unit.kind = structured_item
unit.carrier.kind = repository.create_text_file.v0
unit id/version and creation event are exact current values
```

Suppressed, dissolved and foreign-generation repository units remain visible
to diagnostics but are excluded from declaration membership.

### 4.2 Formation proof

For every candidate unit the body must find exactly one current
`structure_formation` event that:

```text
was written by the authorized ENCODE path
names that exact unit id and formation-time version
belongs to the current Packet and generation
binds the source observation/formation envelope
has not been superseded for the unit's current version
```

All declared repository units must resolve to the same formation event in v0.

| Current evidence | Derivation outcome |
|---|---|
| no repository unit | not ready: `repository_artifact_set_absent` |
| one exact formation, one or more required units | continue |
| one unit lacks exact formation | reject derivation |
| two current formations contribute repository units | typed ambiguity; no merge |
| formation belongs to another generation | reject derivation |
| compatibility shadow map without formation event | reject derivation |

The one-formation rule is a bounded v0 policy, not a metaphysical claim that
software can only be designed in one thought. Multi-formation candidate
assembly requires its own future composition contract.

### 4.3 Choice proof

An `artifact_set` formation normally represents several required artifacts and
does not invoke CHOOSE.

If any included unit is `selected`, derivation additionally requires one exact
current choice event proving:

```text
the choice set is the same formation
the selected unit/version is the surviving alternative
the other alternatives are suppressed
the choice event belongs to the current Packet/generation
```

Selected state without that witness is not declaration evidence. Suppressed
alternatives never re-enter through caller-supplied paths or refs.

## 5. Target Declaration Contract

The target v0 declaration refines the already implemented shadow schema:

```lua
{
  protocol_version = "repository.artifact_set_contract.v0",
  artifact_set_id = "artifact-set:<sha256>",

  packet_id = string,
  lineage_id = string,
  generation = integer,
  process_contract_id = string,
  context = "software_task.v0",
  stage_id = string,
  repository_id = string,

  birth_ref = "trace:...",
  formation_event_ref = "trace:...",
  choice_event_ref = "trace:..." | nil,

  artifacts = {
    {
      work_unit_id = string,
      work_unit_version = integer,
      unit_created_event_ref = "trace:...",
      relative_path = string,
      expected_kind = "regular_file",
      provenance_refs = string[],
    },
  },

  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "semantic_proposal" | "mixed",
}
```

`source_refs` is the canonical sorted union of the named birth, formation,
choice, unit-creation and bounded source-provenance refs. Named fields remain
mandatory; a generic source-ref bag cannot impersonate a formation or choice
witness.

The schema amendment must occur in CRYSTALL before implementation changes the
existing `runtime/artifact_set.lua` protocol validator.

## 6. Canonical Derivation

Conceptual API:

```lua
artifact_set.derive(instance) -> detached_contract | nil, diagnostic
```

No authoritative member list or process coordinate is accepted as an input.

Deterministic order:

```text
1. verify immutable birth coordinates
2. scan current field unit_order
3. collect eligible repository units
4. prove one exact formation and optional exact choice
5. normalize every relative path with repository path policy
6. reject duplicate work ids and duplicate paths
7. sort artifacts by relative_path, then work_unit_id
8. sort/deduplicate bounded provenance refs
9. preserve the least-strong content truth status
10. digest the normalized record excluding artifact_set_id
11. return a deep detached copy
```

The derivation writes no trace event, field state, CALM state, completion
record or registry state. Repeating it against unchanged evidence returns the
same bytes and identity.

## 7. Derive, Validate And Inspect Stay Separate

| Operation | Question | May select members? | May write state? |
|---|---|---:|---:|
| `derive(instance)` | What exact set does the body currently declare? | body evidence only | no |
| `validate(contract)` | Is this detached record well formed and self-identical? | no | no |
| `inspect(instance, contract)` | Are all exact declared versions currently complete? | no | no |
| seal prepare | Does current completion plus lifecycle permit sealing? | no | no |
| seal commit | Did closure and final inventory prove this exact set? | no | yes, later boundary |

`validate` does not make a caller-supplied declaration authoritative.
Irreversible seal preparation must re-derive the current contract and require
exact equality with any detached contract presented as an assertion.

## 8. Freshness And Staleness

Freshness is per object, not a global field revision.

The declaration binds:

```text
formation event identity
choice event identity when present
each unit id and exact version
each unit creation event
Packet generation and repository identity
```

An unrelated field mutation does not stale the set. A current declared unit
version change, activation change, formation replacement, choice replacement
or repository-coordinate change does.

Inspection must cite the exact current work-completion and verification refs
for the same unit versions. Old-version completion remains historical evidence
but cannot satisfy the current declaration.

## 9. Failure Classification

| Condition | Class | Consequence |
|---|---|---|
| build repository_id absent | typed not-ready/unsupported v0 | no declaration |
| no current repository units | typed absence | no declaration |
| malformed semantic carrier/path | semantic material rejection | no hand or seal authority |
| exact unit missing formation witness | evidence incomplete | no declaration |
| several current formations | typed ambiguity | no merge, no declaration |
| selected unit lacks choice witness | evidence incomplete | no declaration |
| duplicate path/work id | contract conflict | no declaration |
| stale/foreign unit | evidence conflict | exclude/reject exact claim |
| malformed trusted field/event structure | runtime invariant | fail loudly |
| substrate claims a complete set | semantic proposal only | zero authority delta |

Derivation failure is not candidate quarantine because no seal lifecycle
transition has begun.

## 10. Truth Matrix

| Claim | Truth status |
|---|---|
| birth coordinates agree | `runtime_confirmed` |
| formation/choice refs and unit versions agree | `runtime_confirmed` |
| path normalization and set identity | `runtime_confirmed` act |
| artifact content originated from substrate | preserved `semantic_proposal` or `mixed` |
| declared files are sufficient software | not established |
| declared files exist exactly on disk | not established by derivation |
| candidate is sealed | not established by derivation |

## 11. Named Writers And Readers

| Record/view | Writer | Reader |
|---|---|---|
| Packet birth contract | Packet birth body writer | artifact-set derivation |
| structure formation | ENCODE body writer | artifact-set derivation |
| choice event | CHOOSE body writer | artifact-set derivation when selected |
| current field units | field/body mutation contracts | artifact-set derivation and inspection |
| artifact-set declaration | pure derivation, no stored writer | inspector and seal planner |
| work completion | ☱ completion writer | artifact-set inspector |
| declaration snapshot in seal request/event | future seal planner/body writer | closure verifier, QA, corpus |

There is no standalone declaration event without a named need.

## 12. Permanent Controls

| ID | Control | Expected result |
|---|---|---|
| AS01 | one exact repository formation | one deterministic declaration |
| AS02 | repeat unchanged derivation | byte-identical contract/id |
| AS03 | caller removes one unit from detached copy | re-derive mismatch; cannot seal |
| AS04 | caller adds foreign unit | validation/re-derive mismatch |
| AS05 | two current repository formations | typed ambiguity; no merge |
| AS06 | one unit lacks formation witness | no declaration |
| AS07 | selected unit with exact choice | included with choice ref |
| AS08 | selected unit without choice | no declaration |
| AS09 | suppressed alternative | excluded |
| AS10 | foreign generation unit | excluded and cannot satisfy set |
| AS11 | declared unit version changes | old declaration stale |
| AS12 | unrelated object changes | declaration remains exact |
| AS13 | duplicate normalized path | rejected |
| AS14 | duplicate work id | rejected |
| AS15 | repository_id absent | no declaration |
| AS16 | repository_id differs from birth | loud contract divergence |
| AS17 | mutate returned declaration | Packet/next derivation unchanged |
| AS18 | substrate outputs artifact_set_id | no authority delta |
| AS19 | all members complete but set semantically insufficient | set may complete; QA still required |
| AS20 | hand-disabled observer ablation | route, loss and Packet mutations identical |

Death fixtures are not needed for this pure derivation table. Formation and
choice fixtures must be grown through their real organs rather than assembled
as synthetic event tables.

## 13. CRYSTALL Consequences

The later CRYSTALL round must amend:

```text
candidate_seal.v0 §3 artifact-set API/schema
completion_scope.v0 artifact-set input contract
work_layer_projection.v0 source refs only where its reader changes
capability_safe_repository_hands.v0 only where formation evidence is shared
```

It must decide whether formation lookup becomes a shared pure helper or is
implemented independently with matched controls. It may not duplicate mutable
formation truth.

## 14. Explicit Deferrals

```text
multi-formation candidate composition
imported/pre-existing artifact declaration
stage-ledger v1 ref
semantic judgment of artifact sufficiency
candidate seal implementation
QA execution
fresh repository allocation
router promotion
```

## 15. Table Thesis

```text
The body may seal only the candidate it can derive from its own current causal
history. A convenient list supplied at the sealing boundary is not a candidate;
it is an attempt to choose evidence after seeing the result.
```
