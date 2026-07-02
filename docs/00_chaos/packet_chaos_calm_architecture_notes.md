# Packet Chaos Calm Architecture Notes

Raw architectural reflection for the next packet layer in `proc-17`.

This document is chaos-layer only.

No table contract yet.

No code contract yet.

## Starting Point

A user prompt enters through `▽`.

That birth does not create a clean plan.

It creates a dirty packet.

The dirty packet is closer to a thought before words than to a task object.

It is not required to be comfortable for a human reader.

It must be process-readable for the body.

## Zig Packet Invariant

The Zig packet prototype already had the deeper shape:

```text
SUBSTRATE
  body, memory, io, clock, PU budget

CHAOS
  mutable dirty field
  CRZ, fingerprints, mutation, raw pressure

BOUNDARY
  observes both sides
  decides whether to continue chaos, encode, or manifest

CALM
  deterministic crystallized executable form
  trigram VM

TENSION
  measures pressure between chaos and calm
  hold / reinforce / release / manifest
```

For `proc-17`, this is not code to copy.

It is the packet invariant.

## Corrected Eyes

The old Zig names were:

```text
OBSERVE_A watches CHAOS
OBSERVE_B watches CALM
```

For current ProcessLang topology:

```text
☴ OBSERVE
  watches CHAOS
  reads dirty pressure, raw prompt, unresolved substrate output, drift, mutation

☱ RUNTIME
  watches CALM and substrate
  reads crystallized form, executable state, budget, trace, death pressure
```

`☴` and `☱` are both eyes, but they face opposite directions.

`☴` sees what has not become form yet.

`☱` sees what already has runtime shape.

## ENCODE Is The Crystallizer

The body should not manually prebuild all internal structure.

The body should create conditions where `☵ ENCODE` can crystallize useful
structure from CHAOS into CALM.

This means:

```text
do not hardcode intelligence
do not manually decompose every task
do not make CYCLE invent work units
do not make RUNTIME become planner
```

Instead:

```text
packet starts dirty
☴ observes chaos pressure
☵ crystallizes part of chaos into calm
☱ reads calm/runtime
☳ chooses what continues
☶ checks the shape
☲ continues while unfinished pressure is payable
△ manifests when form can leave the packet
```

## Packet Areas

Future packet shape should probably expose internal areas:

```text
packet.substrate
  budget
  clock
  io/tool limits
  sandbox limits

packet.chaos
  raw prompt
  dirty substrate responses
  unresolved pressure
  candidate fragments
  fingerprints
  drift indicators

packet.boundary
  observations
  encode attempts
  loss records
  decisions between chaos/calm/manifest

packet.calm
  crystallized internal form
  work units if they emerge
  constraints
  executable plan fragments
  current form state

packet.tension
  chaos pressure
  calm rigidity
  boundary load
  unresolved delta
  action pressure
```

`packet.trace` remains append-only runtime evidence.

`packet.residue` remains what can survive packet death.

`packet.manifest` remains what can leave through `△`.

## Work Units Are Not Primary

`work.units` may appear later.

But they belong inside CALM.

They should be the result of crystallization, not the starting assumption.

Bad direction:

```text
human/codex manually invents all cycles
packet receives a prebuilt plan
CYCLE loops over it
```

Better direction:

```text
packet receives dirty pressure
ENCODE crystallizes a calm structure
CALM may contain work units
RUNTIME counts what exists
LOGIC validates what is counted
CYCLE says again or stop
```

The less external hand-authoring we need, the better.

## Loss And Death

Encoding from CHAOS into CALM is lossy.

That is correct.

But loss must be visible.

The packet can die in at least two different ways:

```text
budget death
  the packet cannot pay for continuation

identity/loss death
  the packet has drifted too far from its original pressure
```

Ordinary agents often keep acting after identity death.

`proc-17` should not.

If the packet is no longer the same packet, it should die or leave residue,
not continue producing unrelated form.

## Minimal Next Step

Do not implement a planner yet.

Do not implement automatic cycle decomposition yet.

First table/crystal/code pass should only give packet a place for:

```text
chaos
calm
boundary
tension
substrate
```

And define who is allowed to write each area.

Likely ownership:

```text
▽ initializes chaos
☴ appends chaos observations
☵ writes calm through crystallization
☱ reads calm/substrate/runtime
☳ records selected continuing branch
☶ records validation
☲ records continuation decision
△ records manifest
```

The architecture should make intelligence possible without pretending the
body already knows the whole decomposition.

