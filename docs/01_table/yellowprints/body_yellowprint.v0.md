# Body Yellowprint v0

Yellowprint means navigable architecture map.
It is not yet a final contract.

## Layer Split

```text
procesis-body/
  core/        invariant runtime mechanisms
  organs/      ProcessLang operator organs
  runtime/     durable state, residue, traces
  tools/       host interaction
  substrates/  LLM/provider adapters
  cli/         first executable entrypoint
  tests/       body tests
  docs/        layered design trace
```

## Four Documentation Layers

```text
00_chaos
  raw discussion
  topology corrections
  unresolved memory/runtime ideas
  planGOD readings

01_table/yellowprints
  maps
  candidate module layout
  migration notes from planGOD
  inventories of decisions

02_crystall/blueprints
  stable contracts
  topology law
  packet lifecycle
  substrate contract
  tool contract

03_manifest
  current commands
  current implemented modules
  how to run
  what is real now
```

## Two-Center Runtime Map

```text
             chaos side                  manifest side

             OBSERVE                     RUNTIME
               |                            |
          reads raw state              sustains executable state
          detects signal               tracks cost/conditions
          does not decide              does not hallucinate memory
```

Important:

```text
OBSERVE reads.
CHOOSE chooses.
LOGIC validates.
RUNTIME sustains.
MANIFEST closes.
```

Old Eva let OBSERVE become too central. The body should not repeat that.

## Packet Shape

The task packet is a mortal process body.

Candidate packet sections:

```text
identity
task
trace
topology
context
budget
pressure
loss
tool_events
substrate_events
manifests
residue
death
```

## Cognitive Wrapper Ownership

The body should own most process control.

```text
body decides when to call substrate
body decides call mode: glyph / natural / mixed
body validates substrate output
body owns tool execution
body owns manifest and death
```

The substrate supplies semantic current.

It does not own the packet.

## Agent Multiplication Rule

Do not multiply agents.

Use phantoms:

```text
temporary
role-bound
budgeted
parent-linked
dead after return
```

Phantoms return into packet trace.
They do not become separate immortal agents.

## Runtime As Decoding Capacity

Do not implement memory as "remember everything".

Better first model:

```text
trace      = what happened
residue    = compressed consequence
runtime    = conditions for decoding and reuse
manifest   = current visible output
```

Memory-like behavior emerges when the body can quickly decode old residue into
useful current constraints.

## Hallucination Handling Map

Hallucination is not accepted as truth.

It is treated as unsupported semantic pressure:

```text
substrate emits nonexistent API / method / route
LOGIC checks current files and specs
RUNTIME records the failed contact
DISSOLVE removes the false factual claim
ENCODE preserves the missing-shape residue
CHOOSE either rejects it or promotes it into a build candidate
```

Useful distinction:

```text
false fact        -> dissolve
repeated gap form -> possible missing organ
```

This is how "hallucination as source of truth" should be read:

```text
not factual authority
but diagnostic source
```

## planGOD Carry-Over

Keep:

- provider as replaceable Layer 0 substrate;
- packet flow through organs;
- prompt assembly as explicit boundary;
- run telemetry;
- no hidden steering rule;
- semantic anchors and glyph residues as memory candidates;
- parallel/chain/grok as pressure modes;
- operator projections instead of generic personas.

Do not keep unchanged:

- OBSERVE as single central brain;
- phantom as just a prompt role;
- RUNTIME as simple long-term memory;
- prose-first internal payload;
- all optics loaded as default context.

## ProcessLang Lua Carry-Over

The old stack Lua source can be used as operator helper material:

```text
/home/slasten/docs/stack/stack-core/ProcessLang/lua
```

Use it for:

```text
small organ utilities
operator vocabulary
Lua implementation style
```

Do not use it directly for:

```text
packet protocol
runtime truth
budget/death
unsupported form handling
final topology
```

`core/topology.lua` should be generated or written from current procesis canon,
not from stale historical order.

## First Lua Body Map

Current candidate module split:

```text
core/packet.lua
  packet protocol: birth, trace, budget, unsupported forms, death, residue

core/topology.lua
  ProcessLang operator order, adjacency, route checks

core/unsupported_form.lua
  unsupported semantic form capture, dissolve, encode, promote/decay

runtime/budget.lua
  spend, pressure, death conditions

substrates/fake.lua
  deterministic substrate for tests

tools/fake.lua
  deterministic tool facade for tests

cli/procesis-body.lua
  machine-facing single-task loop
```

Real providers should wait until fake substrate tests pass.

## CLI Direction

First CLI is not a user interface.

It is a machine interface for:

```text
Codex
tests
future wrappers
packet trace inspection
```

Preferred first output:

```text
JSONL event stream
```

Read:

```text
docs/01_table/yellowprints/machine_cli_yellowprint.v0.md
docs/02_crystall/blueprints/machine_cli.v0.md
```

## Test Surface

First tests should cover:

```text
packet birth
budget spend
packet death
valid topology route
invalid topology route
unsupported form capture
unsupported form dissolve
unsupported form promotion
fake substrate loop
```

## Packet Protocol Link

Packet protocol is the first body protocol to crystallize.

Read:

```text
docs/01_table/yellowprints/packet_protocol_yellowprint.v0.md
docs/02_crystall/blueprints/packet_protocol.v0.md
```
