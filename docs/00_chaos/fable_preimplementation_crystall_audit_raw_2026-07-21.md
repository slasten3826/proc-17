# Fable Preimplementation Crystall Audit Raw - 2026-07-21

Status:

```text
chaos / external cold-audit evidence
author: Fable / Claude Opus through Claude Code
carrier: supplied by the machinist in chat
scope actually read: six TABLE documents, two chaos sources, supersession
banner, seven resulting CRYSTALL documents, selected runtime contracts
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

Аудит завершён. Отчёт по форме брифа (§9), находки подтверждены точными
строками.

## 0. Мета-находка до отчёта

Бриф просит аудит до кристаллизации, а три документационные таблицы прямо
пишут `crystallization authorized: no` и требуют cross-table audit как гейт
(`corpus` §28, `profiles` §18, `snapshots` §23). При этом в
`docs/02_crystall/blueprints/` уже лежат семь незакоммиченных блюпринтов от той
же даты 2026-07-20, покрывающих ровно эти шесть таблиц.

Бриф велит возвращать аудит в чат, так что прошедший аудит мог не оставить
следа, но в репозитории нет и `document_decision`, фиксирующего, что гейт
кристаллизации был закрыт. Либо гейт нарушен, либо решение не записано. Оба
варианта против собственного закона проекта: решение без ledger-события.

Я аудировал и таблицы, и расхождения блюпринтов.

## 1. Холодная база

```text
git: main @ da89dc8
worktree: 1 modified supersession banner, brief, 6 tables, 7 blueprints, 1 chaos
lua5.4 tests/run.lua -> all tests ok, все gate-сьюты зелёные
lua5.4 tests/smoke_mortality_battery.lua -> 8/8
```

Прочитано:

```text
6 таблиц целиком
2 chaos-дока
баннер старой glyph-таблицы
7 блюпринтов целиком
runtime/repository_result.lua
runtime/network_ingress.lua
runtime/lineage.lua
runtime/lineage_runner.lua
целевые grep-проверки
```

Заявления таблиц о текущем runtime проверены кодом и честны:

```text
repository_result.lua:184 действительно требует ровно один артефакт
carrier.lua:121 принимает carrier.v0 recovery
network_ingress.lua:61 рождает с work_mode = lineage.work_mode
```

Гэп §1 stage-таблицы реален.

## 2. Находки

### F1. Дублированный ключ `generation` в схеме инспекции

```text
class: table contradiction
severity: high
```

`completion_scope_candidate_seal_yellowprint.v0.md:170` объявляет
`generation = 2 | nil`, то есть целое число. Строка 191 в том же
Lua-литерале объявляет `generation = { state = ... }`, то есть блок состояния.

Один ключ имеет два несовместимых контракта. Блюпринт скопировал дефект без
починки: `completion_scope.v0.md:118` и `:156`.

Минимальный контрпример: любая реализация `runtime/completion_scope.lua`
попытается вернуть оба поля. В Lua второй ключ молча затрёт первый. Будет
потерян либо номер поколения, либо state-блок.

Нарушен закон брифа: schemas precise enough to write blueprints without
inventing policy.

Минимальная правка на уровне TABLE: переименовать второй блок, например в
`generation_state`, в таблице и блюпринте.

Блокирует `completion_scope.v0` и транзитивно `work_layer_projection.v0`.

### F2. TOCTOU-окно в порядке seal-транзакции

```text
class: transaction/document divergence
severity: medium
runtime implementation: absent
crystall treatment: already correct
table amendment: missing
```

Таблица §8 задаёт порядок:

```text
inventory at step 2
seal_pending only at step 5
```

Между ними materialization grant остаётся жив. Авторизованное действие может
создать новый absent path после инвентаризации и до закрытия власти.
`root_fingerprint` является идентичностью корня, а не digest содержимого, поэтому
проверка шага 8 не обязана увидеть новый файл. Печать может описать мир без
этого файла.

Это нарушает законы таблицы:

```text
a seal must describe the world that exists
C16a: undeclared path appears in seal inventory
```

Блюпринт `candidate_seal.v0.md` §1 уже вводит правильный порядок:

```text
seal_pending
-> invalidate leases
-> inventory
-> commit closure
```

Минимальная правка: амендировать §8 таблицы или явно пометить старый порядок
как superseded ссылкой на crystall §1.

### F3. `context` молча сменил словарь между TABLE и CRYSTALL

```text
class: identity/provenance defect
severity: medium
```

Таблицы фиксируют:

```text
context = "software_task.v0"
```

Это находится в `nested_work_layer_derivation_yellowprint.v0.md:109` и
`completion_scope_candidate_seal_yellowprint.v0.md:172`.

Оба блюпринта заменили значение на идентификатор процессного контракта:

```text
work_layer_projection.v0.md:98
completion_scope.v0.md:120

