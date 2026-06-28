# Substrate And Language Choice

## Substrate

The LLM is not the agent.

The LLM is replaceable substrate/current.

The body should be able to run through different providers:

```text
local model
DeepSeek
GLM
Claude
OpenAI
other OpenAI-compatible endpoint
```

Provider differences are real:

```text
latency
cost
context length
tool discipline
hallucination pressure
language style
reasoning depth
failure shape
```

But these differences should not redefine the body.

## Narrow Provider Contract

First rough shape:

```text
ask(messages, options) -> result | error
```

Later the result should probably include:

```text
text
reasoning_text?
tool_intents?
usage?
latency?
provider_metadata?
raw?
```

The body should not leak provider-specific fields into every organ.

## Language Choice

Current preference: Lua.

There is no strong reason to reject Lua for the first body.

Why Lua fits:

```text
small language
fast iteration
simple runtime model
tables fit packet-shaped data
coroutines can model continuation
easy to read and patch
already close to planGOD/Eva lineage
good as glue around tools/substrates
can later be embedded into C/Zig if needed
```

Lua also matches the intended first body:

```text
agent orchestration
packet routing
prompt assembly
trace writing
provider adapters
tool facades
small CLI
```

## Lua Risks

Lua is not magic.

Known risks:

```text
small standard library
JSON/HTTP/filesystem need dependency decisions
dynamic typing can hide contract bugs
large projects need discipline
packaging can become messy
parallelism is not native in the same way as Go/Rust
sandbox/security must be designed explicitly
```

These risks are manageable if the first body stays narrow.

## Alternatives

Python:

```text
excellent libraries
easy HTTP/JSON/tooling
but heavy, dependency-prone, and too easy to sprawl
```

TypeScript:

```text
good CLI ecosystem
good schemas
but Node/package churn is noisy for a body core
```

Go:

```text
strong CLI and concurrency
simple deployment
but less process-native and slower to shape experimentally
```

Zig/C:

```text
excellent for final packet body / runtime substrate
strong control over memory and death
but too slow for early organ discovery
```

## Current Decision

Start with Lua for the body.

Keep contracts narrow enough that later parts can move:

```text
Lua = nervous system / orchestration / first organs
C/Zig = possible later bones / hard runtime / packet VM
```

Do not rewrite into C/Zig before the organs are understood.

