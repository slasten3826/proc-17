# Authority Instrument Current Evidence v0

```text
layer: MANIFEST
date: 2026-08-11
status: runtime_confirmed diagnostic report
protocol: current-authority-evidence.v0
source revision: a01b3b2cd3fa2f9ab020a2ef52c7e1dfd152ab82
report id: sha256:d0761ba2cd42afbcfa9ba7a04319d6129ecdb3e7a4bfa0c6650cf5ae5085a650
authority surface: sha256:121ba1d3320d7f8e41ea6d18f091bf04ab394d5801e41feca5b5cdf4de88b0b5
case manifest: sha256:9204383c8a0f403a9d5e17c4bd0ab5bcb1b95fb9c99caf6062336e37ab63df9f
promotion authorized: false
```

## 1. Reproduction

The report was grown twice from a clean published worktree with:

```text
lua tests/run_current_edge_report.lua \
  a01b3b2cd3fa2f9ab020a2ef52c7e1dfd152ab82
```

Both runs produced the exact report id above. The campaign used the canonical
omitted-option v3 instrument, seven runner-grown lives and no caller-built
route evidence.

## 2. Epochs

No epoch below was merged with another closure.

| Evidence epoch | Physics epoch | Authority / policy / observer | Lives | Physical | Eligible | Gates |
|---|---|---|---:|---:|---:|---|
| `sha256:1feaeaa15522f4c2e7fde6f4b72ba832ca459582401638f108e3d911405dfc92` | `sha256:4f490b981531b8c8a1e1757df9851b435f9aef30c2b080e55402cec28a265b90` | tree / class-order / legacy-shadow | 1 | 1 | 1 | observer, L0, L1 missing |
| `sha256:464c83ba11acf5c06c88a3abb0f9c66ffdf08871f37259afad5a22dda7b58790` | `sha256:3a4eeee75ff811d868504def3f71cc1896cc653c9c92534f500529b7a7ddd6ae` | tree / binary / none | 1 | 2 | 0 | observer, L0, L1 missing |
| `sha256:7af91634d1d298e95c767220370a89f97c0673b46158af7d3d437e9c2ffb19e1` | `sha256:4f490b981531b8c8a1e1757df9851b435f9aef30c2b080e55402cec28a265b90` | tree / class-order / none | 3 | 1 | 1 | observer, L0, L1 missing |
| `sha256:e56a3b236790f974d180fdda3e01309e726b2d9263abf727ba69dfa942962f34` | `sha256:554fd9cebd8e4905a6cd42ea15bd9ca5ee2a49a1e7d03d5f0b4ab1ed37390bd2` | legacy / legacy-control / none | 1 | 2 | 0 | observer, L0, L1 missing |
| `sha256:f1fe78135e622b39510373622f179810267420be3084e60c36fbd958a116066d` | `sha256:902762f01f563850fb8380b4d81916f0fe4b535b5349d713fbe940763215ad14` | tree / class-order ablation / none | 1 | 0 | 0 | observer, L0, L1 missing |

Every epoch had a green ledger gate, green implementation-provenance gate,
zero instrument errors and diagnostic closure status.

## 3. Diagnostic Union

The cross-epoch union is an index, not promotion evidence:

```text
physical: ▽->☴, ☴->☰, ☴->☵
eligible: ▽->☴
required legal directions: 38
```

This campaign therefore confirms that the canonical v3 observer can see and
classify current movement. It does not confirm the complete 38-direction
authority surface.

## 4. Eligibility Rejections

| Reason | Executed count |
|---|---:|
| `binary_policy_control` | 2 |
| `harness_override` | 1 |
| `non_tree_authority` | 3 |
| `tie_only_selection` | 1 |
| `authority_tainted` | 0 |
| `candidate_unqualified` | 0 |
| `consumer_ablation_active` | 0 |
| `control_fallback` | 0 |
| `epoch_mismatch` | 0 |
| `fixture_witness` | 0 |
| `instrumentation_error` | 0 |
| `missing_action_contract` | 0 |
| `route_identity_mismatch` | 0 |
| `unresolved_source_ref` | 0 |

Zero-count rows are retained because the closed edge-credit vocabulary, not
the observed sample, owns this list.

## 5. Case Gates

Every current case was present in the report and remained missing in all five
epochs:

```text
P01 P02 P03 P04 P05 P06a P06b P07 P08 P09 P10 P11 P12 P13
L1_ACCEPTED_BUILD L1_REJECTED_BUILD L1_MULTI_CHOOSE L1_LONG_TREE
```

The case ids attached to campaign lives were candidate labels only. No case was
laundered green without its evaluator and required matched controls.

## 6. Promotion Blockers

```text
case_manifest_incomplete
cross_epoch_union_non_promotable
diagnostic_report_only
eligible_direction_coverage_incomplete
l0_case_gate_incomplete
l1_case_gate_incomplete
observer_gate_incomplete
physical_direction_coverage_incomplete
target_epoch_decision_absent
```

The instrument is complete enough to report insufficiency precisely. The
full-tree evidence campaign and DISSOLVE corpus remain later work; this record
changes neither router authority nor the default mode.

## 7. Verification

```text
lua tests/run.lua                         127 listed suites passed
lua tests/smoke_mortality_battery.lua      8/8 passed
lua tests/red_qa_hand.lua                  84/84 + red baseline 5/5
current campaign regeneration              identical report id
instrument errors                          0 in every epoch
git diff --check                           passed before manifest write
```
