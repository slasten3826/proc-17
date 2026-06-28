# Tool Facade Blueprint v0

Tool facade normalizes host interaction into packet protocol.

## Primary Rule

Tools are called by the body.

The LLM substrate may propose tool use, but it does not execute tools.

## Current Tools

```text
tools/contract.lua
  shared tool call/result contract helpers

tools/fake.lua
  deterministic fake tool facade for tests

tools/fs.lua
  real workspace-relative read_file/write_file facade
```

## Tool Call Contract

Tool call payload should include:

```text
tool
action
input
```

Allowed v0 fake actions:

```text
inspect_task
read_file
write_file
list_dir
run_command
```

The fake tool simulates actions; it does not touch the host filesystem.

`write_file` currently performs permission checks only.
It never writes to disk.

The fs tool can touch the host filesystem, with constraints:

```text
relative paths only
absolute paths denied
parent traversal denied
write_file must pass mode path policy
```

## Tool Result Contract

Normalized result:

```text
ok
action
output
error
metadata
```

Successful tool result may enter trace as:

```text
truth_status = runtime_confirmed
```

Failed tool result enters trace as:

```text
truth_status = rejected
```

## Current Verification

```text
unit_test: fake tool success
unit_test: fake tool invalid action failure
unit_test: fake write tool denies implementation write outside manifest
unit_test: fake write tool allows layer docs writes
unit_test: fs tool denies parent traversal
unit_test: fs tool denies implementation write outside manifest
unit_test: fs tool writes allowed layer docs path
unit_test: fs tool reads written file
integration_test: machine CLI emits tool_call/tool_result
```

## Limits

```text
no real shell tool yet
no directory creation yet
no list_dir implementation yet
no run_command implementation yet
real write tool is guarded but intentionally minimal
```
