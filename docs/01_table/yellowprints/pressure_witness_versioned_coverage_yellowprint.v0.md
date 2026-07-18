# Pressure Witness Versioned Coverage Yellowprint v0

Status:

```text
table / pre-corpus witness repair
transition step: 4.3B-W before corpus crystallization
same physical principle as runtime camera treatment:
  time  -> monotonic frame sequence plus reconciliation watermark
  space -> object identity plus version-at-coverage
sources:
  docs/00_chaos/pressure_witness_repair_notes.md
  docs/00_chaos/runtime_camera_treatment_results_2026-07-16.md
  docs/00_chaos/promotion_tables_materialization_and_witness_audit_2026-07-17.md
  docs/00_chaos/fable_response_materialization_witness_2026-07-17.md
production code change authorized: no
corpus construction authorized: no
pressure weight calibration authorized: no
router promotion authorized: no
```

## 1. Purpose

This table repairs two different witness degeneracies before the promotion
corpus is grown:

```text
relation_debt
  conditional in code but recurrent over common post-OBSERVE states

upper_observation_debt
  insufficiently sensitive to versioned mutations of already known units
```

The repair is not a new score and not a larger weight. It gives both witnesses
a fact-shaped answer to one question:

```text
which exact Packet object changed or remains uncovered for this reader?
```

## 2. One Camera Principle, Two Axes

| Axis | Coarse signal rejected as sufficient | Selected coverage law | Debt condition |
|---|---|---|---|
| Time / lower body | Any runtime revision moved | Frame sequence plus reconciliation watermark | Significant frame exists above watermark |
| Space / relations | Global potential revision moved | Relation coverage `{unit id, version}` | Addressable current unit missing/stale in relation coverage |
| Space / upper sight | Unit id was once in scope | Observation coverage `{unit id, version}` | Upper-visible or newly changed known unit missing/stale in sight coverage |

Global revision axes remain useful telemetry and scan triggers. They are not
proof that a particular organ has unpaid work.

```text
revision changed       -> inspect the relevant object domain
object delta found     -> emit a witness with exact refs
no object delta found  -> emit no debt
```

## 3. Shared Bounded Coverage Contract

Stored coverage uses deterministic ordered entries, not an unordered Lua map:

```lua
{
  protocol_version = "object-version-coverage.v0",
  domain = "relation" | "upper_observation",
  entries = {
    {
      object_kind = "field_unit",
      object_id = string,
      version = integer,
      activation_at_coverage = string,
      source_ref = string,
    },
  },
  total_count = integer,
  stored_count = integer,
  truncated = boolean,
  global_revision_at_capture = integer,
  capture_event_ref = string,
  event_truth_status = "runtime_confirmed",
}
```

Ordering follows `field.unit_order`, then stable object id for any non-field
extension. A derived lookup map may be built transiently by a reader; it is not
a second mutable truth store.

Boundedness law:

```text
truncation is visible
an object omitted by truncation is never silently considered covered
freshness cannot be claimed beyond the stored coverage boundary
```

Coverage confirms that the body read object version N. It does not promote the
object's semantic content truth.

## 4. Relation Coverage Domain

### 4.1 Domain membership

Relation coverage considers generation-local addressable units whose current
activation is:

```text
live
selected
```

Suppressed or dissolved units do not require a new relation epoch merely by
existing. If they later become addressable through a legal new identity or
state, they re-enter as current objects under that event's law.

### 4.2 CONNECT snapshot write

Every raw relation epoch stores exact version coverage for every considered
addressable unit, including units for which CONNECT found no relation:

```lua
raw_relation_snapshot.coverage.unit_versions = object_version_coverage
```

The existing global `source_revision` remains capture provenance and an
atomic-write guard. It is no longer the sole freshness or completeness test.

### 4.3 Relation-debt read

For each current addressable unit:

| Coverage state | Contribution result |
|---|---|
| Same id and same version | No debt for that unit |
| Id absent | `relation_debt` names missing unit/version |
| Id present with older version | `relation_debt` names stale unit and both versions |
| Unit now suppressed/dissolved | Outside relation-debt domain |
| Coverage truncated before unit | Debt names uncovered unit and truncation ref |

