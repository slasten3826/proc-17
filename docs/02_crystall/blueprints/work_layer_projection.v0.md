# Work Layer Projection Blueprint v0

Status:

```text
crystall
date: 2026-07-20
source table: docs/01_table/yellowprints/nested_work_layer_derivation_yellowprint.v0.md
depends on: docs/02_crystall/blueprints/completion_scope.v0.md
implementation authority: pure projection and massless shadow observer
pressure authority: forbidden
manifest authority: forbidden
amended 2026-07-21: F3 process_contract_id separated from semantic context
audit source: docs/00_chaos/fable_preimplementation_crystall_audit_raw_2026-07-21.md
F4 amendment: build ◈ assembles a final rejected verdict; build ▲ requires that
  verdict and no standalone failure crystal
F4 decision: docs/00_chaos/f4_rejected_generation_terminal_projection_notes_2026-07-21.md
2026-07-21 cross-table documentary gate: satisfied
```

## 0. Crystallized Claim

For `software_task.v0`, the four glyphs are a deterministic projection of
current body evidence:

```text
mode  = plan | build
glyph = ⋯ | ⊞ | ◈ | ▲
```

They are not Packet state, operator position, router output, substrate intent or
root completion.

```text
operator says where the Packet acts
mode says which typed life it is living
layer says which work form its evidence has reached
scope says how much is actually complete
```

## 1. Target Surface

New:

```text
runtime/work_layer.lua
tests/test_work_layer.lua
tests/test_work_layer_shadow.lua
```

Later observers:

```text
runtime/tension_runner.lua       optional shadow capture hook
runtime/edge_stats.lua           instrumentation counters only
runtime/documentation_snapshot.lua future named reader
CLI/TUI                         detached read-only projection
```

Dependencies:

```text
runtime/completion_scope.lua
runtime/plan_completion.lua
runtime/structure_inspection.lua
runtime/object_coverage.lua
runtime/repository_result.lua
core/digest.lua
core/json.lua
```

The module has no dependency on `runtime.pressure`, `runtime.tree_router` or
substrate adapters.

## 2. Public API

```lua
local work_layer = require("runtime.work_layer")

work_layer.inspect_packet(instance, contract_view)
  -> projection | nil, err

work_layer.inspect_corpse(corpse, contract_view)
  -> projection | nil, err

work_layer.same(left, right) -> boolean
work_layer.verify(projection) -> true | nil, err
```

`contract_view` carries independent `process_contract_id` and semantic
`context` fields. The inspector verifies it against birth/stage evidence; a
caller cannot select either coordinate by supplying a string.

The inspector obtains completion-scope evidence through the named module. A
caller cannot inject a preselected glyph or a forged scope inspection.

## 3. Projection Record

```lua
{
  protocol_version = "runtime.work_layer_projection.v0",
  projection_id = "work-layer:<sha256>",

  packet_id = string,
  lineage_id = string | nil,
  generation = integer,
  stage_id = string | nil,
  process_contract_id = "plan.only.v0" | "build.only.v0" | "software.create.v0",
  context = "software_task.v0",
  mode = "plan" | "build",

  glyph = "⋯" | "⊞" | "◈" | "▲" | nil,
  state = "forming" | "checking" | "crystallized"
    | "crystallizing_failure" | "boundary" | "unsupported",
  reason = string,

  completion_scope = "none" | "work_item" | "artifact_set"
    | "candidate_sealed",
  boundary_candidate = "none" | "plan_stage_ready"
    | "software_acceptance_ready"
    | "rejected_generation_recovery_ready",
  boundary_terminalized = boolean,
  boundary_terminal_ref = string | nil,

  source_refs = string[],
  relevant_object_versions = table[],
  relevant_revisions = table,
  missing_requirements = string[],
  conflicting_refs = string[],

  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed" | "semantic_proposal" | "mixed",
}
```

The identity projection includes every field except `projection_id`. Returned
values are detached. A projection is ephemeral unless a named observer stores
an immutable copy.

## 4. Authority And Input Readers

| Input | Named reader | Permitted contribution |
|---|---|---|
| Packet work regime | birth contract reader | exact mode |
| process/stage contract | contract reader | process-contract, context and stage identity |
| field structure | structure inspection | formation state and exact versions |
| plan completion | plan completion module | plan assessment/result refs |
| repository progress | work completion/result modules | current artifact evidence |
| completion scope | completion scope module | local scope and boundary candidate |
| Packet/corpse finality | Packet/corpse verifier | terminalized boundary |

