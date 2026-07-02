# Packet Internal Architecture Yellowprint v0

Table-layer address map for packet internal areas.

Source:

```text
docs/00_chaos/packet_chaos_calm_architecture_notes.md
```

This is not a final implementation contract.

It defines the first stable table shape for the packet as a body with internal
CHAOS and CALM.

## Role

```text
packet = mortal process body for one task life
```

The packet is not only:

```text
task string
plan
trace
chat context
model response
```

It is the living internal form that begins dirty at `▽`, may crystallize
through `☵`, and dies or manifests at the end of its life.

## Area Map

Candidate packet areas:

```text
substrate
chaos
boundary
calm
tension
trace
residue
death
manifest
```

Existing areas:

```text
trace
residue
death
budget
context
metadata
```

New internal areas:

```text
substrate
chaos
boundary
calm
tension
manifest
```

`budget` may remain top-level in v0 while also being exposed through
`substrate.budget`.

## Area Meanings

### substrate

Runtime body conditions:

```text
budget
clock
io/tool limits
sandbox limits
host conditions
```

Owner:

```text
body runtime
```

Writers:

```text
▽ initializes
☱ snapshots
tool/runtime layers update through explicit events
```

Readers:

```text
☱ ☶ ☲ △
```

### chaos

Dirty pre-form field:

```text
raw prompt
dirty substrate responses
unresolved pressure
candidate fragments
fingerprints
drift indicators
```

Owner:

```text
packet life before crystallization
```

Writers:

```text
▽ initializes
☴ appends observations
substrate_result may append semantic pressure
☷ may decay stale pressure later
```

Readers:

```text
☴ ☵ ☳ ☶
```

### boundary

Transition record between CHAOS and CALM:

```text
observations
encode attempts
loss records
decisions between chaos/calm/manifest
```

Owner:

```text
body boundary layer
```

Writers:

```text
☴ records observations
☵ records crystallization attempts and loss
☳ records selected continuing branch
☶ records validation
☲ records continuation decision
```

Readers:

```text
☵ ☳ ☶ ☱ ☲ △
```

### calm

Crystallized internal form:

```text
work units if they emerge
constraints
executable plan fragments
current form state
runtime-usable structure
```

Owner:

```text
☵ ENCODE through crystallization
```

Writers:

```text
☵ writes calm through crystallization
☶ may mark invalid/rejected status
☳ may mark selected continuing branch
```

Readers:

```text
☱ ☳ ☶ ☲ △
```

Important rule:

```text
work units are not primary
work units may appear inside calm only after crystallization
```

### tension

Pressure between CHAOS and CALM:

```text
chaos pressure
calm rigidity
boundary load
unresolved delta
action pressure
```

Owner:

```text
body pressure model
```

Writers:

```text
☱ measures
☶ may mark impossible/invalid pressure
☲ may record continuation pressure
```

Readers:

```text
☵ ☳ ☶ ☲ △
```

## Corrected Eyes

```text
☴ OBSERVE
  reads CHAOS
  sees unresolved dirty pressure

☱ RUNTIME
  reads CALM + SUBSTRATE
  sees crystallized runtime shape and cost/death pressure
```

Both are eyes.

They do not face the same direction.

## Crystallization

`☵ ENCODE` is the only normal path from CHAOS to CALM.

Candidate operation:

```text
crystallize(packet, input) -> calm_delta
```

Required visible fields:

```text
source_chaos_refs
calm_delta
loss
confidence/status
boundary_event_id
```

Crystallization must not pretend to be lossless.

## Ownership Table

```text
▽
  initializes packet.chaos

☴
  appends chaos observations

☵
  writes calm through crystallization
  records loss in boundary

☱
  reads calm/substrate/runtime
  may write runtime/tension snapshots

☳
  records selected continuing branch

☶
  validates calm/boundary shape

☲
  records again/stop continuation decision

△
  writes manifest output
```

## Trace Relation

Internal areas are mutable packet state.

Trace remains append-only runtime evidence.

Rule:

```text
no important area mutation without trace event
```

Possible new event types:

```text
chaos_observation
crystallization
calm_update
tension_measure
cycle_progress
```

These names are candidates only.

They should be crystallized later.

## Death Relation

Packet may die through:

```text
budget death
identity/loss death
unsafe scope
invalid topology
needs user input
complete manifest
```

Identity/loss death means:

```text
the packet can technically continue,
but continuing would no longer be the same packet
```

This should become first-class later.

## First Implementation Boundary

Do not implement a planner.

Do not implement automatic task decomposition.

Do not hardcode cycle units.

First implementation should only:

```text
add packet areas
initialize them
expose small append/update helpers
write trace events for area mutation
preserve old packet behavior
```

The body should then be able to grow decomposition from `☵` pressure, not from
manual external planning.

