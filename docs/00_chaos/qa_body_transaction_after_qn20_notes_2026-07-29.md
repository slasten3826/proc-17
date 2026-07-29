# QA Body Transaction After QN20 Notes

Status:

```text
layer: CHAOS
date: 2026-07-29
chapter: 8.5.6 boundary reconciliation
runtime implementation authorized by this note: no
TABLE amendment authorized: proposed, not yet executed
current native containment: QN01-QN20 green
current Packet/body QA authority: absent
current expected-red matrix: 44 green / 40 red / 0 skip
```

Primary runtime sources:

```text
runtime/qa_request.lua
runtime/qa_capability.lua
runtime/qa_provider_witness.lua
runtime/qa_process.lua
runtime/repository_capability.lua
tests/test_qa_contract.lua
tests/test_qa_execution.lua
tests/test_qa_check_verdict.lua
```

Primary documentary sources:

```text
docs/01_table/yellowprints/qa_execution_capability_yellowprint.v0.md
docs/01_table/yellowprints/qa_check_verdict_yellowprint.v0.md
docs/02_crystall/blueprints/qa_execution_capability.v0.md
docs/02_crystall/blueprints/qa_check_verdict.v0.md
docs/00_chaos/qa_e10_qn20_campaign_implementation_2026-07-29.md
```

## 0. Why This Reconciliation Exists

The private QA enclosure is now physically mature enough to run one exact
candidate repeatedly without leaking any named owned resource. That does not
make its output Packet truth.

The next task is not to build another sandbox and not to let the current
provider witness append a convenient `passed` flag. It is to build the causal
bridge by which one living Packet requests one exact execution, private
authority performs it once, and a different body writer admits only the exact
joined evidence.

The old QA execution and verdict TABLE/CRYSTALL documents anticipated this
bridge before RUN v1, controller terminal v2 and QN17-QN20 existed. Their
authority separation remains correct. Some of their physical schemas and
handoff assumptions are now stale. Code must not implement the stale forms
literally.

## 1. Runtime-Confirmed Frontier

The 84-control QA matrix currently decomposes as:

```text
QA contract/profile      QC01-QC14 green, QC15 red       14 / 1
body execution           QE02-QE03, QE05-QE07 green      5 / 15
native enclosure         QN01-QN20 green                 20 / 0
body check/verdict       QV01-QV24 red                    0 / 24
fixture guard            QF01-QF05 green                  5 / 0
                                                        --------
total                                                    44 / 40
```

The 40 red controls have exact causes:

```text
QC15
  runtime.qa_verdict is absent

QE01, QE04, QE08-QE20
  runtime.qa_execution is absent and no grown body transaction exists

QV01-QV24
  runtime.qa_evidence and runtime.qa_verdict are absent;
  Packet has no dedicated QA event gate
```

These are withheld authorities, not ordinary regressions.

## 2. What The Lower Layer Already Owns

The promoted private path owns:

```text
exact candidate seal and terminal source authority
one-use sealed-source reservation and sticky disposition
pre/post no-follow inventory against the seal
exact admitted Lua 5.4 environment
static supervisor identity and memory-erasure boundary
candidate STARTED, first cause and terminal arbitration
bounded stdout/stderr/resource/scratch measurements
process-tree reap, EOF and namespace cleanup finality
source consumed or quarantined before final report assembly
strict provider witness report/error v1
hostile, fault, cleanup-ambiguity and repeated-residue campaigns
```

QN20 adds one important execution fact: the providers can remain loaded once
while 32 fresh transactions return every named owned channel to its exact
baseline. It does not add a Packet writer.

## 3. What The Body Still Does Not Own

No current module can lawfully complete this chain:

```text
eligible sealed Packet
  -> body qa_check_request event
  -> private body_execution grant
  -> one private execution transaction
  -> private execution receipt
  -> body qa_check OR qa_execution_failure
  -> deterministic qa_candidate_verdict
  -> completion/work-layer/manifest/corpse readers
```

In particular:

```text
qa_request.prepare is pure and has no event writer;
qa_capability.mint deliberately returns grant_mint_not_promoted;
qa_capability.begin/commit are deliberate closed stubs;
qa_provider_witness is private harness evidence, not a body transaction;
packet.event_types has no QA event family;
runtime.qa_execution, runtime.qa_evidence and runtime.qa_verdict are absent.
```

