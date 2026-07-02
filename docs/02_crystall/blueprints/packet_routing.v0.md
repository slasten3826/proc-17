# Packet Routing Blueprint v0

Target module:

```text
runtime/router.lua
```

This blueprint defines the next routing layer.

It does not replace `runtime/runner.lua` immediately.

The existing runner remains a smoke rail until the router is tested.

## Public Contract

```lua
router.after_tick(packet, tick) -> decision | nil, err
```

Input shape:

```lua
{
  operator = "☵" | "☳" | "☲" | "☶" | "☴" | "☱",
  payload = table,
}
```

Decision shape:

```lua
{
  kind = "route_decision",
  from = operator,
  to = operator,
  reason = string,
  pressure = table,
  truth_status = "runtime_confirmed",
}
```

## Hard Rules

```text
☵ -> ☴
☳ -> ☴
☲ -> ☱
☶ -> ☱
```

These are deterministic in v0.

## Eye Rules

`☴` routes by upper pressure:

```text
encoding_pressure -> ☵
choice_pressure -> ☳
runtime_ready -> ☱
```

`☱` routes by lower pressure:

```text
continuation_pressure -> ☲
validation_pressure -> ☶
semantic_uncertainty -> ☴
manifest_ready -> △
cannot_continue -> △
```

## Required Packet Pressure Fields

Packet/router should read pressure from existing packet areas first:

```text
packet.calm.current
packet.calm.work_units
packet.calm.status
packet.tension
packet.boundary.choices
packet.boundary.validations
packet.boundary.cycles
packet.substrate.budget
packet.trace
```

If pressure is missing, route conservatively.

Conservative defaults:

```text
☴ with calm work units -> ☳
☴ without calm -> ☵
☱ with remaining work -> ☲
☱ with no remaining work -> △
```

## Loss/Budget Separation

Router must expose both axes separately:

```text
pressure.loss
pressure.budget
```

It must not collapse them into one score.

## Required Tests

```text
after ☵ routes to ☴
after ☳ routes to ☴
after ☲ routes to ☱
after ☶ routes to ☱
☴ without calm routes to ☵
☴ with calm alternatives routes to ☳
☴ with runtime_ready pressure routes to ☱
☱ with remaining work routes to ☲
☱ with validation pressure routes to ☶
☱ with no remaining work routes to △
router decision keeps loss and budget separate
```

## Later Integration

After tests pass, build a new runner:

```text
runtime/pressure_runner.lua
```

It should execute:

```text
run operator
ask router.after_tick
run next operator
repeat until △ or death
```

Do not remove `runtime/runner.lua` until pressure runner has live smoke tests.
