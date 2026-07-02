# Tension Runner Yellowprint v0

Source chaos:

```text
docs/00_chaos/tension_runner_notes.md
docs/00_chaos/packet_will_routing_notes.md
```

Goal:

```text
execute packet movement through router decisions
```

## Route Loop

```text
packet.new
current = ☴

while current != △ and ticks < max_ticks:
  run current organ
  decision = router.after_tick(packet, current)
  current = decision.to
```

## Operators v0

Executable:

```text
☴ observe
☵ encode
☳ choose
☱ runtime eye
☲ cycle
△ manifest
```

Placeholder:

```text
☶ logic accepted validation
```

Not yet executable:

```text
☰ connect
☷ dissolve
```

## Runtime Eye v0

`☱` should record runtime pressure without deciding by itself.

Decision still belongs to `router.after_tick`.

## Stop Conditions

```text
△ reached
max_ticks reached
operator error
router error
```

If `max_ticks` is reached, packet remains running.

That is not death.

## Expected Fake Smoke

Fake substrate should produce:

```text
observe
encode
observe
choose
observe
runtime
cycle
runtime
...
```

The run may stop by tick limit because no executor marks work done.
