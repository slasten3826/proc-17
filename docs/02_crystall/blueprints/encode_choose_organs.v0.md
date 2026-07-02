# Encode Choose Organs Blueprint v0

This blueprint defines the first executable `☵` and `☳` organs for
`proc-17-next`.

## Modules

```text
organs/encode.lua
organs/choose.lua
```

## ENCODE Contract

Required function:

```text
encode.run(packet, options) -> packet, payload | nil, error
```

Required behavior:

```text
read packet.chaos
do not encode packet.substrate as material
call logic.encode.encode
call packet.crystallize
record visible loss
write packet.calm.current
write packet.calm.work_units from encoded field items when possible
```

Source refs must point to:

```text
chaos:raw_prompt
chaos:fragment:<n>
```

Substrate may affect limits.

Substrate must not appear as source material.

## CHOOSE Contract

Required function:

```text
choose.run(packet, options) -> packet, payload | nil, error
```

Required behavior:

```text
read packet.calm.current.field
call logic.choose.choose
call body.record_choice
record selected alternatives
record killed alternatives
record choice loss
do not rewrite packet.calm.work_units
do not decide continuation
do not write packet.death
```

## Packet Event Extensions

The packet may support trace event types:

```text
choice
cycle
validation
```

`choice` is required for trace-visible `☳`.

## Tests

```text
unit_test: encode source refs are chaos refs
unit_test: encode ignores substrate secret as material
unit_test: encode writes calm and work_units
unit_test: choose records boundary choice and trace event
unit_test: choose preserves work_units
unit_test: choose payload has no continuation decision
unit_test: body cycle sees encode-created work_units
```

