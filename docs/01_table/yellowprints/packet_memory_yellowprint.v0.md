# Packet Memory Yellowprint v0

Status:

```text
table
from docs/00_chaos/packet_cemetery_memory_notes.md
```

## Direction

Build packet memory as:

```text
packet cemetery + runtime decoder
```

Do not build:

```text
chat history
vector database
semantic long-term memory
automatic substrate summarizer
```

Memory is optional and must be explicitly enabled.

Default:

```text
memory.enabled = false
```

This prevents accidental cross-packet contamination.

## Storage Area

Use workspace sandbox:

```text
sandbox/packets/<packet_id>.json
```

The path must stay inside sandbox.

Packet ids used for filenames must be sanitized.

## Capsule Fields

Minimum saved capsule:

```lua
{
  kind = "packet_memory_capsule",
  protocol_version = packet.protocol_version,
  packet_id = packet.id,
  parent_id = packet.parent_id,
  status = packet.status,
  death = packet.death,
  residue = packet.residue,
  manifest = packet.manifest,
  trace_tail = {},
  loss_records = {},
  runtime = {
    foundation = packet.runtime.foundation,
  },
  saved_at = os.time(),
}
```

Do not require full packet serialization in v0.

The capsule is not meant to restart the old packet.

## Runtime Inheritance

New packets may carry:

```lua
packet.runtime.memory.inherited_residue = {}
```

Inherited residue item:

```lua
{
  kind = "inherited_packet_residue",
  source_packet_id = string,
  source_status = string,
  source_death = table | nil,
  residue = table,
  manifest = table | nil,
  loss_records = table,
  trace_tail = table,
  truth_status = "runtime_confirmed",
}
```

## API

Add module:

```text
runtime/packet_memory.lua
```

Functions:

```lua
packet_memory.capsule(packet, options) -> capsule
packet_memory.save(packet, options) -> capsule, path
packet_memory.load(packet_id, options) -> capsule
packet_memory.inherit(capsule) -> inherited_residue
packet_memory.attach(packet, inherited_residue) -> packet
```

Functions that read, write, inherit, or attach memory require:

```lua
{enabled = true}
```

or packet runtime memory already enabled for attach.

## Tests

Required:

```text
capsule contains residue, death, manifest, trace tail, loss records
save writes sandbox/packets/<id>.json
load returns same capsule identity
inherit returns runtime_confirmed inherited residue
attach puts residue under packet.runtime.memory.inherited_residue
bad packet id/path is rejected
memory save/load/inherit/attach are disabled by default
```