Unavailable named readers produce `unsupported` or an exact missing requirement.
Substrate prose contributes no glyph authority.

## 5. Derivation Order

```text
1. validate Packet/corpse identity and lifecycle
2. derive mode from immutable birth/stage contract
3. select one known work-context derivation table
4. obtain a fresh completion-scope inspection
5. collect exact current-generation source refs and object versions
6. reject stale, conflicting and cross-generation evidence
7. apply mode-specific precedence from strongest boundary downward
8. emit one projection or typed unsupported
```

Unknown is not `⋯`. `⋯` is positive evidence of formation/materialization work;
unknown means no lawful derivation table or reader exists.

## 6. Plan Derivation

| Priority | Evidence | Glyph | State | Scope | Candidate | Reason | Missing |
|---:|---|---|---|---|---|---|---|
| P1 | exact `plan.result.v0` and Packet manifest/corpse | `▲` | boundary | none | `plan_stage_ready`, terminalized | `plan_stage_candidate_ready` | lineage stage assessment and transition/root accounting |
| P2 | exact accepted plan assessment, typed result not manifested | `◈` | crystallized | none | none | `plan_export_ready` | typed plan delivery |
| P3 | exact plan structure, accepted assessment absent | `⊞` | checking | none/work_item | none | `plan_structure_requires_review` | completion review |
| P4 | exact absence of current plan structure | `⋯` | forming | none | none | `plan_structure_missing` | semantic/structural formation |

Plan `◈` means selected/crystallized plan form, not failure. Plan `▲` remains a
Packet boundary candidate until lineage writes stage completion.

## 7. Build Derivation

| Priority | Evidence | Glyph | State | Scope | Candidate | Reason | Missing |
|---:|---|---|---|---|---|---|---|
| B1 | exact seal + accepted required QA | `▲` | boundary | candidate_sealed | software_acceptance_ready | `software_acceptance_candidate_ready` | △/corpse, then lineage assessment and required docs |
| B2 | final rejected QA verdict bound to exact seal/contract/rejected checks | `▲` | boundary | candidate_sealed | rejected_generation_recovery_ready | `rejected_generation_recovery_ready` | △ rejected-generation projection/corpse, then lineage recovery decision |
| B3 | exact rejected required check evidence, final verdict absent | `◈` | crystallizing_verdict | candidate_sealed | none | `qa_rejection_verdict_pending` | one final immutable rejected QA verdict |
| B4 | exact seal, no current QA check/verdict evidence | `⊞` | checking | candidate_sealed | none | `candidate_sealed_qa_missing` | exact QA evidence/verdict |
| B5 | exact artifact set complete, seal absent | `⋯` | forming | artifact_set | none | `artifact_set_complete_seal_missing` | candidate seal |
| B6 | declared artifact set incomplete | `⋯` | forming | none/work_item | none | `candidate_materialization_incomplete` | bounded create-only materialization |

For living B1/B2, `boundary_terminalized=false`. After lawful △ and corpse
capture, the same glyph/candidate re-derives with `boundary_terminalized=true`
and the exact corpse ref. Only the terminalized projection is admissible to the
lineage reader.

No build layer means in-place repair:

```text
rejected required check -> ◈ crystallize one final verdict
exact final rejected verdict -> ▲ enter rejected terminal boundary
△ embeds bounded rejected-generation evidence and kills the Packet
fresh generation -> ⋯ rebuild in a fresh repository
```

## 8. Freshness

Projection freshness uses exact object/version coverage:

```text
object id + version + source event
```

Global field/calm/runtime revisions are telemetry and quick scan hints. They are
not sufficient proof of staleness.

| Change | Effect |
|---|---|
| covered object version advances | re-derive |
| relation endpoint version advances | re-derive relation-dependent layer |
| unrelated object changes | projection remains valid when out of scope |
| QA for another seal arrives | no advancement |
| old generation evidence appears | historical only |
| current sealed candidate identity changes | invariant failure |

The inspector stores no mutable coverage ledger.

## 9. Unsupported And Conflict Law

```text
invalid mode/birth identity             loud invariant error
unknown context                         unsupported
completion reader unavailable           unsupported
accepted and rejected current verdicts  loud body inconsistency
foreign seal/generation                 unsupported with conflict refs
causal ref ordering impossible          loud invariant error
stale-only evidence                      lower layer or unsupported
substrate layer claim                    ignored as authority
```

