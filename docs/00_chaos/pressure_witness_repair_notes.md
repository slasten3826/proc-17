# Pressure Witness Repair Notes

Status:

```text
chaos / post-shadow-audit synthesis
checkpoint: 7616292 Build shadow full-tree packet physics
trigger: cold Fable QA audit + direct Codex code inspection
authority: working technical frame, not table, crystall, or runtime law
step_10: blocked
live_router: legacy remains authoritative
shadow_router: measurement instrument only
```

Sources:

```text
docs/00_chaos/fable_cold_shadow_audit_raw_2026-07-16.md
docs/00_chaos/full_packet_tree_physics_notes.md
docs/00_chaos/packet_lineage_reentry_architecture_notes.md
docs/02_crystall/blueprints/operator_tree_physics.v0.md
docs/03_manifest/full_tree_edge_evidence.v0.md
runtime/pressure.lua
runtime/body.lua
runtime/freshness.lua
runtime/tree_router.lua
runtime/router.lua
runtime/tension_runner.lua
```

## 1. Зачем Нужен Этот Документ

Первый full-tree shadow sprint сделал почти всё, что от него требовалось:

```text
появилось полное дерево
появились именованные pressure contributions
появился независимый shadow prediction
появился candidate / committed / executed ledger
live route не изменился
ошибочная новая политика не получила власть
```

После этого холодный аудит обнаружил, что большая часть текущего pressure vector
не несёт различающей информации. Числа существуют, provenance существует, код
детерминирован, но несколько pressure witnesses почти постоянны или дублируют
друг друга.

Поэтому текущая задача не называется "подкрутить веса".

Текущая задача:

```text
понять, какие наблюдаемые изменения действительно создают давление,
какие только являются историческими фактами,
и какие являются ожидаемым следствием действия самого органа
```

Этот документ должен вернуть контекст человеку и дать следующей таблице
правильные вопросы. Он намеренно не выбирает окончательную реализацию.

## 2. Простая Картина

Сейчас тело умеет замечать, что счётчик изменился.

Но оно ещё не всегда умеет отличить:

```text
"что-то изменилось"
"изменилось что-то важное"
"изменение ещё никто не учёл"
"из-за изменения нужен именно этот орган"
```

В первой shadow-политике эти ступени местами схлопнулись:

```text
revision changed
  -> observation stale
  -> eye debt = 1
  -> pressure toward eye
  -> candidate score
  -> route prediction
```

Первый переход является фактом. Остальные являются интерпретацией этого факта.

Именно интерпретация сейчас сломана.

## 3. Что Подтверждено И Не Является Провалом

### 3.1 Shadow isolation работает

Cold audit воспроизвёл:

```text
39 Lua suites pass
8/8 mortality cases pass
legacy and shadow lives spend the same steps
legacy and shadow make the same substrate calls
legacy and shadow accumulate the same identity loss
shadow cannot move the live Packet
```

Это означает, что обнаруженные ниже дефекты не заразили рабочий legacy route.

### 3.2 Edge ledger различает намерение и событие

Три состояния не схлопнуты:

```text
candidate  ребро было рассмотрено
committed  authoritative router выбрал переход
executed   принимающий орган действительно завершил tick
```

Последний committed transition перед `tick_limit` не получает ложный executed
witness. Эта граница должна сохраниться.

### 3.3 Полное дерево не опровергнуто

Аудит не показал, что pressure-driven routing невозможен.

Он показал более узкое утверждение:

```text
pressure.binary.v0 в текущем наборе witnesses
не содержит достаточно варьирующейся информации для live authority
```

Это различие важно. Мы проверяем не веру в дерево, а конкретную физическую
реализацию его датчиков.

## 4. Четыре Разных Слоя, Которые Нельзя Смешивать

Следующая таблица и кристалл должны явно различать:

