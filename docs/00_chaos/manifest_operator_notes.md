# Manifest Operator Notes

Date: 2026-06-30

`△ MANIFEST` has been underbuilt.

Until now it mostly closed the packet:

```text
substrate loop complete
```

That is not enough.

`△` should be the last assembler.
It should gather what the body already has and produce the visible outer form.

## Current Problem

The body already contains useful material:

```text
substrate_result.text
☵ encoded_field
☳ selected / killed alternatives
☶ validation boundary
☲ continuation decision
☱ runtime pressure snapshot
death residue
```

But the final manifest ignores most of it.

This creates a split:

```text
inside trace: useful answer exists
outside output: substrate loop complete
```

That means the packet thinks, but the mouth only says that processing ended.

## What Manifest Should Do

Manifest should not think again.
Manifest should not call the substrate.
Manifest should not invent new truth.

Manifest should assemble:

```text
visible output
output type
source event ids
validation state
choice pressure summary
residue
```

Manifest is the last beautiful collector.

## First Simple Version

For v0, keep it deterministic:

```text
if substrate text has python/code fence -> output.type = code
else if work_mode == plan -> output.type = plan
else if substrate text says manifest none / unsupported / residue -> output.type = residue
else -> output.type = text
```

Output text is the substrate text.

The body does not claim the substrate text is runtime truth.
The runtime-confirmed fact is:

```text
this is the selected visible output assembled from known trace material
```

not:

```text
every claim in the text is true
```

## Source Binding

Manifest should record:

```text
substrate_result_event
encoded_field_event
choice_event
validation_event
cycle_event
runtime_snapshot_event
```

Missing sources should be explicit but not fatal.

## Residue

Manifest should preserve simple residue:

```text
assumptions found in text
unsupported markers
missing markers
choice killed count
validation result
```

In v0 this can be shallow.
Later it can become a real residue compiler.

## Final Envelope

The final JSONL envelope should include a compact manifest summary.

Currently final only says:

```text
status=dead
residue=...
```

That makes machine readers scan trace manually.

Better:

```text
status=dead
manifest={type, text/source summary}
residue=...
```

Trace remains the full truth.
Final envelope becomes the convenient outer surface.

## Boundary

`△` is allowed to output code as text.

`△` is not yet allowed to write files unless the body has an explicit write tool path and permissions.

For now:

```text
manifest output != filesystem write
```

Writing files is a later MANIFEST capability.

