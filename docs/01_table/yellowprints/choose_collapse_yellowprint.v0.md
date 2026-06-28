# Choose Collapse Yellowprint v0

`choose_collapse` is the first table shape for `☳ CHOOSE`.

It exists because `☱ RUNTIME` exposed a missing upper-side organ: the body can
validate proposals with `☶`, but still lets substrate choose focus too often.

## Primary Shape

```text
☳ CHOOSE = irreversible narrowing of possibility
```

CHOOSE is not a final plan.
CHOOSE is not LOGIC.
CHOOSE is not substrate preference text.

CHOOSE is the body event where a possibility field becomes a continuing branch
and the rest becomes loss.

## Pair With LOGIC

`☳` and `☶` are paired but not identical.

```text
☳ CHOOSE
  active exclusion
  receives possibility field
  narrows before all rules can be enumerated
  selected branch continues
  unselected branches die as active paths

☶ LOGIC
  passive constraint
  receives formed proposal
  checks against rule boundary
  accepted form passes
  invalid form is rejected
```

Short distinction:

```text
☳ kills alternatives
☶ rejects invalid forms
```

## Package Mutation

The package must change when it passes through `☳`.

No mutation means no real CHOOSE event.

Candidate payload:

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

## Selected

`selected` is the branch that continues.

Truth boundary:

```text
selection event
  runtime_confirmed

selection reason from substrate
  semantic_proposal
```

Candidate selected item:

```text
id
kind
value
source_truth_status
selection_truth_status = runtime_confirmed
reason
```

## Killed Alternatives

CHOOSE should not archive an infinite field.

V0 can store bounded loss:

```text
killed_alternatives
  bounded sample/list of alternatives if available

not_chosen_count
  count of alternatives that no longer continue

loss.kind
  attention_collapse
```

If alternatives are too large:

```text
killed_alternatives = {}
not_chosen_count = known_count_or_unknown
loss.truncated = true
```

## Choice Pressure

Why choice is required:

```text
budget_pressure
attention_pressure
operator_pressure
task_pressure
context_limit_pressure
```

This pressure can be runtime-confirmed as a condition.

The explanation for why a selected item is "best" may remain semantic.

## First Concrete Route

Current route:

```text
☴ repo_listing_eye
substrate proposes paths
☶ repo_selection_validator
☴ repo_context_eye
```

This works, but substrate currently performs the focus choice.

Future body-owned route:

```text
☴ observe listing
☵ encode listing into candidate field
☳ choose focus
☶ validate focus
☴ observe selected context
```

In repo terms:

```text
repo_listing_payload.entries -> candidate field
candidate field -> selected focus paths
not selected entries -> attention loss/count
selected paths -> LOGIC validation
accepted paths -> repo_context_eye
```

## Relation To RUNTIME

`☱ RUNTIME` should be able to see CHOOSE pressure later:

```text
choice_count
selected_count
not_chosen_count
loss.kind
last_choice_event
```

But RUNTIME must not choose.

## Relation To CYCLE

`☲ CYCLE` can use choice pressure later:

```text
no selected branch -> stop_no_progress
selected branch with payable budget -> continue
repeated selected branch -> stop_repetition
```

But CYCLE must not choose.

## V0 Candidate Input

Minimal v0 input:

```text
field
limits
pressure
optional semantic_ranking
```

`field`:

```text
items
item_count
truth_status = runtime_confirmed or mixed
```

`limits`:

```text
max_selected
max_killed_sample
```

`semantic_ranking`:

```text
optional substrate proposal
truth_status = semantic_proposal
```

## V0 Candidate Output

```text
choose_collapse_payload
```

Required fields:

```text
kind
selected
not_chosen_count
loss
limits
truth_status = runtime_confirmed
```

Optional fields:

```text
killed_alternatives
choice_pressure
choice_basis
semantic_ranking
```

## Test Surface

Candidate tests:

```text
selects at most max_selected items
records not_chosen_count
records loss.kind = attention_collapse
does not promote semantic reasons to runtime truth
returns runtime_confirmed for the narrowing event
does not validate selected paths
does not read files
does not call substrate
does not decide continuation
```

## Open Questions

```text
can CHOOSE operate before ENCODE exists?
is field.items enough for v0?
should killed_alternatives be sample-only by default?
should loss have numeric budget-like cost?
where should choose residue live in packet?
```

No crystal yet.
No implementation yet.
