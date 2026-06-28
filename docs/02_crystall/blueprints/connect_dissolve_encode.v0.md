# CONNECT / DISSOLVE / ENCODE Blueprint v0

This blueprint defines the first crystallized contract for the upper-side
preparation contour:

```text
☰ CONNECT
☷ DISSOLVE
☵ ENCODE
```

Only `☵ ENCODE` becomes a first module in v0.

`☰ CONNECT` and `☷ DISSOLVE` are crystallized here as payload contracts used
by ENCODE and later unsupported-form handling.

## Topology Rule

Current topology:

```text
☰ adjacent: ▽ ☷ ☴ ☵
☷ adjacent: ▽ ☰ ☴ ☳
☵ adjacent: ☰ ☴ ☱ ☳ ☲
```

Required rule:

```text
☰ may feed ☵ directly as source binding
☷ must not be hidden inside ☵ as a direct step
```

If DISSOLVE pressure reaches ENCODE, it must arrive as:

```text
prepared residue
explicit dissolved_record
explicit connection to source
```

not as invisible cleanup inside ENCODE.

## Module

```text
logic/encode.lua
```

Operator:

```text
☵ ENCODE
```

No v0 modules yet:

```text
logic/connect.lua
logic/dissolve.lua
```

Reason:

```text
☰ first appears as connection records inside encoded fields
☷ first appears as dissolved records from validation/unsupported-form handling
```

## Primary Rule

ENCODE turns observed material into a loss-bearing portable field.

ENCODE must preserve source truth.

ENCODE must leave loss.

If no package-visible field, source binding, or loss exists, no real ENCODE
happened.

## Scope

ENCODE may:

```text
convert repo listing entries into field items
convert substrate response lines into field items
convert repo context blocks into field items
convert trace events into field items
carry connection records
carry dissolved records as residue items
record compression/projection loss
```

ENCODE must not:

```text
call substrate
run tools
read files
write files
choose continuing branch
validate selected paths
decide continuation
manifest final output
append packet trace by itself
promote semantic content to runtime truth
hide DISSOLVE as internal direct step
```

Those belong to other operators.

## Required Function

```text
encode(input) -> encoded_field_payload | nil, error
```

Input:

```text
observations
substrate_result
repo_listing
repo_context
trace_tail
connections
dissolved_records
limits
pressure
```

All input keys are optional except that at least one source must provide
encodable material.

## Required Payload Fields

```text
kind = encoded_field_payload
field
connections
source_mix
encoding_basis
hierarchy
loss
limits
truth_status = runtime_confirmed
```

## Field Contract

```text
field = {
  truth_status,
  items
}
```

`field.truth_status` is:

```text
runtime_confirmed
```

only when every item source is runtime-confirmed.

Otherwise:

```text
semantic_proposal
```

or:

```text
mixed
```

Each field item must include:

```text
id
kind
value
source_kind
source_ref
source_truth_status
content_truth_status
encoding_truth_status = runtime_confirmed
connections
```

The encoding event is runtime-confirmed.

The content truth remains inherited from source.

## Source Kinds

Allowed v0 source kinds:

```text
repo_listing_entry
substrate_response_line
repo_context_block
trace_event
unsupported_residue
dissolved_record
runtime_snapshot_section
```

## Item Kinds

Allowed v0 item kinds:

```text
repo_path
semantic_line
context_block
trace_event
unsupported_residue
dissolved_residue
runtime_pressure
```

## CONNECT Payload Contract

Connection records are the v0 manifestation of `☰ CONNECT`.

```text
connection_record = {
  from,
  to,
  relation_kind,
  source_truth_status,
  relation_truth_status,
  pressure,
  evidence
}
```

Allowed relation kinds:

```text
task_to_observation
observation_to_source
substrate_call_to_result
result_line_to_candidate
repo_path_to_listing
context_to_path
unsupported_to_origin
trace_event_to_pressure
```

