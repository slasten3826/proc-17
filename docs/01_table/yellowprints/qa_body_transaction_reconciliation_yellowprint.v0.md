# QA Body Transaction Reconciliation Yellowprint v0

Status:

```text
layer: TABLE integration treatment
date: 2026-07-29
scope: causal join of body request, private execution, evidence and verdict
source: docs/00_chaos/qa_body_transaction_after_qn20_notes_2026-07-29.md
companions:
  qa_body_execution_after_qn20_yellowprint.v0.md
  qa_body_evidence_verdict_v1_yellowprint.v0.md
runtime implementation authorized: no
router/pressure promotion authorized: no
crystallization authorized: yes; post-QN20 cross-table audit 2026-07-29
gate record: docs/00_chaos/qa_body_transaction_table_cross_audit_2026-07-29.md
```

## 0. Integration Claim

The second QA hand is one causal transaction distributed across three current
truth stores:

```text
Packet trace/body evidence
private QA capability registry
private repository source registry
```

The native supervisor/provider is an effect boundary, not a fourth mutable
truth store. It returns terminal observations which the transaction owner must
commit or reject.

The private environment registry is an exact prerequisite witness. It owns
measured-environment identity and availability, but no request, transaction
progress, result or receipt. Revalidating its opaque lease therefore does not
create a fourth transaction ledger.

No one store can claim the whole transaction independently.

## 1. Selected Integration Laws

```text
R01 Request event precedes and causes private grant begin.
R02 Sticky private begin precedes and causes source reservation.
R03 Exact body_execution source identity contains request identity.
R04 Source acquisition is resolved before private result assembly; every
    acquired source reaches terminal disposition first.
R05 Private receipt precedes Packet outcome append.
R06 Packet check/failure precedes verdict assembly.
R07 Verdict precedes terminal QA projection.
R08 Corpse retention follows terminal/body facts and cannot create them.
R09 Every partial state has one named reader and one closed consequence.
R10 No failed edge returns authority to its prior active state.
R11 Provider witness and body execution share physics but never authority.
R12 Candidate rejection is evidence; infrastructure failure is effect failure.
R13 Accepted and rejected candidate verdicts have equal phase depth.
R14 Economics and completion remain independent.
R15 Initial implementation is manually grown; routing remains unpromoted.
R16 Begin revalidates the opaque measured-environment lease before mutation.
R17 A denied source reservation produces not_acquired evidence, not fictional
    source finality.
```

## 2. Three-Surface Agreement

| Surface | Owns | Must not own |
|---|---|---|
| Packet | request/check/failure/verdict events | handles, private receipt state, provider authority |
| QA registry | grant/transaction/receipt/private normalized result | Packet event truth, repository handle contents |
| repository registry | sealed source lease/disposition | QA contract/verdict, Packet mutation |

Agreement is checked by exact ids and authoritative records, never by matching
strings alone.

The causal join is healthy only in these combinations:

```text
no request + no grant + source available
request + active grant + source available
request + running grant + source available/not_acquired
request + running grant + source reserved/attempted
request + consumed_failed grant + source not_acquired + private error
request + terminal source + committed receipt + exact body outcome
request + terminal source + quarantined transaction + loud invariant
```

Any other cross-surface combination has an explicit row below.

## 3. Phase Table

| Phase | Body state | QA private state | Source state | Sole action | First next reader |
|---|---|---|---|---|---|
| P0 sealed | seal, no request | absent | available | pure eligibility/request derivation | ☶ request writer |
| P1 requested | exact request event | absent | available | grant mint | QA resolver |
| P2 granted | request event | active grant + opaque environment lease | available | transaction begin + environment revalidation | body execution adapter |
| P3 running | request event | running sticky transaction | available/not acquired | reserve exact source | repository source bridge |
| P3a source bound | request event | running sticky transaction | reserved/attempted | shared physical engine | body adapter |
| P4 physical terminal | request event | terminal transaction + private result | not_acquired/consumed/quarantined | receipt commit | strict body join |
| P5 body observed | check or execution failure | committed receipt | terminal/not_acquired | verdict or runner | ☱ / effect-failure path |
| P6 verdict | final candidate verdict | committed receipt | terminal | terminal projection | △ |
| P7 corpse | immutable QA envelope | no new authority | terminal history | lineage historical read | lineage/corpus |

