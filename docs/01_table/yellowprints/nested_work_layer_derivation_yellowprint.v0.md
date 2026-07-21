# Nested Work Layer Derivation Yellowprint v0

Status:

```text
table / yellowprint
documentation authority only
no runtime authority
no router authority
no mutable layer state
prepared for shadow implementation
amended 2026-07-21: F3 process_contract_id separated from semantic context;
  F6 canonical stage identity; F4 derives rejected terminal candidates from
  final QA verdicts and removes the standalone failure crystal
audit source: docs/00_chaos/fable_preimplementation_crystall_audit_raw_2026-07-21.md
F4 decision: docs/00_chaos/f4_rejected_generation_terminal_projection_notes_2026-07-21.md
```

Date:

```text
2026-07-20
```

Primary chaos source:

[`../../00_chaos/nested_work_layer_runtime_integration_2026-07-20.md`](../../00_chaos/nested_work_layer_runtime_integration_2026-07-20.md)

Companion tables:

```text
completion_scope_candidate_seal_yellowprint.v0.md
stage_transition_generation_recovery_yellowprint.v0.md
documentation_layer_snapshots_truth_yellowprint.v0.md
documentation_profiles_economy_yellowprint.v0.md
documentation_corpus_assembly_reentry_yellowprint.v0.md
```

Archaeology:

[`nested_layer_glyphs_yellowprint.v0.md`](nested_layer_glyphs_yellowprint.v0.md)

The archaeology document remains useful for the original nested-glyph idea,
but its mutable `packet.runtime.layer` sketch and its in-place build repair
meaning are superseded by this table.

## 0. Table Decision

For the `software_task.v0` context, proc-17 may expose a work-layer projection:

```text
mode  = plan | build
glyph = ⋯ | ⊞ | ◈ | ▲
```

The projection is derived from body-owned evidence. It is not a Packet field,
not a substrate declaration and not a routing instruction.

Canonical law:

```text
The work layer names the form already proved by the current evidence.
It does not create that form and it does not choose the next operator.
```

The first implementation must run as a massless shadow observer. Promotion to
a pressure input is a later decision requiring a separate corpus.

## 1. Coordinate Separation

| Coordinate | Question | Owner | May directly route? |
|---|---|---|---|
| ProcessLang operator | Where is the Packet acting now? | topology + router + body | router selects an adjacent operator |
| work mode | What kind of work does this Packet life perform? | verified birth/stage contract | no |
| work context | Which nested process is being described? | process contract | no |
| work layer | What form has current evidence reached? | pure derivation | no |
| completion scope | How much work is actually proved complete? | named completion readers | no |
| documentation profile | Which additional corpus is required? | root process contract | no |

These coordinates must not be collapsed.

Examples:

```text
operator = ☱, mode = build, glyph = ⊞, scope = candidate_sealed
operator = △, mode = plan,  glyph = ▲, scope = none,
           boundary_candidate = plan_stage_ready
operator = ☵, mode = build, glyph = ◈, scope = candidate_sealed,
           reason = qa_rejection_verdict_pending
```

The examples describe possible observations. They do not add topology edges.

## 2. Projection Contract

Conceptual API:

```lua
work_layer.inspect(instance, options) -> projection | nil, err
```

Exact candidate envelope:

```lua
{
  protocol_version = "runtime.work_layer_projection.v0",
  projection_id = "work-layer:<digest>",

  packet_id = "packet:...",
  lineage_id = "lineage:..." | nil,
  generation = 1,
  stage_id = "stage:<lineage_id>:1:plan" | "stage:<lineage_id>:2:build",

  process_contract_id = "plan.only.v0" | "build.only.v0" | "software.create.v0",
  context = "software_task.v0",
  mode = "plan" | "build",
  glyph = "⋯" | "⊞" | "◈" | "▲" | nil,
  state =
      "forming"
    | "checking"
    | "crystallized"
    | "crystallizing_failure"
    | "boundary"
    | "unsupported",

  reason = "plan_structure_missing" | string,
  completion_scope = "none" | "work_item" | "artifact_set"
    | "candidate_sealed",
  boundary_candidate = "none" | "plan_stage_ready"
    | "software_acceptance_ready"
    | "rejected_generation_recovery_ready",
  boundary_terminalized = boolean,
  boundary_terminal_ref = string | nil,

  source_refs = {"trace:...", "completion:..."},
  relevant_object_versions = {
    {domain = "field_unit", id = "unit:...", version = 2},
  },
  relevant_revisions = {
    field = 7,
    calm = 3,
    runtime = 11,
  },
  missing_requirements = {"qa_verdict_for:candidate-seal:..."},
  conflicting_refs = {},

  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed"
    | "semantic_proposal"
    | "mixed",
}
```

