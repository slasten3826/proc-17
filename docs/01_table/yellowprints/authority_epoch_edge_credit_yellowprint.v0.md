# Authority Epoch And Eligible Edge Credit Yellowprint v0

Status:

```text
layer: TABLE
date: 2026-08-01
source:
  docs/00_chaos/full_tree_post_hands_qa_audit_2026-08-01_notes.md
scope:
  immutable authority identity
  edge-stats epoch separation
  physical execution versus promotion credit
  corpus merge and closure law
production code change authorized: no
router default change authorized: no
promotion authorized: no
next layer: CRYSTALL
```

This table extends, but does not erase:

```text
docs/01_table/yellowprints/edge_evidence_roles_yellowprint.v0.md
docs/01_table/yellowprints/tree_authority_promotion_corpus_yellowprint.v0.md
docs/01_table/yellowprints/tree_authority_promotion_record_yellowprint.v0.md
docs/01_table/yellowprints/pressure_need_and_action_composition_yellowprint.v0.md
```

Where their merge or closure language treats every `tree` execution as one
kind of evidence, this table is the more precise law. Old records remain
archaeology. They are not reinterpreted as if they had carried fields that did
not exist when they were produced.

## 0. Mission

The instrument answers two different questions without collapsing them:

| Question | Required answer |
|---|---|
| What physics committed this movement? | An immutable authority epoch |
| Did the destination organ really run? | Physical edge evidence |
| May this execution support a promotion claim? | Eligible edge credit |
| May two lives be summed? | Only under an exact merge law |
| May the body promote itself? | No; final promotion remains a document decision |

The causal chain is:

```text
resolved runner configuration
-> immutable authority epoch
-> pressure snapshot and qualified candidate
-> route decision retaining eligibility
-> committed transition
-> destination arrival or typed failure
-> dual edge ledger
-> epoch-bounded corpus
-> human/machine document decision
```

The instrument is massless:

```text
it creates no pressure
it selects no route
it charges no Packet budget or loss
it mutates no field, CALM, runtime evidence or repository
its failure cannot become a Packet death
its failure invalidates the measurement and promotion claim
```

## 1. Selected Decisions

| ID | Question | Decision |
|---|---|---|
| D01 | Is `router_mode` the authority identity? | No. It names only the movement arrangement |
| D02 | Is one epoch id sufficient? | No. Physics and instrumentation receive separate ids |
| D03 | What is the full record called? | `authority_epoch.v0` |
| D04 | What is the next edge protocol? | `edge-stats.v3`; v2 is not upgraded in place |
| D05 | Does every real execution count toward promotion? | No. Physical execution and eligible execution are separate counters |
| D06 | Does an ineligible execution disappear? | No. It remains runtime-confirmed physical evidence |
| D07 | Can a later arrival upgrade an ineligible route? | No. Selection eligibility is immutable; final credit can only preserve or reject it |
| D08 | Can unlike epochs merge? | No. Raw merge requires exact evidence epoch identity |
| D09 | Can observer-on and observer-off raw ledgers merge? | No. They remain paired but separate evidence epochs |
| D10 | Can work mode or task prompt define the epoch? | No. They are life inputs, not authority physics |
| D11 | Can model/provider define the epoch? | No. They remain invocation provenance |
| D12 | Do policy knobs that change selection define the epoch? | Yes |
| D13 | Does any active routing-consumer ablation define the epoch? | Yes |
| D14 | Can a harness route receive promotion credit? | No |
| D15 | Can binary Tree evidence close qualified Tree directions? | No |
| D16 | Can runtime evidence issue the final promotion verdict? | No |
| D17 | What happens after a harness route enters a body life? | A monotonic authority taint excludes that route and all later routes from promotion credit |

## 2. Vocabulary

| Term | Meaning |
|---|---|
| Physics epoch | Exact movement, pressure, composition, action, topology and ablation contract |
| Evidence epoch | Physics epoch plus observer/instrumentation configuration |
| Life label | Work mode, case id, model, prompt, budget and other inputs not defining authority |
| Physical activity | Candidate, selection, commit, arrival or failure that actually occurred |
| Qualified candidate | Candidate whose policy supplied exact witness/action evidence and did not mark it unqualified |
| Eligible edge credit | Physical destination arrival whose entire derivation-to-arrival chain remains promotion-eligible |
| Closure | At least one eligible executed ref for every direction in the declared authority surface |
| Control evidence | Real evidence useful for diagnosis but forbidden from closure |
| Instrument error | Measurement failure outside Packet physics |

The word `promotion_eligible` does not mean `promoted`.

```text
promotion_eligible = this route may enter the candidate corpus
promoted           = a later document decision changed authority
```

## 3. Authority Epoch Schema

### 3.1 Full record

```lua
{
  kind = "authority_epoch",
  protocol_version = "authority_epoch.v0",

  physics = {
    topology_version = "processlang.topology.v0",
    authority_surface_id = string,
    operator_registry_version = "operator-registry.v0",

    router_mode = "legacy" | "shadow" | "tree",
    configured_movement_owner = "legacy_control"
                              | "tree"
                              | "harness_override",

    pressure_policy = "camera_reconciliation"
                    | "sampled"
                    | "qualified_need_v0",
    pressure_derivation_version = "pressure.binary.v0"
                                | "pressure.qualified_need.v0",
    pressure_calibration_status = string,

    routing_policy = "legacy.control.v0"
                   | "pressure.binary.v0"
                   | "pressure.class_order.v0",
    routing_policy_status = string,
    policy_parameters = normalized_map,

    witness_protocol = "none" | "pressure.witness.v1",
    witness_gate_version = "none" | string,
    action_protocol = "none" | "pressure.action_plan.v0",

    ablation_vector = normalized_map,
  },

  instrumentation = {
    observer_mode = "none" | "tree_shadow" | "legacy_shadow",
    observer_enabled = boolean,
    observer_protocol = "none" | "edge-observer.v0",
    edge_stats_protocol = "edge-stats.v3",
  },

  physics_epoch_id = "sha256:" .. hex,
  evidence_epoch_id = "sha256:" .. hex,
  event_truth_status = "runtime_confirmed",
}
```

