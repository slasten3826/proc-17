# CONNECT Operator Notes

Raw notes for `☰ CONNECT`.

This is not a table or crystal yet.
It records the current understanding after comparing `proc-17` with older
packet bodies.

## First Correction

`☰ CONNECT` is not just "link two objects".

That reading is too flat.

The stronger invariant:

```text
CONNECT gives pressure a channel
```

or:

```text
CONNECT maintains relation strongly enough that later form is not arbitrary
```

## First Invariant

Before CONNECT:

```text
things may be near each other
things may be mentioned together
things may be in the same prompt or trace
```

After CONNECT:

```text
there is a relation the body can carry forward
there is source binding
there is provenance pressure
there is a channel through which later operators can move material
```

If no relation becomes package-visible, no real CONNECT happened.

## Difference From OBSERVE

`☴ OBSERVE` sees material.

`☰ CONNECT` binds material.

OBSERVE can say:

```text
this file exists
this line was emitted
this event is in trace
this task was given
```

CONNECT should say:

```text
this file is related to this task
this response line came from this substrate call
this candidate belongs to this observation
this unsupported shape recurs with this pressure
```

Short form:

```text
☴ sees
☰ binds
```

## Difference From ENCODE

`☵ ENCODE` makes material portable.

`☰ CONNECT` keeps material related to its source.

ENCODE without CONNECT pressure can create a clean field that has lost its
origin.

That is dangerous:

```text
formed field looks real
source relation is gone
semantic proposal starts pretending to be runtime truth
```

So the first `proc-17` ENCODE must carry CONNECT residue:

```text
source_kind
source_ref
source_truth_status
relation_to_task
relation_to_observation
```

This does not mean CONNECT must be implemented as a separate CLI organ first.

It means ENCODE v0 must not erase source binding.

## Difference From LOGIC

`☶ LOGIC` checks whether a formed claim passes a rule boundary.

`☰ CONNECT` does not validate.

It relates.

Example:

```text
DeepSeek says:
  logic/choose.lua is relevant to CHOOSE

CONNECT pressure:
  task -> substrate_call -> response_line -> repo_path candidate

LOGIC pressure:
  does repo_path exist?
```

Relation can be runtime-confirmed while explanation remains semantic:

```text
the response line came from this substrate call
  runtime_confirmed

the model's reason for relevance
  semantic_proposal
```

## Packet-Slop Trace

In older neural packet work, CONNECT appeared less as a single operation and
more as field physics.

In L1:

```text
trace links previous pass to next pass
position changes meaning
core / trace / phase are not independent
carry-state moves pressure through ticks
```

In Eva encode core:

```text
connect_strength is maintained every tick
chaos_flux depends on connect_strength
raw_mass enters the process only through sustained connection
if connect_strength collapses, the encode process dies
```

This should not be copied literally into `proc-17`.

But it clarifies the invariant:

```text
CONNECT is sustained relation, not decorative reference
```

## Proc-17 Form

`proc-17` currently has no real neural field.

Its current medium is:

```text
packet trace
observations
substrate calls/results
repo listing/context
runtime pressure snapshots
user task
```

Therefore first CONNECT manifestation should probably be lightweight:

```text
relation records
source references
provenance links
recurrence keys
task-to-item binding
observation-to-field binding
```

Possible package-visible shape:

```text
connections = {
  {
    from,
    to,
    relation_kind,
    source_truth_status,
    relation_truth_status,
    pressure
  }
}
```

This may live inside ENCODE output at first.

It does not require a separate `logic/connect.lua` yet.

## What CONNECT Must Not Become

CONNECT must not become:

```text
LLM association dump
tag cloud
semantic similarity blob
unverified dependency graph
hidden planner context
```

A relation may be semantic.

But its status must remain visible.

## Open Questions

```text
does CONNECT deserve its own module in proc-17 v0?
or should it first appear as source binding inside ENCODE?
what is the smallest useful connection record?
how does CONNECT decay when not reinforced?
can repeated unsupported forms create weak CONNECT pressure?
how does CONNECT differ from repo_context observation?
how should CONNECT expose relation without pretending to validate it?
```

No table yet.
No crystal yet.
No code yet.
