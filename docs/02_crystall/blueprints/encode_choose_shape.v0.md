# ENCODE / CHOOSE Shape Blueprint v0

This blueprint defines the first crystallized contract for the shape boundary
between:

```text
☵ ENCODE
☳ CHOOSE
```

It extends, but does not replace:

```text
connect_dissolve_encode.v0.md
choose_collapse.v0.md
```

## Primary Rule

`☵` must expose the structural shape of the field before `☳` collapses it.

`☳` must collapse at a declared structural level.

If `☳` collapses a structured reflection by flat line order, the route has
preserved syntax but lost form.

## Required Field Additions

Future `encoded_field_payload.field` must include:

```text
shape
intent
items
truth_status
```

`shape` describes what the field structurally is.

Allowed v0 shapes:

```text
repo_path_field
semantic_line_field
structured_reflection_field
mixed_context_field
residue_field
```

`intent` describes what pressure the field is carrying toward `☳`.

Allowed v0 intents:

```text
select_focus
preserve_reflection
choose_next_context
rank_candidates
carry_residue
```

## Required Item Additions

Each field item may include:

```text
parent_id
role
order
```

Allowed v0 roles:

```text
alternative
container
header
constraint
evidence
child
residue
```

Rules:

```text
role = alternative means ☳ may kill it directly
role = header means item carries structure, not a peer branch
role = container means children should be considered under it
role = evidence means item supports a branch but is not itself the branch
```

V0 may keep `field.items` flat.

Hierarchy can be represented with:

```text
parent_id
role
order
```

Nested item arrays are not required by this blueprint.

## ENCODE Contract Extension

`☵ ENCODE` must:

```text
set field.shape
set field.intent when known from route pressure
preserve visible section boundaries when source text has explicit sections
mark structural items with role
preserve source truth
record hierarchy_loss when structure was flattened or omitted
record section_detection_loss when section-like structure was partially detected
```

`☵ ENCODE` must not:

```text
validate section claims
choose important sections
promote section content to runtime truth
hide unknown structure as if it were a clean flat list
```

## CHOOSE Contract Extension

`☳ CHOOSE` input pressure should include:

```text
field_shape
field_intent
collapse_level
```

Allowed v0 collapse levels:

```text
item
section
child
path
residue
```

`☳ CHOOSE` must:

```text
record collapse_level in choice_pressure or loss
select only items eligible for the collapse level
avoid killing structural support items as if they were peer alternatives
preserve semantic ranking as semantic pressure only
```

`☳ CHOOSE` must not:

```text
infer field shape from raw text
repair malformed structure
validate selected paths
call substrate
read files
avoid loss by keeping everything
```

## Shape Behavior

### repo_path_field

Default intent:

```text
select_focus
```

Default collapse level:

```text
path
```

Allowed loss:

```text
path_focus_loss
attention_collapse
```

### semantic_line_field

Default intent:

```text
rank_candidates
```

Default collapse level:

```text
item
```

Allowed loss:

```text
attention_collapse
```

Risk:

```text
line order may not represent real alternatives
```

### structured_reflection_field

Default intent:

```text
preserve_reflection
```

Default collapse level:

```text
section
```

Rule:

```text
section headers and required constraints are not peer alternatives
```

If intent is `preserve_reflection`, `☳` must not kill entire required sections
only because `max_selected` was reached by earlier lines.

Allowed loss:

```text
child_collapse
section_collapse only when intent permits section choice
```

### mixed_context_field

Default intent:

```text
choose_next_context
```

Rule:

```text
runtime-confirmed context blocks and semantic proposal lines are not equivalent peers
```

`☳` must not collapse evidence blocks and semantic claims together unless the
field declares them as alternatives.

### residue_field

Default intent:

```text
carry_residue
```

Rule:

```text
residue may be deferred, killed, or carried, but must not be silently erased
```

## Loss Contract Extension

`☵` may add loss kind:

```text
section_detection_loss
```

`hierarchy_loss` already exists as a loss field in the ENCODE contract.
This blueprint only clarifies when it should become true.

`☳` may add loss kinds:

```text
section_collapse
child_collapse
path_focus_loss
residue_defer_loss
```

`☳` loss should include:

```text
collapse_level
not_chosen_count
truncated
```

## Compatibility Rule

Existing v0 fields without explicit `shape` are interpreted as:

```text
semantic_line_field
```

unless all items are `repo_path`, in which case they may be interpreted as:

```text
repo_path_field
```

This preserves current behavior while making the missing shape visible.

## Test Obligations For Future Manifestation

No code is required by this blueprint pass.

Future code must add tests for:

```text
encode_structured_reflection_preserves_sections
encode_sets_field_shape_and_intent
choose_records_collapse_level
choose_structured_reflection_preserves_required_sections
choose_repo_path_field_still_kills_unselected_paths
choose_ignores_structural_headers_as_peer_alternatives
```

## Current Status

```text
stage: crystallized_contract_pending_manifestation
code_change: none in this pass
```
