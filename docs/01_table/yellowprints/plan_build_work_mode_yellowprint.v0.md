# Plan Build Work Mode Yellowprint v0

This yellowprint compiles raw pressure from:

```text
docs/00_chaos/plan_build_hints_modes.md
docs/00_chaos/plan_build_mode_request.md
docs/00_chaos/cognitive_battery_hints_results.md
```

It turns the technical hint toggle into a work-mode table.

## Core Table

```text
plan  = ⋯⊞◈ = think / inspect / crystallize
build = ◈▲  = act / cut / manifest
```

## Mode To Hint Mapping

```text
plan:
  hints = false by default
  manifestation_pressure = low

build:
  hints = true by default
  manifestation_pressure = high
```

`--hints` and `--no-hints` remain debug overrides.

## CLI Surface

Primary work-mode flag:

```text
--work-mode plan
--work-mode build
```

Compatibility:

```text
no --work-mode => build
```

Reason:

```text
current CLI default has hints enabled
this is equivalent to build current
```

## Precedence

```text
1. explicit --hints / --no-hints
2. --work-mode hint default
3. compatibility default: build
```

Allowed overrides:

```text
--work-mode plan --hints
--work-mode build --no-hints
```

Invalid:

```text
--work-mode nope
--work-mode plan --work-mode build
--hints --no-hints
```

Invalid input exits:

```text
code = 2
```

## Trace Pressure

Trace should expose:

```text
mode_enter.payload.work_mode
hint_pressure.payload.work_mode
hint_pressure.payload.reason
```

Expected reasons:

```text
work_mode_plan
work_mode_build
cli_override
```

## Expected Behavior

Plan:

```text
notice contradictions
preserve uncertainty
produce blueprint/residue
do not force manifestation
```

Build:

```text
act
select
cut
write
test
manifest
finish packet when payable
```

## Test Pressure

Future manifestation should prove:

```text
plan disables hints by default
build enables hints by default
default work mode is build
manual hints override plan
manual no-hints override build
invalid work mode exits 2
conflicting work modes exit 2
work mode is visible in trace
```