The schema is a table decision, not yet a Lua contract. Exact key names may be
revised at crystall if current runtime primitives make a smaller shape honest.

## 3. Identity And Idempotence

`projection_id` is a digest of every identity-bearing field except itself.

Identity includes:

```text
Packet identity
lineage/generation/stage identity when present
process-contract identity, semantic context and mode
glyph/state/reason/scope
boundary candidate and terminalization fields
ordered source refs
ordered object-version refs
relevant revisions
missing requirements
conflicting refs
truth statuses
```

Identity excludes:

```text
wall-clock time
display formatting
TUI labels
observer trace event id
caller-owned metadata
```

Matched law:

```text
same owned facts -> byte-equivalent projection -> same projection_id
changed relevant object version -> re-derive -> possibly new projection_id
```

An observer may append a deep-copied projection to trace. The trace event is a
historical observation; it is never the current mutable source of layer truth.

## 4. Authority Matrix

| Actor | May supply facts? | May select glyph? | May mutate evidence while inspecting? |
|---|---:|---:|---:|
| Packet body | yes, through existing owned stores | no direct selection | no |
| completion inspector | yes, derived records only | contributes evidence | no |
| work-layer inspector | reads only | derives deterministically | no |
| substrate | semantic content only | no | no |
| caller / harness | process contract only | no | no |
| router | reads future qualified witnesses | no | no |
| TUI / CLI | displays projection | no | no |
| documentation observer | copies projection into snapshot | no | no |

Forbidden shortcuts:

```text
options.layer = "▲"
substrate says "done" -> glyph ▲
caller sets packet.runtime.layer
router writes the layer it wants to see
missing evidence interpreted as successful boundary
```

## 5. Input Readers

The inspector may consume only named, verified readers.

| Reader | Current implementation | Contribution |
|---|---|---|
| Packet work regime | `core/packet.lua` / birth contract | mode and Packet identity |
| field structure | field/body readers | formation and active object versions |
| plan completion | `runtime/plan_completion.lua` | exact plan candidate, assessment and result refs |
| repository work completion | `runtime/work_completion.lua` | exact work-item evidence |
| artifact projection | `runtime/repository_result.lua` | current repository artifact result |
| completion scope | companion table; future inspector | Packet-local artifact-set and seal facts plus a typed boundary candidate |
| terminal Packet state | Packet/corpse/manifest readers | historical boundary evidence |
| lineage stage projection | companion table; future inspector | stage identity and transition state |

Unavailable readers must produce `unsupported` or a named missing requirement.
They must not be replaced by inference from prose.

## 6. Derivation Order

The inspector derives in this order:

```text
1. verify Packet identity and readable lifecycle state
2. derive process-contract identity and mode from verified birth/stage contract
3. derive semantic context from that process contract
4. obtain completion-scope inspection
5. collect current-generation source refs and object versions
6. reject conflicts, stale refs and cross-generation evidence
7. apply the mode-specific precedence table
8. return one projection or an explicit unsupported result
```

The order matters. A manifest-like event from another generation cannot move
the current Packet to `▲`; a current `candidate_sealed` fact cannot be inferred
before scope verification.

## 7. Plan Derivation Table

Precedence is evaluated from the highest proved boundary downward.

| Priority | Required evidence | Glyph | State | Scope | Boundary candidate | Reason | Missing requirement |
|---:|---|---|---|---|---|---|---|
| P1 | exact current-stage `plan.result.v0` and verified Packet terminal/manifest boundary | `▲` | `boundary` | `none` | `plan_stage_ready` | `plan_stage_candidate_ready` | lineage stage assessment, then stage transition or root completion accounting |
| P2 | exact accepted `plan.completion_assessment.v0`; typed plan result not yet manifested | `◈` | `crystallized` | `none` | `none` | `plan_export_ready` | typed plan delivery |
| P3 | exact current plan structure exists but accepted completion assessment is absent | `⊞` | `checking` | `none` or `work_item` | `none` | `plan_structure_requires_review` | plan completion review |
| P4 | no exact current plan structure | `⋯` | `forming` | `none` | `none` | `plan_structure_missing` | semantic/structural formation |

