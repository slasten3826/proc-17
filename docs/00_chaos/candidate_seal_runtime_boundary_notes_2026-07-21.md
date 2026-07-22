# Candidate Seal Runtime Boundary Notes - 2026-07-21

Status:

```text
chaos / first draft
scope: implementation step 8.4 only
discussion owner: machinist + Codex
code authority granted by this document: no
TABLE amendment authority granted by this document: no
CRYSTALL amendment authority granted by this document: no
router promotion: forbidden
QA execution authority: forbidden
```

Primary prior contracts:

```text
docs/01_table/yellowprints/completion_scope_candidate_seal_yellowprint.v0.md
docs/02_crystall/blueprints/candidate_seal.v0.md
docs/02_crystall/blueprints/completion_scope.v0.md
docs/02_crystall/blueprints/work_layer_projection.v0.md
docs/02_crystall/blueprints/capability_safe_repository_hands.v0.md
docs/02_crystall/blueprints/stage_transition_generation_recovery.v0.md
```

Current implementation inputs:

```text
runtime/artifact_set.lua
runtime/completion_scope.lua
runtime/work_layer.lua
runtime/repository_capability.lua
runtime/repository_provider.lua
runtime/repository_effect.lua
runtime/work_completion.lua
runtime/body.lua
runtime/tension_runner.lua
native/proc17_repository_fs.c
```

## 0. Trigger

Implementation steps 8.1 through 8.3 now provide:

```text
strict artifact-set validation and current completion inspection
Packet/corpse-local completion-scope projection
derived plan/build work-layer projection
massless work-layer shadow observation
```

The honest current build boundary is:

```text
exact artifact set complete
candidate seal absent
work layer = build ⋯
reason = artifact_set_complete_seal_missing
```

The next step is not QA. The next step is to make one complete candidate safe
to hand to future QA.

## 1. Physical Claim

A candidate seal is not merely a digest and not merely a status field.

```text
candidate seal
  = exact declared artifact set
  + exact final observed repository inventory
  + closed source-write authority
  + immutable body-owned record joining those facts
```

The required causal order is:

```text
prove exact artifact-set readiness
close future proc-17 source-write authority
invalidate old unconsumed write leases
observe the final repository tree
commit closure against that exact observation
append one immutable candidate-seal event
```

Inventory before authority closure is invalid because a write may occur between
observation and seal. Authority closure without an exact inventory is invalid
because the body would know that writing stopped but not what was frozen.

The intended work-layer consequence is:

```text
build ⋯  exact candidate still forming or unsealed
build ⊞  exact candidate sealed and awaiting QA
```

Sealing does not prove software quality. Artifact meaning remains
`semantic_proposal` or `mixed`.

## 2. Scope Of Physical Immutability

The seal makes mutation physically unavailable to the proc-17 body through its
capability system.

It does not make the directory globally immutable to the operating system:

```text
another host process may still mutate the tree
the user may still mutate the tree
the filesystem may fail or be replaced
proc-17 does not own a filesystem snapshot primitive yet
```

Therefore the exact claim is:

```text
After seal, no current or future proc-17 source-write capability may mutate the
sealed root. A future QA reader must revalidate root identity and candidate
inventory before treating the seal as current evidence.
```

This is not a weakness to hide. It is the current host trust boundary.

Persistent recovery of an in-memory `seal_pending` transaction after process
crash remains explicitly deferred by the existing crystall.

## 3. Existing Machinery

The first repository hand already supplies useful parts:

```text
opaque native repository handle
exact root fingerprint
private grant registry state
single-use effect leases
create-no-replace materialization
independent bounded read-back
native no-follow path handling
root revalidation
typed quarantine on ambiguous effects
body-owned repository events
```

The following pieces do not yet exist:

```text
body-derived artifact-set declaration
generation/root candidate lifecycle
seal lease and closure receipt
production recursive inventory operation
candidate-seal verifier and body writer
post-seal denial enforcement
completion-scope candidate-seal reader
```

The seal must extend the existing trust boundary. It must not introduce a shell
helper, a public provider handle, a caller-owned grant or an LLM-selected
authority path.

