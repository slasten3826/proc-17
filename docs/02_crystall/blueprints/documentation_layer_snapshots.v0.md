# Documentation Layer Snapshots Blueprint v0

Status:

```text
crystall
date: 2026-07-20
source table: docs/01_table/yellowprints/documentation_layer_snapshots_truth_yellowprint.v0.md
work-layer source: docs/02_crystall/blueprints/work_layer_projection.v0.md
first authority: massless lineage-side observer
Packet mutation authority: forbidden
completion authority: forbidden
substrate calls: forbidden
amended 2026-07-21: F3 work_context separated from process_contract_id;
  F6 choice boundary mapping made unambiguous; F4 replaces failure-crystal
  capture with rejected-check/final-verdict/terminal-manifest boundaries
audit source: docs/00_chaos/fable_preimplementation_crystall_audit_raw_2026-07-21.md
F4 decision: docs/00_chaos/f4_rejected_generation_terminal_projection_notes_2026-07-21.md
2026-07-21 cross-table documentary gate: satisfied
```

## 0. Crystallized Claim

A documentation layer snapshot is an immutable, content-addressed historical
frame produced from one exact work-layer projection and one named material
boundary.

```text
work layer says what form the current work has
material boundary says what actually happened
snapshot preserves both without changing either
```

The recorder may runtime-confirm that it captured a frame. That act does not
upgrade semantic proposals, estimates, inherited applicability or document
decisions inside the frame.

## 1. Target Surface

New:

```text
runtime/documentation_snapshot.lua
tests/test_documentation_snapshot.lua
tests/test_documentation_snapshot_truth.lua
tests/test_documentation_snapshot_shadow.lua
```

Dependencies:

```text
runtime/work_layer.lua
runtime/completion_scope.lua
runtime/object_coverage.lua
runtime/corpse.lua
runtime/lineage.lua
core/digest.lua
core/json.lua
```

Later integration:

```text
runtime/lineage_runner.lua
runtime/documentation_contract.lua
runtime/documentation_corpus.lua
runtime/documentation_renderer.lua
```

The first implementation is an in-memory sidecar observer. It neither appends
to the Packet trace nor stores a mutable `last_snapshot` field.

## 2. Public API

```lua
local snapshot = require("runtime.documentation_snapshot")

snapshot.derive(subject_view, work_layer_projection, boundary, policy)
  -> candidate | nil, outcome

snapshot.verify(candidate, source_resolver, policy)
  -> verified_snapshot | nil, err

snapshot.same(left, right)
  -> boolean

snapshot.freshness(verified_snapshot, current_view)
  -> freshness_assessment | nil, err
```

Outcomes from `derive`:

```text
candidate                     exact qualified frame exists
unsupported_layer_projection known absence; no fabricated snapshot
unqualified_boundary         no named material boundary
out_of_scope                 profile/bound excludes capture
```

Malformed trusted records, hash conflicts and impossible ancestry return loud
errors. Known absence is not converted into an error or a fake empty snapshot.

## 3. Input Views

The module accepts detached bounded views, never a capability-bearing live
Packet object.

```lua
subject_view = {
  subject_kind = "packet" | "lineage",
  subject_ref = string,
  lineage_id = string,
  session_id = string,
  generation = integer | nil,
  packet_id = string | nil,
  stage_id = string | nil,
  process_contract_id = string,
  work_mode = "plan" | "build",
  work_context = "software_task.v0",
  trace_head_seq = integer | nil,
  ledger_head_seq = integer | nil,
  trace_events = bounded_detached_event[],
  ledger_events = bounded_detached_event[],
  object_records = bounded_detached_record[],
  terminal_ref = string | nil,
}

boundary = {
  kind = string,
  event_domain = "packet_trace" | "lineage_ledger",
  event_ref = string,
  event_seq = integer,
  occurred_at = number | nil,
  basis_refs = string[],
}
```

The caller must obtain the view through an existing read-only projection or a
frozen corpse/lineage record. Provider handles, repository grants, functions,
file descriptors and mutable field tables are invalid input.

`process_contract_id` and `work_context` are copied as separate identity fields
from the verified work-layer/contract view. The process-contract ref itself
remains in `basis_refs`; neither coordinate is reconstructed from the other.

## 4. Snapshot Envelope

