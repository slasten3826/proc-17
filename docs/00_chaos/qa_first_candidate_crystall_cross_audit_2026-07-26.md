# QA First Candidate CRYSTALL Cross-Audit

Status:

```text
layer: chaos (crystall audit evidence + document decision)
date: 2026-07-26
chapter: 8.5.5D provider physics
scope: C1-C10 only
audit result: accepted after in-place corrections
CRYSTALL gate: satisfied
implementation authorized: exact D1-D7 order only
Packet QA request/grant/receipt authority: forbidden
body evidence/verdict/completion/tree authority: forbidden
```

## 0. Audited Crystall

Primary new owners:

```text
docs/02_crystall/blueprints/qa_detached_source_staging.v0.md
docs/02_crystall/blueprints/qa_provider_candidate_transaction.v0.md
```

Amended owners:

```text
docs/02_crystall/blueprints/candidate_seal_transaction.v0.md
docs/02_crystall/blueprints/qa_execution_capability.v0.md
docs/02_crystall/blueprints/qa_native_supervisor.v0.md
```

Source decisions:

```text
docs/00_chaos/qa_first_candidate_table_cross_audit_2026-07-26.md
docs/01_table/yellowprints/candidate_seal_transaction_yellowprint.v0.md
docs/01_table/yellowprints/qa_detached_source_staging_yellowprint.v0.md
docs/01_table/yellowprints/qa_provider_candidate_transaction_yellowprint.v0.md
docs/01_table/yellowprints/qa_execution_capability_yellowprint.v0.md
```

Current ABI/runtime surfaces checked for implementability:

```text
native/proc17_qa_wire.h
native/proc17_qa_policy.h
native/proc17_qa_launcher_internal.h
native/proc17_qa_launcher.c
native/proc17_qa_supervisor.c
runtime/candidate_seal.lua
runtime/repository_capability.lua
runtime/repository_provider.lua
runtime/qa_provider.lua
runtime/qa_environment.lua
core/qa_schema.lua
tests/support/qa_control_catalog.lua
```

## 1. C1-C10 Ownership Map

| Slice | Crystall owner | Closed implementation decision |
|---|---|---|
| C1 | candidate seal amendment | bounds enter inventory/closure/body identities |
| C2 | provider transaction | source binding v1 conditional schema and sticky lease |
| C3 | provider transaction | one pure inventory normalizer, two private root checks |
| C4 | detached staging | exact self-bind/open_tree/move_mount/cleanup machine |
| C5 | detached staging | feature/policy/build/environment identity rotation |
| C6 | detached staging | RUN kinds 3/4, fd3..fd6 and fixed result vocabulary |
| C7 | provider transaction | strict private process observation/error |
| C8 | provider transaction | post-disposition witness assembler and firewall |
| C9 | provider transaction | source disposition and Packet/root/economics ablation |
| C10 | provider transaction | QN16-only promotion and implementation order |

Every slice has one owner. None depends on code inventing policy.

## 2. Exact Implementable Chain

```text
C1 seal commits canonical bounds
  -> C2 source binding v1 proves closure/bounds/transaction mode
  -> C3 repository provider reads and pure normalizer derives pre inventory
  -> C4 exact sealed fd becomes detached source mount
  -> C5 measured environment proves that exact staging policy
  -> C6 one fixed RUN returns private native facts
  -> C7 adapter removes raw identities and normalizes process fact
  -> C3 derives post inventory through the same reader
  -> C8 creates private pending join
  -> C9 registry terminalizes source lease
  -> C8 final assembler names witness report/error
  -> C9 proves Packet/public root/economics unchanged
  -> C10 allows QN16 alone to change color
```

The chain has no body request, QA execution receipt or Packet event.

## 3. Findings During Crystallization

### F1. Final witness was ordered before source finality

Class:

```text
temporal writer contradiction / high
```

The TABLE draft assembled the final witness before `finish_qa_source`, even
though terminal disposition was one of the writer's required facts.

Correction applied to TABLE and CRYSTALL:

