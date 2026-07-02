# DeepSeek Encode Choose Plan Notes

Raw notes from asking the old `procesis-body` DeepSeek substrate how to build
`☵ ENCODE` and `☳ CHOOSE` for `proc-17-next`.

Mode:

```text
work_mode = plan
```

## Prompt Context

DeepSeek was told:

```text
new packet core has substrate, chaos, boundary, calm, tension, trace, residue, death, manifest
packet.new births dirty CHAOS from prompt
packet.crystallize requires loss and writes CALM + boundary crystallization/loss records
runtime/body.lua computes progress from packet.calm.work_units
logic/cycle.lua remains as-is
☵ should crystallize CHAOS into CALM with visible loss
☳ should collapse alternatives and record killed alternatives
☳ must not decide continuation
```

## Useful Signal

DeepSeek's useful proposal:

```text
☵ ENCODE
  reads packet.chaos
  writes packet.calm
  writes packet.boundary.loss_records
  failed/unsupported fragments should leave residue/boundary records
  loss must be visible

☳ CHOOSE
  collapses alternatives
  records killed alternatives
  does not decide continuation

runtime/body.lua
  after encode reads packet.calm.work_units as progress
  after choose may read alternatives, but alternatives are not progress
  cycle remains the continuation gate
```

## Bad Or Misaligned Signal

DeepSeek also proposed:

```text
packet/encode.lua
packet/choose.lua
packet/crystallize.lua
```

This conflicts with the current body shape.

Current preferred direction:

```text
core/packet.lua remains packet core
logic/encode.lua remains pure logic
logic/choose.lua remains pure logic
organs/encode.lua binds logic.encode to packet.crystallize
organs/choose.lua binds logic.choose to body.record_choice
```

DeepSeek also put the initial prompt under `packet.substrate`.

Correction:

```text
prompt belongs to packet.chaos.raw_prompt
substrate is runtime body condition
```

DeepSeek suggested writing killed alternatives into `trace.killed`.

Correction:

```text
trace is append-only event list
killed alternatives belong in packet.boundary.choices payload
trace event may reference that payload
```

DeepSeek had a contradiction around `☳`:

```text
it says CHOOSE should not modify work_units
but also says CHOOSE mutates packet.calm
```

Current preferred boundary:

```text
☳ may mark selected branch
☳ records selected/killed alternatives
☳ must not decide continuation
☳ should not rewrite progress/work_units in v0
```

## Working Interpretation

The plan-mode response confirms the broad architecture:

```text
☵ = crystallization adapter around logic.encode + packet.crystallize
☳ = collapse adapter around logic.choose + body.record_choice
☲ = unchanged continuation gate
```

But module placement and packet ownership must follow `proc-17-next`, not the
old body or DeepSeek's invented `packet/` folder.