| Layer | Вопрос | Пример |
|---|---|---|
| record | Что реально произошло? | `budget revision 3 -> 4` |
| freshness | Совпадает ли старое чтение с текущим состоянием? | lower eye is stale |
| witness | Значит ли разница, что существует неудовлетворённая потребность? | budget crossed near-death threshold |
| pressure | К какому соседнему оператору и с какой силой тянет эта потребность? | help `☱` or `△` |

Правильный record может породить неправильный witness.

Правильный witness может быть направлен не к тому оператору.

Правильное pressure contribution ещё не гарантирует правильный route, если
другие contributions дублируют тот же источник.

## 5. Два Глаза И Конструктивная Протухлость

### 5.1 Верхний глаз

Текущий `☴ OBSERVE` выполняет примерно такую транзакцию:

```text
1. читает upper revisions
2. вызывает substrate
3. записывает semantic proposal в CHAOS
4. записывает upper-eye observation с revisions из шага 1
5. добавляет новый potential unit
6. potential revision изменяется
```

После шага 6 observation фактически stale. Это исторически честно: поле после
действия уже не совпадает с полем, прочитанным перед действием.

Переход `☴ -> ☴` не существует, поэтому немедленного self-loop нет.

Но долг не исчезает. После следующего оператора ☴ снова может стать соседним
кандидатом, а его debt всё ещё равен единице. Поэтому локально корректная
протухлость превращается в почти постоянный routing signal.

### 5.2 Нижний глаз

Текущий `☱ RUNTIME` читает, среди прочего:

```text
budget
loss
calm
evidence
history
constraints
```

После каждого body tick `budget.charge` безусловно увеличивает budget revision.
Следовательно, даже только что выполненный lower observation протухает после
обычной оплаты следующего шага.

Это тоже фактически честно: бюджет действительно изменился.

Но обычная ожидаемая цена одного тика не обязательно означает:

```text
"нужно снова идти в ☱"
```

Значимыми могут быть не все изменения бюджета, а, например:

```text
переход через warning threshold
невозможность оплатить следующий tick
неожиданное отклонение от заявленной стоимости
смена exhausted / payable state
```

### 5.3 Наш предыдущий вывод был локально верным

Ранее мы решили, что stale-after-own-action не является ошибкой, потому что
глаз не соединён сам с собой.

Уточнение после аудита:

```text
нет немедленного self-loop                 true
staleness является честным фактом          true
любой stale обязан давать eye pressure     false
```

Проблема не в freshness ledger. Проблема в функции:

```text
freshness -> routing debt
```

## 6. Возможная, Но Пока Не Принятая Развязка Глаз

Один кандидат для будущей таблицы:

```text
read_revisions
  что глаз действительно прочитал

acknowledged_revisions
  какое состояние завершённая транзакция глаза уже признаёт своим
  ожидаемым результатом и не требует немедленно перечитывать
```

Другой кандидат:

```text
не добавлять второй watermark,
а классифицировать revision deltas по actor/source/reason
```

Например:

```text
self-produced expected delta       не создаёт generic eye debt
external or downstream delta       может создать debt
threshold-changing economic delta  создаёт runtime/manifest pressure
unknown delta                      создаёт observation pressure
```

Третий кандидат:

```text
оставить strict freshness как есть,
но сделать отдельный relevance reader для routing
```

Эти варианты нельзя выбирать в хаосе. Таблица должна сравнить их по правам,
стоимости, named readers и способности быть протестированными.

## 7. D1: Runtime Mismatch Сейчас Не Является Mismatch

Текущие readers:

```text
lower_observation_debt
  читает latest lower eye
  если stale, даёт +1 к ☱

runtime_mismatch
  снова читает latest lower eye
  если stale и CALM существует, даёт ещё +1 к ☱
```

Один источник создаёт два именованных contributions.

Это нарушает не только арифметику, но и смысл имени.

Настоящий runtime mismatch должен иметь отдельный comparator, например:

```text
CALM ожидает work state A, runtime подтверждает B
selected relation не установлена в active runtime view
claimed evidence fingerprint не совпадает с текущим evidence
installed form отстаёт от подтверждённого execution result
```

