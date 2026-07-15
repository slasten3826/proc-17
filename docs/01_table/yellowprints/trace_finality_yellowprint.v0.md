# Trace Finality Yellowprint v0

Status:

```text
table
author: claude (Mythos/Fable)
from docs/00_chaos/corpse_trace_writes_notes.md
second layer of death finality
```

## Goal

Freeze the ledger of a dead packet.

After death nothing writes:

```text
no trace events
no boundary records
```

The five-op guard from the previous fix stays as is.

## Core Rule

Dead packet writes nothing.

```text
dead -> reject exported trace append
dead -> reject record_choice / record_validation / record_cycle
rejection happens BEFORE any mutation
```

Half-writes are forbidden: a rejected record must leave boundary lists
untouched.

## Guard Placement

```text
core/packet.lua
  exported packet.append_trace -> dead_guard
  internal local append_trace  -> NO guard
```

Reason the internal path stays open:

```text
packet.die sets status = "dead" first
then appends the death event through the internal path
```

The death event is the last legal write.

```text
runtime/body.lua
  record_choice     -> dead_guard before boundary mutation
  record_validation -> dead_guard before boundary mutation
  record_cycle      -> dead_guard before boundary mutation
```

## Error Shape

Match existing convention:

```text
nil, "dead packet cannot append trace"
nil, "dead packet cannot record choice"
nil, "dead packet cannot record validation"
nil, "dead packet cannot record cycle"
```

Live callers (organs/choose, tension_runner) ignore return values and
only run on live packets; no caller changes required.

## Non-Goals

```text
manifested freeze (open ontology pressure, separate decision)
direct field mutation protection (Lua physics, out of scope)
dying status semantics
guarding internal append_trace
```

## Integration Lesson

Do not test only through core.

At least one test must go through the body channel:

```text
kill packet
body.record_choice(corpse, ...) -> rejected
boundary.choices unchanged
trace unchanged
```

Because the half-write lives in body, not in core.
