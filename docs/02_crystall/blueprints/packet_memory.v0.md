# Packet Memory Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/packet_memory_yellowprint.v0.md
```

## Purpose

Implement the first proc-17 memory primitive.

Memory is saved packet residue decoded by runtime.

## Scope

In scope:

```text
core/packet.lua runtime.memory initialization
runtime/packet_memory.lua
tests/test_packet_memory.lua
tests/run.lua registration
```

Out of scope:

```text
automatic routing from inherited residue
substrate summarization
vector search
full packet restart
automatic save at every manifest
```

## Packet Change

`packet.new(prompt, options)` must initialize:

```lua
runtime = {
  foundation = ...,
  evidence = {},
  memory = {
    enabled = options.memory_enabled == true,
    inherited_residue = options.inherited_residue or {},
  },
}
```

If memory is disabled, inherited residue must be ignored at birth.

Birth trace may include inherited residue count.

## packet_memory.capsule

Signature:

```lua
packet_memory.capsule(instance, options) -> capsule
```

Options:

```lua
trace_tail_count = number default 8
```

Capsule kind:

```text
packet_memory_capsule
```

The capsule must contain enough runtime evidence to influence a later packet,
but not enough to restart the old packet as living state.

## packet_memory.save

Signature:

```lua
packet_memory.save(instance, options) -> capsule, path
```

Default root:

```text
sandbox/packets
```

Requires:

```lua
options.enabled == true
```

The function must create the directory if needed and write JSON.

Only safe packet ids are allowed in filenames:

```text
letters numbers dot underscore hyphen
```

## packet_memory.load

Signature:

```lua
packet_memory.load(packet_id, options) -> capsule
```

Must read JSON from the same safe path rules.

Requires:

```lua
options.enabled == true
```

## packet_memory.inherit

Signature:

```lua
packet_memory.inherit(capsule) -> inherited_residue
```

Output must have:

```lua
kind = "inherited_packet_residue"
truth_status = "runtime_confirmed"
source_packet_id = capsule.packet_id
```

Requires:

```lua
options.enabled == true
```

## packet_memory.attach

Signature:

```lua
packet_memory.attach(instance, inherited_residue) -> instance
```

Must append to:

```lua
instance.runtime.memory.inherited_residue
```

Requires either:

```lua
options.enabled == true
```

or:

```lua
instance.runtime.memory.enabled == true
```

No route change in v0.

## Acceptance

```text
lua tests/run.lua
```

must pass.
