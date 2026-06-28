# CONNECT / DISSOLVE / ENCODE Yellowprint v0

This yellowprint compiles first table shape for:

```text
☰ CONNECT
☷ DISSOLVE
☵ ENCODE
```

It is not a crystal yet.
It should guide the next blueprint pass.

## Why One Yellowprint

These three operators should not be tabled as unrelated helpers.

In `proc-17` they form the first upper-side preparation contour:

```text
☰ binds source pressure
☷ removes false/stale status
☵ forms portable field
```

Then:

```text
☳ collapses field
☶ validates formed selection
☱ reads lower pressure
```

## Topology Guard

Current topology:

```text
☰ adjacent: ▽ ☷ ☴ ☵
☷ adjacent: ▽ ☰ ☴ ☳
☵ adjacent: ☰ ☴ ☱ ☳ ☲
```

Important consequence:

```text
☰ can feed ☵ directly
☷ cannot feed ☵ directly
```

Therefore:

```text
☰ source binding may be carried inside ENCODE v0
☷ dissolve effect must enter ENCODE only as prepared residue or indirect route
```

No table below may imply:

```text
☷ hidden inside ☵
```

## Current Proc-17 Medium

The current body medium is not neural L1/L2.

It is:

```text
packet trace
task
observations
substrate calls
substrate results
repo listing/context
validation events
runtime pressure snapshots
unsupported forms
```

So the first table shape must be data/protocol shaped.

It must not pretend that `proc-17` already has a neural field.

## Shared Truth Rule

Operator events can be runtime-confirmed.

Encoded or related content may remain semantic.

Required distinction:

```text
relation_event_truth_status
source_truth_status
content_truth_status
encoding_event_truth_status
```

Never promote semantic content to runtime truth because it was connected,
dissolved, or encoded.

## ☰ CONNECT Table

### Invariant

```text
☰ gives pressure a channel
```

### Input Material

```text
task
observation event
substrate_call event
substrate_result line
repo path
repo context block
trace event
unsupported form
runtime snapshot section
```

### Output Shape

```text
connection_record
```

Fields:

```text
from
to
relation_kind
source_truth_status
relation_truth_status
pressure
evidence
```

### Relation Kinds v0

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

### Required Effects

CONNECT must make relation package-visible.

It may live inside another payload at v0, especially:

```text
encoded_field_payload.connections
```

### Forbidden Effects

CONNECT must not:

```text
validate truth
invent dependency graph
hide semantic status
become tag cloud
become hidden planner memory
```

## ☷ DISSOLVE Table

### Invariant

```text
☷ removes false form as active truth while preserving useful residue
```

### Input Material

```text
unsupported form
invalid path
unsupported reason
stale relation
dead branch
semantic proposal that failed validation
trace pressure that should decay
```

### Output Shape

```text
dissolved_record
```

Fields:

```text
target
old_status
new_status
dissolve_reason
residue
pressure_before
pressure_after
```

### New Status v0

```text
false_as_fact
unsupported_residue
stale
decayed
rejected
dead_branch
```

### Required Effects

DISSOLVE must remove or weaken active status.

It may preserve residue when shape remains diagnostically useful.

### Forbidden Effects

DISSOLVE must not:

```text
delete evidence silently
rewrite history
hide validation failure
pretend failed claim never existed
feed ☵ directly as if adjacent
```

## ☵ ENCODE Table

### Invariant

```text
☵ turns observed material into a loss-bearing portable field
```

### Input Material

```text
observations
substrate_result
repo_listing
repo_context
trace_tail
unsupported residue
connections
dissolved_records
limits
pressure
```

### Output Shape

```text
encoded_field_payload
```

Fields:

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

### Field Shape

```text
field = {
  truth_status,
  items
}
```

Each item:

```text
id
kind
value
source_kind
source_ref
source_truth_status
content_truth_status
encoding_truth_status
connections
```

### Source Kinds v0

```text
repo_listing_entry
substrate_response_line
repo_context_block
trace_event
unsupported_residue
dissolved_record
runtime_snapshot_section
```

### Loss Shape

```text
loss = {
  kind,
  input_count,
  output_count,
  omitted_count,
  source_detail_loss,
  hierarchy_loss,
  truncated
}
```

Allowed loss kinds:

```text
field_compression
source_projection
trace_tail_compression
unsupported_residue_encoding
```

### Required Effects

ENCODE must:

```text
produce a field usable by ☳
preserve source truth
preserve source relation
record loss
make hierarchy visible
```

### Forbidden Effects

ENCODE must not:

```text
validate selected paths
choose continuing branch
call substrate
run tools
manifest output
promote semantic content to runtime truth
hide DISSOLVE as an internal direct step
```

## First Route

Current route:

```text
☴ observe source material
CLI builds ad hoc field
☳ choose
☶ validate
```

Target v0 route:

```text
☴ observe source material
☰ expose source connections
☵ encode into field
☳ choose from field
☶ validate selected form
☱ read runtime pressure
```

Unsupported route:

```text
☴ observe unsupported emitted form
☶ validate and reject factual status
☷ dissolve false status into residue
☰ connect residue to origin
☵ encode residue into field item if pressure remains
☳ reject / defer / promote
```

The unsupported route is not direct `☷ -> ☵`.

It passes through explicit residue/source connection.

## Module Direction

Likely first modules:

```text
logic/encode.lua
```

Not yet required:

```text
logic/connect.lua
logic/dissolve.lua
```

Reason:

```text
CONNECT can first appear as connection records inside ENCODE output
DISSOLVE can first appear inside unsupported-form/status handling
```

This avoids creating fake organs before pressure requires them.

## First Implementation Boundary

The first code change should move field-building out of:

```text
cli/procesis-body.lua
```

and into:

```text
logic/encode.lua
```

CLI should then route:

```text
observations + substrate_result -> encode.encode(...) -> choose.choose(...)
```

## Tests To Add Later

```text
encode_repo_listing_to_field
encode_substrate_lines_to_field
encode_preserves_source_truth
encode_records_loss
encode_carries_connection_records
dissolve_invalid_claim_to_residue
connect_relation_does_not_validate_truth
cli_uses_encoded_field_before_choose
```

## Open Table Questions

```text
should ENCODE always run before CHOOSE by default?
should connection records be top-level packet events or payload internals first?
what exact residue shape should DISSOLVE produce?
how long does dissolved residue remain selectable?
should CHOOSE receive dissolved residue items directly or only encoded items?
how much trace_tail can ENCODE compress safely?
```

No crystal yet.
No code yet.
