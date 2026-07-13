# Grave Router Warning Yellowprint v0

Status:

```text
table
from Mythos/Fable Entry 003
step 3 only
```

## Goal

Make inherited warning graves mechanically visible to the router.

Do not use LLM semantic retrieval.

Do not implement cemetery or compost yet.

## Core Rule

Warning graves do not rewrite the whole route.

They only penalize entering a known dead pattern.

V0 target pattern:

```text
ancestor died in ☱☲ loop without progress
descendant is about to enter repeated ☱ -> ☲ again
```

The first cycle is allowed.

The repeated cycle is blocked.

Reason:

```text
one ☲ may be work
☱☲☱☲ with no new signal is the inherited dead pattern
```

## Router Input

Router pressure snapshot should expose:

```lua
karma = {
  warning_count = number,
  bequest_count = number,
  neutral_count = number,
  active_warning = table | nil,
}
```

`active_warning` is chosen by deterministic body rules, not by substrate.

## Warning Match v0

A warning matches repeated cycle when:

```text
warning.grave_kind == "warning"
warning.warning.pattern.last_operator == "☲" or "☱"
warning.warning.do_not_repeat exists
current router source == "☱"
normal route would be "☲"
last_cycle.decision == "again"
  or last_cycle.reason == "remaining_work"
```

This is deliberately narrow.

It prevents the grave from poisoning good routes.

## Router Action

When matched:

```text
☱ -> △
reason = "karma_warning_manifest_pressure"
```

The packet does not silently continue the inherited dead loop.

It manifests residue/evidence instead.

## Non-Goals

```text
warning scoring
warning decay
bequest routing
grave semantic similarity
cemetery persistence
compost
```

## Integration Lesson

Do not rely only on hand-written warning fixtures.

At least one test must grow the warning from a real budget death:

```text
ancestor dies
grave.classify(ancestor)
descendant inherits grave
descendant avoids repeated ☱☲ loop
```
