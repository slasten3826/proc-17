# Versioned Witness Table Observation - 2026-07-17
Status:

```text
chaos / table observation plus direct runtime diagnostic
observes:
  docs/01_table/yellowprints/blocked_lineage_yellowprint.v0.md Amendment A1
  docs/01_table/yellowprints/pressure_witness_versioned_coverage_yellowprint.v0.md
  docs/01_table/yellowprints/tree_authority_promotion_corpus_yellowprint.v0.md Amendment A1
  docs/01_table/yellowprints/tree_authority_promotion_record_yellowprint.v0.md Amendment A1
result:
  blocked-lineage materialization law: coherent at table level
  upper-observation version coverage: coherent at table level
  relation coverage as routing treatment: incomplete
production code change authorized: no
crystallization authorized: no
corpus construction authorized: no
```

## 1. What The New Tables Closed

The blocked-lineage chain now has no missing embodiment stage:

```text
Packet birth
-> attach selected graves before first tick
-> FLOW materializes inherited failed form as child-local field unit
-> repair pressure and ☷ readiness name the same unit/version refs
-> ☷ directly dissolves the form
-> immutable release record discharges pressure
```

The direct unit target matches the existing field right granted to ☷ and the
older `relation or form` DISSOLVE contract. No synthetic relation is required.

The dual truth boundary is also coherent:

```text
ancestor failure fact              runtime_confirmed
child materialization event        runtime_confirmed
applicability to current child     grave_pressure
```

The versioned upper-observation proposal closes a real blind spot. An eye that
stores `{unit id, version}` can detect CHOOSE suppression, ENCODE remap/new
identity, and DISSOLVE release without returning to global revision staleness.

## 2. New Finding During Observation

The proposed shared root cause was too broad for `relation_debt`.

Fable proposed:

```text
global relation epoch staleness
-> replace with per-object version coverage
-> recurrent relation debt disappears
```

Current runtime actually derives relation debt by comparing live/selected unit
IDs against the raw relation snapshot's `source_refs`. After OBSERVE creates a
new unit, that unit is genuinely uncovered. Per-object versions improve the
comparison but produce the same missing-object result.

## 3. Runtime-Confirmed Diagnostic

The diagnostic used real Packet, FLOW, OBSERVE, CONNECT, field, pressure, and
tree-router modules with the fake substrate:

```text
FLOW
-> OBSERVE
-> CONNECT, coverage=2
-> OBSERVE, appends third unit
-> pressure.derive(current=☴)
-> tree_router.predict
```

Output:

```text
connect_covered=2
relation_debt -> ☰ refs=1
encoding_debt -> ☵ refs=3
selected=☰
reason=highest_pressure_canonical_tie_break
viable ☰ total=1
viable ☵ total=1
```

This is not a stale-global-revision artifact. The latest observed unit has
never been inspected by CONNECT.

## 4. Why This Matters

The versioned table's C1-C4 controls require current ☴ with fresh relation
coverage plus another need. Under the current OBSERVE contract, reaching ☴ and
executing it always appends a new live sensor-output unit. Relation coverage is
therefore incomplete again before route derivation.

Binary pressure then produces simultaneous valid votes:

```text
relation coverage gap   -> ☰ = 1
encoding need           -> ☵ = 1
choice need             -> ☳ = 1
runtime consequence     -> ☱ = 1
rigidity                -> ☷ = 1
```

When ☰ is among the tied candidates, canonical order favors it. Version maps
do not decide which valid need is stronger.

## 5. Correct Layer Split

The older pressure-repair chaos already supplied the missing distinction:

| Layer | Current fact |
|---|---|
| Record | Unit N exists at version V |
| Freshness | Unit N/V is absent from relation coverage |
| Witness | OPEN: does that gap require CONNECT before another transform? |
| Pressure | OPEN: how does relation work compete with encoding, choice, runtime, or rigidity? |

Per-object coverage repairs record/freshness. It does not automatically repair
witness/pressure.

## 6. Open Architecture Decision

Two serious models remain.

### Model R1 - Coverage gap is not yet relation pressure

```text
relation_coverage_gap is a body fact
relation_need requires an additional structural/declared witness
only relation_need contributes toward ☰
```

This preserves direct OBSERVE exits but must define how the body detects actual
relation need without secretly running CONNECT inside the pressure reader.

### Model R2 - Coverage gap is valid relation pressure

```text
every new addressable unit creates some positive ☰ pressure
other simultaneous needs may still be stronger
```

This requires a measured magnitude/composition law after witness repair.
Binary one-vote scoring cannot express it, and canonical tie-break is not a
physical substitute.

The rejected shortcut is to mark OBSERVE output non-addressable merely to
silence ☰. That would hide real relation work and falsify E05.

## 7. Consequence For The Promotion Sequence

The blocked-lineage table may proceed to a later crystall after this table
observation is externally checked.

The witness table may not yet feed a full crystall:

```text
upper-sight branch       coherent candidate
relation coverage branch partial
relation witness law     missing
pressure composition     missing if R2 is selected
C1-C5 route controls     currently red/unreachable honestly
```

The corpus and promotion record remain correctly blocked. The 38/38 rule is
not relaxed.

## 8. Questions For External Audit

```text
Q1. Do you agree that current relation_debt is ID/source-ref based rather than
    caused solely by global source_revision inequality?

Q2. Is every newly observed live unit itself sufficient relation pressure, or
    only a coverage/freshness fact?

Q3. If it is sufficient pressure, what non-vibed magnitude/composition law lets
    legitimate ENCODE/CHOOSE/RUNTIME/DISSOLVE pressure beat it when warranted?

Q4. If it is not sufficient pressure, what Packet-owned evidence establishes
    relation_need without executing CONNECT inside the pressure reader?

Q5. Should witness repair split into W0 object coverage and W1 pressure
    composition before the promotion corpus?
```