The exact observer protocol name may be crystallized from current runtime
structures. It must be explicit and versioned; `none` is a real value.

### 3.2 Identity decomposition

```text
physics_epoch_id
  = digest(normalize(authority_epoch.physics))

evidence_epoch_id
  = digest(normalize({
      physics_epoch_id,
      authority_epoch.instrumentation,
    }))
```

The full record is immutable after runner birth. Routes carry ids and refs, not
independently editable copies of the epoch.

### 3.3 Required physics fields

| Field | Why it belongs to physics identity | Current writer |
|---|---|---|
| `topology_version` | Changes legal neighbors | `core.topology` |
| `authority_surface_id` | Changes the edge/direction closure surface | Edge catalog derivation |
| `operator_registry_version` | Changes readiness and effect ownership | Operator registry |
| `router_mode` | Changes who commits movement | Runner options |
| `configured_movement_owner` | Names the owner promised by resolved runner configuration | Resolved runner mode |
| `pressure_policy` | Distinguishes binary, sampled and qualified derivation | Resolved pressure dispatcher |
| `pressure_derivation_version` | Names actual sensor schema | Pressure result |
| `pressure_calibration_status` | Prevents measured and vibed policies from aliasing | Pressure module |
| `routing_policy` | Distinguishes binary totals from class composition | Tree/legacy decision |
| `routing_policy_status` | Preserves treatment/promotion phase | Routing module |
| `policy_parameters` | Threshold/fallback knobs can change the route | Normalized resolved options |
| `witness_protocol` | Distinguishes exact witness-bearing policy | Qualified pressure |
| `witness_gate_version` | Names versioned object coverage law | Witness contract |
| `action_protocol` | Distinguishes exact executable plans from prose pressure | Pressure action |
| `ablation_vector` | Consumer removal changes available causality | Normalized resolved options |

#### 3.3.1 Authority surface identity

The surface id is not a hand-written label. It is derived from:

```lua
{
  topology_version = string,
  edges = {
    {
      edge_id = string,
      left = glyph,
      right = glyph,
      legal_directions = sorted_unique_string_array,
    },
  },
  edge_count = integer,
  legal_direction_count = integer,
}
```

Current expected cardinality is 22 edges and 38 legal directions. The resolver
must compare the topology adjacency and edge catalog; disagreement is an
instrument error, not a new surface id. A future lawful topology revision
changes the structured surface and therefore its digest.

### 3.4 Values that do not belong to the epoch

These remain mandatory per-life provenance where applicable:

| Value | Why it is not authority identity |
|---|---|
| Work mode | Different cases must contribute to one authority corpus |
| Prompt/task hash | Packet input, not routing law |
| Model/provider | Semantic substrate provenance |
| Packet/lineage/generation/session ids | Life identity |
| Initial budget/loss | Economic initial condition |
| Repository id/path | World identity |
| Capability instance handles | Per-life authority material |
| Grave/carrier refs | Inherited state |

They cannot be discarded. They simply do not alter `physics_epoch_id`.

### 3.5 Implementation provenance

Runtime cannot honestly derive a Git commit from Packet state. Therefore:

```lua
implementation_provenance = {
  source_revision = string | nil,
  worktree_state = "clean" | "dirty" | "unknown",
  artifact_digest = string | nil,
  event_truth_status = "runtime_confirmed",
  content_truth_status = "unknown"
                       | "semantic_proposal"
                       | "runtime_confirmed",
  verifier_ref = string | nil,
}
```

It is not hashed into the physics epoch. It is mandatory at promotion-corpus
assembly, where an external verifier must resolve it. v0 promotion closure
requires one verified implementation revision with
`content_truth_status=runtime_confirmed`. Diagnostic runs may leave it
`unknown` or `semantic_proposal`, but cannot become final promotion
evidence.

## 4. Normalization Laws

### 4.1 General law

Normalization is structured and deterministic:

```text
maps sorted by key
arrays preserve declared semantic order
sets converted to sorted unique arrays
booleans explicit, never omitted as implicit false
nil-capable enum values rendered as "none"
numbers use one canonical finite representation
unknown policy-affecting key rejects epoch construction
host service handles and functions never enter the digest
```

The digest uses the project's canonical structured digest implementation. A
string assembled ad hoc from selected values is forbidden.

### 4.2 Policy parameter map

At minimum:

```lua
policy_parameters = {
  movement_threshold = number,
  allow_control_fallback = boolean,
}
```

Any future option that changes candidate inclusion, ranking, tie resolution or
readiness interpretation must be added here before it can affect production.

### 4.3 Current ablation vector

```lua
ablation_vector = {
  relation_consumer = boolean,
  structure_consumer = boolean,
  choice_consumer = boolean,
  plan_completion_consumer = boolean,
  plan_delivery_consumer = boolean,
  repository_review = boolean,
  repository_effect = boolean,
  repository_reconcile = boolean,
  repository_delivery = boolean,
}
```

The current option aliases map exactly:

| Runtime option | Canonical key |
|---|---|
| `ablate_relation_consumer` | `relation_consumer` |
| `ablate_structure_consumer` | `structure_consumer` |
| `ablate_choice_consumer` | `choice_consumer` |
| `ablate_plan_completion_consumer` | `plan_completion_consumer` |
| `ablate_plan_delivery_consumer` | `plan_delivery_consumer` |
| `ablate_repository_review` | `repository_review` |
| `ablate_repository_effect` | `repository_effect` |
| `ablate_repository_reconcile` | `repository_reconcile` |
| `ablate_repository_delivery` | `repository_delivery` |

An unknown `ablate_*` option is an instrument error until this registry is
amended. It cannot be ignored and called an unablated life.

Observer enable/disable is not placed in this vector. It changes
`evidence_epoch_id`, while a routing-consumer ablation changes both ids.

## 5. Current Epoch Classification

