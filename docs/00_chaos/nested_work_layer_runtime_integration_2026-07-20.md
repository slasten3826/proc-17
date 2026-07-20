# Nested Work Layer Runtime Integration Notes

Status:

```text
chaos
architecture pressure after live plan-to-build experiment
discussion document
no code authority
no router change
```

Date:

```text
2026-07-20
```

Primary sources:

```text
docs/00_chaos/nested_layer_glyphs_notes.md
docs/01_table/yellowprints/nested_layer_glyphs_yellowprint.v0.md
docs/00_chaos/plan_build_carrier_live_software_experiment_2026-07-20.md
docs/02_crystall/blueprints/lineage_mechanics.v0.md
docs/03_manifest/current_state.md
```

Relevant current code:

```text
core/packet.lua
runtime/plan_completion.lua
runtime/work_completion.lua
runtime/completion.lua
runtime/lineage.lua
runtime/lineage_runner.lua
runtime/carrier.lua
runtime/network_ingress.lua
runtime/qualified_pressure.lua
organs/manifest.lua
```

## 1. Trigger

The old nested-layer notes proposed two orthogonal coordinates:

```text
mode  = plan | build
layer = ⋯ | ⊞ | ◈ | ▲
```

The proposal deliberately said not to implement a layer field until an
experiment required it.

The first live paired software experiment supplied that requirement.

Observed:

```text
build-only
  -> real verified artifact
  -> two external QA defects

plan -> build
  -> explicit transported plan.result.v0
  -> real verified artifact
  -> 9/9 external QA green without repair
```

The experiment also exposed a false boundary:

```text
repository artifact complete != software task complete
```

The body currently knows `plan` and `build`, but it does not know whether a
build artifact is waiting for QA, waiting for repair, or ready for root-task
manifestation.

## 2. The Missing Coordinate

The current body already answers:

```text
operator = where the Packet acts in the ProcessLang topology
mode     = why this Packet life is working
```

It does not yet answer:

```text
layer    = what process form the current work has reached
context  = which nested process the glyph describes
scope    = what kind of completion has been proven
```

These coordinates must remain distinct.

Example:

```text
operator = ☱
mode     = build
layer    = ⊞
context  = software_task
reason   = artifact verified, QA evidence absent
```

The same operator may serve different nested layers. The same layer may create
pressure toward different operators. Neither coordinate replaces the tree.

## 3. Correction To The Old Suggested Shape

The old table proposed a possible future field:

```lua
packet.runtime.layer = "⋯" | "⊞" | "◈" | "▲"
```

That shape is now too weak if interpreted as mutable authority.

An arbitrary writer must not be able to do this:

```lua
packet.runtime.layer = "▲"
```

and thereby manufacture completion.

This would repeat the project's recurring defect:

```text
status written
status not guarded
consumer trusts the label
```

The old suggested field remains useful archaeology, but current physics
requires a stronger rule:

```text
mode and context are birth/regime contracts
current layer is derived from Packet evidence
completion is proved by named readers
```

## 4. Preferred V0 Shape: Derived Layer Projection

The first implementation candidate is a pure inspector, conceptually:

```lua
work_layer.inspect(instance, options) -> projection | nil, err
```

Candidate projection:

```lua
{
  protocol_version = "runtime.work_layer_projection.v0",
  mode = "plan" | "build",
  context = "software_task",
  glyph = "⋯" | "⊞" | "◈" | "▲",
  state = "forming" | "checking" | "repairing" | "boundary",
  reason = "artifact_verified_qa_missing",
  source_refs = {...},
  relevant_revisions = {...},
  missing_requirements = {...},
  truth_status = "runtime_confirmed",
}
```

This is a sketch, not a contract.

The important law is:

```text
no independent mutable layer store
no caller-selected glyph
no substrate-selected glyph
no glyph without causal source refs
```

The projection may be copied into an immutable trace observation for audit and
TUI display. The trace copy must not become a second mutable source of truth.
Current truth is re-derived from current Packet evidence.

This repeats the camera lesson:

```text
derive from owned facts
record what was seen
do not let the record replace the facts
```

## 5. Layer Is Not A Router

The implementation must not become:

```lua
if layer == "⊞" then
    next_operator = "☶"
end
```

That would rebuild a fixed pipeline inside a field named `layer`.

Instead:

```text
evidence derives layer projection
layer projection exposes missing requirement
named pressure producer emits a qualified witness
tree router selects among adjacent viable actions
body executes the selected operator
new evidence changes the projection
```

Example:

```text
build ⊞
reason: artifact verified, QA evidence absent
pressure: qa_evidence_need
probable consumer: ☶
```

The witness may make ☶ viable. It does not command ☶ and does not bypass
topology, readiness or capability checks.

## 6. Candidate Plan Projection

The current exact plan life already contains most of the necessary evidence.

Possible interpretation:

| Layer | Packet evidence | Missing requirement | Likely pressure |
|---|---|---|---|
| `plan ⋯` | no exact work structure | semantic formation | observe/encode need |
| `plan ⊞` | work sequence formed | current structural assessment | observation/reconciliation need |
| `plan ◈` | current accepted plan assessment | typed export | plan delivery need |
| `plan ▲` | `plan.result.v0` manifested | stage boundary | death/transition accounting |

The observed plan route was:

```text
▽ -> ☴ -> ☵ -> ☴ -> ☱ -> △
```

It may already be a physical traversal of the nested plan process even though
the body does not yet name the layer projection.

This means nested layers do not necessarily require four substrate calls.
Body transformations, observations and assessments may move the process form
without asking the substrate to narrate every layer.

## 7. Candidate Build Projection

Possible interpretation:

| Layer | Packet evidence | Missing requirement | Likely pressure |
|---|---|---|---|
| `build ⋯` | requested artifact absent or selected action unapplied | bounded artifact effect | encode/choose/effect need |
| `build ⊞` | artifact effect independently verified | accepted QA evidence | QA execution/validation need |
| `build ◈` | QA rejected with concrete failure refs | bounded repair effect | repair formation/selection/effect need |
| `build ▲` | required QA accepted or life cannot lawfully continue | root manifest or paid continuation | manifest/cycle/death need |

Unlike a monotonic maturity enum, build work may recur:

```text
build ⋯ -> build ⊞ -> build ◈ -> build ⊞ -> ... -> build ▲
```

Therefore the glyph is better understood as the current process gesture or
derived form, not as an integer level that only increments.

The old meaning of `build ▲` was "bounded repeat until manifest or death".
That remains compatible:

```text
accepted QA     -> manifest boundary
repair possible -> paid continuation
budget/loss end -> death with residue
```

## 8. Current False-Green Baseline

The build-only live route was:

```text
▽ -> ☴ -> ☵ -> ☱ -> ☶ -> ☱ -> △
```

Current authority says:

```text
repository work completion exists
remaining repository work = 0
repository.result.v0 may manifest
Packet dies complete
```

The proposed shadow layer inspector should say at the pre-manifest boundary:

```text
mode: build
layer: ⊞
reason: artifact_verified_qa_missing
root_task_complete: false
```

This disagreement is not an unexpected regression. It is the initial red
control that justifies the new layer:

```text
legacy/current completion = artifact complete
nested process completion = QA still missing
```

The current route must remain authoritative while this is observed in shadow.

## 9. Three Completion Scopes

The live experiment requires at least three different facts:

```text
artifact_complete
stage_complete
root_task_complete
```

### Artifact Complete

Example:

```text
notes.py exists
its bytes and hash match the selected action
the independent provider read-back was accepted
```

This is already implemented by `runtime.work_completion.v0`.

### Stage Complete

Examples:

```text
plan.result.v0 is ready for transport
one build artifact is ready for QA
a repair attempt has produced new evidence
```

Stage completion may legally terminate one Packet without completing the root
task.

### Root Task Complete

For the current software-task experiment:

```text
required artifact evidence accepted
required QA evidence accepted
no required repair remains
root completion contract satisfied
```

Only this fact may support the final user-facing task manifest.

## 10. Current Lineage Gap

Current lineage state owns one fixed pair:

```lua
lineage.work_mode
lineage.completion_contract_id
```

Current `plan.v0` completion behaves as:

```text
exact plan corpse
  -> task_state = complete
  -> lineage complete
```

Current carriers support only:

```text
carrier_class = recovery
unfinished recoverable terminal
```

Therefore current lineage cannot express:

```text
plan stage complete
root task incomplete
continue deliberately in build mode
```

The temporary paired experiment bypassed this gap with a host harness.

## 11. Candidate Lineage Extension

The same lineage is the preferred first hypothesis because:

```text
the root user task is unchanged
cumulative economics must not reset
the build Packet is a descendant of the plan Packet
the plan corpse is part of task ancestry
```

Candidate concepts:

```text
lineage.root_task
lineage.current_stage
lineage.stage_ledger
lineage.process_contract_id
```

Possible stage record:

```lua
{
  stage_id = "stage:plan:1",
  mode = "plan",
  context = "software_task",
  completion_contract_id = "plan.v0",
  expected_result = "plan.result.v0",
  status = "active",
}
```

On exact plan completion, the body would append immutable lineage events:

```text
stage_completed
root_completion_evaluated: unfinished
stage_transition_selected: plan -> build
transition_carrier_built
```

The lineage must not silently mutate `work_mode`.

## 12. Transition Carrier

Do not overload the current recovery carrier.

Recovery means:

```text
the previous Packet failed to finish its current work
continue from bounded residue
```

Plan-to-build means:

```text
the previous Packet completed its stage
begin a different typed stage of the same root task
```

These are different causal classes.

Candidate new class:

```text
carrier_class = stage_transition
transition_contract_id = plan_to_build.v0
```

Required properties:

```text
source plan corpse verified
source plan manifest verified
source and target stage named
target generation named
payload bounded and hashed
lineage budget charged
no repository grant or provider handle transported
no live Packet identity transported
plan content remains semantic_proposal
applicability to build remains inherited proposal
```

The target path remains canonical:

```text
△ -> corpse -> carrier -> NETWORK@▽ -> fresh Packet
```

## 13. Truth Status Across The Boundary

The plan carrier contains several different truths:

```text
plan Packet died                     runtime_confirmed
plan manifest was assembled          runtime_confirmed
plan content                         semantic_proposal
plan applies to this build Packet    inherited applicability proposal
build effects                        absent until build runtime
```

Transport must preserve these distinctions.

In particular:

```text
manifestation does not canonize semantic plan content
inheritance does not authorize repository effects
same lineage does not mean same Packet identity
```

## 14. QA Is Build `⊞`, Not A Chat Role

The external 9-case QA battery showed the missing layer, but its evidence is not
inside the body.

Future QA must be a bounded runtime capability, not another substrate opinion.

Conceptual chain:

```text
declared QA requirement
  -> capability-authorized execution
  -> bounded stdout/stderr/exit/timeout evidence
  -> ☶ validation
  -> ☱ reconciliation
  -> accepted or rejected QA state
```

The substrate may propose tests or interpret a failure for repair. It may not:

```text
mint execution authority
declare its own code tested
promote prose confidence to QA evidence
hide a non-zero exit behind a summary
```

The first QA hand requires its own threat model. It must not be smuggled in as
an arbitrary shell command merely to complete this layer quickly.

## 15. Repair Is Build `◈`

Rejected QA must produce concrete failure refs:

```text
test identity
exit status
bounded output digest
artifact/version under test
runtime cost
```

Repair pressure may then expose those refs to the substrate through a bounded
semantic observation. The resulting proposal must still pass normal ENCODE,
CHOOSE, capability and effect boundaries.

Current create-no-replace authority cannot repair an existing file.

Therefore `build ◈` also requires a separately designed safe mutation:

```text
exact replace
or exact patch
with expected old digest
with independent post-write read-back
```

This is another capability campaign, not a relaxation of the first hand.

## 16. Shadow-First Migration

Do not gate current manifests immediately.

The safest migration repeats the successful Tree-authority transition:

```text
1. derive layer projection in shadow
2. record immutable observations
3. prove observer ablation
4. compare current completion against projected scope
5. grow false-green and false-red corpus
6. only then grant pressure authority
```

Initial shadow observations should include:

```text
existing plan lives
existing build repository lives
build-only live defect case
plan-to-build green case
rejected validation lives
budget death before QA
```

The current hand remains authoritative until the layer corpus can distinguish
artifact completion from root completion without breaking mortality,
capability safety or lineage accounting.

## 17. Likely Table Split

This chaos document probably produces three table documents, not one.

### Table A: Nested Work Layer Derivation

```text
mode/context inputs
layer evidence matrix
freshness and revision law
named readers
pressure producers
shadow observations
```

### Table B: Completion Scope

```text
artifact_complete
stage_complete
root_task_complete
manifest permissions
false-green and false-red cases
```