```text
process + pre/post -> private untagged pending join
finish source lease -> terminal disposition
pending join + disposition -> final witness
```

The pending join has no protocol id, store or external reader.

### F2. D source transaction digest did not initially commit every binding coordinate

Class:

```text
identity underspecification / medium
```

The first C2 seed omitted root fingerprint, candidate-seal event ref,
inventory digest and bounds. Other ids committed them transitively, but the
transaction identity itself should change on every exact binding change.

Correction applied:

```text
provider_witness transaction seed commits every v1 binding coordinate except
the derived transaction id, absent qa_request_id and truth-status wrapper
```

The id remains audit identity, never authority.

### F3. Fixed Lua-error exit and contained-outcome mapping were implicit

Class:

```text
implementation choice leakage / medium
```

Without a fixed exit, C and tests could choose different meanings for the same
runtime error. Without a complete mapping, D assembler would invent whether a
signal/limit result was accepted or rejected.

Correction applied:

```text
unhandled Lua load/runtime error fixture exit = 70
expected_exit -> accepted
every other contained process outcome -> rejected with the same exact reason
```

The broader hostile outcomes remain unpromoted; schema existence is not
experimental evidence.

### Audit verdict on findings

All three were corrected before implementation authority was granted.

## 4. Supersession Audit

| Stale crystall text | New authority | Status |
|---|---|---|
| `qa.native_request.v0` generic D wording | exact `qa.native_run_request.v0` | explicitly superseded for D |
| fd3..fd5 descriptor list | fixed fd3..fd6 ABI | explicitly superseded |
| direct procfd bind | detached staging state machine | explicitly superseded; no fallback |
| probe-specific direct mount path | same staging function as RUN | explicitly superseded |
| source binding v0 `request_id` | v1 closure/QA/transaction split | v0 rejected after promotion |
| adapter returns complete provider report | private process observation first | amended |
| D uses body candidate report/error | distinct witness protocols | forbidden alias |
| seal omits inventory bounds | bounds-bearing inventory/closure/body seal | amended |

Old text remains archaeology where stated. It owns no fallback behavior.

## 5. Native ABI Audit

Current wire already reserves:

```text
PROBE_REQUEST=1
PROBE_RESULT=2
RUN_REQUEST=3
RUN_RESULT=4
```

C6 fills kinds 3/4 without changing wire envelope version 0 or adding a second
result kind. Candidate outcome versus provider error is a closed disposition
inside RUN_RESULT.

Current supervisor already reads fd 6 for self hashing. C6 documents that real
fact and adds it to the shared fixed-descriptor contract rather than assigning
a new descriptor.

The staging sequence is implementable with the selected Linux APIs:

```text
statx mount identity
private nonrecursive self-bind
open_tree clone
umount temporary bind
mount_setattr on detached fd
move_mount into empty root
```

Missing syscall/mount-id support withholds environment availability. No root,
copy, direct-bind or pathname fallback exists.

## 6. Identity Audit

| Identity | Directly commits | Cannot mean |
|---|---|---|
| inventory id/digest | request, root, bounds, exact entries/counts | current defaults |
| closure id | sealed root lifecycle + inventory including bounds | body acceptance |
| candidate seal id | Packet/work/closure/inventory including bounds | QA result |
| source transaction id | every provider-witness binding coordinate | source authority by itself |
| witness id | every detached witness field except ids | body request |
| environment id | provider/supervisor/policy/feature/build coordinates | source identity |
| process observation | one contained process world | pre/post source stability |
| witness report | process + pre/post + terminal source disposition | QA check/verdict |

No identity is overloaded across rows.

## 7. Writer/Reader Audit

