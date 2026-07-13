# Session Compost Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/session_compost_yellowprint.v0.md
implementation target
```

## Scope

Implement explicit session-local compost.

Do not connect compost to router.

Do not connect compost to foundation.

Do not make compost automatic inside `add_grave`.

## Files

```text
runtime/session_memory.lua
tests/test_session_memory.lua
```

## Session Shape

Every session must have:

```lua
grave = {
  warnings = {},
  bequests = {},
  neutral = {},
}
```

Add:

```lua
compost = {
  next_insert_id = number,
  patterns = {},
}
```

`next_insert_id` starts at `1`.

## Insert Metadata

When `session_memory.add_grave(session, input)` stores a fresh grave, attach:

```lua
grave_insert_id = session.compost.next_insert_id
```

Then increment:

```lua
session.compost.next_insert_id += 1
```

Reason:

```text
compost must remove oldest graves by real session insertion order
kind ordering is not good enough
```

## API

Add:

```lua
session_memory.compost(session, options) -> payload | nil, err
```

Options:

```lua
{
  max_fresh_graves = number | nil,
  now = number | nil,
}
```

Defaults:

```lua
max_fresh_graves = 8
now = os.time()
```

Validation:

```text
session must be proc17_session
max_fresh_graves must be number >= 0
```

## Fresh Count

Fresh grave count:

```text
#session.grave.warnings
+ #session.grave.bequests
+ #session.grave.neutral
```

If count <= limit:

```text
do nothing
return payload with composted_count = 0
```

If count > limit:

```text
compost count - limit oldest graves
```

Oldest means smallest `grave_insert_id`.

If missing, treat as oldest:

```text
grave_insert_id = 0
```

This keeps older sessions loadable.

## Pattern Key

Build pattern key from:

```text
grave_kind
death_cause
last_operator
do_not_repeat
```

String form may be:

```text
grave_kind|death_cause|last_operator|do_not_repeat
```

Use empty string for nil values.

## Last Operator Extraction

For warning:

```lua
grave.warning.pattern.last_operator
or grave.residue.last_operator
or grave.death.last_operator
or "unknown"
```

For bequest/neutral:

```lua
grave.residue.last_operator
or grave.death.last_operator
or "unknown"
```

## Do Not Repeat Extraction

For warning:

```lua
grave.warning.do_not_repeat
or grave.warning.pattern.do_not_repeat
or grave.residue.do_not_repeat
```

For bequest/neutral:

```lua
nil
```

## Pattern Shape

Store compost pattern as:

```lua
{
  kind = "compost_pattern",
  key = string,
  grave_kind = "warning" | "bequest" | "neutral",
  death_cause = string | nil,
  last_operator = string,
  do_not_repeat = string | nil,
  count = number,
  first_seen_at = number,
  last_seen_at = number,
}
```

Do not store:

```text
source_packet_id
trace_tail
residue
manifest
packet metadata
```

## Pattern Merge

If pattern key exists:

```text
count += 1
last_seen_at = now
```

If pattern key does not exist:

```text
insert new pattern
count = 1
first_seen_at = now
last_seen_at = now
```

Pattern storage may be an array.

V0 may find existing pattern by linear scan.

## Grave Removal

Remove composted graves from their fresh grave arrays.

Implementation can:

```text
collect candidates with kind, index, insert_id, grave
sort by insert_id asc
choose excess candidates
remove by kind/index in descending index order
```

This avoids index shifts.

## Payload

Return:

```lua
{
  kind = "session_compost_payload",
  composted_count = number,
  fresh_grave_count_before = number,
  fresh_grave_count_after = number,
  pattern_count = number,
  truth_status = "runtime_confirmed",
}
```

## Save / Load

`session_memory.create` initializes `compost`.

`session_memory.load` must ensure missing `compost` for older session files.

`session_memory.save` must preserve `compost`.

## Tests

Extend `tests/test_session_memory.lua`:

```text
new session has compost.patterns empty
add_grave assigns increasing grave_insert_id
compost below limit does nothing
compost over limit removes oldest fresh graves
compost creates pattern without source_packet_id
same warning pattern increments count
fresh grave count stays at limit
second session compost remains empty
bequest compost creates bequest pattern
neutral compost creates neutral pattern
load old-shaped session without compost receives default compost shape
```

Integration-style test:

```text
grow two real warning graves through tension_runner deaths
add them to session
compost with low limit
verify pattern records ☱ budget_exhausted loop death
verify compost pattern contains no packet ids
```

This integration test may live in `tests/test_session_memory.lua` or a later
dedicated generation test.

## Acceptance

```text
lua tests/run.lua
```

must pass.

## Non-Goals

```text
automatic compost
foundation reinforcement
router pressure from compost
cross-session compost merge
semantic similarity
TUI display
global graveyard
```
