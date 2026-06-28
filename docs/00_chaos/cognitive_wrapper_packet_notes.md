# Cognitive Wrapper And Packet Protocol Notes

This note captures the concrete working model of `procesis-body`.

## Frame

The body is a cognitive wrapper around replaceable LLM substrate.

```text
procesis-body = cognitive wrapper / organs / runtime
packet        = what moves inside the wrapper
LLM           = called by wrapper, not owner of wrapper
```

This differs from common coding agents.

## Common Agent Shapes

Weak cognitive wrapper:

```text
prompt + tools + model decides most things
```

The model receives a prompt and largely decides what to do.

Medium cognitive wrapper:

```text
model + wrapper cooperate
```

Codex and Claude Code are closer to this: the wrapper controls tools,
permissions, context, and some planning, but the model still carries much of the
agency.

Procesis body target:

```text
wrapper owns most process control
LLM supplies semantic current
packet protocol carries state between organs
```

The LLM should not decide the whole process from a prompt.

## Packet Role

The packet is the thing that moves through the cognitive wrapper.

It carries:

```text
task
operator position
runtime truth
semantic proposals
tool evidence
substrate outputs
unsupported forms
budget
death state
residue
```

The packet is how organs communicate without turning the LLM into the agent.

## LLM Call Modes

The wrapper may call the substrate in different modes.

Candidate modes:

```text
glyph
natural
mixed
```

`glyph` mode:

```text
compact ProcessLang / operator trace / machine-facing compression
```

`natural` mode:

```text
human language explanation, code reasoning, user-facing text, broad semantic work
```

`mixed` mode:

```text
glyph skeleton + natural payload
```

The mode belongs to the packet event, not to the model identity.

## No Agent Multiplication

Do not create many agents.

Create phantoms only when needed.

Phantom:

```text
temporary manifestation
narrow role
called by wrapper
bounded by packet budget
returns result into parent packet
dies
```

A phantom is not an independent immortal agent.

## Control Ownership

The body should own:

```text
when to call substrate
which mode to call it in
what context to expose
what operator route is active
what counts as runtime truth
what gets manifested
when packet dies
```

The substrate may supply:

```text
semantic proposal
code proposal
interpretation
compression
critique
phantom role output
```

Every substrate output remains proposal until the body validates or rejects it.

