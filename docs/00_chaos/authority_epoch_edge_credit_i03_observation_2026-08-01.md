# Authority Epoch Edge Credit I03 Observation

```text
layer: CHAOS
date: 2026-08-01
status: runtime_observation
source blueprint:
  docs/02_crystall/blueprints/authority_epoch_edge_credit.v0.md
slice: I03 pure edge-credit route chain
source baseline commit: 1d3433a
implementation commit: pending
body integration: none
promotion decision: forbidden
```

## 0. Scope

I03 implements the pure causal measuring unit behind the future authority
instrument. It does not route a Packet, write Packet trace, change pressure,
charge budget, add loss, or alter an organ effect.

The implemented chain is:

```text
route request when needed
-> immutable selection identity
-> immutable selection eligibility
-> committed Packet route reference
-> arrival | typed failure | host-ceiling pending
-> final credit decision only after arrival
```

The module is not yet connected to `runtime/tension_runner.lua`. Therefore the
new DISSOLVE hypotheses are now a named future measurement target, not a
runtime-confirmed result of this slice.

## 1. Changed Surface

New implementation:

```text
runtime/edge_credit.lua
tests/test_edge_credit.lua
```

Registry update:

```text
tests/run.lua
```

I03 was built on the still-uncommitted I02 eligibility-carry work in:

```text
core/packet.lua
runtime/pressure_composition.lua
runtime/router.lua
tests/test_pressure_composition.lua
tests/test_eligibility_carry.lua
```

This distinction must remain visible when the implementation is committed.

## 2. Protocol Records Implemented

```text
edge_credit_state
route_evidence_request
route_evidence_selection
edge_credit_selection_eligibility
route_evidence_commit
authority_taint
route_evidence_arrival
edge_credit_decision
route_evidence_failure
route_evidence_pending
authority_instrument_error
```

All identities are deterministic SHA-256 records over normalized causal seeds.
Returned records and snapshots are detached copies. Later API calls verify the
stored chain before extending it. Direct post-append mutation is detected by
digest verification.

## 3. Runtime-Confirmed Laws

The targeted controls confirm:

1. A qualified Tree selection is credited only after its matching committed
   route reaches a successful destination tick.
2. Candidate-unqualified, fixture, binary-policy and non-Tree routes remain
   physical evidence but cannot receive promotion credit.
3. A successful effect cannot launder an ineligible selection.
4. Typed destination failure and `tick_limit` pending preserve the route chain
   without inventing execution credit.
5. Missing or inconsistent Tree eligibility remains `unclassified`; it emits a
   typed instrument error and never blocks the body transition.
6. Replayed terminal phases and mismatched route refs fail transactionally.
7. The first committed movement-owner mismatch creates one append-only
   `authority_taint` record. Every later classified selection is ineligible.
8. Later taint cannot rewrite an earlier credited decision.
9. Equal inputs reproduce equal route-evidence and record identities.

## 4. Test Evidence

```text
lua tests/test_edge_credit.lua
  EC01-EC12: green
  detached return control: green
  stored-record mutation control: green

lua tests/test_authority_epoch.lua
  green

lua tests/test_eligibility_carry.lua
  green

lua tests/test_pressure_composition.lua
  green

lua tests/run.lua
  117 suites: green

lua tests/smoke_mortality_battery.lua
  8/8: green
```

QA matrix result:

```text
all QA suites included in the 117-suite full run remained green
QA implementation changed: no
```

Packet ablation:

```text
status: structurally exact for I03
reason: no body or runner imports runtime.edge_credit in this slice
Packet trace/budget/loss/revisions route: unreachable from the new module
digest artifact: deferred until the opt-in off/v3 paired runner life in I07
```

This is not presented as an observed off/on Packet digest. I03 has no runtime
switch to ablate yet; claiming such a digest would manufacture evidence.

## 5. Epoch Identities Observed

Qualified live Tree policy:

```text
physics_epoch_id:
  sha256:4f490b981531b8c8a1e1757df9851b435f9aef30c2b080e55402cec28a265b90
evidence_epoch_id:
  sha256:7af91634d1d298e95c767220370a89f97c0673b46158af7d3d437e9c2ffb19e1
```

Binary live Tree control:

```text
physics_epoch_id:
  sha256:9a932cfd6bef8476ecda36b51512ba26a44ae4cc481f3f75c263240387b111fe
evidence_epoch_id:
  sha256:29bf55a2e58c686791c2d04534ea4d4ee84b1cb27410fe9685af3543a1a1defd
```

The identities do not alias.

## 6. Known Red Controls

Still absent by slice order:

```text
I04 edge_stats.v3 physical channel
I05 promotion channel and atomic merge
I06 source store, life projection, case manifest and corpus
I07 body-grown EC02/EC05/EC06/EC11 and opt-in runner integration
I08 complete corpus and observer pairs
I09 canonical v3 cutover
I10 promotion record
```

In particular:

```text
the instrument cannot yet observe a real DISSOLVE life
the instrument cannot yet prove masslessness with an off/v3 Packet pair
no physical edge ledger or corpus consumes I03 records yet
no default authority or routing behavior changed
```

## 7. Relevance To The DISSOLVE Hypotheses

The two current hypotheses remain separate:

```text
L1-DISSOLVE:
  irreversible difference production and bounded identity projection

L2-DISSOLVE:
  semantic garbage collection and paid release of unsupported form
```

I03 supplies the causal unit needed to test them later. A future experiment can
now require that a claimed DISSOLVE effect belongs to one exact selected route,
one committed transition and one successful destination tick. It cannot yet
say whether either hypothesis is true.

The immediate next slice remains I04: consume these records into a pure
physical `edge_stats.v3` channel without granting promotion authority.
