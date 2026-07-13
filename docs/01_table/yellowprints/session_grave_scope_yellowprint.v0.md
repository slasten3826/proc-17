# Session Grave Scope Yellowprint v0

Status:

```text
table
from docs/00_chaos/session_grave_scope_notes.md
```

## Goal

Add runtime support for session-local graves.

Do not implement CLI/TUI yet.

Do not make a global graveyard.

## Session Shape

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
  grave = {
    warnings = {},
    bequests = {},
    neutral = {},
  },
}
```

## Defaults

```text
session_memory.create(nil) creates a fresh safe id
new session grave is empty
session file lives under sandbox/sessions
session id uses safe filename rules
```

## Grave Rules

Adding a grave to a session:

```text
classify if raw
store warning under session.grave.warnings
store bequest under session.grave.bequests
store neutral under session.grave.neutral
```

Inheriting graves:

```text
session_memory.inherit_graves(session, {enabled = true})
```

returns only graves from that session.

If disabled, no grave inheritance enters the packet.

## API

```lua
session_memory.new_id() -> string
session_memory.create(session_id, options) -> session
session_memory.save(session, options) -> session, path
session_memory.load(session_id, options) -> session | nil, err
session_memory.append_packet(session, packet_id) -> session
session_memory.add_grave(session, grave_input) -> grave_record | nil, err
session_memory.inherit_graves(session, options) -> graves | nil, err
```

## Tests

```text
create without id makes safe session id
new session has empty grave
session save/load roundtrip works
append packet updates packet_ids and current_packet_id
add warning grave stores only in that session
second session starts with empty grave
inherit_graves disabled by default
inherit_graves enabled returns session-local graves
unsafe session id rejected
non-sandbox root rejected
```
