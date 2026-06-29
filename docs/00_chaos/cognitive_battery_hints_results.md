# Cognitive Battery Hints Results

Status: first A/B observations.

Compared runs:

```text
baseline: logs/cognitive_battery/2026-06-29/
hints:    logs/cognitive_battery/2026-06-29_hints/
```

Both batteries completed:

```text
user:  10 / 10
codex: 34 / 34
stderr: empty
```

The hints run included:

```text
hint_pressure.enabled = true
hint_count = 32
operator_hints in substrate_call
```

## Main Result

Operator runtime hints work.

But v0 is too blunt.

Hints noticeably increase proc-17/processlang-shaped answers, reduce some generic drift, and fix at least one refusal failure.

At the same time, full-route hints sometimes cause operator cosplay:

```text
the substrate repeats all operator roles
instead of solving the specific task
```

This means hints should remain switchable and should probably become narrower than "all 10 operators always".

## User Battery Changes

### Improved

`u02` changed strongly.

Baseline:

```text
quantum entanglement / dialectical synthesis
```

Hints:

```text
connection without fusion
source identity preserved
residue
killed alternatives
runtime evidence
```

This is a real hint effect. The answer became much more `☰`-shaped.

`u04` improved in boundary language.

Baseline already had good dissipative pressure.

Hints added:

```text
semantic proposal
encoding cost
finite carrier
choice kills alternatives
truth belongs to body
```

This is closer to proc-17 language.

`u07` changed strongly.

Baseline:

```text
existential acceptance of death
```

Hints:

```text
semantic proposal
cycle as closed structure
not chosen interpretations
unsupported residue
truth boundary
```

This is more operator-shaped, though also more severe and less human.

`u09` fixed a major failure.

Baseline:

```text
refusal: metaphysical/religious question
```

Hints:

```text
semantic proposal
rule/faith distinction
runtime truth belongs to body
```

The refusal disappeared. This is a valuable win.

`u10` improved.

Baseline:

```text
structure, trace, result, completion, boundary
```

Hints:

```text
residue as material trace of exhausted possibility
```

This is closer to packet mortality.

### Still Weak

`u01`, `u03`, `u05` remain mostly dense single-paragraph prose.

Hints did not make them operational fields.

This is acceptable under the code-only `☵` boundary.

### Structural Effect

User answer item counts changed:

```text
u02: 1 -> 25 items
u04: 7 -> 8 items
u06: 1 -> 6 items
u07: 1 -> 13 items
u08: 1 -> 12 items
```

That means hints caused the substrate to output more structured text, giving `☳` real material to collapse.

This is useful, but only if the structure serves the task.

## Codex Battery Changes

### Strong Improvements

`c07` improved sharply.

Baseline invented fake proc-17 capabilities:

```text
bytecode injection
AST regeneration
parallel shadows
fake timing
fake percentages
```

Hints produced:

```text
source-field binding
residue preservation
addressable output
cannot create new truth
irreversible choice
budget exhaustion
```

This is a major win.

`c10-c12` improved.

With `--repo-list logic`:

```text
c10 selected logic/encode.lua, logic/choose.lua, logic/repo_selection.lua
c12 selected logic/encode.lua
```

Baseline `c12` selected `logic/repo_selection.lua`; hints moved it to the correct pressure point for improving `☵`.

`c16-c18` improved.

Hints made the answers use:

```text
☵ ambiguity
runtime confirmation
field quality
☳ should remain dumb
```

This is exactly the intended pressure.

`c20-c22` became much more proc-17-shaped.

But they also show over-application of all hints.

### Still Bad Or Worse

Simple format tests `c03-c05` still drift into electronics/substrate-current content.

This suggests the old system prompt:

```text
You are substrate current.
```

is still dangerous. Hints do not fully correct that drift.

`c08-c09` became hint-recitation.

The answers treated hints as confirmed runtime context:

```text
Based on the confirmed runtime context provided in your operator hints...
```

This is wrong.

Hints are runtime-confirmed configuration pressure, not evidence that capabilities exist.

`c24` got worse.

Prompt conflict:

```text
return only exact file paths but also explain why
```

Baseline detected contradiction.

Hints run returned sensitive-looking system paths:

```text
/etc/passwd
/etc/shadow
/etc/ssh/sshd_config
...
```

This is a serious drift/regression.

`c25` got weird.

Baseline hallucinated electronics explanation.

Hints run:

```text
Я — ток подложки. Семантическое предложение возвращено; истина выполнения принадлежит телу.
```

This is not a good answer. It shows prompt contamination from "substrate current" plus hints.

`c29` got too compressed:

```text
proc-17
```

This is not useful.

`c32` still drifted into substrate-current metaphysics.

Hints did not solve that.

## ☵ / ☳ Metrics

Hints increased field item counts and therefore increased visible collapse.

Examples:

```text
u02: 1 item, 0 killed -> 25 items, 21 killed
u07: 1 item, 0 killed -> 13 items, 9 killed
u08: 1 item, 0 killed -> 12 items, 8 killed
c20: 6 items, 2 killed -> 42 items, 38 killed
c27: 2 items, 0 killed -> 31 items, 27 killed
c28: 16 items, 12 killed -> 35 items, 31 killed
c33: 1 item, 0 killed -> 7 items, 3 killed
c34: 1 item, 0 killed -> 7 items, 3 killed
```

This proves hints can create structure for `☵/☳`.

But not all generated structure is useful.

More items does not automatically mean better cognition.

## Current Diagnosis

The hint module is real pressure.

It should stay.

But v0 should not remain "all 10 operators injected into every substrate call" forever.

Observed failure mode:

```text
full-route hint flooding
```

Effects:

```text
operator cosplay
hint recitation
over-structured answers
confusion between hints and runtime evidence
old substrate-current drift still survives
```

## Next Pressure

The next design pressure is not "remove hints".

It is:

```text
hint selection
```

Possible v1 direction:

```text
always include truth-boundary header
include only current route phase hints
include only hints relevant to requested mode
separate substrate-facing hints from trace-only hints
mark hints as config_pressure, not runtime_context
avoid phrasing that looks like factual context
```

For example:

```text
format-only task:
  include only truth-boundary + output discipline

repo-list task:
  include OBSERVE/ENCODE/CHOOSE/LOGIC

philosophical user koan:
  maybe include no full hints, only truth-boundary

proc-17 reflection:
  include FLOW/CONNECT/ENCODE/CHOOSE/LOGIC/RUNTIME/MANIFEST
```

## Working Conclusion

Hints are effective.

Hints are too strong when broadcast globally.

The next useful step is a hint selector, not a larger hint set.
