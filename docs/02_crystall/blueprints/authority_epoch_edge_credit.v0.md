# Authority Epoch And Eligible Edge Credit Blueprint v0

Status:

```text
layer: CRYSTALL
date: 2026-08-01
chaos:
  docs/00_chaos/full_tree_post_hands_qa_audit_2026-08-01_notes.md
table:
  docs/01_table/yellowprints/authority_epoch_edge_credit_yellowprint.v0.md
  including Amendment A1: Live Policy Versus Observer Policy
  including Amendment A2: Observer Trace And Corpse Equality
  including Amendment A3: Corpus Life Identity And Replay Rejection
  including Amendment A4: Corpus-Bound Source Evidence
  including Amendment A5: Observer Family Scope At Harness Failure
  including Amendment A6: Packet-Local Trace Identity And Neutral Host Time
  including Amendment A7: Target Evidence Versus Observer-Control Evidence
  including Amendment A8: Observer Lane Has Zero Retention Mass
protocols:
  authority_epoch.v0
  authority-instrument-bounds.v0
  route-evidence.v0
  edge-source-evidence.v0
  edge-life-projection.v0
  tree-authority-cases.v0
  edge-case-evidence.v0
  edge-harness-evidence.v0
  authority-target-decision.v0
  edge-credit.v0
  edge-stats.v3
  edge-evidence-corpus.v1
implementation authorization:
  measurement and evidence plumbing only
route target/ranking change: forbidden
pressure witness change: forbidden
organ effect change: forbidden
router default change: forbidden
promotion decision: forbidden
```

This blueprint replaces `edge-stats.v2` only for new evidence. Existing v2
reports and their blueprint remain archaeology and are never restamped into v3.

## 0. Selected Contract

```text
resolved effective configuration
-> one immutable authority epoch
-> one Tree candidate eligibility observation
-> one route evidence identity
-> one commit observation
-> one arrival/failure/pending observation
-> one final edge-credit decision
-> one dual physical/promotion ledger
-> one exact epoch bucket
-> one external promotion decision
```

The instrument has four ownership boundaries:

| Boundary | Owner | Prohibited authority |
|---|---|---|
| Effective policy identity | `runtime/authority_epoch.lua` | No route selection |
| Route/credit causal chain | `runtime/edge_credit.lua` | No Packet mutation |
| Per-life and merge ledger | `runtime/edge_stats_v3.lua` then canonical `runtime/edge_stats.lua` | No corpus promotion |
| Post-life body projection | `runtime/edge_life_projection.lua` | No body mutation or verdict |
| Required case manifest | `runtime/edge_case_manifest.lua` | No claim that a case passed |
| Multi-life corpus/closure | `runtime/edge_corpus.lua` | No default flip |

All records introduced by this blueprint live in the runner result and corpus
artifacts. They do not create Packet trace events. Existing pressure,
derivation, route, observer, tick and effect events remain their body-owned
source refs.

## 1. Safety Refinements From TABLE Amendments

### 1.1 Live policy versus observer policy

The resolved Tree policy occupies exactly one role:

| `router_mode` | Live movement physics | Massless observer |
|---|---|---|
| `legacy` | legacy control | none |
| `shadow` | legacy control | resolved Tree policy |
| `tree` | resolved Tree policy | legacy observer when enabled |

Therefore the implementation computes:

```text
physics_epoch_id  = live movement only
evidence_epoch_id = physics id + configured arrangement + instrumentation
```

Required consequence:

```text
shadow Tree-ablation changes evidence_epoch_id only
tree Tree-ablation changes both ids
legacy unused Tree options change neither id
```

This is not a routing change. It is the exact implementation of observer
masslessness.

### 1.2 Observer trace versus corpse identity

The new v3 instrument is strictly outside Packet trace, so its `off`/`on`
ablation requires exact Packet and raw corpse equality. The pre-existing router
observer is different: it already writes explicitly referenced pressure and
observer events into trace, and `corpse.v0` commits to `trace_tail`.

Its ablation therefore compares a verified semantic projection that removes
only those named observer refs and the derived raw corpse hash. No unreferenced
trace, terminal, residue, repository or QA delta is allowed.

### 1.3 Corpus life identity

Packet ids are process-local and therefore cannot identify experiments across
Lua restarts. Corpus-bound lives use an explicit runner-only
`evidence_run_id`; raw merge rejects every overlapping life id, including an
otherwise identical replay.

### 1.4 Durable source refs

Every route/credit source ref copied into a v3 ledger resolves through an
immutable evidence store. The body event remains the sole fact writer; the
instrument transports a deep-copied digest-bound record and never carries a
live Packet, provider, grant or callback into the corpus.

Whole-life observer comparison uses a separate post-life projection with the
same plain-data boundary. The corpus stores the projection, never the object it
observed.

### 1.5 Harness failure is not a synthetic life

P12 observer pairing covers completed-life P01-P11 families. P13 remains a
matched harness-error control and cannot be filled by inventing a corpse or
post-life projection that runtime did not produce.

## 2. Target Files

### 2.1 New modules

```text
runtime/authority_epoch.lua
  effective policy resolution
  normalization
  authority surface binding
  physics/evidence identity and verification

runtime/edge_credit.lua
  route evidence identity
  immutable selection eligibility
  authority taint
  commit/arrival/failure/pending phase records
  final credit decision

runtime/edge_corpus.lua
  exact evidence-epoch buckets
  observer-pair records
  implementation provenance gate
  physical and promotion closure reports

runtime/edge_life_projection.lua
  post-life plain-data masslessness projection
  exact and observer-neutral digests
  no live identity transport

runtime/edge_case_manifest.lua
  versioned P01-P13 and L1 requirement manifest
  case-evidence shape and reference verification
  no route or promotion authority
```

### 2.2 Staged statistics replacement

```text
runtime/edge_stats_v3.lua
  pure v3 implementation while the runner still defaults to v2
  retain observer and rail role separation
  replace ambiguous edge counters with physical/promotion channels
  exact epoch merge
  sole instrumentation error ledger

runtime/edge_stats.lua
  current v2 implementation until I09
  becomes the canonical v3 facade at I09

runtime/edge_stats_v2.lua
  receives the old implementation at I09
  archaeology/rejection controls only; never a live fallback after I09
```

### 2.3 Modified policy-description modules

```text
runtime/edge_catalog.lua
  versioned authority surface derivation

runtime/pressure.lua
  pure effective pressure descriptor

runtime/qualified_pressure.lua
  export witness/action/gate protocol constants

runtime/tree_router.lua
  pure effective Tree routing descriptor

runtime/router.lua
  export legacy descriptor
  retain decision-level eligibility and reasons

runtime/pressure_composition.lua
  normalized promotion-ineligibility reasons and basis

core/packet.lua
  carry Tree eligibility fields into the route without reconstructing them
  missing/malformed fields cannot block the body transition
  no new instrumentation event type

runtime/tension_runner.lua
  construct epoch and edge-credit state
  orchestrate selection/commit/arrival/failure/pending evidence
  expose v3 result projection
```

### 2.4 Tests

```text
tests/test_authority_epoch.lua
tests/test_edge_credit.lua
tests/test_edge_stats_v3.lua
tests/test_edge_source_evidence.lua
tests/test_edge_life_projection.lua
tests/test_edge_case_manifest.lua
tests/test_edge_corpus.lua
tests/test_authority_instrument_ablation.lua

update:
  tests/test_edge_metric_roles.lua
  tests/test_edge_evidence.lua
  tests/test_tree_instrumentation.lua
  tests/test_qualified_pressure_shadow.lua
  tests/test_post_collapse_plan_life.lua
  tests/run.lua
```

No QA native module, provider, capability, repository hand or organ module is
modified by this treatment.

## 3. Authority Surface Contract

### 3.1 Edge catalog API

```lua
local catalog = require("runtime.edge_catalog")

catalog.protocol_version = "edge-catalog.v0"
catalog.surface_protocol = "operator-tree.authority-surface.v0"

surface, err = catalog.authority_surface()
ok, err = catalog.verify_authority_surface(surface)
```

### 3.2 Surface schema

```lua
{
  kind = "operator_tree_authority_surface",
  protocol_version = "operator-tree.authority-surface.v0",
  topology_version = "processlang.topology.v0",
  catalog_version = "edge-catalog.v0",
  edges = {
    {
      edge_id = "E01" .. "E22",
      left = glyph,
      right = glyph,
      legal_directions = sorted_unique_string_array,
    },
  },
  edge_count = 22,
  legal_direction_count = 38,
  surface_id = "sha256:" .. hex,
  event_truth_status = "runtime_confirmed",
}
```

The digest seed excludes `surface_id` and
`event_truth_status`. It includes every other field.

### 3.3 Verification

For every edge:

```text
left/right resolve through core.topology
left and right are mutually adjacent
each direction names exactly those endpoints
one-way boundary directions remain exactly one-way in the catalog
edge ids and endpoint pairs are unique
direction strings are globally unique
edge_count and legal_direction_count match derived values
surface_id recomputes exactly
```

Topology/catalog disagreement returns:

```lua
{
  class = "instrument_contract",
  code = "authority_surface_mismatch",
  stage = "authority_epoch",
}
```

It does not become a new surface and does not become a Packet death.

## 4. Effective Policy Descriptors

### 4.1 Legacy descriptor

`runtime/router.lua` exports:

```lua
router.legacy_policy = "legacy.control.v0"
router.legacy_policy_status = "historical_control"

descriptor = router.legacy_descriptor()
```

Schema:

```lua
{
  kind = "legacy_policy_descriptor",
  protocol_version = "legacy-policy-descriptor.v0",
  routing_policy = "legacy.control.v0",
  routing_policy_status = "historical_control",
  event_truth_status = "runtime_confirmed",
}
```

### 4.2 Pressure descriptor API

`runtime/pressure.lua` exports:

```lua
descriptor, diagnostics_or_err = pressure.describe(options)
```

Descriptor:

```lua
{
  kind = "pressure_policy_descriptor",
  protocol_version = "pressure-policy-descriptor.v0",
  pressure_policy = "camera_reconciliation"
                  | "sampled"
                  | "qualified_need_v0",
  pressure_derivation_version = "pressure.binary.v0"
                              | "pressure.qualified_need.v0",
  pressure_calibration_status = "vibed_control"
                              | "unmeasured_qualified",
  witness_protocol = "none" | "pressure.witness.v1",
  witness_gate_version = "none" | "object-version-coverage.v0",
  action_protocol = "none" | "pressure.action_plan.v0",
  ablation_vector = normalized_ablation_vector,
  unused_options = sorted_unique_string_array,
  event_truth_status = "runtime_confirmed",
}
```

Current exports added to `runtime/qualified_pressure.lua`:

```lua
qualified.witness_protocol = "pressure.witness.v1"
qualified.witness_gate_version = "object-version-coverage.v0"
qualified.action_protocol = pressure_action.protocol_version
```

Binary policies always emit:

```text
witness_protocol = none
witness_gate_version = none
action_protocol = none
ablation_vector = all false
```

Qualified ablations are effective only when the Tree descriptor is assigned to
live or observer authority. Under `legacy`, supplied Tree-only options are
reported in `unused_options` and do not change identities.

### 4.3 Tree routing descriptor API

`runtime/tree_router.lua` exports:

```lua
descriptor, err = tree_router.describe(pressure_descriptor, tree_options)
```

Schema:

```lua
{
  kind = "tree_policy_descriptor",
  protocol_version = "tree-policy-descriptor.v0",
  pressure = pressure_policy_descriptor_without_unused_options,
  routing_policy = "pressure.binary.v0" | "pressure.class_order.v0",
  routing_policy_status = "vibed_control" | "shadow_treatment",
  policy_parameters = {
    movement_threshold = finite_number,
    allow_control_fallback = boolean,
  },
  event_truth_status = "runtime_confirmed",
}
```

Defaults are materialized:

```text
movement_threshold = 0
allow_control_fallback = false
all nine ablation keys = false
```

No missing key is interpreted differently by two readers.

### 4.4 Current ablation keys

The normalizer accepts exactly:

```lua
{
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

Runtime aliases are the exact TABLE mapping. Any unknown top-level key matching
`^ablate_` returns `unknown_policy_affecting_option` for promotion
instrumentation. The Packet run may continue with an invalid ledger.

### 4.5 Instrument transport bounds

`runtime/authority_epoch.lua` normalizes:

```lua
options.authority_instrument_bounds = {
  max_source_records = positive_integer,
  max_single_source_bytes = positive_integer,
  max_source_bytes_per_life = positive_integer,
  max_projection_bytes = positive_integer,
  max_error_records = positive_integer,
}
```

Omitted values materialize the v0 safety defaults:

```lua
{
  kind = "authority_instrument_bounds",
  protocol_version = "authority-instrument-bounds.v0",
  max_source_records = 4096,
  max_single_source_bytes = 2 * 1024 * 1024,
  max_source_bytes_per_life = 32 * 1024 * 1024,
  max_projection_bytes = 16 * 1024 * 1024,
  max_error_records = 256,
  calibration_status = "unmeasured_safety_control",
}
```

An explicit override keeps the same calibration status until a later
measurement contract says otherwise. Whether equal values came from defaults
or explicit input is a diagnostic outside the epoch; equal effective bounds
remain one evidence identity. Byte counts are the exact lengths of normalized
`core.json.encode` output. Bounds affect evidence retention, so the complete
descriptor enters instrumentation identity; they never enter physics identity
or Packet economics.

## 5. Authority Epoch API

### 5.1 Module

```lua
local epoch = require("runtime.authority_epoch")

epoch.protocol_version = "authority_epoch.v0"

record, diagnostics_or_err = epoch.resolve(options)
ok, err = epoch.verify(record)
same, err = epoch.same_physics(left, right)
same, err = epoch.same_evidence(left, right)
copy, err = epoch.snapshot(record)
```

The resolver directly requires the current policy modules. Callers cannot pass
replacement descriptor functions or an already-built epoch as truth.

The sole caller assertion surface is:

```lua
options.expected_authority_epoch = {
  physics_epoch_id = string | nil,
  evidence_epoch_id = string | nil,
}
```

The resolver first derives both ids, then compares any supplied expectation.
Mismatch returns a structured `authority_epoch_expectation_mismatch` marked
fatal to the harness. The run stops before FLOW without creating Packet death;
an expected record/payload cannot be supplied as truth.

### 5.2 Corrected record schema

```lua
{
  kind = "authority_epoch",
  protocol_version = "authority_epoch.v0",

  configured = {
    router_mode = "legacy" | "shadow" | "tree",
    configured_movement_owner = "legacy_control" | "tree",
  },

  physics = {
    topology_version = "processlang.topology.v0",
    authority_surface_id = "sha256:" .. hex,
    operator_registry_version = "operator-registry.v0",
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
    observer_protocol = "none" | "edge-observer.v0",
    edge_stats_protocol = "edge-stats.v3",
    bounds = authority_instrument_bounds_v0,
  },

  physics_epoch_id = "sha256:" .. hex,
  evidence_epoch_id = "sha256:" .. hex,
  event_truth_status = "runtime_confirmed",
}
```

`harness_override` remains a per-route authority. Existing runner
configuration never declares it as clean body authority.

### 5.3 Resolution matrix

| Mode | Physics owner/policy | Instrumentation |
|---|---|---|
| `legacy` | legacy descriptor | none |
| `shadow` | legacy descriptor | Tree observer descriptor from effective Tree options |
| `tree`, `legacy_shadow=false` | Tree descriptor | none |
| `tree`, observer default/on | Tree descriptor | legacy descriptor |

`tree_test_override` does not alter the epoch. Its first harness route is
recorded as an authority-taint boundary.

### 5.4 Digest seeds

```lua
physics_seed = {
  protocol_version = "authority_epoch.v0",
  physics = normalized_physics,
}

evidence_seed = {
  protocol_version = "authority_epoch.v0",
  physics_epoch_id = physics_epoch_id,
  configured = normalized_configured,
  instrumentation = normalized_instrumentation,
}
```

Ids:

```lua
physics_epoch_id = "sha256:" .. assert(digest.record(physics_seed))
evidence_epoch_id = "sha256:" .. assert(digest.record(evidence_seed))
```

### 5.5 Verification

`epoch.verify`:

```text
rejects unknown/missing keys
verifies every nested descriptor
recomputes the current authority surface
requires surface id equality
recomputes both ids
requires role matrix consistency
requires observer_enabled to agree with observer_mode/policy
requires configured owner to agree with router_mode
verifies effective instrument bounds and calibration status
requires runtime-confirmed event status
```

It never checks work mode, task, model, budget or repository identity.

### 5.6 Diagnostics

Successful resolution may return:

```lua
{
  kind = "authority_epoch_diagnostics",
  unused_options = sorted_unique_string_array,
  event_truth_status = "runtime_confirmed",
}
```

Diagnostics are life provenance and are not hashed.

## 6. Candidate Eligibility Carry

### 6.1 Composition output

Each qualified candidate adds:

```lua
promotion_eligible = boolean
promotion_ineligibility_reasons = sorted_unique_string_array
promotion_eligibility_basis = {
  witness_ids = sorted_unique_string_array,
  unqualified_snapshot = boolean,
  fixture_witness_ids = sorted_unique_string_array,
}
```

Current derivation:

```text
snapshot.unqualified non-empty -> candidate_unqualified
selected witness promotion_source=fixture -> fixture_witness
otherwise candidate may remain eligible
```

The pressure snapshot ref is the basis for unqualified diagnostics. No second
diagnostic id registry is invented.

### 6.2 Decision output

Before `record_derivation`, `runtime/router.lua` normalizes the
prediction and its selected candidate. It returns for every committable Tree
decision:

```lua
promotion_eligible = boolean
promotion_ineligibility_reasons = sorted_unique_string_array
promotion_eligibility_basis = normalized_table
```

Rules:

| Decision | Eligibility |
|---|---|
| Qualified unique selected | Exact selected candidate value |
| Qualified control fallback | false, `control_fallback` |
| Binary Tree selected | false, `binary_policy_control` |
| Tie-only binary selected | false, also `tie_only_selection` |
| No viable/ambiguity | false; no route credit because no commit |

`derive_tree_authority` must retain these fields. It may not reconstruct
them from the target glyph.

For binary Tree, normalization writes the false eligibility triple onto the
selected ephemeral candidate before the derivation event is appended. For
qualified Tree, normalization verifies the composition result and selected
candidate already agree. Current `control_selected` remains a
non-committable control outcome; its false eligibility is still observable.

### 6.3 Trace consistency

The existing body trace gains no new event type. Existing records add fields:

```text
Tree route_derivation payload:
  promotion_eligible
  promotion_ineligibility_reasons
  promotion_eligibility_basis

Tree route payload:
  same three fields
```

`core.packet.commit_transition` deep-copies the Tree eligibility fields without
interpreting them. `runtime.edge_credit` verifies:

```text
decision eligibility equals selected candidate
decision eligibility equals recorded derivation
reasons and basis are normalized and equal
classified Tree route cannot omit the eligibility triple
```

An absent or inconsistent triple makes the route's measurement unclassified;
it does not reject an otherwise lawful body transition. This is policy evidence
already produced by the body, not an instrumentation trace event. Correct Tree
implementations always emit it whether edge instrumentation is on or off.

## 7. Edge Credit API

### 7.1 State

```lua
local credit = require("runtime.edge_credit")

state, err = credit.new(authority_epoch_or_nil, {
  life_id = string,
  packet_id = string,
  lineage_id = string,
  generation = integer,
})
```

State:

```lua
{
  kind = "edge_credit_state",
  protocol_version = "edge-credit.v0",
  authority_epoch = authority_epoch | nil,
  identity = {
    life_id = string,
    packet_id = string,
    lineage_id = string,
    generation = integer,
  },
  events = append_only_record_array,
  next_sequence = integer,
}
```

There is no mutable `tainted=true` source of truth. Taint is derived by
scanning ordered events for the first authority mismatch.

### 7.2 APIs

```lua
selection, err = credit.prepare(state, decision, {
  route_ordinal = integer,
  derivation_event = table | nil,
})

commit, taint_or_nil, err = credit.record_commit(state, selection, route_event)

arrival, credit_decision, err = credit.record_arrival(state, commit, {
  destination_tick_ref = string,
  effect_refs = string[],
  payload_kind = string,
})

failure, err = credit.record_failure(state, commit, {
  destination_tick_ref = string,
  failure_ref = string,
  failure_kind = string,
})

pending, err = credit.record_pending(state, commit, {
  stop_reason = "tick_limit",
})

taint = credit.authority_taint(state)
ok, err = credit.verify(state)
snapshot, err = credit.snapshot(state)
```

Every returned record is deep-copied into the caller. Stored records are
immutable by contract and verified by digest before later use.

All record ids use one law:

```text
record id = "sha256:" .. digest.record(normalized record seed)
record seed excludes its own id and free-form display message
record seed includes every causal ref and status field
nil identity values are normalized to the explicit string "none"
```

### 7.3 Route evidence identity

Selection record:

```lua
{
  kind = "route_evidence_selection",
  protocol_version = "route-evidence.v0",
  record_id = "sha256:" .. hex,
  route_evidence_id = "sha256:" .. hex,
  sequence = integer,
  route_ordinal = integer,
  evidence_epoch_id = string | nil,
  physics_epoch_id = string | nil,
  life_id = string,
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
  classification_status = "classified" | "unclassified",
  classification_error_codes = sorted_unique_string_array,
  eligibility = edge_credit_selection_eligibility | nil,
  event_truth_status = "runtime_confirmed",
}
```

`authority_basis_ref`:

| Authority | Basis |
|---|---|
| Tree | Existing route derivation ref |
| Legacy | `runner-route-request:<packet>:<ordinal>` record in credit state |
| Harness | `runner-route-request:<packet>:<ordinal>` record in credit state |

The request record is instrumentation-only and precedes Packet commit.

Request record:

```lua
{
  kind = "route_evidence_request",
  protocol_version = "route-evidence.v0",
  record_id = "sha256:" .. hex,
  sequence = integer,
  life_id = string,
  packet_id = string,
  route_ordinal = integer,
  from = glyph,
  to = glyph,
  route_authority = "legacy_control" | "harness_override",
  reason = string,
  event_truth_status = "runtime_confirmed",
}
```

`authority_basis_ref` equals this `record_id`. The human-readable
`runner-route-request:*` form is a display label only, never identity.

`route_evidence_id` seed:

```lua
{
  protocol_version = "route-evidence.v0",
  evidence_epoch_id = evidence_epoch_id,
  life_id = life_id,
  packet_id = packet_id,
  lineage_id = lineage_id,
  generation = generation,
  route_ordinal = route_ordinal,
  from = from,
  to = to,
  route_authority = route_authority,
  authority_basis_ref = authority_basis_ref,
  derivation_ref = derivation_ref,
  pressure_snapshot_ref = pressure_snapshot_ref,
  selected_action_plan_id = selected_action_plan_id,
}
```

### 7.4 Selection eligibility

```lua
{
  kind = "edge_credit_selection_eligibility",
  protocol_version = "edge-credit.v0",
  eligibility_ref = "sha256:" .. hex,
  route_evidence_id = string,
  physics_epoch_id = string | nil,
  evidence_epoch_id = string | nil,
  status = "eligible" | "ineligible",
  reasons = sorted_unique_string_array,
  basis_refs = sorted_unique_string_array,
  policy_rule_ref = "edge-credit.policy.v0",
  policy_rule_status = "document_decision",
  evaluation_truth_status = "runtime_confirmed",
}
```

Closed promotion reason vocabulary:

```text
non_tree_authority
harness_override
authority_tainted
binary_policy_control
candidate_unqualified
fixture_witness
consumer_ablation_active
control_fallback
tie_only_selection
missing_action_contract
unresolved_source_ref
epoch_mismatch
route_identity_mismatch
instrumentation_error
```

Closed unclassified selection error codes:

```text
eligibility_chain_missing
eligibility_chain_mismatch
authority_basis_missing
authority_epoch_invalid
```

The latter are normalized into `authority_instrument_error` records. They are
not eligibility reasons and cannot manufacture an ineligible record where the
required status was absent. New strings in either vocabulary require a TABLE
amendment or protocol version.

Eligibility algorithm:

```text
1. verify state and decision shape
2. derive any prior authority taint from state.events
3. compare route authority with configured movement owner
4. for Tree authority, verify decision, selected candidate and derivation-event
   eligibility agree
