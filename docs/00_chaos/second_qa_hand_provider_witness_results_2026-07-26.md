# Second QA Hand - Provider Witness Results

Status:

```text
layer: chaos evidence after manifestation
date: 2026-07-26
chapter: 8.5.5D provider physics
implementation range: D1-D7 complete
body QA authority: absent
tree/completion promotion: absent
next hostile campaigns QN17-QN20: deferred
```

Continuation amendment 2026-07-28:

```text
the required new TABLE/CRYSTALL round now exists and passed both audits;
E1-E10 of qa_hostile_execution_campaign.v0 are authorized;
QN17-QN20 remain runtime-red until that implementation executes;
Packet/body QA authority remains absent.
```

Implementation continuation 2026-07-28:

`E1` is complete with zero production/color delta. RUN v1 wire and strict Lua
schemas exist beside the still-live RUN v0 path. `E2-E10` remain pending;
QN17-QN20 remain deferred and body QA authority remains absent. See
`docs/03_manifest/qa_hostile_execution_e1.v0.md`.

E2 continuation 2026-07-28:

Measured environment v1 is now active and historical v0 is unavailable for
new contracts. Production execution remains RUN v0; E3-E10 remain pending.
See `docs/03_manifest/qa_environment_rotation_e2.v0.md`.

## 1. Proven Claim

The implemented slice proves one bounded physical statement:

```text
one exact living build Packet can seal one real repository source;
the trusted D harness can consume that source lease once;
the production native provider can execute tests/run.lua from a detached,
read-only, noexec source mount;
the harness can classify exit 0 and one Lua runtime error;
pre-source == sealed-source == post-source;
the source lease reaches terminal disposition before a report exists;
the Packet and public root projection remain unchanged.
```

This is `qa.provider_witness_report.v0`, not a body QA report. No organ,
router, pressure reader, completion reader, lineage reader or public CLI can
consume it.

## 2. Implemented Slices

| Slice | Runtime-confirmed result |
|---|---|
| D1 | inventory bounds enter inventory digest/id; seal and witness share one pure normalizer |
| D2 | source binding v1 separates closure request, optional body request and transaction identity |
| D3 | PROBE and RUN share detached source staging; policy/environment identities rotate |
| D4 | fixed RUN wire and two silent production fixtures execute through launcher/supervisor |
| D5 | strict Lua normalizer converts closed numeric physics into process observation/error |
| D6 | one callback owns pre-inventory, RUN and post-inventory; terminal source finish precedes assembly |
| D7 | only QN16 changes from expected red to green |

## 3. Real Witnesses

Two disposable identity-owned roots were grown through the real first hand,
sealed through the candidate-seal transaction and consumed through the real
repository and QA providers.

```text
clean tests/run.lua
  -> qa.provider_witness_report.v0
  -> outcome=accepted
  -> reason=expected_exit
  -> termination=exit/0
  -> source.stable=true

Lua runtime error in tests/run.lua
  -> qa.provider_witness_report.v0
  -> outcome=rejected
  -> reason=unexpected_exit
  -> termination=exit/70
  -> source.stable=true
```

The process measurements come from the native parent boundary:

```text
wall time       CLOCK_MONOTONIC
user/system CPU wait4 rusage
max RSS         wait4 rusage, Linux KiB converted to bytes
streams         bounded native measurements and SHA-256
scratch         trusted namespace measurement fields
```

The implementation initially projected `max_rss_bytes=0` without carrying a
native witness and left time fields at their initialized values. This was
caught before this record was written. The RUN wire now carries the measured
resident set and the supervisor records monotonic/rusage values. The evidence
claim therefore has a named physical writer.

## 4. Hostile Results

The D harness controls establish:

```text
changed detached plan
  -> no source reservation; exact plan remains usable

pre-inventory mismatch
  -> no native RUN; typed world error; source finishes once

post-inventory drift after a clean RUN
  -> no witness report; ambiguous/source_drift; source quarantined

malformed trusted inventory
  -> source quarantined first; invariant then fails loudly; replay starts no RUN

private handle/path/raw inventory/raw output
  -> cannot cross the callback or final report

returned report mutation
  -> cannot alter Packet, registry or provider state
```

The callback is deliberately indivisible:

```text
pre inventory -> RUN exactly once -> post inventory -> private pending join
```

There is no replay authority between these operations.

## 5. Runtime Discoveries

Detached staging confirmed the identity split already amended into TABLE and
CRYSTALL:

```text
original source continuity: device + inode across locator/self-bind
staged mount continuity: detached device + inode + mount-id equals attached
original mount-id is not required to equal the cloned staged mount-id
```

The old launcher contract test also still expected
`candidate_execution_not_promoted`. Promotion correctly replaced that state
with strict request rejection; the test now asserts
`native_run_request_rejected` for malformed input.

## 6. Verification Record

Observed locally on 2026-07-26:

```text
lua tests/run.lua
  exit 0
  107 test_* ok markers
  final: all tests ok

lua tests/smoke_mortality_battery.lua
  8/8 mortality cases green

lua tests/test_qa_native_supervisor.lua
  QN01-QN16 green
  QN17-QN20 explicit deferred skips in ordinary regression

lua tests/red_qa_hand.lua
  expected exit 1
  exact control matrix: 40 green / 44 red / 0 skip

make -C native qa-supervisor-basic-fixtures-test
  clean and nonzero production fixtures green
```

The expected-red matrix is part of the evidence. Turning an unauthorized red
control green is a regression, not progress.

## 7. Explicit Non-Claims

This slice does not prove:

```text
hostile candidate containment beyond the two basic fixtures
trusted crash or pipe-fault classification
cleanup ambiguity classification
repeated execution leak freedom
Packet QA request/grant/receipt
body QA check or verdict
QA-driven work-layer/completion/tree movement
generic commands, executables, argv, environment or cwd
universal software correctness
```

The next implementation authority must come from a new table/crystall round.
`D` has finished provider physics; it has not silently created the second hand.
