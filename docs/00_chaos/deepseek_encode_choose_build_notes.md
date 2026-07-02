# DeepSeek Encode Choose Build Notes

Raw notes from asking old `procesis-body` DeepSeek substrate in build mode how
to implement `☵ ENCODE` and `☳ CHOOSE` for `proc-17-next`.

Mode:

```text
work_mode = build
```

## Useful Signal

DeepSeek correctly reinforced:

```text
organs/encode.lua
  bind existing logic.encode to new packet body
  write CALM
  make loss visible
  add tests for simple encode, empty input, truncation/loss, repeated encode

organs/choose.lua
  bind existing logic.choose to runtime/body record_choice
  record selected and killed alternatives
  do not decide continuation
  do not rewrite progress

logic/cycle.lua
  remains unchanged
```

It also correctly stated:

```text
CLI is not the body
core/packet.lua should not be replaced
packet/ folder should not be invented
```

## Bad Or Misaligned Signal

DeepSeek still made important structural mistakes.

### Wrong ENCODE Input

It proposed:

```text
organs/encode reads packet.substrate
```

Correction:

```text
☵ reads packet.chaos
substrate is runtime condition, not raw task material
```

`packet.chaos.raw_prompt` and `packet.chaos.fragments` are the source pressure.

### Wrong Trace Mutation

It proposed manual writes:

```text
table.insert(packet.trace, ...)
```

Correction:

```text
trace must be written through packet API
```

For encode:

```text
packet.crystallize(...)
```

For choose, either:

```text
body.record_choice(...)
```

or a packet/body helper that appends a valid event.

### Wrong CHOOSE Death Model

It proposed killed alternatives go into:

```text
packet.death
```

Correction:

```text
packet.death is packet death
killed alternatives are choice loss
```

Killed alternatives belong in:

```text
packet.boundary.choices[].killed_alternatives
```

They may later produce residue, but they are not packet death.

### Wrong Tension Shape

It proposed:

```text
packet.tension = (packet.tension or 0) + #killed
```

Correction:

```text
packet.tension is a table
```

Tension can record collapse pressure, but must preserve structured fields.

## Current Interpretation

The build-mode response gives implementation pressure, not implementation law.

Use it like this:

```text
organs/encode.lua
  source: packet.chaos
  pure logic: logic.encode
  write path: packet.crystallize
  output: packet.calm.current / packet.calm.work_units if units emerge
  loss: required

organs/choose.lua
  source: packet.calm.current or packet.calm.work_units
  pure logic: logic.choose
  write path: body.record_choice
  output: packet.boundary.choices
  do not touch progress
  do not touch packet.death
  do not decide continuation
```

## Implementation Boundary

First implementation should not try to make `☵` fully intelligent.

It should make the correct body connection:

```text
CHAOS -> logic.encode -> packet.crystallize -> CALM
CALM alternatives -> logic.choose -> body.record_choice -> BOUNDARY
```

Once this path is real, later runs can improve what gets crystallized.

