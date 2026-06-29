# ENCODE / CHOOSE Shape Notes

Raw notes for the current `☵ -> ☳` problem.

This document exists because live reflection runs showed that `☵ ENCODE` and
`☳ CHOOSE` are working, but the shape between them is still too crude.

## Trigger

DeepSeek was asked what proc-17 should do next.

The answer had a structured shape:

```text
3 strongest next pressures
3 things not to implement yet
2 concrete next tests
```

The current route encoded that answer as flat lines:

```text
line:1 header
line:2 pressure
line:3 pressure
line:4 pressure
line:5 header
line:6 not-yet
line:7 not-yet
line:8 not-yet
line:9 header
line:10 test
line:11 test
```

Then `☳ CHOOSE` selected the first four lines and killed the rest.

That preserved the first section and destroyed the other two sections as active
paths.

For a file-selection task this kind of collapse can be correct.

For structured reflection it is accidental truncation.

## Important Correction

The first diagnosis was:

```text
☳ is broken
```

The better diagnosis is:

```text
☵ gave ☳ the wrong field shape
```

`☳` is deliberately stupid.

It receives a field, selects a bounded branch, and records killed alternatives.

If the field is a flat list of lines, `☳` makes a flat line collapse.

If the field is a set of repo paths, `☳` makes a repo focus collapse.

If the field is structured sections, `☳` can choose sections or preserve section
boundaries.

So the next pressure is not to make `☳` clever.

The next pressure is to make field shape explicit.

## What DeepSeek Said With CHOOSE Disabled

DeepSeek was then run with:

```text
--no-choose
```

so that the current `☳` could not cut the answer about `☳`.

DeepSeek returned:

```text
Diagnosis:
1. CHOOSE treats structured reflection as flat line field, truncating sections after first 4 lines.
2. ENCODE encodes substrate response as flat semantic_line items, losing section boundaries.
3. CLI builds candidate field directly, bypassing ENCODE's field ownership.
4. CHOOSE's max_selected=4 is hardcoded for file choice, wrong for structured reflection.

Design rules:
1. ENCODE must preserve section structure when encoding substrate responses.
2. CHOOSE must accept field_shape metadata to select sections, not just flat lines.
3. CLI must delegate field construction to ENCODE, not build fields ad hoc.

Concrete next tests:
1. Test encode preserves section headers as structured items with kind="section".
2. Test choose with section-shaped field selects whole sections, not first N lines.
3. Test CLI --no-choose passes raw ENCODE output without CHOOSE truncation.
```

This is useful pressure, not contract.

The phrase:

```text
kind="section"
```

is a possible manifestation, not yet the final shape.

## Current Pressure

The route needs to distinguish at least these field shapes:

```text
repo_path_field
semantic_line_field
structured_reflection_field
mixed_context_field
residue_field
```

They should not all collapse the same way.

## Field Intent Versus Field Shape

Two different things are currently tangled.

`field_shape`:

```text
what the field structurally is
```

Examples:

```text
flat_list
sectioned_document
repo_listing
mixed_context
residue_set
```

`field_intent`:

```text
why this field is being passed to ☳
```

Examples:

```text
select_focus
preserve_reflection
choose_next_context
rank_candidates
carry_residue
```

The same shape can be used under different intent.

Example:

```text
sectioned_document + preserve_reflection
sectioned_document + select_one_section
```

These should not have identical `☳` behavior.

## Boundary Rule

`☵` owns field formation.

`☳` owns irreversible narrowing.

If `☳` needs to understand whether it is narrowing:

```text
files
lines
sections
records
residue
```

then `☵` must expose that shape before `☳` runs.

`☳` must not infer document structure from raw text by itself.

That would make `☳` a hidden parser/planner.

## Section Boundary Problem

Structured reflection contains boundaries that are not alternatives.

Example:

```text
3 strongest next pressures
3 things not to implement yet
2 concrete next tests
```

Those section labels are not competing branches.

They are parts of one answer form.

If `☳` treats them as alternatives, it kills necessary context.

So:

```text
not every item in field.items is a peer alternative
```

Some items are:

```text
containers
headers
constraints
children
evidence
```

## CHOOSE Should Still Kill

This pressure must not soften `☳`.

`☳` must still create loss.

The correction is not:

```text
keep everything
```

The correction is:

```text
kill at the right structural level
```

For repo paths:

```text
kill unselected paths
```

For structured reflection:

```text
possibly kill whole sections
or keep all required sections and choose within each section
```

The policy depends on field intent.

## Raw Questions

```text
how should ☵ represent section boundaries?
does field.items stay flat with parent ids, or become nested?
does ☳ select sections, children, or both?
can field_intent stay pressure-only before it becomes a formal field?
should max_selected mean selected items, selected sections, or selected branches?
how does killed_alternatives represent children of killed sections?
what is the minimum shape that fixes reflection without overbuilding?
```

## Current Non-Goal

No code yet.

No router yet.

No model switching yet.

No semantic repo ranking yet.

This pass is only:

```text
⋯ chaos
⊞ table
◈ crystal
```

for `☵ ENCODE` and `☳ CHOOSE`.
