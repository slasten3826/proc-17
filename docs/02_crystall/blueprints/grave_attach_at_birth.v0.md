# Grave Attach At Birth Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/grave_attach_at_birth_yellowprint.v0.md
implementation target
```

## Scope

Implement step 2:

```text
classified graves can attach to a newborn packet
```

Do not modify router decisions.

## Files

```text
core/packet.lua
runtime/grave.lua
runtime/tension_runner.lua
tests/test_grave.lua
tests/test_tension_runner.lua
```

## Packet Shape

Initialize:

```lua
runtime.karma = {
  warnings = {},
  bequests = {},
  neutral = {},
}
```

## Grave Attach API

Add:

```lua
grave.attach(instance, graves, options) -> attach_payload | nil, err
```

Validation:

```text
instance must be table
graves must be table
```

`graves` can be either:

```text
one grave-like table
array of grave-like tables
```

If an item is already:

```lua
{ kind = "grave", grave_kind = ... }
```

use it directly.

Otherwise call:

```lua
grave.classify(item)
```

## Attachment Rules

Warning:

```lua
instance.runtime.karma.warnings[#warnings + 1] = grave
```

Bequest:

```lua
instance.runtime.karma.bequests[#bequests + 1] = grave
instance.chaos.unresolved_pressure[#pressure + 1] = {
  kind = "grave_bequest_pressure",
  source_packet_id = grave.source_packet_id,
  death_cause = grave.death_cause,
  remaining_work_count = grave.bequest.remaining_work_count,
  progress = grave.bequest.progress,
  trace_tail = grave.bequest.trace_tail,
  death_truth_status = grave.death_truth_status,
  applicability_truth_status = grave.applicability_truth_status,
}
```

Neutral:

```lua
instance.runtime.karma.neutral[#neutral + 1] = grave
```

## Attach Payload

Return:

```lua
{
  kind = "grave_attach_payload",
  attached_count = number,
  warning_count = number,
  bequest_count = number,
  neutral_count = number,
  truth_status = "runtime_confirmed",
}
```

## Tension Runner

After:

```lua
packet_core.new
budget.init
loss.init
result = ...
```

If:

```lua
options.inherited_graves
```

then call:

```lua
grave.attach(instance, options.inherited_graves)
```

Store payload in:

```lua
result.grave
```

If attach fails:

```lua
return nil, "grave:" .. err
```

## Tests

Extend `tests/test_grave.lua`:

```text
attach warning into runtime.karma.warnings
attach bequest into runtime.karma.bequests and chaos.unresolved_pressure
attach neutral into runtime.karma.neutral
attach accepts a single grave-like table
```

Extend `tests/test_tension_runner.lua`:

```text
inherited_graves attaches before route
result.grave exposes counts
route prefix remains unchanged for warning-only inheritance
```

## Acceptance

```text
lua tests/run.lua
```

must pass.
