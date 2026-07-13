# Session Grave Scope Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/session_grave_scope_yellowprint.v0.md
implementation target
```

## Scope

Implement session-local grave storage.

Do not connect CLI/TUI.

Do not connect automatic runner retrieval yet.

## Files

```text
runtime/session_memory.lua
tests/test_session_memory.lua
tests/run.lua
```

## Storage

Default root:

```text
sandbox/sessions
```

Path:

```text
sandbox/sessions/<session_id>.json
```

Reject:

```text
absolute paths
parent traversal
non-sandbox roots
unsafe ids
```

## Session Creation

```lua
session_memory.create(session_id, options) -> session
```

If `session_id == nil`, generate safe local id.

Every new session must include:

```lua
grave = {
  warnings = {},
  bequests = {},
  neutral = {},
}
```

## Grave Add

```lua
session_memory.add_grave(session, input) -> grave_record | nil, err
```

If `input.kind == "grave"`, use it.

Otherwise:

```lua
runtime.grave.classify(input)
```

Store by `grave_kind`.

## Grave Inheritance

```lua
session_memory.inherit_graves(session, options) -> graves | nil, err
```

Requires:

```lua
options.enabled == true
```

Returns array:

```text
warnings then bequests then neutral
```

No cross-session lookup.

## Acceptance

```text
lua tests/run.lua
```

must pass.
