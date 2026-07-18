# Relation Consumer Causality Yellowprint v0

Status:

```text
table / pre-crystall relation-consumer gate
date: 2026-07-17
scope clarification 2026-07-18:
  this table governs discrete L2-CONNECT only
  it does not govern continuous L1-CONNECT body physics
sources:
  docs/00_chaos/promotion_tables_materialization_and_witness_audit_2026-07-17.md
  docs/00_chaos/versioned_witness_table_observation_2026-07-17.md
  docs/00_chaos/fable_response_relation_witness_law_2026-07-17.md
  docs/00_chaos/codex_response_to_fable_relation_witness_law_2026-07-17.md
  docs/00_chaos/fable_response_witness_acceptance_2026-07-17.md
  docs/01_table/yellowprints/operator_tree_physics_yellowprint.v0.md
production code change authorized: no
crystallization authorized: no
corpus construction authorized: no
router promotion authorized: no
partially superseded 2026-07-18 by:
  docs/01_table/yellowprints/l2_transient_relation_lifecycle_yellowprint.v0.md
amendment scope:
  versioned causality and ablation gates remain active
  RUNTIME raw activation is rejected
  DISSOLVE is split into raw-release and formed-dissolution contracts
```

## 0. Decision

Current proc-17 has a real `☰ CONNECT` writer but no demonstrated live reader
whose behavior depends on the written relations.

This table does not invent a consumer to preserve the full-tree schedule. It
tests whether consumers already declared by Packet physics can become causal:

```text
☰ writes E_raw
☵ may consume relation motifs while forming CALM
☱ may install or reject current relations as active E
☷ may release active rigid relations
```

The result is allowed to be negative. If no downstream behavior changes under
relation ablation, relation-driven routing remains outside the promoted
authority surface until a real consumer appears.

## 1. Why This Is A Separate Table

The previous versioned-coverage table answered:

```text
which current unit versions were inspected by CONNECT?
```

It did not answer:

```text
who needs the resulting relation, and what body behavior changes because it
exists?
```

Four layers must remain separate:

| Layer | Question | Sufficient for ☰ pressure? |
|---|---|---:|
| Record | Does a unit or relation exist? | No |
| Coverage | Has CONNECT inspected the current unit version? | No |
| Causal use | Does a named reader change or lose an operation because of the relation? | Candidate evidence |
| Routing pressure | Should that causal fact compete for the next legal operator? | Only after matched controls |

An uncovered unit is real body state. It is not automatically an urgent call
to CONNECT.

## 2. Current Runtime Inventory

The inventory distinguishes executable code from declared future physics.

| Surface | Current executable fact | Status |
|---|---|---|
| `☰` | Writes bounded raw relation snapshots | Runtime-confirmed by code/tests |
| `☱` | Registry declares active-relation writes, but the organ does not call `field.activate_relations` | Declared, not manifested |
| `☵` | Operator-tree table declares relation hints; current registry and organ do not read field relations | Declared, not manifested |
| `☷` | Reads and weakens active relations | Implemented reader with no live producer of active relations |
| `☴` | Upper revision snapshot includes relation axes, but the substrate call does not receive or inspect relation objects | Freshness telemetry, not relation consumption |
| pressure readers | Read raw coverage and active rigidity | Instrumentation/routing reads, not downstream work |

Stronger executable finding:

```text
field.activate_relations(...) has no production caller today
raw relation snapshots can be written without entering active Packet physics
```

Therefore the current consumer inventory is empty. This is evidence about the
implementation, not proof that Packet physics can never contain relation
consumers.

## 3. Two Legitimate Causality Classes

### 3.1 Blocking demand

A named consumer cannot perform a declared operation or preserve a required
invariant until relation work occurs.

```text
missing relation -> consumer blocked
relation supplied -> consumer proceeds
```

This is the strongest relation-need witness.

### 3.2 Causal affordance

A named consumer can still run without the relation, but a valid relation
causes a bounded, declared, and observable difference in its body-owned result.

```text
same Packet state without relation -> result A
same Packet state with relation    -> result B
remove only relation use           -> result returns to A
```

This is weaker than starvation but may still be physical pressure. It is valid
only when the effect is body-visible and survives ablation. "The LLM might do
better" is not causal affordance.

This table therefore narrows one earlier CHAOS claim:

```text
starvation is sufficient, but not the only possible causal basis
coverage alone remains insufficient
```

## 4. Candidate Consumer R1: ENCODE Relation Motif

`☰-☵` is a canonical edge, so ENCODE is the first immediate consumer candidate.

Selected candidate contract:

```lua
encode_input.relation_hints = {
  raw_epoch = integer,
  relation_ids = {string},
  endpoint_versions = table,
  content_truth_status = string,
}
```

