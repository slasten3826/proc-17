# Candidate Seal Finality And Post-Seal Alignment Notes - 2026-07-22

Status:

```text
chaos / implementation decision
date: 2026-07-22
trigger: independent review of commit 534cf27
machinist decision: accepted
TABLE amendment authority: granted
CRYSTALL amendment authority: granted
runtime reader implementation authority: granted
QA authority: forbidden
router/pressure promotion: forbidden
automatic lineage transition: forbidden in this slice
```

Primary contracts:

```text
docs/01_table/yellowprints/candidate_seal_transaction_yellowprint.v0.md
docs/01_table/yellowprints/completion_scope_candidate_seal_yellowprint.v0.md
docs/01_table/yellowprints/nested_work_layer_derivation_yellowprint.v0.md
docs/02_crystall/blueprints/candidate_seal_transaction.v0.md
docs/02_crystall/blueprints/completion_scope.v0.md
docs/02_crystall/blueprints/work_layer_projection.v0.md
```

## 0. Trigger And Runtime Reproduction

The candidate-seal transaction itself is final, but its first reader was not.
The defect was grown through the real body path:

```text
repository effect
  -> accepted verification
  -> work completion
  -> exact candidate seal
  -> mutate the sealed repository work-unit version in the Packet field
```

Observed before this decision:

```text
private root state: sealed
immutable candidate-seal event: present
candidate_seal.current: absent/error
completion_scope.highest_scope: none
completion_scope.candidate.state: unsealed
work_layer: build ... / candidate_materialization_incomplete
```

The body therefore requested a write that its own private registry had already
made permanently impossible. The world fact remained correct; the reader hid
it because it revalidated historical finality against mutable current thought.

The same review found a smaller coverage gap: TABLE control `LC10a` already
requires a cross-lineage alias denial for one physical root, and the runtime
does deny it, but the permanent lifecycle suite did not exercise that branch.

## 1. Two Facts, Not One Mutable Status

A valid candidate seal answers one irreversible question:

```text
Was this exact repository candidate closed by this generation?
```

Current body alignment answers a different, repeatable question:

```text
Does the Packet's current repository-artifact thought still describe the
already sealed candidate?
```

They have different time semantics:

```text
seal fact
  historical, immutable, runtime_confirmed
  once true, never becomes absent

artifact alignment
  pure current derivation
  aligned | diverged
  may change when relevant field objects change
```

The alignment view is not a second seal and stores no mutable truth. It is
re-derived from the immutable seal event and current body evidence on every
read.

## 2. Finality Law

```text
An immutable, well-formed candidate-seal event bound to this Packet remains
visible for the rest of the generation.

Later body drift cannot unseal the root, erase the event, lower the physical
scope below candidate_sealed or restore materialization authority.
```

Seal record verification checks:

```text
schema and digest identity
Packet/lineage/generation/stage/repository subject binding
one non-contradictory immutable body event
```

It does not ask whether the current mutable field still matches the sealed
artifact set. That question belongs only to the alignment reader.

The seal writer remains stricter. Before the original body append it must still
prove exact current artifact evidence and private closure agreement.

## 3. Alignment Contract

The pure alignment projection is:

```lua
{
  protocol_version = "repository.candidate_seal_alignment.v0",
  alignment_id = "candidate-seal-alignment:<sha256>",
  packet_id = string,
  lineage_id = string,
  generation = integer,
  candidate_seal_id = string,
  sealed_artifact_set_id = string,
  current_artifact_set_id = string | nil,
  state = "aligned" | "diverged",
  reason = "exact_current_artifact_evidence"
    | "current_artifact_set_unavailable"
    | "current_artifact_set_changed"
    | "current_artifact_evidence_changed",
  source_refs = string[],
  conflicting_refs = string[],
  event_truth_status = "runtime_confirmed",
}
```

`aligned` requires the same exact body evidence that authorized the original
seal. A typed current-body absence, changed set identity, stale work version,
changed completion/verification ref or changed artifact content is `diverged`.
A malformed body/seal invariant remains loud and is not converted into a
beautiful conflict.

Unrelated trace/body motion that leaves repository-artifact evidence exact does
not create divergence.

## 4. Completion And Work-Layer Consequences

The completion reader always reads the historical seal before deciding whether
current materialization is complete.

```text
seal absent
  candidate.state = unsealed
  candidate.artifact_alignment = not_applicable

seal present + aligned
  highest_scope = candidate_sealed
  candidate.state = sealed
  candidate.artifact_alignment = aligned

seal present + diverged
  highest_scope = candidate_sealed
  candidate.state = sealed
  candidate.artifact_alignment = diverged
  conflicting_refs name seal and current-body evidence
```

The diverged work-layer projection is deliberately not materialization:

```text
mode = build
glyph = [checking]
state = checking
reason = candidate_sealed_body_conflict
missing = fresh_generation_plan_for:<candidate_seal_id>
```

In the executable glyph vocabulary, `[checking]` is `⊞`.

This reason has higher precedence than accepted/rejected QA evidence. A future
QA readiness reader must require `artifact_alignment = aligned`; it may never
accept a candidate whose current body has already disowned it.

This slice does not kill the Packet, invoke PLAN, allocate a root or create a
descendant. Those are later stage/lineage authorities. It only removes the
false instruction to write into a sealed root and exposes the exact reason a
fresh generation is required.

## 5. Product Lineage Consequence

The larger software loop implied by this law is:

```text
PLAN N
  -> BUILD N in a fresh root
  -> candidate seal N
  -> QA N
  -> PLAN/assessment N+1
       accepted: lineage delivery may finish
       changed/rejected: BUILD N+1 in another fresh root
```

The old candidate is not patched and is not renamed into absence. It remains an
immutable ancestor identified by its seal, verdict, decisions, residue and
lineage ledger refs. The next BUILD writes a complete candidate in a fresh
repository. This is a future stage-runner contract, not runtime authority
granted by this note.

## 6. Permanent Controls

```text
LC10a
  same trusted root + changed lineage_id is denied as logical alias

SF01
  exact grown seal remains readable after relevant field-version drift

SF02
  the same drift derives artifact_alignment = diverged

SF03
  completion scope remains candidate_sealed and names the conflict

SF04
  work layer reports candidate_sealed_body_conflict and never materialization

SF05
  post-seal write/mint/resolve authority remains denied

SF06
  unrelated body/trace motion preserves aligned

SF07
  malformed or contradictory seal history remains loud

SF08
  reader output is detached and deterministic
```

## 7. Rejected Treatments

```text
erase or invalidate the historical seal after field drift
reopen the sealed repository root
lower scope to unsealed/incomplete materialization
silently accept QA against a body-diverged candidate
store mutable alignment beside private root state
let substrate decide whether the old seal still applies
invent automatic death/rebirth before stage authority exists
```

## 8. Thesis

```text
The seal records what the generation irreversibly built.
Alignment records whether its current thought still agrees.
Thought may move; the sealed past does not.
```
