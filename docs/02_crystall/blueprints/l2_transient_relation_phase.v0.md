# L2 Transient Relation Phase Blueprint v0

Status:

```text
crystall / roadmap step 3 contract 2 of 4
date: 2026-07-18
table: docs/01_table/yellowprints/l2_transient_relation_lifecycle_yellowprint.v0.md
coverage contract: docs/02_crystall/blueprints/object_version_coverage.v0.md
implementation authorized by this document: no
router/pressure promotion: forbidden
```

## 0. Selected Law

```text
CONNECT records one bounded replaceable raw relation epoch
raw storage is transient recognition, not retained graph authority
OBSERVE may expose an exact raw relation without consuming it
DISSOLVE may release an exact raw relation without activating it
ENCODE alone may consume an exact raw relation into retained CALM form
RUNTIME may reconcile formed state but may not originate it from raw CONNECT
```

One canonical raw epoch plus immutable trace events forms the causal chain. No
second mutable lifecycle ledger is added.

## 1. Target Modules

```text
runtime/field.lua                 raw v1 epoch, phase derivation, dispositions
runtime/object_coverage.lua       shared per-object coverage helper
organs/connect.lua                exact probe and raw writer
organs/observe.lua                body-native relation sensor
organs/dissolve.lua               separate raw-release mode
organs/encode.lua                 exact relation-guided formation mode
core/packet.lua                   relation_formation event/right
runtime/operator_registry.lua     mode-accurate reads/writes/readiness
tests/test_relation_phase.lua     local phase and ownership contract
tests/test_vertical_packet_life.lua grown roads in roadmap step 4
```

The existing `relations.active` API remains a legacy compatibility surface while
the new protocol is opt-in. It is not the canonical retained result of L2 v0.

## 2. Canonical Raw Epoch

```lua
field.relations.raw = {
  protocol_version = "field.raw_relations.v1",
  epoch = integer,
  probe_policy = {
    policy_id = string,
    bounds = {max_units=integer, max_relations=integer},
    policy_version = integer,
  },
  source_potential_revision = integer, -- telemetry/atomic guard only
  source_event_refs = string[],
  coverage = object_version_coverage,
  outcome = "relations_recorded" | "empty" | "unsupported",
  items = {
    {
      id = string,
      epoch = integer,
      from = unit_id,
      to = unit_id,
      endpoint_versions = {[unit_id]=integer},
      kind = string,
      source_refs = string[],
      event_truth_status = "runtime_confirmed",
      content_truth_status = string,
      version = 1,
    },
  },
  omitted_relations = integer,
  truncated = boolean,
  trace_event_id = string,
  event_truth_status = "runtime_confirmed",
  content_truth_status = string,
}
```

The raw writer stores independent copies in field and trace. Relation IDs are
stable only inside their epoch. A later epoch may reuse the same endpoints but
creates new raw identities.

`source_potential_revision` remains useful for validating that capture and write
belong to one atomic view. Freshness and readiness use exact object versions,
not revision inequality alone.

## 3. Probe Law

CONNECT's exact probe domain is the ordered set of current-generation `live` or
`selected` field units accepted by its bounded structural policy.

```text
zero addressable units -> CONNECT not ready
one or more uncovered units -> CONNECT may run an honest probe
no candidate found -> write empty/unsupported epoch with full coverage
same object versions + same policy -> immediate CONNECT repetition not ready
covered object/policy changes -> probe re-arms exactly once
```

The raw epoch itself is the probe stamp. No separate `probe_stamps` table is
created.

Probe identity is the deterministic tuple:

```text
(generation, policy_id, policy_version, bounds, ordered {unit_id,version})
```

Global `revisions.potential` changes may trigger a scan, but they do not re-arm
the probe when this tuple is unchanged.

## 4. Structural Candidate Law

The v0 detector may use only body-visible material predicates:

```text
explicit parent/carrier structure
shared exact source/provenance event
declared relation candidate from a registered deterministic projection adapter
another named body-native predicate with its own test
```

