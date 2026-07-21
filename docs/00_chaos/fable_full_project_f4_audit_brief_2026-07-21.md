# Fable Full-Project F4 Audit Brief - 2026-07-21

Status:

```text
chaos / external cold-audit carrier
target: Claude Opus / Claude Code (new or untrusted session)
scope: entire current proc-17 worktree, then focused F4 analysis
requested mode: read-only audit
do not modify code or documentation
do not assume memory from an earlier Fable/Mythos session
```

## Привет

Мы продолжаем собирать `proc-17`: исполняемое тело `procesis`, которое прежде
всего создаёт новое программное обеспечение через смертные Packet-поколения,
полное дерево операторов и lineage-side continuity.

В прошлый раз внешний аудит нашёл F1-F6 в новых TABLE/CRYSTALL-контрактах.
F1-F3, F5 и F6 уже получили amendment. F4 намеренно оставлен открытым:

```text
F4 = документы требуют exact typed failure crystal,
     но отдельная схема, identity law, writer and implementation boundary
     для failure_crystal.v0 пока не определены
```

Нам нужен не быстрый ответ по шести документам. Сначала прочитай весь текущий
проект и восстанови его замысел из файлов и работающего тела. Только после этого
решай, нужен ли failure crystal вообще и каким он может быть.

Этот бриф не является скрытым требованием реализовать crystal. Допустимый итог
аудита: отдельный failure crystal избыточен и должен быть удалён из контрактов.

## 1. Полная Холодная Инвентаризация

Сначала зафиксируй текущий worktree:

```text
pwd
git status --short
git log --oneline --decorate -n 30
git ls-files
rg --files
```

Центральные TABLE/CRYSTALL-документы сейчас могут быть незакоммиченными. Это
ожидаемо. Холодный клон без текущего dirty worktree будет неполным и для этого
аудита недостаточен.

Прочитай все доступные текстовые файлы текущего проекта, включая tracked и
untracked:

```text
README and root metadata
docs/00_chaos/**
docs/01_table/**
docs/02_crystall/**
docs/03_manifest/**
core/**
runtime/**
organs/**
logic/**
substrates/**
tools/**
cli/**
tests/**
native source, headers, Makefiles and test harnesses
other project-owned text/configuration files returned by rg --files
```

Do not byte-read generated binaries, object files, caches, temporary fixture
roots or `.git` internals. Inventory them when relevant and list every excluded
class in the report. Do not silently replace "read the whole project" with a
small hand-picked source list.

Old and superseded documents are archaeology, not current authority. Read their
status/supersession banners and use them to reconstruct the path, but do not
report an explicitly superseded law as a current contradiction.

## 2. Runtime Baseline Before Interpretation

Run, without installing anything:

```text
lua tests/run.lua
lua tests/smoke_mortality_battery.lua
```

Record:

```text
test-module count
green/red/skip results
native provider availability and skips
dirty worktree before and after tests
```

The baseline proves current body behavior only. It does not prove unwritten QA
or failure-crystal behavior. Do not report an admitted future implementation
gap as a current runtime regression.

## 3. Current Audit Ledger

Read these two records early, but do not stop there:

```text
docs/00_chaos/fable_preimplementation_crystall_audit_raw_2026-07-21.md
docs/00_chaos/preimplementation_audit_disposition_2026-07-21.md
```

Current disposition:

```text
F1 generation/generation_state collision                amended
F2 seal transaction TOCTOU                              amended
F3 process_contract_id/context collision                amended
F4 failure crystal contract                             open
F5 writerless stage-level rejected                      removed from v0
F6 identity/vocabulary/corpus/grave seams               amended
global preimplementation crystall gate                  open because F4
```

Audit the amendments against the full project. If one is wrong, bring a causal
counterexample. Do not reopen it merely because another naming convention is
more familiar.

## 4. F4 Surfaces To Trace

Do not limit yourself to this list, but trace at least:

```text
completion scope and candidate seal TABLE/CRYSTALL
nested work-layer derivation TABLE/CRYSTALL
stage transition and generation recovery TABLE/CRYSTALL
documentation snapshot and corpus TABLE/CRYSTALL
grave classifier/attach/router contracts and runtime
corpse, residue, carrier, NETWORK ingress and lineage runner
truth-status, digest, immutable-record and named-reader patterns
QA-related schemas, spells, validation and capability boundaries
current ⋯ ⊞ ◈ ▲ laws and build-generation rebirth law
```

Search for all spellings and conceptual aliases, not only the literal token:

```text
failure_crystal
failure crystal
failure crystallization
rejected generation
qa_rejected
recovery constraint
residue
do_not_repeat
diagnosis
repair proposal
```

One required question is whether the project already contains the missing organ
under another name or distributed across QA verdict, corpse, residue, grave and
carrier. A new object is justified only if it owns a distinct causal job.

## 5. F4 Is An Open Question

The following are hypotheses, not accepted decisions:

```text
H1 a QA verdict proves what check failed but is not a recovery memory
H2 a failure crystal may bind exact failure facts to bounded interpretation
H3 the body may be able to write a minimal crystal without a substrate call
H4 semantic diagnosis, if present, must remain semantic_proposal/mixed
H5 a crystal must never grant patch, process-contract or recovery authority
H6 the separate object may be redundant with seal + QA verdict + corpse
```

Try to falsify all six.

Consider at least four outcomes:

```text
A. no separate object:
   derive the recovery view from seal + QA verdict + corpse/source refs

B. minimal mechanical crystal:
   body writes only exact rejected checks, receipts, digests and provenance

C. split crystal:
   immutable mechanical core plus optional bounded semantic interpretation

D. explicit deferral:
   B2/B3 remain unavailable and implementation gate stays closed until QA exists
```

Do not choose C merely because it is the richest design. Prefer the smallest
object that owns a necessary job and has named readers.

## 6. Questions The Audit Must Answer

### Necessity

1. What information would a failure crystal contain that cannot be derived
   exactly from candidate seal, QA verdict, corpse, process contract and source
   refs?
2. If the answer is "none", which TABLE/CRYSTALL rows should lose the object?
3. If it is necessary, what breaks without it in a grown rejected-generation
   life?

### Authority And Truth

1. Who is the sole writer: body, lineage, QA validator, substrate, or a composed
   transaction?
2. Which fields are `runtime_confirmed`, `document_decision`,
   `semantic_proposal`, `mixed`, or applicability-only?
3. Can the record be produced when the substrate is absent or silent?
4. Can any field accidentally become a new acceptance/process contract?
5. Who decides whether recovery is allowed and affordable? The answer must not
   be smuggled into the crystal.

### Identity And Causality

1. What exact ids/versions must participate in identity?
2. Must it bind lineage, generation, Packet, stage, repository, candidate seal,
   QA contract, verdict and rejected checks?
3. At what causal point can it be committed, and can it be committed twice?
4. Is it Packet-local evidence, lineage evidence, or a Packet-written object
   later registered by lineage?
5. What crosses △ and NETWORK@▽: the object, a verified ref, or a bounded
   projection?

### Work Layer And Routing

1. Is build `◈` a real phase that performs work, or merely the interval between
   rejected verdict and mechanical record commit?
2. Does B3 -> B2 require an LLM call? If yes, how does the body remain valid
   without a substrate?
3. Which operator may produce or observe the record without turning a work
   layer into a router?
4. What happens when the writer/reader is absent: `unsupported`, honest death,
   suspension, or loud invariant failure?

### Grave, Karma And Recovery

1. Does failure crystal duplicate grave warning/bequest or corpse residue?
2. Which source may influence semantic next-generation pressure, and which may
   mechanically constrain lineage?
3. Can grave/karma override exact QA evidence or recovery policy?
4. Can an old crystal poison unrelated descendants or survive retention without
   a reader/expiry law?

### Security And Bounds

1. Can it contain raw unbounded stdout/stderr, source bytes, paths, handles,
   leases, grants or provider objects?