5. if that required Tree chain is missing/malformed, emit an unclassified
   selection with no eligibility record
6. for legacy/harness authority, create a classified ineligible record from the
   verified authority basis; do not require invented Tree candidate evidence
7. for classified Tree authority, require qualified live Tree policy in physics
8. require decision promotion_eligible true
9. copy normalized decision reasons/basis
10. add epoch/authority/taint/action/ref reasons
11. eligible iff final reason set is empty
12. append selection; never mutate it later
```

Legacy and harness selections have a classified ineligible record. A Tree
selection whose policy-evidence chain is absent is physically identified but
unclassified, exactly as TABLE section 11 requires. Recording that selection
adds an instrumentation error to `edge_stats.errors`; it never rewrites the
Packet route.

### 7.5 Authority taint

The first committed route whose authority differs from
`configured_movement_owner` produces:

```lua
{
  kind = "authority_taint",
  protocol_version = "edge-credit.v0",
  record_id = "sha256:" .. hex,
  route_evidence_id = string,
  commit_ref = string,
  sequence = integer,
  configured_owner = string,
  observed_owner = string,
  cause = "authority_owner_mismatch",
  event_truth_status = "runtime_confirmed",
}
```

The mismatching route is already ineligible. All later selections add
`authority_tainted`. Earlier selection and credit records are not
rewritten.

### 7.6 Commit record

```lua
{
  kind = "route_evidence_commit",
  protocol_version = "route-evidence.v0",
  record_id = "sha256:" .. hex,
  route_evidence_id = string,
  selection_ref = string,
  route_trace_ref = string,
  from = glyph,
  to = glyph,
  route_authority = string,
  event_truth_status = "runtime_confirmed",
}
```

The verifier reads the deep-copied Packet route event and requires identity,
authority, endpoints, derivation, snapshot and action-plan equality.

### 7.7 Arrival and final decision

Arrival record:

```lua
{
  kind = "route_evidence_arrival",
  protocol_version = "route-evidence.v0",
  record_id = "sha256:" .. hex,
  route_evidence_id = string,
  commit_ref = string,
  destination_tick_ref = string,
  effect_refs = sorted_unique_string_array,
  payload_kind = string,
  event_truth_status = "runtime_confirmed",
}
```

Final decision:

```lua
{
  kind = "edge_credit_decision",
  protocol_version = "edge-credit.v0",
  credit_decision_ref = "sha256:" .. hex,
  route_evidence_id = string,
  selection_eligibility_ref = string,
  commit_ref = string,
  arrival_ref = string,
  status = "credited" | "rejected",
  reasons = sorted_unique_string_array,
  basis_refs = sorted_unique_string_array,
  event_truth_status = "runtime_confirmed",
}
```

`credited` requires:

```text
eligible immutable selection
matching verified commit
successful destination execution
matching destination tick
no identity/epoch/taint error
empty reasons
```

The final decision itself is the runtime-confirmed arrival evidence. An organ
payload need not invent a universal effect event merely to satisfy the
instrument. Existing action protocols still verify exact effect refs where
their contract requires them.

If selection eligibility is unclassified, arrival is still recorded and
`credit_decision` is nil. `edge_stats.record_arrival` counts physical execution,
writes `unclassified_executed`, and records the classification error.

### 7.8 Failure and pending records

Failure:

```lua
{
  kind = "route_evidence_failure",
  protocol_version = "route-evidence.v0",
  record_id = "sha256:" .. hex,
  route_evidence_id = string,
  commit_ref = string,
  destination_tick_ref = string,
  failure_ref = string,
  failure_kind = string,
  event_truth_status = "runtime_confirmed",
}
```

Pending:

```lua
{
  kind = "route_evidence_pending",
  protocol_version = "route-evidence.v0",
  record_id = "sha256:" .. hex,
  route_evidence_id = string,
  commit_ref = string,
  stop_reason = "tick_limit",
  event_truth_status = "runtime_confirmed",
}
```

Neither creates an `edge_credit_decision(status=credited)`.

## 8. Runner Choreography

### 8.0 Measurement rollout switch

The v3 instrument is introduced behind one runner-only switch while the
implementation slices are incomplete:

```text
options.authority_instrument = "edge_stats_v2" | "v3" | "off"
```

Rollout law:

| Phase | Omitted option | Explicit options |
|---|---|---|
| I01-I06 | Existing v2 behavior | No v3 runner mode; new modules are pure |
| I07-I08 | `edge_stats_v2` | `v3` for new controls; `off` only with `authority_instrument_test_override=true` |
| After I09 cutover | `v3` | `off` only for permanent ablation controls |

Exactly one instrument may run in one life. The temporary `edge_stats_v2`
choice preserves the current report while v3 is incomplete; it is removed from
the runtime option contract when v3 becomes the default. It is not a fallback
after promotion and no v2 record is converted or dual-written as v3.

`off` suppresses measurement only. It cannot alter router, pressure, body,
budget, loss, repository, QA or finality behavior, and a result produced with
it cannot enter a v3 corpus.

### 8.1 Birth

Runner-only provenance input:

```lua
options.edge_evidence = {
  case_id = string | nil,
  corpus_layer = "L0" | "L1" | "unit" | "archaeology" | nil,
  evidence_run_id = string | nil,
}
```

`prepare_options` validates and deep-copies a supplied value into runner-local
state. An omitted value is treated as empty only by the instrument; the shared
body option table is not normalized or enlarged. `edge_evidence` and every
other instrument-only option are removed at each organ/router context boundary
and are never mirrored into `packet_options` or Packet metadata.

After Packet birth hooks and before FLOW:

```lua
epoch_record, epoch_diagnostics = authority_epoch.resolve(options)
life_source = edge_stats.make_life_source({
  packet_id = instance.id,
  lineage_id = instance.lineage_id,
  generation = instance.generation,
  session_id = instance.session_id,
  work_mode = instance.work_mode,
  case_id = options.edge_evidence.case_id,
  corpus_layer = options.edge_evidence.corpus_layer,
  evidence_run_id = options.edge_evidence.evidence_run_id,
  model = options.model,
  prompt_hash = digest.sha256(instance.chaos.raw_prompt),
})

result.authority_epoch = epoch_record
result.authority_epoch_diagnostics = epoch_diagnostics
result.edge_stats_v3 = edge_stats.new(epoch_record, life_source)
result.edge_credit = edge_credit.new(epoch_record, {
  life_id = life_source.life_id,
  packet_id = instance.id,
  lineage_id = instance.lineage_id,
  generation = instance.generation,
})
```

Optional model attribution is provenance only and may remain nil when the
substrate has not yet disclosed it. It never changes life or epoch identity.

If epoch resolution returns an expected contract error:

```text
result.authority_epoch = nil
result.authority_epoch_error = structured error
edge_credit state remains unclassified
edge_stats.v3 starts ledger_status=invalid
Packet life continues if its body configuration is otherwise valid
```

A thrown Lua exception remains a harness failure.
An expected-epoch mismatch is also a deliberate harness failure and does not
take the invalid-ledger continuation branch.

### 8.2 Selection and commit

`commit_route` becomes:

```text
1. remove observer payload from committed route, as today
2. allocate route ordinal
3. edge_credit.prepare
4. record live Tree derivation or observer channels
5. edge_stats.record_selection
6. packet.commit_transition
7. attach route trace ref to runner-side route copy
8. edge_credit.record_commit
9. edge_stats.record_transition
10. return pending arrival containing commit and route evidence refs
```

Source bundles at this boundary contain only completed records:

```text
Tree derivation -> pressure snapshot + route derivation events + each named
                   witness/readiness/action policy record
observer        -> observer event + every pressure ref named by it
selection       -> route request when legacy/harness + eligibility record when present
commit          -> Packet route trace event + authority-taint record when emitted
```

Every source record crosses this boundary as an alias-free plain-data value
snapshot. Repeated Lua table identity is not evidence identity and is not
preserved. Cycles, metatables, functions and live handles still invalidate the
instrument record; they are never admitted by falling back to the live source.

The body-owned `route_derivation` event carries the already selected candidate
as `selected_candidate`. This is the named writer consumed by the eligibility
chain verifier; it records an existing Tree decision and cannot alter ranking.

Tree may audit excluded adjacency candidates that are not directions in the
38-direction authority surface. Packet trace retains the complete derivation.
The v3 statistics projection intersects its candidate list with the versioned
authority surface before counting directions, so an audited one-way boundary
reverse such as `☴->▽` remains body evidence without becoming a physical edge.

If Packet commit fails, the selected phase remains physical evidence but cannot
receive committed or executed credit.

An expected classification failure does not make `prepare` fail: it returns an
unclassified physical selection as defined in section 7.4. If the instrument
cannot construct even route identity, the runner records a structured error,
commits the body route through the unchanged Packet contract, and marks the v3
ledger invalid. No instrument failure is allowed to veto or redirect that
transition. An impossible Lua state still fails the harness loudly.

### 8.3 Successful destination tick

At the current placement after:

```text
registry execution succeeded
qualified readiness verified
qualified effect verified
result tick appended
destination tick ref known
```

the runner calls:

```lua
arrival_record, credit_decision, arrival_err = edge_credit.record_arrival(...)
if arrival_record then
  edge_stats.record_arrival(
    stats,
    arrival_record,
    credit_decision,
    destination_tick_and_effect_source_bundle
  )
else
  edge_stats.note_error(stats, normalize_instrument_error(arrival_err))
