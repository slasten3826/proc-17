# Candidate Seal TABLE Cross-Audit - 2026-07-22

Status:

```text
chaos / documentary gate record
scope: step 8.4 TABLE -> CRYSTALL transition
audit kind: internal cross-table consistency audit
external independent audit claimed: no
machinist crystallization decision: granted 2026-07-22
code authority granted: yes, by machinist 2026-07-22 after crystall review
QA authority granted: no
router promotion granted: no
decision truth status: document_decision
```

Audited TABLE set:

```text
docs/01_table/yellowprints/artifact_set_derivation_yellowprint.v0.md
docs/01_table/yellowprints/repository_candidate_lifecycle_yellowprint.v0.md
docs/01_table/yellowprints/candidate_seal_transaction_yellowprint.v0.md
```

Compatibility surfaces checked:

```text
docs/01_table/yellowprints/capability_safe_repository_hands_yellowprint.v0.md
docs/01_table/yellowprints/completion_scope_candidate_seal_yellowprint.v0.md
docs/01_table/yellowprints/stage_transition_generation_recovery_yellowprint.v0.md
docs/02_crystall/blueprints/capability_safe_repository_hands.v0.md
docs/02_crystall/blueprints/candidate_seal.v0.md
docs/02_crystall/blueprints/completion_scope.v0.md
docs/02_crystall/blueprints/work_layer_projection.v0.md
```

## 0. Gate Question

Can the three TABLE contracts be crystallized without requiring the CRYSTALL
writer to invent:

```text
an authority owner
a state transition
a truth upgrade
a failure/death class
a reader for a stored fact
a cross-generation root policy
an inventory/hash boundary
```

## 1. Result

```text
gate result: satisfied for CRYSTALL writing
runtime implementation gate: opened by machinist 2026-07-22
runtime implementation status: complete for the direct/shadow v0 boundary;
  independent audit pending
QA/router promotion gates: closed
```

No unresolved cross-table contradiction was found after the following
amendments were applied:

```text
old G5 narrowed to unclaimed-root compatibility
first-use claim made sticky after clean/failed first effect
repository_id forbidden as a physical-root reset alias
root claim and generation lifecycle represented by one mutable authority surface
action consumption separated from provider in-flight state
abort evidence split between registry and provider owners
malformed trusted physics kept loud instead of laundered into Packet death
standalone caller-selected artifact declaration rejected
private closure stores request/closure/inventory identity; candidate_seal_id is
  derived only after the body event and is not a second registry commit
```

## 2. Cross-Table Invariants

| Invariant | Derivation TABLE | Lifecycle TABLE | Transaction TABLE | Result |
|---|---|---|---|---|
| caller cannot select candidate members | owns | unaffected | re-derives before pending | consistent |
| one generation owns one used root | binds generation in declaration | owns sticky claim | requires owner lifecycle | consistent |
| descendant cannot mutate ancestor root | excludes foreign generation | denies after claim | tests denial before seal/after terminal | consistent |
| no duplicate mutable ownership truth | pure view only | one aggregate owns state | consumes detached projection only | consistent |
| no write during inventory/commit | no authority | seal_pending/revision/in-flight gate | owns transaction order | consistent |
| exact-tree inventory | supplies expected files/dirs | supplies exact root | provider observes and verifier compares | consistent |
| abort requires positive evidence | no lifecycle transition | registry proof owner | joins registry + provider proofs | consistent |
| quarantine is terminal authority | no effect | root-wide terminal state | validated ambiguity -> effect_failure | consistent |
| broken runtime remains loud | invariant on malformed body evidence | defensive close may quarantine | no Packet-death laundering | consistent |
| seal does not prove semantics | preserves content status | no semantic authority | emits mixed seal status | consistent |

## 3. Writer/Reader Audit

Every proposed stored/private fact has a named first reader:

```text
root authority -> mint alias check / resolve / effect / seal gate
generation claim -> resolve / effect / seal planner
in-flight dispatch -> begin-seal exclusion
seal transaction state -> lease checks / commit / body verifier
quarantine reason -> operator failure or loud invariant report
candidate seal body event -> completion scope / future QA / corpse / corpus
```

Pure derivations are not falsely assigned storage writers. Returned projections
remain detached and carry no authority.

## 4. Capability Delta Audit

The only intentional removal of an existing compatibility ability is:

```text
same-lineage generation N+1 may no longer reuse a root after generation N has
consumed its first repository effect
```

This agrees with the existing fresh-generation/fresh-repository stage law.
Before a fresh-root allocator exists, a combined hands + lineage recovery path
may block honestly. CRYSTALL must state this delta; implementation may not hide
it with fallback root reuse.

## 5. Remaining Deferrals

```text
fresh repository allocator
QA hand/check/verdict execution
automatic recovery from quarantine
persistent seal/root-lock recovery
terminal-root cleanup/compost
global filesystem immutability
multi-formation candidate composition
imported artifact roots
router promotion
```

None is required to specify the three implementation contracts. Each remains a
closed gate in their CRYSTALL status.

## 6. Decision

The machinist explicitly authorized the CRYSTALL round on 2026-07-22. The
original documentary decision authorized three specialized blueprints and
amendments to older blueprint wording. A later explicit machinist instruction
on 2026-07-22 separately authorized implementation.

```text
TABLE -> CRYSTALL: yes
CRYSTALL -> MANIFEST/code: yes, granted 2026-07-22 after crystall review
```

## 7. Produced Crystall Set

The authorized round produced:

```text
docs/02_crystall/blueprints/artifact_set_derivation.v0.md
docs/02_crystall/blueprints/repository_candidate_lifecycle.v0.md
docs/02_crystall/blueprints/candidate_seal_transaction.v0.md
```

Compatibility amendments were applied to the older hands, candidate-seal,
completion-scope and work-layer blueprints. The old umbrella candidate-seal
document remains archaeology; it explicitly delegates conflicting detailed
physics to this specialized set.

```text
crystall documents produced: yes
implementation started: yes, 2026-07-22
runtime implementation completed: yes, direct/shadow v0
independent implementation audit completed: no
```

## 8. Implementation Evidence And Honest Gaps

Implemented surfaces:

```text
body-derived artifact-set and formation readers
sticky root/generation lifecycle and terminal source-write lock
separate consumed-action and provider-in-flight truth
bounded descriptor-relative native exact-tree inventory
two-owner abort proof, quarantine and atomic private closure
dedicated candidate-seal body event with private/public agreement
pure completion-scope and work-layer readers
```

Green local evidence:

```text
full Lua suite: 99 suites, `all tests ok`
mortality battery 8/8
native clean build and native contract tests
ASan/UBSan native execution (leak mode unavailable under ptrace sandbox)
candidate-seal direct, hostile, native and split-brain controls
```

The pre-existing Linux provider control `P15` for a cross-device bind-mounted
parent remains an explicit skip because `PROC17_TEST_BIND_MOUNT` was not
enabled. No cross-device result is claimed by this implementation run.

The following TABLE controls are not falsely claimed as complete:

```text
ST16a/ST19/ST20
  typed unstable/quarantine behavior is green, but deterministic native
  inventory race injection hooks are not yet present

ST31
  generic effect_failure mortality is green; a candidate-seal failure grown
  through the runner is blocked by the deliberately closed router/execution
  promotion gate

ST33
  reader purity and generic work-layer observer ablation are green; a sealed
  candidate life cannot be paired before candidate execution is promoted

ST34
  documentation export/profile integration remains an explicit deferral
```

These gaps block promotion, not the direct API implementation or external
audit. QA authority, software acceptance and root delivery remain absent.
