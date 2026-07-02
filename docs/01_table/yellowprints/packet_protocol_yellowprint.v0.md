# Packet Protocol Yellowprint v0

Packet protocol is the body-internal contract for one task life.

It is not only a data shape.
It is the rule for how organs exchange truth, pressure, cost, and residue.

## Core Reading

```text
packet != prompt
packet != chat history
packet != model response
packet != memory

packet = mortal process body for one task
```

The protocol must keep this distinction stable:

```text
semantic proposal != runtime truth
```

## Shape

Candidate packet shape:

```text
packet = {
  protocol_version,
  id,
  parent_id,
  role,
  task,
  status,
  operator,
  topology,
  budget,
  pressure,
  context,
  trace,
  residue,
  death
}
```

Next internal architecture layer may add:

```text
substrate
chaos
boundary
calm
tension
manifest
```

See:

```text
packet_internal_architecture_yellowprint.v0.md
```

The packet has mutable fields, but runtime truth comes primarily from trace.

```text
header = current summary / cached state
trace  = append-only truth line
```

## Status

```text
born
running
blocked
dying
dead
manifested
```

## Trace Events

The trace should use typed events.

Candidate event types:

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
unsupported_form
gap_residue
choice
manifest
death
```

Every event should carry:

```text
id
time
operator
type
payload
cost
truth_status
```

## Truth Status

Useful statuses:

```text
runtime_confirmed
semantic_proposal
unsupported
rejected
promoted
manual
unknown
```

This prevents model text from becoming fact just because it exists in context.

## Substrate Calls

LLM calls are packet events.

The body owns when and how they happen.

Substrate call event should carry:

```text
mode
operator
prompt_payload
context_refs
expected_shape
budget_cost
```

Candidate modes:

```text
glyph
natural
mixed
```

The substrate response is not runtime truth by default.

```text
substrate_result.truth_status = semantic_proposal
```

## Phantoms

The protocol may later support phantoms.

Phantom is not another agent.

Phantom is:

```text
bounded child manifestation
specific role
specific packet slice
budgeted
dead after return
```

First implementation may skip phantoms, but the protocol should not be designed
around multiplying agents.

## Budget

Budget should be protocol-visible.

Candidate dimensions:

```text
steps
substrate_calls
tool_calls
file_writes
test_runs
tokens
time
uncertainty
```

Lua v0 can start small:

```text
steps
substrate_calls
tool_calls
file_writes
test_runs
```

## Unsupported Form

Unsupported form should be first-class in packet protocol.

Event shape:

```text
unsupported_form = {
  emitted_form,
  source_event_id,
  unsupported_because,
  recurrence_key,
  recurrence_count,
  architectural_fit,
  decision
}
```

Decision:

```text
reject
defer
promote
decay
```

## Residue

Residue is written when:

```text
packet dies
gap is promoted
important validation fails
task manifests final output
```

Residue should be compact and reusable:

```text
worked
failed
missing
death_cause
files_touched
tests_run
do_not_repeat
resume_hint
```

## Protocol Operations

First Lua operations:

```text
new(task, options) -> packet
append(packet, event) -> packet
spend(packet, cost) -> packet | error
enter(packet, operator) -> packet | error
validate_transition(packet, next_operator) -> ok | error
record_unsupported(packet, form) -> packet
decide_gap(packet, recurrence_key, decision) -> packet
manifest(packet, payload) -> packet
die(packet, cause) -> packet
residue(packet) -> residue
```

## Design Pressure

The protocol should be boring to implement and hard to misuse.

Rules:

```text
append-only trace
no silent budget mutation
no manifest without truth status
no unsupported form as fact
no death without residue
no child packet without parent link
```
