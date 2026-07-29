# QA Body Transaction Reconciliation Blueprint v0

Status:

```text
layer: crystall (◈)
date: 2026-07-29
source table:
  docs/01_table/yellowprints/qa_body_transaction_reconciliation_yellowprint.v0.md
gate record:
  docs/00_chaos/qa_body_transaction_table_cross_audit_2026-07-29.md
crystall audit:
  docs/00_chaos/qa_body_transaction_crystall_cross_audit_2026-07-29.md
depends on:
  docs/02_crystall/blueprints/qa_body_execution_after_qn20.v0.md
  docs/02_crystall/blueprints/qa_body_evidence_verdict_v1.v0.md
implementation authority: yes; exact M1-M4 slices and matrix only
router/pressure promotion: forbidden
lineage software acceptance: forbidden
```

## 0. Integration Claim

The QA hand is complete only when one causal chain agrees across three current
truth stores:

```text
Packet trace/body evidence
private QA capability registry
private repository source registry
```

The measured-environment registry is a prerequisite witness, not an execution
ledger. The native supervisor is an effect boundary, not a truth store.

No implementation slice may make one surface silently repair another. A split
is either an explicitly pending phase, a typed effect failure or a loud trusted
invariant.

## 1. Canonical Causal Chain

```text
current seal/alignment/contract/environment
  -> qa.check_request.v0 + request event
  -> qa.execution_grant.v1 active
  -> sticky running transaction
  -> source lease OR exact not_acquired denial
  -> shared physical terminal result
  -> private body report/error
  -> qa.execution_receipt.v1
  -> qa.check.v0 OR qa.execution_failure.v0
  -> qa.candidate_verdict.v0 OR effect_failure mortality
  -> qa.terminal_projection.v1
  -> corpse.qa_evidence.v1
```

Every arrow is re-derived from authoritative parent records. A child id is
never proof that an absent parent existed.

## 2. Phase Ownership

| Phase | Current facts | Sole advancing writer | First next reader |
|---|---|---|---|
| P0 sealed | seal, no request | ☶ request writer | private grant mint |
| P1 requested | request event | QA registry mint | begin |
| P2 active | grant + environment lease | QA registry begin | body adapter |
| P3 running | sticky transaction | repository reserve | shared engine/body adapter |
| P3a acquired | source lease attempted | shared engine | body adapter |
| P4 private terminal | source final/not_acquired + result + receipt | ☶ strict join | ☱ or runner |
| P5 observed | check or execution failure | ☱ verdict or runner mortality | △ / corpse |
| P6 verdict | exact accepted/rejected verdict | △ manifest | corpse |
| P7 historical | corpse QA envelope | lineage historical reader | corpus/recovery proposal |

No transition may skip P1, P2, P4 or P5. An acquired source always passes P3a.

## 3. Partial-State Reconciliation

| Observed state | Classification | Required action |
|---|---|---|
| request, no grant | pending/denied before authority | no process/cost; mint may be attempted once |
| active grant, source available | not begun | begin once or remain pending |
| running, no reserve outcome | trusted registry contradiction | loud; invent no failure |
| running, exact signed reservation denial | typed not-acquired infrastructure result | commit consumed_failed receipt |
| running, malformed/foreign denial | trusted contradiction | quarantine attempt + loud |
| source attempted, no terminal disposition | cleanup gap | quarantine attempt + loud |
| terminal source, no normalized private result | final assembly contradiction | quarantine + loud |
| private result, no receipt | private commit contradiction | quarantine + loud |
| receipt, no matching body outcome | split brain | loud; never rerun |
| body outcome, no matching receipt | forged/split body | loud; never rerun |
| check, no verdict | valid ◈ phase | ☱ may assemble verdict |
| failure, no death yet | committed effect-failure phase | runner charges/kills once |
| verdict, no terminal projection | valid ▲ phase | △ may project |

No reconciliation path creates check, verdict, source finality or successful
candidate execution from absence.

The sole proof of the fourth row is
`repository.qa_source_reservation_denial.v0`. A generic capability diagnostic
is not evidence and follows the malformed/foreign loud row.

## 4. Classification Boundary

| Physical fact | Body fact | Verdict | Mortality |
|---|---|---|---|
| expected exit 0 + complete finality | accepted check | accepted | none |
| contained nonzero/signal/timeout/limit/policy | rejected check | rejected | none before terminal policy |
| exact pre-entry source denial | execution failure / not_acquired | none | effect_failure |
| incomplete environment/provider/source observation | execution failure | none | effect_failure |
| cleanup/reap/EOF/namespace ambiguity | execution failure | none | effect_failure |
| malformed trusted causal tuple | no body fact | none | loud harness failure |

Candidate rejection and infrastructure failure are disjoint protocols.

## 5. Reader/Writer Closure

