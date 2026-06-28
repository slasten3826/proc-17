# Machine CLI Yellowprint v0

The first CLI is a machine-facing execution surface.

It exists so another agent or test can run the body and inspect packet events.

## Non-Goals

```text
no TUI
no chat interface
no rich human UX
no agent marketplace
no real provider requirement
```

## First Commands

Candidate commands:

```text
procesis-body run --task "..." --fake
procesis-body packet-new --task "..."
procesis-body packet-trace <packet-file>
procesis-body test-loop --fake
```

This can be simplified during implementation.

## Output Modes

```text
--json
  one final JSON object

--jsonl
  one event per line

--trace
  full packet trace

--summary
  compact final result
```

First implementation should prefer:

```text
--jsonl
```

because packet life is an event stream.

## Exit Codes

Candidate exit codes:

```text
0 complete / manifested
1 runtime error
2 invalid input
3 packet died before completion
4 test failure
5 unsupported command
```

## Machine Contract

Every machine-facing output event should include:

```text
packet_id
event_id
type
operator
truth_status
payload
```

No prose-only output for machine mode.

