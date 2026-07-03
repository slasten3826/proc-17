# Build Mode Hod Yesod Architecture Notes

Status:

```text
chaos
build-mode only
```

## Trigger

`☶ HOD` and `☱ YESOD` were reread from `slop.raw.txt`.

Old Lua ProcessLang was checked:

```text
/home/slasten/work/slastack/slastack/10-table/stack-core/ProcessLang/lua
```

The conclusion:

```text
☶☱ executable architecture belongs to build mode, not plan mode
```

## Why Build Only

Plan mode should shape intent, structure, alternatives, and residue.

Plan mode should not execute spells.

If plan mode starts running tests, writing files, reinforcing patterns, or
making runtime truth, it stops being plan mode.

Build mode is where words must touch reality.

So:

```text
plan mode  = ⋯⊞◈
build mode = ◈▲ with ☶☱ active
```

## HOD Reading

`slop.raw.txt` says:

```text
HOD = desire -> spell/code/ritual -> execution -> reality changed
```

For proc-17:

```text
☶ is not generic reasoning
☶ is spell execution and validation
```

Examples:

```text
py_compile(file)
run smoke command
validate json
check sandbox path
apply guarded file write
validate repo path
run unit suite
```

If nothing touches runtime reality, it is not full `☶`.

## YESOD Reading

`slop.raw.txt` says:

```text
HOD spell repeated -> YESOD foundation
```

For proc-17:

```text
☱ should reinforce successful/failed build patterns
```

Required ideas:

```text
spell_hash
repetition_count
strength
stability
foundation_state
runtime_eternal / stable_runtime
```

`☱` should not be human memory.

It should be runtime foundation: what the body no longer has to rediscover.

## What Old Lua ProcessLang Gives

Useful old primitives:

```text
LOGIC.validate(value, rules)
LOGIC.rule(check_fn, message)
RUNTIME.context(initial)
RUNTIME.snapshot()
RUNTIME.rollback(snapshot)
RUNTIME.safe(fn, fallback)
RUNTIME.machine(states, initial)
CYCLE.until_stable(value, fn, predicate, max_iter)
ENCODE.freeze(t)
MANIFEST.seal(value)
```

Do not copy blindly.

But the primitives are the right shape.

## Current Gap

Current proc-17:

```text
☶ in tension_runner is placeholder accepted
☱ records snapshot only
☲ can say stop_repetition
router still loops through ☱☲ until tick_limit
```

Observed failure:

```text
build+QA loop generated code
longer cycle introduced regression
☶ did not run tests as spell
☱ did not reinforce test evidence
☲ kept saying more/stop without executable grounding
```

## Build Mode Target

In build mode, the lower triangle should become:

```text
☲ asks for continuation
☶ runs executable spells
☱ records and reinforces runtime evidence
△ manifests final artifact or residue
```

Plan mode should not activate this full loop.

## First Build-Mode Spells

Start small:

```text
py_compile_python_file
run_cli_smoke_commands
validate_json_file
check_command_exit_code
check_file_exists
```

Each spell result should have:

```text
name
intention_hash
command/code
executed
success
reality_changed
stdout
stderr
exit_code
```

Then `☱` can reinforce:

```text
success pattern
failure pattern
regression pattern
```

## Rule

```text
No build-mode cycle without runtime evidence.
```

If `☲` wants another turn, `☶` must provide evidence.

If evidence repeats or fails, `☱` decides whether to stabilize, manifest, or
stop as residue.

