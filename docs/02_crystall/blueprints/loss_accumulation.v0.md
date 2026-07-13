# Loss Accumulation Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/packet_mortality_yellowprint.v0.md
implementation pending
```

## Purpose

Implement packet loss accumulation.

This blueprint covers loss only.

Budget charging remains separate:

```text
docs/02_crystall/blueprints/budget_economy.v0.md
```

## Non-Negotiable Separation

```text
loss = packet physics
budget = runtime economics
```

Loss code must not spend budget.

Budget code must not mutate loss.

## New Module

Add:

```text
runtime/loss.lua
```

Responsibilities:

```text
normalize loss amounts
accumulate loss into packet.tension
compute loss_remaining
set near_death/exhausted flags
create loss_accumulation records
build identity_loss residue
```

No routing.

No substrate calls.

No budget charging.

## Packet Shape

Use existing tension fields:

```lua
packet.tension.loss = number
packet.tension.loss_remaining = number
packet.tension.loss_near_death = boolean
packet.tension.loss_exhausted = boolean
packet.tension.loss_events = {}
```

Initialize:

```lua
loss = 0
loss_remaining = 1.0
loss_near_death = false
loss_exhausted = false
loss_events = {}
```

If these fields are absent on an existing packet, `runtime/loss.lua` should
initialize them lazily.

## API

```lua
loss.init(instance, options) -> instance
loss.apply(instance, input) -> record | nil, err
loss.from_encode_loss(encoded_loss) -> amount
loss.from_choose_loss(choice_loss) -> amount
loss.snapshot(instance) -> table
loss.is_exhausted(instance) -> boolean
loss.identity_residue(instance, options) -> table
```

`loss.apply` input:

```lua
{
  operator = "☵",
  event_id = "event-4" | nil,
  amount = 0.25,
  kind = "field_compression",
  source = "encode_loss" | "choice_loss" | "dissolve_loss" | "manual",
  detail = {},
  truth_status = "runtime_confirmed",
}
```

Output record:

```lua
{
  kind = "loss_accumulation",
  operator = "☵",
  event_id = "event-4" | nil,
  amount = 0.25,
  source = "encode_loss",
  loss_after = 0.25,
  loss_remaining_after = 0.75,
  near_death = false,
  exhausted = false,
  truth_status = "runtime_confirmed",
}
```

## Thresholds

Default:

```text
max_loss = 1.0
near_death_at = 0.20 remaining
exhausted_at = 0.00 remaining
```

Meaning:

```text
loss_remaining <= 0.20 -> loss_near_death = true
loss_remaining <= 0.00 -> loss_exhausted = true
```

Allow options override for tests:

```lua
loss.init(instance, {max_loss = 1.0, near_death_at = 0.2})
```

## Encode Loss Mapping

`organs/encode.lua` already carries:

```lua
payload.loss.loss_percentage
payload.loss.omitted_count
payload.loss.truncated
payload.loss.loss_level
payload.loss.loss_log
```

V0 mapping:

```lua
amount = clamp(loss_percentage or 0, 0, 1)
```

If `loss_percentage` is missing:

```lua
amount = omitted_count > 0 and 0.1 or 0
```

Do not use `loss.amount` directly for encode if it is a count.

Counts and percentages are different units.

## Choose Loss Mapping

`logic/choose.lua` already emits:

```lua
payload.loss.not_chosen_count
payload.loss.before_count
payload.loss.after_count
payload.loss.truncated
payload.loss.collapse_level
```

V0 mapping:

```lua
amount = not_chosen_count / before_count
```

Clamp:

```text
0.0 <= amount <= 1.0
```

If `before_count` is missing or zero:

```lua
amount = 0
```

This makes a 1-of-many collapse more expensive than a 1-of-2 collapse.

## Near-Zero Operators

Do not apply normal loss for:

```text
☴ OBSERVE
☱ RUNTIME
☲ CYCLE
```

They spend budget, but should not materially damage identity in v0.

If later evidence shows they should apply small loss, that must be a separate
change.

## Integration Points

Apply encode loss after:

```text
organs/encode.lua -> packet.crystallize(...)
```

Apply choose loss after:

```text
organs/choose.lua -> body.record_choice(...)
```

Store runtime loss events under:

```lua
packet.tension.loss_events
```

Do not duplicate all `boundary.loss_records`.

Loss accumulation records are runtime physics.

Boundary loss records are operator evidence.

## Identity Loss Residue

`loss.identity_residue(instance, options)` should return:

```lua
{
  cause = "identity_loss",
  loss = number,
  loss_remaining = number,
  loss_near_death = boolean,
  loss_exhausted = boolean,
  loss_events_tail = {},
  loss_records_tail = {},
  last_operator = string,
  do_not_repeat = "packet coherence exhausted by loss",
}
```

Tail limits default to small counts:

```text
loss_events_tail = 5
loss_records_tail = 5
```

## Tests

Add:

```text
tests/test_loss_accumulation.lua
```

Cases:

```text
init creates loss fields
apply loss decreases remaining
near_death flag appears at threshold
exhausted flag appears at zero
encode percentage maps to amount
encode count fallback does not treat omitted_count as percentage
choose loss maps killed alternatives ratio
near-zero operators are not charged by default
identity residue includes loss tail and cause
```

## Acceptance

```text
lua tests/run.lua
```

must pass.

Manual inspection should show:

```text
packet.tension.loss_remaining changes after ☵/☳
router can see loss_near_death/loss_exhausted through packet.tension
```
