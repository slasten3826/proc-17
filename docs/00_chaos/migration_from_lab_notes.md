# Migration From Lab Notes

Raw migration notes for rebuilding `proc-17` from the first body.

The first body is now the donor/lab:

```text
/home/slasten/work/procesis-body
```

The new body is:

```text
/home/slasten/work/proc-17-next
```

## Rule

Do not rebuild from nothing.

Move proven organs from the lab into the new body.

But do not move the old packet center.

## Packet Rule

Old packet-related assumptions are not trusted.

If a module expects old `packet.v0` shape directly, it must be treated as a
gap/adaptation point before becoming live in the new body.

Exception:

```text
☲ cycle
```

The latest cycle module moves as-is because it is pure and already reflects the
near-zero-loss progress gate.

## First Green Layer

Moved from lab:

```text
core/json.lua
core/modes.lua
core/sandbox.lua
core/topology.lua
logic/encode.lua
logic/choose.lua
logic/cycle.lua
logic/manifest.lua
logic/repo_selection.lua
runtime/operator_hints.lua
runtime/system_prompt.lua
runtime/trace_store.lua
runtime/pressure_snapshot.lua
tools/*
substrates/*
```

Not moved as live route yet:

```text
cli/procesis-body.lua
organs/repo_listing.lua
organs/repo_context.lua
old tests that require old packet behavior
```

## Victory Condition

The rebuild is successful when the notes-app test can run in the new body in
one packet life, with the body cycling itself until the app is complete.

The body should not need manual bridge work for:

```text
file block extraction
workspace writing
test running
result observation
fix loop
```

Those should emerge as packet/calm/cycle-capable body functions.