| Current life | Configured/observed owner | Pressure/routing | Action protocol | Epoch reading | Promotion use |
|---|---|---|---|---|---|
| Default `shadow` | legacy/legacy | binary Tree observes | none | historical comparison | control only |
| Explicit `tree`, policy omitted | tree/tree | binary/vibed | none | binary Tree authority | control only for qualified promotion |
| CLI Plan/Build | tree/tree | qualified/class order | action plan v0 | narrow product epoch with relation consumer ablated | physical product evidence, not full-Tree closure |
| Full qualified diagnostic | tree/tree | qualified/class order | action plan v0 | candidate epoch | mechanically creditable per route; final use requires corpus decision |
| QA M4 grown transaction | tree, then harness routes | qualified plus explicit helper sequence | repository action plus manual QA transaction | Tree epoch with a later authority-taint boundary | QA physical/safety evidence; tainted routes cannot close Tree |

This table does not call the full qualified diagnostic epoch promoted. It only
makes its evidence classifiable.

## 6. Route Evidence Chain

### 6.1 Stable route identity

One attempted movement receives:

```lua
{
  kind = "route_evidence_identity",
  protocol_version = "route-evidence.v0",
  route_evidence_id = "sha256:" .. hex,
  evidence_epoch_id = string,
  physics_epoch_id = string,
  packet_id = string,
  lineage_id = string,
  generation = integer,
  from = glyph,
  to = glyph,
  edge_id = "E01" .. "E22",
  route_authority = "legacy_control" | "tree" | "harness_override",
  authority_basis_ref = string,
  derivation_ref = string | nil,
  pressure_snapshot_ref = string | nil,
  selected_action_plan_id = string | nil,
}
```

The id is derived from immutable identity fields. A route object is not mutated
into a new identity at commit or arrival.

Authority basis law:

| Route authority | Required basis |
|---|---|
| `tree` | Derivation and pressure snapshot refs |
| `legacy_control` | Legacy decision ref |
| `harness_override` | Explicit harness transition request ref |

Missing the required basis makes the route unclassified, never eligible.

### 6.2 Phase records

| Phase | Required evidence | Physical meaning | Promotion meaning |
|---|---|---|---|
| Candidate | Candidate audit and derivation ref | Neighbor considered | None |
| Selected | Selected candidate and exact eligibility record | Policy chose target | Potential credit only |
| Committed | Packet transition event ref | Position changed | Still no closure |
| Executed | Destination tick/effect ref | Organ completed its tick | Eligible closure credit may be written |
| Failed | Typed destination failure ref | Attempt reached effect boundary and failed | No closure credit |
| Pending at host ceiling | Commit ref, no destination tick | Route exists but organ did not run | No closure credit |

Every phase names the same `route_evidence_id`. A mismatched id or epoch
is an instrument error.

### 6.3 Selection eligibility record

```lua
{
  kind = "edge_credit_selection_eligibility",
  protocol_version = "edge-credit.v0",
  eligibility_ref = string,
  route_evidence_id = string,
  physics_epoch_id = string,
  evidence_epoch_id = string,
  status = "eligible" | "ineligible",
  reasons = string[],
  basis_refs = string[],
  policy_rule_ref = string,
  policy_rule_status = "document_decision",
  evaluation_truth_status = "runtime_confirmed",
}
```

This record is immutable. There is no implicit eligible default. Missing
status is unclassified and blocks promotion reporting.

```text
eligible   -> reasons is empty, basis_refs and policy_rule_ref resolve
ineligible -> reasons is non-empty, basis_refs and policy_rule_ref resolve
```

### 6.4 Final execution credit decision

A successful arrival creates a separate derived decision. It never edits the
selection record:

```lua
{
  kind = "edge_credit_decision",
  protocol_version = "edge-credit.v0",
  credit_decision_ref = string,
  route_evidence_id = string,
  selection_eligibility_ref = string,
  commit_ref = string,
  arrival_ref = string,
  status = "credited" | "rejected",
  reasons = string[],
  basis_refs = string[],
  event_truth_status = "runtime_confirmed",
}
```

`credited` requires an eligible selection record plus a valid matching
commit and arrival chain. A later mismatch writes `rejected`; it cannot
rewrite the earlier observation.

```text
credited -> reasons is empty
rejected -> reasons is non-empty
```

## 7. Eligibility Derivation

### 7.1 Required conjunction

A route is eligible only when all rows are true:

| Gate | Required fact |
|---|---|
| Authority | Route authority is `tree` |
| Authority continuity | No earlier committed route created authority taint |
| Epoch | Route refs exactly one valid evidence epoch |
| Policy | Qualified policy produced the selected candidate |
| Candidate | Selected candidate has `promotion_eligible=true` |
| Witness | No fixture-only or unqualified witness participated |
| Action | Exact action protocol is valid when the witness requires an action |
| Selection | No canonical control fallback or tie-only claim |
| Ablation | No active routing-consumer ablation in the target full-Tree epoch |
| Provenance | Derivation, snapshot, readiness and action refs resolve |
| Commit | Commit names the same route evidence id |
| Arrival | Destination tick/effect names the same route evidence id |
| Instrument | No epoch or ledger error exists for the life |

For a deliberately narrow authority claim, an explicit later promotion record
may name a nonzero canonical ablation vector. That creates a different target
epoch and a narrower declared surface. It cannot count as full-Tree closure.

### 7.2 Closed initial reason vocabulary

| Reason | Trigger |
|---|---|
| `non_tree_authority` | Legacy or shadow movement |
| `harness_override` | Test/manual route committed movement |
| `authority_tainted` | An earlier route broke configured authority continuity |
| `binary_policy_control` | Binary Tree cannot qualify the qualified epoch |
| `candidate_unqualified` | Candidate writer returned false |
| `fixture_witness` | Any selected witness came from a fixture |
| `consumer_ablation_active` | Target full-Tree epoch has a routing consumer removed |
| `control_fallback` | Canonical fallback resolved ambiguity/no qualified need |
| `tie_only_selection` | Canonical order was the only winner |
| `missing_action_contract` | Exact action was required but absent/invalid |
| `unresolved_source_ref` | Witness/readiness/action ref cannot resolve |
| `epoch_mismatch` | Route phases disagree on epoch |
| `route_identity_mismatch` | Route phases disagree on route id |
| `instrumentation_error` | Ledger could not classify the route |

