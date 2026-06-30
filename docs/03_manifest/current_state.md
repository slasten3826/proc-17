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
logic/
organs/
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
  real workspace-relative read_file/write_file/list_dir facade with mode path policy

logic/repo_selection.lua
  LOGIC boundary: validates selected paths against runtime-confirmed repo listing

logic/choose.lua
  CHOOSE collapse: pure deterministic narrowing of a supplied possibility field into selected branch plus attention loss and collapse level

logic/encode.lua
  ENCODE field formation: pure deterministic source material to loss-bearing encoded field with source binding, field shape, and field intent

logic/cycle.lua
  CYCLE boundary: pure bounded continuation decision module

logic/manifest.lua
  MANIFEST assembler: pure deterministic final output assembly from substrate result, source event ids, choice/logic/cycle context, and residue summary

runtime/pressure_snapshot.lua
  RUNTIME lower pressure eye: pure read-only packet/body pressure snapshot

runtime/operator_hints.lua
  operator word pressure: switchable local pressure map for all 10 operators, derived from work mode, emitted into trace, and formatted for substrate as [procesis word] without truth promotion

runtime/system_prompt.lua
  proc-17 substrate envelope: places substrate current inside the body, binds plan/build meanings, and preserves runtime truth authority in the body

organs/repo_context.lua
  first OBSERVE-side eye: explicit file-list repo context payload through fs/sandbox

organs/repo_listing.lua
  OBSERVE-side retina: bounded runtime-confirmed repo file tree through fs/sandbox

runtime/trace_store.lua
  explicit JSONL packet trace writer

cli/procesis-body.lua
  machine-facing JSONL CLI with --fake, --deepseek, --mode, --work-mode plan/build, --repo-list, --repo-context, --hints/--no-hints debug overrides, proc-17 system prompt, work-mode-derived operator word pressure, default ENCODE field formation before CHOOSE, default CHOOSE collapse, default LOGIC boundary, default CYCLE decision, default runtime pressure snapshot, and final MANIFEST payload summary

tests/
  JSON, packet, topology, sandbox, substrate normalization, tool facade, fs tool, encode field formation, choose collapse, cycle decision, manifest assembly, runtime pressure snapshot, repo listing organ, repo selection validator, repo context organ, trace store, and CLI smoke tests
  includes mode path policy tests, operator word/system prompt tests, and operator runtime hints compatibility tests
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
repo_listing_eye: bounded_read_only_file_tree
repo_context_eye: explicit_file_list_read_only
repo_selection_validator: pure_logic_module
encode_field: pure_logic_module
encode_boundary: default_before_choose_cli_boundary
encode_shape: repo_path_field_semantic_line_field_structured_reflection_field_mixed_context_field_residue_field
choose_collapse: pure_logic_module
choose_boundary: default_on_cli_boundary
choose_collapse_level: item_path_child_section_residue
logic_boundary: default_on_cli_boundary
cycle_decision: default_on_cli_boundary
runtime_pressure_snapshot: default_on_read_only_module
growth_pipeline: documented_only_pending
trace_store: explicit_jsonl
body_modes: packet_cli_and_path_policy_implemented
work_mode: plan_build_cli_contract
operator_hints: work_mode_derived_switchable_trace_visible_prompt_pressure
procesis_word: substrate_facing_canonical_orientation_not_runtime_evidence
system_prompt: proc17_envelope_for_substrate_current
manifest_assembler: deterministic_v0_output_from_trace_material
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

Run fake machine CLI with runtime-confirmed repo context:

```text
lua cli/procesis-body.lua run --task "inspect context" --fake --jsonl --repo-context README.md,core/packet.lua
```

Run fake machine CLI with runtime-confirmed repo listing:

```text
lua cli/procesis-body.lua run --task "inspect tree" --fake --jsonl --repo-list
```

Run fake machine CLI with runtime-confirmed repo listing under prefix:

```text
lua cli/procesis-body.lua run --task "inspect docs" --fake --jsonl --repo-list docs/02_crystall
```

Run fake machine CLI with default RUNTIME lower pressure snapshot:

```text
lua cli/procesis-body.lua run --task "inspect runtime" --fake --jsonl
```

Run fake machine CLI in plan work mode:

```text
lua cli/procesis-body.lua run --task "inspect plan" --fake --jsonl --work-mode plan
```

Run fake machine CLI in build work mode:

```text
lua cli/procesis-body.lua run --task "inspect build" --fake --jsonl --work-mode build
```

Run fake machine CLI with operator runtime hints override:

```text
lua cli/procesis-body.lua run --task "inspect hints" --fake --jsonl --hints
```

Run fake machine CLI without operator runtime hints:

```text
lua cli/procesis-body.lua run --task "inspect hints" --fake --jsonl --no-hints
```

Run fake machine CLI without LOGIC boundary:

```text
lua cli/procesis-body.lua run --task "inspect logic" --fake --jsonl --no-logic
```

Run fake machine CLI without CYCLE decision:

```text
lua cli/procesis-body.lua run --task "inspect cycle" --fake --jsonl --no-cycle
```

Run fake machine CLI without RUNTIME lower pressure snapshot:

```text
lua cli/procesis-body.lua run --task "inspect runtime" --fake --jsonl --no-runtime-snapshot
```

Run DeepSeek machine CLI with default RUNTIME lower pressure snapshot:

```text
lua cli/procesis-body.lua run --task "Return one word: ok" --deepseek --jsonl
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
test_encode ok
test_choose ok
test_cycle ok
test_runtime_pressure_snapshot ok
test_repo_listing ok
test_repo_selection ok
test_repo_context ok
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

Manual DeepSeek repo listing cases:

```text
/tmp/proc-17-case-a-crystall-listing.jsonl
/tmp/proc-17-case-b-listing-context.jsonl
/tmp/proc-17-case-c-adversarial-listing.jsonl
/tmp/proc-17-case-d-insufficient-listing.jsonl
```

Observed result:

```text
repo_listing reduced absent-path invention
valid paths can still receive unsupported roles or reasons
insufficient listings can produce correct request for broader listing
next pending LOGIC boundary: repo_selection_validator
implementation hardening target: fs.list_dir internal io.popen/find
```

Manual DeepSeek cycle check:

```text
/tmp/proc-17-cycle-live.jsonl
```

Observed result:

```text
DeepSeek proposed two valid files, one absent path, and one directory
repo_selection_validator accepted the two files
repo_selection_validator rejected absent path and directory
cycle_decision returned continue with reason continuation_payable
```

Current missing integration:

```text
automatic handoff from cycle continue decision to repo_context_organ
repo_selection_validator only runs when repo_listing evidence exists
```

## Current Limits

```text
no real tool facade
no shell command tool
no directory creation in fs tool
no automatic trace persistence
no automatic repo file selection
no automatic repo selection loop yet
no automated ⋯☴⊞☴◈☴ pipeline yet
no semantic repo ranking
no TUI or human UI
no child packet execution
no real file writes; write permissions are dry-run only
real provider calls are manual, not part of normal test suite
repo listing v0 uses internal host find behind sandbox; shell is still not exposed to substrate
repo listing hardening pending
```
