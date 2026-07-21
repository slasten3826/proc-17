# Fable Full-Project F4 Audit Raw - 2026-07-21

Status:

```text
chaos / external cold-audit evidence
author: Fable / Claude Opus through Claude Code
carrier: supplied by the machinist in chat
requested scope: entire current proc-17 worktree, then focused F4 analysis
actual declared scope: complete reading of F4 surfaces and runtime authority chain;
  tests, 115 chaos archaeology documents and native C were exercised or searched,
  but not read line by line
code/document changes by auditor: none
interpretation by Codex in this file: none
```

Preservation note:

```text
The report below preserves the auditor's claims and structure.
Terminal line wrapping was normalized where the pasted transcript split words.
This file is evidence, not an accepted project decision.
```

---

Инжест завершён. Отчёт по форме брифа §9.

## 1. Свидетельство полного инжеста

```text
worktree: /home/slasten/work/procesis-body @ main da89dc8
dirty: 3 modified (grave_classifier table+blueprint, nested_layer_glyphs banner),
       19 untracked (2 briefs, raw report, disposition, 6 tables, 7 blueprints)
lua5.4 tests/run.lua -> exit 0, 95 ok-lines, no red
lua5.4 tests/smoke_mortality_battery.lua -> 8/8 ok
worktree before/after tests: identical
native provider: linux suites green, including repository-provider-linux and hostile-audit
```

Прочитано целиком:

```text
six TABLE documents under F4 and their amendments
both chaos sources
the audit brief
the disposition record
the raw record of the previous audit
current_state.md
README
runtime authority chain:
  repository_result
  carrier
  corpse
  grave
  network_ingress
  logic/manifest
  heads of spells/session_memory
targeted searches through organs/, logic/ and core/
whole-tree alias sweep for:
  failure_crystal
  crystallization
  qa_rejected
  residue
  repair
```

Исключено из побайтового чтения, с явным признанием:

```text
about 35k lines of tests: executed and searched, not read line by line
115 chaos archaeology documents: banners and selected documents only
native C, about 3.8k lines: suites executed, source not read line by line
.git
```

«Прочитай всё» было исполнено как полное чтение всех F4-поверхностей и цепочки
власти плюс инвентаризация и статусные баннеры остального.

Амендменты F1-F3, F5 и F6 проверены по факту:

```text
generation_state renamed in table and blueprint
seal_pending now precedes inventory
process_contract_id and context are independent
stage v0 has no rejected state
grave is isolated from QA generation evidence
```

Противоречий с амендментами не найдено.

## 2. Реконструированная модель

Packet является смертной генерацией задачи. Он рождается через FLOW и
`packet_birth`, живёт под tree- или legacy-властью, платит локальным бюджетом и
loss, затем умирает типизированно:

```text
complete
budget_exhausted
identity_loss
validation_failure
```

Руки являются единственной capability-safe мутацией мира: create-no-replace
через приватный grant с независимым read-back. △ собирает манифест только из
Packet-состояния и затем финализирует жизнь.

Смертная цепь:

```text
Packet death
  -> corpse.capture
     immutable hash over manifest + residue + trace_tail(32) + evidence refs
  -> completion.evaluate
     intrinsic task state is separate from lineage wallet
  -> lineage_runner
     finish | suspend | exhaust | carrier.build_recovery
  -> network_ingress
  -> clean descendant Packet
```

QA в проектируемой архитектуре находится между seal и △ той же build-жизни:

```text
seal closes source-write authority
  -> read-only execution of declared checks
  -> ☶ validation
  -> ☱ verdict
```

Failure crystallization предполагалась между rejected verdict и △. Вопрос F4:
рождается ли там новый самостоятельный объект или это фаза сборки честного
терминального манифеста.

## 3. Вердикт F4

```text
outcome A: derived view sufficient
standalone failure_crystal.v0 is a redundant organ
```

Каждая механическая обязанность, которую таблицы возлагают на failure crystal,
уже имеет владельца:

| Обязанность | Существующий владелец |
|---|---|
| Какой check упал, на каком seal и по какому контракту | `qa.candidate_verdict.v0`, связанный с `candidate_seal_id`, `qa_contract_id`, `check_refs` и runtime-confirmed результатом |
| Переживание фактов после смерти Packet | corpse + полный manifest + residue + hash |
| Переезд ограниченных фактов потомку | carrier; v1 должен добавить rejected-candidate projection |
| Применимость к новой жизни не является фактом | закрытый `applicability_truth_status` vocabulary |
| Семантический диагноз | обычный substrate report через carrier projection и ENCODE потомка |
| Давление grave | отдельная grave/karma область, уже отгороженная от QA |

Проверка гипотез брифа:

```text
H6 confirmed:
  no existing named reader needs a distinct failure-crystal identity

H3 confirmed:
  mechanical projection requires no substrate call; B3 -> B2 can be body-derived

H4 confirmed and strengthened:
  semantic diagnosis must not be stored in the same authority object as exact facts

H1 half false:
  verdict alone is not recovery memory, but verdict + terminal projection + carrier is

H2 false as stated:
  binding is exact source refs, not colocation in a new object

H5 satisfied by removal:
  the body exposes no failure-crystal acceptor for substrate-forged objects
```

