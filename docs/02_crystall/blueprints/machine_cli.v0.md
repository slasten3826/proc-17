# Machine CLI Blueprint v0

The first CLI is machine-facing.

It is not a user interface.

## Scope

The first CLI must expose:

```text
packet birth
fake substrate loop
fake tool loop
trace events
manifest result
death / residue
test visibility
```

The first CLI must not include:

```text
TUI
chat UI
interactive human shell
provider setup wizard
multi-agent UI
```

Test status:

```text
integration_test: fake_substrate_loop_integration
```

## Output Contract

Machine mode output must be structured.

First supported output mode:

```text
jsonl
```

Each JSONL line must represent one packet event or final envelope.

Required event fields:

```text
packet_id
event_id
type
operator
truth_status
payload
```

The fake run should include at least:

```text
birth
operator_enter
substrate_call
substrate_result
tool_call
tool_result
budget_spend
manifest
death
final
```

Test status:

```text
integration_test: machine_cli_jsonl_output_integration
```

## First Command Contract

The first command may be narrow:

```text
procesis-body run --task <text> --fake --jsonl
```

DeepSeek is also available after adapter verification:

```text
procesis-body run --task <text> --deepseek --jsonl
```

`--fake` remains the default test path.
Real provider calls are manual checks, not normal test-suite requirements.

Optional trace persistence:

```text
procesis-body run --task <text> --fake --jsonl --trace-file <path>
```

`--trace-file` writes the same packet event stream plus final envelope to disk.

Optional body mode:

```text
procesis-body run --task <text> --fake --jsonl --mode chaos
```

Allowed modes:

```text
chaos
table
crystall
manifest
```

Invalid mode exits with code `2`.

Optional OBSERVE-side repo context:

```text
procesis-body run --task <text> --fake --jsonl --repo-context README.md,core/packet.lua
```

`--repo-context` accepts a comma-separated explicit file list.
The CLI reads those files through the repo context organ and fs/sandbox.
The resulting payload is runtime-confirmed evidence and is included in
the `substrate_call` payload.

Test status:

```text
integration_test: machine_cli_fake_run_integration
integration_test: machine_cli_trace_file_integration
integration_test: machine_cli_mode_integration
integration_test: machine_cli_repo_context_integration
manual_check: machine_cli_deepseek_smoke
```

## Exit Code Contract

```text
0 complete / manifested
1 runtime error
2 invalid input
3 packet died before completion
4 test failure
5 unsupported command
```

Test status:

```text
integration_test: machine_cli_exit_code_integration
```
