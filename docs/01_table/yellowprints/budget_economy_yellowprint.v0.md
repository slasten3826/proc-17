# Budget Economy Yellowprint v0

Status:

```text
table
from docs/00_chaos/budget_economy_notes.md
no implementation yet
```

## Goal

Make runtime budget measurable, chargeable, visible, and capable of killing a
packet.

This is the budget side of packet mortality.

Loss remains separate packet physics.

## Budget Axes

Minimum axes:

```lua
{
  steps = number,
  substrate_calls = number,
  prompt_tokens = number,
  completion_tokens = number,
  total_tokens = number,
  estimated_tokens = number,
  tool_calls = number,
  file_writes = number,
  test_runs = number,
  time_ms = number,
  money_units = number,
}
```

V0 can implement only:

```text
steps
substrate_calls
prompt_tokens
completion_tokens
total_tokens
estimated_tokens
```

The remaining axes stay in shape for later tools.

## Packet Budget Shape

Packet should expose:

```lua
packet.substrate.budget = {
  steps = limit,
  substrate_calls = limit,
  prompt_tokens = limit | nil,
  completion_tokens = limit | nil,
  total_tokens = limit | nil,
  estimated_tokens = limit | nil,
  ...
}
```

Add runtime accounting:

```lua
packet.runtime.budget = {
  spent = {},
  remaining = {},
  events = {},
  exhausted = false,
  exhausted_keys = {},
}
```

`substrate.budget` remains requested/available budget.

`runtime.budget` records what happened.

## Budget Cost Record

Every charged event should have:

```lua
{
  kind = "budget_cost",
  operator = "☴",
  event_id = "event-3",
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

If provider usage is available:

```text
truth_status = runtime_confirmed
```

If local estimate is used:

```text
truth_status = estimated
```

## Charging Rules

```text
every operator tick -> steps +1 spent
☴ substrate invocation -> substrate_calls +1 spent
☴ response with usage -> prompt/completion/total token spent
☴ response without usage -> estimated_tokens spent
tool call -> tool_calls +1 spent
file write -> file_writes +1 spent
test run -> test_runs +1 spent
```

Do not charge loss here.

Loss is packet physics and belongs to a separate accumulator.

## Usage Source

Current code already returns:

```lua
response.usage
```

from:

```text
substrates/openai_compatible.lua
substrates/contract.lua
```

Expected usage fields:

```text
prompt_tokens
completion_tokens
total_tokens
```

If provider uses different names later, normalize them before budget charging.

## Estimator

V0 estimator may be simple:

```text
estimated_tokens = ceil(char_count / chars_per_token)
```

Default:

```text
chars_per_token = 4
```

The estimate must be marked:

```text
truth_status = estimated
```

Estimated token budget should not silently override runtime-confirmed usage.

## Budget Probe

Add later module:

```text
runtime/budget_probe.lua
```

Probe cases:

```text
short_math
copy_text
short_reasoning
small_code
```

Output:

```lua
{
  kind = "substrate_budget_profile",
  provider = string,
  model = string,
  usage_supported = boolean,
  probes = {},
  avg_prompt_tokens = number,
  avg_completion_tokens = number,
  avg_total_tokens = number,
  avg_chars_per_token = number | nil,
  truth_status = "runtime_confirmed" | "estimated",
}
```

Budget probe is useful but not required before first charging implementation.

## Routing Pressure

Budget exhaustion should become runtime pressure:

```text
runtime.budget.exhausted = true
runtime.budget.exhausted_keys = {"steps" | "total_tokens" | ...}
```

Router should see:

```text
budget.exhausted == true
```

and route toward:

```text
△
```

Death/manifest should preserve residue:

```text
budget exhausted
exhausted keys
last route
remaining work
```

## CLI Pressure

Future CLI flags:

```text
--budget-steps <n>
--budget-substrate-calls <n>
--budget-tokens <n>
--budget-estimated-tokens <n>
--budget-probe
```

First useful CLI should at least expose budget in JSONL:

```text
packet_id
session_id
operator
event_id
budget_cost
budget_spent
budget_remaining
```

## Tests

Required first tests:

```text
one tick charges steps
substrate response with usage charges token fields as runtime_confirmed
substrate response without usage charges estimated_tokens as estimated
budget spent accumulates per packet
budget remaining decreases
steps exhaustion marks budget exhausted
token exhaustion marks budget exhausted
fake ☱☲ loop can die from budget_exhausted before host tick_limit
```

## Acceptance

Budget economy v0 is accepted when:

```text
lua tests/run.lua passes
fake loop no longer relies only on tick_limit for death
JSON-visible packet budget shows per-operator and total cost
loss and budget remain separate fields
```
