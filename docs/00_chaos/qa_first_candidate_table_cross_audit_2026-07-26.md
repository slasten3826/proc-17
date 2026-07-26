# QA First Candidate TABLE Cross-Audit

Status:

```text
layer: chaos (cross-table audit evidence + document decision)
date: 2026-07-26
chapter: 8.5 second QA hand
scope: step 8.5.5D provider physics only
audit result: accepted after in-place TABLE corrections
TABLE gate: satisfied
CRYSTALL authorized: yes, exact D0 surface only
runtime implementation authorized: no; CRYSTALL remains mandatory
Packet QA execution authorized: no
QA verdict/completion/tree promotion authorized: no
```

## 0. Audited Corpus

Primary CHAOS source:

```text
docs/00_chaos/second_qa_hand_first_candidate_transaction_notes_2026-07-26.md
```

New TABLE owners:

```text
docs/01_table/yellowprints/qa_detached_source_staging_yellowprint.v0.md
docs/01_table/yellowprints/qa_provider_candidate_transaction_yellowprint.v0.md
```

Amended TABLE owner:

```text
docs/01_table/yellowprints/qa_execution_capability_yellowprint.v0.md
docs/01_table/yellowprints/candidate_seal_transaction_yellowprint.v0.md
```

Dependency contracts checked at their joins:

```text
candidate_seal_transaction_yellowprint.v0.md
repository_candidate_lifecycle_yellowprint.v0.md
capability_safe_repository_hands_yellowprint.v0.md
qa_contract_profile_yellowprint.v0.md
qa_check_verdict_yellowprint.v0.md
qa_execution_capability.v0.md
qa_native_supervisor.v0.md
```

Runtime claims were checked against:

```text
runtime/repository_capability.lua
runtime/repository_provider.lua
runtime/candidate_seal.lua
runtime/qa_provider.lua
tests/support/qa_control_catalog.lua
tests/red_qa_hand.lua
```

## 1. Audit Question

The audit did not ask whether the future complete QA hand is designed. It
asked one narrower question:

```text
Can CRYSTALL specify one real execution of one exact sealed candidate inside
the native isolated world without granting that execution any Packet, receipt,
verdict, completion or routing authority?
```

Answer after the corrections below:

```text
yes
```

## 2. Closed D Causal Chain

The accepted TABLE chain is:

```text
real first-hand build Packet
  -> exact current candidate seal and private closure
  -> one repository.qa_source_binding.v1(provider_witness)
  -> one sticky private repository source lease
  -> one pre-inventory through repository_provider.inventory_tree
  -> fd-authoritative detached source staging
  -> one exact native RUN
  -> one private process observation/error
  -> one post-inventory through the same repository reader
  -> one private pending join
  -> one terminal source-lease disposition
  -> one D-owned witness report/error
```

Deliberately absent from the chain:

```text
qa.check_request.v0
qa.execution_grant.v0
qa.execution_receipt.v0
qa_check / qa_execution_failure body events
qa.candidate_verdict.v0
completion/work-layer/pressure/tree readers
Packet mutation of any kind
```

This absence is an authority boundary, not unfinished wiring inside D.

## 3. Findings And Disposition

### F1. Ambiguous source-binding `request_id`

Class:

```text
identity vocabulary collision / high before implementation
```

The current private `repository.qa_source_binding.v0` names the candidate-seal
closure request with `request_id`. The future body contract independently owns
`qa.check_request.v0.request_id`. Reusing the key would make one source lease
unable to state which request identity it carries.

Disposition applied in TABLE:

```text
repository.qa_source_binding.v0 -> superseded in-memory protocol
repository.qa_source_binding.v1:
  closure_request_id = candidate-seal closure coordinate
  qa_request_id      = future body request coordinate or absent in D
  transaction_id     = one private source-consumption coordinate
```

Mode law:

| Mode | closure request | QA request | Caller |
|---|---|---|---|
| `provider_witness` | required | forbidden | trusted D harness |
| `body_execution` | required | required | future QA capability registry |