One contribution may summarize several uncovered units, but its bounded
`source_refs` and counts must preserve the exact domain delta.

### 4.4 CONNECT reader closure

CONNECT readiness independently computes the same uncovered/stale domain and
returns those unit/version refs. A selected CONNECT tick writes a new coverage
epoch over those objects.

```text
pressure says which units lack relation coverage
readiness confirms those same units are actionable
CONNECT discharges the debt by covering them
```

CONNECT may discover zero relations and still discharge coverage debt when it
honestly inspected all named units. Empty recognition is not failed sight.

## 5. Upper-Observation Coverage Domain

### 5.1 Domain membership

Upper sight considers:

```text
all current generation field units that are live or selected
plus any unit covered by the previous upper observation whose version advanced
  into suppressed or dissolved state and has not yet been observed at that version
```

The second clause is essential. Relation coverage may stop caring about a
suppressed unit, but OBSERVE must see the fact that a previously visible unit
was suppressed before the change can be considered observed.

After an observation covers that suppressed/dissolved version, the unit no
longer creates debt unless its version changes again.

### 5.2 Observation write

The upper observation envelope gains bounded version coverage:

```lua
observation.read_units = object_version_coverage
```

It includes:

```text
every field unit in the actual observation scope
the planned sensor-output unit at its created version
explicit missing/truncated scope
```

The planned sensor output is covered at version 1 by the same transaction that
records the observation and creates the unit. OBSERVE therefore does not make
itself stale merely by producing its own output.

### 5.3 Upper-observation-debt read

| Current object state | Contribution result |
|---|---|
| Same id/version covered | No upper debt |
| New upper-visible unit | Debt names id/version |
| Covered unit version advanced | Debt names id, covered version, current version |
| Covered unit became suppressed/dissolved | One debt until that new version is observed |
| Budget/loss/clock changed but field units did not | No upper debt |
| Coverage truncated before relevant object | Debt names missing scope/truncation |

### 5.4 OBSERVE reader closure

OBSERVE readiness returns the same missing/stale unit-version refs that support
the pressure contribution. The OBSERVE call scope includes those refs; a
generic always-ready substrate call is not sufficient reader closure.

The substrate may describe their semantics, but the body owns coverage and the
fact that a version was or was not inspected.

## 6. Matched Relation Controls

Each state is grown from the previous state with one declared variable change.

| ID | Packet state | Expected witness | Expected reader/result |
|---|---|---|---|
| A1 | Two live units; fresh CONNECT epoch covers both current versions | `relation_debt` absent | CONNECT may be ready for another reason, but not these units |
| A2 | A1 plus one new live unit after the epoch | Debt present; refs name exactly new unit/version | CONNECT readiness names same unit |
| A3 | A2 plus CONNECT executes a covering epoch | Debt absent | New coverage stores all three current versions |
| A4 | A2 but new unit becomes suppressed or dissolved before CONNECT | Debt absent for removed unit | CONNECT readiness does not claim it as addressable debt |

Required additional assertion:

```text
an unrelated global potential revision with no relation-domain object delta
does not recreate relation_debt
```

## 7. Matched Upper-Sight Controls

| ID | Packet state | Expected witness | Expected reader/result |
|---|---|---|---|
| B1 | OBSERVE runs; no field mutation follows | Upper debt absent | Own sensor output is covered at created version |
| B2 | B1 plus ☳ suppresses one covered unit | Debt present; refs name unit and old/new versions | OBSERVE readiness names same changed unit |
| B3 | B2 plus OBSERVE covers the suppressed version | Debt absent | New observation stores current version |
| B4 | B1 plus budget/loss/clock movement only | Debt absent | No field object delta exists |

Additional required cases before full corpus:

| ID | Mutation | Required witness |
|---|---|---|
| B5 | ☵ creates/remaps a new formed unit | Upper debt names new/remapped unit identity |
| B6 | ☷ dissolves a previously covered inherited form | Upper debt names dissolved version/release ref |

## 8. Route-Competition Controls

Matched witness tests prove sensors. Route controls prove those sensors can
govern motion without deleting every competitor.

