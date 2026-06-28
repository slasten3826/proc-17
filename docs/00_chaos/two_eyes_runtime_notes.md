# Two Eyes Runtime Notes

Raw notes for thinking about the second eye:

```text
☱ RUNTIME
```

## Trigger

After first working organs:

```text
▽ FLOW
☴ OBSERVE
☶ LOGIC
☲ CYCLE
```

the next pressure is:

```text
☱ RUNTIME
```

Not as "memory database".
Not as "state manager that decides everything".
But as the second eye.

## Two Eyes

The body seems to need two read-only eyes:

```text
☴ OBSERVE
  external evidence eye

☱ RUNTIME
  internal evidence eye
```

They should be technically similar.
They should speak the same payload language.
They should look in opposite directions.

## ☴ OBSERVE Direction

OBSERVE looks outward / chaos-side:

```text
repo tree
file contents
tool output
substrate output
external uncertainty
unsupported emitted forms
```

Current OBSERVE organs:

```text
repo_listing_eye
repo_context_organ
```

OBSERVE answers:

```text
what is visible outside the packet?
```

## ☱ RUNTIME Direction

RUNTIME should look inward / manifest-side:

```text
packet state
budget
mode
current operator
trace tail
last event
last truth statuses
cycle pressure
death pressure
continuation capacity
residue shape
```

RUNTIME answers:

```text
what can the body sustain right now?
```

## Shared Language

The two eyes should share conventions:

```text
kind = *_payload
truth_status = runtime_confirmed
limits
bounded output
entries/items
no unsupported interpretation
read-only first
```

Example symmetry:

```text
repo_listing_payload
  kind
  entries
  limits
  ignored
  truth_status

runtime_snapshot_payload
  kind
  packet_state
  budget
  trace_tail
  limits
  stop_reasons
  truth_status
```

## What RUNTIME Is Not

RUNTIME is not:

```text
chat history
memory database
semantic planner
tool executor
substrate caller
final decider
```

It should not absorb agency.

It should not become the body itself.

## What RUNTIME Is

RUNTIME is read-only evidence about internal condition.

It can expose:

```text
packet is alive/dead/dying
budget can/cannot pay
mode allows/denies classes of action
trace has/has not repeated
last validation accepted/rejected
cycle decided continue/stop
death cause is forming
```

But it should not decide what to do with that evidence.

Other operators consume it:

```text
☶ LOGIC
  validates against runtime evidence

☲ CYCLE
  decides continuation using runtime evidence

☳ CHOOSE
  later selects route using runtime evidence

△ MANIFEST
  reports result/death using runtime evidence
```

## First Possible Organ

Candidate:

```text
runtime_snapshot
```

Possible module:

```text
runtime/snapshot.lua
```

Input:

```text
packet
limits
```

Output:

```text
runtime_snapshot_payload
```

Candidate fields:

```text
packet_id
status
mode
operator
budget
trace_count
trace_tail
last_event
residue_summary
can_continue
stop_reasons
truth_status = runtime_confirmed
```

## Important Open Question

Should `runtime_snapshot` compute:

```text
can_continue
stop_reasons
```

or should that belong only to `☲ CYCLE`?

Maybe RUNTIME should report raw condition:

```text
budget_negative
status_dead
trace_count
last_event
```

and CYCLE should compute:

```text
can_continue
stop_reason
```

This boundary needs thought before code.

## Current Feeling

The first RUNTIME organ should be as stupid as possible:

```text
snapshot, not judgment
condition, not decision
internal evidence, not planning
```

Then CYCLE and LOGIC can consume it.

## One-Line Shape

```text
☴ OBSERVE sees what the world shows.
☱ RUNTIME sees what the packet can sustain.
```
