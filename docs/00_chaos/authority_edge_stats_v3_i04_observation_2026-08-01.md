# Authority Edge Stats v3 I04 Observation

```text
layer: CHAOS
date: 2026-08-01
status: runtime_observation
source blueprint:
  docs/02_crystall/blueprints/authority_epoch_edge_credit.v0.md
slice: I04 pure edge-stats.v3 physical channel
source baseline commit: 1d3433a
implementation commit: pending
body integration: none
promotion writer: absent by design
```

## 0. Result

I04 creates a pure `edge-stats.v3` ledger beside the still-authoritative v2
implementation. The new module does not run inside `tension_runner` and cannot
change Packet movement.

The physical chain now has named, non-overlapping writers:

```text
Tree derivation -> candidate
edge-credit selection -> selected
Packet route commit -> committed
successful destination tick -> executed
typed destination failure -> failed
host tick_limit -> pending_at_host_ceiling
```

No observer prediction contributes to those physical counters. No I04 API
writes a promotion counter.

## 1. Changed Surface

New:

```text
runtime/edge_stats_v3.lua
tests/test_edge_stats_v3.lua
```

Extended reader contract:

```text
runtime/edge_credit.lua
  edge_credit.verify_record(detached_record)
```

The record verifier leaves digest ownership with the module that minted the
record. `edge_stats.v3` does not reconstruct a second edge-credit identity
algorithm.

Test registry:

```text
tests/run.lua
```

Unchanged runtime authorities:

```text
runtime/edge_stats.lua remains edge-stats.v2
runtime/tension_runner.lua remains on its existing v2 path
router default unchanged
Packet trace unchanged
```

## 2. New Protocol Records

```text
edge_statistics / edge-stats.v3
edge_evidence_life_source
edge_source_evidence / edge-source-evidence.v0
edge_route_phase_index
physical direction channel
zeroed promotion direction channel
epoch-bounded observer records
epoch-bounded rail records
authority_instrument_error
authority_instrument_error_overflow
```

The ledger contains all 22 canonical edges and all 38 legal directions from
birth. Unvisited directions remain explicitly `untested`.

## 3. Runtime-Confirmed Physical Laws

The targeted controls establish:

1. Candidate, selected, committed, executed, failed and pending are separate
   phases with separate sole writers.
2. One route phase cannot be replayed or terminalized twice.
3. Failure and host-ceiling pending never increment execution.
4. Observer predictions retain observer and rail roles but have zero physical
   candidate mass.
5. Tree derivations retain the authoritative rail role but do not invent a
   selected phase.
6. Every route phase is joined through one `route_evidence_id`, life and route
   ordinal rather than array position.
7. Detached edge-credit records are verified by `runtime.edge_credit`; a
   changed record with its old id is rejected transactionally.
8. Transactional replacement makes stale nested Lua references harmless: a
   caller must re-read the current ledger after every successful write.

## 4. Source Evidence Controls

Runtime-confirmed controls from the I04 subset:

```text
SE01 source owner discarded:
  stored evidence remains resolvable and verifies

SE02 exact life/kind/original-id/payload replay:
  one evidence record, no duplicate byte charge

SE03 same key with changed payload:
  source_evidence_conflict, whole transaction unchanged

SE04 function/userdata/thread/metatable/live Packet:
  source_evidence_not_plain, whole transaction unchanged

SE05 caller mutates payload after recording:
  stored source payload and digest remain unchanged

SE09 count/single-record/aggregate-byte overflow:
  physical phase remains visible
  source is omitted
  omission economics increase
  ledger becomes invalid
  promotion remains impossible
```

An omitted selection source does not erase a later physical commit. Once the
ledger is invalid, later phases may remain physically visible while refusing
classification. This is distinct from a conflicting payload, which rejects
the entire attempted transaction.

## 5. Bounds And Error Memory

Effective bounds come from the verified authority epoch:

```text
max_source_records
max_single_source_bytes
max_source_bytes_per_life
max_projection_bytes
max_error_records
```

Source bytes are normalized `source_record` JSON bytes. Instrument transport
cost never enters Packet budget or loss. The final error slot is reserved for
one digest-chained overflow aggregate, so repeated diagnostics cannot create
unbounded error memory.

## 6. Test Evidence

```text
lua tests/test_edge_stats_v3.lua
  physical phase controls: green
  observer/rail role controls: green
  SE01-SE05 and SE09: green
  forged detached credit control: green
  source-bound continuation control: green

lua tests/test_edge_credit.lua
  green

lua tests/test_edge_evidence.lua
  existing edge-stats.v2: green

lua tests/test_edge_metric_roles.lua
  existing observer/rail roles: green

lua tests/test_authority_epoch.lua
  green

lua tests/test_eligibility_carry.lua
  green

lua tests/run.lua
  118 suites: green

lua tests/smoke_mortality_battery.lua
  8/8: green
```

QA matrix:

```text
all QA suites in the full run: green
QA modules changed: no
```

Packet ablation:

```text
status: structurally exact for I04
reason:
  runtime/edge_stats_v3 is not imported by the runner or Packet body
  runtime/edge_stats.lua remains v2
observed off/v3 Packet digest: not yet available
required slice for observed pair: I07
```

## 7. Epoch Identities Observed

The I04 controls reuse the verified qualified Tree epoch:

```text
physics_epoch_id:
  sha256:4f490b981531b8c8a1e1757df9851b435f9aef30c2b080e55402cec28a265b90
evidence_epoch_id:
  sha256:7af91634d1d298e95c767220370a89f97c0673b46158af7d3d437e9c2ffb19e1
```

Bound variants produce distinct evidence epochs through their instrumentation
configuration while retaining the same physical epoch. No unlike epoch is
merged in I04.

## 8. Known Red Controls

Still open by explicit slice order:

```text
I05:
  eligible/ineligible/unclassified promotion channels
  SE06 missing-required-source classification
  SE07 merge source conflict
  EM01-EM11 except corpus-only EM09
  exact-epoch atomic merge

I06:
  durable post-life projection
  case manifest
  corpus and observer pairs
  SE08

I07:
  opt-in runner integration
  body-grown EC02/EC05/EC06/EC11
  observed off/v3 Packet ablation digest
```

The following claims remain forbidden now:

```text
promotion coverage is complete
v3 is the current body authority
the instrument has observed a real DISSOLVE route
the DISSOLVE hypotheses are runtime-confirmed
```

## 9. Immediate Next Slice

I05 may now consume the immutable selection eligibility and final credit
decision into a promotion channel. It must add atomic exact-epoch merge without
changing any physical fact already recorded by I04.

Only after I07 can the instrument observe the current DISSOLVE implementation.
That future observation will have a place to land without being mistaken for a
route decision or a semantic law.
