# Host Guard And Physis Rename Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/host_guard_and_physis_rename_yellowprint.v0.md
implementation target
```

## Scope

Implement only:

```text
default max_ticks derived from internal step budget
packet.physis as internal physical/runtime condition area
compatibility alias packet.substrate = packet.physis
code reads physis first
```

Do not implement grave/memory learning.

## Packet Core Change

In `core/packet.lua`, replace internal area key:

```lua
areas.physis = {
  budget = budget,
  clock = {ticks = 0},
  sandbox = options.sandbox or {},
  host = options.host or {},
}
```

Packet instance:

```lua
physis = areas.physis,
substrate = areas.physis, -- compatibility alias only
```

New code must use:

```lua
instance.physis
```

## Runtime Reads

Update reads from:

```text
instance.substrate.budget
```

to:

```text
instance.physis.budget
```

Affected likely modules:

```text
runtime/body.lua
runtime/budget.lua
runtime/loss.lua
runtime/router.lua
organs/encode.lua
runtime/tension_runner.lua
```

Use helper/fallback where appropriate:

```lua
local physis = instance.physis or instance.substrate or {}
```

This keeps old packets/tests working during transition.

## Default max_ticks

In `runtime/tension_runner.lua`:

```lua
local function default_max_ticks(instance)
  local budget = instance.physis and instance.physis.budget or {}
  local steps = budget.steps
  if type(steps) == "number" and steps > 0 then
    return steps * 4
  end
  return 256
end
```

Then:

```lua
local max_ticks = options.max_ticks or default_max_ticks(instance)
```

Explicit `options.max_ticks` remains exact.

## Tests

Update:

```text
tests/test_packet.lua
tests/test_tension_runner.lua
```

Add/verify:

```text
packet.physis.budget exists
packet.substrate == packet.physis compatibility alias
default runner with default budget can reach budget_exhausted before tick_limit when work does not complete
explicit max_ticks still produces tick_limit when set low
```

## Acceptance

```text
lua tests/run.lua
```

must pass.
