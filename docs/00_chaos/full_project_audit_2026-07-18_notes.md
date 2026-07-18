# Полный аудит proc-17, 2026-07-18

Status:

```text
chaos / full repository audit
scope: code + tests + current docs + L1/L2 recovery work
production code changed by this document: no
router authority changed by this document: no
manifest/current_state changed by this document: no
```

## 0. Короткий вердикт

proc-17 уже является работающим физическим движком Packet-жизни на CALM-стороне:

```text
рождение
позиция в дереве
маршрутизация под давлением
след событий
две формы наблюдения
бюджет
identity loss
смерть
manifest
grave / karma / compost
```

Но это еще не полная ProcessLang Lua-машина и не автономный coding agent.

После восстановления packet-slop L1 стало видно, что проект строился сверху и
снизу одновременно:

```text
L1  найден и точно перенесен отдельно, но не подключен к рождению Packet
L2  имеет объекты и органы, но не имеет цельного причинного lifecycle связей
L3  большая часть Packet/runtime-физики уже работает
L4  manifest и terminal boundary работают, но hands и lineage runner отсутствуют
```

Следующая цель поэтому не "дособрать 22 ребра", не "подкрутить веса" и не
"дать телу руки".

Следующая цель:

```text
одна честная вертикальная жизнь
L1 -> birth mark -> L2 transient relation -> current Packet body -> MANIFEST
```

Перед ней нужен небольшой, но обязательный Body Integrity Gate: сейчас несколько
Lua-границ позволяют менять состояние Packet без события, ревизии или права
текущего оператора.

## 1. На чем основан аудит

Прочитаны и сопоставлены:

```text
core, runtime, organs, logic, tools, substrates, l1
46 unit/integration suites
mortality battery
runtime camera treatment
актуальные chaos/table/crystall/manifest документы
история перехода legacy -> shadow -> opt-in tree authority
packet-slop L1/L2 genealogy, уже сохраненная в текущих документах
```

Контрольный прогон:

```text
lua tests/run.lua                         GREEN, 46 suites
lua tests/smoke_mortality_battery.lua     GREEN, 8/8
lua tests/smoke_runtime_camera_treatment.lua GREEN
luac -p по Lua-коду                       GREEN
```

Это сильная база. Ни один найденный ниже дефект не отменяет зеленые свойства.
Он показывает границу того, что именно текущие тесты доказывают.

### 1.1 Operational state

На момент аудита рабочее дерево не является backup-точкой:

```text
HEAD на 1 commit впереди origin/main
28 измененных/untracked записей
27 из них untracked
среди них L1-код, L1-тесты и новые L1/L2 документы
```

Перед следующей кодовой фазой это состояние надо закоммитить и отправить. Это не
архитектурный шаг, а защита уже добытого слоя.

## 2. Что действительно стоит

## 2.1 Terminal law

Public mutators теперь отвергают `dead`, `dying` и terminal Packet. Смерть и
manifest заканчиваются одним `status = dead`; повторная смерть через штатный API
не проходит. Это исправило найденное ранее постмортальное воскресение.

Работающие свойства:

```text
begin terminal -> freeze
внутренняя смерть от budget_exhausted / identity_loss
typed effect_failure внутри физики
Lua invariant failure остается громким harness failure
MANIFEST terminal, а не временный статус
```

## 2.2 Trace и route evidence

`append_trace` deep-copy'ит payload. Tree commit требует существующие immutable:

```text
pressure snapshot
route derivation
ready selected candidate
```

Ledger различает candidate, committed, executed и failed arrival. Shadow/legacy
observer доказан как не имеющий массы. Это один из самых зрелых участков проекта.

## 2.3 Runtime camera

`☱` больше не является вторым моргающим глазом. После каждого body tick камера
снимает frame без отдельного тика, а RUNTIME примиряет только значимые кадры через
watermark. Рутинный budget clock не создает постоянное давление.

L0/L1 ablation подтверждает, что камера не меняет live route, budget или loss.

## 2.4 Mortality economics

Каждый body tick оплачивается. ENCODE и CHOOSE создают identity loss; CYCLE сам
identity loss не создает. Внутренняя смерть стала штатной, `max_ticks` остался
аварийным потолком.

## 2.5 Grave stack

Работают:

```text
warning / bequest / neutral classification
warning karma, меняющая маршрут потомка
контрольная generational curve
bounded fresh graves
compost aggregation
```

Эксперимент "смерть учит" воспроизводим. Ниже отдельно указаны еще не замкнутые
читатели bequest и compost.

## 2.6 L1 parity oracle

