# Tension Runner Blueprint v0

Target module:

```text
runtime/tension_runner.lua
```

Public contract:

```lua
tension_runner.run(prompt, substrate, options) -> packet, result | nil, err
```

Result shape:

```lua
{
  kind = "tension_runner_result",
  packet_id = string,
  ticks = table,
  routes = table,
  stop_reason = string,
  final_status = string,
}
```

## Defaults

```text
start_operator = ☴
max_ticks = 12
work_mode = build
```

## Tick Shape

```lua
{
  index = number,
  operator = glyph,
  payload = table,
}
```

## Route Shape

Use `runtime/router.lua` decision shape:

```lua
{
  kind = "route_decision",
  from = glyph,
  to = glyph,
  reason = string,
  pressure = table,
}
```

## Manifest Rule

When current operator is `△`:

```text
assemble manifest
packet.manifest_packet
packet.die
stop_reason = manifested
```

If runner stops by tick limit:

```text
do not manifest
do not die
packet.status remains running
```

## Required Tests

```text
fake substrate routes through router, not fixed rail
run includes observe, encode, choose, runtime, cycle
after choose, upper eye can route to runtime
tick limit leaves packet running
missing substrate fails through observe
unit suite remains green
```
