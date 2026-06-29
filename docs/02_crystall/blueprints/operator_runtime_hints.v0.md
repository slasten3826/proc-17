# Operator Runtime Hints Blueprint v0

This blueprint defines the first contract for:

```text
operator_runtime_hints
```

It crystallizes:

```text
docs/01_table/yellowprints/operator_runtime_hints_yellowprint.v0.md
```

## Primary Rule

Operator runtime hints are an optional pressure module.

They are enabled by default.

They must be explicitly disabled by settings or CLI.

They must never promote semantic content into runtime truth.

## Scope

The module provides short operator-local pressure for:

```text
▽ ☰ ☷ ☵ ☳ ☴ ☲ ☶ ☱ △
```

It does not provide:

```text
human prose interpretation
long scripture quotes
semantic validation
runtime evidence
truth upgrade
```

## Data Contract

The module should expose an addressable map:

```lua
{
  ["☵"] = {
    operator = "☵",
    role = "form addressable field from inspectable/runtime-shaped material",
    hints = {
      "Encoding is not copying.",
      "Structure has cost.",
      "Show what was omitted, compressed, or made addressable.",
      "Do not promote prose into runtime truth.",
    },
    trace_pressure = {
      "field shape explicit",
      "loss visible",
      "source truth status preserved",
      "prose remains semantic unless engineering pressure is explicit",
    },
  },
}
```

Required fields per operator:

```text
operator
role
hints
trace_pressure
```

Optional fields:

```text
pseudocode
version
density
```

## Enable Contract

Default:

```text
hints.enabled = true
```

Settings may set:

```text
hints.enabled = true
hints.enabled = false
```

CLI override:

```text
--hints
--no-hints
```

Precedence:

```text
CLI override > settings > default true
```

Invalid combinations:

```text
--hints --no-hints
```

must exit with:

```text
code = 2
```

## Runtime Placement

When enabled, hints may be attached to:

```text
substrate_call payload
packet trace
organ-local config
```

Minimum v0 requirement:

```text
include active hints in substrate_call payload
emit trace-visible hint pressure before substrate call
```

Recommended payload shape:

```lua
operator_hints = {
  enabled = true,
  density = "short",
  active = {
    {
      operator = "☵",
      role = "...",
      hints = {...},
    },
    {
      operator = "☳",
      role = "...",
      hints = {...},
    },
  },
}
```

When disabled:

```lua
operator_hints = {
  enabled = false,
  active = {},
}
```

or omit `operator_hints` entirely if trace records disabled state.

The implementation must choose one behavior and test it.

## Trace Contract

When hints are enabled, trace should include a runtime-confirmed event:

```text
type = hint_pressure
operator = ☴ or current_route_operator
truth_status = runtime_confirmed
payload.enabled = true
payload.density = short
payload.operators = [...]
payload.hint_count = N
```

When hints are disabled by CLI or settings, trace should include:

```text
type = hint_pressure
truth_status = runtime_confirmed
payload.enabled = false
payload.reason = cli | settings
```

Hints are runtime-confirmed as configuration state only.

Hint content does not become runtime-confirmed semantic truth about the task.

## Active Hint Selection v0

For the first manifestation, active hints may include the full route set:

```text
▽ ☰ ☷ ☵ ☳ ☴ ☲ ☶ ☱ △
```

This is acceptable because the payload is short.

Future versions may narrow active hints by:

```text
current operator
route phase
body mode
task kind
```

But v0 should not depend on a complex selector.

## Operator Hint Set v0

### `▽`

```text
Flow is input pressure before form.
Do not solve before the packet is born.
Record the task as received before transforming it.
```

### `☰`

```text
Connection is not fusion.
Bind source to field item.
Keep relation evidence visible.
```

### `☷`

```text
Dissolve removes false form, not evidence.
Unsupported form should leave residue.
Weakening is not deletion.
```

### `☵`

```text
Encoding is not copying.
Structure has cost.
Show what was omitted, compressed, or made addressable.
Do not promote prose into runtime truth.
```

### `☳`

```text
Choice kills alternatives.
A choice without killed alternatives is only confirmation.
Record what was not chosen.
Do not invent criteria after collapse.
```

### `☴`

```text
Observe reads without mutating.
Observation is not confirmation.
Raw evidence should enter before interpretation.
```

### `☲`

```text
Continuation must be paid.
Cycle is not immortality.
Stop when pressure is exhausted or repetition becomes false life.
```

### `☶`

```text
Rule does not create truth.
Rule rejects unsupported form.
Semantic proposal remains semantic until runtime confirms it.
```

### `☱`

```text
Runtime reads the body, not the idea.
Pressure is current state, not interpretation.
Memory is re-decoding available trace.
```

### `△`

```text
Manifest is form death.
Output must not hide residue.
Completion kills the packet.
```

## Truth Boundary

Hints may influence:

```text
prompt construction
trace pressure
operator discipline
loss reporting
selection criteria visibility
```

Hints must not change:

```text
source_truth_status
content_truth_status
runtime evidence
validation result
selected branch by themselves
```

If a future organ reads hints directly, it must treat them as configuration pressure,
not evidence.

## CLI Contract

Machine CLI should support:

```text
lua cli/procesis-body.lua run --task "x" --fake --jsonl --hints
lua cli/procesis-body.lua run --task "x" --fake --jsonl --no-hints
```

Default command should behave like:

```text
--hints
```

unless settings disable it.

`--no-hints` is required for baseline tests.

## Test Obligations For Manifestation

Future code should add:

```text
test_operator_hints_default_enabled
test_operator_hints_cli_disable
test_operator_hints_cli_enable
test_operator_hints_conflicting_flags_invalid
test_operator_hints_trace_enabled
test_operator_hints_trace_disabled
test_operator_hints_in_substrate_call_when_enabled
test_operator_hints_absent_or_empty_when_disabled
test_operator_hints_do_not_promote_truth
```

CLI tests should cover:

```text
--fake --jsonl
--fake --jsonl --hints
--fake --jsonl --no-hints
```

Provider tests should remain manual unless fake substrate can verify prompt payload.

## Current Status

```text
stage: manifested_lua_v0
code:
  runtime/operator_hints.lua
  cli/procesis-body.lua
  core/packet.lua
tests:
  tests/test_operator_hints.lua
  tests/test_cli.lua
```
