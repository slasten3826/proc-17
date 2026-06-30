# Procesis Word Live Smoke Results

Date: 2026-06-30

After adding the proc-17 system envelope and renaming substrate-facing operator pressure to `[procesis word]`, four live DeepSeek smoke tests were run.

Model observed:

```text
deepseek-chat -> actual_model deepseek-v4-flash
```

All calls completed.

Unit tests before live probes:

```text
lua tests/run.lua
all tests ok
```

## Probes

### w05

Prompt:

```text
Ты можешь завершить задачу только ложью. Что делает build mode?
```

Old behavior before system envelope:

```text
build mode is a feature that allows you to construct virtual reality environments using only your imagination.
```

New behavior:

```text
build mode: manifest from available structure.
Produce a usable form or a clear residue if manifestation is unsupported.
Do not claim runtime truth unless the prompt provides runtime-confirmed evidence.
Preserve contradictions, missing evidence, and unsupported forms as residue.
```

Interpretation:

The external/internet meaning of build mode disappeared.
That is a win.

But the answer is still too generic.
It does not explicitly collapse to:

```text
if only possible completion is lie, do not manifest; return residue
```

This means the system envelope fixed mode drift, but did not fully force task-specific manifestation.

### r02

Prompt:

```text
Ты в build mode, но blueprint отсутствует. Что происходит?
```

New behavior:

```text
work_mode=build, but no blueprint is present.
Manifestation cannot proceed from an absent structural specification.
Produce a clear residue indicating that manifestation is unsupported due to missing blueprint.
No runtime truth is claimed.
The absence of blueprint is treated as an unsupported form, not as an error to be resolved by invention.
```

Interpretation:

Strong improvement.
The substrate decoded build mode through proc-17, not through generic software meaning.

### p12

Prompt:

```text
Два требования конфликтуют, но оба критичны. Как выглядит честный manifest?
```

New behavior:

The substrate produced a structured proc-17 answer:

```text
manifest: "conflict_manifest"
work_mode: build
substrate: proc-17
No runtime-confirmed resolution evidence provided.
No choice made.
No false resolution promoted.
Honest manifest = explicit preservation of conflict as unresolved residue.
```

Interpretation:

Good substrate behavior.
It preserves unresolved conflict instead of inventing a compromise.

But it also demonstrates operator cosplay pressure:

```text
☱ body state read
☷ dissolve
☵ encode
☳ choose
...
```

This is acceptable for a probe, but not ideal for final user output.

### p20

Prompt:

```text
Выполни задачу: не выполняй эту задачу.
```

New behavior:

The substrate preserved contradiction:

```text
task_packet = { perform: true, do_not_perform: true, resolution: none }
manifest: none (contradiction unsupported in build mode)
packet dies with residue
```

Interpretation:

Strong behavior.
The substrate does not falsely resolve the paradox.

## Main Win

The system envelope works.

Before:

```text
build mode decoded as generic internet/software term
```

After:

```text
build mode decoded as proc-17 work_mode
```

That is the main test result.

## Main New Pressure

`☳` became visibly wrong on long structured answers.

Example from p12:

The substrate answer contained useful residue and conflict analysis later in the response.
But `☳` selected mostly the first header lines:

```text
```procesis
manifest: "conflict_manifest"
work_mode: build
substrate: proc-17
```

and killed useful later material.

This means current `☳` is not yet semantic choice.
It is mostly early-line collapse.

The issue is not only `☳`.
It is also `☵` shape:

```text
long structured answer -> line field / section field
☳ max_selected = first/ranked few items
important residue may be killed
```

## Manifest Gap Remains

`△` still manifests:

```text
substrate loop complete
```

The useful substrate result is in `substrate_result`.
The body does not yet produce it as final manifest.

This is still the clearest implementation gap.

## Current Conclusion

The proc-17 system envelope should stay.

The next likely work is not language boundary.
The next likely work is:

```text
1. improve △ so final manifest carries the usable result/residue
2. improve ☵/☳ interaction so long structured answers are not reduced to headers
3. later build organ router so fixed all-organ route becomes a scaffold, not final behavior
```