```lua
{
  kind = "proc17_documentation_layer_snapshot",
  protocol_version = "documentation.layer_snapshot.v0",
  snapshot_id = "snapshot:<sha256>",

  subject_kind = "packet" | "lineage",
  subject_ref = string,
  lineage_id = string,
  session_id = string,
  generation = integer | nil,
  packet_id = string | nil,
  stage_id = string | nil,
  process_contract_id = string,
  work_mode = "plan" | "build",
  work_context = "software_task.v0",
  work_layer = "⋯" | "⊞" | "◈" | "▲",
  corpus_layer = "00_chaos" | "01_table" | "02_crystall" | "03_manifest",

  boundary_kind = string,
  boundary_event_domain = "packet_trace" | "lineage_ledger",
  captured_after_event_ref = string,
  captured_trace_seq = integer | nil,
  captured_ledger_seq = integer | nil,
  layer_projection_ref = string,
  basis_refs = string[],
  relevant_object_versions = table[],
  relevant_revisions = table,

  content = table,
  claims = documentation_claim[],
  completeness = {
    state = "complete" | "partial" | "truncated",
    omitted_count = integer,
    omitted_kinds = string[],
    truncation_reason = string | nil,
    missing_requirement_refs = string[],
    retained_content_digest = string,
  },
  redactions = documentation_redaction[],

  event_truth_status = "runtime_confirmed",
  content_truth_statuses = string[],
  captured_at = number | nil,
}
```

`snapshot_id` hashes the canonical encoding of every field except itself.
`captured_at` is copied from the qualified boundary event; the recorder's wall
clock is not part of the frame.

All arrays are bounded and canonicalized. Ordering is preserved where causally
meaningful and sorted where the source contract defines a set. Every retained
table is deep-copied before hashing and before return.

## 5. Claim Contract

```lua
{
  claim_id = "claim:<sha256>",
  subject = string,
  predicate = string,
  object = bounded_scalar_or_table,
  source_refs = string[],
  truth_status = string,
  applicability_status = string | nil,
  observed_at = {
    domain = "packet_trace" | "lineage_ledger",
    seq = integer,
  } | nil,
  basis_object_versions = table[],
  basis_revisions = table | nil,
}
```

`claim_id` hashes every field except itself.

Required laws:

```text
no claim without a resolvable source ref
no cross-generation source without explicit verified ancestry
no unbounded raw substrate response
capture confirmation does not promote content truth
historical claim cannot satisfy current completion without freshness
```

One snapshot may therefore contain both a runtime-confirmed candidate digest
and a semantic-proposal architecture explanation without flattening either.

## 6. Qualified Boundaries

A candidate exists only when both inputs are exact:

```text
verified runtime.work_layer_projection.v0
one boundary event admitted by this registry
```

| Boundary | Required evidence | Corpus layer |
|---|---|---|
| `root_request_registered` | root task/process contract/birth refs | `00_chaos` |
| `semantic_observation_materialized` | exact observation and materialized-unit refs | `00_chaos` |
| `structure_formation_current` | formation, identity-map and loss refs | `01_table` |
| `choice_committed` | alternatives, selected/killed partition and loss | `01_table` |
| `plan_crystallization_current` | exact plan candidate and coverage | `02_crystall` |
| `stage_manifested` | terminal plan result/corpse | `03_manifest` |
| `candidate_sealed` | exact artifact set, repository and seal | `03_manifest` |
| `qa_verdict_recorded` | exact seal and QA evidence | `03_manifest` |
| `qa_rejection_observed` | rejected required check refs; final verdict absent | `02_crystall` |
| `rejected_generation_terminal_ready` | final rejected verdict bound to current seal/check refs | `03_manifest` |
| `generation_terminal` | corpse, economics and residue | `03_manifest` |
| `root_completion_recorded` | verified lineage completion event | `03_manifest` |

The implementation must encode this registry as data with a validator, not as
free-form caller labels. A caller-supplied boundary kind without its required
refs returns `unqualified_boundary`.

`choice_committed` cannot select its own layer. It records the table of
alternatives and therefore maps to `01_table`. A later exact
`plan_crystallization_current` boundary is required for `02_crystall`, even
when both boundaries cite the same causal choice event.

## 7. Derivation Procedure

```text
1. verify the detached subject identity and bound
2. verify the work-layer projection and its causal relation to the subject
3. resolve the named boundary event in the declared journal and sequence
4. verify every required causal ref and explicit ancestor ref
5. select the corpus layer admitted by projection + boundary
6. collect only the record classes admitted for that layer
7. preserve each source truth/applicability status
8. apply bounds and redaction before identity calculation
9. derive completeness and exact omitted inventory
10. derive claims and per-object coverage
11. canonicalize, hash and deep-copy the candidate
12. independently verify the candidate before lineage-side recording
```

No step calls the substrate or writes into Packet/field/CALM/trace.

