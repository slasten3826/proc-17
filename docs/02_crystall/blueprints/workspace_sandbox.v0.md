# Workspace Sandbox Blueprint v0

Status: implemented in this pass

Source:

```text
docs/01_table/yellowprints/workspace_sandbox_yellowprint.v0.md
```

## Modules

```text
core/sandbox.lua
tools/fs.lua
tests/test_sandbox.lua
tests/test_fs_tool.lua
```

## Constants

Workspace root:

```lua
"sandbox"
```

## Contexts

Sandbox context:

```lua
{
  mode = "manifest",
  context = "body" | "workspace"
}
```

Default:

```text
body
```

## Public Sandbox Functions

Existing:

```lua
check_path(path)
can_read_file(context, path)
can_write_file(context, path)
can_run_command(context, command)
```

New:

```lua
workspace_root() -> "sandbox"
is_workspace_path(path) -> boolean
can_make_dir(context, path) -> ok, reason
```

## Body Context

Body context preserves current behavior:

```text
relative reads allowed
writes governed by mode path policy
shell denied
```

## Workspace Context

Workspace context:

```text
relative paths only
parent traversal denied
absolute paths denied
must start with sandbox/
.git and hidden control dirs denied
writes allowed only under sandbox/
mkdir allowed only under sandbox/
```

Workspace write ignores body mode path policy because the workspace root is already the hard boundary.

## FS Tool Changes

`tools/fs.lua` accepts:

```lua
input.context = "workspace"
```

for:

```text
read_file
list_dir
write_file
make_dir
```

`write_file` accepts:

```lua
write_mode = "create_only"
```

v0:

```text
create_only is default for workspace context
create_only denies existing target
overwrite remains old body behavior only
```

`make_dir` creates a single directory path via Lua/host primitive.

## Tests

Required:

```text
workspace path helper identifies sandbox paths
workspace write allows sandbox/projects/hello/main.py
workspace write denies README.md
workspace write denies .git
workspace make_dir allows sandbox/projects/test
workspace make_dir denies docs path
fs make_dir creates sandbox directory
fs write_file create_only writes new file
fs write_file create_only denies existing file
```