New reason strings require a TABLE amendment or a versioned extension. Free
prose may accompany a reason but cannot replace it.

### 7.3 Monotonicity

```text
eligible selected route
  keeps its immutable selection record
  receives credited only after matching commit and successful arrival
  receives a new rejected decision on later evidence failure

ineligible selected route
  keeps its immutable ineligible record
  can never receive credited at commit, arrival, merge or report time

unclassified route
  remains physical evidence
  cannot receive promotion credit

first route whose authority differs from configured_movement_owner
  is ineligible
  creates an append-only authority-taint observation
  makes every later route in that life ineligible
  does not rewrite credit decisions for causally earlier routes
```

This prevents post-hoc laundering by a successful destination effect.

## 8. Dual Edge Ledger

### 8.1 Direction record

```lua
{
  direction = "glyph->glyph",
  legal = boolean,

  physical = {
    candidate_count = integer,
    selected_count = integer,
    committed_count = integer,
    executed_count = integer,
    failed_count = integer,
    pending_at_host_ceiling_count = integer,
    derivation_refs = string[],
    committed_refs = string[],
    executed_refs = string[],
    failure_refs = string[],
  },

  promotion = {
    eligible_selected_count = integer,
    eligible_committed_count = integer,
    eligible_executed_count = integer,
    ineligible_executed_count = integer,
    unclassified_executed_count = integer,
    eligible_derivation_refs = string[],
    eligible_committed_refs = string[],
    eligible_executed_refs = string[],
    credit_decision_refs = string[],
    rejected_reason_counts = map<string, integer>,
    rejected_route_refs = string[],
  },

  physical_status = "untested" | "selected" | "committed"
                  | "executed" | "failed",
  promotion_status = "unqualified" | "eligible_executed",
}
```

Ambiguous root fields such as one bare `executed_count` or `coverage` are
not authoritative in v3. Compatibility projections may render them only with
an explicit `physical_*` name.

The status fields are derived summaries, never counter owners:

```text
physical precedence:
  executed > failed > committed > selected > untested

promotion:
  eligible_executed iff eligible_executed_count > 0
  otherwise unqualified
```

### 8.2 Counter invariants

```text
promotion.eligible_executed_count <= physical.executed_count
promotion.eligible_committed_count <= physical.committed_count
promotion.eligible_executed refs are a subset of physical.executed refs
failed and pending records never enter eligible_executed
ineligible and unclassified executions remain visible
one route_evidence_id contributes at most once to each phase
one arrival ref contributes to exactly one route_evidence_id
```

### 8.3 Closure law

For one direction:

```text
physical green
  iff physical.executed_count > 0

promotion green
  iff promotion.eligible_executed_count > 0
     and unclassified_executed_count == 0 for the cited route
     and the corpus epoch/provenance gates are green
```

The full Tree remains closed only by promotion-green directions, never by the
physical status alone.

## 9. Writer And Reader Matrix

| Record | Sole writer | First reader | Later reader | Packet mutation |
|---|---|---|---|---:|
| Resolved authority epoch | Runner birth resolver | Edge ledger constructor | Route evidence/corpus renderer | none |
| Pressure policy/version facts | Pressure dispatcher result | Epoch resolver | Corpus audit | none |
| Candidate eligibility | Composition policy | Router decision projection | Edge-credit evaluator | none |
| Route evidence identity | Router/runner at derivation boundary | Commit recorder | Arrival/failure recorder | none beyond ordinary route |
| Authority-taint observation | Edge-credit evaluator over ordered committed routes | Later route evaluator | Corpus audit | none |
| Commit ref | Packet transition writer | Edge ledger | Corpus | ordinary movement only |
| Arrival ref | Runner after completed destination tick | Edge ledger | Corpus | none |
| Selection eligibility | Edge-credit evaluator at derivation | Commit/arrival evaluator | Edge ledger | none |
| Final credit decision | Edge-credit evaluator after arrival | Edge ledger | Promotion report | none |
| Epoch bucket | Edge ledger | Merge validator | Corpus assembler | none |
| Observer ablation pair | Deterministic corpus harness | Promotion gate G7 | Promotion record | none |
| Final promotion decision | Documentation process | Default-authority commit procedure | Release/runtime operators | separate commit |

The runner derives the epoch from resolved modules and normalized options. A
caller may supply an expected epoch id for assertion, but may not supply the
record as truth.

## 10. Merge And Corpus Law

### 10.1 Raw edge-stats merge

| Target/source relation | Result |
|---|---|
| Same `edge-stats.v3` and same `evidence_epoch_id` | Merge |
| Same physics, different observer mode | Reject raw merge; retain separate paired buckets |
| Different pressure policy/version | Reject |
| Different routing/composition policy | Reject |
| Different policy parameters | Reject |
| Different ablation vector | Reject |
| Different topology/surface/registry version | Reject |
| Missing epoch record or id | Reject |
| v2 plus v3 | Reject |
| v2 plus v2 | Existing archaeology only, never new promotion closure |
| Unknown eligibility reason/schema | Reject promotion merge |

A rejected merge leaves the target byte-for-byte unchanged.

### 10.2 Corpus bucketing

One corpus may contain many buckets:

```lua
{
  kind = "edge_evidence_corpus",
  protocol_version = "edge-evidence-corpus.v1",
  buckets = {
    [evidence_epoch_id] = edge_stats_v3,
  },
  observer_pairs = {...},
  implementation_provenance = {...},
}
```

It never exposes a summed closure across bucket ids.

### 10.3 Observer ablation

Observer-on and observer-off lives must have:

```text
same physics_epoch_id
different evidence_epoch_id
equal walk/routes/budget/loss/revisions/effects/finality
instrumentation-only trace and metric delta
```

The ablation report links both buckets. v0 does not fold them into one raw
ledger. A promotion campaign chooses one canonical observer configuration and
uses the other only as G7 evidence.