end
```

This remains before the next route derivation. It does not alter body charge or
operator physics order.

### 8.4 Typed effect failure

At the existing failure branch:

```lua
failure_record = edge_credit.record_failure(...)
edge_stats.record_failure(stats, failure_record, failure_source_bundle)
```

The Packet then follows its existing `effect_failure` mortality law.
No promotion execution is written.

### 8.5 Host ceiling

Before `finish_measurements` on `tick_limit`, if one pending arrival
exists:

```lua
pending_record = edge_credit.record_pending(...)
edge_stats.record_pending(stats, pending_record)
```

The Packet remains alive exactly as today.

### 8.6 Instrument errors

`note_stats_error` becomes a projection over the sole v3 error ledger:

```lua
edge_stats.note_error(result.edge_stats, structured_error)
```

At finish:

```lua
result.edge_evidence_v3 = edge_stats.summary(result.edge_stats_v3)
result.authority_instrument_errors =
  result.edge_evidence_v3.errors_or_nil
```

These v3 names remain distinct from the temporary v2 `edge_stats` and
`edge_evidence` fields. Exactly one family exists in a life. There is no second
mutable v3 error list; `authority_instrument_errors` is a derived result view.

### 8.7 I07 runtime precision amendment

The first runner-grown v3 lives fixed the following implementation readings
without changing TABLE physics:

```text
raw task carrier:            instance.chaos.raw_prompt
instrument option locality:  runner only; absent from all body contexts
durable source values:       alias-free detached plain data
Tree statistics domain:      canonical authority directions only
Tree eligibility writer:     route_derivation.selected_candidate
v3 result namespace:         edge_stats_v3 / edge_evidence_v3
```

The corresponding runtime evidence is recorded in
`docs/00_chaos/authority_runner_v3_i07_observation_2026-08-01.md`. These are
precision amendments to the runner choreography, not permission to change
route, pressure, readiness, effect, budget, loss or finality behavior.

## 9. Edge Statistics v3

### 9.1 Root schema

```lua
{
  kind = "edge_statistics",
  protocol_version = "edge-stats.v3",
  authority_epoch = authority_epoch | nil,
  evidence_epoch_id = string | nil,
  physics_epoch_id = string | nil,
  ledger_status = "valid" | "invalid",
  instrument_bounds = authority_instrument_bounds_v0,
  source_usage = {
    record_count = integer,
    encoded_bytes = integer,
    omitted_record_count = integer,
    omitted_encoded_bytes = integer,
  },
  source_lives = {
    [life_id] = life_source_record,
  },
  errors = structured_instrument_error_array,
  error_overflow = authority_instrument_error_overflow | nil,

  comparison_count = integer,
  tree_derivation_count = integer,
  tree_no_viable_count = integer,
  tree_outcome_counts = map,
  observers = keyed_observer_records,
  rails = keyed_rail_records,

  evidence_records = keyed_source_evidence_records,
  source_index = keyed_life_kind_source_index,
  routes = keyed_route_phase_records,
  edges = keyed_edge_records,
  edge_order = string[],
  truth_status = "runtime_confirmed",
}
```

### 9.2 Life source record

```lua
{
  kind = "edge_evidence_life_source",
  protocol_version = "edge-stats.v3",
  life_id = "sha256:" .. hex,
  packet_id = string,
  lineage_id = string,
  generation = integer,
  session_id = string | nil,
  work_mode = string,
  case_id = string | nil,
  corpus_layer = "L0" | "L1" | "unit" | "archaeology" | nil,
  evidence_run_id = string | nil,
  model = string | nil,
  prompt_hash = string | nil,
  event_truth_status = "runtime_confirmed",
}
```

`evidence_run_id` is runner/corpus provenance, never Packet identity. A corpus
harness supplies a stable unique value such as `case:P03:run:02`; it is not
randomly invented by the body.

Life id seed:

```lua
{
  protocol_version = "edge-stats.v3",
  evidence_run_id = evidence_run_id or "diagnostic-unscoped",
  packet_id = packet_id,
  lineage_id = lineage_id,
  generation = generation,
  session_id = session_id or "none",
  case_id = case_id or "none",
  corpus_layer = corpus_layer or "diagnostic",
}
```

These fields do not enter epoch ids. A runner result may be diagnostic with a
nil `evidence_run_id`; `corpus.add_life` rejects it. Raw merge requires disjoint
life-id sets. Even byte-identical overlap rejects, because summing one life
twice would counterfeit evidence.

Promotion corpus lives use `L0` or `L1` and require a manifest case id. `unit`
and `archaeology` remain valid diagnostic provenance but cannot satisfy a case
or direction closure gate.

### 9.3 Durable source evidence

Every source required by a route phase is copied through:

```lua
{
  kind = "edge_source_evidence",
  protocol_version = "edge-source-evidence.v0",
  evidence_ref = "sha256:" .. hex,
  life_id = string,
  source_kind = "packet_trace" | "runner_tick" | "runner_effect"
              | "policy_evidence" | "edge_credit" | "observer",
  original_source_id = string,
  source_digest = "sha256:" .. hex,
  source_record = deep_copied_plain_data,
  source_truth_status = string | nil,
  event_truth_status = "runtime_confirmed",
}
```

Identity seed:

```lua
{
  protocol_version = "edge-source-evidence.v0",
  life_id = life_id,
  source_kind = source_kind,
  original_source_id = original_source_id,
  source_digest = source_digest,
}
```

The source index is:

```lua
source_index[life_id][source_kind][original_source_id] = evidence_ref
```

A source bundle passed to one recording call is:

```lua
{
  life_id = string,
  records = {
    {
      source_kind = source_kind,
      original_source_id = string,
      source_record = plain_data,
    },
  },
}
```

Each phase record is captured as `edge_credit`; nested records with their own
identity are separate entries, so selection and eligibility as well as arrival
and credit decision remain independently resolvable. Required body events
arrive in the bundle. The ledger deep-copies before mutation, rejects cyclic or
metatable-bearing tables and rejects functions, userdata, threads, Packet
objects, provider handles and capability grants.

Within one life and source kind, the same original id plus exact payload is an
idempotent reference reuse. The same id with any payload change invalidates the
recording transaction. Required refs must resolve through this store before a
route can be classified or a corpus can close.

An omitted required source is different from a conflicting source: the phase is
recorded physically in one atomic transaction, the ledger becomes invalid and
the route is unclassified. A conflicting payload rejects the whole transaction
without mutation because accepting it would overwrite an existing fact.

Before insertion the ledger computes exact normalized JSON bytes. A count,
single-record or aggregate-byte overflow omits that source, increments the
omitted usage fields and records `instrument_source_bound_exceeded` in the same
physical-phase transaction. `max_error_records` reserves its final slot for one
digest-bound overflow aggregate whose count may rise; arbitrary errors cannot
grow memory without limit.

Single and aggregate source byte counts use the normalized `source_record`
encoding; wrapper overhead is bounded by `max_source_records`. Projection bytes
use the complete record seed excluding `projection_id`.

### 9.4 Route phase index

The ledger owns one join index so callers never infer phase continuity from
array position:

```lua
{
  kind = "edge_route_phase_index",
  protocol_version = "edge-stats.v3",
  route_evidence_id = string,
  life_id = string,
  route_ordinal = integer,
  edge_id = string,
  direction = "glyph->glyph",
  selection_ref = string,
  commit_ref = string | nil,
  authority_taint_ref = string | nil,
  arrival_ref = string | nil,
  failure_ref = string | nil,
  pending_ref = string | nil,
  credit_decision_ref = string | nil,
  phase_status = "selected" | "committed" | "executed"
               | "failed" | "pending_at_host_ceiling",
}
```

Exactly one of `arrival_ref`, `failure_ref` and `pending_ref` may be present.
Every later phase resolves the same selection and life. A duplicate or
contradictory phase rejects before counters mutate.

### 9.5 Direction schema

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
    derivation_refs = sorted_unique_string_array,
    selected_refs = sorted_unique_string_array,
    committed_refs = sorted_unique_string_array,
    executed_refs = sorted_unique_string_array,
    failure_refs = sorted_unique_string_array,
    pending_refs = sorted_unique_string_array,
    authority_counts = map<string, integer>,
    arrival_kinds = map<string, integer>,
    failure_kinds = map<string, integer>,
  },

  promotion = {
    eligible_selected_count = integer,
    eligible_committed_count = integer,
    eligible_executed_count = integer,
    ineligible_executed_count = integer,
    unclassified_executed_count = integer,
    eligible_derivation_refs = sorted_unique_string_array,
    eligible_committed_refs = sorted_unique_string_array,
    eligible_executed_refs = sorted_unique_string_array,
    credit_decision_refs = sorted_unique_string_array,
    rejected_reason_counts = map<string, integer>,
    rejected_route_refs = sorted_unique_string_array,
  },

  physical_status = "untested" | "selected" | "committed"
                  | "failed" | "executed",
  promotion_status = "unqualified" | "eligible_executed",
}
```

Status precedence:

```text
executed > failed > committed > selected > untested
```

Counters and refs remain authoritative when several outcomes coexist.

### 9.6 Edge schema

An edge contains:

```lua
{
  id = "E01" .. "E22",
  edge = string,
  left = glyph,
  right = glyph,
  legal_directions = map,
  directions = map<direction, direction_record>,
  physical_executed_direction_count = integer,
  promotion_executed_direction_count = integer,
  required_direction_count = integer,
  physical_coverage = "untested" | "partial" | "complete",
  promotion_coverage = "unqualified" | "partial" | "complete",
}
```

The v2 root/edge fields `executed_count`, `coverage` and
`status` are absent as authorities.

### 9.7 Observer and rail channels

The schemas from `edge_evidence_roles.v0` remain structurally intact:

```text
observers.tree    = Tree counterfactual over legacy live movement
observers.legacy  = legacy counterfactual over Tree live movement
tree_shadow rail  = counterfactual prediction
tree_authority    = authoritative Tree derivation
```

They are now epoch-bounded. Unlike evidence epochs do not merge merely because
observer metadata agrees.

## 10. Edge Statistics APIs

```lua
local stats = require("runtime.edge_stats")

stats.protocol_version = "edge-stats.v3"

life_source, err = stats.make_life_source(source_fields)
ledger, err = stats.new(authority_epoch_or_nil, life_source, epoch_error)
ok, err = stats.note_error(ledger, structured_error)

ok, err = stats.record_observer(ledger, shadow_record, source_bundle)
ok, err = stats.record_tree_derivation(ledger, tree_decision, source_bundle)
ok, err = stats.record_selection(ledger, selection_record, source_bundle)
ok, err = stats.record_transition(ledger, commit_record, source_bundle)
ok, err = stats.record_arrival(
  ledger, arrival_record, credit_decision_or_nil, source_bundle
)
ok, err = stats.record_failure(ledger, failure_record, source_bundle)
ok, err = stats.record_pending(ledger, pending_record, source_bundle_or_nil)

summary, err = stats.summary(ledger)
merged, err = stats.merge(target, source)
ok, err = stats.verify(ledger)
```

During I04-I08 pure and opt-in callers require
`runtime.edge_stats_v3`. After I09 `runtime.edge_stats` is the canonical v3
facade shown above; no live caller requires `runtime.edge_stats_v2`.

Every `record_*` call is transactional over source capture, route index and
counters: validate into a deep-copied working ledger, verify it, then replace
the target contents. A conflicting source bundle cannot leave an orphan record
or a partially incremented direction. A missing source commits the physical
phase together with its structured invalid-ledger error, never by partial
failure.

Compatibility aliases `record`, `record_transition` and others may
remain only while their callers are migrated in the same implementation slice.
No public v3 API accepts a naked route plus caller-invented eligibility bool.

