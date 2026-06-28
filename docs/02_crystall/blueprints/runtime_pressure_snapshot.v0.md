# Runtime Pressure Snapshot Blueprint v0

This blueprint defines the first `☱ RUNTIME` contract.

## Primary Rule

RUNTIME exposes lower pressure condition as read-only evidence.

RUNTIME must not become memory, planner, continuation logic, or will.

## Module

```text
runtime/pressure_snapshot.lua
```

Operator:

```text
☱ RUNTIME
```

## Scope

RUNTIME may read packet/body condition supplied to it.

RUNTIME must not:

```text
call substrate
run tools
read files
write files
mutate packet
append trace events by itself
validate selected paths
decide continuation
choose next action
manifest final output
```

Those belong to other operators.

## Topology Contract

RUNTIME is the lower pressure hub.

Adjacent operators:

```text
☵ ENCODE
☳ CHOOSE
☴ OBSERVE
☲ CYCLE
☶ LOGIC
△ MANIFEST
```

Not directly adjacent:

```text
▽ FLOW
☰ CONNECT
☷ DISSOLVE
```

Implication:

```text
RUNTIME does not infer raw input, connection intent, or dissolution intent.
It reads only pressure that has already reached the lower body side.
```

## Required Function

```text
snapshot(input) -> runtime_pressure_snapshot_payload | nil, error
```

Input:

```text
packet
limits
logic_context
cycle_context
manifest_context
```

`packet` may include:

```text
id
protocol_version
status
mode
operator
budget
trace
residue
death
tick_count
```

`limits` may include:

```text
trace_tail_count
include_residue
include_budget
include_pressure_sections
```

## Required Payload Fields

```text
kind = runtime_pressure_snapshot_payload
packet_id
protocol_version
status
mode
operator
packet_state
budget_pressure
trace_pressure
logic_pressure
cycle_pressure
manifest_pressure
death_pressure
conditions
limits
truth_status = runtime_confirmed
```

## Pressure Sections

Packet state:

```text
status
mode
operator
tick_count
```

Budget pressure:

```text
budget
budget_negative_keys
budget_exhausted_keys
```

Trace pressure:

```text
trace_count
trace_tail
last_event
last_event_type
last_truth_status
```

Logic pressure:

```text
last_validation_event
accepted_count
rejected_count
rejection_reasons
```

Cycle pressure:

```text
last_cycle_decision
last_cycle_reasons
repeated_fingerprint
turn_budget_pressure
```

Manifest pressure:

```text
last_manifest_event
pending_output_shape
output_pressure
```

Death pressure:

```text
status_dead
status_dying
residue_count
death_residue_present
```

## Adjacent Pressure Handling

`☵ ENCODE` pressure in v0, without crystallizing ENCODE itself:

```text
trace shape
residue shape
last truth status
bounded tail decoding
```

RUNTIME does not implement ENCODE.
It only exposes already-encoded packet traces and residue in a bounded form.

`☳ CHOOSE` pressure in v0, without crystallizing CHOOSE itself:

```text
accepted branch count
rejected branch count
last selected branch if already validated
```

RUNTIME does not implement CHOOSE.
It only exposes what choice pressure has already left in packet context.

No additional ENCODE or CHOOSE theory is part of this blueprint.

`☲ CYCLE` pressure in v0:

```text
previous cycle decision
turn count
repeat signal if already supplied
```

RUNTIME does not decide continuation.

`☶ LOGIC` pressure in v0:

```text
last validation result
rejection reasons
boundary status
```

RUNTIME does not validate.

`△ MANIFEST` pressure in v0:

```text
pending output shape
last manifestation event
death/report readiness if already supplied
```

RUNTIME does not manifest.

## Forbidden Payload Fields

The snapshot must not return:

```text
can_continue
stop_reason
next_action
route_choice
selected_paths
final_answer
plan
```

These fields create false agency inside RUNTIME.

## Determinism Contract

For the same input packet and contexts, `snapshot(input)` must return the same
payload.

No clock reads in v0.
No filesystem reads in v0.
No substrate calls in v0.
No random values in v0.

## Error Contract

Missing packet:

```text
nil, "missing_packet"
```

Invalid trace shape:

```text
nil, "invalid_trace"
```

Invalid budget shape:

```text
nil, "invalid_budget"
```

Invalid limits:

```text
nil, "invalid_limits"
```

## Test Obligations

```text
unit_test: snapshots packet id/status/mode/operator
unit_test: copies budget pressure without mutation
unit_test: marks negative and exhausted budget keys
unit_test: counts trace events
unit_test: returns bounded trace_tail
unit_test: exposes last_event and last_truth_status
unit_test: exposes logic pressure when supplied
unit_test: exposes cycle pressure when supplied
unit_test: exposes manifest pressure when supplied
unit_test: exposes death pressure when packet is dead or dying
unit_test: does not include can_continue
unit_test: does not include next_action
unit_test: does not mutate packet
unit_test: is deterministic for same input
```

## Not In Scope

```text
memory archive
semantic summarization
state fingerprint computation
cycle decision
logic validation
manifest formatting
automatic packet loop orchestration
```

## Expected Route

First expected route:

```text
repo_listing_eye
repo_selection_validator
cycle_decision
runtime_pressure_snapshot
cycle_decision consumes snapshot in a later pass
```

The first implementation may be manually called by tests before it is wired into
the CLI loop.

## Manifest v0 Status

Current implementation:

```text
runtime/pressure_snapshot.lua
tests/test_runtime_pressure_snapshot.lua
cli/procesis-body.lua runtime snapshot by default
cli/procesis-body.lua --no-runtime-snapshot
```

Implemented:

```text
pure snapshot(input)
bounded trace tail
budget pressure
trace pressure
logic/cycle/manifest/death pressure sections
forbidden agency fields absent
CLI JSONL observation emitted by default
CLI runtime snapshot disabled only by --no-runtime-snapshot
CLI passes default LOGIC/CYCLE contexts when enabled
unit tests
CLI smoke test
```

Still absent:

```text
DeepSeek live trace with default runtime snapshot
```
