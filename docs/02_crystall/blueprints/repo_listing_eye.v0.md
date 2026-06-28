# Repo Listing Eye Blueprint v0

This blueprint defines the read-only repo listing eye for `proc-17`.

## Primary Rule

The body may expose repository shape to substrate only as bounded
runtime-confirmed evidence.

The substrate must not invent repository shape.

## Organ

```text
repo_listing_eye
```

Operator:

```text
☴ OBSERVE
```

Mode:

```text
read-only
```

## Scope

`repo_listing_eye` lists workspace-relative paths.

It does not read file contents.

File content remains owned by:

```text
repo_context_organ
```

## Required Behavior

The organ must:

```text
accept optional workspace-relative prefix
deny absolute paths
deny parent traversal
list bounded file/directory entries
apply explicit ignore rules
produce repo_listing_payload
append runtime_confirmed observation event
optionally pass repo_listing_payload into substrate_call
```

## Required Payload Fields

```text
kind = repo_listing_payload
root
prefix
entries
limits
ignored
truth_status = runtime_confirmed
```

Each entry must include:

```text
path
kind = file | directory
truth_status = runtime_confirmed
```

File entries may include:

```text
bytes
```

## Limits

Initial limits:

```text
max_entries
max_depth
max_path_bytes
```

If the listing is truncated, payload must include:

```text
truncated = true
truncation_reason
```

## Ignore Rules

Initial ignored paths:

```text
.git
.agents
.codex
node_modules
vendor
tmp
```

Ignore rules must be visible in payload.

## Sandbox Contract

All path roots and prefixes must pass through:

```text
core/sandbox.lua
```

Denied:

```text
absolute paths
parent traversal
shell command
git command
delete
write
```

The implementation may use Lua filesystem primitives inside body-owned code.
It must not expose shell execution to substrate.

## CLI Contract

Initial CLI should be explicit:

```text
procesis-body run --task <text> --fake --jsonl --repo-list
```

Optional prefix:

```text
procesis-body run --task <text> --fake --jsonl --repo-list docs/02_crystall
```

No automatic always-on listing in v0.

## Test Obligations

```text
unit_test: repo listing returns known repo files
unit_test: repo listing marks entries runtime_confirmed
unit_test: repo listing denies absolute prefix
unit_test: repo listing denies parent traversal prefix
unit_test: repo listing respects max_entries
unit_test: repo listing omits ignored directories
integration_test: CLI emits repo_listing observation
integration_test: substrate_call receives repo_listing payload
manual_check: DeepSeek can choose relevant files from listing without inventing absent modules
```

## Not In Scope

```text
semantic file ranking
content reading
automatic context selection
shell tool
git status
runtime memory eye
phantom execution
```

## Relation To Repo Context Eye

Expected later route:

```text
repo_listing_eye produces file tree
substrate proposes relevant files as semantic_proposal
body validates proposed paths
repo_context_organ reads selected files
substrate reasons from runtime-confirmed contents
```

The proposal step must not become runtime truth until validated.
