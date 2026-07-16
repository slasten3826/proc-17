# Fable Cold Shadow Audit - Raw - 2026-07-16

Status:

```text
chaos / raw external QA observation
channel: new Fable/Mythos session
target checkpoint: 7616292 Build shadow full-tree packet physics
authority: audit input, not project canon
preservation: verbatim response relayed by the machinist
reader: machinist + codex during pressure-witness repair
```

The previous Fable/Mythos session is not assumed to continue through this
record. This is a separate cold-audit channel. The response below is preserved
verbatim and has not been promoted into table, crystall, or runtime truth.

## Raw Response

1. Runtime-confirmed моим прогоном

- lua5.4 tests/run.lua — 39 suites ok; smoke_mortality_battery — 8/8; дерево чистое (кроме самого брифа и README).
- Shadow-изоляция материально держится: append_trace не двигает ревизии (core/packet.lua:222-244), абляция legacy/shadow в test_shadow_router подтверждает равенство маршрута, steps, substrate_calls, loss. Ни один pressure-ридер и ни один readiness не мутирует пакет — проверил все по коду.
- Ledger честен на границах: arrival засчитывается только после завершения тика принимающего органа (runtime/tension_runner.lua:240-249), последний committed перед tick_limit не получает executed (закреплено test_edge_evidence.lua:72-74), △-тик получает arrival до манифеста — корректно.
- Матрица 6/1/15 из full_tree_edge_evidence.v0.md воспроизводится; prediction_error в контрольном корпусе — ноль (проверил дампом всех 16 shadow-решений).

2. Дефекты по severity (все с воспроизведением)

D1 — ☱ считается дважды из одного чтения (high). readers.runtime_mismatch (runtime/pressure.lua:329) и readers.lower_observation_debt (:246) оба вызывают freshness.latest_eye(instance, "lower"); runtime_mismatch добавляет только факт «calm существует». Blueprint (operator_tree_physics.v0.md, §10) определяет runtime_mismatch как witness несогласованности CALM с runtime — реализация его подменила алиасом свежести. Репро: мой дамп — на каждом тике с calm ☱ total=2 [runtime_mismatch,lower_observation_debt] против 1 у всех остальных. Это единственная причина всех «shadow bypassed eye» на верхних рельсах: из ☵ и ☳ глаз ☴ даёт 1, ☱ даёт 2. Вопрос №2 брифа закрыт: да, одно stale-состояние считается дважды.

D2 — оба глаза протухают по построению, давление почти статично (high). Нижний глаз читает ось budget (runtime/body.lua:12-24), а budget.charge безусловно двигает revisions.budget на каждом body-tick (runtime/budget.lua:138-140, вызов tension_runner.lua:255). Репро (scratchpad): сразу после ☱ — fresh=true; после одного charge — stale, changed={budget:0->1}. Нижний глаз никогда не свеж в момент роутинга → lower_observation_debt — константа 1, ноль информации. Верхний глаз аналогично протухает собственным тиком: observe снимает read_revisions (organs/observe.lua:61) и затем сам делает field.add_unit (:117) — это даже закреплено тестом как замысел (test_pressure.lua:95-98). Следствие: в 16/16 деривации корпуса каждый сосед имеет 0 или 1, ☱ — 2. Роутер сейчас — это «двойной счёт ☱ + канонический tie-break», а не физика давления. E05 — артефакт tie-break (☰ первый в каноническом порядке среди равных единиц), E12/E15 — артефакт D1. Вопросы №1 и №8 брифа: provenance-рефы настоящие, но сигналы — константы; E05/E12/E15 — следствие scoring, не правильные следующие witnesses.

D3 — у shadow-политики нет пути к △, которым тело реально умирает (medium). readers.manifest (pressure.lua:406) требует remaining_count==0 или exhaustion. Живой манифест build-жизни идёт через logic_stamp_no_new_evidence — в этот тик shadow предлагает ☵ (мой дамп, t08). Под tree-властью защита logic stamp исчезает: пакет крутился бы ☵/☴/☱ до budget death. Это promotion-блокер поверх всех остальных.