## 4. Gap A: Who Declares The Artifact Set

The TABLE law says:

```text
artifact-set declaration writer = stage/root process contract + field formation
```

The current implementation validates and inspects a supplied contract:

```lua
artifact_set.validate(contract)
artifact_set.inspect(instance, contract)
```

Tests and shadow callers currently construct that contract outside the body.
Identity and current work completion are checked, but the caller still chooses
which set to present.

That is sufficient for a pure shadow inspection. It is insufficient for an
irreversible seal transaction.

The body must be able to derive the candidate declaration from current Packet
evidence without allowing the caller to select a convenient subset.

Candidate direction:

```lua
artifact_set.derive(instance, process_view)
  -> exact detached repository.artifact_set_contract.v0 | nil, reason
```

The derivation should bind:

```text
Packet, lineage, generation, stage and repository identities
the exact current field formation
selected/live repository work-unit ids and versions
relative paths and expected regular-file kinds
formation and choice provenance
the process-contract/stage ref when that reader exists
preserved semantic content status
```

The derivation must reject:

```text
ambiguous current formations
duplicate paths or work identities
suppressed alternatives presented as required artifacts
foreign-generation units
repository units without exact formation provenance
caller attempts to add, remove or replace one artifact
```

Open decision:

```text
Should the declaration be a pure deterministic view re-derived when needed, or
should the body append one dedicated declaration event before materialization?
```

The current preference is a pure derived contract consumed by seal preparation.
It avoids a second mutable storage surface. The seal event would preserve the
exact normalized declaration and its refs. TABLE must still decide whether a
separate declaration event is needed for temporal ordering or corpus export.

## 5. Gap B: Generation Authority And Sealed Root Finality

The current capability design intentionally allows one lineage grant to
re-resolve for a later generation before any seal exists:

```text
G5: same lineage, next generation -> grant re-resolves
```

That compatibility law becomes dangerous after a candidate is sealed. If a
later generation re-resolves the same grant against the same root, it can
mutate the ancestor candidate even if the old generation lifecycle says
`sealed`.

The stage/recovery law already supplies the missing invariant:

```text
one build generation -> one repository id/root fingerprint
rejected generation -> fresh Packet and fresh repository identity
```

Proposed root-finality law:

```text
Once any candidate lifecycle reaches sealed or quarantined for a root
fingerprint, that root can never again back proc-17 source-write authority for
any generation. A descendant must receive a different repository id and root
fingerprint.
```

This means the private model likely needs two related indices:

```text
exact lifecycle key:
  session + lineage + generation + repository + root fingerprint

terminal root lock:
  root fingerprint -> sealed | quarantined
```

The exact lifecycle explains which generation was sealed. The terminal root
lock prevents another generation or another newly minted grant from reopening
the same physical candidate.

The named materialization grant remains evidence in the closure receipt, but
the closure must remove all proc-17 source-write authority targeting the root,
not only one convenient grant projection.

Questions for TABLE:

```text
May several active grants target one unsealed root before seal?
Must begin-seal reject ambiguity or close every exact-root grant atomically?
Does G5 remain legal only while the root has never entered seal_pending?
When is a generation/root lifecycle first created: mint, resolve or birth?
```

## 6. Candidate Lifecycle

The intended private state remains:

```text
active -> seal_pending -> sealed
                      -> quarantined
seal_pending -> active only after exact no-effect proof
```

Meaning:

```text
active
  source-write actions may still be reviewed and dispatched

seal_pending
  no new action, grant or old lease may reach the provider
  final inventory is being resolved

sealed
  exact inventory and closure receipt agree
  source-write authority is terminally absent

quarantined
  the body cannot prove whether authority/inventory remained coherent
  source-write authority is terminally absent
```

`active` after an exact no-effect abort does not claim that the candidate can
be repaired. It only says that registry authority is not ambiguous. Current
artifact evidence may still be stale or blocked and may force Packet death.

## 7. Lease And Dispatch Meaning

