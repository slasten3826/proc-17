# Opus Pre-Crystall Six-Table Audit Brief - 2026-07-20

Status:

```text
chaos / external cold-audit carrier
target: Claude Opus / Claude Code
scope: six new TABLE documents before crystallization
requested mode: read-only audit
do not modify code or documentation
absence of future implementation is not automatically a defect
```

## Привет

Мы собираем `proc-17`, исполняемое тело `procesis` для создания нового
программного обеспечения.

Текущий спринт добавляет ещё не код, а шесть TABLE/yellowprint-документов. Они
должны закрыть последний крупный архитектурный разрыв между уже работающим
Packet/runtime и будущим полным процессом:

```text
plan -> build -> candidate seal -> QA -> accepted delivery
                         |
                         -> rejected death -> fresh generation -> rebuild
```

До перехода в CRYSTALL нужен независимый холодный аудит таблиц.

Не продолжай выводы прежней сессии и не изображай память о проекте. Сначала
проверь текущую копию самостоятельно. Если знакомые идеи совпадут с прежними,
это должно следовать из файлов и runtime evidence, а не из роли.

Проект собирался совместно человеком и машинами. Сейчас твоя роль узкая:
внешний инженерный аудитор. Нужен не пересказ, не похвала и не альтернативный
дизайн с нуля, а проверка внутренней связности именно выбранной архитектуры.

## 1. Сначала Холодная Проверка

До чтения старых отзывов:

```text
git status --short
lua tests/run.lua
lua tests/smoke_mortality_battery.lua
```

Таблицы сейчас могут быть незакоммиченными. Это ожидаемо и не является
дефектом. Ничего не добавляй в index, не коммить и не исправляй.

Полный suite подтверждает текущую baseline-физику, но не доказывает будущие
контракты таблиц. Не называй отсутствие тестов для ещё не написанного кода
регрессией текущего runtime.

## 2. Обязательные Источники

### Chaos boundary

```text
docs/00_chaos/nested_work_layer_runtime_integration_2026-07-20.md
docs/00_chaos/self_documenting_lineage_corpus_notes_2026-07-20.md
```

### Six TABLE documents under audit

```text
docs/01_table/yellowprints/documentation_profiles_economy_yellowprint.v0.md
docs/01_table/yellowprints/documentation_layer_snapshots_truth_yellowprint.v0.md
docs/01_table/yellowprints/documentation_corpus_assembly_reentry_yellowprint.v0.md
docs/01_table/yellowprints/nested_work_layer_derivation_yellowprint.v0.md
docs/01_table/yellowprints/completion_scope_candidate_seal_yellowprint.v0.md
docs/01_table/yellowprints/stage_transition_generation_recovery_yellowprint.v0.md
```

### Superseded archaeology

```text
docs/01_table/yellowprints/nested_layer_glyphs_yellowprint.v0.md
```

Read its supersession banner first. The old body is preserved intentionally;
do not report already-marked in-place repair semantics as a new defect.

### Current runtime contracts to compare against

```text
core/packet.lua
runtime/work_completion.lua
runtime/repository_result.lua
runtime/completion.lua
runtime/lineage.lua
runtime/lineage_runner.lua
runtime/carrier.lua
runtime/network_ingress.lua
runtime/repository_capability.lua
runtime/repository_action.lua
runtime/repository_effect.lua
runtime/plan_completion.lua
runtime/body.lua
organs/manifest.lua
```

### Existing lower-layer TABLE/CRYSTALL authority

```text
docs/01_table/yellowprints/post_collapse_plan_delivery_yellowprint.v0.md
docs/01_table/yellowprints/capability_safe_repository_hands_yellowprint.v0.md
docs/01_table/yellowprints/lineage_in_memory_slice_yellowprint.v0.md
docs/01_table/yellowprints/lineage_completion_continuation_separation_yellowprint.v0.md
docs/02_crystall/blueprints/capability_safe_repository_hands.v0.md
docs/03_manifest/current_state.md
```

Read more only when an exact claim requires it. Do not drown the audit in the
whole archaeology before checking the selected boundary.

## 3. Current Runtime Baseline

The current code already has:

```text
Packet mortality, corpse and lineage recovery
cumulative lineage budget and Packet-local loss
full Tree authority and qualified pressure
exact plan completion and plan.result.v0
one capability-safe create-no-replace repository hand
attempt -> receipt -> independent read-back -> validation -> ☱ completion
one-artifact repository.result.v0 manifestation
NETWORK@▽ recovery ingress
```

