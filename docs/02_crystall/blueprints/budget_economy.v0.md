# Budget Economy Blueprint v0

Status:

```text
crystall
from docs/01_table/yellowprints/budget_economy_yellowprint.v0.md
implementation pending
```

## Purpose

Implement runtime budget charging for packet mortality.

This blueprint covers budget only.

Loss accumulation remains a separate blueprint.

## Non-Negotiable Separation

```text
budget = runtime economics
loss = packet physics
```

Budget code must not mutate packet loss.

Loss code must not spend runtime budget.

Both may route to `△`, but for different reasons.

## New Module

Add:

```text
runtime/budget.lua
```

Responsibilities:

```text
normalize budget axes
charge cost
accumulate spent totals
compute remaining totals
detect exhaustion
estimate tokens when usage is missing
create budget_cost records
```

No routing.

No substrate calls.

No manifest assembly.

## Packet Shape

Keep:

```lua
packet.substrate.budget
```

as configured budget limits.

Add under runtime:

```lua
packet.runtime.budget = {
  spent = {},
  remaining = {},
  events = {},
  exhausted = false,
  exhausted_keys = {},
}
```

Initialize `remaining` from `packet.substrate.budget`.

Missing numeric limits mean "unbounded for this axis".

## API

```lua
budget.init(instance) -> instance
budget.charge(instance, input) -> record | nil, err
budget.from_usage(usage) -> cost
budget.estimate_tokens(text, options) -> estimated_count
budget.snapshot(instance) -> table
budget.is_exhausted(instance) -> boolean, keys
```

`budget.charge` input:

```lua
{
  operator = "☴",
  event_id = "event-3" | nil,
  cost = {
    steps = 1,
    substrate_calls = 1,
    prompt_tokens = 812,
    completion_tokens = 240,
    total_tokens = 1052,
  },
  source = "body_tick" | "substrate_usage" | "local_estimator",
  truth_status = "runtime_confirmed" | "estimated",
}
```

Output record:

```lua
{
  kind = "budget_cost",
  operator = "☴",
  event_id = "event-3" | nil,
  cost = {},
  source = string,
  truth_status = string,
  spent_after = {},
  remaining_after = {},
  exhausted = boolean,
  exhausted_keys = {},
}
```

## Charging Rules

Tension runner:

```text
before or after every operator tick, charge {steps = 1}
```

Observe organ / substrate call:

```text
when substrate is called, charge {substrate_calls = 1}
when response.usage exists, charge token usage
when response.usage missing, estimate tokens from prompt + response text
```

V0 can charge substrate call in tension runner if simpler, because `☴` is the
only substrate-calling organ right now.

But the budget record must still identify operator `☴`.

## Token Usage

Use provider usage when available:

```lua
usage.prompt_tokens
usage.completion_tokens
usage.total_tokens
```

If `total_tokens` is missing but prompt/completion exist:

```lua
total_tokens = prompt_tokens + completion_tokens
```

If usage is missing:

```lua
estimated_tokens = ceil((#prompt_text + #response_text) / chars_per_token)
truth_status = "estimated"
source = "local_estimator"
```

Default:

```text
chars_per_token = 4
```

## Exhaustion

For each charged axis:

```text
remaining = limit - spent
```

If `remaining <= 0`:

```lua
runtime.budget.exhausted = true
runtime.budget.exhausted_keys includes axis
```

Unbounded axes are not exhausted.

## Router Integration

Update router budget pressure to prefer:

```lua
instance.runtime.budget.exhausted
instance.runtime.budget.exhausted_keys
instance.runtime.budget.remaining
```

over raw `instance.substrate.budget <= 0`.

Raw budget remains fallback until all tests are migrated.

## Death Integration

If budget is exhausted during tension runner:

```text
route to △ if possible
manifest residue if possible
die with budget_exhausted if continuation cannot be paid
```

The first version may directly kill after a charged tick when exhaustion is
detected and no manifest has happened.

Residue should include:

```text
cause = budget_exhausted
exhausted_keys
last_operator
trace_tail
remaining_work_count
```

## Tests

Add:

```text
tests/test_budget.lua
```

Cases:

```text
init copies numeric limits into remaining
charge steps decreases remaining steps
charge accumulates spent totals
usage with prompt/completion/total charges runtime_confirmed tokens
usage without total computes total
missing usage can produce estimated_tokens
unbounded axis does not exhaust
remaining <= 0 marks exhausted
exhausted keys are stable
```

Update tension runner tests:

```text
fake loop with small steps dies/stops by budget_exhausted, not only tick_limit
normal run exposes budget records
```

## Acceptance

```text
lua tests/run.lua
```

must pass.

Manual smoke should show:

```text
packet.runtime.budget.spent.steps > 0
packet.runtime.budget.events not empty
substrate usage tokens visible when provider returns usage
```
