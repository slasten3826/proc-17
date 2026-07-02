# Encode Choose Organs Yellowprint v0

Table shape for first `☵` and `☳` organs in `proc-17-next`.

Sources:

```text
docs/00_chaos/encode_substrate_chaos_boundary_notes.md
docs/00_chaos/deepseek_encode_choose_plan_notes.md
docs/00_chaos/deepseek_encode_choose_build_notes.md
```

## Scope

Implement organs, not new packet core:

```text
organs/encode.lua
organs/choose.lua
```

Existing pure logic stays:

```text
logic/encode.lua
logic/choose.lua
```

## ☵ ENCODE Organ

Role:

```text
CHAOS -> logic.encode -> packet.crystallize -> CALM
```

Reads:

```text
packet.chaos.raw_prompt
packet.chaos.fragments
packet.substrate only as constraints
```

Must not:

```text
encode substrate as source material
hide loss
write calm without crystallization
```

Writes:

```text
packet.boundary.crystallizations
packet.boundary.loss_records
packet.calm.current
packet.calm.structures
packet.calm.work_units when units emerge from the encoded field
packet.trace through packet.crystallize
```

## ☳ CHOOSE Organ

Role:

```text
CALM alternatives -> logic.choose -> body.record_choice -> BOUNDARY
```

Reads:

```text
packet.calm.current.field
packet.calm.work_units only as fallback field material
```

Writes:

```text
packet.boundary.choices
packet.trace choice event
packet.tension.last_choice_pressure
```

Must not:

```text
rewrite packet.calm.work_units
decide continuation
write packet.death
write manifest
```

## First Tests

```text
encode reads chaos raw prompt and ignores substrate host secret
encode writes calm through packet.crystallize with visible loss
encode creates work_units from encoded field items
choose records selected and killed alternatives
choose does not rewrite progress/work_units
choose does not decide continuation
body cycle can use encode-produced work_units
```

