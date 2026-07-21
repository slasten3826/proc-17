# Completion Scope Blueprint v0

Status:

```text
crystall
date: 2026-07-20
source table: docs/01_table/yellowprints/completion_scope_candidate_seal_yellowprint.v0.md
implementation authority: pure scope readers and shadow observations only
root manifest authority replacement: forbidden
candidate sealing authority: separate candidate_seal.v0 crystall
QA execution authority: deferred
amended 2026-07-21: F1 generation_state, F3 context identity, F5 stage status
  and F6 canonical ids/boundary vocabulary; F4 removes the standalone failure
  crystal and binds rejected evidence through the terminal Packet manifest
audit source: docs/00_chaos/fable_preimplementation_crystall_audit_raw_2026-07-21.md
F4 decision: docs/00_chaos/f4_rejected_generation_terminal_projection_notes_2026-07-21.md
2026-07-21 cross-table documentary gate: satisfied
```

## 0. Crystallized Claim

`complete` is a typed derived scope, not a Packet boolean and not substrate
prose.

```text
Packet/corpse may prove:
  work_item -> artifact_set -> candidate_sealed

Packet/corpse may additionally expose one terminal boundary candidate:
  plan_stage_ready
  software_acceptance_ready
  rejected_generation_recovery_ready

verified lineage may prove:
  stage -> software_accepted -> root_delivery
```

A boundary candidate is not a larger completion scope. It is exact evidence
offered by one mortal Packet to the lineage reader after △ or death.

## 1. Authority Boundary

Three public entry points enforce subject ceilings:

```lua
local completion_scope = require("runtime.completion_scope")

completion_scope.inspect_packet(instance, contract_view)
  -> inspection | nil, err

completion_scope.inspect_corpse(corpse, contract_view)
  -> inspection | nil, err

completion_scope.inspect_lineage(lineage, contract_view)
  -> inspection | nil, err
```

`contract_view` is a verified detached process/stage-contract projection. It
contains independent `process_contract_id` and semantic `context` fields and is
checked against Packet birth or lineage-ledger evidence before use.

There is no generic API that silently joins a live Packet to caller-supplied
lineage state.

| Subject | Maximum scope | Additional lawful output |
|---|---|---|
| living Packet | `candidate_sealed` | local QA state and boundary candidate |
| verified corpse | `candidate_sealed` | terminal boundary candidate |
| verified lineage ledger head | `root_delivery` | stage/root assessments from exact refs |

Forbidden outputs:

```text
packet/corpse -> stage complete
packet/corpse -> software_accepted
packet/corpse -> root_delivery
substrate prose -> any scope advancement
wallet state -> intrinsic completion change
```

## 2. Target Surface

New:

```text
runtime/completion_scope.lua
tests/test_completion_scope.lua
```

Later integration, only after the pure module is green:

```text
runtime/completion.lua          consume lineage-level scope for process contracts
runtime/corpse.lua              retain exact boundary-candidate refs
runtime/tension_runner.lua      optional massless shadow observation
runtime/lineage_runner.lua      named reader for lineage scopes
tests/test_completion_scope_shadow.lua
```

Dependencies:

```text
runtime/work_completion.lua
runtime/repository_result.lua
runtime/plan_completion.lua
runtime/corpse.lua
runtime/lineage.lua
runtime/lineage_budget.lua      negative dependency only: scope must ignore it
runtime/artifact_set.lua        supplied by candidate_seal.v0
core/digest.lua
core/json.lua
```

The first implementation may return `unsupported` for seal/QA/stage fields
whose named writers do not exist yet. It may not infer them from nearby data.

## 3. Inspection Record