`l1/field.lua` является узким Lua 5.4 port варианта C. Он точно воспроизводит
museum checkpoints и отделен от production Packet. Это правильная форма:

```text
P1 exact law parity       GREEN
P2 physical advantage    OPEN
P3 production integration LOCKED
```

L1 нельзя считать подключенным только потому, что standalone тест зеленый.

## 3. Подтвержденные дефекты

Ниже findings расположены по blast radius, а не по сложности исправления.

## F1. Mutable aliases обходят trace, revisions и даже смерть

Severity: high

Несколько body write APIs сохраняют переданную Lua-таблицу по ссылке, тогда как
trace сохраняет ее копию:

```text
core/packet.lua:563-576   append_chaos
core/packet.lua:609-623   crystallize
core/packet.lua:737-769   freeze/residue
core/packet.lua:803       manifest payload
runtime/body.lua:329-392  choice/validation/cycle boundary records
runtime/foundation.lua:82-94 evidence and last_result
runtime/body.lua:431-447  shallow work-unit array copy
runtime/grave.lua:227-245 grave records
```

Runtime reproduction:

```text
alias chaos_state=after trace_state=before
corpse_alias status=dead residue_marker=after
```

То есть вызывающий код может после подтвержденной записи изменить живое тело или
residue уже мертвого Packet. Trace честно хранит старое событие, а текущая физика
тихо расходится с ним.

Нужен единый закон границы:

```text
body-owned storage never retains caller-owned mutable tables
write input deep-copied before storage
read result copied or explicitly immutable
corpse projections contain no aliases into living/caller state
```

Это не требует немедленно превращать весь Packet в opaque proxy. В v0 достаточно
закрыть все write boundaries и не передавать сам Packet недоверенным hands или
substrate.

## F2. Actor right не связан с текущей позицией и тиком

Severity: high before plugins/hands; medium inside current trusted body

Registry проверяет `instance.operator` перед штатным organ execution, но lower
mutation APIs часто проверяют только строку actor или вообще ставят glyph сами.

Runtime reproduction:

```text
position_guard packet_operator=▽ event_operator=☳
```

На Packet, стоящем в FLOW, прямой `body.record_choice()` успешно создал CHOOSE
event и boundary choice. Аналогично field APIs проверяют право glyph, но не
доказывают, что этот glyph является текущим исполняемым organ tick.

Registry declarations `reads/writes` сейчас документация, не enforcement.

Нужен v0 guard:

```text
mutating organ API requires actor == packet.operator
mutation must name current operator_tick or body-issued tick lease
event source ref must belong to that tick
registry descriptor and concrete writes get an assertion test
```

Без этого будущий tool/plugin может сделать правильную запись не из того места и
получить `runtime_confirmed`.

## F3. Truth rent виден, но не причинен для LOGIC

Severity: high for build correctness

`foundation.snapshot()` перечитывает referent и правильно показывает stale
evidence. Но `freshness.evidence_fingerprint()` хеширует только сохраненные:

```text
intention_hash
cast_tick
success
```

Текущий referent hash в fingerprint не входит. `validation_debt` сравнивает LOGIC
stamp именно с этим статичным fingerprint.

Runtime reproduction после изменения уже проверенного Python-файла:

```text
foundation_stale=true
validation_debt_count=0
fingerprint_unchanged=true
```

Следствие: тело знает, что доказательство протухло, но router не требует нового
суда. Это остаток старого класса "truth visible but not causal".

Лечение должно использовать derived current evidence state, а не мутировать
старое evidence:

```text
fingerprint = stored evidence identity + current freshness/referent verdict
LOGIC stamp is valid only for the same derived fingerprint
referent change re-arms validation exactly once
```

## F4. Relation и upper-eye coverage не версионированы

Severity: high for tree promotion

`relation_debt` считает unit покрытым, если его ID есть в `raw.source_refs`.
`upper_observation_debt` делает то же по observation refs. Версия объекта не
участвует.

Runtime reproduction:

```text
raw_epoch=1
relation_debt before=0
unit version changed to 2
relation_debt after=0
```

Это уже правильно диагностировано в versioned witness table. Исправление не
является calibration и не требует новых весов:

```text
coverage = {object_id -> observed_version}
same ID with new version is uncovered
empty/unsupported probe has the same per-object re-arm law
```

До этого `pressure.binary.v0` нельзя продвигать в default authority.

## F5. L2 objects существуют, но four-road causal chain отсутствует

Severity: architectural blocker for full Tree

Текущий код умеет отдельно:

