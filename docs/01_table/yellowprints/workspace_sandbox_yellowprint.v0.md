# Workspace Sandbox Yellowprint v0

Source chaos:

```text
docs/00_chaos/workspace_sandbox_notes.md
```

## Intent

Separate proc-17 body development from proc-17 task execution.

```text
body context
  may use existing mode path policy for proc-17 source/docs/tests

workspace context
  may only mutate sandbox/
```

## Workspace Root

Repo-relative workspace root:

```text
sandbox/
```

Required subroots:

```text
sandbox/projects/
sandbox/runs/
sandbox/tmp/
```

## Context Field

Tool calls that write files should include:

```text
context = body | workspace
```

Default for current internal tools may remain:

```text
body
```

New agent-facing file writes should use:

```text
workspace
```

## Workspace Write Policy

Allowed paths must:

```text
be relative
not contain ..
start with sandbox/
not contain hidden control dirs
not target .git
```

Allowed:

```text
sandbox/projects/hello/main.py
sandbox/runs/run-001/trace.jsonl
sandbox/tmp/scratch.py
```

Denied:

```text
README.md
core/packet.lua
docs/00_chaos/x.md
../x
/tmp/x
sandbox/../README.md
sandbox/projects/.git/config
```

## Directory Creation

Workspace v0 should support directory creation under sandbox:

```text
make_dir(path)
```

Allowed:

```text
sandbox/projects/hello
sandbox/runs/run-001
sandbox/tmp
```

Denied outside sandbox.

## File Creation

First file write organ should use create-only semantics.

```text
write_file mode = create_only
```

Rules:

```text
parent directory must exist
target file must not already exist
content written exactly
trace/tool result records bytes and path
```

Overwrite and append are deferred.

## Tests

Required:

```text
workspace write allows sandbox/projects/hello/main.py
workspace write denies README.md
workspace write denies core/packet.lua
workspace write denies parent traversal
workspace write denies absolute path
workspace write denies .git path
workspace mkdir allows sandbox/projects/hello
workspace mkdir denies docs path
create_only denies existing file
```