```lua
{
  protocol_version = "runtime.completion_scope_inspection.v0",
  inspection_id = "completion-scope:<sha256>",

  subject_kind = "packet" | "corpse" | "lineage",
  packet_id = string | nil,
  lineage_id = string | nil,
  generation = integer | nil,
  stage_id = string | nil,
  process_contract_id = "plan.only.v0" | "build.only.v0" | "software.create.v0",
  context = "software_task.v0",

  highest_scope = "none" | "work_item" | "artifact_set"
    | "candidate_sealed" | "stage" | "software_accepted"
    | "root_delivery",

  boundary_candidate = {
    state = "none" | "plan_stage_ready" | "software_acceptance_ready"
      | "rejected_generation_recovery_ready",
    terminalized = boolean,
    terminal_ref = string | nil,
    source_refs = string[],
  },

  work_items = {
    needed_count = integer,
    done_count = integer,
    remaining_count = integer,
    done_refs = string[],
    missing_ids = string[],
  },

  artifact_set = {
    state = "complete" | "incomplete" | "unsupported",
    contract_ref = string | nil,
    artifact_refs = string[],
  },

  candidate = {
    state = "unsealed" | "sealed" | "qa_rejection_observed"
      | "qa_accepted" | "qa_rejected" | "unsupported",
    candidate_seal_id = string | nil,
    candidate_seal_event_ref = string | nil,
    qa_verdict_ref = string | nil,
  },

  generation_state = {
    state = "active" | "terminal_candidate" | "terminal_incomplete"
      | "accepted_history" | "rejected_history" | "unsupported",
    terminal_ref = string | nil,
    rejected_generation_manifest_ref = string | nil,
  },

  stage = {
    state = "active" | "complete" | "suspended" | "unsupported",
    completion_ref = string | nil,
  },

  root = {
    software_state = "unfinished" | "accepted" | "rejected" | "unsupported",
    documentation_state = "disabled" | "incomplete" | "partial" | "complete"
      | "blocked" | "unsupported",
    delivery_state = "unfinished" | "complete" | "unsupported",
  },

  source_refs = string[],
  relevant_object_versions = table[],
  missing_requirements = string[],
  conflicting_refs = string[],
  event_truth_status = "runtime_confirmed",
  content_truth_status = "runtime_confirmed" | "semantic_proposal" | "mixed",
}
```

`unsupported` belongs to the inspection or one of its named reader components,
not to `boundary_candidate.state`. An unavailable reader yields candidate
`none`, an exact component-level `unsupported`, and a named missing
requirement.

The identity projection contains every field except `inspection_id`. Arrays are
normalized, bounded and sorted where their source contract has no meaningful
order. Returned records are detached deep copies.

## 4. Scope Derivation

The inspector applies this order and stops at the highest exact scope:

```text
1. validate subject kind, protocol, identity and current/frozen status
2. bind one exact process contract/context/stage/generation
3. reject cross-generation and conflicting refs
4. derive work-item progress from named completion events
5. derive declared artifact-set completion
6. verify candidate seal when present
7. derive local QA state bound to that exact seal
8. derive one Packet/corpse boundary candidate when supported
9. for lineage subject only, verify stage assessment
10. for lineage subject only, verify software assessment
11. for lineage subject only, verify documentation and root delivery
12. emit missing requirements and preserved truth statuses
```

Missing evidence lowers or makes a scope unsupported. It never becomes success.
Contradictory trusted records return an error instead of a prettier inspection.

## 5. Packet And Corpse Boundary Candidates

### 5.1 Plan

`plan_stage_ready` requires:

```text
exact plan.result.v0
exact Packet-local manifest event
exact terminal event/corpse binding the result
current lineage/generation/stage identity
```

It does not write `stage.state=complete`. The lineage completion reader owns
that later act.

### 5.2 Accepted Build

`software_acceptance_ready` requires:

```text
exact current candidate seal
exact accepted required QA verdict bound to that seal
no conflicting current verdict
```

A living Packet reports `terminalized=false`. After △, the corpse inspection
requires the Packet-local manifest to bind the same seal/verdict refs and reports
`terminalized=true` plus the exact corpse ref. Neither writes
`software_accepted`; only the terminalized form is admissible to lineage.

### 5.3 Rejected Build

`rejected_generation_recovery_ready` requires:

```text
exact current candidate seal
one final rejected QA verdict bound to that seal and QA contract
all rejected required check refs named by that verdict
```

A living Packet reports the recovery candidate with `terminalized=false`.
△ must embed one bounded rejected-generation projection containing the exact
seal/verdict/check evidence. Corpse inspection requires that projection in the
full terminal manifest and reports `terminalized=true`. Trace-tail presence,
residue or proposed repair text alone is insufficient.

## 6. Lineage Scope Derivation

The lineage reader consumes only verified ledger events and content-addressed
Packet/corpse evidence.

```text
stage:
  exact stage contract
  exact terminal candidate/corpse
  stage_completion_evaluated
  stage_completed

software_accepted:
  exact build stage
  exact seal and accepted QA verdict
  software_acceptance_ready corpse
  no newer superseding generation
  root software assessment
  software_accepted ledger event

root_delivery:
  software_accepted
  required documentation complete, or explicit off/optional policy
  exact export receipt when required
  root_delivery_completed ledger event
```

The lineage reader may not manufacture a missing event because all its inputs
would support writing one. Assessment and committed ledger fact remain distinct.

## 7. Manifest Permissions