There is no phase transition that skips P1, P2, P4 or P5. Candidate execution
cannot skip P3a; typed source-reservation denial moves directly from P3 to P4
with `source_acquisition=not_acquired` and no provider entry.

## 4. Transition Table

| From | Trigger | Required evidence | To | Cost | Failure class |
|---|---|---|---|---|---|
| P0 | record request | current seal/alignment/contract/environment | P1 | none | not-ready/loud by schema |
| P1 | mint grant | exact request event ref + private registries | P2 | none | denial, no source effect |
| P2 | begin | exact active grant/request/current environment lease | P3 | none | denial, no source effect |
| P3 | reserve source | exact body binding and transaction digest | P3a | none | closed expected denial -> P4 not_acquired; trusted contradiction -> loud |
| P3a | execute | pre==seal, exact RUN v1, post==pre | P4 | measured | candidate/error/loud |
| P4 | commit receipt | terminal source or exact not_acquired denial + normalized private result | P4 | none | quarantine/loud |
| P4 | append outcome | exact receipt/result/current body join | P5 | recorded, not charged here | check/failure/loud |
| P5 check | assemble verdict | complete exact required-check set | P6 | normal ☱ step only | not-ready/loud |
| P5 failure | runner effect failure | exact typed failure | terminal death | one effect charge | effect_failure |
| P6 | manifest | current verdict + check + alignment | terminal Packet | normal △ step | loud on contradiction |
| terminal | capture corpse | body/terminal evidence | P7 | none | loud on invalid freeze |

## 5. Partial-State Disposition

| Observed split | Meaning | Required consequence |
|---|---|---|
| request event, no grant | pending/denied before authority | remain pending; no process/cost |
| active grant, source available | not begun | begin once or remain pending |
| running grant, no source lease | source reservation failed | consumed_failed + not_acquired private error; never active |
| running grant, reserve outcome absent | trusted registry contradiction | loud; no invented not_acquired evidence |
| running grant, malformed/foreign reserve rejection | trusted caller/registry contradiction | quarantine attempt + loud; no body failure |
| source attempted, no terminal disposition | trusted cleanup gap | quarantine attempt + loud |
| terminal source, no private result | final assembly contradiction | quarantine + loud |
| private result, no receipt | private commit contradiction | quarantine + loud |
| receipt, no body outcome | split brain | loud, no rerun |
| body outcome, no receipt | forged/split body | loud, no rerun |
| check, no verdict | valid crystallization phase | remain ◈; ☱ may assemble |
| execution failure, no death yet | committed effect-failure phase | runner charges/kills once |
| verdict, no terminal projection | valid boundary phase | remain ▲; △ may project |

No cleanup path invents a check, verdict or complete result.

## 6. Candidate And Infrastructure Semantics

| Physical result | Body record | Verdict contribution | Mortality |
|---|---|---|---|
| expected exit 0, complete finality | accepted check | accepted | none |
| contained nonzero/signal/timeout/limit/policy | rejected check | rejected | none before verdict/terminal policy |
| typed source reservation denial before provider entry | execution failure, source not_acquired | none | effect_failure |
| source/environment/provider observation incomplete after acquisition | execution failure, source terminal | none | effect_failure |
| cleanup/reap/EOF/namespace ambiguous | execution failure | none | effect_failure |
| malformed trusted causal tuple | none | none | loud harness failure, not Packet death |

This table forbids treating every nonzero process result as infrastructure and
forbids treating every provider error as candidate rejection.

## 7. Evidence Identity Chain

```text
qa_contract_id
  -> qa_check_request.request_id
  -> request event ref
  -> qa grant id
  -> physical transaction id
  -> source binding/lease/disposition OR typed not_acquired denial
  -> normalized private result id
  -> execution receipt id
  -> qa_check_id OR qa_execution_failure_id
  -> qa_verdict_id
  -> terminal projection
  -> corpse hash
```

Each arrow is re-derived and verified at its boundary. No child id is accepted
as proof of an absent parent record.

## 8. Reader Timing

