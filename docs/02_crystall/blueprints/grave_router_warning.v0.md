# Grave Router Warning Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/grave_router_warning_yellowprint.v0.md
implementation target
```

## Scope

Implement the first mechanical karma rule:

```text
warning grave can stop repeated ☱☲ loop
```

Do not change classification.

Do not change attach.

Do not implement cemetery.

## Files

```text
runtime/router.lua
tests/test_router.lua
tests/test_tension_runner.lua
```

## Router Pressure

Extend `pressure_snapshot`:

```lua
karma = {
  warning_count = #(runtime.karma.warnings or {}),
  bequest_count = #(runtime.karma.bequests or {}),
  neutral_count = #(runtime.karma.neutral or {}),
  warnings = runtime.karma.warnings or {},
}
```

## Match Function

Add local function:

```lua
repeated_cycle_warning(pressure) -> warning | nil
```

Return warning when:

```text
last_cycle exists
last_cycle.decision == "again" or last_cycle.reason == "remaining_work"
warning.warning.pattern.last_operator == "☲"
or warning.warning.pattern.last_operator == "☱"
warning.warning.do_not_repeat != nil
```

## Runtime Route Rule

In `route_runtime`, after hard death pressure and before ordinary
`remaining_work`:

```text
if remaining work would route to ☲
and repeated_cycle_warning exists
then route to △
reason = "karma_warning_manifest_pressure"
```

Do not apply before first ☲.

Do not apply when there is no remaining work.

## Tests

Add router unit tests:

```text
first ☱ with inherited warning still routes to ☲
after one cycle says again, ☱ routes to △
pressure exposes karma warning count
real ancestor budget death produces a grave that changes descendant route
```

Update tension runner inherited warning test:

```text
route prefix reaches first ☱☲☱
next route manifests because of karma warning
```

## Acceptance

```text
lua tests/run.lua
```

must pass.