Rules:

```text
relation_truth_status may be runtime_confirmed
semantic explanation remains semantic_proposal
connection does not validate truth
connection must not invent dependency graph
```

## DISSOLVE Payload Contract

Dissolved records are the v0 transferable result of `☷ DISSOLVE`.

```text
dissolved_record = {
  target,
  old_status,
  new_status,
  dissolve_reason,
  residue,
  pressure_before,
  pressure_after
}
```

Allowed new statuses:

```text
false_as_fact
unsupported_residue
stale
decayed
rejected
dead_branch
```

Rules:

```text
dissolved_record may be encoded later
dissolved_record is not direct ☷ -> ☵ adjacency
residue must preserve why the false body was removed
history must not be rewritten
```

## Loss Contract

ENCODE must report loss.

Required loss fields:

```text
kind
input_count
output_count
omitted_count
source_detail_loss
hierarchy_loss
truncated
```

Allowed loss kinds:

```text
field_compression
source_projection
trace_tail_compression
unsupported_residue_encoding
```

`omitted_count` is:

```text
max(input material count - output item count, 0)
```

`truncated` is true when ENCODE had more material than limits allowed.

## Encoding Basis

`encoding_basis` must describe the deterministic ordering and source selection
used to build the field.

Allowed v0 basis order:

```text
1. repo_listing entries, if present
2. substrate response lines, if no repo_listing entries
3. explicit repo_context blocks, if supplied as source material
4. trace_tail events, if supplied as source material
5. dissolved_records / unsupported residue, if supplied
```

This is a default basis, not a ranking claim.

Semantic ranking remains CHOOSE pressure, not ENCODE truth.

## Determinism Contract

For the same input and limits, `encode(input)` must return the same payload.

No clock reads in v0.
No filesystem reads in v0.
No substrate calls in v0.
No random values in v0.

## Error Contract

No encodable material:

```text
nil, "empty_sources"
```

Invalid limits:

```text
nil, "invalid_limits"
```

Invalid source shape:

```text
nil, "invalid_source"
```

Invalid connection shape:

```text
nil, "invalid_connection"
```

Invalid dissolved record shape:

```text
nil, "invalid_dissolved_record"
```

## Test Obligations

```text
unit_test: encodes repo_listing entries into repo_path items
unit_test: encodes substrate response lines into semantic_line items
unit_test: preserves source_truth_status
unit_test: marks encoding_truth_status = runtime_confirmed
unit_test: records source_kind and source_ref
unit_test: carries connection records
unit_test: carries dissolved records only as explicit residue
unit_test: reports loss.kind
unit_test: reports omitted_count
unit_test: bounds output by limits.max_items
unit_test: does not call substrate
unit_test: does not read files
unit_test: does not choose continuing branch
unit_test: does not validate selected paths
unit_test: is deterministic for same input
```

## CLI Route Contract

Future CLI route:

```text
☴ observe source material
☵ encode source material into encoded_field_payload
☳ choose from encoded_field_payload.field
☶ validate selected form
☲ cycle decision
☱ runtime pressure snapshot
△ manifest envelope
```

Current CLI uses ENCODE before CHOOSE.

## Not In Scope

```text
standalone CONNECT module
standalone DISSOLVE module
unsupported-form promotion policy
recurrence tracking
path validation
repo context reads
semantic ranking generation
LLM calls
cycle decision
runtime pressure snapshot
packet trace append
manifest output
```

## First Manifest Target

The first implementation should add:

```text
logic/encode.lua
tests/test_encode.lua
cli/procesis-body.lua uses encode before choose
```

Implemented in manifest v0.

## Still Open

```text
whether ENCODE should always run before CHOOSE by default
whether connection records should become top-level events later
whether DISSOLVE deserves logic/dissolve.lua after unsupported-form work
how long dissolved residue remains selectable
how much trace_tail can be compressed safely
```
