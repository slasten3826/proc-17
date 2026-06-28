# ProcessLang Lua Source Notes

Source inspected:

```text
/home/slasten/docs/stack/stack-core/ProcessLang/lua
```

Files:

```text
canon.lua
processlang.lua
FLOW.lua
CONNECT.lua
DISSOLVE.lua
ENCODE.lua
CHOOSE.lua
OBSERVE.lua
CYCLE.lua
LOGIC.lua
RUNTIME.lua
MANIFEST.lua
```

## Reading

This Lua source is useful.

It should not be copied blindly as `procesis-body`.

It is closer to:

```text
ProcessLang Lua primitive library
```

than to:

```text
mortal packet runtime body
```

## What To Use

Use the operator files as early organ utility vocabulary:

```text
FLOW      pipe, chain, map, filter
CONNECT   compose, zip, merge, bridge
DISSOLVE  split, flatten, diff
ENCODE    accumulate, group, compress, pack
CHOOSE    branch, first, best, gate
OBSERVE   watch, assert, measure, snapshot
CYCLE     times, until_stable, converge
LOGIC     validate, rule, infer
RUNTIME   context, safe, machine
MANIFEST  render, emit, seal
```

These can help the first Lua body stay small.

## What Not To Use As-Is

Do not treat it as final topology.

Reasons:

```text
old order is present
packet protocol is absent
budget/death are absent
unsupported form protocol is absent
child packet protocol is absent
runtime truth boundary is not strict enough
```

`RUNTIME.lua` still looks like generic state/history.
For `procesis-body`, runtime must mean cost, continuation, residue, decoding
conditions, and death checks.

## Noted Bug / Layout Risk

`processlang.lua` contains:

```lua
processlang.canon = dofile(base .. "../canon.lua")
```

But in the inspected directory `canon.lua` is in the same directory as
`processlang.lua`.

So this file is either from an older layout or currently has a path bug.

For `procesis-body`, imports should not depend on this layout.

## Decision

Use this source as:

```text
input material for core/topology.lua
input material for organs/*.lua helpers
historical ProcessLang Lua manifestation
```

Do not use it as:

```text
packet protocol
body runtime
final canon
```

The first implementation should probably split:

```text
core/topology.lua
  current procesis topology and trace validation

core/packet.lua
  packet.v0 protocol

organs/*.lua
  small operator helpers, partly borrowed from old ProcessLang Lua
```