The existing effect lease is single-use but has no candidate-lifecycle owner.
Step 8.4 must define two different things precisely:

```text
unconsumed old lease
  issued before seal_pending but not yet used
  invalidated by lifecycle revision

active provider dispatch
  trusted provider call currently executing
  begin-seal must not overlap it
```

Lua execution is synchronous today, so a normal body tick cannot run inventory
concurrently with a repository effect. The private contract should still name
the distinction so a future asynchronous provider cannot silently violate it.

The registry must not infer safety merely from `action_dispatches[action_id]`.
That map records consumed authority, not whether a provider call is in flight.

## 8. Proposed Operator Choreography

The current repository hand already follows a useful body pattern:

```text
☱ reviews one exact action
☶ executes one exact world effect and validates its receipt
☱ records current work completion
```

Candidate hypothesis for seal:

```text
☱ prepares/reviews one exact candidate-seal request
☶ begins seal_pending, inventories, commits closure and appends candidate_seal
☱ observes the committed seal and derives candidate_sealed / build ⊞
```

The seal event should be appended in the same ☶ operation that commits the
closure. Deferring the event to a later ☱ tick creates a dangerous interval:

```text
repository authority already closed
Packet does not yet contain the body-owned seal fact
```

If closure succeeds and event append fails, the harness/runtime must fail
loudly while the lifecycle remains sealed or quarantined. It must never reopen
the repository to make the Packet trace look coherent.

This operator choreography is still a Chaos hypothesis. No pressure reader or
router route is authorized yet. Direct service calls and shadow observations
must prove the mechanics first.

## 9. Native Inventory Boundary

The current production native provider has exact operations for:

```text
open repository
revalidate root
create one absent regular file
read one exact path
close handle
```

It does not expose a production inventory operation. Test-only C code contains
directory traversal patterns, but those are not a production proof.

The inventory operation needs its own ABI and hostile tests. Minimum laws:

```text
descriptor-relative traversal only
no symlink following at any component
root identity checked before and after the operation
hard path, depth, entry-count and total-byte bounds
deterministic canonical order independent of readdir order
regular files read through bounded descriptors
file identity/content stability checked around each read
special files reported but never opened for content
unexpected files and directories remain visible
no shell, helper process or weak Lua filesystem fallback
```

The expected tree is not only the declared files. Required parent directories
must be derived from declared relative paths. TABLE must decide whether any
extra empty directory is rejected; the current preference is exact-tree
semantics for a fresh generation root:

```text
allowed regular files = exactly declared artifact paths
allowed directories   = root plus exact ancestors of declared paths
everything else       = inventory mismatch
```

Open hashing decision:

```text
native code computes file hashes directly
or
native code returns bounded captured bytes to the trusted Lua adapter, which
computes hashes with core.digest and removes raw content from the public receipt
```

The second approach avoids introducing a second SHA-256 implementation but
needs an explicit aggregate byte ceiling. Neither approach is selected by this
Chaos note.

Because ordinary filesystems do not provide a free recursive snapshot, the
provider may need a bounded double observation:

```text
enumerate and identify entries
read exact regular files
re-enumerate/revalidate identities and metadata
reject or quarantine on any drift
```

This detects ordinary races. It does not claim global immunity from a hostile
external process after the operation returns. Future QA revalidation remains
mandatory.

## 10. Transaction Sketch

Proposed causal skeleton:

```text
1. artifact_set.derive produces an exact body-derived declaration
2. artifact_set.inspect proves every declared current version complete
3. ☱ emits an instrumentation-only exact seal review/request
4. registry verifies one active exact lifecycle and no active provider dispatch
5. registry enters seal_pending and increments lifecycle/root revision
6. every preexisting effect lease becomes unusable
7. provider inventories the exact root under hard bounds
8. candidate_seal verifier compares declaration, completions, verifications,
   expected ancestor directories, observed bytes and root identity
9. registry commits sealed against the inventory digest
10. ☶ dedicated body writer appends candidate_seal
11. completion_scope re-derives candidate_sealed
12. work_layer shadow re-derives build ⊞
```

