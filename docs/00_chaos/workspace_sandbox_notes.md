# Workspace Sandbox Notes

Date: 2026-06-30

This note records the next safety boundary.

proc-17 has two different worlds:

```text
proc17_root
  the body source code

workspace_sandbox
  the only world where proc-17 may perform user-task repo mutation
```

These must not be confused.

## Why

The current machine is a real working machine.

proc-17 must not treat `/home/slasten/work` as its playground.
It must not treat its own source repo as the default target repo.

The body can be developed in proc17_root by Codex/user collaboration.

But when proc-17 acts as a coding agent, it should only act inside:

```text
/home/slasten/work/procesis-body/sandbox
```

In repo-relative form:

```text
sandbox/
```

## Proposed Layout

```text
sandbox/
  projects/
    hello/
    tictactoe/
    external-repo-copy/
  runs/
    2026-06-30-001/
      trace.jsonl
      manifest.json
      stdout.txt
      stderr.txt
  tmp/
```

## Root Rule

For agent work:

```text
all writes must stay under sandbox/
```

No exceptions in v0.

## Read Rule

Reads for repo context may eventually target:

```text
sandbox/projects/<project>
```

Current proc-17 source reads remain allowed for developing proc-17 itself.

But user-task mutation should use workspace sandbox reads/writes.

## Write Rule

Allowed:

```text
sandbox/projects/hello/hello.py
sandbox/runs/<run-id>/trace.jsonl
sandbox/tmp/scratch.py
```

Denied:

```text
../anything
/absolute/path
.git/config
sandbox/../README.md
README.md
core/packet.lua
docs/...
```

The last three are denied for agent workspace writes even if they are valid proc-17 development paths.

## File Write Modes

The first file write organ should support:

```text
create_only
overwrite
append
```

v0 should start with:

```text
create_only
```

Overwrite is dangerous and should require explicit mode later.

## Directory Creation

The body will need to create directories under sandbox.

Allowed:

```text
sandbox/projects/<name>/
sandbox/runs/<run-id>/
sandbox/tmp/
```

Denied:

```text
any directory outside sandbox
.git
hidden control dirs
```

## Relationship To Existing Sandbox Policy

Existing sandbox policy is mode/path permission for proc-17 development.

Workspace sandbox is stricter:

```text
agent workspace write -> must be under sandbox/
proc-17 development write -> governed by mode path policy
```

These are different contexts.

The tool call must say which context it is using.

## Future Coding Agent Path

Once workspace sandbox exists:

```text
plan -> build -> △ code manifest
file_write -> sandbox/projects/<task>/main.py
test_runner -> run allowed checks
△ repo mutation manifest
```

This is the first real transition from code generation to coding agent.

