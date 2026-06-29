# Cognitive Battery Run 2026-06-29 With Hints

Status: captured, not yet canon.

This directory stores the repeated cognitive battery run through proc-17 body with operator runtime hints enabled.

## Run Shape

- substrate: DeepSeek through `cli/procesis-body.lua`
- hints: enabled by default
- route: live proc-17 CLI route with logs, cycle, runtime, encode, choose, logic, and operator hints enabled
- output format: JSONL stdout plus JSONL trace files
- stderr: empty after final run
- user battery: 10 / 10 complete
- codex battery: 34 / 34 complete

Each test has three files:

- `*.trace.jsonl`: internal packet/operator trace
- `*.stdout.jsonl`: CLI output stream
- `*.stderr.txt`: runtime stderr

## Difference From Previous Run

Previous baseline:

```text
logs/cognitive_battery/2026-06-29/
```

This run:

```text
logs/cognitive_battery/2026-06-29_hints/
```

The main intended difference is:

```text
operator_runtime_hints enabled
```

Each run should include:

```text
type = hint_pressure
payload.enabled = true
payload.hint_count = 32
```

and `substrate_call.payload.operator_hints`.

## User Battery

Source:

```text
docs/00_chaos/cognitive_test_battery_user_candidate.md
```

Files:

```text
user/u01..u10.{trace.jsonl,stdout.jsonl,stderr.txt}
```

## Codex Battery

Source:

```text
docs/00_chaos/cognitive_test_battery_codex_candidate.md
```

Files:

```text
codex/c01..c34.{trace.jsonl,stdout.jsonl,stderr.txt}
```

Special flags:

```text
c10-c12 use --repo-list logic
```

## Read Rule

Analyze this run by comparison against the baseline run.

Do not judge hints only by answer beauty.

Check:

```text
project grounding
substrate drift
refusal behavior
repo truth behavior
☵ field shape
☳ killed alternatives
☶ truth boundary
```