| Fact | Sole writer | First reader | Closed consequence |
|---|---|---|---|
| request proposal | pure request derivation | ☶ request writer | event or not-ready |
| request event | ☶ | QA grant mint | active grant or denial |
| environment lease | environment registry | begin/native callback | valid or denial/failure |
| grant | QA registry | begin | running or pending |
| running transaction | QA registry | body adapter | source attempt |
| source lease/disposition | repository registry | shared engine/receipt | terminal source fact |
| not_acquired denial | repository registry | body adapter/receipt | consumed_failed result |
| pending physical join | shared engine | selected adapter | immediate final record |
| witness report/error | witness adapter | QN harness | harness-only result |
| body report/error | body adapter | receipt commit | private receipt |
| receipt + private result | QA registry | ☶ strict join | check/failure or loud |
| check | ☶ | ☱ | verdict or not-ready |
| execution failure | ☶ | runner | one effect death |
| verdict | ☱ | completion/work-layer/△ | boundary projection |
| terminal QA projection | △ | corpse | immutable envelope |
| corpse QA envelope | corpse capturer | lineage history | proposal only |

There is no writer without a named reader in this surface.

## 6. Implementation Preconditions

Before implementation changes any color:

```text
P01 all QE08-QE20 placeholders become exact falsifiers
P02 all placeholder QV controls become exact falsifiers
P03 each positive check/receipt/corpse fixture is grown by real producers
P04 synthetic records are used only for trusted-corruption controls
P05 baseline remains exactly 44 green / 40 red / 0 skip
P06 QN16-QN20 reports, errors and residue vector are snapshotted
P07 full suite and mortality battery are green
```

Module existence, empty readers, hand-built provider reports and an assertion
that only checks a field name are forbidden evidence.

## 7. Slice M1 - Shared Physical Engine

Files:

```text
new runtime/qa_candidate_transaction.lua
modify runtime/repository_capability.lua
modify runtime/qa_environment.lua
modify runtime/qa_provider_witness.lua
modify provider-witness/native tests
```

Required behavior:

```text
root-bound repository provider travels with source handle
verified QA provider travels with measured environment lease/pair
one shared pre/seal/RUN/post/finality engine
provider-witness adapter retains exact public protocols
body path remains closed
```

Permitted QA control delta:

```text
none
before: 44 green / 40 red / 0 skip
after:  44 green / 40 red / 0 skip
```

M1 gate:

```text
QN16-QN20 output tables exact
QN20 repeated-residue vector exact
Packet/public-root witness ablation exact
provider substitution controls red/green as designed
full suite + mortality green
```

## 8. Slice M2 - Body Execution And Strict Outcome Join

Files:

```text
complete runtime/qa_capability.lua
new runtime/qa_execution.lua
new core/qa_evidence_schema.lua
new runtime/qa_evidence.lua
modify runtime/qa_request.lua and runtime/qa_process.lua for schema reuse
modify core/packet.lua and runtime/body.lua
modify organs/logic.lua and runtime/tension_runner.lua
rewrite exact QE/QV falsifiers and fixtures
```

Required grown lives:

```text
E1 accepted candidate
E2 rejected Lua-error candidate
E3 contained timeout/output/memory limit candidates
E4 clean pre-entry source denial
E5 post-start cleanup ambiguity
E6 source drift
E7 malformed trusted private/native tuple
E8 exact replay after receipt and body event
E9 receipt/body split
E10 alignment drift before body append
E11 QA-disabled matched life
E12 repeated body transactions under residue observer
```

Manual actor-valid entries are exact:

```text
☶: logic.qa_execution.action = execute_current_candidate
☱: runtime.qa_verdict.action = assemble_current_candidate_verdict
```

Authorized new greens:

```text
QE01 QE04 QE08 QE09 QE10 QE11 QE12 QE13 QE14 QE15
QE16 QE17 QE18 QE19 QE20                         = 15

QV01 QV02 QV03 QV04 QV05 QV06 QV07 QV08
QV13 QV14 QV15 QV21 QV22                         = 13
```

Expected matrix:

```text
72 green / 12 red / 0 skip
```

Still red by law:

```text
QC15
QV09 QV10 QV11 QV12 QV16 QV17 QV18 QV19 QV20 QV23 QV24
```

No M2 implementation may add a verdict, terminal projection or descendant
reader merely to improve the count.

## 9. Slice M3 - Verdict And Shadow Readers

Files:

```text
new runtime/qa_verdict.lua
modify organs/runtime.lua
modify runtime/completion_scope.lua
modify runtime/work_layer.lua
complete exact verdict controls
```

Required grown evidence:

```text
accepted check awaiting verdict remains ◈
rejected check awaiting verdict remains ◈
accepted complete set becomes accepted ▲
rejected complete set becomes recovery-ready ▲
execution failure yields no verdict
substrate text cannot create or alter verdict
Packet/corpse cannot claim software_accepted
rejected verdict alone cannot birth a descendant
```

Authorized new greens:

```text
QC15                                                = 1
QV09 QV10 QV11 QV12 QV16 QV17 QV18 QV23 QV24      = 9
```

Expected matrix:

```text
82 green / 2 red / 0 skip
```

Only `QV19` and `QV20` remain red.

