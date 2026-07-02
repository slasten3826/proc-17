# Encode Substrate Chaos Boundary Notes

Raw clarification after two DeepSeek runs suggested that `☵ ENCODE` should read
`packet.substrate`.

## Observation

DeepSeek twice pulled `☵` toward:

```text
packet.substrate
```

This is not random.

It is the pressure of the old topology and ordinary agent architecture.

In the old body, task, context, tool output, runtime environment, and model
input were much closer together.

So the model read `substrate` as:

```text
everything available to work with
```

In that architecture, saying "ENCODE reads substrate" is understandable.

It is not correct for the new packet architecture.

## New Packet Boundary

In `proc-17-next`:

```text
packet.substrate
  conditions of life
  budget
  clock
  sandbox
  host
  tool/io limits

packet.chaos
  source material
  dirty prompt
  substrate responses as semantic pressure
  unresolved fragments
  candidate material before form

packet.calm
  crystallized runtime-usable form
```

Therefore:

```text
☵ reads CHAOS
☵ may be constrained by SUBSTRATE
☵ writes CALM
```

Short formula:

```text
☵ reads CHAOS under SUBSTRATE constraints
```

Wrong formula:

```text
☵ reads SUBSTRATE as source material
```

## Why It Matters

If `☵` treats substrate as source material, CALM becomes polluted.

It may encode:

```text
budget
sandbox details
host details
tool limits
runtime metadata
```

as if they were the task itself.

That collapses the distinction between:

```text
what the packet is trying to become
```

and:

```text
what conditions allow the packet to live
```

The new packet architecture must preserve this distinction.

## Correct Example

Input:

```text
packet.chaos.raw_prompt = "build notes app"
packet.substrate.budget.file_writes = 8
packet.substrate.sandbox.root = "sandbox/"
```

Correct encode:

```text
source material:
  packet.chaos.raw_prompt

constraints:
  file_writes budget
  sandbox root

calm result:
  work units for notes app
```

Incorrect encode:

```text
calm result includes sandbox root as if it were a user requirement
calm result includes budget as if it were application domain
```

## Test Pressure

When `organs/encode.lua` is implemented, add a test:

```text
packet.chaos.raw_prompt = "build notes app"
packet.substrate.host.secret = "do_not_encode"

organs.encode(packet)

assert CALM source refs point to chaos
assert CALM does not include "do_not_encode"
```

Substrate may affect limits/loss.

Substrate must not become task material.

## Current Rule

```text
CHAOS = material
SUBSTRATE = conditions
CALM = crystallized form
BOUNDARY = transition/loss record
TENSION = pressure between material and form
```