## 4. The Post-QN20 Conflict

The old body-execution blueprint correctly forbids
`qa.provider_witness_report.v0` as a body input. The promoted provider now emits
the much stronger v1 report/error, but the prohibition still holds in spirit:

```text
provider witness output is not body evidence by itself
```

However, implementing a second inventory, supervisor and source-finality path
beside the promoted witness would duplicate the most dangerous physics in the
project. The two paths could drift in exactly the safety properties QN17-QN20
were built to measure.

A naive wrapper is also invalid. If `runtime.qa_execution` merely calls
`qa_provider_witness.execute`, the real source transaction remains
`transaction_kind=provider_witness`. Its identity does not contain the body
request, QA contract or check. The request would accompany execution in prose
but would not physically cause it.

Therefore neither shortcut is acceptable:

```text
forbidden A: provider witness report -> Packet event directly
forbidden B: duplicate native/source/inventory implementation for body QA
forbidden C: body wrapper around a provider_witness source transaction
```

## 5. Selected Architectural Hypothesis

Extract one shared private candidate-transaction engine beneath two adapters:

```text
                     shared private candidate transaction
                     source + inventory + RUN + finality
                                  |
                   +--------------+--------------+
                   |                             |
         provider-witness adapter       body-execution adapter
         transaction_kind               transaction_kind
         = provider_witness              = body_execution
         no qa_request_id                exact qa_request_id
                   |                             |
         report/error v1                private execution receipt
         harness readers only                    |
                                           strict body join
                                                  |
                                      qa_check / execution_failure
```

This is one physical engine with two authority envelopes, not one report with
two interpretations.

The shared engine owns no Packet writer and no verdict. It receives only a
private, already validated transaction descriptor and returns one private
pending result after terminal source disposition. Each adapter assembles its
own final protocol from that result.

The provider-witness adapter must retain its exact public test behavior so all
QN16-QN20 evidence remains valid. The body adapter must use a distinct source
binding whose identity includes the exact body request.

## 6. Body Execution Causal Chain

The proposed exact order is:

```text
1. ☶ derives qa.check_request.v0 from current Packet/seal/contract/environment.
2. ☶ appends or finds the exact dedicated request event.
3. qa_capability validates request + event + current private coordinates.
4. qa_capability mints one active private grant; it launches nothing.
5. qa_capability.begin atomically consumes replay authority and creates one
   sticky running transaction id.
6. the body adapter reserves repository.qa_source_binding.v1 with:
     transaction_kind = body_execution
     closure_request_id = exact seal closure request
     qa_request_id = exact Packet request
     transaction_id = exact private running transaction
7. the shared engine performs pre-inventory, RUN v1, post-inventory and source
   finality exactly once.
8. the body adapter normalizes the private result against the request.
9. qa_capability commits one private execution receipt before body append.
10. qa_evidence re-derives current alignment and joins body request + private
    receipt + private normalized result.
11. ☶ appends exactly one qa.check or qa_execution_failure.
12. ☱ later assembles exactly one deterministic candidate verdict.
```

The request event is causally prior to grant begin. The private grant is
causally prior to source reservation and provider entry. The receipt is
causally prior to body outcome. No later writer may reverse this order.

## 7. Why Source Reservation Moves After Grant Begin

The old blueprint places source reservation inside grant mint and calls the
operation atomic across two private registries. The current runtime has two
independent weak-key registries. Pretending that two Lua module calls form one
atomic state transition would create a split state if the second write fails.

The proposed safer order is:

```text
mint grant without external/source consumption
  -> begin makes QA transaction sticky
  -> reserve exact body_execution source
```

Consequences:

```text
mint denial        -> no source change, no process, no cost
begin denial       -> no source change, no process, no cost
source denial      -> QA transaction remains consumed/failed, never active
provider failure   -> QA transaction remains consumed/failed or quarantined
body append split  -> receipt remains committed, no rerun
```

This preserves the existing law that a failed first effect does not release
authority. It also gives every partial state one owner instead of claiming
cross-module atomicity that Lua cannot materially provide.

TABLE must decide this amendment explicitly before implementation.

## 8. Evidence Must Not Regress From V1

The old conceptual `qa.check.v0` collapses cleanup to:

