# Runtime Pressure Snapshot Yellowprint v0

`runtime_pressure_snapshot` is the first table shape for `☱ RUNTIME`.

It exists because `proc-17` now has external sight, LOGIC boundaries, and
CYCLE continuation, but does not yet have a lower pressure eye.

## Two Hubs

```text
☴ OBSERVE
  upper pressure hub
  looks toward chaos / external evidence
  adjacent: ▽ ☰ ☷ ☵ ☳ ☱

☱ RUNTIME
  lower pressure hub
  looks toward manifest / body condition
  adjacent: ☵ ☳ ☴ ☲ ☶ △
```

The two organs should speak a similar payload language, but they do not look in
the same direction.

```text
☴ sees what can be contacted from outside the packet.
☱ sees what pressure has reached the body before manifestation.
```

## Distinction

```text
OBSERVE asks:
  what is visible outside the packet?

RUNTIME asks:
  what pressure is acting on the packet/body right now?
```

RUNTIME is not memory in the human sense. It does not "remember" by owning an
archive. It exposes conditions that allow residue to be decoded quickly.

## Role

```text
operator: RUNTIME
purpose: expose lower pressure condition as evidence
mode: read-only first
```

RUNTIME does not decide, route, plan, or produce will.

Will is expected to emerge from topology:

```text
▽ input pressure
☰ ☷ ☵ ☳ ☲ ☶ pressure transformers
☴ upper pressure hub
☱ lower pressure hub
△ output pressure
```

## Input

```text
packet
limits
optional cycle context
optional logic context
```

Limits candidate:

```text
trace_tail_count
include_residue
include_budget
include_pressure_sections
```

## Output

```text
runtime_pressure_snapshot_payload
```

Payload candidate:

```text
kind
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
trace_count
trace_tail
last_event
residue_summary
conditions
limits
truth_status = runtime_confirmed
```

## Pressure Sections

RUNTIME should report raw pressure, not decisions.

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
last_event_type
last_truth_status
```

LOGIC pressure:

```text
last_validation_event
accepted_count
rejected_count
rejection_reasons
```

CYCLE pressure:

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

Raw conditions:

```text
status_dead
status_dying
budget_negative
budget_exhausted_keys
has_trace
has_residue
last_truth_status
last_event_type
last_validation_event
last_cycle_decision
last_manifest_event
```

Avoid in v0:

```text
can_continue
stop_reason
next_action
route_choice
```

Those belong to CYCLE / CHOOSE / MANIFEST.

## Route

First expected route:

```text
OBSERVE collects external evidence
LOGIC validates boundary crossings
RUNTIME reads lower pressure after LOGIC/CYCLE history exists
CYCLE consumes runtime pressure and decides continuation
MANIFEST reports result/death using runtime evidence
```

RUNTIME is adjacent to `☲` and `☶`.

```text
☲ keeps the lower eye open across turns.
☶ constrains how the lower eye reads.
```

RUNTIME is not adjacent to `☰` and `☷`.

```text
☰ and ☷ reach RUNTIME only after being transformed through other operators.
RUNTIME should not directly infer raw connection/dissolution intent.
```

## Read-Only Constraint

RUNTIME pressure snapshot must not mutate:

```text
packet status
budget
trace
residue
death
files
tools
```

## Test Surface

Candidate tests:

```text
snapshot exposes packet id/status/mode/operator
snapshot exposes budget copy
snapshot exposes pressure sections
snapshot counts trace events
snapshot includes bounded trace_tail
snapshot exposes last_event
snapshot marks negative budget keys
snapshot reports last LOGIC/CYCLE/MANIFEST events when present
snapshot does not mutate packet
snapshot does not include can_continue
snapshot does not include next_action
snapshot keeps truth_status runtime_confirmed
```

## Open Questions

```text
should trace_tail include full payloads or summarized envelopes?
should residue be summarized by counts only?
should snapshot be appended as observation event or returned only?
should repeated_fingerprint belong to RUNTIME or CYCLE only?
should manifest_pressure exist before first MANIFEST event?
```

Early implementation should be a pure read-only function.