| Evidence | Packet △ may assemble | Lineage may later assert |
|---|---|---|
| work item | bounded artifact/diagnostic result | nothing larger |
| artifact set | materialization report | nothing larger |
| candidate seal | sealed-candidate report | nothing larger |
| plan result | plan-stage terminal candidate | stage after corpse assessment |
| accepted QA | software-acceptance terminal candidate | software acceptance after corpse assessment |
| final rejected QA verdict | rejected-generation terminal candidate; △ embeds bounded rejection projection | rejected history/recovery decision |
| required docs receipt | no dead Packet mutation | root delivery from lineage |

The existing legacy repository manifest remains authoritative until a separate
promotion record says otherwise.

## 8. Completion And Economics Separation

`inspect_packet`, `inspect_corpse` and intrinsic portions of
`inspect_lineage` must not read:

```text
Packet remaining budget except as historical terminal evidence
lineage budget remaining/exhausted
allow_recovery policy
future generation capacity
documentation affordability
```

Matched states with identical evidence and different wallets produce identical
scope and boundary-candidate fields. Affordability is read only after completion
by the continuation/delivery selector.

## 9. Truth And Failure Law

```text
derivation act                         runtime_confirmed
observed byte/hash/seal/QA mechanics   runtime_confirmed
semantic artifact meaning             preserved proposal/mixed
lineage applicability decision         runtime_confirmed act over preserved inputs
```

| Condition | Result |
|---|---|
| named reader unavailable | typed `unsupported` or missing requirement |
| expected evidence absent/stale | lower honest scope |
| cross-generation QA/seal | rejected evidence, no advancement |
| conflicting current verdicts | loud body/lineage invariant failure |
| malformed trusted record | loud harness/runtime failure |
| substrate says complete | zero authority delta |

Invariant failure is never converted into Packet mortality.

## 10. Permanent Controls

```text
CS01 one complete work item is not root completion
CS02 all current declared work items derive artifact_set only
CS03 stale work-item version cannot satisfy the set
CS04 exact seal advances Packet scope to candidate_sealed
CS05 accepted QA without corpse yields only terminalized=false local candidate
CS06 accepted QA + corpse still cannot make Packet/corpse software_accepted
CS07 verified lineage assessment may derive software_accepted
CS08 required docs pending preserves software_accepted and blocks root_delivery
CS09 exact required docs receipt permits lineage root_delivery
CS10 plan result under software.create completes stage, not root
CS11 same plan result under plan.only may complete root through lineage
CS12 same corpse under funded/exhausted wallet has identical intrinsic scope
CS13 old-generation accepted QA cannot advance current generation
CS14 conflicting trusted verdicts fail loudly
CS15 observer enabled/disabled leaves route, budget, loss and effects identical
CS16 same semantic context under plan.only and software.create retains distinct process-contract identity and root scope
CS17 rejected check evidence without a final verdict is not a terminal candidate
CS18 final rejected verdict yields terminalized=false before △ and true only from the corpse manifest
CS19 rejected evidence older than trace_tail remains available through the full manifest projection
```

Tests must grow real Packet/corpse evidence through current helpers. Synthetic
terminal records are insufficient for CS05-CS13.

## 11. Shadow Integration

Optional observer mode:

```lua
options.completion_scope_observer = "off" | "shadow_v0"
```

In shadow mode:

```text
inspection occurs after a committed body tick
result is deep-copied into instrumentation only
no pressure reader consumes it
no readiness changes
legacy and tree routes remain byte-for-behavior identical
disagreement with legacy manifest is counted, not repaired
```

## 12. Implementation Order

```text
1. pure validation, identity and detached-return helpers
2. Packet work-item/artifact-set projection
3. candidate-seal projection as unsupported until seal writer exists
4. plan Packet/corpse boundary candidate
5. shadow observer and exact ablation
6. accepted/rejected build candidates after seal/QA contracts exist
7. lineage stage/software/root readers
8. grown matched corpus and false-green audit
9. separate authority-promotion decision
```

## 13. Promotion Gates

```text
G0 schemas and subject ceilings are closed
G1 Packet/corpse can never emit lineage scopes
G2 pure repeat and detached-return controls are green
G3 current one-file result is classified no higher than supported evidence
G4 observer ablation is exact
G5 accepted/rejected grown lives bind exact seals and corpses
G6 completion/economics ablation is exact
G7 no invariant failure becomes honest Packet death
```

## 14. Explicit Deferrals

```text
candidate seal implementation
QA command execution and sandbox
`qa-check.v0` record schema and final verdict writer
root manifest authority replacement
automatic recovery routing from missing requirements
persistent lineage resume
parallel/branching stages
semantic completion classifier
documentation renderer/export implementation
```

## 15. Crystall Thesis

```text
A mortal Packet may finish its evidence without accepting the whole software.
Acceptance is a lineage fact composed only after the Packet can no longer edit
the world whose result is being judged.
```
