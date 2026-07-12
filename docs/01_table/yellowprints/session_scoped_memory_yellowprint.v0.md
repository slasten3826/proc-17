# Session Scoped Memory Yellowprint v0

Status:

```text
table
from docs/00_chaos/session_scoped_memory_notes.md
no implementation yet
```

## Goal

Add scoped memory for CLI/TUI use.

Session memory prevents packet residue from becoming one global pool.

## Terms

```text
packet memory
  saved capsule of one dead/manifested packet

packet cemetery
  global storage of packet capsules

session
  runtime container for related packets

session memory
  inherited residue selected from packets inside one session
```

## Storage

Packet capsules stay in:

```text
sandbox/packets/<packet_id>.json
```

Sessions live in:

```text
sandbox/sessions/<session_id>.json
```

Session ids use same safe filename rules as packet ids:

```text
letters numbers dot underscore hyphen
```

Session id is machine identity.

Session label is optional human metadata.

## Session File

Minimal shape:

```lua
{
  kind = "proc17_session",
  protocol_version = "session.v0",
  session_id = string,
  label = string | nil,
  created_at = number,
  updated_at = number,
  packet_ids = {},
  current_packet_id = string | nil,
  residue_policy = "last_packet",
}
```

## Default Rules

```text
every CLI/TUI run has a session
if no session is specified, create a fresh clean session
memory is disabled by default
session without --memory does not inherit residue
--memory in a fresh session has no inherited residue
session memory never searches all packets by default
```

This avoids cross-task contamination.

Fresh session creation is the default because a clean run should still have
identity, logs, packets, and later resumability.

## CLI Shape

First useful commands:

```text
proc17 run --task "..." --jsonl
proc17 run --session <id> --memory --task "..." --jsonl
proc17 session list --json
proc17 session show <id> --json
```

Later:

```text
proc17 session new [--label <text>]
proc17 session label <id> <text>
proc17 session forget <id>
proc17 run --session <id> --memory-from <packet_id>
proc17 run --session <id> --memory-tail <n>
```

## Run Semantics

For:

```text
proc17 run --task T
```

CLI should:

```text
create fresh random session
run packet without inherited residue
save resulting packet capsule
append packet id to new session
emit jsonl events including session_id
```

For:

```text
proc17 run --session X --memory --task T
```

CLI should:

```text
load session X or create it if missing
select parent packet using residue_policy
load parent packet capsule if present
inherit residue from parent packet
create new packet with memory_enabled=true and inherited_residue
run tension_runner
save resulting packet capsule
append packet id to session X
update current_packet_id
emit jsonl events
```

If `--session X` is provided without `--memory`:

```text
create/load session
run packet without inherited residue
save packet
append packet id to session
```

The session tracks continuity, but memory does not enter the packet.

If `--label L` is provided:

```text
set/update session.label = L
```

The label is not used for filesystem path decisions.

## Body Boundary

Session code belongs under runtime, not core packet:

```text
runtime/session_memory.lua
```

It may use:

```text
runtime/packet_memory.lua
core/json.lua
```

It must not:

```text
route operators
validate topology
call substrate
modify old packet capsules
promote semantic content to runtime truth
```

## API Sketch

```lua
session_memory.new_id(options) -> string
session_memory.load(session_id, options) -> session | nil, err
session_memory.save(session, options) -> session, path
session_memory.create(session_id, options) -> session
session_memory.set_label(session, label) -> session
session_memory.append_packet(session, packet_id) -> session
session_memory.select_parent(session, options) -> packet_id | nil
session_memory.inherit_for_packet(session, options) -> inherited_residue[]
```

All filesystem paths must stay under:

```text
sandbox/sessions
sandbox/packets
```

## Test Requirements

```text
session id safety rejects unsafe ids
fresh id generation returns safe ids
new session can be created and saved
session label can be set without affecting path
saved session can be loaded
append packet updates packet_ids and current_packet_id
select_parent returns last packet by default
fresh session does not inherit global packets
session without memory does not inherit residue
session with memory inherits only from selected session packet
```

## Acceptance

Session memory is accepted when:

```text
run without --session creates a new clean session
two different sessions can run without sharing inherited residue
same session can carry residue from previous packet when memory is enabled
lua tests/run.lua passes
```
