# Workspace Sandbox Smoke Results

Date: 2026-06-30

This note records the first workspace sandbox smoke test.

## Direct FS Tool Smoke

The direct tool smoke used:

```text
tools/fs.lua
context = workspace
```

Actions:

```text
make_dir sandbox
make_dir sandbox/projects
make_dir sandbox/projects/workspace_smoke
write_file sandbox/projects/workspace_smoke/main.py
read_file sandbox/projects/workspace_smoke/main.py
write_file same path again
write_file README.md
write_file sandbox/projects/.git/config
```

Observed:

```text
mkdir sandbox                                  ok
mkdir projects                                 ok
mkdir project                                  ok
write main                                     ok
read main                                      ok
duplicate main                                 denied: target already exists
deny readme                                    denied: workspace context requires sandbox path
deny git                                       denied: hidden control directories are not allowed
```

Meaning:

```text
workspace context can create/write inside sandbox/
workspace context cannot overwrite create_only target
workspace context cannot write repo root
workspace context cannot write .git control path
```

## Live Plan/Build Smoke

Task:

```text
create simple Python CLI project in workspace sandbox
main.py prints exactly:
hello from proc-17 workspace
```

Pipeline:

```text
plan mode  -> blueprint
build mode -> Python code
△          -> code/python manifest
fs tool    -> write sandbox/projects/hello_proc17/main.py
runtime    -> python3 sandbox/projects/hello_proc17/main.py
```

Logs:

```text
logs/workspace_write_smoke/2026-06-30/
```

Manifest summary:

```json
{
  "type": "code",
  "language": "python",
  "source_event": "event-8"
}
```

Created file:

```text
sandbox/projects/hello_proc17/main.py
```

Runtime output:

```text
hello from proc-17 workspace
```

Safety checks after write:

```text
duplicate write -> denied: target already exists
README.md write -> denied: workspace context requires sandbox path
```

## Meaning

This is the first bridge from:

```text
manifest code
```

to:

```text
workspace file artifact
```

It is not full repo mutation yet because the file write is still manually bridged after manifest.

But the safety substrate is now present:

```text
all workspace writes are sandbox-rooted
create_only prevents accidental overwrite
repo root and proc-17 source are protected from workspace writes
```

Next pressure:

```text
make the body perform this bridge itself:
△ code manifest -> file_write organ -> runtime test -> repo mutation manifest
```

