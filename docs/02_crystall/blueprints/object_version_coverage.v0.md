# Object-Version Coverage Blueprint v0

Status:

```text
crystall / roadmap step 3 contract 3 of 4
date: 2026-07-18
table: docs/01_table/yellowprints/pressure_witness_versioned_coverage_yellowprint.v0.md
amended by: docs/00_chaos/versioned_witness_table_observation_2026-07-17.md
implementation authorized by this document: no
pressure contribution authority: forbidden until roadmap step 5
```

## 0. Selected Law

The runtime camera solved freshness in time with a frame sequence and watermark.
Object coverage applies the same law in space:

```text
object identity + version-at-read -> exact bounded coverage
global revision                  -> scan hint, never sufficient witness
stored coverage + current field  -> derived missing/stale delta
```

Coverage answers what a reader has inspected. It does not by itself answer how
urgent another operation is.

## 1. Target Modules

```text
runtime/object_coverage.lua       NEW: canonical capture/diff/ref helpers
runtime/field.lua                 ordered coverage domains
runtime/body.lua                  observation envelope integration
organs/connect.lua                raw probe coverage writer/reader
organs/observe.lua                upper coverage writer/reader
runtime/pressure.lua              unchanged until roadmap step 5
runtime/operator_registry.lua     readiness may use exact deltas in step 4
tests/test_object_coverage.lua    matched record/freshness controls
```

No second mutable object-change ledger is introduced.

## 2. Coverage Record

```lua
{
  protocol_version = "object-version-coverage.v0",
  domain = "relation" | "upper_observation",
  policy_id = string,
  entries = {
    {
      object_kind = "field_unit",
      object_id = string,
      version = integer,
      activation_at_coverage = "live" | "selected" | "suppressed" | "dissolved",
      source_ref = string,
    },
  },
  total_count = integer,
  stored_count = integer,
  omitted_count = integer,
  truncated = boolean,
  global_revision_at_capture = integer,
  capture_event_ref = string | nil,
  event_truth_status = "runtime_confirmed",
}
```

Entries follow `field.unit_order`; any future non-unit extension uses stable id
ordering after units. Duplicate object ids are invalid. Versions are integers
`>=1`.

Truncation is visible and conservative:

```text
omitted object is uncovered
truncated coverage can never claim complete freshness
```

Coverage truth confirms the act of reading versions. It preserves each unit's
own semantic content status.

## 3. Public Helper API

```lua
local coverage = require("runtime.object_coverage")

record, err = coverage.capture(entries, options)
delta, err  = coverage.diff(record, current_entries, options)
refs        = coverage.source_refs(delta)
equal       = coverage.same_delta(left, right)
```

`capture` and `diff` are pure over owned copies. They do not read or mutate a
Packet directly.

Delta shape:

```lua
{
  kind = "object_version_delta",
  domain = string,
  missing = {{object_id=string, current_version=integer}},
  stale = {{object_id=string, covered_version=integer, current_version=integer}},
  departed = {{object_id=string, covered_version=integer, current_activation=string|nil}},
  uncovered_by_truncation = integer,
  changed_count = integer,
  source_refs = string[],
  event_truth_status = "runtime_confirmed",
}
```

The delta is derived and ephemeral. It is not stored as another source of truth.

## 4. Field Domain API

```lua
entries, meta_or_err = field.coverage_domain(instance, domain, options)
```

For `domain="relation"`:

```text
current generation only
activation live or selected
ordered by field.unit_order
```

For `domain="upper_observation"`:

```text
all current generation live/selected units
plus a previously covered unit whose version advanced into suppressed/dissolved
until that exact changed version is observed once
```

The prior upper coverage is input to domain derivation; no persistent
`needs_observation` flag is added to a unit.

## 5. Relation Probe Stamp

Every `field.raw_relations.v1` epoch stores relation-domain coverage even when it
contains zero relations.

```text
writer: CONNECT
first reader: CONNECT readiness
secondary future reader: relation freshness/pressure in roadmap step 5
```

CONNECT readiness computes the current domain and diffs it against the raw
epoch's coverage under the same probe policy.

```text
empty delta + same policy -> no probe debt/readiness from coverage
missing/stale entry       -> exact probe readiness refs
unit leaves addressable domain -> no relation coverage debt for that unit
```

An unrelated potential revision with identical current entries does nothing.

Important boundary:

```text
relation coverage gap = runtime-confirmed freshness fact
relation pressure need = still an open scheduling law
```

Roadmap step 4 may use the first for exact readiness and fixture routes. It may
not silently restore the old binary `relation_debt` from every gap.

## 6. Upper Observation Stamp

Each upper observation envelope stores `read_units` coverage for its actual
scope.

```text
writer: OBSERVE/body observation commit
first reader: OBSERVE readiness
secondary future reader: upper_observation_debt in roadmap step 5
```

Required cases:

```text
new visible unit                    -> missing
covered unit version advanced       -> stale
covered unit became suppressed      -> one stale sight until covered
budget/loss/clock only changed       -> empty delta
unchanged current versions           -> empty delta
```

## 7. OBSERVE Own-Output Law

Semantic OBSERVE often creates one sensor-output field unit. It must not become
stale solely because it produced that output.

The implementation provides one body-owned commit operation, conceptually:

```lua
observation, unit_or_err = body.commit_upper_observation(instance, {
  observation = validated_observation,
  sensor_output = validated_unit_or_nil,
  planned_unit_id = string_or_nil,
})
```

Before its first append it validates the observation, planned deterministic unit
id, source event, bounds and coverage. The stored coverage includes the planned
output at version `1`; the operation then appends the event/unit synchronously
inside one trusted body call.

Expected input failures mutate nothing. An impossible failure after the first
append is a loud invariant failure, not partial success or Packet death. General
cross-organ rollback remains outside v0.

Body-native relation observation creates no sensor-output unit and therefore
captures only its exact current endpoint/scope versions.

## 8. Capture Event Reference

The parent trace event is the authority for a coverage capture. If its id is not
known until append, the body-owned stored projection may fill
`capture_event_ref=event.id` after the event is created. Readers also receive the
parent event id explicitly.

No caller may provide an arbitrary capture event ref. Body Integrity Gate actor,
tick and ownership checks remain mandatory.

## 9. Same-Ref Reader Closure

For every candidate reader:

```text
coverage.diff names exact object/version refs
readiness recomputes and returns the same refs
organ scope contains those refs
successful capture covers those refs
unchanged derivation no longer emits them
```

Source-ref equality is compared as a deterministic ordered set. A reader that
returns generic `field changed` has not closed the contract.

## 10. Matched Tests

| ID | One changed variable | Required result |
|---|---|---|
| OVC-A1 | Fresh relation coverage | Empty relation delta |
| OVC-A2 | Add one live unit | Missing exact id/version |
| OVC-A3 | CONNECT covers A2 | Delta disappears |
| OVC-A4 | Suppress A2 before CONNECT | Unit leaves relation domain; no relation delta |
| OVC-A5 | Move only global potential revision | Delta remains empty |
| OVC-B1 | OBSERVE creates own output | Output is already covered at version 1 |
| OVC-B2 | CHOOSE suppresses covered unit | Upper stale delta names old/new versions |
| OVC-B3 | OBSERVE covers suppressed version | Delta disappears once |
| OVC-B4 | Move only budget/loss/clock | Upper delta remains empty |
| OVC-B5 | ENCODE creates/remaps unit | Upper delta names new identity/version |
| OVC-B6 | DISSOLVE changes covered unit | Upper delta names released version |
| OVC-T1 | Truncate before relevant object | Freshness remains conservatively incomplete |

## 11. Step 5 Promotion Preconditions

This crystall does not authorize route competition. Before pressure consumes a
coverage fact:

```text
the fact varies in a grown body
readiness and writer consume the same refs
success discharges it
a competitor remains live
the intended target does not win only by canonical tie-break
removing only the fact changes the contribution
```

Relation coverage additionally needs a selected `relation_need` law. Coverage
alone is necessary but not sufficient.

## 12. Explicit Deferrals

```text
relation_need versus mere relation_coverage_gap
pressure magnitude/composition and age
tree-router weights/default authority
non-unit object domains
persisted coverage indexes
general transaction rollback
```

## 13. Acceptance

This crystall is implementation-ready when:

```text
coverage is bounded, deterministic and versioned
freshness derives from current objects, never a second ledger
global revisions are only scan hints
raw empty probes and upper sight have named readers
OBSERVE does not stale itself
suppression is visible once to the upper eye but leaves relation domain
coverage fact is not mislabeled as routing pressure
```
