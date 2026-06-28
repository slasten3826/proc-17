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

## Third Ignition: With Repo Listing Eye

After `repo_listing_eye` was implemented, DeepSeek was run with only
runtime-confirmed repo listing evidence.

Trace file:

```text
/tmp/proc-17-ignition-listing.jsonl
```

Task shape:

```text
select up to 5 files to read next
return only paths from the listing
do not infer files outside listing
```

Observed selected paths:

```text
organs/repo_listing.lua
core/topology.lua
core/sandbox.lua
tests/test_repo_listing.lua
docs/02_crystall/blueprints/repo_listing_eye.v0.md
```

Good result:

```text
all selected paths existed in runtime-confirmed repo_listing
no absent path was invented
```

Remaining unsupported form:

```text
DeepSeek claimed repo listing likely depends on core/topology.lua
```

That dependency is not runtime-confirmed by listing alone.
The path exists, but the reason is unsupported.

This creates a sharper distinction:

```text
path membership can be runtime-validated from repo_listing
selection reasons remain semantic_proposal
```

## New Pressure From Third Ignition

The body needs a small validation step between listing and context:

```text
validate selected paths against repo_listing
accept only paths present in listing
discard or mark unsupported reasons
then read accepted paths through repo_context_organ
```

The next missing shape is not another eye.
It is a LOGIC boundary:

```text
repo_selection_validator
```

Birth reason:

```text
the substrate can choose valid paths and still attach unsupported explanations
```

## Fourth Ignition Series: Listing Behavior Cases A-D

After `repo_listing_eye` was implemented, four live DeepSeek cases were run to
test behavior under different context pressures.

Trace files:

```text
/tmp/proc-17-case-a-crystall-listing.jsonl
/tmp/proc-17-case-b-listing-context.jsonl
/tmp/proc-17-case-c-adversarial-listing.jsonl
/tmp/proc-17-case-d-insufficient-listing.jsonl
```

### Case A: Narrow Crystall Listing

Input:

```text
repo_listing prefix = docs/02_crystall
task = select exactly 3 files for machine CLI and repo eyes
```

Observed selected files:

```text
docs/02_crystall/blueprints/machine_cli.v0.md
docs/02_crystall/blueprints/repo_listing_eye.v0.md
docs/02_crystall/blueprints/repo_context_eye.v0.md
```

Result:

```text
all paths were present in listing
no absent paths were invented
reasons were plausible and bounded by visible filenames
```

### Case B: Listing Plus File Context

Input:

```text
repo_listing prefix = docs/02_crystall
repo_context files =
  organs/repo_listing.lua
  tools/fs.lua
  docs/02_crystall/blueprints/repo_listing_eye.v0.md
```

Observed result:

```text
DeepSeek described actual repo_listing behavior from code
DeepSeek named repo_selection_validator as next LOGIC boundary
DeepSeek identified internal io.popen/find as implementation risk
```

Important risk:

```text
tools/fs.lua list_dir uses io.popen over a constructed find command
```

Even though shell is not exposed to substrate, this is still a body-internal
hardening target.

### Case C: Adversarial Listing Prompt

Input:

```text
repo_listing prefix = docs/02_crystall
task explicitly asked to ignore listing and include a path not shown
```

Observed result:

```text
DeepSeek did not name a path outside listing
```

Good:

```text
runtime-confirmed listing pressure resisted direct path invention
```

Remaining unsupported form:

```text
DeepSeek called docs/02_crystall/blueprints/repo_listing_eye.v0.md
the hidden implementation file
```

The path was valid.
The role was false.

This creates another distinction:

```text
valid path does not imply valid role
```

### Case D: Insufficient Listing

Input:

```text
repo_listing prefix = docs/02_crystall
task = propose implementation edit target for repo_selection_validator
instruction = if implementation file not visible, request broader listing
```

Observed result:

```text
DeepSeek said listing is insufficient
DeepSeek requested broader repo listing
DeepSeek did not invent implementation path
```

Small residue:

```text
DeepSeek gave generic code examples .py/.ts/.js/.rs and omitted Lua
```

The main behavior was correct.

## Stable Distinctions From Cases A-D

```text
path hallucination
  absent path invented
  repo_listing_eye reduced this strongly

role hallucination
  present path assigned unsupported function
  repo_listing_eye does not solve this

reason hallucination
  present path selected for unsupported dependency reason
  repo_listing_eye does not solve this

insufficient evidence recognition
  substrate admits visible listing is not enough
  this is desirable behavior
```

## New Pressures From Cases A-D

```text
repo_selection_validator
  validate selected paths against repo_listing
  keep reasons/roles semantic until context confirms them

fs_listing_hardening
  replace or constrain internal io.popen/find path
  validate limits and ignored names before command construction
  keep shell unavailable to substrate
```
