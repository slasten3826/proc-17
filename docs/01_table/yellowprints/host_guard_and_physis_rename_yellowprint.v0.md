# Host Guard And Physis Rename Yellowprint v0

Status:

```text
table
from Mythos/Fable observation entry 002
small implementation target
grave/memory loop deferred
```

## Goal

Close two small runtime clarity gaps:

```text
default max_ticks should be host guard, not primary death
packet internal substrate area should not collide with LLM substrate adapter
```

Do not implement grave/memory learning in this change.

## Problem 1: Host Guard Wins By Default

Current shape:

```text
default_budget.steps = 64
default max_ticks = 12
```

So default host guard can stop the packet before internal budget death.

That makes `tick_limit` too central.

Better default:

```text
if max_ticks is not explicitly provided:
  max_ticks = budget.steps * 4
```

If steps are missing:

```text
max_ticks = 256
```

Explicit `options.max_ticks` still wins.

## Problem 2: Substrate Name Collision

Current collision:

```text
substrate = LLM adapter passed to tension_runner.run(...)
packet.substrate = internal packet material limits area
```

This is confusing.

The LLM adapter should keep the canonical name:

```text
substrate
```

The packet internal area should become:

```text
packet.physis
```

Meaning:

```text
packet physical/runtime conditions:
  budget
  clock
  sandbox
  host
```

## Compatibility

For v0, keep a compatibility alias:

```lua
packet.substrate = packet.physis
```

But new code should read:

```lua
packet.physis.budget
```

Docs should call the old name deprecated.

## Non-Goals

```text
grave / packet memory learning
session memory changes
full docs rewrite
removing compatibility alias
renaming substrate adapter modules
```

## Acceptance

```text
lua tests/run.lua passes
default tension runner uses max_ticks > default steps
explicit max_ticks still works
runtime budget reads packet.physis.budget
tests assert physis exists
```
