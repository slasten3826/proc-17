# Observe Organ Yellowprint v0

Table shape for first `☴ OBSERVE` organ in `proc-17-next`.

## Role

`☴` reads CHAOS and may ask a substrate current for semantic pressure.

It does not validate truth.

It does not encode.

It does not choose.

It appends observed/substrate material back into `packet.chaos`.

## Module

```text
organs/observe.lua
```

## Reads

```text
packet.chaos.raw_prompt
packet.chaos.fragments
packet.substrate only for call options/conditions
```

## Calls

```text
substrate.ask(call, options)
```

Call shape:

```text
mode
operator = "☴"
prompt_payload
system_prompt
expected_shape = "semantic_proposal"
work_mode
```

## Writes

```text
packet.chaos.fragments
packet.trace via packet.append_chaos
```

The substrate response remains:

```text
truth_status = semantic_proposal
```

## Must Not

```text
promote substrate text to runtime truth
write CALM
call ENCODE
call CHOOSE
decide continuation
manifest output
```