Plan `◈` requires one clarification: the glyph means crystallized plan form,
not failure. Therefore the generic `state` vocabulary is not a synonym for the
glyph. For P2 the exact state is `crystallized` with reason
`plan_export_ready`. Even at P1 the Packet has only a `plan_stage_ready`
candidate. The stage scope remains lineage-owned until the corpse and exact
terminal refs are assessed.

If the plan evidence is contradictory, stale or truncated, the result remains
at `⊞` or becomes `unsupported`; it never advances because a later-looking
event exists.

## 8. Build Derivation Table

Precedence is again evaluated from the strongest proved boundary downward.

| Priority | Required evidence | Glyph | State | Scope | Boundary candidate | Reason | Missing requirement |
|---:|---|---|---|---|---|---|---|
| B1 | current sealed candidate + exact accepted required QA + Packet-local software acceptance prerequisites satisfied | `▲` | `boundary` | `candidate_sealed` | `software_acceptance_ready` | `software_acceptance_candidate_ready` | Packet terminal manifest/corpse, then lineage software assessment and any required documentation |
| B2 | one final rejected QA verdict bound to the current seal, QA contract and rejected check refs | `▲` | `boundary` | `candidate_sealed` | `rejected_generation_recovery_ready` | `rejected_generation_recovery_ready` | △ embeds the rejected-generation terminal projection, then corpse and lineage recovery assessment |
| B3 | one or more current required QA checks rejected; final current verdict absent | `◈` | `crystallizing_verdict` | `candidate_sealed` | `none` | `qa_rejection_verdict_pending` | one final immutable rejected QA verdict |
| B4 | current candidate sealed; no current QA check/verdict evidence | `⊞` | `checking` | `candidate_sealed` | `none` | `candidate_sealed_qa_missing` | accepted or rejected QA evidence |
| B5 | declared artifact set fully evidenced, candidate seal absent | `⋯` | `forming` | `artifact_set` | `none` | `artifact_set_complete_seal_missing` | candidate seal |
| B6 | fresh generation active; declared artifact set incomplete | `⋯` | `forming` | `none` or `work_item` | `none` | `candidate_materialization_incomplete` | bounded create-only materialization |

Important consequences:

```text
artifact completion does not imply build ⊞ until the whole declared set is known
candidate seal does not imply accepted QA
rejected check evidence does not imply a final verdict or permission to patch
final rejected verdict does not imply root completion
build ▲ may be a software-acceptance candidate boundary or a paid rebirth boundary
an ▲ boundary never grants the living Packet stage, software or root completion
```

For B1/B2 the living projection has `boundary_terminalized=false`. The lawful
△/corpse transition re-derives the same glyph and candidate with
`boundary_terminalized=true`; only that historical form is admissible to the
lineage completion/recovery reader.

The current one-file build life is expected to project as B5 or B4 depending
on whether a candidate-seal observer exists. It must not project as B1 merely
because `repository.result.v0` says `complete`.

## 9. Unsupported And Conflict Outcomes

The projection uses `glyph = nil`, `state = "unsupported"` when the body cannot
lawfully select one glyph.

| Condition | Outcome | Why |
|---|---|---|
| mode absent or invalid | error | birth contract corruption |
| context contract unknown | unsupported | no context derivation table |
| completion reader unavailable | unsupported | missing organ is not negative evidence |
| accepted and rejected QA both current | unsupported + conflict refs | world/body inconsistency |
| candidate seal references another generation | unsupported | ancestry mismatch |
| later source ref precedes required cause | error | causal ordering corruption |
| old object version only | lower layer or unsupported | stale evidence cannot rule current form |
| substrate prose claims a layer | ignore prose as authority | semantic content has no layer right |

Unknown is not `⋯`. `⋯` means formation is positively derived, while unknown
means the inspector lacks an applicable contract.

## 10. Freshness And Object Coverage

Freshness follows the same spatial law as qualified pressure and the runtime
camera:

```text
coverage = {object_id -> observed_version}
```

Global revision axes are audit summaries, not sufficient freshness proof.

| Change | Required effect |
|---|---|
| covered unit version changes | prior projection becomes historical/stale |
| relation endpoint version changes | relation-dependent projection re-derives |
| unrelated object changes | projection remains valid if contract scope excludes it |
| QA evidence for different candidate arrives | no advancement |
| current candidate seal changes | impossible in lawful physics; invariant failure |
| lineage stage changes | prior projection remains historical, new Packet derives new projection |