No substrate call is required for steps 2 through 12.

## 11. Failure Separation

Task/readiness outcomes:

```text
artifact set incomplete
artifact version stale
declared path missing
undeclared extra path observed
inventory differs from declaration without authority ambiguity
```

These do not become successful seals. Exact no-effect cases may return the
lifecycle to active, while higher body logic decides whether useful work is
still possible.

Capability exclusions:

```text
no exact materialization authority
ambiguous matching grants
active provider dispatch
old lease after seal_pending
new grant/resolve against sealed root
```

World/authority ambiguity:

```text
root replaced during inventory
entry changes during inventory
provider cannot prove whether closure occurred
provider returns contradictory identity
```

These quarantine source-write authority.

Harness/runtime invariants:

```text
malformed trusted provider receipt
closure receipt contradicts private lifecycle
body event append fails after closure
private lifecycle and public projection diverge
```

These fail loudly. They are not honest Packet mortality.

## 12. Truth Law

```text
artifact semantic sufficiency          semantic_proposal | mixed
body derivation of declaration shape   runtime_confirmed act
work-completion evidence                runtime_confirmed
observed paths, bytes and identities    runtime_confirmed
lifecycle transition                    runtime_confirmed
candidate-seal append                    runtime_confirmed
future QA judgment                       not present in step 8.4
```

The seal must preserve both classes. A runtime-confirmed digest must not upgrade
the meaning of its contents to runtime-confirmed software correctness.

## 13. Writer And Reader Chain

| Record or view | Writer | First named reader |
|---|---|---|
| derived artifact declaration | body derivation over process/field evidence | artifact-set inspector and seal planner |
| seal review/request | ☱ exact review path | ☶ seal effect |
| inventory receipt | trusted native provider plus strict Lua adapter | candidate-seal verifier |
| closure receipt | private capability registry | candidate-seal verifier/body writer |
| candidate seal | dedicated ☶ body writer | completion-scope inspector |
| candidate-sealed scope | pure completion-scope inspector | work-layer inspector |
| build `⊞` projection | pure work-layer inspector | shadow instrumentation; future QA pressure reader |

No row names the substrate as an authority writer.

## 14. Falsifiers Before Promotion

Artifact declaration:

```text
caller removes one planned artifact -> cannot seal
caller adds a foreign artifact -> cannot seal
suppressed alternative enters declaration -> cannot seal
stale work version -> cannot seal
```

Lifecycle:

```text
old lease after seal_pending -> zero provider calls
new action after seal_pending -> zero provider calls
new grant against sealed root -> denied
same grant re-resolved by generation N+1 against sealed root -> denied
fresh generation with different root fingerprint -> not denied by ancestor seal
returned lifecycle projection mutation -> zero private-state delta
```

Inventory:

```text
undeclared file -> reject
undeclared directory -> reject under exact-tree policy
symlink at any depth -> reject without following
fifo/socket/device -> reject without reading
file growth/replacement during read -> reject or quarantine
root replacement during inventory -> quarantine
entry/path/byte bound exceeded -> typed bounded failure
malformed native receipt -> loud harness failure
```

Commit:

```text
exact closure creates one immutable seal
repeat exact seal is idempotent and creates no second transition
closure success plus event append failure never reopens writes
seal id presented as capability -> no authority
returned seal mutation -> no trace/private-state delta
```

Isolation:

```text
seal service disabled/enabled in observation-only harness -> same route/loss
substrate says candidate is sealed -> zero authority delta
documentation profile changes -> zero seal identity delta
```

## 15. Proposed Step 8.4 Decomposition

```text
8.4.0  resolve this Chaos note into TABLE/CRYSTALL amendments
8.4.1  body-derived artifact-set declaration and provenance controls
8.4.2  private generation/root lifecycle and terminal root lock
8.4.3  seal_pending transition plus old-lease/new-grant denial battery
8.4.4  native bounded inventory ABI and hostile fixtures
8.4.5  pure candidate-seal prepare/verification
8.4.6  closure receipt plus dedicated body event writer
8.4.7  post-seal denial, idempotence and loud-failure battery
8.4.8  completion-scope/work-layer shadow consumption
```