### 10.4 Promotion assembly

Final closure assembly requires:

```text
one declared target physics epoch
one canonical evidence epoch
one verified implementation revision
all required L0 cases under that epoch
required L1 records under that epoch where applicable
zero edge-stats errors
zero unclassified cited executions
38/38 eligible executed directions, unless authority surface was revised
```

Selecting the target epoch is a `document_decision`. The ledger only proves
what occurred inside it.

## 11. Instrument Failure Law

| Failure | Packet result | Instrument result | Promotion result |
|---|---|---|---|
| Epoch cannot be derived at birth | Life may run if body config is otherwise valid | Invalid ledger, loud result error | Blocked |
| Route loses eligibility fields | Route may execute | Unclassified physical evidence | Blocked |
| Commit/arrival ids disagree | Packet physics retained | Instrument error | Blocked |
| Merge ids disagree | No Packet involved | Hard merge rejection, target unchanged | Blocked |
| Unknown ablation option | Life may run only as non-promotion diagnostic | Epoch invalid for promotion | Blocked |
| Observer mutates physics | Ordinary test exposes delta | G7 red | Blocked |
| Ledger code throws malformed Lua error | Harness fails loudly | No typed Packet death | Blocked |

The instrument must not hide a body defect. Conversely, an instrument defect
must not be narrated as a beautiful Packet death.

## 12. Compatibility And Migration

`edge-stats.v2` cannot be upgraded to v3 evidence because it did not store:

```text
exact pressure/routing epoch
normalized ablation vector
observer evidence epoch
route-level eligibility chain
separate physical and promotion execution
```

Migration law:

| Existing artifact | Allowed use |
|---|---|
| v2 unit/behavior tests | Regression archaeology |
| v2 6/1/15 and later matrices | Historical diagnosis |
| v2 execution ref | Physical historical claim only |
| v2 merged corpus | Never promotion input |
| Fresh v3 rerun | New promotion evidence |

No inference script may stamp old v2 routes eligible from current code or
documentation.

## 13. Predicted Implementation Boundaries

The CRYSTALL layer should allocate changes in this order:

```text
I01 authority_epoch pure resolver and verifier
I02 normalized policy-parameter and ablation registry
I03 runner result receives one immutable epoch record
I04 router retains decision-level eligibility and exact reasons
I05 commit/arrival chain receives route_evidence_id and epoch refs
I06 edge-stats.v3 dual counters and refs
I07 exact merge rejection and immutable-on-failure test
I08 result summary exposes physical and promotion views separately
I09 corpus bucket/closure assembler
I10 regenerate current qualified edge report
```

No pressure writer, route ranking or organ effect should change in I01-I10.

## 14. Permanent Control Matrix

### 14.1 Epoch identity controls

| ID | Pair/change | Required result |
|---|---|---|
| AE01 | `tree` binary versus `tree` qualified | Different physics and evidence ids |
| AE02 | Same resolved configuration, map insertion order changed | Same ids |
| AE03 | Work mode Plan versus Build | Same ids |
| AE04 | Prompt/model/budget changed | Same ids |
| AE05 | One routing consumer ablated | Both ids change |
| AE06 | Legacy observer on versus off | Physics id same, evidence id changes |
| AE07 | Threshold or fallback changed | Both ids change |
| AE08 | Unknown policy-affecting option | Epoch construction fails closed for promotion |
| AE09 | Topology/registry/surface version changed | Both ids change |
| AE10 | Caller lies about expected id | Loud assertion failure, no Packet death |

### 14.2 Edge-credit controls

| ID | Grown state | Required result |
|---|---|---|
| EC01 | Eligible qualified route executes | Physical and eligible-executed increment |
| EC02 | Candidate says ineligible, route executes | Physical increments; eligible-executed stays zero |
| EC03 | Harness override executes | Physical increments; reason `harness_override` |
| EC04 | Binary Tree route executes | Physical increments; qualified promotion zero |
| EC05 | Route commits at host ceiling | Committed increments; no executed credit |
| EC06 | Destination returns typed failure | Failed increments; no executed credit |
| EC07 | Arrival omits eligibility chain | Unclassified increments; summary blocked |
| EC08 | Ineligible route followed by successful effect | Remains ineligible |
| EC09 | Same arrival replayed | Rejected; counters unchanged |
| EC10 | Candidate/commit/arrival refs mismatch | Instrument error; physical trace retained |
| EC11 | Tree route executes after harness override | Physical increments; reason `authority_tainted`; no eligible credit |
| EC12 | Eligible Tree route precedes later harness override | Earlier immutable credit remains; later route cannot borrow it |

### 14.3 Merge controls

| ID | Merge | Required result |
|---|---|---|
| EM01 | Same evidence epoch | Exact sum |
| EM02 | Binary plus qualified | Reject; target unchanged |
| EM03 | Canonical plus ablated | Reject; target unchanged |
| EM04 | Observer on plus off | Reject raw merge; pair remains constructible |
| EM05 | v2 plus v3 | Reject |
| EM06 | Same ids but altered epoch payload | Reject digest/payload mismatch |
| EM07 | Unknown eligibility reason | Reject promotion assembly |
| EM08 | Different work modes, same epoch | Merge allowed; case labels retained outside epoch |
| EM09 | Different verified implementation revisions | Final closure assembly rejects |
| EM10 | Partial source merge failure | No partial target mutation |

### 14.4 Masslessness controls

With the instrument disabled and enabled:

```text
Packet walk equal
selected routes equal
budget and loss equal
substrate/tool calls equal
field and revision vector equal
repository and QA effects equal
manifest/death/corpse equal
only runner result/instrumentation trace may differ
```

## 15. False-Green Matrix