"plan.only.v0" | "build.only.v0" | "software.create.v0"
```

Сам `process.contract.v0` содержит оба поля:

```text
process_contract_id = "software.create.v0"
context = "software_task.v0"
```

Значит это разные координаты. Snapshot-конверт сохранил старый словарь как
`work_context = string`. Холодный читатель, соединяющий snapshot work_context
с projection context, получит несовпадающие vocabulary.

В отличие от F2, этот переход нигде не задекларирован.

Минимальная правка: одно решение во всех таблицах и блюпринтах. Либо context
остаётся `software_task.v0`, а блюпринты добавляют отдельное поле
`process_contract_id`, либо таблицы явно амендируются под другой словарь.

### F4. Failure crystal является несущим контрактом без схемы

```text
class: table underspecification
severity: medium
```

`Exact typed failure crystal` является входом для:

```text
completion scope
build B2/B3
S13/S14/L8/L13 controls
recovery carrier payload
corpus object kind
failure_crystal_recorded snapshot boundary
```

QA verdict имеет хотя бы conceptual schema (`qa.verdict.v0`), но у failure
crystal нет `protocol_version`, identity law или точного модуля-писателя ни в
одной из шести таблиц и семи блюпринтов.

Writer matrix называет `exact build failure-crystallization path`, но сам путь
не специфицирован. Инспектор B2 обязан отличить exact typed crystal от residue,
но его признак не определён. Реализация будет вынуждена изобрести схему.

Смягчение: QA целиком отложено. Failure crystal можно явно отложить вместе с
QA. Тогда это должно быть записано в deferrals derivation-таблицы, потому что
сейчас B2/B3 выглядят готовыми к crystall.

### F5. Статус стадии `rejected` не имеет писателя

```text
class: status without writer
severity: medium
```

Stage-таблица §5 определяет:

```text
rejected = process contract declares stage terminal failure
```

Но в схеме `process.contract.v0` нет поля или политики, объявляющей, когда
стадия, а не поколение, становится rejected. Нет `max_attempts` или другого
критерия.

Ни один путь runner §18 не пишет этот статус. Ветки дают:

```text
complete
recovery
suspend
terminate
```

Это статус без стражника. Минимальная правка: убрать `rejected` из v0 enum или
назвать точное декларирующее поле контракта.

### F6. Неблокирующие расхождения

```text
severity: low
```

1. Формат `stage_id` расходится: `stage:build:2` в completion table и artifact
   set против `stage:<lineage>:2:build` в stage table. Короткая форма коллидирует
   между lineage.
2. `seal_ref` и `seal_id` находятся рядом в candidate-блоке, но различие не
   определено.
3. `boundary_candidate` enum содержит `unsupported` в completion table, но не
   в derivation table и blueprint.
4. `choice_committed` отображается в `01_table` или `02_crystall` без правила
   выбора. Registry-as-data будет вынужден изобрести дизамбигуацию.
5. Applicability vocabulary разросся без реестра:
   `reentry_proposal`, `inherited_proposal`, `corpus_reentry_proposal`,
   `grave_pressure`.
6. Corpus generation entry требует `corpse_id`, то есть живое поколение нельзя
   включить. Законность экспорта на ledger head с активным поколением явно не
   запрещена и не разрешена.

Остаточный риск вне скоупа: ни одна таблица не говорит, как grave/karma
классифицирует `qa_rejected` поколение. Прошлый паттерн producer/consumer может
повториться на новом terminal-классе.

## 3. Подтверждённые сквозные инварианты

- Completion/economics separation выдержана: кошелёк нигде не меняет intrinsic
  оценку.
- Иммутабельность поколений согласована: no reopen/patch, recovery означает
  свежий Packet и свежий repository.
- Рекурсия receipt закрыта: corpus не включает собственный receipt, delivery
  envelope является внешней границей.
- Subject ceiling согласован: Packet/corpse никогда не производит
  `software_accepted` или `root_delivery`.
- `structured_content_id` корректно исключает profile и доказываемо проецирует
  тот же structured content.
- Двухledgerная экономика документации согласована между TABLE и CRYSTALL.
- Per-object version coverage применяется как закон свежести во всех новых
  контрактах.
- Supersession banner старой glyph-таблицы корректен; in-place repair отозван.

## 4. Матрица готовности к CRYSTALL

| Crystall | Вердикт |
|---|---|
| `completion_scope.v0` | ready after F1 rename and F3 context correction |
| `work_layer_projection.v0` | ready after F3; inherits F1 |
| `candidate_seal.v0` | ready; amend TABLE transaction order for F2 |
| `stage_transition_generation_recovery.v0` | ready after F5; explicitly defer F4 |
| `documentation_profiles_economy.v0` | ready |
| `documentation_layer_snapshots.v0` | ready after work_context follows F3 |
| `documentation_corpus_assembly_reentry.v0` | ready |

Порядок зависимостей из брифа корректен. `completion_scope -> artifact_set` из
`candidate_seal` законно разрешён через `unsupported`.

## 5. Рекомендуемый следующий ход

Один минимальный шаг: амендировать дублированный `generation` F1 в таблице и
блюпринте. Это единственный дефект, который гарантированно взорвётся на первой
реализации `completion_scope.lua`; правка занимает две строки.

F2, F3 и F5 идут следом одним amendment-проходом до начала имплементации.

Файлы аудитор не трогал. В index ничего не добавлял. Отчёт возвращён в чат;
дальше машинист и Codex решают, что станет chaos-residue, а что будет принято
как amendment.
