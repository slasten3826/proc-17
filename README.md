# proc-17

proc-17 is the first procesis body.

It is not a chatbot.
It is a packet runtime around replaceable LLM substrate.

```text
procesis      = law / source orientation
proc-17       = body / runtime / organs
packet        = mortal task life
LLM substrate = replaceable semantic current
tools         = runtime contact
trace         = packet life line
residue       = what remains after packet death
```

## Current Shape

```text
packet.v0
topology.v0
fake substrate
DeepSeek substrate
fake tool facade
JSONL trace store
machine CLI
tests
```

## Machine CLI

Run fake loop:

```sh
lua cli/procesis-body.lua run --task "smoke" --fake --jsonl
```

Run fake loop and persist trace:

```sh
lua cli/procesis-body.lua run --task "smoke" --fake --jsonl --trace-file /tmp/proc-17-trace.jsonl
```

Run DeepSeek loop:

```sh
DEEPSEEK_API_KEY=... lua cli/procesis-body.lua run --task "Return one word: ok" --deepseek --jsonl
```

## Tests

```sh
lua tests/run.lua
```

Expected:

```text
test_json ok
test_topology ok
test_packet ok
test_substrates ok
test_tools ok
test_trace_store ok
test_cli ok
all tests ok
```

## Boundary

Substrate output is proposal, not runtime truth.

```text
substrate_result -> semantic_proposal
tool_result      -> runtime_confirmed
```

The body owns packet lifecycle, topology, budget, trace, manifestation, death,
and residue.

