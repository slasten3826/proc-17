# Packet Mortality Yellowprint v0

Status:

```text
table
from docs/00_chaos/packet_mortality_runtime_gap_notes.md
implementation pending
```

## Goal

Make packet death internal to proc-17 body.

The packet must not only be externally stopped by host `max_ticks`.

It must be able to die because continuation cannot be paid or identity cannot
survive accumulated loss.

## Source Pressure

Mythos/Fable observed a fake-substrate walk:

```text
▽ ☴ ☵ ☴ ☳ ☴ ☱ ☲ ☱ ☲ ☱ ☲ ☱
stop_reason: tick_limit
death_cause: nil
residue: nil
```

This is acceptable as old smoke behavior.

It is not acceptable as packet mortality.

## Invariants

```text
existence_must_be_paid
free_motion_is_false_life
death_must_leave_residue
max_ticks_is_host_guard_not_packet_law
```

## Two Death Axes

Budget death:

```text
axis: runtime economics
cause: budget_exhausted
meaning: continuation cannot be paid
```

Loss death:

```text
axis: packet physics
cause: identity_loss
meaning: packet coherence is exhausted
```

These axes must remain separate:

```text
budget does not directly create loss
loss does not directly spend budget
```

Both can route toward `△`.

Both can create death residue.

## Budget Payment

Budget economy is specified in:

```text
docs/01_table/yellowprints/budget_economy_yellowprint.v0.md
```

Minimum payment rules:

```text
operator tick -> steps
☴ substrate call -> substrate_calls
☴ substrate usage -> prompt/completion/total tokens
tool call -> tool_calls
file write -> file_writes
test run -> test_runs
```

If budget cannot pay continuation:

```text
runtime.budget.exhausted = true
runtime.budget.exhausted_keys = {...}
router sees budget pressure
packet goes toward △ or dies budget_exhausted
```

## Loss Accumulation

Loss visibility is specified in:

```text
docs/01_table/yellowprints/loss_visibility_yellowprint.v0.md
```

Loss sources:

```text
☵ ENCODE: compression/projection/omission/truncation
☳ CHOOSE: killed alternatives / attention collapse
☷ DISSOLVE: future weakening/removal
☶ LOGIC: future rejected form pressure, if needed
```

Minimum runtime fields:

```lua
packet.tension.loss = number
packet.tension.loss_remaining = number
packet.tension.loss_near_death = boolean
packet.tension.loss_exhausted = boolean
```

Initial direction:

```text
loss starts with full coherence
loss records subtract from remaining coherence
near_death threshold routes to △
exhausted threshold kills identity
```

Do not tune perfect loss math in v0.

First loss economy can be crude if visible and deterministic.

## Operator Loss Pressure

Rough first operator expectations:

```text
▽ FLOW      no loss at birth
☰ CONNECT   low loss
☷ DISSOLVE  medium/high loss when implemented
☴ OBSERVE   near-zero loss
☵ ENCODE    high variable loss
☳ CHOOSE    medium/high variable loss
☲ CYCLE     near-zero loss
☶ LOGIC     low/medium loss only if rejection damages route
☱ RUNTIME   near-zero loss
△ MANIFEST  terminal, not ordinary loss
```

Important:

```text
☲ should spend budget, but almost no loss
☱ should spend budget, but almost no loss
☵ and ☳ are first real loss generators
```

## Host Guard vs Packet Death

`max_ticks` remains useful.

It prevents broken code from running forever.

But it must be represented as host guard:

```text
stop_reason = tick_limit
death = nil
packet may remain running
residue says external host guard stopped observation
```

or, if policy chooses to kill:

```text
death_cause = cancelled
residue says host tick limit stopped packet
```

It must not be confused with:

```text
budget_exhausted
identity_loss
complete
```

## Residue Requirements

Every death must leave residue.

Budget death residue:

```lua
{
  cause = "budget_exhausted",
  exhausted_keys = {},
  last_operator = "☲",
  trace_tail = {},
  remaining_work_count = number,
  do_not_repeat = "loop consumed budget without progress",
}
```

Identity loss residue:

```lua
{
  cause = "identity_loss",
  loss = number,
  loss_remaining = number,
  loss_records_tail = {},
  do_not_repeat = "packet coherence exhausted by loss",
}
```

Complete death residue:

```lua
{
  cause = "complete",
  manifest_type = string,
}
```

## Runtime Integration Points

Likely modules:

```text
runtime/budget.lua
runtime/loss.lua
runtime/tension_runner.lua
runtime/router.lua
core/packet.lua
logic/manifest.lua
```

`core/packet.lua` already supports:

```text
budget_exhausted
identity_loss
complete
cancelled
```

Use existing causes before inventing new ones.

## Router Pressure

Router should receive:

```text
budget.exhausted
budget.exhausted_keys
loss.near_death
loss.exhausted
```

Routing rule:

```text
loss exhausted -> △ or direct identity_loss death
loss near death -> △
budget exhausted -> △ or direct budget_exhausted death
```

Do not let `☱ <-> ☲` continue without payment.

## First Acceptance Test

Create a fake loop test with small budget:

```text
prompt creates remaining work
fake substrate does not complete work
max_ticks is high
budget.steps is low
```

Expected:

```text
stop_reason != tick_limit
packet.death.cause = budget_exhausted
packet.residue not empty
trace shows paid ticks
runtime.budget.exhausted = true
```

## Second Acceptance Test

Create high-loss encode/choose case:

```text
large input
small encode limit
many killed alternatives
loss threshold low
```

Expected:

```text
packet.tension.loss_remaining decreases
loss_near_death or loss_exhausted becomes true
router routes toward △
if exhausted, packet.death.cause = identity_loss
residue explains loss exhaustion
```

## Non-Goals

```text
perfect operator pricing
money pricing
smart budget optimizer
semantic loss recovery
new UI
new agent autonomy
```

The first table target is simpler:

```text
no free ticks
visible budget cost
visible loss accumulation
honest death with residue
```

## Next Crystall Pressure

Crystall should split into two small blueprints:

```text
budget charging v0
loss accumulation v0
```

Then a third integration blueprint:

```text
mortality runner integration v0
```

Do not implement all mortality in one large patch unless the code shape stays
small and testable.
