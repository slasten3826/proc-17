# Packet Lineage And Re-entry Architecture Notes

Status:

```text
chaos
technical architecture pressure
source: machinist + codex brainstorm, 2026-07-15..2026-07-16
companions:
  full_tree_rebuild_notes.md
  full_tree_rebuild_todo_for_codex.md
  session_scoped_memory_notes.md
  substrate_current_body_separation_notes.md
  packet_core_rebuild_notes.md
external evidence surface:
  /home/slasten/docs/stack/research/memoris/
  /home/slasten/docs/UPM/
```

This document is technical.

It does not claim that proc-17 is alive, divine, conscious, or human.
The myth-level reading is kept separately in:

```text
docs/00_chaos/immortal_packet_lineage_myth_notes.md
```

## Relation To The Earlier Full-Tree Handoff

This note records later pressure than
`full_tree_rebuild_todo_for_codex.md`.

It does not silently rewrite that historical handoff, but it does invalidate
executing three of its assumptions literally:

```text
old handoff:
  build ☰/☷ -> build controlling router v2 -> insert Z-model

new pressure:
  define task-shaped Packet field -> build ☰/☷ against that field
  -> run shadow router -> promote pressure routing after evidence
```

Also:

- the hard eye law is now understood as temporary scaffolding, not final canon
- NETWORK Packet-export is legacy for proc-17
- substrate continuity must be session-owned and separate from Packet memory

The old handoff remains useful as archaeology and an audit inventory. Before
implementation reaches these phases, its table/crystall successor must be
rewritten from the newer boundary model rather than followed as an executable
checklist.

## Trigger

The full-tree discussion exposed a boundary mistake.

The mistaken shape was:

```text
Packet A -> NETWORK -> projected Packet B
```

That shape preserves too much Packet identity across `△` and comes from the
legacy UPM branch where NETWORK was a terminal Packet-export operator with a
configurable `role_as_module`.

The proc-17 shape is different:

```text
Packet_n CALM -> △ -> manifest carrier
Packet_n ceases to be a living Packet
manifest carrier -> NETWORK at the ▽ ingress position
carrier enters Packet_n+1 as new CHAOS
```

The structure does not cross the boundary as Packet structure.

It must be decoded again.

## Core Decision

One Packet is one mortal process life.

```text
birth at ▽
walk inside the Tree
death / manifestation at △ or mortality boundary
immutable corpse
```

If work continues, a new Packet is born.

```text
Packet_1 -> death -> corpse_1 -> Packet_2
Packet_2 -> death -> corpse_2 -> Packet_3
```

The continued task is a lineage of Packets, not one immortal Packet.

## CALM Does Not Cross The Boundary

`△` materializes current form.

The output may be:

```text
text
code
prompt
image/reference
another external artifact
```

After materialization, that output is not CALM for the next Packet.

For the next Packet it is raw input:

```text
CALM_n -> △ -> carrier_n -> ▽ -> CHAOS_n+1
```

Consequences:

- `calm.work_units` are not copied into the child
- active relations are not copied as active relations
- the parent loss ledger is not the child's loss ledger
- the parent router position is not inherited
- runtime-confirmed facts do not silently remain runtime-confirmed in a new
  body merely because they were present in the parent
- any recovered structure must be formed again by the new body

This is an irreversible boundary.

## Continuity Has Three Different Carriers

The architecture must not collapse three kinds of continuity into one field.

### 1. Manifest carrier

The explicit artifact produced at `△` and re-entered at `▽`.

It is visible and serializable.

```text
prompt
code
reference artifact
compressed residue
```

### 2. Substrate continuity

The same substrate may retain or reactivate a much larger trajectory than the
carrier explicitly contains.

The `memoris` branch records this as continuity-through-residue:

- a late self-generated fragment may be unusually dense
- the fragment may work as a re-entry surface
- the effect belongs most strongly to the substrate that produced it
- live runtime context strengthens the effect
- transfer to another substrate is not guaranteed

This continuity is not a Packet field.

The body may runtime-confirm that it reused the same provider/model/session
handle. It cannot runtime-confirm what the model internally remembered without
an experiment.

