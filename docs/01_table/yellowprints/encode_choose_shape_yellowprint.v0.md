# ENCODE / CHOOSE Shape Yellowprint v0

This yellowprint compiles the first table for the `☵ -> ☳` shape boundary.

It does not replace:

```text
connect_dissolve_encode_yellowprint.v0.md
choose_collapse_yellowprint.v0.md
```

It links them.

## Problem

Current working route:

```text
☴ observe
☵ encode into field
☳ choose from field
☶ validate selected form
```

The route is correct.

The weak point is:

```text
field shape
```

Current flat semantic line fields make `☳` collapse by line order even when the
source was a structured reflection.

## Core Distinction

`☵ ENCODE`:

```text
forms material into a possibility field
preserves source truth
records source binding
records encoding loss
exposes shape
```

`☳ CHOOSE`:

```text
receives a possibility field
uses shape and pressure
selects continuing branch
kills alternatives at the chosen structural level
records attention loss
```

## Field Shape Table

### repo_path_field

Source:

```text
repo_listing
```

Items:

```text
repo_path
```

Normal `☳` level:

```text
path
```

Expected loss:

```text
unselected paths
```

### semantic_line_field

Source:

```text
substrate_result without detected structure
```

Items:

```text
semantic_line
```

Normal `☳` level:

```text
line
```

Expected loss:

```text
unselected lines
```

Risk:

```text
line order may be accidental rather than meaningful
```

### structured_reflection_field

Source:

```text
substrate_result with section-like structure
```

Items:

```text
section
section_child
constraint
test
claim
```

Normal `☳` level:

```text
section
or child within section
```

Expected loss:

```text
unselected sections
or unselected children inside preserved sections
```

Forbidden loss:

```text
killing section boundaries as if they were peer alternatives
```

### mixed_context_field

Source:

```text
substrate_result + repo_context
substrate_result + repo_listing
```

Items:

```text
semantic_line
context_block
repo_path
```

Normal `☳` level:

```text
must be declared by field_intent
```

Risk:

```text
mixing evidence blocks with semantic proposals as peer alternatives
```

### residue_field

Source:

```text
dissolved_records
unsupported_residue
```

Items:

```text
dissolved_residue
unsupported_residue
```

Normal `☳` level:

```text
residue
```

Expected loss:

```text
deferred or killed residue branches
```

## Field Intent Table

`field_shape` says:

```text
what the field is
```

`field_intent` says:

```text
what pressure ☳ should apply
```

Candidate intents:

```text
select_focus
preserve_reflection
choose_next_context
rank_candidates
carry_residue
```

## Shape/Intent Matrix

```text
repo_path_field + select_focus
  choose selected paths

semantic_line_field + rank_candidates
  choose selected lines

structured_reflection_field + preserve_reflection
  preserve required sections; choose only optional children

structured_reflection_field + select_focus
  choose whole sections or explicit child branches

mixed_context_field + choose_next_context
  choose context-bearing items; do not treat evidence blocks as claims

residue_field + carry_residue
  preserve residue enough for later DISSOLVE/LOGIC pressure
```

## ENCODE Responsibilities

`☵` must expose:

```text
field.shape
field.intent
item.kind
item.parent_id when structure exists
item.role when item is not a peer alternative
source_truth_status
content_truth_status
encoding_truth_status
connections
loss
```

Possible item roles:

```text
alternative
container
header
constraint
evidence
child
residue
```

V0 may keep `items` flat if structure is represented with:

```text
parent_id
role
order
```

Nested representation is not required for the first table.

## CHOOSE Responsibilities

`☳` must treat peer alternatives differently from structural support.

Allowed collapse levels:

```text
item
section
child
path
residue
```

Required pressure fields:

```text
operator_pressure
field_shape
field_intent
collapse_level
```

`☳` may still be deterministic and stupid.

It only needs enough shape metadata to avoid accidental truncation.

## Loss Table

`☵` loss:

```text
field_compression
source_projection
section_detection_loss
hierarchy_loss
```

`☳` loss:

```text
attention_collapse
section_collapse
child_collapse
path_focus_loss
residue_defer_loss
```

Loss must report:

```text
not_chosen_count
truncated
collapse_level
```

## Forbidden Shapes

`☵` must not emit:

```text
structured reflection as undifferentiated semantic_line list when sections are visible
mixed context as peer alternatives without intent
runtime-confirmed truth for semantic content
hidden validation result
hidden choice result
```

`☳` must not:

```text
parse raw text to discover sections
promote semantic ranking to runtime truth
validate paths
call substrate
read files
keep everything to avoid choosing
kill required structure accidentally
```

## Documentation Tests

Next crystal should define tests for:

```text
encode_structured_reflection_preserves_sections
choose_structured_reflection_does_not_kill_required_sections_by_line_limit
choose_repo_path_field_still_kills_unselected_paths
choose_records_collapse_level
```

No implementation in this pass.
