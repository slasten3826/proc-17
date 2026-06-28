# Runtime Manifestation Notes

Raw note after first `◈☱`.

## Question

How should `☱ RUNTIME` become manifest?

Not as a planner.
Not as memory.
Not as another agent.

It should become a read-only lower pressure organ.

## Current Shape

The crystal says:

```text
runtime/pressure_snapshot.lua
snapshot(input) -> runtime_pressure_snapshot_payload | nil, error
```

This was ready for a small first manifestation.

## Manifestation Direction

First manifestation was chosen to be small:

```text
pure Lua module
no file reads
no tool calls
no substrate calls
no trace append by itself
deterministic output
unit tests before CLI wiring
```

This keeps `☱` as eye, not hand.

The first CLI wiring should stay on by default, like truck brakes:

```text
runtime snapshot active unless explicitly disabled
```

The switch should disable it only when the caller explicitly asks:

```text
--no-runtime-snapshot
```

CLI still remains the normal `▽ -> △` machine surface, but it emits the lower
pressure reading as internal JSONL evidence.

## Where It Sits

Likely route:

```text
☴ repo_listing_eye
☶ repo_selection_validator
☲ cycle_decision
☱ runtime_pressure_snapshot
☲ cycle_decision consumes runtime pressure later
△ manifest report uses runtime evidence later
```

The first `△☱` can be both:

```text
tested module
optional JSONL observation in CLI
```

## What It Must Show

`☱` should show the body condition after pressure has reached the lower side:

```text
packet state
budget pressure
trace pressure
logic pressure
cycle pressure
manifest pressure
death pressure
```

It should not explain all causes.
It should not infer raw connection or dissolution.

## What We Are Not Doing Yet

We are not opening `☵`.
We are not opening `☳`.

They are adjacent to `☱`, but their own crystals are later work.

For now:

```text
☵ enters ☱ as already encoded trace/residue pressure
☳ enters ☱ as already chosen/validated branch pressure
```

## Test Thought

A good first test is not "can runtime decide?"

A good first test is:

```text
given a packet with trace, budget, logic result, and cycle result
runtime returns a bounded pressure snapshot
runtime mutates nothing
runtime does not contain next_action
```

If this passes, the lower eye exists.

## Manifested Shape

First manifestation:

```text
runtime/pressure_snapshot.lua
tests/test_runtime_pressure_snapshot.lua
cli/procesis-body.lua runtime snapshot by default
```

Observed JSONL shape:

```text
operator = ☱
type = observation
payload.kind = runtime_pressure_snapshot
payload.runtime_pressure_snapshot.kind = runtime_pressure_snapshot_payload
truth_status = runtime_confirmed
```

This makes `☱` visible during live substrate runs without turning it into the
public task/result interface.