No persistent history needs migration because v0 bindings are private and
in-memory.

### F2. One protocol name described two incompatible reports

Class:

```text
schema identity collision / high
```

The first draft gave the D-only report the already-owned protocol name
`qa.provider_candidate_report.v0`. The existing body transaction requires that
schema to carry body request/check coordinates; D correctly has none. Two
schemas under one protocol version would make strict validation impossible.

Disposition applied in TABLE:

```text
D-only:
  qa.provider_witness_report.v0
  qa.provider_witness_error.v0

future body transaction, unchanged:
  qa.provider_candidate_report.v0
  qa.provider_error.v0
```

Neither D protocol is accepted by the future body writer.

### F3. The provider was named writer of a fact not yet observable

Class:

```text
writer/temporal contradiction / high
```

The first draft said `qa_provider.run` returned the final report, but the exact
post-inventory is taken only after that call returns. The provider cannot
truthfully write whole-transaction source stability before D7.

Disposition applied in TABLE:

```text
strict native adapter
  writes private process observation/error only

D transaction assembler after post-inventory
  joins witness + process + pre/post inventory + source disposition
  writes provider_witness_report/error
```

The correction gives each fact one writer at the first point where all of its
inputs exist.

### F4. Seal evidence did not preserve its inventory bounds

Class:

```text
evidence join omission / high before D
```

The seal request supplies exact `inventory_bounds`, but the original
normalized inventory, private closure and body seal omitted them. D therefore
could not prove that pre/post inventory used the same limits as the sealing
observation. Reusing current defaults would make policy configuration an
unstated source of truth.

Disposition applied in TABLE:

```text
one normalized inventory_bounds record now crosses:
  request -> inventory -> closure -> body seal -> QA source binding

inventory_digest and inventory_id commit to the bounds
closure_id and candidate_seal_id transitively and directly commit to them
the source resolver compares binding bounds to the sealed private closure
```

Equal entries under different bounds are now different evidence and cannot be
cross-joined. The full bounded record is retained because the later repository
reader needs the values, not merely their digest.

### F5. Final witness preceded terminal source disposition

Class:

```text
writer/temporal contradiction / high
```

The first transaction order assembled the final witness at D8 but finished the
private source lease only at D10, while the report's writer contract required
terminal source disposition. A clean report could therefore escape before
source finality was known.

Disposition applied in TABLE:

```text
D8  create private pending join only
D9  leave source callback with no userdata
D10 finish source lease exactly once
D11 assemble final witness from pending join + terminal disposition
```

The pending join has no protocol identity and no external reader. A failed or
contradictory finish emits no clean witness.

### Audit verdict on findings

All five findings were corrected in TABLE before crystallization. None is
deferred to implementation.

## 4. Authority And Identity Join

| Coordinate/fact | Sole owner | First validating reader | May authorize body truth in D? |
|---|---|---|---|
| root authority id | repository registry | source resolver/launcher | no |
| original fd identity | repository provider + launcher reobservation | supervisor and launcher validator | no |
| staged mount identity | native supervisor | native launcher validator | no |
| environment id | environment registry | D witness validator | no |
| closure request id | candidate-seal transaction | source-binding resolver | no |
| QA request id | future Packet request writer | future QA capability registry | absent |
| transaction id | D witness derivation/source lease | source resolver and D assembler | no |
| witness id | trusted D harness | D schema validator | no |
| inventory id/digest | shared pure normalizer over provider observation | seal/source transaction | no |
| process observation/error | strict native adapter | D assembler | no |
| witness report/error | D assembler | D harness assertions | no |
| body check/verdict | dedicated future body writers | completion/work layer | absent |

No row aliases another row's identity. In particular:

```text
closure_request_id != qa_request_id by role
transaction_id is neither request id
original mount id need not equal cloned staged mount id
witness report id is not a body provider-result id
environment id is policy identity, not source identity
```

## 5. Detached Source Proof

The staging table closes the `/tmp` source problem without converting a path
into authority:

```text
exact sealed fd
  -> observe transient procfd-derived locator
  -> compare locator identity to fd identity
  -> private-namespace self-bind
  -> open_tree detached clone
  -> detach temporary self-bind
  -> mount_setattr readonly,nosuid,nodev,noexec
  -> hide host /tmp and construct empty root
  -> move_mount exact detached object to /qa/source
```

Required identity relations:

```text
original.device == detached.device == attached.device
original.inode  == detached.inode  == attached.inode
detached.staged_mount_id == attached.staged_mount_id
detached.staged_mount_id may differ from original.mount_id
```

The locator, raw device/inode/mount ids and mount descriptors remain
native-private. The normalized report carries only the already-defined
environment policy identity and pre/post inventory stability.

## 6. Inventory Ownership

The host is read exactly twice through one authority API:

```lua
repository_provider.inventory_tree(repository_userdata, inventory_bounds)
```

The candidate-seal normalizer is to be factored into shared pure logic. The
factor performs no host read. Authority-specific root continuity is proven by
the active candidate-seal or QA-source lease before the pure normalization.

The canonical normalized `inventory_bounds` record is an input to the pure
inventory identity. It is preserved by the private closure and body seal, then
checked by the source-binding resolver before either D observation.

Required equality:

```text
pre.inventory_id == seal.inventory_id == closure.inventory_id
post.inventory_id == pre.inventory_id
pre.inventory_digest == seal.inventory_digest == closure.inventory_digest
post.inventory_digest == pre.inventory_digest
pre.inventory_bounds == seal.inventory_bounds == closure.inventory_bounds
post.inventory_bounds == pre.inventory_bounds
pre.entries == post.entries == sealed exact inventory
```

This does not create a second filesystem reader or inventory ledger.

## 7. Writer/Reader Audit

| Record/state | Writer | Named reader | Result |
|---|---|---|---|
| source binding v1 | trusted D harness | repository source resolver | closed |
| private source lease | repository registry | callback/finish operations | closed |
| transient locator | native staging implementation | immediate identity comparator | closed, ephemeral |
| native staging attestation | kernel/supervisor observation | launcher validator | closed, private |
| environment feature record | production probe | environment registry/contract binder | closed |
| raw pre/post inventory | repository provider | pure normalizer | closed |
| normalized inventory | pure normalizer under private lease | D assembler/equality controls | closed |
| native RUN request | strict QA adapter | launcher/supervisor | closed |
| process observation/error | strict adapter | D assembler | closed |
| witness report/error | D assembler | D harness assertions | closed |
| source disposition | repository registry | replay/cleanup controls | closed |
| measured D cost | supervisor/adapter | D harness | closed, observation only |

There is no new written record without a named reader.

## 8. Failure Separation

| Failure class | Candidate started? | D result | Source disposition |
|---|---:|---|---|
| malformed trusted input/wire | no or unknown | loud invariant | quarantine when authority was consumed |
| pre-inventory mismatch | no | witness world error | consumed only with complete proof; otherwise quarantine |
| clean detached-staging failure | no | `world/source_staging_failed` | consumed after proven cleanup |
| candidate Lua load/runtime failure | yes | witness report `rejected/unexpected_exit` | consumed |
| post-inventory drift | yes | witness ambiguous error | quarantine |
| reap/EOF/cleanup uncertainty | yes or unknown | witness ambiguous error | quarantine |
| impossible native result | unknown | loud invariant | quarantine |

An infrastructure uncertainty never becomes candidate rejection. Candidate
rejection never becomes Packet death because D has no body writer.

## 9. Packet And Root Ablation

D may change only private source-lease lifecycle for its disposable root.

Required Packet equality before/after:

```text
status, death and residue
trace length and canonical trace content
budget and loss
field revisions and contents
current operator and tick counters
candidate-seal body projection
```

Required public root equality before/after:

```text
state remains sealed
same root authority/lifecycle/closure/inventory
source-write authority remains terminally closed
```

No body observer may infer that D ran.

## 10. Red/Green Gate

Runtime-confirmed preimplementation baseline on 2026-07-26:

```text
lua tests/run.lua
  exit 0; all ordinary suites green

lua tests/smoke_mortality_battery.lua
  8/8 green

lua tests/red_qa_hand.lua
  expected nonzero red-battery exit
  individual controls: 39 green / 45 red
  native supervisor: 15 green / 5 red
  QN16: red
```

The only authorized D delta is:

```text
QN16 clean and nonzero fixtures classify exactly: red -> green
```

Required post-D matrix:

```text
40 green / 44 red
native supervisor: 16 green / 4 red
```

`QN17-QN20`, `QE08-QE20`, every body check/verdict control and every
completion/tree promotion control remain red. Any additional green is a failed
authority ablation.

## 11. CHAOS Falsifier Coverage

| CHAOS falsifier | TABLE owner/control |
|---|---|
| S1 no fallback after direct procfd failure | DS-T01 |
| S2 source below host `/tmp` stages exactly | DS-T02 |
| S3 transient path substitution fails | DS-T03/DS-T04 |
| S4 wrong detached device/inode stops | DS-T05 |
| S5 wrong staged mount continuity stops | DS-T06/DS-T07 |
| S6 write through `/qa/source` is denied | DS-T08 |
| S7 staging failure starts no candidate | DS-T16/DS-T17 |
| S8 clean silent candidate is exact | PT-T10 |
| S9 Lua error remains candidate rejection | PT-T11 |
| S10 source drift produces no clean report | PT-T13 |
| S11 replay starts no second supervisor | PT-T08/PT-T09 |
| S12 Packet has zero D mass | PT-T18 |
| S13 no receipt/body evidence | PT-T17/PT-T20 |
| S14 QN16 alone changes color | PT-T21/PT-T22 |

All CHAOS falsifiers have a named TABLE control. None requires a policy choice
to be invented in code.

## 12. Cross-Document Supersession

The old execution table remains live for future body execution, with three
explicit amendments:

```text
section 8 direct-bind mechanics
  -> superseded by detached source staging TABLE

sections 5-7 and 16 request/grant/receipt/body transaction
  -> not entered by D; remain future body authority

repository.qa_source_binding.v0 ambiguous request key
  -> superseded by v1 split identity vocabulary
```

The old direct-bind prose remains archaeology. It is not implementation
authority and must be marked similarly in CRYSTALL.

## 13. Deferred Surface

This gate does not decide or authorize:

```text
hostile candidate containment claims QN17
trusted crash/pipe fault classification QN18
cleanup ambiguity campaign QN19
repeated leak campaign QN20
Packet QA request/grant/receipt transaction
QA check/failure body writers
verdict assembly
completion/work-layer/tree promotion
retry, resume, parallel checks or generic commands
raw output retention
repository cleanup/compost
```

Those remain later slices. D cannot make them green accidentally.

## 14. Required CRYSTALL Order

CRYSTALL may now transcribe the accepted TABLE decisions in this order:

```text
C1 candidate inventory/closure/body-seal bounds commitment amendment
C2 repository.qa_source_binding.v1 exact schema and validator
C3 shared pure inventory normalizer and authority-specific root checks
C4 detached source staging syscall/cleanup state machine
C5 environment feature/build identity rotation
C6 native RUN request/result/error wire and fixed descriptors
C7 strict private process observation/error normalizers
C8 D witness report/error assembler
C9 source-lease disposition and Packet/root ablation
C10 QN16-only promotion controls
```

CRYSTALL may choose representation and function boundaries. It may not invent
new authority, a second host reader, a body receipt, a report protocol alias or
a fallback source path.

## 15. Decision

```text
document_decision:
  the two new TABLE owners and the 2026-07-26 execution-table amendment are
  accepted for step 8.5.5D

  crystallization is authorized for the exact provider-witness surface

  runtime implementation remains forbidden until the corresponding CRYSTALL
  amendments exist and preserve the QN16-only red/green boundary
```

The audit's central result is not that candidate execution is generally safe.
It is narrower and testable:

```text
the provider may observe one real sealed candidate without the Packet gaining
even one bit of authority from that observation
```
