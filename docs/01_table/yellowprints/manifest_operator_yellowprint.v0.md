# Manifest Operator Yellowprint v0

Source chaos:

```text
docs/00_chaos/manifest_operator_notes.md
```

## Intent

`△ MANIFEST` assembles the visible outer form from existing body material.

It does not call the substrate.
It does not decide new truth.
It does not write files in v0.

## Inputs

Required:

```text
substrate_result
work_mode
```

Optional:

```text
substrate_result_event
encoded_field_event
choice_event
validation_event
cycle_event
runtime_snapshot_event
choose_context
logic_context
cycle_context
```

## Output Payload

Manifest payload shape:

```text
kind = manifest_payload
output = {
  type = code | plan | residue | text | empty
  text = string
  language = optional string
}
sources = {
  substrate_result_event = event id | nil
  encoded_field_event = event id | nil
  choice_event = event id | nil
  validation_event = event id | nil
  cycle_event = event id | nil
  runtime_snapshot_event = event id | nil
}
assembly = {
  rule = deterministic_v0
  work_mode = plan | build
  substrate_truth_status = semantic_proposal
}
residue = {
  assumptions = []
  unsupported = []
  missing = []
  choice = optional summary
  validation = optional summary
}
```

## Output Type Detection

Simple deterministic rules:

```text
empty:
  substrate text is empty

code:
  fenced code block exists

plan:
  work_mode == plan

residue:
  text contains strong residue/unsupported/no manifest markers

text:
  fallback
```

Code language:

```text
```python -> python
```lua    -> lua
```zig    -> zig
```       -> unknown
```

## Truth Boundary

`manifest.truth_status = runtime_confirmed` means:

```text
the body assembled this output from trace material
```

It does not mean:

```text
all claims inside output.text are runtime-confirmed
```

The source text truth status remains semantic unless validated elsewhere.

## Final Envelope

CLI final envelope should include a compact manifest summary:

```text
manifest = {
  type
  language
  text_preview
  source_event
}
```

The full output remains in the `manifest` event payload.

## Tests

Required:

```text
manifest_code_fence_detects_code_type
manifest_plan_mode_detects_plan_type
manifest_residue_text_detects_residue_type
manifest_empty_detects_empty_type
cli_manifest_contains_substrate_text_not_loop_complete
cli_final_contains_manifest_summary
```

