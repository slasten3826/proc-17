# Packet Mortality Runner Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/packet_mortality_yellowprint.v0.md
implementation pending
```

## Purpose

Wire budget charging and loss accumulation into `runtime/tension_runner.lua` so a
packet can honestly die.

This blueprint integrates:

```text
docs/02_crystall/blueprints/budget_economy.v0.md
docs/02_crystall/blueprints/loss_accumulation.v0.md
```

## Target Gap

Current fake-substrate walk can end as:

```text
stop_reason = tick_limit
packet.death = nil
packet.residue = nil
```

after:

```text
☱ -> ☲ -> ☱ -> ☲ -> ...
```

This is host stop, not packet death.

V0 mortality must make unpaid continuation fatal before relying on host
`max_ticks`.

## Required Imports

`runtime/tension_runner.lua` should use:

```lua
local budget = require("runtime.budget")
local loss = require("runtime.loss")
```

## Runner Initialization

After packet birth:

```lua
budget.init(instance)
loss.init(instance)
```

Do this inside `tension_runner.run` before the first operator tick.

`core/packet.lua` may later initialize these directly, but runner init is enough
for v0 if tests cover it.

## Per-Tick Budget Charge

Every operator tick must charge:

```lua
budget.charge(instance, {
  operator = current,
  cost = {steps = 1},
  source = "body_tick",
  truth_status = "runtime_confirmed",
})
```

Charge before or after `run_operator`, but keep behavior consistent.

Recommended:

```text
charge before operator execution
if charge exhausts budget, do not run another expensive operation
```

Exception:

```text
birth is not a charged operator tick in v0
```

## Substrate Usage Charge

When `☴` returns observe payload with substrate response:

```lua
response.usage
```

charge:

```lua
budget.charge(instance, {
  operator = "☴",
  event_id = observe_payload.trace_event_id,
  cost = budget.from_usage(response.usage),
  source = "substrate_usage",
  truth_status = "runtime_confirmed",
})
```

Also charge:

```lua
{substrate_calls = 1}
```

If usage is missing, charge estimated tokens only if the estimator is
implemented.

Do not block mortality v0 on perfect token estimates.

## Loss Application

After `☵`:

```lua
loss.apply(instance, {
  operator = "☵",
  event_id = encode_payload.trace_event_id,
  amount = loss.from_encode_loss(encode_payload.loss),
  kind = encode_payload.loss.kind,
  source = "encode_loss",
  detail = encode_payload.loss,
  truth_status = "runtime_confirmed",
})
```

After `☳`:

```lua
loss.apply(instance, {
  operator = "☳",
  event_id = choose_payload.trace_event_id,
  amount = loss.from_choose_loss(choose_payload.loss),
  kind = choose_payload.loss.kind,
  source = "choice_loss",
  detail = choose_payload.loss,
  truth_status = "runtime_confirmed",
})
```

If the payload has no loss table, apply no loss and keep going.

Missing loss should be visible in tests only if the operator claims to be lossy.

## Mortality Check

After each tick and after budget/loss application:

```lua
if loss.is_exhausted(instance) then
  die identity_loss
elseif budget.is_exhausted(instance) then
  die budget_exhausted
end
```

V0 may directly call `packet_core.die`.

Later versions may route to `△` first when a last manifest is possible.

Direct death is acceptable in v0 because the current problem is false life.

## Budget Death Residue

Add helper inside runner or budget module.

Minimum residue:

```lua
{
  cause = "budget_exhausted",
  exhausted_keys = {},
  last_operator = current,
  trace_tail = {},
  remaining_work_count = number,
  do_not_repeat = "loop consumed budget without progress",
}
```

Use:

```lua
body.progress(instance).remaining_count
```

for `remaining_work_count`.

## Identity Loss Death Residue

Use:

```lua
loss.identity_residue(instance, {last_operator = current})
```

Cause:

```text
identity_loss
```

## Runner Result

When mortality stops the runner:

```lua
result.stop_reason = "budget_exhausted" | "identity_loss"
result.final_status = instance.status
return instance, result
```

Do not return `tick_limit` for internal packet death.

## Host Tick Limit

Keep host `max_ticks`.

If it fires:

```lua
result.stop_reason = "tick_limit"
result.final_status = instance.status
```

Do not call it `budget_exhausted`.

Do not invent death residue unless a policy explicitly kills by host guard.

V0 should leave host tick limit as host evidence.

## Router Integration

`runtime/router.lua` already reads:

```lua
instance.tension.loss_near_death
instance.tension.loss_exhausted
```

It should be updated to read budget from:

```lua
instance.runtime.budget.exhausted
```

If budget exhaustion is handled directly inside runner, router update can be
small:

```text
expose budget pressure accurately
do not rely only on raw substrate budget <= 0
```

## Test Updates

Update:

```text
tests/test_tension_runner.lua
```

Add case:

```text
max_ticks = 20
budget.steps = small number
fake substrate produces remaining work
```

Expected:

```text
result.stop_reason = "budget_exhausted"
packet.status = "dead"
packet.death.cause = "budget_exhausted"
packet.residue not nil
packet.runtime.budget.exhausted = true
```

Add loss death case if small:

```text
low max_loss / low threshold
☵ or ☳ pushes loss to exhausted
result.stop_reason = "identity_loss"
packet.death.cause = "identity_loss"
```

If that case is too wide, leave identity-loss death to `tests/test_loss_accumulation.lua`
and only route near-death in runner tests.

## Acceptance

```text
lua tests/run.lua
```

must pass.

The old Mythos/Fable failure should no longer be true for small budget:

```text
walk may still show ☱☲ pressure
but packet dies from budget_exhausted before host tick_limit
death residue exists
```

## Non-Goals

```text
perfect economic tuning
dollar pricing
full final manifest on death
TUI display
session memory changes
tool/file/test budgets
```

First goal:

```text
no free ticks
no silent immortal ☱☲ loop
honest death with residue
```
