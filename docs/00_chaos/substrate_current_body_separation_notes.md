# Substrate Current And Body Separation Notes

Proc-17 body must work without DeepSeek.

DeepSeek is not the body.

DeepSeek is not the packet.

DeepSeek is not the router.

DeepSeek is substrate current.

## Shape

```text
proc-17 body = organs + packet + router + trace + budget/loss
packet = thing that moves inside the body
substrate = current that can fill the packet with semantic material
```

In current architecture, DeepSeek sits behind `☴`.

```text
☴ observe -> substrate.ask -> DeepSeek
```

DeepSeek answers with semantic proposal.

The answer enters packet chaos:

```text
truth_status = semantic_proposal
```

It does not become runtime truth by itself.

## Important Split

Wrong:

```text
DeepSeek controls proc-17
```

Better:

```text
DeepSeek feeds proc-17
```

Body control belongs to:

```text
packet pressure
eyes
router
organs
budget/loss
trace
```

## Why This Matters

Normal agents often let the LLM decide almost everything.

Proc-17 should not.

The LLM can propose.

The body must route, encode, choose, validate, cycle, and manifest.

This means proc-17 can be tested in layers:

```text
body without substrate
body with fake substrate
body with DeepSeek
body with another substrate
```

If the body only works with DeepSeek, the architecture is wrong.

If replacing DeepSeek changes semantic style but not body mechanics, the
architecture is working.

## Current Placement

DeepSeek currently enters through:

```text
organs/observe.lua
```

The current call shape:

```text
observe.run(packet, substrate, options)
```

The substrate must satisfy:

```text
substrate.ask(call, options) -> response
```

This is why fake substrate and DeepSeek substrate can share the same body path.

## Invariant

Substrate produces semantic current.

Body produces process continuity.

Packet carries pressure.

Router chooses the next operator from packet pressure.

No substrate response is truth until the body makes it runtime-confirmed.

## Channel Boundary

Some substrate responses may contain structured candidates such as traces.

That does not give the substrate validation authority.

For trace work:

```text
substrate may fill trace_channel with candidates
substrate may fill semantic_channel with purpose
body fills runtime_channel with validation
```

The substrate should not be asked:

```text
is this trace valid?
```

The body should answer that locally.