The inspector does not persist a mutable coverage ledger. It derives refs and
versions from body-owned evidence on each inspection.

## 11. Layer And Pressure

V0 shadow operation emits no pressure.

Future promoted operation may expose a missing requirement to an existing
qualified-pressure mechanism. The bridge must satisfy:

```text
projection reason -> exact missing requirement -> named reader -> typed witness
```

Candidate mappings, not yet authority:

| Projection reason | Possible witness | Candidate consumer |
|---|---|---|
| `plan_structure_missing` | semantic formation need | ☴ / ☵ according to tree pressure |
| `plan_structure_requires_review` | plan completion review need | ☱ |
| `plan_export_ready` | plan delivery need | △ |
| `candidate_materialization_incomplete` | declared materialization need | effect-capable path |
| `artifact_set_complete_seal_missing` | candidate seal need | ☱ or a dedicated body action |
| `candidate_sealed_qa_missing` | QA evidence need | ☶ through a lawful QA capability |
| `qa_rejection_verdict_pending` | final rejected-verdict assembly need | future dedicated QA verdict writer after exact ☶/☱ evidence |
| `rejected_generation_recovery_ready` | terminal/rebirth accounting need | △ / lineage runner boundary |

This table intentionally does not assign weights or guaranteed next operators.

## 12. Layer And Documentation Snapshots

Documentation snapshots may copy:

```text
work_layer_projection_ref
projection_id
glyph
reason
source_refs
missing_requirements
```

They may not copy only the glyph and discard its derivation.

The snapshot content remains historical even after a later projection replaces
it. A stale `build ⊞` snapshot is honest evidence that the candidate once
awaited QA; it is not current authority after a rejected verdict.

`stage`, `software_accepted` and `root_delivery` are lineage-side evidence
assembled after the relevant Packet has died. They do not retroactively change
that Packet's final work-layer projection. The corpus composes the historical
Packet boundary candidate with later lineage acceptance and documentation
evidence as separate outer boundaries.

The documentation profile never changes work-layer derivation. It only decides
which snapshots are retained and how much narration is generated.

## 13. Named Writer / Reader Table

| Record | Writer | Named readers | Must not read as |
|---|---|---|---|
| current projection | pure inspector return value | shadow observer, completion audit, TUI, documentation snapshotter | mutable Packet status |
| projection trace observation | body observer | evidence corpus, TUI history, debugger | current layer truth |
| missing requirement | inspector | future qualified witness producer | direct route command |
| object-version refs | inspector | freshness check, corpus audit | broad global epoch |
| unsupported outcome | inspector | audit and promotion gate | `⋯` fallback |

Every written observation has a named reader. If no reader is enabled, the
inspector should return the projection to its caller without creating a new
storage surface.

## 14. False-Green Matrix

| Apparent success | Why it is false | Required projection |
|---|---|---|
| substrate says plan is complete | semantic proposal only | remain at evidence-derived plan layer |
| one repository work unit complete | artifact set may be incomplete | build `⋯` |
| all declared files exist | candidate not sealed or independently verified | build `⋯` |
| candidate sealed | QA missing | build `⊞` |
| tests described in prose | no runtime QA evidence | build `⊞` |
| rejected check plus a suggested patch | no final body verdict and no fresh birth | build `◈` |
| rejected candidate has residue | residue is neither a final QA verdict nor a terminal candidate | build `◈` until the verdict boundary is proved; never accepted root |
| documentation corpus exported | software acceptance not implied | retain underlying software layer |

## 15. False-Red Matrix

| Apparent failure | Why it need not block the derived layer |
|---|---|
| unrelated field object changed | outside exact projection coverage |
| documentation profile is off | software work layer is orthogonal |
| prior generation failed | current generation derives from its own evidence |
| optional human narration absent | structured/runtime evidence may still satisfy contract |
| lineage wallet is exhausted after an exact Packet terminal candidate | the historical Packet `▲` remains true; any derived stage fact is unchanged and continuation becomes unaffordable |

The last row preserves the completion/economy separation already established
by `lineage_completion_continuation_separation_yellowprint.v0.md`.

## 16. Permanent Control Matrix

### Pure derivation