| Record | First legal read | Stale when |
|---|---|---|
| request proposal | same ☶ derivation | seal/alignment/contract/environment changes |
| request event | grant mint/begin | Packet/coordinate mismatch or terminal state |
| grant | begin | request/current private coordinates diverge |
| environment lease | begin and immediate native-entry callback | measured record revision/state changes |
| source lease | shared engine | terminal disposition or root revision conflict |
| receipt/result | strict body join | current body alignment diverges |
| check | ☱ verdict preparation | seal/contract/environment no longer current |
| failure | runner effect-failure handling | never reused as check/verdict |
| verdict | completion/work-layer/△ | seal/alignment no longer current |
| corpse envelope | lineage historical reader | always historical for descendant current state |

No reader waits for a generic global revision when exact object identity and
version are available.

The source reader is not a caller-selected host service. The repository source
callback yields the retained opaque handle and its exact root-bound inventory
provider together; neither may escape the callback.

## 9. Economics Ledger

There are two different costs:

```text
body phase cost       one ordinary step for each executed organ tick
external QA cost      measured provider projection charged once
```

External QA projection:

```text
tool_calls <- qa_cost.tool_calls
test_runs  <- qa_cost.qa_executions
time_ms    <- qa_cost.wall_time_ms
```

| Writer | May record cost | May debit Packet budget |
|---|---|---|
| native/provider | yes, private measurement | no |
| receipt | yes, detached evidence | no |
| check/failure event | yes, admitted projection | no |
| qa_execution effect payload | yes | no direct mutation |
| tension runner | yes, budget event | yes, exactly once |
| verdict/manifest/corpse | historical projection only | no |

Identity loss is unchanged by execution, check and verdict. Future semantic
diagnosis is separate ENCODE/CHOOSE work and may have its own loss.

## 10. Work-Layer And Terminal Symmetry

```text
sealed, no outcome       -> ⊞ checking
request/check, no verdict -> ◈ crystallizing
accepted verdict          -> ▲ candidate acceptance boundary
rejected verdict          -> ▲ recovery boundary
execution failure         -> ⊞ infrastructure incomplete, then effect death
```

`▲` means the generation has produced a complete typed boundary. It does not
mean success. Accepted and rejected verdicts both require request, execution,
receipt, check and ☱ assembly.

## 11. Initial Route Ceiling

The first corpus manually grows actor-valid phases:

```text
sealed Packet -> ☶ request/execution/outcome -> ☱ verdict -> △ projection
```

Completion and work-layer readers are shadow observers. Router pressure,
automatic ☱->☶ selection and default authority remain unchanged until:

```text
accepted life green
rejected life green
infrastructure life green
disabled ablation exact
economics exact
corpse/descendant controls exact
```

## 12. Red-First Repair

The current red tests correctly preserve withheld authority but many future
controls are placeholders:

```text
transaction_surface(id) -> unconditional red
outcome_surface(id)     -> unconditional red
```

Before implementation, each placeholder must become one exact falsifier with
a grown producer or a named missing producer. The rewritten battery must remain:

```text
44 green / 40 red / 0 skip
```

Module presence, empty readers and hand-built provider tables are not valid
ways to turn a control green.

## 13. Control Ownership

### Existing contract/profile controls

```text
QC01-QC14 current green foundation
QC15 verdict/substrate authority ceiling -> verdict milestone
```

### Remaining execution controls

| Control | Owning evidence |
|---|---|
| QE01 | disabled body execution ablation |
| QE04 | current sealed/aligned readiness gate |
| QE08 | request/lease/receipt replay law |
| QE09 | sticky failed first attempt |
| QE10 | shared exact pre/seal/post inventory |
| QE11 | source drift produces no candidate outcome |
| QE12 | candidate vs infrastructure classification |
| QE13 | malformed trusted report loudness |
| QE14 | receipt/body split law |
| QE15 | one external-effect charge |
| QE16 | pre-dispatch denial zero process/cost |
| QE17 | private coordinate isolation |
| QE18 | detached private-state immutability |
| QE19 | foreign lineage/root alias denial |
| QE20 | repeated grown body transaction residue |

### Verdict controls