The current code does not yet have:

```text
derived work-layer projection
completion-scope inspector above one artifact
multi-file candidate seal
post-seal authority closure
QA execution capability
plan->build stage transition inside lineage
fresh repository allocation per rejected build generation
lineage corpus export implementation
CLI/TUI for these contracts
```

This absence is planned. Report it as `implementation gap`, not as a TABLE
defect, unless the table claims the function already exists or gives no lawful
path by which it could exist.

## 4. Fixed Decisions You Must Audit, Not Silently Replace

The following are current project decisions. You may prove them internally
inconsistent or unsafe, but do not replace them merely because a conventional
agent would choose another design.

```text
proc-17 primarily creates new software
legacy source is read-only evidence; output is a fresh reconstruction

a materialized candidate is not patched after rejection
each rejected build generation dies
each descendant build generation receives a fresh repository identity

work layer is derived evidence, not mutable Packet state
work layer is not a router and does not command an operator

completion has separate scopes:
  work item -> artifact set -> candidate sealed -> stage
  -> software accepted -> root delivery

build ▲ after rejection is a generation terminal/rebirth boundary
it is not build-stage completion and not root success

accepted QA produces software_accepted
required documentation may still keep root_delivery incomplete
root delivery is lineage-side and does not rewrite a dead Packet's layer

plan success and build recovery use different carrier classes:
  stage_transition
  recovery

no carrier transports a writable grant, provider handle or live Packet
lineage economics do not reset on stage transition or rebirth

first QA-placement hypothesis:
  materialization -> seal -> read-only QA in one build Packet life
  after seal the same Packet no longer has source-write authority

documentation profile is orthogonal:
  off | structured | full
structured corpus requires no extra substrate call in v0
full is additive human projection over structured evidence

canonical lineage corpus lives outside the sealed candidate repository
Packet △ remains Packet-local; lineage assembler owns cross-generation corpus
```

## 5. Known Explicit Deferrals

Do not report these merely as omissions:

```text
the exact QA hand and its threat model
general shell/network capability
persistent crash recovery
parallel/branching lineage
QA child Packet alternative
reuse of a sealed candidate after Packet death
repository cleanup/compost policy
cross-session shared corpus memory
semantic automatic process-contract selection
documentation-only Packet continuation
mutable patch/replace/delete hands
```

You should report a defect if a non-deferred contract already depends on one of
these without admitting that dependency or without a typed unavailable path.

## 6. Audit Questions

### A. Six-table consistency

1. Do all six documents use the same meaning for `⋯ ⊞ ◈ ▲`?
2. Does any document accidentally treat a generation boundary as stage/root
   completion?
3. Does any document let documentation alter candidate bytes, route or work
   loss?
4. Does root delivery avoid recursive inclusion of its own corpus receipt and
   completion event?
5. Are optional and required documentation outcomes composed consistently?

### B. Derivation and epistemic status

1. Can every derived layer/scope/status name exact source refs and object
   versions?
2. Does any caller, substrate or Markdown label manufacture runtime truth?
3. Are binding acts (`runtime_confirmed`) separated from project decisions
   (`document_decision`) and semantic content (`semantic_proposal`/mixed)?
4. Can stale or cross-generation evidence advance a current layer/scope?
5. Is `unsupported` distinct from negative evidence and from `⋯`?

### C. Completion and seal

1. Does the scope ladder preserve current `runtime.work_completion.v0` without
   laundering `repository.result.v0` into root completion?
2. Is artifact-set identity exact enough for several files and versions?
3. Does seal close all write paths, including creation of a new absent path and
   replay of pre-seal leases?
4. Is the bounded repository inventory sufficient to prove what was sealed?
5. Is there a race or split-brain between authority closure, closure receipt
   and body seal event?
6. Can QA mutate source through caches, temp files or undeclared capabilities?
7. Can malformed Lua/provider behavior become a pretty Packet death instead of
   a loud harness/runtime failure?

### D. Stage transition and recovery

1. Can a plan stage complete without completing `software.create.v0`?
2. Does the transition carrier derive target mode/stage from an immutable
   process contract rather than mutable `lineage.work_mode`?
