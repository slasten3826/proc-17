# Build Mode Hod Yesod Yellowprint v0

Status:

```text
table
build-mode only
no code yet
```

Source chaos:

```text
docs/00_chaos/build_mode_hod_yesod_architecture_notes.md
```

## Scope

This yellowprint defines the build-mode lower triangle:

```text
☲ CYCLE
☶ LOGIC/HOD
☱ RUNTIME/YESOD
△ MANIFEST
```

It must not activate in plan mode.

Plan mode remains:

```text
shape intent
form field
choose/collapse
produce plan/residue
```

Build mode adds:

```text
execute spells
collect runtime evidence
reinforce foundation patterns
manifest artifact/residue
```

## Build-Mode Law

```text
No build-mode cycle without runtime evidence.
```

If `☲` says another turn is needed, the next lower-body movement must be
grounded by `☶` evidence or `☱` foundation pressure.

Do not let build mode become:

```text
ask LLM again
ask LLM again
ask LLM again
```

That creates plausible regressions.

## ☶ HOD Shape

`☶` is spell execution and validation.

It should not be generic reasoning.

Minimum spell result:

```text
kind = spell_result
name
intention_hash
command_or_code
executed
success
reality_changed
stdout
stderr
exit_code
truth_status = runtime_confirmed
```

First spell kinds:

```text
py_compile_python_file
run_cli_smoke_commands
validate_json_file
check_command_exit_code
check_file_exists
```

Existing code that already belongs near `☶`:

```text
logic/repo_selection.lua
core/sandbox.lua
tools/fs.lua
```

## ☱ YESOD Shape

`☱` is runtime foundation, not memory prose.

It should see spell results and reinforce patterns.

Minimum foundation pattern:

```text
spell_hash
name
repetition_count
success_count
failure_count
strength
stability
last_result
```

Minimum foundation state:

```text
fluid
crystallizing
stable_runtime
collapsing
```

`☱` should answer:

```text
is this build pattern stable?
is this a repeated failure?
is this ready to manifest?
should this stop as residue?
```

## ☲ CYCLE Shape In Build Mode

`☲` remains cheap.

It does not run tests.

It does not decide correctness.

It can say:

```text
again
stop_complete
stop_repetition
stop_budget
stop_invalid
needs_user_input
```

But build-mode routing must respect stop decisions.

If `☲` returns:

```text
stop_repetition
stop_budget
stop_invalid
stop_unsafe
needs_user_input
```

then `☱` must not route back to another bare `☲`.

It should route toward:

```text
△ manifest residue
☴ semantic uncertainty
☶ validation/spell if evidence is missing but can be obtained
```

## Mode Separation

Build mode enables:

```text
☶ spell execution
☱ foundation reinforcement
runtime evidence required for repeated cycles
```

Plan mode disables:

```text
spell execution
foundation reinforcement
file writes
test execution
stable runtime promotion
```

Plan mode may still describe future spells as proposed work units.

It must not execute them.

## Packet Fields Needed Later

Likely additions:

```text
packet.boundary.spells
packet.runtime.foundation
packet.runtime.patterns
packet.runtime.snapshots
packet.runtime.rollback_points
packet.tension.runtime_evidence
```

Do not add all blindly.

Implement only the first fields needed for build-mode evidence.

## First Useful Build Loop

Target loop for generated Python code:

```text
☴ observe substrate code
☵ encode code artifact
☳ choose artifact/action
☱ runtime sees build mode
☶ py_compile spell
☱ reinforce compile evidence
☶ smoke commands spell
☱ reinforce smoke evidence
☲ decide continuation
☱ route to △ when stable or stopped
△ manifest code + evidence + residue
```

This is the shape that would have caught the habit-tracker regression.

## Non-Goals

Do not implement full organogenesis.

Do not make `☱` an LLM memory.

Do not let `☶` become a generic "think harder" module.

Do not run build-mode spells in plan mode.

