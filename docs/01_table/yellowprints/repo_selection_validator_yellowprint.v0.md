# Repo Selection Validator Yellowprint v0

`repo_selection_validator` is the LOGIC boundary after `repo_listing_eye`.

It exists because live ignition showed that substrate can select existing paths
while still attaching unsupported roles or reasons.

## Distinction

```text
repo_listing_eye
  observes paths that exist

substrate selection
  proposes paths to read next

repo_selection_validator
  checks proposed paths against observed listing

repo_context_organ
  reads accepted paths
```

## Failure Shapes

```text
path hallucination
  selected path is absent from repo_listing

role hallucination
  selected path exists, but is assigned unsupported role

reason hallucination
  selected path exists, but the stated dependency/reason is unsupported
```

`repo_selection_validator` should solve path hallucination first.

It should not pretend to solve role or reason hallucination.

## Input

```text
repo_listing_payload
substrate_result
selection extraction rules
limits
```

## Output

```text
repo_selection_payload
```

Payload candidate:

```text
accepted_paths
rejected_paths
unparsed_text
selection_reasons
truth_status = runtime_confirmed for path membership only
```

## Route

```text
OBSERVE repo listing
substrate proposes file selections as semantic_proposal
LOGIC validate proposed paths against listing entries
OBSERVE read accepted paths through repo_context_organ
substrate reasons from runtime-confirmed file contents
```

## Validation Rule

Runtime-confirmed:

```text
path exists in repo_listing entries
path kind is file unless directory reading is explicitly allowed
path passes sandbox path check
```

Still semantic:

```text
why the path was chosen
what role the file has
whether the file implements a concept
dependency claims
```

## Test Surface

Candidate tests:

```text
accepts path present in listing
rejects path absent from listing
rejects directory when file-only mode is active
preserves reasons as semantic_proposal
emits accepted paths for repo_context_organ
records rejected paths as unsupported or rejected
```

## Open Questions

```text
should selection input require JSON, or parse paths from text?
should reasons be retained in payload, or stripped before context read?
should accepted directories ever be allowed?
```

Early implementation can parse plain text paths conservatively because current
substrate outputs are not yet structured.