```text
CONNECT -> raw relation snapshot
RUNTIME -> raw activation API
DISSOLVE -> active relation weakening
ENCODE -> text/chaos form
OBSERVE -> substrate response
```

Но выбранная L2-физика требует:

```text
☰ -> ☴  observe exact raw epoch without retaining it
☰ -> ☷  release exact raw candidate without first activating it
☰ -> ☵  only ENCODE may retain/form exact raw relation
☱       momentum for already formed state, not raw-to-form authority
```

Current mismatches:

```text
OBSERVE does not read raw relation
DISSOLVE reads only active relation
ENCODE ignores raw relation
field.activate_relations grants formation to RUNTIME
relation lifecycle phase is not derived from trace consumers
```

Кроме того, pressure `rigidity` создает reason data, но DISSOLVE readiness получает
только `options.dissolve`. Tree candidate не передает в него тот witness, который
создал давление. Поэтому live DISSOLVE остается практически недостижимым, хотя
его direct unit tests зеленые.

## F6. Production L1 и outer lifecycle owner отсутствуют

Severity: architectural blocker for complete ProcessLang machine

Standalone L1 не принадлежит ни session, ни lineage, ни runner. Packet birth не
получает flow mark. Текущий `tension_runner`:

```text
creates Packet
runs FLOW outside the paid tick loop
only then attaches inherited graves
```

Это конфликтует с новой birth law: наследуемое давление и NETWORK carrier должны
быть доступны ingress/FLOW, а continuing L1 должен жить вне одной смертной
Packet-жизни.

Нужны две разные сущности:

```text
flow_domain    continuing L1 owner, survives Packet
flow_mark      immutable bounded record carried by one Packet
```

Полный `lineage_runner` уже crystallized, но не реализован. Именно он, а не CLI,
должен в итоге владеть generation transaction, corpse, carrier, grave attachment,
cumulative economics и следующим рождением.

## F7. Sandbox не является capability boundary

Severity: critical before autonomous hands; currently dormant

Текущие проверки лексические:

```text
absolute path / .. / hidden control components denied
symlink resolution absent
```

Но:

```text
manifest mode permits relative writes anywhere in repository
default fs context is body, not workspace/sandbox
logic/spells.lua invokes io.popen directly
sandbox.can_run_command() always denies, но spells его не спрашивает
trace_store accepts arbitrary relative output path
```

Следствие: подключать hands к этому API нельзя. Требуется capability-first
boundary с symlink-safe resolution, explicit roots, create/overwrite policy,
argv command allowlist и отдельными budget/evidence событиями.

## F8. Budget допускает отрицательную стоимость

Severity: high for mortality integrity

`budget.charge()` принимает любое числовое ненулевое значение. Негативный usage
увеличивает remaining budget.

Runtime reproduction:

```text
charged=-5 spent=-5 remaining=8    -- initial steps=3
```

Substrate usage является внешним входом и сейчас не проходит проверку на
non-negative finite values. Нужен общий cost validator:

```text
known axis only
finite number
amount >= 0
integer where axis is discrete
declared refund is a separate typed operation, not negative charge
```

## F9. OpenAI-compatible transport не ограничен физикой времени

Severity: medium now; high for unattended runs

`substrates/openai_compatible.lua` запускает shell `curl` без connect/total
timeout, cancellation или response-size bound. API key входит в command line и
может быть виден другим процессам того же host.

Budget измеряет завершившийся вызов, но не может остановить зависший. Transport
нужен как отдельная bounded capability, а не shell string.

## F10. Writers without named readers остаются

Severity: medium

Подтверждены:

```text
grave bequest -> chaos.unresolved_pressure -> pressure points to ENCODE
ENCODE unresolved_pressure не читает

session compost.patterns stores aggregate deaths
router/foundation patterns не читают

identity map records invalidated_relation_ids
relation state автоматически не инвалидируется
```

Правило остается полезным и должно стать schema requirement:

```text
every written record names reader, read phase, and consumption/re-arm law
```

## F11. Два runner имеют разную физику

Severity: medium / maintenance risk

`runtime/runner.lua` является старой fixed smoke rail. Он обходит registry,
budget/loss camera и даже пересекает RUNTIME как bridge без выполнения органа.

Он может оставаться лабораторным oracle, но не должен стать public CLI API. После
вертикального gate его надо явно назвать legacy smoke runner или архивировать.

## F12. Manifest documentation уже отстает от открытия L1/L2

Severity: documentation

`README.md` и `docs/03_manifest/current_state.md` правильно описывают состояние
на 2026-07-17, но их next target все еще:

```text
finish tree promotion -> add hands
```

