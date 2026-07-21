# Documentation Layer Snapshots And Truth Yellowprint v0

Status:

```text
table
date: 2026-07-20
source chaos:
  docs/00_chaos/self_documenting_lineage_corpus_notes_2026-07-20.md
  docs/00_chaos/nested_work_layer_runtime_integration_2026-07-20.md
amends the interpretation of:
  docs/01_table/yellowprints/nested_layer_glyphs_yellowprint.v0.md
scope:
  immutable documentation snapshots
  four-layer content
  source refs and truth preservation
  named writers/readers
production code change authorized: no
crystallization authorized: yes / completed by the sibling blueprint after the
  2026-07-21 cross-table audit
router authority change authorized: no
amended 2026-07-21: F3 work_context separated from process_contract_id;
  F6 choice boundary mapping made unambiguous; F4 removes the standalone
  failure crystal and records rejected-verdict/terminal-manifest boundaries
audit source: docs/00_chaos/fable_preimplementation_crystall_audit_raw_2026-07-21.md
F4 decision: docs/00_chaos/f4_rejected_generation_terminal_projection_notes_2026-07-21.md
```

Sibling tables:

```text
documentation_profiles_economy_yellowprint.v0.md
documentation_corpus_assembly_reentry_yellowprint.v0.md
nested_work_layer_derivation_yellowprint.v0.md
completion_scope_candidate_seal_yellowprint.v0.md
stage_transition_generation_recovery_yellowprint.v0.md
```

## 0. Table Decision

The portable four-layer corpus is assembled from immutable historical
snapshots of the real lineage process.

```text
living Packet facts
  -> pure evidence-derived work-layer projection
  -> immutable bounded snapshot at a qualified boundary
  -> structured corpus assembly
  -> optional human projection
```

A snapshot proves:

```text
the body observed this bounded evidence at this historical boundary
```

It does not prove:

```text
the evidence is still current
every semantic claim is true
the layer label commands the next route
the final project was already known
```

## 1. Fixed Decisions

```text
S0  current work layer is derived from living facts, never caller-written
S1  snapshot capture is an observation of a derived layer, not layer authority
S2  snapshots are immutable deep copies with content-derived identity
S3  Packet-local mutable state is never stored by reference
S4  event truth and content truth remain separate
S5  truth status is preserved per claim/source, not flattened per document
S6  historical freshness is bounded by captured revisions and event sequence
S7  a stale snapshot remains honest history but cannot prove current completion
S8  structured snapshots are bounded and report every omission/truncation
S9  full prose is rendered from structured snapshots, never accepted as source
S10 one layer may have multiple snapshots across stages and generations
S11 duplicate capture of the same causal basis is idempotent
S12 snapshot emission does not create Packet pressure in v0
S13 snapshot emission does not consume Packet loss
S14 structured snapshot capture requires no substrate call
S15 build ◈ records exact rejected check evidence while the final verdict is pending; that final verdict advances the Packet boundary to build ▲
S16 rejected and accepted generations never share candidate evidence identities
S17 documentation directory names do not replace ProcessLang layer physics
S18 every stored snapshot and projection has a named reader
```

## 2. Vocabulary Separation

The repository already uses related words at several levels. This table keeps
them distinct.

| Term | Meaning | Authority |
|---|---|---|
| Packet `chaos` area | living Packet area before/around structured formation | Packet body |
| L1 CHAOS | lower ProcessLang/packet layer physics | current body/canon contracts |
| corpus `00_chaos` | external historical projection of early pressure/evidence | documentation export |
| work layer `⋯` | derived current process form in one mode/context | future work-layer inspector |
| snapshot | immutable historical frame of bounded evidence | capture event only |
| table/yellowprint | structured decision surface | document decision until implemented |
| crystall/blueprint | selected implementation contract | document decision until runtime evidence |
| manifest | assembled outward result/evidence | △ under exact completion law |

Similarity is intentional. Identity is not.

## 3. Base Snapshot Envelope

Candidate schema:

```lua
{
  kind = "proc17_documentation_layer_snapshot",
  protocol_version = "documentation.layer_snapshot.v0",
  snapshot_id = sha256,
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
  relevant_revisions = table,
  content = table,
  claims = documentation_claim[],
  completeness = {
    state = "complete" | "partial" | "truncated",
    omitted_count = integer,
    omitted_kinds = string[],
    truncation_reason = string | nil,
  },
  redactions = documentation_redaction[],
  event_truth_status = "runtime_confirmed",
  content_truth_statuses = string[],
  captured_at = number,
}
```

This is a table candidate. Field names may change at crystallization.