Arbitrary `options.candidates` remain available only to legacy/local unit
fixtures. `vertical_packet_life.v0` rejects caller-injected candidates unless
they are emitted by a registered body adapter and carry exact provenance.

Detection confirms that the predicate matched. It does not confirm the semantic
meaning of the relation.

## 5. Derived Phase

```lua
phase, err = field.raw_relation_phase(instance, raw_epoch, relation_id)
```

The function is pure over the current field and immutable trace.

| Phase | Derivation |
|---|---|
| `available` | Current epoch/endpoints; no terminal disposition |
| `observed` | Current exact observation exists; no terminal disposition |
| `encoded` | Relation-formation event consumed exact epoch/id/versions |
| `released` | Raw-release event consumed exact epoch/id/versions |
| `stale` | A covered endpoint's current version differs or is absent |
| `replaced` | `field.relations.raw.epoch` is newer |
| `expired` | Packet is terminal without encoded/released disposition |

Precedence:

```text
encoded/released -> replaced -> stale -> expired -> observed -> available
```

`observed` is non-terminal. `encoded` and `released` are terminal for one raw
identity. Contradictory terminal dispositions are an invariant failure.

## 6. Body-Native Relation Observation

`organs.observe` gains an explicit sensor mode:

```lua
observe.run(instance, substrate_or_nil, {
  sensor = "relation_native",
  relation_input = {
    raw_epoch = integer,
    relation_ids = string[],
    endpoint_versions = map,
    source_event_refs = string[],
  },
})
```

This mode:

```text
requires no substrate
reads exact current raw identities and endpoints
writes one ordinary observation event with relation refs
creates no semantic response unit
creates no retained/active relation
does not terminally consume the raw identity
charges one body tick and zero substrate calls/loss
```

The current semantic sensor remains separate. One OBSERVE tick declares which
sensor(s) it ran; registry declarations must match the actual mode.

Repeated native observation of unchanged exact refs is not ready. An endpoint,
relation epoch, requested evidence scope, or content evidence version change may
re-arm it.

## 7. Raw DISSOLVE Release

`organs.dissolve` gains `scope="raw"` without passing through
`relations.active`.

```lua
dissolve.run(instance, {
  scope = "raw",
  raw_epoch = integer,
  relation_id = string,
  endpoint_versions = map,
  reason = {
    kind = "stale" | "contradictory" | "unsupported"
         | "explicitly_released" | "snapshot_replaced",
    event_id = string,
    policy_id = string | nil,
  },
  preserve_residue = boolean,
})
```

The reason event/policy must be body-visible and name the same raw identity. A
semantic proposal may suggest a reason but cannot authorize the release alone.

The mutation writes one `relation_mutation` event:

```lua
{
  scope = "raw",
  disposition = "released",
  raw_epoch = integer,
  relation_id = string,
  endpoint_versions = map,
  reason = typed_reason,
  residue_unit_id = string | nil,
  event_truth_status = "runtime_confirmed",
  content_truth_status = inherited,
}
```

Raw release creates zero formed-identity loss. Projection omission remains
visible. Optional residue is a new bounded unit with release provenance; it is
not a surviving raw relation.

## 8. Relation-Guided ENCODE

`organs.encode` gains an explicit relation input mode:

```lua
encode.run(instance, {
  relation_input = {
    raw_epoch = integer,
    relation_ids = string[],
    endpoint_versions = map,
    source_event_refs = string[],
    requested_shape = string | nil,
  },
  -- existing encode bounds remain
})
```

Before the first mutation ENCODE verifies that all raw identities are current,
available/observed, unconsumed, and version-exact.

The retained v0 result is existing body-owned CALM form, not a renamed raw edge:

```lua
calm_delta.relation_formation = {
  protocol_version = "l2.relation_formation.v0",
  formed_from = {
    raw_epoch = integer,
    relation_ids = string[],
    endpoint_versions = map,
    observation_event_refs = string[],
  },
  formed_unit_ids = string[],
  identity_map_ref = string,
  content_truth_status = preserved,
}
```