Если такого comparator пока нет, честное поведение v0:

```text
runtime_mismatch emits no contribution
```

Переименовать второй stale в mismatch или дать ему меньший вес нельзя. Это
скроет дефект, а не исправит его.

## 8. Как Из Этого Получился Ложный Router

Текущая политика:

```text
каждый witnessed help kind = +1
каждый witnessed resistance kind = -1
при равенстве используется canonical tie-break
```

В наблюдённом корпусе:

```text
обычный кандидат  0 или 1
☱                2, когда CALM существует и lower eye stale
```

Отсюда:

```text
E12 ☵-☱  выбирается из-за двойного счёта ☱
E15 ☳-☱  выбирается из-за двойного счёта ☱
E05 ☰-☴  выбирается как первый canonical кандидат среди равных единиц
```

Следовательно, текущие E05/E12/E15 нельзя выращивать как доказательство
правильной физики. Сначала нужно проверить, исчезают ли они при абляции
вырожденных readers.

## 9. Edge Witness Не Равен Semantic Witness

Матрица `6 complete / 1 partial / 15 absent` честно говорит о выполненных
направлениях рёбер.

Но выполненный glyph transition ещё не доказывает семантику органа.

Пример E10:

```text
edge: ☴ -> ☳
executed count: present
field alternatives: one
CHOOSE result: confirmation
killed alternatives: zero
identity loss from choice: zero
```

По собственному контракту proc-17 это confirmation, а не выбор.

Следующая evidence table должна хранить отдельно:

```text
edge executed
organ semantic preconditions satisfied
organ produced its distinguishing effect
```

## 10. Manifestation Пока Не Выводится Из Packet Полностью

### 10.1 Pressure gap

Текущий `manifest` pressure появляется, если:

```text
remaining work == 0
or budget exhausted
or identity near death
```

Но живой build-route сейчас завершает полезную работу через legacy condition:

```text
logic_stamp_no_new_evidence
```

Shadow reader этого условия не выражает. В момент нормального legacy manifest
shadow предлагает вернуться к ☵. Если дать tree-router власть сейчас, пакет
может продолжать ☵/☴/☱ до budget death вместо нормального △.

### 10.2 Carrier gap

`organs/manifest.lua` собирает часть результата из `options.result.ticks`, то
есть из run-report внешнего harness.

Это означает:

```text
Packet state недостаточен для последнего органа
```

Для основной гипотезы proc-17 это promotion blocker. △ должен читать
manifestable material и completion evidence из Packet. Runner может вывести
готовый carrier наружу, но не должен тайно возвращать органу память всей жизни.

## 11. DISSOLVE Получает Причину Не Из Тела

`pressure.rigidity` уже способен вывести typed dissolve reason.

Но `organs/dissolve.lua` readiness требует `options.reason`, переданный внешним
caller/harness. Tree-router выбирает ☷ по pressure, но принимающий орган не
получает witness, который породил этот выбор.

Получилась новая запись без читателя:

```text
pressure derives dissolve_reason
router selects or considers ☷
dissolve readiness asks harness for options.reason
```

Возможные будущие формы:

```text
router commits a typed route_intent with source refs,
then destination organ reads that intent
```

или:

```text
dissolve independently derives readiness from the same Packet records
```

Первый вариант делает причину перехода явной. Второй уменьшает coupling, но
рискует дважды реализовать одну derivation. Решение принадлежит таблице.

## 12. Trace Пока Append-only Только Наполовину

`append_trace` сохраняет `payload` по ссылке. После append caller может изменить
ту же таблицу, и уже записанное событие изменится задним числом.

Примеры текущего поведения:

```text
CHOOSE пишет event, затем меняет field_shadow.status
router пишет snapshot, затем добавляет trace_event_id в исходный payload
```

Список событий append-only, но содержимое события не immutable.

Это особенно важно сейчас, потому что pressure provenance и edge evidence
ссылаются на trace как на runtime-confirmed историю. До promotion trace payload
должен получить snapshot/freeze boundary.

