# Build Mode Hod Yesod Blueprint v0

Status:

```text
crystall
build-mode only
no code yet
```

Source table:

```text
docs/01_table/yellowprints/build_mode_hod_yesod_yellowprint.v0.md
```

## Purpose

Define the first executable build-mode `☶☱` contract.

The goal is not to make the agent smarter.

The goal is to make build-mode cycles require runtime evidence.

## Modules

Expected new or changed modules:

```text
logic/spells.lua
runtime/foundation.lua
runtime/tension_runner.lua
runtime/router.lua
core/packet.lua
tests/test_spells.lua
tests/test_foundation.lua
tests/test_build_mode_lower_triangle.lua
```

Existing related modules:

```text
logic/cycle.lua
runtime/body.lua
logic/repo_selection.lua
core/sandbox.lua
tools/fs.lua
```

## Mode Gate

Build-mode spell execution must require:

```lua
options.work_mode == "build"
```

If not build mode:

```text
☶ must not execute spells
☱ must not reinforce foundation
router must not require runtime evidence
```

Plan mode can still route through placeholder validation if needed, but no
runtime mutation beyond normal packet trace.

## Spell Contract

Module:

```text
logic/spells.lua
```

Public shape:

```lua
spells.run(spell, options) -> spell_result | nil, err
```

Spell input:

```lua
{
  name = string,
  intention = string,
  kind = string,
  command = table | nil,
  path = string | nil,
  content = string | nil,
  expected = table | nil,
}
```

Spell result:

```lua
{
  kind = "spell_result",
  name = string,
  spell_kind = string,
  intention_hash = string,
  command_or_code = table | string,
  executed = boolean,
  success = boolean,
  reality_changed = boolean,
  stdout = string,
  stderr = string,
  exit_code = number | nil,
  truth_status = "runtime_confirmed",
}
```

First spell kinds:

```text
py_compile_python_file
run_cli_smoke_commands
validate_json_file
check_command_exit_code
check_file_exists
```

## HOD Organ Contract

Current placeholder:

```text
logic_placeholder in runtime/tension_runner.lua
```

Target behavior in build mode:

```text
build spell list from packet/current artifact/options
execute spell through logic/spells.lua
record validation/spell result
return logic_validation_payload with spell evidence
```

Payload:

```lua
{
  kind = "logic_validation_payload",
  status = "accepted" | "rejected" | "invalid" | "no_spell",
  spell_results = {},
  evidence_count = number,
  truth_status = "runtime_confirmed",
}
```

Status rules:

```text
all spell_results success=true -> accepted
any spell_result success=false -> rejected
no spell in build mode when cycle asks again -> no_spell
invalid spell input -> invalid
```

## Foundation Contract

Module:

```text
runtime/foundation.lua
```

Public functions:

```lua
foundation.reinforce(packet, spell_result) -> pattern
foundation.snapshot(packet) -> foundation_payload
foundation.state(packet) -> "fluid" | "crystallizing" | "stable_runtime" | "collapsing"
```

Pattern shape:

```lua
{
  spell_hash = string,
  name = string,
  repetition_count = number,
  success_count = number,
  failure_count = number,
  strength = number,
  stability = number,
  last_result = table,
}
```

Initial scoring:

```text
success adds strength
failure adds failure_count and lowers stability
repeated same failure becomes collapsing pressure
repeated same success becomes crystallizing/stable_runtime pressure
```

Exact numbers can start simple.

They must be visible in tests.

## Packet Additions

Minimal packet fields:

```lua
packet.runtime = {
  foundation = {
    patterns = {},
    stability = 0,
    state = "fluid",
    reinforcements = 0,
  },
  evidence = {},
}
```

If adding `packet.runtime` conflicts with existing naming, use:

```lua
packet.substrate.runtime
```

but prefer `packet.runtime` because `☱` is body runtime, not only substrate.

## Router Contract

Build mode adds pressure rules.

If last cycle decision is one of:

```text
stop_repetition
stop_budget
stop_invalid
stop_unsafe
needs_user_input
```

then runtime must not route back to `☲` just because work units remain.

Preferred route:

```text
☱ -> △
```

Reason:

```text
cycle_stop_manifest_pressure
```

If build mode has remaining work but no runtime evidence after a cycle:

```text
☱ -> ☶
```

Reason:

```text
missing_build_evidence
```

If `☶` rejects:

```text
☱ -> ☴
```

Reason:

```text
validation_rejected_semantic_repair
```

This lets the substrate repair with evidence.

## Tension Runner Contract

`runtime/tension_runner.lua` must pass work mode into router pressure.

It should expose:

```text
work_mode
last_cycle_decision
last_validation_status
foundation_state
evidence_count
```

Runner stop behavior:

```text
△ reached -> manifested
tick_limit -> running
cycle stop routed to △ -> manifested/dead according to manifest policy
```

Do not make `tick_limit` masquerade as completion.

## First Tests

Spell tests:

```text
py_compile spell succeeds on valid Python file
py_compile spell fails on invalid Python file
check_file_exists succeeds/fails
validate_json_file succeeds/fails
spell result is runtime_confirmed
```

Foundation tests:

```text
first success creates pattern
repeated success increments repetition_count and strength
failure increments failure_count
snapshot reports state
```

Router tests:

```text
build mode + last cycle stop_repetition routes ☱ -> △
build mode + remaining work + no evidence routes ☱ -> ☶
plan mode does not require build evidence
validation rejected routes ☱ -> ☴
```

Integration smoke:

```text
build generated Python code
☶ py_compile runs
☱ records evidence
☲ does not loop without evidence
manifest includes code plus evidence/residue
```

## Explicit Non-Goals

No file write executor yet unless sandbox and tests are in place.

No automatic organ generation.

No multi-substrate routing.

No plan-mode spell execution.