Required behavior:

| Condition | ENCODE behavior |
|---|---|
| No current relation motif | Uses the existing structure path |
| Current supported motif | May form hierarchy/network/grouping that names consumed relation ids |
| Stale endpoint version | Does not consume the stale relation; records why |
| Unsupported or contradictory motif | Preserves it as residue/pressure; does not silently promote it |
| Semantic relation content | Remains semantic; ENCODE confirms only that the relation was structurally consumed |

The consumer is accepted only if relation use changes a body-owned ENCODE
record such as hierarchy, grouping, ordering, identity mapping, or explicit
consumed-relation provenance. Prompt wording alone is not an effect.

## 5. Candidate Consumer R2: RUNTIME Relation Installation

Amendment note 2026-07-18:

```text
This candidate is rejected by the four-road L2 lifecycle table.
ENCODE owns formation from raw relation; RUNTIME may only preserve or reinforce
already formed structure. Keep this section as the archaeology of the earlier
consumer hypothesis, not as authority for crystallization or code.
```

The operator-tree table assigns active `E` and relation momentum to `☱`.
Current code declares this ownership but does not execute it.

Candidate contract:

```text
fresh E_raw exists
-> when the Packet legally reaches ☱, RUNTIME inspects the epoch
-> structurally current relations become active, or are rejected with a typed reason
-> activation is a runtime-confirmed body event
-> relation semantic content keeps its original truth status
```

Important topology law:

```text
☰ and ☱ are not adjacent
this contract never authorizes ☰ -> ☱
```

The Packet must reach `☱` through a legal path such as `☰ -> ☴ -> ☱` or
`☰ -> ☵ -> ☱`, and every intermediate operator must perform real work. The
router must not invent a bridge for implementation convenience.

Activation eligibility must be body-owned and deterministic:

```text
raw epoch is current
endpoints exist at recorded versions
relation state is structurally installable
boundedness/truncation is explicit
```

RUNTIME does not decide whether a semantic claim is true. It only confirms
that a relation with its existing truth status was or was not installed into
active Packet state.

## 6. Candidate Consumer R3: DISSOLVE Active Relation

`☷` already consumes active rigid/stale relations. It is downstream evidence
for R2, not an independent justification for raw relation production while no
activation path exists.

```text
☰ writes raw relation
legal path reaches ☱
☱ activates relation
rigidity/staleness becomes measurable
legal path reaches ☷
☷ releases the exact active relation
```

The separate direct-unit inherited-form contract remains valid. An inherited
failed form does not require a synthetic relation merely to give DISSOLVE a
handle.

## 7. Matched ENCODE Controls

All pairs use the same units, truth statuses, bounds, work mode, and substrate
response. Only relation availability/use changes.

| ID | Prepared state | Expected result |
|---|---|---|
| A1 | Addressable units, no relation motif | Baseline ENCODE form and provenance |
| A2 | A1 plus one current supported motif produced by ☰ | ENCODE result names consumed relation and differs in one declared structural dimension |
| A3 | A2 with one endpoint version advanced | Relation is not consumed; typed stale result; output does not pretend current structure |
| A4 | A2 with relation-consumption policy disabled in shadow ablation | Result returns to A1 shape except instrumentation |
| A5 | A2 relation content is `semantic_proposal` | Structural consumption is confirmed; semantic truth is not promoted |
| A6 | ☰ records an honest empty snapshot | ENCODE follows A1; empty recognition does not become a fake motif |

Acceptance requires:

```text
A2 differs from A1 in body state, not prose
A4 removes the same difference
A3 and A6 remain honest negative controls
the relation was produced from Packet state, not supplied only as a harness answer
```

## 8. Matched RUNTIME And DISSOLVE Controls

| ID | Prepared state | Expected result |
|---|---|---|
| B1 | No pending raw relation epoch | ☱ claims no relation-installation work |
| B2 | Fresh raw relation with current endpoints; Packet reaches ☱ legally | ☱ activates it once and records source epoch/ids |
| B3 | B2 but an endpoint version changed before ☱ | Typed stale rejection; no active relation |
| B4 | B2 but raw snapshot was truncated | Only explicit stored scope may activate; truncation remains visible |
| B5 | B2 relation content is semantic | Activation preserves semantic truth status |
| B6 | B2 followed by one rigidity mutation | ☷ readiness names the same active relation |
| B7 | B6 followed by ☷ | Relation weakens/releases once; active revision and residue change lawfully |

The B-chain must be grown through canonical adjacency. Direct organ calls may
prove local contracts, but only an integration life can prove routing.

