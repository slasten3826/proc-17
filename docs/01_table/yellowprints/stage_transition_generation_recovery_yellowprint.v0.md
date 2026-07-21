# Stage Transition And Generation Recovery Yellowprint v0

Status:

```text
table / yellowprint
documentation authority only
no lineage v1 implementation
no carrier v1 implementation
no default process-contract change
prepared for shadow lineage projection
amended 2026-07-21: F5 removes writerless stage-level rejected state;
  F6 canonical stage identity and applicability vocabulary; F4 recovery reads
  the rejected-generation terminal manifest projection, not a failure crystal
audit source: docs/00_chaos/fable_preimplementation_crystall_audit_raw_2026-07-21.md
F4 decision: docs/00_chaos/f4_rejected_generation_terminal_projection_notes_2026-07-21.md
```

Date:

```text
2026-07-20
```

Primary chaos source:

[`../../00_chaos/nested_work_layer_runtime_integration_2026-07-20.md`](../../00_chaos/nested_work_layer_runtime_integration_2026-07-20.md)

Companion tables:

```text
nested_work_layer_derivation_yellowprint.v0.md
completion_scope_candidate_seal_yellowprint.v0.md
documentation_profiles_economy_yellowprint.v0.md
documentation_corpus_assembly_reentry_yellowprint.v0.md
```

Current lineage authority:

```text
lineage_in_memory_slice_yellowprint.v0.md
lineage_completion_continuation_separation_yellowprint.v0.md
lineage_mechanics_yellowprint.v0.md
```

## 0. Table Decision

The primary software process is one root-task lineage containing multiple
mortal Packet generations and typed stages.

Canonical route:

```text
root request
  -> plan Packet generation
  -> exact plan-stage terminal candidate
  -> Packet death/corpse
  -> lineage stage completion assessment
  -> stage-transition carrier
  -> NETWORK@▽
  -> build Packet generation in a fresh repository
  -> candidate seal
  -> bounded QA

     accepted
       -> Packet terminal software-acceptance candidate
       -> Packet death/corpse
       -> lineage software assessment
       -> root software acceptance
       -> optional/required lineage corpus boundary
       -> final delivery

     rejected
       -> final rejected QA verdict
       -> △ rejected-generation terminal projection
       -> Packet death/corpse
       -> build-generation recovery carrier
       -> NETWORK@▽
       -> fresh build Packet in another fresh repository
```

Stage transition and recovery are not the same event:

```text
stage transition = previous stage succeeded; begin a different typed stage
recovery         = previous generation did not finish its current stage/root work
```

Both preserve lineage economics and ancestry. Neither preserves live Packet
identity or writable authority.

## 1. Current Gap

Current `lineage.in_memory.v0` stores one fixed pair:

```lua
lineage.work_mode
lineage.completion_contract_id
```

Current `carrier.v0` accepts only:

```text
carrier_class = recovery
```

Current `network_ingress` births every descendant with:

```lua
work_mode = lineage.work_mode
```

Therefore the current body can express:

```text
plan -> plan recovery -> plan recovery ...
build -> build recovery -> build recovery ...
```

It cannot express:

```text
plan stage complete
root task incomplete
next Packet is build mode
```

The host harness used in the paired plan/build experiment performed this
transition outside lineage. This table moves the transition into body mechanics
without pretending it is already implemented.

## 2. Identity Hierarchy

```text
session
  -> root lineage
       -> root task
       -> process contract
       -> stage 1: plan
            -> generation 1
            -> generation 2 if plan recovery is needed
       -> stage 2: build
            -> generation 3 / build attempt 1
            -> generation 4 / build attempt 2 after rejection
       -> lineage corpus/export revisions
       -> final delivery
```

Identity laws:

```text
one lineage has one immutable root-task identity
generation numbers increase monotonically across every stage
stage_id = "stage:" .. lineage_id .. ":" .. ordinal .. ":" .. stage_key
one generation owns exactly one Packet
one Packet generation belongs to exactly one stage attempt
one stage may contain several generations
one corpse may produce at most one accepted child carrier
one build generation has one unique repository identity
Packet identity never crosses △
repository write authority never crosses a carrier
```