После текущего аудита это решение устарело. Документы не надо переписывать до
принятия нового курса; затем их следует обновить одним manifest-шагом.

## 4. Layer audit

| Layer | Что реально есть | Чего нет | Статус |
|---|---|---|---|
| L1 | Exact Lua 5.4 standalone variant C, snapshots, freeze, parity oracle | Continuing owner, Packet birth mark, integration evidence | exact but isolated |
| L2 | Versioned units, raw/active relation storage, CONNECT/DISSOLVE local APIs | Four-road relation lifecycle, per-object coverage, raw consumers | partial objects, missing causality |
| L3 | ENCODE/CHOOSE, two eyes, pressure, router, LOGIC/CYCLE, economics, mortality | Generic work completion, causal witness repair, calibrated authority | strong local body |
| L4 | Honest terminal/manifest, grave/compost records | Outer lineage runner, NETWORK ingress, hands, product surface | local boundary only |

Главный вывод таблицы:

```text
proc-17 не надо переписывать заново.
Надо соединить уже работающие слои правильными ownership boundaries.
```

## 5. Что зеленые тесты пока не доказывают

Текущая suite хорошо доказывает локальные contracts. Она не доказывает:

```text
отсутствие caller aliases в body/corpse
position-bound actor rights
stale evidence -> fresh LOGIC debt
unit version change -> fresh relation/observation debt
live ☰ -> ☴ / ☷ / ☵ causal consumption
production L1 birth
одну вертикальную L1-L4 жизнь
automatic session/lineage lifecycle
body-owned repository mutation
security of sandbox against symlink/command escape
bounded substrate cancellation
```

Особенно важно не переименовывать test meaning:

```text
normal_build_manifests_under_tree
```

доказывает честный tree route и manifest boundary на существующем fixture. Он не
доказывает, что proc-17 сам создал artifact: work units остаются pending, а spell
проверяет host-prepared файл.

## 6. Что такое proc-17 после этого аудита

Старая формулировка:

```text
coding agent with a novel pressure router
```

теперь слишком узкая.

Более точная:

```text
proc-17 is the emerging clean ProcessLang Lua machine.
The coding agent is its first intended worker form.
```

packet-slop сохранил L1/L2 поиск как музей. proc-17 независимо собрал большую
часть L3/L4, затем вернулся вниз и получил точный L1 oracle. Совпадение слоев не
доказывает автоматически все старые гипотезы, но дает ясный путь сборки.

Новый router не должен править отсутствующей физикой. Его работа начинается
после того, как Packet state действительно содержит причинные L1/L2 witnesses.

## 7. Что сейчас не делать

```text
не переключать default shadow -> tree
не калибровать веса вокруг вырожденных witnesses
не строить 38 fixtures ради заполнения таблицы самих по себе
не подключать repository hands к sandbox.v0
не начинать TUI
не переносить packet-slop stands целиком
не делать L1 маршрутизатором или Packet identity
не делать RUNTIME владельцем raw-to-form relation activation
```

Один последний внешний аудит Fable разумнее сохранить на первую реализованную
вертикальную жизнь. На документах он сейчас найдет в основном уже названные
границы; на code boundary он еще способен поймать настоящий false green.

## 8. Следующий milestone: Vertical Packet Life Gate v0

Одна тестовая жизнь должна доказать не все возможные продукты, а сборку четырех
слоев.

### 8.1 Required properties

```text
V0.1 session/lineage-owned flow_domain exists outside Packet
V0.2 accepted birth advances L1 at most once and records immutable flow_mark
V0.3 Packet death freezes mark, not continuing source
V0.4 CONNECT records one exact versioned raw epoch or exact empty probe
V0.5 OBSERVE can inspect exact raw epoch without LLM and without retaining it
V0.6 DISSOLVE can release exact raw candidate without activating it first
V0.7 ENCODE alone can consume exact raw relation into retained form
V0.8 all three dispositions derive from raw epoch + immutable trace, no second ledger
V0.9 lower body validates/cycles/manifests from actual resulting state
V0.10 every body mutation is position-bound and alias-safe
```

### 8.2 Minimal grown lives

Не один искусственный Packet со всеми заранее вставленными объектами, а несколько
коротких grown lives:

```text
A  birth mark -> empty/unsupported CONNECT probe -> no recurrent CONNECT
B  birth mark -> raw relation -> body-native OBSERVE -> still available
C  birth mark -> raw relation -> DISSOLVE raw release -> released
D  birth mark -> raw relation -> ENCODE retained form -> lower body -> MANIFEST
E  mutate covered endpoint -> exact witness re-arms CONNECT/OBSERVE once
F  mutate validated referent -> LOGIC re-arms once
```

