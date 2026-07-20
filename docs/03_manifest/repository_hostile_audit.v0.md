# Repository Hostile Audit Manifest v0

Status:

```text
manifest
implemented and locally verified 2026-07-20
roadmap step: 7.8 of 7.10
source plan: docs/00_chaos/first_repository_hand_hostile_audit_plan_2026-07-20.md
source results: docs/00_chaos/first_repository_hand_hostile_audit_results_2026-07-20.md
scope: existing one-file hand under hostile composition and resource pressure
router authority change: absent
decision truth status: document_decision
runtime evidence status: runtime_confirmed by listed tests
```

## Result

The first repository hand is now fail-closed across its demonstrated
composition boundary. Mutated actions, forged request fields, stale leases,
malformed provider residue and stale or forged completion records cannot widen
authority or create current completion truth.

## Strengthened Laws

```text
lease issuance rereads the complete current action
lease use requires the same active grant revision and live handle
create accepts one exact plain request envelope
provider residue is one bounded relative-name record or loud corruption
generic trace append cannot mint repository body events
completion truth is revalidated whenever read
```

Historical events are not rewritten when current truth changes. A completion
followed by a conflicting attempt remains in trace but no longer satisfies
`is_complete`; a completion for an older work version cannot finish the current
version.

## Evidence

```text
repository-hostile-audit                  16/16 green
repository-effect                         14/14 green
repository-progress                        9/9 green
real Linux effect/resource                 2/2 green
staged repository suites                  12 green / 1 route red
ordinary Lua regression                   80/80 green
native repeated transactions              128, zero fd delta each
GCC -fanalyzer                            green
ASan + UBSan                              green (LeakSan not claimed)
```

## Remaining Boundary

This manifest does not authorize automatic route selection, host-service
propagation through the runner, automatic RUNTIME review/reconciliation,
central economics charging or artifact manifestation. The one staged red suite
is still `tests.test_repository_route`, with five green controls and five red
controls. That frontier belongs to roadmap 7.9.
