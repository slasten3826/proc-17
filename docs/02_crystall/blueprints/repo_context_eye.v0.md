# Repo Context Eye Blueprint v0

This blueprint defines the first OBSERVE-side eye for `proc-17`.

## Primary Rule

The substrate must not be asked to understand the repository without
runtime-confirmed repo evidence.

## Organ

```text
repo_context_organ
```

Operator:

```text
☴ OBSERVE
```

First mode:

```text
read-only
```

## Required Behavior

The organ must:

```text
list repo files or accept an explicit file list
read selected files through tool/sandbox
produce repo_context_payload
append runtime_confirmed evidence events
pass repo_context_payload into substrate_call
keep substrate_result as semantic_proposal
```

## Required Payload Fields

```text
file_tree
selected_files
files
limits
```

Each file entry should include:

```text
path
content
bytes
truth_status = runtime_confirmed
```

## Sandbox Contract

All reads must pass through:

```text
core/sandbox.lua
tools/fs.lua
```

Denied:

```text
absolute paths
parent traversal
shell command
git mutation
delete
write during first eye pass
```

## Test Obligations

```text
unit_test: repo context reads allowed file
unit_test: repo context denies unsafe path through fs/sandbox
unit_test: repo context payload marks files runtime_confirmed
integration_test: substrate_call receives repo_context payload
manual_check: DeepSeek ignition with repo_context reduces unsupported repo-shape hallucination
```

## Not In Scope

```text
automatic large-repo indexing
semantic file ranking
write actions
runtime memory
residue store
phantom organ execution
```

## Manifest v0 Status

Current implementation:

```text
organs/repo_context.lua
cli/procesis-body.lua --repo-context <comma-separated-files>
```

Implemented:

```text
explicit file list
fs/sandbox reads
runtime_confirmed file payloads
observation event with kind = repo_context
repo_context included in substrate_call
prompt_payload includes encoded runtime-confirmed context
unit and CLI integration tests
```

Still absent:

```text
automatic repo file discovery
semantic file ranking
directory summaries
runtime-side memory eye
```
