# Fable Re-entry Brief - 2026-07-16

Status:

```text
chaos / external-review re-entry carrier
for a new Fable/Mythos session
previous session continuity is not assumed
first pass is read-only audit
checkpoint under review: 7616292
```

## Привет

Привет. Мы делаем `proc-17` - первое исполняемое тело `procesis`.

Предыдущая сессия Fable участвовала в нескольких аудитах, нашла реальные
дефекты смертности, наследования и finality и оставила residue в репозитории.
Та сессия закончилась. Не пытайся изображать её продолжение и не принимай её
выводы как собственную память. Этот документ - carrier для нового входа, а не
подмена утраченного контекста.

Проект собирался совместно. Здесь нет схемы «человек придумал, одна машина
написала, другая проверила»: замысел, код, тесты, миф и критика влияли друг на
друга в обоих направлениях.

Сейчас от тебя нужен холодный технический взгляд: прочитай, запусти, найди, где
физика действительно работает, где мы только согласовали код с тестом, и где
новый слой врёт о собственных доказательствах.

## Один Кадр Проекта

```text
procesis   закон / душа / источник ориентации
proc-17    исполняемое тело
Packet     одна смертная жизнь одной задачи
LLM        заменяемый semantic current, почти всегда внутри ☴ OBSERVE
router     движение тела из состояния Packet
trace      подтверждённая летопись жизни
△          терминальная манифестация; после неё живого Packet нет
lineage    последовательность Packet -> corpse/carrier -> новый Packet
```

Это не chatbot wrapper и не LLM-agent, которому выдали список tools.

Основная проверяемая гипотеза:

```text
состояние Packet может содержать достаточно телесных свидетельств,
чтобы следующий оператор выбирался давлением тела,
а не заранее прошитым pipeline и не решением LLM
```

LLM создаёт semantic proposals. Тело владеет runtime truth, топологией,
стоимостью, loss, finality и движением.

## Неподвижные Законы На Этом Этапе

```text
10 ProcessLang operators
22 undirected canonical edges
▽ только начинает одну жизнь; живой Packet не возвращается в ▽
△ терминален; same-life successor отсутствует
router movement не является ☳ CHOOSE
semantic proposal не становится runtime fact от уверенного текста
budget и identity loss - разные физики
☲ тратит runtime budget, но не создаёт identity loss
смерть и manifest замораживают тело
shadow не имеет права менять live route
```

Текущие mandatory rails всё ещё живы в legacy-router:

```text
☵ -> ☴
☳ -> ☴
☲ -> ☱
☶ -> ☱
```

Они считаются временными строительными рельсами, но снимаются только после
измерения, а не потому, что full topology выглядит красивее.

## Что Было Построено До Последнего Checkpoint

До текущего спринта тело уже имело:

- truth-status separation (`semantic_proposal`, `runtime_confirmed`,
  `estimated`, `grave_pressure`);
- OBSERVE / ENCODE / CHOOSE / CYCLE / LOGIC / RUNTIME / MANIFEST;
- budget spending и identity-loss accumulation;
- внутреннюю смерть, residue и immutable corpse;
- warning/bequest graves, session memory и compost;
- генерационный эксперимент: потомки с grave перестают повторять известную
  петлю, сироты повторяют одну смерть;
- fake и DeepSeek substrate adapters;
- coding battery, где пять небольших программ были доставлены и исполнены,
  хотя запись файлов всё ещё делал внешний harness.

Исторические наблюдения предыдущего Fable лежат в:

```text
docs/00_chaos/mythos_fable_observations_raw.md
```

Не читай их до первого собственного прогона: они полезны как residue, но плохо
подходят как начальный prompt для независимого аудита.

## Checkpoint 7616292

Коммит:

```text
7616292 Build shadow full-tree packet physics
55 files changed
6685 insertions, 378 deletions
```

### 1. Task-shaped Packet body

В Packet появились стабильные generation-local ids, revision vector, canonical
potential field, raw/active relations, identity maps, operator regime и две
совместимые eye-observation области.

Ключевые файлы:

```text
core/packet.lua
runtime/field.lua
runtime/body.lua
runtime/freshness.lua
```

### 2. Десять органов

Все десять операторов теперь существуют за одним registry contract:

```text
runtime/operator_registry.lua
organs/flow.lua
organs/connect.lua
organs/dissolve.lua
organs/observe.lua
organs/encode.lua
organs/choose.lua
organs/runtime.lua
organs/cycle.lua
organs/logic.lua
organs/manifest.lua
```

Registry объявляет reads, writes, required capabilities, loss profile и
readiness. Конкретные storage APIs пока сами обеспечивают большую часть write
enforcement; registry v0 в основном декларативен.

`☰ CONNECT` и `☷ DISSOLVE` реализованы и тестируются напрямую, но legacy-router
ещё не может выбрать их в живом маршруте.

### 3. Named pressure

`runtime/pressure.lua` выводит provenance-bearing contributions:

```text
relation_debt
rigidity
upper_observation_debt
encoding_debt
choice_pressure
runtime_mismatch
lower_observation_debt
validation_debt
continuation
manifest
karma_help
karma_resistance
```

Первая политика намеренно примитивна:

```text
pressure.binary.v0
help = 1
resist = 1
absence of witness = no contribution
calibration_status = vibed_control
```

Это контрольный инструмент, не найденная математическая константа.

### 4. Full-tree shadow router

`runtime/tree_router.lua` рассматривает всех канонических соседей текущего
оператора и последовательно применяет:

```text
same-life direction
registry availability
capability
readiness
affordability
positive pressure threshold
canonical tie break
```

