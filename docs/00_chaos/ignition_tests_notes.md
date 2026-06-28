# Ignition Tests Notes

Raw live DeepSeek ignition notes.

Date:

```text
2026-06-28
```

Trace files:

```text
/tmp/proc-17-ignition-chaos.jsonl
/tmp/proc-17-ignition-table.jsonl
/tmp/proc-17-ignition-crystall.jsonl
/tmp/proc-17-ignition-eye.jsonl
```

Each trace has:

```text
15 JSONL events
birth
mode_enter
operator_enter
substrate_call
substrate_result
tool_call
tool_result
budget_spend
manifest
death
final
```

## Test Shape

The body ran DeepSeek through three modes:

```text
chaos
table
crystall
```

The substrate was asked to return semantic proposals only.

The body correctly stored the model output as:

```text
truth_status = semantic_proposal
```

Mode permissions were trace-visible:

```text
chaos    code_writes=false layer=docs/00_chaos
table    code_writes=false layer=docs/01_table
crystall code_writes=false layer=docs/02_crystall
```

## Observation

DeepSeek produced confident but unsupported structure when it did not receive
real repo context.

Chaos mode output hallucinated `proc-17` as:

```text
modular data-processing pipeline
stream ingestion
middleware layers
source connectors
sink adapters
schema definitions
```

Table mode output hallucinated modules:

```text
Scheduler
Memory Manager
I/O Controller
Error Handler
Clock / Timer
Cache
Interrupt Vector
Process Table
Stack
Heap
```

Crystall mode output drifted into a semiconductor-like contract:

```text
Substrate_Current
Body_Node
Thermal_Constraint
Reliability_Flag
```

None of that is runtime-confirmed repo truth.

## Important Result

This is useful negative data.

The ignition did not show that DeepSeek can understand the repo from a task
prompt alone.

It showed the opposite:

```text
without repo-context tools,
DeepSeek fills missing runtime evidence with plausible structure
```

This confirms the body rule:

```text
substrate_result = semantic_proposal
not runtime truth
```

## Consequence

Before meaningful DeepSeek ignition tests, the body needs a real repo-context
tool loop.

Likely next need:

```text
body reads file tree
body reads selected files
body gives substrate actual context refs/payload
substrate proposal is checked against tool evidence
unsupported claims become gap residue
```

This suggests direction:

```text
real tool loop before deeper substrate tests
```

## Organogenesis Signal

Possible future organ pressure:

```text
repo_context_organ
```

Birth reason:

```text
substrate hallucinated repo shape when no real repo evidence was supplied
```

This organ should not be implemented yet.

It is only a raw candidate pressure from ignition data.

## Second Ignition: With Repo Context Eye

After `repo_context_organ` was implemented, DeepSeek was run again with
runtime-confirmed context from:

```text
README.md
docs/03_manifest/current_state.md
docs/02_crystall/blueprints/repo_context_eye.v0.md
cli/procesis-body.lua
organs/repo_context.lua
```

The task explicitly required:

```text
read runtime-confirmed repo context only
do not infer files or features outside provided context
```

Observed result:

```text
DeepSeek described only present capabilities:
  packet lifecycle
  fake and DeepSeek substrates
  --repo-context explicit file context
  trace file persistence
  mode policy
  fake tool loop
  current tests

DeepSeek named absent capabilities:
  no automatic repo file discovery
  no semantic repo ranking
  no shell tool
  no child packets
  no real file writes
```

This is materially better than the first ignition.

The first ignition invented unsupported repo architecture.
The second ignition stayed inside observed files.

## New Pressure From Second Ignition

The next missing organ appears as:

```text
repo_listing_eye
```

Birth reason:

```text
repo_context_organ can read files only when the file list is manually supplied
```

This is not enough for autonomous repo understanding.

But the solution must not be:

```text
give substrate shell
let substrate run find/ls
let substrate infer tree from memory
```

The solution should be:

```text
body-owned read-only repo listing
sandbox-checked paths
bounded output
runtime_confirmed file tree payload
then repo_context_organ reads selected files
```

The eye needs a retina before it needs a brain.