For a Packet subject, the projection and subject identities must match exactly.
For a lineage subject, the ledger boundary must explicitly reference the
historical terminal Packet projection it documents; same-lineage ancestry and
the exact ledger head are mandatory. A lineage event never receives a synthetic
Packet trace sequence.

## 8. Layer Content Contracts

### 8.1 `00_chaos`

May contain:

```text
root request and task boundary
bounded semantic observations
qualified unresolved pressure
inherited residue with applicability preserved
bounded legacy observations
open questions with their decision status
```

It must not claim an accepted implementation, complete legacy understanding or
current truth merely because an ancestor asserted it.

### 8.2 `01_table`

May contain:

```text
versioned requirement and artifact matrices
current relation map with endpoint versions
acceptance contract
exact alternative set
selected/killed partition and choice loss
writer/reader declarations
stage/generation plan
```

Confirmation of a one-member set is labelled confirmation, not choice and not
suppression loss.

### 8.3 `02_crystall`

May contain:

```text
selected blueprint and interface contracts
document-selected invariant set
artifact/file plan without write authority
declared capability boundary without private handles
QA contract
rejected-check evidence and final-verdict assembly state
```

Selected does not mean implemented. A rejected-check snapshot proves neither a
final verdict nor next-birth authority. The later terminal manifest and carrier
preserve exact facts while applicability to a descendant remains a proposal.

### 8.4 `03_manifest`

May contain:

```text
verified materialized artifact inventory
candidate seal
declared versus executed invocation evidence
QA run and exact verdict
economics with exact/estimated statuses
generation history and known limitations
completion assessment available at this causal boundary
```

A failed generation can have an honest manifest. Manifest is outward assembly,
not a synonym for successful root completion.

## 9. Work-Layer Mapping

| Mode/layer | Required current evidence | Snapshot contribution |
|---|---|---|
| `plan ⋯` | root request/unresolved pressure | `00_chaos` |
| `plan ⊞` | work structure/relations/alternatives | `01_table` |
| `plan ◈` | selected plan and acceptance contract | `02_crystall` |
| `plan ▲` | verified plan result and terminal stage candidate | `03_manifest` |
| `build ⋯` | fresh generation and whole candidate proposal/materialization evidence | `01_table` + `02_crystall` |
| `build ⊞` | sealed candidate and QA need/result | `03_manifest` |
| `build ◈` | rejected required check evidence exists and final verdict is absent | in-progress `02_crystall` |
| `build ▲` | accepted QA candidate, or final rejected QA verdict bound to exact current seal/checks | terminal-candidate `03_manifest` |

`stage`, `software_accepted` and `root_delivery` are lineage facts. They may be
captured by later lineage-bound snapshots but never rewrite the historical
Packet glyph.

## 10. Idempotence And Freshness

Idempotence law:

```text
same subject identity
+ same work-layer projection
+ same qualified boundary
+ same material refs/object versions/content
-> same snapshot_id
-> one stored object
```

Irrelevant trace narration does not change identity. A changed object version,
relation endpoint version, selected alternative, candidate digest, verdict or
generation does.

Snapshots are never updated. Freshness is a separate derived assessment:

```lua
{
  snapshot_id = string,
  status = "current" | "historical" | "superseded" | "unverifiable",
  changed_refs = string[],
  superseding_refs = string[],
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
}
```

Comparison priority:

```text
object id + version
relation id + endpoint versions
candidate/stage/generation identity
superseding verdict refs
global revisions only where object coverage is unavailable
```

Historical does not mean false; it means inadmissible as current evidence.

## 11. Completeness And Bounds

```text
complete  -> every required record in this bounded snapshot scope is present
partial   -> known required refs are absent or unresolved
truncated -> declared count/byte/source-expansion bound stopped retention
```

Partial and truncated snapshots remain exportable evidence. They cannot satisfy
a complete structured-corpus requirement. Missing and omitted records are
explicit; concise rendering may not hide them.

Bounds apply before hashing and return. Exceeding a bound never causes an
unbounded fallback.

## 12. Redaction

```lua
{
  redaction_id = "redaction:<sha256>",
  source_ref = string,
  path = string,
  reason = "secret" | "capability" | "host_path" | "scope" | "size_bound",
  removed_bytes = integer | nil,
  retained_digest = string | nil,
  event_truth_status = "runtime_confirmed",
}
```

Redaction changes snapshot identity and completeness metadata, not source
evidence. Private grants, handles and secrets are rejected or omitted before
canonical encoding. The implementation must not retain secret bytes merely to
prove their removal.

