# Session Scoped Memory Notes

Status:

```text
chaos
new pressure from CLI design
```

## Trigger

proc-17 already has packet memory:

```text
sandbox/packets/<packet_id>.json
```

But packet memory alone is global.

If every new packet can see every old packet, unrelated tasks will contaminate
each other.

The user compared this to Codex sessions:

```text
session has context
session has continuity
session is not all memory
```

proc-17 needs the same boundary.

## New Default

The default should not be:

```text
run without session
```

The default should be:

```text
run with a fresh clean session
```

If the operator does not specify a session, CLI/TUI creates one.

That session receives a random uuid-like id.

This matches the familiar coding-agent shape:

```text
new chat/session starts clean
old sessions exist but do not leak in
resume happens only when explicitly selected
```

So session is not an optional memory feature.

Session is the container for the interaction.

Memory is optional inside that container.

## Core Insight

Memory must be scoped.

Not:

```text
all packets are one giant memory
```

But:

```text
session owns a local packet lineage
```

A session is not a living packet.

A session is a room where related packets leave residue.

```text
session
  packet A
  packet B inherits residue from A
  packet C inherits residue from A/B if selected
```

Outside the session, that residue should not enter by default.

## Why This Matters

Without sessions:

```text
task about procesis
task about notes app
task about TUI design
task about finances
```

all leave residue in the same pool.

Later ☱ could re-decode irrelevant residue and pollute the packet.

That is not memory.

That is drift.

## Session Shape

Possible storage:

```text
sandbox/sessions/<session_id>/session.json
sandbox/sessions/<session_id>/packets/<packet_id>.json
```

or:

```text
sandbox/packets/<packet_id>.json
sandbox/sessions/<session_id>.json
```

The second shape keeps packet cemetery global, while session index says which
packets belong to which room.

First version should probably use the second shape.

## Session Index

Minimal session file:

```lua
{
  kind = "proc17_session",
  session_id = "string",
  label = "string | nil",
  created_at = number,
  updated_at = number,
  packet_ids = {},
  current_packet_id = "string | nil",
  residue_policy = "explicit_parent | recent_tail | none",
}
```

`session_id` is stable machine identity.

`label` is human/operator metadata and can be added later:

```text
session_id = "9f4e1d7c-..."
label = "tui design"
```

The label must not be the filesystem identity.

## Memory Entry Rules

Default should be conservative:

```text
no explicit session -> create fresh clean session
session exists -> only session packets are candidates
explicit parent -> inherit only from selected parent packet
recent tail -> inherit from last N packets in session
```

Do not search all packet cemetery by default.

Do not automatically pull packets from other sessions.

Do not use semantic similarity as v0 memory routing.

## CLI Pressure

CLI should allow:

```text
--session <id>
--new-session
--label <text>
--memory
--memory-from <packet_id>
--memory-tail <n>
```

If no session flag is provided:

```text
create a new clean session with random id
```

If `--session <id>` is provided:

```text
resume that session
```

If `--label <text>` is provided:

```text
attach/update human label on current session
```

But first useful form can be smaller:

```text
proc17 run --session tui-design --memory --task "..."
```

Meaning:

```text
load session tui-design
inherit recent session residue if memory is enabled
run packet
save packet
append packet id to session
```

## Body Boundary

Session is runtime/container state.

It must not become operator logic.

The packet should only see inherited residue after ☱ decodes it into runtime
memory.

The router should not read random session files directly.

## TUI Pressure

TUI can show:

```text
session_id
session_label
session packet count
current packet
parent packet
memory mode on/off
inherited residue count
```

This is useful for humans.

But machine CLI must expose the same facts as JSON.

## Open Questions

```text
Should session id be UUID v4, timestamp-random, or another local id?
Should session memory inherit last packet only or last N?
Should user be able to pin important packets?
Should session be renamed/title-inferred by substrate or only explicit?
Should packet cemetery remain global with session index, or be physically nested?
```

## First Decision Pressure

For v0:

```text
CLI/TUI owns session management
every run has a session
if no session is specified, create a fresh random session
memory remains disabled by default
session memory only enters packet when memory is enabled
session memory should inherit explicit parent or last packet only
saved packet is appended to session after run
session label can be set by operator metadata
```

This keeps memory useful without making it global.
