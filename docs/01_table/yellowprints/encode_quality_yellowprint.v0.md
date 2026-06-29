# ENCODE Quality Yellowprint v0

This yellowprint compiles raw pressure from:

```text
docs/00_chaos/encode_quality_before_choose_notes.md
```

It focuses only on `☵ ENCODE` quality before `☳ CHOOSE`.

It does not make `☳` smarter.

## Core Table

Current rule:

```text
☵ prepares field protocol
☳ executes collapse
```

Therefore:

```text
bad ☵ field -> bad ☳ cut
clean ☵ field -> useful ☳ cut
```

## Quality Target

Better `☵` does not mean:

```text
large parser
semantic reasoning
LLM interpretation
hidden validation
```

Better `☵` means:

```text
explicit field shape
explicit field intent
explicit role metadata
explicit hierarchy confidence
explicit ambiguity pressure
explicit loss when structure was not trusted
```

## Field Quality States

### clean_structure

Observed when:

```text
section headers are explicit
children are visible
source shape can be represented without guessing
```

Example:

```text
3 strongest next pressures:
field shape
collapse level
section boundary
```

Expected `☵` result:

```text
field.shape = structured_reflection_field
field.intent = preserve_reflection
items include section/container and section_child/alternative
loss.hierarchy_loss = false
```

### flat_structure

Observed when:

```text
no structure is visible
lines are independent enough to remain line items
```

Expected `☵` result:

```text
field.shape = semantic_line_field
field.intent = rank_candidates
loss.hierarchy_loss = false
```

### ambiguous_structure

Observed when:

```text
text appears section-like
but section boundaries are not clean enough to trust
```

Examples:

```text
3 strongest next pressures: field shape, collapse level, section boundary
```

or:

```text
Diagnosis: ENCODE sees X. Design rules: ENCODE should Y.
```

Expected `☵` result:

```text
field.shape = semantic_line_field
field.intent = rank_candidates
field.possible_shape = structured_reflection_field
field.structure_status = ambiguous_structure
loss.hierarchy_loss = true
```

Important:

```text
ambiguous structure is pressure, not trusted hierarchy
```

### mixed_truth_structure

Observed when:

```text
runtime-confirmed evidence and semantic proposals are in one field
```

Expected `☵` result:

```text
field.shape = mixed_context_field
field.intent = choose_next_context
field.truth_status = mixed
items preserve source_truth_status
```

### residue_structure

Observed when:

```text
source material is unsupported or dissolved residue
```

Expected `☵` result:

```text
field.shape = residue_field
field.intent = carry_residue
items preserve dissolve status
```

## Ambiguity Signals

`☵` should be able to emit ambiguity without pretending certainty.

Possible field-level keys:

```text
possible_shape
structure_status
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

## Intent Source

`field.intent` may come from:

```text
route pressure
source kind
detected structure
fallback default
```

Priority table:

```text
1. explicit route pressure intent
2. clean structure intent
3. source-kind default intent
4. semantic fallback intent
```

Route pressure must not promote content truth.

It only says what the route wants to do with the field.

## Loss Table

When `☵` sees possible structure but cannot trust it:

```text
loss.hierarchy_loss = true
```

When `☵` trusts structure and preserves it:

```text
loss.hierarchy_loss = false
```

When `☵` cannot determine if structure exists:

```text
loss.hierarchy_loss = false
field.structure_status = flat_structure
```

Do not use `hierarchy_loss` as a generic uncertainty flag.

Use it only when structure pressure was present but not safely encoded.

## What ☵ Must Not Do

`☵` must not:

```text
parse every colon as a section
invent child items from ambiguous inline text
ask substrate for clarification
validate section claims
choose important sections
repair malformed documents
hide ambiguity as clean semantic_line_field
```

## What ☳ Receives

For clean structure:

```text
☳ receives structured_reflection_field
☳ can collapse at child or section level
```

For ambiguous structure:

```text
☳ receives semantic_line_field
☳ sees possible_shape / hierarchy_loss pressure
☳ still collapses at item level unless route pressure says otherwise
```

This keeps `☳` stupid and keeps ambiguity visible.

## Test Pressure

Future manifestation should test:

```text
encode_inline_section_marks_ambiguous_structure
encode_route_pressure_sets_intent
encode_clean_section_keeps_hierarchy_loss_false
choose_does_not_parse_ambiguous_structure
```

No code in this table pass.
