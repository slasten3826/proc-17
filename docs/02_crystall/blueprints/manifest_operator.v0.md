# Manifest Operator Blueprint v0

Status: implemented

Source:

```text
docs/01_table/yellowprints/manifest_operator_yellowprint.v0.md
```

## Modules

```text
logic/manifest.lua
cli/procesis-body.lua
tests/test_manifest.lua
tests/test_cli.lua
```

## Public Function

```lua
manifest.assemble(input) -> payload | nil, err
```

Input:

```lua
{
  work_mode = "plan" | "build",
  substrate_result = response_table,
  sources = {
    substrate_result_event = event_id,
    encoded_field_event = event_id,
    choice_event = event_id,
    validation_event = event_id,
    cycle_event = event_id,
    runtime_snapshot_event = event_id,
  },
  choose_context = table | nil,
  logic_context = table | nil,
  cycle_context = table | nil,
}
```

Output:

```lua
{
  kind = "manifest_payload",
  output = {
    type = "code" | "plan" | "residue" | "text" | "empty",
    text = string,
    language = string | nil,
  },
  sources = {...},
  assembly = {
    rule = "deterministic_v0",
    work_mode = work_mode,
    substrate_truth_status = "semantic_proposal",
  },
  residue = {
    assumptions = {},
    unsupported = {},
    missing = {},
    choice = {...} | nil,
    validation = {...} | nil,
  },
  summary = {
    type = output.type,
    language = output.language,
    text_preview = first compact part,
    source_event = sources.substrate_result_event,
  },
}
```

## Detection Rules

Order:

```text
empty
code
plan
residue
text
```

Code detection:

```text
```<language>
...
```
```

Any fenced code block marks output as code.
The full substrate text remains output text in v0.

Plan detection:

```text
work_mode == plan
```

Residue detection:

case-insensitive marker match:

```text
residue
unsupported
manifest: none
no manifest
not produced
cannot manifest
```

## CLI Integration

Replace:

```lua
packet.manifest(p, {truth_status = "runtime_confirmed", result = "substrate loop complete"})
```

with:

```lua
local manifest_payload = manifest.assemble(...)
packet.manifest(p, manifest_payload)
```

Runtime snapshot should receive:

```text
pending_output_shape = manifest_output_type
```

when known, or `pending_manifest_payload` pressure before final event.

For v0, it is acceptable for runtime snapshot to say:

```text
pending_output_shape = "manifest_payload"
```

## Final Envelope

CLI final envelope should include:

```lua
manifest = manifest_payload.summary
```

This is a convenience surface.
The full manifest remains in the `manifest` trace event.

## Non-Goals

No file writes.
No patch application.
No second substrate call.
No truth promotion of substrate claims.
No organ routing.
