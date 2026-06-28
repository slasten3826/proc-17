# Unsupported Form Protocol

This is probably the central future mechanism of `procesis-body`.

## Problem

Substrates hallucinate.

The usual readings are too crude:

```text
hallucination = truth
hallucination = garbage
```

Both fail.

If the body believes hallucination, it manifests false runtime state.

If the body discards every hallucination, it may lose a signal about what the
process is trying to become.

## Working Definition

```text
hallucination = unsupported semantic form
```

Unsupported means:

```text
not confirmed by files
not confirmed by specs
not confirmed by tools
not confirmed by trace
not confirmed by runtime state
```

Semantic form means the emitted shape may still have structure.

Examples:

```text
nonexistent method
nonexistent module
nonexistent file
nonexistent previous action
nonexistent capability
nonexistent route through organs
```

## Core Move

The body should not ask only:

```text
is this true?
```

It should also ask:

```text
what missing structure would make this true?
should that structure exist?
```

This does not make hallucination factual.

It makes hallucination diagnostic.

## Organ Route

```text
☴ OBSERVE
  capture the unsupported emitted form

☶ LOGIC
  check against repo, specs, tools, trace, and runtime truth

☷ DISSOLVE
  remove false factual status

☵ ENCODE
  preserve the missing-shape residue

☳ CHOOSE
  reject, defer, or promote

☱ RUNTIME
  track recurrence, cost, pressure, and confirmation state

△ MANIFEST
  only output validated facts as facts
```

## Promotion

An unsupported form can become a build candidate only when it has pressure.

Rough rule:

```text
unsupported form
+ recurrence
+ architectural fit
+ useful route
+ payable cost
= candidate missing organ / spec / test
```

Without those conditions, it decays.

## Why This Matters

This is the difference between:

```text
LLM wrapper with filters
```

and:

```text
body that metabolizes substrate noise
```

The substrate emits pressure.
The body decides whether the pressure is garbage, exploration, or missing
architecture.

## Simple Example

Substrate writes:

```text
packet.promote_gap("runtime_memory")
```

But no such method exists.

Bad body:

```text
runs it and crashes
```

Over-filtered body:

```text
marks it hallucination and forgets it
```

Procesis body:

```text
LOGIC: method does not exist
DISSOLVE: claim removed
ENCODE: substrate wants a gap-promotion route
CHOOSE: decide whether gap promotion is real architecture
MANIFEST: create TODO/spec/test only if chosen
```

The fact was false.
The missing-shape signal may be real.

