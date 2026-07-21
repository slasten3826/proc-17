# Stage Transition And Generation Recovery Blueprint v0

Status:

```text
crystall
date: 2026-07-20
source table: docs/01_table/yellowprints/stage_transition_generation_recovery_yellowprint.v0.md
depends on:
  docs/02_crystall/blueprints/lineage_in_memory_slice.v0.md
  docs/02_crystall/blueprints/lineage_completion_continuation_separation.v0.md
  docs/02_crystall/blueprints/completion_scope.v0.md
  docs/02_crystall/blueprints/documentation_profiles_economy.v0.md
implementation authority: shadow stage projection, then opt-in linear process v1
default lineage authority change: forbidden until promotion record
QA implementation: deferred
amended 2026-07-21: F5 removes writerless stage-level rejected state;
  F6 canonical stage identity and applicability vocabulary; F4 recovery carries
  the rejected-generation terminal manifest projection, not a failure crystal
audit source: docs/00_chaos/fable_preimplementation_crystall_audit_raw_2026-07-21.md
F4 decision: docs/00_chaos/f4_rejected_generation_terminal_projection_notes_2026-07-21.md
2026-07-21 cross-table documentary gate: satisfied
```

## 0. Crystallized Claim

One software request is a lineage of mortal Packet lives grouped into typed
stages.

```text
root task
  -> plan stage, one or more Packet generations
  -> exact terminal plan candidate + corpse
  -> lineage stage completion
  -> stage-transition carrier
  -> NETWORK@▽
  -> build stage in a fresh repository
  -> one or more build generations
  -> accepted terminal candidate or rejected-generation recovery
  -> lineage software acceptance / final delivery
```

Stage transition and recovery are distinct:

```text
transition = source stage succeeded; enter declared successor
recovery   = source generation failed to finish; retry same stage in new life
```

Neither carries Packet identity or source authority across △.

## 1. Identity Laws

```text
one root request -> one lineage id
one declared stage -> one stage id
stage id -> "stage:" .. lineage_id .. ":" .. ordinal .. ":" .. stage_key
one Packet birth -> one generation number and Packet id
one build generation -> one repository id/root fingerprint
one terminal Packet -> one immutable corpse
one corpse -> at most one committed child carrier
one child carrier -> exactly one target generation transaction
```

A stage may contain several recovery generations. `attempt_count` is derived
from generation entries and never independently incremented.

## 2. Target Surface

New:

```text
runtime/process_contract.lua
runtime/stage_projection.lua
runtime/stage_completion.lua
runtime/repository_generation.lua
runtime/applicability.lua
tests/test_process_contract.lua
tests/test_stage_projection.lua
tests/test_stage_completion.lua
tests/test_stage_transition.lua
tests/test_generation_recovery.lua
tests/test_repository_generation.lua
tests/test_applicability.lua
```

Modify behind explicit v1 mode:

```text
runtime/lineage.lua
runtime/lineage_runner.lua
runtime/carrier.lua
runtime/network_ingress.lua
runtime/completion.lua
runtime/corpse.lua
runtime/session_memory.lua
runtime/tension_runner.lua
tests/test_lineage.lua
tests/test_lineage_runner.lua
tests/test_carrier.lua
tests/test_network_ingress.lua
tests/run.lua
```

The existing linear same-mode `lineage.in_memory.v0` remains a control path
until v1 parity and promotion are recorded.

Sibling dependency, not reimplemented here:

```text
runtime/documentation_contract.lua
```

## 3. Process Contract

```lua
local process_contract = require("runtime.process_contract")

process_contract.bind(input, policy) -> contract | nil, err
process_contract.verify(contract) -> true | nil, err
process_contract.stage(contract, stage_key) -> detached_stage | nil, reason
process_contract.successor(contract, stage_id) -> detached_stage | nil, reason
```

Primary contract:

```lua
{
  protocol_version = "process.contract.v0",
  process_contract_id = "software.create.v0",
  process_contract_ref = "process-contract:<sha256>",
  context = "software_task.v0",
  stages = {
    {
      stage_key = "plan",
      ordinal = 1,
      mode = "plan",
      completion_contract_id = "plan.v0",
      expected_result_protocol = "plan.result.v0",
      on_success = "transition:build",
    },
    {
      stage_key = "build",
      ordinal = 2,
      mode = "build",
      completion_contract_id = "software.candidate_qa.v0",
      expected_result_protocol = "repository.accepted_candidate.v0",
      on_success = "software_accepted",
      on_rejected_generation = "recover_same_stage",
    },
  },
  documentation_contract_ref = "documentation-contract:<sha256>",
  binding_event_truth_status = "runtime_confirmed",
  contract_decision_truth_status = "document_decision",
}
```

