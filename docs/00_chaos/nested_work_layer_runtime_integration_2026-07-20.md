# Nested Work Layer Runtime Integration Notes

Status:

```text
chaos
architecture pressure after live plan-to-build experiment
discussion document
no code authority
no router change
amended after the greenfield-generation boundary correction
```

Date:

```text
2026-07-20
```

## 0. Frame Correction: Generation, Not In-Place Repair

The first version of this note accidentally imported the conventional coding
agent model:

```text
generate -> test -> patch the same repository -> test again
```

That is not the primary proc-17 product contract.

proc-17 first creates new software. A materialized build candidate is a whole
form, not a mutable patient. Once the candidate is sealed for QA, rejection
does not authorize a patch, overwrite or repair inside that repository.

The corrected process is:

```text
create generation N in a fresh repository
  -> seal candidate N
  -> run bounded QA against candidate N
  -> accepted: manifest the root result
  -> rejected: crystallize the failure, kill candidate N
               build a typed recovery carrier
               birth generation N+1 in another fresh repository
               create the whole candidate again under inherited constraints
```

Canonical candidate law proposed by this amendment:

```text
A build candidate is immutable after materialization.
Rejected form is never repaired in place.
Repair changes the conditions of the next birth.
Every new build generation materializes under a fresh repository identity.
```

During materialization, the body may create each declared absent path once.
After the candidate is sealed, its source tree is read-only evidence. This
makes the existing create-no-replace hand a candidate canonical boundary, not
merely an incomplete precursor to an overwrite hand.

For legacy work, the same law produces reconstruction rather than mutation:

```text
legacy repository: read-only source of observed behavior and constraints
fresh repository: generation-scoped output authority
result: a new implementation, compared against the observed contract
```

The claim is deliberately narrower than "no technical debt can exist".
Regeneration prevents patch-history debt from accumulating inside a candidate;
plan quality, architecture, QA coverage and inherited constraints still decide
whether the newly created form is good.

All earlier wording in this document about exact replace, exact patch or
same-candidate repair is superseded by this section. The corrected sections
below retain the original question but no longer grant mutation authority.

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
build candidate is still forming, waiting for QA, rejected and waiting for
failure crystallization, or accepted for root-task manifestation.

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
  state = "forming" | "checking" | "crystallizing_failure" | "boundary",
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
| `build ⋯` | fresh generation exists; declared candidate form is absent or incomplete | bounded create-only materialization | encode/choose/effect need |
| `build ⊞` | whole candidate is sealed and independently readable | accepted QA evidence | QA execution/validation need |
| `build ◈` | QA rejected with concrete failure refs | typed failure crystal and terminal residue | encode/crystallize/death need |
| `build ▲` | required QA accepted, or rejected generation has produced a lawful recovery boundary | final manifest or paid rebirth | manifest/death/lineage need |

Unlike a mutable repair loop, recurrence crosses a death and birth boundary:

```text
generation N
  build ⋯ -> build ⊞
    accepted -> build ▲ -> final manifest
    rejected -> build ◈ -> △ -> corpse -> recovery carrier

generation N+1, fresh Packet and fresh repository identity
  NETWORK@▽ -> build ⋯ -> build ⊞ -> ...
```

Therefore the glyph is better understood as the current process gesture or
derived form, not as an integer level and not as permission to mutate an older
form.

The old meaning of `build ▲` was "bounded repeat until manifest or death".
That remains compatible:

```text
accepted QA     -> manifest boundary
rejected QA     -> failure crystal, death and possibly paid rebirth
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
one whole build candidate is sealed for QA
a rejected candidate has produced a typed failure crystal
```

Stage completion may legally terminate one Packet without completing the root
task.

### Root Task Complete

For the current software-task experiment:

```text
required artifact evidence accepted
required QA evidence accepted
no rejected generation remains active
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
lineage.current_generation
lineage.stage_ledger
lineage.generation_ledger
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

It must also distinguish the identity of every materialized generation:

```text
generation id
Packet id
fresh repository identity/root
candidate digest or sealed artifact set
QA verdict and evidence refs
terminal corpse and recovery carrier, if rejected
```

Lineage economics remain cumulative. Rebirth must not reset the price already
paid by rejected ancestors.

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

The current recovery carrier is the correct causal family for a rejected build
generation, because that generation did not finish the root task. It may need a
typed build-generation recovery contract, but it must not be confused with the
successful plan-to-build stage-transition carrier.

No carrier may transport a writable repository identity, provider handle or
live candidate tree. A descendant receives:

```text
original root-task contract
accepted plan carrier, when present
bounded failure crystal and concrete QA refs
cumulative lineage economics
fresh destination repository identity and fresh capabilities
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

