# Packet Spec

Packet is the mortal body of a task.

## Identity

```text
packet != prompt
packet != chat
packet != LLM response
packet != immortal memory
packet = bounded process body for one task life
```

## Fields

```text
id
birth_time
task
trace
state
context
budget
loss
decay
pressure
tool_events
manifestations
residue
death
```

## Budget

Budget is not decoration.

Costs include:

```text
file reads
searches
LLM calls
tool calls
test runs
context growth
failed loops
patch churn
invalid assumptions
```

## Residue

Residue is compact transferable learning after packet death.

```text
what worked
what failed
what killed the packet
what not to repeat
which files mattered
which assumptions were wrong
```

Residue is not packet identity.