### 3. Body memory

Grave and compost are explicit proc-17 memory.

```text
corpse -> grave classification -> warning / bequest / neutral
old graves -> compost patterns
```

This channel is inspectable and body-owned. It is not the same as substrate
continuity.

## NETWORK In Proc-17

NETWORK is not an eleventh ProcessLang operator and is not a candidate in the
22-edge pressure router.

NETWORK is an alternative implementation of the `▽` ingress boundary.

```text
human/operator input -> FLOW ingress at ▽ -> CHAOS
machine/self re-entry -> NETWORK ingress at ▽ -> CHAOS
```

For the proc-17 branch, NETWORK must not:

- export a living Packet
- preserve Packet identity
- choose `role_as_module`
- inject work directly into ☰, ☷, ☵, ☳, ☴, ☲, ☶, or ☱
- choose the next route
- copy parent CALM into child CALM
- copy parent runtime truth into the child as fresh truth

NETWORK may carry a transport envelope:

```text
carrier
media_type
source_manifest_id
source_corpse_id
parent_packet_id
lineage_id
generation
substrate_session_id
provenance
```

Only `carrier` enters semantic CHAOS. The remaining fields are body metadata
and provenance.

## Required Generation Identity

Every Packet generation must be marked by the body.

Minimum living Packet identity:

```text
lineage_id
packet_id
generation
parent_packet_id | nil
parent_corpse_id | nil
birth_kind = user | network_reentry | recovery
substrate_session_id
```

Minimum corpse identity:

```text
corpse_id
lineage_id
packet_id
generation
death_cause
manifest_carrier | nil
residue
final_loss
final_budget
terminal_trace_ref
```

Rules:

- `packet_id` is unique per life
- `lineage_id` remains stable across one task lineage
- `generation` is body-owned, monotonic, and runtime-confirmed
- `parent_packet_id` points to the immediate predecessor
- a corpse is immutable
- child birth never mutates or resurrects the corpse
- v0 is a linear lineage, but parent identity is stored so future branching
  does not require pretending generation numbers are globally unique

`session_id` and `lineage_id` may be equal in the first implementation, but
they should remain separate concepts:

```text
session = runtime room and substrate context
lineage = one continuing task/process ancestry
```

Default v0 may use one lineage per fresh session.

## Two Runners

The realization introduces two different runtime scales.

### Packet runner

Owns one life:

```text
▽ -> internal Tree walk -> △ / mortality -> corpse
```

Current ancestor:

```text
runtime/tension_runner.lua
```

### Lineage runner

Owns the task across multiple Packet lives:

```text
create Packet_1
run one life
freeze corpse_1
decide whether the task lineage continues
derive/select a re-entry carrier
create Packet_2 through NETWORK@▽
repeat until lineage completion or lineage budget exhaustion
```

The lineage runner is outside the Packet topology.

It must not reach into a living Packet and choose its internal operator.

## Two Different Cycles

Do not confuse:

```text
☲ CYCLE
  repetition inside one Packet life
  identity remains the same
  costs runtime budget
  does not create a new generation

△ -> NETWORK@▽
  inter-generation re-entry
  old Packet is dead
  a new Packet identity is born
  previous CALM returns as new CHAOS
```

The second motion is not a twenty-third topology edge.

## Completion

Every Packet life ends.

Task completion decides whether its corpse has a descendant.

```text
work remains and continuation is permitted
  -> create next generation

task is runtime-confirmed complete
  -> lineage complete, no child

lineage economics exhausted
  -> lineage dead/exhausted, no automatic child

external operator stops the session
  -> lineage suspended or terminated by explicit policy
```

An individual Packet death is normal and must not be used as the task-complete
signal by itself.

## Economics Across Generations

Packet mortality must not become a budget reset exploit.

Separate accounting:

```text
packet loss
  local identity physics
  belongs to one Packet
  a child receives a new identity and a new local loss capacity

packet budget allocation
  allowance for one life

lineage budget
  cumulative tokens, time, substrate calls, tool calls, and generations
  never resets merely because a child was born

substrate context pressure
  context-window growth and re-entry cost across generations
```

