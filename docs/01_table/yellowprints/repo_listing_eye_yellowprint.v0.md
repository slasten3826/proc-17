# Repo Listing Eye Yellowprint v0

`repo_listing_eye` is the next OBSERVE-side pressure after the first
repo-context ignition.

It exists because `repo_context_organ` can read only files that are already
named by the caller.

## Distinction

```text
repo_listing_eye
  answers: what files exist here?

repo_context_organ
  answers: what do selected files contain?
```

These should stay separate.

Listing is retina.
Context is focused reading.

## Role

```text
operator: OBSERVE
side: chaos-facing
mode: read-only
purpose: produce bounded runtime-confirmed repo file tree
```

## Input

```text
packet
mode
workspace root
sandbox policy
listing limits
ignore rules
optional path prefix
```

## Output

```text
repo_listing_payload
```

Payload candidate:

```text
root
paths
limits
ignored
truth_status = runtime_confirmed
```

Each path entry candidate:

```text
path
kind = file | directory
bytes optional for file
truth_status = runtime_confirmed
```

## First Route

```text
packet birth
mode_enter
OBSERVE repo listing
ENCODE bounded tree payload
OBSERVE selected file context
substrate_call with listing + context evidence
substrate_result as semantic_proposal
```

## Read-Only Constraint

Allowed:

```text
list workspace-relative paths
apply ignore rules
bound depth/count/output size
```

Denied:

```text
shell command
git mutation
absolute path listing
parent traversal
delete
write
```

## Sandbox Dependency

All listing must go through body-owned code and sandbox checks.

The substrate must not call:

```text
find
ls
git
shell
```

## Initial Ignore Candidates

```text
.git
.agents
.codex
node_modules
vendor
tmp
```

Ignore policy should be explicit in payload when it affects output.

## Test Surface

Candidate tests:

```text
repo listing returns known repo files
repo listing marks entries runtime_confirmed
repo listing denies absolute root
repo listing denies parent traversal
repo listing respects max_entries
repo listing omits ignored directories
CLI can include repo listing before repo context
```

## Open Questions

```text
should listing live in tools/fs.lua or organs/repo_listing.lua?
should listing include file sizes in v0?
should CLI default to listing README/docs/core, or require --repo-list?
```

Early implementation should prefer explicit `--repo-list` over automatic
always-on listing.

## Ignition Result Notes

Cases A-D showed:

```text
repo_listing_eye reduces absent-path invention
repo_listing_eye does not validate file role
repo_listing_eye does not validate selection reasons
insufficient listing can cause correct request for broader listing
```

Next downstream table shape:

```text
repo_selection_validator
```