## 3. Root Process Contract

The root process contract is selected explicitly by CLI/TUI/API policy before
the first Packet birth. The substrate cannot select or modify it.

Primary candidate:

```lua
{
  protocol_version = "process.contract.v0",
  process_contract_id = "software.create.v0",
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

The documentation policy is bound first through the sibling documentation
contract and enters this process contract only by immutable ref. This avoids a
second copied authority surface for profile, required and limits. The body can
runtime-confirm that these exact contracts were bound before birth. That does
not turn the human/project policy encoded by them into an observed law of the
world.

Compatibility contracts:

| Contract | Stages | Intended use |
|---|---|---|
| `plan.only.v0` | plan | existing plan API/tests |
| `build.only.v0` | build | capability experiments and explicit direct-build requests |
| `software.create.v0` | plan then build | primary product path |

The current runtime keeps its existing defaults until a shadow corpus and
promotion record authorize changing them.

## 4. Lineage State v1 Shape

Candidate extension:

```lua
{
  kind = "proc17_lineage",
  protocol_version = "lineage.in_memory.v1",

  lineage_id = "lineage:...",
  session_id = "session:...",
  status = "created" | "running" | "evaluating_terminal"
    | "transitioning" | "continuing" | "assembling_delivery"
    | "suspended" | "complete" | "exhausted" | "terminated",

  process_contract_id = "software.create.v0",
  process_contract_ref = "process-contract:...",
  root_task = {},

  current_stage_id = "stage:..." | nil,
  current_stage_key = "plan" | "build" | nil,
  current_generation = integer,
  current_packet_id = string | nil,
  current_corpse_id = string | nil,
  current_carrier_id = string | nil,

  stages = {},
  generations = {},
  ledger = {},
  budget = {},
  policy = {},
  continued_corpses = {},
  pending_generation = nil,
  terminal = nil,
}
```

`current_*` fields are validated projections/cache over the append-only ledger.
They are not independent truth stores. A mismatch between the projection and
ledger is an invariant failure.

The v0 fields:

```text
lineage.work_mode
lineage.completion_contract_id
```

may remain read-only compatibility projections during migration. They must be
derived from the current stage and cannot select the next stage by mutation.

## 5. Stage Record

One stage identity persists across recovery generations of that stage.

```lua
{
  protocol_version = "lineage.stage.v0",
  stage_id = "stage:<lineage_id>:2:build",
  lineage_id = "lineage:...",
  stage_key = "build",
  ordinal = 2,
  mode = "build",
  context = "software_task.v0",
  completion_contract_id = "software.candidate_qa.v0",
  expected_result_protocol = "repository.accepted_candidate.v0",
  status = "pending" | "active" | "complete" | "suspended",
  attempt_count = 2,
  generation_refs = {2, 3},
  accepted_generation = 3 | nil,
  opened_event_ref = "lineage-event:..." | nil,
  terminal_event_ref = "lineage-event:..." | nil,
}
```

`attempt_count` is a derived projection from stage generation entries. It is not
a counter that can drift independently.

Stage status meaning:

| Status | Meaning |
|---|---|
| `pending` | declared by process contract, not yet entered |
| `active` | at least one current generation is working this stage |
| `complete` | exact stage completion contract satisfied |
| `suspended` | stage intrinsically unfinished but no current continuation is running |

A rejected build candidate normally rejects one generation, not the build stage.
The stage stays active while a paid lawful recovery is selected and becomes
`suspended` when no continuation is currently running. Stage-level rejection is
not a v0 state: no process-contract field or lineage event owns such a
transition. A future contract may add it only together with an exact policy,
named writer and ledger event.

## 6. Generation Entry v1

Current generation identity is extended, not replaced:

```lua
{
  generation = 3,
  packet_id = "packet:...",
  stage_id = "stage:<lineage_id>:2:build",
  stage_key = "build",
  stage_attempt = 2,
  mode = "build",
  completion_contract_id = "software.candidate_qa.v0",

  parent_packet_id = "packet:...",
  parent_corpse_id = "corpse:...",
  ingress_carrier_id = "carrier:...",
  ingress_carrier_class = "recovery",

  repository_id = "repo:<lineage>:generation:3" | nil,
  repository_allocation_ref = "repository-allocation:..." | nil,
  candidate_seal_id = "candidate-seal:..." | nil,
  qa_verdict_ref = "qa-verdict:..." | nil,

  corpse_id = "corpse:..." | nil,
  terminal_kind = string | nil,
  local_budget_allocation = {},
  substrate_session_id = string | nil,
  born_event_id = string,
  terminal_event_id = string | nil,
}
```

Plan generations have nil repository/candidate/QA fields. Build generations
must receive a fresh repository allocation before any repository hand becomes
ready.

## 7. Stage Ledger

The lineage ledger is the authoritative history for both generations and
stages. Candidate new event kinds:

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
documentation_export_started/completed/partial
root_delivery_completed
```

