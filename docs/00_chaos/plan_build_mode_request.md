# Plan Build Mode Request

Status: implementation request.

This document requests turning the technical hint toggle into a work-mode contract.

## Problem

Current CLI exposes:

```text
--hints
--no-hints
```

This is technically correct but conceptually wrong as the main interface.

The A/B battery showed that hints are not merely prompt decorations.

Hints produce build current.

No hints produce plan behavior.

Therefore the public mode should not be named after the mechanism.

It should be named after the process state:

```text
plan
build
```

## Desired Contract

Add:

```text
--work-mode plan
--work-mode build
```

Mapping:

```text
plan:
  process = ⋯⊞◈
  hints = false by default
  manifestation_pressure = low

build:
  process = ◈▲
  hints = true by default
  manifestation_pressure = high
```

`--hints` and `--no-hints` should remain as debug overrides.

## Precedence

Desired precedence:

```text
explicit --hints / --no-hints
  overrides --work-mode hint default

--work-mode
  chooses default hint state

no --work-mode
  keep current compatibility default for now
```

Compatibility question:

```text
Should no --work-mode default to build or current behavior?
```

Current behavior is:

```text
hints enabled by default
```

This is effectively build current.

For now, safest implementation may be:

```text
default work_mode = build
```

But this should be revisited when CLI becomes user-facing.

## Mode Semantics

### Plan

Plan means:

```text
think
inspect
notice contradictions
preserve uncertainty
produce blueprint/residue
do not force manifestation
```

It is good for:

```text
chaos
table
crystall
architecture
conflict detection
requirements
test design
```

### Build

Build means:

```text
act
select
cut
write
test
manifest
finish packet when payable
```

It is good for:

```text
code changes
test execution
repo edits
implementation from blueprint
```

## CLI Trace

CLI should make the mode visible in trace.

Possible place:

```text
mode_enter payload.work_mode = plan | build
```

or separate event:

```text
type = work_mode_enter
```

Simpler v0:

```text
mode_enter payload.work_mode
hint_pressure payload.work_mode
```

## Hint Pressure

In plan:

```text
hint_pressure.enabled = false
reason = work_mode_plan
```

In build:

```text
hint_pressure.enabled = true
reason = work_mode_build
```

If manually overridden:

```text
reason = cli_override
```

## Conflict Rules

Invalid:

```text
--work-mode plan --work-mode build
--work-mode nope
--hints --no-hints
```

Should exit:

```text
code = 2
```

Allowed:

```text
--work-mode plan --hints
--work-mode build --no-hints
```

These are debug/manual override combinations.

Trace should reveal that override happened.

## Test Obligations

Future code should add:

```text
cli_work_mode_plan_disables_hints_by_default
cli_work_mode_build_enables_hints_by_default
cli_work_mode_invalid_exits_2
cli_work_mode_conflict_exits_2
cli_work_mode_plan_hints_override_enables_hints
cli_work_mode_build_no_hints_override_disables_hints
cli_work_mode_visible_in_trace
```

Later live tests should run:

```text
plan_build_mode_probe_battery.md
```

## Key Law

```text
Do not use build current for plan obstacles.
Do not use plan caution for build manifestation.
```

## Current Request

Manifest the first Lua v0 of:

```text
--work-mode plan
--work-mode build
```

with hints derived from work mode and explicit hint flags retained as overrides.
