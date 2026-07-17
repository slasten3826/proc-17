# Fable Review: Death Of Legacy Router Authority - 2026-07-16

Status:

```text
chaos / targeted external review response
author: claude (Mythos/Fable)
reviews: docs/00_chaos/fable_tree_authority_handoff_2026-07-16.md
checkpoint: 49c2e89 + untracked handoff
verdict: diagnosis CONFIRMED with amplification;
         promotion direction supported;
         two correctness blockers found beyond the listed ones;
         one defect class the proposed lifecycle does not cover, with repro
code changes: none (first pass)
```

## 1. Диагноз подтверждён собственным прогоном

Та же rejected-validation жизнь, остановленная за один тик до краша
(`max_ticks = 9`), в граничном тике показывает обе власти рядом:

```text
trace: ☴☵☴☳☴☱☶☱☴
live route at boundary:   ☴ -> ☱   reason=choice_observed
shadow at boundary:       ☰        (highest_pressure_canonical_tie_break)
  ☱ total=0 EXCLUDED: nothing_to_reconcile
```

Legacy коммитит переход в орган, который readiness-aware отбор в тот же момент
исключает с точным типизированным основанием. Это ровно
`conditional organs + unconditional dispatcher`. Контрпримера не нашёл:
в однопоточном runner между derivation и commit состояние не меняется, поэтому
tree-власть по построению не может закоммитить неготовый орган (TOCTOU-класса
пока не существует).

Диагноз, однако, неполон. Диспетчер безусловен в ТРЁХ местах, а не в одном:

```text
(a) readiness      найденная регрессия (☱:nothing_to_reconcile)
(b) run failure    готовый орган, чей run провалился
(c) entry commit   runner_entry коммитит ▽ -> start_operator без кандидатов
```

## 2. Дефект, который предложенный lifecycle не покрывает (репро)

Класс (b). Субстрат, умирающий посреди жизни:

```lua
local calls = 0
local dying_substrate = {
    ask = function(call, o)
        calls = calls + 1
        if calls >= 2 then
            return nil, "substrate_connection_lost"
        end
        return require("substrates.fake").ask(call, o)
    end,
}
tension_runner.run("build notes app", dying_substrate, {work_mode = "build", ...})
-- => nil, "☴:substrate_connection_lost"   (вся жизнь = строковая ошибка harness)
```

Шаги 1-9 протокола закрывают только pre-commit отбор и `no_viable_edge`.
Committed-переход, чей орган начал тик и провалился, остаётся фатальной
строкой. Закона `proposal != committed route` недостаточно; нужен второй:

```text
committed != executed
failed execution of a committed route is a typed body event,
not a harness abort
```

Уровень evidence `committed без executed` в ledger уже есть - у него нет
только поведения. Судьба такого тика - предмет table/crystall (повторная
derivation под новым давлением или типизированная смерть), но не строка.

Класс (c) уже закреплён тестом как норма: `tests/test_tension_runner.lua:179`
утверждает `err == "☴:missing_capability"`. Под новым законом рождение обязано
выводить первое ребро той же derivation (или умирать типизированно), и этот
assert умрёт вместе с legacy-властью.

## 3. Promotion blockers: correctness vs calibration

### Correctness (блокируют переворот default)

```text
C1  у tree-политики нет пути к △ в нормальном build-случае.
    Живой манифест идёт через logic_stamp_no_new_evidence; pressure.manifest
    требует remaining == 0 или exhaustion. Под tree-властью записанная
    дипсик-батарея стала бы 0/5 manifested: единственный успешный терминал
    недостижим. Это не «жизнь пойдёт плохо», это гарантированная потеря
    способности завершать.
    Фикс packet-visible и дешёвый: у manifest-ридера появляется второй
    witness - runtime.logic_stamp.evidence_fingerprint == текущий fingerprint
    при remaining > 0 => "no_new_evidence_possible" => давление к △.
    Штамп и fingerprint уже состояние пакета, harness не нужен.
    (Будущий witness той же категории: completion_state == "complete" из
    camera reconciliation - но он ждёт рук.)

C2  классы (b) и (c) из раздела 1-2: ни одна жизнь не имеет права
    закончиться строковой ошибкой harness. Инвариант: каждая жизнь
    заканчивается terminal record или host tick_limit.

C3  поведение no_viable_edge должно стать законом ДО переворота (раздел 4),
    иначе первый же stall - неопределённость у руля.

C4  △-орган читает options.result (память harness, тики run-report).
    Под tree-властью readiness терминального оператора зависит от harness -
    скрытая власть становится живой. Либо перенести входы манифеста в пакет,
    либо явно пометить △ как временно harness-зависимый орган в promotion
    record.
```

### Calibration (НЕ блокируют; ради них promotion и делается)

```text
relation_debt почти константен -> ☰-аттрактор
upper_observation_debt протухает собственным тиком ☴ -> константа
binary weights и canonical tie-break
воспроизведутся ли рельсы как измеренное поведение
```

Блуждание ограничено бюджетом, mortality-стражи целы, смерть честна и несёт
полный candidate audit в residue. Это информативный корпус, а не опасность.
Лечить вырожденные witnesses ДО переворота не нужно - но C1 обязателен,
иначе весь корпус будет состоять из одних смертей.

## 4. no_viable_edge: ответ из детерминизма

Между тиками тело - замкнутая детерминированная система: нет внешних событий,
нет источника изменений состояния. Следовательно:

