# Pressure Topology Notes

Raw notes on the pressure physics of `proc-17`.

This document is prior to implementation.
It corrects the naive reading of operators as modules.

## Input And Output

```text
▽
  input pressure
  user gives task / current enters the body

△
  output pressure
  the same pressure exits after passing through the body
```

`▽` and `△` can be treated as outside-facing boundaries:

```text
▽ = input boundary
△ = output boundary
```

They are not ordinary internal organs.

They are where the machine touches the outside as task and result.

## Internal Pressure Transformers

The internal operators:

```text
☰ ☷ ☵ ☳ ☲ ☶
```

are pressure transformers.

They do not merely "handle tasks".

They change the nature of pressure.

First rough reading:

```text
☰ CONNECT
  pressure becomes relation / binding / context

☷ DISSOLVE
  pressure becomes subtraction / removal / weakening of false form

☵ ENCODE
  pressure becomes compressed trace / hierarchy / loss-bearing form

☳ CHOOSE
  pressure becomes selected direction under alternatives

☲ CYCLE
  pressure becomes continuation / recurrence / sustained turn

☶ LOGIC
  pressure becomes constraint / rule / validation boundary
```

These are not final definitions.

The important point:

```text
they transform pressure
```

## The Two Pressure Hubs

The two hubs:

```text
☴ OBSERVE
☱ RUNTIME
```

are not just "eyes".

They are pressure regions.

They show where transformed pressure gathers.

## Upper Hub: OBSERVE

```text
☴ OBSERVE
```

OBSERVE is the upper pressure hub.

It is connected to:

```text
▽ ☰ ☷ ☵ ☳ ☱
```

It is not connected to:

```text
☲ ☶
```

This matters.

OBSERVE sees the external/chaos-facing side:

```text
input pressure
relations
dissolutions
encodings
choices
runtime reflection
```

But it does not directly see:

```text
cycle continuation
logic constraint
```

Those come through other routes.

OBSERVE is not the place where the machine decides continuation or validation.

## Lower Hub: RUNTIME

```text
☱ RUNTIME
```

RUNTIME is the lower pressure hub.

It is connected to:

```text
☵ ☳ ☴ ☲ ☶ △
```

It is not connected to:

```text
☰ ☷
```

This matters.

RUNTIME sees the manifest/internal sustain side:

```text
encoded state
chosen direction
observe reflection
cycle continuation pressure
logic constraint pressure
output pressure
```

But it does not directly see:

```text
raw connection
raw dissolution
```

Those have already been transformed before reaching runtime.

## CYCLE And LOGIC Shape Runtime Seeing

RUNTIME does not merely look downward.

Its seeing is shaped by:

```text
☲ CYCLE
☶ LOGIC
```

`☲ CYCLE` keeps the runtime eye open across turns:

```text
what changed?
what repeated?
what can continue?
what pressure persists?
```

`☶ LOGIC` constrains the runtime eye:

```text
what is valid?
what is rejected?
what boundary holds?
what must not pass?
```

So RUNTIME should not be a passive state dump.

It is a lower pressure reading shaped by continuation and constraint.

## Will Is Not Centralized

The body's "will" should not live in one module.

It should not be:

```text
the LLM
the runtime
the planner
the CLI
the cycle module
```

Will should emerge from topology:

```text
input pressure
operator transformations
upper pressure hub
lower pressure hub
logic constraints
cycle continuation
manifest boundary
```

This is important.

If one module is allowed to "own will", the body collapses back into a normal
agent scaffold.

## Runtime Snapshot Correction

Naive idea:

```text
runtime_snapshot = state dump
```

Better idea:

```text
runtime_snapshot = lower pressure reading
```

It should still be read-only.

But it should expose pressure-relevant conditions:

```text
encoded state pressure
choice pressure
cycle pressure
logic pressure
manifest pressure
budget pressure
death pressure
trace pressure
```

It should not decide.

It should not plan.

It should not own will.

It should make lower pressure visible.

## One-Line Shape

```text
▽ enters as pressure.
☰☷☵☳☲☶ transform pressure.
☴ and ☱ are pressure hubs.
△ exits as manifested pressure.
Will emerges from the topology, not from a central controller.
```
