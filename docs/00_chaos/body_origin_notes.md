# Body Origin Notes

This file is raw working reasoning for `procesis-body`.

It is not the public contract.
It is the place where unresolved body-shape ideas are preserved before they are
compiled into yellowprints or blueprints.

## Current Frame

```text
procesis      = soul / law
procesis-body = body / runtime / organs
LLM substrate = spark / current
task          = mortal packet life
```

The immediate target is a substrate-neutral coding agent. It should be able to
use different LLM providers while keeping the same process body.

## Eva Reading

The `eva/planGOD` prototype is valuable, but it was built on an older topology.

Old Eva topology:

```text
OBSERVE = central cognitive hub
```

New body topology must not preserve that shape as-is.

The newer packet reading has two centers:

```text
OBSERVE -> reads toward chaos
RUNTIME -> reads toward manifest
```

In the Zig packet prototype this already appeared as:

```text
OBSERVE_A = OBSERVE
OBSERVE_B = RUNTIME
```

So `OBSERVE_B` should not remain named as a second observation. It is the runtime
side of the double center.

## Memory Question

Old Eva used `RUNTIME` largely as memory:

```text
E_momentum
E_edges
residue
```

That was useful, but probably not exact.

Human "memory" is not simply stored data. It is closer to fast decoding of what
has already been formed. The apparent memory is a runtime ability to reopen a
compressed trace, not a warehouse of facts.

Working direction:

```text
memory != archive
memory != chat history
memory ~= decoding capacity over prior residue
```

For `procesis-body`, this means runtime should not be treated as a generic
memory database. Runtime should hold the conditions that make prior traces
readable, usable, and costly to sustain.

## Hallucination As Request Signal

Eva exposed a useful failure mode.

When a substrate invented methods, APIs, or code paths that did not exist in the
specs, the old reading was:

```text
hallucination = false output
```

That is too flat.

A better body reading:

```text
hallucination = unsupported semantic form
```

The content is not trusted as fact. But the shape may still be useful.

If a substrate repeatedly invents the same missing method, missing organ, or
missing route, the body can read that as a request signal:

```text
this does not exist
but the current process is trying to route through it
there may be a missing body part here
```

So the body should not simply believe hallucinations, and should not simply
discard them. It should:

```text
capture the unsupported form
prove what is unsupported
strip the false claim
preserve the missing-shape residue
decide whether it deserves a spec, todo, or implementation
```

This turns hallucination into diagnostic pressure, not truth.

## Documentation Direction

Use four layers:

```text
00_chaos     our reasoning and unresolved discussion
01_table     yellowprints
02_crystall  blueprints
03_manifest  docs for what exists
```

`chaos` can contain Russian, rough wording, contradictions, and live discussion.

`table` and `crystall` should become machine-facing and more stable.

`manifest` should describe the real implemented body, not wishes.