The CLI/TUI/API or trusted default binds the documentation contract first. The
process contract carries its exact immutable ref instead of copying profile,
required and limit fields into a second authority surface. Substrate output may
not select or widen either contract.

Compatibility contracts:

```text
plan.only.v0
build.only.v0
software.create.v0
```

## 4. Lineage v1

`runtime.lineage` supports a new explicit protocol without mutating v0 meaning:

```lua
{
  kind = "proc17_lineage",
  protocol_version = "lineage.in_memory.v1",
  lineage_id = string,
  session_id = string,
  status = "created" | "running" | "evaluating_terminal"
    | "transitioning" | "continuing" | "assembling_delivery"
    | "suspended" | "complete" | "exhausted" | "terminated",

  process_contract_id = string,
  process_contract_ref = string,
  root_task = table,

  current_stage_id = string | nil,
  current_stage_key = string | nil,
  current_generation = integer,
  current_packet_id = string | nil,
  current_corpse_id = string | nil,
  current_carrier_id = string | nil,

  stages = table[],
  generations = table[],
  ledger = table[],
  budget = table,
  policy = table,
  continued_corpses = table,
  pending_generation = table | nil,
  terminal = table | nil,
}
```

`current_*` values are validated projections over the append-only ledger. A
mismatch is an invariant failure. Compatibility `work_mode` and
`completion_contract_id` are read-only projections from the current stage.

## 5. Stage And Generation Records

Stage:

```lua
{
  protocol_version = "lineage.stage.v0",
  stage_id = string,
  lineage_id = string,
  stage_key = "plan" | "build",
  ordinal = integer,
  mode = "plan" | "build",
  context = "software_task.v0",
  completion_contract_id = string,
  expected_result_protocol = string,
  status = "pending" | "active" | "complete" | "suspended",
  attempt_count = integer,
  generation_refs = integer[],
  accepted_generation = integer | nil,
  opened_event_ref = string | nil,
  terminal_event_ref = string | nil,
}
```

Generation:

```lua
{
  generation = integer,
  packet_id = string,
  stage_id = string,
  stage_key = string,
  stage_attempt = integer,
  mode = "plan" | "build",
  completion_contract_id = string,

  parent_packet_id = string | nil,
  parent_corpse_id = string | nil,
  ingress_carrier_id = string | nil,
  ingress_carrier_class = "stage_transition" | "recovery" | nil,

  repository_id = string | nil,
  repository_allocation_ref = string | nil,
  candidate_seal_id = string | nil,
  qa_verdict_ref = string | nil,

  corpse_id = string | nil,
  terminal_kind = string | nil,
  local_budget_allocation = table,
  substrate_session_id = string | nil,
  born_event_id = string,
  terminal_event_id = string | nil,
}
```

Plan generations have nil repository fields. Every build generation must have
a fresh committed repository allocation before Packet birth.

## 6. Ledger Events

Required event vocabulary:

```text
process_contract_bound
stage_declared
stage_opened
generation_allocated
repository_generation_allocated
generation_born
packet_terminal
corpse_registered
stage_completion_evaluated
root_completion_evaluated
stage_completed
stage_transition_selected
stage_transition_carrier_built
generation_recovery_selected
generation_recovery_carrier_built
stage_suspended
software_accepted
documentation_export_started
documentation_export_completed
documentation_export_partial
root_delivery_completed
```

Every decision event includes decision, reason, exact source refs, target
identity when applicable, completion/economy refs, carrier ref, preserved truth
statuses and `event_truth_status=runtime_confirmed`.

No lineage decision without a ledger event is valid.

## 7. Stage And Root Assessment

Modules:

```lua
stage_completion.evaluate(lineage, stage, corpse, scope)
  -> stage_assessment | nil, err

completion.evaluate_root(lineage, stage_assessment, corpse, scope)
  -> root_assessment | nil, err
```

Order:

```text
1. verify corpse and current generation ancestry
2. obtain terminalized completion-scope candidate
3. derive and append stage_completion_evaluated
4. derive and append root_completion_evaluated independently
5. commit stage/root facts when their contracts are satisfied
6. select exactly one transition/recovery/terminal branch
```

Completion readers may read identity, contracts and exact evidence. They may not
read budget, carrier capacity, recovery policy or future repository availability.

| Stage | Root | Lawful branch |
|---|---|---|
| complete | complete | finish or required documentation boundary |
| complete | unfinished + successor | stage transition |
| unfinished + intrinsically recoverable | unfinished | same-stage recovery if affordable/policy allows |
| rejected generation + exact terminal manifest projection | unfinished | build recovery if affordable |
| blocked/unknown | not complete | suspend/terminate by exact class |
| invariant error | n/a | fail runner loudly |

## 8. Carrier v1

`runtime.carrier` gains a v1 family; v0 recovery remains unchanged during
migration.

```lua
{
  kind = "proc17_lineage_carrier",
  protocol_version = "lineage.carrier.v1",
  carrier_id = string,
  carrier_hash = string,
  carrier_class = "stage_transition" | "recovery",
  transition_contract_id = string | nil,
  recovery_contract_id = string | nil,

  lineage_id = string,
  source_stage_id = string,
  target_stage_id = string,
  source_generation = integer,
  target_generation = integer,
  source_packet_id = string,
  source_corpse_id = string,

  root_task_ref = string,
  process_contract_ref = string,
  source_stage_completion_ref = string | nil,
  source_manifest_ref = string | nil,
  payload = table,
  payload_bytes = integer,
  bounds = table,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
  payload_content_truth_status = "mixed" | "semantic_proposal",
  applicability_truth_status = "inherited_proposal",
}
```

`carrier_hash` covers every field except itself. Payload is bounded before
construction. No path root, grant, lease, provider handle, live Packet or
mutable lineage table may appear.

## 9. Stage-Transition Carrier

```lua
carrier.build_stage_transition(lineage, source_stage, target_stage,
  corpse, stage_assessment, options) -> carrier | nil, err
```

Requires:

```text
source plan corpse/result exact
source stage complete
target is exact declared successor
root remains unfinished
target generation is current + 1
source corpse has no committed child
carrier cost affordable before commit
```

Payload contains bounded original task, accepted `plan.result.v0` projection and
public target-stage contract. Plan applicability remains inherited proposal.

## 10. Same-Stage Recovery Carrier

```lua
carrier.build_generation_recovery(lineage, stage, corpse,
  stage_assessment, options) -> carrier | nil, err
```

Requires intrinsic unfinished/rejected generation evidence and exact recovery
policy. Source and target stage ids are equal.

Build recovery may carry bounded:

```text
original task
accepted plan ref/projection
prior terminal manifest
bounded rejected-generation projection from that exact terminal manifest
corpse residue and remaining-work projection
historical rejected repository/seal/QA public ids
```

Historical repository identity is evidence only. Recovery always reconstructs
the whole candidate in a fresh root.

## 11. Fresh Repository Allocation

Host-side module:

```lua
local repository_generation = require("runtime.repository_generation")

repository_generation.begin(lineage, generation_tx, stage, services)
  -> allocation_tx | nil, err

repository_generation.commit(lineage, generation_tx, allocation_tx)
  -> public_allocation | nil, err

repository_generation.quarantine(allocation_tx, reason)
  -> true | nil, err
```

Order:

```text
1. lineage selects lawful build birth and generation transaction
2. host allocates absent empty root
3. provider opens and fingerprints it
4. private generation-scoped materialization grant is minted
5. lineage appends repository_generation_allocated
6. NETWORK ingress receives public repository id/ref only
7. Packet birth commits against same transaction
```

Allocation or host failure before birth creates no fake Packet death. An
ambiguous/orphan allocation is quarantined, not silently reused.

## 12. NETWORK@▽ v1

```lua
network_ingress.prepare_v1(lineage, carrier, generation_tx,
  public_repository_allocation, options)
  -> ingress | nil, err
```

The ingress verifies carrier hash/bounds, one-child law, stage relation, target
transaction and optional repository allocation. It derives mode and completion
contract from the target stage.

Packet options contain only public identities:

```lua
{
  work_mode = target_stage.mode,
  process_contract_id = string,
  stage_id = string,
  stage_key = string,
  completion_contract_id = string,
  lineage_id = string,
  generation = integer,
  parent_id = string,
  parent_corpse_id = string,
  carrier_id = string,
  repository_id = string | nil,
}
```

Private services remain host-side. The new Packet is born through normal L1/FLOW.

## 13. Same-Life QA Boundary

For v0 design, candidate materialization, seal and bounded QA belong to one
build Packet life:

```text
create -> seal -> source writes gone -> read-only QA -> verdict -> △
```

Same-life QA is not same-life acceptance authority. Accepted QA produces
`software_acceptance_ready`; only the later terminalized corpse and lineage
assessment produce `software_accepted`.

If a sealed Packet dies before QA verdict, v0 recovery builds a fresh candidate
in a fresh repository. It does not resume QA against the ancestor root.

## 14. Runner Decision Order

```text
run one Packet life
capture and verify corpse
register corpse and reconcile Packet cost
derive intrinsic stage assessment
derive intrinsic root assessment

if root delivery complete:
    finish lineage complete

elseif stage complete and declared successor exists:
    evaluate transition affordability/policy
    append transition decision
    build/charge carrier and target allocation
    open successor stage and birth child

elseif stage unfinished after its terminal generation and intrinsically recoverable:
    evaluate recovery affordability/policy
    append recovery decision
    build/charge carrier and fresh allocation when build
    birth same-stage child

elseif blocked/unknown:
    suspend/terminate by typed reason

elseif body/host invariant failed:
    fail runner loudly without forged corpse or decision
```

Completion is evaluated before affordability. A finished stage remains finished
when the wallet cannot pay for its successor.

## 15. Economics

Lineage budget remains cumulative across Packet work, carriers, allocations,
repository effects, seal, QA and documentation.

```text
new Packet receives a local allocation
ancestor spend remains spent
carrier/allocation must be charged before child commit
failed pre-birth host transaction is reported exactly
no transition/recovery child is free
```

Packet-local loss never crosses identity. Lineage economics do.

## 16. Truth Across Birth

| Source fact | Descendant status |
|---|---|
| ancestor died | prior runtime-confirmed fact |
| stage completed | prior runtime-confirmed lineage fact |
| plan/failure interpretation | preserved semantic proposal/mixed |
| applicability to child | inherited proposal/grave pressure |
| target repository allocation | runtime-confirmed only after host commit |
| future candidate success | absent |

Transport never upgrades semantic truth.

Applicability registry:

| Status | Admitted producer | Admitted reader |
|---|---|---|
| `reentry_proposal` | compatibility `carrier.v0` | current network ingress |
| `inherited_proposal` | `lineage.carrier.v1` transition/recovery | v1 verifier and NETWORK ingress |
| `grave_pressure` | grave record or nested grave claim | grave attach/FLOW/pressure |
| `corpus_reentry_proposal` | verified corpus carrier | cold corpus reader and NETWORK@▽ |

`runtime.applicability` validates the exact protocol/class/status tuple. Unknown
tokens and mismatched classes are rejected. A v1 recovery carrier itself uses
`inherited_proposal`; grave-derived fields nested in its payload preserve their
own `grave_pressure` status instead of changing the envelope token.

## 17. Writer And Reader Matrix

| Record | Writer | First named reader |
|---|---|---|
| process contract | trusted binder | lineage constructor |
| documentation contract | trusted documentation binder | process/lineage constructor |
| stage declarations | lineage constructor | stage projector/allocator |
| stage assessment | stage completion reader | lineage runner |
| root assessment | root completion reader | lineage runner/docs boundary |
| transition/recovery decision | lineage runner | matching carrier builder |
| carrier | dedicated builder | NETWORK ingress |
| applicability registry | immutable body module | carrier/grave/corpus verifiers and NETWORK ingress |
| repository allocation | trusted host lifecycle | grant resolver/birth audit |
| stage/generation projection | pure ledger reader | work layer/CLI/TUI/corpus |

## 18. Failure Classes