Отдельный «кристалл успеха» отсутствует. Создание отдельного кристалла провала
асимметрично и расширяет поверхность истины без новой причинной работы.

## 4. Настоящая находка внутри F4

Отдельный объект избыточен, но F4 скрывает один реальный недостающий закон.

`corpse.capture` хранит полный Packet manifest, однако trace ограничен
`trace_tail` из 32 событий. В длинной build-жизни QA-evidence может оказаться
старше хвоста. Текущий rejected manifest не обязан связывать:

```text
candidate_seal_id
qa_verdict_ref
rejected check refs
bounded mechanical check projections
```

Тогда corpse остаётся валидным, но recovery descendant получает manifest без
точных фактов провала. Значит требуемый контракт:

```text
The terminal manifest of a qa_rejected generation embeds a bounded structured
projection of the exact current candidate seal, final rejected verdict and
rejected check evidence.
```

Это расширение уже существующего закона manifest honesty, а не новый орган.
Rejected validation уже проецируется в честный blocked terminal result; QA
rejection является ещё одним типизированным случаем того же писателя:

```text
logic/manifest + △
```

Предложенная фазовая интерпретация аудитора:

```text
build ◈ = assembly of the honest terminal projection for a rejected generation
build ▲ = that projection exists and the generation is ready for terminalization
```

Принятый кандидат не получает отдельный success crystal. Отвергнутый кандидат
также не нуждается в failure crystal. Оба требуют честный terminal manifest.

## 5. Findings

### F4-a - Standalone Failure Crystal Is Redundant

Класс: architecture redundancy.

Механические поля выводятся из seal, exact QA verdict/check records, manifest,
corpse and carrier refs. Недеривабелен только семантический диагноз; он обязан
оставаться `semantic_proposal`, а не становиться runtime authority object.

### F4-b - Rejected-Generation Terminal Projection Is Missing

Класс: contract underspecification.

Severity: medium before QA implementation, promotion blocker for rejected QA.

Контрпример:

```text
long build life
QA evidence occurs more than 32 trace events before death
corpse retains full manifest but truncates old trace events
manifest does not embed rejected seal/verdict/check projection
descendant receives recovery carrier without exact failure facts
```

Минимальная правка: TABLE amendment assigning the bounded projection to △ and
requiring corpse/carrier/corpus readers to preserve it.

### F4-c - QA Check Records Have No Schema

Класс: underspecification.

Severity: low while QA hand remains explicitly deferred.

`qa.candidate_verdict.v0` refers to `qa-check:...`, but `qa-check.v0` has no
schema, writer or threat model. Name it as an explicit dependency deferred with
the QA hand. Do not invent the schema inside F4.

No unrelated critical or high defect was found during the declared ingestion.
Known bequest/compost readers remain admitted defects. Legacy `logic/spells.lua`
uses `io.popen`; the future QA hand must not inherit that authority surface.

## 6. Deletion And Replacement Map

One replacement is required throughout the six TABLE documents and seven
CRYSTALL blueprints:

```text
exact typed failure crystal
  -> rejected-generation terminal projection
     embedded in the terminal Packet manifest
     and bound to exact seal/verdict/check evidence
```

Required document effects:

```text
nested work layer:
  remove failure-crystal input and missing reason
  make ◈ the rejected-verdict assembly phase
  make ▲ the exact rejected terminal candidate

completion scope:
  remove failure_crystal_ref
  require bounded rejected projection in terminal manifest/corpse boundary

stage transition:
  recovery carrier transports bounded rejected-generation projection

documentation snapshots:
  replace failure_crystal_recorded boundary with rejected-generation manifest boundary

documentation corpus:
  remove failure_crystal object kind/ref
  preserve QA evidence/verdict and Packet manifest/corpse refs

grave:
  retain QA independence; refer to future lineage rejected-generation contracts
```

If a portable named object is later useful for corpus indexing, it may be a
pure corpus-assembler derivation from the terminal manifest. It must not become
a new runtime writer or authority.

## 7. Falsification Corpus

Possible before QA hand exists:

```text
short versus long rejected traces around corpse trace_tail=32
manifest/corpse mutation controls
grave classification with and without QA metadata
carrier transport of bounded rejection refs into a clean child
```

Blocked by QA-hand implementation:

```text
foreign-seal verdict
cross-generation verdict
conflicting verdicts
malformed QA receipt
timeout
substrate-supplied crystal-shaped table rejected because no acceptor exists
```

## 8. Recommended Next Move

Record one `document_decision`:

```text
outcome A
standalone failure_crystal.v0 removed
rejected-generation terminal projection added as manifest honesty law
qa-check.v0 explicitly deferred with QA hand
```

Then amend TABLE and CRYSTALL consistently. This closes the preimplementation
documentary gate without creating a new runtime schema.

---

Worktree was not modified by the auditor. The report was returned in chat for
the machinist and Codex to classify.
