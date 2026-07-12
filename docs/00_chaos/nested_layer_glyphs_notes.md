# Nested Layer Glyphs Notes

Status:

```text
chaos
new control pressure
```

## Trigger

proc-17 currently has two work modes:

```text
plan
build
```

The ORK loop exposed another axis:

```text
build thing
run thing
fix thing
repeat
```

But these should not become another set of names.

They are already the same four abstraction glyphs:

```text
⋯ ⊞ ◈ ▲
```

## Core Insight

Do not create new names for nested abstraction levels.

Use the glyphs again.

Context disambiguates.

The same glyphs can describe:

```text
project layer
document layer
task layer
packet layer
work gesture
```

This is not ambiguity if the current context is explicit.

It is recursion.

## Working Matrix

```text
plan ⋯  = first idea form
plan ⊞  = structure check without code
plan ◈  = blueprint / contract / spec
plan ▲  = plan exported as external form

build ⋯ = first working artifact
build ⊞ = run / observe / validate the artifact
build ◈ = fix concrete bad noise
build ▲ = repeat until manifest or death
```

## Why Not New Names

Names like:

```text
phase
stage
workflow
operation mode
```

would create extra conceptual bodies.

proc-17 should not need them.

The body already has:

```text
mode  = why the body works
layer = at what abstraction depth the work currently happens
```

So the minimal pair is:

```text
mode:  plan | build
layer: ⋯ | ⊞ | ◈ | ▲
```

## Meaning By Context

`⋯` does not mean one fixed English word.

It means the chaos layer of the current context.

Examples:

```text
project ⋯ = raw project idea
document ⋯ = raw notes
packet ⋯ = raw input pressure
build ⋯ = first rough artifact
```

Same for the other glyphs:

```text
⊞ = addressable structure in this context
◈ = stabilized contract in this context
▲ = exported form in this context
```

## Rule

When proc-17 needs nested abstraction levels:

```text
reuse ⋯⊞◈▲
do not rename them
write the context explicitly
let the glyph carry the operation
```

## Immediate Use

The next code-level pressure is probably:

```text
packet.runtime.mode
packet.runtime.layer
```

But not yet.

First preserve the idea in chaos and table.
