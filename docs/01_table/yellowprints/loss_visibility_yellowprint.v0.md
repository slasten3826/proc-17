# Loss Visibility Yellowprint v0

Status:

```text
table
from chaos/loss_visibility_between_encode_and_logic_notes.md
```

## Existing Shape

`☵` already emits aggregate loss:

```text
loss.kind
loss.input_count
loss.output_count
loss.omitted_count
loss.truncated
loss.source_detail_loss
loss.hierarchy_loss
loss.encoding_type
loss.loss_percentage
loss.loss_level
```

`packet.crystallize` already stores that loss in:

```text
packet.boundary.loss_records
packet.trace crystallization payload.loss
```

`☶` already runs spells in build mode through:

```text
logic/spells.lua
runtime/tension_runner.lua
runtime/foundation.lua
```

## Missing Shape

Aggregate loss is not addressable enough.

Need:

```text
loss.loss_log
field.encoding.loss_log
calm_delta.loss_log
```

Each loss record should be small and stable:

```lua
{
  kind = "omitted_item",
  source_kind = string,
  source_ref = string,
  item_id = string,
  reason = string,
  content_preview = string,
  truth_status = string,
}
```

For v0, `omitted_item` from `max_items` is enough.

Future loss kinds may include:

```text
compressed_detail
weakened_truth
category_ambiguity
hierarchy_lens
language_fallback
```

Do not implement those yet.

## Spell Shape

Add one `☶` spell:

```text
loss_threshold
```

Input:

```lua
{
  kind = "loss_threshold",
  name = "loss_threshold",
  loss = table,
  threshold = number,
}
```

Rules:

```text
loss.loss_percentage <= threshold -> success
loss.loss_percentage > threshold  -> failure
missing loss table                 -> failure
missing threshold                  -> default 0.50
```

Output remains a normal spell result:

```lua
kind = "spell_result"
spell_kind = "loss_threshold"
success = boolean
stdout = verdict summary
stderr = rejection reason or empty
truth_status = "runtime_confirmed"
```

## Minimal Integration

Do not route on this verdict yet.

Do not make `☵` smarter yet.

Do not make `☲` use loss verdict yet.

Just make loss visible enough that `☶` can test it.

## Test Pressure

Required tests:

```text
logic.encode limited max_items records loss_log
logic.encode non-truncated field has empty loss_log
logic.spells loss_threshold accepts below threshold
logic.spells loss_threshold rejects above threshold
organs.encode carries loss_log into packet boundary loss_records
```