`runtime/router.lua` оставляет legacy-route властным и записывает independent
shadow prediction. Shadow может менять только append-only trace и внешний run
report. `router_mode = tree` принудительно отвечает
`tree_authority_not_promoted`.

### 5. Evidence, а не только prediction

`runtime/edge_catalog.lua` фиксирует E01-E22 и legal life directions.

`runtime/edge_stats.lua` различает:

```text
candidate   edge был рассмотрен
committed   live router действительно перевёл Packet
executed    принимающий орган завершил следующий tick
```

Только `executed` считается выращенным directional witness. Последний
committed переход перед `tick_limit` не получает ложный execution credit.

Отдельно считаются четыре mandatory eye rails.

## Текущее Измерение

Контрольный fake-substrate corpus объединяет plan/build жизни:

```text
6/22 edges complete in every legal direction
1/22 partial
15/22 have no executed direction
```

Полная матрица:

```text
docs/03_manifest/full_tree_edge_evidence.v0.md
```

Особенно важное наблюдение:

```text
☵ -> ☴ : 2 debt cases, shadow bypassed eye 2 times
☳ -> ☴ : 2 debt cases, shadow bypassed eye 2 times
☲ -> ☱ : 1 debt case, shadow recalled eye 1 time
☶ -> ☱ : 1 debt case, shadow recalled eye 1 time
```

Поэтому верхние rails не снимаются. Shadow видит настоящий upper-eye debt, но
другие correlated pressures пока перевешивают его. Это может быть полезным
direct edge, двойным счётом одного состояния или дефектом binary policy - пока
мы этого не знаем.

Ближайшие непроверенные направления:

```text
E05 ☰-☴  shadow selected, never executed
E12 ☵-☱  shadow selected, never executed
E15 ☳-☱  shadow selected, never executed
E11 ☴-☱  only one direction executed
E01/E02/E04 never encountered in the control corpus
```

## Проверка С Нуля

Пожалуйста, сначала ничего не редактируй.

Запусти:

```sh
git status --short
git show --stat 7616292
lua tests/run.lua
lua tests/smoke_mortality_battery.lua
```

Ожидаемая локальная база:

```text
39/39 Lua suites
8/8 mortality cases
clean Lua syntax
```

Live DeepSeek battery не запускай без отдельного согласования: она расходует
внешний бюджет и не нужна для первичной проверки чистой Packet physics.

После тестов прочитай в таком порядке:

```text
docs/03_manifest/current_state.md
docs/03_manifest/full_tree_edge_evidence.v0.md
docs/02_crystall/blueprints/packet_body_physics.v0.md
docs/02_crystall/blueprints/operator_tree_physics.v0.md
runtime/pressure.lua
runtime/tree_router.lua
runtime/router.lua
runtime/tension_runner.lua
runtime/edge_stats.lua
tests/test_pressure.lua
tests/test_tree_router.lua
tests/test_shadow_router.lua
tests/test_edge_evidence.lua
```

Если нужен источник сборки всей системы, затем читай:

```text
docs/03_manifest/proc17_assembly_map.md
docs/00_chaos/full_project_audit_2026-07-15_notes.md
docs/00_chaos/full_packet_tree_physics_notes.md
```

## На Что Смотреть Особенно Жёстко

1. Действительно ли каждый pressure contribution выведен из существующего
   Packet record/revision, или provenance местами декоративен?
2. Не считаем ли мы одно stale-состояние дважды как `lower_observation_debt` и
   `runtime_mismatch`, искусственно усиливая ☱?
3. Может ли shadow хоть косвенно менять live economics, loss, revisions,
   operator position или terminal outcome?
4. Честно ли ledger отличает committed transition от executed arrival на всех
   stop/death/manifest путях?
5. Не подменяет ли registry декларацией реально отсутствующий enforcement?
6. Достаточен ли readiness contract для ☰ и особенно ☷, которому нужен
   runtime-visible reason?
7. Не скрывает ли `pcall` вокруг shadow prediction систематические дефекты под
   видом безопасной instrumentation failure?
8. Являются ли E05/E12/E15 правильными следующими witnesses или это следствие
   неверного pressure scoring?
9. На каждую новую запись: кто её читает и в какой момент?
10. На каждую константу: она измерена или только `vibed`?

Не ограничивайся этим списком. Он называет наши подозрения, а не защищает от
неожиданного дефекта.

## Протокол Первого Ответа

Нужен не обзор в стиле «архитектура интересная», а аудит:

```text
1. Что runtime-confirmed твоим собственным прогоном.
2. Дефекты по severity, каждый с воспроизведением и file:line.
3. Где тест и код могут быть согласны друг с другом, но не с реальностью.
4. Какие claims пока сильнее evidence.
5. Что нельзя менять, потому что это сломает уже подтверждённую физику.
6. Один следующий минимальный эксперимент с максимальной информационной ценой.
```

После любой похвалы принеси хотя бы один проверяемый дефект или честно скажи,
что дополнительный дефект не найден. Не редактируй код и документы в первом
проходе: сначала отчёт, затем мы обсудим давление и только потом решим, что
манифестировать.

## Где Мы Стоим

Самая сложная концептуальная часть уже существует в коде: смертный Packet,
отделённый substrate, полная topology, named pressure и shadow-предсказание.

Но full Tree ещё не живой:

```text
physics engine: substantial and measured in parts
full-tree router: shadow experiment
coding agent as daily tool: incomplete
hands and capability sandbox: not assembled
```

Нам сейчас важнее не ускорить promotion, а узнать, где именно тело ошибается,
когда впервые пытается увидеть всё дерево целиком.