| False claim | Rejecting assertion |
|---|---|
| `tree` flag proves one physics | AE01 |
| A successful effect launders an ineligible route | EC02 + EC08 |
| Harness-grown QA route proves automatic Tree routing | EC03 |
| A Tree label after harness intervention restores clean authority | EC11 + EC12 |
| Binary execution closes qualified direction | EC04 + EM02 |
| Committed means executed | EC05 |
| Typed failure counts as arrival success | EC06 |
| Missing eligibility means probably eligible | EC07 |
| Observer is massless, so its ledgers may be mixed | AE06 + EM04 |
| An ablation is only a test label | AE05 + EM03 |
| Old v2 refs can be restamped | EM05 plus migration law |
| Work mode split prevents one full corpus | AE03 + EM08 |
| Runtime says eligible, therefore authority is promoted | Section 10.4 document-decision gate |

## 16. Explicit Deferrals

This table does not decide:

```text
DISSOLVE witness/action semantics
CYCLE witness/action semantics
automatic QA pressure/action semantics
whether all declared 38 directions remain lawful under newer phase laws
numeric pressure calibration
live model quality
release policy
default router authority
cross-commit behavioral equivalence
general distributed corpus signing
```

Those features will use this instrument; they are not prerequisites for its
schema.

## 17. TABLE Acceptance

This table may feed CRYSTALL when all statements are accepted:

```text
authority is an immutable resolved record, not router_mode alone
physics and evidence epoch identities are distinct
route eligibility is carried through derivation, commit and arrival
authority intervention creates monotonic forward taint without rewriting past
physical execution is never erased by promotion ineligibility
ineligible execution can never close a direction
edge-stats.v2 remains archaeology
edge-stats.v3 direct merge requires exact evidence epoch
observer ablation uses paired buckets, not silent summation
instrument failure remains outside Packet death physics
final promotion remains a separate document decision
no routing semantics change is hidden in this measuring treatment
```

Current TABLE disposition:

```text
authority_epoch.v0: specified
edge-credit.v0: specified
edge-stats.v3: specified at contract level
implementation: not authorized by TABLE alone
CRYSTALL: ready for construction
router promotion: blocked
```

## Amendment A1: Live Policy Versus Observer Policy

Status:

```text
layer: TABLE AMENDMENT
date: 2026-08-01
found during: CRYSTALL construction
reason:
  the original schema placed Tree pressure/ablation inside physics even when
  router_mode=shadow and Tree was only a massless observer
supersedes:
  section 3.1 flat physics policy placement
  section 3.3 reading of router_mode/pressure/ablation as always-live physics
  AE05 without mode qualification
retains:
  two epoch ids
  exact raw merge
  dual edge credit
  all promotion and taint laws
```

### A1.1 Corrected causal split

The epoch first resolves one Tree policy descriptor, then places it according
to actual authority:

```lua
tree_policy_descriptor = {
  pressure_policy = string,
  pressure_derivation_version = string,
  pressure_calibration_status = string,
  routing_policy = string,
  routing_policy_status = string,
  policy_parameters = normalized_map,
  witness_protocol = string,
  witness_gate_version = string,
  action_protocol = string,
  ablation_vector = normalized_map,
}
```

Assignment matrix:

| Router mode | Live policy in physics | Observer policy in instrumentation |
|---|---|---|
| `legacy` | `legacy.control.v0` | none |
| `shadow` | `legacy.control.v0` | resolved Tree policy descriptor |
| `tree` | resolved Tree policy descriptor | legacy observer when enabled, otherwise none |

Therefore:

```text
legacy and shadow may share one physics_epoch_id
legacy and shadow must have different evidence_epoch_id

changing Tree pressure/threshold/ablation under shadow
  changes evidence_epoch_id only

changing Tree pressure/threshold/ablation under tree
  changes physics_epoch_id and evidence_epoch_id
```

### A1.2 Corrected schema

The authoritative shape for CRYSTALL is:

```lua
{
  kind = "authority_epoch",
  protocol_version = "authority_epoch.v0",

  configured = {
    router_mode = "legacy" | "shadow" | "tree",
    configured_movement_owner = "legacy_control" | "tree",
  },

  physics = {
    topology_version = string,
    authority_surface_id = string,
    operator_registry_version = string,
    movement_owner = "legacy_control" | "tree",
    live_policy = legacy_policy_descriptor | tree_policy_descriptor,
  },

  instrumentation = {
    router_mode = "legacy" | "shadow" | "tree",
    observer_mode = "none" | "tree_shadow" | "legacy_shadow",
    observer_enabled = boolean,
    observer_policy = "none"
                    | legacy_policy_descriptor
                    | tree_policy_descriptor,
    observer_protocol = string,
    edge_stats_protocol = "edge-stats.v3",
  },

  physics_epoch_id = digest(normalize(physics)),
  evidence_epoch_id = digest(normalize({
    physics_epoch_id = physics_epoch_id,
    configured = configured,
    instrumentation = instrumentation,
  })),
  event_truth_status = "runtime_confirmed",
}
```

`router_mode` remains recorded and merge-significant through the evidence
identity. It does not pretend that enabling a massless observer changed live
Packet movement.

`harness_override` is route-level authority evidence, never a configured clean
movement owner. Its first committed route taints later promotion credit without
manufacturing a new physics epoch.

### A1.3 Effective options, not dead declarations

Only effective policy options enter a descriptor:

| Situation | Epoch treatment |
|---|---|
| Qualified Tree options under `tree` | Live physics |
| Qualified Tree options under `shadow` | Observer instrumentation |
| Qualified Tree options under `legacy` | Unused-option diagnostic; no id change |
| `legacy_shadow` under `tree` | Instrumentation only |
| `legacy_shadow` outside `tree` | Unused-option diagnostic |

An unused option is retained in invocation provenance so the caller can see
that it had no effect. It is forbidden from manufacturing a new epoch.

### A1.4 Revised permanent controls

| ID | Pair/change | Required result |
|---|---|---|
| AE05-T | Tree authority, one routing consumer ablated | Both ids change |
| AE05-S | Shadow mode, one Tree observer consumer ablated | Physics id same, evidence id changes |
| AE05-L | Legacy mode, unused Tree ablation option changed | Both ids same; unused-option diagnostic changes |
| AE06-A | Legacy versus shadow with same live legacy policy | Physics id same, evidence id changes |
| AE06-B | Tree legacy observer on versus off | Physics id same, evidence id changes |

