# Plan Build Work Mode Blueprint v0

This blueprint defines the first contract for:

```text
--work-mode plan
--work-mode build
```

It crystallizes:

```text
docs/01_table/yellowprints/plan_build_work_mode_yellowprint.v0.md
```

## Primary Rule

Work mode is the public process contract.

Hints are an internal pressure mechanism.

## CLI Contract

Supported:

```text
lua cli/procesis-body.lua run --task "x" --fake --jsonl --work-mode plan
lua cli/procesis-body.lua run --task "x" --fake --jsonl --work-mode build
```

Compatibility default:

```text
work_mode = build
```

## Hint Derivation

```text
plan  -> hints=false
build -> hints=true
```

Manual overrides:

```text
--work-mode plan --hints     -> hints=true
--work-mode build --no-hints -> hints=false
```

Precedence:

```text
explicit hint flag > work-mode default > compatibility default
```

## Invalid Input

Invalid:

```text
--work-mode nope
--work-mode plan --work-mode build
--hints --no-hints
```

Exit:

```text
code = 2
```

## Trace Contract

`mode_enter` payload must include:

```text
work_mode = plan | build
```

`hint_pressure` payload must include:

```text
work_mode = plan | build
reason = work_mode_plan | work_mode_build | cli_override
```

`substrate_call` payload should include:

```text
work_mode = plan | build
operator_hints.enabled = derived boolean
```

## Non-Goal

This blueprint does not yet require separate behavior in deterministic organs.

For v0, work mode controls hint pressure and trace visibility.

Later versions may use work mode for:

```text
manifestation pressure
cycle policy
conflict handling
output shape
```

## Test Obligations

```text
cli_work_mode_default_build
cli_work_mode_plan_disables_hints
cli_work_mode_build_enables_hints
cli_work_mode_plan_hints_override
cli_work_mode_build_no_hints_override
cli_work_mode_invalid_exits_2
cli_work_mode_conflict_exits_2
cli_work_mode_visible_in_trace
```

## Current Status

```text
stage: manifested_lua_v0
code:
  cli/procesis-body.lua
  core/packet.lua
  runtime/operator_hints.lua
tests:
  tests/test_cli.lua
  tests/test_operator_hints.lua
```
