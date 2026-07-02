# Observe Organ Blueprint v0

This blueprint defines the first executable `☴ OBSERVE` organ for
`proc-17-next`.

## Required Module

```text
organs/observe.lua
```

## Required Function

```text
observe.run(packet, substrate, options) -> packet, payload | nil, error
```

## Required Behavior

```text
read packet.chaos.raw_prompt
build substrate call with operator "☴"
call substrate.ask
append response to packet.chaos through packet.append_chaos
return observe payload
```

## Truth Rule

Substrate output is always:

```text
semantic_proposal
```

unless a later organ validates it.

## Trace Rule

The organ must not write trace directly.

It must use:

```text
packet.append_chaos
```

## Tests

```text
unit_test: fake substrate response enters chaos fragment
unit_test: trace last event is chaos_append
unit_test: response truth_status remains semantic_proposal
unit_test: observe does not write calm
unit_test: missing substrate returns error
```