| Condition | Class | Result |
|---|---|---|
| stage incomplete | task state | recovery candidate may exist |
| stage complete, no successor | process contract | root finish or typed block |
| transition unaffordable | economics | stage truth preserved; no child |
| recovery disabled | policy | lineage suspends; intrinsic state preserved |
| carrier too large | typed transport failure | no child |
| carrier hash/ancestry mismatch | hostile/invariant | ingress rejected |
| repository unavailable | host capability | no Packet death forged |
| duplicate root/repository id | invariant | loud failure/quarantine |
| wrong stage/mode at birth | transaction invariant | commit denied |
| corpse already continued | lineage invariant | second child denied |
| malformed trusted Lua/provider record | world invariant | loud runner failure |
| QA rejects current candidate | generation task evidence | rejected generation recorded; QA alone does not change grave kind |

`qa_rejected` is a generation outcome, not a stage status. In v0 the stage
remains active while recovery is committed or becomes suspended when no child
is running. A future stage-level rejection requires a process-contract policy,
a dedicated ledger event and a named writer before it can enter the enum.

## 19. Permanent Controls

```text
ST01 software.create declares plan then build exactly
ST02 substrate cannot alter stage order/mode/contracts
ST03 stage attempt count derives from generations
ST04 recovery generation preserves stage id and changes Packet id
ST05 transition changes stage id and Packet id
ST06 one corpse cannot commit two children
ST07 completion assessment identical under funded/exhausted wallet
ST08 completed stage remains complete when transition unaffordable
ST09 rejected QA changes generation history, never stage status by itself
ST10 grave/karma cannot authorize or deny rejected-generation recovery

CR01 transition carrier verifies exact plan corpse/result/successor
CR02 recovery carrier refuses complete root
CR03 carrier mutation breaks hash
CR04 carrier contains no authority or live table
CR05 applicability remains inherited proposal

RG01 every build generation gets distinct repository id/fingerprint/root
RG02 rejected ancestor root is never target root
RG03 allocation failure before birth creates no Packet death
RG04 orphan/ambiguous allocation quarantines
RG05 grant identity matches generation transaction exactly

NW01 target mode comes from target stage, not caller
NW02 wrong target generation/stage rejects ingress
NW03 child birth occurs through L1/FLOW
NW04 child has calm/field/loss reset and lineage economics preserved
NW05 private provider/grant objects never enter Packet/carrier

QA01 accepted QA before corpse is only non-terminal boundary candidate
QA02 exact corpse terminalizes candidate
QA03 lineage alone writes software_accepted
QA04 rejected generation recovery starts fresh build ⋯
QA05 recovery consumes the exact terminal manifest projection, never trace-tail presence alone

AP01 carrier.v0 admits only reentry_proposal
AP02 lineage.carrier.v1 admits only inherited_proposal at envelope level
AP03 grave records admit only grave_pressure
AP04 corpus carriers admit only corpus_reentry_proposal
AP05 unknown or mismatched applicability status is rejected
AP06 content truth is never inferred from applicability truth
```

All terminal and continuation controls use grown lives.

## 20. Shadow Migration

```text
1. bind/validate process contracts without changing v0 behavior
2. derive shadow stage/generation projections from current v0 ledger
3. prove observer ablation and v0 reconstruction
4. add v1 state behind explicit process_mode=stageful_v1
5. grow plan-only parity lives
6. implement carrier v1 and plan -> build with fake allocator
7. implement hostile fresh repository allocation
8. grow rejected build -> fresh build generation after seal/QA exist
9. grow accepted build -> software acceptance
10. record separate default-authority promotion
```

No big-bang replacement of the current runner is permitted.

## 21. Promotion Gates

```text
G0 process/stage schemas closed
G1 v0 control path remains green
G2 stage projections are ledger-derived and massless
G3 completion/economics separation exact
G4 carrier class and one-child controls green
G5 NETWORK ingress derives target identity without authority leakage
G6 fresh repository hostile controls green
G7 plan -> build grown life completes under explicit v1
G8 rejected generation -> fresh build life green
G9 accepted QA -> corpse -> lineage acceptance green
G10 invariant failures stay loud and outside Packet mortality
```

## 22. Explicit Deferrals

```text
parallel/branching stage graphs
multiple accepted build candidates
QA child Packet
`qa-check.v0` schema and final QA-verdict writer
resume QA against old sealed root
legacy in-place repair
repository cleanup/compost implementation
persistent lineage resume
semantic process-contract selection
default software.create promotion
documentation-only Packet generation
stage-level rejection without an explicit process-contract policy and ledger event
```

## 23. Crystall Thesis

```text
The task survives by lineage, not by keeping one Packet alive.
Success changes stages; failure changes generations; neither carries mutable
identity across death.
```