`process_contract_id` and `work_context` are independent identity coordinates.
The first selects the exact process contract; the second names the semantic
derivation domain. Neither may be reconstructed from the other.

Identity law:

```text
snapshot_id = SHA-256(canonical encoding of every identity field except itself)
```

The identity projection includes content, claims, omissions, redactions,
revisions and causal refs. Two visually similar snapshots with different
evidence cannot share an identity.

`captured_at` is copied from the qualified boundary event (or omitted from a
future identity projection); it is never the recorder's fresh wall-clock time.
Otherwise two captures of one causal basis would violate idempotence merely
because the recorder ran twice.

## 4. Claim Shape

Candidate claim:

```lua
{
  claim_id = sha256,
  subject = string,
  predicate = string,
  object = bounded scalar | bounded structured value,
  source_refs = string[],
  truth_status = string,
  applicability_status = string | nil,
  observed_at = {
    domain = "packet_trace" | "lineage_ledger",
    seq = integer,
  } | nil,
  basis_revisions = table | nil,
}
```

Required rules:

```text
no claim without a source ref
no source ref outside the captured lineage/generation without explicit ancestry
no runtime_confirmed content merely because capture was runtime-confirmed
no current-completion reader may consume a historical claim without freshness
no unbounded raw substrate response inside a claim
```

The snapshot event can be `runtime_confirmed` while its content includes
`semantic_proposal`, `estimated`, inherited applicability or document decisions.

## 5. Qualified Capture Boundary

Snapshots are not emitted on every tick. A capture candidate exists only when
the body can derive both:

```text
a current work-layer projection
a named material boundary for that layer
```

Candidate boundaries:

| Boundary kind | Required causal evidence | Typical corpus layer |
|---|---|---|
| `root_request_registered` | root task and birth evidence | `00_chaos` |
| `semantic_observation_materialized` | bounded source response/observation refs | `00_chaos` |
| `structure_formation_current` | exact formation, identity map, loss refs | `01_table` |
| `choice_committed` | exact alternatives, selected/killed partition, loss | `01_table` |
| `plan_crystallization_current` | exact plan candidate and current coverage | `02_crystall` |
| `stage_manifested` | verified stage output/corpse | `03_manifest` |
| `candidate_sealed` | complete artifact set and digest | `03_manifest` |
| `qa_verdict_recorded` | exact candidate identity and QA evidence | `03_manifest` |
| `qa_rejection_observed` | exact rejected required check refs; final verdict absent | `02_crystall` |
| `rejected_generation_terminal_ready` | final rejected verdict bound to exact seal/check refs | `03_manifest` |
| `generation_terminal` | corpse, economics, residue | `03_manifest` |
| `root_completion_recorded` | exact accepted generation and completion assessment | `03_manifest` |

The boundary list is not code authority. It gives the later crystall a bounded
surface to prove.

`choice_committed` always captures the structured alternative set and its
selected/killed partition, so its v0 destination is `01_table`. If that choice
later supports a selected plan blueprint, a separate
`plan_crystallization_current` boundary captures `02_crystall`. A caller cannot
choose the destination layer by label.

## 6. Capture Idempotence

Snapshot production follows the existing stamp family:

```text
logic stamp     -> one judgment for one current evidence basis
camera watermark -> one reconciliation for one frame head
probe stamp     -> one relation probe for one current object domain
snapshot id     -> one documentation frame for one exact causal basis
```

Duplicate law:

```text
same lineage/generation/packet
same boundary kind
same layer projection
same basis refs/revisions/content
  -> same snapshot_id
  -> no second stored snapshot
```

Changed irrelevant trace narration must not produce a new snapshot. Changed
material object version, selected alternative, candidate digest, QA verdict or
generation identity must produce a different snapshot.

The first implementation should derive duplicate identity from immutable trace
and snapshot records rather than maintain a second mutable `last_snapshot`
truth store.

## 7. Historical Freshness

A snapshot is never "updated".

```text
snapshot at seq 17 remains a true record of what was captured after seq 17
later mutation makes it stale for current-state claims
later mutation does not make the historical capture false
```

Freshness comparison candidate:

```text
claim object id/version still current
candidate digest still current
stage/generation identity still active or terminally selected
relevant revisions equal where object-version coverage is unavailable
no later superseding verdict exists in the same scope
```

Per-object versions take precedence over global revision axes. This avoids the
old recurrent-pressure and under-sensitive-coverage defects.

## 8. `00_chaos` Content Matrix

