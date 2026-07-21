# Preimplementation Audit Disposition - 2026-07-21

Status:

```text
chaos / document_decision
decision owner: machinist + Codex
source audit:
  docs/00_chaos/fable_preimplementation_crystall_audit_raw_2026-07-21.md
F4 audit:
  docs/00_chaos/fable_full_project_f4_audit_raw_2026-07-21.md
F4 decision:
  docs/00_chaos/f4_rejected_generation_terminal_projection_notes_2026-07-21.md
code authority granted by this record: no
global documentary crystall gate: satisfied
QA implementation gate: closed / explicitly deferred
```

This record names the disposition of the cold-audit findings. It does not edit
the raw external report and does not convert the auditor's claims into
`runtime_confirmed` facts.

## Accepted And Amended

### F1 - Duplicate Generation Key

Accepted.

```text
generation       -> scalar Packet generation identity
generation_state -> derived state block
```

TABLE and CRYSTALL now use separate keys.

### F2 - Seal Transaction TOCTOU

Accepted.

`seal_pending` and lease invalidation now precede the final no-follow inventory.
No source-write authority exists between that inventory and committed closure.

### F3 - Context Identity Drift

Accepted.

```text
process_contract_id -> process authority identity
context             -> semantic work context
```

The fields are independent across completion, work-layer and documentation
snapshot contracts.

### F5 - Writerless Stage Rejection

Accepted with removal, not invention.

Stage v0 states are:

```text
pending | active | complete | suspended
```

`qa_rejected` rejects one generation. It does not reject the stage. A future
stage-level rejection requires an explicit process-contract policy, named
writer and ledger event.

### F6 - Vocabulary And Boundary Seams

Accepted and normalized:

```text
stage_id = "stage:" .. lineage_id .. ":" .. ordinal .. ":" .. stage_key
candidate_seal_id names the content-addressed record
candidate_seal_event_ref names its trace event when needed
unsupported is an inspection outcome, not a boundary_candidate kind
choice_committed maps to 01_table
plan_crystallization_current separately maps to 02_crystall
```

Applicability is now a closed vocabulary tied to exact producers and readers:

```text
reentry_proposal
inherited_proposal
grave_pressure
corpus_reentry_proposal
```

A living generation cannot be fabricated as a terminal corpus entry. Corpus
assembly at an active ledger head is partial, contains terminal ancestors only,
records the omission and cannot satisfy root delivery.

QA rejection remains lineage generation evidence. Grave classification reads
death/progress/residue and cannot authorize or deny recovery.

## Resolved Finding

### F4 - Rejected-Generation Terminal Projection

Resolved by outcome A after the focused external audit and a TABLE/CRYSTALL
cross-check.

```text
standalone failure_crystal.v0: removed from current executable direction
build ◈: exact rejected check evidence exists; final verdict is pending
build ▲: final rejected verdict is bound to the current seal/check set
△: embeds one bounded rejected-generation projection in the terminal manifest
corpse: freezes the full manifest; trace_tail is diagnostic only
carrier: transports a bounded inherited projection to a fresh generation
qa-check.v0: explicitly deferred with the future QA hand
```

The final verdict and terminal manifest perform the causal jobs formerly
assigned to a failure crystal. Semantic diagnosis remains a separate descendant
`semantic_proposal`; it cannot alter the dead generation or its exact verdict.

The six TABLE documents and seven CRYSTALL blueprints now use the same phase,
identity, writer/reader and deferral laws. The three documentation TABLE gates
record the 2026-07-21 cross-table audit as satisfied.

This closes documentary ambiguity only. It grants no new runtime, router, QA,
filesystem or lineage authority. Pure readers and shadow observers retain only
the authority written in their individual CRYSTALL status blocks.

## Closure Verification

Observed after the synchronized amendment:

```text
active six-TABLE/seven-CRYSTALL failure_crystal fields/readers/writers: zero
remaining old-term matches on those surfaces: removal-status prose only
paired derivations checked:
  B2 final rejected verdict -> ▲
  B3 rejected check evidence with verdict absent -> ◈
  L13 exact final verdict -> ◈ to ▲
  S14 exact terminal manifest projection -> fresh build recovery
  G2 rejected corpus history -> QA verdict + bounded manifest projection
snapshot boundaries checked:
  qa_rejection_observed
  rejected_generation_terminal_ready
Markdown structure check: 19 affected documents green
Lua baseline: 91 test modules, all green
mortality battery: 8/8 green
runtime source changes in this pass: none
```

These results prove documentary consistency and regression safety of a docs-only
pass. They do not prove the deferred QA or rejected-generation runtime behavior.

## Gate State

```text
cross-table audit preserved: yes
F1 amended: yes
F2 amended: yes
F3 amended: yes
F4 resolved: yes / outcome A
F5 amended: yes
F6 amended: yes
six TABLE contracts synchronized: yes
seven CRYSTALL blueprints synchronized: yes
documentation cross-table crystallization gate: satisfied
QA implementation authorized: no / explicit future campaign
production implementation globally authorized: no
next decision: choose the first blueprint-bounded implementation slice
```