Missing evidence cannot advance a glyph. A later-looking event with invalid
provenance cannot outrank earlier exact evidence.

## 10. Layer, Scope And Lineage

`completion_scope` in this projection is intentionally Packet-local. The
following facts remain outside it:

```text
stage complete
software_accepted
root_delivery
```

Those later lineage facts do not retroactively rewrite the dead Packet's final
glyph. Corpus and UI may display the historical Packet layer beside lineage
acceptance as separate records.

Lineage wallet state cannot alter a derived glyph. It may deny the transition
that would follow a valid terminal candidate.

## 11. Shadow Observer

```lua
options.work_layer_observer = "off" | "shadow_v0"
```

Shadow rules:

```text
derive only after committed body state
append/store only a detached immutable projection
never feed pressure/readiness/router
never change Packet revisions, budget, loss or effects
observer errors are instrumentation errors, not Packet death
count agreement/divergence against current behavior without changing it
```

The top-level observer statistics name their authority epoch. They do not mix
legacy, tree and future layer observers into one unlabeled counter.

## 12. Documentation Reader Contract

A documentation snapshot may copy:

```text
projection_id
glyph/state/reason
completion_scope
boundary candidate and terminalization
source refs/object versions
missing requirements/conflicts
truth statuses
```

Copying only the glyph is invalid because it discards the derivation.

Documentation profile selection has zero effect on projection derivation.

## 13. Permanent Controls

```text
WL01 repeat pure inspection gives same bytes/id
WL02 observer enabled/disabled gives identical route/budget/loss/effects
WL03 caller-supplied glyph is rejected/ignored
WL04 substrate says ▲ and evidence does not advance
WL05 returned projection mutation changes no stored observation
WL06 plan structure absent/present yields ⋯ -> ⊞
WL07 accepted plan assessment yields ⊞ -> ◈
WL08 exact plan manifest/corpse yields ◈ -> ▲ terminalized
WL09 stale plan object removes advanced layer
WL10 incomplete/complete artifact set changes reason without QA claim
WL11 complete set plus seal yields ⋯ -> ⊞
WL12 rejected required check without final verdict yields ⊞ -> ◈
WL13 exact final rejected verdict over the same seal/check set yields ◈ -> ▲ recovery candidate
WL14 accepted QA yields ⊞ -> ▲ acceptance candidate
WL15 living/corpse pair keeps glyph but false -> true terminalization
WL16 QA for another seal cannot advance
WL17 old generation acceptance cannot advance current generation
WL18 unknown context is unsupported, not ⋯
WL19 conflicting trusted verdicts fail loudly
WL20 documentation off/structured/full leaves projection identical
WL21 same semantic context under different process contracts retains distinct projection identity
```

Terminal and generation controls use grown lives, not hand-written corpse
fixtures.

## 14. Evidence Corpus

Required grown classes:

```text
exact plan life through result/corpse
stale and truncated plan candidate
one-file legacy current build result
multi-file partial/complete artifact set
sealed candidate without QA
accepted QA before and after corpse
rejected required check before final verdict, final verdict before △, and after corpse
budget death before seal and during future QA
new generation after rejected ancestor
documentation profile ablation
```

Each row records operator walk, mode/context/stage/generation, projection,
scope, terminalization, exact refs/versions, missing requirements, observer
ablation and named readers.

## 15. Implementation Order

```text
1. schema validation, canonical identity and detached returns
2. plan derivation over existing plan evidence
3. current one-file build baseline with honest low scope
4. shadow observer and ablation
5. artifact-set/seal readers as their contracts land
6. accepted/rejected QA derivations after QA hand exists
7. terminalized living/corpse matched pairs
8. CLI/TUI and documentation read-only consumers
9. separate decision on qualified-pressure bridge
```

## 16. Promotion Gates

```text
G0 table and crystall precedence agree
G1 pure/idempotent/detached controls green
G2 no caller or substrate authority
G3 observer ablation exact
G4 stale/cross-generation controls green
G5 scope never exceeds Packet subject ceiling
G6 terminalized false/true matched pairs green
G7 every stored observation has a named reader
```

Passing these gates exposes an observational API only. Routing and manifestation
remain separate authorities.

## 17. Explicit Deferrals

```text
pressure weights or routing from glyphs
new topology edges
candidate seal effect
QA execution
`qa-check.v0` and final QA-verdict writer
stage transition
root completion gating
human narration
mutable repair or reopening a generation
```

## 18. Crystall Thesis

```text
The layer is a reading of the work, not a command to the work.
```
