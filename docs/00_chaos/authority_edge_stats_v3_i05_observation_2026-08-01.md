# Authority Edge Stats v3 I05 Observation

```text
layer: CHAOS
date: 2026-08-01
status: runtime_observation
source blueprint:
  docs/02_crystall/blueprints/authority_epoch_edge_credit.v0.md
slice: I05 promotion channel and atomic merge
source baseline commit: 1d3433a
implementation commit: pending
body integration: none
promotion decision: still forbidden
```

## 0. Result

I05 adds the second channel to the pure v3 ledger:

```text
physical:
  what route phases actually happened

promotion:
  which executed route is admissible evidence for a declared authority epoch
```

Promotion reads only immutable edge-credit selection records and their final
arrival decisions. It does not read current pressure code, rerun eligibility,
move a Packet or alter a physical counter.

The module also gains exact-epoch atomic merge. Merge is evidence arithmetic,
not authority promotion.

## 1. Changed Surface

Extended:

```text
runtime/edge_credit.lua
  verify_record(detached_record)
  is_eligibility_reason(reason)

runtime/edge_stats_v3.lua
  promotion projection
  invalid-ledger classification
  exact-epoch transactional merge

tests/test_edge_stats_v3.lua
  historical I04 physical controls now observe the I05 promotion reader
```

New:

```text
tests/test_edge_stats_v3_promotion.lua
```

Unchanged:

```text
runtime/edge_stats.lua remains v2
runtime/tension_runner.lua has no v3 import
Packet/body/router/pressure authority unchanged
```

## 2. Promotion Phase Law

The implemented temporal law is:

```text
eligible immutable selection
  -> eligible_selected_count

matching commit while the ledger remains valid
  -> eligible_committed_count

matching successful arrival + matching credited final decision
  -> eligible_executed_count
  -> promotion_status eligible_executed

matching rejected final decision
  -> ineligible_executed_count
  -> closed rejection reasons

missing classification, missing required source or inconsistent decision
  -> unclassified_executed_count
  -> ledger invalid
```

Selection and commit are potential credit only. Neither closes direction
coverage. The one-way E03 control becomes promotion-complete only after the
credited arrival.

## 3. Runtime-Confirmed Separation

The targeted controls establish:

1. Eligible, ineligible and unclassified execution all remain physically
   executed.
2. Rejected execution cannot increment eligible execution.
3. Missing source cannot borrow a valid-looking final decision.
4. A later invalid phase does not erase earlier physical or potential-credit
   records.
5. Invalid ledger status suppresses edge-level promotion coverage without
   rewriting historical counters.
6. Promotion refs are verified subsets of their physical phase refs.
7. Unknown eligibility reasons cannot enter a verified or merged ledger.

## 4. SE06 And SE07

SE06 is now executable:

```text
required destination effect source omitted
-> arrival remains physical
-> source_evidence_unresolved
-> ledger invalid
-> unclassified execution
-> zero eligible execution
```

SE07 is enforced at both local and merge boundaries:

```text
same source key + changed payload
-> source_evidence_conflict
-> attempted transaction unchanged

malformed or unresolved source ledger
-> merge rejects before target mutation
```

## 5. Atomic Merge Law

Accepted merge requires:

```text
both protocol_version = edge-stats.v3
both ledgers verify and are valid
exact evidence_epoch_id equality
exact authority epoch payload equality
same 22-edge authority surface
disjoint life_id sets
disjoint route and source identities
closed eligibility vocabulary
```

The operation is:

```text
preflight target and source
-> deep-copy target
-> add source lives, sources, routes and counters
-> derive coverage/status
-> verify complete working ledger
-> replace target contents
```

Every rejection leaves the target byte-equivalent to its pre-merge snapshot.

## 6. Merge Controls

Runtime-confirmed pure-module controls:

```text
EM01 same exact evidence epoch:
  physical and promotion channels sum

EM02 binary plus qualified:
  evidence_epoch_mismatch

EM03 canonical plus consumer-ablated:
  evidence_epoch_mismatch

EM04 observer arrangement on/off:
  raw merge rejects
  corpus pair half remains I06

EM05 v2 plus v3:
  edge_stats_protocol_mismatch

EM06 changed source payload:
  reject, target unchanged

EM07 unknown eligibility reason:
  reject, target unchanged

EM08 Plan plus Build in same epoch:
  merge, both life sources retained

EM09 implementation revision closure:
  deferred to corpus I06 as specified

EM10 malformed source halfway:
  reject, target unchanged

EM11 same life merged twice:
  life_source_overlap, target unchanged
```

## 7. Test Evidence

```text
lua tests/test_edge_stats_v3_promotion.lua
  promotion temporal controls: green
  eligible/ineligible/unclassified controls: green
  SE06-SE07: green
  EM01-EM08 and EM10-EM11 local portions: green

lua tests/test_edge_stats_v3.lua
  physical and bounded-source controls: green

lua tests/test_edge_credit.lua
  green

lua tests/test_edge_evidence.lua
  existing v2 path: green

lua tests/test_edge_metric_roles.lua
  observer/rail roles: green

lua tests/run.lua
  119 suites: green

lua tests/smoke_mortality_battery.lua
  8/8: green
```

QA matrix:

```text
all QA suites in full run: green
QA implementation changed: no
```

Packet ablation:

```text
status: structurally exact for I05
reason:
  v3 remains unreachable from runner and Packet body
observed off/v3 digest pair: deferred to I07
```

## 8. Known Red Controls

I06 remains absent:

```text
edge_life_projection.v0
required case manifest
implementation provenance
observer off/on post-life pairs
edge corpus and closure
SE08
EM04 corpus-pair acceptance
EM09 implementation-revision closure rejection
```

I07 remains absent:

```text
authority_instrument = v3 opt-in runner path
body-grown EC02/EC05/EC06/EC11
source bundles from real Packet events
exact off/v3 Packet/corpse ablation
real DISSOLVE route measurement
```

No current result authorizes:

```text
default v3 cutover
Tree authority promotion
DISSOLVE semantic change
DISSOLVE hypothesis confirmation
```

## 9. Immediate Next Slice

I06 builds the durable after-life layer: bounded body projections, required
case manifest and a corpus that can compare observer pairs without retaining a
live Packet. I07 then connects the already verified measurement chain to real
runner lives behind an explicit opt-in switch.