Each implementation step requires red tests before code. Steps 8.4.2 through
8.4.7 use the same paranoid standard as the first repository hand.

## 16. Explicit Non-Goals

```text
QA command execution
QA check/verdict schemas
QA scratch filesystem
router promotion from work-layer pressure
same-candidate repair
replace/delete/rename hands
fresh repository allocator implementation
lineage stage transition implementation
persistent crash recovery
global OS immutability
CLI/TUI rendering
documentation export
```

The fresh repository allocator is not implemented here, but step 8.4 must make
reuse of a sealed root impossible so the later allocator cannot inherit an
unsafe compatibility path.

## 17. Questions That TABLE Must Answer

```text
Q1  Is artifact-set declaration pure and re-derived, or a dedicated body event?
Q2  What exact process/stage evidence is required before declaration?
Q3  Does sealing close every grant for one root or reject multiple grants?
Q4  When is the generation/root lifecycle born?
Q5  What is the exact active-dispatch counter contract in synchronous v0?
Q6  Are extra empty directories illegal under exact-tree inventory?
Q7  Does native inventory return hashes or bounded captured bytes?
Q8  Which failures permit exact abort to active, and which quarantine?
Q9  Is ☱ review -> ☶ commit -> ☱ observation the canonical organ path?
Q10 How is an exact repeat distinguished from a second seal attempt?
Q11 What happens to the living Packet after a seal transaction quarantines its root?
Q12 How long does a terminal root lock live, and how is safe identity reuse handled?
```

## 18. External Review Disposition - 2026-07-22

An external cold review confirmed the three implementation observations that
motivated this note:

```text
G5 currently permits a later generation of the same lineage to re-resolve the
same grant and root

action_dispatches records consumed authority, not an active provider call

the production native ABI has no recursive repository inventory operation
```

The review also supplied proposed answers to Q1, Q3, Q4, Q6, Q7, Q9 and Q10,
and found the two additional questions now listed as Q11 and Q12. This section
records the current disposition. It is still Chaos evidence, not TABLE
authority.

### 18.1 Accepted Directions

```text
Q1  The artifact-set declaration is a pure deterministic derivation. The seal
    event preserves the normalized declaration and its provenance. There is no
    independent declaration event or mutable declaration store.

Q3  More than one active exact-root grant is seal ambiguity. Begin-seal rejects
    it; it does not silently revoke or close authority that the request did not
    name. The terminal root lock separately prevents any future grant from
    reopening the root after seal_pending begins.

Q6  v0 uses exact-tree inventory. Allowed directories are only the root and the
    ancestors required by declared artifact paths. Host contamination is
    visible and makes the candidate not sealable; it is not silently ignored.

Q7  The native provider returns bounded captured bytes under per-file and
    aggregate ceilings. The trusted Lua adapter computes SHA-256 with
    core.digest, then excludes raw bytes from the public receipt. v0 does not
    introduce a second SHA-256 implementation in C.

Q9  The candidate path remains ☱ review -> ☶ commit and append -> ☱
    observation. Closing authority and appending the public body fact belong to
    the same ☶ transaction boundary.
```

The active-dispatch answer implied by the review also sharpens Q5:

```text
action_dispatches remains the consumed-authority ledger
active provider execution gets a separate private in-flight counter/state
begin-seal requires that in-flight state to be empty
```

Synchronous Lua makes overlap impossible in the ordinary v0 runner, but the
private contract must still represent the fact it claims so a future provider
cannot turn an implementation accident into a false safety proof.

### 18.2 Q4 Splits Into Two Births

The proposal "the lifecycle is born at mint" is only partly compatible with
the current body. `repository_capability.mint` knows the session, lineage,
repository and root, but it does not know a Packet generation. Generation is
first present in resolution/action context, and G5 deliberately lets one
lineage grant serve more than one generation before sealing.

Therefore TABLE must distinguish two private records rather than force both
meanings into one lifecycle:

```text
root-authority history
  born at mint/open
  keyed by session + repository + root fingerprint
  owns root-wide active/pending/terminal exclusion and grant membership

generation candidate lifecycle
  born on the first authoritative generation/root use or begin-seal
  keyed by session + lineage + generation + repository + root fingerprint
  owns the exact candidate transaction and resulting seal identity
```

The root history makes the G5 condition inspectable. The generation lifecycle
states whose candidate was sealed. The remaining TABLE decision is whether the
second record is established on first successful generation-specific effect or
only on begin-seal; mint alone cannot establish it without changing the mint
contract and superseding G5.

### 18.3 Exact Repeat Requires Two-Surface Agreement

Q10 cannot be answered only by comparing a request digest with private
`sealed` state. Exact idempotence requires agreement between both authorities:

```text
same normalized seal-request digest
same private sealed lifecycle and closure receipt
same immutable candidate-seal body event
```

When all three agree, a repeated exact request returns the existing seal and
creates no new transition or event. A different digest is denied. Private
`sealed` state with a missing or contradictory body event is a loud runtime
invariant failure, not idempotent success and not Packet mortality.

### 18.4 Q11 Follows Existing Effect Physics For v0

The current body already answers the nearest physical precedent:

```text
ambiguous repository effect
  -> grant quarantine
  -> typed terminal effect_failure
  -> operator_failure event
  -> Packet death with cause effect_failure
  -> lineage completion classifies the corpse as blocked
```

Candidate-seal quarantine should follow that law in v0. The living Packet does
not remain forever at build `⋯`, does not proceed to `△`, and does not claim an
unsealed candidate. It dies as `effect_failure` with exact seal/root/quarantine
refs in residue. No new death cause is needed merely to name the seal phase.

Automatic recovery onto a fresh root would be a separate lineage policy. It
is plausible, but it is not authorized by step 8.4 and must never inherit
candidate truth from the quarantined root. Until that policy is specified, the
safe v0 result is blocked lineage plus operator-visible intervention.

### 18.5 Q12 Is A Session-Local Safety Lock In v0

The current capability registry is private in-memory session state. Therefore
the terminal root lock in v0 has the same lifetime:

```text
it survives Packet death and generation changes within the registry session
it does not claim persistence across runtime process loss
sealed/quarantined roots are not cleaned up or recycled by step 8.4
```

The current public root fingerprint is derived from repository/provider path
and device/inode identities. A deleted inode may eventually be reused. Within
v0, a resulting lock collision must fail in the safe direction as a typed
denial. A future allocator must choose a different root rather than weakening
the lock or silently treating the reused identity as new. Persistent cleanup,
root birth identity and crash recovery remain later contracts.

### 18.6 Questions Still Open For TABLE

The review does not close every design decision:

```text
Q2  exact process/stage evidence required by artifact_set.derive
Q4  exact birth point of the generation candidate lifecycle
Q8  exhaustive no-effect abort versus quarantine matrix
```

Q11 is resolved only for v0 mortality. A future fresh-root recovery policy is
still open and belongs to lineage/stage transition work, not candidate sealing.

## 19. Remaining Question Resolution - 2026-07-22

A second external response accepted the Q4 split and proposed concrete
resolutions for Q2, Q4 and Q8. Code inspection supports the direction with two
precision amendments:

```text
effect_counts[generation] is an existing hook, not itself the ownership record

the private registry proves whether closure committed; the provider proves
root continuity and observation postconditions
```

These answers remain inputs to TABLE until written there.

### 19.1 Q2: Evidence Required By artifact_set.derive

The minimum v0 derivation basis is:

```text
one runtime-confirmed Packet birth event whose process_contract_id, work mode,
context and stage_id agree with immutable Packet coordinates

one non-empty repository_id agreeing between birth and Packet

exactly one current structure formation contributing all and only the current
generation's live/selected repository.create_text_file.v0 units

exact unit ids and versions, normalized relative paths and regular-file kinds

formation event, unit-creation and source provenance refs, plus an exact choice
ref whenever selected state suppresses alternatives
```

