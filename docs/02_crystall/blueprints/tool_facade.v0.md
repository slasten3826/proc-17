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
list_dir
run_command
```

The fake tool simulates actions; it does not touch the host filesystem.

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
integration_test: machine CLI emits tool_call/tool_result
```

## Limits

```text
no real filesystem tool yet
no real shell tool yet
no write tool yet
no permission model yet
```
