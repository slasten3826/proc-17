# Lineage Completion / Continuation Separation Manifest v0

Status:

```text
manifest
implemented and locally verified 2026-07-19
source chaos: docs/00_chaos/lineage_completion_economy_separation_notes_2026-07-19.md
source table: docs/01_table/yellowprints/lineage_completion_continuation_separation_yellowprint.v0.md
source crystall: docs/02_crystall/blueprints/lineage_completion_continuation_separation.v0.md
scope: bounded in-memory lineage completion and continuation boundary
decision truth status: document_decision
```

## Result

The completion writer no longer asks the lineage wallet or recovery policy what
state the task is in.

The active split is:

```text
runtime/completion.lua
  exact task state
  intrinsic terminal recoverability

runtime/lineage_runner.lua
  selected lineage outcome
  cumulative affordability
  automatic-recovery permission
  carrier materialization
```

The ambiguous assessment field `recoverable` is removed. Its replacement is:

```lua
terminal_recoverable = boolean
terminal_recovery_basis = terminal cause | nil
```

No compatibility alias remains.

## Reproduced Before Treatment

One grown and hash-verified corpse was evaluated twice:

```text
corpse death cause: budget_exhausted

funded lineage:
  task_state = unfinished
  recoverable = true

exhausted lineage:
  task_state = blocked
  recoverable = false
  missing = recoverable terminal state
```

The same evidence received different task verdicts because the lineage wallet
was read inside completion.

## Runtime After Treatment

The permanent matched test now grows one real local budget death and evaluates
the same corpse under three lineage states:

```text
funded + recovery enabled
exhausted + recovery enabled
funded + recovery disabled
```

All three assessments are identical on the relevant contract:

```text
task_state = unfinished
terminal_recoverable = true
terminal_recovery_basis = budget_exhausted
missing_requirements = {}
assessment_id = same canonical digest
recoverable = absent
```

The runner then produces different, correctly owned continuation outcomes:

```text
funded + enabled:
  recovery carrier may be built

exhausted:
  lineage.status = exhausted
  terminal.cause = lineage_budget_exhausted
  carrier_count = 0
  child_count = 0

recovery disabled:
  lineage.status = suspended
  terminal.cause = recovery_disabled_by_policy
  carrier_count = 0
  child_count = 0
```

## Decision Order

The bounded runner now reads the assessment before lineage gates:

```text
complete
unsafe
unknown
intrinsically nonrecoverable
lineage budget exhausted
recovery disabled by policy
recovery carrier attempt
```

This preserves completion on the last paid action and prevents economics from
hiding unsafe, unknown or blocked task evidence.

## Carrier Contract

Recovery carrier construction now requires:

```text
task_state = unfinished
terminal_recoverable = true
terminal_recovery_basis is present
current corpse/lineage ancestry matches
```

A negative carrier test proves that clearing intrinsic recoverability rejects
the carrier before materialization.

Carrier construction still does not own budget or policy authority. The bounded
runner is their named reader and applies both before calling the carrier builder.

## Verification

```text
red baseline:
  tests/test_lineage_completion_separation.lua failed on missing
  terminal_recoverable before implementation

green treatment:
  lua tests/run.lua                                  77 suites passed
  tests/test_lineage_completion_separation.lua      passed
  tests/test_lineage_completion.lua                 passed
  tests/test_carrier.lua                            passed
  tests/test_lineage_runner.lua                     passed
  lua tests/smoke_mortality_battery.lua             8/8 passed
  lua tests/smoke_runtime_camera_treatment.lua      passed
  lua tests/smoke_pressure_ablation.lua             passed
  luac -p over all Lua sources                      passed
  git diff --check                                  passed
```

The live DeepSeek smoke was not rerun because this treatment changes no
substrate adapter, prompt or semantic proposal contract.

## Claims

This treatment proves:

```text
same corpse and completion contract -> same task assessment
lineage wallet cannot rewrite task state
recovery policy cannot rewrite task state
economic exhaustion blocks a child with an exact economic cause
disabled automatic recovery blocks a child with an exact policy cause
existing two-generation recovery remains operational
```

## Deliberate Limits

This treatment does not implement:

```text
full continuation candidate/exclusion ledger
persistent lineage or resume
branching descendants
new intrinsic recovery classes
carrier compaction
repository hands
```

The next product-bearing pressure remains capability-safe repository work. The
completion record is now safe to become an input to future persistence without
confusing task truth with the wallet that happened to observe it.