More than one current formation claiming repository units is rejected in v0;
the body does not merge them and the caller cannot choose one. Suppressed or
foreign-generation units cannot enter the declaration. `artifact_set.inspect`
already joins a supplied declaration to current units and completion evidence,
but `artifact_set.derive` must add the missing body-owned formation/choice proof
instead of treating the existing unit selector as sufficient proof by itself.

The current birth event is sufficient stage authority for v0. An explicit
stage-record ref remains stageful-v1 work.

### 19.2 Q4: First Authority Consumption Claims The Root

The root-authority history is created by mint/open. The generation candidate
lifecycle is created atomically when the first generation-specific authority
is consumed:

```text
begin_effect validates the exact action and private grant
if the root is unclaimed, it binds the root to that action's lineage/generation
the generation lifecycle is created
only then is effect authority consumed and the provider may be entered
```

The existing `effect_counts[generation]` transition from zero to one is the
nearest implementation hook and audit evidence, but it must not become a
second source of ownership truth. Root claim, lifecycle birth and first effect
consumption are one private registry transition.

A typed no-effect failure of that first effect does not release the claim. The
root remains owned by the failed generation even when it materialized zero
files. Otherwise a helpful rollback would silently reopen the forbidden
cross-generation path.

After a root is claimed:

```text
the owning generation may re-resolve its active grant
a different generation cannot resolve or dispatch against that root
a descendant must receive a different repository identity/root
```

G5 is therefore narrowed to unclaimed roots and superseded after first
authority consumption. The existing G5 unit is a compatibility fixture, not a
live proof that cross-generation root reuse is still lawful. Replacing it must
produce separate controls for unclaimed compatibility, first-use claim,
same-generation continuation and descendant denial.

Changing only the caller-visible `repository_id` cannot bypass the claim or a
terminal root lock when the trusted provider resolves the same root identity.
The logical repository coordinate is evidence, not a physical-root reset
primitive.

In current v0 a sealable artifact set necessarily has repository-effect
completion evidence, so begin-seal should encounter an existing generation
lifecycle. If a future imported-artifact contract permits sealing before any
body effect, begin-seal will need an explicitly authorized atomic claim path;
that case is not invented by step 8.4.

### 19.3 Q8: Abort Requires Two Independent Positive Proofs

Before `seal_pending`, validation/readiness failure changes no lifecycle and
the root remains active.

After `seal_pending`, return to active is legal only when both facts are
positively established:

```text
private registry proof:
  closure commit did not occur and no provider dispatch remains in flight

trusted provider proof:
  the original root identity was continuously revalidated after the failed or
  rejected inventory attempt
```

Consequences:

```text
complete stable inventory with an exact mismatch
  -> no seal; abort to active is permitted

typed bound exhaustion followed by exact root revalidation and no commit
  -> no seal; abort to active is permitted

root replacement, entry drift, provider panic, contradictory identity or any
unknown postcondition
  -> quarantine

closure commit followed by candidate-seal event append failure
  -> loud runtime invariant; private state stays sealed and authority never
     reopens

malformed trusted receipt while seal_pending
  -> loud runtime invariant plus terminal quarantine when continuity cannot be
     independently proved; never a cosmetic Packet failure
```

The distinction is not the error label. It is whether the failure carries both
required proofs from their named owners. Returning to active from mere absence
of evidence is forbidden.

### 19.4 Documentary Consequence

Q2, Q4 and Q8 now have sufficiently precise candidate answers for a TABLE
round. TABLE must still expose every writer, reader, state transition and
falsifier rather than copying these paragraphs as prose. No implementation is
authorized by this resolution alone.

## 20. Current Thesis

```text
A candidate becomes judgeable only after the body has stopped being able to
rewrite it, observed exactly what remains, and recorded both facts without
upgrading semantic meaning into runtime truth.
```

The difficult part of step 8.4 is not hashing files. It is proving that the
identity being hashed is the body-derived candidate, that no proc-17 write can
cross the observation boundary, and that no descendant can reopen the same
physical root after the seal.