Every decision event contains:

```text
decision
reason
source stage/generation/Packet/corpse refs
target stage/generation when applicable
completion-assessment ref
budget/policy assessment ref when continuation is involved
carrier ref when created
event_truth_status = runtime_confirmed
preserved content truth statuses
```

The lineage runner is a body authority and must be auditable. It may not decide
to continue, transition or finish without a ledger event and exact source refs.

## 8. Stage Completion Versus Root Completion

The runner evaluates terminal evidence in this order:

```text
1. verify corpse and current generation ancestry
2. evaluate current stage completion contract
3. append stage_completion_evaluated
4. evaluate root process completion independently
5. append root_completion_evaluated
6. select exactly one lawful branch
```

Branch matrix:

| Stage assessment | Root assessment | Branch |
|---|---|---|
| complete | complete | finish or required documentation boundary |
| complete | unfinished, next stage exists | stage transition |
| unfinished and intrinsically recoverable | unfinished | same-stage recovery if affordable/policy permits |
| rejected generation with exact terminal manifest projection | unfinished | same-stage build recovery if affordable |
| blocked/unknown | not complete | suspend/terminate by exact classification |
| invariant error | not applicable | fail harness/runtime loudly |

Affordability never changes the stage/root assessment. It only decides whether
a lawful transition/recovery action can be paid.

## 9. Successful Stage Transition Carrier

Do not overload `carrier.v0` by changing the meaning of `recovery`.

Candidate new family:

```lua
{
  protocol_version = "lineage.carrier.v1",
  carrier_id = "carrier:<digest>",
  carrier_class = "stage_transition",
  transition_contract_id = "plan_to_build.v0",

  lineage_id = "lineage:...",
  source_stage_id = "stage:<lineage_id>:1:plan",
  target_stage_id = "stage:<lineage_id>:2:build",
  source_generation = 1,
  target_generation = 2,
  source_packet_id = "packet:...",
  source_corpse_id = "corpse:...",

  root_task_ref = "task:...",
  process_contract_ref = "process-contract:...",
  source_stage_completion_ref = "stage-completion:...",
  source_manifest_ref = "plan-result:...",

  payload = {
    original_task = "bounded semantic content",
    accepted_plan = "bounded plan.result.v0 projection",
    target_stage_contract = "bounded public projection",
  },

  bounds = {},
  source_refs = {},
  event_truth_status = "runtime_confirmed",
  payload_content_truth_status = "mixed",
  applicability_truth_status = "inherited_proposal",
}
```

Transition invariants:

```text
source plan corpse and result verify exactly
source stage is complete under the process contract
target stage is the exact declared successor
target generation is current + 1
carrier is bounded and hashed
carrier creation is charged to cumulative lineage budget
no repository grant, host path, provider handle or live Packet table is present
one source corpse creates at most one accepted child carrier
```