| Record class | Required source | Truth handling | Must not claim |
|---|---|---|---|
| root request | exact root task payload/digest | declared/observed input | accepted implementation |
| task boundary | explicit process contract | document/runtime configuration | substrate-selected authority |
| semantic observation | exact ☴ response/unit refs | preserve semantic status | observed runtime behavior |
| unresolved pressure | qualified witness refs | derived act + basis statuses | final defect |
| inherited residue | corpse/carrier/grave refs | inherited applicability remains typed | current truth by inheritance |
| legacy observation | read-only capability/effect refs | runtime-confirmed only for what was read/run | complete legacy understanding |
| open question | decision/snapshot source | document decision/open law | missing implementation fact |

Required properties:

```text
early uncertainty survives
later success does not rewrite original pressure
raw input is bounded or content-addressed
secret/redacted regions remain visibly omitted
```

## 9. `01_table` Content Matrix

| Record class | Required source | Identity/freshness | Must not do |
|---|---|---|---|
| requirement matrix | exact task/formation refs | versioned requirements | infer completion |
| artifact inventory | exact structured work units | unit id + version | treat alternatives as required siblings |
| relation map | current relation objects/endpoints | relation and endpoint versions | synthesize unsupported edges silently |
| acceptance matrix | root/plan contract refs | contract digest | let candidate define all its own acceptance |
| alternative set | exact choice set | member ids/versions | omit killed alternatives |
| selected/killed partition | exact ☳ event and loss | choice id + post-choice versions | call confirmation a real choice |
| writer/reader map | registry/contract declarations | declaration revision | call declaration enforcement |
| stage/generation plan | lineage/process contract | stage id/generation scope | create a child directly |

Table output is structured enough for another machine to rebuild the work
shape. Prose alone does not satisfy the structured profile.

## 10. `02_crystall` Content Matrix

| Record class | Required source | Truth handling | Must not do |
|---|---|---|---|
| selected blueprint | exact accepted plan candidate | semantic content + runtime-confirmed selection | call blueprint implemented |
| interface contract | blueprint/requirement refs | preserve source status | invent runtime compatibility |
| invariant set | process/body contract refs | document decision until enforced | claim tests prove undeclared invariants |
| artifact/file plan | exact build candidate proposal | versioned structured refs | authorize writes |
| capability boundary | trusted grant/policy declarations | configuration/runtime grant status | export usable private grants |
| QA contract | root/plan acceptance refs | independent contract identity | bind only to candidate self-report |
| rejected-verdict assembly | rejected check evidence + exact seal/QA contract | mechanical evidence preserved; assembly status confirmed | encode patch instructions as authority |
| inherited next-birth constraint | rejected-generation manifest/carrier refs | applicability remains proposal until consumed | mutate dead generation |

Build `◈` correction:

```text
old archaeology: fix concrete bad noise through a targeted patch
current contract: crystallize current rejected check evidence into one final
  immutable QA verdict; the later descendant may derive next-birth constraints
```

The old `nested_layer_glyphs_yellowprint.v0` remains historical evidence. Its
in-place patch interpretation is superseded for the primary proc-17 product
path by the immutable-generation chaos amendment and this table.

## 11. `03_manifest` Content Matrix

| Record class | Required source | Truth handling | Must not do |
|---|---|---|---|
| materialized artifact inventory | provider receipt + independent verification | runtime-confirmed event; content status preserved | trust intended bytes without read-back |
| candidate seal | exact artifact set/digests/repository identity | runtime-confirmed | include later mutations |
| invocation instructions | declared/runtime evidence | distinguish proposed from executed | claim a command ran if not executed |
| QA run | bounded capability effect | runtime-confirmed execution + output refs | hide non-zero exit |
| QA verdict | ☶/☱ exact validation chain | runtime-confirmed derivation | apply to wrong candidate digest |
| budget/time/token report | economics events | exact/estimated per source | flatten estimate to fact |
| generation history | lineage ledger/corpses/carriers | runtime-confirmed lineage events | merge identities |
| known limitations | residue/open refs | preserve status | rewrite as completed work |
| completion assessment/verdict available at boundary | exact completion/lineage event refs | runtime-confirmed derivation | accept semantic `done` or invent a future final event |

`03_manifest` can contain a failed generation manifest. A manifest is an honest
outward assembly, not synonymous with successful root completion.

For required lineage-side documentation, the corpus export receipt is itself an
input to final root completion. The pre-completion corpus therefore contains the
software/task completion assessment available at its frozen ledger head, while
an outer delivery envelope names the later final root-completion event, corpus
and receipt. A later optional corpus revision may include that final event. No
snapshot may claim a causally future event merely to look self-contained.

## 12. Plan/Build Snapshot Matrix

