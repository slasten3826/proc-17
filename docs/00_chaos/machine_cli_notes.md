# Machine CLI Notes

The first CLI is not a user interface.

It is a machine interface for:

```text
Codex
tests
future wrappers
debugging packet life
```

No TUI.
No chat UI.
No human-oriented interactive shell yet.

## Role

The CLI should expose the body loop in a form that another machine can call and
inspect.

It should make packet life visible:

```text
birth
operator route
substrate calls
tool calls
validations
unsupported forms
budget spends
manifest
death
residue
```

## Output

Prefer machine-readable output first.

Candidate modes:

```text
--json
--jsonl
--trace
--summary
```

Early default can be JSONL because packet life is event-shaped.

Human pretty output can come later.

## Why Not Pi / TUI Yet

Pi-like CLI/TUI can be studied later.

Right now, a rich UI would create pressure in the wrong place.

First need:

```text
packet protocol works
fake substrate loop works
tests pass
trace is readable by machines
```

The first CLI should serve the body, not define it.

