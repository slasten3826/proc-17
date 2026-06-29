# ENCODE Quality Blueprint v0

This blueprint defines the first quality contract for:

```text
☵ ENCODE
```

It extends:

```text
connect_dissolve_encode.v0.md
encode_choose_shape.v0.md
```

It does not change the `☳ CHOOSE` contract.

## Primary Rule

`☵` must not only produce a field.

`☵` must report the quality of the field shape it produced.

If source material appears structured but cannot be safely encoded as structure,
`☵` must expose that ambiguity instead of pretending the field is clean.

## Non-Goal

This blueprint does not require:

```text
large parser
inline section parser
LLM interpretation
substrate repair call
semantic validation
smarter ☳
```

The goal is not to understand every format.

The goal is to avoid hiding structure pressure.

## Field Quality Contract

`encoded_field_payload.field` may include:

```text
structure_status
possible_shape
structure_pressure
```

Allowed `structure_status` values:

```text
clean_structure
flat_structure
ambiguous_structure
mixed_truth_structure
residue_structure
```

Allowed `structure_pressure` values:

```text
inline_section_candidate
mixed_evidence_and_claims
format_contract_drift
colon_sentence
numbered_list_without_section_boundary
```

`possible_shape` is optional and must remain a pressure hint.

It must not promote the field to that shape.

## Required Behavior

### Clean Structure

When source text has explicit section headers:

```text
Header:
child
child
```

`☵` should emit:

```text
field.shape = structured_reflection_field
field.intent = preserve_reflection
field.structure_status = clean_structure
loss.hierarchy_loss = false
```

### Flat Structure

When no structure pressure is visible:

```text
line one
line two
line three
```

`☵` should emit:

```text
field.shape = semantic_line_field
field.intent = rank_candidates
field.structure_status = flat_structure
loss.hierarchy_loss = false
```

### Ambiguous Structure

When text appears section-like but boundaries are not safe:

```text
Header: child A, child B, child C
```

`☵` should emit:

```text
field.shape = semantic_line_field
field.intent = rank_candidates
field.possible_shape = structured_reflection_field
field.structure_status = ambiguous_structure
field.structure_pressure = inline_section_candidate
loss.hierarchy_loss = true
```

This means:

```text
structure pressure existed
☵ did not trust it enough to form hierarchy
☳ must still receive an honest field
☱ can see that hierarchy was lost
```

### Mixed Truth Structure

When runtime-confirmed context and semantic proposal content share a field:

```text
repo_context + substrate_result
```

`☵` should emit:

```text
field.shape = mixed_context_field
field.intent = choose_next_context
field.structure_status = mixed_truth_structure
field.truth_status = mixed
```

### Residue Structure

When dissolved or unsupported residue is encoded:

```text
dissolved_records
unsupported_residue
```

`☵` should emit:

```text
field.shape = residue_field
field.intent = carry_residue
field.structure_status = residue_structure
```

## Intent Source Contract

`field.intent` is chosen by priority:

```text
1. explicit route pressure intent
2. clean structure intent
3. source-kind default intent
4. semantic fallback intent
```

Route pressure may set intent.

Route pressure must not:

```text
change source_truth_status
change content_truth_status
validate semantic content
force ambiguous structure into clean structure
```

## Loss Contract Extension

`hierarchy_loss` means:

```text
structure pressure existed but was not safely encoded as hierarchy
```

It must not mean:

```text
generic uncertainty
low confidence
semantic disagreement
bad model output by itself
```

When `hierarchy_loss = true`, the field should explain why through:

```text
structure_status
structure_pressure
possible_shape
```

## CHOOSE Boundary

`☳` must not parse or repair ambiguous structure.

For ambiguous structure, `☳` receives:

```text
field.shape = semantic_line_field
loss.hierarchy_loss = true
```

and still performs normal item-level collapse unless route pressure says
otherwise.

This keeps `☳` stupid and keeps `☵` responsible for field quality.

## Test Obligations For Future Manifestation

Future code should add:

```text
encode_inline_section_marks_ambiguous_structure
encode_clean_section_marks_clean_structure
encode_flat_lines_mark_flat_structure
encode_route_pressure_sets_intent
encode_hierarchy_loss_explains_pressure
choose_does_not_parse_ambiguous_structure
```

## Current Status

```text
stage: crystallized_contract_pending_manifestation
code_change: none in this pass
```
