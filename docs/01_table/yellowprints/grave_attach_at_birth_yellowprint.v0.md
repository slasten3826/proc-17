# Grave Attach At Birth Yellowprint v0

Status:

```text
table
from Mythos/Fable Entry 003
step 2 only
```

## Goal

Attach already classified graves to a newborn packet.

Do not change router behavior yet.

Do not implement cemetery storage or compost yet.

## Split

Grave classifier produces three grave kinds:

```text
warning
bequest
neutral
```

At birth these must enter different packet areas.

## Channels

Warning channel:

```text
grave.warning -> packet.runtime.karma.warnings
```

This is mechanical inheritance.

It is not substrate advice.

It is not a chat message.

Later router may read it as route penalty.

Bequest channel:

```text
grave.bequest -> packet.runtime.karma.bequests
grave.bequest -> packet.chaos.unresolved_pressure
```

This is unfinished pressure.

It should not force the route yet.

It only makes the newborn packet non-empty in the direction where an ancestor
died with progress.

Neutral channel:

```text
grave.neutral -> packet.runtime.karma.neutral
```

Neutral graves are visible but do not create pressure.

## Truth

Death fact:

```text
runtime_confirmed
```

Applicability:

```text
grave_pressure
```

Attachment event:

```text
runtime_confirmed
```

The body can confirm that it attached a grave.

The body cannot confirm that the grave is semantically applicable yet.

## API

Extend:

```lua
runtime/grave.lua
```

Add:

```lua
grave.attach(instance, graves, options) -> attach_payload | nil, err
```

Input `graves` may be:

```text
single grave record
single raw residue/capsule/packet
array of graves/raw inputs
```

Every input must pass through `grave.classify` unless it is already
`kind = "grave"`.

## Packet Runtime Shape

Packet runtime should have:

```lua
runtime.karma = {
  warnings = {},
  bequests = {},
  neutral = {},
}
```

## Attach Payload

```lua
{
  kind = "grave_attach_payload",
  warning_count = number,
  bequest_count = number,
  neutral_count = number,
  attached_count = number,
  truth_status = "runtime_confirmed",
}
```

## Runner

`runtime/tension_runner.lua` may accept:

```lua
options.inherited_graves
```

After packet birth and before first tick:

```text
classify graves
attach warnings/bequests/neutral
store payload in result.grave
```

No route change in this step.

## Tests

```text
warning attaches to runtime.karma.warnings
bequest attaches to runtime.karma.bequests
bequest creates chaos.unresolved_pressure item
neutral attaches to runtime.karma.neutral
tension runner attaches inherited_graves before first tick
attachment does not change route yet
```

## Non-Goals

```text
router warning penalty
semantic grave retrieval
cemetery persistence
compost
generation curve
```
