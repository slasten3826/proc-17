# Repository Delivery Manifest v0

Status:

```text
manifest
implemented and locally verified 2026-07-20
roadmap step: 7.10 of 7.10
repository-hand chapter: complete v0
source plan: docs/00_chaos/first_repository_hand_manifest_plan_2026-07-20.md
source results: docs/00_chaos/first_repository_hand_manifest_results_2026-07-20.md
source table: docs/01_table/yellowprints/capability_safe_repository_hands_yellowprint.v0.md
source crystall: docs/02_crystall/blueprints/capability_safe_repository_hands.v0.md
scope: one exact completed create_text_file result through △
router authority: opt-in tree only; default shadow unchanged
decision truth status: document_decision
runtime evidence status: runtime_confirmed by listed tests
```

## Result

Proc-17 now owns one complete repository work life:

```text
▽ -> ☴ -> ☵ -> ☱ -> ☶ -> ☱ -> △ -> dead/complete
```

Real alternatives lawfully insert `☴ -> ☳` and still deliver exactly one
selected artifact. The route is pressure-derived; no full trace is fixed in a
harness.

△ consumes one current `work_completion` event and emits a deterministic
`repository.result.v0`. The result reports the repository id, relative path,
operation, observed byte length, SHA-256 and provenance. Its assembly is
runtime-confirmed while semantic content origin remains separately typed.

## Terminal Authority

MANIFEST has no filesystem authority. It receives no capability registry,
provider, repository handle, root path or raw file bytes. It does not call a
substrate or tool. It validates and projects Packet-owned evidence only.

Readiness, execution and qualified-effect verification each reconstruct the
current completion chain. Stale/conflicting completion or rejected verification
cannot produce a complete repository result. Trusted invariant corruption stays
loud.

## Economics

The external effect is charged exactly once before delivery: two tool calls and
one file write for create plus independent read-back. △ adds one ordinary body
step, no tool/write cost and no identity loss.

## Evidence

```text
repository-manifest                       11/11 green
repository-hand battery                   14/14 green
registered Lua corpus                     91 suites green
real production-provider lives             3/3 green
mortality                                  8/8 green
native full test                            green
GCC -fanalyzer                              green
ASan + UBSan                                green (LeakSan not claimed)
```

The production `REAL1` case creates and verifies an actual file under an
identity-owned temporary repository, reaches △, freezes `dead/complete`, revokes
the grant and cleans the fixture.

## Boundary

This closes the first hand chapter, not the product roadmap. V0 remains one
absent UTF-8 text file and one artifact per Packet result. No overwrite, patch,
delete, rename, mkdir, arbitrary read/search, shell, test runner, git,
multi-file transaction, persistent lineage or user surface is claimed.

The next architecture decision may expose this exact capability through the
machine CLI or widen work only through another capability-first treatment. It
must not weaken the demonstrated one-file boundary.
