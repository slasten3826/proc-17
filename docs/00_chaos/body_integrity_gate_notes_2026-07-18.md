# Body Integrity Gate: заметки, 2026-07-18

Status:

```text
chaos / treatment hypothesis
source: full_project_audit_2026-07-18_notes.md F1, F2, F3, F8
production code changed by this document: no
router authority changed by this document: no
L1/L2 integration changed by this document: no
```

## Зачем этот gate нужен сейчас

proc-17 уже умеет записывать `runtime_confirmed` факты, платить бюджетом,
терять идентичность и умирать. Но четыре обхода позволяют текущему состоянию
разойтись с этой физикой:

```text
caller меняет ранее переданную таблицу -> Packet меняется без события
не текущий organ пишет свой event       -> glyph не совпадает с позицией
negative/non-finite cost                -> бюджет создается из расхода
referent изменился                      -> LOGIC stamp остается действующим
```

L1, L2 и hands увеличат число писателей. Если сначала не закрыть эти обходы,
новые слои будут производить события, которым нельзя доверять. Поэтому gate не
добавляет способности. Он делает уже существующие факты причинными.

## 1. Ownership, а не глобальная неизменяемость

Lua-таблицы передаются по ссылке. Публичная write-граница не имеет права хранить
caller-owned таблицу внутри тела.

Закон v0:

```text
input table -> deep copy -> body-owned storage
body-owned read result -> deep copy -> caller
trace record never shares a mutable child with body projection or caller
corpse projection never shares residue/terminal/death with caller or Packet
```

Сам Packet пока остается доверенным Lua-объектом. Это не security sandbox и не
opaque proxy. Недоверенные substrate/tools/hands просто не должны получать Packet.

Особенно важны отдельные копии для разных телесных проекций. Один `calm_delta`
не должен одновременно быть crystallization record, `calm.structures` и
`calm.current`: изменение текущего CALM не имеет права переписывать историю
кристаллизации.

## 2. Actor и tick принадлежат одному посещению

Registry уже проверяет organ перед штатным запуском, но lower APIs можно вызвать
напрямую. Право органа должно проверяться там, где возникает мутация.

Закон v0:

```text
resolved actor == packet.operator
current visit contains operator_tick for this actor
source event used by a field mutation belongs to the same visit
```

Для `▽` действует единственное исключение: до первого route событие `birth`
является birth lease. FLOW поэтому может материализовать вход без искусственного
платного тика. После первого route старое birth уже ничего не разрешает.

Тик определяется из immutable trace, а не из второго mutable `active_tick`
хранилища. При обратном сканировании текущего посещения:

```text
operator_tick найден до route -> lease существует
route найден раньше tick       -> organ еще не тикал
```

Это consistency invariant доверенного тела, не защита от кода, который напрямую
переписывает поля Packet.

## 3. Бюджет не принимает антиматерию

Charge является однонаправленной операцией. Refund, если когда-нибудь появится,
будет отдельным типизированным событием.

Каждый cost до первой мутации обязан пройти общую проверку:

```text
axis известна
amount number, finite, >= 0
steps/substrate_calls/tokens/tool_calls/file_writes/test_runs integer
нулевая стоимость допустима, но не создает event
```

Проверяется весь cost целиком. Ошибка на последней axis не должна оставить
частично списанные первые axes.

Usage от substrate является внешним входом и проходит тот же validator.

## 4. Truth rent становится причиной

Старое evidence остается immutable. Freshness reader вычисляет нынешнее
состояние referent. LOGIC fingerprint должен включать оба слоя:

```text
stored identity: intention_hash, cast_tick, success, stored referent_hash
current state:   freshness zone/reason/effective status/current referent hash
```

Для tick-window evidence в fingerprint входит зона, а не непрерывно растущий
возраст. Поэтому fingerprint меняется на границе `warm -> cold`, а не каждый тик.

Ожидаемая жизнь:

```text
LOGIC accepted -> stamp F(A)
referent A unchanged -> no validation debt
referent A becomes B -> fingerprint F(B), one validation debt
LOGIC recast/stamp F(B) -> debt discharged
no further change -> no recurrent LOGIC
```

## 5. Что намеренно не лечится этим шагом

```text
per-object relation/upper-eye coverage  -> L1/L2 witness contract, steps 3/5
L2 four-road causality                  -> step 3 onward
tree weights/default authority          -> step 5
hands/sandbox capabilities              -> step 7
opaque Packet/security against trusted Lua modules
full transaction rollback inside a partially failed multi-write organ
```

F4 из полного аудита остается подтвержденным blocker, но его лечение требует
согласовать версии L2 referents. Подмешивать его в integrity gate означало бы
тайно начать следующий архитектурный шаг.

## 6. Фальсификаторы

Gate отвергнут, если после лечения верно хотя бы одно:

```text
изменение caller input меняет stored body/corpse/trace
record_choice на Packet в ▽ создает ☳ event
field source event взят из прошлого посещения того же glyph
negative/NaN/infinite/unknown/fractional discrete cost меняет budget
изменение проверенного файла не меняет evidence fingerprint
после повторного LOGIC неизменный referent снова создает validation debt
legacy/shadow/tree нормальные жизни меняют маршрут только из-за gate
```

## 7. Порядок реализации

```text
1. table: классифицировать границы и точные acceptance cases
2. crystall: назвать APIs, ошибки, файлы и неизменяемые свойства
3. red tests: воспроизвести каждый bypass до лечения
4. code: ownership -> actor/tick -> budget -> truth rent
5. targeted tests после каждого блока
6. full suite + mortality + camera smoke
7. treatment record; только затем шаг 3
```
