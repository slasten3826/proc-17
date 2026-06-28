# Repo Selection Validator Blueprint v0

This blueprint defines the LOGIC boundary between repo listing and repo context.

## Primary Rule

The body may validate that a selected path exists in runtime-confirmed listing.

The body must not promote the substrate's reason or role claim to runtime truth.

## Module

```text
repo_selection_validator
```

Operator:

```text
☶ LOGIC
```

## Scope

The validator checks path membership only.

It does not read files.

It does not decide that a file implements a concept.

It does not prove dependency claims.

It validates proposal shape before runtime contact.

Sandbox still guards contact itself.

## Required Behavior

The validator must:

```text
accept repo_listing_payload
accept substrate selection proposal
extract candidate paths conservatively
accept paths present in listing entries
reject paths absent from listing entries
reject directories unless allow_directories = true
preserve reasons as semantic_proposal or unsupported text
produce repo_selection_payload
```

Required module path:

```text
logic/repo_selection.lua
```

Required functions:

```text
build_index(repo_listing_payload) -> index
extract_paths(text, repo_listing_payload, options) -> candidates
validate(input) -> repo_selection_payload | nil, error
```

`validate(input)` input:

```text
listing
text
allow_directories = false
max_paths = 8
```

## Required Payload Fields

```text
kind = repo_selection_payload
accepted_paths
rejected_paths
reasons
unparsed_text
limits
truth_status = runtime_confirmed for path membership only
```

Each accepted path must include:

```text
path
kind
truth_status = runtime_confirmed
```

Each rejected path must include:

```text
path
reason
truth_status = rejected
```

Reason text from substrate must include:

```text
truth_status = semantic_proposal
```

## Path Extraction v0

The first extractor should be conservative:

```text
prefer exact path membership against repo_listing entries
accept paths inside backticks only if exact listed path
accept bare listed paths only if exact listed path
do not repair or normalize model output paths
do not accept basename-only matches
deduplicate accepted paths
```

If text contains no listed path, output should keep:

```text
unparsed_text
```

## Input Truth Boundaries

Runtime-confirmed input:

```text
repo_listing_payload.entries
```

Runtime-confirmed output:

```text
accepted path membership
rejected absent path membership
directory rejection
limit rejection
```

Semantic input:

```text
substrate_result.text
substrate_result.proposal
selection reasons
role claims
dependency claims
```

## Test Obligations

```text
unit_test: accepts listed file path
unit_test: rejects absent path
unit_test: rejects listed directory by default
unit_test: allows listed directory only when allow_directories = true
unit_test: preserves reason as semantic_proposal
unit_test: unparsed text remains semantic
unit_test: deduplicates repeated path
unit_test: enforces max_paths
integration_test: listing -> substrate proposal -> selection validation -> context read
```

## Not In Scope

```text
semantic file ranking
proving file roles
dependency graph discovery
automatic edit target selection
file content reading
shell access
```

## Ignition Evidence

Cases A-D showed:

```text
DeepSeek usually selected paths present in listing
DeepSeek resisted direct adversarial request to invent absent path
DeepSeek still assigned unsupported role to a valid path
DeepSeek could recognize insufficient listing and request broader listing
```

Contract implication:

```text
validate path membership
do not validate role from listing alone
do not validate reason from listing alone
```

## Expected Route

```text
repo_listing_eye
substrate selection proposal
repo_selection_validator
repo_context_organ reads accepted paths
substrate reasons from file contents
```

## Manifest v0 Status

Current implementation:

```text
logic/repo_selection.lua
tests/test_repo_selection.lua
```

Implemented:

```text
build_index
extract_paths
validate
listed file acceptance
absent path rejection
directory rejection by default
directory allowance by option
max_paths enforcement
deduplication
semantic_proposal preservation for reasons
tuned extraction for backticks, markdown bold, leading line paths, and standalone listed paths
```

Still absent:

```text
CLI integration
automatic listing -> selection -> context loop
structured JSON selection protocol
role validation
reason validation
```
