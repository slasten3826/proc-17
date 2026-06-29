# DeepSeek Next Pressure Notes

Raw notes from asking DeepSeek what should come next after the third
development day.

Date:

```text
2026-06-29
```

Trace file:

```text
/tmp/proc17-next-deepseek.jsonl
```

Context supplied:

```text
docs/03_manifest/current_state.md
docs/00_chaos/reflection_model_tests_notes.md
docs/00_chaos/encode_operator_notes.md
docs/02_crystall/blueprints/connect_dissolve_encode.v0.md
```

## Task

```text
You are entering proc-17 after its third development day.
Read only the runtime-confirmed repo context.
Reflect on what should be done next.
Return exactly 8 short lines:
  3 strongest next pressures
  3 things not to implement yet
  2 concrete next tests
Do not invent files or features outside the provided context.
```

## DeepSeek Result

```text
3 strongest next pressures:
Automatic handoff from cycle continue decision to repo_context_organ is missing.
ENCODE operator needs to become a visible module, not CLI ad hoc field building.
Substrate selection should become runtime pressure, not CLI folklore.

3 things not to implement yet:
substrate_profile, substrate_router, field_intent organs.
Real tool facade, shell command tool, or directory creation.
Automatic repo file selection or semantic repo ranking.

2 concrete next tests:
Test that cycle continue decision triggers repo_context_organ call.
Test that logic/encode.lua produces correct encoded_field_payload from repo_listing entries.
```

## Immediate Reading

The strongest useful pressure was:

```text
☲ continue should be able to produce the next ☴ observation step
```

Current `☲ CYCLE` can say continuation is payable.

But the route still ends at `△`.

So continuation is visible, but not yet operational.

This does not necessarily require a large new organ.
It may first require a small integration test:

```text
when ☲ decision = continue,
the body can perform one additional bounded observation step
```

## ENCODE Correction

DeepSeek said:

```text
ENCODE operator needs to become a visible module, not CLI ad hoc field building.
```

This is partly stale.

`logic/encode.lua` already exists.

But the pressure is still useful.

What must be checked:

```text
CLI must not secretly build possibility fields outside ☵
☵ must own field formation
☳ must receive formed fields, not raw CLI leftovers
```

So the next action here is not "create ENCODE".

The next action is:

```text
audit route ownership around ☵ -> ☳
```

## Substrate Pressure

DeepSeek named:

```text
substrate selection should become runtime pressure, not CLI folklore
```

This agrees with previous live tests.

But DeepSeek also correctly said not to implement:

```text
substrate_profile
substrate_router
field_intent
```

So this stays raw pressure.

No router yet.

## CHOOSE Distortion

The run exposed a problem in current `☳ CHOOSE`.

The answer had structure:

```text
3 strongest next pressures
3 things not to implement yet
2 concrete next tests
```

But current `☵` encoded it as flat semantic lines:

```text
line:1 header
line:2 pressure
line:3 pressure
line:4 pressure
line:5 header
line:6 do-not-implement
line:7 do-not-implement
line:8 do-not-implement
line:9 header
line:10 test
line:11 test
```

Then `☳` used:

```text
max_selected = 4
```

and selected only:

```text
line:1
line:2
line:3
line:4
```

The rest became killed alternatives.

This means:

```text
☳ preserved first section
☳ killed "not yet" boundaries
☳ killed concrete tests
```

For file choice this may be correct.

For structured reflection this is wrong pressure.

## Current CHOOSE Problem

Current `☳` is too line-shaped.

It treats every field as:

```text
flat ordered alternatives
```

But some fields are:

```text
sections
records
claims with constraints
tests
warnings
repo paths
```

Choosing four lines from a structured reflection is not real choice.

It is accidental truncation.

## Working Hypothesis

The problem may not be inside `logic/choose.lua`.

`logic/choose.lua` is deliberately stupid:

```text
receive field
rank
select up to limit
record killed alternatives
```

The problem may be before it:

```text
☵ gives ☳ the wrong field shape
```

If `☵` gives a flat line field, `☳` makes a flat line collapse.

If `☵` gives a structured field, `☳` can collapse structured alternatives.

## Raw Pressure

Possible future pressure:

```text
field_shape
field_intent
structured_reflection_field
section_preserving_encode
choice_mode
```

Do not implement these yet.

First ask the substrate with `☳` disabled.

The question must not be cut by the current `☳` while asking how to fix `☳`.

## Next Test

Run DeepSeek with:

```text
--no-choose
```

and ask:

```text
what should be done with ☳ CHOOSE,
given that flat line collapse killed important reflection sections?
```

The output should remain `semantic_proposal`.

No `☳` event should appear.