## 9. Relation-Pressure Acceptance Gate

A relation contribution may enter promotion evidence only when all rows pass:

| Requirement | Required evidence |
|---|---|
| Named reader | Existing organ and exact operation |
| Exact object domain | Unit/relation ids plus current versions |
| Causal class | Explicitly `blocking_demand` or `causal_affordance` |
| Body-visible effect | Stored state/event differs, not only substrate text |
| CONNECT capability | ☰ can inspect or produce the relevant relation without semantic invention |
| Shared provenance | Pressure, readiness, relation snapshot, and reader name compatible refs |
| Positive control | Relation fact creates the declared effect |
| Negative control | Missing/stale/empty relation does not create the effect |
| Ablation | Disabling only relation use removes the effect |
| Discharge | Successful processing changes or removes the same witness |
| Truth preservation | Structural use never upgrades semantic content |
| Boundedness | Scope, truncation, and omitted counts remain explicit |
| Topology | No non-canonical bridge or fake intermediate tick |

An organ declaration in a table is a hypothesis until these controls pass. A
passing unit test built entirely from harness-injected relation candidates is
not sufficient promotion evidence.

## 10. Route Competition Controls

Only after one consumer passes Section 9:

| ID | State | Required observation |
|---|---|---|
| C1 | Coverage gap with no causal reader fact | No ☰ routing contribution |
| C2 | Same state plus accepted causal reader fact | Typed ☰ contribution with reader/object refs |
| C3 | Remove only causal reader fact | Contribution disappears |
| C4 | Accepted ☰ pressure plus another ready neighbor | Selection is explained by measured pressure, not exclusion theater |
| C5 | Equal valid totals | Record tie explicitly; canonical order remains control policy until an age law is separately accepted |
| C6 | Relation work completed or honestly empty | Same witness is discharged or transformed |

This table does not tune weights. It first proves that a varying signal exists.

## 11. Decision Matrix

| ENCODE controls | RUNTIME controls | Decision |
|---:|---:|---|
| Green | Green | Full internal relation chain exists; crystallize both readers and W1 pressure |
| Green | Red | ☰ has a causal immediate reader; stage ENCODE path only; active-E claims remain blocked |
| Red | Green | Relation lifecycle exists; stage raw/active/DISSOLVE path; motif claims remain blocked |
| Red | Red | Keep relation coverage as telemetry and gate ☰ routing on pipeline A or a later explicit authority revision |

No outcome permits inventing a consumer solely to close 38/38.

## 12. Age And Fairness Are Deferred

Fable's narrowed proposal remains a candidate:

```text
terminal-class guard
-> oldest unserved witness among equal non-terminal totals
-> canonical order only for true same-age ties
```

It is not part of this table's implementation gate. Age should be tabled only
after varying causal witnesses exist and an actual equal-score starvation case
is reproduced. Otherwise proc-17 would gain a scheduler for signals that have
not yet earned physical meaning.

Any later age contract must still define stable witness identity, source-event
resolution, service/discharge, unsupported no-op handling, and a named reader
for every record it writes.

## 13. False-Green Matrix

| False green | Rejecting assertion |
|---|---|
| Coverage gap treated as causal need | C1 emits no contribution |
| Relation changes only prompt text | A2 requires body-state difference |
| Harness injects the desired relation/output | Integration relation originates from Packet state |
| ☱ registry declaration treated as implementation | B2 must execute and record activation |
| Semantic proposal becomes runtime truth | A5/B5 preserve content truth |
| Empty CONNECT snapshot called useful relation | A6 follows baseline |
| Direct `☰ -> ☱` shortcut | Integration trace must remain canonical |
| All competitors excluded | C4 keeps another ready neighbor |
| Canonical tie called pressure proof | C4 cannot pass solely by tie order |
| Active relation exists only in a unit fixture | B-chain must be grown through a living Packet |
| Full corpus proceeds after partial chain | Decision matrix stages only passed claims |

## 14. Next Sequence

```text
1. observe this table against current code and Packet documents
2. amend defects in place; keep rejected hypotheses visible
3. crystallize the smallest R1/R2 contracts that survive observation
4. implement behind shadow/feature control without router authority
5. run A/B matched controls and observer ablation
6. decide the matrix row from evidence
7. only then amend the promotion corpus and relation pressure surface
```

Until step 6, the honest state is:

```text
☰ organ exists
relation storage exists
causal consumer is unproved
relation-driven authority remains blocked
```

After the 2026-07-18 amendment, "causal consumer" means the direction-specific
OBSERVE, raw-DISSOLVE, or ENCODE reader defined by the L2 lifecycle table. The
older RUNTIME activation matrix cannot satisfy the gate by itself.