```text
QV01-QV08    strict private-to-body join and event gate
QV09-QV12   ◈/▲ and deterministic accepted/rejected verdict
QV13-QV15   effect failure, conflict and replay
QV16-QV18   substrate/subject/recovery authority ceilings
QV19-QV20   corpse retention and descendant history
QV21-QV22   causal classification and detached immutability
QV23-QV24   economics and truth ceiling
```

## 14. Promotion Milestones

These are merge/promotion checkpoints, not permission to fake intermediate
greens. CRYSTALL must provide a finer exact delta for every implementation
slice.

### M0 Documentary and red-contract repair

```text
expected matrix: 44 green / 40 red
allowed color change: none
```

### M1 Shared physical-engine extraction

```text
expected matrix: 44 green / 40 red
allowed color change: none
required invariant: QN16-QN20 outputs and QN20 residue vector exact
```

### M2 Complete body execution and outcome join

Authorized new greens:

```text
QE01, QE04, QE08-QE20                    15
QV01-QV08, QV13-QV15, QV21-QV22         13
```

Expected matrix:

```text
72 green / 12 red
```

No verdict, terminal or descendant control may green here.

### M3 Deterministic verdict and shadow readers

Authorized new greens:

```text
QC15                                           1
QV09-QV12, QV16-QV18, QV23-QV24               9
```

Expected matrix:

```text
82 green / 2 red
```

Only corpse/descendant retention remains red.

### M4 Terminal retention and descendant history

Authorized new greens:

```text
QV19, QV20                                     2
```

Expected matrix:

```text
84 green / 0 red
```

This closes the body QA hand but does not promote routing, CLI acceptance or
lineage-level `software_accepted`.

## 15. Cross-Layer Falsification Corpus

At minimum grow:

```text
C1 accepted exact candidate
C2 rejected Lua-error candidate
C3 contained output-limit candidate
C4 contained memory-limit candidate
C5 clean pre-start infrastructure failure
C6 post-start cleanup ambiguity
C7 malformed trusted result
C8 request replay after exact receipt/body event
C9 append split after receipt
C10 alignment drift before body append
C11 >32 later events before corpse capture
C12 descendant offered ancestor QA envelope
C13 QA disabled matched ablation
C14 repeated body transactions under QN20 observer
```

Candidate, death, corpse and descendant fixtures are grown through real
producers. Synthetic reports/receipts/corpses are valid only for trusted
corruption tests.

## 16. Named Writers And Readers

| Fact | Sole writer | First reader | Closed? |
|---|---|---|---|
| request proposal | pure request derivation | ☶ writer | yes |
| request event | ☶ body writer | QA grant mint | yes |
| QA grant | QA registry | begin | yes |
| running transaction | QA registry | body adapter | yes |
| source lease/disposition | repository registry | shared engine/receipt | yes |
| source not_acquired denial | repository registry | body adapter/receipt | yes |
| physical pending result | shared engine | selected adapter | yes |
| witness report/error | witness adapter | QN harness | yes |
| body report/error | body adapter | receipt commit | yes |
| receipt/private result | QA registry | strict body join | yes |
| check | ☶ body writer | ☱ verdict | yes |
| execution failure | ☶ body writer | runner | yes |
| verdict | ☱ body writer | completion/work-layer/△ | yes |
| terminal projection | △ | corpse/lineage | yes |
| corpse QA envelope | corpse capturer | historical lineage reader | yes |

## 17. Explicit Non-Claims

```text
default tree routing
pressure calibration
multiple checks/profiles
provider retry/resume
semantic failure diagnosis
automatic rejected-generation recovery
lineage software acceptance
CLI/TUI presentation
generic command execution
```

## 18. Exit Gate

The three post-QN20 TABLE treatments may crystallize only after one cross-table
audit proves:

```text
all schemas use the same request/receipt/result identities;
all partial states have one consequence;
v1 process finality is preserved without raw authority;
economics has one Packet-budget writer;
the promotion milestone arithmetic covers exactly all remaining 40 controls;
no provider-witness record acquires a body reader;
environment and source pre-entry denial states do not invent authority/finality;
router and lineage acceptance remain outside the authorization surface.
```
