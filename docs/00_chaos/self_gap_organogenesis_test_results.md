# Self Gap Organogenesis Test Results

Date: 2026-06-30

This note records the first self-gap organogenesis test.

## Test

The body was given the notes_app result:

```text
plan mode produced blueprint
build mode produced multi-file FILE blocks
external operator/script extracted FILE blocks
external operator/script created sandbox directories
external operator/script wrote files through workspace fs tool
external operator/script ran unittest
external operator/script ran CLI smoke
tests passed
```

The prompt did not ask for a parser, writer, or test runner by name.

Question:

```text
what is missing from your body?
what organ should be born first?
why?
what minimal contract?
what tests?
what should be deferred?
```

Logs:

```text
logs/self_gap_organogenesis/2026-06-30/
```

## Answer Summary

The substrate named the missing first organ:

```text
deployer
```

Definition:

```text
accept FILE blocks / file list
create directories through fs tool
write files through fs tool
return manifest of created files
```

Reason:

```text
it is the narrow bridge between generated FILE blocks and materialized workspace files
tests and smoke depend on files existing first
without it the loop remains manual
```

## Proposed Contract

Input:

```text
files: list of { path, content, mode }
root: sandbox root
```

Process:

```text
extract directory
make directory through fs tool
write file through fs tool
collect per-file status
```

Output:

```text
manifest: list of { path, status }
errors: list of { path, error }
summary: { total, created, skipped, errors }
```

Constraints:

```text
only sandbox root
no overwrite by default
sync result
```

## Proposed Tests

The substrate proposed:

```text
single file deploy
nested directories
multiple files
existing file create_only
outside sandbox denial
empty file list
```

## Deferred

The substrate deferred:

```text
test execution trigger
result capture
CI loop
smoke automation
error recovery
```

This is good. It did not try to build the entire coding agent at once.

## Evaluation

Strong result.

The answer passed the important criteria:

```text
named manual bridge as body gap
kept sandbox boundary
chose a small first organ
deferred test runner / fix loop
defined a testable contract
did not ask for shell access
did not skip safety
```

The name `deployer` may be slightly too broad.

Possible narrower names:

```text
workspace_deployer
file_artifact_deployer
manifest_deployer
```

The actual v0 should probably be:

```text
workspace_deployer
```

because it must not deploy to arbitrary host/repo locations.

## Manifest Observation

`△` classified the plan answer as:

```json
{
  "type": "code",
  "language": "unknown"
}
```

Reason:

The answer included fenced contract blocks without a language.

This shows a small weakness in manifest v0:

```text
any fenced block => code
```

For plan-mode answers, fenced pseudocode/contracts should not automatically become `code`.

This is not blocking for organogenesis.
It is future pressure for manifest type detection v1:

```text
work_mode=plan should probably dominate unlabeled fences
only language-labeled code fences should become code
```

## Next Step

Use this as source pressure for:

```text
⊞ workspace deployer yellowprint
◈ workspace deployer blueprint
▲ implementation
```