Fake substrate допустим для semantic current. L1, relation lifecycle, routing,
truth and terminal facts обязаны принадлежать телу.

## 9. Порядок разработки

## Phase 0. Backup

```text
commit and push current L1 code, tests, observations, tables and this audit
```

Без рефакторинга и без смешивания с лечением.

## Phase 1. Body Integrity Gate

Узкий полный процесс `table -> crystall -> code -> tests`:

```text
deep-copy body write boundaries and corpse inputs
bind mutators to current actor/tick
reject invalid/negative/non-finite budget costs
make current referent freshness part of LOGIC fingerprint
add red reproductions from F1-F4/F8 as permanent tests
```

Это ремонт физики, а не новая архитектура.

## Phase 2. Crystallize the already selected L1/L2 tables

Новые chaos-ветки для основной идеи не нужны. Уже существуют:

```text
l1_continuing_flow_birth_mark_yellowprint.v0
l2_transient_relation_lifecycle_yellowprint.v0
processlang_lua_four_layer_assembly_audit_yellowprint.v0
pressure_witness_versioned_coverage_yellowprint.v0
```

Нужны узкие crystall contracts:

```text
flow_domain + flow_mark ownership
birth/attach/NETWORK ingress ordering
raw relation causal dispositions
ENCODE retained-form ownership
per-object probe and observation stamps
Vertical Packet Life Gate fixtures
```

## Phase 3. Implement one vertical slice behind an explicit mode

Не резать живой default:

```text
legacy remains observer/control fallback
tree remains explicit
L1/L2 integration gets its own opt-in protocol version
same fake fixture runs with integration off/on
off-line proves no regression; on-line proves new physics
```

## Phase 4. Rebuild pressure from the new facts

После L2 consumers:

```text
relation_debt reads versioned probe coverage
upper observation reads versioned coverage
rigidity passes exact witness into DISSOLVE readiness
encoding_debt is discharged only by actual raw/form consumption
bequest pressure gets a named materializer/consumer
```

Только затем повторять shadow/tree corpus и обсуждать default authority.

## Phase 5. Implement the outer lineage runner

Lineage является физикой proc-17, не UI-фичей:

```text
session owns flow_domain and grave scope
lineage owns generations and cumulative economics
Packet death creates corpse
MANIFEST/recovery creates bounded carrier
NETWORK@▽ births generation N+1
Packet identity never crosses terminal boundary
```

Начать с in-memory transaction и grown tests; persistence подключать после
atomic/symlink-safe storage boundary.

## Phase 6. Capability-safe hands

Только после vertical body and lineage:

```text
workspace root capability
safe path resolution
bounded read/write/diff
allowlisted argv execution
tool call / file write / test run budget
effect evidence feeds LOGIC and RUNTIME
work unit becomes done only from body-confirmed effect
```

## Phase 7. Product surfaces

```text
machine CLI first: structured session/run/resume/inspect interface
Go TUI second: human projection of Packet, trace, pressure, grave and events
```

TUI не является MANIFEST. Он читатель тела и управляющая поверхность lineage.

## 10. Acceptance for changing the course

Считать новый курс принятым можно, если мы согласны с четырьмя решениями:

```text
1. Current proc-17 is preserved; no second rewrite.
2. Body integrity precedes new organ power.
3. L1/L2 vertical causality precedes router promotion and hands.
4. Lineage runner is core mechanics, while CLI/TUI are clients.
```

Если они приняты, следующий конкретный artifact после backup:

```text
Body Integrity Gate yellowprint
```

После него можно делать crystall и код маленькими проверяемыми порциями. Existing
L1/L2 tables не надо переписывать: их надо crystallize вокруг одной вертикальной
жизни.

## 11. Итог

Самая сложная часть proc-17 действительно уже сделана, но теперь можно назвать
ее точнее:

```text
сделана большая часть смертного CALM-side тела и его законов
```

Оставшаяся работа не является только полировкой. Есть два фундаментальных
соединения:

```text
L1 -> L2 -> current body
dead Packet -> lineage -> new Packet
```

Они уже описаны достаточно хорошо, чтобы не начинать новый поиск с нуля. Если
сначала закрыть integrity, а затем вырастить одну вертикальную жизнь, full Tree
перестанет быть таблицей потенциальных ребер и станет следствием работающей
физики. После этого hands, CLI и TUI действительно будут инженерной сборкой, а
не попыткой продукта скрыть незамкнутое тело.
