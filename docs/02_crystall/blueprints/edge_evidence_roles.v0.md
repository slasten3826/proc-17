# Edge Evidence Roles Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/edge_evidence_roles_yellowprint.v0.md
implementation target: runtime/edge_stats.lua
protocol: edge-stats.v2
implemented and confirmed: 2026-07-17
```

## 1. Root Contract

```lua
{
  kind = "edge_statistics",
  protocol_version = "edge-stats.v2",
  comparison_count = integer,
  observers = {
    tree = observer_record,
    legacy = observer_record,
  },
  tree_derivation_count = integer,
  tree_no_viable_count = integer,
  edges = table,
  rails = table,
  truth_status = "runtime_confirmed",
}
```

Forbidden root compatibility fields:

```text
shadow_ticks
agreement_count
divergence_count
no_viable_edge_count
```

## 2. Observer Contract

```lua
{
  observer = "tree" | "legacy" | string,
  observed_authority = "legacy_control" | "tree" | string,
  evidence_role = "route_comparison",
  comparison_count = integer,
  agreement_count = integer,
  divergence_count = integer,
  no_prediction_count = integer,
  unavailable_count = integer,
}
```

`edge_stats.record` requires `shadow.observer` and `shadow.live_authority`.
Known observer keys must match their declared observed authority. Mismatch is an
instrumentation contract error, not a Packet death.

## 3. Rail Contract

```lua
rail = {
  id = string,
  from = glyph,
  eye = glyph,
  debt_kind = string,
  channels = {
    tree_shadow = rail_channel,
    tree_authority = rail_channel,
  },
  promotion_status = "insufficient_evidence",
}
```

```lua
rail_channel = {
  id = "tree_shadow" | "tree_authority",
  evidence_role = "counterfactual_prediction" | "authoritative_derivation",
  observer = "tree" | nil,
  observed_authority = "legacy_control" | nil,
  authority = "none" | "tree",
  target_kind = "predicted_to" | "selected_to",
  cases = integer,
  target_count = integer,
  reference_eye_count = integer,
  eye_debt_cases = integer,
  eye_target_count = integer,
  debt_eye_target_count = integer,
  fresh_eye_target_count = integer,
  debt_bypass_count = integer,
  fresh_direct_count = integer,
  no_target_count = integer,
}
```

No flat v1 rail counters remain on `rail`.

## 4. Writers

```text
edge_stats.record(tree observer shadow)
  -> observers.tree
  -> rails[*].channels.tree_shadow

edge_stats.record(legacy observer shadow)
  -> observers.legacy
  -> no rail channel

edge_stats.record_tree_derivation(tree decision)
  -> tree_derivation_count
  -> rails[*].channels.tree_authority
```

Tree edge candidate/selection audits continue to feed the existing edge ledger.
This amendment changes role storage, not edge coverage semantics.

## 5. Merge

Before mutation:

```text
target.kind and source.kind must be edge_statistics
both protocol versions must equal edge-stats.v2
known observer metadata must match
rail channel metadata must match
```

Merge counters only inside the same observer key and same rail channel key.
Unknown keys may be copied only with explicit metadata.

## 6. Tests

Permanent tests must prove:

```text
shadow life writes tree observer and tree_shadow rail channel only
tree life writes legacy observer and tree_authority rail channel only
mixed merge retains both without flat aggregate ambiguity
v1/v2 merge is rejected
observer on/off leaves tree_authority channel and Packet physics identical
```

## 7. Non-Goals

```text
no pressure weight changes
no route target changes
no manifest laundering treatment
no default authority flip
no promotion decision
```

## 8. Manifested Result

```text
runtime/edge_stats.lua emits edge-stats.v2
tests/test_edge_metric_roles.lua is permanent and green
tree/legacy comparisons survive mixed merge under separate observer keys
tree shadow/tree authority rails survive under separate channels
v1 and metadata-mismatched merges fail loudly before mutation
44 main suites, 8/8 mortality, camera and ablation green
```

The blueprint is implemented. It authorizes v2 promotion-corpus collection but
does not authorize a routing or default-authority change.