2. What are the hard item/byte/ref/excerpt limits?
3. How are malformed, conflicting, cross-generation and stale records handled?
4. Can a substrate forge a crystal-shaped proposal that a body reader accepts?

### Tests And Promotion

1. What is the smallest grown-life fixture that proves the design?
2. Which matched pairs and hostile cases falsify it?
3. Which observer/shadow slice can be implemented before authority promotion?
4. Does resolving F4 unblock every dependent CRYSTALL, or expose another hidden
   decision?

## 7. Required Falsifiers

At minimum construct or specify these counterexamples:

```text
same QA verdict, different candidate seal
same seal, verdict from another generation
rejected check with malformed/missing runtime receipt
two conflicting current QA verdicts
substrate returns a complete crystal-shaped table
semantic diagnosis absent
semantic diagnosis contradicts exact rejected check
crystal replayed into another lineage
grave warning contradicts crystal facts
lineage cannot afford recovery after exact failure evidence exists
caller mutates returned record
record exceeds bounds
```

For every proposed field, name one reader. For every reader, name the exact
effect of presence versus absence. A field with no reader is not allowed merely
for future convenience.

## 8. Finding Classification

Use:

| Class | Meaning |
|---|---|
| `runtime defect` | current code violates a current implemented contract |
| `contract contradiction` | selected TABLE/CRYSTALL laws cannot coexist |
| `contract underspecification` | implementation would invent consequential policy |
| `redundant organ` | proposed object has no unique writer/reader job |
| `authority leak` | record can grant power outside its declared boundary |
| `identity/provenance defect` | stale, foreign or ambiguous evidence can pass |
| `implementation gap` | sufficient future contract exists but code is absent |
| `explicit deferral` | absence is admitted and safely typed |
| `non-issue` | suspected problem is already prevented; cite how |

Severity:

```text
critical  sandbox/finality/authority corruption
high      false recovery/completion or blocks the full implementation gate
medium    future implementation must guess or reader misclassifies
low       naming/observability issue without semantic drift
```

Do not manufacture a defect to perform independence. A conclusion that F4 is
already derivable and should be deleted is as valuable as a new schema.

## 9. Required Report Shape

Return one report in this order:

### 1. Full-ingestion evidence

```text
git/worktree state
test results
areas and file counts actually read
excluded non-text/generated classes
confirmation that untracked current docs were included
```

### 2. Reconstructed project model

Explain the current authority chain in project terms, not generic agent terms:

```text
Packet -> Tree -> hands/effects -> △ -> corpse -> lineage -> carrier -> NETWORK@▽
```

Include where QA and failure crystallization would have to fit.

### 3. F4 verdict

Choose and defend one:

```text
separate object required
derived view sufficient
split mechanical/semantic object required
explicit deferral remains correct
```

If no option is exact, state a fifth precisely.

### 4. Findings

For each finding:

```text
class + severity
exact file/section/code refs
smallest causal counterexample
violated project law
minimum TABLE-level correction
```

Report unrelated critical/high defects discovered during full ingestion. Keep
unrelated medium/low archaeology out unless it changes F4.

### 5. Candidate contract or deletion map

If the object is required, provide the smallest exact schema, writer/reader
matrix, causal transaction and bounds. If redundant, list every document row
to amend and the existing records that replace it.

### 6. Falsification corpus

List grown lives, matched pairs, hostile cases and promotion gates. Separate
tests possible now from tests blocked on the future QA hand.

### 7. One next move

Recommend one smallest next action. Do not jump to CLI/TUI, product polish or a
general framework rewrite.

## 10. Editing Boundary

Do not modify the worktree during this audit:

```text
no code edits
no documentation edits
no generated audit file
no git add/commit/push
no dependency installation
no cleanup of the dirty tree
```

Return the report in chat. The machinist will carry it back to Codex, and we
will decide what enters CHAOS/TABLE/CRYSTALL.

## 11. Audit Thesis

```text
Read the whole body before naming the missing organ.

A failure crystal is justified only if it owns a causal job that QA verdict,
corpse, residue, grave, carrier and lineage cannot already perform without
authority leakage or semantic loss.
```