Операционная severity пока medium, потому что shadow не управляет телом.
Эпистемическая severity high, потому что изменяемая летопись не может быть
окончательным доказательством.

## 13. Диагностические Дефекты

### 13.1 Вакуумная проверка

Тест читает:

```text
edge_stats_error
```

Runner пишет:

```text
edge_stats_errors
```

Проверка всегда сравнивает отсутствующее поле с `nil` и всегда проходит.

### 13.2 Prediction error смешан с физическим исходом

Ошибка shadow reader внутри `pcall` может превратиться в `prediction_error`, а
агрегатор частично считает это рядом с `no_prediction` / `no_viable_edge`.

Нужно различать:

```text
no viable physical edge
no positive pressure
instrumentation failure
reader failure
router failure
```

Ошибка измерительного прибора не является состоянием Packet.

### 13.3 Registry остаётся декларативным

Registry правильно собирает права органов в одном месте, но пока не является
полным enforcement boundary. Ложная декларация `writes` может не быть поймана.

Это не причина откладывать shadow experiments, но это отдельный blocker перед
полной властью и особенно перед подключением hands.

## 14. Почему Шаг 10 Закрыт

Под шагом 10 этого спринта понимается:

```text
дать full-tree router live authority
и начать снимать mandatory eye rails
```

Сейчас это запрещено, потому что:

```text
pressure vector в основном состоит из констант
☱ получает duplicate contribution
normal completion не ведёт shadow к △
☷ не получает собственный readiness witness
manifest material частично живёт вне Packet
trace payload можно изменить после записи
partial prediction failures не имеют отдельного типа
```

Если выполнить шаг 10 сейчас, мы получим не полное дерево, а другой hardcoded
router, скрытый внутри арифметики и canonical tie-break.

Все четыре rails остаются authoritative scaffolding.

## 15. Что Нельзя Ломать Во Время Ремонта

```text
corpse finality and terminal freeze
budget / identity-loss separation
truth-status separation
shadow isolation from live economics and route
candidate / committed / executed distinction
field actor rights and rollback behavior
canonical 22-edge topology
LLM exclusion from route authority
all four mandatory rails until new evidence exists
```

Особенно важно: ремонт witnesses не является поводом переписать topology или
вернуть решение маршрута substrate.

## 16. Следующий Минимальный Эксперимент

Cold audit предложил shadow-only абляцию на том же control corpus.

Её смысл не в том, чтобы сразу выбрать исправление. Её смысл в том, чтобы
доказать или опровергнуть диагноз о вырожденных signals.

Контроль:

```text
C0 current pressure.binary.v0
```

Минимальные варианты:

```text
A  runtime_mismatch disabled
B  budget/loss revision deltas excluded only from lower eye routing debt
AB both changes together
```

Важно:

```text
strict freshness records остаются неизменными
live legacy route остаётся неизменным
rails остаются неизменными
tree authority остаётся запрещённой
никакие веса не калибруются
```

Сравнивать нужно:

```text
per-tick contribution vectors
number of varying vs constant readers
shadow predicted edges
legacy/shadow agreement
rail recall and bypass
E05/E12/E15 selection
prediction errors
no-viable-edge outcomes
```

Прогноз аудита:

```text
E12/E15 исчезнут после удаления duplicate runtime_mismatch
E05 окажется tie-break artifact
lower rail recall превратится в bypass
agreement with legacy резко упадёт
```

Если прогноз подтверждается, вывод будет узким и сильным:

```text
до настройки весов нужно пересобрать pressure witnesses
```

Если не подтверждается, значит в текущем поле уже существуют другие
варьирующиеся причины, которые аудит недооценил.

## 17. Вопросы Для Таблицы

Для каждого pressure kind таблица должна ответить:

