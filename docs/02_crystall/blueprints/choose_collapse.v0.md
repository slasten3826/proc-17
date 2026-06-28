# Choose Collapse Blueprint v0

This blueprint defines the first `☳ CHOOSE` contract.

## Primary Rule

CHOOSE performs irreversible narrowing of a possibility field.

CHOOSE must leave loss.

If no package-visible loss or narrowing exists, no real CHOOSE happened.

## Module

```text
logic/choose.lua
```

Operator:

```text
☳ CHOOSE
```

Current manifest wiring:

```text
cli/procesis-body.lua
  CHOOSE runs by default after substrate observation/runtime tool touch
  CHOOSE can be disabled only with --no-choose
```

## Scope

CHOOSE may select a bounded continuing branch from a supplied field.

CHOOSE must not:

```text
call substrate
run tools
read files
write files
validate selected paths
decide continuation
manifest final output
append packet trace by itself
```

Those belong to other operators.

## Pair Contract With LOGIC

CHOOSE and LOGIC both reduce what can pass, but by different motion.

```text
☳ CHOOSE
  receives possibility field
  selects continuing branch
  kills alternatives as active paths
  records loss

☶ LOGIC
  receives formed proposal
  validates against rule boundary
  accepts or rejects
```

Short rule:

```text
☳ kills alternatives
☶ rejects invalid forms
```

## Required Function

```text
choose(input) -> choose_collapse_payload | nil, error
```

Input:

```text
field
limits
pressure
semantic_ranking
```

`field`:

```text
items
truth_status
```

Each field item may include:

```text
id
kind
value
truth_status
```

`limits`:

```text
max_selected
max_killed_sample
```

`pressure` may include:

```text
budget_pressure
attention_pressure
operator_pressure
task_pressure
context_limit_pressure
```

`semantic_ranking` is optional and must remain semantic:

```text
items
truth_status = semantic_proposal
```

## Required Payload Fields

```text
kind = choose_collapse_payload
selected
killed_alternatives
not_chosen_count
choice_pressure
choice_basis
loss
limits
truth_status = runtime_confirmed
```

## Selected Contract

Each selected item must include:

```text
id
kind
value
source_truth_status
selection_truth_status = runtime_confirmed
reason
```

The selection event is runtime-confirmed.

The reason may be semantic if it came from substrate ranking.

```text
reason.truth_status = semantic_proposal | runtime_confirmed | unknown
```

## Loss Contract

CHOOSE must report loss.

Required loss fields:

```text
kind = attention_collapse
not_chosen_count
truncated
```

`not_chosen_count` is:

```text
max(field item count - selected count, 0)
```

`killed_alternatives` is a bounded sample only.

It must not become an archive of the whole field unless the field is already
small enough.

## Selection Rule v0

V0 selection is deterministic.

Allowed basis order:

```text
1. semantic_ranking order, if supplied
2. field item order
```

CHOOSE may use semantic ranking only as ordering pressure.

It must not promote semantic reasons to runtime truth.

If semantic ranking references unknown items, those references are ignored by
CHOOSE. LOGIC can reject formed paths later when validation exists.

When a runtime-confirmed repo listing is present, CHOOSE uses listing files as
the possibility field and substrate output only as ordering pressure.

When no runtime-confirmed field is present, CHOOSE may collapse substrate
response lines as semantic proposal items.

## Error Contract

Missing field:

```text
nil, "missing_field"
```

Invalid field items:

```text
nil, "invalid_field_items"
```

Invalid limits:

```text
nil, "invalid_limits"
```

No selectable items:

```text
nil, "empty_field"
```

## Determinism Contract

For the same input field, limits, pressure, and semantic ranking,
`choose(input)` must return the same payload.

No clock reads in v0.
No filesystem reads in v0.
No substrate calls in v0.
No random values in v0.

## Test Obligations

```text
unit_test: selects at most max_selected items
unit_test: records not_chosen_count
unit_test: records loss.kind = attention_collapse
unit_test: bounds killed_alternatives by max_killed_sample
unit_test: returns runtime_confirmed for the narrowing event
unit_test: preserves semantic ranking reasons as semantic_proposal
unit_test: ignores semantic ranking references absent from field
unit_test: does not validate selected paths
unit_test: does not call substrate
unit_test: does not read files
unit_test: does not decide continuation
unit_test: is deterministic for same input
```

## Not In Scope

```text
path validation
repo context reads
semantic file ranking generation
LLM calls
cycle decision
runtime pressure snapshot
packet trace append
manifest output
```

## First Expected Route

Future route:

```text
☴ repo_listing_eye
☵ candidate field, minimal v0 may be direct field construction
☳ choose_collapse
☶ repo_selection_validator
☴ repo_context_eye
```

Since `☵ ENCODE` is not crystallized yet, first implementation may accept a
prebuilt `field.items` input.

This does not define ENCODE.

## Manifest v0 Status

Current implementation:

```text
logic/choose.lua
tests/test_choose.lua
```

Implemented:

```text
deterministic choose(input)
field-order fallback
semantic_ranking order as semantic pressure
unknown semantic ranking references ignored
selected items marked selection_truth_status = runtime_confirmed
semantic reasons preserved as semantic_proposal
not_chosen_count
loss.kind = attention_collapse
bounded killed_alternatives sample
unit tests
```

Still absent:

```text
CLI wiring
repo_listing candidate-field construction
RUNTIME choice pressure section
```