| ID | Prepared state | Required selected direction |
|---|---|---|
| C1 | Fresh relation coverage plus encoding need | `☴ -> ☵` from encoding witness |
| C2 | Fresh relation coverage plus at least two alternatives | `☴ -> ☳` from choice witness |
| C3 | Fresh relation coverage plus significant unreconciled runtime consequence | `☴ -> ☱` from reconciliation witness |
| C4 | Fresh relation coverage plus one runtime-confirmed rigid form | `☴ -> ☷` from rigidity witness |
| C5 | Uncovered addressable unit with other ready neighbors present | `☴ -> ☰` from relation witness |
| C6 | Post-CHOOSE version change with other ready neighbors present | Adjacent operator `-> ☴` from upper-sight witness |

For C1-C6:

```text
competitors remain available and readiness-audited
the intended witness has exact source refs
the selected target does not win solely by canonical tie-break
removing only the intended body fact changes or removes the contribution
```

E07 `☴ -> ☷` is explicitly included. With recurrent relation debt, ☰ shadows
☷ in a binary tie because ☰ precedes ☷ in canonical order.

## 9. Reader And Truth Matrix

| Record | Writer | Named reader | Truth boundary |
|---|---|---|---|
| Relation unit-version coverage | ☰ CONNECT | relation-debt reader, CONNECT readiness, relation consumers | Coverage event confirmed; semantic relation content unchanged |
| Upper unit-version coverage | ☴ OBSERVE/body observation API | upper-debt reader, OBSERVE readiness | Observation event confirmed; represented content retains own status |
| Inherited failed-form unit | ▽ FLOW | repair-rigidity reader, ☷ readiness | Materialization confirmed; applicability remains grave pressure |
| Repair release record | ☷ DISSOLVE | upper-debt reader, repair-pressure discharge | Release confirmed; ancestral applicability is not rewritten |

Every pressure source must resolve to a stored Packet object/version or an
immutable event that names it. A global revision number alone is insufficient
provenance for these witnesses.

## 10. False-Green Matrix

| False green | Rejecting assertion |
|---|---|
| Store IDs without versions | B2 must fail until versions are stored/read |
| Add a second mutable semantic-change ledger | Coverage must derive from field objects and immutable observations |
| Treat global revision inequality as debt | Unrelated-revision control emits no contribution |
| Treat any version difference as relation need | A4 removes suppressed/dissolved unit from relation domain |
| Let upper eye forget suppression | B2 requires one bounded sight debt |
| Let OBSERVE stale itself | B1 remains debt-free |
| Let budget movement request upper sight | B4 remains debt-free |
| Hide omitted objects behind a limit | Truncation remains explicit and cannot claim fresh coverage |
| Claim reader closure from generic readiness | Readiness refs must equal the witness object domain |
| Force route by excluding all competitors | C1-C6 retain available competitors |
| Win only by canonical order | Direction remains promotion-blocked |
| Tune weights before witness controls pass | Weight/calibration work remains forbidden |

## 11. Future Implementation Surface

This table predicts changes in:

```text
runtime/field.lua
  raw relation snapshot version coverage
  bounded deterministic coverage helpers

runtime/body.lua
  upper observation read_units coverage

organs/connect.lua
  exact relation-domain readiness and coverage write

organs/observe.lua
  exact upper-sight scope and own-output version coverage

runtime/pressure.lua
  relation_debt and upper_observation_debt object-version comparison

runtime/operator_registry.lua
  readiness source refs aligned with witness domains

tests
  A1-A4, B1-B6, C1-C6 matched controls and observer ablations
```

The crystall stage chooses concrete helpers and transaction rollback behavior.
This table does not authorize implementation.

## 12. Pre-Corpus Gate

Corpus fixture construction remains blocked until:

```text
A1-A4 pass
B1-B6 pass
C1-C6 pass for the directions their organs can already execute
stored coverage is bounded and deterministic
global revisions are telemetry/scan triggers, not sole witness truth
pressure and readiness consume the same object-version refs
own-output and budget-only camera regressions remain absent
no selected route is justified only by canonical tie-break
observer ablation changes instrumentation only
```