```text
cleanup = complete
```

The promoted private report now contains stronger facts:

```text
termination
first cause
candidate STARTED state
source staging
process-tree reap
stdout EOF
stderr EOF
scratch observation
namespace cleanup
source pre/post identity and terminal disposition
measured cost
```

The body check must preserve the bounded v1 cause/finality projection. It may
not throw these distinctions away merely because accepted/rejected both have
complete cleanup. This is necessary for later corpse audit and for the existing
law that a contained timeout is candidate rejection while cleanup ambiguity is
infrastructure failure.

No raw stdout/stderr, host path, fd, lease, userdata, scratch content or private
process token may enter the event.

Because no `qa.check.v0` history exists, TABLE may precision-amend the v0 schema
before its first implementation rather than creating a compatibility alias.

## 9. Closed Outcome Classes

### 9.1 Cleanly contained candidate result

```text
expected exit 0                        -> qa.check accepted
nonzero/signal/timeout/limit/policy   -> qa.check rejected
```

Candidate rejection is still valid runtime evidence. It is not
`effect_failure`. Accepted and rejected checks take the same epistemic route to
☱ and require a final verdict.

### 9.2 Infrastructure execution failure

```text
source preflight mismatch
source drift
environment/provider unavailable after begin
incomplete process/reap/EOF/scratch/namespace observation
```

After a valid private receipt, this becomes `qa.execution_failure.v0`, returns
the existing typed `effect_failure`, pays actual incurred cost once and creates
no check or verdict.

### 9.3 Trusted-physics contradiction

```text
malformed native/provider record
impossible cause/finality tuple
foreign receipt or private/body identity contradiction
```

This is loud harness failure after best-effort quarantine/finality. It is not a
beautiful Packet death and never triggers a retry.

### 9.4 Split brain

```text
receipt + no exact body outcome
body outcome + no exact receipt
same request + different normalized result
```

Split brain is loud and sticky. The candidate is never rerun to repair an
append failure.

## 10. Truth Status

```text
request derivation and body append                 runtime_confirmed
private grant/transaction/receipt                  runtime_confirmed
process termination/cause/finality                 runtime_confirmed
source stability and disposition                   runtime_confirmed
check accepted/rejected under exact contract       runtime_confirmed
verdict over complete required-check set           runtime_confirmed
applicability of ancestor rejection to descendant  inherited proposal only
semantic explanation of failure                    semantic_proposal, deferred
universal software correctness                     absent
```

An accepted verdict means only:

```text
this exact sealed candidate satisfied this exact birth-bound QA contract in
this exact measured environment
```

It does not mean that the program is universally correct.

## 11. Economics And Identity Loss

The private v1 cost remains evidence. The existing Packet budget receives one
projection:

```text
tool_calls = qa_cost.tool_calls
test_runs  = qa_cost.qa_executions
time_ms    = qa_cost.wall_time_ms
```

Rules:

```text
pre-dispatch denial costs zero external effect;
the normal ☶ body tick still costs one step;
candidate execution cost is charged once by the runner effect path;
the qa_check event records that cost but does not charge it again;
☱ verdict assembly pays only its normal body tick;
replay returns existing detached evidence and charges nothing twice;
QA execution creates no identity loss by itself.
```

The provider, receipt writer and event writer may not each debit the same test.
The runner remains the sole Packet-budget writer.

## 12. Initial Routing Law

The first implementation is a manually grown body transaction, not router
promotion.

```text
☶ request/execution/check
  -> ☱ deterministic verdict
```

Tests may move an exact living Packet through those actors while retaining all
actor-tick guards. Completion/work-layer readers run in shadow first. No QA
pressure reader or live tree route is authorized until accepted, rejected and
infrastructure lives all satisfy the same evidence and economics gates.

This prevents route convenience from deciding evidence semantics.

## 13. Required Documentary Treatment

The existing documents are not discarded. They need dated amendments.

### TABLE

```text
T1 qa_execution_capability
   - one shared private physical engine, two authority adapters
   - body_execution binding is request-causal
   - grant begin precedes source reservation
   - provider witness v1 is never direct body input
   - full v1 cause/finality preservation

T2 qa_check_verdict
   - amend qa.check.v0 and execution_failure.v0 to current v1 evidence
   - preserve receipt-before-event and split-brain law
   - exact one-charge economics

T3 body transaction reconciliation
   - explicit writer/reader/transition matrix across the two tables
   - exact red-control deltas per implementation slice
```