```text
какой exact record является источником
кто и когда записывает record
кто и когда читает record
какая component revision связана с ним
может ли witness меняться внутри реальных lives
является ли delta self-produced или внешней
является ли delta ожидаемой или неожиданной
какое условие discharge
не дублирует ли он другой pressure kind
какой target operator или edge получает contribution
как readiness принимающего орган получает source refs
какой тест выращивает witness настоящим прогоном
```

Отдельные открытые вопросы:

1. Нужны ли глазам `acknowledged_revisions`, или достаточно typed revision
   causes?
2. Должен ли routine budget charge влиять только на threshold pressures, а не
   на generic lower-eye debt?
3. Что является Packet-local runtime mismatch?
4. Что является Packet-local completion, usable partial и manifest material?
5. Передаёт ли router committed pressure witness принимающему органу?
6. Как различить edge execution и distinguishing semantic effect органа?
7. Где должна происходить immutable trace snapshot: внутри `append_trace` или
   на каждом public event constructor?
8. Какие failures shadow-прибора должны немедленно проваливать corpus run?

## 18. Предварительный Порядок Работы

```text
1. сохранить raw cold audit                                  done
2. собрать этот chaos frame                                  done
3. построить pressure-witness + ablation yellowprint         next
4. кристаллизовать shadow experiment contract
5. манифестировать только experiment harness and diagnostics
6. прогнать C0/A/B/AB на одном corpus
7. записать runtime result обратно в chaos
8. отдельно кристаллизовать физический repair witnesses
9. исправить trace and diagnostic defects
10. повторно измерить shadow
11. обсуждать promotion только после нового evidence record
```

Простой D5 typo можно исправить быстро, но baseline абляции должен оставаться
воспроизводимым. Нельзя незаметно смешать ремонт прибора и эксперимент над
физикой.

## 19. Итог Хаоса

Первый full-tree sprint построил не готовую волю, а первый прибор для её
измерения.

Прибор показал:

```text
топология доступна
маршруты наблюдаемы
изоляция работает
ledger честен
но текущие witnesses ещё не образуют живой градиент
```

Следующий слой должен начинаться не с коэффициентов и не с удаления рельсов.

Он начинается с более строгого вопроса:

```text
какая разница в состоянии Packet действительно требует движения,
а какая только доказывает, что время прошло и тело заплатило за жизнь?
```

## 20. Diagnostic Update - 2026-07-16

The C0/A/B/AB experiment is recorded in:

```text
docs/00_chaos/pressure_ablation_diagnostic_results_2026-07-16.md
```

Outcome:

```text
D1 duplicate runtime_mismatch                     confirmed
☵ -> ☱ and ☳ -> ☱ shadow selections             removed by D1 ablation
both apparent lower-rail recalls                  removed by D1 ablation
budget/loss exclusion alone                       affects only 2/12 lower debts
pre-first-☱ missing lower observation             causes 10/12 lower debts
normal manifest gap                               confirmed in C0/A/B/AB
E05 disappears forecast                           rejected; E05 rises through tie-break
all E12 disappears forecast                       rejected; reverse ☱ -> ☵ survives
```

Therefore the next work item is no longer "grow E05/E12/E15". It is the L0/L1
shadow treatment experiment for continuous runtime camera and reconciliation
debt, after trace payload immutability is repaired.

## 21. Treatment Update - 2026-07-16

The L0/L1 treatment is recorded in:

```text
docs/00_chaos/runtime_camera_treatment_results_2026-07-16.md
```

Work-order state:

```text
3. pressure-witness + ablation yellowprint                  done
4. shadow experiment contract                               done
5. diagnostic harness                                       done
6. C0/A/B/AB corpus                                         done
7. diagnostic result                                        done
8. physical repair witnesses                                done for camera; other blockers open
9. trace immutability and D5 diagnostic typo                done
10. L0/L1 shadow remeasurement                              done
11. promotion discussion                                    blocked by manifest, ☷, calibration
```

The camera treatment removes the duplicate and routine lower pressure while
retaining bounded significant-frame debt. It does not yet calibrate tied
candidate selection and therefore does not authorize step 10 authority
promotion.