| Record | Writer | First reader | Closed? |
|---|---|---|---|
| bounds-bearing inventory | pure normalizer after root proof | seal or D comparator | yes |
| bounds-bearing closure | repository registry | body seal/source resolver | yes |
| bounds-bearing body seal | dedicated body writer | D witness derivation | yes |
| source binding v1 | D witness derivation | repository source resolver | yes |
| source lease/disposition | repository registry | callback/finish/replay controls | yes |
| staging attestation | native supervisor/kernel observation | native launcher validator | yes, private |
| environment record | production probe | environment registry/D witness | yes |
| process observation/error | strict adapter | pending-join builder | yes |
| pending join | D callback | finish/final assembler | yes, ephemeral |
| witness report/error | final D assembler | hostile harness | yes |
| measured D cost | supervisor/adapter | harness | yes, no economic writer |

No written record lacks a named reader. No reader receives authority over its
writer's upstream fact.

## 8. Failure And Finality Audit

```text
preflight/staging clean failure
  candidate_started=false
  complete cleanup proof
  source consumed
  witness world error after disposition

contained candidate result
  staging/reap/EOF/cleanup complete
  pre == seal == post
  source consumed
  witness accepted/rejected after disposition

source drift or cleanup uncertainty
  no witness report
  source quarantined
  witness ambiguous error only after disposition

trusted contradiction
  quarantine attempted
  harness loud
  no beautiful Packet death and no rerun
```

Seal finality and source-write closure survive every branch.

## 9. Authority Ceiling Audit

Forbidden by module placement, schema and controls:

```text
organ/router call to D witness module
QA request/grant/receipt creation
Packet trace/event append
budget/loss/lineage accounting
provider witness accepted as body report
completion/work-layer/tree consumption
generic command/executable/env/cwd selection
source path/fd/raw identity projection
```

The only mutation outside private native mechanics is source-lease lifecycle.
Packet and public root projections are ablated before/after.

## 10. Control Coverage

| Slice | Blocking controls |
|---|---|
| C1 | ST21a bounds-only identity/cross-join |
| C2 | SB01-SB10 |
| C3 | IN01-IN08 |
| C4 | DS01-DS12 |
| C5 | EN01-EN06 |
| C6 | NW01-NW10 |
| C7 | PO01-PO08 |
| C8 | WA01-WA10 |
| C9 | AB01-AB09 |
| C10 | QN16 exact delta and whole-catalog ablation |

TABLE falsifiers PT-T01 through PT-T23 and DS-T01 through DS-T20 all have a
CRYSTALL owner. No implementation slice is accepted from branch coverage
alone; real source-under-`/tmp`, native fixture execution and grown sealed roots
are required where named.

## 11. Runtime Baseline

No runtime code changed in this CRYSTALL round. The preimplementation baseline
remains the TABLE-audit observation:

```text
lua tests/run.lua -> exit 0, all ordinary suites green
lua tests/smoke_mortality_battery.lua -> 8/8
lua tests/red_qa_hand.lua -> expected nonzero
  39 green / 45 red
  native 15 green / 5 red
  QN16 red
```

Required implementation result:

```text
ordinary and mortality baselines unchanged
40 green / 44 red
native 16 green / 4 red
QN16 is the only expected-red control promoted
```

## 12. Authorized Implementation Order

```text
D1 implement C1 bounds commitment + C3 pure normalizer; full regression
D2 implement C2 source binding v1 + sticky controls; full regression
D3 implement C4 staging in PROBE + C5 environment rotation; full regression
D4 implement C6 RUN wire/parser/basic native fixtures; full regression
D5 implement C7 strict process normalizers; full regression
D6 implement C8/C9 real sealed-root witness transaction; full regression
D7 implement C10 QN16 promotion and exact matrix audit; full regression
```

Each slice stops on:

```text
unexpected ordinary regression
unauthorized expected-red status change
new raw authority projection
failure that cannot be classified without inventing policy
```

## 13. Decision

```text
document_decision:
  C1-C10 crystall is accepted
  exact D1-D7 implementation is authorized

  authorization does not include Packet QA execution, body evidence, verdict,
  completion/work-layer promotion, QN17-QN20 or generic command authority
```

The crystallized boundary is now mechanical:

```text
the provider may execute and remember one sealed candidate only after every
source authority has a terminal fate; the Packet still learns nothing
```
