# Body Modes Notes

Raw idea: `procesis-body` should not use only the common agent split:

```text
plan mode
build mode
```

The body should probably have four process modes matching the four abstraction
layers:

```text
chaos mode
table mode
crystall mode
manifest mode
```

This is not only UI state.

It is process permission.

## Chaos Mode

Purpose:

```text
free discussion
raw thought
weird associations
origin pressure
unresolved forms
```

Behavior:

```text
high hallucination tolerance
low enforcement
no code writes
no final claims
no crystall authority
```

Chaos mode is where the body can "talk", wander, collide meanings, and let
unsupported forms appear without killing them too early.

Unsupported does not mean true.
But chaos mode should not cut every unsupported form immediately.

## Table Mode

Purpose:

```text
first structure from chaos
maps
relations
inventories
candidate routes
visible options
```

Behavior:

```text
hallucinations start being tagged
unsupported forms become marked unknowns
relations are made explicit
still no implementation code
```

Table mode turns raw pressure into addressable structure.

## Crystall Mode

Purpose:

```text
blueprint
contract
spec
test obligation
implementation boundary
```

Behavior:

```text
strict hallucination cutting
runtime truth matters
claims must become testable or be marked untestable
no direct code implementation yet
```

Crystall mode is where the body says:

```text
this is stable enough to constrain implementation
```

## Manifest Mode

Purpose:

```text
code
tests
commands
artifacts
runtime-visible output
```

Behavior:

```text
code writes allowed
must follow crystall
tests required
trace/residue updated
runtime truth overrides semantic proposal
```

Main law:

```text
code writes only in manifest mode
```

## Possible Packet Field

Later this might become part of packet protocol:

```text
packet.mode = chaos | table | crystall | manifest
```

Mode would control allowed actions:

```text
chaos
  can write docs/00_chaos
  cannot write implementation

table
  can write docs/01_table
  cannot write implementation

crystall
  can write docs/02_crystall
  can define test obligations
  cannot implement runtime code directly

manifest
  can write code/tests/docs/03_manifest
  must link to crystall contract
```

## Why This Matters

This prevents the common agent failure:

```text
discussion pressure -> premature code
```

It also preserves the procesis layer discipline inside the body itself.

The body does not just store layers.
The body operates in layers.

