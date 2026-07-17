# Fable Handoff: Death Of Legacy Router Authority - 2026-07-16

Status:

```text
chaos / targeted external-review carrier
checkpoint under review: 49c2e89
decision proposed, implementation not started
code changes are not requested in the first pass
```

## Привет

После твоего аудита коммита `49c2e89 Implement runtime camera
reconciliation` мы воспроизвели найденную регрессию и остановились перед
следующим архитектурным шагом.

Нам сейчас нужен не общий аудит проекта и не подтверждение уже принятого
решения. Нужно проверить конкретный вывод: регрессия является границей между
legacy-router, который всё ещё владеет живым маршрутом, и readiness-aware
физикой нового тела. Если этот вывод неверен или promotion сформулирован
опасно, принеси воспроизводимый контрпример до изменения кода.

Можно ответить сообщением или записать отдельный документ в `docs/00_chaos`.
Код в первом проходе не меняй.

## Что Изменил 49c2e89

Коммит ввёл runtime camera и reconciliation для ☱:

```text
каждый завершённый body tick -> immutable runtime frame
рутинное движение budget/clock -> telemetry, но не generic pressure
значимое непримирённое изменение -> runtime_reconciliation_debt
☱ готов только тогда, когда действительно есть что примирять
визит ☱ двигает monotonic reconciliation watermark
кадр собственного ☱ не создаёт новый долг ☱
```

Одновременно:

- удалён ложный двойной счёт ☱ через `runtime_mismatch`;
- sampled pressure сохранён как контрольная L0-политика;
- `append_trace` теперь deep-copy, поэтому записанный trace payload больше
  нельзя задним числом мутировать по общей ссылке;
- live route намеренно не менялся: legacy остался властью, full-tree router -
  тенью.

Локально подтверждено:

```text
lua tests/run.lua                       -> all tests ok
lua tests/smoke_mortality_battery.lua   -> 8/8
runtime camera treatment smoke          -> green
pressure ablation smoke                 -> green
```

## Найденная Регрессия

Честно проваленная build-валидация завершает весь harness ошибкой:

```text
nil, "☱:nothing_to_reconcile"
```

Минимальный сценарий:

```lua
local tension_runner = require("runtime.tension_runner")
local fake = require("substrates.fake")

local packet, result = tension_runner.run("build notes app", fake, {
    work_mode = "build",
    max_ticks = 14,
    packet_options = {
        budget = {
            steps = 32,
            substrate_calls = 8,
            encode_items = 8,
            loss = 10,
        },
    },
    logic = {
        spells = {
            {
                kind = "check_file_exists",
                name = "missing",
                intention = "force honest rejection",
                path = "sandbox/definitely_missing_runtime_probe.py",
            },
        },
    },
})
```

Механика воспроизведения:

```text
☶ rejects validation
☱ routes to ☴ for semantic repair
☴ produces a new semantic proposal
legacy route_observe sees historical last_choice
legacy proposes ☱ with reason choice_observed
new ☱ readiness says nothing_to_reconcile
operator_registry rejects the tick
tension_runner converts a rejected candidate into a fatal harness error
```

Это не опровержение runtime camera. Наоборот, камера впервые честно говорит,
что пустой ☱ не должен тикать. Ошибка возникает потому, что управляющий маршрут
по-прежнему предполагает: если legacy выбрал орган, орган обязан исполниться.

## Наш Диагноз

Система находится в состоянии частичной миграции:

```text
old live-router:
    selected target == committed transition

new body contract:
    selected target == candidate
    readiness decides whether the transition may be committed

current result:
    conditional organs + unconditional dispatcher
```

Технически два роутера не управляют Packet одновременно:

```text
legacy_after_tick -> live authority
tree_router       -> append-only shadow prediction
```

Но новая readiness-aware физика уже вошла в органы и registry, тогда как
право маршрута осталось у legacy. Поэтому это конфликт двух поколений
архитектуры, даже если только одно из них сейчас держит руль.

Локальная правка `choice_observed` уберёт этот репро, но не класс дефекта.
Следующий условный орган снова сможет получить невозможный committed route.

## Принятое Направление

Решение человека-машиниста и Codex:

```text
legacy-router умирает как власть
tree-router становится живой властью
legacy остаётся тенью, контрольной линией и временным rollback switch
```

Старый роутер не удаляется из истории и не чинится как будущая архитектура.
Он нужен для абляций и для ответа на вопрос «куда пошло бы старое тело».

Главный новый закон:

```text
route proposal != committed route
```

Предполагаемый живой протокол:

```text
1. Router выводит соседние route candidates из Packet pressure.
2. Topology, capability, readiness и affordability проверяются до commit.
3. Неготовый candidate исключается из текущего решения.
4. Отказ candidate записывается в ledger, но не является body tick.
5. Отказ не тратит budget и не создаёт identity loss.
6. Router пересчитывает решение среди оставшихся соседей.
7. Готовый candidate становится committed route.
8. Только завершённый tick принимающего органа становится executed edge.
9. Если жизнеспособных соседей нет, тело получает typed no_viable_edge,
   а не строковую ошибку harness.
```

`no_viable_edge` ещё не означает автоматически смерть или manifest. Это
типизированное физическое состояние, для которого boundary policy должна
отдельно решить дальнейшую судьбу.

## Что Мы Не Хотим Делать

