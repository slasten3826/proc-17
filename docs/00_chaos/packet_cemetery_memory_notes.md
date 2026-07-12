# Packet Cemetery Memory Notes

Status:

```text
chaos
new pressure
```

## Trigger

proc-17 has no human-style memory.

That is probably correct.

The body should not remember by keeping a chat transcript alive forever.

A packet lives, moves, manifests or dies, and leaves trace/residue.

Memory can be built from that:

```text
packet lived
packet traced
packet manifested or died
packet left residue
runtime can re-decode it later
```

## Core Insight

Memory is not a living old packet.

Memory is a cemetery of finished packets plus a runtime decoder.

Old packet must not be resurrected.

Its residue can become pressure for a new packet.

```text
packet A dies
packet A capsule is saved
packet B is born with parent_id = A
☱ reads packet A residue as inherited runtime pressure
```

This matches the existing direction:

```text
memory is not stored facts
memory is fast re-decoding of what already happened
```

## Boundary

Do not make this a vector database.

Do not summarize everything through the substrate.

Do not use old packet output as automatic truth for new work.

The saved packet is runtime evidence that a previous packet existed.

Its semantic content may still be semantic.

## Minimal Shape

Save a packet capsule:

```text
packet_id
parent_id
status
death
residue
manifest
trace_tail
loss_records
runtime foundation
```

Load a packet capsule:

```text
source_packet_id
source_status
source_death
residue
manifest
loss_records
trace_tail
truth_status = runtime_confirmed
```

Attach it to a new packet:

```text
new_packet.runtime.memory.inherited_residue[]
```

## Why Runtime Owns It

`☱` reads the body.

Previous packet residue is body history, not new raw chaos.

So the first memory organ belongs under runtime.

Later, `☵` may encode inherited residue into calm structure when the current
task needs it.

But the first step is simpler:

```text
save capsule
load capsule
attach inherited residue to runtime memory
```

## Acceptance

The first manifest is accepted when:

```text
completed/dead packet can be saved under sandbox/packets
saved capsule can be loaded
new packet can inherit residue from loaded capsule
inherited residue is visible in runtime.memory
old packet status remains dead/manifested
```