```text
same state -> same derivation -> no_viable_edge повторится вечно
```

Любое «подождать» - бесконечный бесплатный цикл по построению. Поэтому:

```text
no_viable_edge => немедленная внутренняя смерть, typed cause "stalled"
residue = полный candidate audit (кто исключён и почему, тотал каждого)
```

Наследник линии получает могилу с точной причиной затыка. Никакой harness
policy, никакого hold-состояния. Если однажды у тела появятся внешние
источники событий (channels, руки, часы среды) - hold можно пересмотреть,
но только с настоящим witness внешнего времени.

`stalled` требует добавления в `packet.death_causes` (сейчас его нет) -
это часть миграции, не расширение онтологии задним числом.

## 5. Аудит lifecycle: бесплатные циклы и скрытая власть

- Шаги 1-7 - фильтрация внутри ОДНОЙ derivation (уже реализована в
  `tree_router.candidates/select`). Пост-commit retry не существует и не
  должен появиться: повторный выбор после отказа живёт только внутри
  следующей derivation следующего тика.
- Q4: отклонённый кандидат меняет только ledger. Давление из факта отказа -
  второй контур управления и петля обратной связи; причины отказа и так
  выводимы из состояния.
- Q2: закона `proposal != committed` недостаточно. Нужны ещё два именованных:
  `commit carries its evidence` (committed route ссылается на pressure
  snapshot и readiness witnesses своей derivation - почти уже записывается)
  и `committed != executed` (раздел 2). С этими тремя граница router/registry
  замкнута, отдельный новый body-boundary не нужен.
- Q9, скрытая власть - три места: пост-commit retry (не строить),
  no_viable_edge policy (сделать законом тела, раздел 4), и C4
  (△ читает harness). Плюс сам `start_operator` - власть harness над первым
  ребром; приемлемо, только если рождение получает свою derivation.

## 6. Невидимая строка решения, которую надо произнести вслух

Переворот власти автоматически отменяет четыре mandatory eye rails и
eye-tick закон в живом маршруте - они живут в `hard_next` legacy и умирают
вместе с ним. До сих пор eye-tick был «закон пока». Promotion record обязан
содержать это отдельным предложением как онтологическое решение, а не
побочный эффект. Тень уже показывает: на контрольном корпусе после лечения
нижнего давления обходятся все четыре рельсы.

## 7. Минимальная безопасная последовательность коммитов

```text
M1  красные интеграционные тесты (без кода):
      rejected-validation жизнь -> typed terminal, не nil-строка
      substrate умирает в середине -> typed terminal
      build с проходящим спеллом -> manifested под router_mode=tree
      рождение без субстрата -> typed, не "☴:missing_capability"
M2  packet core: death cause "stalled"; типизированное событие отказа
    органа; tension_runner перестаёт превращать ошибки registry.run в
    stage_error
M3  manifest witness из logic stamp (C1) + перемер shadow-корпуса
    (ожидание: normal_manifest predicted_triangle > 0)
M4  authority: router_mode=tree разрешён; instrumentation flip
    (legacy пишется как shadow prediction); default пока legacy
M5  evidence: полный corpus + mortality + failure/repair жизни под tree;
    edge evidence v1; отдельным коммитом - переворот default
M6  чистка тестов, закрепляющих старую власть (route prefix asserts,
    choice_observed, строка missing_capability)
```

## 8. Первый красный тест (до кода)

```lua
-- tests/test_tree_authority_survival.lua (имя - предложение)
local p, result = tension_runner.run(<rejected-validation life>, fake, {
    router_mode = "shadow",  -- M1: красный уже в shadow из-за (a)
    work_mode = "build", max_ticks = 20, ...
})
assert_true(p ~= nil, "a life may not end as a harness string error")
assert_eq(p.status, "dead", "life ends in a terminal state")
assert_true(p.terminal ~= nil, "terminal record exists")
assert_true(({budget_exhausted = true, stalled = true, complete = true})
    [p.terminal.cause], "death cause is typed")
```

Сегодня он красный ровно на найденной регрессии; после M2 зелёный в shadow;
после M4 обязан оставаться зелёным под tree.

## 9. Ответы на оставшиеся вопросы handoff одним абзацем каждый

Q6: переворот live/shadow безопасен ДО лечения relation_debt, но ПОСЛЕ
C1-C4: с вырожденным давлением тело блуждает и честно умирает (информация),
без C1 оно не умеет завершаться (потеря функции). Q7: минимальные инварианты
переключения default - все 8 mortality-кейсов под tree; хотя бы одна
manifested build-жизнь под tree; ни одного harness-abort из поведения органа;
routing derivation не тратит budget/loss; legacy shadow пишет divergence.
Q8: полный repair-до-манифеста тест честно невозможен без рук - artefact
не может измениться, значит новая evidence не может родиться; до pipeline A
предел честности - «rejected validation не роняет harness и приводит к
typed terminal с residue, называющим отказ». Тест на настоящую починку
формы - первый тест pipeline A, не этого promotion.

## 10. Что подтверждаю как не подлежащее слому

Список «Что нельзя ломать» из handoff подтверждаю целиком, добавляю одно:
`sampled`-политика и legacy-shadow остаются доступными до тех пор, пока
существует хоть один вопрос вида «куда пошло бы старое тело» - это
контрольная линия всех будущих абляций давления.
