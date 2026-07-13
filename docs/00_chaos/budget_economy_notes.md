# Budget Economy Notes

Status:

```text
chaos
packet mortality follow-up
```

## Trigger

Mythos/Fable found the mortality gap:

```text
packet can loop until max_ticks
budget can be checked
but budget is not yet paid per tick
```

The user agreed with loss economics and added the next pressure:

```text
token budget must be counted too
coding agents usually know token usage
proc-17 should know how much each packet and PL trace costs
```

## Core Separation

Keep the existing split:

```text
loss = packet physics
budget = runtime economics
```

Loss answers:

```text
how much identity/coherence remains?
```

Budget answers:

```text
how much continuation can be paid?
```

They are independent axes.

Budget exhaustion can kill motion.

Loss exhaustion can kill identity.

## Budget Is Not Only Tokens

Budget should include:

```text
steps
substrate_calls
prompt_tokens
completion_tokens
total_tokens
estimated_tokens
tool_calls
file_writes
test_runs
time_ms
money_units
```

Tokens are the main LLM currency.

But they are not the only runtime cost.

## Token Truth

Token accounting has truth levels.

If substrate API returns usage:

```text
truth_status = runtime_confirmed
source = substrate_usage
```

Example usage shape:

```lua
{
  prompt_tokens = 1234,
  completion_tokens = 567,
  total_tokens = 1801,
}
```

If usage is unavailable, proc-17 may estimate:

```text
truth_status = estimated
source = local_estimator
```

Estimated token budget should be visible as estimate.

It must not pretend to be runtime-confirmed usage.

## Existing Code Pressure

Current substrate contract already preserves usage:

```text
substrates/openai_compatible.lua -> decoded.usage
substrates/contract.lua -> response.usage
```

So token accounting can be wired without changing the API provider shape first.

The body just does not yet charge those tokens into budget.

## Budget Probe

proc-17 should be able to profile a substrate.

Not because the body cannot count official usage.

Because the body should learn the practical cost profile of a substrate:

```text
short input
long output
reasoning-like answer
copy task
code task
```

Probe examples:

```text
input probe:
  "Solve: 1847 * 29. Answer only with the number."

output probe:
  "Rewrite this text exactly: <known text>"

reasoning probe:
  "Solve a small problem and show short reasoning."

code probe:
  "Write a small function and one test."
```

Probe output should create a substrate economy profile:

```lua
{
  kind = "substrate_budget_profile",
  provider = "deepseek",
  model = "deepseek-chat",
  usage_supported = true,
  probes = {},
  avg_prompt_tokens = number,
  avg_completion_tokens = number,
  avg_total_tokens = number,
  avg_chars_per_token = number | nil,
  truth_status = "runtime_confirmed" | "estimated",
}
```

## Per-Trace Cost

Budget must be visible per packet and per operator.

Example:

```text
packet_id: packet-17
trace: ▽☴☵☴☳☴☱☲△
budget.total_tokens: 4312
budget.steps_spent: 9
most_expensive_operator: ☴
```

Operator cost shape:

```lua
{
  operator = "☴",
  event_id = "event-3",
  budget_cost = {
    steps = 1,
    substrate_calls = 1,
    prompt_tokens = 812,
    completion_tokens = 240,
    total_tokens = 1052,
    time_ms = 1430,
    truth_status = "runtime_confirmed",
  },
}
```

Most non-substrate organs may cost:

```text
tokens = 0
steps = 1
```

That is still useful.

It shows what costs machine thought and what costs substrate current.

## Budget Limits

Later CLI/TUI should allow:

```text
--budget-tokens 10000
--budget-steps 64
--budget-substrate-calls 8
```

If tokens remaining approaches zero:

```text
☱ may route to △ before another substrate call
```

If tokens are exhausted:

```text
death_cause = budget_exhausted
residue = token budget exhausted
```

The first implementation should not over-optimize this.

Just make budget measured, charged, visible, and fatal.

## Cost Of PL Trace

The user wants to see:

```text
how much each PL trace cost
how much the packet cost
how much each mode costs
which route is cheaper
```

This makes budget empirical.

After enough runs, proc-17 can compare:

```text
same task
different substrate
different route
different work_mode
different budget cap
```

and learn which body motion is cheaper without confusing cheapness with truth.

## Non-Goal

Do not price in dollars first.

Dollars can be added later.

For v0, "budget" can mean:

```text
tokens + steps + calls
```

Money is only a projection of budget under a provider price table.

## First Useful Shape

For v0:

```text
charge one step per tick
charge one substrate_call per ☴ substrate invocation
if substrate response has usage, charge prompt/completion/total tokens
store per-event budget_cost
accumulate packet budget spent/remaining
make budget exhaustion route/manifest/death visible
```

This closes the first mortality gap without pretending the economics are final.