### Table C: Stage Transition Lineage

```text
stage ledger
plan-to-build transition
transition carrier
NETWORK ingress
truth statuses
cumulative economics
```

QA and repair hands should remain later, separate capability tables after the
process physics is stable.

## 18. Candidate Red Tests

### Layer Authority

```text
caller supplies glyph ▲ -> ignored/rejected
substrate says "layer complete" -> semantic only
same Packet facts -> same derived layer
relevant evidence change -> layer projection changes
irrelevant revision change -> projection remains equivalent
stale evidence -> cannot preserve advanced projection
shadow layer observer disabled -> current physics identical
```

### Completion Scope

```text
verified artifact without QA -> artifact complete, root incomplete
accepted QA for wrong artifact version -> root incomplete
accepted QA for current artifact -> root completion candidate
rejected QA -> repair pressure, no final manifest
budget death while QA missing -> residue names missing QA
```

### Stage Transition

```text
exact plan stage -> typed transition carrier
plan manifest tampered -> no carrier
plan semantic content altered -> hash mismatch
repository authority inserted into carrier -> reject
transition unpaid by lineage -> no birth
build child receives fresh Packet identity and build mode
parent plan state does not cross the boundary
```

## 19. Open Questions

### Q1. What selects the process contract?

Possibilities:

```text
operator/CLI explicitly requests software.plan_build.v0
task classifier selects a declared contract
all build tasks always require plan first
```

The substrate must not silently grant itself a larger process contract.

### Q2. Is plan-to-build always automatic?

Some tasks need only a plan. Some need direct build. Some need both.

The transition must follow an explicit root-task contract, not a universal
assumption that every plan must produce code.

### Q3. Does QA happen in the same build Packet?

Possibilities:

```text
same Packet continues from artifact effect into QA
artifact stage manifests and a fresh build/QA Packet is born
same Packet when budget permits, new generation after death
```

Current packet physics permits cycles inside one life and lineage continuation
after death. The correct boundary needs evidence, not aesthetic preference.

### Q4. Is `▲` a state, gesture or boundary?

The old matrix gives context-sensitive meanings:

```text
plan ▲  = exported plan
build ▲ = bounded repeat until manifest/death
```

The v0 inspector must avoid pretending these are one monotonic maturity enum.

### Q5. Who owns the mode transition?

Candidates:

```text
lineage_runner as body mechanics
future CLI as explicit process requester
lineage runner executes a CLI-selected process contract
```

The current strongest candidate is:

```text
CLI selects a bounded process contract
lineage runner owns and audits its execution
```

This keeps the interface from becoming the body while avoiding universal
automatic build continuation.

### Q6. What is the first lawful QA capability?

Arbitrary shell is too broad.

Candidates require a separate threat analysis:

```text
fixed interpreter compile check
operator-declared exact argv allowlist
repository-owned test manifest with digest pinning
sandboxed test provider with timeout/output/network bounds
```

### Q7. Does the plan need four substrate calls?

Current evidence says no.

One substrate response passed through body-owned structure formation,
observation, assessment and manifestation. More substrate calls should appear
only when a named semantic pressure requires them.

## 20. What Must Not Change Yet

Do not yet change:

```text
current router authority
current repository manifest gate
current plan completion contract
current recovery carrier
current lineage terminal behavior
current capability provider
```

The first code, after tables and crystall, should be observation-only.

## 21. Proposed Order

```text
1. discuss and amend this chaos boundary
2. build three table documents
3. crystallize only the shadow layer inspector
4. implement and test observer-only projection
5. grow a completion-scope corpus
6. crystallize stage transition and carrier
7. implement automatic plan-to-build under explicit opt-in contract
8. design QA capability separately
9. gate root completion on accepted QA
10. add repair capability and bounded recurrence
```

This order deliberately separates:

```text
seeing the missing layer
transporting a completed stage
touching the world through QA and repair
```

## 22. Current Thesis

The nested glyphs are not decorative metadata and not a second router.

They are a body-derived projection of process form:

```text
operator says where
mode says why
layer says what form
context says of what
completion scope says how much is actually finished
```

The live plan-to-build experiment is the first evidence strong enough to make
this projection necessary.

The immediate task is not to implement all four glyphs. It is to prove that the
body can derive the correct glyph and completion scope without being told the
answer by the caller, substrate or legacy manifest path.
