# DISSOLVE P10 Evidence Blueprint v0

```text
layer: CRYSTALL
date: 2026-08-13
source table:
  docs/01_table/yellowprints/dissolve_p10_evidence_yellowprint.v0.md
implementation authorization: P10 direct inherited-form reader and tests only
pressure witness/action/organ change: forbidden; diagnostic precision only in section 8
general DISSOLVE semantics: unchanged
router/default authority change: forbidden
promotion decision: forbidden
```

## 0. Implementation Claim

Replace the obsolete P10 semantic predicate:

```text
any direction mentioning ☷ + any crystallization loss
```

with a pure join over already-written evidence:

```text
credited arrival into ☷
+ normalized unit_dissolution
+ exact target final state
+ exact residue final state
+ matched no-rigidity life
+ green observer pair
```

No writer, route, pressure contribution, readiness rule or organ effect is
changed by this blueprint.

## 1. Code Surface

Modify:

```text
runtime/edge_case_manifest.lua
tests/run.lua
```

Add:

```text
tests/test_dissolve_p10_evidence.lua
```

Amend documentation:

```text
docs/01_table/yellowprints/tree_authority_promotion_corpus_yellowprint.v0.md
docs/02_crystall/blueprints/authority_epoch_edge_credit.v0.md
docs/03_manifest/qualified_dissolve_inherited_form.v0.md
docs/03_manifest/current_state.md
```

Do not modify `organs/dissolve.lua`, pressure policy, edge credit or topology in
this slice.

## 2. Pure Reader Helpers

`runtime/edge_case_manifest.lua` adds private pure helpers equivalent to:

```lua
has_credited_arrival(life, "☷") -> boolean
direct_release_evidence(life) -> boolean
no_rigidity_control(primary, control) -> boolean
```

`direct_release_evidence` reads only the immutable life projection. It must:

```text
verify exactly one direct unit_dissolution payload
verify event actor/truth and canonical stored zero-cost boundary
resolve exact target and residue in final projected field
verify both schemas
join event id, release id, versions, activation and ancestor refs
return false on absence or contradiction
```

It does not throw for an honest semantic miss. Invalid corpus/projection shape
continues to use the existing typed instrumentation errors.

## 3. Control Evaluation Amendment

While resolving required controls, retain resolved lives by control kind. For
P10 after primary evaluation:

```text
each primary must have at least one no_rigidity control with:
  same work mode
  same exact prompt bytes
  no active inherited form
  no unit_dissolution
  no credited arrival into ☷
```

Missing controls remain `blocked`. Present but semantically false controls make
the case `red`.

No generic semantics are invented for other control kinds in this slice.

## 4. Version Boundary

Only P10 declares:

```text
evaluator_id = tree-authority.case.P10.unit_dissolution.v1
evaluator_version = edge-case-evaluator.p10.release.v1
```

The case-manifest digest therefore changes. The outer corpus protocol remains
v1 because its record shape does not change; its embedded current manifest
provides the semantic version boundary.

## 5. Grown Corpus Fixture

Grow three deterministic lives under frozen host time:

```text
A primary:
  real QA-rejected ancestor and recovery carrier
  Tree + qualified_need_v0
  legacy observer enabled
  E02 and unit_dissolution execute

B observer mirror:
  same Packet/prompt/lineage/generation/policy
  legacy observer disabled
  same E02 and unit_dissolution execute

C no-rigidity:
  same exact prompt bytes, work mode and Tree physics
  ordinary user/FLOW birth without NETWORK rejected form
  no DISSOLVE arrival/effect
```

Add A/B/C to an `authority_claim=diagnostic` corpus, add the A/B observer pair,
then evaluate P10 with C in the `no_rigidity` slot.

Expected:

```text
observer pair = green
P10 case = green
P10 evaluator refs resolve to A, B and C
full-tree promotion/closure = still blocked
```

## 6. False-Green Tests

Use verified detached life projections, not unverified literal tables:

```text
F1 unrelated boundary.loss_records + claimed ☷ direction, no event -> red
F2 positive release projection without eligible arrival -> red
F3 positive event with target restored live before projection -> red
F4 positive event with residue removed before projection -> red
F5 active-form control supplied as no_rigidity -> red
```

The grown positive test is the acceptance test; synthetic projection mutations
are hostile evaluator tests only and never promotion evidence.

## 7. Gates

```text
focused P10 test green
all Lua suites green
mortality battery 8/8
luac -p changed Lua green
git diff --check green
pending raw-stale DISSOLVE gate remains honestly red
no authority/default change
```

Manifest only after all gates hold.

## 8. Precision Amendment From The Red Corpus

The first grown corpus correctly rejected a relation-consumer ablation and
incorrectly treated the expected current-work defer as an unqualified
snapshot. Amend the implementation surface:

```text
runtime/qualified_pressure.lua
```

Exact change:

```text
remove only the writerless
  network_current_work_deferred_by_inherited_form
entry from upper diagnostics while the inherited form is pending

retain the actual deferral in witness derivation
retain every incomplete/truncated/unsupported diagnostic
retain ablation ineligibility
```

The grown P10 primary/mirror omit all ablation options. No witness shape,
action, readiness, organ effect, rank, topology or router authority changes.
