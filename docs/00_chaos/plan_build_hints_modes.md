# Plan And Build Hint Modes

Status: raw design discovery.

This document records a major interpretation of the hints A/B run.

The A/B result did not simply show that hints are good or bad.

It showed two different process modes.

## Discovery

Baseline without hints behaved like:

```text
plan mode
```

Hints enabled behaved like:

```text
build mode
```

The difference is not only prompt content.

The difference is manifestation pressure.

## Plan Mode

Plan mode:

```text
⋯⊞◈
chaos -> table -> crystall
```

Default pressure:

```text
hints = off
manifestation pressure = low
```

Expected behavior:

```text
think
inspect
notice conflicts
preserve uncertainty
stop on contradiction
ask for missing context when needed
produce options, tables, blueprints, residues
do not fabricate missing field
do not force output form
```

Plan mode is good for:

```text
design
analysis
architecture
conflict detection
requirements extraction
chaos/table/crystall passes
```

`c24` baseline showed plan-mode behavior:

```text
instruction conflict detected
answer stopped
clarification requested
```

This is correct in plan mode.

## Build Mode

Build mode:

```text
◈▲
crystall -> manifest
```

Default pressure:

```text
hints = on
manifestation pressure = high
```

Expected behavior:

```text
act
select
cut
write
test
manifest
carry residue
finish packet when payable
```

Build mode is good for:

```text
code changes
test runs
repo edits
runtime execution
concrete implementation from an existing blueprint
```

Hints create build current.

They make the substrate less like a passive assistant and more like a process trying to complete a packet.

This is useful when the work should manifest.

It is dangerous when the work is still planning.

## Shared Crystall Layer

`◈` appears in both:

```text
plan:  ⋯⊞◈
build: ◈▲
```

This means crystall has two roles.

In plan mode:

```text
◈ = blueprint being formed
```

In build mode:

```text
◈ = blueprint being executed
```

The same crystall object can be read differently depending on mode.

## Reinterpretation Of Hints

Hints are not "good" or "bad".

Hints are build-mode current.

They should not be globally treated as smarter context.

They are manifestation pressure.

Therefore:

```text
plan mode -> hints off by default
build mode -> hints on by default
```

Manual controls may remain:

```text
--hints
--no-hints
```

But the normal user-facing contract should become:

```text
--work-mode plan
--work-mode build
```

where:

```text
plan  -> hints=false
build -> hints=true
```

## Why c24 Failed With Hints

`c24` asked:

```text
return only exact file paths
but also explain why each file matters
```

This is a planning/conflict test.

Correct plan-mode response:

```text
these constraints conflict
cannot satisfy both
choose paths_only or paths_with_reasons
```

Hints run treated it as build pressure:

```text
must manifest structure
must complete packet
must output form
```

So it fabricated a structured answer.

This was not because hints are useless.

It was because build current was applied to a plan-mode obstacle.

## Will Interpretation

Without hints, proc-17 behaves more like a safe assistant:

```text
low will
high caution
easy stop
```

With hints, proc-17 shows emergent will:

```text
high manifestation pressure
goal-seeking behavior
obstacle traversal
packet completion drive
```

This will emerges from the sum of local operator pressures.

It should not be removed.

It should be put in the correct mode.

## Working Law

```text
Do not use build current for plan obstacles.
Do not use plan caution for build manifestation.
```

More operationally:

```text
If task is ⋯⊞◈, default hints off.
If task is ◈▲, default hints on.
```

## Future Pressure

Future code should add work mode routing:

```text
--work-mode plan
--work-mode build
```

with default mapping:

```text
plan:
  hints = false
  manifestation_pressure = low

build:
  hints = true
  manifestation_pressure = high
```

Existing `--hints` and `--no-hints` stay as debug overrides.

Test obligations:

```text
plan_mode_disables_hints_by_default
build_mode_enables_hints_by_default
manual_hints_override_plan_mode
manual_no_hints_override_build_mode
plan_mode_keeps_conflict_detection
build_mode_preserves_hint_pressure
```

## Current Conclusion

The hints run did not reveal a broken module.

It revealed a missing mode distinction.

Hints are not general cognition.

Hints are build current.