The plan result remains semantic material with preserved status. The body
confirms only its identity, transport and applicability proposal.

## 10. Same-Stage Recovery Carrier

Recovery remains the class for intrinsically unfinished work.

Candidate v1 shape shares the family envelope but uses:

```text
carrier_class = recovery
recovery_contract_id = plan_recovery.v0 | build_generation_recovery.v0
source_stage_id = target_stage_id
```

Build-generation recovery payload:

```lua
payload = {
  original_task = "bounded semantic content",
  accepted_plan_ref = "plan-result:..." | nil,
  prior_manifest = "bounded terminal projection",
  rejected_generation = "bounded exact terminal-manifest projection" | nil,
  residue = "bounded corpse residue",
  remaining_work = "bounded semantic projection",
  rejected_candidate = {
    generation = 2,
    repository_id = "historical public identity",
    candidate_seal_id = "candidate-seal:..." | nil,
    qa_verdict_ref = "qa-verdict:..." | nil,
  },
}
```

Historical repository identity may be cited as evidence. It grants no access
and is never reused as the target repository.

Recovery does not mean "continue editing". It means:

```text
birth a fresh Packet
allocate a fresh repository for build mode
recreate the whole candidate under inherited constraints
```

## 11. Carrier Class Matrix

| Property | Stage transition | Same-stage recovery |
|---|---|---|
| Source stage complete | required | normally false |
| Target stage | different declared successor | same stage |
| Root task complete | false | false |
| Carries accepted prior stage result | yes | if relevant |
| Carries rejected-generation projection/residue | not as failure authority | yes when produced |
| Target mode | process-contract successor | same stage mode |
| Fresh Packet | yes | yes |
| Fresh build repository | when target is build | every build generation |
| Resets lineage budget | never | never |
| Carries source capability | never | never |
| Carrier applicability status | inherited proposal | inherited proposal |
| Nested grave applicability | none | grave pressure remains attached to grave-derived claims |

The classes may share validation utilities, hashing and bounded transport. They
must not share ambiguous completion semantics.

## 12. NETWORK@▽ Ingress

NETWORK ingress verifies carrier and lineage state, then derives birth input.

Required v1 derivation:

```text
verify carrier identity/hash/bounds
verify source corpse and one-child rule
verify source/target stage relation
verify target generation transaction
derive target mode from target stage, not a mutable lineage.work_mode
derive prompt/semantic carrier projection
attach ancestry ids
attach repository public identity only after trusted target allocation
birth a new Packet through L1/FLOW
commit lineage birth transaction
```

Packet options may include public identity projections:

```lua
{
  work_mode = target_stage.mode,
  process_contract_id = lineage.process_contract_id,
  stage_id = target_stage.stage_id,
  stage_key = target_stage.stage_key,
  completion_contract_id = target_stage.completion_contract_id,
  lineage_id = lineage.lineage_id,
  generation = target_generation,
  parent_corpse_id = source_corpse_id,
  carrier_id = carrier_id,
  repository_id = target_public_repository_id | nil,
}
```

Private registry objects and provider handles remain host-side.

## 13. Fresh Repository Generation

Every build generation receives a new repository identity.

Allocation order:

```text
1. lineage selects a lawful build birth and target generation
2. host lifecycle authority allocates an absent, empty generation root
3. provider opens and fingerprints the root
4. private generation-scoped materialization grant is minted
5. lineage records repository_generation_allocated
6. NETWORK@▽ receives only the public repository identity/ref
7. Packet birth commits against the same generation transaction
```

Allocation invariants:

```text
repository id unique within lineage and session
root absent/empty before allocation
root fingerprint bound to generation transaction
grant bound to session + lineage + generation + repository
failed/rejected ancestor root never reused
allocation failure before Packet birth creates no fake Packet death
orphan allocation after host failure is quarantined by lifecycle authority
cleanup/compost is host/session lifecycle work, not a coding hand
```