The substrate may propose tests or interpret a failure into constraints for a
later generation. It may not:

```text
mint execution authority
declare its own code tested
promote prose confidence to QA evidence
hide a non-zero exit behind a summary
mutate the sealed candidate under test
```

The first QA hand requires its own threat model. It must not be smuggled in as
an arbitrary shell command merely to complete this layer quickly.

## 15. Failure Crystallization Is Build `◈`

Rejected QA must produce concrete failure refs:

```text
test identity
exit status
bounded output digest
artifact/version under test
runtime cost
```

Failure-crystallization pressure may expose those refs to the substrate through
a bounded semantic observation. The resulting crystal describes what the next
generation must account for; it does not describe an edit to the rejected
repository.

Candidate rejection must therefore execute this boundary:

```text
freeze candidate source tree
record exact QA evidence and candidate digest
crystallize concrete failure constraints
manifest terminal residue/corpse
optionally build a paid recovery carrier
birth a fresh Packet with a fresh empty destination repository
materialize the whole candidate again
```

The following earlier proposal is explicitly rejected for the primary proc-17
product path:

```text
exact replace
or exact patch
inside the failed candidate repository
```

No overwrite or patch capability is required for this loop. The future
capability campaign is instead:

```text
multi-file create-once materialization in a fresh generation root
candidate sealing and read-only QA
generation-scoped repository grants
fresh-root allocation and eventual cleanup/compost
```

Cleanup is lineage/session lifecycle authority, not a coding hand. Failed
generation repositories may remain temporarily as auditable corpses, but they
must not become active mutable ancestors.

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
candidate_sealed
stage_complete
root_task_complete
manifest permissions
candidate immutability
false-green and false-red cases
```

### Table C: Stage Transition Lineage

```text
stage ledger
generation ledger
plan-to-build transition
transition carrier
rejected-generation recovery
fresh repository identity
NETWORK ingress
truth statuses
cumulative economics
```

QA and generation-lifecycle capabilities should remain later, separate tables
after the process physics is stable. There is no planned in-place repair hand
on the primary path.

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
rejected QA -> failure-crystallization pressure, no final manifest
rejected QA -> sealed candidate bytes remain unchanged
attempted overwrite after sealing -> denied without touching the candidate
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
rejected build corpse -> typed recovery carrier
next build child receives a fresh repository identity
rejected candidate files do not cross into the new destination root
lineage budget does cross and remains cumulative
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

### Q3. Does QA happen in the materializing Packet or a QA child?

Possibilities:

```text
same Packet seals its candidate and continues into read-only QA
artifact stage manifests and a fresh QA Packet observes the sealed candidate
```

This boundary still needs evidence, but both forms obey the same stronger law:

```text
QA receives no candidate mutation authority
rejection cannot route back into the sealed repository
any new materialization requires death/recovery and a fresh generation root
```

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

Also do not widen the current create-no-replace hand into overwrite or patch.
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
8. design read-only QA capability separately
9. gate root completion on accepted QA
10. add rejected-generation crystallization, fresh-root recovery and bounded recurrence
```

This order deliberately separates:

```text
seeing the missing layer
transporting a completed stage
testing an immutable candidate
replacing rejected form through paid rebirth
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

The product boundary is equally important:

```text
proc-17 does not improve a candidate by accumulating edits
proc-17 improves a lineage by generating successive whole candidates
```

For greenfield work, every candidate begins empty. For legacy work, the old
repository is observed read-only and a replacement is born elsewhere. The
evolutionary unit is the complete generated form; QA selects forms, and
failure changes the inherited conditions of the next birth.

The immediate task is not to implement all four glyphs. It is to prove that the
body can derive the correct glyph and completion scope without being told the
answer by the caller, substrate or legacy manifest path.