| ID | Control | Expected |
|---|---|---|
| L01 | same Packet state inspected twice | same bytes and projection id |
| L02 | inspector enabled vs disabled | identical route, budget, loss and effects |
| L03 | caller supplies desired glyph | rejected or ignored; no authority |
| L04 | substrate writes `layer=▲` in prose | no advancement |
| L05 | projection trace payload mutated by caller | stored deep copy unchanged |

### Plan matched pairs

| ID | A | B | Expected delta |
|---|---|---|---|
| L06 | exact plan structure absent | exact structure current | `⋯ -> ⊞` |
| L07 | completion assessment absent | accepted assessment exact | `⊞ -> ◈` |
| L08 | typed plan result absent | exact manifest present | `◈ -> ▲` |
| L09 | current assessment | same assessment with stale unit version | advanced layer disappears |

### Build matched pairs

| ID | A | B | Expected delta |
|---|---|---|---|
| L10 | one declared artifact missing | complete exact set | materialization reason changes; no QA claim |
| L11 | complete set unsealed | exact current seal | `⋯ -> ⊞` |
| L12 | sealed, QA absent | one exact rejected required check, final verdict absent | `⊞ -> ◈` |
| L13 | rejected check evidence, final verdict absent | exact final rejected verdict over the same seal/check set | `◈ -> ▲` recovery boundary |
| L14 | sealed, QA absent | exact accepted required QA | `⊞ -> ▲` software-acceptance candidate boundary |
| L15 | accepted QA for candidate A | same QA attached to candidate B | B remains `⊞` |

### Scope and generation controls

| ID | Control | Expected |
|---|---|---|
| L16 | old generation accepted QA | cannot advance new generation |
| L17 | rejected generation leaves residue | next generation starts `build ⋯` |
| L18 | lineage budget exhausted after stage completion | historical Packet projection remains `▲`; transition denied separately |
| L19 | unknown process context | unsupported, not fallback `⋯` |
| L20 | conflicting current QA verdicts | unsupported/invariant failure |

## 17. Shadow Corpus

The first evidence corpus must contain grown lives, not hand-authored terminal
fixtures.

Required classes:

```text
exact plan life through plan result
truncated or stale plan candidate
single-file current build life
multi-file partial materialization life
sealed candidate with no QA
accepted QA life
rejected required check before final verdict
final rejected verdict before and after △/corpse
budget death before sealing
budget death during QA
new generation born from rejected ancestor
documentation profile off / structured / full ablation
```

Each row records:

```text
actual operator walk
mode/process-contract/context/stage/generation
derived glyph/state/reason
completion scope
source refs and object versions
missing requirements
observer enabled/disabled equality
legacy/current completion disagreement
named reader for every record
```

## 18. Promotion Gates

| Gate | Requirement |
|---|---|
| D0 | table and crystall contracts agree |
| D1 | pure derivation controls green |
| D2 | shadow observer ablation exact |
| D3 | no caller/substrate glyph authority |
| D4 | completion-scope corpus separates artifact, stage and root |
| D5 | stale/cross-generation evidence controls green |
| D6 | no unknown outcome silently becomes `⋯` |
| D7 | any future pressure bridge uses named qualified witnesses |
| D8 | TUI/CLI reads projection without becoming its owner |

Passing D0-D6 permits an observational API. It does not permit the layer to
gate routes or manifests. Those authorities require the companion completion
and lineage campaigns.

## 19. Implementation Sequence Predicted By The Table

```text
1. crystallize the projection schema and exact derivation precedence
2. implement pure read-only inspector
3. add observer trace event with deep-copy sealing
4. prove observer ablation
5. grow plan and current-build baseline corpus
6. add completion-scope shadow reader
7. grow sealed/accepted/rejected candidate corpus
8. expose projection to CLI/TUI and documentation snapshots
9. only then consider a qualified-pressure bridge
```

## 20. Explicit Deferrals

This table does not authorize:

```text
QA execution
`qa-check.v0` and final QA-verdict writer
candidate sealing effects
stage transitions
fresh repository allocation
root completion gating
mutable repair
new topology edges
layer-based fixed routing
human narration calls
```

Those belong to companion contracts or later capability campaigns.

## 21. Table Thesis

```text
The operator tells where the Packet acts.
The mode tells what kind of life it is living.
The layer tells what form its evidence has reached.
The scope tells how much has actually been completed.

None of these facts may be manufactured by the substrate or caller.
```
