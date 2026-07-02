# Packet Core Yellowprint v0

First table shape for the clean-room packet.

## Required Areas

```text
substrate
chaos
boundary
calm
tension
trace
residue
death
manifest
```

## First Operations

```text
new(prompt, options) -> packet
append_trace(packet, event) -> packet
append_chaos(packet, fragment) -> packet
crystallize(packet, record) -> packet
measure_tension(packet, record) -> packet
die(packet, cause, residue) -> packet
```

## Crystallization Rule

`crystallize` must:

```text
read CHAOS refs
write CALM delta
record loss
append boundary record
append trace event
```