M3 is shadow-only for completion/work-layer projections. It changes no route,
pressure, Packet budget or mortality policy.

## 10. Slice M4 - Terminal And Historical Retention

Files:

```text
modify logic/manifest.lua
modify runtime/corpse.lua
modify runtime/carrier.lua
complete long-trace and descendant controls
```

Required grown lives:

```text
T1 rejected verdict -> exact terminal projection -> corpse
T2 accepted verdict -> symmetric exact terminal projection -> corpse
T3 >32 later events before death retain exact QA envelope
T4 descendant receives ancestor envelope as historical proposal
T5 descendant current QA readers remain unsatisfied
```

Authorized new greens:

```text
QV19 QV20 = 2
```

Expected matrix:

```text
84 green / 0 red / 0 skip
```

This closes the body QA hand. It does not authorize router promotion, automatic
recovery, CLI acceptance or lineage `software_accepted`.

## 11. Exact Economics Checks

For every grown execution, assert independently:

```text
ordinary ☶ body tick charged once by runner
external QA projection charged once by runner
check/failure event contains same projection but does not debit
verdict/manifest/corpse copy evidence but do not debit
replay adds no process call, event or charge
not_acquired adds no external charge
identity loss unchanged by QA execution/verdict
```

The external mapping is exact:

```text
tool_calls <- qa_cost.tool_calls
test_runs  <- qa_cost.qa_executions
time_ms    <- qa_cost.wall_time_ms
```

## 12. Loud-Invariant Corpus

The following must fail the harness/body call loudly without inventing an
honest Packet death:

```text
unknown protocol/key/code/stage
invalid digest or actor
provider selected independently of environment lease
inventory provider selected independently of sealed source
accepted result with incomplete finality/nonzero exit
reason/cause/termination contradiction
impossible source/process tri-state
receipt/result digest disagreement
receipt/body split
foreign session/lineage/generation/stage/repository/seal
two outcomes or verdicts for one current request
```

If authority was already acquired, quarantine/finality is attempted first.
The contradiction itself is never rewritten as `effect_failure` mortality.

## 13. Disabled And Observer Ablations

Matched lives must prove:

```text
qa_enabled=false -> no readiness/request/grant/source/provider/event/cost
provider-witness adapter -> no Packet trace/revision/budget/loss mutation
completion/work-layer observers -> no route/state/revision mutation
ancestor envelope present/absent -> descendant current result unchanged
```

The only permitted deltas are the named observer records outside Packet or the
explicit historical carrier projection.

## 14. Route Ceiling

During M1-M4 the corpus drives phases explicitly:

```text
sealed Packet
  -> actor-valid ☶ QA execution
  -> actor-valid ☱ verdict
  -> actor-valid △ terminal projection
```

No change is authorized in:

```text
pressure readers
tree scores/tie-breaks
default readiness
automatic ☱->☶ or ☶->☱ route
legacy observer policy
promotion record
```

Routing is a later experiment only after all 84 controls and the ordinary
regression suite are green.

## 15. Regression Gate Per Slice

After every implementation slice run:

```text
lua tests/red_qa_hand.lua
lua tests/run.lua
lua tests/smoke_mortality_battery.lua
native syntax/build/sanitizer targets touched by the slice
QN repeated-residue campaign when M1/M2 touches physical execution
```

Inspect additionally:

```text
no surviving QA child/supervisor process
no leaked mount/namespace/temp-root residue
no repository source authority reopened
no worktree mutation outside owned fixtures
git diff --check
```

An unexpected green is a failure until its producer and reader are named.

## 16. Promotion Record Requirements

The final implementation record must state explicitly:

```text
which exact controls changed color in each slice
which grown life produced each terminal fact
that QN16-QN20 remained exact under engine extraction
that accepted/rejected phase depth is symmetric
that infrastructure failure stayed outside verdict
that the runner remained sole debit writer
that corpse retention survived trace-tail truncation
that software_accepted and router promotion remain absent
```

## 17. Explicit Deferrals

```text
router/pressure promotion
automatic rejected-generation recovery
multiple checks/profiles
semantic diagnosis
provider retry/resume
persistent transaction recovery
lineage software acceptance
CLI/TUI QA workflow
generic command execution
future public signature/admission policy
```

## 18. Exit Gate

Implementation authority may be granted only after a post-crystall audit
confirms:

```text
all three blueprints use the same ids and schemas
both providers are registry-bound and cannot be substituted
all partial states have one closed consequence
RUN v1 finality reaches check/corpse without weakening
matrix arithmetic covers exactly the remaining 40 controls
M1 cannot turn any body control green
M2 cannot turn verdict/terminal controls green
M3 cannot turn corpse/descendant controls green
router and lineage acceptance remain outside scope
```

## 19. Blueprint Thesis

The second hand is not complete when code can run tests. It is complete when
the body can prove exactly which candidate ran, under which sealed source and
measured world, preserve either the candidate result or the infrastructure
failure through death, and do so without granting the harness, provider or
substrate the right to write that story.