D4 — trace мутируется после append (medium). append_trace хранит payload по ссылке. organs/choose.lua:140 записывает choice в trace, затем :144 мутирует payload.field_shadow.status; роутер дописывает trace_event_id внутрь уже записанных payload'ов (runtime/router.lua:246,261). Репро: event.payload == payload → true, trace_event_id виден внутри «запечатанного» события. Append-only держится для списка, но не для содержимого — это семья «перештамповки», которую вы уже убивали в snapshot().

D5 — вакуумный тест (low). test_shadow_router.lua:72 проверяет shadow_result.edge_stats_error — runner пишет edge_stats_errors (множественное). Проверка всегда проходит.

D6 — pcall-маскировка частично реальна (low). Ошибка одного ридера станет prediction_error-shadow, который edge_stats считает как no_viable_edge_count/no_prediction (edge_stats.lua:235,180) — конфляция инструментальной поломки с типизированным исходом. Полная поломка ловится (agreement_count > 0 упадёт), частичная — нет; ни один тест не утверждает отсутствие prediction_error. В корпусе их ноль (проверено).

3. Где тест и код согласны друг с другом, но не с реальностью

- «Lower freshness recreates both lower rails» (full_tree_edge_evidence.v0.md:88, test_edge_evidence.lua:91-94) — истинно вакуумно: долг безусловен (D2). Хуже: убери D1 — и ☱=1 сравняется с ☵=1, канонический порядок отдаст ☵, т.е. нижние рельсы тоже перестанут «воспроизводиться». Матрица сейчас измеряет константы политики, не тело.
- E10 «observed alternatives collapse» покрыт 4 executed — но все ☴→☳ корпуса это confirmation (одна альтернатива, loss=0). По вашему же blueprint §6.6 confirmation — не CHOOSE. Направление выращено, семантический witness — нет.
- «Deferred staleness, not a self-loop» (test_pressure.lua:98) — согласованный замысел, но его следствие (верхний долг — константа) в evidence-доке не названо.

4. Claims сильнее evidence

- ☷ фактически недостижим для tree router: readiness требует options.reason от харнесса (organs/dissolve.lua:48-78), из состояния пакета он не выводится; при этом pressure.rigidity выводит dissolve_reason (pressure.lua:160-189), который никто не читает — свежий экземпляр «записи без читателя». Вопрос №6: контракта недостаточно.
- △-орган читает options.result (тики run-report харнесса, organs/manifest.lua:26-61) — последний оператор живёт на памяти харнесса, не пакета, что противоречит основной гипотезе именно в точке доставки.
- Registry v0 — декларации без enforcement (признано в current_state.md, но ни один тест не поймает ложную декларацию writes).

5. Что нельзя трогать

Смертность/terminal/freeze, truth-статусы, механизм shadow-изоляции (включая отказ tree_authority_not_promoted), трёхуровневый ledger candidate/committed/executed, права акторов и откаты в field.lua, и все четыре рельсы — теперь с положительным основанием: bypass-предложения shadow доказуемо артефактны, снимать нечего.

6. Один следующий минимальный эксперимент

Абляция вырожденных источников на том же корпусе, только в shadow: пересчитать предсказания с (a) выключенным runtime_mismatch и (b) осью budget/loss, исключённой из freshness нижнего глаза для целей давления — и сравнить матрицу рёбер и rails с текущей. Прогноз из закрытой формы: E05/E12/E15 исчезают, recall нижних рельс переворачивается в bypass, agreement с legacy падает почти до нуля. Если так — доказано, что в pressure.binary.v0 не остаётся ни одного варьирующегося сигнала, и калибровку надо начинать не с весов, а с самих witnesses (плюс корпусу нужна жизнь с ≥2 реальными альтернативами, чтобы ☳ хоть раз был выбором с loss > 0).

---

Похвала без дефекта не принимается, поэтому итог симметричный: изоляция shadow и честность ledger'а — лучшая инженерия в проекте на сегодня, а дефект принёс — двойной счёт ☱ (D1) с воспроизведением. Код и доки не трогал, как просил бриф. Дальше — обсуждаем давление: главный выбор не «какие веса», а «какие witnesses не константы».