### 10.1 Recording ownership

Each API owns one non-overlapping fact:

| API | May increment |
|---|---|
| `record_observer` | Observer and counterfactual rail channels only |
| `record_tree_derivation` | Candidate counts and derivation refs from live Tree authority only |
| `record_selection` | Selected counts and the route phase index |
| `record_transition` | Committed counts |
| `record_arrival` | Executed counts and promotion decision channels |
| `record_failure` | Failed counts |
| `record_pending` | Host-ceiling pending counts |

An observer prediction is never a physical candidate or selection. A Tree
derivation may expose several candidates, but it does not increment
`selected_count`; the one immutable selection record does that exactly once.
Legacy and harness routes have no invented candidate count.

### 10.2 Physical recording

Physical channels consume route/phase records regardless of eligibility:

```text
legacy route      -> physical
binary Tree route -> physical
qualified route   -> physical
harness route     -> physical
tainted route     -> physical
```

### 10.3 Promotion recording

Promotion phase ownership is temporal:

```text
verified eligible selection
  -> eligible_selected_count
matching commit of that immutable selection
  -> eligible_committed_count
credited final arrival decision
  -> eligible_executed_count + exact refs
rejected final arrival decision
  -> ineligible_executed_count + reasons
missing/malformed eligibility or decision after physical arrival
  -> unclassified_executed_count + instrument error
```

Selected and committed eligibility is potential credit only; it never closes a
direction. A later rejection does not rewrite those historical phases. The
ledger reads the immutable eligibility and final decision records and never
recomputes candidate eligibility from current code.

### 10.4 Verification invariants

```text
eligible_executed_count <= physical.executed_count
eligible_committed_count <= physical.committed_count
every eligible ref is a physical ref subset
every credit decision ref resolves to one arrival
one route_evidence_id contributes once per phase
every route phase resolves through the route index
every route evidence id binds one source life id
every required original ref resolves through source_index to a verified payload
source evidence contains plain immutable data only
one life/kind/original id cannot resolve to two source digests
one arrival ref belongs to one route
arrival, failure and pending are mutually exclusive for one route
failed and pending never count executed
all counts are non-negative integers
all refs are unique and sorted in snapshots
epoch payload recomputes to stored ids
invalid ledger cannot report promotion complete
```

## 11. Atomic Merge

### 11.1 Preflight

Before target mutation:

```text
verify target fully
verify source fully
require both edge-stats.v3
require both ledger_status=valid
require exact evidence_epoch_id equality
require exact verified epoch payload equality
require exact edge surface equality
validate every source life/observer/rail/edge/direction record
validate every source-evidence digest and index binding
reject live/non-plain values in source evidence
validate all eligibility reason names
require disjoint source life ids
```

### 11.2 Transaction

Implementation:

```lua
working = deep_copy(target)
apply_source(working, source)
assert(stats.verify(working))
replace_table_contents(target, working)
return target
```

No error path mutates `target`. Tests compare the target digest before and
after every rejected merge.

### 11.3 Required rejection codes

```text
edge_stats_protocol_mismatch
authority_epoch_missing
authority_epoch_invalid
evidence_epoch_mismatch
authority_surface_mismatch
observer_metadata_mismatch
rail_metadata_mismatch
life_source_conflict
life_source_overlap
source_evidence_conflict
source_evidence_unresolved
unknown_eligibility_reason
invalid_counter_subset
```

Errors are structured instrument failures, not Packet outcomes.

## 12. Post-Life Projection API

### 12.1 Module

```lua
local projection = require("runtime.edge_life_projection")

projection.protocol_version = "edge-life-projection.v0"

record, err = projection.capture(instance, runner_result, corpse_or_nil, {
  life_id = string,
  instrument_bounds = authority_instrument_bounds_v0,
})
ok, err = projection.verify(record)
same, differences_or_err = projection.same_exact(left, right)
same, differences_or_err = projection.same_observer_neutral(left, right)
copy, err = projection.snapshot(record)
```

Capture is post-life observation. It computes a digest of the Packet before and
after and fails loudly if the projector itself mutates any body field.

### 12.2 Schema

```lua
{
  kind = "edge_life_projection",
  protocol_version = "edge-life-projection.v0",
  projection_id = "sha256:" .. hex,
  life_id = string,
  corpse_status = "present" | "absent_alive" | "absent_unavailable",
  exact_components = masslessness_component_map,
  exact_digest = "sha256:" .. hex,
  observer_neutral_components = masslessness_component_map,
  observer_neutral_digest = "sha256:" .. hex,
  removed_observer_refs = sorted_unique_string_array,
  removed_observer_ref_digest = "sha256:" .. hex,
  encoded_bytes = integer,
  event_truth_status = "runtime_confirmed",
}
```

`projection_id` is the digest of protocol version, life id, corpse status,
both component digests, the removed-ref digest and encoded byte count. Component
digests are over the complete normalized maps shown below. Capture rejects
before returning a record when normalized size exceeds
`max_projection_bytes`; body state remains unchanged.

The whitelisted component map is:

```lua
{
  identity_and_work_contract = plain_data,
  operator_status_and_walk = plain_data,
  committed_routes = plain_data,
  budget_and_loss = plain_data,
  substrate_and_tool_calls = plain_data,
  chaos_calm_field_revisions_effects = plain_data,
  repository_results = plain_data,
  qa_results = plain_data,
  manifest_death_residue_terminal = plain_data,
  packet_trace = plain_data,
  corpse = plain_data | nil,
}
```

Runner instrumentation fields are absent by construction. Aliased Packet
surfaces such as `physis`/legacy compatibility mirrors are normalized once,
not recursively copied as a second fact.

### 12.3 Observer-neutral derivation

The projector reads observer decisions from the completed runner result and
builds the removable ref set from:

```text
observer decision trace_event_id
pressure_snapshot_ref named by that decision
```

Before removal it verifies each ref against Packet trace, observer identity,
live authority and expected payload kind. It then:

```text
removes exactly those trace events
applies the same removal to corpse.trace_tail
normalizes only the host-time paths authorized by TABLE Amendment A6
removes raw corpse_hash from every observer-neutral corpse
retains every other component byte-for-byte
```

No payload-kind-wide filter exists. An unverified or absent named ref rejects
capture. Exact components always retain raw time and raw corpse identity.

Trace ids obey two Packet-local derived lanes:

```text
body event:                 event-<body ordinal>
observer instrumentation:  observer-event-<observer ordinal>
```

Observer insertion cannot consume a body ordinal. Cross-life source identity
continues to bind `life_id` as specified by Amendments A3/A4.

Closed neutral host-time paths are:

```text
packet_trace[*].time
packet_trace[death|manifest].payload.residue.trace_tail[*].time
manifest_death_residue_terminal.death.time
manifest_death_residue_terminal.residue.trace_tail[*].time
corpse.residue.trace_tail[*].time
corpse.trace_tail[*].time
corpse.trace_tail[death|manifest].payload.residue.trace_tail[*].time
corpse.frozen_at
```

They become `host_wall_time_excluded.v0`. No recursive key-name or string
filter exists; an unrelated `metadata.time` remains comparison-significant.
Runner `legacy` and `shadow` both project as live authority `legacy_control`;
the observer arrangement itself is absent from the physical component map.

### 12.4 Pair laws

```text
new authority instrument off/on:
  compare exact_digest and every exact component

existing Tree/legacy observer disabled/enabled:
  require same physics_epoch_id separately
  compare observer_neutral_digest and every neutral component
  raw exact/corpse hashes may differ only through verified removed refs
```

Digest equality is an accelerator, not the only assertion. A green comparator
also performs exact normalized component equality and returns the component
names that differ on red.

### 12.5 Bounded body-retention tails

`core.packet.body_trace_tail(trace, count)` is the sole bounded tail selector
for Packet-derived durable body history. It scans backward over the complete
trace, counts only records whose Packet-owned lane is `body`, returns at most
`count` detached records in original order, and does not mutate the trace.

The helper is consumed by:

```text
runtime/corpse.lua
runtime/budget.lua exhaustion residue
runtime/packet_memory.lua capsule
```

Observer records remain in the complete Packet trace and in runner-side
evidence, but never occupy these bounded stores. Historical records without a
stored lane tag are recognized only through the closed
`observer-event-<ordinal>` plus observer-payload contract. No generic event or
payload filter exists.

## 13. Required Case Manifest

### 13.1 Module

```lua
local cases = require("runtime.edge_case_manifest")

cases.protocol_version = "tree-authority-cases.v0"

manifest = cases.current()
ok, err = cases.verify_manifest(manifest)
record, err = cases.evaluate_l0(case_id, immutable_corpus_view, evidence_input)
record, err = cases.verify_l1_document(live_document_evidence)
record, err = cases.l1_document(fields)
record, err = cases.harness_evidence(fields)
ok, err = cases.verify_harness_evidence(record)
ok, err = cases.verify_case_evidence(record, manifest)
```

Callers cannot replace the manifest while claiming this protocol version and
cannot submit an L0 `status=green` directly.

### 13.2 Manifest

```lua
{
  kind = "tree_authority_case_manifest",
  protocol_version = "tree-authority-cases.v0",
  manifest_id = "sha256:" .. hex,
  source_table = "tree_authority_promotion_corpus_yellowprint.v0",
  required_l0 = case_definition_array,
  required_l1 = case_definition_array,
  decision_truth_status = "document_decision",
  event_truth_status = "runtime_confirmed",
}
```

Closed required cases:

| ID | Layer | Evidence kind | Required control |
|---|---|---|---|
| P01 | L0 | accepted build life | observer mirror |
| P02 | L0 | rejected build life | legacy dissent |
| P03 | L0 | inherited repair lineage | grave/different-session controls |
| P04 | L0 | no-viable Tree life | malformed harness boundary |
| P05 | L0 | typed effect-failure life | malformed effect boundary |
| P06a | L0 | budget death without progress | host ceiling above budget |
| P06b | L0 | budget death with progress | grave-disabled orphan |
| P07 | L0 | identity-loss life | larger-loss control |
| P08 | L0 | host tick-limit life | observer mirror |
| P09 | L0 | CONNECT witness life | no-relation-need control |
| P10 | L0 | DISSOLVE witness life | no-rigidity control |
| P11 | L0 | multi-alternative CHOOSE life | confirmation control |
| P12 | L0 | observer-pair family aggregate | every required deterministic family |
| P13 | L0 | malformed harness boundary | matching typed failure |
| L1_ACCEPTED_BUILD | L1 | live artifact | successful provider run |
| L1_REJECTED_BUILD | L1 | live artifact | honest blocked manifest |
| L1_MULTI_CHOOSE | L1 | live artifact | real killed alternatives/loss |
| L1_LONG_TREE | L1 | live artifact | bounded longer trace |

`case_definition` schema:

```lua
{
  case_id = string,
  layer = "L0" | "L1",
  evidence_kind = "life" | "lineage" | "family_pair"
                | "harness_boundary" | "live_document",
  evaluator_id = string,
  evaluator_version = "edge-case-evaluator.v0",
  required_control_kinds = sorted_unique_string_array,
  observer_pair_required = boolean,
  observer_family_case_ids = sorted_unique_string_array,
}
```

Closed `required_control_kinds` vocabulary:

```text
observer_mirror
legacy_dissent
grave_disabled
different_session
malformed_harness
malformed_effect
host_ceiling_above_budget
grave_disabled_orphan
larger_loss_limit
no_relation_need
no_rigidity
single_alternative_confirmation
matched_typed_failure
successful_provider_run
honest_blocked_manifest
real_alternative_loss
bounded_long_trace
```

Each `case_definition` fixes `case_id`, `layer`, `evidence_kind`,
`evaluator_id`, `evaluator_version`, control requirements and whether an
observer-pair ref is mandatory. Definition order is canonical and
`manifest_id` covers every field.

Closed evaluator identities:

```text
L0 evaluator_id = "tree-authority.case." .. case_id .. ".v0"
L1 evaluator_id = "tree-authority.live." .. case_id .. ".document.v0"
evaluator_version = "edge-case-evaluator.v0"
```

### 13.3 Case evidence

```lua
{
  kind = "edge_case_evidence",
  protocol_version = "edge-case-evidence.v0",
  case_evidence_id = "sha256:" .. hex,
  case_manifest_id = string,
  case_id = string,
  layer = "L0" | "L1",
  target_evidence_epoch_id = string,
  implementation_revision = string,
  status = "green" | "red" | "blocked",
  life_ids = sorted_unique_string_array,
  control_life_ids = sorted_unique_string_array,
  observer_pair_refs = sorted_unique_string_array,
  evidence_refs = sorted_unique_string_array,
  evaluator_id = string,
  evaluator_version = string,
  verifier_ref = string,
  evaluation_truth_status = "runtime_confirmed" | "document_decision",
  event_truth_status = "runtime_confirmed",
}
```

`case_evidence_id` covers every field except itself. Missing cases are derived
from the manifest; no synthetic `status=missing` record is written.

For L0, status, cited refs and truth status are outputs of the closed evaluator;
caller input is limited to candidate life/control/pair refs and bounded harness
evidence for P13. For L1, the input is an immutable dated document record with
artifact digest, provider/model, source revision and verifier ref; the verifier
may return green/red/blocked but cannot alter the manifest.

Green law:

```text
L0:
  runtime_confirmed evaluator
  exact manifest evaluator id/version
  all life/control/pair/evidence refs resolve in the corpus
  all primary and non-observer control lives use the target evidence epoch
  all cited lives use the target physics epoch and implementation revision
  an observer pair may cross evidence epochs but must contain the target epoch

L1:
  document_decision evaluation
  non-empty dated live artifact refs and verifier ref
  live life provenance names provider/model and target implementation revision

P12:
  green observer pair for P01, P02, P03, P04, P05, P06a, P06b, P07,
  P08, P09, P10 and P11
  each pair contains one target-evidence life and one same-physics control life
```

The immutable corpus view therefore carries both `target_evidence_epoch_id`
and `target_physics_epoch_id`. Evidence-epoch equality is a primary-life law,
not a pair-wide law: observer configuration is part of evidence identity and a
real enabled/disabled pair must normally cross evidence epochs. Teaching the
pair evaluator to require one evidence id for both sides would make only
synthetic observer fixtures green.

P13 is a harness-failure boundary without a completed life projection; its own
matched valid/invalid control is mandatory, but it is not forged into a
life-based observer pair.

The record reports whether a required experiment passed. It cannot alter route
credit, case definitions, default authority or promotion state.

### 13.4 Harness-boundary evidence

```lua
{
  kind = "edge_harness_boundary_evidence",
  protocol_version = "edge-harness-evidence.v0",
  boundary_evidence_id = "sha256:" .. hex,
  case_id = "P04" | "P05" | "P13",
  invalid_invocation_digest = "sha256:" .. hex,
  harness_error_code = string,
  packet_death_observed = false,
  packet_terminal_observed = false,
  matching_valid_life_id = string,
  source_revision = string,
  verifier_ref = string,
  event_truth_status = "runtime_confirmed",
}
```

The id covers every field except itself. The closed L0 evaluator verifies the
matching valid life and source revision. A typed Packet death cannot substitute
for the required loud harness boundary.

### 13.5 L1 document evidence

```lua
{
  kind = "edge_live_case_document",
  protocol_version = "edge-case-evidence.v0",
  document_id = "sha256:" .. hex,
  case_id = "L1_ACCEPTED_BUILD" | "L1_REJECTED_BUILD"
          | "L1_MULTI_CHOOSE" | "L1_LONG_TREE",
  artifact_path = string,
  artifact_digest = "sha256:" .. hex,
  provider = string,
  model = string,
  prompt_hash = "sha256:" .. hex,
  usage_ref = string,
  source_revision = string,
  verifier_ref = string,
  decision = "green" | "red" | "blocked",
  decision_reason = "verified_success" | "semantic_failure"
                  | "provider_unavailable" | "transport_failure"
                  | "verifier_rejection",
  decision_truth_status = "document_decision",
}
```

`document_id` covers every field except itself. The corpus stores this record
beside the derived case evidence. It verifies non-empty fields, manifest case,
target source revision and artifact digest shape; it does not pretend to rerun a
live provider call during deterministic corpus assembly.

Status/reason consistency is closed: green uses `verified_success`; red uses
`semantic_failure` or `verifier_rejection`; blocked uses
`provider_unavailable` or `transport_failure`.

## 14. Edge Corpus API

### 14.1 Module

```lua
local corpus = require("runtime.edge_corpus")

record, err = corpus.new({
  corpus_id = string,
  authority_claim = "full_tree" | "diagnostic",
  bounds = {
    max_lives = positive_integer,
    max_observer_pairs = positive_integer,
    max_case_records = positive_integer,
    max_documents = positive_integer,
    max_harness_records = positive_integer,
  } | nil,
})

ok, err = corpus.add_life(
  record, runner_result, life_projection, implementation_provenance
)
pair, err = corpus.add_observer_pair(record, enabled_life_id, disabled_life_id)
record, err = corpus.add_harness_evidence(record, harness_boundary_evidence)
case_record, err = corpus.evaluate_l0_case(record, case_id, evidence_input)
case_record, err = corpus.add_l1_document(record, live_document_evidence)
report, err = corpus.closure(record, {
  target_evidence_epoch_id = string,
  target_epoch_decision = authority_target_decision_v0 | nil,
  implementation_revision = string,
  observer_pair_ref = string | nil,
})
ok, err = corpus.verify(record)
```

### 14.2 Corpus schema

```lua
{
  kind = "edge_evidence_corpus",
  protocol_version = "edge-evidence-corpus.v1",
  corpus_id = string,
  authority_claim = "full_tree" | "diagnostic",
  bounds = {
    max_lives = integer,
    max_observer_pairs = integer,
    max_case_records = integer,
    max_documents = integer,
    max_harness_records = integer,
    calibration_status = "unmeasured_safety_default"
                       | "explicit_unmeasured_override",
  },
  buckets = {
    [evidence_epoch_id] = edge_stats_v3,
  },
  life_provenance = {
    [life_id] = implementation_provenance,
  },
  life_projections = {
    [life_id] = edge_life_projection_v0,
  },
  case_manifest = tree_authority_case_manifest_v0,
  case_evidence = {
    [case_evidence_id] = edge_case_evidence_v0,
  },
  case_documents = {
    [document_id] = edge_live_case_document,
  },
  harness_evidence = {
    [boundary_evidence_id] = edge_harness_boundary_evidence,
  },
  observer_pairs = observer_pair_array,
  event_truth_status = "runtime_confirmed",
}
```

### 14.3 Implementation provenance