Passing this gate proves witness shape and route eligibility. It does not prove
38/38 edge closure, pressure weight optimality, live substrate quality, or
default tree authority.

## Observation O1: Relation Coverage Is Necessary But Not Sufficient

Status:

```text
PARTIALLY CONFIRMED BY CODE INSPECTION AND DIRECT RUNTIME DIAGNOSTIC
date: 2026-07-17
upper-observation version treatment: retained for crystall consideration
relation object coverage: retained as record/freshness contract
relation coverage as sufficient routing witness: rejected
route controls C1-C5: blocked pending another table decision
corpus construction: remains forbidden
```

### O1.1 Reproduction

A direct local body diagnostic executed:

```text
FLOW
-> OBSERVE                 two units now exist
-> CONNECT                 raw epoch covers both units
-> OBSERVE                 one new live sensor-output unit is appended
-> derive pressure at ☴
```

Observed:

```text
relation_debt -> ☰   amount=1   refs=1
encoding_debt -> ☵   amount=1   refs=3
selected=☰
reason=highest_pressure_canonical_tie_break
```

The new sensor-output unit is genuinely absent from the preceding relation
coverage. Replacing ID coverage with ID/version coverage does not remove that
fact.

### O1.2 Root-cause correction

The current `relation_debt` reader does not derive debt solely from global
`source_revision != revisions.potential`. It compares current live/selected
unit IDs against `raw.source_refs`. Global revision equality is used elsewhere
as a snapshot/activation guard, but it is not the complete cause of the
post-OBSERVE route vote.

Per-object versions repair overly broad relation staleness and make provenance
precise. They do not answer whether a newly uncovered unit must make CONNECT
more urgent than ENCODE, CHOOSE, RUNTIME, or DISSOLVE.

The unresolved layers are:

```text
record:     a new unit is absent from relation coverage
freshness:  the relation epoch is incomplete for current addressable potential
witness:    whether this gap requires relation work before another transform
pressure:   how that need competes with simultaneous encoding/choice/etc. need
```

The first two are repaired by versioned coverage. The latter two are not.

### O1.3 Effect on this table

Sections 3-7 remain useful as coverage and upper-sight contracts. Section 8 is
not yet an executable pre-corpus gate for exits from OBSERVE:

```text
C1-C4 assume fresh relation coverage at current ☴
current OBSERVE always appends a new live unit
that unit honestly recreates relation coverage debt
binary.v0 ties then favor canonical ☰
```

C5 remains a valid positive CONNECT case but does not prove when CONNECT should
yield to another simultaneous pressure. C6 remains a valid upper-sight
hypothesis.

No C1-C5 case may be marked green by suppressing the new unit, excluding ☰ by
harness configuration, or increasing a weight before the missing witness law
is tabled.

### O1.4 Open treatment classes

| Treatment class | Consequence | Current status |
|---|---|---|
| Every uncovered unit must visit CONNECT first | Makes direct post-OBSERVE exits structurally unreachable in ordinary lives | Conflicts with current full-tree claim unless topology/authority is revised |
| Split `relation_coverage_gap` from `relation_need` | Coverage remains fact; only evidence of actual relation work creates route pressure | Preferred question, but relation-need evidence is not yet defined |
| Keep coverage pressure and introduce measured magnitude/specificity | Simultaneous valid needs can outrank one another without canonical tie | Possible only after witness shape; requires its own table, not vibed weights |
| Make OBSERVE output non-addressable by default | Silences relation debt by classification | Risks hiding real E05 relation work; not selected |

The next table observation must decide whether coverage gap is itself a
pressure witness or only input to a more specific relation-need witness. If the
gap remains pressure, a separate magnitude/composition law is required before
C1-C4 can pass.

### O1.5 Revised pre-corpus state

```text
A1-A4                  useful but insufficient for route authority
B1-B6                  retained as next crystall candidate
C1-C5                  red/open
C6                     pending
W0 relation branch     blocked
W0 upper-sight branch  table-complete, not runtime-confirmed
```

This observation does not weaken 38/38. It explains why the gate cannot yet be
attempted honestly.
