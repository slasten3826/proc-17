# Session Compost Notes

Status:

```text
chaos
from Mythos/Fable grave notes and session-local grave correction
```

## Trigger

Grave now works as session-local inheritance:

```text
packet dies
grave.classify
session.grave stores warning / bequest / neutral
next packet can inherit session graves
router can react to warning pressure
```

But this creates a new danger.

If graves never die, memory becomes hidden immortality.

The system would preserve old individual deaths forever and let them command
new packets indefinitely.

That contradicts packet mortality.

So grave itself needs decay.

## Core Claim

Compost is the death of graves.

Not deletion into nothing.

Not permanent archive.

Compost means:

```text
individual grave dies
statistical pattern remains
```

The full story disappears.

The lesson becomes soil.

## Session Scope

Compost must be session-local.

Each session has:

```text
session.grave
session.compost
```

There is no global compost in v0.

Reason:

```text
different sessions are different rooms
different rooms should not inherit each other's dead pressure
```

If a finance session creates a grave, a TUI design session should not inherit
its compost unless the operator explicitly merges sessions later.

That is out of scope for v0.

## Fresh Grave

A fresh grave keeps individuality:

```text
source_packet_id
death
residue
trace_tail
grave_kind
warning / bequest / neutral payload
```

Fresh graves are still close enough to the original packet that they can
pressure a descendant directly.

## Composted Pattern

A composted pattern should not keep individuality.

It should keep only shape:

```lua
{
  kind = "compost_pattern",
  grave_kind = "warning",
  death_cause = "budget_exhausted",
  last_operator = "☱",
  do_not_repeat = "loop consumed budget without progress",
  count = number,
}
```

This is no longer "packet X died".

It is "this session has seen this death pattern N times".

## What Must Be Lost

Compost should remove:

```text
source_packet_id
trace_tail
full residue
manifest
packet-specific metadata
```

If compost keeps these forever, it is not compost.

It is just archive with another name.

## What May Remain

Compost may keep:

```text
grave_kind
death_cause
last_operator
do_not_repeat
remaining_work_count bucket
count
first_seen_at
last_seen_at
```

The exact set should stay small.

Compost is not human-readable history.

It is body soil.

## Threshold

Compost should happen when fresh graves exceed a limit.

Example:

```text
max_fresh_graves = 8
```

If a ninth grave enters, the oldest grave decays into compost.

Fresh grave list stays bounded.

Compost pattern count grows.

## Warning / Bequest / Neutral

Warning compost is straightforward:

```text
same death pattern happened N times
```

Bequest compost is more delicate.

A bequest is not a bad route.

It is useful unfinished work.

If bequests compost too aggressively, the system may lose useful continuation.

V0 can still compost bequests, but the pattern should not become a router
penalty.

Neutral compost is lowest priority.

It may be counted but should not pressure routing.

## Foundation Boundary

Mythos suggested:

```text
grave -> compost -> foundation
```

This is probably right, but not all at once.

V0 compost can live in:

```text
session.compost.patterns
```

Later step can decide how these patterns enter:

```text
packet.runtime.foundation
```

Do not wire foundation too early.

First prove that graves decay correctly.

## Runtime Boundary

Router should not read session files directly.

Runner/session layer may attach fresh graves at packet birth.

Later, runner/session layer may also attach compost pressure, but that is a
separate decision.

For now:

```text
session_memory owns storage
grave owns classification
router owns route pressure only after packet birth
```

## Test Shape

A good compost test should not use prose.

It should mechanically prove:

```text
create session
add graves over threshold
compost runs
oldest fresh grave removed
session.compost.patterns receives shape
pattern count increments on repeated shape
source_packet_id does not survive compost
fresh grave count remains bounded
second session compost is empty
```

This proves:

```text
grave is useful
grave is mortal
session boundary holds
statistical soil survives individual death
```

## Non-Goals

```text
global graveyard
semantic grave retrieval
LLM-based similarity
foundation reinforcement
router reading compost directly
cross-session merge
human memory UI
```

## Open Questions

Should warning, bequest, and neutral share one `max_fresh_graves` limit or have
separate limits?

Should compost trigger automatically inside `session_memory.add_grave`, or only
when `session_memory.compost(session)` is explicitly called?

Should compost patterns preserve `grave_kind`, or should warning/bequest/neutral
have separate pattern stores?

Should bequest compost keep a very small `remaining_work_count` bucket, or is
that already too much identity?
