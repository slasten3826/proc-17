# Session Compost Yellowprint v0

Status:

```text
table
from docs/00_chaos/session_compost_notes.md
no crystall yet
```

## Purpose

Keep session grave useful without letting it become immortal memory.

Compost converts old individual graves into bounded statistical soil.

```text
fresh grave = individual death record
compost pattern = repeated death shape without individual identity
```

## Boundary

Compost belongs to session storage.

V0 location:

```lua
session.compost = {
  patterns = {},
}
```

Compost does not belong to:

```text
global memory
router
LLM context
packet core
```

Router may use grave pressure only after runner/session layer attaches it to a
packet.

Foundation integration is later.

## Session Shape Extension

Current session:

```lua
session.grave = {
  warnings = {},
  bequests = {},
  neutral = {},
}
```

Add:

```lua
session.compost = {
  patterns = {},
}
```

Fresh grave remains the direct inheritance pool.

Compost is compressed history.

## V0 Trigger Decision

Use explicit compost call:

```lua
session_memory.compost(session, options)
```

Do not automatically compost inside `session_memory.add_grave` in v0.

Reason:

```text
explicit call is easier to test
explicit call keeps add_grave simple
automatic compost can be added later after behavior is measured
```

## V0 Limit Decision

Use one total fresh grave limit:

```lua
max_fresh_graves = 8
```

The total fresh grave count is:

```text
#warnings + #bequests + #neutral
```

If total count is over limit, compost oldest graves until total count equals
limit.

This means each fresh grave needs insertion order metadata or the compost
algorithm needs a stable ordering.

V0 should prefer stable ordering without mutating grave records if possible:

```text
warnings oldest first
bequests oldest first
neutral oldest first
```

This is imperfect because it gives warning graves first decay priority.

Open concern:

```text
true insertion order may be needed later
```

## Alternative Limit Model

Separate limits:

```lua
max_fresh_warnings = 8
max_fresh_bequests = 8
max_fresh_neutral = 4
```

Rejected for v0.

Reason:

```text
more knobs before we know the pressure
harder to reason about generation experiments
```

Keep this as future option.

## Pattern Key

V0 pattern key:

```text
grave_kind
death_cause
last_operator
do_not_repeat
```

For warning graves:

```lua
last_operator = grave.warning.pattern.last_operator
do_not_repeat = grave.warning.do_not_repeat
```

For bequest graves:

```lua
last_operator = residue.last_operator or death.last_operator
do_not_repeat = nil
```

For neutral graves:

```lua
last_operator = residue.last_operator or death.last_operator
do_not_repeat = nil
```

If `last_operator` is missing:

```text
last_operator = "unknown"
```

## Pattern Shape

```lua
{
  kind = "compost_pattern",
  grave_kind = "warning" | "bequest" | "neutral",
  death_cause = string | nil,
  last_operator = string,
  do_not_repeat = string | nil,
  count = number,
  first_seen_at = number,
  last_seen_at = number,
}
```

Do not preserve:

```text
source_packet_id
trace_tail
full residue
manifest
packet-specific metadata
```

If any of those survive compost, v0 is wrong.

## Warning Compost

Warning compost means:

```text
this session repeatedly died this way
```

It is not a fresh router warning yet.

V0 compost should not directly affect router.

Later bridge may turn compost patterns into foundation pressure.

## Bequest Compost

Bequest compost is allowed in v0, but weaker than warning compost.

It must not become a router penalty.

Pattern may preserve only coarse continuation shape:

```lua
grave_kind = "bequest"
death_cause = "budget_exhausted"
last_operator = "☱"
count = N
```

Do not preserve exact remaining work list.

Reason:

```text
exact remaining work belongs to fresh bequest
composted bequest is only evidence that useful deaths happened in this session
```

## Neutral Compost

Neutral compost is mostly accounting.

It should not pressure route.

It may be useful later for session statistics.

## API Sketch

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

Payload:

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

## Data Flow

```text
session_memory.add_grave(session, grave_input)
  -> session.grave.*

session_memory.compost(session, {max_fresh_graves = 8})
  -> removes oldest excess fresh graves
  -> increments session.compost.patterns
```

No packet is born during compost.

No substrate is called.

No route is changed.

## Test Plan

Minimum tests:

```text
new session has compost.patterns empty
compost below limit does nothing
compost over limit removes excess fresh graves
compost creates pattern without source_packet_id
repeated same warning increments pattern count
fresh grave count remains bounded
second session compost remains empty
bequest compost creates bequest pattern but no warning penalty
neutral compost creates neutral pattern
```

Important integration-style test:

```text
grow real warning graves through packet deaths
add them to one session
compost over threshold
verify individual packet ids are gone
verify pattern count records repeated ☱☲ budget death
```

This follows the lesson:

```text
death fixtures should be grown by death
```

## V0 Non-Goals

```text
automatic compost in add_grave
global compost
cross-session merge
foundation reinforcement
router reading compost
LLM similarity
human-readable grave archive
TUI display
```

## Open Questions

Should v0 add insertion metadata to graves when they enter session.grave?

Should compost use total grave limit or per-kind limits after generation tests?

Should bequest compost retain a coarse `remaining_work_count_bucket`, or is even
that too much identity?

Should compost payload include pattern ids for debugging, or would that leak too
much internal detail?