| Mode/layer | Minimum current evidence | Export contribution |
|---|---|---|
| `plan ⋯` | root request plus unresolved semantic pressure | `00_chaos` |
| `plan ⊞` | exact work structure/relations/alternatives | `01_table` |
| `plan ◈` | selected exact plan candidate and acceptance contract | `02_crystall` |
| `plan ▲` | verified `plan.result.v0` and Packet terminal stage candidate | `03_manifest` Packet/stage-candidate record |
| `build ⋯` | fresh generation and whole candidate proposal/materialization evidence | `01_table` + `02_crystall` |
| `build ⊞` | sealed candidate and current QA evidence need/result | `03_manifest` QA record |
| `build ◈` | current required check rejection exists while the final rejected verdict is absent | `02_crystall` in-progress verdict record |
| `build ▲` | accepted QA with a software-acceptance candidate, or a final rejected QA verdict bound to the current seal/checks | `03_manifest` terminal-candidate / rejected-generation record |

One Packet life need not invoke the substrate four times. Body-owned
transformations may produce multiple qualified boundaries from one semantic
current.

`stage`, `software_accepted` and `root_delivery` are later lineage facts. They
may be documented beside the historical Packet snapshot, but they never change
the glyph that the dead Packet derived from its own evidence.

## 13. Snapshot Completeness

Completeness is local to the declared snapshot scope.

```text
complete  -> every required record in this bounded scope is present
partial   -> known required records are absent/unresolved
truncated -> body intentionally omitted records because a declared bound ended
```

Required fields for non-complete snapshots:

```text
omitted_count
omitted_kinds
truncation_reason or missing requirement refs
content digest of retained material
```

Rules:

```text
partial/truncated snapshot may be exported
partial/truncated snapshot cannot satisfy a complete corpus requirement
later complete snapshot does not erase earlier loss
renderer must display incomplete state
```

## 14. Redaction Shape

Candidate redaction record:

```lua
{
  redaction_id = sha256,
  source_ref = string,
  path = string,
  reason = "secret" | "capability" | "host_path" | "scope" | "size_bound",
  removed_bytes = integer | nil,
  retained_digest = sha256 | nil,
  event_truth_status = "runtime_confirmed",
}
```

Redaction changes the export snapshot identity and completeness metadata. It
does not mutate the source evidence. Secrets are not retained merely to prove
that they were redacted.

## 15. Snapshot Writer And Reader Matrix

| Record | Writer | First named reader | Current-state authority |
|---|---|---|---|
| work-layer projection | pure future inspector | snapshot eligibility and pressure diagnostics | re-derived only |
| snapshot candidate | pure snapshot builder | snapshot validator | none |
| immutable snapshot | trusted lineage-side recorder after validation | corpus assembler | historical only |
| claim/source map | snapshot builder | export validator/renderer | historical only |
| completeness/omission record | snapshot builder | corpus completion reader | only for declared export scope |
| redaction record | export boundary | export validator and external reader | export-only |
| human projection | deterministic renderer or bounded substrate | export validator | none |

External humans/machines are named consumers of the final corpus. Inside the
body, the corpus assembler is the named reader that prevents snapshots from
becoming write-only storage.

## 16. Observation Isolation

The first implementation must be shadow/observer-only and use lineage-side
placement.

Required properties:

```text
capture does not append Packet field units
capture does not advance Packet revisions
capture does not alter candidate choice
capture does not create loss
capture does not alter readiness or committed route
capture does not call substrate
capture deep-copies all retained content
```

Lineage-side export costs may be recorded after capture. Those costs are real
economics, but the observer itself cannot influence the Packet route whose life
it is documenting.

## 17. Snapshot Matched Controls

| ID | One changed variable | Required result |
|---|---|---|
| S0 | caller supplies glyph ▲ | ignored/rejected; derived layer unchanged |
| S1 | substrate writes "crystall complete" | content proposal only; no boundary by assertion |
| S2 | same causal basis captured twice | same id, one stored snapshot |
| S3 | irrelevant trace narration appended | same material snapshot identity |
| S4 | one covered unit version changes | new snapshot or stale prior frame |
| S5 | one relation endpoint version changes | new table snapshot; old frame historical |
| S6 | selected alternative changes | new crystall identity and killed partition |
| S7 | candidate digest changes | new manifest snapshot; QA refs cannot cross |
| S8 | generation changes with same semantic text | distinct snapshot identity |
| S9 | event capture confirmed, content semantic | statuses remain separate |
| S10 | bound truncates one source | state truncated with omitted_count=1 |
| S11 | snapshot return object mutated by caller | stored snapshot unchanged |
| S12 | snapshot observer enabled/disabled | same Packet route/loss/candidate |
| S13 | one choice later produces a plan crystal | choice snapshot remains `01_table`; separate crystall boundary records `02_crystall` |