ENCODE also appends a dedicated `relation_formation` event containing those
exact refs. The raw phase derives `encoded` from that event.

Required effects:

```text
CALM crystallization owns the retained form
new field unit identities are explicit
identity map records old endpoint -> new form units
raw-to-formed provenance is immutable
omitted alternatives and ENCODE loss remain explicit
semantic content truth is preserved
```

If no valid `relation_input` is supplied, ordinary text ENCODE may still run but
must report `formation_basis != relation_guided`.

## 9. Retained Form Ownership Decision

For `vertical_packet_life.v0`:

```text
canonical retained structure = CALM crystallization + field identity map
relations.raw                = transient current epoch
relations.active             = legacy compatibility only
RUNTIME raw activation       = forbidden in the new protocol
RUNTIME momentum             = deferred until a formed-state reader is named
```

This chooses neither silent reuse of raw IDs nor a premature second persistent
relation graph. If later evidence requires a first-class formed relation, it
must be derived from the ENCODE formation event under a new schema revision.

## 10. Readiness And Same-Ref Closure

| Organ/mode | Readiness witness | Successful discharge |
|---|---|---|
| CONNECT probe | uncovered exact probe tuple | new raw/empty epoch coverage |
| OBSERVE relation-native | current raw refs not covered by matching observation | exact observation event |
| DISSOLVE raw | exact raw refs plus supported release reason | released disposition event |
| ENCODE relation | exact raw refs plus declared formation demand | formation event + CALM form |

Readiness and mutation consume the same epoch, relation ids and endpoint
versions. A generic `ready=true` or only a global revision is insufficient.

These readiness facts do not automatically become pressure contributions in
roadmap step 4. Router authority waits for the witness work in step 5.

## 11. Truth, Cost And Loss

| Operation | Body budget | Substrate | Identity loss |
|---|---:|---:|---:|
| CONNECT raw/empty probe | one tick | zero | zero |
| OBSERVE relation-native | one tick | zero | zero |
| OBSERVE semantic | one tick | measured usage | zero from sight itself |
| DISSOLVE raw release | one tick | normally zero | zero formed loss |
| ENCODE relation formation | one tick | path-dependent | explicit ENCODE loss |
| DISSOLVE formed (legacy/future) | one tick | normally zero | explicit when identity removed |

Runtime-confirmed operation facts never upgrade semantic content status.

## 12. Permanent Local Tests

| ID | Assertion |
|---|---|
| L2P1 | Raw epoch covers exact ordered unit versions and is bounded |
| L2P2 | Empty probe suppresses unchanged repeat and re-arms on exact change |
| L2P3 | Native OBSERVE creates no substrate call, field unit, activation or loss |
| L2P4 | Observation leaves raw relation available |
| L2P5 | Raw DISSOLVE releases without ever creating active relation |
| L2P6 | Relation ENCODE creates CALM form/new ids/provenance/loss |
| L2P7 | ENCODE without the raw refs cannot claim relation-guided formation |
| L2P8 | RUNTIME cannot activate raw relation in the opt-in protocol |
| L2P9 | Stale/replaced/terminal phases derive without a mutable phase ledger |
| L2P10 | Proposal content remains proposal through all three dispositions |

## 13. Explicit Deferrals

```text
relation-gap-to-pressure law and all weights
default tree authority
first-class persistent formed relation graph
RUNTIME momentum for formed relations
formed CALM dissolution redesign
semantic relation detector
general multi-organ transaction rollback
```

## 14. Acceptance

This crystall is implementation-ready when:

```text
the raw epoch is exact, bounded, replaceable and non-retaining
each of the three exits names and consumes the same refs
OBSERVE sees without retaining
DISSOLVE releases without creating
ENCODE alone originates retained form
RUNTIME activation is excluded from the new protocol
phase is derived from field plus trace
truth/loss/economics remain separated
pressure authority remains explicitly downstream
```
