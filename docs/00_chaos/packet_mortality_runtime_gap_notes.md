# Packet Mortality Runtime Gap Notes

Status:

```text
chaos
external review pressure
source: Fable/Mythos reading of procesis + proc-17
```

## Trigger

Fable read procesis and proc-17, installed Lua 5.4, and ran:

```text
lua5.4 tests/run.lua
all tests ok
```

The useful part was not praise.

The useful part was the live packet walk:

```text
walk: ▽ ☴ ☵ ☴ ☳ ☴ ☱ ☲ ☱ ☲ ☱ ☲ ☱
stop_reason: tick_limit
death_cause: nil
residue: nil
```

The packet did not die.

It was externally stopped by `max_ticks`.

That means the current runner can still create false life:

```text
motion without payment
loop without death
stop without residue
```

## What Fable Saw Correctly

The strongest existing parts are real:

```text
truth_status per trace event
semantic_proposal from substrate
runtime_confirmed only from body
spells with reality_changed
build mode requiring spell evidence
mandatory eye tick
topology validation through adjacency
development process mirroring chaos -> table -> crystall -> manifest
```

But the central packet law is not wired tightly enough:

```text
existence_must_be_paid
free_motion = false_life
packet can die from its own bad life
```

The body has theology with tests, but mortality is not yet painful.

## Existing v0 Excuse

The original tension runner note said:

```text
with fake substrate, ☱ <-> ☲ may continue until tick limit
this is correct for v0
```

That was true when the goal was movement smoke.

It is no longer enough once proc-17 claims packet mortality.

`max_ticks` is useful as a host safety guard.

It is not packet death.

## Current Runtime Gap

Observed gap:

```text
logic/cycle.lua checks whether budget can pay
runtime/tension_runner.lua limits ticks externally
router reads budget/loss pressure
but tick cost is not reliably charged into packet budget
loss records exist
but loss is not accumulated into tension.loss_remaining
```

So the route can become:

```text
☱ -> ☲ -> ☱ -> ☲ -> ...
```

and the only thing that stops it is:

```text
external max_ticks
```

That leaves:

```text
packet.status = running
death = nil
residue = nil
```

For smoke tests this is acceptable.

For packet ontology this is incomplete.

## Budget vs Loss

Keep the existing separation:

```text
budget = runtime economics
loss = packet physics
```

They are not the same variable.

Budget says:

```text
can this body afford another operation/substrate/tool/test/write?
```

Loss says:

```text
how much packet coherence remains after structure, choice, compression, and damage?
```

A packet may die because budget is exhausted.

A packet may die because loss is exhausted.

Those are different deaths.

## Correct Shape

Every tick should be paid.

At minimum:

```text
each operator tick spends budget.steps
substrate call spends budget.substrate_calls
tool call spends budget.tool_calls
file write spends budget.file_writes
test run spends budget.test_runs
```

Loss should accumulate from operations that wound form:

```text
☵ encoding loss
☳ killed alternatives / attention collapse
☷ future dissolution
possibly failed/rejected validation pressure
```

When budget is exhausted:

```text
packet dies with death_cause = budget_exhausted
residue explains unpaid continuation
```

When loss is exhausted:

```text
packet dies with death_cause = identity_loss
residue explains loss exhaustion
```

When host `max_ticks` fires:

```text
runner stops for host safety
packet should either remain running with explicit external_stop residue
or be killed by a separate cancelled/host_limit cause
```

But `tick_limit` must not pretend to be packet law.

## Why This Matters

Packet mortality is not decorative.

It is the difference between:

```text
agent loop with timeout
```

and:

```text
mortal process body
```

If a packet can move forever without paying, proc-17 repeats the old false-life
pattern that procesis and the packet myth reject.

The first honest death is more important than the first beautiful UI.

## Smallest Future Fix

Do not redesign the whole runner first.

Small v0 pressure:

```text
runtime/tension_runner charges one step per tick
budget exhaustion kills packet with residue
loss accumulator reads event.cost.loss and boundary.loss_records
tension.loss_remaining is updated
near_death/exhausted flags are set deterministically
router sees those flags and routes to △
manifest records death residue
```

The fake-substrate loop should then end as:

```text
death: budget_exhausted
residue: loop consumed budget without completing remaining work
```

or, for high-loss encode/choose cases:

```text
death: identity_loss
residue: packet coherence exhausted by compression/choice loss
```

## Non-Goal

Do not make death dramatic.

Do not make budget/loss moral.

Do not tune perfect economics yet.

The first goal is simpler:

```text
no free ticks
no silent endless ☱☲
no external max_ticks as fake death
```

## Current Interpretation

Fable's finding should be treated as valid pressure.

It does not invalidate the body.

It identifies the next missing law:

```text
the packet can be born
the packet can move
the packet can manifest
but the packet cannot yet honestly die from unpaid existence
```

That is the runtime gap.