```lua
{
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

Final closure requires:

```text
one non-empty source_revision
worktree_state=clean
content_truth_status=runtime_confirmed
non-empty verifier_ref
every cited life has the same revision
```

### 14.4 Adding a life

`corpus.add_life`:

```text
verifies runner edge-stats and epoch
verifies one matching life source record
requires non-empty evidence_run_id unique within the corpus
requires every cited source ref to resolve inside edge-stats.v3
verifies one matching immutable life projection
records implementation provenance separately
creates or selects exact evidence-epoch bucket
uses atomic edge_stats.merge inside existing bucket
never sums across bucket ids
```

`add_life`, `add_observer_pair`, `evaluate_l0_case` and `add_l1_document` are
deep-copy transactions. `add_harness_evidence` follows the same law. Any
projection, provenance, merge, pair, harness or case failure leaves the corpus
digest unchanged.
Omitted defaults are 1024 lives, 1024 observer pairs, 4096 case records, 256
documents and 256 harness records. Crossing any bound rejects before mutation;
the corpus cannot evict or compost evidence implicitly.

An invalid life may be archived in a diagnostic artifact but is rejected from
`edge-evidence-corpus.v1`.

### 14.5 Observer pair

Pair schema:

```lua
{
  kind = "observer_ablation_pair",
  protocol_version = "edge-evidence-corpus.v1",
  pair_id = "sha256:" .. hex,
  enabled_life_id = string,
  disabled_life_id = string,
  enabled_projection_ref = string,
  disabled_projection_ref = string,
  comparison_mode = "observer_neutral",
  physics_epoch_id = string,
  enabled_evidence_epoch_id = string,
  disabled_evidence_epoch_id = string,
  equality_digest = "sha256:" .. hex,
  ledger_equality_digest = "sha256:" .. hex,
  status = "green" | "red",
  differing_fields = sorted_unique_string_array,
  event_truth_status = "runtime_confirmed",
}
```

`equality_digest` binds the comparison mode, physics epoch, both projection
ids, both observer-neutral digests, ledger equality digest, status and
normalized differing fields.
`pair_id` additionally binds both life/evidence-epoch ids. Pair order is
canonicalized by disabled/enabled role, not lexical id order.

Required equal vector:

```text
walk and committed routes
budget and loss
substrate/tool calls
field/revisions/effects
repository and QA results
manifest/death/residue and semantic corpse projection
physical/promotion route phases after life-local ref normalization
```

Pair prerequisites:

```text
same case_id, prompt hash, work mode and implementation revision
same declared Packet/session/lineage/generation and work-contract coordinates
same initial memory, budget, capability and repository fixture
different evidence_run_id
only the named observer configuration differs
```

The deterministic corpus harness grows the two lives in isolated fixture
processes when global body id counters would otherwise differ.

Allowed delta:

```text
observer events
observer counters
evidence_epoch_id
life-local ids and refs
```

The corpus does not re-read or filter a Packet. It resolves both stored
`edge_life_projection.v0` records and invokes the verified
`same_observer_neutral` comparator from section 12. Every other corpse field and
trace event remains comparison-significant.

It separately normalizes each per-life edge ledger to edge id, direction,
phase counts, authority and promotion outcome, excluding epoch/life/record refs,
then requires exact equality. `ledger_equality_digest` binds that normalized
comparison; raw ledgers remain in separate evidence buckets.

A body difference produces and stores `status=red`; red is valid negative
evidence, not an API failure. A malformed projection or identity mismatch that
prevents comparison rejects the transaction instead.

A physics-epoch delta also produces a retained red pair with
`differing_fields={"physics_epoch_id", ...}`. It proves that the attempted
ablation changed the body configuration and therefore cannot satisfy an
observer gate; the enabled side remains the pair's declared target coordinate,
while both immutable evidence epochs remain bound by `pair_id`.

This exception does not apply to the new authority instrument. Its records live
outside Packet trace, so `off` versus `v3` requires exact raw Packet and corpse
equality. The pair is never a raw merge.

### 14.6 Target epoch decision

```lua
{
  kind = "authority_target_decision",
  protocol_version = "authority-target-decision.v0",
  decision_id = "sha256:" .. hex,
  corpus_id = string,
  target_physics_epoch_id = string,
  target_evidence_epoch_id = string,
  authority_surface_id = string,
  rationale_ref = string,
  decision_truth_status = "document_decision",
}
```

The decision id covers every field except itself. The corpus verifies its own
id, corpus id, target bucket and surface; it cannot create this record.

### 14.7 Closure report

```lua
{
  kind = "edge_closure_report",
  protocol_version = "edge-evidence-corpus.v1",
  target_physics_epoch_id = string,
  target_evidence_epoch_id = string,
  target_epoch_decision_ref = string | nil,
  target_epoch_decision = authority_target_decision_v0 | nil,
  target_selection_truth_status = "document_decision" | "diagnostic_query",
  authority_surface_id = string,
  authority_claim = "full_tree" | "diagnostic",
  implementation_revision = string,
  observer_pair_ref = string | nil,
  physical_direction_count = integer,
  eligible_direction_count = integer,
  required_direction_count = integer,
  directions = {
    [direction] = {
      physical_status = string,
      promotion_status = string,
      executed_refs = string[],
      ledger_eligible_executed_refs = string[],
      corpus_eligible_executed_refs = string[],
      rejected_reason_counts = map,
    },
  },
  observer_gate = "green" | "red" | "missing",
  l0_case_gate = "green" | "red" | "missing",
  l1_case_gate = "green" | "red" | "missing",
  case_status = {
    [case_id] = {
      status = "green" | "red" | "blocked" | "missing",
      case_evidence_refs = string[],
    },
  },
  ledger_gate = "green" | "red",
  provenance_gate = "green" | "red",
  closure_status = "complete" | "partial" | "blocked" | "diagnostic",
  decision_truth_status = "runtime_confirmed",
}
```

For `authority_claim=full_tree`:

```text
required_direction_count = authority surface legal direction count
target physics owner is Tree with the qualified policy descriptor
target_epoch_decision is verified, document-owned and its id equals
target_epoch_decision_ref
observer_pair_ref resolves one green pair containing target_evidence_epoch_id
all required L0 and L1 manifest cases are green for target epoch/revision
each corpus-eligible ref belongs to an L0/L1 life with green provenance gates
closure complete iff every direction has corpus_eligible_executed_refs non-empty
physical-only directions remain visible and do not close
```

Top-level `eligible_direction_count` is the count of directions with non-empty
`corpus_eligible_executed_refs`, not the raw ledger promotion count.

Status derivation:

```text
blocked    -> any ledger/provenance/observer/case gate is red or invalid
partial    -> gates are non-red but a required case/pair/direction is missing
complete   -> every full-tree gate is green
diagnostic -> diagnostic claim with structurally valid evidence, regardless of count
```

For one L0 case under the selected epoch/revision, any `red` or `blocked`
record dominates green; green requires at least one green record and no
contradiction. For L1, semantic `red` still dominates, while a transient
provider `blocked` record remains visible but may be followed by a green retry;
blocked without green is reported missing/blocked, never satisfied. Records
from other epochs/revisions remain visible but cannot be cherry-picked into the
target gate.

`unit`, `archaeology` and unscoped diagnostic lives remain visible in ledger
counts but are filtered out of `corpus_eligible_executed_refs`. The corpus never
recomputes route eligibility; it only resolves each credited route's immutable
life id and applies the closed layer/provenance gate.

`evaluate_l0_case` infers its target without a caller-authored verdict. Primary
life refs determine the evidence epoch. P12 uses the one evidence epoch common
to every supplied observer pair, and P13 uses its matching valid-life ref.
Ambiguous or absent targets reject before mutation.

For `authority_claim=diagnostic`, the report uses the same 38-direction
denominator but can return only `diagnostic` or `blocked`. It may report counts
and gaps; it cannot prove a smaller product authority. A future narrow authority
surface requires the explicit later promotion contract allowed by TABLE section
7.1 plus a versioned surface id; v0 never infers one from ablation.

A diagnostic report may omit `target_epoch_decision_ref`; it then records
`target_selection_truth_status=diagnostic_query`. That query can never be
upgraded in place into a full-tree closure report.

The report can prove closure. It cannot set runtime default authority.

## 15. Error Boundary

### 15.1 Expected instrument errors

Expected errors are normalized:

```lua
{
  kind = "authority_instrument_error",
  protocol_version = "authority-instrument-error.v0",
  error_id = "sha256:" .. hex,
  class = "configuration" | "identity" | "ledger" | "bounds"
        | "merge" | "corpus",
  code = string,
  stage = string,
  route_evidence_id = string | nil,
  source_refs = sorted_unique_string_array,
  message = string,
  event_truth_status = "runtime_confirmed",
}
```

The error id seed excludes `error_id` and free-form `message`.

Reserved overflow aggregate:

```lua
{
  kind = "authority_instrument_error_overflow",
  protocol_version = "authority-instrument-error.v0",
  overflow_count = integer,
  overflow_digest = "sha256:" .. hex,
  event_truth_status = "runtime_confirmed",
}
```

Each omitted normalized error advances
`overflow_digest = digest(previous_digest, normalized_error_without_message)`.
The aggregate is the reserved final error slot and does not conceal that the
ledger is invalid.

### 15.2 Body behavior

| Instrument failure | Body behavior |
|---|---|
| Epoch configuration cannot classify | Run may continue; ledger invalid |
| Eligibility fields absent | Route may execute; arrival unclassified |
| Epoch/route id mismatch | Body trace retained; promotion blocked |
| Stats record rejects | Body result retained; ledger invalid |
| Source transport bound exceeded | Physical phase retained when possible; ledger invalid |
| Projection/corpus bound exceeded | Body retained; archival transaction rejects |
| Merge/corpus rejects | No Packet involved |
| Lua exception or impossible internal state | Harness fails loudly |

No instrument error calls:

```text
packet.die
packet.manifest_packet
budget.charge
loss.record
field mutation
repository or QA provider
```

## 16. v2 Migration Boundary

### 16.1 No restamping

v2 lacks exact:

```text
live versus observer policy placement
physics/evidence ids
ablation vector
selection eligibility reasons
route identity chain
physical/promotion split
atomic epoch merge
```

Therefore:

```text
v2 -> v3 conversion function does not exist
v2 + v3 merge always rejects
v2 reports retain historical physical meaning
fresh v3 rerun is required for promotion evidence
```

### 16.2 Existing tests

Tests that assert `edge-stats.v2` are migrated to v3 behavior. A dedicated
archaeology fixture may retain one hand-built v2 record solely to prove
rejection.

The old blueprint:

```text
docs/02_crystall/blueprints/edge_evidence_roles.v0.md
```

remains the treatment record for v2 observer-role separation. This blueprint
inherits those roles and supersedes its merge/coverage protocol for new runs.

## 17. Permanent Red Tests

### 17.1 Authority epoch AE01-AE11 plus Amendment A1

```text
AE01 tree binary versus tree qualified -> both ids differ
AE02 map insertion order -> ids equal
AE03 Plan versus Build -> ids equal
AE04 prompt/model/budget -> ids equal
AE05-T tree consumer ablation -> both ids differ
AE05-S shadow observer ablation -> physics equal, evidence differs
AE05-L legacy unused ablation -> both ids equal, diagnostic differs
AE06-A legacy versus shadow -> physics equal, evidence differs
AE06-B tree legacy observer on/off -> physics equal, evidence differs
AE07 threshold/fallback under tree -> both ids differ
AE08 unknown ablate key -> invalid promotion epoch
AE09 topology/surface mismatch -> exact structured error
AE10 expected id lie -> loud assertion, no Packet death
AE11 instrument bounds changed -> physics equal, evidence differs
```

### 17.2 Edge credit EC01-EC12

```text
EC01 eligible qualified arrival -> physical and credited
EC02 candidate ineligible arrival -> physical only
EC03 harness route -> physical, harness_override reason
EC04 binary Tree route -> physical, binary_policy_control
EC05 host ceiling -> committed + pending, no execution
EC06 typed effect failure -> failed, no execution
EC07 missing eligibility chain -> unclassified arrival
EC08 successful effect cannot launder ineligible selection
EC09 replayed arrival -> rejection, counters unchanged
EC10 mismatched route/epoch refs -> instrument error
EC11 Tree route after harness -> authority_tainted
EC12 pre-harness credit immutable; post-harness cannot borrow
```

At least EC02, EC05, EC06 and EC11 use body-grown runner lives rather than
hand-built records.

### 17.3 Source evidence SE01-SE09

```text
SE01 discard Packet/result after life -> every ledger source ref still resolves
SE02 exact source id/payload reused in two lawful bundles -> one evidence record
SE03 same life/kind/source id with changed payload -> reject, ledger unchanged
SE04 function/userdata/thread/metatable/live Packet in bundle -> reject
SE05 mutate caller payload after record -> stored digest/payload unchanged
SE06 required source omitted -> physical phase visible, ledger invalid, no credit
SE07 merge ledger with unresolved/conflicting source -> reject, target unchanged
SE08 corpus closure reads only self-contained source store -> deterministic
SE09 source count/single/aggregate bound -> physical visible, ledger invalid
```

### 17.4 Life projection LP01-LP09

```text
LP01 capture completed life -> Packet digest unchanged before/after
LP02 v3 off/on control -> exact component maps and raw corpse equal
LP03 existing observer on/off -> neutral maps equal, named raw refs differ
LP04 absent/wrong observer ref -> capture rejects
LP05 same payload kind without named ref -> remains comparison-significant
LP06 mutate caller Packet/result/corpse after capture -> projection unchanged
LP07 cycle/metatable/function/live handle in selected component -> reject
LP08 discard source objects -> stored projections still compare deterministically
LP09 projection byte bound -> reject projection, body digest unchanged
LP10 grown Tree observer off/on pair with corpse -> neutral maps equal
LP11 observer append cannot shift later body event ids
LP12 unrelated metadata.time delta -> neutral maps differ
```

### 17.5 Merge EM01-EM11

```text
EM01 same evidence epoch -> exact sum
EM02 binary plus qualified -> reject, target digest unchanged
EM03 canonical plus ablated -> reject, target unchanged
EM04 observer on/off -> raw reject, corpus pair accepted
EM05 v2 plus v3 -> reject
EM06 same ids with altered payload -> reject
EM07 unknown eligibility reason -> reject
EM08 Plan/Build same epoch -> merge; both life refs retained
EM09 different implementation revisions -> closure reject
EM10 malformed source halfway through -> no partial target mutation
EM11 same life merged twice -> reject, target unchanged
```

### 17.6 Masslessness MI01-MI06

```text
MI01 v3 instrument off/on -> birth Packet digest equal before FLOW;
      completed control life raw corpse equal
MI02 full Plan off/on life -> walk/economics/loss/revisions/finality/corpse equal
MI03 repository off/on life -> effect/read-back/result/corpse equal
MI04 typed effect failure off/on -> death/residue/raw corpse equal
MI05 QA M4 grown off/on life -> candidate/verdict/terminal/raw corpse equal
MI06 existing router observer pair -> named observer refs may differ;
      verified semantic body/corpse projection remains equal
