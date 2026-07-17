# Edge Evidence Roles Yellowprint v0

Status:

```text
table
from docs/00_chaos/promotion_metrics_role_separation_notes.md
scope: edge-stats.v2 measurement schema
```

## 1. Comparison Table

| Observer key | Observer | Observed authority | Meaning |
|---|---|---|---|
| `tree` | full-tree policy | `legacy_control` | candidate policy compared with historical live route |
| `legacy` | historical policy | `tree` | deposed policy compared with tree live route |

Canonical counters live only inside the keyed observer record:

| Counter | Meaning |
|---|---|
| `comparison_count` | bounded observer records consumed |
| `agreement_count` | predicted target equals live target |
| `divergence_count` | targets differ or no prediction exists |
| `no_prediction_count` | observer produced no target |
| `unavailable_count` | observer has no rule for the source operator |

The edge-stat root may expose total `comparison_count`. It must not expose
cross-observer agreement, divergence, or no-prediction totals.

## 2. Rail Channel Table

| Channel | Evidence role | Authority | Target field | Reference route |
|---|---|---|---|---|
| `tree_shadow` | `counterfactual_prediction` | none | tree `predicted_to` | legacy live route |
| `tree_authority` | `authoritative_derivation` | tree | tree selected target | none |

Legacy shadow has no tree candidate/contribution audit and therefore does not
create rail-pressure evidence. It remains useful in the comparison table.

## 3. Neutral Rail Counters

Every channel has:

| Counter | Meaning |
|---|---|
| `cases` | derivations relevant to this rail source |
| `target_count` | derivations that selected or predicted a target |
| `reference_eye_count` | comparison reference route used the eye |
| `eye_debt_cases` | candidate audit contains the rail debt witness |
| `eye_target_count` | channel target is the eye |
| `debt_eye_target_count` | debt exists and target is the eye |
| `fresh_eye_target_count` | no debt exists and target is the eye |
| `debt_bypass_count` | debt exists and target bypasses the eye |
| `fresh_direct_count` | no debt exists and target is a non-eye neighbor |
| `no_target_count` | derivation produced no viable target |

`required_eye_recall` becomes a derived report ratio from
`debt_eye_target_count / eye_debt_cases`. It is not stored as an ambiguously
named count.

## 4. Merge Table

| Input | Result |
|---|---|
| v2 shadow life + v2 tree life | observer and rail channels summed independently |
| v2 + unknown observer | explicit keyed observer record with carried authority metadata |
| v1 + v2 | hard error |
| mismatched observer authority metadata | hard error |
| missing channel | zero-valued channel, never reinterpret another channel |

## 5. Invariants

```text
comparison bucket names its observer and observed authority
rail bucket names its evidence role and authority
tree_shadow never receives tree-live derivations
tree_authority never receives counterfactual shadow predictions
legacy observer never writes tree rail evidence
statistics remain read-only with respect to Packet physics
```

## 6. Acceptance

```text
mixed-mode corpus preserves both observer histories separately
flat ambiguous v1 counters are absent
rail channel counts survive merge independently
Gate B observer ablation remains physically identical
all existing edge coverage, mortality, and camera tests remain green
```

## 7. Treatment Record

```text
protocol: edge-stats.v2
mixed-epoch role gate: green
main suites: 44 green
mortality: 8/8 green
v1/v2 guard: green
observer metadata guard: green
route physics delta: none
```

This table is implemented. Promotion thresholds remain open and must read v2
channels rather than historical flat counters.
