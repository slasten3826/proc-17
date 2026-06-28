# Packet Lifecycle Notes

The task is a mortal packet.

The packet is not a message.
The packet is the temporary process body of a task.

## Birth

Packet birth starts when a task enters the body.

Candidate initial fields:

```text
id
parent_id
task
birth_time
budget
pressure
topology_state
trace
residue
death
```

## Life

Packet life is not free continuation.

Every continuation should cost something:

```text
tokens
time
tool calls
filesystem risk
uncertainty
context pressure
user attention
```

The runtime should not allow immortal loops.

## Organs During Life

Raw movement:

```text
▽ FLOW     task enters / process starts moving
☰ CONNECT  bind task to repo, tools, context, law
☷ DISSOLVE remove stale assumptions and false shape
☵ ENCODE   compress trace/residue
☳ CHOOSE   select next route
☴ OBSERVE  inspect world/substrate output
☲ CYCLE    continue while cost is payable
☶ LOGIC    validate claim/action/scope
☱ RUNTIME  sustain budget/conditions/death checks
△ MANIFEST output result / patch / death residue
```

## Death

Death is not failure by default.

A packet can die correctly when:

```text
task is complete
budget is exhausted
needed external input is absent
runtime truth blocks continuation
scope would become unsafe
trace has collapsed into repetition
```

Death should leave residue:

```text
what was attempted
what was learned
what killed continuation
what should not be repeated
what can be resumed later
```

## Child Packets

Future multi-agent work should create child packets, not prompt-only phantoms.

Child packets need:

```text
parent_id
task_slice
operator_role
budget
trace
manifest
residue
death
```

No child packet is immortal.

