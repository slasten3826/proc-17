# Packet Internal Architecture Blueprint v0

This blueprint defines the first crystallized internal architecture for the
`proc-17` packet.

It extends, but does not replace:

```text
docs/02_crystall/blueprints/packet_protocol.v0.md
```

## Primary Rule

The packet is not only a task container.

The packet is a mortal internal process body with dirty CHAOS and crystallized
CALM.

## Compatibility Rule

Existing packet protocol v0 remains valid.

This layer is additive.

Old required fields remain:

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

Internal architecture v0 adds optional fields first:

```text
substrate
chaos
boundary
calm
tension
manifest
```

They may become required after the first implementation stabilizes.

## Area Definitions

### substrate

Runtime body conditions.

Shape:

```text
substrate = {
  budget = table,
  clock = table | nil,
  io_limits = table | nil,
  tool_limits = table | nil,
  sandbox = table | nil,
  host = table | nil
}
```

Allowed writers:

```text
▽ initialize
☱ runtime snapshot/update
runtime/tool layer through explicit trace event
```

Allowed readers:

```text
☱ ☶ ☲ △
```

### chaos

Dirty pre-form packet field.

Shape:

```text
chaos = {
  raw_prompt = string | nil,
  fragments = list,
  unresolved_pressure = list,
  fingerprints = list,
  drift = table,
  observations = list
}
```

Allowed writers:

```text
▽ initialize raw_prompt
☴ append observations
substrate_result append semantic fragments
☷ decay stale pressure later
```

Allowed readers:

```text
☴ ☵ ☳ ☶
```

### boundary

Transition record between CHAOS and CALM.

Shape:

```text
boundary = {
  observations = list,
  crystallizations = list,
  loss_records = list,
  choices = list,
  validations = list,
  cycles = list
}
```

Allowed writers:

```text
☴ observation record
☵ crystallization/loss record
☳ choice record
☶ validation record
☲ continuation record
```

Allowed readers:

```text
☵ ☳ ☶ ☱ ☲ △
```

### calm

Crystallized runtime-usable form.

Shape:

```text
calm = {
  structures = list,
  constraints = list,
  executable_fragments = list,
  work_units = list,
  current = table | nil,
  status = string | nil
}
```

Allowed writers:

```text
☵ through crystallization only
☶ mark invalid/rejected status
☳ mark selected continuing branch
```

Allowed readers:

```text
☱ ☳ ☶ ☲ △
```

Important:

```text
work_units are not primary.
work_units may appear only as crystallized CALM structure.
```

### tension

Pressure between CHAOS and CALM.

Shape:

```text
tension = {
  chaos_pressure = number | nil,
  calm_rigidity = number | nil,
  boundary_load = number | nil,
  unresolved_delta = number | nil,
  action_pressure = string | nil
}
```

Allowed writers:

```text
☱ measure/update
☶ mark impossible/invalid pressure
☲ record continuation pressure
```

Allowed readers:

```text
☵ ☳ ☶ ☲ △
```

### manifest

Externalizable packet form.

Shape:

```text
manifest = {
  output_type = string | nil,
  language = string | nil,
  payload = any,
  residue = table | nil,
  source_events = table | nil
}
```

Allowed writers:

```text
△ only
```

Allowed readers:

```text
△
packet death/residue
```

## Corrected Eye Contract

```text
☴ OBSERVE
  reads packet.chaos
  sees dirty unresolved pressure
  may append chaos observations

☱ RUNTIME
  reads packet.calm + packet.substrate
  sees crystallized runtime shape, cost, and death pressure
  may update packet.tension
```

They are both eyes, but not the same eye.

`☴` looks toward pre-form.

`☱` looks toward formed runtime.

## Crystallization Contract

`☵ ENCODE` is the normal path from CHAOS to CALM.

Candidate operation:

```text
crystallize(packet, input) -> packet | nil, error
```

Required effects:

```text
read packet.chaos
append packet.boundary.crystallizations
append packet.boundary.loss_records
update packet.calm
append trace event
```

Required crystallization record:

```text
{
  source_chaos_refs = list,
  calm_delta = table,
  loss = table,
  status = string,
  trace_event_id = string
}
```

Crystallization must not be lossless.

If no loss is recorded, the event is invalid.

## Trace Rule

Internal area mutation requires a trace event.

No silent updates.

Candidate event types:

```text
chaos_observation
crystallization
calm_update
tension_measure
cycle_progress
```

Implementation may reuse existing event types at first if event type expansion
would create too much churn.

If existing event types are reused, payload kind must identify the internal
mutation.

## Death Rule

Packet death may be caused by:

```text
budget_exhausted
identity_loss
blocked_by_runtime_truth
needs_user_input
invalid_topology
loop_repetition
unsafe_scope
complete
```

`identity_loss` means:

```text
the packet can technically continue,
but continuing would no longer be this packet
```

This blueprint introduces `identity_loss` as architecture pressure.

It does not require immediate death implementation.

## Non-Goals

Do not implement in this layer:

```text
automatic planner
automatic task decomposition engine
hardcoded cycle units
LLM-owned packet state
human-readable packet UI
```

The purpose is to make the internal body possible, not to pre-author its full
intelligence.

## First Implementation Boundary

First code pass should be small:

```text
initialize internal areas on packet.new
provide append/update helpers for chaos/calm/boundary/tension
preserve current packet tests
add tests for area initialization and trace-visible mutation
```

Do not route CLI through the new architecture until the internal packet surface
is stable.