Plan stages require no output repository grant. Read-only legacy observation, if
later implemented, is a different capability from build destination authority.

## 14. Legacy Reconstruction

For a legacy input, the primary contract remains reconstruction:

```text
legacy repository
  -> read-only observation contract
  -> plan stage derives behavioral/structural requirements
  -> build generations write only into fresh roots
  -> QA compares new candidate against observed contract
```

No stage transition or recovery carrier transports legacy write authority.
The old project remains an evidence source, not a mutable patient.

Differential QA belongs to the future QA capability campaign and must name both
read-only source identity and sealed candidate identity exactly.

## 15. QA Placement Decision For v0

First implementation hypothesis:

```text
candidate materialization and bounded QA occur in the same build Packet life
```

Reason:

```text
seal closes source writes without requiring Packet death
QA is the build ⊞ phase of the same candidate attempt
one Packet can spend budget on create -> seal -> read-only QA -> verdict
an extra QA child would add a new carrier/capability boundary before evidence requires it
```

After seal, the living build Packet has:

```text
read-only candidate identity
bounded QA capability if authorized
no source materialization capability
```

If it dies before a verdict, a descendant does not resume QA against the old
candidate in v0. It receives recovery material, a fresh repository and rebuilds
the candidate. This is intentionally expensive but preserves the generation law.

The QA-child alternative remains a future experiment, not an invisible fallback.

Same-life QA is not same-life acceptance authority. The living build Packet may
record an exact accepted verdict and derive a software-acceptance candidate, but
only the lineage reader may turn the later corpse-bound evidence into stage
completion and `software_accepted`.

## 16. Stage Transition State Machine

### Plan success

```text
stage(plan)=active
Packet plan result manifests and dies
corpse registered
stage completion = complete
root completion = unfinished
stage(plan)=complete
lineage affordability/policy checked
stage_transition selected and charged
carrier built and verified
stage(build)=opened
generation transaction allocated
fresh build Packet born
```

### Plan incomplete death

```text
stage(plan)=active
Packet dies budget/loss/stall
intrinsic assessment = unfinished/recoverable
same-stage recovery selected if affordable
fresh plan Packet born through recovery carrier
```

### Build rejection

```text
stage(build)=active
candidate sealed
required QA check evidence rejects
one final rejected QA verdict is assembled
△ embeds the exact rejected-generation projection
Packet dies and corpse registered
generation outcome = rejected
stage remains active if recovery selected
fresh repository + build Packet generation born
```

### Build acceptance

```text
stage(build)=active
candidate sealed
QA accepted
Packet manifests a software-acceptance candidate and dies
corpse registered
lineage verifies stage/candidate/seal/QA/terminal refs
stage(build)=complete
root software assessment=accepted
documentation policy evaluated
lineage completes or enters required corpus/export boundary
```

## 17. Glyph Mapping Across Generations

| Event | Source projection | Boundary | Descendant projection |
|---|---|---|---|
| plan formation | plan `⋯/⊞/◈` | exact plan manifest | plan `▲` historical |
| plan -> build | plan `▲` | corpse + stage carrier + NETWORK@▽ | build `⋯` |
| build candidate sealed | build `⊞` | no death yet | same Packet remains build `⊞` |
| required QA check rejects, final verdict absent | build `◈` | rejected-verdict crystallization still active | no descendant yet |
| final rejected QA verdict present | build `▲` | △ terminal projection + corpse + lineage recovery assessment | next generation build `⋯` |
| QA accepted | build `▲` software-acceptance candidate | terminal candidate + corpse + lineage software assessment | no coding descendant |

The next generation never inherits the old glyph as mutable state. It derives
its own layer from fresh evidence.

## 18. Completion And Continuation Algorithm

Conceptual runner branch:

```text
run one Packet life
freeze terminal Packet
capture and verify corpse
register corpse in lineage
derive stage assessment from exact current stage contract
derive root assessment from exact process/documentation contract

if root delivery complete:
    finish lineage complete

elseif stage complete and exact successor exists:
    assess transition affordability/policy
    if allowed:
        build stage-transition carrier
        charge carrier/allocation
        open successor stage
        birth next generation
    else:
        suspend/exhaust with stage completion preserved

elseif stage intrinsically unfinished after its terminal generation and terminal recoverable:
    assess recovery affordability/policy
    if allowed:
        build same-stage recovery carrier
        charge carrier/allocation
        birth next generation in same stage
    else:
        suspend/exhaust with intrinsic assessment preserved

elseif assessment unknown/blocked:
    suspend/terminate by typed reason

else if body/host invariant failed:
    fail runner loudly; do not forge corpse or lineage decision
```

## 19. Economics

Lineage economics are cumulative across:

```text
all Packet ticks
all substrate calls and token usage
all generation allocations
all carrier construction/transport
all repository effects and verification
all candidate sealing
all QA attempts
all structured/full documentation work
all export effects
```

Each Packet still has local budget and loss. A new birth receives an allocation
from remaining lineage budget; it does not reset what ancestors spent.

Matched law:

```text
stage complete + transition wallet empty
  -> stage remains complete
  -> root remains unfinished
  -> lineage becomes exhausted/suspended
  -> no carrier or child is created for free
```

## 20. Truth Across Birth

| Carrier fact | Descendant status |
|---|---|
| source Packet died | prior runtime-confirmed fact |
| source stage completed | prior runtime-confirmed assessment |
| source plan text | semantic proposal |
| plan applicability to build | inherited proposal |
| source QA rejected exact seal | prior runtime-confirmed fact |
| failure interpretation | semantic proposal with exact refs |
| warning/do-not-repeat | grave pressure, not universal law |
| target repository exists | absent until host allocation confirms it |
| target candidate will pass | absent |

Carrier validation confirms provenance and bounds. It does not canonize semantic
content or guarantee future success.

### Applicability Vocabulary v0

Applicability status is a closed body vocabulary, not a free-form truth label:

| Status | Exact producer/surface | Named reader | Meaning |
|---|---|---|---|
| `reentry_proposal` | compatibility `carrier.v0` recovery | current `network_ingress` verifier | old same-lineage recovery carrier may seed a new Packet |
| `inherited_proposal` | `lineage.carrier.v1` stage transition or recovery | v1 carrier verifier and NETWORK ingress | bounded ancestor content is proposed as applicable to the child |
| `grave_pressure` | grave record or grave-derived nested claim | grave attach/FLOW/pressure reader | ancestor death may perturb the child but is not a route command |
| `corpus_reentry_proposal` | verified external corpus carrier | cold corpus reader and NETWORK@▽ ingress | prior lineage evidence is proposed to a fresh task/lineage |

Validation laws:

```text
status must match the exact producer protocol and carrier/source class
unknown status or class/status mismatch rejects the carrier/source
carrier-level v1 applicability is inherited_proposal
nested grave claims retain grave_pressure and are never flattened into the carrier status
content truth and applicability truth remain separate coordinates
absence is nil, never an invented generic proposal string
```

The current `carrier.v0` keeps `reentry_proposal` as a compatibility token. It
is not silently renamed during shadow migration.

## 21. Writer / Reader Matrix

| Record | Writer | Named readers |
|---|---|---|
| root process contract | CLI/TUI/API policy binder | lineage create, stage projector, completion |
| stage declaration/open event | lineage body | generation allocator, NETWORK ingress, corpus |
| generation transaction | lineage allocator | birth commit, repository allocator |
| repository allocation | trusted lifecycle authority | grant resolver, birth audit, corpus |
| stage completion assessment | completion reader | lineage runner, stage ledger, corpus |
| root completion assessment | root reader | lineage runner, docs assembler, delivery |
| transition decision | lineage runner | carrier builder, audit |
| transition carrier | dedicated carrier builder | NETWORK ingress only |
| recovery decision | lineage runner | recovery carrier builder, audit |
| recovery carrier | dedicated carrier builder | NETWORK ingress only |
| applicability vocabulary | immutable body registry | carrier/grave/corpus verifiers and NETWORK ingress |
| stage/generation projection | pure ledger reader | work-layer inspector, CLI/TUI, corpus |