### A1.5 Amendment acceptance

```text
observer policy never enters live physics merely because options mention it
effective Tree policy occupies exactly one role: live authority or observer
shadow ablation cannot falsify a physics-epoch change
tree ablation remains a real physics-epoch change
unused options remain visible but cannot create identity
all original merge and promotion-credit restrictions remain in force
```

## Amendment A2: Observer Trace and Corpse Equality

Status:

```text
layer: TABLE AMENDMENT
date: 2026-08-01
found during: CRYSTALL construction
reason:
  the original masslessness vector required corpse equality while allowing
  observer trace delta, but corpse.v0 hashes trace_tail and therefore turns
  a lawful observer event into a raw corpse_hash delta
supersedes:
  section 14.4 raw reading of "manifest/death/corpse equal"
retains:
  exact body equality for the new authority instrument
  observer masslessness as a falsifiable requirement
```

Two ablations have different comparison laws because the old router observer
already writes named instrumentation events into the Packet trace:

| Ablation | Required equality |
|---|---|
| New authority instrument `off` versus `v3` | Exact Packet and raw corpse equality; all new records live outside Packet trace |
| Existing Tree/legacy observer disabled versus enabled | Semantic body/corpse equality after removing only trace events explicitly referenced by that observer |

The observer comparator must derive the removable set from observer records;
it may not filter by payload kind alone:

```text
allowed refs = observer decision trace refs
             + pressure snapshot refs named by those decisions

every allowed ref must resolve to the expected observer and live-authority pair
every other Packet trace event remains comparison-significant
corpse_hash itself is excluded only because it commits to the filtered trace_tail
manifest, death, residue, evidence and the filtered corpse payload remain equal
```

This is not permission for arbitrary semantic comparison. An unexplained trace
or corpse delta makes the pair red. A future observer that writes no Packet
trace receives the stricter exact-equality law automatically.

### A2.1 Revised masslessness controls

```text
MI01-MI05 authority instrument off/on -> exact Packet and corpse equality
MI06 existing observer pair -> only explicitly referenced observer events and
                               their derived corpse hash may differ
all repository, QA, budget, loss, field, revision, route and terminal facts
remain exact in both classes
```

## Amendment A3: Corpus Life Identity And Replay Rejection

Status:

```text
layer: TABLE AMENDMENT
date: 2026-08-01
found during: CRYSTALL construction
reason:
  Packet ids are process-local counters and may repeat after Lua restart;
  exact-epoch merge did not explicitly reject the same life twice
supersedes:
  section 10 corpus identity underspecification
  EM01 reading that permits overlapping life sources
retains:
  work/task/model provenance outside epoch identity
  exact same-evidence-epoch merge for distinct lives
```

Every corpus-bound life receives runner-only provenance:

```lua
{
  case_id = string | nil,
  evidence_run_id = non_empty_string,
}
```

`evidence_run_id` is supplied by the experiment/corpus harness. It is not a
Packet field, is not randomly invented by the body and does not enter either
epoch id. A diagnostic life may omit it, but that life cannot enter a corpus.

Merge and corpus law:

```text
one evidence_run_id names at most one life in one corpus
every corpus route_evidence_id seed includes the derived life_id
raw edge-stats merge requires disjoint life_id sets
byte-identical overlap still rejects rather than double-counting
rejected overlap leaves the target digest unchanged
repeated experiment -> new explicit evidence_run_id
```

Permanent additions:

| ID | Control | Required result |
|---|---|---|
| EM11 | Merge the same life twice | Reject; target unchanged |
| CO10 | Missing or reused evidence_run_id | Reject; corpus unchanged |

## Amendment A4: Corpus-Bound Source Evidence

Status:

```text
layer: TABLE AMENDMENT
date: 2026-08-01
found during: CRYSTALL construction
reason:
  v3 route records named Packet trace/tick refs, but a merged corpus had no
  contract for resolving those refs after the source runner life ended
supersedes:
  section 9 reading that an id alone is a durable later-reader payload
retains:
  body writers as sole owners of physical facts
  instrument masslessness
```

`edge-stats.v3` transports immutable evidence copies for every source ref used
by its route and credit records:

```text
body event remains the fact writer
runner captures the completed event only after its authoritative write
edge ledger deep-copies and digests the event as source evidence
corpus resolves refs only through that immutable store
no Packet table, provider handle, grant, callback or other live identity crosses
```

Source identity binds:

```text
life_id + source kind + original source id + exact payload digest
```

Within one life, replaying the exact same source payload is idempotent and
reuses one source-evidence ref. The same source id with changed payload is an
instrument error. A missing required source keeps physical evidence visible but
blocks classification/closure. Raw merge validates the complete source store
before mutating counters.

Observer-pair evidence has a separate named writer: a massless post-life
projector receives the finished Packet, runner result and corpse when present,
then emits one immutable plain-data `edge_life_projection.v0`. It whitelists the
masslessness vector; it does not archive the live Packet.

```text
exact projection:
  all named body components, full trace and raw corpse identity

observer-neutral projection:
  same components, removing only trace refs named and verified by the observer,
  plus the raw corpse hash derived from that trace_tail
```

The corpus stores this projection per life. Observer-pair comparison reads only
the two stored projections. Missing projection, unverified removed ref or live
value in a projection blocks the pair and closure.

The transport is host-bounded, but never charged to Packet budget/loss:

```text
source-record count bound
single source byte bound
aggregate source bytes per life
post-life projection bytes
instrument error-record bound with one reserved overflow aggregate
```

Effective per-life bounds and their calibration status enter instrumentation
and therefore `evidence_epoch_id`, never `physics_epoch_id`. Exceeding a source
bound records the physical phase plus an invalid-ledger error when structurally
possible; it cannot kill, redirect or charge the Packet. Exceeding projection
or corpus bounds rejects archival, leaving the corpus unchanged.

## Amendment A5: Observer Family Scope At Harness Failure

Status:

```text
layer: TABLE AMENDMENT
date: 2026-08-01
found during: CRYSTALL construction
reason:
  P12 said every deterministic family receives a life observer pair, while
  P13 intentionally aborts at the harness boundary and may produce no completed
  life/corpse projection
```