## 13. Writer And Reader Contract

| Record | Writer | First named reader | Authority |
|---|---|---|---|
| work-layer projection | pure `runtime.work_layer` | eligibility derivation | current form only |
| snapshot candidate | pure snapshot derivation | snapshot verifier | none |
| verified snapshot | lineage-side recorder | corpus assembler | historical only |
| claim/source map | snapshot derivation | verifier/cold reader | historical only |
| omission/redaction map | snapshot derivation | corpus completion reader | export scope only |
| freshness assessment | pure comparator | current-state consumer | admissibility only |
| human projection | later renderer | export validator | none |

The corpus assembler is the required internal reader of stored snapshots.

## 14. Observation Isolation

With snapshot observer off and on, the following Packet values must be byte- or
value-identical:

```text
walk and committed/executed edge ledger
Packet trace
field/CALM contents
revision vector
readiness and pressure inputs
Packet-local budget and loss
substrate calls made by body
candidate bytes/digest
status, death and residue
```

Snapshot derivation is massless with respect to the Packet, not economically
free. Its measured capture work may produce one lineage-scoped documentation
cost after the frame is frozen. Recording, validation, rendering and export may
produce further lineage-scoped documentation costs; none can flow backward into
the observed Packet.

## 15. Failure Law

| Failure | Class | Required behavior |
|---|---|---|
| unsupported projection | known absence | no snapshot |
| unqualified boundary | known absence | no snapshot |
| malformed body fact | world invariant failure | loud; no fabrication |
| missing source ref | provenance failure | partial or invalid per requirement |
| hash mismatch | integrity failure | reject |
| cross-lineage ref without ancestry | identity failure | reject |
| source exceeds bound | typed truncation | explicit omitted inventory |
| returned object aliases source | immutability failure | reject implementation |
| recorder mutates Packet | body invariant violation | reject implementation |
| renderer strengthens claim | projection failure | reject projection; preserve structured source |

Host exceptions are never translated into Packet death.

## 16. Permanent Controls

```text
S0 caller-supplied glyph cannot replace derived work layer
S1 semantic "complete" cannot create a boundary
S2 same causal basis yields same id and one stored object
S3 irrelevant trace narration leaves identity unchanged
S4 covered unit version change creates a new frame
S5 relation endpoint change creates a new table frame
S6 selected/killed partition change creates a new crystall frame
S7 candidate digest change invalidates old QA/currentness
S8 equal text in another generation remains distinct
S9 capture truth and content truth remain separate
S10 bounded omission is explicit and non-complete
S11 caller mutation cannot change stored snapshot
S12 observer off/on has exact Packet ablation
S13 rejected required check without final verdict is build ◈
S14 final rejected verdict over the same seal/check set is build ▲
S15 living Packet snapshot cannot claim software_accepted
S16 historical snapshot cannot satisfy current completion without freshness
S17 private capabilities never enter canonical content
S18 root-completion snapshot uses lineage_ledger sequence and no fabricated trace sequence
S19 same work_context under a different process_contract_id produces a distinct snapshot
S20 choice_committed maps only to 01_table; a separate crystallization boundary is required for 02_crystall
```

At least one fixture for each material class must be grown through real body or
lineage execution rather than constructed as a self-consistent synthetic table.

## 17. Implementation Sequence

```text
S0 canonical claim/redaction/snapshot validators
S1 pure derivation from one frozen grown plan fixture
S2 duplicate and mutation controls
S3 work-layer and boundary registry integration
S4 pure freshness assessment
S5 in-memory lineage-side recorder
S6 observer off/on ablation over plan and build lives
S7 content matrices for rejected and accepted build generations
S8 hand verified snapshots to corpus assembler
S9 add deterministic rendering only after structured storage is green
```

## 18. Promotion Gate

Snapshot recording may become a normal lineage observer only when:

```text
identity is deterministic and content-addressed
source refs, ancestry and truth statuses verify independently
duplicate capture is idempotent
all retained values are detached and bounded
off/on Packet ablation is exact
partial/truncated frames cannot satisfy complete requirements
living Packet scope cannot become lineage acceptance
the corpus assembler reads every stored snapshot class
```

No snapshot may contribute routing pressure or Packet completion in v0.

## 19. Deferred

```text
snapshot-driven routing
live TUI replay authority
rich media
substrate narration
`qa-check.v0` record schema and QA execution
cross-session snapshot search
persistent same-lineage resume
compost/aggregation
cryptographic signatures
```

The first executable proof is one already-supported plan/build life, captured
with the observer disabled and enabled, followed by exact life ablation.