3. Can one corpse produce two children or two carrier classes?
4. Can successful transition and same-stage recovery be confused by a reader?
5. Is stage identity stable while generation/attempt identity increases?
6. Does every build generation receive a truly fresh repository without
   carrying ancestor authority?
7. Does affordability affect only continuation, never intrinsic completion?
8. Is every lineage-runner decision written to a ledger with a named reader?

### E. Documentation corpus

1. Is Packet-local manifestation separated cleanly from lineage corpus
   assembly?
2. Does every snapshot remain historical rather than becoming a second mutable
   truth store?
3. Are structured exports deterministic, bounded and independently verifiable?
4. Can full narration alter structured corpus identity or software completion?
5. Can required corpus failure block root delivery without erasing accepted
   software evidence?
6. Does reentry always birth a fresh Packet and preserve applicability status?
7. Does every written record have a named reader and a retention boundary?

### F. Crystall readiness

1. Are the schemas and causal order precise enough to write blueprints without
   inventing policy during implementation?
2. Which table, if any, still contains an unresolved decision that blocks its
   crystall?
3. Is the proposed dependency order sound?

```text
completion_scope.v0
work_layer_projection.v0
candidate_seal.v0
stage_transition_generation_recovery.v0
documentation_profiles_economy.v0
documentation_layer_snapshots.v0
documentation_corpus_assembly_reentry.v0
```

4. Should any listed crystall be split further for authority or threat-model
   reasons? Explain the exact boundary, not a stylistic preference.

## 7. Required Audit Method

Use these rules:

```text
cold code/test check before old external commentary
current runtime evidence before documentation claims about current behavior
integration boundary above synthetic fixture when a real producer exists
every storage surface must have a named writer and reader
every authority must have an explicit mint/resolve/revoke boundary
every terminal claim must name exact completion scope
every continuation must preserve mortality and cumulative economics
every constant or default must be identified as measured, controlled or chosen
every claimed defect must include a concrete causal path
```

Do not require a runtime reproduction for a purely future table contradiction.
In that case provide exact document sections and construct the smallest
counterexample state.

## 8. Classification Vocabulary

Classify each finding as exactly one of:

| Class | Meaning |
|---|---|
| `runtime defect` | existing code violates its current contract; reproduce it |
| `table contradiction` | two selected contracts cannot both be true |
| `table underspecification` | crystall would have to invent a consequential policy |
| `authority leak` | an actor can gain or widen power without the declared boundary |
| `false completion` | smaller evidence can satisfy a larger completion scope |
| `identity/provenance defect` | stale, foreign or ambiguous evidence can be accepted |
| `implementation gap` | lawful future contract exists but code is not written yet |
| `explicit deferral` | named future work; not a defect in this audit |
| `non-issue` | suspected problem is already prevented; cite the prevention |

Severity:

```text
critical  can violate sandbox/finality or corrupt authority irreversibly
high      blocks crystall or permits false completion/identity
medium    future reader will misclassify or implementation must guess
low       naming, observability or maintainability issue without semantic drift
```

## 9. Required Report Shape

Return the report in this order:

### 1. Cold baseline

```text
git state
full test result
mortality result
files actually read
```

### 2. Findings

Highest severity first. Every finding must include:

```text
classification + severity
exact file and line/section references
smallest counterexample or reproduction
which fixed law is violated
minimum correction at TABLE level
whether it blocks one crystall or all crystallization
```

Do not manufacture a weak defect merely to satisfy the review protocol. If no
defect exists, state that directly and name residual untested risks.

### 3. Cross-table invariants confirmed

List only invariants you actually traced through writers and readers.

### 4. Crystall readiness matrix

For each proposed crystall:

```text
ready | ready after named table correction | blocked by open decision
```

### 5. Recommended next move

One smallest next action. Do not propose a general rewrite, framework migration,
CLI/TUI implementation or product roadmap in this audit.

## 10. Editing Boundary

Do not modify files during this pass.

Specifically:

```text
no apply/edit/write
no new audit document in the repository
no formatting cleanup
no code fixes
no commits
no dependency installation
```

Return findings in chat. The machinist will courier the report back to Codex,
and we will decide which observations become chaos residue or TABLE amendments.

## 11. Audit Thesis

```text
The question is not whether the future code already exists.

The question is whether these six tables describe one implementable world
without hidden authority, false completion, identity leakage or policy that
would have to be invented while writing the crystall.
```