```text
не возвращать ☱ в always-ready
не добавлять пустой платный ☱ tick
не маскировать readiness failure как success
не чинить каждый stale legacy predicate отдельным if
не подгонять pressure weights под старые mandatory rails
не объявлять старые трассы эталоном новой физики
не удалять legacy до сравнительных тестов
```

## Почему Promotion Не Считается Автоматически Безопасным

Мы не предполагаем, что после смены одного флага всё сразу заработает.
Текущий shadow уже показал открытые дефекты:

- `relation_debt` остаётся почти константным и тянет верхнее дерево к ☰;
- `upper_observation_debt` ещё не стал достаточно условным witness;
- ☷ имеет rigidity pressure, но readiness и named reader пока не замкнуты;
- обычный build-manifest использует legacy reason, которого tree policy не
  воспроизводит;
- binary weights и canonical tie-break пока являются контрольной, а не
  измеренной физикой;
- normal completion и semantic repair должны стать Packet-visible pressure,
  а не знаниями harness;
- все четыре mandatory eye rails текущий shadow обходит на контрольном
  корпусе после удаления ложного нижнего давления.

Именно поэтому promotion нужен как наблюдаемая миграция, а не как заявление,
что full-tree router уже правилен.

## Предполагаемая Миграция

Пока это chaos-кандидат, не утверждённый blueprint:

```text
Phase 1  вырастить failing integration test из rejected validation
Phase 2  отделить candidate, rejected candidate, committed и executed
Phase 3  сделать tree authority доступной без удаления legacy
Phase 4  перевернуть instrumentation: legacy prediction становится shadow
Phase 5  прогнать fake corpus, mortality и build failure/repair lives
Phase 6  сделать tree новым default только после runtime evidence
Phase 7  сохранить explicit legacy mode для контрольных абляций
```

Мы ожидаем, что первая tree-authority жизнь может пойти плохо. Это не повод
возвращать старые рельсы; это способ впервые увидеть реальные дефекты pressure
и witnesses. Но promotion не должен нарушить уже подтверждённые finality,
mortality, truth-status, budget/loss separation и corpse immutability.

## Что Просим Проверить

1. Верен ли диагноз «не дефект ☱, а конфликт legacy authority с новым
   readiness contract»? Принеси контрпример, если нет.
2. Достаточно ли закона `proposal != committed route`, или между router и
   registry нужен ещё один явно названный body-boundary?
3. Где должен жить повторный выбор после rejected candidate, чтобы он не стал
   бесплатным бесконечным мета-циклом?
4. Должен ли rejected candidate менять pressure/state или только ledger?
5. Что должен означать `no_viable_edge`: pressure для △, внутренняя смерть,
   запрос нового semantic current или отдельный terminal class?
6. Можно ли безопасно перевернуть live/shadow до лечения вырожденного
   `relation_debt`, если legacy остаётся rollback switch?
7. Какие минимальные invariants должны блокировать переключение default на
   tree authority?
8. Как вырастить end-to-end test, в котором rejected validation не просто не
   роняет harness, а действительно приводит к новой форме, новой проверке и
   честному manifest/death?
9. Не переносим ли мы скрытую власть harness в candidate retry или в
   `no_viable_edge` policy?
10. Найди хотя бы один дефект в этом предложении с конкретным
    воспроизведением или замкнутой контртрассой.

## Что Нельзя Ломать

Подтверждённые части текущего тела:

```text
runtime camera frames are immutable trace records
routine budget/clock movement is telemetry, not generic ☱ pressure
☱ readiness is conditional
reconciliation watermark is monotonic
☱ does not create self-reconciliation debt
append_trace deep-copies payload
budget and identity loss remain separate
death/manifest freeze the Packet
shadow cannot mutate live economics or route
candidate/committed/executed remain distinct evidence levels
```

## Минимальный Порядок Чтения

```text
docs/00_chaos/fable_cold_shadow_audit_raw_2026-07-16.md
docs/00_chaos/pressure_ablation_diagnostic_results_2026-07-16.md
docs/00_chaos/runtime_camera_reconciliation_hypothesis_notes.md
docs/00_chaos/runtime_camera_treatment_results_2026-07-16.md
docs/01_table/yellowprints/operator_tree_physics_yellowprint.v0.md
docs/02_crystall/blueprints/operator_tree_physics.v0.md
runtime/router.lua
runtime/tree_router.lua
runtime/operator_registry.lua
runtime/tension_runner.lua
organs/runtime.lua
runtime/reconciliation.lua
tests/test_shadow_router.lua
tests/test_runtime_camera.lua
tests/test_tension_runner.lua
```

## Желаемый Ответ

Не нужен длинный обзор всей религии. Нужен targeted review:

```text
1. Подтверди или опровергни диагноз собственным прогоном.
2. Раздели promotion blockers на correctness и calibration.
3. Проверь proposed route lifecycle на бесплатные циклы и скрытую власть.
4. Назови минимальную безопасную последовательность migration commits.
5. Дай один первый тест, который должен стать красным до кода.
6. Принеси хотя бы один конкретный дефект или честно скажи, что не нашёл.
```

Мы не просим сохранить старый роутер из уважения к проделанной работе. Его
время как власти закончилось. Вопрос теперь в том, как передать власть полному
дереву так, чтобы новая физика управляла телом, а не только красиво объясняла
его trace.
