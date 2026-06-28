# Packet Protocol Blueprint v0

This is the first stable contract for the `procesis-body` packet protocol.

## Identity

```text
packet = mortal process body for one task life
```

The packet is not:

```text
prompt
chat
model response
long-term memory
```

## Protocol Version

```text
protocol_version = "packet.v0"
```

Every packet must carry this version.

Test status:

```text
unit_test: packet_birth_unit
```

## Required Packet Fields

Lua packet v0 must include:

```text
protocol_version
id
parent_id
task
status
mode
operator
budget
pressure
trace
residue
death
```

Optional v0 fields:

```text
context
topology
metadata
```

Test status:

```text
unit_test: packet_birth_unit
```

## Mode Contract

Allowed packet modes:

```text
chaos
table
crystall
manifest
```

Default mode:

```text
manifest
```

Allowed mode event:

```text
mode_enter
```

Test status:

```text
unit_test: packet mode validation
unit_test: mode_enter trace event
```

## Status Contract

Allowed statuses:

```text
born
running
blocked
dying
dead
manifested
```

Invalid status is a protocol error.

Test status:

```text
unit_test: packet_status_validation_unit
```

## Trace Contract

The trace is append-only.

Required event fields:

```text
id
type
operator
payload
truth_status
cost
time
```

Allowed event types:

```text
birth
operator_enter
operator_exit
observation
substrate_call
substrate_result
phantom_spawn
phantom_result
tool_call
tool_result
validation
budget_spend
mode_enter
unsupported_form
gap_residue
choice
manifest
death
```

Allowed truth statuses:

```text
runtime_confirmed
semantic_proposal
unsupported
rejected
promoted
manual
unknown
```

Test status:

```text
unit_test: packet_trace_append_unit
unit_test: packet_trace_event_validation_unit
```

## Control Ownership Contract

The cognitive wrapper owns process control.

The LLM substrate does not own:

```text
operator route
tool execution
runtime truth
budget mutation
manifest status
packet death
```

The LLM substrate may produce:

```text
semantic_proposal
code_proposal
compression
critique
interpretation
```

These must enter the packet as trace events.

Test status:

```text
manual_check: first CLI loop must show wrapper-owned control flow
```

## Substrate Call Contract

LLM calls are explicit packet events.

Required substrate call payload fields:

```text
mode
operator
prompt_payload
expected_shape
```

Allowed modes:

```text
glyph
natural
mixed
```

Substrate result default truth status:

```text
semantic_proposal
```

Any promotion from `semantic_proposal` to `runtime_confirmed` must happen by
validation outside the substrate.

Test status:

```text
unit_test: substrate_call_event_validation_unit
unit_test: substrate_result_default_truth_status_unit
```

## Budget Contract

Lua packet v0 budget must support at least:

```text
steps
substrate_calls
tool_calls
file_writes
test_runs
```

Budget mutation must happen through explicit spend operation.

Required operation:

```text
spend(packet, cost) -> packet | error
```

If budget goes below zero, packet must enter `dying` or `dead` through explicit
death handling. It must not continue silently.

Test status:

```text
unit_test: packet_budget_spend_unit
unit_test: packet_budget_exhaustion_unit
```

## Operator Contract

The packet current operator must be one of ProcessLang v0 glyphs:

```text
▽ ☰ ☷ ☵ ☳ ☴ ☲ ☶ ☱ △
```

Operator transitions must be validated by topology/router.

Required operation:

```text
enter(packet, operator) -> packet | error
```

Test status:

```text
unit_test: topology_valid_route_unit
unit_test: topology_invalid_route_unit
```

## Unsupported Form Contract

Unsupported semantic form is first-class packet data.

Required event type:

```text
unsupported_form
```

Required payload fields:

```text
emitted_form
source_event_id
unsupported_because
recurrence_key
recurrence_count
decision
```

Allowed decisions:

```text
reject
defer
promote
decay
```

Unsupported form must never be manifested as `runtime_confirmed`.

Required operations:

```text
record_unsupported(packet, form) -> packet
decide_gap(packet, recurrence_key, decision) -> packet
```

Test status:

```text
unit_test: unsupported_form_capture_unit
unit_test: unsupported_form_dissolve_unit
unit_test: unsupported_form_promote_unit
```

## Manifest Contract

Manifest event must include truth status.

Allowed manifest truth statuses:

```text
runtime_confirmed
manual
unknown
```

`unsupported` and `semantic_proposal` must not be final manifest truth unless
the manifest explicitly says it is unconfirmed.

Required operation:

```text
manifest(packet, payload) -> packet
```

Test status:

```text
unit_test: packet_manifest_truth_status_unit
```

## Death Contract

Death is part of normal packet life.

Allowed death causes:

```text
complete
budget_exhausted
blocked_by_runtime_truth
needs_user_input
invalid_topology
loop_repetition
unsafe_scope
cancelled
```

Death must write residue.

Required operations:

```text
die(packet, cause) -> packet
residue(packet) -> residue
```

Residue must include:

```text
cause
worked
failed
missing
do_not_repeat
resume_hint
```

Test status:

```text
unit_test: packet_death_unit
unit_test: packet_death_residue_unit
```

## Child Packet Contract

Child packets are allowed only with:

```text
parent_id
task
budget
operator
trace
death
```

No child packet is immortal.

Phantoms are child packet candidates, not independent agents.

Phantom constraints:

```text
bounded role
bounded budget
parent_id required
return result into parent trace
death required
```

Test status:

```text
not_testable_yet_with_reason: child packets are not in first implementation scope
```

## Lua v0 Module Target

First implementation target:

```text
core/packet.lua
```

Required exported functions:

```text
new
append
spend
enter
record_unsupported
decide_gap
manifest
die
residue
```

No real provider is required for packet protocol tests.
