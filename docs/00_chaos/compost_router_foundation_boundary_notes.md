# Compost Router Foundation Boundary Notes

Status:

```text
chaos
reflection after session compost manifest
```

## Current Router State

Router reads only packet-local runtime pressure.

For grave inheritance it currently reads:

```text
packet.runtime.karma.warnings
```

These are fresh warning graves attached at packet birth.

The current grave route effect is deliberately narrow:

```text
if packet repeats inherited ☱☲ dead loop
then ☱ -> △
reason = karma_warning_manifest_pressure
```

This is fresh-grave pressure.

It is not compost pressure.

## Current Foundation State

Foundation exists as runtime machinery for stabilized patterns.

But grave and compost are not connected to foundation yet.

Current shape:

```text
grave -> karma -> router
grave -> compost
```

Missing future shape:

```text
compost -> foundation
```

## Why Router Should Not Read Compost Directly

Compost is statistical soil.

Fresh grave is a direct death record.

If router reads compost directly, old statistics can become hard commands.

That would make compost too strong.

It would turn:

```text
this session saw this pattern many times
```

into:

```text
never route this way
```

too early.

That risks the same poison problem grave classification was built to avoid.

## Proposed Boundary

Fresh grave:

```text
strong pressure
packet.runtime.karma.warnings
router may react mechanically
```

Compost:

```text
weak pressure
session.compost.patterns
should become foundation pressure later
router should not read session.compost directly
```

Foundation:

```text
body habit
not a command
not a memory archive
not an LLM summary
```

## Possible Future Flow

At packet birth:

```text
session.compost.patterns
  -> packet.runtime.foundation.patterns
```

Example:

```lua
{
  kind = "compost_foundation_pattern",
  source = "session_compost",
  death_cause = "budget_exhausted",
  last_operator = "☱",
  count = 14,
  truth_status = "runtime_confirmed",
}
```

This should not directly block a route.

It should alter foundation pressure that the normal runtime machinery can later
observe.

## Testing Order

Do not wire compost to foundation yet.

First prove compost itself in a generation test:

```text
same session
many packet deaths
grave fills
compost trims fresh graves
compost pattern count rises
individual packet ids disappear
```

Only after that should the project test:

```text
compost pattern enters foundation
foundation changes packet behavior
```

## Rule Of Thumb

```text
fresh grave can warn
compost can bias
foundation can remember as habit
router should only see packet-local pressure
```

Session files should not become hidden router inputs.
