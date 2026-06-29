# ENCODE Quality Before CHOOSE Notes

Raw notes after the first `☵/☳` manifestation.

## Current Realization

The live problem is not:

```text
☳ is too stupid
```

The better frame is:

```text
☵ gives ☳ incomplete or dirty field information
```

`☳ CHOOSE` should remain stupid.

It is not a text-understanding organ.

It is not a planner.

It is not a semantic repair layer.

It is an irreversible collapse organ.

## Working Analogy

Rough analogy:

```text
☵ = investigator / protocol writer
☳ = executioner / collapse worker
```

Or:

```text
☵ prepares the case file
☳ executes the cut
```

If the case file is bad, the cut is bad.

If the case file is precise, even a stupid cut can be correct.

## Operator Boundary

`☴ OBSERVE`:

```text
sees raw material
```

`☵ ENCODE`:

```text
turns raw material into explicit field form
```

`☳ CHOOSE`:

```text
cuts alternatives inside that form
```

So the current route should be read as:

```text
☴ sees substrate text
☵ writes field protocol
☳ cuts according to protocol
```

Not:

```text
☴ sees text
☳ understands text and chooses
```

## What ☵ Must Make Visible

`☵` must expose:

```text
field shape
field intent
section boundaries
parent/child relations
which items are alternatives
which items are headers
which items are evidence
which items are constraints
source truth
content truth
encoding truth
loss
```

Without these, `☳` can only cut by accidental surface order.

## What ☳ Should Not Do

`☳` must not:

```text
parse raw text
infer hidden sections
repair bad field structure
guess author intent
validate claims
promote semantic reasons to runtime truth
avoid killing because it is unsure
```

If `☳` starts doing those things, it becomes hidden `☵`, hidden `☶`, or hidden
planner.

That would blur the body.

## Current V0 Limitation

Current `☵` detects explicit section headers only when they appear as separate
lines ending with `:`.

Works:

```text
3 strongest next pressures:
field shape
collapse level
section boundary
```

Does not yet work:

```text
3 strongest next pressures: field shape, collapse level, section boundary
```

The second form remains `semantic_line_field`.

This is acceptable as v0, because inline section parsing is riskier.

Many ordinary sentences contain colons.

If `☵` parses every colon as section structure, it may hallucinate hierarchy.

## New Pressure

The next pressure is:

```text
☵ quality
```

Not:

```text
☳ intelligence
```

Better `☵` means:

```text
cleaner field shape
less accidental collapse
better source preservation
clearer hierarchy
explicit uncertainty when shape is ambiguous
```

## Dirty Field Cases

Possible dirty field cases:

```text
inline sections
mixed evidence and claims
headers with payload on same line
numbered lists that are not sections
colon sentences that are not sections
LLM output that ignores requested format
repo paths mixed with explanations
runtime-confirmed context mixed with semantic proposal
```

`☵` must not pretend all of these are the same.

## Possible Future ☵ Behavior

For ambiguous inline sections, `☵` might:

```text
keep semantic_line_field
set hierarchy_loss = true
set possible_shape = structured_reflection_field
record ambiguous_structure pressure
avoid promoting inferred hierarchy to runtime truth
```

This would let `☱ RUNTIME` see that the body had structure pressure but did not
trust it enough to form sections.

## Important Non-Goal

Do not solve this by making `☳` parse inline text.

Do not solve this by asking the substrate to always format perfectly.

Substrate formatting is pressure, not contract.

The body should benefit from good formatting but survive bad formatting.

## Next Question For DeepSeek

Ask with `☳` disabled:

```text
Given that ☳ should stay stupid and ☵ must improve field quality,
what should ☵ do next?
```

The answer should remain semantic proposal.

No code until the pressure is clear.
