# Repository Route Promotion Manifest v0

Status:

```text
manifest
implemented and locally verified 2026-07-20
roadmap step: 7.9 of 7.10
source plan: docs/00_chaos/first_repository_hand_route_promotion_plan_2026-07-20.md
source results: docs/00_chaos/first_repository_hand_route_promotion_results_2026-07-20.md
source table: docs/01_table/yellowprints/capability_safe_repository_hands_yellowprint.v0.md
source crystall: docs/02_crystall/blueprints/capability_safe_repository_hands.v0.md
scope: qualified routing of one exact create/read-back/completion action
router authority: opt-in tree only; default shadow unchanged
decision truth status: document_decision
runtime evidence status: runtime_confirmed by listed tests
```

## Result

Proc-17 can now route one exact repository work unit from field formation to a
body-owned completion without a caller spell, caller path or fixed hand trace.
Qualified pressure selects only a phase whose exact prerequisites exist.

```text
single:       ▽ -> ☴ -> ☵ -> ☱ -> ☶ -> ☱
alternatives: ▽ -> ☴ -> ☵ -> ☴ -> ☳ -> ☶ -> ☱
```

The singular route uses one RUNTIME action review and no fake choice. A real
alternative set is observed at its current field versions and collapsed before
effect. LOGIC owns external mutation and verification; RUNTIME owns final
reconciliation into `work_completion`.

## Authority And Privacy

The action contains only immutable public grant projection and exact work
referents. The capability registry remains an opaque host service passed by
reference outside action options. It cannot enter pressure evidence, trace,
Packet memory, corpse, carrier or manifest.

An action is eligible only when it is current, capability-bound, topologically
reachable and affordable. Missing or disabled authority produces no review,
attempt or provider call. Malformed trusted state is a loud harness failure,
not Packet death.

## Evidence And Economics

The accepted life records exactly:

```text
one repository_effect_attempt
one repository_effect_receipt
one repository_verification
one accepted LOGIC validation
one runtime.work_completion.v0
```

The organ reports actual effect cost and the tension runner charges it once.
The demonstrated create/read-back costs two tool calls and one file write.
Repository review, effect and reconciliation create no identity loss.

Receipt is not completion. Rejected independent read-back produces no
completion. Removing the review, effect or reconciliation witness independently
removes its downstream phase.

## Verification

```text
repository-route                         11/11 green
staged repository-hand battery           13/13 green
repository-hostile-audit                 16/16 green
repository-effect                        14/14 green
repository-progress                       9/9 green
registered Lua corpus                    90 suites green
mortality                                 8/8 green
native hostile/fault corpus                green
GCC -fanalyzer                             green
ASan + UBSan                               green (LeakSan not claimed)
```

## Boundary

This manifest changes neither default router authority nor operation width.
Only the already demonstrated one-file `create_text_file` surface is routed.

The body now knows that repository work is complete, but △ does not yet project
that exact verified result. Roadmap 7.10 owns repository result manifestation.
Until then, `done=1` is runtime truth inside the body, not a claim that a useful
external result has already been delivered.

Update 2026-07-20: roadmap 7.10 closed this boundary. The current terminal
record is [`repository_delivery.v0.md`](repository_delivery.v0.md). This file
remains the pre-delivery route record.
