# Body Spec

`procesis-body` is a process body for coding work.

## Law

The body boots from `procesis`.

```text
ProcessLang       -> topology
DissipativeMath   -> cost physics
Packet            -> mortal task body
Optics            -> domain projection
IngestionPolicy   -> no false full-read claims
```

The body must enforce these laws at runtime, not only mention them in prompts.

## Body Parts

```text
core/packet      mortal task body
core/router      ProcessLang adjacency enforcement
core/substrate   replaceable LLM adapters
core/tools       filesystem, shell, git, web
core/runtime     memory, residue, task history
core/policy      permissions and constraints

organs/flow      task enters
organs/connect   bind task to repo/context/tools
organs/dissolve  remove stale assumptions or bad continuation
organs/encode    compress context into packet state
organs/choose    select next action/tool/route
organs/observe   inspect files, outputs, web, runtime
organs/cycle     iterate edit/test/debug
organs/logic     validate constraints, tests, topology
organs/runtime   persist residue and useful state
organs/manifest  output, patch, commit, artifact, death boundary
```

## Core Rule

```text
LLM is not the agent.
LLM is replaceable current inside packet body.
```

The agent is the process body executing a mortal packet under procesis law.

## Minimal Coding Loop

```text
▽ FLOW      receive task
☰ CONNECT   attach repo, files, goal, tools
☴ OBSERVE   inspect current state
☵ ENCODE    compress relevant context
☳ CHOOSE    select next operation
☶ LOGIC     validate operation
△ MANIFEST  apply patch / run command / answer
☲ CYCLE     continue if task not complete
☱ RUNTIME   persist residue after death
```

Every transition must be valid under ProcessLang topology.

## Death

A task packet dies when:

```text
task manifests final answer
budget is exhausted
invalid topology blocks continuation
loop repeats without useful progress
user cancels
runtime can no longer sustain packet
```

Death may leave residue. Residue is not identity.

## First MVP

```text
CLI only
single repo
single packet per user task
one substrate adapter first
patch-based file edits
command/test execution
residue log
no web UI
no multi-agent
```