P12 covers completed-life families P01-P11, including P06a and P06b. P13 keeps
its own required matched valid/invalid harness control and implementation
ablation, but no synthetic life is invented solely to fit the observer-pair
schema. A future runner that can expose a complete immutable failed-run
projection may extend P12 through a versioned case manifest.

## Amendment A6: Packet-Local Trace Identity And Neutral Host Time

Status:

```text
layer: TABLE AMENDMENT
date: 2026-08-01
found during: I06 real observer-pair falsification
source:
  docs/00_chaos/authority_observer_reference_cascade_i06_notes_2026-08-01.md
supersedes:
  Amendment A2 reading that removing observer events alone is sufficient
retains:
  exact comparison for the new external authority instrument
  exact named-ref verification before observer removal
  every semantic/body delta remains comparison-significant
```

### A6.1 Trace identity ownership

Event ids are unique inside one Packet. Cross-life archival uniqueness is
provided by the existing A3/A4 source identity, not by a process-global Lua
counter.

| Lane | Id form | Writer | Reader |
|---|---|---|---|
| body | `event-<packet-local ordinal>` | Packet append path | all body/corpus ref readers |
| observer | `observer-event-<packet-local observer ordinal>` | named router observer only | post-life projector |

Each ordinal is derived from the append-only trace already owned by the Packet.
There is no second counter or cache. Observer-lane insertion cannot renumber a
body-lane event.

### A6.2 Closed observer-neutral normalization

After observer refs are verified and removed, the neutral projection may
normalize only:

```text
trace-event wall time at packet_trace[*].time
death.time
event wall time inside residue.trace_tail
the same residue trace-tail wall time when embedded in corpse.residue
the same trace-tail wall time inside a death/manifest event residue payload
corpse trace-tail event wall time
corpse.frozen_at
corpse.corpse_hash
```

The normalized value for host time is the fixed marker
`host_wall_time_excluded.v0`. `corpse_hash` is absent from every neutral corpse
because it commits to the raw tail representation. Exact components retain all
raw values.

No payload-kind filter and no generic key-name filter exists. In particular,
`metadata.time`, tool output timestamps and semantic content remain exact.

I08 precision: `corpse.v0` embeds the Packet residue as well as maintaining its
own bounded `trace_tail`. The embedded `corpse.residue.trace_tail[*].time` is
the same A6 host-wall-time fact, not a second semantic clock. It receives the
same fixed marker in the observer-neutral projection; exact corpse components
retain the raw value. A `death` or `manifest` trace event may itself carry that
same residue snapshot in `payload.residue`; its bounded nested trace times are
the same closed fact. Only these two event kinds and this exact structural path
are normalized.

### A6.3 Revised pair acceptance

```text
new instrument off/on:
  exact components and raw corpse equal

existing observer off/on:
  same physics epoch
  same explicit Packet/work/FLOW prerequisites
  runner mode projects to live authority (tree or legacy_control), not observer arrangement
  observer body refs verified
  observer-lane events removed
  closed host-time paths normalized
  neutral components equal
```

Permanent controls:

| ID | Control | Required result |
|---|---|---|
| LP10 | Independently grown Tree observer off/on pair with corpse | neutral equality |
| LP11 | Observer append followed by body append | body id sequence unchanged |
| LP12 | `metadata.time` differs | neutral pair remains red |

## Amendment A7: Target Evidence Versus Observer-Control Evidence

Status:

```text
layer: TABLE AMENDMENT
date: 2026-08-01
found during: I06.4 corpus assembly
reason:
  the first stateless manifest fixture assigned one evidence epoch to both
  sides of an observer pair, although observer configuration is part of
  evidence identity by D09 and section 10.3
```

The target coordinate of a case has two distinct laws:

```text
primary life and ordinary control life:
  target evidence_epoch_id
  target physics_epoch_id
  target implementation revision

observer-control life:
  its own evidence_epoch_id
  target physics_epoch_id
  target implementation revision
```

Every observer pair cited by a target case contains at least one life from the
target evidence epoch. The other life normally belongs to a different evidence
epoch because its observer configuration differs. Requiring one evidence id
for both sides makes only a synthetic ablation fixture green and contradicts
the raw no-merge law.

For P12, the target evidence epoch is the unique epoch common to all twelve
family pairs. No caller-authored target field or verdict is accepted by the
case evaluator. An absent or ambiguous intersection rejects before corpus
mutation.

A pair whose physics epoch differs is retained as `status=red`, not admitted as
an ablation success. A malformed life/work identity still rejects the pair
transaction entirely.

## Amendment A8: Observer Lane Has Zero Retention Mass

Status:

```text
layer: TABLE AMENDMENT
date: 2026-08-01
found during: I08 MI06 full masslessness campaign
reason:
  observer ids did not shift body ids, but observer events still occupied
  slots in bounded corpse trace_tail and displaced retained body history
```

The Packet trace remains append-only and retains both lanes. Every stored
observer event is tagged `identity_lane=observer_instrumentation`; the
`observer-event-*` identity plus the closed observer payload family remains a
compatibility reader for older in-memory records.

Bounded body-retention views count only body-lane events:

```text
corpse.trace_tail
budget_exhaustion residue.trace_tail
packet_memory capsule.trace_tail
```

Observer events are evidence for the runner-side observer/corpus channel. They
cannot consume body retention capacity, enter graves through displacement, or
change what a descendant inherits. The bound remains exact: a body tail of
size N contains at most N records; observer records are not appended outside
the bound.

This does not authorize filtering by payload wording. The Packet append path
owns the lane tag. Post-life projection retains its exact named-ref verifier
and its compatibility removal for archaeological corpses that may still
contain observer records.

Permanent controls:

| ID | Control | Required result |
|---|---|---|
| MI06a | Long completed observer off/on pair | same retained corpse body tail |
| MI06b | Budget-dead observer off/on pair | same residue body tail |
| MI06c | Packet-memory capsules from MI06b | exact equality |