Then perform one cross-table audit against the current code and QN20 evidence.

### CRYSTALL

```text
C1 shared private candidate-transaction engine boundary
C2 qa_capability grant/transaction/receipt amendment
C3 qa_execution orchestration and v1 normalization amendment
C4 qa_evidence and qa_verdict schema amendment
C5 cross-crystall audit and implementation authorization
```

No body code changes before these gates close.

## 14. Proposed Implementation Slices After CRYSTALL

```text
B1 exact red event/schema tests and dedicated Packet QA actor rights
B2 shared private transaction extraction with provider-witness ablation
B3 private grant/begin/source/receipt state machine
B4 qa_execution inspect/execute with accepted, rejected and infrastructure rows
B5 qa_evidence request/check/failure strict join
B6 deterministic ☱ verdict
B7 completion/work-layer shadow readers
B8 terminal manifest and corpse retention beyond trace_tail
B9 descendant historical-only controls and grown lineage corpus
B10 only then route/CLI promotion
```

Each slice must state the exact expected QA matrix before execution. A control
may turn green only when its real producer exists; module-presence green is not
accepted.

## 15. Mandatory Falsifiers

```text
F01 provider witness report supplied as body input writes no event
F02 same physical result under foreign request/contract/check is denied
F03 provider_witness source binding cannot satisfy body_execution
F04 body_execution without exact request event launches nothing
F05 request replay launches no second supervisor
F06 failed first source/provider attempt never restores grant authority
F07 private receipt commits before body outcome
F08 receipt/body split is loud and never reruns
F09 current alignment change before append writes no check/verdict
F10 accepted and rejected preserve exact v1 cause/finality
F11 cleanup ambiguity creates failure, never rejected check
F12 malformed trusted result is loud, never Packet mortality
F13 external effect cost is charged once; verdict charges no test twice
F14 body event mutation changes no private receipt or trace
F15 >32 later trace events cannot erase corpse QA evidence
F16 ancestor QA evidence cannot satisfy descendant current request
F17 shared-engine extraction changes no QN16-QN20 result or residue vector
F18 QA-disabled ablation changes no route, trace, budget, loss or provider count
```

Death/corpse/lineage fixtures must be grown by execution. Caller-built reports,
receipts or corpses cannot serve as promotion evidence.

## 16. Named Writers And Readers

| Record | Sole writer | First named reader |
|---|---|---|
| QA request proposal | pure `qa_request` | ☶ request writer |
| request event | ☶ dedicated body writer | private QA grant resolver |
| private QA grant | `qa_capability.mint` | transaction begin |
| private transaction | `qa_capability.begin` | body source resolver/engine |
| source lease/disposition | repository capability registry | shared engine/receipt commit |
| private physical pending result | shared engine | selected adapter only |
| provider witness report/error | witness adapter | QN harness only |
| private execution receipt/result | body adapter + QA registry | ☶ strict evidence join |
| `qa.check.v0` | ☶ strict evidence writer | ☱ verdict assembler |
| `qa.execution_failure.v0` | ☶ strict failure writer | runner effect-failure path |
| `qa.candidate_verdict.v0` | ☱ deterministic assembler | completion/work-layer/△ |
| terminal QA projection | △ manifest assembler | corpse/lineage/corpus |
| corpse QA envelope | corpse capturer | lineage historical reader |

No record in this chain is born without a named reader.

## 17. Non-Claims

This CHAOS note does not authorize or claim:

```text
body QA execution
Packet check/verdict events
software acceptance
router or pressure promotion
automatic recovery from rejected QA
multiple/optional test profiles
generic command execution
raw diagnostics or prompt ingestion
provider retry
CLI/TUI QA controls
```

It selects the boundary that the next TABLE round must make precise.

## 18. Next Action

Build the three TABLE treatments in section 13 and audit them together against:

```text
the current 44/40 red matrix;
repository.qa_source_binding.v1;
provider witness report/error v1;
QN17-QN20 promotion evidence;
existing Packet actor and budget laws.
```

Only after that audit may CRYSTALL amend the implementation plan.
