# Loss Visibility Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/loss_visibility_yellowprint.v0.md
```

## Purpose

Make `☵` loss inspectable by `☶`.

This closes the first gap between encoded packet structure and runtime
validation.

## Scope

In scope:

```text
logic/encode.lua loss_log
organs/encode.lua loss_log carry
logic/spells.lua loss_threshold spell
tests for encode, spells, organ packet carry
```

Out of scope:

```text
router decisions from loss verdict
loss recovery
substrate re-ask
new encode structures
new cycle behavior
```

## ENCODE Contract Additions

`encode.encode(input)` must include:

```lua
encoded.field.encoding.loss_log = {}
encoded.field.loss_log = {}
encoded.loss.loss_log = {}
```

The same records may be shared by value.

When `max_items` truncates input, `loss_log` must include one record per omitted
input item.

Minimum record:

```lua
{
  kind = "omitted_item",
  source_kind = string,
  source_ref = string,
  item_id = string,
  reason = "max_items",
  content_preview = string,
  truth_status = string,
}
```

## ORGAN Carry Contract

`organs/encode.lua` must carry:

```lua
calm_delta.loss_log
loss.loss_log
payload.loss.loss_log
```

`packet.crystallize` already stores `record.loss`, so no packet API change is
required for v0.

## LOGIC Spell Contract

`logic/spells.lua` must support:

```lua
spells.run({
  kind = "loss_threshold",
  name = "loss_threshold",
  loss = encoded.loss,
  threshold = 0.50,
})
```

Success rule:

```text
loss.loss_percentage <= threshold
```

Failure rule:

```text
loss missing or loss.loss_percentage > threshold
```

The spell must be deterministic and must not execute shell commands.

## Acceptance

The work is accepted when:

```text
lua tests/run.lua
```

passes, and focused tests prove:

```text
truncation creates addressable loss_log
no truncation creates empty loss_log
loss_threshold accepts/rejects by threshold
packet boundary stores loss_log after organ encode
```
