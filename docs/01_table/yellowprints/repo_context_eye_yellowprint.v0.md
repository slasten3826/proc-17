# Repo Context Eye Yellowprint v0

`repo_context_organ` is the first OBSERVE-side eye for `proc-17`.

It exists because live DeepSeek ignition showed that substrate without repo
evidence fills missing context with plausible but unsupported structure.

## Role

```text
operator: OBSERVE
side: chaos-facing
mode: read-only first
purpose: provide runtime-confirmed repo evidence before substrate reasoning
```

## Input

```text
packet
task
mode
workspace root
sandbox policy
file selection rules
```

## Output

```text
repo_context_payload
```

Payload candidate:

```text
file_tree
selected_files
file_summaries
evidence_events
limits
```

## First Route

```text
packet birth
mode_enter
OBSERVE repo tree
OBSERVE selected files
ENCODE repo context payload
substrate_call with context payload
substrate_result as semantic_proposal
LOGIC compare proposal against evidence
unsupported claims become gap residue
```

## Read-Only Constraint

The first eye must not write files.

Allowed:

```text
list files
read files
encode context
```

Denied:

```text
write files
run shell
git mutation
delete
```

## Sandbox Dependency

All file access must go through:

```text
core/sandbox.lua
tools/fs.lua
```

No direct host reads from substrate.

## Test Surface

Candidate tests:

```text
repo context lists files
repo context refuses unsafe paths
repo context reads selected allowed files
repo context payload includes evidence markers
substrate call includes repo context payload
unsupported repo claim can be detected later
```

## Open Question

File selection policy is not fully decided.

Early implementation can start with explicit file list or small default roots.