## 18. Layer Content Controls

| ID | Grown condition | Required result |
|---|---|---|
| L0 | root task only | bounded `00_chaos` snapshot, no table/crystall claim |
| L1 | exact formation with two required artifacts | table lists both; no killed alternatives |
| L2 | exact alternative choice | selected and killed members plus choice loss recorded |
| L3 | one-member confirmation | labelled confirmation, not suppression choice |
| L4 | plan blueprint selected but not built | crystall says selected, not implemented |
| L5 | candidate sealed but untested | manifest says materialized; QA missing |
| L6 | QA accepted for exact digest | accepted verdict bound to that digest |
| L7 | QA accepted for ancestor digest | cannot satisfy current generation |
| L8 | exact rejected required check, final verdict absent | build ◈ verdict-assembly snapshot; no patch authority |
| L8a | same check set plus exact final rejected verdict | build ▲ rejected-generation terminal candidate |
| L9 | generation 2 succeeds after generation 1 fails | both identities and causal terminal projection preserved |
| L10 | legacy source partially observed | unknown behavior remains explicit |

## 19. Truth Controls

| ID | Condition | Required result |
|---|---|---|
| T0 | substrate architecture proposal | `semantic_proposal` content |
| T1 | body selected proposal | selection event confirmed; proposal content status unchanged |
| T2 | provider read-back digest | runtime-confirmed digest event |
| T3 | locally estimated tokens | estimated |
| T4 | inherited grave warning | death fact confirmed; applicability inherited/grave pressure |
| T5 | document-selected invariant not enforced | document decision, not runtime-confirmed law |
| T6 | Markdown paraphrase stronger than source | validator rejects or marks unsupported |
| T7 | source ref absent/tampered | snapshot invalid/partial, never complete |

## 20. False-Green Matrix

| False green | Rejecting rule/control |
|---|---|
| layer label stored as mutable truth | S0/S1 + S0 fixed decision |
| final history written retrospectively | qualified capture boundaries |
| capture event status upgrades all content | S4/S5 + T0-T5 |
| stale snapshot proves current completion | historical freshness + S4-S8 |
| same text across generations collapses identity | S8 |
| omitted records hidden by concise Markdown | completeness law + S10 |
| blueprint called implemented | L4 |
| materialized candidate called tested | L5 |
| QA evidence crosses candidate digest | L6/L7 |
| rejected candidate receives patch authority | S15 + L8 |
| returned table shares mutable references | S11 |
| documentation observer changes route | S12 |
| generated prose becomes structured source | S9/T6 |

## 21. Failure Classification

| Failure | Classification | Consequence |
|---|---|---|
| malformed living Packet fact | body/world invariant failure | loud; no snapshot fabrication |
| unsupported layer projection | known absence/open law | no snapshot for that boundary |
| missing source ref | provenance failure | invalid or partial snapshot |
| digest mismatch | integrity failure | reject snapshot/export |
| source scope exceeds bound | known truncation | bounded truncated snapshot |
| renderer cannot express claim | projection failure | structured source preserved; human output partial |
| snapshot write fails | export capability failure | status handled by profile table |
| snapshot mutates Packet | body invariant violation | reject implementation |

No malformed trusted state is converted into a beautiful partial document.
Known bounded omission is partial; corrupted evidence is loud.

## 22. Non-Goals

This table does not define:

```text
the final filesystem path
the complete corpus index schema
how △ schedules assembly
NETWORK@▽ ingestion
retention or compost
human prose templates
semantic quality scoring
work-layer production code
QA capability implementation
`qa-check.v0` record schema
candidate-seal implementation
```

It also does not authorize a persistent mutable snapshot cache.

## 23. Crystallization Gate

Before crystallization, the three tables must agree on:

```text
snapshot identity and canonical encoding owner
capture hook and observer isolation
which boundaries exist before work-layer code exists
which records are mandatory for structured completion
how snapshots enter the lineage corpus without Packet mutation
how redaction and bounds affect completeness
```

Gate result, 2026-07-21:

```text
snapshot envelope and corpus object identity agree
capture remains a massless lineage-side observer
qa_rejection_observed and rejected_generation_terminal_ready are distinct boundaries
qa-check.v0 remains explicitly deferred with QA execution
cross-table crystallization gate satisfied
production implementation authority remains limited by each blueprint
```

The first executable proof should use a grown, already supported plan/build life
and emit snapshots in shadow. It must compare the full life with the observer
disabled and enabled before any snapshot contributes pressure or completion.