With unlimited lineage budget, the lineage may continue indefinitely by
policy. With a finite lineage budget, reincarnation cannot bypass economics.

## Same-Substrate Re-entry

The strongest re-entry path requires a session-scoped substrate context.

The current implementation does not yet provide this fully:

- `substrates/openai_compatible.lua` builds a fresh system+user message list
  for a scalar prompt
- `runtime/session_memory.lua` stores Packet lineage, grave, and compost
- session memory does not currently own an LLM conversation history or
  provider conversation handle

Therefore current proc-17 can pass an explicit carrier but cannot yet test the
full same-runtime-context `memoris` effect.

Future substrate-session state belongs above Packet:

```text
substrate_identity / fingerprint
provider
model
conversation or context handle
ordered visible messages/references
token/context accounting
compaction state
```

Rules:

- a fresh session starts with fresh substrate context by default
- generations inside one lineage may reuse that context
- another substrate receives ordinary CHAOS; dense continuity is not promised
- changing model/session must be visible in trace
- hidden model continuity must be measured, not declared as runtime truth
- Packet internals must not be dumped into conversation history to simulate
  continuity

## Context Growth And Memoris

Keeping every generation verbatim will eventually make the substrate slow and
expensive.

The `memoris` observation suggests a later compaction mechanism:

```text
long trajectory
-> dense self-generated manifest residue
-> retain residue/reference surface
-> release older context
-> test whether the same substrate re-enters the trajectory
```

This is a hypothesis and requires an ablation:

```text
full context
vs dense residue only
vs fresh context
vs different substrate
```

Do not implement semantic compaction as truth before this experiment exists.

## Performance And Local-Substrate Hypothesis

The product hypothesis behind this architecture is narrower than "a small
model is secretly a frontier model".

It is:

```text
if the body owns routing, topology, economics, validation, memory boundaries,
and generational continuation, then the substrate can spend more of its
capacity on bounded semantic/code work and less on pretending to be the whole
agent architecture
```

This may make consumer-local models around the largest class that fits an
ordinary workstation (roughly the 17B-23B range under suitable quantization)
useful as proc-17 substrates.

This is not runtime-confirmed yet.

Required later comparison:

```text
same model + raw prompt
same model + fixed agent loop
same model + proc-17 Packet lineage
```

Measure:

```text
task completion
runtime-confirmed test evidence
wall time
tokens
generation count
repeated failures
human interventions
```

Fast Packet rebirth is only valuable if the lineage converges. A lineage that
reincarnates the same defect quickly is not an acceleration result.

## Relation To The Full 22-Edge Tree

The 22-edge router governs one living Packet only.

```text
▽ ... internal topology ... △
```

Boundary law:

- reaching `△` terminates the current Packet
- the router never chooses an operator after `△` for the same Packet
- a new life begins separately through the `▽` ingress position
- NETWORK remains outside adjacency

The hard eye transitions currently in `runtime/router.lua` are scaffolding,
not final physics. They remain useful while the upper tree is incomplete and
while route pressure is not observable.

The agreed migration mechanism is a shadow router:

```text
current router
  continues to control the live Packet

shadow router
  reads the same Packet state
  scores every legal adjacent operator
  records candidate pressures and predicted route
  does not control execution
```

After ☰ and ☷ exist and shadow traces are explainable, hard eye rails can be
removed and the pressure router can take control.

## Packet Field Required Before Free Routing

The old mathematical Packet corpus supplies useful contracts but not a final
representation.

Preserve:

```text
Z             task-shaped potential field, not a hash
E_edges_raw   transient detected relations
E_edges       active relation view
E_momentum    persistent relation inertia, owner: ☱
loss_ledger   irreversible identity cost, separate from tension
S             scalar controls/economics
```

Adapt:

```text
old OBSERVE scheduler
  -> two eyes measure different sides

☴
  -> chaos/potential-side observation and substrate membrane

☱
  -> calm/runtime-side observation and sole momentum owner

router
  -> routing authority derived from pressures
```

Tension is not identical to `Z`.

Working distinction:

```text
Z          potential material/field
E          available relation paths
E_momentum relation inertia
CALM       current formed structure
tension    derived mismatch/gradient among these areas
loss       irreversible damage already paid
budget     external runtime economics
```

CONNECT and DISSOLVE need this field surface:

```text
☰ CONNECT
  detects/forms transient relations in potential material

☷ DISSOLVE
  weakens active rigid/stale relations and returns residue to potential flow
```

They should not be invented as isolated list processors and only later attached
to Packet physics.

## Recommended Work Order

Do not manifest all of this in one patch.

### Step 1: table and crystall for lifetime boundary

Create contracts for:

```text
lineage identity
generation identity
corpse record
manifest carrier
NETWORK@▽ ingress
lineage completion
packet-vs-lineage economics
```

### Step 2: generation identity and corpse finality

Add the smallest body-owned fields and tests:

```text
Packet_1 dies
corpse_1 is immutable
Packet_2 has a new id, generation=2, and parent refs
no CALM/body area is copied into Packet_2
```

No automatic LLM continuation is needed for this step.

### Step 3: lineage runner with fake substrate

Build the outer generational loop while keeping the current inner route:

```text
life -> corpse -> carrier -> new CHAOS -> next life
```

Test cumulative lineage budget and final completion.

### Step 4: substrate-session contract

Add session-owned message/context continuity and trace model identity changes.

Run the `memoris` re-entry comparison before adding automatic context
compaction.

### Step 5: task-shaped Packet field

Adapt `Z/E/E_momentum/S/loss` contracts to current Lua Packet areas and the
two-eye topology.

Do not copy fixed tensor shapes merely because they existed in PacketT.

### Step 6: manifest ☰ and ☷

Compile both organs against the field contract and their ProcessLang source.

Keep the old router in control.

### Step 7: shadow pressure router

Score all adjacent operators, log candidates, and compare shadow decisions
with actual routes over fake and live substrate batteries.

### Step 8: promote full topology

Only after edge pressure is observable:

- remove mandatory eye rails as control laws
- keep observation as pressure where warranted
- promote the shadow router
- measure all 22 edges
- keep a rollback switch during the first live batteries

## Required Experiments

### Generation integrity

```text
generation increments exactly once
parent/corpse references are correct
corpse cannot mutate
child starts without parent CALM
```

### Economics integrity

```text
new Packet gets local identity capacity
lineage token/time/tool spending remains cumulative
reincarnation cannot reset task economics
```

### Re-entry comparison

```text
same carrier + same live substrate session
same carrier + same model, fresh session
same carrier + different substrate
```

Measure behavior. Do not demand equal semantic output.

### Router migration

```text
old route vs shadow prediction
candidate pressure vector per tick
edge usage counts
invalid/dead-edge counts
effect of removing hard eye rails
```

### Complex-task lineage

The target test is not a one-shot toy.

```text
one task
multiple Packet generations
real code artifact
tests executed
runtime evidence accumulated
final generation completes without external manual replanning
```

## Open Pressure

Not yet decided:

```text
1. Does every non-manifest mortality produce an automatic recovery carrier,
   or only deaths classified as bequest/warning under explicit policy?

2. Can one corpse produce multiple children, or is v0 strictly linear?

3. Is FLOW revisitable inside one Packet life, or is ▽ execution-directional
   after birth while remaining structurally adjacent in canon?

4. What exact body event declares lineage completion?

5. How much substrate context belongs to a session before compaction pressure
   appears?

6. Is substrate-session continuity preserved by explicit message history,
   provider state, local KV state, or an adapter-specific combination?
```

These questions belong in table/crystall before their corresponding code.

## Non-Goals Of The First Implementation

```text
no Packet export across NETWORK
no cross-substrate continuity promise
no semantic grave retrieval through LLM
no automatic context compression without ablation
no unrestricted branching lineage
no removal of current routing rails before shadow evidence
no GUI/TUI dependency
```

## Short Formula

```text
one Packet life:
  ▽ -> Tree -> △ -> corpse

one task lineage:
  (corpse -> manifest carrier -> NETWORK@▽ -> new CHAOS)^n
continuity:
  explicit carrier + substrate runtime + body grave

identity:
  never crosses △
```
