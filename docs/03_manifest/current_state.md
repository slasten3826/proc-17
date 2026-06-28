# Current Manifest State

This document describes what exists now.
It must not describe planned behavior as if it exists.

## Existing Files

```text
README.md
BODY_SPEC.md
PACKET_SPEC.md
SUBSTRATE_SPEC.md
core/
cli/
substrates/
tests/
docs/
```

## Existing Code

Executable Lua v0 skeleton exists.

Current implemented files:

```text
core/topology.lua
  ProcessLang operator topology and trace validation

core/modes.lua
  body mode permission descriptors and write path policy

core/sandbox.lua
  default-deny host permission layer for filesystem/shell checks

core/packet.lua
  packet.v0 protocol: birth, mode, trace, budget spend, unsupported form, manifest, death, residue

core/json.lua
  small dependency-free JSON encoder/decoder

substrates/contract.lua
  shared substrate call/response contract helpers

substrates/fake.lua
  deterministic fake substrate

substrates/openai_compatible.lua
  OpenAI-compatible chat/completions adapter via curl

substrates/deepseek.lua
  DeepSeek adapter using DEEPSEEK_API_KEY

tools/contract.lua
  shared tool call/result contract helpers

tools/fake.lua
  deterministic fake tool facade with write permission dry-run

tools/fs.lua
  real workspace-relative read_file/write_file facade with mode path policy

runtime/trace_store.lua
  explicit JSONL packet trace writer

cli/procesis-body.lua
  machine-facing JSONL CLI with --fake, --deepseek, and --mode

tests/
  JSON, packet, topology, sandbox, substrate normalization, tool facade, fs tool, trace store, and CLI smoke tests
  includes mode path policy tests
```

## Current Git State

This directory is published as:

```text
https://github.com/slasten3826/proc-17
```

Current branch:

```text
main
```

## Current Architecture Status

```text
stage: first_executable_skeleton
implementation: lua_v0_skeleton
cli: machine_jsonl_fake_and_deepseek
packet_model: packet.v0_partial
router: topology.v0_partial
runtime: budget_inside_packet_only
sandbox: default_deny_v0
substrates: fake_and_deepseek
tools: fake_only
fs_tool: read_write_guarded
trace_store: explicit_jsonl
body_modes: packet_cli_and_path_policy_implemented
```

## Current Commands

Run all tests:

```text
lua tests/run.lua
```

Run fake machine CLI:

```text
lua cli/procesis-body.lua run --task "smoke" --fake --jsonl
```

Run fake machine CLI in chaos mode:

```text
lua cli/procesis-body.lua run --task "smoke" --fake --jsonl --mode chaos
```

Run fake machine CLI with trace file:

```text
lua cli/procesis-body.lua run --task "smoke" --fake --jsonl --trace-file /tmp/proc-17-trace.jsonl
```

Run DeepSeek machine CLI:

```text
lua cli/procesis-body.lua run --task "Return one word: ok" --deepseek --jsonl
```

## Current Verification

Last verified:

```text
lua tests/run.lua
```

Result:

```text
test_json ok
test_modes ok
test_sandbox ok
test_topology ok
test_packet ok
test_substrates ok
test_tools ok
test_fs_tool ok
test_trace_store ok
test_cli ok
all tests ok
```

Manual DeepSeek smoke:

```text
lua cli/procesis-body.lua run --task "Return one word: ok" --deepseek --jsonl
```

Observed result:

```text
http_status: 200
text: ok
truth_status: semantic_proposal
final status: dead
death cause: complete
```

## Current Limits

```text
no real tool facade
no shell command tool
no directory creation in fs tool
no automatic trace persistence
no TUI or human UI
no child packet execution
no real file writes; write permissions are dry-run only
real provider calls are manual, not part of normal test suite
```
