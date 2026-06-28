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

## Manual Check Result

DeepSeek ignition with `--repo-list` showed:

```text
selected paths stayed inside runtime-confirmed listing
selection reasons still contained unsupported dependency inference
```

Additional cases A-D showed:

```text
narrow listing can produce bounded file choices
listing plus context lets substrate identify concrete implementation risk
adversarial prompt did not force absent-path invention
valid path can still be assigned false implementation role
insufficient listing can produce correct request for broader listing
```

Contract implication:

```text
path membership may be validated against repo_listing
selection reasons must remain semantic_proposal
```

Next LOGIC boundary:

```text
repo_selection_validator
```

The boundary must validate path membership only.
Role and reason claims stay semantic until file context confirms them.

## Manifest v0 Status

Current implementation:

```text
tools/fs.lua list_dir
organs/repo_listing.lua
cli/procesis-body.lua --repo-list [prefix]
```

Implemented:

```text
workspace-relative prefix
sandbox denial for absolute paths
sandbox denial for parent traversal
bounded max_depth / max_entries / max_path_bytes
ignored path filtering
runtime_confirmed listing payload
observation event with kind = repo_listing
repo_listing included in substrate_call
unit and CLI integration tests
```

Implementation note:

```text
Lua v0 has no lfs/posix dir primitive in this environment.
list_dir currently uses internal host find behind sandbox.
This is not exposed as a shell tool to substrate.
```

Still absent:

```text
semantic file ranking
automatic context selection
directory summary compression
non-shell Lua directory primitive
```