No stage status or carrier is written without a named consumer.

## 22. Failure Classification

| Condition | Class | Result |
|---|---|---|
| exact stage incomplete | task state | recovery may be considered |
| stage complete, no successor in contract | contract/root assessment | root complete or blocked by explicit contract |
| transition unaffordable | economics | stage truth preserved; no child |
| recovery forbidden by policy | policy | root remains unfinished; lineage suspends/terminates |
| carrier exceeds bounds | typed transport failure | no child |
| carrier hash/ancestry mismatch | invariant/hostile input | reject ingress |
| repository allocation unavailable | host capability failure | no Packet death forged |
| duplicate repository identity | invariant failure | runner fails loudly |
| Packet born in wrong mode/stage | birth transaction invariant | commit denied |
| source corpse already continued | lineage invariant | second child denied |
| malformed Lua/provider response | harness/world invariant | loud runner failure |
| QA rejects current candidate | generation task evidence | lineage records rejected generation; grave kind is unchanged by QA alone |

`qa_rejected` is generation evidence. It never writes a rejected stage by
itself. The lineage recovery reader may keep the stage active, suspend it when
continuation is unavailable, or complete a later accepted generation.
Grave/karma may preserve independent mortality residue, but it cannot approve,
deny or classify this recovery decision.

World failures are not prettified as Packet mortality. Task failures are not
allowed to crash the host merely because they are inconvenient.

## 23. Permanent Control Matrix

### Process contract

| ID | Control | Expected |
|---|---|---|
| S01 | unknown process contract | fail before Packet birth |
| S02 | substrate requests another process contract | no authority delta |
| S03 | `plan.only.v0` exact plan | lineage may complete after plan |
| S04 | same exact plan under `software.create.v0` | stage complete, root unfinished |
| S05 | mutable caller changes stage list after birth | stored bound contract unchanged |

### Stage transition

| ID | Control | Expected |
|---|---|---|
| S06 | exact plan corpse/result | one plan->build transition candidate |
| S07 | plan result stale/missing | no stage transition |
| S08 | target mode supplied as plan despite build successor | ingress rejected |
| S09 | same corpse used for second transition | denied |
| S10 | transition carrier carries provider/grant handle | validation rejected |
| S11 | transition budget unavailable | no carrier/child; plan stage remains complete |
| S12 | exact carrier | child is fresh Packet with next generation/build stage |

### Same-stage recovery

| ID | Control | Expected |
|---|---|---|
| S13 | recoverable plan death | next Packet remains plan stage/mode |
| S14 | rejected build + exact terminal manifest projection | next Packet remains build stage/mode |
| S15 | rejected build with mutation instruction | instruction has no source authority |
| S16 | blocked/nonrecoverable terminal | no recovery carrier |
| S17 | same corpse, wallet available/exhausted | intrinsic assessment same; child only when affordable |

### Repository generation

| ID | Control | Expected |
|---|---|---|
| S18 | build generation N -> N+1 | different repository ids and root fingerprints |
| S19 | allocator returns ancestor repository id | invariant failure |
| S20 | carrier contains source repository public id | historical only; target still fresh |
| S21 | carrier contains private grant | validation rejected |
| S22 | allocation fails before birth | no fake Packet/corpse |
| S23 | birth commit identity differs from allocation | commit denied/quarantine allocation |

### QA placement

| ID | Control | Expected |
|---|---|---|
| S24 | same build Packet before seal | source create authority available |
| S25 | same Packet after seal | source create authority unavailable; QA read authority may be available |
| S26 | Packet dies sealed but untested | recovery rebuilds fresh candidate; no inherited QA authority |
| S27 | QA rejected | no in-place retry or source mutation |