```

For MI01-MI05 the Packet digest comparison excludes no body field. New
instrument records are outside Packet, so equality is exact. MI06 follows
TABLE Amendment A2 and rejects every delta outside the refs named by the
observer record.

### 17.7 Case manifest CA01-CA12

```text
CA01 current manifest -> 14 L0 ids (P06 split) + 4 L1 ids, stable digest
CA02 unknown case/evaluator/version -> reject, corpus unchanged
CA03 L0 green without runtime-confirmed evaluator -> reject
CA04 green with unresolved life/control/pair/evidence ref -> reject
CA05 cited life epoch/revision differs -> reject
CA06 L1 green without live provider/model/artifact/document verifier -> reject
CA07 P12 omits one completed-life family pair -> not green
CA08 P13 uses matched harness refs and requires no synthetic life pair
CA09 unit/archaeology credited route -> absent from corpus-eligible refs
CA10 38 ledger-green directions with one missing case -> closure not complete
CA11 same target L0 case green plus red -> red dominates; no cherry-pick
CA12 L1 transient blocked then verified green retry -> green, failure retained
```

### 17.8 Corpus CO01-CO15

```text
CO01 add same-epoch Plan and Build lives -> one bucket
CO02 add unlike epochs -> two buckets, no summed closure
CO03 closure selects exactly one evidence epoch
CO04 unknown provenance -> blocked
CO05 dirty provenance -> blocked
CO06 observer pair physics delta -> red
CO07 physical-only direction -> visible, not closed
CO08 eligible direction -> exact credit and source refs
CO09 diagnostic claim with complete counts -> diagnostic, never complete
CO10 missing/reused evidence_run_id -> reject without corpus mutation
CO11 missing/tampered life projection -> reject without corpus mutation
CO12 observer pair body delta -> red pair retained, closure blocked
CO13 max_lives exceeded -> reject without eviction or corpus mutation
CO14 full-tree missing/forged target document decision -> closure blocked
CO15 observer pair ledger-channel delta with equal body projection -> red
```

## 18. Implementation Slices

Each slice begins with its permanent red controls and ends with the full suite.

### I01 Surface and pure epoch identity

```text
files:
  runtime/edge_catalog.lua
  runtime/authority_epoch.lua
  runtime/pressure.lua
  runtime/qualified_pressure.lua
  runtime/tree_router.lua
  runtime/router.lua
tests:
  AE01-AE11 and A1 controls
body integration:
  none
exit:
  deterministic ids and descriptor verification green
```

### I02 Eligibility reason carry

```text
files:
  runtime/pressure_composition.lua
  runtime/router.lua
  core/packet.lua
tests:
  qualified/binary/fallback/fixture reason controls
  existing route/walk/economics exact
exit:
  selection truth survives derivation -> decision -> route
  missing eligibility cannot block a body transition
```

### I03 Pure edge-credit route chain

```text
files:
  runtime/edge_credit.lua
tests:
  EC01-EC12 module controls
  exact selection/commit/arrival/failure/pending identity
exit:
  selection/commit/arrival/failure/pending records verify
  authority taint is monotonic and append-only
body integration:
  none
```

### I04 Pure edge-stats.v3 physical channel

```text
files:
  runtime/edge_stats_v3.lua
tests:
  physical candidate/selected/committed/executed/failed/pending
  existing observer and rail roles
  SE01-SE05 and SE09 source capture/bound controls
exit:
  v3 physical ledger verifies independently
  current runner and edge_stats.v2 remain untouched
```

### I05 Promotion channel and atomic merge

```text
files:
  runtime/edge_stats_v3.lua
tests:
  credited/ineligible/unclassified subsets
  no physical evidence erased
  EM01-EM11 except corpus-only EM09
  SE06-SE07 invalid-ledger and merge controls
exit:
  promotion coverage reads only final credit decisions
  unlike evidence never sums and rejection is mutation-free
```

### I06 Pure corpus and observer pairs

```text
files:
  runtime/edge_life_projection.lua
  runtime/edge_case_manifest.lua
  runtime/edge_corpus.lua
tests:
  LP01-LP09
  CA01-CA12
  CO01-CO15
  EM04 and EM09
  SE08 self-contained corpus control
exit:
  bucketed physical/promotion closure and provenance gates green
body integration:
  none
```

### I07 Opt-in runner integration

```text
files:
  runtime/tension_runner.lua
tests:
  epoch present on legacy/shadow/tree v3 results
  grown EC02/EC05/EC06/EC11 lives
  physical v3 report reproduces current body observations
  invalid epoch or credit leaves Packet physics unchanged
  no concurrent v2/v3 write
exit:
  explicit authority_instrument=v3 closes the full route chain
  omitted option still runs the unchanged v2 path
```

### I08 Full masslessness campaign

```text
tests:
  MI01-MI06
  complete existing suite
  mortality 8/8
  QA red-hand matrix
exit:
  instrument has zero Packet/repository/QA/economic mass
  observer semantic projection follows Amendment A2 exactly
```

Runtime observation:

```text
status: complete
date: 2026-08-09
evidence:
  docs/00_chaos/authority_instrument_masslessness_i08_observation_2026-08-09.md
result:
  MI01-MI06 green
  TABLE Amendment A8 closes observer retention mass
  full suite, mortality and QA red-hand gates green
default authority:
  unchanged edge_stats_v2
```

### I09 Canonical v3 cutover

```text
files:
  runtime/edge_stats.lua becomes canonical v3 facade
  runtime/edge_stats_v2.lua receives historical v2 implementation
  runtime/tension_runner.lua defaults to v3
tests:
  complete existing suite migrated to explicit v3 assertions
  v2 archaeology fixture rejects v3 merge
  authority_instrument=edge_stats_v2 rejected by live runner
  mortality 8/8
  QA red-hand matrix
exit:
  omitted authority_instrument now selects v3
  edge_stats_v2 runtime option is removed
  no live fallback or dual writer remains
```

### I10 Current evidence manifest

```text
grow fresh v3 deterministic lives
write current physical direction union
write current eligible direction union
name every rejected reason and epoch
write P01-P13 and L1 case-gate status without filling missing evidence
do not claim promotion
```

## 19. Observation Gate Per Slice

After every implementation slice record:

```text
source commit
changed modules
new protocol records
targeted control result
full suite count
mortality result
QA matrix result when affected
Packet ablation digest
edge epoch ids observed
known red controls remaining
```

Stop before the next slice when:

```text
any route changes unexpectedly
Packet budget/loss/revision changes
observer changes physics_epoch_id
binary and qualified ids alias
an ineligible arrival receives credit
merge failure mutates target
instrument error becomes Packet death
```

## 20. Explicit Deferrals

```text
DISSOLVE witness/action/readiness treatment
CYCLE witness/action/readiness treatment
automatic QA route producers/actions
remaining 22-edge direction campaign
topology revision for phase-law conflicts
numeric pressure calibration
compost and qualified grave readers
live DeepSeek promotion corpus
release/default authority decision
distributed signing and hostile remote corpus ingestion
cross-commit behavioral equivalence
```

This instrument is required by those campaigns. None of their semantics is
smuggled into this implementation.

## 21. Crystall Acceptance

Implementation may begin only while all statements remain true:

```text
Tree policy is live physics only under tree authority
shadow Tree policy is observer instrumentation only
physics and evidence epoch ids have deterministic verified seeds
work mode/model/task/budget remain life provenance, not epoch identity
unknown effective ablations fail promotion classification closed
candidate eligibility survives body records without reconstruction
missing eligibility leaves physical execution unclassified, never vetoed
route evidence lives outside Packet trace
authority taint moves forward and never rewrites history
arrival credit requires successful destination execution
one route phase index owns every selection/commit/outcome join
every durable source ref resolves inside an immutable plain-data store
host evidence is bounded without charging or killing the Packet
observer pairs read immutable post-life projections, never live Packets
physical evidence survives every promotion rejection
edge-stats.v3 owns one instrumentation error ledger
raw merge requires exact evidence epoch and is atomic
observer ablations remain paired separate buckets
observer corpse comparison filters only refs named by the observer
v2 receives no inferred upgrade
corpus closure names one epoch and one verified implementation revision
full-tree closure requires every inherited L0/L1 case gate, not directions alone
diagnostic corpus can never claim a narrow authority surface
runtime evidence cannot flip default authority
no pressure, route, organ, budget, loss, repository or QA behavior changes
```

Current CRYSTALL disposition:

```text
authority surface: exact
effective policy descriptors: exact
authority_epoch.v0: exact
authority-instrument-bounds.v0: exact
route-evidence.v0: exact
edge-source-evidence.v0: exact
edge-life-projection.v0: exact
tree-authority-cases.v0: exact
edge-case-evidence.v0: exact
edge-harness-evidence.v0: exact
authority-target-decision.v0: exact
edge-credit.v0: exact
edge-stats.v3: exact
edge-evidence-corpus.v1: exact
implementation slices: I01-I10 ordered
implementation authorization: measurement-only
promotion/default change: blocked
```

## 22. I09 Runtime Closure Precision Amendment

Source:

```text
docs/00_chaos/authority_instrument_i09_cutover_observation_2026-08-11.md
docs/01_table/yellowprints/authority_epoch_edge_credit_yellowprint.v0.md
  Amendment A9
```

The canonical runner must not call the strict public transaction API for each
tick. It uses these exact internal boundaries:

```lua
recorder = edge_stats.begin_runtime(epoch_record, life_source, epoch_error)
edge_stats.runtime_record_tree_derivation(recorder, decision, sources)
edge_stats.runtime_record_observer(recorder, observer, sources)
edge_stats.runtime_record_selection(recorder, selection, sources)
edge_stats.runtime_record_transition(recorder, commit, sources)
edge_stats.runtime_record_arrival(recorder, arrival, credit, sources)
edge_stats.runtime_record_failure(recorder, failure, sources)
edge_stats.runtime_record_pending(recorder, pending, sources)
edge_stats.runtime_note_error(recorder, err)
ledger, summary = edge_stats.finish_runtime(recorder)
```

The recorder is an opaque weak-registry capability. Its table contains no
caller-readable state. Every queued operation is deep-copied at entry. Closure
replays the journal through the same private `*_on` writers used by public
transactions and calls the complete public verifier before returning.

If a replay operation rejects, closure discards that possibly touched working
ledger, replays the accepted prefix from the verified base, appends one
normalized instrument error, and continues. No partial mutation is accepted as
diagnostic evidence.

`source_usage_for_life` takes the constant-time global usage only when the
ledger has exactly one life and that life matches the request. Merged ledgers
retain indexed per-life derivation. No mutable usage cache is introduced.

Credit uses the parallel runner-only API:

```lua
state = edge_credit.new_runtime(epoch_record, life_identity)
selection = edge_credit.runtime_prepare(state, decision, context)
commit, taint = edge_credit.runtime_record_commit(state, selection, route_event)
arrival, decision = edge_credit.runtime_record_arrival(state, commit, input)
failure = edge_credit.runtime_record_failure(state, commit, input)
pending = edge_credit.runtime_record_pending(state, commit, input)
state = edge_credit.finish_runtime(state)
```

Every credit writer records `#events` before mutation and truncates to that
length on rejection. Only a state minted by `new_runtime` is admitted. Public
states continue through strict copy-and-verify transactions.

`tension_runner` publishes no statistics ledger during the life. It publishes
the verified credit state, verified statistics ledger and detached summary only
inside `finish_measurements`. Neither runtime surface is a Packet field or a
route input.

Acceptance:

```text
ER01-ER05 green
I09 cutover controls green
full suite green with v3 default
mortality 8/8
QA control matrix 84/84
QA red baseline 5/5
no live require of runtime.edge_stats_v2
```