### Ledger and projections

| ID | Control | Expected |
|---|---|---|
| S28 | stage cache differs from ledger derivation | invariant failure |
| S29 | observer enabled/disabled | identical route/economy/effects |
| S30 | generation numbers cross stage boundary | monotonic, no reset |
| S31 | one stage spans several retries | same stage id, increasing attempt/generation |
| S32 | accepted generation recorded | exactly one current accepted build generation |

## 24. Grown-Life Corpus

The campaign must grow complete lives:

```text
P1  plan.only exact success
P2  software.create plan success -> build birth
P3  plan budget death -> plan recovery
P4  plan stage complete but transition budget exhausted
B1  build candidate accepted first generation
B2  build candidate rejected -> fresh generation -> accepted
B3  build dies before seal -> fresh generation
B4  build dies after seal before QA -> fresh generation
B5  build required QA check rejected before final verdict
B6  build generation intrinsically blocked
D1  accepted software + docs off
D2  accepted software + required structured corpus
D3  required corpus export partial/exhausted
H1  injected runner exception during carrier/allocation/birth
```

Each life records:

```text
operator walk per Packet
Packet/generation/stage/repository identities
corpse and carrier chain
stage and root assessments
cumulative/local budget and loss
candidate seal and QA refs
documentation state
named reader for every ledger record
observer ablation result
```

Fixtures for death, seal, QA and transition must be grown by the real producer
path whenever that producer exists.

## 25. Shadow Migration

```text
1. crystallize process/stage/carrier v1 schemas
2. add pure v1 projection over current v0 lineage without changing authority
3. bind explicit compatibility process contracts in shadow
4. classify current plan/build lives by stage and root scope
5. implement stage-transition carrier behind a disabled-by-default runner path
6. prove plan->build birth in an in-memory fake-substrate corpus
7. add fresh build repository allocation transaction
8. grow real provider plan->build life
9. add candidate seal and QA capability campaign
10. grow rejected build -> fresh build generation
11. compare old fixed-mode runner and new process runner
12. write explicit promotion record and rollback rule
```

The current runner remains authority until the new process runner proves exact
identity, economics, mortality and host-failure boundaries.

## 26. Promotion Gates

| Gate | Requirement |
|---|---|
| F0 | process/stage/generation/carrier schemas crystallized |
| F1 | v0 lineage tests remain green |
| F2 | v1 projection observer has zero mass |
| F3 | stage vs root completion matched controls green |
| F4 | transition and recovery carriers cannot be confused |
| F5 | plan->build changes mode only through verified stage carrier |
| F6 | cumulative economics never reset at stage/generation boundaries |
| F7 | build generations always receive unique fresh repositories |
| F8 | no capability crosses corpse/carrier/NETWORK boundary |
| F9 | rejected candidate cannot be mutated or reused |
| F10 | same-Packet seal->QA safety controls green |
| F11 | invariant/host failures remain loud and create no fake deaths |
| F12 | root completion composes required documentation correctly |
| F13 | grown end-to-end plan->build->QA life succeeds under new authority |

## 27. Explicit Deferrals

This table does not yet implement or authorize:

```text
persistent crash resume
branching lineage / multiple children per corpse
parallel build generations
cross-session shared memory
QA child Packets
reuse of sealed candidates after Packet death
general shell or network authority
`qa-check.v0` record schema and final QA-verdict writer
legacy source mutation
automatic semantic process-contract selection
repository cleanup/compost policy
documentation-only Packet continuation
stage-level terminal rejection without an explicit process-contract policy and ledger event
```

## 28. Table Thesis

```text
The task outlives every Packet.
The lineage remembers what each Packet proved and paid.

Success in one stage creates a transition.
Failure in one generation creates recovery pressure.
Both require death, a typed carrier and a fresh birth.

No rebirth resets the bill.
No rebirth reuses the body.
No rejected build reuses its writable world.
```
